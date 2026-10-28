@echo off
chcp 65001 >nul
echo 正在用华为云码道打开本项目...
start "" "D:\CodeArts Agent\bin\codearts-agent.cmd" "%~dp0."
