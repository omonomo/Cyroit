#!/bin/bash

# Table modificator
#
# Copyright (c) 2023 omonomo
#
# 各種テーブルの修正・追加プログラム


# ログをファイル出力させる場合は有効にする (<< "#LOG" をコメントアウトさせる)
<< "#LOG"
LOG_OUT=/tmp/table_modificator.log
LOG_ERR=/tmp/table_modificator_err.log
exec 1> >(tee -a $LOG_OUT)
exec 2> >(tee -a $LOG_ERR)
#LOG

font_familyname="Roroit"

lookupIndex_calt="18" # caltテーブルのlookupナンバー
listNo="0"
caltListName="caltList" # caltテーブルリストの名称
caltList="${caltListName}_${listNo}" # Lookupごとのcaltテーブルリスト
cmapList="cmapList" # 異体字セレクタリスト
extList="extList" # 異体字のglyphナンバーリスト
gsubList="gsubList" # 作成フォントのGSUBから抽出した置き換え用リスト

zero_width="0" # 文字幅ゼロ
hankaku_width="512" # 半角文字幅
hankaku_width_Loose="576" # 半角文字幅 (Loose 版)
xAvg_char_width=${hankaku_width} # フォントの半角文字幅は常に1:2とする
zenkaku_width="1024" # 全角文字幅
underline="-80" # アンダーライン位置
#vhea_ascent1024="994"
#vhea_descent1024="256"
#vhea_linegap1024="0"

mode="" # 生成モード

leaving_tmp_flag="false" # 一時ファイルを残すか
loose_flag="false" # Loose 版にするか
reuse_list_flag="false" # 生成済みのリストを使うか

cmap_flag="true" # cmapを編集するか
gsub_flag="true" # GSUBを編集するか
other_flag="true" # その他を編集するか
reuse_list_flag="false" # 生成済みのリストを使うか

calt_insert_flag="true" # caltテーブルを挿入するか
patch_only_flag="false" # caltテーブルのみ編集
calt_ok_flag="true" # フォントがcaltに対応しているか

symbol_only_flag="false" # カーニング設定を記号、桁区切りのみにするか
basic_only_flag="false" # カーニング設定を基本ラテン文字に限定するか
optimize_flag="false" # なんちゃって最適化ルーチンを実行するか

# エラー処理
trap "exit 3" HUP INT QUIT

option_format_cm() { # calt_table_maker 用のオプションを整形 (戻り値: 整形したオプション)
  local opt # 整形前のオプション
  local leaving_tmp_flag # 一時作成ファイルを残すか
  local symbol_only_flag # カーニング設定を記号、桁区切りのみにするか
  local basic_only_flag # カーニング設定を基本ラテン文字に限定するか
  local optimize_flag="false" # なんちゃって最適化ルーチンを実行するか
  opt="${2}"
  leaving_tmp_flag="${3}"
  symbol_only_flag="${4}"
  basic_only_flag="${5}"
  optimize_flag="${6}"

  if [ "${leaving_tmp_flag}" != "false" ]; then # -l オプションがある場合
    opt="${opt}l"
  fi
  if [ "${symbol_only_flag}" != "false" ]; then # -k オプションがある場合
    opt="${opt}k"
  fi
  if [ "${basic_only_flag}" != "false" ]; then # -b オプションがある場合
    opt="${opt}b"
  fi
  if [ "${optimize_flag}" != "false" ]; then # -o オプションがある場合
    opt="${opt}o"
  fi
  eval "${1}=\${opt}" # 戻り値を入れる変数名を1番目の引数に指定する
}

option_check() {
  if [ -n "${mode}" ]; then # -Cp のうち2個以上含まれていたら終了
    echo "Illegal option"
    exit 1
  fi
}

remove_temp() {
  echo "Remove temporary files"
  rm -f ${font_familyname}*.ttx
  rm -f ${font_familyname}*.ttx.bak
  rm -f ${caltListName}*.txt
  rm -f ${cmapList}.txt
  rm -f ${extList}.txt
  rm -f ${gsubList}.txt
}

table_modificator_help()
{
    echo "Usage: table_modificator.sh [options]"
    echo ""
    echo "Options:"
    echo "  -h         Display this information"
    echo "  -x         Cleaning temporary files" # 一時作成ファイルの消去のみ
    echo "  -l         Leave (do NOT remove) temporary files"
    echo "  -N string  Set fontfamily (\"string\")"
    echo "  -w         Set the ratio of hankaku to zenkaku characters to 9:16"
    echo "  -k         Don't make calt settings for latin characters"
    echo "  -b         Make kerning settings for basic Latin characters only"
    echo "  -o         Enable optimization process when make kerning settings"
    echo "  -r         Reuse an existing list"
    echo "  -m         Disable edit cmap tables"
    echo "  -g         Disable edit GSUB tables"
    echo "  -t         Disable edit other tables"
    echo "  -C         End just before editing calt feature"
    echo "  -p         Run calt patch only"
}

# 設定読み込み
settings="settings" # 設定ファイル名
settings_txt=$(find . -maxdepth 1 -name "${settings}.txt" | head -n 1)
if [ -n "${settings_txt}" ]; then
    S=$(grep -m 1 "^FONT_FAMILYNAME=" "${settings_txt}") # フォントファミリー名
    if [ -n "${S}" ]; then font_familyname="${S#FONT_FAMILYNAME=}"; fi
fi

echo
echo "= Font tables Modificator ="
echo

# Get options
while getopts hxlN:wkbormgtCp OPT
do
    case "${OPT}" in
        "h" )
            table_modificator_help
            exit 0
            ;;
        "x" )
            echo "Option: Cleaning temporary files"
            remove_temp
            ./uvs_table_maker.sh -x -N "${font_familyname}"
            ./calt_table_maker.sh -x
            exit 0
            ;;
        "l" )
            echo "Option: Leave (do NOT remove) temporary files"
            leaving_tmp_flag="true"
            ;;
        "N" )
            echo "Option: Set fontfamily: ${OPTARG}"
            font_familyname=${OPTARG// /}
            ;;
        "w" )
            echo "Option: Set the ratio of hankaku to zenkaku characters to 9:16"
            loose_flag="true"
            hankaku_width="${hankaku_width_Loose}"
            ;;
        "k" )
            echo "Option: Don't make calt settings for latin characters"
            symbol_only_flag="true"
            ;;
        "b" )
            echo "Option: Make calt settings for basic Latin characters only"
            basic_only_flag="true"
            ;;
        "o" )
            echo "Option: Enable optimization process when make kerning settings"
            optimize_flag="true"
            ;;
        "r" )
            echo "Option: Reuse an existing list"
            reuse_list_flag="true"
            ;;
        "m" )
            echo "Option: Disable edit cmap tables"
            cmap_flag="false"
            ;;
        "g" )
            echo "Option: Disable edit GSUB tables"
            gsub_flag="false"
            ;;
        "t" )
            echo "Option: Disable edit other tables"
            other_flag="false"
            ;;
        "C" )
            echo "Option: End just before editing calt feature"
            option_check
            mode="-C"
            patch_only_flag="false"
            other_flag="true"
            cmap_flag="true"
            gsub_flag="true"
            calt_insert_flag="false"
            ;;
        "p" )
            echo "Option: Run calt patch only"
            option_check
            mode="-p"
            patch_only_flag="true"
            other_flag="false"
            cmap_flag="false"
            gsub_flag="true"
            calt_insert_flag="true"
            ;;
        * )
            table_modificator_help
            exit 1
            ;;
    esac
done
echo

# ttxファイルを削除、パッチのみの場合フォントをリネームして再利用
rm -f ${font_familyname}*.ttx ${font_familyname}*.ttx.bak
if [ "${patch_only_flag}" = "true" ]; then
  find . -maxdepth 1 -name "${font_familyname}*.orig.ttf" | while read P
  do
    mv -f "$P" "${P%%.orig.ttf}.ttf"
  done
fi

# フォントがあるかチェック
fontName_ttf=$(find . -maxdepth 1 -name "${font_familyname}*.ttf" | head -n 1)
if [ -z "${fontName_ttf}" ]; then
  echo "Error: ${font_familyname} not found" >&2
  exit 1
fi

# cmap GSUB 以外のテーブル更新 ----------
if [ "${other_flag}" = "true" ]; then
  find . -maxdepth 1 -not -name "*.*.ttf" | \
  grep -e "${font_familyname}.*\.ttf$" | while read P
  do
    ttx -t name -t head -t OS/2 -t post -t hmtx "$P" # フォントスタイル判定のため、name テーブルも取得
#    ttx -t name -t head -t OS/2 -t post -t vhea -t hmtx "$P" # 縦書き情報の取り扱いは中止

    # head, OS/2 (フォントスタイルを修正、Oblique の場合 Italic のフラグも立てた方がよい)
    if [ "$(grep -m 1 "Bold Oblique" "${P%%.ttf}.ttx")" ]; then
      sed -i.bak -e 's,macStyle value="........ ........",macStyle value="00000000 00000011",' "${P%%.ttf}.ttx"
      sed -i.bak -e 's,fsSelection value="........ ........",fsSelection value="00000011 10100001",' "${P%%.ttf}.ttx"
    elif [ "$(grep -m 1 "Oblique" "${P%%.ttf}.ttx")" ]; then
      sed -i.bak -e 's,macStyle value="........ ........",macStyle value="00000000 00000010",' "${P%%.ttf}.ttx"
      sed -i.bak -e 's,fsSelection value="........ ........",fsSelection value="00000011 10000001",' "${P%%.ttf}.ttx"
    elif [ "$(grep -m 1 "Bold" "${P%%.ttf}.ttx")" ]; then
      sed -i.bak -e 's,macStyle value="........ ........",macStyle value="00000000 00000001",' "${P%%.ttf}.ttx"
      sed -i.bak -e 's,fsSelection value="........ ........",fsSelection value="00000001 10100000",' "${P%%.ttf}.ttx"
    elif [ "$(grep -m 1 "Regular" "${P%%.ttf}.ttx")" ]; then
      sed -i.bak -e 's,macStyle value="........ ........",macStyle value="00000000 00000000",' "${P%%.ttf}.ttx"
      sed -i.bak -e 's,fsSelection value="........ ........",fsSelection value="00000001 11000000",' "${P%%.ttf}.ttx"
    fi

    # head (フォントの情報を修正)
    sed -i.bak -e 's,flags value="........ ........",flags value="00000000 00000011",' "${P%%.ttf}.ttx"

    # OS/2 (全体のWidthの修正)
    sed -i.bak -e "s,xAvgCharWidth value=\"...\",xAvgCharWidth value=\"${xAvg_char_width}\"," "${P%%.ttf}.ttx"

    # post (アンダーラインの位置を指定、等幅フォントであることを示す)
    sed -i.bak -e "s,underlinePosition value=\"-..\",underlinePosition value=\"${underline}\"," "${P%%.ttf}.ttx"
    sed -i.bak -e 's,isFixedPitch value=".",isFixedPitch value="1",' "${P%%.ttf}.ttx"

    # vhea
#    sed -i.bak -e "s,ascent value=\"...\",ascent value=\"${vhea_ascent1024}\"," "${P%%.ttf}.ttx"
#    sed -i.bak -e "s,descent value=\"-...\",descent value=\"-${vhea_descent1024}\"," "${P%%.ttf}.ttx"
#    sed -i.bak -e "s,lineGap value=\"...\",lineGap value=\"${vhea_linegap1024}\"," "${P%%.ttf}.ttx"

    # hmtx (Widthのブレを修正)
    sed -i.bak -e "s,width=\".\",width=\"${zero_width}\"," "${P%%.ttf}.ttx" # zero width
    sed -i.bak -e "s,width=\"3..\",width=\"${hankaku_width}\"," "${P%%.ttf}.ttx" # .notdef
    sed -i.bak -e "s,width=\"4..\",width=\"${hankaku_width}\"," "${P%%.ttf}.ttx" # 半角
    sed -i.bak -e "s,width=\"5..\",width=\"${hankaku_width}\"," "${P%%.ttf}.ttx"
    sed -i.bak -e "s,width=\"6..\",width=\"${hankaku_width}\"," "${P%%.ttf}.ttx"
    sed -i.bak -e "s,width=\"7..\",width=\"${hankaku_width}\"," "${P%%.ttf}.ttx"
    sed -i.bak -e "s,width=\"8..\",width=\"${zenkaku_width}\"," "${P%%.ttf}.ttx" # 全角
    sed -i.bak -e "s,width=\"9..\",width=\"${zenkaku_width}\"," "${P%%.ttf}.ttx"
    sed -i.bak -e "s,width=\"1...\",width=\"${zenkaku_width}\"," "${P%%.ttf}.ttx"

    # テーブル更新
    mv "$P" "${P%%.ttf}.orig.ttf"
    ttx -m "${P%%.ttf}.orig.ttf" "${P%%.ttf}.ttx"
    echo
  done
  rm -f ${font_familyname}*.orig.ttf
  rm -f ${font_familyname}*.ttx.bak

  find . -maxdepth 1 -not -name "*.*.ttx" | \
  grep -e "${font_familyname}.*\.ttx$" | while read P
  do
    mv "$P" "${P%%.ttx}.others.ttx"
  done
fi

# cmap テーブルの更新 ----------
if [ "${cmap_flag}" = "true" ]; then
  if [ "${reuse_list_flag}" = "false" ]; then
    rm -f ${cmapList}.txt
  fi
  cmaplist_txt=$(find . -maxdepth 1 -name "${cmapList}.txt" | head -n 1)
  if [ -z "${cmaplist_txt}" ]; then # cmapListが無ければ作成
    if [ "${leaving_tmp_flag}" = "true" ]; then
      ./uvs_table_maker.sh -l -N "${font_familyname}"
    else
      ./uvs_table_maker.sh -N "${font_familyname}"
    fi
  fi

  find . -maxdepth 1 -not -name "*.*.ttf" | \
  grep -e "${font_familyname}.*\.ttf$" | while read P
  do
    ttx -t cmap "$P"

    # cmap (format14を置き換える)
    sed -i.bak -e '/map uv=/d' "${P%%.ttf}.ttx" # cmap_format_14の中を削除
    sed -i.bak -e "/<cmap_format_14/r ${cmapList}.txt" "${P%%.ttf}.ttx" # cmap_format_14を置き換え

    # テーブル更新
    mv "$P" "${P%%.ttf}.orig.ttf"
    ttx -m "${P%%.ttf}.orig.ttf" "${P%%.ttf}.ttx"
    echo
  done
  rm -f ${font_familyname}*.orig.ttf
  rm -f ${font_familyname}*.ttx.bak

  find . -maxdepth 1 -not -name "*.*.ttx" | \
  grep -e "${font_familyname}.*\.ttx$" | while read P
  do
    mv "$P" "${P%%.ttx}.cmap.ttx"
  done
fi

# GSUB テーブルの更新 ----------
if [ "${gsub_flag}" = "true" ]; then # caltListを作り直す場合は今あるリストを削除
  if [ "${reuse_list_flag}" = "false" ]; then
    rm -f ${caltListName}*.txt
  fi

  find . -maxdepth 1 -not -name "*.*.ttf" | \
  grep -e "${font_familyname}.*\.ttf$" | while read P
  do
    calt_ok_flag="true" # calt不対応の場合は後でfalse
    ttx -t GSUB "$P"

    # GSUB (用字、言語全て共通に変更)
    if [ -n "$(grep -m 1 'FeatureTag value="calt"' "${P%%.ttf}.ttx")" ]; then # caltフィーチャがすでにあるか判定
      echo "Already calt feature exist. Do not overwrite the table."
    elif [ -n "$(grep -m 1 'FeatureTag value="zero"' "${P%%.ttf}.ttx")" ]; then # zeroフィーチャ(caltのダミー)があるか判定
      echo "Compatible with calt feature." # フォントがcaltフィーチャに対応していた場合
      # caltテーブル加工用ファイルの作成
      if [ "${calt_insert_flag}" = "true" ]; then
        gsublist_txt=$(find . -maxdepth 1 -name "${gsubList}.txt" | head -n 1)
        if [ -z "${gsublist_txt}" ]; then # gsubListが無ければ作成(calt_table_maker で使用するため)
          if [ "${leaving_tmp_flag}" = "true" ]; then
            ./uvs_table_maker.sh -l -N "${font_familyname}"
          else
            ./uvs_table_maker.sh -N "${font_familyname}"
          fi
        fi
        caltlist_txt=$(find . -maxdepth 1 -name "${caltListName}*.txt" | head -n 1)
        if [ -z "${caltlist_txt}" ]; then # caltListが無ければ作成
          option_format_cm opt_fg "" "${leaving_tmp_flag}" "${symbol_only_flag}" "${basic_only_flag}" "${optimize_flag}"
          ./calt_table_maker.sh -"${opt_fg}"
        fi
        # フィーチャリストを変更
        sed -i.bak -e 's,FeatureTag value="zero",FeatureTag value="calt",' "${P%%.ttf}.ttx" # caltダミー(zero)を変更
        find . -maxdepth 1 -name "${caltListName}*.txt" | while read line # caltList(caltルックアップ)の数だけループ
        do
          sed -i.bak -e "/Lookup index=\"${lookupIndex_calt}\"/{n;d;}" "${P%%.ttf}.ttx" # Lookup index="${lookupIndex_calt}"〜の中を削除
          sed -i.bak -e "/Lookup index=\"${lookupIndex_calt}\"/{n;d;}" "${P%%.ttf}.ttx"
          sed -i.bak -e "/Lookup index=\"${lookupIndex_calt}\"/{n;d;}" "${P%%.ttf}.ttx"
          sed -i.bak -e "/Lookup index=\"${lookupIndex_calt}\"/{n;d;}" "${P%%.ttf}.ttx"
          sed -i.bak -e "/Lookup index=\"${lookupIndex_calt}\"/{n;d;}" "${P%%.ttf}.ttx"
          sed -i.bak -e "/Lookup index=\"${lookupIndex_calt}\"/{n;d;}" "${P%%.ttf}.ttx"
          sed -i.bak -e "/Lookup index=\"${lookupIndex_calt}\"/r ${caltList}.txt" "${P%%.ttf}.ttx" # Lookup index="${lookupIndex_calt}"〜の後に挿入
          lookupIndex_calt=$((lookupIndex_calt + 1))
          listNo=$((listNo + 1))
          caltList="${caltListName}_${listNo}"
        done
      fi
    else
      echo "Not compatible with calt feature." # フォントが対応していないか、すでにcaltがある場合
      calt_ok_flag="false"
    fi
    # calt対応に関係なくスクリプトリストを変更
    sed -i.bak -e '/FeatureIndex index=".." value=".."/d' "${P%%.ttf}.ttx" # 2桁のindexを削除

    sed -i.bak -e 's,FeatureIndex index="0" value=".",FeatureIndex index="0" value="0",' "${P%%.ttf}.ttx" # 始めの部分は上書き
    sed -i.bak -e 's,FeatureIndex index="1" value=".",FeatureIndex index="1" value="3",' "${P%%.ttf}.ttx"
    sed -i.bak -e 's,FeatureIndex index="2" value=".",FeatureIndex index="2" value="6",' "${P%%.ttf}.ttx"
    sed -i.bak -e 's,FeatureIndex index="3" value=".",FeatureIndex index="3" value="7",' "${P%%.ttf}.ttx"
    sed -i.bak -e 's,FeatureIndex index="4" value=".",FeatureIndex index="4" value="8",' "${P%%.ttf}.ttx"
    sed -i.bak -e 's,FeatureIndex index="5" value=".",FeatureIndex index="5" value="9",' "${P%%.ttf}.ttx"
    sed -i.bak -e 's,FeatureIndex index="6" value="..",FeatureIndex index="6" value="10",' "${P%%.ttf}.ttx"
    sed -i.bak -e 's,FeatureIndex index="7" value="..",FeatureIndex index="7" value="11",' "${P%%.ttf}.ttx"
    sed -i.bak -e 's,FeatureIndex index="8" value="..",FeatureIndex index="8" value="12",' "${P%%.ttf}.ttx"

    if [ -n "$(grep -m 1 'FeatureTag value="ss01"' "${P%%.ttf}.ttx")" ]; then # ssフィーチャがあるか判定、ss対応の場合
      sed -i.bak -e 's,<FeatureIndex index="9" value=".."/>,<FeatureIndex index="9" value="13"/>\
      <FeatureIndex index="10" value="14"/>\
      <FeatureIndex index="11" value="15"/>\
      <FeatureIndex index="12" value="16"/>\
      <FeatureIndex index="13" value="17"/>\
      <FeatureIndex index="14" value="18"/>\
      <FeatureIndex index="15" value="19"/>\
      <FeatureIndex index="16" value="20"/>\
      <FeatureIndex index="17" value="21"/>\
      <FeatureIndex index="18" value="22"/>\
      <FeatureIndex index="19" value="23"/>\
      <FeatureIndex index="20" value="24"/>\
      <FeatureIndex index="21" value="25"/>\
      <FeatureIndex index="22" value="26"/>\
      <FeatureIndex index="23" value="27"/>\
      ,' "${P%%.ttf}.ttx" # index9を上書き、以降 index(12 + ss フィーチャの数)、value(index + 4) を追加
      if [ "${calt_ok_flag}" = "true" ]; then # calt対応であればさらに1つ index 追加
        sed -i.bak -e 's,<FeatureIndex index="23" value=".."/>,<FeatureIndex index="23" value="27"/>\
        <FeatureIndex index="24" value="28"/>\
        ,' "${P%%.ttf}.ttx"
      fi
    else # ss非対応の場合
      sed -i.bak -e 's,<FeatureIndex index="9" value=".."/>,<FeatureIndex index="9" value="13"/>\
      <FeatureIndex index="10" value="14"/>\
      <FeatureIndex index="11" value="15"/>\
      <FeatureIndex index="12" value="16"/>\
      ,' "${P%%.ttf}.ttx" # index9を上書き、以降 index12 まで追加
      if [ "${calt_ok_flag}" = "true" ]; then # calt対応であれば index13 を追加
        sed -i.bak -e 's,<FeatureIndex index="12" value=".."/>,<FeatureIndex index="12" value="16"/>\
        <FeatureIndex index="13" value="17"/>\
        ,' "${P%%.ttf}.ttx"
      fi
    fi

    sed -i.bak -e '/<LangSys>/{n;d;}' "${P%%.ttf}.ttx" # LangSysタグとその間を削除
    sed -i.bak -e '/<LangSys>/{n;d;}' "${P%%.ttf}.ttx"
    sed -i.bak -e '/<LangSys>/{n;d;}' "${P%%.ttf}.ttx"
    sed -i.bak -e '/<LangSys>/{n;d;}' "${P%%.ttf}.ttx"
    sed -i.bak -e '/<LangSys>/d' "${P%%.ttf}.ttx"
    sed -i.bak -e '/<\/LangSys>/d' "${P%%.ttf}.ttx"

    sed -i.bak -e '/LangSysRecord/d' "${P%%.ttf}.ttx" # LangSysRecordタグを削除
    sed -i.bak -e '/LangSysTag/d' "${P%%.ttf}.ttx" # LangSysTagタグを削除

    # テーブル更新
    mv "$P" "${P%%.ttf}.orig.ttf"
    ttx -m "${P%%.ttf}.orig.ttf" "${P%%.ttf}.ttx"
    echo
  done
  if [ "${patch_only_flag}" = "false" ] && [ "${calt_insert_flag}" = "true" ]; then # パッチのみの場合、再利用できるように元のファイルを残す
    rm -f ${font_familyname}*.orig.ttf
  fi
  rm -f ${font_familyname}*.ttx.bak

  find . -maxdepth 1 -not -name "*.*.ttx" | \
  grep -e "${font_familyname}.*\.ttx$" | while read P
  do
    mv "$P" "${P%%.ttx}.GSUB.ttx"
  done
fi

# 一時ファイルを削除
if [ "${leaving_tmp_flag}" = "false" ]; then
  remove_temp
  echo
fi

# Exit
echo "Finished modifying the font tables."
echo
exit 0
