"""HTTP-layer tests for the GraphFold local UI server.

A fake runner stands in for the Lean executables, so no Lean toolchain is
needed. From the GraphFold project root:

    python3 -m unittest discover -s web/test
"""
import json
import sys
import threading
import unittest
import urllib.error
import urllib.request
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import server  # noqa: E402

FIXTURE = (server.PROJECT_ROOT / "examples" / "diamond.txt").read_text(encoding="utf-8")
OUTPUTS = {
    "shortest": "0: 0\n1: 2\n2: 5\n3: 3",
    "paths": "0: 1\n1: 1\n2: 2\n3: 3",
    "optimal": "0: min=0,count=1\n1: min=2,count=1\n2: min=5,count=2\n3: min=3,count=1",
}


def fixture_runner(mode, path, trace=False):
    graph = Path(path).read_text(encoding="utf-8")
    assert "vertices 4" in graph
    return {"code": 0, "stdout": OUTPUTS[mode], "stderr": ""}


class Served:
    """Run an app on a background thread for the duration of a `with` block."""

    def __init__(self, runner):
        self.app = server.create_app(runner=runner)
        self.base = "http://127.0.0.1:%d" % self.app.server_address[1]
        self.thread = threading.Thread(target=self.app.serve_forever, daemon=True)

    def __enter__(self):
        self.thread.start()
        return self

    def __exit__(self, *exc):
        self.app.shutdown()
        self.app.server_close()
        self.thread.join()

    def get(self, path):
        return self._send(urllib.request.Request(self.base + path))

    def post(self, path, body, raw=None):
        data = raw if raw is not None else json.dumps(body).encode("utf-8")
        request = urllib.request.Request(
            self.base + path, data=data, method="POST",
            headers={"Content-Type": "application/json"},
        )
        return self._send(request)

    @staticmethod
    def _send(request):
        try:
            with urllib.request.urlopen(request) as response:
                return response.status, response.read()
        except urllib.error.HTTPError as error:
            with error:
                return error.code, error.read()


class HttpBoundary(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.served = Served(fixture_runner).__enter__()

    @classmethod
    def tearDownClass(cls):
        cls.served.__exit__(None, None, None)

    def test_ui_serves_editor_visualization_and_three_buttons(self):
        status, html = self.served.get("/")
        self.assertEqual(status, 200)
        page = html.decode("utf-8")
        for text in ["graph-text", "graph-svg", "run-shortest", "run-paths", "run-optimal", "result-output"]:
            self.assertIn(text, page)
        self.assertEqual(self.served.get("/app.js")[0], 200)
        self.assertEqual(self.served.get("/style.css")[0], 200)

    def test_health_check(self):
        status, body = self.served.get("/api/health")
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(body), {"status": "ok"})

    def test_unknown_paths_are_json_404s(self):
        status, body = self.served.get("/missing")
        self.assertEqual(status, 404)
        self.assertEqual(json.loads(body), {"error": "Not found"})
        self.assertEqual(self.served.post("/api/other", {"mode": "paths", "graph": FIXTURE})[0], 404)

    def test_all_three_modes_send_graph_files_to_runner(self):
        for mode in server.MODES:
            status, body = self.served.post("/api/run", {"mode": mode, "graph": FIXTURE})
            self.assertEqual(status, 200)
            output = json.loads(body)["output"]
            self.assertIn("2: min=5,count=2" if mode == "optimal" else "3: 3", output)

    def test_rejects_unknown_modes_and_missing_graph(self):
        for body in [{"mode": "rm", "graph": FIXTURE}, {"mode": "paths"}]:
            self.assertEqual(self.served.post("/api/run", body)[0], 400)
        with self.assertRaises(ValueError):
            server.request_input({"mode": "shortest", "graph": 1})
        with self.assertRaises(ValueError):
            server.request_input(["shortest", FIXTURE])

    def test_rejects_malformed_json(self):
        status, body = self.served.post("/api/run", None, raw=b"{not json")
        self.assertEqual(status, 400)
        self.assertEqual(json.loads(body)["error"], "Malformed JSON")

    def test_rejects_oversized_requests(self):
        huge = {"mode": "paths", "graph": "x" * (server.MAX_BODY + 4096)}
        self.assertEqual(self.served.post("/api/run", huge)[0], 413)


class RunnerDelegation(unittest.TestCase):
    def test_propagates_lean_parser_errors(self):
        def broken(mode, path, trace=False):
            return {"code": 1, "stdout": "", "stderr": "error: expected FROM < TO"}

        with Served(broken) as served:
            status, body = served.post("/api/run", {"mode": "paths", "graph": FIXTURE})
            self.assertEqual(status, 422)
            self.assertIn("FROM < TO", json.loads(body)["error"])

    def test_trace_endpoint_delegates_to_distinct_lean_trace_executable(self):
        records = []

        def runner(mode, path, trace=False):
            records.append({"mode": mode, "graph": Path(path).read_text(encoding="utf-8"), "trace": trace})
            return {"code": 0, "stdout": "start|0|0\nfinish|0|0", "stderr": ""}

        with Served(runner) as served:
            for mode in server.MODES:
                status, body = served.post("/api/trace", {"mode": mode, "graph": FIXTURE})
                self.assertEqual(status, 200)
                self.assertEqual(json.loads(body)["output"], "start|0|0\nfinish|0|0")
        self.assertEqual(len(records), 3)
        self.assertTrue(all(r["trace"] is True and r["graph"] == FIXTURE for r in records))

    def test_temporary_graph_file_is_removed_after_the_run(self):
        seen = []

        def runner(mode, path, trace=False):
            seen.append(Path(path))
            return {"code": 0, "stdout": "", "stderr": ""}

        with Served(runner) as served:
            served.post("/api/run", {"mode": "paths", "graph": FIXTURE})
        self.assertEqual(len(seen), 1)
        self.assertFalse(seen[0].exists())

    def test_runner_exceptions_become_500_responses(self):
        def runner(mode, path, trace=False):
            raise server.ProcessStartError("Could not start lake: No such file or directory")

        with Served(runner) as served:
            status, body = served.post("/api/run", {"mode": "paths", "graph": FIXTURE})
            self.assertEqual(status, 500)
            self.assertIn("Could not start lake", json.loads(body)["error"])


class LeanRunner(unittest.TestCase):
    """The process layer, exercised with the Python interpreter standing in for Lean."""

    def test_collects_exit_code_and_trimmed_output(self):
        result = server.run_process(sys.executable, ["-c", "import sys; print('hi'); sys.stderr.write('warn\\n'); sys.exit(3)"])
        self.assertEqual(result, {"code": 3, "stdout": "hi", "stderr": "warn"})

    def test_missing_executable_is_a_start_error(self):
        with self.assertRaises(server.ProcessStartError):
            server.run_process("/nonexistent/graphfold-binary", [])

    def test_output_is_bounded(self):
        with self.assertRaisesRegex(RuntimeError, "exceeded"):
            server.run_process(sys.executable, ["-c", "import sys; sys.stdout.write('x' * 400000)"])

    def test_hung_executables_time_out(self):
        with mock.patch.object(server, "TIMEOUT_SECONDS", 0.5):
            with self.assertRaisesRegex(RuntimeError, "timed out"):
                server.run_process(sys.executable, ["-c", "import time; time.sleep(30)"])

    def test_falls_back_to_lake_exe_when_binary_is_missing(self):
        calls = []

        def fake_run(command, args, cwd=None):
            calls.append((command, list(args)))
            if command.endswith("trace"):
                raise server.ProcessStartError(f"Could not start {command}: No such file or directory")
            return {"code": 0, "stdout": "", "stderr": ""}

        with mock.patch.object(server, "run_process", fake_run):
            server.lean_runner("shortest", "/tmp/input.txt", trace=True)
            server.lean_runner("paths", "/tmp/input.txt")
        self.assertEqual(calls[0][0], str(server.PROJECT_ROOT / ".lake" / "build" / "bin" / "trace"))
        self.assertEqual(calls[1], ("lake", ["exe", "trace", "shortest", "/tmp/input.txt"]))
        self.assertEqual(calls[2][1], ["/tmp/input.txt"])
        self.assertEqual(calls[2][0], str(server.PROJECT_ROOT / ".lake" / "build" / "bin" / "paths"))


if __name__ == "__main__":
    unittest.main()
