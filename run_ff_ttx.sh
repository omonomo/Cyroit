#!/bin/bash
set -e

# FontForge and TTX runner
#
# Copyright (c) 2023 omonomo
#
# 一連の操作を自動化するプログラム


# ログをファイル出力させる場合は有効にする (コメントアウトさせる)
<< "#LOG"
LOG_OUT=/tmp/run_ff_ttx.log
LOG_ERR=/tmp/run_ff_ttx_err.log
exec 1> >(tee -a $LOG_OUT)
exec 2> >(tee -a $LOG_ERR)
#LOG

font_familyname="Cyroit"
font_familyname_suffix=""

font_familyname_suffix_def=(BS SP FX HB DG) # バージョン違いの名称 (デフォルト設定)
font_familyname_suffix_def_opt=(ztsp tsp ztcp Zzubtsp ztp) # 各バージョンのオプション (デフォルト設定)
#font_familyname_suffix_def=(BS SP FX HB DG DS TM TS)
#font_familyname_suffix_def_opt=(ztsp tsp ztcp Zzubtsp ztp tp zp p)
build_fonts_dir="build" # 完成品を保管するフォルダ
illegal_opt_fg="hVxfNn" # font_generator に指定できないオプション

opt_fg="" # font_generator のオプション
opt_tm="" # table_modificator のオプション
mode="" # 生成モード

draft_flag="false" # 下書きモード
leaving_tmp_flag="false" # 一時ファイル残す
loose_flag="false" # Loose 版にする
reuse_list_flag="false" # 生成済みのリストを使う
table_modify_flag="true" # フィーチャテーブルを編集する
symbol_only_flag="false" # カーニング設定を記号、桁区切りのみにする

font_version="0.1.0"

version="version"
version_txt=$(find . -name "${version}.txt" -maxdepth 1 | head -n 1)
if [ -n "${version_txt}" ]; then
  font_v=$(head -n 1 < ${version_txt})
  if [ -n "${font_v}" ]; then
    font_version=${font_v}
  fi
fi

option_format_fg() { # font_generator 用のオプションを整形 (戻り値: 整形したオプション)
  local opt # 整形前のオプション
  local leaving_tmp_flag # 一時作成ファイルを残すか
  local loose_flag # Loose 版にするか
  local draft_flag= # 下書きモードか
  opt="${2}"
  leaving_tmp_flag="${3}"
  loose_flag="${4}"
  draft_flag="${5}"

  if [ "${leaving_tmp_flag}" = "true" ]; then # 引数に l はないが、一時作成ファイルを残す場合
    opt="${opt}l"
  fi
  if [ "${loose_flag}" = "true" ]; then # 引数に L はないが、Loose 版にする場合
    opt="${opt}L"
  fi
  if [ "${draft_flag}" = "true" ]; then # 引数に d はないが、下書きモードで処理する場合
    opt="${opt}d"
  fi
  eval "${1}=\${opt}" # 戻り値を入れる変数名を1番目の引数に指定する
}

option_format_tm() { # table_modificator 用のオプションを整形 (戻り値: 整形したオプション)
  local opt # 整形前のオプション
  local leaving_tmp_flag # 一時作成ファイルを残すか
  local loose_flag # Loose 版にするか
  local reuse_list_flag # 作成済みのリストを使用するか
  local symbol_only_flag # カーニング設定を記号、桁区切りのみにするか
  opt="${2}"
  leaving_tmp_flag="${3}"
  loose_flag="${4}"
  reuse_list_flag="${5}"
  symbol_only_flag="${6}"

  if [ "${leaving_tmp_flag}" != "false" ]; then # -l オプションか 引数に l がある場合
    opt="${opt}l"
  fi
  if [ "${loose_flag}" != "false" ]; then # -L オプションか 引数に L がある場合
    opt="${opt}L"
  fi
  if [ "${reuse_list_flag}" != "false" ]; then # -r オプションがある場合
    opt="${opt}r"
  fi
  if [ "${symbol_only_flag}" != "false" ]; then # -S オプションがある場合
    opt="${opt}S"
  fi
  eval "${1}=\${opt}" # 戻り値を入れる変数名を1番目の引数に指定する
}

option_check() {
  if [ -n "${mode}" ]; then # -dCpF のうち2個以上含まれていたら終了
    echo "Illegal option"
    exit 1
  fi
}

remove_temp() {
  echo "Remove temporary files"
  sh font_generator.sh -x
  sh table_modificator.sh -x -N "${font_familyname}"
  rm -f *.nopatch.ttf
}

forge_ttx_help()
{
    echo "Usage: run_ff_ttx.sh [options] [argument (options of font_generator)]"
    echo ""
    echo "Option:"
    echo "  -h         Display this information"
    echo "  -x         Cleaning temporary files" # 一時作成ファイルの消去のみ
    echo "  -l         Leave (do NOT remove) temporary files"
    echo "  -N string  Set fontfamily (\"string\")"
    echo "  -n string  Set fontfamily suffix (\"string\")"
    echo "  -L         Set the ratio of hankaku to zenkaku characters to 9:16"
    echo "  -S         Don't make calt settings for latin characters"
    echo "  -r         Reuse an existing list"
    echo "  -d         Draft mode (skip time-consuming processes)" # グリフ変更の確認用 (最後は通常モードで確認すること)
    echo "  -C         End just before editing calt feature" # caltの編集・確認を繰り返す時用にcalt適用前のフォントを作成する
    echo "  -p         Run calt patch only" # -C の続きを実行
    echo "  -F         Complete Mode (generate finished fonts)" # 完成品作成
    exit 0
}

echo
echo "*** FontForge and TTX runner ***"
echo

# オプションを取得
while getopts hxlN:n:LSrdCpF OPT
do
    case "${OPT}" in
        "h" )
            forge_ttx_help
            ;;
        "x" )
            echo "Option: Cleaning temporary files"
            remove_temp
            rm -f *.ttf
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
        "n" )
            echo "Option: Set fontfamily suffix: ${OPTARG}"
            font_familyname_suffix=${OPTARG// /}
            ;;
        "L" )
            echo "Option: Set the ratio of hankaku to zenkaku characters to 9:16"
            loose_flag="true"
            ;;
        "S" )
            echo "Option: Don't make calt settings for latin characters"
            symbol_only_flag="true"
            ;;
        "r" )
            echo "Option: Reuse an existing list"
            reuse_list_flag="true"
            ;;
        "d" )
            echo "Option: Draft mode (skip time-consuming processes)"
            option_check
            mode="-d"
            draft_flag="true"
            leaving_tmp_flag="true"
            table_modify_flag="false"
            ;;
        "C" )
            echo "Option: End just before editing calt feature"
            option_check
            mode="-C"
            draft_flag="false"
            leaving_tmp_flag="true"
            table_modify_flag="true"
            ;;
        "p" )
            echo "Option: Run calt patch only"
            option_check
            mode="-p"
            draft_flag="false"
            leaving_tmp_flag="true"
            table_modify_flag="true"
            ;;
        "F" )
            echo "Option: Complete Mode (generate finished fonts)"
            option_check
            mode="-F"
            draft_flag="false"
            table_modify_flag="true"
            ;;
        * )
            exit 1
            ;;
    esac
done
echo

shift $((OPTIND - 1))

# 引数を取得
if [ "${mode}" != "-p" ]; then # -p オプション以外は引数を取得
  if [ $# -eq 1 ]; then
    opt_fg=$(echo "$1" | tr -d ' -')
    array=($(echo ${opt_fg} | sed 's/./& /g')) # 配列化 (abc → a b c)
    for S in ${array[@]}; do
      if grep -q "${S}" <<< "${illegal_opt_fg}"; then # 引数に使用できないオプションが含まれていれば終了
        echo "Illegal argument"
        exit 1
      elif [ "${S}" = "l" ]; then # l が含まれていれば一時作成ファイルを残す (-l オプションと区別)
        leaving_tmp_flag="true_arg"
      elif [ "${S}" = "L" ]; then # L が含まれていれば Loose 版にする (-L オプションと区別)
        loose_flag="true_arg"
      elif [ "${S}" = "d" ]; then # d が含まれていれば下書きモードで処理 (-d オプションと区別)
        draft_flag="true_arg"
      elif [ "${S}" = "P" ]; then # P が含まれていればテーブルを編集する前に終了
        table_modify_flag="false"
      fi
    done
  elif [ $# -gt 1 ]; then
    echo "Illegal argument"
    exit 1
  fi
fi

# フォント作成
case ${mode} in
  "-d" )
    if [ $# -eq 0 ]; then
      opt_fg="oP" # 引数が無い場合の設定 (パッチ適用前で終了)
    fi
    ;;
  "-C" )
    if [ $# -eq 0 ]; then
      opt_fg="Seo" # 引数が無い場合の設定
    fi
    ;;
  "-p" )
    ;;
  "-F" )
    if [ $# -eq 0 ]; then
      opt_fg="P" # 引数が無い場合の設定 (一旦パッチ適用前で終了し、その後続きを実行)
    fi
    ;;
  "" )
    if [ $# -eq 0 ]; then
      opt_fg="o" # 引数が無い場合の設定
    fi
    ;;
  * )
    exit 1
    ;;
esac

if [ "${mode}" != "-p" ]; then # -p オプション以外はフォントを作成
  option_format_fg opt_fg "${opt_fg}" "${leaving_tmp_flag}" "${loose_flag}" "${draft_flag}"
  if [ -n "${opt_fg}" ]; then
    sh font_generator.sh -"${opt_fg}" -N "${font_familyname}" -n "${font_familyname_suffix}" auto
  else
    sh font_generator.sh -N "${font_familyname}" -n "${font_familyname_suffix}" auto
  fi
fi

if [ "${table_modify_flag}" = "false" ]; then # 下書きモードか、引数に P があった場合テーブルを編集しない
  exit 0
fi

# -F オプションの場合、パッチ適用前からの続きを実行
if [ "${mode}" = "-F" ]; then
  if [ $# -eq 0 ] && [ -z "${font_familyname_suffix}" ]; then
    for i in ${!font_familyname_suffix_def[@]}; do # 引数が無く、suffix も無い場合、デフォルト設定でフォントにパッチを当てる
      opt_fg=${font_familyname_suffix_def_opt[${i}]}
      option_format_fg opt_fg "${opt_fg}" "${leaving_tmp_flag}" "${loose_flag}" "${draft_flag}"
      if [ -n "${opt_fg}" ]; then
        sh font_generator.sh -"${opt_fg}" -N "${font_familyname}" -n "${font_familyname_suffix_def[${i}]}"
      else
        sh font_generator.sh -N "${font_familyname}" -n "${font_familyname_suffix_def[${i}]}"
      fi
    done
  fi
  if [ $# -eq 0 ]; then # 引き数がない場合、通常版を生成
    opt_fg="Sp"
    option_format_fg opt_fg "${opt_fg}" "${leaving_tmp_flag}" "${loose_flag}" "${draft_flag}"
    if [ -n "${opt_fg}" ]; then
      sh font_generator.sh -"${opt_fg}" -N "${font_familyname}" -n "${font_familyname_suffix}"
    else
      sh font_generator.sh -N "${font_familyname}" -n "${font_familyname_suffix}"
    fi
  fi
fi

# テーブル加工 (-F オプション以外はカーニング設定を基本ラテン文字に限定、最適化処理をしない)
case ${mode} in
  "-C" ) opt_tm="C" ;;
  "-p" ) opt_tm="pb" ;;
  "-F" ) opt_tm="o" ;;
     * ) opt_tm="b" ;;
esac
option_format_tm opt_tm "${opt_tm}" "${leaving_tmp_flag}" "${loose_flag}" "${reuse_list_flag}" "${symbol_only_flag}"
if [ -n "${opt_tm}" ]; then
  sh table_modificator.sh -"${opt_tm}" -N "${font_familyname}${font_familyname_suffix}"
else
  sh table_modificator.sh -N "${font_familyname}${font_familyname_suffix}"
fi

# -F が有効で、-l が無効、引数にも l が無い場合、一時ファイルを削除
if [ "${leaving_tmp_flag}" = "false" ]; then
  remove_temp
  echo
fi

# -F オプションの場合、完成したフォントを移動
if [ "${mode}" = "-F" ]; then
  echo "Move finished fonts"
  mkdir -p "${build_fonts_dir}/${font_familyname}"
  if [ $# -eq 0 ] && [ -z "${font_familyname_suffix}" ]; then # 引数が無く、suffix も無い場合、デフォルト設定で各フォルダにフォントを移動
    for S in ${font_familyname_suffix_def[@]}; do
      mkdir -p "${build_fonts_dir}/${font_familyname}/${S}"
      mv -f ${font_familyname}${S}*.ttf "${build_fonts_dir}/${font_familyname}/${S}/."
    done
  elif [ -n "${font_familyname_suffix}" ]; then # suffix がある場合、フォルダを作ってフォントを移動
    mkdir -p "${build_fonts_dir}/${font_familyname}/${font_familyname_suffix}"
    mv -f ${font_familyname}${font_familyname_suffix}*.ttf "${build_fonts_dir}/${font_familyname}/${font_familyname_suffix}/."
  fi
  # パッチ未適用のフォントを除外して移動
  find . -not -name "*.nopatch.ttf" -maxdepth 1 | \
  grep -e "${font_familyname}.*\.ttf$" | while read line
  do
    mv -f "${line}" "${build_fonts_dir}/${font_familyname}/."
  done
  echo

  # Exit
  echo "Succeeded in generating custom fonts!"
  echo "Font version : ${font_version}"
  echo
fi

exit 0
