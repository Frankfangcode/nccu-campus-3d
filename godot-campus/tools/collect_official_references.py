"""Fill missing building references from NCCU's public university archive."""
from pathlib import Path
import urllib.request,urllib.parse,json,hashlib,time,html,re
root=Path(__file__).resolve().parents[3]/'素材圖片'/'建築素材庫'
manifest=json.loads((root/'manifest.json').read_text(encoding='utf-8'))
headers={'User-Agent':'NCCU-Campus-Reference-Library/1.0'}
def get(url):
    time.sleep(0.6)
    with urllib.request.urlopen(urllib.request.Request(url,headers=headers),timeout=25) as response:return response.read()
def api(host,**kw):return json.loads(get(host+'/api.php?'+urllib.parse.urlencode({'action':'query','format':'json',**kw})))
host='https://nccuwiki.lib.nccu.edu.tw'
names=['風雩樓','逸仙樓','研究大樓','學思樓','大仁樓','大智樓','大勇樓','季陶樓']
pages=api(host,titles='|'.join(names),prop='images',imlimit=50)['query']['pages']
existing={r['id'] for r in manifest['assets']}
for page in pages.values():
    name=page['title']
    files=[i['title'] for i in page.get('images',[]) if i['title'].lower().endswith(('.jpg','.jpeg','.png'))]
    files=sorted(files,key=lambda s:(not any(x in s for x in ['正面','正門','全景','2025','外觀']),s))[:2]
    if not files:continue
    imagepages=api(host,titles='|'.join(files),prop='imageinfo',iiprop='url|extmetadata',iiurlwidth=1280)['query']['pages']
    for photo in imagepages.values():
        title=photo['title'];key=hashlib.sha256((host+title).encode()).hexdigest()[:12]
        if key in existing:continue
        info=photo['imageinfo'][0];url=info.get('thumburl',info['url'])
        try:content=get(url)
        except Exception as error:
            manifest.setdefault('failures',[]).append({'title':title,'error':str(error)});continue
        if not content.startswith((b'\xff\xd8\xff',b'\x89PNG')):raise RuntimeError('Not an image: '+url)
        rel=Path('官方參考')/(key+'.jpg');(root/rel).parent.mkdir(exist_ok=True);(root/rel).write_bytes(content)
        manifest['assets'].append({'id':key,'title':name+' / '+title,'categories':[name,'政大記憶網'],'file':rel.as_posix(),'source_page':info['descriptionurl'],'download_url':url,'author':'來源：政治大學記憶網；原攝影者詳見來源頁','license':'未確認開放授權；僅本機建模參考','license_url':'','description':'官方校史影像，可能為歷史照片；拍攝日期與現況需交叉確認。','date':'詳見來源頁','usage':'reference_only; not licensed for game texture or public redistribution','sha256':hashlib.sha256(content).hexdigest(),'downloaded':'2026-10-12'})
        print('OFFICIAL_IMAGE',len(manifest['assets']),flush=True)
    (root/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
# A nearby bridge omitted by the initial per-category sample.
title='File:恆光橋.JPG'
response=api('https://commons.wikimedia.org/w',titles=title,prop='imageinfo',iiprop='url|extmetadata',iiurlwidth=1280)
info=next(iter(response['query']['pages'].values()))['imageinfo'][0]
key=hashlib.sha256(title.encode()).hexdigest()[:12]
if key not in existing:
    url=info.get('thumburl',info['url']);content=get(url);rel=Path('網路參考')/(key+'.jpg');(root/rel).write_bytes(content)
    meta=info['extmetadata'];plain=lambda k:html.unescape(re.sub('<[^>]*>','',meta.get(k,{}).get('value','')))
    manifest['assets'].append({'id':key,'title':title,'categories':['恆光橋','校園周邊'],'file':rel.as_posix(),'source_page':info['descriptionurl'],'download_url':url,'author':plain('Artist'),'license':plain('LicenseShortName'),'license_url':plain('LicenseUrl'),'date':plain('DateTimeOriginal'),'description':plain('ImageDescription'),'usage':'modeling_reference; review license before redistribution','sha256':hashlib.sha256(content).hexdigest(),'downloaded':'2026-10-12'})
(root/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
print('OFFICIAL_REFERENCE_COLLECTION_COMPLETE',len(manifest['assets']),flush=True)
