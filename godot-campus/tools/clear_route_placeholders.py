"""Remove migrated placeholder signs/trees in the rebuilt survey district.

Uses an immutable local backup, so reruns never progressively erode the campus.
Keeps the river and large ground plane. The matching old physics is removed too.
"""
from pathlib import Path
import json,struct
ROOT=Path(__file__).resolve().parents[1]
source=ROOT/'artifacts/campus-before-route.glb'
raw=source.read_bytes()
n=struct.unpack_from('<I',raw,12)[0]
doc=json.loads(raw[20:20+n]); start=20+n
blob=bytearray(raw[start+8:])
def region(x,z):
    return (-253<x<-76 and -116<z<-22) or (-222<x<-138 and -126<z<=-116) or (-162<x<-84 and -136<z<=-116)
def values(index):
    a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
    fmt={5126:'f',5125:'I',5123:'H',5121:'B'}[a['componentType']]
    count={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]
    stride=v.get('byteStride',struct.calcsize(fmt)*count)
    offset=v.get('byteOffset',0)+a.get('byteOffset',0)
    return [struct.unpack_from('<'+fmt*count,blob,offset+i*stride) for i in range(a['count'])]
removed=0
identity=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]
for node in doc['nodes']:
    if 'mesh' not in node:continue
    m=node.get('matrix',identity)
    mesh=doc['meshes'][node['mesh']]
    kept=[]
    for primitive in mesh['primitives']:
        mat=doc['materials'][primitive['material']].get('name','')
        if mat.startswith(('terrain','water')):
            kept.append(primitive);continue
        pos=values(primitive['attributes']['POSITION'])
        indices=[v[0] for v in values(primitive['indices'])] if 'indices' in primitive else list(range(len(pos)))
        chosen=[]
        for i in range(0,len(indices),3):
            tri=indices[i:i+3]
            center=[sum(pos[j][k] for j in tri)/3 for k in range(3)]
            x=sum(m[k*4]*center[k] for k in range(3))+m[12]
            z=sum(m[k*4+2]*center[k] for k in range(3))+m[14]
            if region(x,z):removed+=1
            else:chosen.extend(tri)
        if not chosen:continue
        if len(chosen)!=len(indices):
            blob.extend(b'\0'*((-len(blob))%4));offset=len(blob)
            data=struct.pack('<'+'I'*len(chosen),*chosen);blob.extend(data)
            view=len(doc['bufferViews']);doc['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':len(data),'target':34963})
            accessor=len(doc['accessors']);doc['accessors'].append({'bufferView':view,'componentType':5125,'count':len(chosen),'type':'SCALAR','min':[min(chosen)],'max':[max(chosen)]})
            primitive['indices']=accessor
        kept.append(primitive)
    if kept:mesh['primitives']=kept
    else:node.pop('mesh')
doc['buffers'][0]['byteLength']=len(blob)
j=json.dumps(doc,separators=(',',':')).encode();j+=b' '*((-len(j))%4);blob+=b'\0'*((-len(blob))%4)
result=struct.pack('<III',0x46546c67,2,28+len(j)+len(blob))+struct.pack('<II',len(j),0x4e4f534a)+j+struct.pack('<II',len(blob),0x004e4942)+blob
(ROOT/'assets/models/campus.glb').write_bytes(result)
data=json.loads((ROOT/'artifacts/campus-before-route.json').read_text(encoding='utf-8'))
before=len(data['colliders'])
data['colliders']=[c for c in data['colliders'] if not region(c.get('x',c.get('cx',(c.get('x0',0)+c.get('x1',0))/2)),c.get('z',c.get('cz',(c.get('z0',0)+c.get('z1',0))/2)))]
(ROOT/'assets/data/campus.json').write_text(json.dumps(data,ensure_ascii=False,separators=(',',':')),encoding='utf-8')
print('Removed placeholder triangles:',removed,'matching old colliders:',before-len(data['colliders']))
