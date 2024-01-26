#!/bin/bash

# サブフォルダにあるフォントを集合させるプログラム

sh_dir=$(cd $(dirname $0) && pwd)

ls -F "${sh_dir}" | grep / | while read -r S; do
  mv ${sh_dir}/${S}*.ttf ${sh_dir}/
done

#rm -f OFL.txt
#rm -f README.md

exit 0