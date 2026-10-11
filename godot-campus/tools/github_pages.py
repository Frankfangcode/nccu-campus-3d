"""Use the existing Git credential helper without printing or storing credentials."""
import subprocess,urllib.request,json,os,sys
REPO='wenzhotw/nccu-exchange-map'
def auth():
    env={**os.environ,'GIT_TERMINAL_PROMPT':'0','GCM_INTERACTIVE':'never'}
    p=subprocess.run(['git','credential','fill'],input='protocol=https\nhost=github.com\n\n',text=True,capture_output=True,env=env,timeout=30)
    if p.returncode:raise RuntimeError('GitHub Git credentials are unavailable; sign in to GitHub in Git Credential Manager.')
    values=dict(line.split('=',1) for line in p.stdout.splitlines() if '=' in line)
    return values.get('password','')
def api(path,method='GET',payload=None):
    headers={'Authorization':'Bearer '+auth(),'Accept':'application/vnd.github+json','X-GitHub-Api-Version':'2022-11-28','User-Agent':'NCCU-Campus-Publisher'}
    req=urllib.request.Request('https://api.github.com/repos/'+REPO+path,headers=headers,method=method,data=json.dumps(payload).encode() if payload is not None else None)
    with urllib.request.urlopen(req,timeout=40) as response:return json.load(response)
if __name__=='__main__':
    mode=sys.argv[1] if len(sys.argv)>1 else 'status'
    if mode=='status':
        r=api('/pages');print(json.dumps({k:r.get(k) for k in ['status','html_url','build_type','source']},indent=2))
    elif mode=='build':
        print(json.dumps(api('/pages/builds','POST')))
    elif mode=='latest':
        r=api('/pages/builds/latest');print(json.dumps({k:r.get(k) for k in ['status','error','commit','updated_at']},indent=2))
