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

# 個別製作用 (絵文字減らした版は、グリフ数の違いにより calt 設定を作り直す必要があるため)
font_familyname0="Cyroit"

# 設定読み込み
settings="settings" # 設定ファイル名
settings_txt=$(find . -maxdepth 1 -name "${settings}.txt" | head -n 1)
if [ -n "${settings_txt}" ]; then
    S=$(grep -m 1 "^FONT_FAMILYNAME=" "${settings_txt}") # フォントファミリー名
    if [ -n "${S}" ]; then
        font_familyname0="${S#FONT_FAMILYNAME=}"
    fi
fi

font_familyname1="${font_familyname0}Loose"
font_familyname_suffix="EH"
font_familyname_suffix_opt="Sjp"

build_fonts_dir="build" # 完成品を保管するフォルダ

./run_ff_ttx.sh -Fl -N "${font_familyname0}"
./font_generator.sh -${font_familyname_suffix_opt} -N "${font_familyname0}" -n "${font_familyname_suffix}"

./run_ff_ttx.sh -Fwlr -N "${font_familyname1}"
./font_generator.sh -${font_familyname_suffix_opt} -N "${font_familyname1}" -n "${font_familyname_suffix}"

./table_modificator.sh -ol -N "${font_familyname0}${font_familyname_suffix}"
mkdir -p "${build_fonts_dir}/${font_familyname0}/${font_familyname_suffix}"
mv -f ${font_familyname0}${font_familyname_suffix}*.ttf "${build_fonts_dir}/${font_familyname0}/${font_familyname_suffix}/."

./table_modificator.sh -owr -N "${font_familyname1}${font_familyname_suffix}"
mkdir -p "${build_fonts_dir}/${font_familyname1}/${font_familyname_suffix}"
mv -f ${font_familyname1}${font_familyname_suffix}*.ttf "${build_fonts_dir}/${font_familyname1}/${font_familyname_suffix}/."

./run_ff_ttx.sh -x

echo
echo "Succeeded in generating all custom fonts!"
echo

exit 0
