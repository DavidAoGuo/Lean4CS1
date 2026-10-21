/-
Chromium run with `--remote-debugging-port=<p>` exposes its WebSocket
debugger URL over plain HTTP, at `GET /json/version` on that same
port -- no WebSocket involved yet, just JSON over HTTP/1.1. This
module fetches and parses that (`fetchJson`/`version`), and parses
the `ws://host:port/path` URL it hands back into the pieces
`WebSocket.connect`/`Protocol.connect` want (`parseWsUrl`).

Nothing in this sandbox has a Chromium binary to point this at, so
unlike `Transport`/`WebSocket`/`Protocol`, this module's HTTP/JSON
handling is tested here against a small mock HTTP server instead of
the real thing -- see `Tests.lean`.
-/

import LeanCDP.Transport
import Lean.Data.Json

namespace LeanCDP.Discovery

open Lean Std.Async LeanCDP

/-- `GET path` over a fresh connection to `host:port`, parsing the body as JSON. -/
def fetchJson (host : String) (port : UInt16) (path : String) : Async Json := do
  let conn ← Transport.connect host port
  let req := s!"GET {path} HTTP/1.1\r\nHost: {host}:{port}\r\nConnection: close\r\n\r\n"
  conn.send req.toUTF8
  let raw ← conn.recvAll
  match (String.fromUTF8! raw).splitOn "\r\n\r\n" with
  | _ :: body :: _ =>
    match Json.parse body with
    | .ok j => return j
    | .error e => throw <| .userError s!"LeanCDP.Discovery.fetchJson: {e}"
  | _ => throw <| .userError "LeanCDP.Discovery.fetchJson: malformed HTTP response (no blank line)"

/-- Chromium's own `GET /json/version` response: version strings plus the
*browser-level* `webSocketDebuggerUrl` (for per-tab targets, see `/json/list`
instead -- not wrapped here, but `fetchJson` handles either path identically). -/
def version (host : String) (port : UInt16) : Async Json :=
  fetchJson host port "/json/version"

/-- Parse `ws://host:port/path...` into the parts `WebSocket.connect` and
`Protocol.connect` take separately. `none` on anything else (`wss://` included --
CDP's own debugging endpoint is always plain `ws://`). -/
def parseWsUrl (url : String) : Option (String × UInt16 × String) := Id.run do
  if !(url.startsWith "ws://") then return none
  let rest := (url.drop 5).copy
  match rest.splitOn "/" with
  | authority :: pathParts =>
    match authority.splitOn ":" with
    | [host, portStr] =>
      match portStr.toNat? with
      | some p => return some (host, p.toUInt16, "/" ++ String.intercalate "/" pathParts)
      | none => return none
    | _ => return none
  | [] => return none

/-- `version host port`, then pull out and parse `webSocketDebuggerUrl`. This
is the one call site that ties `Discovery` to `WebSocket`/`Protocol`'s
`connect (host) (port) (path)` shape; everything above it is reusable on its
own (e.g. against `/json/list`, which this doesn't otherwise model). -/
def discoverBrowserWebSocket (host : String) (port : UInt16) : Async (String × UInt16 × String) := do
  let v ← version host port
  let some urlJson := (v.getObjVal? "webSocketDebuggerUrl").toOption
    | throw <| .userError "LeanCDP.Discovery: no webSocketDebuggerUrl in /json/version"
  let some url := urlJson.getStr?.toOption
    | throw <| .userError "LeanCDP.Discovery: webSocketDebuggerUrl was not a string"
  let some parts := parseWsUrl url
    | throw <| .userError s!"LeanCDP.Discovery: couldn't parse webSocketDebuggerUrl: {url}"
  return parts

end LeanCDP.Discovery
