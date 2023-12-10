@echo off
:: フォントを集合させるプログラム

set FAMILY=Cyroit

set SUFFIX0=DG
set SUFFIX1=DS
set SUFFIX2=FX
set SUFFIX3=HB
set SUFFIX4=SP
set SUFFIX5=TM
set SUFFIX6=TS

for /f "usebackq delims== tokens=1,2" %%a in (`set SUFFIX`) do (
  move .\%%b\%FAMILY%%%b-Bold.ttf .\
  move .\%%b\%FAMILY%%%b-BoldOblique.ttf .\
  move .\%%b\%FAMILY%%%b-Regular.ttf .\
  move .\%%b\%FAMILY%%%b-Oblique.ttf .\

  rd /q %%b
)

:: del /q OFL.txt
:: del /q README.md
