"""Collect attributed building references, separate from game runtime textures."""
from pathlib import Path
import urllib.request,urllib.parse,json,re,html,hashlib,shutil,time
from concurrent.futures import ThreadPoolExecutor
ROOT=Path(__file__).resolve().parents[3]/'素材圖片'/'建築素材庫'
ROOT.mkdir(parents=True,exist_ok=True)
API='https://commons.wikimedia.org/w/api.php'
HEAD={'User-Agent':'NCCU-Campus-Reference-Library/1.0 (architectural study; local development)'}
def request(url):
    cached=ROOT/'http-cache'/(hashlib.sha256(url.encode()).hexdigest()+'.json')
    if '/w/api.php?' in url and cached.exists():return cached.read_bytes()
    for attempt in range(4):
        try:
            time.sleep(2)
            with urllib.request.urlopen(urllib.request.Request(url,headers=HEAD),timeout=40) as r:content=r.read()
            if '/w/api.php?' in url:
                cached.parent.mkdir(exist_ok=True);cached.write_bytes(content)
            return content
        except Exception:
            if attempt==3:raise
            time.sleep(15+attempt*15)
def api(**kw):return json.loads(request(API+'?'+urllib.parse.urlencode({'action':'query','format':'json',**kw})))
def plain(s):return html.unescape(re.sub('<[^>]*>','',s or '')).strip()
cache=ROOT/'catalog-cache.json'
if cache.exists():catalog=json.loads(cache.read_text(encoding='utf-8'))
else:
    catalog={};seen=set()
    queue=[('National Chengchi University Main campus',0),('National Chengchi University Zhinan campus',0)]
    while queue:
        name,depth=queue.pop(0)
        if name in seen:continue
        seen.add(name)
        response=api(list='categorymembers',cmtitle='Category:'+name,cmlimit=500)
        members=response.get('query',{}).get('categorymembers',[])
        files=[m['title'] for m in members if m['ns']==6 and m['title'].lower().endswith(('.jpg','.jpeg','.png'))]
        if files:catalog[name]=files
        if depth<3:
            queue.extend((m['title'].removeprefix('Category:'),depth+1) for m in members if m['ns']==14)
        print('CATEGORY',len(seen),len(files),flush=True)
    for label,query in [('指南路街景','"Zhinan Road"'),('萬壽橋','"Wanshou Bridge" Taipei'),('景美溪','"Jingmei River"'),('指南宮','"Zhinan Temple"')]:
        response=api(list='search',srsearch=query,srnamespace=6,srlimit=6)
        catalog[label]=[r['title'] for r in response.get('query',{}).get('search',[]) if r['title'].lower().endswith(('.jpg','.jpeg','.png'))]
    cache.write_text(json.dumps(catalog,ensure_ascii=False,indent=2),encoding='utf-8')
selected={}
for category,files in catalog.items():
    # Direct category files include buildings lacking dedicated subcategories.
    count=12 if category.startswith('Buildings of NCCU') else 3
    for title in sorted(files,key=lambda s:('202' not in s,s))[:count]:selected.setdefault(title,[]).append(category)
records=[];failures=[]
existing=ROOT/'manifest.json'
old={r.get('title'):r for r in json.loads(existing.read_text(encoding='utf-8'))['assets']} if existing.exists() else {}
def collect(item):
    title,categories=item
    if title in old and (ROOT/old[title]['file']).is_file():return old[title]
    response=api(prop='imageinfo',titles=title,iiprop='url|extmetadata|size',iiurlwidth=1280)
    pages=response['query']['pages'];page=next(iter(pages.values()));info=page['imageinfo'][0];meta=info.get('extmetadata',{})
    get=lambda k:plain(meta.get(k,{}).get('value',''))
    url=info.get('thumburl',info['url'])
    key=hashlib.sha256(title.encode()).hexdigest()[:12]
    path=Path('網路參考')/(key+'.jpg')
    content=request(url);(ROOT/path).parent.mkdir(exist_ok=True);(ROOT/path).write_bytes(content)
    return {'id':key,'title':title,'categories':categories,'file':path.as_posix(),'source_page':info['descriptionurl'],'download_url':url,'author':get('Artist'),'license':get('LicenseShortName'),'license_url':get('LicenseUrl'),'description':get('ImageDescription'),'date':get('DateTimeOriginal'),'sha256':hashlib.sha256(content).hexdigest(),'usage':'modeling_reference; review license before redistribution','downloaded':'2026-10-12'}
with ThreadPoolExecutor(max_workers=1) as pool:
    futures=[(title,pool.submit(collect,(title,categories))) for title,categories in selected.items()]
    for title,f in futures:
        try:records.append(f.result());print('IMAGE',len(records),flush=True)
        except Exception as e:failures.append({'title':title,'error':str(e)});print('DOWNLOAD_FAILED',str(e)[:100],flush=True)
for path in sorted((ROOT.parent/'法學院').glob('*.jpg')):
    rel=Path('使用者提供')/'法學院'/path.name
    (ROOT/rel).parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,ROOT/rel)
    records.append({'id':path.stem,'title':'法學院 '+path.name,'categories':['法學院・使用者提供'],'file':rel.as_posix(),'source_page':'','author':'使用者提供，原攝影者待確認','license':'未確認；僅建模參考','license_url':'','description':'灰色外牆、米金色直向遮陽板、雙層窗格、入口退縮。照片不是測量資料。','usage':'reference_only; do not publish source photo','sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
known={r['id'] for r in records}
for record in old.values():
    if record['id'] not in known and ('政大記憶網' in record.get('categories',[]) or '恆光橋' in record.get('categories',[])):
        records.append(record)
manifest={'purpose':'Architectural reference library, not runtime textures','assets':records,'failures':failures,'official_sources':['https://bdmap.nccu.edu.tw/','https://nccuwiki.lib.nccu.edu.tw/index.php/校園建物'],'notes':['照片日期與現況可能不同。','現有遊戲座標為風格化配置，並非實測校園 GIS。','模型未確認的背面、尺度、地形須標示為推估。']}
(ROOT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
cards=[]
for r in records:
    esc=lambda s:html.escape(str(s),quote=True)
    cards.append(f'<article data-search="{esc(r["title"]+" "+" ".join(r["categories"])+" "+r.get("description",""))}"><img loading="lazy" src="{esc(r["file"])}"><div><h2>{esc(r["title"].removeprefix("File:"))}</h2><p>{esc(" / ".join(r["categories"]))}</p><p>{esc(r["author"])} · {esc(r["license"])}</p><a href="{esc(r["source_page"])}" target="_blank" rel="noopener">來源與授權</a><details><summary>建模參考資訊</summary>{esc(r.get("description",""))}</details></div></article>')
page='''<!doctype html><html lang="zh-Hant"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>政大建築參考素材庫</title><style>body{margin:0;background:#111b23;color:#e2e9e8;font:15px system-ui}header{padding:32px 5%;background:#192a35}h1{margin:0 0 12px}p{color:#a9bbc5;line-height:1.6}input{width:min(90%,650px);padding:14px;border:1px solid #48606e;background:#0d1820;color:white;border-radius:6px}main{padding:24px 4%;display:grid;grid-template-columns:repeat(auto-fill,minmax(290px,1fr));gap:20px}article{background:#1b2b36;border:1px solid #344956;border-radius:8px;overflow:hidden}article img{width:100%;height:230px;object-fit:contain;background:#080e12}article div{padding:18px}h2{font-size:16px;overflow-wrap:anywhere}a{color:#dfc38c}details{margin-top:12px;color:#bcc8cc}article[hidden]{display:none}</style><header><h1>政大 · 建築參考素材庫</h1><p>校園與周邊／照片來源與授權／法學院建模參考<br>照片不等同測量；本庫不隨遊戲匯出。搜尋中文或英文建築名稱。</p><input id="search" placeholder="法學院、Library、Zhinan、Administration…"><p id="count"></p><a href="manifest.json">完整素材清單 JSON</a></header><main>'''+''.join(cards)+'''</main><script>const cards=[...document.querySelectorAll('article')];function filter(){const q=document.querySelector('input').value.toLowerCase();let n=0;cards.forEach(c=>{c.hidden=!c.dataset.search.toLowerCase().includes(q);if(!c.hidden)n++});document.querySelector('#count').textContent=n+' / '+cards.length+' 張參考照片'}document.querySelector('input').oninput=filter;filter()</script></html>'''
(ROOT/'index.html').write_text(page,encoding='utf-8')
print(json.dumps({'downloaded':len(records),'failures':len(failures),'categories':len(catalog)}),flush=True)
