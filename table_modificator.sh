#!/bin/bash

# Table modificator
#
# Copyright (c) 2023 omonomo

# 各種テーブルの修正・追加プログラム
#

font_familyname="Cyroit"

glyphNo_without_nerd="13704" # calt用異体字の先頭glyphナンバー (Nerd Fontsなし)
glyphNo_with_nerd="22862" # calt用異体字の先頭glyphナンバー (Nerd Fontsあり)

lookupIndex_calt="17"
listNo="0"
caltL="caltList"
caltList="${caltL}_${listNo}"
cmapList="cmapList"
extList="extList"
gsubList="gsubList"

half_width="512" # 半角文字幅
full_width="1024" # 全角文字幅
underline="-80" # アンダーライン位置
#vhea_ascent1024="994"
#vhea_descent1024="256"
#vhea_linegap1024="0"

leaving_tmp_flag="false" # 一時ファイル残す

cmap_flag="true" # cmapを編集するか
gsub_flag="true" # GSUBを編集するか
other_flag="true" # その他を編集するか

calt_insert_flag="true" # caltテーブルを挿入するか
patch_only_flag="false" # パッチモード
calt_ok_flag_l="true" # calt対応に必要なファイル(gsubList)があるか
calt_ok_flag_f="true" # フォントがcaltに対応しているか

# エラー処理
trap "exit 3" HUP INT QUIT

echo
echo "= Font tables Modificator ="
echo

table_modificator_help()
{
    echo "Usage: table_modificator.sh [options]"
    echo ""
    echo "Options:"
    echo "  -h         Display this information"
    echo "  -l         Leave (do NOT remove) temporary files"
    echo "  -N string  Set fontfamily (\"string\")"
    echo "  -m         Disable edit cmap tables"
    echo "  -g         Disable edit GSUB tables"
    echo "  -t         Disable edit other tables"
    echo "  -C         End just before editing calt feature"
    echo "  -p         Run calt patch only"
    exit 0
}

# Get options
while getopts hlN:mgtCp OPT
do
    case "${OPT}" in
        "h" )
            table_modificator_help
            ;;
        "l" )
            echo "Option: Leave (do NOT remove) temporary files"
            leaving_tmp_flag="true"
            ;;
        "N" )
            echo "Option: Set fontfamily: ${OPTARG}"
            font_familyname=`echo $OPTARG | tr -d ' '`
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
            calt_insert_flag="false"
            ;;
        "p" )
            echo "Option: Run calt patch only"
            patch_only_flag="true"
            cmap_flag="false"
            other_flag="false"
            ;;
        * )
            exit 1
            ;;
    esac
done

# ttxファイルを削除、パッチのみの場合フォントをリネームして再利用
rm -f ${font_familyname}*.ttx ${font_familyname}*.ttx.bak
if [ "${patch_only_flag}" = "true" ]; then
  find . -name "${font_familyname}*.orig.ttf" -maxdepth 1 | while read P
  do
    mv -f "$P" "${P%%.orig.ttf}.ttf"
  done
fi

# フォントがあるかチェック
fontName_ttf=`find . -name "${font_familyname}*.ttf" -maxdepth 1 | head -n 1`
if [ -z "${fontName_ttf}" ]; then
  echo "Error: ${font_familyname} not found" >&2
  exit 1
fi

if [ "${other_flag}" = "true" ]; then
  find . -not -name "*.*.ttf" -maxdepth 1 | \
  grep -e "${font_familyname}.*\.ttf$" | while read P
  do
    ttx -t name -t head -t OS/2 -t post -t hmtx "$P"
#    ttx -t name -t head -t OS/2 -t post -t vhea -t hmtx "$P" # 縦書き情報の取り扱いは中止

    # head, OS/2 (フォントスタイルを修正)
    if [ "$(cat ${P%%.ttf}.ttx | grep "Bold Oblique")" ]; then
      sed -i.bak -e 's,macStyle value="........ ........",macStyle value="00000000 00000011",' "${P%%.ttf}.ttx"
      sed -i.bak -e 's,fsSelection value="........ ........",fsSelection value="00000010 10100001",' "${P%%.ttf}.ttx"
    elif [ "$(cat ${P%%.ttf}.ttx | grep "Oblique")" ]; then
      sed -i.bak -e 's,macStyle value="........ ........",macStyle value="00000000 00000010",' "${P%%.ttf}.ttx"
      sed -i.bak -e 's,fsSelection value="........ ........",fsSelection value="00000010 10000001",' "${P%%.ttf}.ttx"
    elif [ "$(cat ${P%%.ttf}.ttx | grep "Bold")" ]; then
      sed -i.bak -e 's,macStyle value="........ ........",macStyle value="00000000 00000001",' "${P%%.ttf}.ttx"
      sed -i.bak -e 's,fsSelection value="........ ........",fsSelection value="00000000 10100000",' "${P%%.ttf}.ttx"
    elif [ "$(cat ${P%%.ttf}.ttx | grep "Regular")" ]; then
      sed -i.bak -e 's,macStyle value="........ ........",macStyle value="00000000 00000000",' "${P%%.ttf}.ttx"
      sed -i.bak -e 's,fsSelection value="........ ........",fsSelection value="00000000 11000000",' "${P%%.ttf}.ttx"
    fi

    # head (フォントの情報を修正)
    sed -i.bak -e 's,flags value="........ ........",flags value="00000000 00000011",' "${P%%.ttf}.ttx"

    # OS/2 (全体のWidthの修正)
    sed -i.bak -e "s,xAvgCharWidth value=\"...\",xAvgCharWidth value=\"${half_width}\"," "${P%%.ttf}.ttx"

    # post (アンダーラインの位置を指定、等幅フォントであることを示す)
    sed -i.bak -e "s,underlinePosition value=\"-..\",underlinePosition value=\"${underline}\"," "${P%%.ttf}.ttx"
    sed -i.bak -e 's,isFixedPitch value=".",isFixedPitch value="1",' "${P%%.ttf}.ttx"

    # vhea
#    sed -i.bak -e "s,ascent value=\"...\",ascent value=\"${vhea_ascent1024}\"," "${P%%.ttf}.ttx"
#    sed -i.bak -e "s,descent value=\"-...\",descent value=\"-${vhea_descent1024}\"," "${P%%.ttf}.ttx"
#    sed -i.bak -e "s,lineGap value=\"...\",lineGap value=\"${vhea_linegap1024}\"," "${P%%.ttf}.ttx"

    # hmtx (Widthのブレを修正)
    sed -i.bak -e "s,width=\"3..\",width=\"${half_width}\"," "${P%%.ttf}.ttx" # .notdef
    sed -i.bak -e "s,width=\"4..\",width=\"${half_width}\"," "${P%%.ttf}.ttx" # 半角
    sed -i.bak -e "s,width=\"5..\",width=\"${half_width}\"," "${P%%.ttf}.ttx"
    sed -i.bak -e "s,width=\"9..\",width=\"${full_width}\"," "${P%%.ttf}.ttx" # 全角
    sed -i.bak -e "s,width=\"1...\",width=\"${full_width}\"," "${P%%.ttf}.ttx"

    # テーブル更新
    mv "$P" "${P%%.ttf}.orig.ttf"
    ttx -m "${P%%.ttf}.orig.ttf" "${P%%.ttf}.ttx"
    echo
  done
  rm -f ${font_familyname}*.orig.ttf
  rm -f ${font_familyname}*.ttx.bak

  find . -not -name "*.*.ttx" -maxdepth 1 | \
  grep -e "${font_familyname}.*\.ttx$" | while read P
  do
    mv "$P" "${P%%.ttx}.others.ttx"
  done
fi

# cmapテーブル加工用ファイルの作成
if [ "${cmap_flag}" = "true" ]; then
  if [ "${leaving_tmp_flag}" = "true" ]; then
    sh uvs_table_maker.sh -l -N "${font_familyname}"
  else
    sh uvs_table_maker.sh -N "${font_familyname}"
  fi

  find . -not -name "*.*.ttf" -maxdepth 1 | \
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

  find . -not -name "*.*.ttx" -maxdepth 1 | \
  grep -e "${font_familyname}.*\.ttx$" | while read P
  do
    mv "$P" "${P%%.ttx}.cmap.ttx"
  done
fi

if [ "${gsub_flag}" = "true" ]; then
  rm -f ${caltL}*.txt
  gsubList_txt=`find . -name "${gsubList}.txt" -maxdepth 1 | head -n 1`
  if [ -n "${gsubList_txt}" ]; then # gsubListがあり、
    caltNo=`grep 'Substitution in="A"' "${gsubList}.txt"`
    if [ -n "${caltNo}" ]; then # calt用の異体字があった場合gSubListからglyphナンバーを取得
      temp=${caltNo##*glyph} # glyphナンバーより前を削除
      glyphNo=${temp%\"*} # glyphナンバーより後を削除してオフセット値追加
    else
      echo "Can't find glyph number of \"A moved left\""
      echo
      calt_ok_flag_l="false"
    fi
  else
    echo "Can't find GSUB List"
    echo
    calt_ok_flag_l="false"
  fi

  find . -not -name "*.*.ttf" -maxdepth 1 | \
  grep -e "${font_familyname}.*\.ttf$" | while read P
  do
    calt_ok_flag_f="true"
    ttx -t GSUB "$P"

    # GSUB (用字、言語全て共通に変更)
    gpc=`grep 'FeatureTag value="calt"' "${P%%.ttf}.ttx"` # caltフィーチャがすでにあるか判定
    gpz=`grep 'FeatureTag value="zero"' "${P%%.ttf}.ttx"` # zeroフィーチャ(caltのダミー)があるか判定
    if [ -n "${gpc}" ]; then
      echo "Already calt feature exist. Do not overwrite the table."
    elif [ -n "${gpz}" ]; then
      echo "Compatible with calt feature."
      # caltテーブル加工用ファイルの作成
      if [ "${calt_insert_flag}" = "true" ]; then
        caltlist_txt=`find . -name "${caltL}*.txt" -maxdepth 1 | head -n 1`
        if [ -z "${caltlist_txt}" ]; then #caltListが無ければ作成
          if [ "${patch_only_flag}" = "true" ]; then
            if [ "${leaving_tmp_flag}" = "true" ]; then
              sh calt_table_maker.sh -b -l -n ${glyphNo}
            else
              sh calt_table_maker.sh -b -n ${glyphNo}
            fi
          else
            if [ "${leaving_tmp_flag}" = "true" ]; then
              sh calt_table_maker.sh -l -n ${glyphNo}
            else
              sh calt_table_maker.sh -n ${glyphNo}
            fi
          fi
        fi
        # フォントがcaltフィーチャに対応していた場合フィーチャリストを変更
        sed -i.bak -e 's,FeatureTag value="zero",FeatureTag value="calt",' "${P%%.ttf}.ttx" # caltダミー(zero)を変更
        find . -name "${caltL}*.txt" -maxdepth 1 | while read line # caltList(caltルックアップ)の数だけループ
        do
          sed -i.bak -e "/Lookup index=\"${lookupIndex_calt}\"/{n;d;}" "${P%%.ttf}.ttx" # Lookup index="17"〜の中を削除
          sed -i.bak -e "/Lookup index=\"${lookupIndex_calt}\"/{n;d;}" "${P%%.ttf}.ttx"
          sed -i.bak -e "/Lookup index=\"${lookupIndex_calt}\"/{n;d;}" "${P%%.ttf}.ttx"
          sed -i.bak -e "/Lookup index=\"${lookupIndex_calt}\"/{n;d;}" "${P%%.ttf}.ttx"
          sed -i.bak -e "/Lookup index=\"${lookupIndex_calt}\"/{n;d;}" "${P%%.ttf}.ttx"
          sed -i.bak -e "/Lookup index=\"${lookupIndex_calt}\"/{n;d;}" "${P%%.ttf}.ttx"
          sed -i.bak -e "/Lookup index=\"${lookupIndex_calt}\"/r ${caltList}.txt" "${P%%.ttf}.ttx" # Lookup index="17"〜の後に挿入
          lookupIndex_calt=`expr ${lookupIndex_calt} + 1`
          listNo=`expr ${listNo} + 1`
          caltList="${caltL}_${listNo}"
        done
      fi
    else
      echo "Not compatible with calt feature."
      calt_ok_flag_f="false"
    fi
    # calt対応に関係なくスクリプトリストを変更
    sed -i.bak -e '/FeatureIndex index="10" value=".."/d' "${P%%.ttf}.ttx" # 最少のindex数が9なので10以降を削除して数を合わせる
    sed -i.bak -e '/FeatureIndex index="11" value=".."/d' "${P%%.ttf}.ttx"
    sed -i.bak -e '/FeatureIndex index="12" value=".."/d' "${P%%.ttf}.ttx"
    sed -i.bak -e '/FeatureIndex index="13" value=".."/d' "${P%%.ttf}.ttx"

    sed -i.bak -e 's,FeatureIndex index="0" value=".",FeatureIndex index="0" value="0",' "${P%%.ttf}.ttx" # 始めの部分は上書き
    sed -i.bak -e 's,FeatureIndex index="1" value=".",FeatureIndex index="1" value="1",' "${P%%.ttf}.ttx"
    sed -i.bak -e 's,FeatureIndex index="2" value=".",FeatureIndex index="2" value="4",' "${P%%.ttf}.ttx"
    sed -i.bak -e 's,FeatureIndex index="3" value=".",FeatureIndex index="3" value="5",' "${P%%.ttf}.ttx"
    sed -i.bak -e 's,FeatureIndex index="4" value=".",FeatureIndex index="4" value="6",' "${P%%.ttf}.ttx"
    sed -i.bak -e 's,FeatureIndex index="5" value=".",FeatureIndex index="5" value="7",' "${P%%.ttf}.ttx"
    sed -i.bak -e 's,FeatureIndex index="6" value=".",FeatureIndex index="6" value="8",' "${P%%.ttf}.ttx"

    sed -i.bak -e 's,FeatureIndex index="7" value=".",FeatureIndex index="7" value="9",' "${P%%.ttf}.ttx" # index7 は valueが1桁と2桁の2つの場合がある
    sed -i.bak -e 's,FeatureIndex index="7" value="..",FeatureIndex index="7" value="9",' "${P%%.ttf}.ttx"

    sed -i.bak -e 's,FeatureIndex index="8" value="..",FeatureIndex index="8" value="10",' "${P%%.ttf}.ttx"

    if [ "${calt_ok_flag_l}" = "true" ] && [ "${calt_ok_flag_f}" = "true" ]; then # calt対応であれば index13を追加
      sed -i.bak -e 's,<FeatureIndex index="9" value=".."/>,<FeatureIndex index="9" value="11"/>\
      <FeatureIndex index="10" value="12"/>\
      <FeatureIndex index="11" value="13"/>\
      <FeatureIndex index="12" value="14"/>\
      <FeatureIndex index="13" value="15"/>,' "${P%%.ttf}.ttx" # index9を上書き、以降は追加
    else
      sed -i.bak -e 's,<FeatureIndex index="9" value=".."/>,<FeatureIndex index="9" value="11"/>\
      <FeatureIndex index="10" value="12"/>\
      <FeatureIndex index="11" value="13"/>\
      <FeatureIndex index="12" value="14"/>,' "${P%%.ttf}.ttx" # index9を上書き、以降は追加
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

  find . -not -name "*.*.ttx" -maxdepth 1 | \
  grep -e "${font_familyname}.*\.ttx$" | while read P
  do
    mv "$P" "${P%%.ttx}.GSUB.ttx"
  done
fi

# 一時ファイルを削除
if [ "${leaving_tmp_flag}" = "false" ]; then
  echo "Remove temporary files"
  rm -f ${font_familyname}*.ttx
  rm -f ${font_familyname}*.ttx.bak
  rm -f ${caltL}*.txt
  rm -f ${cmapList}.txt
  rm -f ${extList}.txt
  rm -f ${gsubList}.txt
  echo
fi

# Exit
echo "Finished modifying the font tables."
echo
exit 0
