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

| Module | What it does |
|---|---|
| `LeanCDP.Transport` | Async TCP: `connect` (numeric IPv4 literal, or any hostname via `Std.Async.DNS`), `send`/`recv?`/`close`, plus `Buffered` — "read exactly N bytes" / "read until this delimiter" — shared by `WebSocket` and `Discovery`. |
| `LeanCDP.Codec.Base64` | RFC 4648 base64 encode/decode. |
| `LeanCDP.Codec.SHA1` | FIPS 180-1 SHA-1. |
| `LeanCDP.WebSocket` | RFC 6455 client: handshake (refusing any server-selected extension it wasn't offered), mandatory client-side masking, all three payload-length encodings, fragment reassembly, automatic `Ping`→`Pong`, and UTF-8 validation of completed Text messages (closes with code 1007 on invalid UTF-8, per §8.1). |
| `LeanCDP.Protocol` | The CDP JSON-RPC envelope. A single background reader per `Client` dispatches responses to the matching call by request `id` (so any number of calls can be in flight at once) and queues anything with no `id` as an event, retrievable via `pollEvent`/`nextEvent`/the session-filtered `*Matching` variants. |
| `LeanCDP.Discovery` | Reads Chromium's `GET /json/version` and parses its `webSocketDebuggerUrl`. |
| `LeanCDP.Page` | `Target.createTarget`/`attachToTarget` + `Page.navigate`/`captureScreenshot`, and a `waitForLoad` that waits on a real `Page.loadEventFired` event scoped to its own session. |

Each layer only depends on the one below it: `Transport` knows
nothing about WebSockets; `WebSocket` knows nothing about CDP or
JSON; `Protocol` knows nothing about how the WebSocket URL was found.

## Verifying it actually works, not just that it compiles

`LeanCDP.Testing.Mocks` provides five small, *independently written*
mock servers (deliberately not sharing code with the client — the
point is to cross-check two separate implementations of the same wire
format) and `Tests.lean` drives the real client against each of them
over actual loopback TCP:

- a WebSocket echo server, exercising the handshake, message
  fragmentation in both directions, the 126-length *and*
  64-bit-length payload encodings in both directions, and
  unsolicited-`Ping` → automatic-`Pong`;
- a server that sends one deliberately-invalid-UTF-8 Text frame,
  exercising `WebSocket`'s rejection of it (closing with code 1007
  rather than handing the bytes back);
- a server whose handshake response selects `permessage-deflate`
  despite never being offered it, exercising `connect`'s refusal to
  complete that handshake at all;
- a plain HTTP server returning a canned `/json/version`-shaped body,
  exercising `Discovery.fetchJson`/`version`/`discoverBrowserWebSocket`
  *and*, reached a second time via the hostname `"localhost"` instead
  of a literal, `Transport.connect`'s DNS resolution path;
- a fake CDP peer that echoes back `{"id","method","params"}` as
  `{"id","result"}` (with an artificial delay for one method, `"Slow"`),
  exercising `Protocol.Client.call`'s request-id round trip, an event
  arriving with no call in flight (`nextEvent`), and two calls
  answered out of send order both resolving to the *correct* caller.

Plus pure-function vectors for SHA-1 (FIPS 180-1), base64 (RFC 4648),
and the exact worked handshake example from RFC 6455 §1.3.

```sh
cd LeanCDP
lake build
lake exe leancdp-test
```

All 22 checks pass, reliably, both via `lake exe` and the built
binary directly.

### Also confirmed against a real Chromium

`lake exe leancdp-chromium-demo` (see `ChromiumDemo.lean`) runs the
whole stack — `Discovery` → `Protocol.connect` → `Client.call` →
`LeanCDP.Page` — against an actual headless Chromium, not a mock:

```sh
chromium --headless --no-sandbox --disable-gpu \
  --remote-debugging-port=9222 --remote-debugging-address=127.0.0.1 \
  --user-data-dir=/tmp/leancdp-chromium-demo about:blank &
lake exe leancdp-chromium-demo
```

`Browser.getVersion` and `Target.getTargets` come back correctly
decoded, real browser data. `LeanCDP.Page` opens a tab, runs
JavaScript in it via `Runtime.evaluate` to paint some content, and
screenshots it back — checked for a valid PNG signature and a
non-trivial size, then written to `chromium-demo-screenshot.png` so a
human can also just look at it.

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

## Design notes worth knowing

- **No `permessage-deflate` or other WebSocket extensions, by
  design.** This client's handshake request never lists an extension
  in `Sec-WebSocket-Extensions`, and RFC 6455 §9.1 forbids a compliant
  server from selecting one the client didn't offer — so there is
  nothing to decompress in normal operation. `connect` additionally
  refuses outright if a server's handshake response names an
  extension anyway, rather than risk silently misreading compressed
  frames as raw bytes.
- **`Transport.Connection.close` is best-effort.** Closing an
  already-closed (or already-torn-down-by-the-peer) connection counts
  as success, not an error — closing the last target attached to a
  Chromium connection, for instance, can take the whole debugging
  socket down with it before this package's own `close` call runs.

## Known gaps

- **No typed per-CDP-domain API.** `Protocol.Client.call`/`callSession`
  are fully generic (`call "Page.navigate" params` works for any of
  CDP's hundreds of methods across dozens of domains); hand-writing
  typed request/response wrappers for them is a separate, much longer
  project than this one.
- **`LeanCDP.Page` covers one workflow.** Create a tab, navigate it,
  wait for load, screenshot it, run JavaScript in it, close it. Other
  CDP domains (`DOM`, `Network`, `Input`, ...) are reachable directly
  through `Protocol.Client.callSession` but have no dedicated wrapper
  of their own yet.
- **Never run against a real Firefox**, or any non-Chromium CDP
  target — only Chromium, which this client has been built and tested
  against throughout.
