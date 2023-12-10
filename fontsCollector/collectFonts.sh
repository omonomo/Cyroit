#!/bin/bash

# フォントを集合させるプログラム

sh_dir=$(cd $(dirname $0) && pwd)
font_familyname="Cyroit"
font_familyname_suffix=("DG" "DS" "FX" "HB" "SP" "TM" "TS")

for S in ${font_familyname_suffix[@]}; do
  mv ${sh_dir}/${S}/${font_familyname}${S}-Bold.ttf ${sh_dir}/
  mv ${sh_dir}/${S}/${font_familyname}${S}-BoldOblique.ttf ${sh_dir}/
  mv ${sh_dir}/${S}/${font_familyname}${S}-Oblique.ttf ${sh_dir}/
  mv ${sh_dir}/${S}/${font_familyname}${S}-Regular.ttf ${sh_dir}

  rm -rf ${sh_dir}/${S}
done

#rm -f OFL.txt
#rm -f README.md