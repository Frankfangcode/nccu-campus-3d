"""Index the user's ordered walking survey without uploading original photographs."""
from pathlib import Path
import sys,json,hashlib,html
PROJECT=Path(__file__).resolve().parents[1]
WORKSPACE=PROJECT.parents[1]
sys.path.insert(0,str(WORKSPACE/'.asset-tools'))
from PIL import Image,ImageOps
root=WORKSPACE/'素材圖片'/'建築素材庫'
source=WORKSPACE/'素材圖片'/'蓋亞造界3D game照片'
thumbs=root/'沿路照片縮圖';thumbs.mkdir(exist_ok=True)
def subject(n):
    if n==59:return ['法學院','中正圖書館'],'路口全景；全景投影會使建築變形，僅供方位辨識。'
    if n in [60,61,82,84,85]:return ['莊敬宿舍','法學院'],'宿舍灰色立面、暖色管線、候車亭與 ATM；沿四維道辨識。'
    if n in [62,63,75,76,83,91,93]:return ['法學院'],'法學院側立面／入口與沿街關係；可見白色外框及暖色遮陽肋。'
    if n in [64,65,66,68]:return ['中正圖書館'],'圖書館側立面與通往泳館的路口；保留既有圖書館主體。'
    if n in [67,69]:return ['鳳凰林','游泳館'],'草地、磚鋪步道與樹蔭，連接法學院與游泳館。'
    if 70<=n<=80:return ['游泳館'],'泳館金屬斜屋頂、玻璃端牆、粉色磁磚、入口階梯及側邊坡道。'
    if n==81:return ['鳳凰林'],'鳳凰林紀念石與草地。'
    if 86<=n<=90 or n in [92,102]:return ['實小附設幼兒園'],'粉色磁磚、圓弧雨棚、幾何壁飾、綠色圍欄與遊戲區。'
    if n==94:return ['李園','井塘樓'],'李園開放草坪與後方井塘樓的相對位置。'
    if n in [95,96]:return ['莊敬九舍'],'粉色宿舍立面、窗台冷氣、石材入口與階梯。'
    if n in [98,101]:return ['井塘樓','教育學院'],'教育學院弧形正立面、四層窗列、白色立肋與前庭。'
    return ['社資中心','井塘樓'],'社資中心入口、深色長立面與街角關係。'
manifest=json.loads((root/'manifest.json').read_text(encoding='utf-8'))
manifest['assets']=[a for a in manifest['assets'] if not a['id'].startswith('survey-20261012-')]
records=[]
for path in sorted(source.glob('IMG_20261012_*.jpg')):
    n=int(path.stem.rsplit('_',1)[1]);tags,description=subject(n)
    target=thumbs/(path.stem+'.jpg')
    with Image.open(path) as original:
        dimensions=list(original.size)
        gps=bool(original.getexif().get(34853))
        im=ImageOps.exif_transpose(original)
        im.thumbnail((1280,720));im.save(target,quality=88)
    relative='../蓋亞造界3D game照片/'+path.name
    item={'id':f'survey-20261012-{n:03d}','title':'使用者沿路照片 '+path.name,'categories':tags,'buildings':tags,
          'file':target.relative_to(root).as_posix(),'original_file':relative,'source_page':'','download_url':'',
          'author':'使用者提供','license':'使用者提供・本機建模參考','license_url':'','description':description,
          'date':'2026-10-12','sha256':hashlib.sha256(target.read_bytes()).hexdigest(),
          'original_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'original_dimensions':dimensions,'gps_present':gps,
          'usage':'local modeling reference only; original photographs are not distributed with the game','downloaded':'2026-10-12'}
    records.append(item);manifest['assets'].append(item)
manifest['walking_survey']={'date':'2026-10-12','count':len(records),'sequence':'059–102（未提供 097）',
    'map':'../../政大平面圖/山下校園地圖.jpg','position_method':'平面圖相對關係與沿路照片交叉推估；沒有 EXIF GPS，非實測還原。'}
(root/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
cards=[]
for a in records:
    esc=html.escape
    cards.append(f'<article><a href="{esc(a["original_file"],quote=True)}"><img loading="lazy" src="{esc(a["file"],quote=True)}"></a><div><small>{esc(a["title"])}</small><h2>{esc(" · ".join(a["categories"]))}</h2><p>{esc(a["description"])}</p><a href="{esc(a["original_file"],quote=True)}">查看原始照片 ↗</a></div></article>')
page='''<!doctype html><html lang="zh-Hant"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>法學院至教育學院 · 沿路照片</title><style>body{margin:0;background:#13232a;color:#e7e5d9;font:16px system-ui}header{padding:40px 5%}h1{font-size:34px}p{line-height:1.8;color:#b3c6c5}main{padding:0 5% 40px;display:grid;grid-template-columns:repeat(auto-fit,minmax(310px,1fr));gap:22px}article{background:#20333b;border:1px solid #3c565d}article img{width:100%;aspect-ratio:16/9;object-fit:contain;background:#0a1319}article div{padding:20px}h2{font-size:18px}a{color:#e9c78a}small{font-size:11px;color:#9fb5bd}.preview{width:min(100%,1100px)}</style><header><a href="index.html">← 全部建築素材</a><h1>法學院 → 教育學院</h1><p>2026.10.12 沿路實拍 · 43 張<br>依原始編號排列；點圖可開啟原始高解析度照片。<br>位置依山下校園地圖與街景推估，未取得測量尺度。</p><a href="../../政大平面圖/山下校園地圖.jpg">查看提供的山下校園地圖</a><p>法學院／宿舍路口 → 圖書館側邊 → 鳳凰林與游泳館 → 法學院側巷 → 附幼與莊敬九舍 → 李園 → 井塘樓／教育學院、社資中心</p><img class="preview" src="photo-route.png" alt="本次 Godot 街區實際畫面"></header><main>'''+''.join(cards)+'</main></html>'
(root/'walking-route.html').write_text(page,encoding='utf-8')
public={'survey_date':'2026-10-12','photo_count':len(records),'coordinates_measured':False,
    'notes':'Photos inform visible facades; dimensions and distances are estimated. The supplied downhill map labels the law building as a planned site; current photos override that old status. No original photos are packaged.',
    'map_reference':'User-supplied NCCU downhill campus map',
    'official_context':['https://educ.nccu.edu.tw/PageDoc/Detail?fid=9695&id=13661','https://bdmap.nccu.edu.tw/'],
    'photo_groups':[{'id':a['id'],'subjects':a['categories'],'observations':a['description']} for a in records],
    'districts':{'LawCollege':[-110,0,-78],'SwimmingPool':[-123,0,-120],'DormitoryCourtyard':[-111,0,-34],'Kindergarten':[-163,0,-31],'DormitoryNine':[-199,0,-57],'JingTang':[-193,0,-112],'SocialScience':[-238,0,-105]}}
(PROJECT/'assets/data/walking_survey.json').write_text(json.dumps(public,ensure_ascii=False,indent=2),encoding='utf-8')
print('Indexed walking photographs:',len(records),'with GPS:',sum(a['gps_present'] for a in records))
