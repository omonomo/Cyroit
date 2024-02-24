@echo off
:: スタイルごとに仕分けるプログラム

set REG=Regular
set BLD=Bold
set OBL=Oblique
set BOB=BoldOblique

cd /d %~dp0

mkdir %BOB%
move "*%BOB%.ttf" .\%BOB%
mkdir %OBL%
move "*%OBL%.ttf" .\%OBL%
mkdir %REG%
move "*%REG%.ttf" .\%REG%
mkdir %BLD%
move "*%BLD%.ttf" .\%BLD%

exit
