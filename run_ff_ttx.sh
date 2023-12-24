#!/bin/bash
set -e

# FontForge and TTX runner
#
# Copyright (c) 2023 omonomo

# 一連の操作を自動化したプログラム

font_familyname="Cyroit"
tmpdir_name="font_generator_tmpdir" # font_generatorのテンポラリフォルダ名

font_familyname_suffix=("HB" "SP" "TM" "TS" "FX" "DG" "DS") # バージョン違いの名称
build_fonts_dir="build" # 完成品を保管するフォルダ

font_version="0.1.0"

version="version"
version_txt=`find . -name "${version}.txt" -maxdepth 1 | head -n 1`
if [ -n "${version_txt}" ]; then
  font_v=`cat ${version_txt} | head -n 1`
  if [ -n "${font_v}" ]; then
    font_version=${font_v}
  fi
fi

forge_ttx_help()
{
    echo "Usage: run_ff_ttx.sh [options]"
    echo ""
    echo "Option:"
    echo "  -h  Display this information"
    echo "  -d  Draft mode (skip time-consuming processes)" # グリフ変更の確認用 (最後は通常モードで確認すること)
    echo "  -C  End just before editing calt feature" # caltの編集・確認を繰り返す時用にcalt適用前のフォントを作成する
    echo "  -p  Run calt patch only" # -C の続きを実行
    echo "  -c  Disable calt feature" # calt有無の見た目確認用
    echo "  -e  Disable add Nerd fonts" # NerdFonts無しの場合のサイズ確認用
    echo "  -F  Complete Mode (generate finished fonts)" # 完成品作成
}

# フォント作成
if [ $# -eq 0 ]; then
  echo "Normal Mode"
  sh font_generator.sh -l -o -N "${font_familyname}" auto
elif [ "$1" = "-d" ]; then
  echo "Draft Mode"
  sh font_generator.sh -l -d -o -P -N "${font_familyname}" auto
  exit 0 # 下書きモードの場合テーブルを編集しない
elif [ "$1" = "-C" ]; then
  echo "End just before editing calt feature"
  sh font_generator.sh -l -Z -z -t -o -N "${font_familyname}" auto
elif [ "$1" = "-p" ]; then
  echo "Run calt patch only"
  sh table_modificator.sh -p -l
  exit 0
elif [ "$1" = "-c" ]; then
  echo "Disable calt feature"
  sh font_generator.sh -l -z -t -c -o -N "${font_familyname}" auto
elif [ "$1" = "-e" ]; then
  echo "Disable add Nerd fonts"
  sh font_generator.sh -l -e -o -N "${font_familyname}" auto
elif [ "$1" = "-F" ]; then
  echo "Complete Mode (generate finished fonts)"
  sh font_generator.sh -P -N "${font_familyname}" auto # パッチ適用直前まで作成
elif [ "$1" = "-h" ]; then
  forge_ttx_help
  exit 0
else
  echo "illegal option."
  echo
  forge_ttx_help
  exit 1
fi

# 完成品作成のためフォントにパッチを当てる
if [ "$1" = "-F" ]; then
  for S in ${font_familyname_suffix[@]}; do
    if [ "${S}" = "HB" ]; then
      sh font_generator.sh -Z -z -b -t -g -p -N "${font_familyname}" -n "${S}"
    fi
    if [ "${S}" = "SP" ]; then
      sh font_generator.sh -t -g -p -N "${font_familyname}" -n "${S}"
    fi
    if [ "${S}" = "TM" ]; then
      sh font_generator.sh -z -p -N "${font_familyname}" -n "${S}"
    fi
    if [ "${S}" = "TS" ]; then
      sh font_generator.sh -p -N "${font_familyname}" -n "${S}"
    fi
    if [ "${S}" = "FX" ]; then
      sh font_generator.sh -z -t -c -p -N "${font_familyname}" -n "${S}"
    fi
    if [ "${S}" = "DG" ]; then
      sh font_generator.sh -z -t -p -N "${font_familyname}" -n "${S}"
    fi
    if [ "${S}" = "DS" ]; then
      sh font_generator.sh -t -p -N "${font_familyname}" -n "${S}"
    fi
    sh font_generator.sh -z -t -g -p -N "${font_familyname}" # 通常
  done
fi

# テーブル加工
if [ "$1" = "-C" ]; then
  sh table_modificator.sh -l -C -N "${font_familyname}"
  exit 0
elif [ "$1" = "-F" ]; then
  sh table_modificator.sh -N "${font_familyname}"
else
  sh table_modificator.sh -l -N "${font_familyname}"
fi

# 完成したフォントの移動と一時ファイルの削除
if [ "$1" = "-F" ]; then
  echo "Remove temporary folders and files"
  rm -rf ${tmpdir_name}.*
  rm -f ${font_familyname}*.nopatch.ttf

  echo "Move finished fonts"
  mkdir -p "${build_fonts_dir}"
  for S in ${font_familyname_suffix[@]}; do
    mkdir -p "${build_fonts_dir}/${S}"
    mv -f ${font_familyname}${S}*.ttf "${build_fonts_dir}/${S}/."
  done
  mv -f ${font_familyname}*.ttf "${build_fonts_dir}/."
  echo

  # Exit
  echo "Succeeded in generating custom fonts!"
  echo "Font version : ${font_version}"
  echo
fi
exit 0
