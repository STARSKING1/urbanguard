#!/usr/bin/env bash
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

exec python3 -c '
import http.server
import socketserver
import sqlite3
import json
import os

PORT = 8080

class HazardAPIHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        hazards = []
        if os.path.exists("hazards.db"):
            try:
                conn = sqlite3.connect("hazards.db")
                cursor = conn.cursor()
                cursor.execute("SELECT id, description, severity, latitude, longitude FROM hazards")
                rows = cursor.fetchall()
                for r in rows:
                    hazards.append({
                        "id": str(r[0]),
                        "title": str(r[1]),
                        "category": str(r[2]),
                        "latitude": float(r[3]),
                        "longitude": float(r[4])
                    })
                conn.close()
            except Exception:
                pass
        
        if not hazards:
            hazards = [{
                "id": "h1",
                "title": "Flash Flood Warning",
                "category": "Flood",
                "latitude": 12.9716,
                "longitude": 77.5946
            }]
            
        body = json.dumps(hazards).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        return

class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

with ReusableTCPServer(("0.0.0.0", PORT), HazardAPIHandler) as httpd:
    httpd.serve_forever()
'
