"""Fetch only the required members of the official export-template ZIP via HTTP ranges."""
import io, os, urllib.request, zipfile, pathlib
URL='https://godot-releases.nbg1.your-objectstorage.com/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz'
class RemoteZip(io.RawIOBase):
    def __init__(self):
        req=urllib.request.Request(URL, method='HEAD')
        with urllib.request.urlopen(req, timeout=60) as r: self.length=int(r.headers['Content-Length'])
        self.pos=0
    def seekable(self):return True
    def readable(self):return True
    def tell(self):return self.pos
    def seek(self, offset, whence=0):
        self.pos=offset if whence==0 else self.pos+offset if whence==1 else self.length+offset
        return self.pos
    def read(self, count=-1):
        if count<0:count=self.length-self.pos
        count=min(count,self.length-self.pos)
        if count<=0:return b''
        req=urllib.request.Request(URL,headers={'Range':f'bytes={self.pos}-{self.pos+count-1}'})
        with urllib.request.urlopen(req,timeout=180) as r:
            if r.status!=206:raise RuntimeError('Server does not support range requests')
            data=r.read()
        if len(data)!=count:raise RuntimeError('Incomplete range')
        self.pos+=len(data)
        return data
dest=pathlib.Path(os.environ['APPDATA'])/'Godot/export_templates/4.7.2.stable'
dest.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(RemoteZip()) as z:
    for name in ['web_nothreads_release.zip','web_nothreads_debug.zip','windows_release_x86_64.exe']:
        member=next((n for n in z.namelist() if n.endswith('/'+name)),None)
        if not member:raise RuntimeError('Missing '+name)
        target=dest/name
        if target.exists() and target.stat().st_size==z.getinfo(member).file_size:
            print(name,'already installed',flush=True);continue
        data=z.read(member) # ZipFile validates the member's CRC.
        target.write_bytes(data)
        print(name,len(data),'bytes verified & installed',flush=True)
(dest/'version.txt').write_text('4.7.2.stable',encoding='utf-8')
