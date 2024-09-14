#!/bin/bash
set -e

# 通常版、Loose 版両方の全バージョンを一度に生成させるプログラム


# ログをファイル出力させる場合は有効にする (<< "#LOG" をコメントアウトさせる)
<< "#LOG"
LOG_OUT=/tmp/run_ff_ttx.log
LOG_ERR=/tmp/run_ff_ttx_err.log
exec 1> >(tee -a $LOG_OUT)
exec 2> >(tee -a $LOG_ERR)
#LOG

# 個別製作用 (絵文字少ない版は、グリフ数の違いにより calt 設定を作り直す必要があるため)
font_familyname0="Cyroit"
font_familyname1="CyroitLoose"
font_familyname_suffix="EH"
font_familyname_suffix_opt="Sjp"

build_fonts_dir="build" # 完成品を保管するフォルダ

sh run_ff_ttx.sh -Fl -N "${font_familyname0}"
sh font_generator.sh -${font_familyname_suffix_opt} -N "${font_familyname0}" -n "${font_familyname_suffix}"

sh run_ff_ttx.sh -Fwlr -N "${font_familyname1}"
sh font_generator.sh -${font_familyname_suffix_opt} -N "${font_familyname1}" -n "${font_familyname_suffix}"

sh table_modificator.sh -ol -N "${font_familyname0}${font_familyname_suffix}"
mkdir -p "${build_fonts_dir}/${font_familyname0}/${font_familyname_suffix}"
mv -f ${font_familyname0}${font_familyname_suffix}*.ttf "${build_fonts_dir}/${font_familyname0}/${font_familyname_suffix}/."

sh table_modificator.sh -owr -N "${font_familyname1}${font_familyname_suffix}"
mkdir -p "${build_fonts_dir}/${font_familyname1}/${font_familyname_suffix}"
mv -f ${font_familyname1}${font_familyname_suffix}*.ttf "${build_fonts_dir}/${font_familyname1}/${font_familyname_suffix}/."

sh run_ff_ttx.sh -x

echo
echo "Succeeded in generating all custom fonts!"
echo

exit 0
