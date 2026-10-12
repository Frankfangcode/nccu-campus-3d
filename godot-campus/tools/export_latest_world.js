// 從來源模組保留每棟建築名稱、座標、碰撞、地圖及可行走高度。
async () => {
 const T=await import('/node_modules/three/build/three.module.js');
 const {scene}=await import('/src/core/engine.js');
 const {world}=await import('/src/world/registry.js');
 const {colliders}=await import('/src/core/collision.js');
 const {OUT}=await import('/src/render/kit.js');
 const {sky,clouds}=await import('/src/world/environment/sky.js');
 const {police}=await import('/src/actors/police-car.js');
 const {driveCar}=await import('/src/actors/campus-bus.js');
 const {RIV}=await import('/src/world/terrain/river.js');
 const {LOTS}=await import('/src/world/layout.js');
 const {GLTFExporter}=await import('/world-export/GLTFExporter.js');
 const {mergeBufferGeometries}=await import('/world-export/BufferGeometryUtils.js');
 const preserve=new Set(['law-school','swimming-hall','law-education-route']);
 const region=(x,z)=>(x>-253&&x<-76&&z>-116&&z<-22)||(x>-222&&x<-138&&z>-126&&z<=-116)||(x>-162&&x<-84&&z>-136&&z<=-116)||(x>99&&x<125&&z>-32&&z<-18);
 const skip=new Set([sky,police,driveCar,...clouds]);
 const cache=new Map(),buckets=new Map();let count=0;
 const root=new T.Group();root.name='NCCU_LatestWeb';
 scene.updateMatrixWorld(true);
 function material(mat,o){
   if(cache.has(mat.uuid))return cache.get(mat.uuid);
   const m=new T.MeshStandardMaterial({color:mat.color||'#547075',map:mat.map||null,vertexColors:mat.vertexColors,transparent:mat.transparent,opacity:mat.opacity,side:mat.side,alphaTest:mat.alphaTest,roughness:.85});
   let kind='surface';const c=m.color;
   if(mat.isShaderMaterial){kind='water';m.metalness=.25;m.roughness=.22;}
   else if(mat.userData.paving&&mat.map?.image?.getContext){const p=mat.map.image.getContext('2d').getImageData(20,20,1,1).data;kind=p[0]>p[1]*1.25?'brick':p[0]<90?'asphalt':'paving';}
   else if(c.g>c.r*1.15&&c.g>c.b*1.14&&!m.map)kind='green';
   if(o.geometry.type==='PlaneGeometry'&&o.geometry.parameters.width>500)kind='terrain';
   if(m.alphaTest>0)kind='leaves';m.name=kind+'_'+cache.size;cache.set(mat.uuid,m);return m;
 }
 function add(geo,mat,matrix,group){
   let g=geo.clone().applyMatrix4(matrix);g=g.index?g.toNonIndexed():g;
   for(const key of Object.keys(g.attributes))if(!['position','normal','uv','color'].includes(key))g.deleteAttribute(key);
   const pos=g.attributes.position;
   // 保留照片街區內的大型地面／河道，其餘舊佔位物與靜態石獅不重複匯入。
   if(!mat.name.startsWith('terrain')&&!mat.name.startsWith('water')){
     const keep=[];
     for(let i=0;i<pos.count;i+=3){let x=0,y=0,z=0;for(let j=0;j<3;j++){x+=pos.getX(i+j)/3;y+=pos.getY(i+j)/3;z+=pos.getZ(i+j)/3;}
       if(region(x,z))continue;
       for(let j=0;j<3;j++)keep.push(i+j);
     }
     if(!keep.length)return;
     if(keep.length<pos.count){const clean=new T.BufferGeometry();for(const [key,a] of Object.entries(g.attributes)){const vals=new Float32Array(keep.length*a.itemSize);keep.forEach((idx,i)=>{for(let k=0;k<a.itemSize;k++)vals[i*a.itemSize+k]=a.array[idx*a.itemSize+k];});clean.setAttribute(key,new T.BufferAttribute(vals,a.itemSize));}g=clean;}
   }
   if(!g.attributes.normal)g.computeVertexNormals();
   if(!g.attributes.uv)g.setAttribute('uv',new T.BufferAttribute(new Float32Array(g.attributes.position.count*2),2));
   if(!g.attributes.color)g.setAttribute('color',new T.BufferAttribute(new Float32Array(g.attributes.position.count*3).fill(1),3));
   const p=new T.Vector3().setFromMatrixPosition(matrix),cell=[Math.floor(p.x/64),Math.floor(p.z/64)];
   const key=group+'_'+mat.uuid+'_'+cell.join('_');
   if(!buckets.has(key))buckets.set(key,{mat,group,cell,geos:[]});buckets.get(key).geos.push(g);count++;
 }
 function walk(o,group='Terrain'){
   if(skip.has(o)||!o.visible||o.isSprite||o.isPoints||o.isLight||o.isLine||o.material===OUT||o.name.startsWith('石獅'))return;
   if(o.name.startsWith('Building_')){if(preserve.has(o.name.slice(9)))return;group=o.name;}
   if(o.isMesh){
     const mats=Array.isArray(o.material)?o.material:[o.material];
     if(mats.some(m=>m.side===T.BackSide))return;
     const matrices=[];
     if(o.isInstancedMesh){for(let i=0;i<o.count;i++){const m=new T.Matrix4();o.getMatrixAt(i,m);matrices.push(m.premultiply(o.matrixWorld));}}
     else matrices.push(o.matrixWorld);
     for(const matrix of matrices){
       if(mats.length===1)add(o.geometry,material(mats[0],o),matrix,group);
       else {const g=o.geometry.index?o.geometry.toNonIndexed():o.geometry;for(const part of g.groups){const sub=new T.BufferGeometry();for(const [key,a] of Object.entries(g.attributes))sub.setAttribute(key,new T.BufferAttribute(a.array.slice(part.start*a.itemSize,(part.start+part.count)*a.itemSize),a.itemSize));add(sub,material(mats[part.materialIndex],o),matrix,group);}}
     }
   }
   o.children.forEach(c=>walk(c,group));
 }
 scene.children.forEach(o=>walk(o));
 const groups=new Map();
 for(const {mat,group,cell,geos} of buckets.values()){
   if(!groups.has(group)){const node=new T.Group();node.name=group;root.add(node);groups.set(group,node);}
   const merged=mergeBufferGeometries(geos,false);if(!merged)throw Error('Cannot merge '+group);
   const mesh=new T.Mesh(merged,mat);mesh.name=mat.name+'_'+cell.join('_');groups.get(group).add(mesh);
 }
 const buildings=world.buildings.filter(b=>!preserve.has(b.id)).map(b=>({id:b.id,name:b.name,map:(b.map||[]).filter(s=>s.x!==undefined)}));
 const heights=[];
 for(const b of world.buildings){
   if(preserve.has(b.id)||!b.heightAt)continue;
   const group=groups.get('Building_'+b.id);if(!group)continue;
   const box=new T.Box3().setFromObject(group);const step=.5;
   for(let x=Math.floor(box.min.x)-1;x<Math.ceil(box.max.x)+1;x+=step)for(let z=Math.floor(box.min.z)-1;z<Math.ceil(box.max.z)+1;z+=step){
     const h=b.heightAt(x+step/2,z+step/2);if(h==null||h<=.025||region(x,z))continue;
     const ys=[[x,z],[x+step,z],[x+step,z+step],[x,z+step]].map(([px,pz])=>b.heightAt(px,pz)??h);
     heights.push([x,z,step,...ys]);
   }
 }
 const filtered=colliders.filter(c=>!region(c.x??c.cx??(c.x0+c.x1)/2,c.z??c.cz??(c.z0+c.z1)/2));
 const data={source:'9fde140',buildings,colliders:filtered,lots:LOTS.filter(l=>!region(l.x,l.z)),river:RIV,heights,groups:[...groups.keys()],meshes:count};
 const glb=await new Promise((ok,bad)=>new GLTFExporter().parse(root,ok,bad,{binary:true,maxTextureSize:1024}));
 for(const [name,body] of [['campus.glb',glb],['latest-world.json',JSON.stringify(data)]]){const r=await fetch('http://127.0.0.1:8794/'+name,{method:'POST',body});if(!r.ok)throw Error('Cannot save '+name);}
 return {groups:data.groups,meshes:count,colliders:filtered.length,heights:heights.length,bytes:glb.byteLength};
}
