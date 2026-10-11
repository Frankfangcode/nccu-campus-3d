"""Prepare an isolated Pages/source commit without touching the user's checkout."""
from pathlib import Path
import shutil,json,hashlib
root=Path(__file__).resolve().parents[1]
workspace=root.parents[1]
destination=(workspace/'.publish-campus').resolve()
assert destination.is_relative_to(workspace.resolve()) and (destination/'.git').is_file()
source_dest=destination/'godot-campus'
ignored={'.godot','build','artifacts','vendor','__pycache__'}
count=0
for path in root.rglob('*'):
    rel=path.relative_to(root)
    if any(part in ignored for part in rel.parts) or path.suffix in {'.log','.tmp'} or not path.is_file():continue
    target=source_dest/rel;target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(path,target);count+=1
site=destination/'campus3d';site.mkdir(exist_ok=True)
files=['index.html','index.js','index.wasm','index.icon.png','index.apple-touch-icon.png','index.audio.worklet.js','index.audio.position.worklet.js','campus.zip','preview.png']
manifest={}
for name in files:
    source=root/'build/web'/name
    assert source.is_file(),name
    assert source.stat().st_size<100*1024*1024,(name,'exceeds GitHub file limit')
    shutil.copy2(source,site/name)
    manifest[name]={'bytes':source.stat().st_size,'sha256':hashlib.sha256(source.read_bytes()).hexdigest()}
shutil.copy2(root/'CREDITS.txt',site/'CREDITS.txt')
shutil.copytree(root/'licenses',site/'licenses',dirs_exist_ok=True)
(site/'.nojekyll').write_text('',encoding='utf-8')
(site/'version.json').write_text(json.dumps({'edition':'Godot mobile exploration','files':manifest},indent=2),encoding='utf-8')
print('Staged source files:',count)
print('Website:',site)
print('Website download files:',sum(v['bytes'] for v in manifest.values())//1048576,'MiB')
