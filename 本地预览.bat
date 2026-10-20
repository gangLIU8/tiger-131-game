@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo.
echo   虎式 I 型 · 131  ·  靶场射击
echo   ------------------------------------
echo   网址: http://127.0.0.1:8778
echo   关掉本窗口即停止服务
echo.

start "" http://127.0.0.1:8778/index.html

set "PY=C:\Users\Administrator\AppData\Local\Programs\Python\Python312\python.exe"
if not exist "%PY%" set "PY=python"

"%PY%" -m http.server 8778 --bind 127.0.0.1
pause
