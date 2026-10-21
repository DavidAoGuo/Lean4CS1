/-
RFC 6455 WebSocket, from scratch, on top of `LeanCDP.Transport`. This
is the layer CDP actually rides on: a CDP message is just a WebSocket
text frame carrying JSON.

Handles the parts of the spec a real connection needs: the HTTP
Upgrade handshake (with `Sec-WebSocket-Accept` verification), masking
of outgoing frames (mandatory for a client), the three payload-length
encodings, message reassembly across fragmented frames, and replying
to `Ping` with `Pong`. What it does not do: compression extensions
(`permessage-deflate`) and UTF-8 validation of text payloads -- both
left as exercises, same spirit as the ones at the end of the course's
`E11_abstractAlgebra.lean`.
-/

import LeanCDP.Transport
import LeanCDP.Codec.Base64
import LeanCDP.Codec.SHA1

namespace LeanCDP.WebSocket

open Std.Async LeanCDP.Codec

/-- The GUID RFC 6455 §1.3 fixes for computing `Sec-WebSocket-Accept`. -/
private def guid : String := "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

/-- `base64(SHA1(key ++ guid))`, as the handshake response is required to be. -/
def expectedAccept (clientKey : String) : String :=
  Base64.encode (SHA1.digest (clientKey ++ guid).toUTF8)

/-- The frame opcodes this module understands. -/
inductive Opcode where
  | continuation
  | text
  | binary
  | close
  | ping
  | pong
  | other (code : UInt8)
  deriving Repr, BEq

def Opcode.toByte : Opcode → UInt8
  | .continuation => 0x0
  | .text         => 0x1
  | .binary       => 0x2
  | .close        => 0x8
  | .ping         => 0x9
  | .pong         => 0xA
  | .other c      => c

def Opcode.ofByte (b : UInt8) : Opcode :=
  if b == 0x0 then .continuation
  else if b == 0x1 then .text
  else if b == 0x2 then .binary
  else if b == 0x8 then .close
  else if b == 0x9 then .ping
  else if b == 0xA then .pong
  else .other b

private def Opcode.isControl : Opcode → Bool
  | .close | .ping | .pong => true
  | _ => false

/-- Strip leading/trailing spaces, enough for an HTTP header value. -/
private def trimSpaces (s : String) : String :=
  String.ofList ((s.toList.dropWhile (· == ' ')).reverse.dropWhile (· == ' ')).reverse

/--
An open, handshaken WebSocket connection. Buffers whatever bytes
`Transport.recv?` handed back but weren't yet consumed as a complete
frame (or, during the handshake, as the HTTP response), since a
single TCP read can straddle -- or span several -- of those
boundaries.
-/
structure Connection where
  private mk ::
  conn : LeanCDP.Transport.Connection
  private buf : IO.Ref ByteArray

/-- Find `needle` in `hay`, returning the index of its first occurrence. -/
private def findSub (hay : ByteArray) (needle : ByteArray) : Option Nat := Id.run do
  let n := hay.size
  let m := needle.size
  let mut result : Option Nat := none
  if m == 0 then
    return none
  if m ≤ n then
    for start in [0 : n - m + 1] do
      if result.isNone then
        let mut matched := true
        for j in [0:m] do
          if hay.get! (start + j) != needle.get! j then
            matched := false
        if matched then
          result := some start
  return result

namespace Connection

/-- Pull more bytes from the transport into `buf`. `false` means the peer closed the connection. -/
private def fill (c : Connection) : Async Bool := do
  match ← c.conn.recv? with
  | some chunk => c.buf.modify (· ++ chunk); return true
  | none => return false

/-- Read until `buf` holds at least `n` bytes, or the peer closes first. -/
private partial def ensure (c : Connection) (n : Nat) : Async Bool := do
  let rec loop : Async Bool := do
    let bufSize := (← c.buf.get).size
    if bufSize ≥ n then return true
    else if ← c.fill then loop else return false
  loop

/-- Take and remove the first `n` bytes of `buf`. Caller must have `ensure`d at least `n` first. -/
private def take (c : Connection) (n : Nat) : Async ByteArray := do
  let b ← c.buf.get
  c.buf.set (b.extract n b.size)
  return b.extract 0 n

/-- Read until `delim` appears in `buf`; returns the bytes before it and consumes through it. -/
private partial def readUntil (c : Connection) (delim : ByteArray) : Async (Option ByteArray) := do
  let rec loop : Async (Option ByteArray) := do
    let cur ← c.buf.get
    match findSub cur delim with
    | some idx =>
      c.buf.set (cur.extract (idx + delim.size) cur.size)
      return some (cur.extract 0 idx)
    | none => if ← c.fill then loop else return none
  loop

private def unmask (mask : ByteArray) (payload : ByteArray) : ByteArray := Id.run do
  let mut out := ByteArray.empty
  for i in [0:payload.size] do
    out := out.push (payload.get! i ^^^ mask.get! (i % 4))
  return out

/-- Build one masked frame (client → server frames are always masked). -/
private def encodeFrame (opcode : Opcode) (payload : ByteArray) : Async ByteArray := do
  let maskKey ← IO.getRandomBytes 4
  let len := payload.size
  let maskBit : UInt8 := 0x80
  let mut header := ByteArray.empty
  header := header.push (0x80 ||| opcode.toByte)  -- FIN=1: this module never fragments outgoing frames
  if len < 126 then
    header := header.push (maskBit ||| len.toUInt8)
  else if len ≤ 0xFFFF then
    header := header.push (maskBit ||| 126)
    header := header.push ((len / 256) % 256).toUInt8
    header := header.push (len % 256).toUInt8
  else
    header := header.push (maskBit ||| 127)
    for i in [0:8] do
      let shift := (7 - i) * 8
      header := header.push ((len >>> shift) % 256).toUInt8
  header := header ++ maskKey
  let mut maskedPayload := ByteArray.empty
  for i in [0:len] do
    maskedPayload := maskedPayload.push (payload.get! i ^^^ maskKey.get! (i % 4))
  return header ++ maskedPayload

private def sendFrame (c : Connection) (opcode : Opcode) (payload : ByteArray) : Async Unit := do
  c.conn.send (← encodeFrame opcode payload)

/-- Read exactly one raw frame: `(fin, opcode, payload)`, already unmasked. `none` at EOF. -/
private def recvFrame (c : Connection) : Async (Option (Bool × Opcode × ByteArray)) := do
  if !(← c.ensure 2) then return none
  let hdr ← c.take 2
  let b0 := hdr.get! 0
  let b1 := hdr.get! 1
  let fin := (b0 &&& 0x80) != 0
  let opcode := Opcode.ofByte (b0 &&& 0x0F)
  let masked := (b1 &&& 0x80) != 0
  let lenField := (b1 &&& 0x7F).toNat
  let mut payloadLen := lenField
  if lenField == 126 then
    if !(← c.ensure 2) then return none
    let ext ← c.take 2
    payloadLen := (ext.get! 0).toNat * 256 + (ext.get! 1).toNat
  else if lenField == 127 then
    if !(← c.ensure 8) then return none
    let ext ← c.take 8
    let mut n := 0
    for i in [0:8] do
      n := n * 256 + (ext.get! i).toNat
    payloadLen := n
  let mut maskKey := ByteArray.empty
  if masked then
    if !(← c.ensure 4) then return none
    maskKey ← c.take 4
  if !(← c.ensure payloadLen) then return none
  let raw ← c.take payloadLen
  return some (fin, opcode, if masked then unmask maskKey raw else raw)

/--
Read one *message*, reassembling fragmented (`fin = false`) frames,
transparently answering `Ping` with `Pong`, and surfacing a `Close`
frame as `none` (while echoing a `Close` back, per spec). Everything
other than `Text`/`Binary` is handled internally and never returned.
-/
partial def recvMessage (c : Connection) : Async (Option (Opcode × ByteArray)) := do
  let rec loop (acc? : Option (Opcode × ByteArray)) : Async (Option (Opcode × ByteArray)) := do
    match ← c.recvFrame with
    | none => return none
    | some (fin, opcode, payload) =>
      if opcode.isControl then
        match opcode with
        | .ping => c.sendFrame .pong payload; loop acc?
        | .close => c.sendFrame .close payload; return none
        | _ => loop acc?  -- an inbound .pong, or an unrecognised control opcode: nothing to do
      else
        let merged := match acc? with
          | some (o, p) => (o, p ++ payload)
          | none => (opcode, payload)
        if fin then return some merged else loop (some merged)
  loop none

/-- Send a complete text message as a single frame. -/
def sendText (c : Connection) (s : String) : Async Unit :=
  c.sendFrame .text s.toUTF8

/-- Send a complete binary message as a single frame. -/
def sendBinary (c : Connection) (data : ByteArray) : Async Unit :=
  c.sendFrame .binary data

/-- Send a `Close` frame and shut down the underlying transport. -/
def close (c : Connection) : Async Unit := do
  c.sendFrame .close ByteArray.empty
  c.conn.close

end Connection

/--
Perform the RFC 6455 handshake against `host:port`, requesting
`path`, and return the connection ready for `sendText`/`recvMessage`.
`host` must be a numeric IPv4 literal (same restriction as
`Transport.connect`). Throws if the server doesn't answer `101`, or
if `Sec-WebSocket-Accept` doesn't match what RFC 6455 says it must be.
-/
def connect (host : String) (port : UInt16) (path : String := "/") : Async Connection := do
  let tconn ← LeanCDP.Transport.connect host port
  let buf ← IO.mkRef ByteArray.empty
  let c : Connection := ⟨tconn, buf⟩
  let key := Base64.encode (← IO.getRandomBytes 16)
  let req :=
    s!"GET {path} HTTP/1.1\r\n" ++
    s!"Host: {host}:{port}\r\n" ++
    "Upgrade: websocket\r\n" ++
    "Connection: Upgrade\r\n" ++
    s!"Sec-WebSocket-Key: {key}\r\n" ++
    "Sec-WebSocket-Version: 13\r\n\r\n"
  c.conn.send req.toUTF8
  match ← c.readUntil "\r\n\r\n".toUTF8 with
  | none => throw <| .userError "LeanCDP.WebSocket.connect: connection closed during handshake"
  | some headerBytes =>
    let lines := (String.fromUTF8! headerBytes).splitOn "\r\n"
    let statusLine := lines.headD ""
    if !((statusLine.splitOn " ").contains "101") then
      throw <| .userError s!"LeanCDP.WebSocket.connect: handshake rejected: {statusLine}"
    match lines.find? (fun l => (l.toLower).startsWith "sec-websocket-accept:") with
    | none => throw <| .userError "LeanCDP.WebSocket.connect: no Sec-WebSocket-Accept header"
    | some line =>
      let value := trimSpaces (((line.splitOn ":").drop 1).headD "")
      if value ≠ expectedAccept key then
        throw <| .userError s!"LeanCDP.WebSocket.connect: Sec-WebSocket-Accept mismatch, got {value}"
      return c

end LeanCDP.WebSocket
