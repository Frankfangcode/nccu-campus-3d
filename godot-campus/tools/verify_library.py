from pathlib import Path
import json,hashlib,sys
root=Path(__file__).resolve().parents[1]
library=root.parents[1]/'素材圖片'/'建築素材庫'
manifest=json.loads((library/'manifest.json').read_text(encoding='utf-8'))
for record in manifest['assets']:
    file=(library/record['file']).resolve()
    assert file.is_relative_to(library.resolve())
    content=file.read_bytes()
    assert content.startswith((b'\xff\xd8\xff',b'\x89PNG')),record['title']
    assert hashlib.sha256(content).hexdigest()==record['sha256'],record['title']
    assert record['license'] and record['author'],record['title']
sys.path.insert(0,str(root.parents[1]/'.preview-tools'))
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    browser=p.chromium.launch(executable_path='C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless=True)
    page=browser.new_page(viewport={'width':1360,'height':900})
    errors=[];page.on('pageerror',lambda e:errors.append(str(e)))
    page.goto((library/'index.html').as_uri())
    assert page.locator('article').count()==len(manifest['assets'])
    page.locator('input').fill('法學院')
    assert page.locator('article:visible').count()>=6
    page.locator('input').fill('萬壽橋')
    assert page.locator('article:visible').count()>=1
    page.locator('input').fill('')
    page.screenshot(path=str(root/'artifacts/reference-library.png'))
    assert not errors,errors
    browser.close()
print('REFERENCE_LIBRARY_PASS',len(manifest['assets']),'attributed images; hashes, files and search verified')
