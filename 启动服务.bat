@echo off
chcp 65001 >nul
cd /d "%~dp0server"
echo 正在启动 校园集市（MySQL + 后端）...
node start.js
pause
