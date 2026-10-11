from pathlib import Path
import sys,json
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT.parents[1]/'.preview-tools'))
from playwright.sync_api import sync_playwright
errors=[];messages=[]
with sync_playwright() as p:
    browser=p.chromium.launch(executable_path='C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',headless=True,args=['--enable-webgl','--ignore-gpu-blocklist','--autoplay-policy=no-user-gesture-required','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
    page=browser.new_page(viewport={'width':1440,'height':900})
    page.on('pageerror',lambda e:errors.append(str(e)))
    def console(m):
        messages.append(m.text)
        print('BROWSER',m.type,m.text,flush=True)
    page.on('console',console)
    page.goto('http://127.0.0.1:8790/?test=1',wait_until='load',timeout=120000)
    print('Page loaded',flush=True)
    try:
        for _ in range(90):
            if any('CAMPUS_READY' in m for m in messages):break
            page.wait_for_timeout(1000)
        assert any('CAMPUS_READY' in m for m in messages),'Game never became ready'
    except Exception:
        page.screenshot(path=str(ROOT/'artifacts/web-failure.png'),timeout=15000)
        (ROOT/'artifacts/web-failure.json').write_text(json.dumps({'errors':errors,'messages':messages},indent=2),encoding='utf-8')
        raise
    print('Game ready',flush=True)
    page.screenshot(path=str(ROOT/'artifacts/web-menu.png'))
    page.mouse.click(280,505)
    page.wait_for_timeout(1000)
    if not any('CAMPUS_PLAYING true' in m for m in messages):
        page.mouse.click(280,545);page.wait_for_timeout(1000)
    assert any('CAMPUS_PLAYING true' in m for m in messages),'Menu click did not start'
    before=page.screenshot(path=str(ROOT/'artifacts/web-before.png'))
    page.keyboard.down('w');page.wait_for_timeout(2500);page.keyboard.up('w')
    page.wait_for_timeout(600)
    after=page.screenshot(path=str(ROOT/'artifacts/web-after.png'))
    assert before!=after,'The rendered scene did not update after keyboard input'
    page.keyboard.press('m');page.wait_for_timeout(500)
    page.screenshot(path=str(ROOT/'artifacts/web-map.png'))
    page.keyboard.press('m')
    page.screenshot(path=str(ROOT/'artifacts/web-game.png'))
    failures=errors+[m for m in messages if 'SCRIPT ERROR' in m or 'ERROR:' in m]
    result={'loaded':True,'started':True,'keyboard_input_rendered':True,'errors':failures,'messages':messages[-20:]}
    (ROOT/'artifacts/web-test.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(result,ensure_ascii=False))
    browser.close()
    assert not failures,failures
