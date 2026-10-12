"""以最新模組化網頁的靜態校園取代舊地圖，保留 Godot 照片建築與故事存檔。"""
from pathlib import Path
import sys,json,threading,http.server,base64
ROOT=Path(__file__).resolve().parents[1];WORK=ROOT.parents[1];WEB=WORK/'upstream/nccu100'
sys.path.insert(0,str(WORK/'.preview-tools'))
from playwright.sync_api import sync_playwright
class Receiver(http.server.BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(200);self.send_header('Access-Control-Allow-Origin','*');self.send_header('Access-Control-Allow-Methods','POST');self.send_header('Access-Control-Allow-Headers','Content-Type');self.end_headers()
    def do_POST(self):
        name=self.path.strip('/')
        if name not in ['campus.glb','latest-world.json']:self.send_error(403);return
        path=ROOT/('assets/models' if name.endswith('.glb') else 'assets/data')/name
        path.write_bytes(self.rfile.read(int(self.headers['Content-Length'])))
        self.send_response(200);self.send_header('Access-Control-Allow-Origin','*');self.end_headers();print(name,path.stat().st_size,flush=True)
server=http.server.ThreadingHTTPServer(('127.0.0.1',8794),Receiver)
threading.Thread(target=server.serve_forever,daemon=True).start()
with sync_playwright() as p:
    browser=p.chromium.launch(executable_path='C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless=True,args=['--use-angle=swiftshader','--enable-unsafe-swiftshader'])
    page=browser.new_page()
    # 不啟動遊戲迴圈、NPC 或天氣，避免將動態物件烘進靜態地圖。
    main=(WEB/'src/main.js').read_text(encoding='utf-8').split("import './world/environment/grass.js'")[0]
    main+='\nwindow.staticWorldReady=true;'
    page.route('**/src/main.js',lambda r:r.fulfill(body=main,content_type='application/javascript'))
    loader=(WEB/'src/world/buildings/index.js').read_text(encoding='utf-8')
    paths=sorted((WEB/'src/world/buildings').glob('*/index.js'))
    imports='\n'.join(f"import b{i} from '/src/world/buildings/{path.parent.name}/index.js';" for i,path in enumerate(paths))
    modules='{'+','.join(f"'./{path.parent.name}/index.js':{{default:b{i}}}" for i,path in enumerate(paths))+'}'
    loader=imports+'\n'+loader.replace("const modules = import.meta.glob('./*/index.js', { eager: true });",'const modules = '+modules+';')
    loader="import {scene} from '/src/core/engine.js';\nimport * as THREE from '/node_modules/three/build/three.module.js';\n"+loader
    loader=loader.replace('try { def.build(); }', "try { const before=new Set(scene.children); def.build(); const group=new THREE.Group(); group.name='Building_'+def.id; scene.children.filter(o=>!before.has(o)).forEach(o=>group.add(o)); scene.add(group); }")
    page.route('**/src/world/buildings/index.js',lambda r:r.fulfill(body=loader,content_type='application/javascript'))
    for name in ['GLTFExporter.js','BufferGeometryUtils.js']:
        source=(ROOT/'tools/vendor'/name).read_text(encoding='utf-8').replace("'./three.module.js'","'/node_modules/three/build/three.module.js'")
        page.route('**/world-export/'+name,lambda r,request,s=source:r.fulfill(body=s,content_type='application/javascript'))
    page.on('pageerror',lambda e:print('ERROR',e,flush=True))
    page.goto('http://127.0.0.1:8793/',wait_until='networkidle')
    page.wait_for_function('window.staticWorldReady',timeout=60000)
    print(page.evaluate((ROOT/'tools/export_latest_world.js').read_text(encoding='utf-8')),flush=True)
    browser.close()
server.shutdown()
