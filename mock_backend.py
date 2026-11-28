"""Mock Spring Boot backend cho app_music - phục vụ kiểm thử UC 8.x.

Chạy:  python mock_backend.py
Listen: 0.0.0.0:8080  (Android emulator truy cập qua 10.0.2.2:8080)

Endpoints:
  POST /api/auth/register  {email, password, displayName} -> {token, user}
  POST /api/auth/login     {email, password}               -> {token, user}
  POST /api/auth/google    {idToken}                       -> {token, user}
  PUT  /api/auth/profile   {displayName, photoUrl}         -> {user}
  GET  /api/health                                          -> {status}
"""
import json
import threading
import time
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

USERS = {}          # email -> {password, displayName, photoUrl, uuid}
TOKENS = {}         # token -> email
LOCK = threading.Lock()


def issue_token(email):
    token = "mock-jwt-" + uuid.uuid4().hex
    TOKENS[token] = email
    return token


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):
        print("[mock] " + fmt % args, flush=True)

    def _read_json(self):
        length = int(self.headers.get("Content-Length") or 0)
        if not length:
            return {}
        try:
            return json.loads(self.rfile.read(length).decode("utf-8"))
        except Exception:
            return {}

    def _send(self, code, payload):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _authed_email(self):
        header = self.headers.get("Authorization") or ""
        if header.startswith("Bearer "):
            return TOKENS.get(header[7:].strip())
        return None

    def do_GET(self):
        if self.path.startswith("/api/health"):
            self._send(200, {"status": "UP", "users": len(USERS)})
        else:
            self._send(404, {"message": "Not found"})

    def do_POST(self):
        body = self._read_json()
        path = self.path.split("?")[0]

        if path == "/api/auth/register":
            email = (body.get("email") or "").strip().lower()
            password = body.get("password") or ""
            displayName = (body.get("displayName") or email.split("@")[0]).strip()
            if not email or "@" not in email:
                return self._send(400, {"message": "Email không hợp lệ"})
            if len(password) < 6:
                return self._send(400, {"message": "Mật khẩu phải có ít nhất 6 ký tự"})
            with LOCK:
                if email in USERS:
                    return self._send(409, {"message": "Email đã được đăng ký"})
                USERS[email] = {
                    "password": password,
                    "displayName": displayName,
                    "photoUrl": None,
                    "uuid": str(uuid.uuid4()),
                }
            token = issue_token(email)
            return self._send(200, {"token": token, "user": _user_payload(email)})

        if path == "/api/auth/login":
            email = (body.get("email") or "").strip().lower()
            password = body.get("password") or ""
            with LOCK:
                user = USERS.get(email)
            if user is None or user["password"] != password:
                return self._send(401, {"message": "Sai email hoặc mật khẩu"})
            token = issue_token(email)
            return self._send(200, {"token": token, "user": _user_payload(email)})

        if path == "/api/auth/google":
            id_token = body.get("idToken") or ""
            if not id_token:
                return self._send(400, {"message": "Thiếu Google idToken"})
            email = "google.user@gmail.com"
            with LOCK:
                if email not in USERS:
                    USERS[email] = {
                        "password": uuid.uuid4().hex,
                        "displayName": "Google User",
                        "photoUrl": None,
                        "uuid": str(uuid.uuid4()),
                    }
            token = issue_token(email)
            return self._send(200, {"token": token, "user": _user_payload(email)})

        self._send(404, {"message": "Not found"})

    def do_PUT(self):
        body = self._read_json()
        path = self.path.split("?")[0]
        if path == "/api/auth/profile":
            email = self._authed_email()
            if email is None:
                return self._send(401, {"message": "Chưa đăng nhập"})
            with LOCK:
                user = USERS.get(email)
                if user is None:
                    return self._send(404, {"message": "Không tìm thấy user"})
                if body.get("displayName") is not None:
                    user["displayName"] = body["displayName"]
                if body.get("photoUrl") is not None:
                    user["photoUrl"] = body["photoUrl"]
            return self._send(200, {"user": _user_payload(email)})
        self._send(404, {"message": "Not found"})


def _user_payload(email):
    user = USERS[email]
    return {
        "email": email,
        "displayName": user["displayName"],
        "photoUrl": user["photoUrl"],
        "uuid": user["uuid"],
    }


if __name__ == "__main__":
    server = ThreadingHTTPServer(("0.0.0.0", 8080), Handler)
    print("[mock] backend mock dang listen tren 0.0.0.0:8080", flush=True)
    server.serve_forever()
