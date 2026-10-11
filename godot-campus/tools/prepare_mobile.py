from pathlib import Path
import re,sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root.parents[1]/'.asset-tools'))
for path in (root/'assets/models').glob('*mobile*.png.import'):
    text=path.read_text(encoding='utf-8')
    text=re.sub(r'process/size_limit=\d+','process/size_limit=1024',text)
    path.write_text(text,encoding='utf-8')
config=root/'export_presets.cfg'
text=config.read_text(encoding='utf-8')
text=text.replace('assets/models/student_female.glb"','assets/models/student_female.glb,assets/models/student_rig*,assets/models/student_female_rig*,assets/fonts/NotoSansTC.ttf"',1)
config.write_text(text,encoding='utf-8')
from fontTools.ttLib import TTFont
from fontTools import subset
from fontTools.varLib.instancer import instantiateVariableFont
font=TTFont(root/'assets/fonts/NotoSansTC.ttf')
instantiateVariableFont(font,{'wght':500},inplace=True)
texts=''.join(p.read_text(encoding='utf-8') for folder,pattern in [('scripts','*.gd'),('assets/data','*.json')] for p in (root/folder).glob(pattern))
texts+=''.join(chr(i) for i in range(32,256))+'政大校園地圖任務探索導航完整室內室外手機設定跑步跳躍互動前進後退繼續取消確認上下車流暢均衡細緻'
options=subset.Options();options.name_IDs=['*'];options.name_languages=['*']
job=subset.Subsetter(options=options);job.populate(text=texts);job.subset(font)
target=root/'assets/fonts/NotoSansTC-Game.ttf';font.save(target)
print('Mobile font:',target.stat().st_size,'bytes')
