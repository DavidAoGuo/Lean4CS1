#!/usr/bin/env python3
"""GraphFold local UI server (Python 3 standard library only, no packages).

Static HTML/JS is served at 127.0.0.1:8787 by default. POST /api/run writes
a temporary graph file and invokes the actual Lean executable. No graph
algorithm is reimplemented in Python.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

PROJECT_ROOT = Path(__file__).resolve().parent.parent
PUBLIC_ROOT = PROJECT_ROOT / "web" / "public"
MAX_BODY = 256 * 1024
TIMEOUT_SECONDS = 20
MODES = ("shortest", "paths", "optimal")
FILES = {
    "/": ("index.html", "text/html; charset=utf-8"),
    "/app.js": ("app.js", "text/javascript; charset=utf-8"),
    "/style.css": ("style.css", "text/css; charset=utf-8"),
}
JSON_HEADERS = {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
    "X-Content-Type-Options": "nosniff",
}
SECURITY_HEADERS = {
    "X-Content-Type-Options": "nosniff",
    "Referrer-Policy": "no-referrer",
    "Content-Security-Policy": (
        "default-src 'self'; script-src 'self'; style-src 'self'; "
        "img-src 'self' data:; object-src 'none'; base-uri 'none'; "
        "frame-ancestors 'none'"
    ),
}


class ProcessStartError(RuntimeError):
    """The executable could not be started at all (missing, not executable)."""


def request_input(body):
    """Validate request shape, not graph semantics: the Lean parser owns those."""
    if not isinstance(body, dict):
        raise ValueError("Expected a JSON object")
    mode = body.get("mode")
    if mode not in MODES:
        raise ValueError('mode must be "shortest", "paths", or "optimal"')
    graph = body.get("graph")
    if not isinstance(graph, str) or len(graph.encode("utf-8", "replace")) > MAX_BODY:
        raise ValueError("graph must be a UTF-8 string of at most 256 KiB")
    return {"mode": mode, "graph": graph}


def run_process(command, args, cwd=PROJECT_ROOT):
    """Run a process without a shell; collect bounded stdout/stderr."""
    try:
        child = subprocess.Popen(
            [command, *args],
            cwd=cwd,
            shell=False,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except OSError as error:
        raise ProcessStartError(f"Could not start {command}: {error.strerror or error}") from error

    output = {"stdout": bytearray(), "stderr": bytearray()}
    overflow = threading.Event()
    lock = threading.Lock()

    def drain(stream, name):
        # Stop the child as soon as its combined output passes the limit,
        # rather than buffering an unbounded result and checking afterwards.
        for chunk in iter(lambda: stream.read1(8192), b""):
            with lock:
                output[name] += chunk
                total = len(output["stdout"]) + len(output["stderr"])
            if total > MAX_BODY:
                overflow.set()
                child.kill()
                break
        stream.close()

    readers = [
        threading.Thread(target=drain, args=(child.stdout, "stdout"), daemon=True),
        threading.Thread(target=drain, args=(child.stderr, "stderr"), daemon=True),
    ]
    for reader in readers:
        reader.start()
    try:
        child.wait(timeout=TIMEOUT_SECONDS)
    except subprocess.TimeoutExpired:
        child.kill()
        child.wait()
        for reader in readers:
            reader.join()
        raise RuntimeError("Lean executable timed out") from None
    for reader in readers:
        reader.join()
    if overflow.is_set():
        raise RuntimeError("Lean output exceeded 256 KiB")
    return {
        "code": child.returncode,
        "stdout": output["stdout"].decode("utf-8", "replace").strip(),
        "stderr": output["stderr"].decode("utf-8", "replace").strip(),
    }


def lean_runner(mode, graph_file, trace=False):
    """Prefer already-built Lake binaries; they are produced by `lake build`."""
    command = "trace" if trace else mode
    args = [mode, str(graph_file)] if trace else [str(graph_file)]
    binary = PROJECT_ROOT / ".lake" / "build" / "bin" / command
    try:
        return run_process(str(binary), args)
    except ProcessStartError:
        return run_process("lake", ["exe", command, *args])


class GraphFoldHandler(BaseHTTPRequestHandler):
    """HTTP boundary. The `runner` attribute is injectable so tests need no Lean."""

    runner = staticmethod(lean_runner)

    def log_request(self, code="-", size="-"):
        # Keep the terminal quiet during normal use; errors are still logged.
        pass

    def send_json(self, status, value):
        payload = json.dumps(value).encode("utf-8")
        self.send_response(status)
        for name, header in {**SECURITY_HEADERS, **JSON_HEADERS}.items():
            self.send_header(name, header)
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_GET(self):
        try:
            path = urlsplit(self.path).path
            if path in FILES:
                file_name, content_type = FILES[path]
                contents = (PUBLIC_ROOT / file_name).read_bytes()
                self.send_response(200)
                for name, header in SECURITY_HEADERS.items():
                    self.send_header(name, header)
                self.send_header("Content-Type", content_type)
                # no-store, not no-cache: these files are edited while a page
                # is open, and `no-cache` only asks the browser to revalidate.
                # With no ETag to revalidate against, a browser or an
                # intermediary such as the VS Code port-forwarding proxy can
                # keep serving a stale script, so an edit appears to have had
                # no effect. Refusing storage entirely is correct for a local
                # teaching server and costs nothing at this scale.
                self.send_header("Cache-Control", "no-store")
                self.send_header("Content-Length", str(len(contents)))
                self.end_headers()
                self.wfile.write(contents)
            elif path == "/api/health":
                self.send_json(200, {"status": "ok"})
            else:
                self.send_json(404, {"error": "Not found"})
        except Exception as error:  # noqa: BLE001 - report, never crash the server
            self.send_json(500, {"error": str(error) or "Internal server error"})

    def do_POST(self):
        try:
            path = urlsplit(self.path).path
            if path not in ("/api/run", "/api/trace"):
                self.send_json(404, {"error": "Not found"})
                return
            try:
                length = int(self.headers.get("Content-Length", "0"))
            except ValueError:
                self.send_json(400, {"error": "Malformed Content-Length"})
                return
            if length > MAX_BODY + 2048:
                self.send_json(413, {"error": "Request too large"})
                return
            try:
                body = json.loads(self.rfile.read(length).decode("utf-8"))
            except (UnicodeDecodeError, json.JSONDecodeError):
                self.send_json(400, {"error": "Malformed JSON"})
                return
            try:
                request = request_input(body)
            except ValueError as error:
                self.send_json(400, {"error": str(error)})
                return
            with tempfile.TemporaryDirectory(prefix="graphfold-") as directory:
                graph_file = Path(directory) / "input.txt"
                graph_file.write_text(request["graph"], encoding="utf-8", errors="replace")
                result = self.runner(request["mode"], str(graph_file), path == "/api/trace")
            if result["code"] != 0:
                message = result["stderr"] or result["stdout"] or f"Process exited with code {result['code']}"
                self.send_json(422, {"error": message})
            else:
                self.send_json(200, {"mode": request["mode"], "output": result["stdout"]})
        except Exception as error:  # noqa: BLE001 - report, never crash the server
            self.send_json(500, {"error": str(error) or "Internal server error"})


def create_app(runner=lean_runner, host="127.0.0.1", port=0):
    """Independent injectable runner makes the HTTP boundary testable without Lean."""
    handler = type("GraphFoldHandler", (GraphFoldHandler,), {"runner": staticmethod(runner)})
    return ThreadingHTTPServer((host, port), handler)


def main():
    host = os.environ.get("HOST", "127.0.0.1")
    try:
        port = int(os.environ.get("PORT", "8787"))
    except ValueError:
        port = -1
    if not 0 <= port <= 65535:
        sys.stderr.write("PORT must be an integer between 0 and 65535\n")
        return 1
    server = create_app(host=host, port=port)
    try:
        print(f"GraphFold UI: http://{host}:{server.server_address[1]}")
        print("Use Ctrl+C to stop. Build Lean binaries with: lake build", flush=True)
        server.serve_forever()
    except KeyboardInterrupt:
        print()
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
