"""更新地圖與碰撞資料，保留原 Godot 故事、NPC 和任務座標。"""
from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]/'assets/data'
source=json.loads((root/'latest-world.json').read_text(encoding='utf-8'))
path=root/'campus.json';data=json.loads(path.read_text(encoding='utf-8'))
data['colliders']=source['colliders'];data['river']=source['river'];data['lots']=source['lots']
for collider in data['colliders']:
    # 網頁司令台的一筆欄杆寬度為負值，Godot 需要正的半尺寸。
    if collider.get('obb'):
        collider['hx']=abs(collider['hx']);collider['hz']=abs(collider['hz'])
# 網頁用自訂 draw 畫的半圓弧建築無法從 JS 匯出，這裡以網頁原始碼數值手動登記（會在每次同步時重建）。
# 羅馬廣場：src/world/buildings/roman-plaza/index.js 的 C、RI、RO；弧在中心 -z 側，直邊朝 +z（行政大樓／四維道方向），
# 導航目標放在直邊外側的入口。
arcs={'roman-plaza':{'name':'羅馬廣場','cx':90,'cz':-63,'r_out':15,'r_in':11.5,'approach_x':90,'approach_z':-59}}
entrances={'computer-center':[(70,-43),(40,-31)],'daren-hall':[(150,-21)],'lohas-hall':[(38,-5)],'jiying-hall':[(112,-4)],'command-stand':[(54,-112)]}
for b in source['buildings']:
    numbered=0
    for i,s in enumerate(b['map']):
        title=s.get('label') or (b['name'] if i==0 else '')
        lot={'name':title or b['name']+'附屬量體','x':s['x'],'z':s['z'],'w':s['w'],'d':s['d'],'map_only':not bool(title)}
        if title:
            available=entrances.get(b['id'],[])
            if numbered<len(available):lot['approach_x'],lot['approach_z']=available[numbered]
            numbered+=1
        data['lots'].append(lot)
for a in arcs.values():
    # x/z/w/d 為弧形外接矩形，供只認矩形的程式（小地圖等）使用；shape=arc 的程式改畫半圓環。
    data['lots'].append({'name':a['name'],'x':a['cx'],'z':a['cz']-a['r_out']/2,'w':a['r_out']*2,'d':a['r_out'],'map_only':False,'shape':'arc',**{k:a[k] for k in ('cx','cz','r_out','r_in','approach_x','approach_z')}})
path.write_text(json.dumps(data,ensure_ascii=False,separators=(',',':')),encoding='utf-8')
print('Synced buildings:',len(source['buildings']),'colliders:',len(data['colliders']),'map entries:',len(data['lots']))
