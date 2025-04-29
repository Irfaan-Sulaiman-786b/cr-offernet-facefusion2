#!/usr/bin/env python3

import os
import sys
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler

os.environ['OMP_NUM_THREADS'] = '1'

from facefusion import core

running = False

class FaceFusionHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        global running

        if self.path == '/run':
            if not running:
                running = True
                threading.Thread(target=self.start_facefusion).start()
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b"Starting FaceFusion...\n")
            else:
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b"FaceFusion is already running\n")
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"Not Found\n")

    def start_facefusion(self):
        global running
        try:
            # Set the sys.argv so core.cli() thinks it's called like:
            sys.argv = ['facefusion', 'run', '--host', '0.0.0.0', '--port', os.environ.get('PORT', '8080')]
            core.cli()
        finally:
            running = False

def run_server():
    server_address = ('0.0.0.0', 8080)
    httpd = HTTPServer(server_address, FaceFusionHandler)
    print("Listening on 0.0.0.0:8080...")
    httpd.serve_forever()

if __name__ == '__main__':
    run_server()
