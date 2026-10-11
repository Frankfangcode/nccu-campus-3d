"""Local preview, bound to this machine only. No upload or deployment."""
import http.server, pathlib, functools, sys, urllib.request, webbrowser
root=pathlib.Path(__file__).resolve().parents[1]/'build/web'
class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map={**http.server.SimpleHTTPRequestHandler.extensions_map,'.wasm':'application/wasm','.pck':'application/octet-stream'}
    def do_GET(self):
        if self.path=='/__campus_health':
            self.send_response(200);self.end_headers();self.wfile.write(b'NCCU_GODOT_PREVIEW');return
        super().do_GET()
    def end_headers(self):
        self.send_header('Cache-Control','no-cache')
        super().end_headers()
url='http://127.0.0.1:8790'
try:
    server=http.server.ThreadingHTTPServer(('127.0.0.1',8790),functools.partial(Handler,directory=str(root)))
except OSError:
    with urllib.request.urlopen(url+'/__campus_health',timeout=2) as response:
        if response.read()!=b'NCCU_GODOT_PREVIEW':raise RuntimeError('Port 8790 belongs to a different service.')
    if '--open' in sys.argv:webbrowser.open(url)
    print('Preview is already running: '+url)
else:
    print('NCCU Godot preview: '+url,flush=True)
    if '--open' in sys.argv:webbrowser.open(url)
    server.serve_forever()
