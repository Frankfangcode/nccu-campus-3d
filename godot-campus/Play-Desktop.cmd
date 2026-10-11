@echo off
cd /d "%~dp0"
if exist "build\windows\NCCU-Campus.exe" (
    start "" "build\windows\NCCU-Campus.exe"
) else (
    start "" "%LOCALAPPDATA%\Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64.exe" --path "%~dp0."
)
