"""匯入網頁 v1.24 的原始石獅與騎馬角色，保留來源模型階層。"""
from pathlib import Path
import sys,base64,json
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT.parents[1]/'.preview-tools'))
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    browser=p.chromium.launch(executable_path='C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless=True,args=['--use-angle=swiftshader','--enable-unsafe-swiftshader'])
    page=browser.new_page()
    exporter=(ROOT/'tools/vendor/GLTFExporter.js').read_text(encoding='utf-8').replace("from './three.module.js'", "from '/node_modules/three/build/three.module.js'")
    page.route('**/event-exporter.js',lambda r:r.fulfill(body=exporter,content_type='application/javascript'))
    page.goto('http://127.0.0.1:8793/?debug',wait_until='networkidle')
    page.wait_for_function('window.__oldPrincipal && window.__game')
    output=page.evaluate('''async()=>{
      const T=await import('/node_modules/three/build/three.module.js');
      const {GLTFExporter}=await import('/event-exporter.js');
      const principal=window.__oldPrincipal; principal.freeze(); principal.npc.after(principal.npc,0);
      const result={};
      for(const [name,source] of [['weather_lion',__game.scene.getObjectByName('石獅-左')],['old_principal',principal.npc.g]]){
        // userData 中有 Three.js 節點參照，clone 前先暫存，避免循環 JSON。
        const saved=[]; source.traverse(o=>{saved.push([o,o.userData]);o.userData={};});
        let obj;try{obj=source.clone(true);}finally{saved.forEach(([o,d])=>o.userData=d);}
        obj.position.set(0,0,0);obj.rotation.set(0,0,0);
        const remove=[];let count=0;
        obj.traverse(o=>{
          o.name=o.name||('part_'+count++);o.userData={};
          if(o.isSprite||o.material?.side===T.BackSide){remove.push(o);return;}
          if(o.isMesh){const convert=m=>new T.MeshStandardMaterial({color:m.color,map:m.map,roughness:0.85,transparent:m.transparent,opacity:m.opacity,side:m.side});o.material=Array.isArray(o.material)?o.material.map(convert):convert(o.material);}
        }); remove.forEach(o=>o.removeFromParent());
        const bytes=new Uint8Array(await new Promise((ok,bad)=>new GLTFExporter().parse(obj,ok,bad,{binary:true})));
        let binary='';for(let i=0;i<bytes.length;i+=8192)binary+=String.fromCharCode(...bytes.subarray(i,i+8192));
        result[name]=btoa(binary);
      }return result;
    }''')
    for name,data in output.items():
        target=ROOT/'assets/models'/f'{name}.glb'
        target.write_bytes(base64.b64decode(data));print(name,target.stat().st_size)
    browser.close()
