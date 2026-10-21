# LeanCDP

A from-scratch, pure-Lean 4 client for the Chrome DevTools Protocol
(CDP) — the JSON-RPC-over-WebSocket protocol that tools like
Playwright and Puppeteer use to drive a real browser.

This is its own Lake package, separate from the `fp-course` package
at the repo root. It isn't course material and doesn't need
Mathlib, so it gets its own `lakefile.lean` and `lean-toolchain`
rather than living inside `FPCourse`.

## Why pure Lean, no FFI

Lean 4's bundled `Std` library already ships real async networking —
`Std.Async.TCP`, backed by libuv via `Std.Internal.UV` — as part of
the toolchain itself, no `require` needed. Lean's compiler library
also ships its own JSON implementation, `Lean.Data.Json` (built for
the LSP, equally usable here). Between the two, everything a CDP
client needs down to raw sockets is already reachable from a plain
`lean_lib`. Nothing here wraps Node, Python, or an existing
Playwright/Puppeteer install; `LeanCDP` talks straight to a browser's
debugging port itself. The two pieces neither ships — SHA-1 and
base64, both needed for the WebSocket handshake — are implemented
from scratch in `LeanCDP.Codec`.

## Layers

| Module | What it does | Status |
|---|---|---|
| `LeanCDP.Transport` | Raw async TCP (`connect`/`send`/`recv?`/`close` over `Std.Async.TCP`) plus `Buffered`, the shared "read exactly N bytes / until this delimiter" layer `WebSocket` and `Discovery` both build on. | done |
| `LeanCDP.Codec.Base64` | RFC 4648 base64 encode/decode. | done, against the RFC's own test vectors |
| `LeanCDP.Codec.SHA1` | FIPS 180-1 SHA-1. | done, against the FIPS vectors |
| `LeanCDP.WebSocket` | RFC 6455: handshake, masking, length encoding, fragment reassembly, `Ping`/`Pong`. | done, see below |
| `LeanCDP.Protocol` | The CDP JSON-RPC envelope and a generic `Client.call method params`. | done, see below |
| `LeanCDP.Discovery` | Reads Chromium's `GET /json/version` and parses its `webSocketDebuggerUrl`. | done, confirmed against a real Chromium (see below) |
| `LeanCDP.Page` | `Target.createTarget`/`attachToTarget` + `Page.navigate`/`captureScreenshot` choreography, plus a `Runtime.evaluate`-polling `waitForLoad` (`Protocol.Client` has no event subscriber to wait on `Page.loadEventFired` with). | done, confirmed against a real Chromium (see below) |

Each layer only depends on the one below it: `Transport` knows
nothing about WebSockets; `WebSocket` knows nothing about CDP or
JSON; `Protocol` knows nothing about how the WebSocket URL was found.

## Verifying it actually works, not just that it compiles

`LeanCDP.Testing.Mocks` provides three small, *independently written*
mock servers (deliberately not sharing code with the client — the
point is to cross-check two separate implementations of the same wire
format) and `Tests.lean` drives the real client against each of them
over actual loopback TCP:

- a WebSocket echo server, exercising the handshake, message
  fragmentation in both directions, the 126-length payload encoding
  in both directions, and unsolicited-`Ping` → automatic-`Pong`;
- a plain HTTP server returning a canned `/json/version`-shaped body,
  exercising `Discovery.fetchJson`/`version`/`discoverBrowserWebSocket`;
- a fake CDP peer that echoes back `{"id","method","params"}` as
  `{"id","result"}`, exercising `Protocol.Client.call`'s request-id
  round trip.

Plus pure-function vectors for SHA-1 (FIPS 180-1), base64 (RFC 4648),
and the exact worked handshake example from RFC 6455 §1.3.

```sh
cd LeanCDP
lake build
lake exe leancdp-test
```

All 15 checks pass as of this writing, reliably (checked with
repeated runs, both via `lake exe` and the built binary directly).

Getting there took one real concurrency bug worth recording:
`Async`'s `concurrently` guarantees both sides of a pair eventually
run, but not that the server side's `listen` happens before the
client side's `connect` -- racing those directly was an *intermittent*
hang (nothing listening yet when the client's `connect` fired, and
loopback TCP's retry-before-giving-up window is much longer than
you'd want a test to wait). The fix (see `Testing.Mocks.listenOn`) is
to bind-and-listen *first*, synchronously, and only hand the
already-listening socket into the concurrent pair -- not something
`concurrently`'s own contract was ever going to save us from.

`main` in `Tests.lean` also calls `IO.Process.exit` explicitly rather
than falling through normally, since `Std.Async.TCP.Socket.Server`
exposes no `close` in this version of `Std` -- the listening sockets
from all three mock servers stay open (and, presumably, so does
whatever libuv machinery backs them) for the rest of the process's
life otherwise.

### Also confirmed against a real Chromium

`lake exe leancdp-chromium-demo` (see `ChromiumDemo.lean`) runs the
whole stack -- `Discovery` → `Protocol.connect` → `Client.call` --
against an actual headless Chromium, not a mock:

```sh
chromium --headless --no-sandbox --disable-gpu \
  --remote-debugging-port=9222 --remote-debugging-address=127.0.0.1 \
  --user-data-dir=/tmp/leancdp-chromium-demo about:blank &
lake exe leancdp-chromium-demo
```

`Browser.getVersion` and `Target.getTargets` both come back correctly
decoded, real browser data (the real `Chrome/…` version string, real
target ids); so does an actual round trip through `LeanCDP.Page`:
create a tab, run JavaScript in it via `Runtime.evaluate` to paint
some content, and `Page.captureScreenshot` it back — checked for a
valid PNG signature and a non-trivial size, then written to
`chromium-demo-screenshot.png` so a human can also just look at it.
No mock could stand in for this part: a fake WebSocket peer can echo
back *something* JSON-shaped for `captureScreenshot`, but "is this
actually a PNG of actually-rendered content" is a question only an
actual rendering engine can answer.

This is also what found two real bugs `Tests.lean`'s mocks couldn't:

1. `Discovery.fetchJson` originally read the HTTP response by waiting
   for the peer to close the connection, which every mock server
   obligingly does and a real Chromium does not -- its debugging HTTP
   server keeps the connection alive regardless of the client's
   `Connection: close` header, so the naive version hung forever on
   the very first real request. Fixed by reading the body by
   `Content-Length` instead (`LeanCDP.Transport.Buffered`, shared with
   `WebSocket`, now backs both).
2. CDP's `Page`/`Runtime` methods don't work on the raw browser-wide
   connection at all -- they need a target attached in "flat" session
   mode first, then every call tagged with that session's id. Missing
   entirely until `Protocol.Client.callWith`/`callSession` and
   `LeanCDP.Page` were added; there was no way the browser-level-only
   mock test would ever have surfaced that gap.

## Using it for real

```sh
cd LeanCDP
lake exe leancdp-screenshot <url> [outfile] [cdp-host] [cdp-port]
# e.g.
lake exe leancdp-screenshot http://127.0.0.1:8111/index.html shot.png
```

(`leancdp-screenshot`, see `Screenshot.lean`, needs a Chromium already
listening the same way `leancdp-chromium-demo` does, above.) It's a
thin wrapper over `LeanCDP.Page`: `Discovery.discoverBrowserWebSocket`
to find the browser, `Protocol.connect`, `Page.openBlank`, `.navigate`,
`.waitForLoad`, `.screenshot`, write the bytes, `.close`. See
`ChromiumDemo.lean` for the same pieces used more thoroughly (plus
`Runtime.evaluate`), and `LeanCDP/Page.lean` for what each step does.
Everything in `LeanCDP` runs in the `Async` monad; a plain
`IO`-returning `main` reaches it via `.block` (`(someAsyncAction).block
: IO α`), same as every example in this repo does.

`leancdp-probe` (see `Main.lean`) is a smaller, lower-level smoke test
of just the `Transport` layer — a raw HTTP GET — kept around from
when that was all there was:

```sh
lake exe leancdp-probe <ipv4-host> <port> [path]
```

## Known gaps

- **No `permessage-deflate`** or any other WebSocket extension.
- **No 64-bit WebSocket frame lengths.** `WebSocket`'s encoder and
  decoder both implement the spec's three length encodings (7-bit,
  16-bit, 64-bit), but the test suite only exercises the first two —
  hitting the 64-bit path needs a payload over 64KB, which nothing
  here currently sends.
- **No UTF-8 validation** of incoming text-frame payloads (RFC 6455
  requires closing the connection on invalid UTF-8; this just hands
  back the raw bytes).
- **`Protocol.Client` has no event/notification subscriber.** CDP
  events (`{"method","params"}` with no `id`) are parsed correctly by
  `Message.parse` but silently dropped by `Client.call`'s receive
  loop — there's no way for a caller to be told about one.
  `Page.Session.waitForLoad` works around exactly this by *polling*
  `Runtime.evaluate "document.readyState"` instead of subscribing to
  `Page.loadEventFired`; fine for that, not fine for anything that
  needs to react to, say, `Network.responseReceived` as it happens.
- **One request in flight at a time.** `Client.call` blocks until its
  own response arrives; there's no concurrent-call support.
- **`Transport.connect` takes only numeric IPv4 literals**, no
  hostnames. `Std.Async.DNS` already ships a resolver; wiring it in
  is future work, not a hard problem.
