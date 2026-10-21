/-
`leancdp-test`: the test suite proving `LeanCDP` actually works, not
just that it type-checks.

Pure vectors (FIPS 180-1 SHA-1, RFC 4648 base64, the RFC 6455 §1.3
worked handshake example, and `Discovery.parseWsUrl`) check the
non-networked pieces directly. The three live tests each spin up a
small, independently-written mock server from `LeanCDP.Testing.Mocks`
and drive the real `LeanCDP.Transport`/`WebSocket`/`Protocol`/
`Discovery` code against it over an actual loopback TCP connection:

- the WebSocket echo test covers the handshake, message fragmentation
  in both directions, the 126-length payload encoding in both
  directions, and unsolicited-`Ping` -> automatic-`Pong`;
- the HTTP/JSON test covers `Discovery.version`/`fetchJson` against a
  real (if fake-content) HTTP response;
- the CDP test covers `Protocol.Client.call`'s request-id round trip
  and JSON decoding end to end.

See `LeanCDP/README.md` for what's deliberately still out of scope (a
live Chromium, 64-bit WebSocket lengths, `permessage-deflate`, typed
per-domain CDP wrappers).
-/

import LeanCDP
import LeanCDP.Testing.Mocks

open LeanCDP LeanCDP.Codec LeanCDP.WebSocket Std.Async Lean

structure Check where
  name : String
  ok : Bool

def pureChecks : List Check := [
  ⟨"base64 encode: foobar", Base64.encode "foobar".toUTF8 == "Zm9vYmFy"⟩,
  ⟨"base64 encode: pad 1",  Base64.encode "fo".toUTF8 == "Zm8="⟩,
  ⟨"base64 encode: pad 2",  Base64.encode "f".toUTF8 == "Zg=="⟩,
  ⟨"base64 round-trip",     Base64.decode (Base64.encode "hello, CDP".toUTF8) == some "hello, CDP".toUTF8⟩,
  ⟨"base64 decode rejects garbage", Base64.decode "not valid!!" == none⟩,
  ⟨"sha1(\"\")",  SHA1.toHex (SHA1.digest "".toUTF8) == "da39a3ee5e6b4b0d3255bfef95601890afd80709"⟩,
  ⟨"sha1(\"abc\")", SHA1.toHex (SHA1.digest "abc".toUTF8) == "a9993e364706816aba3e25717850c26c9cd0d89d"⟩,
  ⟨"sha1 two-block vector",
    SHA1.toHex (SHA1.digest "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq".toUTF8)
      == "84983e441c3bd26ebaae4aa1f95129e5e54670f1"⟩,
  ⟨"RFC 6455 §1.3 worked handshake example",
    WebSocket.expectedAccept "dGhlIHNhbXBsZSBub25jZQ==" == "s3pPLMBiTxaQ9kYGzzhZRbK+xOo="⟩,
  ⟨"Discovery.parseWsUrl",
    Discovery.parseWsUrl "ws://127.0.0.1:9222/devtools/browser/abc-123"
      == some ("127.0.0.1", (9222 : UInt16), "/devtools/browser/abc-123")⟩
]

/-- Client side of the WebSocket echo test, against `Mocks.runEchoServerOnce`. -/
def websocketEchoClient (port : UInt16) : Async (List Check) := do
  let conn ← WebSocket.connect "127.0.0.1" port "/leancdp-test"
  conn.sendText "hello"
  let short ← conn.recvMessage
  let longMsg := String.join (List.replicate 300 "x")
  conn.sendText longMsg
  let long ← conn.recvMessage
  conn.close
  return [
    ⟨"handshake + short message fragmented across 2 frames and reassembled",
      short == some (.text, "hello".toUTF8)⟩,
    ⟨"long (300B, 126-length-encoded both ways) message fragmented and reassembled",
      long == some (.text, longMsg.toUTF8)⟩
  ]

def websocketEchoChecks : IO (List Check) := do
  let port : UInt16 := 19222
  let srv ← (Testing.listenOn port).block
  let (sawPong, clientChecks) ←
    ((Testing.runEchoServerOnce srv).concurrently (websocketEchoClient port)).block
  return clientChecks ++ [⟨"server observed the client's auto-Pong reply", sawPong⟩]

/-- Client side of the Discovery test, against `Mocks.runHttpJsonServerOnce`. -/
def discoveryClient (port wsPort : UInt16) : Async Check := do
  let (host, p, path) ← Discovery.discoverBrowserWebSocket "127.0.0.1" port
  return ⟨"Discovery.discoverBrowserWebSocket parses a /json/version response",
    host == "127.0.0.1" && p == wsPort && path == "/devtools/browser/mock-uuid"⟩

def discoveryChecks : IO (List Check) := do
  let port : UInt16 := 19223
  let wsPort : UInt16 := 19224
  let srv ← (Testing.listenOn port).block
  let (_, c) ← ((Testing.runHttpJsonServerOnce srv wsPort).concurrently (discoveryClient port wsPort)).block
  return [c]

/-- Client side of the CDP protocol test, against `Mocks.runCdpMockServerOnce`. -/
def cdpClient (port : UInt16) : Async Check := do
  let client ← Protocol.connect "127.0.0.1" port "/devtools/browser/mock-uuid"
  let result ← client.call "Target.mockMethod" (Json.mkObj [("x", Json.num 1)])
  client.close
  let expected := Json.mkObj [("echoedMethod", Json.str "Target.mockMethod"), ("params", Json.mkObj [("x", Json.num 1)])]
  return ⟨"Protocol.Client.call round-trips a request id and decodes the JSON result",
    result == expected⟩

def cdpChecks : IO (List Check) := do
  let port : UInt16 := 19225
  let srv ← (Testing.listenOn port).block
  let (_, c) ← ((Testing.runCdpMockServerOnce srv).concurrently (cdpClient port)).block
  return [c]

-- `main` exits via `IO.Process.exit` rather than `return`: the live checks leave
-- libuv TCP sockets and its background event-loop thread behind even once
-- every `Async` action involved has produced its result, which otherwise
-- leaves the process hanging after printing everything it has to say.
def main : IO Unit := do
  let live := (← websocketEchoChecks) ++ (← discoveryChecks) ++ (← cdpChecks)
  let all := pureChecks ++ live
  for c in all do
    let status := if c.ok then "ok  " else "FAIL"
    IO.println s!"{status} -- {c.name}"
  let failures := all.filter (fun c => !c.ok)
  if failures.isEmpty then
    IO.println s!"{all.length}/{all.length} checks passed"
    IO.Process.exit 0
  else
    IO.println s!"{failures.length}/{all.length} checks FAILED"
    IO.Process.exit 1
