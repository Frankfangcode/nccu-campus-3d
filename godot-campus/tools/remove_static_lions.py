"""只移除舊校園合併網格裡的石獅本體，保留台座，供新版活動石獅替換。"""
from pathlib import Path
import json,struct
path=Path(__file__).resolve().parents[1]/'assets/models/campus.glb'
raw=path.read_bytes();n=struct.unpack_from('<I',raw,12)[0]
doc=json.loads(raw[20:20+n]);blob=bytearray(raw[28+n:])
def values(index):
    a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
    fmt={5126:'f',5125:'I',5123:'H',5121:'B'}[a['componentType']]
    count={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]
    stride=v.get('byteStride',struct.calcsize(fmt)*count)
    offset=v.get('byteOffset',0)+a.get('byteOffset',0)
    return [struct.unpack_from('<'+fmt*count,blob,offset+i*stride) for i in range(a['count'])]
removed=0
for node in doc['nodes']:
    if 'mesh' not in node:continue
    matrix=node.get('matrix',[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1])
    for primitive in doc['meshes'][node['mesh']]['primitives']:
        pos=values(primitive['attributes']['POSITION'])
        idx=[x[0] for x in values(primitive['indices'])] if 'indices' in primitive else list(range(len(pos)))
        kept=[]
        for i in range(0,len(idx),3):
            tri=idx[i:i+3]
            c=[sum(pos[j][k] for j in tri)/3 for k in range(3)]
            x,y,z=[sum(matrix[k*4+d]*c[k] for k in range(3))+matrix[12+d] for d in range(3)]
            if 2.51<y<4.8 and abs(z+83.6)<0.9 and min(abs(x+56.2),abs(x+35.8))<0.85:removed+=1
            else:kept.extend(tri)
        if len(kept)==len(idx):continue
        if not kept:
            # GLTF 不接受空 accessor；退化三角形不會繪製。
            kept=[idx[0]]*3
        blob.extend(b'\0'*(-len(blob)%4));offset=len(blob)
        packed=struct.pack('<'+'I'*len(kept),*kept);blob.extend(packed)
        view=len(doc['bufferViews']);doc['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':len(packed),'target':34963})
        accessor=len(doc['accessors']);doc['accessors'].append({'bufferView':view,'componentType':5125,'count':len(kept),'type':'SCALAR','min':[min(kept)],'max':[max(kept)]})
        primitive['indices']=accessor
if removed:
    doc['buffers'][0]['byteLength']=len(blob)
    data=json.dumps(doc,separators=(',',':')).encode();data+=b' '*(-len(data)%4);blob+=b'\0'*(-len(blob)%4)
    path.write_bytes(struct.pack('<III',0x46546c67,2,28+len(data)+len(blob))+struct.pack('<II',len(data),0x4e4f534a)+data+struct.pack('<II',len(blob),0x004e4942)+blob)
print('Removed static lion triangles:',removed)
