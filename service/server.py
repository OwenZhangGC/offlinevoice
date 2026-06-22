"""Local SenseVoice ASR service for OfflineVoice.

Runs the SenseVoice model via sherpa-onnx (ONNX runtime, no PyTorch). The Swift
app POSTs raw little-endian float32 mono samples; we return the transcript.

Protocol:
    POST /transcribe?sr=16000   body = raw float32 LE samples (normalized -1..1)
    -> {"text": "..."}
    GET  /health -> {"ok": true, "model": "sense-voice"}
"""

import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse, parse_qs

import numpy as np
import sherpa_onnx

HERE = Path(__file__).resolve().parent
MODEL_DIR = HERE / "models" / "sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17"
PORT = 8765

_recognizer = None


def load_recognizer():
    global _recognizer
    if _recognizer is not None:
        return _recognizer
    model = MODEL_DIR / "model.int8.onnx"
    if not model.exists():
        model = MODEL_DIR / "model.onnx"
    tokens = MODEL_DIR / "tokens.txt"
    print(f"[sensevoice] loading {model.name} ...", flush=True)
    _recognizer = sherpa_onnx.OfflineRecognizer.from_sense_voice(
        model=str(model),
        tokens=str(tokens),
        num_threads=4,
        use_itn=True,           # inverse text normalization: punctuation + digits
        language="auto",        # zh / en / ja / ko / yue auto-detect
    )
    print("[sensevoice] ready", flush=True)
    return _recognizer


def transcribe(samples: np.ndarray, sample_rate: int) -> str:
    recognizer = load_recognizer()
    stream = recognizer.create_stream()
    stream.accept_waveform(sample_rate, samples)
    recognizer.decode_stream(stream)
    return stream.result.text.strip()


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass  # quiet

    def _send(self, code, obj):
        body = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if urlparse(self.path).path == "/health":
            self._send(200, {"ok": True, "model": "sense-voice"})
        else:
            self._send(404, {"error": "not found"})

    def do_POST(self):
        parsed = urlparse(self.path)
        if parsed.path != "/transcribe":
            self._send(404, {"error": "not found"})
            return
        try:
            sr = int(parse_qs(parsed.query).get("sr", ["16000"])[0])
            length = int(self.headers.get("Content-Length", 0))
            raw = self.rfile.read(length)
            samples = np.frombuffer(raw, dtype=np.float32)
            if samples.size == 0:
                self._send(200, {"text": ""})
                return
            text = transcribe(samples, sr)
            self._send(200, {"text": text})
        except Exception as exc:  # noqa: BLE001
            self._send(500, {"error": str(exc)})


def main():
    load_recognizer()  # warm up before accepting requests
    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    print(f"[sensevoice] listening on http://127.0.0.1:{PORT}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        sys.exit(0)


if __name__ == "__main__":
    main()
