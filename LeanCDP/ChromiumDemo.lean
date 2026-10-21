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

This is also the integration test that found a real bug:
`Discovery.fetchJson` originally read the HTTP response by waiting
for the peer to close the connection, which worked against every mock
server in `Tests.lean` (each of which does close immediately) and
then hung forever the first time this ran against a real Chromium --
whose debugging HTTP server keeps the connection alive regardless of
the client's `Connection: close` header. Fixed by reading the body by
`Content-Length` instead; see `LeanCDP/Discovery.lean`.
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
  (client.close).block
  IO.Process.exit 0
