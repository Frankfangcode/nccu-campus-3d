"""Fetch attributed CC0 art and the exact Three.js exporter used for migration."""
from pathlib import Path
import json,urllib.request,concurrent.futures,hashlib
ROOT=Path(__file__).resolve().parents[1]
def get(url):
    req=urllib.request.Request(url,headers={'User-Agent':'NCCU-Campus-Development/1.0'})
    with urllib.request.urlopen(req,timeout=90) as r:return r.read()
def save(job):
    name,url=job;p=ROOT/name;p.parent.mkdir(parents=True,exist_ok=True)
    if p.exists() and p.stat().st_size>0:return str(name)+' cached'
    data=get(url);p.write_bytes(data)
    return f'{name}: {len(data)} bytes'
jobs=[
('licenses/Godot-LICENSE.txt','https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/LICENSE.txt'),
('licenses/Godot-COPYRIGHT.txt','https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/COPYRIGHT.txt'),
('licenses/Threejs-LICENSE.txt','https://raw.githubusercontent.com/mrdoob/three.js/r149/LICENSE'),
('assets/models/student.glb','https://grab3d.com/dl/man-rigged/man-rigged.glb'),
('assets/models/student_female.glb','https://grab3d.com/dl/woman-rigged/woman-rigged.glb'),
('licenses/Grab3D-man.txt','https://grab3d.com/dl/man/LICENSE.txt'),
('licenses/Grab3D-woman.txt','https://grab3d.com/dl/woman/LICENSE.txt'),
('tools/vendor/GLTFExporter.js','https://cdn.jsdelivr.net/npm/three@0.149.0/examples/jsm/exporters/GLTFExporter.js'),
('tools/vendor/BufferGeometryUtils.js','https://cdn.jsdelivr.net/npm/three@0.149.0/examples/jsm/utils/BufferGeometryUtils.js'),
('tools/vendor/three.module.js','https://cdn.jsdelivr.net/npm/three@0.149.0/build/three.module.js'),
('assets/fonts/NotoSansTC.ttf','https://raw.githubusercontent.com/google/fonts/main/ofl/notosanstc/NotoSansTC%5Bwght%5D.ttf'),
('licenses/NotoSansTC-OFL.txt','https://raw.githubusercontent.com/google/fonts/main/ofl/notosanstc/OFL.txt')]
for asset in ['asphalt_02','pavement_02','brown_brick_02','aerial_grass_rock']:
    try:
        files=json.loads(get('https://api.polyhaven.com/files/'+asset))
        lookup={k.lower():v for k,v in files.items()}
        for key,suffix in [('diffuse','albedo'),('nor_gl','normal'),('rough','roughness')]:
            node=lookup.get(key,lookup.get('diff',{})) if key=='diffuse' else lookup.get(key,{})
            image=node.get('1k',{}).get('jpg')
            if image:jobs.append((f'assets/textures/{asset}_{suffix}.jpg',image['url']))
    except Exception as e:print('Texture metadata:',asset,e,flush=True)
with concurrent.futures.ThreadPoolExecutor(max_workers=5) as pool:
    for future in concurrent.futures.as_completed([pool.submit(save,j) for j in jobs]):
        try:print(future.result(),flush=True)
        except Exception as e:print('DOWNLOAD ERROR:',e,flush=True)
manifest={name:{'source':url,'sha256':hashlib.sha256((ROOT/name).read_bytes()).hexdigest()} for name,url in jobs if (ROOT/name).exists()}
(ROOT/'licenses/download-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
for path in (ROOT/'tools/vendor').glob('*.js'):
    s=path.read_text(encoding='utf-8').replace("from 'three'","from './three.module.js'")
    path.write_text(s,encoding='utf-8')
