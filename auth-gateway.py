#!/usr/bin/env python3
"""Auth gateway — single entry point with branded login for MiMo-Code.

Sits on :8080, proxies to ttyd (:7681).
Reads PASSWORD env var; if empty, skips auth entirely.
"""

import os
import hmac
import hashlib
import http.server
import http.client
import urllib.parse
import socket
import select
import threading

PASSWORD = os.environ.get("PASSWORD", "")
SECRET = hmac.new(b"mimo-gateway", PASSWORD.encode(), hashlib.sha256).hexdigest()
COOKIE_NAME = "mimo_session"
LOGIN_PAGE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "login.html")

BACKENDS = {
    "/terminal/": ("127.0.0.1", 7681, False),
}

PROXY_HOP_HEADERS = frozenset([
    "connection", "keep-alive", "proxy-authenticate",
    "proxy-authorization", "te", "trailers",
    "transfer-encoding",
])


def make_token():
    return hmac.new(SECRET.encode(), b"authenticated", hashlib.sha256).hexdigest()


def check_token(token):
    return hmac.compare_digest(token, make_token())


def parse_cookies(cookie_header):
    cookies = {}
    if cookie_header:
        for item in cookie_header.split(";"):
            if "=" in item:
                k, v = item.strip().split("=", 1)
                cookies[k.strip()] = v.strip()
    return cookies


def relay_sockets(a, b):
    """Bidirectional byte relay between two sockets until one closes."""
    try:
        while True:
            readable, _, errored = select.select([a, b], [], [a, b], 30)
            if errored:
                break
            for s in readable:
                data = s.recv(65536)
                if not data:
                    return
                dst = b if s is a else a
                dst.sendall(data)
    except Exception:
        pass
    finally:
        for s in (a, b):
            try:
                s.close()
            except Exception:
                pass


class GatewayHandler(http.server.BaseHTTPRequestHandler):

    def log_message(self, format, *args):  # noqa: A002
        pass

    def is_authenticated(self):
        if not PASSWORD:
            return True
        cookies = parse_cookies(self.headers.get("Cookie", ""))
        return check_token(cookies.get(COOKIE_NAME, ""))

    # ---------- route dispatch ----------

    def route(self, method):
        path = self.path

        if path == "/healthz":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"ok")
            return

        if method == "GET" and path == "/logout":
            self.send_response(302)
            self.send_header("Set-Cookie", f"{COOKIE_NAME}=; Path=/; Max-Age=0")
            self.send_header("Location", "/")
            self.end_headers()
            return

        if method == "GET" and path in ("/", ""):
            if self.is_authenticated():
                self.send_response(302)
                self.send_header("Location", "/terminal/")
                self.end_headers()
                return
            self._serve_login_page()
            return

        if method == "POST" and path == "/login":
            self._handle_login()
            return

        # Proxy routes
        for prefix, (host, port, strip) in BACKENDS.items():
            if path.startswith(prefix) or path == prefix.rstrip("/"):
                if not self.is_authenticated():
                    self.send_response(302)
                    self.send_header("Location", "/")
                    self.end_headers()
                    return

                upgrade = (self.headers.get("Upgrade") or "").lower()
                if upgrade == "websocket":
                    self._handle_websocket(host, port, prefix, strip)
                else:
                    self._proxy_http(method, host, port, prefix, strip)
                return

        # Fallback
        self.send_response(302)
        self.send_header("Location", "/")
        self.end_headers()

    do_GET = lambda self: self.route("GET")
    do_POST = lambda self: self.route("POST")
    do_PUT = lambda self: self.route("PUT")
    do_DELETE = lambda self: self.route("DELETE")
    do_PATCH = lambda self: self.route("PATCH")
    do_OPTIONS = lambda self: self.route("OPTIONS")
    do_HEAD = lambda self: self.route("HEAD")

    # ---------- login ----------

    def _serve_login_page(self, error=False):
        try:
            with open(LOGIN_PAGE, "rb") as f:
                page = f.read()
        except FileNotFoundError:
            self.send_error(500, "login.html not found")
            return
        if error:
            page = page.replace(
                b"<!--ERROR-->",
                '<div class="error">Неверный пароль</div>'.encode("utf-8"),
            )
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(page)))
        self.end_headers()
        self.wfile.write(page)

    def _handle_login(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length).decode()
        params = urllib.parse.parse_qs(body)
        pwd = params.get("password", [""])[0]
        if pwd == PASSWORD:
            token = make_token()
            self.send_response(302)
            self.send_header(
                "Set-Cookie",
                f"{COOKIE_NAME}={token}; Path=/; HttpOnly; SameSite=Lax",
            )
            self.send_header("Location", "/terminal/")
            self.end_headers()
        else:
            self._serve_login_page(error=True)

    # ---------- HTTP proxy ----------

    def _proxy_http(self, method, host, port, prefix, strip=True):
        if strip:
            backend_path = self.path[len(prefix) - 1:] or "/"
        else:
            backend_path = self.path

        try:
            conn = http.client.HTTPConnection(host, port, timeout=60)
            headers = {}
            for key in self.headers:
                if key.lower() not in PROXY_HOP_HEADERS:
                    headers[key] = self.headers[key]
            headers["Host"] = f"{host}:{port}"
            headers["X-Forwarded-For"] = self.client_address[0]
            headers["X-Forwarded-Proto"] = "http"
            headers["X-Forwarded-Host"] = self.headers.get("Host", "")

            body = None
            cl = self.headers.get("Content-Length")
            if cl:
                body = self.rfile.read(int(cl))

            conn.request(method, backend_path, body=body, headers=headers)
            resp = conn.getresponse()

            self.send_response(resp.status)
            for key, val in resp.getheaders():
                if key.lower() in PROXY_HOP_HEADERS:
                    continue
                if key.lower() == "location" and strip:
                    val = self._rewrite_location(val, prefix)
                self.send_header(key, val)
            self.end_headers()

            while True:
                chunk = resp.read(65536)
                if not chunk:
                    break
                self.wfile.write(chunk)
            conn.close()

        except Exception as exc:
            self.send_error(502, f"Backend unavailable: {exc}")

    def _rewrite_location(self, location, prefix):
        if location.startswith("/"):
            return prefix.rstrip("/") + location
        return location

    # ---------- WebSocket proxy ----------

    def _handle_websocket(self, host, port, prefix, strip=True):
        if strip:
            backend_path = self.path[len(prefix) - 1:] or "/"
        else:
            backend_path = self.path

        try:
            backend = socket.create_connection((host, port), timeout=10)

            lines = [f"{self.command} {backend_path} {self.request_version}"]
            for key in self.headers:
                if key.lower() not in PROXY_HOP_HEADERS or key.lower() in ("connection", "upgrade"):
                    lines.append(f"{key}: {self.headers[key]}")
            lines.append(f"Host: {host}:{port}")
            lines.append(f"X-Forwarded-For: {self.client_address[0]}")
            raw = "\r\n".join(lines) + "\r\n\r\n"
            backend.sendall(raw.encode())

            client_sock = self.request
            relay_sockets(client_sock, backend)

        except Exception:
            try:
                self.send_error(502, "WebSocket backend unavailable")
            except Exception:
                pass


class ThreadedHTTPServer(http.server.HTTPServer):
    allow_reuse_address = True

    def process_request(self, request, client_address):
        t = threading.Thread(target=self.process_request_thread, args=(request, client_address))
        t.daemon = True
        t.start()

    def process_request_thread(self, request, client_address):
        try:
            self.finish_request(request, client_address)
        except Exception:
            self.handle_error(request, client_address)
        finally:
            self.shutdown_request(request)


def main():
    addr = ("0.0.0.0", 8080)
    server = ThreadedHTTPServer(addr, GatewayHandler)
    mode = "open (no password)" if not PASSWORD else "password-protected"
    print(f"MiMo-Code auth gateway on :8080  [{mode}]", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down.")
        server.server_close()


if __name__ == "__main__":
    main()
