/-
`LeanCDP.Transport`: a thin, dependency-free wrapper over the raw async
TCP sockets Lean 4 already ships (`Std.Async.TCP`, backed by libuv via
`Std.Internal.UV`). No FFI of our own, no external package -- this is
all reachable from a plain `lean_lib` with no `require` line, because
it is already part of the toolchain.

This is the bottom layer of a pure-Lean Chrome DevTools Protocol (CDP)
client. CDP is JSON-RPC carried over a WebSocket; a WebSocket is a
framed protocol carried over a plain TCP connection, after an HTTP
Upgrade handshake. This module provides exactly that last, plain-TCP
piece -- connect, send bytes, receive bytes -- and nothing CDP- or
WebSocket-specific. See the project README for the layers still to be
built on top of it.
-/

import Std.Async.TCP
import Std.Internal.UV.TCP
import Std.Net.Addr

namespace LeanCDP

open Std.Net Std.Async

/--
An open TCP connection to some remote host. Opaque wrapper around the
underlying `Std.Async.TCP.Socket.Client` so callers of this module
never have to know libuv is involved.
-/
structure Connection where
  private mk ::
  client : TCP.Socket.Client

/--
Resolve a numeric IPv4 literal (e.g. `"127.0.0.1"`) and connect to it
on `port`. Does not do DNS -- hostnames need a resolver on top of this
(`Std.Async.DNS` already ships one; wiring it in is future work, see
README).
-/
def connect (host : String) (port : UInt16) : Async Connection := do
  let some ipv4 := IPv4Addr.ofString host
    | throw <| .userError s!"LeanCDP.Transport.connect: not an IPv4 literal: {host}"
  let addr := SocketAddress.v4 { addr := ipv4, port := port }
  let client ← TCP.Socket.Client.mk
  client.connect addr
  return ⟨client⟩

/--
Write `data` to the connection, blocking until the kernel has accepted
all of it.
-/
def Connection.send (c : Connection) (data : ByteArray) : Async Unit :=
  c.client.send data

/--
Read up to `size` bytes. `none` means the peer closed the connection
(end of stream); `some bytes` can be a short read -- callers that need
"exactly N bytes" or "until some delimiter" must loop and accumulate,
same as any other raw socket API.
-/
def Connection.recv? (c : Connection) (size : UInt64 := 65536) : Async (Option ByteArray) :=
  c.client.recv? size

/--
Read until the peer closes the connection, accumulating every chunk.
Convenient for simple request/response probes (see `Main.lean`); a
real WebSocket layer will want `recv?` directly so it can frame as
bytes arrive instead of waiting for EOF.
-/
partial def Connection.recvAll (c : Connection) : Async ByteArray := do
  let rec loop (acc : ByteArray) : Async ByteArray := do
    match ← c.recv? with
    | some chunk => loop (acc ++ chunk)
    | none => return acc
  loop .empty

/--
Shut down the write side of the connection (half-close). The peer will
see EOF on its next read.
-/
def Connection.close (c : Connection) : Async Unit :=
  c.client.shutdown

end LeanCDP
