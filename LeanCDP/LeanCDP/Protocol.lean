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

`Client` dispatches by a single background reader task (`pump`,
spawned once in `connect`) rather than having `call` read the socket
itself: a request's `id` is matched against an `IO.Promise` registered
for it in `pending`, and anything with no `id` at all (an event) is
queued in `events` instead. That one design covers two things a
read-inside-`call` design structurally cannot: several `call`s
outstanding at once (their responses can arrive in any order --
`pending` resolves each by `id` regardless), and events arriving with
*no* call outstanding at all (there is always something reading the
socket, call in flight or not).
-/

import LeanCDP.WebSocket
import Lean.Data.Json
import Std.Data.HashMap
import Std.Async.Timer

namespace LeanCDP.Protocol

open Lean Std.Async LeanCDP.WebSocket

/-- One parsed CDP message. -/
inductive Message where
  /-- A successful response to request `id`. -/
  | result (id : Nat) (value : Json)
  /-- A failed response to request `id`. -/
  | error (id : Nat) (code : Int) (message : String)
  /-- An unprompted event/notification -- no request `id` of ours to match.
  `sessionId?` is which target's session it belongs to, in flat mode
  (`Target.attachToTarget {flatten: true}`, as `LeanCDP.Page` always uses);
  `none` for a browser-wide event. -/
  | event (method : String) (sessionId? : Option String) (params : Json)
  deriving Inhabited

/-- Classify one incoming JSON value by which of the three CDP shapes it has. -/
def Message.parse (j : Json) : Except String Message := do
  match j.getObjValD "id" with
  | .null =>
    let method ← (j.getObjVal? "method") >>= Json.getStr?
    let sessionId? := ((j.getObjValD "sessionId").getStr?).toOption
    return .event method sessionId? (j.getObjValD "params")
  | idJson =>
    let id ← idJson.getNat?
    match j.getObjValD "error" with
    | .null => return .result id (j.getObjValD "result")
    | errJson =>
      let code := ((errJson.getObjValD "code").getInt?).toOption.getD 0
      let msg := ((errJson.getObjValD "message").getStr?).toOption.getD ""
      return .error id code msg

/--
An open CDP session: a handshaken WebSocket connection, a request-id
counter, a table of in-flight calls awaiting their response
(`pending`, keyed by request `id`), and a FIFO of events that have
arrived but not yet been collected (`events`). A single background
task (`pump`, started by `connect`) is the only thing that ever reads
`ws` -- everything else reaches the connection through `pending`/
`events`.
-/
structure Client where
  private mk ::
  ws : WebSocket.Connection
  private nextId : IO.Ref Nat
  private pending : IO.Ref (Std.HashMap Nat (IO.Promise (Except String Json)))
  private events : IO.Ref (Array (String × Option String × Json))

/-- Resolve the promise for `id`, if `call`/`callWith` is still waiting on it, and forget it either way. -/
private def Client.resolvePending (c : Client) (id : Nat) (result : Except String Json) : Async Unit := do
  match (← c.pending.get).get? id with
  | some promise =>
    IO.Promise.resolve result promise
    c.pending.modify (·.erase id)
  | none => pure ()  -- no one is (or ever was) waiting on this id; nothing to do

/--
The sole reader of `c.ws`, for the lifetime of the connection: reads
one message at a time, dispatches a `result`/`error` to the matching
`pending` promise (if any -- a response to an `id` nobody is waiting
on, e.g. after its `call` already gave up, is simply dropped), and
appends an `event` to the queue. On disconnect, resolves every still-
pending promise to an error instead of leaving `call`s blocked
forever on a promise that was never going to be resolved otherwise.
-/
private partial def pump (c : Client) : Async Unit := do
  let rec loop : Async Unit := do
    match ← c.ws.recvMessage with
    | none =>
      for (_, promise) in (← c.pending.get).toList do
        IO.Promise.resolve (Except.error "connection closed") promise
      c.pending.set {}
    | some (_, payload) =>
      match Json.parse (String.fromUTF8! payload) with
      | .error _ => loop  -- not JSON at all; ignore and keep reading
      | .ok j =>
        match Message.parse j with
        | .error _ => loop  -- JSON, but none of the three CDP shapes; ignore
        | .ok (.event method sessionId? params) => c.events.modify (·.push (method, sessionId?, params)); loop
        | .ok (.result id value) => c.resolvePending id (.ok value); loop
        | .ok (.error id code msg) => c.resolvePending id (.error s!"CDP error {code}: {msg}"); loop
  loop

/-- Connect and perform the WebSocket handshake at the given CDP WebSocket URL path (e.g. the
`webSocketDebuggerUrl` path `LeanCDP.Discovery` reads back from Chromium's `/json/version`). -/
def connect (host : String) (port : UInt16) (path : String) : Async Client := do
  let ws ← WebSocket.connect host port path
  let c : Client := ⟨ws, ← IO.mkRef 1, ← IO.mkRef {}, ← IO.mkRef #[]⟩
  discard <| (pump c).asTask
  return c

/--
Call any CDP method and return its `result` payload, raw. `sessionId?`
addresses the call to a specific target's session (CDP's "flat" mode,
set up via `Target.attachToTarget {flatten: true}`) rather than the
browser-wide connection -- needed for most of `Page`/`Runtime`/`DOM`,
which operate on one target, not the whole browser. Request ids are
unique across the *connection*, session-scoped or not, so `pump`
correlating a response by `id` alone needs no session-awareness of
its own.

Multiple `callWith`/`call`/`callSession` calls may be in flight at
once -- each gets its own `id` and its own promise in `pending`, and
`pump` resolves whichever one a response's `id` names, in whatever
order responses actually arrive. Throws on a CDP error response, or
if the connection closes (any outstanding promise included) before
one arrives.
-/
def Client.callWith (c : Client) (sessionId? : Option String) (method : String)
    (params : Json := Json.mkObj []) : Async Json := do
  let id ← c.nextId.modifyGet (fun n => (n, n + 1))
  let promise ← IO.Promise.new
  c.pending.modify (·.insert id promise)
  let fields := [("id", Json.num id), ("method", Json.str method), ("params", params)] ++
    (match sessionId? with
      | some sid => [("sessionId", Json.str sid)]
      | none => [])
  c.ws.sendText (Json.mkObj fields).compress
  match ← MonadAwait.await promise with
  | .ok value => return value
  | .error e => throw <| .userError s!"LeanCDP.Protocol.Client.call: {e}"

/-- Call a browser-wide CDP method (`Target`, `Browser`, ...) -- no session. -/
def Client.call (c : Client) (method : String) (params : Json := Json.mkObj []) : Async Json :=
  c.callWith none method params

/-- Call a CDP method scoped to one target's session (see `callWith`). -/
def Client.callSession (c : Client) (sessionId : String) (method : String)
    (params : Json := Json.mkObj []) : Async Json :=
  c.callWith (some sessionId) method params

/--
Pop and return the oldest queued event (`{"method","params"}` with no
`id`, e.g. `Network.responseReceived`, plus which target's session it
belongs to, `none` for a browser-wide event) if one has arrived since
the last `pollEvent`/`nextEvent`. Never blocks -- `none` just means
nothing is queued *right now*.
-/
def Client.pollEvent (c : Client) : Async (Option (String × Option String × Json)) := do
  let arr ← c.events.get
  if arr.isEmpty then return none
  else
    c.events.set (arr.extract 1 arr.size)
    return some arr[0]!

/--
Block until at least one event has arrived, then pop and return it.
Implemented by polling `pollEvent` every `pollDelayMs` -- `pump`
already separates events from responses as they arrive, so there is
no socket read to block on here, only the queue to check again.
-/
partial def Client.nextEvent (c : Client) (pollDelayMs : Std.Time.Millisecond.Offset := 50) :
    Async (String × Option String × Json) := do
  match ← c.pollEvent with
  | some ev => return ev
  | none => Std.Async.sleep pollDelayMs; c.nextEvent pollDelayMs

/--
Pop and return the oldest queued event matching `pred method sessionId?
params`, leaving every other queued event (including ones *before* it
in arrival order) in place for whoever else might want them. Never
blocks -- `none` means nothing matching is queued *right now*, not
that nothing is queued at all. The one-shared-queue design `pollEvent`
uses doesn't by itself support more than one consumer with different
interests; this is what makes that workable (see
`Page.Session.waitForLoad`, which only wants *its own* target's
`Page.loadEventFired` and must leave every other event -- another
target's, or a different method entirely -- for someone else).
-/
def Client.pollEventMatching (c : Client) (pred : String → Option String → Json → Bool) :
    Async (Option (String × Option String × Json)) := do
  let arr ← c.events.get
  match arr.findIdx? (fun (m, sid, p) => pred m sid p) with
  | some idx =>
    let ev := arr[idx]!
    c.events.set (arr.eraseIdx! idx)
    return some ev
  | none => return none

/-- Block (by polling, same as `nextEvent`) until an event matching `pred` arrives. -/
partial def Client.nextEventMatching (c : Client) (pred : String → Option String → Json → Bool)
    (pollDelayMs : Std.Time.Millisecond.Offset := 50) : Async (String × Option String × Json) := do
  match ← c.pollEventMatching pred with
  | some ev => return ev
  | none => Std.Async.sleep pollDelayMs; c.nextEventMatching pred pollDelayMs

/-- Discard every *currently queued* event matching `pred`, without blocking
(stops the moment `pollEventMatching` finds nothing left to match). Useful
right before an action that's about to trigger a fresh instance of an event
this client already has a stale queued copy of -- see `Page.Session.navigate`. -/
partial def Client.drainEventsMatching (c : Client) (pred : String → Option String → Json → Bool) :
    Async Unit := do
  match ← c.pollEventMatching pred with
  | some _ => c.drainEventsMatching pred
  | none => return ()

/-- Close the underlying WebSocket connection. `pump` sees the resulting EOF and resolves
(with an error) any call left waiting on a response that will now never arrive. -/
def Client.close (c : Client) : Async Unit := c.ws.close

end LeanCDP.Protocol
