import pathlib,subprocess
root=pathlib.Path(__file__).resolve().parents[1]
log=root/'artifacts/packaged-test.log'
exe=root/'build/windows/NCCU-Campus.exe'
info=subprocess.STARTUPINFO();info.dwFlags|=subprocess.STARTF_USESHOWWINDOW;info.wShowWindow=0
result=subprocess.run([str(exe),'--headless','--log-file',str(log),'--quit-after','350','--','--smoke'],startupinfo=info,timeout=45)
text=log.read_text(encoding='utf-8')
print(text)
assert result.returncode==0
assert 'CAMPUS_READY npc=12 stories=3' in text
assert 'SMOKE_PASS' in text
assert 'ERROR' not in text
print('PACKAGED_WINDOWS_PASS')
