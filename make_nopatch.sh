#!/bin/bash
set -e

# 通常版、Loose 版のパッチ前のフォント (Nerd Fonts なし、派生フォントの素) を生成させるプログラム
# 生成したフォントは各派生フォントの sourceFonts フォルダに移して使用する

# ログをファイル出力させる場合は有効にする (<< "#LOG" をコメントアウトさせる)
<< "#LOG"
LOG_OUT=/tmp/run_ff_ttx.log
LOG_ERR=/tmp/run_ff_ttx_err.log
exec 1> >(tee -a $LOG_OUT)
exec 2> >(tee -a $LOG_ERR)
#LOG

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
font_familyname_suffix=""
font_familyname_suffix_opt0="Poe"
font_familyname_suffix_opt1="Poew"

build_fonts_dir="build/Cyroit.nopatch" # フォントを保管するフォルダ

mkdir -p "${build_fonts_dir}"

./font_generator.sh -${font_familyname_suffix_opt0} -N "${font_familyname0}" -n "${font_familyname_suffix}" auto
mv -f ${font_familyname0}${font_familyname_suffix}*.ttf "${build_fonts_dir}/."

./font_generator.sh -${font_familyname_suffix_opt1} -N "${font_familyname1}" -n "${font_familyname_suffix}" auto
mv -f ${font_familyname1}${font_familyname_suffix}*.ttf "${build_fonts_dir}/."

./run_ff_ttx.sh -x

echo
echo "Finished generating no-patch fonts."
echo

exit 0
