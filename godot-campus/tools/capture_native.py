import subprocess, pathlib, os, sys
root=pathlib.Path(__file__).resolve().parents[1]
exe=pathlib.Path(os.environ['LOCALAPPDATA'])/'Programs/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe'
start=subprocess.STARTUPINFO();start.dwFlags|=subprocess.STARTF_USESHOWWINDOW;start.wShowWindow=0
with (root/'capture.log').open('w',encoding='utf-8') as out:
    proc=subprocess.run([str(exe),'--path',str(root),'--resolution','1440x900','--','--capture']+sys.argv[1:],stdout=out,stderr=subprocess.STDOUT,startupinfo=start,timeout=150)
print((root/'capture.log').read_text(encoding='utf-8')[-6000:])
raise SystemExit(proc.returncode)
