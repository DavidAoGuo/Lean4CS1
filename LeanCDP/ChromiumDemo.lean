/-
`leancdp-chromium-demo`: the integration test none of the mocks in
`LeanCDP.Testing.Mocks` can stand in for -- an actual Chromium.

Not part of `leancdp-test` (and not run by default anywhere) because
most environments running this package won't have a Chromium to
point it at. Where one is available:

```sh
chromium --headless --no-sandbox --disable-gpu \
  --remote-debugging-port=9222 --remote-debugging-address=127.0.0.1 \
  --user-data-dir=/tmp/leancdp-chromium-demo about:blank &
lake exe leancdp-chromium-demo
```

(`--no-sandbox` is needed only because container environments
typically lack the user-namespace permissions Chromium's sandbox
wants; drop it outside a container.)

This is also the integration test that found two real bugs no mock
could have:

1. `Discovery.fetchJson` originally read the HTTP response by waiting
   for the peer to close the connection, which worked against every
   mock server in `Tests.lean` (each of which does close immediately)
   and then hung forever the first time this ran against a real
   Chromium -- whose debugging HTTP server keeps the connection alive
   regardless of the client's `Connection: close` header. Fixed by
   reading the body by `Content-Length` instead; see
   `LeanCDP/Discovery.lean`.
2. `LeanCDP.Page` (the `Target.createTarget`/`attachToTarget`/
   `Page.navigate`/`Page.captureScreenshot` choreography) has no mock
   to test against at all -- a fake WebSocket peer could echo back
   *something* JSON-shaped for `Page.captureScreenshot`, but "is this
   actually a PNG of actually-rendered content" is a question only an
   actual rendering engine can answer. The checks below (PNG magic
   bytes, a non-trivial size) are the closest thing to a correctness
   check available without a human looking at the file -- which is
   also sitting there afterward, for a human to look at.
-/

import LeanCDP

open LeanCDP Std.Async Lean

def main (args : List String) : IO Unit := do
  let port : UInt16 := match args with
    | [p] => p.toNat!.toUInt16
    | _ => 9222
  let (host, wsPort, path) ← (Discovery.discoverBrowserWebSocket "127.0.0.1" port).block
  IO.println s!"discovered: ws://{host}:{wsPort}{path}"
  let client ← (Protocol.connect host wsPort path).block

  let version ← (client.call "Browser.getVersion").block
  IO.println s!"Browser.getVersion -> {version.compress}"
  let targets ← (client.call "Target.getTargets").block
  IO.println s!"Target.getTargets  -> {targets.compress}"

  let page ← (Page.openBlank client).block
  IO.println s!"opened page target {page.targetId}, session {page.sessionId}"
  let js :=
    "document.body.style.background='#003366';" ++
    "document.body.style.color='white';" ++
    "document.body.style.fontFamily='sans-serif';" ++
    "document.body.style.padding='40px';" ++
    "document.body.innerHTML='<h1>LeanCDP</h1>" ++
    "<p>Rendered and photographed by pure Lean 4 code.</p>';"
  discard <| (client.callSession page.sessionId "Runtime.evaluate" (Json.mkObj [("expression", Json.str js)])).block
  let png ← (page.screenshot).block
  let pngSig : ByteArray := [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A].toByteArray
  let isPng := png.size ≥ 8 && png.extract 0 8 == pngSig
  if isPng && png.size > 1000 then
    IO.println s!"Page.captureScreenshot -> {png.size} bytes, valid PNG signature"
  else
    throw <| IO.userError s!"screenshot failed validation: {png.size} bytes, PNG sig {isPng}"
  IO.FS.writeBinFile "chromium-demo-screenshot.png" png
  IO.println "wrote chromium-demo-screenshot.png"
  (page.close).block

  (client.close).block
  IO.Process.exit 0
