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

/-- Create a fresh blank tab and attach to it in flat session mode. -/
def openBlank (client : Client) : Async Session := do
  let created ← client.call "Target.createTarget" (Json.mkObj [("url", Json.str "about:blank")])
  let some targetId := (created.getObjValD "targetId").getStr?.toOption
    | throw <| .userError "LeanCDP.Page.openBlank: Target.createTarget returned no targetId"
  let attached ← client.call "Target.attachToTarget"
    (Json.mkObj [("targetId", Json.str targetId), ("flatten", Json.bool true)])
  let some sessionId := (attached.getObjValD "sessionId").getStr?.toOption
    | throw <| .userError "LeanCDP.Page.openBlank: Target.attachToTarget returned no sessionId"
  return ⟨client, targetId, sessionId⟩

/-- Navigate this page to `url`. Returns once Chromium has *accepted* the
navigation, not once the page has *finished loading* -- see `waitForLoad`. -/
def Session.navigate (s : Session) (url : String) : Async Unit :=
  discard <| s.client.callSession s.sessionId "Page.navigate" (Json.mkObj [("url", Json.str url)])

/--
Poll `document.readyState` via `Runtime.evaluate` until it reports
`"complete"`, up to `maxAttempts` times, `delayMs` apart. A polling
loop rather than subscribing to `Page.loadEventFired` because
`Protocol.Client` has no event mechanism (see the project README) --
every CDP round trip here is a request this client makes and waits on,
never a notification Chromium pushes. Throws if the page never
reaches `"complete"` in time.
-/
partial def Session.waitForLoad (s : Session) (maxAttempts : Nat := 25)
    (delayMs : Std.Time.Millisecond.Offset := 200) : Async Unit := do
  let rec loop (attemptsLeft : Nat) : Async Unit := do
    let result ← s.client.callSession s.sessionId "Runtime.evaluate"
      (Json.mkObj [("expression", Json.str "document.readyState"), ("returnByValue", Json.bool true)])
    let state := ((result.getObjValD "result").getObjValD "value").getStr?.toOption.getD ""
    if state == "complete" then
      return ()
    else if attemptsLeft == 0 then
      throw <| .userError s!"LeanCDP.Page.Session.waitForLoad: still \"{state}\" after the wait budget"
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
