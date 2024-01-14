#!/bin/bash

# Table modificator
#
# Copyright (c) 2023 omonomo

# 各種テーブルの修正・追加プログラム
#

font_familyname="Cyroit"

lookupIndex_calt="17" # caltテーブルのlookupナンバー
listNo="0"
caltL="caltList" # caltテーブルリストの名称
caltList="${caltL}_${listNo}" # Lookupごとのcaltテーブルリスト
cmapList="cmapList" # 異体字セレクタリスト
extList="extList" # 異体字のglyphナンバーリスト
gsubList="gsubList" # 作成フォントのGSUBから抽出した置き換え用リスト

half_width="512" # 半角文字幅
full_width="1024" # 全角文字幅
underline="-80" # アンダーライン位置
#vhea_ascent1024="994"
#vhea_descent1024="256"
#vhea_linegap1024="0"

mode="" # 生成モード

leaving_tmp_flag="false" # 一時ファイル残す

cmap_flag="true" # cmapを編集するか
gsub_flag="true" # GSUBを編集するか
other_flag="true" # その他を編集するか
reuse_list_flag="false" # 生成済みのリストを使かうか

calt_insert_flag="true" # caltテーブルを挿入するか
patch_only_flag="false" # caltテーブルのみ編集
calt_ok_flag="true" # フォントがcaltに対応しているか

basic_only_flag="false" # calt設定を基本ラテン文字に限定

# エラー処理
trap "exit 3" HUP INT QUIT

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
  rm -f ${caltL}*.txt
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
    echo "  -m         Disable edit cmap tables"
    echo "  -g         Disable edit GSUB tables"
    echo "  -t         Disable edit other tables"
    echo "  -C         End just before editing calt feature"
    echo "  -p         Run calt patch only"
    echo "  -b         Make calt settings for basic Latin characters only"
    echo "  -r         Reuse an existing list"
    exit 0
}

echo
echo "= Font tables Modificator ="
echo

# Get options
while getopts hxlN:mgtCpbr OPT
do
    case "${OPT}" in
        "h" )
            table_modificator_help
            ;;
        "x" )
            echo "Option: Cleaning temporary files"
            remove_temp
            sh uvs_table_maker.sh -x
            sh calt_table_maker.sh -x
            exit 0
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
        "b" )
            echo "Option: Make calt settings for basic Latin characters only"
            basic_only_flag="true"
            ;;
        "r" )
            echo "Option: Reuse an existing list"
            reuse_list_flag="true"
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

# cmap GSUB 以外のテーブル更新 ----------
if [ "${other_flag}" = "true" ]; then
  find . -not -name "*.*.ttf" -maxdepth 1 | \
  grep -e "${font_familyname}.*\.ttf$" | while read P
  do
    ttx -t head -t OS/2 -t post -t hmtx "$P"
#    ttx -t head -t OS/2 -t post -t vhea -t hmtx "$P" # 縦書き情報の取り扱いは中止

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

# cmap テーブルの更新 ----------
if [ "${cmap_flag}" = "true" ]; then
  if [ "${reuse_list_flag}" = "false" ]; then
    rm -f ${cmapList}.txt
  fi
  cmaplist_txt=`find . -name "${cmapList}.txt" -maxdepth 1 | head -n 1`
  if [ -z "${cmaplist_txt}" ]; then # cmapListが無ければ作成
    if [ "${leaving_tmp_flag}" = "true" ]; then
      sh uvs_table_maker.sh -l -N "${font_familyname}"
    else
      sh uvs_table_maker.sh -N "${font_familyname}"
    fi
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

# GSUB テーブルの更新 ----------
if [ "${gsub_flag}" = "true" ]; then # caltListを作り直す場合は今あるリストを削除
  if [ "${reuse_list_flag}" = "false" ]; then
    rm -f ${caltL}*.txt
  fi

  find . -not -name "*.*.ttf" -maxdepth 1 | \
  grep -e "${font_familyname}.*\.ttf$" | while read P
  do
    calt_ok_flag="true" # calt不対応の場合は後でfalse
    ttx -t GSUB "$P"

    # GSUB (用字、言語全て共通に変更)
    gpc=`grep 'FeatureTag value="calt"' "${P%%.ttf}.ttx"` # caltフィーチャがすでにあるか判定
    gpz=`grep 'FeatureTag value="zero"' "${P%%.ttf}.ttx"` # zeroフィーチャ(caltのダミー)があるか判定
    if [ -n "${gpc}" ]; then
      echo "Already calt feature exist. Do not overwrite the table."
    elif [ -n "${gpz}" ]; then
      echo "Compatible with calt feature." # フォントがcaltフィーチャに対応していた場合
      # caltテーブル加工用ファイルの作成
      if [ "${calt_insert_flag}" = "true" ]; then
        gsublist_txt=`find . -name "${gsubList}.txt" -maxdepth 1 | head -n 1`
        if [ -z "${gsublist_txt}" ]; then # gsubListが無ければ作成(calt_table_maker で使用するため)
          if [ "${leaving_tmp_flag}" = "true" ]; then
            sh uvs_table_maker.sh -l -N "${font_familyname}"
          else
            sh uvs_table_maker.sh -N "${font_familyname}"
          fi
        fi
        caltlist_txt=`find . -name "${caltL}*.txt" -maxdepth 1 | head -n 1`
        if [ -z "${caltlist_txt}" ]; then # caltListが無ければ作成
          if [ "${basic_only_flag}" = "true" ]; then
            if [ "${leaving_tmp_flag}" = "true" ]; then
              sh calt_table_maker.sh -lb
            else
              sh calt_table_maker.sh -b
            fi
          else
            if [ "${leaving_tmp_flag}" = "true" ]; then
              sh calt_table_maker.sh -l
            else
              sh calt_table_maker.sh
            fi
          fi
        fi
        # フィーチャリストを変更
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
      echo "Not compatible with calt feature." # フォントが対応していないか、すでにcaltがある場合
      calt_ok_flag="false"
    fi
    # calt対応に関係なくスクリプトリストを変更
    sed -i.bak -e '/FeatureIndex index="10" value=".."/d' "${P%%.ttf}.ttx" # 最少のindex数が9なので10以降を削除して数を合わせる
    sed -i.bak -e '/FeatureIndex index="11" value=".."/d' "${P%%.ttf}.ttx"
    sed -i.bak -e '/FeatureIndex index="12" value=".."/d' "${P%%.ttf}.ttx"
    sed -i.bak -e '/FeatureIndex index="13" value=".."/d' "${P%%.ttf}.ttx"
    sed -i.bak -e '/FeatureIndex index="14" value=".."/d' "${P%%.ttf}.ttx"
    sed -i.bak -e '/FeatureIndex index="15" value=".."/d' "${P%%.ttf}.ttx"

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

    gps=`grep 'FeatureTag value="ss01"' "${P%%.ttf}.ttx"` # ssフィーチャがあるか判定
    if [ -n "${gps}" ]; then # ss対応の場合
      sed -i.bak -e 's,<FeatureIndex index="9" value=".."/>,<FeatureIndex index="9" value="11"/>\
      <FeatureIndex index="10" value="12"/>\
      <FeatureIndex index="11" value="13"/>\
      <FeatureIndex index="12" value="14"/>\
      <FeatureIndex index="13" value="15"/>\
      <FeatureIndex index="14" value="16"/>\
      <FeatureIndex index="15" value="17"/>\
      <FeatureIndex index="16" value="18"/>\
      <FeatureIndex index="17" value="19"/>\
      <FeatureIndex index="18" value="20"/>\
      <FeatureIndex index="19" value="21"/>\
      <FeatureIndex index="20" value="22"/>\
      ,' "${P%%.ttf}.ttx" # index9を上書き、以降 index(12 + ss フィーチャの数) を追加
      if [ "${calt_ok_flag}" = "true" ]; then # calt対応であればさらに1つ index 追加
        sed -i.bak -e 's,<FeatureIndex index="20" value="22"/>,<FeatureIndex index="20" value="22"/>\
        <FeatureIndex index="21" value="23"/>\
        ,' "${P%%.ttf}.ttx"
      fi
    else # ss非対応の場合
      sed -i.bak -e 's,<FeatureIndex index="9" value=".."/>,<FeatureIndex index="9" value="11"/>\
      <FeatureIndex index="10" value="12"/>\
      <FeatureIndex index="11" value="13"/>\
      <FeatureIndex index="12" value="14"/>\
      ,' "${P%%.ttf}.ttx" # index9を上書き、以降 index12 まで追加
      if [ "${calt_ok_flag}" = "true" ]; then # calt対応であれば index13 を追加
        sed -i.bak -e 's,<FeatureIndex index="12" value="14"/>,<FeatureIndex index="12" value="14"/>\
        <FeatureIndex index="13" value="15"/>\
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

  find . -not -name "*.*.ttx" -maxdepth 1 | \
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
