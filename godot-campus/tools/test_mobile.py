from pathlib import Path
import sys,json,os,time
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT.parents[1]/'.preview-tools'))
from playwright.sync_api import sync_playwright
url=sys.argv[1] if len(sys.argv)>1 else 'http://127.0.0.1:8790/'
messages=[];errors=[];state={}
with sync_playwright() as p:
    browser=p.chromium.launch(executable_path='C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless=True,args=['--enable-webgl','--ignore-gpu-blocklist','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
    context=browser.new_context(viewport={'width':844,'height':390},is_mobile=True,has_touch=True,device_scale_factor=1)
    page=context.new_page()
    def log(message):
        global state
        value=message.text
        if value.startswith('TEST_STATE '):state=json.loads(value[len('TEST_STATE '):])
        else:
            messages.append(value)
            print(value,flush=True)
    page.on('console',log);page.on('pageerror',lambda e:errors.append(str(e)))
    page.goto(url+'?autostart=1&mobile=1&test=1',wait_until='load',timeout=120000)
    page.wait_for_function('window.campusReady===true',timeout=180000)
    page.wait_for_timeout(2000)
    scale=390/540
    for _ in range(30):
        if state.get('route_button'):break
        page.wait_for_timeout(500)
    bx,by,bw,bh=state['route_button']
    assert by>=0 and by+bh<=540,('Route shortcut is clipped on mobile',state)
    page.screenshot(path=str(ROOT/'artifacts/mobile-route-menu.png'),timeout=60000)
    page.touchscreen.tap((bx+bw/2)*scale,(by+bh/2)*scale)
    page.wait_for_timeout(1800)
    assert any('CAMPUS_PLAYING true' in m for m in messages),'Could not start from touch menu'
    page.wait_for_timeout(1200)
    assert state.get('mobile'),state
    assert state['x'] < -70 and '井塘樓' in state['destination'],('New route shortcut did not enter the district',state)
    before=dict(state)
    cdp=context.new_cdp_session(page)
    def touches(kind,points):
        cdp.send('Input.dispatchTouchEvent',{'type':kind,'touchPoints':[{'x':x,'y':y,'id':i,'radiusX':5,'radiusY':5,'force':1} for i,x,y in points]})
    x=100*scale;y=428*scale
    touches('touchStart',[(1,x,y)])
    touches('touchMove',[(1,x,y-45*scale)])
    touches('touchStart',[(1,x,y-45*scale),(2,520,185)])
    for j in range(5):
        touches('touchMove',[(1,x,y-45*scale),(2,520+j*13,185)])
        page.wait_for_timeout(450)
    page.wait_for_timeout(1200)
    during=dict(state)
    touches('touchEnd',[]);page.wait_for_timeout(1200)
    assert during.get('stick',0)>0.2,('Joystick did not engage',during)
    assert abs(during.get('yaw',0)-before.get('yaw',0))>0.05,('Camera did not respond to second touch',before,during)
    assert abs(during['z']-before['z'])+abs(during['x']-before['x'])>0.5,('Character did not move',before,during)
    assert state.get('stick',1)==0,('Joystick stayed pressed',state)
    page.screenshot(path=str(ROOT/'artifacts/mobile-landscape.png'),timeout=60000)
    # The map button is anchored to the right edge in logical pixels.
    page.touchscreen.tap(844-147*scale,162*scale);page.wait_for_timeout(1200)
    assert state.get('map'),('Map touch did not open',state)
    page.screenshot(path=str(ROOT/'artifacts/mobile-map.png'),timeout=60000)
    page.touchscreen.tap(844-92*scale,40*scale);page.wait_for_timeout(1200)
    assert not state.get('map'),('Map did not close',state)
    page.set_viewport_size({'width':390,'height':844});page.wait_for_timeout(1800)
    page.screenshot(path=str(ROOT/'artifacts/mobile-portrait.png'),timeout=60000)
    failures=errors+[m for m in messages if 'SCRIPT ERROR' in m or 'ERROR:' in m]
    result={'url':url,'photo_route_shortcut':True,'multitouch_move_and_look':True,'release_resets_stick':True,'touch_map':True,'portrait_rendered':True,'state':state,'errors':failures}
    (ROOT/'artifacts/mobile-test.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(result,ensure_ascii=True),flush=True)
    browser.close()
    assert not failures,failures
