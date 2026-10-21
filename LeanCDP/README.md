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
the toolchain itself, no `require` needed. That means the entire
transport layer a CDP client needs (open a TCP connection, send
bytes, receive bytes) is reachable from a plain `lean_lib` today.
Nothing here is a wrapper around Node, Python, or any existing
Playwright/Puppeteer installation; `LeanCDP` talks straight to a
browser's debugging port itself.

## Status

- **`LeanCDP.Transport`** — done. A thin wrapper over
  `Std.Async.TCP.Socket.Client`: `connect host port`, `.send`,
  `.recv?`, `.recvAll`, `.close`. Proven working end-to-end: see
  `Main.lean`, the `leancdp-probe` executable, which does a real raw
  HTTP/1.1 GET over it.
- **WebSocket (RFC 6455)** — not started. CDP rides on a WebSocket,
  which needs: the HTTP `Upgrade` handshake (computing
  `Sec-WebSocket-Accept` requires SHA-1 and Base64, neither of which
  ships in `Std` — both need implementing from scratch, the way the
  community `leanws` package already has), then frame
  encode/decode (masking, opcodes, fragmentation).
- **CDP JSON-RPC envelope** — not started. Once frames flow, CDP
  itself is just `{"id", "method", "params"}` requests and
  `{"id", "result"}` / `{"method", "params"}` (event) responses.
  Needs a JSON library (Lean 4 ships `Lean.Json` in the compiler's
  own `Lean` library, usable without pulling in Mathlib) and typed
  wrappers for the handful of CDP domains worth covering first
  (`Target`, `Page`, `Runtime`).
- **Discovery** — Chromium run with `--remote-debugging-port=<p>`
  exposes its WebSocket URL over plain HTTP at
  `GET /json/version` on that port. `leancdp-probe` already fetches
  arbitrary paths/ports, so pointing it at a live Chromium's
  `/json/version` is the natural first integration test once the
  WebSocket layer exists — nothing in this sandbox currently has a
  Chromium binary to test that against.

## Building and running the smoke test

```sh
cd LeanCDP
lake build
lake exe leancdp-probe <host> <port> [path]   # host must be a bare IPv4 literal
```

With nothing else running, point it at anything speaking HTTP on
localhost, e.g. this repo's own `mdbook` output once served
(`python3 -m http.server <port>` from `book/`):

```sh
lake exe leancdp-probe 127.0.0.1 8111 /index.html
```
