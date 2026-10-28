@echo off
chcp 65001 >nul
cd /d "%~dp0server"
echo 正在初始化数据库 shop_db（建表 + 导入商品）...
node init-db.js
pause
