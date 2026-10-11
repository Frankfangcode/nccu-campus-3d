async () => {
 const {GLTFExporter}=await import('/godot-campus/tools/vendor/GLTFExporter.js');
 const {mergeBufferGeometries}=await import('/godot-campus/tools/vendor/BufferGeometryUtils.js');
 const M=window.migration,T=THREE;M.scene.updateMatrixWorld(true);
 const skip=new Set([M.sky,M.grass,M.player,M.pang,M.police,M.driveCar,...M.clouds,...M.NPCS.map(n=>n.g),...M.crystals.map(c=>c.g)]);
 const materialCache=new Map(),buckets=new Map();let count=0;
 function standard(mat,o){
   if(materialCache.has(mat.uuid))return materialCache.get(mat.uuid);
   let m;
   if(mat.isShaderMaterial)m=new T.MeshStandardMaterial({color:'#375e63',roughness:.22,metalness:.25});
   else if(mat.isMeshBasicMaterial)m=new T.MeshStandardMaterial({color:mat.color,map:mat.map,vertexColors:mat.vertexColors,transparent:mat.transparent,opacity:mat.opacity,side:mat.side,roughness:.85});
   else m=mat.clone();
   m.envMap=null;m.bumpMap=null;m.normalMap=null;
   const color=m.color||new T.Color('white');
   let kind='surface';
   if(mat.isShaderMaterial)kind='water';
   else if(mat.userData.paving){
      const c=mat.map.image.getContext('2d').getImageData(20,20,1,1).data;
      kind=c[0]>c[1]*1.25?'brick':c[0]<90?'asphalt':'paving';
   }else if(color.g>color.r*1.15&&color.g>color.b*1.14&&!m.map)kind='green';
   if(o.geometry.type==='PlaneGeometry'&&o.geometry.parameters.width>500)kind='terrain';
   if(m.alphaTest>0)kind='leaves';
   m.name=kind+'_'+materialCache.size;m.userData={};materialCache.set(mat.uuid,m);return m;
 }
 function addGeometry(geo,mat,matrix,o){
   const g=geo.clone();g.applyMatrix4(matrix);
   for(const key of Object.keys(g.attributes))if(!['position','normal','uv','color'].includes(key))g.deleteAttribute(key);
   if(!g.attributes.normal)g.computeVertexNormals();
   if(!g.attributes.uv)g.setAttribute('uv',new T.BufferAttribute(new Float32Array(g.attributes.position.count*2),2));
   // Normalize attributes so similarly shaded objects can share a draw call.
   if(!g.attributes.color)g.setAttribute('color',new T.BufferAttribute(new Float32Array(g.attributes.position.count*3).fill(1),3));
   const p=new T.Vector3().setFromMatrixPosition(matrix),cell=[Math.floor(p.x/64),Math.floor(p.z/64)];
   const key=mat.uuid+'_'+cell.join('_');
   if(!buckets.has(key))buckets.set(key,{mat,cell,geos:[]});buckets.get(key).geos.push(g.index?g.toNonIndexed():g);count++;
 }
 function walk(o,target){
   if(skip.has(o)||!o.visible||o.material===M.OUT||o.isSprite||o.isPoints||o.isLight)return;
   if(o.isMesh){
     if(Array.isArray(o.material)){
       // Keep per-face facade assignments intact.
       const c=new T.Mesh(o.geometry,o.material.map(m=>standard(m,o)));c.matrix.copy(o.matrixWorld);c.matrixAutoUpdate=false;target.add(c);
     }else if(o.material.visible!==false){
       const mat=standard(o.material,o);
       if(o.isInstancedMesh){const im=new T.Matrix4(),col=new T.Color();for(let i=0;i<o.count;i++){
         o.getMatrixAt(i,im);im.premultiply(o.matrixWorld);
         let geo=o.geometry;
         if(o.instanceColor){geo=geo.clone();o.getColorAt(i,col);const colors=new Float32Array(geo.attributes.position.count*3);for(let j=0;j<colors.length;j+=3){colors[j]=col.r;colors[j+1]=col.g;colors[j+2]=col.b;}geo.setAttribute('color',new T.BufferAttribute(colors,3));mat.vertexColors=true;}
         addGeometry(geo,mat,im,o);
       }}else addGeometry(o.geometry,mat,o.matrixWorld,o);
     }
   }
   o.children.forEach(c=>walk(c,target));
 }
 const campus=new T.Group();campus.name='NCCU_Campus';M.scene.children.forEach(o=>walk(o,campus));
 for(const {mat,cell,geos} of buckets.values()){
   const geo=mergeBufferGeometries(geos,false);if(!geo)throw Error('Geometry merge failed');
   const m=new T.Mesh(geo,mat);m.name=mat.name+'_cell_'+cell.join('_');campus.add(m);
 }
 async function saveGLB(name,root){
   const data=await new Promise((resolve,reject)=>new GLTFExporter().parse(root,resolve,reject,{binary:true,onlyVisible:true,maxTextureSize:1024}));
   const r=await fetch('/save/'+name,{method:'POST',body:data});if(!r.ok)throw Error('Save failed '+name);
 }
 await saveGLB('campus.glb',campus);
 for(const [name,obj] of [['police.glb',M.police],['pangolin.glb',M.pang]]){
   const c=obj.clone(true);c.position.set(0,0,0);c.rotation.set(0,0,0);
   c.updateMatrixWorld(true);
   buckets.clear();
   const prop=new T.Group();prop.name=name.replace('.glb','');walk(c,prop);
   for(const {mat,cell,geos} of buckets.values()){
     const geo=mergeBufferGeometries(geos,false);if(!geo)throw Error('Prop merge failed');
     const mesh=new T.Mesh(geo,mat);mesh.name=mat.name+'_prop_'+cell.join('_');prop.add(mesh);
   }
   await saveGLB(name,prop);
 }
 const data={interior_x:M.IX,river:M.RIV,track:M.TRK,gym:M.GYM,zh:M.ZH,fountain_z:M.FZ,lots:M.LOTS,colliders:M.colliders,
   police:{x:M.police.position.x,z:M.police.position.z,yaw:M.police.rotation.y},
   stories:M.crystals.map(c=>({name:c.name,lines:c.lines,position:c.g.position.toArray()})),
   npcs:M.NPCS.map(n=>({title:n.title||n.tag||'同學',home:n.home,path:n.path||[],speed:n.speed||1.1,face:n.face||0,indoor:!!n.indoorNPC,lines:typeof n.lines==='function'?n.lines():n.lines,look:n.look}))};
 await fetch('/save/campus.json',{method:'POST',body:JSON.stringify(data)});
 return {sourceMeshes:count,exportedMeshes:campus.children.length,materials:materialCache.size,npcs:data.npcs.length};
}
