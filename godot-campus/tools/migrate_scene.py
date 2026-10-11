"""Run the original game locally and export its actual meshes and story data."""
from pathlib import Path
import sys,json,threading,http.server,functools
ROOT=Path(__file__).resolve().parents[1];WORKSPACE=ROOT.parents[1]
sys.path.insert(0,str(WORKSPACE/'.preview-tools'))
from playwright.sync_api import sync_playwright
class Handler(http.server.SimpleHTTPRequestHandler):
    def do_POST(self):
        name=self.path.rsplit('/',1)[-1]
        if name not in ['campus.glb','police.glb','pangolin.glb','campus.json']:
            self.send_error(403);return
        directory=ROOT/('assets/data' if name.endswith('.json') else 'assets/models')
        directory.mkdir(parents=True,exist_ok=True)
        data=self.rfile.read(int(self.headers['Content-Length']))
        (directory/name).write_bytes(data);self.send_response(200);self.end_headers();self.wfile.write(b'OK')
        print(name,len(data),flush=True)
server=http.server.ThreadingHTTPServer(('127.0.0.1',8766),functools.partial(Handler,directory=str(ROOT.parent)))
threading.Thread(target=server.serve_forever,daemon=True).start()
source=(ROOT.parent/'nccu100playplay/index.html').read_text(encoding='utf-8')
source=source.replace('loop();\n})();', '''window.migration={scene,OUT,sky,clouds,grass,player,NPCS,pang,police,driveCar,crystals,colliders,IX,RIV,TRK,GYM,ZH,FZ,LOTS,groundH};
})();''')
with sync_playwright() as p:
    browser=p.chromium.launch(executable_path='C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless=True,args=['--enable-webgl','--ignore-gpu-blocklist'])
    page=browser.new_page();page.route('**/nccu100playplay/',lambda r:r.fulfill(body=source,content_type='text/html; charset=utf-8'))
    page.on('pageerror',lambda e:print('JS ERROR',e,flush=True))
    page.goto('http://127.0.0.1:8766/nccu100playplay/',wait_until='networkidle',timeout=90000)
    page.wait_for_function('window.migration!==undefined')
    script=(ROOT/'tools/export_scene.js').read_text(encoding='utf-8')
    if '--props-only' in sys.argv:
        script=script.replace("await saveGLB('campus.glb',campus);",'')
        script=script.replace("await fetch('/save/campus.json',{method:'POST',body:JSON.stringify(data)});",'')
    print(page.evaluate(script),flush=True)
    browser.close()
server.shutdown()
