/-
The CDP wire format itself: JSON-RPC-*shaped*, but not JSON-RPC 2.0
(no `"jsonrpc":"2.0"` envelope field, and no fixed error-code
vocabulary) -- that's why this doesn't reach for Lean's own
`Lean.JsonRpc.Message` (built for the LSP, which really is strict
JSON-RPC 2.0). CDP messages come in exactly three shapes:

- a request *we* send: `{"id", "method", "params"}`
- a successful response: `{"id", "result"}`
- a failed response: `{"id", "error": {"code", "message"}}`
- an event, which Chromium sends unprompted: `{"method", "params"}`,
  with no `"id"` at all.

This module is deliberately generic at the protocol level rather than
typed per CDP domain: `Client.call "Page.navigate" params` works for
any of CDP's hundreds of methods across dozens of domains, because
hand-writing typed wrappers for all of them is a separate, much
longer project than finishing the transport. Lean's own `Lean.Json`
(bundled with the compiler, no extra `require`) does the encoding and
decoding.
-/

import LeanCDP.WebSocket
import Lean.Data.Json

namespace LeanCDP.Protocol

open Lean Std.Async LeanCDP.WebSocket

/-- One parsed CDP message. -/
inductive Message where
  /-- A successful response to request `id`. -/
  | result (id : Nat) (value : Json)
  /-- A failed response to request `id`. -/
  | error (id : Nat) (code : Int) (message : String)
  /-- An unprompted event/notification -- no request `id` of ours to match. -/
  | event (method : String) (params : Json)
  deriving Inhabited

/-- Classify one incoming JSON value by which of the three CDP shapes it has. -/
def Message.parse (j : Json) : Except String Message := do
  match j.getObjValD "id" with
  | .null =>
    let method ← (j.getObjVal? "method") >>= Json.getStr?
    return .event method (j.getObjValD "params")
  | idJson =>
    let id ← idJson.getNat?
    match j.getObjValD "error" with
    | .null => return .result id (j.getObjValD "result")
    | errJson =>
      let code := ((errJson.getObjValD "code").getInt?).toOption.getD 0
      let msg := ((errJson.getObjValD "message").getStr?).toOption.getD ""
      return .error id code msg

/-- An open CDP session: a handshaken WebSocket connection, plus the
request-id counter every outgoing call needs. -/
structure Client where
  private mk ::
  ws : WebSocket.Connection
  private nextId : IO.Ref Nat

/-- Connect and perform the WebSocket handshake at the given CDP WebSocket URL path (e.g. the
`webSocketDebuggerUrl` path `LeanCDP.Discovery` reads back from Chromium's `/json/version`). -/
def connect (host : String) (port : UInt16) (path : String) : Async Client := do
  let ws ← WebSocket.connect host port path
  let nextId ← IO.mkRef 1
  return ⟨ws, nextId⟩

/--
Call any CDP method and return its `result` payload, raw. `sessionId?`
addresses the call to a specific target's session (CDP's "flat" mode,
set up via `Target.attachToTarget {flatten: true}`) rather than the
browser-wide connection -- needed for most of `Page`/`Runtime`/`DOM`,
which operate on one target, not the whole browser. Request ids are
unique across the *connection*, session-scoped or not, so correlating
a response by `id` alone (see `loop` below) needs no session-awareness
of its own.

Loops past events (silently dropped -- this client has no subscriber
mechanism, see README) and past responses to any *other* in-flight
call (there shouldn't be one, since this client only ever has one
`call` in flight at a time, but a real server is free to interleave
anyway). Throws on a CDP error response, or if the connection closes
first.
-/
partial def Client.callWith (c : Client) (sessionId? : Option String) (method : String)
    (params : Json := Json.mkObj []) : Async Json := do
  let id ← c.nextId.modifyGet (fun n => (n, n + 1))
  let fields := [("id", Json.num id), ("method", Json.str method), ("params", params)] ++
    (match sessionId? with
      | some sid => [("sessionId", Json.str sid)]
      | none => [])
  let request := Json.mkObj fields
  c.ws.sendText request.compress
  let rec loop : Async Json := do
    match ← c.ws.recvMessage with
    | none => throw <| .userError s!"LeanCDP.Protocol.Client.call: connection closed awaiting {method}"
    | some (_, payload) =>
      match Json.parse (String.fromUTF8! payload) with
      | .error e => throw <| .userError s!"LeanCDP.Protocol.Client.call: malformed JSON from peer: {e}"
      | .ok j =>
        match Message.parse j with
        | .error e => throw <| .userError s!"LeanCDP.Protocol.Client.call: malformed CDP message: {e}"
        | .ok (.result rid value) => if rid == id then return value else loop
        | .ok (.error rid code msg) =>
          if rid == id then throw <| .userError s!"LeanCDP.Protocol.Client.call: CDP error {code}: {msg}"
          else loop
        | .ok (.event ..) => loop
  loop

/-- Call a browser-wide CDP method (`Target`, `Browser`, ...) -- no session. -/
def Client.call (c : Client) (method : String) (params : Json := Json.mkObj []) : Async Json :=
  c.callWith none method params

/-- Call a CDP method scoped to one target's session (see `callWith`). -/
def Client.callSession (c : Client) (sessionId : String) (method : String)
    (params : Json := Json.mkObj []) : Async Json :=
  c.callWith (some sessionId) method params

/-- Close the underlying WebSocket connection. -/
def Client.close (c : Client) : Async Unit := c.ws.close

end LeanCDP.Protocol
