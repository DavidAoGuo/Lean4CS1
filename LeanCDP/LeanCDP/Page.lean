/-
Convenience wrappers over `LeanCDP.Protocol.Client` for the one thing
almost every CDP use case needs first: a page to work with. `Page`,
`Runtime`, `DOM`, and most of the rest of CDP operate on one specific
*target* (a tab, roughly), reached by attaching to it in "flat" session
mode (`Target.attachToTarget {flatten: true}`) and tagging every
subsequent call with the `sessionId` that returns -- `Protocol`'s
`Client.callSession` already does the tagging; this module does the
attach/create/navigate/screenshot/close choreography around it so
callers don't have to re-derive it per target.
-/

import LeanCDP.Protocol
import Std.Async.Timer

namespace LeanCDP.Page

open Lean Std.Async LeanCDP.Protocol LeanCDP.Codec

/-- A CDP client attached to one specific page's session -- the level
`Page.navigate`/`Page.captureScreenshot`/`Runtime.evaluate` actually
operate at, as opposed to the browser-wide `Target`/`Browser` domains
`Client.call` reaches directly. -/
structure Session where
  private mk ::
  client : Client
  targetId : String
  sessionId : String

/-- Does `method`/`sessionId?` name *this* session's `Page.loadEventFired`? -/
private def Session.isOwnLoadEvent (s : Session) (method : String) (sessionId? : Option String)
    (_params : Json) : Bool :=
  method == "Page.loadEventFired" && sessionId? == some s.sessionId

/-- Create a fresh blank tab, attach to it in flat session mode, and enable the
`Page` domain so Chromium actually emits `Page.loadEventFired` for it (events
are forward-only from the moment of `Page.enable`, same as any CDP domain --
there is no replaying what the `about:blank` this starts on already did). -/
def openBlank (client : Client) : Async Session := do
  let created ← client.call "Target.createTarget" (Json.mkObj [("url", Json.str "about:blank")])
  let some targetId := (created.getObjValD "targetId").getStr?.toOption
    | throw <| .userError "LeanCDP.Page.openBlank: Target.createTarget returned no targetId"
  let attached ← client.call "Target.attachToTarget"
    (Json.mkObj [("targetId", Json.str targetId), ("flatten", Json.bool true)])
  let some sessionId := (attached.getObjValD "sessionId").getStr?.toOption
    | throw <| .userError "LeanCDP.Page.openBlank: Target.attachToTarget returned no sessionId"
  let s : Session := ⟨client, targetId, sessionId⟩
  discard <| client.callSession sessionId "Page.enable"
  return s

/--
Navigate this page to `url`. Returns once Chromium has *accepted* the
navigation, not once the page has *finished loading* -- see
`waitForLoad`. Also drains any `Page.loadEventFired` for this session
queued but not yet collected (there's at least a chance one is sitting
there from the `about:blank` this session started on, between
`Page.enable` and this call) -- otherwise a `waitForLoad` right after
this could match that *stale* event instead of the one this
navigation is actually going to fire.
-/
def Session.navigate (s : Session) (url : String) : Async Unit := do
  s.client.drainEventsMatching s.isOwnLoadEvent
  discard <| s.client.callSession s.sessionId "Page.navigate" (Json.mkObj [("url", Json.str url)])

/--
Wait for *this session's* `Page.loadEventFired`, up to `maxAttempts`
polls of the event queue, `delayMs` apart (`Protocol.Client`'s events
are queued by a background reader as they arrive -- see `pollEvent`
-- so this is polling the queue, not the network). Throws if it
doesn't arrive within the wait budget.
-/
partial def Session.waitForLoad (s : Session) (maxAttempts : Nat := 100)
    (delayMs : Std.Time.Millisecond.Offset := 100) : Async Unit := do
  let rec loop (attemptsLeft : Nat) : Async Unit := do
    match ← s.client.pollEventMatching s.isOwnLoadEvent with
    | some _ => return ()
    | none =>
      if attemptsLeft == 0 then
        throw <| .userError
          "LeanCDP.Page.Session.waitForLoad: Page.loadEventFired never arrived within the wait budget"
      else
        Std.Async.sleep delayMs
        loop (attemptsLeft - 1)
  loop maxAttempts

/-- Capture the current page as PNG bytes, decoded from CDP's base64 response. -/
def Session.screenshot (s : Session) : Async ByteArray := do
  let result ← s.client.callSession s.sessionId "Page.captureScreenshot"
  let some b64 := (result.getObjValD "data").getStr?.toOption
    | throw <| .userError "LeanCDP.Page.Session.screenshot: Page.captureScreenshot returned no data"
  let some bytes := Base64.decode b64
    | throw <| .userError "LeanCDP.Page.Session.screenshot: couldn't base64-decode the screenshot data"
  return bytes

/-- Close the tab this session is attached to. -/
def Session.close (s : Session) : Async Unit :=
  discard <| s.client.call "Target.closeTarget" (Json.mkObj [("targetId", Json.str s.targetId)])

end LeanCDP.Page
