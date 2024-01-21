@echo off
:: サブフォルダにあるフォントを集合させるプログラム

cd /d %~dp0
for /r %%a in ("*.ttf") do (
  move "%%a" .\
)

:: del /q OFL.txt
:: del /q README.md

exit
