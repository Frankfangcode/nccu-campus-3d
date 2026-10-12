"""Curate building coverage and create an offline, searchable reference gallery."""
from pathlib import Path
import json,re,html,shutil
PROJECT=Path(__file__).resolve().parents[1]
ROOT=PROJECT.parents[1]/'素材圖片'/'建築素材庫'
manifest=json.loads((ROOT/'manifest.json').read_text(encoding='utf-8'))
roster=[
('法學院','山下校區',r'Law (building|College)|法學院'),
('游泳館','山下校區',r'Swimming Pool|游泳館'),('李園','山下校區',r'Plum Garden|李園'),
('鳳凰林','山下校區',r'鳳凰林'),('實小附設幼兒園','山下校區',r'Kindergarten|幼兒園'),('莊敬九舍','山下校區',r'莊敬九舍'),
('四維堂','山下校區',r'Shiwei|Siwei'),('行政大樓','山下校區',r'Administration'),
('中正圖書館','山下校區',r'Chiang Kai-shek.*Library|Main Library'),
('商學院','山下校區',r'Commerce'),('井塘樓','山下校區',r'Jing tan'),
('新聞館','山下校區',r'Journalism'),('資訊大樓／電算中心','山下校區',r'Information [Bb]uilding|Computer center'),
('社資中心','山下校區',r'Social [Ss]cience'),('果夫樓','山下校區',r'Guofu'),
('志希樓','山下校區',r'Zhixi'),('綜合院館','山下校區',r'General Building'),
('體育館','山下校區',r'Gymnasium'),('莊敬宿舍','山下校區',r'JhuangJing'),
('校門','山下校區',r'Gate|maingate'),('風雩樓','山下校區',r'Feng.*[Ll]ou|Feng.*[Bb]uilding'),
('逸仙樓','山下校區',r'Yi[ -]?Hsian|Yi[ -]?Xian|Yixian'),('研究大樓','山下校區',r'Research Building'),
('學思樓','山下校區',r'Xue[ -]?Si|Hsueh'),('大仁樓','山下校區',r'Da[ -]?Ren|Ta[ -]?Jen'),
('大智樓','山下校區',r'Da[ -]?Zhi|Ta[ -]?Chih'),('大勇樓','山下校區',r'Da[ -]?Yong|Ta[ -]?Yung'),
('憩賢樓','山下校區',r'Qi Xian'),('道藩樓','山上校區',r'Dao Fan'),
('百年樓','山上校區',r'Bai Nian'),('季陶樓','山上校區',r'Ji Tao|Chi Tao'),
('傳播學院','山上校區',r'Communication College'),('藝文中心','山上校區',r'art.*culture'),
('國際大樓','山上校區',r'International Building'),('自強十舍','山上校區',r'ZihCiang 10'),
('達賢圖書館','指南校區',r'Dah Hsian|Seetoo'),('國關中心','指南校區',r'IIR|International Relations'),
('身心健康中心','指南校區',r'Physical.*Mental Health'),
('醉夢溪／指南溪','校園周邊',r'Zhinan River|Waterfront'),
('指南路／政大街','校園周邊',r'Zhinan Road|Zhengda Street'),
('萬壽橋','校園周邊',r'Wanshou Bridge'),('景美溪','校園周邊',r'Jingmei|Jingmai'),
('指南宮','校園周邊',r'Zhinan Temple|指南宮'),('恆光橋','校園周邊',r'Hengguang|恆光'),
('全校配置／空拍','全校',r'aerialphoto|campus 2023')]
excluded=r'President|總統|MOU between|Lampyridae|statues|Bus No|NCCU Buses|lecturing|Choice Bazaar|Shenkeng'
assets=[]
for item in manifest['assets']:
    if re.search(excluded,item['title'],re.I):continue
    subject=item['title']+' '+' '.join(item['categories'])
    item['buildings']=[name for name,area,pattern in roster if name in subject or re.search(pattern,subject,re.I)]
    if not item['buildings']:item['buildings']=['校園環境']
    if item['title'].endswith('S__56434702_0.jpg'):
        item['description']='建築設計示意圖；造型可能與完工現況不同，以其他實景照片交叉確認。'
    assets.append(item)
manifest['assets']=assets
coverage=[]
for name,area,pattern in roster:
    refs=[a['id'] for a in assets if name in a['buildings']]
    coverage.append({'name':name,'area':area,'reference_count':len(refs),'reference_ids':refs,'status':'已建立照片參考模型，尺寸與位置為推估' if name in ['法學院','井塘樓','新聞館','社資中心'] else '已建立概略街廓；非逐店還原' if name=='指南路／政大街' else '已收集，待精細建模' if refs else '待補拍／待找到可辨識照片'})
manifest['coverage']=coverage
for c in coverage:
    if c['name'] in ['游泳館','李園','鳳凰林','實小附設幼兒園','莊敬九舍','莊敬宿舍','井塘樓']:
        c['status']='依 2026-10-12 沿路實拍建立外觀與動線；尺度為推估'
manifest['pending_official_sources']=[{'name':'研究大樓','url':'https://classroom.nccu.edu.tw/work/buildingface.php?bdnumber=VWQGNg%3D%3D','status':'搜尋可找到外觀頁，下載連線逾時'}, {'name':'逸仙樓','url':'https://classroom.nccu.edu.tw/work/buildingface.php?bdnumber=VmA%3D','status':'搜尋可找到外觀頁，下載連線逾時'},{'name':'大仁樓','url':'https://classroom.nccu.edu.tw/work/buildingface.php?bdnumber=V2YLPg%3D%3D','status':'搜尋可找到外觀頁，下載連線逾時'}]
(ROOT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
(ROOT/'coverage.json').write_text(json.dumps(coverage,ensure_ascii=False,indent=2),encoding='utf-8')
# Publish only provenance and model status; the reference photographs stay local.
public={'notes':manifest['notes'],'coverage':coverage,'sources':[{'id':a['id'],'title':a['title'],'source':a['source_page'],'license':a['license'],'author':a['author']} for a in assets],'models':[{'name':'法學院','builder':'scripts/architecture_detail.gd:law_college','position':[-200,0,-66],'measured':False,'reference':'使用者提供實景照片；背面尚未測量'},{'name':'指南路街廓','builder':'scripts/architecture_detail.gd:street','position':[0,0,53],'measured':False,'reference':'街景氛圍重建；店名為一般類型，非真實商家'}]}
public['models'][0]['position']=[-110,0,-78]
public['models'][0]['reference']='使用者沿路實拍與提供的山下校園地圖；尺度為推估'
survey_path=PROJECT/'assets/data/walking_survey.json'
if survey_path.exists():
    survey=json.loads(survey_path.read_text(encoding='utf-8'))
    public['walking_survey']={'photos':survey['photo_count'],'districts':survey['districts'],'measured':False}
(PROJECT/'assets/data/architecture_sources.json').write_text(json.dumps(public,ensure_ascii=False,indent=2),encoding='utf-8')
esc=lambda value:html.escape(str(value),quote=True)
cards=[]
for a in assets:
    tags=' '.join(a['buildings'])
    cards.append(f'<article data-search="{esc(tags+" "+a["title"])}"><a href="{esc(a["file"])}"><img loading="lazy" src="{esc(a["file"])}"></a><div><h2>{esc(" · ".join(a["buildings"]))}</h2><p>{esc(a["title"].removeprefix("File:"))}</p><p>{esc(a["author"])}<br>{esc(a["license"])} · {esc(a.get("date","日期待確認"))}</p>'+ (f'<a href="{esc(a["source_page"])}" target="_blank" rel="noopener">原圖來源與授權 ↗</a>' if a['source_page'] else '<span>使用者提供 · 僅供建模參考</span>') +f'<details><summary>照片資訊</summary>{esc(a.get("description",""))}</details></div></article>')
rows=''.join(f'<tr><td>{esc(c["area"])}</td><td>{esc(c["name"])}</td><td>{c["reference_count"]}</td><td>{esc(c["status"])}</td></tr>' for c in coverage)
for name in ['law-college','zhinan-street']:
    if (PROJECT/f'artifacts/{name}.png').exists():shutil.copy2(PROJECT/f'artifacts/{name}.png',ROOT/f'{name}.png')
page='''<!doctype html><html lang="zh-Hant"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>政大建築素材庫</title><style>*{box-sizing:border-box}body{margin:0;background:#101b23;color:#e5ece9;font:15px system-ui}header,section{padding:32px 5%}header{background:#1b2d39;border-bottom:1px solid #47606e}h1{font-size:36px;margin:10px 0}h2{font-size:18px}p{color:#b2c4ca;line-height:1.7}input{width:min(90%,670px);background:#0d1921;border:1px solid #5c747f;color:white;padding:15px;font:inherit;border-radius:6px}.cards{padding:0 5% 30px;display:grid;grid-template-columns:repeat(auto-fill,minmax(285px,1fr));gap:20px}article{border:1px solid #344c59;background:#1a2b35;border-radius:7px;overflow:hidden}article img{width:100%;height:225px;object-fit:contain;background:#080f15}article div{padding:18px}article p{overflow-wrap:anywhere;font-size:13px}a{color:#e8c992}details{margin-top:16px}article[hidden]{display:none}.previews{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:20px}.previews img{width:100%;border-radius:6px}table{border-collapse:collapse;width:100%;font-size:14px}td,th{padding:10px;text-align:left;border-bottom:1px solid #344652}.scroll{overflow:auto}.tag{color:#e5c591;font-size:12px;letter-spacing:.22em}</style><header><div class="tag">NCCU · ARCHITECTURE ARCHIVE / 2026.10</div><h1>政大建築素材庫</h1><p>山下校區、山上校區、指南校區與周邊街景。<br>點照片可看大圖；每筆保留來源及授權。照片僅供建模參考，不會隨遊戲下載。</p><input id="search" placeholder="搜尋：法學院、四維堂、指南路、井塘樓…"><p id="count"></p><a href="manifest.json">素材清單 JSON</a> · <a href="coverage.json">建築覆蓋清單</a></header><section><h2>已開始建立的 3D 場景</h2><div class="previews"><div><img src="law-college.png"><p>法學院：依實景重建外觀，尺寸與位置沿用遊戲概略配置。</p></div><div><img src="zhinan-street.png"><p>指南路：可探索街廓與騎樓；商家、尺度為示意。</p></div></div><details><summary>各建築收集與建模進度（包含尚缺照片）</summary><div class="scroll"><table><thead><tr><th>區域</th><th>建築</th><th>照片</th><th>狀態</th></tr></thead><tbody>'''+rows+'''</tbody></table></div></details></section><main class="cards">'''+''.join(cards)+'''</main><script>const cards=[...document.querySelectorAll('article')];function filter(){let n=0;const q=document.querySelector('input').value.toLowerCase();cards.forEach(c=>{c.hidden=!c.dataset.search.toLowerCase().includes(q);if(!c.hidden)n++});document.querySelector('#count').textContent=n+' / '+cards.length+' 張參考照片'}document.querySelector('input').oninput=filter;filter()</script></html>'''
page=page.replace('<a href="manifest.json">','<a href="walking-route.html">新增：法學院至教育學院 43 張沿路照片與場景 ↗</a> · <a href="manifest.json">')
page=page.replace('尺寸與位置沿用遊戲概略配置','位置參考山下地圖，尺寸由照片推估')
(ROOT/'index.html').write_text(page,encoding='utf-8')
print(json.dumps({'photos':len(assets),'covered':sum(bool(c['reference_count']) for c in coverage),'tracked':len(coverage),'missing':[c['name'] for c in coverage if not c['reference_count']]}))
