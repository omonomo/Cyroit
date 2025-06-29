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
font_familyname_suffix_def=(BS SP FX HB DG EH) # バージョン違いの名称
font_familyname_suffix_def_opt=(zts ts ztc Zzubts zt Sj) # 各バージョンのオプション
#font_familyname_suffix_def=(FX DG) # テスト用
#font_familyname_suffix_def_opt=(ztc zt)

./run_ff_ttx.sh -F -N "${font_familyname0}" S
for i in ${!font_familyname_suffix_def[@]}; do
    ./run_ff_ttx.sh -F -N "${font_familyname0}" -n "${font_familyname_suffix_def[${i}]}" ${font_familyname_suffix_def_opt[${i}]}
done

./run_ff_ttx.sh -Fw -N "${font_familyname1}" S
for i in ${!font_familyname_suffix_def[@]}; do
    ./run_ff_ttx.sh -Fw -N "${font_familyname1}" -n "${font_familyname_suffix_def[${i}]}" ${font_familyname_suffix_def_opt[${i}]}
done

#./run_ff_ttx.sh -FL -N "${font_familyname0}" -n "LG" S
#for i in ${!font_familyname_suffix_def[@]}; do
#    ./run_ff_ttx.sh -FL -N "${font_familyname0}" -n "${font_familyname_suffix_def[${i}]}LG" ${font_familyname_suffix_def_opt[${i}]}
#done
#
#./run_ff_ttx.sh -FwL -N "${font_familyname1}" -n "LG" S
#for i in ${!font_familyname_suffix_def[@]}; do
#    ./run_ff_ttx.sh -FwL -N "${font_familyname1}" -n "${font_familyname_suffix_def[${i}]}LG" ${font_familyname_suffix_def_opt[${i}]}
#done

echo
echo "Succeeded in generating all custom fonts!"
echo

exit 0
