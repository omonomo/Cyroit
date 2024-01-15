#!/bin/sh

# Custom font generator
#
# Copyright (c) 2023 omonomo

# [Original Script]
# Ricty Generator (ricty_generator.sh)
#
# Copyright (c) 2011-2017 Yasunori Yusa
# All rights reserved.

font_familyname="Cyroit"
font_familyname_suffix=""

font_version="0.1.0"
vendor_id="PfEd"

version="version"
version_txt=`find . -name "${version}.txt" -maxdepth 1 | head -n 1`
if [ -n "${version_txt}" ]; then
    font_v=`cat ${version_txt} | head -n 1`
    if [ -n "${font_v}" ]; then
        font_version=${font_v}
    fi
fi

tmpdir_name="font_generator_tmpdir" # 一時作成フォルダ名

# グリフ保管アドレス
address_dvz_latin="64336" # 0ufb50 latinフォントの避難したDVZアドレス
address_visi_latin=`expr ${address_dvz_latin} + 18` # latinフォントの避難した識別性向上アドレス ⁄|

address_visi_kana=`expr ${address_visi_latin} + 2` # 仮名フォントの避難した識別性向上アドレス ゠-➓
address_vert_kana="1114129" # 仮名フォントのvert置換アドレス

address_visi_kanzi=`expr ${address_visi_kana} + 26` # 漢字フォントの避難した識別性向上アドレス 〇-口
address_calt_kanzi="1114841" # 漢字フォントのcalt置換アドレス
address_calt_kanzi2="1115493" # 漢字フォントのcalt置換アドレス
address_calt_kanzi3="1115623" # 漢字フォントのcalt置換アドレス
address_calt_kanzi4="1115776" # 漢字フォントのcalt置換アドレス

address_dvz_latinkana=${address_dvz_latin} # latin仮名フォントの避難したDVZアドレス
address_zenhan_latinkana=`expr ${address_visi_kanzi} + 9` # latin仮名フォントの避難した全角半角アドレス(縦書きの（-゠)
address_vert_latinkana="65682" # latin仮名フォントのvert置換アドレス

address_dvz=${address_dvz_latin} # 避難したDVZアドレス
address_visi=${address_visi_latin} # 避難した識別性向上アドレス
address_zenhan=${address_zenhan_latinkana} # 避難した全角半角アドレス
address_store_end=`expr ${address_zenhan} + 281` # 避難したグリフの最終アドレス(縦書きの゠)

address_vert="1114179" # vert置換アドレス （
address_vert_X=`expr ${address_vert} + 109` # vert置換アドレス ✂
address_vert_dh=`expr ${address_vert_X} + 3` # vert置換アドレス ゠
address_vert_mm=`expr ${address_vert_dh} + 18` # vert置換アドレス ㍉
address_vert_kabu=`expr ${address_vert_mm} + 333` # vert置換アドレス ㍿
address_calt=`expr ${address_vert_kabu} + 7` # calt置換の先頭アドレス(左に移動した A)
address_calt_middle=`expr ${address_calt} + 239` # calt置換の中間アドレス(右に移動した A)
address_calt_figure=`expr ${address_calt_middle} + 239` # calt置換アドレス(桁区切り付きの数字)
address_calt_end=`expr ${address_calt_figure} + 52` # calt置換の最終アドレス (上に移動した colon)
lookupIndex_calt="17" # caltテーブルのlookupナンバー
num_calt_lookups="19" # calt のルックアップ数
address_ss=`expr ${address_calt_end} + 1` # ss置換の先頭アドレス(全角スペース)
address_ss_figure=`expr ${address_ss} + 3` # ss置換アドレス(桁区切り付きの数字)
address_ss_vert=`expr ${address_ss_figure} + 50` # ss置換の全角縦書きアドレス(縦書きの（)
address_ss_zenhan=`expr ${address_ss_vert} + 109` # ss置換の全角半角アドレス(！)
address_ss_visibility=`expr ${address_ss_zenhan} + 172` # ss置換の識別性向上アドレス(/)
address_ss_dvz=`expr ${address_ss_visibility} + 39` # ss置換のDVZアドレス
address_ss_end=`expr ${address_ss_dvz} + 17` # ss置換の最終アドレス (Ｚ)
num_ss_glyphs=`expr ${address_ss_end} - ${address_ss} + 1` # ss置換のグリフ数
lookupIndex_ss="47" # ssテーブルのlookupナンバー
num_ss_lookups="8" # ss のルックアップ数

# フォントバージョンにビルドNo追加
buildNo=`date "+%s"`
buildNo=`expr ${buildNo} % 315360000 / 60`
buildNo=`echo "obase=16; ibase=10; ${buildNo}" | bc`
font_version="${font_version} (${buildNo})"

# 著作権
copyright9="Copyright (c) 2023 omonomo\n\n"
copyright5="[Symbols Nerd Font]\nCopyright (c) 2016, Ryan McIntyre\n\n"
copyright4="[BIZ UDGothic]\nCopyright 2022 The BIZ UDGothic Project Authors (https://github.com/googlefonts/morisawa-biz-ud-gothic)\n\n"
copyright3="[Circle M+]\nCopyright(c) 2020 M+ FONTS PROJECT, itouhiro\n\n"
copyright2="[Inconsolata]\nCopyright 2006 The Inconsolata Project Authors (https://github.com/cyrealtype/Inconsolata)\n\n"
copyright1="[Ricty Generator (Script)]\nCopyright (c) 2011-2017 Yasunori Yusa\n\n"
copyright0="SIL Open Font License Version 1.1 (http://scripts.sil.org/ofl)"

# Set ascent and descent (line width parameters)
typo_ascent1000="860" # em値1000用
typo_descent1000="140"
typo_linegap1000="0"
win_ascent1000="835"
win_descent1000="215"
hhea_ascent1000="860"
hhea_descent1000="140"
hhea_linegap1000="0"

typo_ascent1024="809" # em値1024用
typo_descent1024="215"
typo_linegap1024="226"
win_ascent1024="998"
win_descent1024="252"
hhea_ascent1024="${win_ascent1024}"
hhea_descent1024="${win_descent1024}"
hhea_linegap1024="0"

# em値変更でのY座標のズレ修正用
y_pos_em_revice="-10" #Y座標移動量

# Powerline 変形、移動用
height_percent_pl="123" # PowelineY座標拡大比率
height_percent_block="89" # ボックス要素Y座標拡大比率
height_center_pl="297" # PowerlineリサイズY座標中心
y_pos_pl="76" # PowerlineY座標移動量

# 可視化したスペース等、下線のY座標移動量
y_pos_space="-235"

# ウェイト調整用
weight_extend_kanzi_bold="8" # 主に漢字
weight_extend_kanzi_symbols_regular="6" # 漢字フォントの記号類レギュラー
weight_extend_kanzi_symbols_bold="12" # 漢字フォントの記号類ボールド

weight_reduce_kana_bold="-8" # 主に仮名
weight_reduce_kana_others_regular="-2" # 仮名フォントのその他レギュラー
weight_reduce_kana_others_bold="-12" # 仮名フォントのその他ボールド

# 英数文字の縦横拡大率
height_percent_latin="102" # 縦拡大比率
width_percent_latin="98" # 横拡大比率

# 上付き、下付き数字用
percent_super_sub="75" # 拡大比率
y_pos_super="273" # 上付きY座標移動量
y_pos_sub="-166" # 下付きY座標移動量
weight_extend_super_sub="12" # ウェイト調整

# 演算子移動量
y_pos_math="-25" # 通常
y_pos_s_math="-10" # 上付き、下付き

# 縦書き全角ラテン小文字移動量
y_pos_vert_1="-10"
y_pos_vert_2="10"
y_pos_vert_3="30"
y_pos_vert_4="80"
y_pos_vert_5="120"
y_pos_vert_6="140"
y_pos_vert_7="160"

# calt用
x_pos_calt="20" # ラテン文字の移動量
x_pos_calt_hyphen="40" # - の移動量
y_pos_calt_colon="55" # : の移動量
y_pos_calt_bar="-38" # | の移動量
y_pos_calt_tilde="-195" # ~ の移動量
percent_calt_decimal="93" # 小数の拡大比率

# Set path to command
fontforge_command="fontforge"
ttx_command="ttx"

# Set redirection of stderr
redirection_stderr="/dev/null"

# Set fonts directories used in auto flag
fonts_directories=". ${HOME}/.fonts /usr/local/share/fonts /usr/share/fonts \
${HOME}/Library/Fonts /Library/Fonts \
/c/Windows/Fonts /cygdrive/c/Windows/Fonts"

# Set flags
mode="" # 生成モード

leaving_tmp_flag="false" # 一時ファイル残す
visible_zenkaku_space_flag="true" # 全角スペース可視化
visible_hankaku_space_flag="true" # 半角スペース可視化
improve_visibility_flag="true" # ダッシュ破線化
underline_flag="true" # 全角半角に下線
dvz_flag="true" # DVZ改変
calt_flag="true" # calt対応
ss_flag="false" # ss対応
nerd_flag="true" # Nerd fonts 追加
separator_flag="true" # 桁区切りあり
oblique_flag="true" # オブリーク作成
draft_flag="false" # 下書きモード
patch_flag="true" # パッチを当てる
patch_only_flag="false" # パッチモード

# Set filenames
origin_latin_regular="Inconsolata-Regular.ttf"
origin_latin_bold="Inconsolata-Bold.ttf"
origin_kana_regular="circle-mplus-1m-regular.ttf"
origin_kana_bold="circle-mplus-1m-bold.ttf"
origin_kanzi_regular="BIZUDGothic-Regular.ttf"
origin_kanzi_bold="BIZUDGothic-Bold.ttf"
origin_nerd="SymbolsNerdFontMono-Regular.ttf"

modified_latin_generator="modified_latin_generator.pe"
modified_latin_regular="modified-latin-Regular.sfd"
modified_latin_bold="modified-latin-Bold.sfd"

modified_kana_generator="modified_kana_generator.pe"
modified_kana_regular="modified-kana-regular.sfd"
modified_kana_bold="modified-kana-bold.sfd"

modified_kanzi_generator="modified_kanzi_generator.pe"
modified_kanzi_regular="modified-kanzi-Regular.sfd"
modified_kanzi_bold="modified-kanzi-Bold.sfd"

modified_latin_kana_generator="modified_latin_kana_generator.pe"
modified_latin_kana_regular="modified-latin-kana-Regular.sfd"
modified_latin_kana_bold="modified-latin-kana-Bold.sfd"

custom_font_generator="custom_font_generator.pe"

parameter_modificator="parameter_modificator.pe"

oblique_converter="oblique_converter.pe"

modified_nerd_generator="modified_nerd_generator.pe"
modified_nerd="modified-nerd.ttf"

merged_nerd_generator="merged_nerd_generator.pe"

font_patcher="font_patcher.pe"

################################################################################
# Pre-process
################################################################################

# Print information message
cat << _EOT_

----------------------------
Custom font generator
Font version: ${font_version}
----------------------------

_EOT_

option_check() {
  if [ -n "${mode}" ]; then # -Pp のうち2個以上含まれていたら終了
    echo "Illegal option"
    exit 1
  fi
}

# Define displaying help function
font_generator_help()
{
    echo "Usage: font_generator.sh [options] auto"
    echo "       font_generator.sh [options] [font1]-{Regular,Bold}.ttf [font2]-{regular,bold}.ttf [font3]-{Regular,Bold}.ttf [Nerd fonts].ttf"
    echo ""
    echo "Options:"
    echo "  -h                     Display this information"
    echo "  -V                     Display version number"
    echo "  -f /path/to/fontforge  Set path to fontforge command"
    echo "  -v                     Enable verbose mode (display fontforge's warning)"
    echo "  -l                     Leave (do NOT remove) temporary files"
    echo "  -N string              Set fontfamily (\"string\")"
    echo "  -n string              Set fontfamily suffix (\"string\")"
    echo "  -Z                     Disable visible zenkaku space"
    echo "  -z                     Disable visible hankaku space"
    echo "  -u                     Disable zenkaku hankaku underline"
    echo "  -b                     Disable glyphs with improved visibility"
    echo "  -t                     Disable modified D, V and Z"
    echo "  -c                     Disable calt feature"
    echo "  -s                     Disable thousands separator"
    echo "  -e                     Disable add Nerd fonts"
    echo "  -o                     Disable generate oblique style"
    echo "  -S                     Enable ss feature"
    echo "  -d                     Enable draft mode (skip time-consuming processes)"
    echo "  -P                     End just before patching"
    echo "  -p                     Run font patch only"
    exit 0
}

# Get options
while getopts hVf:vlN:n:ZzubtcseoSdPp OPT
do
    case "${OPT}" in
        "h" )
            font_generator_help
            ;;
        "V" )
            exit 0
            ;;
        "f" )
            echo "Option: Set path to fontforge command: ${OPTARG}"
            fontforge_command="${OPTARG}"
            ;;
        "v" )
            echo "Option: Enable verbose mode"
            redirection_stderr="/dev/stderr"
            ;;
        "l" )
            echo "Option: Leave (do NOT remove) temporary files"
            leaving_tmp_flag="true"
            ;;
        "N" )
            echo "Option: Set fontfamily: ${OPTARG}"
            font_familyname=`echo $OPTARG | tr -d ' '`
            ;;
        "n" )
            echo "Option: Set fontfamily suffix: ${OPTARG}"
            font_familyname_suffix=`echo $OPTARG | tr -d ' '`
            ;;
        "Z" )
            echo "Option: Disable visible zenkaku space"
            visible_zenkaku_space_flag="false"
            ;;
        "z" )
            echo "Option: Disable visible hankaku space"
            visible_hankaku_space_flag="false"
            ;;
        "u" )
            echo "Option: Disable zenkaku hankaku underline"
            if [ "${ss_flag}" = "true" ]; then
                echo "Can't be disabled"
            else
                underline_flag="false"
            fi
            ;;
        "b" )
            echo "Option: Disable glyphs with improved visibility"
            if [ "${ss_flag}" = "true" ]; then
                echo "Can't be disabled"
            else
                improve_visibility_flag="false"
            fi
            ;;
        "t" )
            echo "Option: Disable modified D, V and Z"
            dvz_flag="false"
            ;;
        "c" )
            echo "Option: Disable calt feature"
            if [ "${ss_flag}" = "true" ]; then
                echo "Can't be disabled"
            else
                calt_flag="false"
            fi
            ;;
        "s" )
            echo "Option: Disable thousands separator"
            separator_flag="false"
            ;;
        "e" )
            echo "Option: Disable add Nerd fonts"
            nerd_flag="false"
            ;;
        "o" )
            echo "Option: Disable generate oblique style"
            oblique_flag="false"
            ;;
        "S" )
            echo "Option: Enable ss feature"
            visible_zenkaku_space_flag="false"
            visible_hankaku_space_flag="false"
            underline_flag="true"
            improve_visibility_flag="true"
 #            underline_flag="false" # デフォルトで下線無しにする場合
            dvz_flag="false"
            calt_flag="true"
            separator_flag="false"
            ss_flag="true"
            ;;
        "d" )
            echo "Option: Enable draft mode (skip time-consuming processes)"
            draft_flag="true"
            oblique_flag="false"
            ;;
        "P" )
            echo "Option: End just before patching"
            option_check
            mode="-P"
            patch_flag="false"
            patch_only_flag="false"
            ;;
        "p" )
            echo "Option: Run font patch only"
            option_check
            mode="-p"
            patch_flag="true"
            patch_only_flag="true"
            ;;
        * )
            font_generator_help
            exit 1
            ;;
    esac
done
echo

shift `expr $OPTIND - 1`

# Get input fonts
if [ "${patch_only_flag}" = "false" ]; then
    if [ $# -eq 1 -a "$1" = "auto" ]; then
        # Check existance of directories
        tmp=""
        for i in $fonts_directories
        do
            [ -d "${i}" ] && tmp="${tmp} ${i}"
        done
        fonts_directories=$tmp
        # Search latin fonts
        input_latin_regular=`find $fonts_directories -follow -name "${origin_latin_regular}" | head -n 1`
        input_latin_bold=`find $fonts_directories -follow -name "${origin_latin_bold}" | head -n 1`
        if [ -z "${input_latin_regular}" -o -z "${input_latin_bold}" ]; then
            echo "Error: ${origin_latin_regular} and/or ${origin_latin_bold} not found" >&2
            exit 1
        fi
        # Search kana fonts
        input_kana_regular=`find $fonts_directories -follow -iname "${origin_kana_regular}" | head -n 1`
        input_kana_bold=`find $fonts_directories -follow -iname "${origin_kana_bold}"    | head -n 1`
        if [ -z "${input_kana_regular}" -o -z "${input_kana_bold}" ]; then
            echo "Error: ${origin_kana_regular} and/or ${origin_kana_bold} not found" >&2
            exit 1
        fi
        # Search kanzi fonts
        input_kanzi_regular=`find $fonts_directories -follow -iname "${origin_kanzi_regular}" | head -n 1`
        input_kanzi_bold=`find $fonts_directories -follow -iname "${origin_kanzi_bold}"    | head -n 1`
        if [ -z "${input_kanzi_regular}" -o -z "${input_kanzi_bold}" ]; then
            echo "Error: ${origin_kanzi_regular} and/or ${origin_kanzi_bold} not found" >&2
            exit 1
        fi
        if [ ${nerd_flag} = "true" ]; then
            # Search nerd fonts
            input_nerd=`find $fonts_directories -follow -iname "${origin_nerd}" | head -n 1`
            if [ -z "${input_nerd}" ]; then
                echo "Error: ${origin_nerd} not found" >&2
                exit 1
            fi
        fi
    elif ( [ ${nerd_flag} = "false" ] && [ $# -eq 6 ] ) || ( [ ${nerd_flag} = "true" ] && [ $# -eq 7 ] )
    then
        # Get arguments
        input_latin_regular=$1
        input_latin_bold=$2
        input_kana_regular=$3
        input_kana_bold=$4
        input_kanzi_regular=$5
        input_kanzi_bold=$6
        if [ ${nerd_flag} = "true" ]; then
            input_nerd=$7
        fi
        # Check existance of files
        if [ ! -r "${input_latin_regular}" ]; then
            echo "Error: ${input_latin_regular} not found" >&2
            exit 1
        elif [ ! -r "${input_latin_bold}" ]; then
            echo "Error: ${input_latin_bold} not found" >&2
            exit 1
        elif [ ! -r "${input_kana_regular}" ]; then
            echo "Error: ${input_kana_regular} not found" >&2
            exit 1
        elif [ ! -r "${input_kana_bold}" ]; then
            echo "Error: ${input_kana_bold} not found" >&2
            exit 1
        elif [ ! -r "${input_kanzi_regular}" ]; then
            echo "Error: ${input_kanzi_regular} not found" >&2
            exit 1
        elif [ ! -r "${input_kanzi_bold}" ]; then
            echo "Error: ${input_kanzi_bold} not found" >&2
            exit 1
        elif [ ${nerd_flag} = "true" ] && [ ! -r "${input_nerd}" ]; then
            echo "Error: ${input_nerd} not found" >&2
            exit 1
        fi
        # Check filename
        [ "$(basename $input_latin_regular)" != "${origin_latin_regular}" ] &&
            echo "Warning: ${input_latin_regular} does not seem to be ${origin_latin_regular}" >&2
        [ "$(basename $input_latin_bold)" != "${origin_latin_bold}" ] &&
            echo "Warning: ${input_latin_regular} does not seem to be ${origin_latin_bold}" >&2
        [ "$(basename $input_kana_regular)" != "${origin_kana_regular}" ] &&
            echo "Warning: ${input_kana_regular} does not seem to be ${origin_kana_regular}" >&2
        [ "$(basename $input_kana_bold)" != "${origin_kana_bold}" ] &&
            echo "Warning: ${input_kana_bold} does not seem to be ${origin_kana_bold}" >&2
        [ "$(basename $input_kanzi_regular)" != "${origin_kanzi_regular}" ] &&
            echo "Warning: ${input_kanzi_regular} does not seem to be ${origin_kanzi_regular}" >&2
        [ "$(basename $input_kanzi_bold)" != "${origin_kanzi_bold}" ] &&
            echo "Warning: ${input_kanzi_bold} does not seem to be ${origin_kanzi_bold}" >&2
        [ ${nerd_flag} = "true" ] && [ "$(basename $input_nerd)" != "${origin_nerd}" ] &&
            echo "Warning: ${input_nerd} does not seem to be ${origin_nerd}" >&2
    else
        echo "Error: missing arguments"
        echo
        font_generator_help
    fi
fi

# Check fontforge existance
if ! which $fontforge_command > /dev/null 2>&1
then
    echo "Error: ${fontforge_command} command not found" >&2
    exit 1
fi
fontforge_v=`${fontforge_command} -version`
fontforge_version=`echo ${fontforge_v} | cut -d ' ' -f2`

# Check ttx existance
if ! which $ttx_command > /dev/null 2>&1
then
    echo "Error: ${ttx_command} command not found" >&2
    exit 1
fi
ttx_version=`${ttx_command} --version`

# Make temporary directory
if [ -w "/tmp" -a "${leaving_tmp_flag}" = "false" ]; then
    tmpdir=`mktemp -d /tmp/"${tmpdir_name}".XXXXXX` || exit 2
else
    tmpdir=`mktemp -d ./"${tmpdir_name}".XXXXXX`    || exit 2
fi

# Remove temporary directory by trapping
if [ "${leaving_tmp_flag}" = "false" ]; then
    trap "if [ -d \"$tmpdir\" ]; then echo 'Remove temporary files'; rm -rf $tmpdir; echo 'Abnormally terminated'; fi; exit 3" HUP INT QUIT
    trap "if [ -d \"$tmpdir\" ]; then echo 'Remove temporary files'; rm -rf $tmpdir; echo 'Abnormally terminated'; fi" EXIT
else
    trap "echo 'Abnormally terminated'; exit 3" HUP INT QUIT
fi
echo

################################################################################
# Generate script for modified latin fonts
################################################################################

cat > ${tmpdir}/${modified_latin_generator} << _EOT_
#!$fontforge_command -script

Print("- Generate modified latin fonts -")

# Set parameters
input_list  = ["${input_latin_regular}",    "${input_latin_bold}"]
output_list = ["${modified_latin_regular}", "${modified_latin_bold}"]

# Begin loop of regular and bold
i = 0
while (i < SizeOf(input_list))
# Open latin font
    Print("Open " + input_list[i])
    Open(input_list[i])
    SelectWorthOutputting()
    UnlinkReference()
    ScaleToEm(${typo_ascent1000}, ${typo_descent1000})
    SetOS2Value("WinAscent",             ${win_ascent1000}) # Windows用(この範囲外は描画されない)
    SetOS2Value("WinDescent",            ${win_descent1000})
    SetOS2Value("TypoAscent",            ${typo_ascent1000}) # 組版用(em値と合わせる)
    SetOS2Value("TypoDescent",          -${typo_descent1000})
    SetOS2Value("TypoLineGap",           ${typo_linegap1000})
    SetOS2Value("HHeadAscent",           ${hhea_ascent1000}) # Mac用
    SetOS2Value("HHeadDescent",         -${hhea_descent1000})
    SetOS2Value("HHeadLineGap",          ${hhea_linegap1000})

# --------------------------------------------------

# 使用しないグリフクリア
    Print("Remove not used glyphs")
    Select(0, 31); Clear(); DetachAndRemoveGlyphs()
    Select(65536, 65615); Clear(); DetachAndRemoveGlyphs()

# Clear kerns, position, substitutions
    Print("Clear kerns, position, substitutions")
    RemoveAllKerns()

    lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups); j = 0
    while (j < numlookups)
        if (j != 19 && j != 20) # sups subs 以外のLookupを削除
            Print("Remove GSUB_" + lookups[j])
            RemoveLookup(lookups[j])
        endif
        j++
    endloop

    lookups = GetLookups("GPOS"); numlookups = SizeOf(lookups); j = 0
    while (j < numlookups)
        Print("Remove GPOS_" + lookups[j])
        RemoveLookup(lookups[j]); j++
    endloop

# Clear instructions, hints
    Print("Clear instructions, hints")
    SelectWorthOutputting()
    ClearInstrs()
    ClearHints()

# Proccess before editing
    if ("${draft_flag}" == "false")
        Print("Process before editing")
        SelectWorthOutputting()
        RemoveOverlap()
        CorrectDirection()
    endif

# --------------------------------------------------
# ダイアクリティカルマークの Width 変更
    Print("Modified diacritics width")
    Select(0u0300, 0u0336); SetWidth(500)
    Select(0u0305)
    SelectMore(0u030d, 0u30e)
    SelectMore(0u0310)
    SelectMore(0u0313, 0u31a)
    SelectMore(0u031c, 0u322)
    SelectMore(0u0325)
    SelectMore(0u0329, 0u32d)
    SelectMore(0u032f, 0u330)
    SelectMore(0u0332, 0u334)
    Clear(); DetachAndRemoveGlyphs()

# スペースの width 変更
    Print("Modified space width")
    Select(0u2000); SetWidth(500)
    Select(0u2001); SetWidth(1000)
    Select(0u2002); SetWidth(500)
    Select(0u2003); SetWidth(1000)
    Select(0u2004, 0u200a); SetWidth(500)
    Select(0u200b); SetWidth(0)
    Select(0u202f); SetWidth(500)
    Select(0u205f); SetWidth(500)
    Select(0ufeff); SetWidth(0)

    Print("Edit numbers")
# 4 (縦線を少し細く)
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Move(-112,0)
    Select(0u0034); Copy() # 4
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()

    Select(0u2588); Copy() # Full block
    Select(0u0034); PasteWithOffset(400, 0) # 4
    OverlapIntersect()
    Copy()
    PasteWithOffset(-20, 0)

    Select(65552);  Copy() # Temporary glyph
    Select(0u0034); PasteInto() # 4

    RemoveOverlap()
    SetWidth(500)

    Select(65552); Clear() # Temporary glyph

# 7 (左上を折り曲げる、太さ変更)
    # 折り曲げ
    Select(0u00af); Copy()  # macron
    Select(65552);  Paste() # Temporary glyph
    Rotate(180, 250, 566); Scale(29, 108); Copy()

    Select(0u0037) # 7
    PasteWithOffset(-160, 54)
    PasteWithOffset(-160, 6)
    PasteWithOffset(-160, -41)
    if (input_list[i] == "${input_latin_bold}")
        PasteWithOffset(-140, 54)
        PasteWithOffset(-140, 6)
        PasteWithOffset(-140, -41)
    endif
    RemoveOverlap()
    Simplify()
    # 線を少し細く
    Move(10, 0); Scale(95, 101)

    Select(0u2588); Copy() # Full block
    Select(0u0037); PasteWithOffset(0, -377) # 7

    SetWidth(500)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph

# 6 (上端を少しカット)
    # 先っぽをコピー
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Scale(20, 5)
    if (input_list[i] == "${input_latin_regular}")
        Move(125, 230)
    else
        Move(125, 210)
    endif
    Select(0u0036); Copy() # 6
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    # 先っぽを装着
    if (input_list[i] == "${input_latin_regular}")
        Rotate(6)
        Copy()
        Select(0u0036) # 6
        PasteWithOffset(-33, 29)
    else
        Rotate(14)
        Copy()
        Select(0u0036) # 6
        PasteWithOffset(-38, 21)
    endif
    RemoveOverlap()

    # 先端カット
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Rotate(-36)
        Move(70, 0)
    else
        Rotate(-29)
        Move(150, 0)
    endif
    PasteWithOffset(465, -555)
    RemoveOverlap()
    Copy()
    Select(0u0036); PasteWithOffset(-465, 0) # 6
    OverlapIntersect()
    SetWidth(500)
    Simplify()

    Select(65552); Clear() # Temporary glyph

# 9 (下端を少しカット)
    # 先っぽをコピー
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Scale(20, 5)
    if (input_list[i] == "${input_latin_regular}")
        Move(-135, -210)
    else
        Move(-135, -180)
    endif
    Select(0u0039); RemoveOverlap(); Copy() # 9
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    # 先っぽを装着
    if (input_list[i] == "${input_latin_regular}")
        Rotate(6)
        Copy()
        Select(0u0039) # 9
        PasteWithOffset(29, -24)
    else
        Rotate(7)
        Copy()
        Select(0u0039) # 9
        PasteWithOffset(39, -27)
    endif
    RemoveOverlap()

    # 先端カット
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Rotate(-36)
        Move(840, 0)
    else
        Rotate(-29)
        Move(760, 0)
    endif
    PasteWithOffset(465, 600)
    RemoveOverlap()
    Copy()
    Select(0u0039); PasteWithOffset(-465, 0) # 9
    OverlapIntersect()
    SetWidth(500)
    Simplify()

    Select(65552); Clear() # Temporary glyph

    Print("Edit alphabets")
# A (縦に伸ばして上をカット、Regularは横棒を少し下げる)
    if (input_list[i] == "${input_latin_regular}")
        # 山
        Select(0u2588); Copy() # Full block
        Select(65552); Paste()
        Move(249, 0); Rotate(38, 249, 474)
        PasteWithOffset(-251, 0); Rotate(-19, 249, 474)
        PasteWithOffset(0, 800)
        RemoveOverlap()
        Copy()
        Select(0u0041); PasteInto()
        OverlapIntersect()
        # 横棒
        Select(0u2588); Copy() # Full block
        Select(65553); Paste()
        Scale(55, 4)
 #        ChangeWeight(-2)
        CorrectDirection()
        Copy()
        Select(0u0041); PasteWithOffset(0, -121)
 #        Select(0u0041); PasteWithOffset(0, -91)
        RemoveOverlap()
        Simplify()
        RoundToInt()

        Select(65552); Clear() # Temporary glyph
        Select(65553); Clear() # Temporary glyph
    endif

    Select(0u2588); Copy() # Full block
    Select(0u0041); Scale(100, 104, 250, 0) # A
    PasteWithOffset(0, -373)
    SetWidth(500)
    OverlapIntersect()

    Select(0u2588); Copy() # Full block
    Select(0u00c0, 0u00c4); PasteWithOffset(0, 1035); OverlapIntersect() # ÀÁÃÄ
    Select(0u00c5); PasteWithOffset(0,  1019); OverlapIntersect() # Å
    Select(0u0100); PasteWithOffset(0,  1035); OverlapIntersect() # Ā
    Select(0u0102); PasteWithOffset(0,  1035); OverlapIntersect() # Ă
    Select(0u0104); PasteWithOffset(0, -1000); OverlapIntersect() # Ą
    Select(0u01fa); PasteWithOffset(0,  1019); OverlapIntersect() # Ǻ
    Select(0u0200); PasteWithOffset(0,  1035); OverlapIntersect() # Ȁ
    Select(0u0202); PasteWithOffset(0,  1035); OverlapIntersect() # Ȃ
    Select(0u1ea0); PasteWithOffset(0, -1001); OverlapIntersect() # Ạ
    Select(0u1ea2); PasteWithOffset(0,  1035); OverlapIntersect() # Ả
    Select(0u1ea4); PasteWithOffset(0,  1035); OverlapIntersect() # Ấ
    Select(0u1ea6); PasteWithOffset(0,  1035); OverlapIntersect() # Ầ
    Select(0u1ea8); PasteWithOffset(0,  1035); OverlapIntersect() # Ẩ
    Select(0u1eaa); PasteWithOffset(0,  1035); OverlapIntersect() # Ẫ
    Select(0u1eac); PasteWithOffset(0,  1035); PasteWithOffset(0, -1001); OverlapIntersect() # Ậ
    Select(0u1eae); PasteWithOffset(0,  1035); OverlapIntersect() # Ắ
    Select(0u1eb0); PasteWithOffset(0,  1035); OverlapIntersect() # Ằ
    Select(0u1eb2); PasteWithOffset(0,  1035); OverlapIntersect() # Ẳ
    Select(0u1eb4); PasteWithOffset(0,  1035); OverlapIntersect() # Ẵ
    Select(0u1eb6); PasteWithOffset(0,  1035); PasteWithOffset(0, -1001); OverlapIntersect() # Ặ
    Select(0u0041); Copy() # A
    Select(0u00c0, 0u00c4); PasteInto(); SetWidth(500)
    Select(0u00c5); PasteInto(); RemoveOverlap(); SetWidth(500)
    Select(0u0100); PasteInto(); SetWidth(500)
    Select(0u0102); PasteInto(); SetWidth(500)
    Select(0u0104); PasteInto(); RemoveOverlap(); SetWidth(500)
    Select(0u01fa); PasteInto(); RemoveOverlap(); SetWidth(500)
    Select(0u0200); PasteInto(); SetWidth(500)
    Select(0u0202); PasteInto(); SetWidth(500)
    Select(0u1ea0); PasteInto(); SetWidth(500)
    Select(0u1ea2); PasteInto(); SetWidth(500)
    Select(0u1ea4); PasteInto(); SetWidth(500)
    Select(0u1ea6); PasteInto(); SetWidth(500)
    Select(0u1ea8); PasteInto(); SetWidth(500)
    Select(0u1eaa); PasteInto(); SetWidth(500)
    Select(0u1eac); PasteInto(); SetWidth(500)
    Select(0u1eae); PasteInto(); SetWidth(500)
    Select(0u1eb0); PasteInto(); SetWidth(500)
    Select(0u1eb2); PasteInto(); SetWidth(500)
    Select(0u1eb4); PasteInto(); SetWidth(500)
    Select(0u1eb6); PasteInto(); SetWidth(500)
 #    Select(0u01cd) # Ǎ
 #    Select(0u01de) # Ǟ
 #    Select(0u01e0) # Ǡ
 #    Select(0u0226) # Ȧ
 #    Select(0u023a) # Ⱥ
 #    Select(0u1e00) # Ḁ

# D (クロスバーを付加することで少しくどい感じに)
    Select(0u0044); Copy() # D
    Select(${address_dvz_latin}); Paste() # 避難所
    Select(${address_dvz_latin} + 3); Paste()
    Select(${address_dvz_latin} + 6); Paste()
    Select(${address_dvz_latin} + 9); Paste()
    Select(${address_dvz_latin} + 12); Paste()
    Select(${address_dvz_latin} + 15); Paste()

    Select(0u00af); Copy()  # macron
    Select(65552);  Paste() # Temporary glyph
    Scale(80, 109); Copy()
    Select(0u0044) # D
    if (input_list[i] == "${input_latin_regular}")
        PasteWithOffset(-146, -279)
    else
        PasteWithOffset(-146, -287)
    endif
    SetWidth(500)
    RemoveOverlap()

    Select(65552);  Clear() # Temporary glyph

 #    Select(0u0044); Copy() # D
 #    Select(0u010e) # Ď
 #    Select(0u1e0c) # Ḍ
 #    Select(0u1e0e) # Ḏ

 #    Select(0u1e10) # Ḑ
 #    Select(0u1e0a) # Ḋ
 #    Select(0u0110) # Đ
 #    Select(0u018a) # Ɗ
 #    Select(0u018b) # Ƌ
 #    Select(0u01c5) # ǅ
 #    Select(0u01f2) # ǲ
 #    Select(0u1e12) # Ḓ

# G (折れ曲がったところを少し上げる)
    # 周り
    Select(0u2588); Copy() # Full block
    Select(65552); Paste()
    Move(0, 780)
    PasteWithOffset(-300, 0)
    PasteWithOffset(0, -800)
    Copy()
    Select(65552); PasteInto()
    RemoveOverlap()
    # 折れ曲がったところ
    Select(0u2588); Copy() # Full block
    Select(65553); Paste()
    Scale(100, 20); Move(220, -30)
    Select(0u0047); Copy() # G
    Select(65553); PasteInto()
    OverlapIntersect()
    # 合成
    Select(65552); Copy()
    Select(0u0047); PasteInto() # G
    OverlapIntersect()
    Select(65553); Copy()
    Select(0u0047); PasteWithOffset(0, 20) # G
    RemoveOverlap()
    Simplify()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

    Select(0u2588); Copy() # Full block
    Select(0u0122); PasteWithOffset(0, -1013); OverlapIntersect() # Ģ
    Select(0u011c); PasteWithOffset(0,  1045); OverlapIntersect() # Ĝ
    Select(0u0120); PasteWithOffset(0,  1045); OverlapIntersect() # Ġ
    Select(0u01e6); PasteWithOffset(0,  1045); OverlapIntersect() # Ǧ
    Select(0u011e); PasteWithOffset(0,  1045); OverlapIntersect() # Ğ
    Select(0u1e20); PasteWithOffset(0,  1045); OverlapIntersect() # Ḡ
    Select(0u0047); Copy() # G
    Select(0u0122); PasteInto(); SetWidth(500) # Ģ
    Select(0u011c); PasteInto(); SetWidth(500) # Ĝ
    Select(0u0120); PasteInto(); SetWidth(500) # Ġ
    Select(0u01e6); PasteInto(); SetWidth(500) # Ǧ
    Select(0u011e); PasteInto(); SetWidth(500) # Ğ
    Select(0u1e20); PasteInto(); SetWidth(500) # Ḡ
 #    Select(0u01f4) # Ǵ
 #    Select(0u01e4) # Ǥ
 #    Select(0u0193) # Ɠ
 #    Select(0ua7a0) # Ꞡ

# H (縦の線を少し細くする)
    # H
    Select(0u0048) # H
    Scale(96, 100)
    # 左右に分解
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Move(-230, 0)
    Select(65553);  Paste() # Temporary glyph
    Move(230, 0)

    Select(0u0048); Copy() # H
    Select(65552);  PasteWithOffset(-8, 0) # Temporary glyph
    OverlapIntersect()
    Select(65553);  PasteWithOffset(8, 0) # Temporary glyph
    OverlapIntersect()
    Copy()
    # 合成
    Select(0u0048); Paste() # H
    Select(65552);  Copy() # Temporary glyph
    Select(0u0048); PasteInto() # H
    SetWidth(500)
    RemoveOverlap()
    Simplify()

    # Ħ
    Select(0u0126) # Ħ
    Scale(96, 100)
    # 左右に分解
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Move(-230, 0)
    Select(65553);  Paste() # Temporary glyph
    Move(230, 0)

    Select(0u0126); Copy() # Ħ
    Select(65552);  PasteWithOffset(-8, 0) # Temporary glyph
    OverlapIntersect()
    Select(65553);  PasteWithOffset(8, 0) # Temporary glyph
    OverlapIntersect()
    Copy()
    # 合成
    Select(0u0126); Paste() # Ħ
    Select(65552);  Copy() # Temporary glyph
    Select(0u0126); PasteInto() # Ħ
    SetWidth(500)
    RemoveOverlap()
    Simplify()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

    Select(0u2588); Copy() # Full block
    Select(0u0124); PasteWithOffset(0,  1035); OverlapIntersect() # Ĥ
    Select(0u1e24); PasteWithOffset(0, -1001); OverlapIntersect() # Ḥ
    Select(0u1e2a); PasteWithOffset(0, -1001); OverlapIntersect() # Ḫ
    Select(0u0048); Copy() # H
    Select(0u0124); PasteInto(); SetWidth(500) # Ĥ
    Select(0u1e24); PasteInto(); SetWidth(500) # Ḥ
    Select(0u1e2a); PasteInto(); SetWidth(500) # Ḫ
 #    Select(0u1e28) # Ḩ
 #    Select(0u1e22) # Ḣ
 #    Select(0u021e) # Ȟ
 #    Select(0ua7aa) # Ɦ
 #    Select(0u1e26) # Ḧ
 #    Select(0u2c67) # Ⱨ

# Q (尻尾を下に伸ばす)
    # 下
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Move(0, -1008)
    Select(0u0051); Copy() # Q
    Select(65552);  PasteInto()
    OverlapIntersect()
    # 上
    Select(0u2588); Copy() # Full block
    Select(0u0051); PasteWithOffset(0, 392) # Q
    OverlapIntersect()

    Select(65552); Copy()
    Select(0u0051); PasteWithOffset(0, -20) # Q

    # 開いた隙間を埋める
    Select(0u002d); Copy() # Hyphen-minus
    Select(65552);  Paste() # Temporary glyph

    if (input_list[i] == "${input_latin_regular}")
        Scale(22, 100); Copy()
        Select(0u0051); PasteWithOffset(6, -320) # Q
    else
        Scale(36, 100); Copy()
        Select(0u0051); PasteWithOffset(3, -300) # Q
    endif

    SetWidth(500)
    RemoveOverlap()
    Simplify()

    Select(65552); Clear() # Temporary glyph

 #    Select(0u0051); Copy() # Q
 #    Select(0ua756) # Ꝗ
 #    Select(0ua758) # Ꝙ

# V (左上にセリフを追加してYやレと区別しやすく)
    Select(0u0056); Copy() # V
    Select(${address_dvz_latin} + 1); Paste() # 避難所
    Select(${address_dvz_latin} + 4); Paste()
    Select(${address_dvz_latin} + 7); Paste()
    Select(${address_dvz_latin} + 10); Paste()
    Select(${address_dvz_latin} + 13); Paste()
    Select(${address_dvz_latin} + 16); Paste()

    # 右上の先端を少し伸ばす
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Move(350, 0)
    Select(0u0056); Copy() # V
    Select(65552);  PasteInto()
    OverlapIntersect()
    Copy()
    Select(0u0056) # V
    if (input_list[i] == "${input_latin_regular}")
        PasteWithOffset(4, 12) # V
    else
        PasteWithOffset(4, 13) # V
    endif
    # セリフ追加
    Select(0u00af); Copy() # macron
    Select(65552);  Paste() # Temporary glyph
    Scale(80, 105); Copy()
    Select(0u0056); # V
    if (input_list[i] == "${input_latin_regular}")
        PasteWithOffset(-163, 2) # V
    else
        PasteWithOffset(-148, -21) # V
    endif

    SetWidth(500)
    RemoveOverlap()
    Simplify()
    RoundToInt()

    Select(65552); Clear() # Temporary glyph

 #    Select(0u0056); Copy() # V
 #    Select(0u01b2) # Ʋ
 #    Select(0u1e7c) # Ṽ
 #    Select(0u1e7e) # Ṿ
 #    Select(0ua75e) # Ꝟ

# W (右の線を少し太く)
    if (input_list[i] == "${input_latin_regular}")
        Select(0u2588); Copy() # Full block
        Select(65552);  Paste() # Temporary glyph
        Scale(22, 45); Move(-50, 20); Copy()
        PasteWithOffset(225, 0)
        Select(0u0057); Copy() # W
        Select(65552);  PasteInto() # Temporary glyph
        OverlapIntersect()
        Copy()

        Select(0u0057) # W
        PasteWithOffset(-4, 0)
        SetWidth(500)
        RemoveOverlap()
        Simplify()

        Select(65552);  Clear() # Temporary glyph

        Select(0u2588); Copy() # Full block
        Select(0u0174); PasteWithOffset(0,  1035); OverlapIntersect() # Ŵ
        Select(0u1e80); PasteWithOffset(0,  1035); OverlapIntersect() # Ẁ
        Select(0u1e82); PasteWithOffset(0,  1035); OverlapIntersect() # Ẃ
        Select(0u1e84); PasteWithOffset(0,  1035); OverlapIntersect() # Ẅ
        Select(0u0057); Copy() # W
        Select(0u0174); PasteInto(); SetWidth(500) # Ŵ
        Select(0u1e80); PasteInto(); SetWidth(500) # Ẁ
        Select(0u1e82); PasteInto(); SetWidth(500) # Ẃ
        Select(0u1e84); PasteInto(); SetWidth(500) # Ẅ
 #        Select(0u1e86) # Ẇ
 #        Select(0u1e88) # Ẉ
 #        Select(0u2c72) # Ⱳ

    endif

# Z (クロスバーを付加してゼェーットな感じに)
    Select(0u005a); Copy() # V
    Select(${address_dvz_latin} + 2); Paste() # 避難所
    Select(${address_dvz_latin} + 5); Paste()
    Select(${address_dvz_latin} + 8); Paste()
    Select(${address_dvz_latin} + 11); Paste()
    Select(${address_dvz_latin} + 14); Paste()
    Select(${address_dvz_latin} + 17); Paste()

    Select(0u00af); Copy()  # macron
    Select(65552);  Paste() # Temporary glyph
    Scale(110, 109); Rotate(-2)
    Copy()
    Select(0u005a) # Z
    if (input_list[i] == "${input_latin_regular}")
        PasteWithOffset(6, -279)
    else
        PasteWithOffset(6, -287)
    endif
    SetWidth(500)
    RemoveOverlap()

    Select(65552);  Clear() # Temporary glyph

 #    Select(0u005a); Copy() # Z
 #    Select(0u0179) # Ź
 #    Select(0u017b) # Ż
 #    Select(0u017d) # Ž
 #    Select(0u1e92) # Ẓ

 #    Select(0u01b5) # Ƶ
 #    Select(0u0224) # Ȥ
 #    Select(0u1e90) # Ẑ
 #    Select(0u1e94) # Ẕ
 #    Select(0u2c6b) # Ⱬ
 #    Select(0u2c7f) # Ɀ

# b (縦線を少し細くする)
    Select(0u2588); Copy() # Full block
    Select(0u0062) # b
    if (input_list[i] == "${input_latin_regular}")
        PasteWithOffset(63, 0)
    else
        PasteWithOffset(55, 0)
    endif
    SetWidth(500)
    OverlapIntersect()

 #    Select(0u0062); Copy() # b
 #    Select(0u1e03) # ḃ
 #    Select(0u0180) # ƀ
 #    Select(0u0253) # ɓ
 #    Select(0u0183) # ƃ
 #    Select(0u1d6c) # ᵬ
 #    Select(0u1d80) # ᶀ
 #    Select(0u1e05) # ḅ
 #    Select(0u1e07) # ḇ
 #    Select(0ua797) # ꞗ

# f (右端を少しカット、少し右にずらす)
    # 先っぽをコピー
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Scale(20, 5)
    if (input_list[i] == "${input_latin_regular}")
        Move(170, 260)
    else
        Move(175, 245)
    endif
    Select(0u0066); RemoveOverlap(); Copy() # f
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    # 先っぽを装着
    if (input_list[i] == "${input_latin_regular}")
        Rotate(11)
        Copy()
        Select(0u0066) # f
        PasteWithOffset(-31, 33)
    else
        Rotate(4)
        Copy()
        Select(0u0066) # f
        PasteWithOffset(-25, 23)
    endif
    RemoveOverlap()

    # 先端カット
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Rotate(-28); Move(184, 0)
    else
        Rotate(-28); Move(213, 0)
    endif
    PasteWithOffset(465, -530)
    RemoveOverlap()
    Copy()
    Select(0u0066); PasteWithOffset(-465, 0) # f
    OverlapIntersect()
    Move(10, 0)
    SetWidth(500)
    Simplify()

    Select(65552); Clear() # Temporary glyph

 #    Select(0u0192) # ƒ
 #    Select(0u1d6e) # ᵮ
 #    Select(0u1d82) # ᶂ
 #    Select(0u1e1f) # ḟ
 #    Select(0ua799) # ꞙ

# i (ほんの少し右へ移動)
    Select(0u0069) # i
    SelectMore(0u00ec) # ì
    SelectMore(0u00ed) # í
    SelectMore(0u00ee) # î
    SelectMore(0u00ef) # ï
    SelectMore(0u0129) # ĩ
    SelectMore(0u012b) # ī
    SelectMore(0u012d) # ĭ
    SelectMore(0u012f) # į
    SelectMore(0u0130) # ı
    SelectMore(0u0268) # ɨ
    SelectMore(0u0209) # ȉ
    SelectMore(0u020b) # ȋ
    SelectMore(0u1e2f) # ḯ
    SelectMore(0u1ec9) # ỉ
    SelectMore(0u1ecb) # ị
 #    Select(0u01d0) # ǐ
 #    Select(0u1d96) # ᶖ
 #    Select(0u1e2d) # ḭ
    Move(10, 0)
    SetWidth(500)

# l (縦線を少し細くし、左を少しカットして少し左へ移動)
    Select(0u006c); Copy() # l
    PasteWithOffset(-1, 0)
    OverlapIntersect()

    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Move(116, 600)
        PasteWithOffset(154, 0)
 #        PasteWithOffset(214, 0)
    else
        Move(96, 600)
        PasteWithOffset(134, 0)
 #        PasteWithOffset(194, 0)
    endif
    RemoveOverlap()
    Copy()

    Select(0u006c); PasteInto() # l
    OverlapIntersect()
    Move(-10,0); SetWidth(500)

    Select(0u0142); PasteInto() # ł
    OverlapIntersect()
    Move(-10,0); SetWidth(500)

    Select(65552); Clear() # Temporary glyph

    Select(0u2588); Copy() # Full block
    Select(0u013a); PasteWithOffset(  0,  1073); OverlapIntersect(); Move(-10, 0) # ĺ
    Select(0u013c); PasteWithOffset(  0, -1001); OverlapIntersect(); Move(-10, 0) # ļ
    Select(0u013e); PasteWithOffset(320,   835); OverlapIntersect(); Move(-10, 0) # ľ
    Select(0u0140); PasteWithOffset(320,   655); OverlapIntersect(); Move(-10, 0) # ŀ
    Select(0u1e37); PasteWithOffset(  0, -1001); OverlapIntersect(); Move(-10, 0) # ḷ
    Select(0u1e3b); PasteWithOffset(  0, -1001); OverlapIntersect(); Move(-10, 0) # ḻ
    Select(0u006c); Copy() # l
    Select(0u013a); PasteInto(); SetWidth(500)
    Select(0u013c); PasteInto(); SetWidth(500)
    Select(0u013e); PasteInto(); SetWidth(500)
    Select(0u0140); PasteInto(); SetWidth(500)
    Select(0u1e37); PasteInto(); SetWidth(500)
    Select(0u1e3b); PasteInto(); SetWidth(500)
 #    Select(0u019a) # ƚ
 #    Select(0u0234) # ȴ
 #    Select(0u026b, 0u026d) # ɫɬɭ
 #    Select(0u1d85) # ᶅ
 #    Select(0u1e39) # ḹ
 #    Select(0u1e3d) # ḽ
 #    Select(0u2c61) # ⱡ
 #    Select(0ua749) # ꝉ
 #    Select(0ua78e) # ꞎ
 #    Select(0uab37, 0uab39) # ꬷꬸꬹ

# m (縦線を少し太く)
    if (input_list[i] == "${input_latin_regular}")
        Select(0u006d); Copy() # m
        PasteWithOffset(-2,0)
        RemoveOverlap()

        # 縦横比変更時にゴミが出るため、一旦脚を切って付け直す
        Select(0u2588); Copy() # Full block
        Select(0u006d); PasteWithOffset(0, 450) # m
        OverlapIntersect()

        Select(0u2588); Copy() # Full block
        Select(65552);  Paste() # Temporary glyph
        Move(0, -850)
        Select(0u006d); Copy() # m
        Select(65552);  PasteInto() # Temporary glyph
        OverlapIntersect()
        Copy()
        Select(0u006d); PasteWithOffset(0, -50) # m

        SetWidth(500)
        RemoveOverlap()
        Simplify()

        Select(0u2588); Copy() # Full block
        Select(0u1e43); PasteWithOffset(  0, -1020); OverlapIntersect() # ṃ
        Select(0u006d); Copy() # m
        Select(0u1e43); PasteInto(); SetWidth(500) # ṃ
 #        Select(0u0271) # ɱ
 #        Select(0u1d6f) # ᵯ
 #        Select(0u1d86) # ᶆ
 #        Select(0u1e3f) # ḿ
 #        Select(0u1e41) # ṁ
 #        Select(0uab3a) # ꬺ
    endif

# r (右端を少しカット、少し右にずらす)
    # 先っぽをコピー
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Scale(20, 5)
    if (input_list[i] == "${input_latin_regular}")
        Move(165, 80)
    else
        Move(155, 50)
    endif
    Select(0u0072); RemoveOverlap(); Copy() # r
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    # r 先っぽを装着
    if (input_list[i] == "${input_latin_regular}")
        Rotate(3)
        Copy()
        Select(0u0072) # r
        PasteWithOffset(-32, 23)
    else
        Rotate(1)
        Copy()
        Select(0u0072) # r
        PasteWithOffset(-37, 35)
    endif
    RemoveOverlap()
    # ɍ 先っぽを装着
    Select(65552) # Temporary glyph
    Copy()
    Select(0u0024d) # ɍ
    if (input_list[i] == "${input_latin_regular}")
        PasteWithOffset(-32, 23)
    else
        PasteWithOffset(-37, 35)
    endif
    RemoveOverlap()

    # 先端カット
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Rotate(-28); Move(280, 0)
    PasteWithOffset(465, -735)
    RemoveOverlap()
    Copy()
    # r
    Select(0u0072); PasteWithOffset(-465, 0) # r
    OverlapIntersect()
    Move(5, 0)
    SetWidth(500)
    Simplify()
    # ɍ
    Select(65552); Copy() # Temporary glyph
    Select(0u024d); PasteWithOffset(-465, 0) # ɍ
    OverlapIntersect()
    Move(5, 0)
    SetWidth(500)
    Simplify()

    Select(65552); Clear() # Temporary glyph

    Select(0u2588); Copy() # Full block
    Select(0u0155); PasteWithOffset(0,   878); OverlapIntersect() # ŕ
    Select(0u0157); PasteWithOffset(0, -1001); OverlapIntersect() # ŗ
    Select(0u0159); PasteWithOffset(0,   878); OverlapIntersect() # ř
    Select(0u0211); PasteWithOffset(0,   878); OverlapIntersect() # ȑ
    Select(0u0213); PasteWithOffset(0,   878); OverlapIntersect() # ȓ
    Select(0u1e5b); PasteWithOffset(0, -1001); OverlapIntersect() # ṛ
    Select(0u0072); Copy() # r
    Select(0u0155); PasteInto(); SetWidth(500)
    Select(0u0157); PasteInto(); SetWidth(500)
    Select(0u0159); PasteInto(); SetWidth(500)
    Select(0u0211); PasteInto(); SetWidth(500)
    Select(0u0213); PasteInto(); SetWidth(500)
    Select(0u1e5b); PasteInto(); SetWidth(500)
 #    Select(0u027c, 0u027e) # ɼɽɾ
 #    Select(0u1d72, 0u1d73) # ᵲᵳ
 #    Select(0u1d89) # ᶉ
 #    Select(0u1e5d) # ṝ
 #    Select(0u1e5f) # ṟ
 #    Select(0ua75b) # ꝛ
 #    Select(0ua7a7) # ꞧ
 #    Select(0uab47) # ꭇ
 #    Select(0uab49) # ꭉ

# u (少し左に移動)
    if (input_list[i] == "${input_latin_regular}")
        Select(0u0075) # u
        SelectMore(0u00f9) # ù
        SelectMore(0u00fa) # ú
        SelectMore(0u00fb) # û
        SelectMore(0u00fc) # ü
        SelectMore(0u0169) # ũ
        SelectMore(0u016b) # ū
        SelectMore(0u016d) # ŭ
        SelectMore(0u016f) # ů
        SelectMore(0u0171) # ű
        SelectMore(0u0173) # ų
        SelectMore(0u01b0) # ư
        SelectMore(0u0215) # ȕ
        SelectMore(0u0217) # ȗ
        SelectMore(0u1e79) # ṹ
        SelectMore(0u1e7b) # ṻ
        SelectMore(0u1ee5) # ụ
        SelectMore(0u1ee7) # ủ
        SelectMore(0u1ee9) # ứ
        SelectMore(0u1eeb) # ừ
        SelectMore(0u1eed) # ử
        SelectMore(0u1eef) # ữ
        SelectMore(0u1ef1) # ự
        Move(-5, 0)
        SetWidth(500)

 #        Select(0u01d4) # ǔ
 #        Select(0u01d6) # ǖ
 #        Select(0u01d8) # ǘ
 #        Select(0u01da) # ǚ
 #        Select(0u01dc) # ǜ
 #        Select(0u0289) # ʉ
 #        Select(0u1d99) # ᶙ
 #        Select(0u1e73) # ṳ
 #        Select(0u1e75) # ṵ
 #        Select(0u1e77) # ṷ
 #        Select(0uab4e) # ꭎ
 #        Select(0uab4f) # ꭏ
 #        Select(0uab52) # ꭒ
    endif

# g をオープンテイルに変更するため、それに合わせてjpqyの尻尾を伸ばす
# j
    # 下
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Move(0, -935)
    Select(0u006a); Copy() # j
    Select(65552);  PasteInto()
    OverlapIntersect()
    # 上
    Select(0u2588); Copy() # Full block
    Select(0u006a); PasteWithOffset(0, 420) # j
    OverlapIntersect()
    # 合成
    Select(65552);  Copy()
    Select(0u006a); PasteWithOffset(0, -23) # j

    SetWidth(500)
    RemoveOverlap()
    Simplify()

    Select(0u2588); Copy() # Full block
    Select(0u0135); PasteWithOffset(0, 420) # ĵ
    OverlapIntersect()
    Select(65552);  Copy()
    Select(0u0135); PasteWithOffset(0, -23) # ĵ

    SetWidth(500)
    RemoveOverlap()
    Simplify()

 #    Select(0u006a); Copy() # j
 #    Select(0u01f0) # ǰ
 #    Select(0u0249) # ɉ
 #    Select(0u029d) # ʝ

# p (ついでに縦線を少し細くする)
    # 下
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Move(0, -1025)
    Select(0u0070); Copy() # p
    Select(65552);  PasteInto()
    OverlapIntersect()
    Copy()
    # 合成
    Select(0u0070); PasteWithOffset(0, -11) # p
    RemoveOverlap()

    Select(0u2588); Copy() # Full block
    Select(0u0070) # p
    if (input_list[i] == "${input_latin_regular}")
        PasteWithOffset(64, 0)
    else
        PasteWithOffset(55, 0)
    endif

    SetWidth(500)
    OverlapIntersect()
    Simplify()

 #    Select(0u0070); Copy() # p
 #    Select(0u01a5) # ƥ
 #    Select(0u1d71) # ᵱ
 #    Select(0u1d7d) # ᵽ
 #    Select(0u1d88) # ᶈ
 #    Select(0u1e55) # ṕ
 #    Select(0u1e57) # ṗ
 #    Select(0ua751) # ꝑ
 #    Select(0ua753) # ꝓ
 #    Select(0ua755) # ꝕ

# q (ついでに縦線を少し細くする) ※ g のオープンテール化で使用するため改変時は注意
    # 下
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Move(0, -1025)
    Select(0u0071); Copy() # q
    Select(65552);  PasteInto()
    OverlapIntersect()
    Copy()
    # 合成
    Select(0u0071); PasteWithOffset(0, -11) # q
    RemoveOverlap()

    Select(0u2588); Copy() # Full block
    Select(0u0071) # q
    if (input_list[i] == "${input_latin_regular}")
        PasteWithOffset(-60, 0)
    else
        PasteWithOffset(-52, 0)
    endif

    SetWidth(500)
    OverlapIntersect()
    Simplify()

 #    Select(0u0071); Copy() # q
 #    Select(0u024b) # ɋ
 #    Select(0u02a0) # ʠ
 #    Select(0ua757) # ꝗ
 #    Select(0ua759) # ꝙ

# y (ついでに少し右にずらす) ※ g のオープンテール化で使用するため改変時は注意
    # 下
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Move(0, -1016)
    Select(0u0079); Copy() # y
    Select(65552);  PasteInto()
    OverlapIntersect()
    # 上
    Select(0u2588); Copy() # Full block
    Select(0u0079) # y
    PasteWithOffset(0, 361)
    OverlapIntersect()
    # 合成
    Select(65552)
    if (input_list[i] == "${input_latin_regular}")
        Scale(102, 100); Copy()
        Select(0u0079); PasteWithOffset(-10, -23) # y
    else
        Scale(103, 100); Copy()
        Select(0u0079); PasteWithOffset(-12, -23) # y
    endif

    Move(5, 0)
    SetWidth(500)
    RemoveOverlap()
    Simplify()
    RoundToInt()

    Select(0u2588); Copy() # Full block
    Select(0u00fd); PasteWithOffset(  0,   867); OverlapIntersect(); Move(5, 0) # ý
    Select(0u00ff); PasteWithOffset(  0,   867); OverlapIntersect(); Move(5, 0) # ÿ
    Select(0u0177); PasteWithOffset(  0,   867); OverlapIntersect(); Move(5, 0) # ŷ
    Select(0u0233); PasteWithOffset(  0,   867); OverlapIntersect(); Move(5, 0) # ȳ
    Select(0u1e8f); PasteWithOffset(  0,   867); OverlapIntersect(); Move(5, 0) # ẏ
    Select(0u1ef3); PasteWithOffset(  0,   867); OverlapIntersect(); Move(5, 0) # ỳ
    Select(0u1ef5); PasteWithOffset(310, -1031); OverlapIntersect(); Move(5, 0) # ỵ
    Select(0u1ef7); PasteWithOffset(  0,   867); OverlapIntersect(); Move(5, 0) # ỷ
    Select(0u1ef9); PasteWithOffset(  0,   867); OverlapIntersect(); Move(5, 0) # ỹ
    Select(0u0079); Copy() # y
    Select(0u00fd); PasteInto(); SetWidth(500)
    Select(0u00ff); PasteInto(); SetWidth(500)
    Select(0u0177); PasteInto(); SetWidth(500)
    Select(0u0233); PasteInto(); SetWidth(500)
    Select(0u1e8f); PasteInto(); SetWidth(500)
    Select(0u1ef3); PasteInto(); SetWidth(500)
    Select(0u1ef5); PasteInto(); SetWidth(500)
    Select(0u1ef7); PasteInto(); SetWidth(500)
    Select(0u1ef9); PasteInto(); SetWidth(500)
 #    Select(0u01b4) # ƴ
 #    Select(0u024f) # ɏ
 #    Select(0u1e99) # ẙ
 #    Select(0u1eff) # ỿ
 #    Select(0uab5a) # ꭚ

    Select(65552); Clear() # Temporary glyph

# 記号のグリフを加工
    Print("Edit symbols")
# ^ -> magnified ^
    Select(0u005e); Scale(110, 110, 250, 600); SetWidth(500)
    if (input_list[i] == "${input_latin_regular}")
        ChangeWeight(-4)
    else
        ChangeWeight(-16)
    endif
    CorrectDirection()

# " -> magnified "
    Select(0u0022); Scale(110, 110, 250, 600); SetWidth(500)

# ' -> magnified '
    Select(0u0027); Scale(110, 110, 250, 600); SetWidth(500)

# , -> magnified ,
    Select(0u002c); Scale(115, 115, 250, 0); SetWidth(500)

# . -> magnified .
    Select(0u002e); Scale(115, 115, 250, 0); SetWidth(500)

# : -> magnified :
    Select(0u003a); Scale(115, 115, 250, 0); SetWidth(500)

# ; -> magnified ;
    Select(0u003b); Scale(115, 115, 250, 0); SetWidth(500)

# \` (拡大して少し下に下げる)
    Select(0u0060); Scale(135, 135, 250, 600); Move(0, -20); SetWidth(500)

# % (斜線を少し太く)
    if (input_list[i] == "${input_latin_regular}")
        Select(0u002f); Copy() # /
        Select(65552);  Paste() # Temporary glyph
        Scale(101)
        Rotate(-4)
        Select(0u0025); Copy() # %
        Select(65552);  PasteInto() # Temporary glyph
        OverlapIntersect()
        Copy()

        Select(0u0025) # %
        PasteWithOffset(14, 0)
        RemoveOverlap()
    endif

    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Scale(150, 48)
    Rotate(-30)
    Copy()
    Select(0u0025) # %
    PasteWithOffset(0, 11)
    SetWidth(500)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph

# () 少し下げる
    Select(0u0028); Move(0, -15); SetWidth(500) # (
    Select(0u0029); Move(0, -15); SetWidth(500) # )

# * (スポーク6つに変更)
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Scale(23, 100); Move(2, 727); Copy()
    Scale(72, 100); PasteWithOffset(0, 80)
    RemoveOverlap()
    Select(0u002a) # *
    if (input_list[i] == "${input_latin_regular}")
        Scale(92, 102)
    else
        Scale(80, 102)
    endif
    Copy()
    Select(65552); PasteInto()
    OverlapIntersect()
    Copy()

    Select(0u002a); Paste()
    Rotate(180, 253, 327); PasteInto(); Copy()
    Rotate(60, 253, 327);  PasteInto()
    Rotate(60, 253, 327);  PasteInto()

    Move(0, -13); SetWidth(500)
    RemoveOverlap()

    Select(65552); Clear()

# _ (少し短くする)
    Select(0u005f) # _
    Scale(94, 100)
    SetWidth(500)

# { } (上下の先端を短くし中央先端を伸ばす、右下に少し移動)
    Select(0u002d); Copy()  # hypen-minus
    Select(65552);  Paste() # Temporary glyph
    Scale(30, 88); Copy()
    # {
    Select(0u007b); PasteWithOffset(-171, 5) # {
    if (input_list[i] == "${input_latin_bold}")
        PasteWithOffset(-171, -1)
    endif
    RemoveOverlap()
    Select(0u2588); Copy() # Full block
    if (input_list[i] == "${input_latin_regular}")
        Select(0u007b); PasteWithOffset(-112, 0) # {
 #        Select(0u007b); PasteWithOffset(-92, 0) # {
    else
        Select(0u007b); PasteWithOffset(-107, 0) # {
 #        Select(0u007b); PasteWithOffset(-87, 0) # {
    endif
    OverlapIntersect()
    Move(22, -14); SetWidth(500)
    Simplify()
    # }
    Select(65552);  Copy() # Temporary glyph
    Select(0u007d); PasteWithOffset(131, 5) # }
    if (input_list[i] == "${input_latin_bold}")
        PasteWithOffset(131, -1)
    endif
    RemoveOverlap()
    Select(0u2588); Copy() # Full block
    if (input_list[i] == "${input_latin_regular}")
        Select(0u007d); PasteWithOffset(74, 0) # }
 #        Select(0u007d); PasteWithOffset(54, 0) # }
    else
        Select(0u007d); PasteWithOffset(69, 0) # }
 #        Select(0u007d); PasteWithOffset(49, 0) # }
    endif
    OverlapIntersect()
    Move(22, -14); SetWidth(500)
    Simplify()

    Select(65552); Clear() # Temporary glyph

# ¿ (上に移動)
    Select(0u00bf) # ¿
    Move(0, 45)
    SetWidth(500)

# ‛ (カナフォントを置換)
    Select(0u2019); Copy() # ’
    Select(0u201b); Paste() # ‛
    HFlip()
    CorrectDirection()
    SetWidth(500)

# ‟ (カナフォントを置換)
    Select(0u201d); Copy() # ”
    Select(0u201f); Paste() # ‟
    HFlip()
    CorrectDirection()
    SetWidth(500)

# ⁂ (漢字フォントを置換)
    Select(0u002a); Copy() # *
    Select(0u2042); Paste() # ⁂
    Move(230, 250)
    PasteWithOffset(-40, -250)
    PasteWithOffset(500, -250)
    Scale(68)
    SetWidth(1000)

# ⁄ (/と区別するため分割)
    Select(0u2044); Copy() # ⁄
    Select(${address_visi_latin}); Paste() # 避難所

    Select(0u2044); Copy() # ⁄
    Select(65552);  Paste() # Temporary glyph
    Scale(120); Copy()
    Select(0u2044) # ⁄
    PasteWithOffset(200, 435); PasteWithOffset(-200, -435)
    SetWidth(500)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph

# ⁑ (漢字フォントを置換)
    Select(0u002a); Copy() # *
    Select(0u2051); Paste() # ⁑
    Move(230, 250)
    PasteWithOffset(230, -250)
    Scale(68)
    SetWidth(1000)

# ∇ (漢字フォントを置換)
    Select(0u2206); Copy() # ∆
    Select(0u2207); Paste() # ∇
    VFlip()
    CorrectDirection()
    SetWidth(500)

# ∏ (上に移動)
    Select(0u220f) # ∏
    Move(0, 100)
    SetWidth(500)

# ∐ (追加)
    Select(0u220f); Copy() # ∏
    Select(0u2210); Paste() # ∐
    VFlip()
    CorrectDirection()
    SetWidth(500)

# ∑ (上に移動)
    Select(0u2211) # ∑
    Move(0, 70)
    SetWidth(500)

# ∓ (漢字フォントを置換)
    Select(0u00b1); Copy() # ±
    Select(0u2213); Paste() # ∓
    VFlip()
    CorrectDirection()
    SetWidth(500)

# ⌀ (追加)
    Select(0u2205); Copy() # ∅
    Select(0u2300); Paste() # ⌀
    Scale(130)
    if (input_list[i] == "${input_latin_regular}")
        ChangeWeight(-10)
    else
        ChangeWeight(-24)
    endif
    CorrectDirection()
    Rotate(2)
    Select(0u007c); Copy() # |
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Scale(99)
    else
        ChangeWeight(-6)
        CorrectDirection()
        Scale(92)
    endif
    Move(0, 76)
    Rotate(-45)
    Copy()
    Select(0u2300); PasteInto() # ⌀
    RemoveOverlap()
    Move(230, 0)
    if (input_list[i] == "${input_latin_bold}")
        Scale(110)
        ChangeWeight(-20)
        CorrectDirection()
    endif
    SetWidth(1000)
    RemoveOverlap()
    Select(65552); Clear() # Temporary glyph

# √ (ボールドのウェイト調整)
    Select(0u221a) # √
    if (input_list[i] == "${input_latin_bold}")
        ChangeWeight(-14)
        CorrectDirection()
        SetWidth(500)
    endif

# ⌂ (全角にする)
    Select(0u2302) # ⌂
    Scale(150)
    Move(230, 120)
    SetWidth(1000)

# ⌘ (全角にする)
    Select(0u2318) # ⌘
    Scale(150)
    Move(230, 120)
    SetWidth(1000)

# ⌥ (全角にする)
    Select(0u2325) # ⌥
    Scale(140, 130)
    Move(230, 120)
    SetWidth(1000)

# ⌦ (全角にする)
    Select(0u2326) # ⌦
    Scale(150)
    Move(230, 50)
    SetWidth(1000)

# ⌧ (全角にする)
    Select(0u2327) # ⌧
    Scale(150)
    Move(230, 50)
    SetWidth(1000)

# ⌫ (全角にする)
    Select(0u232b) # ⌫
    Scale(150)
    Move(230, 50)
    SetWidth(1000)

# ⎇ (追加 ) ※ ⌥ の加工より後にすること
    Select(0u2325); Copy() # ⌥
    Select(0u2387); Paste()
    VFlip()
    CorrectDirection()
    SetWidth(1000)

# ⎈ (追加)
    Select(0u2205); Copy() # ∅
    Select(0u2388); Paste() # ⎈
    Scale(130)
    if (input_list[i] == "${input_latin_regular}")
        ChangeWeight(-10)
    else
        ChangeWeight(-24)
    endif
    CorrectDirection()
    Rotate(47)
    Select(0u007c); Copy() # |
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Scale(99)
    else
        ChangeWeight(-6)
        CorrectDirection()
        Scale(92)
    endif
    Move(0, 76); Copy()
    Rotate(-60); PasteInto()
    Rotate(120); PasteInto()
    Copy()
    Select(0u2388); PasteInto() # ⎈
    RemoveOverlap()
    Move(230, 0)
    if (input_list[i] == "${input_latin_bold}")
        Scale(110)
        ChangeWeight(-20)
        CorrectDirection()
    endif
    SetWidth(1000)
    Select(65552); Clear() # Temporary glyph

# ⎋ (全角にする)
    Select(0u238b) # ⎋
    Scale(150)
    Move(250, 50)
    SetWidth(1000)

# ⏎ (全角にする)
    Select(0u23ce) # ⏎
    Scale(150)
    Move(230, 70)
    SetWidth(1000)

# ␣ (上に移動)
    Select(0u2423) # ␣
    Move(0, 68)
    SetWidth(500)

# ␦ (カナフォントを置換)
    Select(0u003F); Copy() # ?
    Select(0u2426); Paste() # ␦
    HFlip()
    CorrectDirection()
    SetWidth(500)

# ⚹ (カナフォントを置換) ※ * の加工より後にすること
    Select(0u002a); Copy() # *
    Select(0u26b9); Paste() # ⚹
    Rotate(90)
    SetWidth(500)

# ✂ (追加)
    Select(0u0058); Copy() # X
    Select(0u2702); Paste() # ✂
    if (input_list[i] == "${input_latin_bold}")
        ChangeWeight(-16)
        CorrectDirection()
    endif
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Scale(66, 100); Copy()
    Select(0u2702); PasteWithOffset(3, -495) # ✂
    OverlapIntersect()
    Select(0u00b0); Copy() # °
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_bold}")
        ChangeWeight(-16)
        CorrectDirection()
    endif
    Scale(90, 100)
    Rotate(10); Copy()
    Select(0u2702) # ✂
    if (input_list[i] == "${input_latin_regular}")
        PasteWithOffset(-166, 80)
    else
        PasteWithOffset(-166, 55)
    endif
    Select(65552)
    Rotate(-20); Copy()
    Select(0u2702) # ✂
    if (input_list[i] == "${input_latin_regular}")
        PasteWithOffset(154, 80)
    else
        PasteWithOffset(154, 55)
    endif
    Move(225, -30)
    Scale(120)
    SetWidth(1000)
    RemoveOverlap()
    Rotate(90, 490, 340)
    Select(65552); Clear() # Temporary glyph

# | (破線にし、縦に伸ばして少し上へ移動) ※ ⌀⎈ の加工より後にすること
# ¦ (隙間を開ける)
    Select(0u007c); Copy() # |
    Select(${address_visi_latin} + 1); Paste() # 避難所
    if (input_list[i] == "${input_latin_regular}")
        Move(0, 50)
        PasteWithOffset(0, 48)
    else
        Move(0, 55)
        PasteWithOffset(0, 48)
    endif
    Move(0, 13)
    SetWidth(500)
    RemoveOverlap()

    # ¦
    Select(0u007c); Copy() # |
    Select(0u00a6); Paste() # ¦
    if (input_list[i] == "${input_latin_regular}")
        Move(0, 575)
        PasteWithOffset(0, -438)
    else
        Move(0, 577)
        PasteWithOffset(0, -436)
    endif

    # |
    Select(0u007c) # |
    if (input_list[i] == "${input_latin_regular}")
        Move(0, 495)
        PasteWithOffset(0, -358)
    else
        Move(0, 497)
        PasteWithOffset(0, -356)
    endif

    Select(${address_visi_latin} + 1); Copy() # 避難所
    Select(0u007c); PasteInto() # |
    SetWidth(500)
    OverlapIntersect()

    Select(0u00a6); PasteInto() # ¦
    SetWidth(500)
    OverlapIntersect()

# 上付き、下付き数字を置き換え
    Print("Edit superscrips and subscripts")
    Select(0u0031) # 1
    lookups = GetPosSub("*") # フィーチャを取り出す

    Select(0u0031); Copy() # 1
    Select(0u00b9); Paste() # ¹
    Scale(${percent_super_sub}, 250, 0)
    ChangeWeight(${weight_extend_super_sub})
    CorrectDirection()
    Move(0,${y_pos_super})
    SetWidth(500)

    Select(0u0032); Copy() # 2
    Select(0u00b2); Paste() # ²
    Scale(${percent_super_sub}, 250, 0)
    ChangeWeight(${weight_extend_super_sub})
    CorrectDirection()
    Move(0,${y_pos_super})
    SetWidth(500)

    Select(0u0033); Copy() # 3
    Select(0u00b3); Paste() # ³
    Scale(${percent_super_sub}, 250, 0)
    ChangeWeight(${weight_extend_super_sub})
    CorrectDirection()
    Move(0,${y_pos_super})
    SetWidth(500)

    Select(0u0069); Copy() # i
    Select(0u2071); Paste() # ⁱ
    Scale(${percent_super_sub}, 250, 0)
    ChangeWeight(${weight_extend_super_sub})
    CorrectDirection()
    Move(0,${y_pos_super})
    SetWidth(500)
    glyphName = GlyphInfo("Name") # sups フィーチャ追加
    Select(0u0069) # i
    AddPosSub(lookups[0][0],glyphName)

    # ⁰, ⁴-⁹
    j = 0
    while (j < 10)
        if (j < 1 || 3 < j)
            Select(0u0030 + j); Copy()
            Select(0u2070 + j); Paste()
            Scale(${percent_super_sub}, 250, 0)
            ChangeWeight(${weight_extend_super_sub})
            CorrectDirection()
            Move(0,${y_pos_super})
            SetWidth(500)
        endif
        j += 1
    endloop

    # ⁺-ⁿ
    orig = [0u002b, 0u2212, 0u003d, 0u0028, 0u0029, 0u006e]
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(0u207a + j); Paste()
        Scale(${percent_super_sub}, 250, 0)
        ChangeWeight(${weight_extend_super_sub})
        CorrectDirection()
        Move(0,${y_pos_super})
        SetWidth(500)
        glyphName = GlyphInfo("Name") # sups フィーチャ追加
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        j += 1
    endloop

    Select(0u207b) # ⁻
    glyphName = GlyphInfo("Name") # sups フィーチャ追加
    Select(0u002d) # -
    AddPosSub(lookups[0][0],glyphName)

    # ₀-₉
    j = 0
    while (j < 10)
        Select(0u0030 + j); Copy()
        Select(0u2080 + j); Paste()
        Scale(${percent_super_sub}, 250, 0)
        ChangeWeight(${weight_extend_super_sub})
        CorrectDirection()
        Move(0,${y_pos_sub})
        SetWidth(500)
        j += 1
    endloop

    # ₊-ₜ
    orig = [0u002b, 0u2212, 0u003d, 0u0028, 0u0029, 0u0000,\
            0u0061, 0u0065, 0u006f, 0u0078, 0u0259,\
            0u0068, 0u006b, 0u006c, 0u006d,\
            0u006e, 0u0070, 0u0073, 0u0074] # 0u0000はダミー
    j = 0
    while (j < SizeOf(orig))
        if (j != 5)
            Select(orig[j]); Copy()
            Select(0u208a + j); Paste()
            Scale(${percent_super_sub}, 250, 0)
            ChangeWeight(${weight_extend_super_sub})
            CorrectDirection()
            Move(0,${y_pos_sub})
            SetWidth(500)
            glyphName = GlyphInfo("Name") # subs フィーチャ追加
            Select(orig[j])
            AddPosSub(lookups[1][0],glyphName)
        endif
        j += 1
    endloop

    Select(0u208b) # ₋
    glyphName = GlyphInfo("Name") # subs フィーチャ追加
    Select(0u002d) # -
    AddPosSub(lookups[1][0],glyphName)

# 演算子を下に移動
    math = [0u002a, 0u002b, 0u002d, 0u003c,\
            0u003d, 0u003e, 0u00d7, 0u00f7, \
            0u2212, 0u2217, 0u2260] # *+-<=>×÷−∗≠
    j = 0
    while (j < SizeOf(math))
        Select(math[j]);
        Move(0,${y_pos_math})
        SetWidth(500)
        j += 1
    endloop

    math = [0u207a, 0u207b, 0u207c,\
            0u208a, 0u208b, 0u208c] # ⁺⁻⁼₊₋₌
    j = 0
    while (j < SizeOf(math))
        Select(math[j]);
        Move(0,${y_pos_s_math})
        SetWidth(500)
        j += 1
    endloop

# --------------------------------------------------

# 記号を一部クリア
    Print("Remove some glyphs")
    Select(0u2190, 0u21ff); Clear() # 矢印
    Select(0u2190, 0u21ff); Clear() # 矢印
 #    Select(0u2500, 0u256c); Clear() # 罫線
    Select(0u25c6, 0u25c7); Clear() # ダイアモンド
    Select(0u25cb, 0u25cf); Clear() # 円
    Select(0u2660, 0u2667); Clear() # トランプ
    Select(0u2700, 0u2701); Clear() # 装飾記号 (はさみ除く)
    Select(0u2703, 0u27bf); Clear() # 装飾記号
    Select(0u2b05, 0u2b07); Clear() # 矢印
    Select(0u2b95); Clear() # 矢印

# Remove ambiguous glyphs
    Print("Remove some ambiguous glyphs")
 #    Select(0u00a1); Clear() # ¡
 #    Select(0u00a4); Clear() # ¤
 #    Select(0u00a7); Clear() # §
 #    Select(0u00a8); Clear() # ¨
 #    Select(0u00aa); Clear() # ª
 #    Select(0u00ad); Clear() # ­
 #    Select(0u00ae); Clear() # ®
 #    Select(0u00b0); Clear() # °
 #    Select(0u00b1); Clear() # ±
 #    Select(0u00b2, 0u00b3); Clear() # ²³
 #    Select(0u00b4); Clear() # ´
 #    Select(0u00b6, 0u00b7); Claer() # ¶·
 #    Select(0u00b8); Clear() # ¸
 #    Select(0u00b9); Clear() # ¹
 #    Select(0u00ba); Clear() # º
 #    Select(0u00bc, 0u00be); Clear() # ¼½¾
 #    Select(0u00bf); Clear() # ¿
 #    Select(0u00c6); Clear() # Æ
 #    Select(0u00d0); Clear() # Ð
 #    Select(0u00d7); Clear() # ×
 #    Select(0u00d8); Clear() # Ø
 #    Select(0u00de, 0u00e1); Clear() # Þ
 #    Select(0u00e6); Clear() # æ
 #    Select(0u00e8, 0u00ea); Clear() # èéê
 #    Select(0u00ec, 0u00ed); Clear() # ìí
 #    Select(0u00f0); Clear() # ð
 #    Select(0u00f2, 0u00f3); Clear() # òó
 #    Select(0u00f7); Clear() # ÷
 #    Select(0u00f8, 0u00fa); Clear() # øùú
 #    Select(0u00fc); Clear() # ü
 #    Select(0u00fe); Clear() # þ
 #    Select(0u0101); Clear() # ā
 #    Select(0u0111); Clear() # đ
 #    Select(0u0113); Clear() # Ē
 #    Select(0u011b); Clear() # ě
 #    Select(0u0126, 0u0127); Clear() # Ħħ
 #    Select(0u012b); Clear() # ī
 #    Select(0u0131, 0u0133); Clear() # ıĲĳ
 #    Select(0u0138); Clear() # ĸ
 #    Select(0u013f, 0u0142); Clear() # ĿŀŁł
 #    Select(0u0144); Clear() # ń
 #    Select(0u0148, 0u014b); Clear() # ňŉŊŋ
 #    Select(0u014d); Clear() # ō
 #    Select(0u0152, 0u0153); Clear() # Œœ
 #    Select(0u0166, 0u0167); Clear() # Ŧŧ
 #    Select(0u016b); Clear() # ū
 #    Select(0u01ce); Clear() # ǎ
 #    Select(0u01d0); Clear() # ǐ
 #    Select(0u01d2); Clear() # ǒ
 #    Select(0u01d4); Clear() # ǔ
 #    Select(0u01d6); Clear() # ǖ
 #    Select(0u01d8); Clear() # ǘ
 #    Select(0u01da); Clear() # ǚ
 #    Select(0u01dc); Clear() # ǜ
 #    Select(0u0251); Clear() # ɑ
 #    Select(0u0261); Clear() # ɡ
 #    Select(0u02c4); Clear() # ˄
 #    Select(0u02c7); Clear() # ˇ
 #    Select(0u02c9, 0u02cb); Clear() # ˉˊˋ
 #    Select(0u02cd); Clear() # ˍ
 #    Select(0u02d0); Clear() # ː
 #    Select(0u02d8, 0u02db); Clear() # ˘˙˚˛
 #    Select(0u02dd); Clear() # ˝
 #    Select(0u02df); Clear() # ˓
 #    Select(0u0300, 0u036f); Clear() # ダイアクリティカルマーク
 #    Select(0u0391, 0u03a1); Clear() # Α-Ρ
 #    Select(0u03a3, 0u03a9); Clear() # Σ-Ω
 #    Select(0u03b1, 0u03c1); Clear() # α-ρ
 #    Select(0u03c3, 0u03c9); Clear() # σ-ω
 #    Select(0u0401); Clear() # Ё
 #    Select(0u0410, 0u044f); Clear() # А-я
 #    Select(0u0451); Clear() # ё
 #    Select(0u2010); Clear() # ‐
    Select(0u2013, 0u2015); Clear() # –—―
 #    Select(0u2016); Clear() # ‖
 #    Select(0u2018); Clear() # ‘
 #    Select(0u2019); Clear() # ’
 #    Select(0u201c); Clear() # “
 #    Select(0u201d); Clear() # ”
 #    Select(0u2020, 0u2022); Clear() # †‡•
    Select(0u2024, 0u2027); Clear() # ․-‧
    Select(0u2030); Clear() # ‰
    Select(0u2032, 0u2033); Clear() # ′″
    Select(0u2035); Clear() # ‵
    Select(0u203b); Clear() # ※
 #    Select(0u203e); Clear() # ‾
 #    Select(0u2074); Clear() # ⁴
 #    Select(0u207f); Clear() # ⁿ
 #    Select(0u2081, 0u2084); Clear() # ₁₂₃₄
 #    Select(0u20ac); Clear() # €
    Select(0u2103); Clear() # ℃
 #    Select(0u2105); Clear() # ℅
    Select(0u2109); Clear() # ℉
    Select(0u2113); Clear() # ℓ
    Select(0u2116); Clear() # №
    Select(0u2121, 0u2122); Clear() # ℡™
    Select(0u2126); Clear() # Ω
    Select(0u212b); Clear() # Å
    Select(0u2153, 0u2154); Clear() # ⅓⅔
    Select(0u215b, 0u215e); Clear() # ⅛⅜⅞
    Select(0u2160, 0u216b); Clear() # Ⅰ-Ⅻ
    Select(0u2170, 0u2179); Clear() # ⅰ-ⅹ
    Select(0u2189); Clear() # ↉
    Select(0u2190, 0u2194); Clear() # ←↑→↓↔
    Select(0u2195, 0u2199); Clear() # ↕↖↗↘↙
    Select(0u21b8, 0u21b9); Clear() # ↸↹
    Select(0u21d2); Clear() # ⇒
    Select(0u21d4); Clear() # ⇔
    Select(0u21e7); Clear() # ⇧
 #    Select(0u2200); Clear() # ∀
 #    Select(0u2202, 0u2203); Clear() # ∂∃
 #    Select(0u2207, 0u2208); Clear() # ∇∈
 #    Select(0u220b); Clear() # ∋
 #    Select(0u220f); Clear() # ∏
 #    Select(0u2211); Clear() # ∑
 #    Select(0u2215); Clear() # ∕
 #    Select(0u221a); Clear() # √
    Select(0u221d, 0u2220); Clear() # ∝∠
 #    Select(0u2223); Clear() # ∣
    Select(0u2225); Clear() # ∥
 #    Select(0u2227, 0u222c); Clear() # ∧∨∩∪∫∬
 #    Select(0u222e); Clear() # ∮
    Select(0u2234, 0u2237); Clear() # ∴∵∶∷
    Select(0u223c, 0u223d); Clear() # ∼∽
 #    Select(0u2248); Clear() # ≈
 #    Select(0u224c); Clear() # ≌
 #    Select(0u2252); Clear() # ≒
 #    Select(0u2260, 0u2261); Clear() # ≠≡
 #    Select(0u2264, 0u2267); Clear() # ≤≥≦≧
    Select(0u226a, 0u226b); Clear() # ≪≫
 #    Select(0u226e, 0u226f); Clear() # ≮≯
 #    Select(0u2282, 0u2283); Clear() # ⊂⊃
 #    Select(0u2286, 0u2287); Clear() # ⊆⊇
 #    Select(0u2295); Clear() # ⊕
 #    Select(0u2299); Clear() # ⊙
    Select(0u22a5); Clear() # ⊥
    Select(0u22bf); Clear() # ⊿
    Select(0u2312); Clear() # ⌒
    Select(0u2460, 0u249b); Clear() # ①-⒛
    Select(0u249c, 0u24e9); Clear() # ⒜-ⓩ
    Select(0u24eb, 0u24ff); Clear() # ⓫-⓿
 #    Select(0u2500, 0u254b); Clear() # ─-╋
 #    Select(0u2550, 0u2573); Clear() # ═-╳
 #    Select(0u2580, 0u258f); Clear() # ▀-▃
 #    Select(0u2592, 0u2595); Clear() # ▒-▕
    Select(0u25a0, 0u25a1); Clear() # ■□ グリフ加工のため、必ずクリア
    Select(0u25a3, 0u25a9); Clear() # ▣-▩
    Select(0u25b2, 0u25b3); Clear() # ▲△
    Select(0u25b6); Clear() # ▶
    Select(0u25b7); Clear() # ▷
    Select(0u25bc, 0u25bd); Clear() # ▼▽
    Select(0u25c0); Clear() # ◀
    Select(0u25c1); Clear() # ◁
    Select(0u25c6, 0u25c8); Clear() # ◆◇◈
    Select(0u25cb); Clear() # ○
    Select(0u25ce, 0u25d1); Clear() # ◎●◐◑
    Select(0u25e2, 0u25e5); Clear() # ◢◣◤◥
    Select(0u25ef); Clear() # ◯
    Select(0u2605, 0u2606); Clear() # ★☆
    Select(0u2609); Clear() # ☉
    Select(0u260e, 0u260f); Clear() # ☎☏
    Select(0u261c); Clear() # ☜
    Select(0u261e); Clear() # ☞
    Select(0u2640); Clear() # ♀
    Select(0u2642); Clear() # ♂
    Select(0u2660, 0u2661); Clear() # ♠♡
    Select(0u2663, 0u2665); Clear() # ♣♤♥
    Select(0u2667, 0u266a); Clear() # ♧♨♩♪
    Select(0u266c, 0u266d); Clear() # ♬♭
    Select(0u266f); Clear() # ♯
    Select(0u269e, 0u269f); Clear() # ⚞⚟
    Select(0u26bf); Clear() # ⚿
    Select(0u26c6, 0u26cd); Clear() # ⛆-⛍
    Select(0u26cf, 0u26d3); Clear() # ⛃-⛓
    Select(0u26d5, 0u26e1); Clear() # ⛕-⛡
    Select(0u26e3); Clear() # ⛣
    Select(0u26e8, 0u26e9); Clear() # ⛨⛩
    Select(0u26eb, 0u26f1); Clear() # ⛫⛱
    Select(0u26f4); Clear() # ⛴
    Select(0u26f6, 0u26f9); Clear() # ⛶⛷⛸⛹
    Select(0u26fb, 0u26fc); Clear() # ⛻⛼
    Select(0u26fe, 0u26ff); Clear() # ⛾⛿
    Select(0u273d); Clear() # ✽
    Select(0u2776, 0u277f); Clear() # ❶-❿
    Select(0u2b56, 0u2b59); Clear() # ⭖⭗⭘⭙
    Select(0u3248, 0u324f); Clear() # ㉈-㉏
    Select(0ue000, 0uf8ff); Clear() # -
    Select(0ufe00, 0ufe0f); Clear()
 #    Select(0ufffd); Clear()

# --------------------------------------------------

# Proccess before saving
    Print("Process before saving")
    if (0 < SelectIf(".notdef"))
        Clear(); DetachAndRemoveGlyphs()
    endif
    RemoveDetachedGlyphs()
    if ("${draft_flag}" == "true")
        SelectWorthOutputting()
        RoundToInt()
    endif

# --------------------------------------------------

# Save modified latin font
    Print("Save " + output_list[i])
    Save("${tmpdir}/" + output_list[i])
 #    Generate("${tmpdir}/" + output_list[i], "", 0x04)
 #    Generate("${tmpdir}/" + output_list[i], "", 0x84)
    Close()
    Print("")

    i += 1
endloop

Quit()
_EOT_

################################################################################
# Generate script for modified kana fonts
################################################################################

cat > ${tmpdir}/${modified_kana_generator} << _EOT_
#!$fontforge_command -script

Print("- Generate modified kana fonts -")

# Set parameters
input_list  = ["${input_kana_regular}",    "${input_kana_bold}"]
output_list = ["${modified_kana_regular}", "${modified_kana_bold}"]

# Begin loop of regular and bold
i = 0
while (i < SizeOf(input_list))
# Open kana font
    Print("Open " + input_list[i])
    Open(input_list[i])
    SelectWorthOutputting()
    UnlinkReference()
    ScaleToEm(${typo_ascent1000}, ${typo_descent1000})
    SetOS2Value("WinAscent",             ${win_ascent1000}) # Windows用(この範囲外は描画されない)
    SetOS2Value("WinDescent",            ${win_descent1000})
    SetOS2Value("TypoAscent",            ${typo_ascent1000}) # 組版用(em値と合わせる)
    SetOS2Value("TypoDescent",          -${typo_descent1000})
    SetOS2Value("TypoLineGap",           ${typo_linegap1000})
    SetOS2Value("HHeadAscent",           ${hhea_ascent1000}) # Mac用
    SetOS2Value("HHeadDescent",         -${hhea_descent1000})
    SetOS2Value("HHeadLineGap",          ${hhea_linegap1000})

# --------------------------------------------------

# 漢字のグリフクリア
    Print("Remove kanzi glyphs")
 #    Select(0u2e80, 0u2fdf) # 部首
    Select(0u3003) # 〃
    SelectMore(0u3005, 0u3007) # 々〆〇
    SelectMore(0u3021, 0u3029) # 蘇州数字
    SelectMore(0u3038, 0u303d) # 蘇州数字他
    SelectMore(0u3400, 0u4dbf)
    SelectMore(0u4e00, 0u9fff)
    SelectMore(0uf900, 0ufaff)
    SelectMore(0u20000, 0u3ffff)
    Clear(); DetachAndRemoveGlyphs()

# 使用しないグリフクリア
    Print("Remove not used glyphs")
    Select(0, 31)
    SelectMore(0u2060)
    SelectMore(0ufeff)
    SelectMore(0uf0000)
    SelectMore(1114112, 1114114)
    SelectMore(1114129, 1114383)
    SelectMore(1114448, 1114465)
 #    SelectMore(1114129, 1114465)
 #    SelectMore(1114112, 1114465)
    Clear(); DetachAndRemoveGlyphs()

# Clear kerns, position, substitutions
    Print("Clear kerns, position, substitutions")
    RemoveAllKerns()

 #    lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups); j = 0
 #    while (j < numlookups)
 #        Print("Remove GSUB_" + lookups[j])
 #        RemoveLookup(lookups[j]); j++
 #    endloop

    lookups = GetLookups("GPOS"); numlookups = SizeOf(lookups); j = 0
    while (j < numlookups)
        Print("Remove GPOS_" + lookups[j])
        RemoveLookup(lookups[j]); j++
    endloop

# Clear instructions, hints
    Print("Clear instructions, hints")
    SelectWorthOutputting()
    ClearInstrs()
    ClearHints()

# Proccess before editing
    if ("${draft_flag}" == "false")
        Print("Process before editing")
        SelectWorthOutputting()
        RemoveOverlap()
        CorrectDirection()
    endif

# --------------------------------------------------

# Scale down all glyphs
    Print("Scale down all glyphs")
    SelectWorthOutputting()
    SetWidth(-1, 1); Scale(91, 91, 0, 0); SetWidth(110, 2); SetWidth(1, 1)
    Move(23, 0); SetWidth(-23, 1)
 #    RemoveOverlap()

# --------------------------------------------------

# ひらがなのグリフ変更
    Print("Edit hiragana and katakana")
# ゠ (左上を折り曲げる)
    Select(0u30a0); Copy() # ゠
    Select(${address_visi_kana}); Paste() # 避難所

    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(250, 0)
    PasteWithOffset(0, -350)
    RemoveOverlap()
    Copy()
    Select(0u30a0); PasteInto() # ゠
    OverlapIntersect()

    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-500, 0)
    Select(0u30fc); Copy() # ー
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    if (input_list[i] == "${input_kana_regular}")
        Scale(84); Copy()
        Select(0u30a0); PasteWithOffset(118, 101) # ゠
 #        Select(0u30a0); PasteWithOffset(133, 101) # ゠
    else
        Scale(80); Copy()
        Select(0u30a0); PasteWithOffset(131, 106) # ゠
 #        Select(0u30a0); PasteWithOffset(146, 106) # ゠
    endif
    SetWidth(1000)
    RemoveOverlap()
    Simplify()

    Select(65552); Clear() # Temporary glyph

# ー (少し下げる)
    Select(0u30fc); Move(0, -14)

    # ぁ (突き抜ける)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(20, 10 ,153, 0); Move(353, 170); Rotate(-22)
    Select(0u3041); Copy() # ぁ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Rotate(8); Copy()

    Select(0u3041); PasteWithOffset(58, 145) # ぁ
    SetWidth(1000)
    RemoveOverlap()
    Select(65552); Clear() # Temporary glyph

# あ (突き抜ける)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(20, 10 ,153, 0); Move(385, 261); Rotate(-22)
    Select(0u3042); Copy() # あ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Rotate(8); Copy()

    Select(0u3042); PasteWithOffset(62, 160) # あ
    SetWidth(1000)
    RemoveOverlap()
    Select(65552); Clear() # Temporary glyph

# ぃ (左の跳ねを少しカット)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Rotate(-23)
    Move(-300, -400)
    PasteWithOffset(-440, 0)
    PasteWithOffset(430, 0)
    RemoveOverlap()
    Copy()

    Select(0u3043); PasteInto() # ぃ
    SetWidth(1000)
    OverlapIntersect()
    Select(65552); Clear() # Temporary glyph

# い (左の跳ねを少しカット)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Rotate(-23)
    Move(-300, -360)
    PasteWithOffset(-500, 0)
    PasteWithOffset(460, 0)
    RemoveOverlap()
    Copy()

    Select(0u3044); PasteInto() # い
    SetWidth(1000)
    OverlapIntersect()
    Select(65552); Clear() # Temporary glyph

# き (切り離す)
    # 下
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(-425, -441)
    if (input_list[i] == "${input_kana_regular}")
      Rotate(-15)
    else
      Rotate(-12)
      Move(0, -12)
    endif
    PasteWithOffset(-35, -511)
    RemoveOverlap()
    Select(0u304d); Copy() # き
    Select(65553);  PasteInto()
    OverlapIntersect()
    # 上
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(395, 159); Rotate(-10)
    PasteWithOffset(-75, 354)
    RemoveOverlap()
    Select(0u304d); Copy()# き
    Select(65552);  PasteInto()
    OverlapIntersect()
    Copy()
    # 合成
    Select(0u304d); Paste() # き
    Select(65553);  Copy()
    Select(0u304d); PasteInto() # き

    SetWidth(1000)
    RemoveOverlap()
    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ぎ (切り離す)
    # 下
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(-450, -450)
    if (input_list[i] == "${input_kana_regular}")
      Rotate(-15)
    else
      Rotate(-12)
      Move(0, -12)
    endif
    PasteWithOffset(-60, -520)
    RemoveOverlap()
    Select(0u304e); Copy() # ぎ
    Select(65553);  PasteInto()
    OverlapIntersect()
    # 上
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(370, 150); Rotate(-10)
    PasteWithOffset(-100, 345)
    RemoveOverlap()
    Select(0u304e); Copy()# ぎ
    Select(65552);  PasteInto()
    OverlapIntersect()
    Copy()
    # 合成
    Select(0u304e); Paste() # ぎ
    Select(65553);  Copy()
    Select(0u304e); PasteInto() # ぎ

    SetWidth(1000)
    RemoveOverlap()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# け げ (はねる) こ ご (はねて左中を少しカット)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(50, 45 ,153, 0); Move(-180, -60)

    # け
    Select(0u3051); Copy() # け
    Select(65552);  PasteInto()
    OverlapIntersect()
    if (input_list[i] == "${input_kana_regular}")
        Rotate(-20, 236, -35)
        Scale(80, 236, -35)
    else
        Rotate(-20, 279, -35)
        Scale(80, 279, -35)
    endif
    Copy()

    Select(0u3051); PasteInto() # け
    SetWidth(1000)
    RemoveOverlap()

    # げ
    Select(0u3052); # げ
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-12, -9)
    else
        PasteWithOffset(-21, -10)
    endif
    SetWidth(1000)
    RemoveOverlap()

    Select(65552); Rotate(-55); Copy()

    # こ
    Select(0u3053) # こ
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(401, 487)
    else
        PasteWithOffset(382, 468)
    endif
    SetWidth(1000)
    RemoveOverlap()

    # ご
    Select(0u3054) # ご
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(392, 505)
    else
        PasteWithOffset(373, 486)
    endif
    SetWidth(1000)
    RemoveOverlap()

    # こごの左中カット
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-400, -310)
    Rotate(-38)
    PasteWithOffset(190, -500)
    PasteWithOffset(-100, 420)
    PasteWithOffset(190, 420)
    RemoveOverlap()
    Copy()

    Select(0u3053) # こ
    PasteInto()
    SetWidth(1000)
    OverlapIntersect()

    Select(0u3054) # ご
    PasteWithOffset(-9, 0)
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph

# ゖ (はねる)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(50, 40 ,153, 0); Move(-150, -60)
    Select(0u3096); Copy() # ゖ
    Select(65552);  PasteInto()
    OverlapIntersect()
    if (input_list[i] == "${input_kana_regular}")
        Rotate(-20, 293, -35)
        Scale(80, 293, -35)
    else
        Rotate(-20, 329, -35)
        Scale(80, 329, -35)
    endif
    Copy()

    Select(0u3096); PasteInto() # ゖ
    SetWidth(1000)
    RemoveOverlap()
    Select(65552); Clear() # Temporary glyph

# さ (切り離す、左上を少しカット)
    # 下
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(-432, -399)
    if (input_list[i] == "${input_kana_regular}")
      Rotate(-15)
    else
      Rotate(-6)
      Move(0, -40)
    endif
    PasteWithOffset(-42, -469)
    RemoveOverlap()
    Select(0u3055); Copy() # さ
    Select(65553);  PasteInto()
    OverlapIntersect()
    # 上
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(397, 207); Rotate(-10)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-8, 402)
 #        PasteWithOffset(-28, 402)
    else
        PasteWithOffset(-15, 402)
 #        PasteWithOffset(-35, 402)
    endif
    RemoveOverlap()
    Select(0u3055); Copy()# さ
    Select(65552);  PasteInto()
    OverlapIntersect()
    Copy()
    # 合成
    Select(0u3055); Paste() # さ
    Select(65553);  Copy()
    Select(0u3055); PasteInto() # さ

    SetWidth(1000)
    RemoveOverlap()
    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ざ (切り離す、左上を少しカット)
    # 下
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(-447, -407)
    if (input_list[i] == "${input_kana_regular}")
      Rotate(-15)
    else
      Rotate(-6)
      Move(0, -40)
    endif
    PasteWithOffset(-57, -477)
    RemoveOverlap()
    Select(0u3056); Copy() # ざ
    Select(65553);  PasteInto()
    OverlapIntersect()
    # 上
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(388, 198); Rotate(-10)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-18, 393)
 #        PasteWithOffset(-38, 393)
    else
        PasteWithOffset(-26, 393)
 #        PasteWithOffset(-46, 393)
    endif
    RemoveOverlap()
    Select(0u3056); Copy()# ざ
    Select(65552);  PasteInto()
    OverlapIntersect()
    Copy()
    # 合成
    Select(0u3056); Paste() # ざ
    Select(65553);  Copy()
    Select(0u3056); PasteInto() # ざ

    SetWidth(1000)
    RemoveOverlap()
    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# せ ぜ (アウトラインの修正と右下を少しカット)
    # せ のアウトライン修正
    if (input_list[i] == "${input_kana_bold}")
        Select(0u30fb); Copy() # ・
        Select(65552);  Paste() # Temporary glyph
        Rotate(3)
        Scale(90, 67); Copy()
        Select(0u305b); PasteWithOffset(325, 190) # せ
        SetWidth(1000)
        RemoveOverlap()
        Select(65552); Clear() # Temporary glyph
    endif

    # 右下カット
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-90, -100)
    Rotate(6)
    PasteWithOffset(-100, 140)
    PasteWithOffset(-100, -100)
    PasteWithOffset(190, 140)
    RemoveOverlap()
    Copy()

    Select(0u305b) # せ
    PasteWithOffset(10, 0)
    SetWidth(1000)
    OverlapIntersect()

    Select(0u305c) # ぜ
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-24, -9)
    else
        PasteWithOffset(-14, -9)
    endif
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph

# そ ぞ (右下を少しカット)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(-80, -160)
    else
        Move(-65, -160)
    endif
    Rotate(6)
    PasteWithOffset(-100, 140)
    PasteWithOffset(190, 140)
    RemoveOverlap()
    Copy()

    Select(0u305d) # そ
    PasteWithOffset(0, 0)
    SetWidth(1000)
    OverlapIntersect()

    Select(0u305e) # ぞ
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-24, 0)
    else
        PasteWithOffset(-19, 0)
    endif
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph

# た (右下の線を少しカットして右に移動)
    # 右下
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(30,30)
    if (input_list[i] == "${input_kana_regular}")
        Rotate(50)
        Move(-65, -175)
    else
        Rotate(55)
        Move(-40, -185)
    endif
    PasteWithOffset(190, -500)
    RemoveOverlap()
    Select(0u305f); Copy() # た
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()

    # その他
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(-470, 300)
    PasteWithOffset(-470, -100)
    PasteWithOffset(190, 300)
    RemoveOverlap()
    Copy()
    Select(0u305f) # た
    PasteInto()
    OverlapIntersect()

    # 合成
    Select(65552);  Copy() # Temporary glyph
    Select(0u305f) # た
    PasteWithOffset(20, 0)

    SetWidth(1000)

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# だ (右下の線を少しカットして右に移動)
    # 右下
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(30,30)
    if (input_list[i] == "${input_kana_regular}")
        Rotate(50)
        Move(-74, -184)
    else
        Rotate(55)
        Move(-49, -194)
    endif
    PasteWithOffset(190, -500)
    RemoveOverlap()
    Select(0u3060); Copy() # だ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()

    # その他
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(-470, 300)
    PasteWithOffset(-470, -100)
    PasteWithOffset(190, 300)
    RemoveOverlap()
    Copy()
    Select(0u3060) # だ
    PasteInto()
    OverlapIntersect()

    # 合成
    Select(65552);  Copy() # Temporary glyph
    Select(0u3060) # だ
    PasteWithOffset(20, 0)

    SetWidth(1000)

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ち ぢ (左下を少しカット)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(150, -160)
    Rotate(-10)
    PasteWithOffset(-100, 140)
    PasteWithOffset(190, 140)
    RemoveOverlap()
    Copy()

    Select(0u3061) # ち
    PasteWithOffset(0, 0)
    SetWidth(1000)
    OverlapIntersect()

    Select(0u3062) # ぢ
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-19, -10)
    else
        PasteWithOffset(-19, -9)
    endif
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph

# な (切り離す)
    # 左下
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(-280, 140)
    PasteWithOffset(-280, 0)
    PasteWithOffset(100, -230)
    RemoveOverlap()
    Select(0u306a); Copy() # な
    Select(65553);  PasteInto()
    OverlapIntersect()
    # 右上
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(370, 541); Rotate(-10, 683, 541)
        PasteWithOffset(370, 541)
    else
        Move(370, 510); Rotate(-10, 713, 510)
        PasteWithOffset(370, 510)
    endif
    RemoveOverlap()
    Select(0u306a); Copy() # な
    Select(65552);  PasteInto()
    OverlapIntersect()
    if (input_list[i] == "${input_kana_regular}")
        Rotate(-15, 683, 541)
    else
        Rotate(-15, 713, 510)
    endif
    Copy()
    # 合成
    Select(0u306a); Paste() # な
    Select(65553);  Copy()
    Select(0u306a); PasteInto() # な

    SetWidth(1000)
    RemoveOverlap()
    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# に (はねる、右下の線を少しカットして右に移動)
    # はねる
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(50, 45 ,153, 0); Move(-180, -60)
    Select(0u306b); Copy() # に
    Select(65552);  PasteInto()
    OverlapIntersect()
    if (input_list[i] == "${input_kana_regular}")
        Rotate(-20, 246, -35)
        Scale(80, 246, -35)
    else
        Rotate(-20, 288, -35)
        Scale(80, 288, -35)
    endif
    Copy()

    Select(0u306b); PasteInto() # に
    RemoveOverlap()

    # 右下の線を少しカットして右に移動
    # 右下
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(25,25)
    if (input_list[i] == "${input_kana_regular}")
        Rotate(50)
        Move(-55, -95)
    else
        Rotate(55)
        Move(-40, -100)
    endif
    PasteWithOffset(190, -450)
    RemoveOverlap()
    Select(0u306b); Copy() # に
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()

    # その他
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(-470, 300)
    PasteWithOffset(-470, -100)
    PasteWithOffset(190, 420)
    RemoveOverlap()
    Copy()
    Select(0u306b) # に
    PasteInto()
    OverlapIntersect()

    # 合成
    Select(65552);  Copy() # Temporary glyph
    Select(0u306b) # に
    PasteWithOffset(10, 0)

    SetWidth(1000)

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ぬ (突き抜ける)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(20, 10 ,153, 0); Move(110, 265); Rotate(20)
    Select(0u306c); Copy() # ぬ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Rotate(8); Copy()

    Select(0u306c); PasteWithOffset(83, -215) # ぬ
    SetWidth(1000)
    RemoveOverlap()
    Select(65552); Clear() # Temporary glyph

# は ば ぱ (はねる)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(50, 45 ,153, 0); Move(-180, -60)
    Select(0u306f); Copy() # は
    Select(65552);  PasteInto()
    OverlapIntersect()
    if (input_list[i] == "${input_kana_regular}")
        Rotate(-20, 222, -35)
        Scale(80, 222, -35)
    else
        Rotate(-20, 258, -35)
        Scale(80, 258, -35)
    endif
    Copy()

    Select(0u306f); PasteInto() # は
    SetWidth(1000)
    RemoveOverlap()

    Select(0u3070) # ば
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-15, -9)
    else
        PasteWithOffset(-16, -10)
    endif
    SetWidth(1000)
    RemoveOverlap()

    Select(0u3071) # ぱ
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-27, -9)
    else
        PasteWithOffset(-9, -10)
    endif
    SetWidth(1000)
    RemoveOverlap()

    Select(65552); Clear() # Temporary glyph

# ふ (切り離す)
    # 下
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(-193, -236); Rotate(5)
    PasteWithOffset(-143, -241)
    PasteWithOffset(157, -241)
    RemoveOverlap()
    Select(0u3075); Copy() # ふ
    Select(65553);  PasteInto()
    OverlapIntersect()
    # 上
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(7, 604); Rotate(-40)
    PasteWithOffset(-353, 579)
    PasteWithOffset(407, 424)
    RemoveOverlap()
    Select(0u3075); Copy()# ふ
    Select(65552);  PasteInto()
    OverlapIntersect()
    Rotate(-5, 500, 510); Copy()
    # 合成
    Select(0u3075); Paste() # ふ
    Move(-10, 0)
    Select(65553);  Copy()
    Select(0u3075); PasteInto() # ふ

    SetWidth(1000)
    RemoveOverlap()
    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ぶ (切り離す)
    # 下
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(-209, -265); Rotate(5)
    PasteWithOffset(-159, -250)
    PasteWithOffset(141, -250)
    RemoveOverlap()
    Select(0u3076); Copy() # ぶ
    Select(65553);  PasteInto()
    OverlapIntersect()
    # 上
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-9, 615); Rotate(-40)
    PasteWithOffset(-369, 570)
    PasteWithOffset(391, 415)
    RemoveOverlap()
    Select(0u3076); Copy()# ぶ
    Select(65552);  PasteInto()
    OverlapIntersect()
    Select(0u25a0); Copy() # Black square
    Select(65552)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-147, 16)
    else
        PasteWithOffset(-197, 16)
    endif
    OverlapIntersect()
    Rotate(-5, 484, 501); Copy()
    # 合成
    Select(0u3076); Paste() # ぶ
    Move(-10, 0)
    Select(65553);  Copy()
    Select(0u3076); PasteInto() # ぶ

 #    # 濁点を後でまとめて付けるようにしたため無効
 #    # ゛
 #    Select(0u25a0); Copy() # Black square
 #    Select(65552);  Paste() # Temporary glyph
 #    Move(260, 440); Rotate(45)
 #    Select(0u3079); Copy()# べ
 #    Select(65552);  PasteInto()
 #    OverlapIntersect()
 #    Scale(95); Rotate(-5)
 #    Copy()
 #    Select(0u3076) # ぶ
 #    if (input_list[i] == "${input_kana_regular}")
 #        PasteWithOffset(105, 89)
 #    else
 #        PasteWithOffset(45, 25)
 #    endif

    SetWidth(1000)
    RemoveOverlap()
    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ぷ (切り離す)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-175, 60)
    PasteWithOffset(-150, -200)
    PasteWithOffset(120, -200)
    RemoveOverlap()
    Select(0u3076); Copy() # ぶ
    Select(65552) # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
          PasteWithOffset(9, 0)
    else
          PasteWithOffset(5, 0)
    endif
    OverlapIntersect()
    Copy()

    Select(0u3077); Paste() # ぷ

 #    # ぶ を使わず ぷ を加工する場合
 #    # 下
 #    Select(0u25a0); Copy() # Black square
 #    Select(65553);  Paste() # Temporary glyph
 #    Move(-200, -265); Rotate(5)
 #    PasteWithOffset(-150, -250)
 #    PasteWithOffset(150, -250)
 #    RemoveOverlap()
 #    Select(0u3077); Copy() # ぷ
 #    Select(65553);  PasteInto()
 #    OverlapIntersect()
 #    # 上
 #    Select(0u25a0); Copy() # Black square
 #    Select(65552);  Paste() # Temporary glyph
 #    Move(-9, 615); Rotate(-40)
 #    PasteWithOffset(-369, 570)
 #    PasteWithOffset(391, 415)
 #    RemoveOverlap()
 #    Select(0u3077); Copy()# ぷ
 #    Select(65552);  PasteInto()
 #    OverlapIntersect()
 #    Select(0u25a0); Copy() # Black square
 #    Select(65552)
 #    if (input_list[i] == "${input_kana_regular}")
 #        PasteWithOffset(-235, 16)
 #    else
 #        PasteWithOffset(-265, 16)
 #    endif
 #    OverlapIntersect()
 #    Rotate(-5, 493, 501); Copy()
    # 合成
 #    Select(0u3077); Paste() # ぷ
 #    Move(-10, 0)
 #    Select(65553);  Copy()
 #    Select(0u3077); PasteInto() # ぷ

    # ゜
 #    Select(0u25a0); Copy() # Black square
 #    Select(65552);  Paste() # Temporary glyph
 #    Move(260, 440); Rotate(45)
 #    Select(0u307a); Copy()# ぺ
 #    Select(65552);  PasteInto()
 #    OverlapIntersect()
 #    Scale(95); Copy()
 #    Select(0u3077) # ぷ
 #    if (input_list[i] == "${input_kana_regular}")
 #        PasteWithOffset(9, 39)
 #    else
 #        PasteWithOffset(-22, 12)
 #    endif

    SetWidth(1000)
    RemoveOverlap()
    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ほ ぼ ぽ (はねる)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(50, 45 ,153, 0); Move(-180, -60)
    Select(0u307b); Copy() # ほ
    Select(65552);  PasteInto()
    OverlapIntersect()
    if (input_list[i] == "${input_kana_regular}")
        Rotate(-20, 222, -35)
        Scale(80, 222, -35)
    else
        Rotate(-20, 258, -35)
        Scale(80, 258, -35)
    endif
    Copy()

    Select(0u307b); PasteInto() # ほ
    SetWidth(1000)
    RemoveOverlap()

    Select(0u307c) # ぼ
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-9, -9)
    else
        PasteWithOffset(-9, -10)
    endif
    SetWidth(1000)
    RemoveOverlap()

    Select(0u307d) # ぽ
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-9, -9)
    else
        PasteWithOffset(-9, -10)
    endif
    SetWidth(1000)
    RemoveOverlap()

    Select(65552); Clear() # Temporary glyph

# み (左上を少しカット)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(30, 70)
    PasteWithOffset(-100, -170)
    PasteWithOffset(200, 0)
    RemoveOverlap()
    Copy()

    Select(0u307f); PasteInto() # み
    SetWidth(1000)
    OverlapIntersect()
    Select(65552); Clear() # Temporary glyph

# め (突き抜ける)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(20, 10 ,153, 0); Move(132, 272); Rotate(20)
    Select(0u3081); Copy() # め
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Rotate(8); Copy()

    Select(0u3081); PasteWithOffset(83, -215) # め
    SetWidth(1000)
    RemoveOverlap()
    Select(65552); Clear() # Temporary glyph

# ら (左下を少しカット)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(160, -160)
    else
        Move(150, -160)
    endif
    Rotate(-5)
    PasteWithOffset(-100, 140)
    PasteWithOffset(190, 140)
    RemoveOverlap()
    Copy()

    Select(0u3089) # ら
    PasteWithOffset(-40, -10)
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph

# り (切り離す)
    # 左
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-480, 60); Rotate(50)
    PasteWithOffset(-495, 100)
    RemoveOverlap()
    Select(0u308a); Copy() # り
    Select(65552);  PasteInto()
    OverlapIntersect()
    Rotate(-2, 210, 240)
    # 右上
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(300, 390)
    Select(0u308a); Copy() # り
    Select(65553);  PasteInto()
    OverlapIntersect()
    Scale(100, 200, 0, 390)
    Copy()
    if (input_list[i] == "${input_kana_regular}")
        Scale(105, 105, 724, 390)
    else
        Scale(105, 120, 688, 390)
    endif
    PasteInto()
    OverlapIntersect()
    Select(0u25a0); Copy() # Black square
    Select(65554);  Paste()
    Move(480, 20)
    Rotate(15, 625, 685)
    PasteWithOffset(480, 0)
    RemoveOverlap()
    Copy()
    Select(65553);  PasteInto()
    OverlapIntersect()
    # 右下
    Select(0u25a0); Copy() # Black square
    Select(65554);  Paste() # Temporary glyph
    Move(180, -500)
    Rotate(2, 300, 0)
    PasteWithOffset(350, -273)
    RemoveOverlap()
    Copy()
    Select(0u308a); PasteInto() # り
    OverlapIntersect()
    # 合成
    Select(65552);  Copy()
    Select(0u308a); PasteInto() # り
    Select(65553);  Copy()
    Select(0u308a); PasteInto() # り

    SetWidth(1000)
    RemoveOverlap()
    Simplify()
    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph
    Select(65554); Clear() # Temporary glyph

# ろ (左下を少しカット)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(150, -160)
    Rotate(-5)
    PasteWithOffset(-100, 140)
    PasteWithOffset(190, 140)
    RemoveOverlap()
    Copy()

    Select(0u308d) # ろ
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-3, 0)
    else
        PasteWithOffset(-17, 0)
    endif
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph

# ゎ (尻尾を少し短くする)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(395, -350)
        Rotate(-10, 535, 120)
    else
        Move(390, -350)
        Rotate(-5, 530, 120)
    endif
    PasteWithOffset(90, 200)
    PasteWithOffset(-380, -70)
    RemoveOverlap()
    Copy()

    Select(0u308e);  PasteInto() # ゎ
    SetWidth(1000)
    OverlapIntersect()
    Select(65552); Clear() # Temporary glyph

# わ (尻尾を少し短くする)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(400, -350)
        Rotate(-10, 540, 120)
    else
        Move(395, -350)
        Rotate(-5, 535, 120)
    endif
    PasteWithOffset(90, 200)
    PasteWithOffset(-380, -70)
    RemoveOverlap()
    Copy()

    Select(0u308f);  PasteInto() # わ
    SetWidth(1000)
    OverlapIntersect()
    Select(65552); Clear() # Temporary glyph

# を (右下を少しカット)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(-70, -160)
    else
        Move(-60, -160)
    endif
    Rotate(4)
    PasteWithOffset(-100, 140)
    PasteWithOffset(190, 140)
    RemoveOverlap()
    Copy()

    Select(0u3092) # を
    PasteWithOffset(0, 0)
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph

# ク グ ク゚ (はらいの部分を少し短くする)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-160, 350)
    Rotate(-46)
    PasteWithOffset(260, 280)
    PasteWithOffset(210, 0)
    PasteWithOffset(50, -500)
    Rotate(8)
    RemoveOverlap()
    Copy()

    Select(0u30af) # ク
    PasteInto()
    SetWidth(1000)
    OverlapIntersect()

    Select(0u30b0) # グ
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-21, -9)
    else
        PasteWithOffset(-46, -9)
    endif
    SetWidth(1000)
    OverlapIntersect()

    Select(1114122) # ク゚
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-30, -9)
    else
        PasteWithOffset(-37, -9)
    endif
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph

# ㇰ (はらいの部分を少し短くする)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-160, 325)
    Rotate(-46)
    PasteWithOffset(260, 280)
    PasteWithOffset(210, 0)
    PasteWithOffset(100, -500)
    Rotate(8)
    RemoveOverlap()
    Copy()

    Select(0u31f0) # ㇰ
    PasteInto()
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph

# ス (左上を少し延ばす)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-500, 300)
    Select(0u30b9); Copy() # ス
    Select(65552);  PasteInto()
    OverlapIntersect()
    Copy()
    Select(0u30b9) # ス
    PasteWithOffset(-20, 0)

    SetWidth(1000)
    RemoveOverlap()
    Simplify()
    Select(65552); Clear() # Temporary glyph

# ズ (左上を少し延ばす)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-500, 300)
    Select(0u30ba); Copy() # ズ
    Select(65552);  PasteInto()
    OverlapIntersect()
    Copy()
    Select(0u30ba) # ズ
    PasteWithOffset(-20, 0)

    SetWidth(1000)
    RemoveOverlap()
    Simplify()
    Select(65552); Clear() # Temporary glyph

# ㇲ (左上を少し延ばす)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-500, 300)
    Select(0u31f2); Copy() # ㇲ
    Select(65552);  PasteInto()
    OverlapIntersect()
    Copy()
    Select(0u31f2) # ㇲ
    PasteWithOffset(-16, 0)

    SetWidth(1000)
    RemoveOverlap()
    Simplify()
    Select(65552); Clear() # Temporary glyph

# セ ゼ セ゚ (右下を少しカット)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-20, -100)
    Rotate(5)
    PasteWithOffset(-100, 140)
    PasteWithOffset(-100, -100)
    PasteWithOffset(190, 140)
    RemoveOverlap()
    Copy()

    Select(0u30bb) # セ
    PasteInto()
    SetWidth(1000)
    OverlapIntersect()

    Select(0u30bc) # ゼ
    PasteWithOffset(-9, -9)
    SetWidth(1000)
    OverlapIntersect()

    Select(1114125) # セ゚
    PasteWithOffset(-9, -9)
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph

# タ ダ (はらいの部分を少し短くする)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-160, 350)
    Rotate(-46)
    PasteWithOffset(260, 280)
    PasteWithOffset(210, 0)
    PasteWithOffset(50, -500)
    Rotate(8)
    RemoveOverlap()
    Copy()

    Select(0u30bf) # タ
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(5, -9)
    else
        PasteWithOffset(2, -9)
    endif
    SetWidth(1000)
    OverlapIntersect()

    Select(0u30c0) # ダ
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-18, -18)
    else
        PasteWithOffset(-52, -18)
    endif
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph

# テ (Tの横棒を少し上に移動)
    # Tの横棒
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(130, 20)
    if (input_list[i] == "${input_kana_regular}")
        Move(0, 86)
    else
        Move(0, 55)
    endif
    Select(0u30c6); Copy() # テ
    Select(65552);  PasteInto()
    OverlapIntersect()

    # その他
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(-200, 500)
    PasteWithOffset( 200, 500)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-200, -313)
        PasteWithOffset( 329, -200)
    else
        PasteWithOffset(-200, -344)
        PasteWithOffset( 298, -200)
    endif
    RemoveOverlap()
    Copy()
    Select(0u30c6); PasteInto() # テ
    OverlapIntersect()

    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(-200, 500)
    PasteWithOffset( 200, 500)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-262, -200)
    else
        PasteWithOffset(-238, -200)
    endif
    RemoveOverlap()
    Copy()
    Select(0u30c6); PasteInto() # テ
    OverlapIntersect()
    # 合成
    Select(65552); Copy()
    Select(0u30c6) # テ
    PasteWithOffset(0, 20)

    SetWidth(1000)
    RemoveOverlap()
    Simplify()
    RoundToInt()
    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ﾃ (Tの横棒を少し上に移動)
    # Tの横棒
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(130, 20)
    if (input_list[i] == "${input_kana_regular}")
        Move(-210, 86)
    else
        Move(-210, 55)
    endif
    Select(0uff83); Copy() # ﾃ
    Select(65552);  PasteInto()
    OverlapIntersect()

    # その他
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(-250, 500)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-410, -313)
        PasteWithOffset(  88, -200)
    else
        PasteWithOffset(-410, -344)
        PasteWithOffset(  65, -200)
    endif
    RemoveOverlap()
    Copy()
    Select(0uff83); PasteInto() # ﾃ
    OverlapIntersect()

    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(-250, 500)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-512, -200)
    else
        PasteWithOffset(-494, -200)
    endif
    RemoveOverlap()
    Copy()
    Select(0uff83); PasteInto() # ﾃ
    OverlapIntersect()
    # 合成
    Select(65552); Copy()
    Select(0uff83) # ﾃ
    PasteWithOffset(0, 20)

    SetWidth(500)
    RemoveOverlap()
    Simplify()
    RoundToInt()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# デ (Tの横棒を少し上に移動)
    # Tの横棒
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(130, 20)
    if (input_list[i] == "${input_kana_regular}")
        Move(0, 77)
    else
        Move(0, 46)
    endif
    Select(0u30c7); Copy() # デ
    Select(65552);  PasteInto()
    OverlapIntersect()

    # その他
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(-200, 500)
    PasteWithOffset( 200, 500)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-200, -322)
        PasteWithOffset( 320, -200)
    else
        PasteWithOffset(-200, -353)
        PasteWithOffset( 298, -200)
    endif
    RemoveOverlap()
    Copy()
    Select(0u30c7); PasteInto() # デ
    OverlapIntersect()

    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(-200, 500)
    PasteWithOffset( 200, 500)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-271, -200)
    else
        PasteWithOffset(-238, -200)
    endif
    RemoveOverlap()
    Copy()
    Select(0u30c7); PasteInto() # デ
    OverlapIntersect()
    # 合成
    Select(65552); Copy()
    Select(0u30c7) # デ
    PasteWithOffset(0, 20)

    SetWidth(1000)
    RemoveOverlap()
    Simplify()
    RoundToInt()
    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ハ (左のはらいを少し下に移動)
    # 左
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-350, 0)
    Scale(100, 150)
    Select(0u30cf); Copy() # ハ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    # 右
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(100, 150)
    Copy()
    Select(0u30cf); PasteWithOffset(350, 0) # ハ
    OverlapIntersect()
    # 合成
    Select(65552);  Copy() # Temporary glyph
    Select(0u30cf); PasteWithOffset(0, -12) # ハ
    SetWidth(1000)

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ㇵ (左のはらいを少し下に移動)
    # 左
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-350, 0)
    Scale(100, 150)
    Select(0u31f5); Copy() # ㇵ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    # 右
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(100, 150)
    Copy()
    Select(0u31f5); PasteWithOffset(350, 0) # ㇵ
    OverlapIntersect()
    # 合成
    Select(65552);  Copy() # Temporary glyph
    Select(0u31f5); PasteWithOffset(0, -8) # ㇵ
    SetWidth(1000)

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ﾊ (左のはらいを少し下に移動)
    # 左
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-560, 0)
    Scale(100, 150)
    Select(0uff8a); Copy() # ﾊ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    # 右
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(100, 150)
    Copy()
    Select(0uff8a); PasteWithOffset(110, 0) # ﾊ
    OverlapIntersect()
    # 合成
    Select(65552);  Copy() # Temporary glyph
    Select(0uff8a); PasteWithOffset(0, -12) # ﾊ
    SetWidth(500)

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ホ ボ ポ (はねを少しカット)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(190,-100)
        Rotate(-4)
    else
        Move(180,-100)
        Rotate(-4)
    endif
    PasteWithOffset(-100, 200)
    PasteWithOffset(-540, 30)
    PasteWithOffset(190, 200)
    RemoveOverlap()
    Copy()

    Select(0u30db) # ホ
    PasteInto()
    SetWidth(1000)
    OverlapIntersect()

    Select(0u30dc) # ボ
    PasteWithOffset(-9, -9)
    SetWidth(1000)
    OverlapIntersect()

    Select(0u30dd) # ポ
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-9, -3)
    else
        PasteWithOffset(-9, -9)
    endif
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph

# ㇹ (はねを少しカット)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(220,-100)
        Rotate(-4)
    else
        Move(210,-100)
        Rotate(-4)
    endif
    PasteWithOffset(-100, 100)
    PasteWithOffset(-510, 0)
    PasteWithOffset(190, 100)
    RemoveOverlap()
    Copy()

    Select(0u31f9) # ㇹ
    PasteInto()
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph

# ラ (フの横棒を少し上に移動)
    # フの横棒
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(130, 20)
    if (input_list[i] == "${input_kana_regular}")
        Move(0, 100)
    else
        Move(0, 64)
    endif
    Select(0u30e9); Copy() # ラ
    Select(65552);  PasteInto()
    OverlapIntersect()

    # その他
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(-200, 500)
    PasteWithOffset( 200, 500)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-50, -299)
        PasteWithOffset( 606, -200)
    else
        PasteWithOffset(-100, -334)
        PasteWithOffset( 552, -200)
    endif
    RemoveOverlap()
    Copy()
    Select(0u30e9); PasteInto() # ラ
    OverlapIntersect()

    # 合成
    Select(65552); Copy()
    Select(0u30e9) # ラ
    PasteWithOffset(0, 20)

    RemoveOverlap()

    # 加工で発生したゴミを除去
    if (input_list[i] == "${input_kana_regular}")
        Select(0u25a0); Copy() # Black square
        Select(65552);  Paste() # Temporary glyph
        Move(134, -160)
        Rotate(9)
        PasteWithOffset(-100, 140)
        PasteWithOffset(190, 140)
        RemoveOverlap()
        Copy()

        Select(0u30e9) # ラ
        PasteWithOffset(-40, -10)
        OverlapIntersect()
    endif

    SetWidth(1000)
    Simplify()
    RoundToInt()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ﾗ (フの横棒を少し上に移動)
    # フの横棒
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(130, 20)
    if (input_list[i] == "${input_kana_regular}")
        Move(-210, 100)
    else
        Move(-210, 64)
    endif
    Select(0uff97); Copy() # ﾗ
    Select(65552);  PasteInto()
    OverlapIntersect()

    # その他
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(-250, 500)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-260, -299)
        PasteWithOffset( 214, -200)
    else
        PasteWithOffset(-310, -334)
        PasteWithOffset( 168, -200)
    endif
    RemoveOverlap()
    Copy()
    Select(0uff97); PasteInto() # ﾗ
    OverlapIntersect()

    # 合成
    Select(65552); Copy()
    Select(0uff97) # ﾗ
    PasteWithOffset(0, 20)

    SetWidth(500)
    RemoveOverlap()
    Simplify()
    RoundToInt()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ル (左右の隙間を少し拡げて上を少し延ばす)
    # 左
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(100, 120)
    Move(-400, 0)
    Select(0u30eb); Copy() # ル
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    # 右
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(100, 120)
    Move(300, 0)
    Select(0u30eb); Copy() # ル
    Select(65553);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    # 合成
    Select(0u30eb); Paste() # ル
    Move(10, 0)
    Select(65552);  Copy() # Temporary glyph
    Select(0u30eb); PasteWithOffset(-10, 0) # ル

    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(0, 600)
    Select(0u30eb); Copy() # ル
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u30eb); PasteWithOffset(0, 10) # ル
    SetWidth(1000)
    RemoveOverlap()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ㇽ (左右の隙間を少し拡げて上を少し延ばす)
    # 左
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(100, 120)
    Move(-400, 0)
    Select(0u31fd); Copy() # ㇽ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    # 右
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(100, 120)
    Move(300, 0)
    Select(0u31fd); Copy() # ㇽ
    Select(65553);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    # 合成
    Select(0u31fd); Paste() # ㇽ
    Move(7, 0)
    Select(65552);  Copy() # Temporary glyph
    Select(0u31fd); PasteWithOffset(-7, 0) # ㇽ

    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(0, 500)
    Select(0u31fd); Copy() # ㇽ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u31fd); PasteWithOffset(0, 7) # ㇽ
    SetWidth(1000)
    RemoveOverlap()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ﾙ (上を少し延ばす)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-250, 600)
    Select(0uff99); Copy() # ﾙ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0uff99); PasteWithOffset(0, 7) # ﾙ
    SetWidth(1000)
    RemoveOverlap()
    Select(65552); Clear() # Temporary glyph

# レ (上を少し延ばす)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(0, 600)
    Select(0u30ec); Copy() # レ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u30ec); PasteWithOffset(0, 10) # レ
    SetWidth(1000)
    RemoveOverlap()
    Select(65552); Clear() # Temporary glyph

# ㇾ (上を少し延ばす)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(0, 500)
    Select(0u31fe); Copy() # ㇾ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u31fe); PasteWithOffset(0, 7) # ㇾ
    SetWidth(1000)
    RemoveOverlap()
    Select(65552); Clear() # Temporary glyph

# ﾚ (上を少し延ばす)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-250, 600)
    Select(0uff9a); Copy() # ﾚ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0uff9a); PasteWithOffset(0, 10) # ﾚ
    SetWidth(1000)
    RemoveOverlap()
    Select(65552); Clear() # Temporary glyph

# 仮名の濁点を拡大移動、半濁点を移動
    Print("Edit kana voiced sound mark")
# ゔ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(-182, 50)
    else
        Move(-205, 50)
        PasteWithOffset(-193, 16)
    endif
    PasteWithOffset(70, -135)
    RemoveOverlap()
    Copy()
    Select(0u3094); PasteInto() # ゔ
    OverlapIntersect()

# がか゚
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-215, 110)
    PasteWithOffset(-176, -100)
    PasteWithOffset(120, -163)
    RemoveOverlap()
    Copy()
    Select(0u304c); PasteInto() # が
    OverlapIntersect()

    Copy()
    Select(1114115); Paste() # か゚

# ぎき゚
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(-95, -35)
    else
        Move(-57, -43)
        Rotate(3)
    endif
    PasteWithOffset(-238, 100)
    PasteWithOffset(40, -130)
    RemoveOverlap()
    Copy()
    Select(0u304e); PasteInto() # ぎ
    OverlapIntersect()

    Copy()
    Select(1114116); Paste() # き゚
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-105, 120)
    PasteWithOffset(-115, -115)
    PasteWithOffset(50, -110)
    RemoveOverlap()
    Copy()
    Select(1114116); PasteInto() # き゚
    SetWidth(1000)
    OverlapIntersect()
    Select(65552);  Clear() # Temporary glyph

# ぐく゚
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Rotate(45); Copy()
    Move(-230, 320)
    PasteWithOffset(-190, -300)
    RemoveOverlap()
    Copy()
    Select(0u3050); PasteInto() # ぐ
    OverlapIntersect()

    Copy()
    Select(1114117); Paste() # く゚

# げけ゚
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-300, 50)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-107, 9)
    else
        PasteWithOffset(-107, 4)
    endif
 #    PasteWithOffset(-107, 39)
    PasteWithOffset(-113, -70)
    PasteWithOffset(70, -140)
    RemoveOverlap()
    Copy()
    Select(0u3052); PasteInto() # げ
    OverlapIntersect()

    Copy()
    Select(1114118); Paste() # け゚
    Move(12, 6)
    SetWidth(1000)

# ごこ゚
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-50, 455)
    Rotate(25)
    PasteWithOffset(-250, -70)
    PasteWithOffset(50, -420)
    RemoveOverlap()
    Copy()
    Select(0u3054); PasteInto() # ご
    OverlapIntersect()

    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-110, 455)
    PasteWithOffset(-250, -70)
    PasteWithOffset(50, -420)
    RemoveOverlap()
    Copy()
    Select(0u3054); PasteInto() # ご
    OverlapIntersect()

    Copy()
    Select(1114119); Paste() # こ゚

# ざ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(27, -70)
    else
        Move(15, -72)
 #        Move(35, -72)
        Rotate(2)
    endif
    PasteWithOffset(-204, 70)
    PasteWithOffset(25, -170)
    RemoveOverlap()
    Copy()
    Select(0u3056); PasteInto() # ざ
    OverlapIntersect()

# じ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-400, 100)
    PasteWithOffset(30, -300)
    RemoveOverlap()
    Copy()
    Select(0u3058); PasteInto() # じ
    OverlapIntersect()

# ず
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-60, 530)
 #    Move(100, 530)
    PasteWithOffset(-210, 0)
    PasteWithOffset(-190, -300)
    RemoveOverlap()
    Copy()
    Select(0u305a); PasteInto() # ず
    OverlapIntersect()

# ぜ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-300, 60)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-111, 25)
    else
        PasteWithOffset(-111, 15)
    endif
 #    PasteWithOffset(-111, 55)
    PasteWithOffset(60, -90)
    RemoveOverlap()
    Copy()
    Select(0u305c); PasteInto() # ぜ
    OverlapIntersect()

# ぞ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-254, 352)
    Rotate(33)
    PasteWithOffset(-128, 586)
    PasteWithOffset(-200, -90)
    PasteWithOffset(50, -220)
    RemoveOverlap()
    Copy()
    Select(0u305e); PasteInto() # ぞ
    OverlapIntersect()

    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-151, 70)
    Rotate(2)
    PasteWithOffset(-200, -90)
    PasteWithOffset(50, -220)
    RemoveOverlap()
    Copy()
    Select(0u305e); PasteInto() # ぞ
    OverlapIntersect()

# だ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-250, 80)
    PasteWithOffset(-120, -42)
    PasteWithOffset(-120, -90)
    PasteWithOffset(60, -90)
    RemoveOverlap()
    Copy()
    Select(0u3060); PasteInto() # だ
    OverlapIntersect()

# ぢ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-250, 80)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-40, -70)
 #        PasteWithOffset(20, -70)
    else
        PasteWithOffset(-34, -63)
 #        PasteWithOffset(26, -63)
    endif
    PasteWithOffset(60, -200)
    RemoveOverlap()
    Copy()
    Select(0u3062); PasteInto() # ぢ
    OverlapIntersect()

# づ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(0, -6)
    Rotate(-24)
    PasteWithOffset(-200, 0)
    PasteWithOffset(60, -90)
    RemoveOverlap()
    Copy()
    Select(0u3065); PasteInto() # づ
    OverlapIntersect()

# で
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(60, 501)
    PasteWithOffset(-213, 0)
    PasteWithOffset(0, -440)
    RemoveOverlap()
    Copy()
    Select(0u3067); PasteInto() # で
    OverlapIntersect()

# ど
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-260, 80)
    PasteWithOffset(-120, -130)
    PasteWithOffset(60, -130)
    RemoveOverlap()
    Copy()
    Select(0u3069); PasteInto() # ど
    OverlapIntersect()

# ば ぱ
    # ば
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-300, 50)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-104, 13)
    else
        PasteWithOffset(-104, 8)
    endif
 #    PasteWithOffset(-104, 43)
    PasteWithOffset(-113, -70)
    PasteWithOffset(70, -106)
    RemoveOverlap()
    Copy()
    Select(0u3070); PasteInto() # ば
    OverlapIntersect()

    # ぱ
    # 左、右下
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-500, 60)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-140, -175)
    else
        PasteWithOffset(-98, -209)
    endif
    PasteWithOffset(90, -320)
    RemoveOverlap()
    Copy()
    Select(0u3071); PasteInto() # ぱ
    OverlapIntersect()
    # 右上
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(120, 485)
    else
        Move(120, 440)
    endif
    Select(0u3070); Copy() # ば
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()

    if (input_list[i] == "${input_kana_regular}")
        Scale(99, 100); Copy()
        Select(0u3071) # ぱ
        PasteWithOffset(-11, 4)
    else
        Copy()
        Select(0u3071) # ぱ
        PasteWithOffset(6, 15)
    endif
    RemoveOverlap()
    # 合成
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-127, 90)
    PasteWithOffset(-100, -123)
    PasteWithOffset(80, -151)
    RemoveOverlap()
    Copy()
    Select(0u3071); PasteInto() # ぱ
    SetWidth(1000)
    OverlapIntersect()
    Simplify()

# び ぴ
    # び
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(-130, -40)
        PasteWithOffset(110, -105)
    else
        Move(113, -195)
        Rotate(40)
        PasteWithOffset(510, -103)
        PasteWithOffset(0, -136)
    endif
    PasteWithOffset(-300, 40)
    RemoveOverlap()
    Copy()
    Select(0u3073); PasteInto() # び
    OverlapIntersect()

    # ぴ
    Copy()
    Select(0u3074); Clear() # ぴ
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-5, 0)
    else
        PasteWithOffset(-6, 0)
    endif
    SetWidth(1000)

# ぶ
 #    # 既に加工した ぶ を切り取って使う場合
 #    Select(0u25a0); Copy() # Black square
 #    Select(65552);  Paste() # Temporary glyph
 #    if (input_list[i] == "${input_kana_regular}")
 #        Move(-145, 50)
 #    else
 #        Move(-220, 34)
 #        Rotate(-5)
 #    endif
 #    PasteWithOffset(-120, -160)
 #    PasteWithOffset(100, -160)
 #    RemoveOverlap()
 #    Copy()
 #    Select(0u3076); PasteInto() # ぶ
 #    OverlapIntersect()

# ぼ ぽ
    # ぼ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-250, 50)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-103, 20)
    else
        PasteWithOffset(-113, 7)
    endif
    PasteWithOffset(-120, -70)
    PasteWithOffset(70, -140)
    RemoveOverlap()
    Copy()
    Select(0u307c); PasteInto() # ぼ
    OverlapIntersect()
    Simplify()

    # ぽ
    # 左、右下
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-500, 60)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-120, -267)
    else
        PasteWithOffset(-119, -301)
    endif
    PasteWithOffset(90, -320)
    RemoveOverlap()
    Copy()
    Select(0u307d); PasteInto() # ぽ
    OverlapIntersect()
    # 右上
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(120, 397)
    else
        Move(120, 363)
    endif
    Select(0u307c); Copy() # ぼ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()

    if (input_list[i] == "${input_kana_regular}")
        Scale(99, 100); Copy()
        Select(0u307d) # ぽ
        PasteWithOffset(-6, 0)
    else
        Copy()
        Select(0u307d) # ぽ
        PasteWithOffset(-6, 0)
    endif
    RemoveOverlap()
    # 合成
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-127, 90)
    PasteWithOffset(-100, -123)
    PasteWithOffset(80, -151)
    RemoveOverlap()
    Copy()
    Select(0u307d); PasteInto() # ぽ
    SetWidth(1000)
    OverlapIntersect()
    Simplify()

# ヴ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-250, 80)
    PasteWithOffset(60, -85)
    RemoveOverlap()
    Copy()
    Select(0u30f4); PasteInto() # ヴ
    OverlapIntersect()

# ガカ゚
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-250, 80)
    PasteWithOffset(-180, -60)
    PasteWithOffset(60, -90)
    RemoveOverlap()
    Copy()
    Select(0u30ac); PasteInto() # ガ
    OverlapIntersect()

    Copy()
    Select(1114120); Paste() # カ゚
    Move(-10, 0)
    SetWidth(1000)

# ギキ゚
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-250, 80)
    PasteWithOffset(60, -90)
    RemoveOverlap()
    Copy()
    Select(0u30ae); PasteInto() # ギ
    OverlapIntersect()

    Copy()
    Select(1114121); Paste() # キ゚

# グク゚
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-250, 80)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-44, -63)
    else
        PasteWithOffset(-50, -54)
    endif
    RemoveOverlap()
    Copy()
    Select(0u30b0); PasteInto() # グ
    OverlapIntersect()

    Copy()
    Select(1114122); Paste() # ク゚
    if (input_list[i] == "${input_kana_regular}")
        Move(-9, 0)
    else
        Move(9, 0)
    endif
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-105, 120)
    PasteWithOffset(-115, -115)
    PasteWithOffset(50, -110)
    RemoveOverlap()
    Copy()
    Select(1114122); PasteInto() # ク゚
    SetWidth(1000)
    OverlapIntersect()
    Select(65552);  Clear() # Temporary glyph

# ゲケ゚
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-250, 80)
    PasteWithOffset(60, -85)
    RemoveOverlap()
    Copy()
    Select(0u30b2); PasteInto() # ゲ
    OverlapIntersect()

    Copy()
    Select(1114123); Paste() # ケ゚
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-85, 120)
    PasteWithOffset(-115, -115)
    PasteWithOffset(50, -120)
    RemoveOverlap()
    Copy()
    Select(1114123); PasteInto() # ケ゚
    SetWidth(1000)
    OverlapIntersect()
    Select(65552);  Clear() # Temporary glyph

# ゴコ゚
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(-59, -52)
    else
        Move(-59, -39)
    endif
    RemoveOverlap()
    Copy()
    Select(0u30b4); PasteInto() # ゴ
    OverlapIntersect()

    Copy()
    Select(1114124); Paste() # コ゚
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-105, 120)
    PasteWithOffset(-115, -115)
    PasteWithOffset(50, -100)
    RemoveOverlap()
    Copy()
    Select(1114124); PasteInto() # コ゚
    SetWidth(1000)
    OverlapIntersect()
    Select(65552);  Clear() # Temporary glyph

# ザ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-300, 60)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-106, 9)
    else
        PasteWithOffset(-106, 9)
    endif
 #    PasteWithOffset(-106, 39)
    PasteWithOffset(80, -100)
    RemoveOverlap()
    Copy()
    Select(0u30b6); PasteInto() # ザ
    OverlapIntersect()

# ジ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-250, 40)
    PasteWithOffset(-120, -95)
    PasteWithOffset(70, -95)
    RemoveOverlap()
    Copy()
    Select(0u30b8); PasteInto() # ジ
    OverlapIntersect()

# ズ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(-68, -21)
    else
        Move(-65, -6)
    endif
    PasteWithOffset(-120, -95)
    PasteWithOffset(70, -95)
    RemoveOverlap()
    Copy()
    Select(0u30ba); PasteInto() # ズ
    OverlapIntersect()

# ゼセ゚
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-200, 50)
    PasteWithOffset(80, -80)
    RemoveOverlap()
    Copy()
    Select(0u30bc); PasteInto() # ゼ
    OverlapIntersect()

    Copy()
    Select(1114125); Paste() # セ゚
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-80, 120)
    PasteWithOffset(-115, -115)
    PasteWithOffset(50, -120)
    RemoveOverlap()
    Copy()
    Select(1114125); PasteInto() # セ゚
    SetWidth(1000)
    OverlapIntersect()
    Select(65552);  Clear() # Temporary glyph

# ゾ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-200, 50)
    PasteWithOffset(60, -90)
    RemoveOverlap()
    Copy()
    Select(0u30be); PasteInto() # ゾ
    OverlapIntersect()

# ダ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-250, 60)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-41, -48)
    else
        PasteWithOffset(-56, -39)
    endif
    PasteWithOffset(-30, -90)
    RemoveOverlap()
    Copy()
    Select(0u30c0); PasteInto() # ダ
    OverlapIntersect()

# ヂ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-37, -70)
    Rotate(15)
    PasteWithOffset(-160, -2)
    PasteWithOffset(70, -90)
    RemoveOverlap()
    Copy()
    Select(0u30c2); PasteInto() # ヂ
    OverlapIntersect()

    if (input_list[i] == "${input_kana_regular}")
        Select(0u25a0); Copy() # Black square
        Select(65552);  Paste() # Temporary glyph
        Move(-70, -70)
        Rotate(15)
        PasteWithOffset(-200, -2)
        PasteWithOffset(70, -190)
        RemoveOverlap()
        Copy()
        Select(0u30c2); PasteInto() # ヂ
        OverlapIntersect()
    endif

# ヅツ゚
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-200, 50)
    PasteWithOffset(60, -90)
    RemoveOverlap()
    Copy()
    Select(0u30c5); PasteInto() # ヅ
    OverlapIntersect()

    Copy()
    Select(1114126); Paste() # ツ゚

# デ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(-110, 3)
    else
        Move(-120, 3)
 #        Move(-95, 3)
    endif
    PasteWithOffset(70, -140)
    RemoveOverlap()
    Copy()
    Select(0u30c7); PasteInto() # デ
    OverlapIntersect()

# ドト゚
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-400, 100)
    PasteWithOffset(50, -220)
    RemoveOverlap()
    Copy()
    Select(0u30c9); PasteInto() # ド
    OverlapIntersect()

    Copy()
    Select(1114127); Paste() # ト゚

# バ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(60, -210)
 #        Move(60, -190)
        Rotate(20)
    else
        Move(60, -220)
 #        Move(60, -190)
        Rotate(19)
    endif
    PasteWithOffset(-350, 0)
    PasteWithOffset(-120, -250)
    RemoveOverlap()

    Select(0u30cf); Copy() # ハ
    Select(65552);  PasteWithOffset(-9, -9) # Temporary glyph
    OverlapIntersect()
    Copy()

    Select(0u30d0); Paste() # バ
    SetWidth(1000)

 #    # ハ を使わず バ を切り取って使う場合
 #    Select(0u25a0); Copy() # Black square
 #    Select(65552);  Paste() # Temporary glyph
 #    Move(-350, 0)
 #    PasteWithOffset(-120, -160)
 #    PasteWithOffset(70, -160)
 #    RemoveOverlap()
 #    Copy()
 #    Select(0u30d0); PasteInto() # バ

 #    OverlapIntersect()

# パ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(110, -130)
    else
        Move(120, -140)
    endif
    Rotate(-20)
    PasteWithOffset(-350, 0)
    PasteWithOffset(-120, -250)
    RemoveOverlap()

    Select(0u30cf); Copy() # ハ
    Select(65552);  PasteWithOffset(-9, -9) # Temporary glyph
    OverlapIntersect()
    Copy()

    Select(0u30d1); Paste() # パ
    SetWidth(1000)

 #    # ハ を使わず パ を切り取って使う場合
 #    Select(0u25a0); Copy() # Black square
 #    Select(65552);  Paste() # Temporary glyph
 #    if (input_list[i] == "${input_kana_regular}")
 #        Move(30, -301)
 #        Rotate(20)
 #    else
 #        Move(51, -297)
 #        Rotate(19)
 #    endif
 #    PasteWithOffset(-350, 0)
 #    PasteWithOffset(-116, -250)
 #    RemoveOverlap()
 #    Copy()
 #    Select(0u30d1); PasteInto() # パ

 #    OverlapIntersect()

# ビ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-250, 30)
    PasteWithOffset(-120, -111)
    PasteWithOffset(50, -111)
    RemoveOverlap()
    Copy()
    Select(0u30d3); PasteInto() # ビ
    OverlapIntersect()

# ブ プ
    # ブ
    if (input_list[i] == "${input_kana_bold}")
        Select(0u25a0); Copy() # Black square
        Select(0u30d6); PasteWithOffset(550, 606) # ブ
        RemoveOverlap()
    endif
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-200, 0)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-16, -33)
    else
        PasteWithOffset(-17, -21)
    endif
    PasteWithOffset(20, -90)
    RemoveOverlap()
    Copy()
    Select(0u30d6); PasteInto() # ブ
    OverlapIntersect()
    Simplify()

    # プ
    Copy()
    Select(0u30d7); Clear() # プ
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-3, 0)
    else
        PasteWithOffset(3, 0)
    endif
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-127, 0)
    PasteWithOffset(20, -151)
    RemoveOverlap()
    Copy()
    Select(0u30d7); PasteInto() # プ
    SetWidth(1000)
    OverlapIntersect()

# ベ ペ
    # ベ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Rotate(45)
    Move(-300, 80)
    PasteWithOffset(120, -200)
    RemoveOverlap()
    Copy()
    Select(0u30d9); PasteInto() # ベ
    OverlapIntersect()

    # ペ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Rotate(45)
    Move(-255, 15)
    PasteWithOffset(120, -290)
    RemoveOverlap()
    Copy()
    Select(0u30da); PasteInto() # ペ
    OverlapIntersect()

# ボ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-200, 70)
    PasteWithOffset(-120, -85)
    PasteWithOffset(80, -85)
    RemoveOverlap()
    Copy()
    Select(0u30dc); PasteInto() # ボ
    OverlapIntersect()

# ポ
    # ゜の周り以外
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-255, 70)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-171, -86)
    else
        PasteWithOffset(-192, -82)
    endif
    PasteWithOffset(80, -252)
    RemoveOverlap()
    Copy()
    Select(0u30dd); PasteInto() # ポ
    OverlapIntersect()

    # ゜の傍
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Rotate(43)
    Move(-685, 145)
    Select(0u30dd); Copy() # ポ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()

    Select(0u30dd) # ポ
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(535, 0)
    else
        PasteWithOffset(520, 0)
    endif
    RemoveOverlap()
    Simplify()

# ヷ
    if (input_list[i] == "${input_kana_bold}")
        Select(0u25a0); Copy() # Black square
        Select(0u30f7); PasteWithOffset(550, 605) # ヷ
        RemoveOverlap()
    endif
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-200, 0)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-16, -24)
    else
        PasteWithOffset(-16, -12)
    endif
    PasteWithOffset(20, -90)
    RemoveOverlap()
    Copy()
    Select(0u30f7); PasteInto() # ヷ
    OverlapIntersect()
    Simplify()

    # 加工で発生したゴミを除去
    if (input_list[i] == "${input_kana_bold}")
        Select(0u25a0); Copy() # Black square
        Select(65552);  Paste() # Temporary glyph
        Move(134, -160)
        Rotate(10)
        PasteWithOffset(-100, 140)
        PasteWithOffset(190, 140)
        RemoveOverlap()
        Copy()

        Select(0u30f7) # ヷ
        PasteWithOffset(-52, -10)
        OverlapIntersect()
    endif

# ヸ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-300, 30)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-115, -1)
    else
        PasteWithOffset(-115, 19)
    endif
 #    PasteWithOffset(-115, 29)
    PasteWithOffset(-115, -80)
    PasteWithOffset(80, -80)
    RemoveOverlap()
    Copy()
    Select(0u30f8); PasteInto() # ヸ
    OverlapIntersect()

# ヹ
    if (input_list[i] == "${input_kana_bold}")
        Select(0u25a0); Copy() # Black square
        Select(0u30f9); PasteWithOffset(550, 614) # ヹ
        RemoveOverlap()
    endif
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(-18, -30)
    else
        Move(-16, -16)
    endif
    PasteWithOffset(-150, -16)
    PasteWithOffset(80, -85)
    RemoveOverlap()
    Copy()
    Select(0u30f9); PasteInto() # ヹ
    OverlapIntersect()

# ヺ
    if (input_list[i] == "${input_kana_bold}")
        Select(0u25a0); Copy() # Black square
        Select(0u30fa); PasteWithOffset(550, 601) # ヺ
        RemoveOverlap()
    endif
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-200, 0)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-15, -24)
    else
        PasteWithOffset(-14, -12)
    endif
    PasteWithOffset(20, -90)
    RemoveOverlap()
    Copy()
    Select(0u30fa); PasteInto() # ヺ
    OverlapIntersect()
    Simplify()

# 〲
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-150, 540)
    PasteWithOffset(-275, 0)
    PasteWithOffset(-150, -400)
    RemoveOverlap()
    Copy()
    Select(0u3032); PasteInto() # 〲
    OverlapIntersect()

# 〴
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Rotate(58)
    Move(-140, 235)
    PasteWithOffset(-280, -150)
    RemoveOverlap()
    Copy()
    Select(0u3034); PasteInto() # 〴
    OverlapIntersect()

# ゞ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Rotate(50)
    Move(-240, -80)
    PasteWithOffset(0, -280)
    RemoveOverlap()
    Copy()
    Select(0u309e); PasteInto() # ゞ
    OverlapIntersect()

# ヾ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Rotate(45)
    Move(-250, -80)
    PasteWithOffset(0, -280)
    RemoveOverlap()
    Copy()
    Select(0u30fe); PasteInto() # ヾ
    OverlapIntersect()

# ㇷ゚
    Select(0u31f7); Copy()
    Select(1114128); Paste() # ㇷ゚
    Move(-37, 0)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-170, 120)
    PasteWithOffset(-150, -215)
    PasteWithOffset(50, -235)
    RemoveOverlap()
    Copy()
    Select(1114128); PasteInto() # ㇷ゚
    SetWidth(1000)
    OverlapIntersect()
    Select(65552);  Clear() # Temporary glyph

# ゜
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(260, 440); Rotate(45)
    Select(0u307a); Copy()# ぺ
    Select(65553);  PasteInto()
    OverlapIntersect()
    Scale(95); Copy()

    if (input_list[i] == "${input_kana_regular}")
        Select(0u3071); PasteWithOffset(86, 59) # ぱ
 #        Select(0u3071); PasteWithOffset(46, 39) # ぱ
        SetWidth(1000); RemoveOverlap()
        Select(0u3074); PasteWithOffset(46, 59) # ぴ
 #        Select(0u3074); PasteWithOffset(46, 39) # ぴ
        SetWidth(1000); RemoveOverlap()
        Select(0u3077); PasteWithOffset(29, 59) # ぷ
 #        Select(0u3077); PasteWithOffset( 9, 39) # ぷ
        SetWidth(1000); RemoveOverlap()
        Select(0u307d); PasteWithOffset(86, 69) # ぽ
 #        Select(0u307d); PasteWithOffset(46, 39) # ぽ
        SetWidth(1000); RemoveOverlap()
        Select(0u30d1); PasteWithOffset( 13, 40) # パ
 #        Select(0u30d1); PasteWithOffset(-37, 30) # パ
        SetWidth(1000); RemoveOverlap()
        Select(0u30d7); PasteWithOffset(80, 53) # プ
 #        Select(0u30d7); PasteWithOffset(40, 33) # プ
        SetWidth(1000); RemoveOverlap()
        Select(0u30da); PasteWithOffset(0, 0) # ペ
        SetWidth(1000); RemoveOverlap()
        Select(0u30dd); PasteWithOffset(70, 53) # ポ
 #        Select(0u30dd); PasteWithOffset(40, 33) # ポ
        SetWidth(1000); RemoveOverlap()
        Select(1114115); PasteWithOffset(66, 59) # か゚
        SetWidth(1000); RemoveOverlap()
        Select(1114116); PasteWithOffset(96, 79) # き゚
        SetWidth(1000); RemoveOverlap()
        Select(1114117); PasteWithOffset(0, -140) # く゚
        SetWidth(1000); RemoveOverlap()
        Select(1114118); PasteWithOffset(86, 69) # け゚
        SetWidth(1000); RemoveOverlap()
        Select(1114119); PasteWithOffset(86, 79) # こ゚
        SetWidth(1000); RemoveOverlap()
        Select(1114120); PasteWithOffset(86, 86) # カ゚
        SetWidth(1000); RemoveOverlap()
        Select(1114121); PasteWithOffset(76, 83) # キ゚
        SetWidth(1000); RemoveOverlap()
        Select(1114122); PasteWithOffset(86, 83) # ク゚
        SetWidth(1000); RemoveOverlap()
        Select(1114123); PasteWithOffset(81, 84) # ケ゚
        SetWidth(1000); RemoveOverlap()
        Select(1114124); PasteWithOffset(88, 89) # コ゚
        SetWidth(1000); RemoveOverlap()
        Select(1114125); PasteWithOffset(86, 84) # セ゚
        SetWidth(1000); RemoveOverlap()
        Select(1114126); PasteWithOffset(86, 84) # ツ゚
        SetWidth(1000); RemoveOverlap()
        Select(1114127); PasteWithOffset(-50, 0) # ト゚
        SetWidth(1000); RemoveOverlap()
        Select(1114128); PasteWithOffset(30, -40) # ㇷ゚
        SetWidth(1000); RemoveOverlap()
    else
        Select(0u3071); PasteWithOffset(62, 42) # ぱ
 #        Select(0u3071); PasteWithOffset(12, 12) # ぱ
        SetWidth(1000); RemoveOverlap()
        Select(0u3074); PasteWithOffset(17, 32) # ぴ
 #        Select(0u3074); PasteWithOffset(7, 12) # ぴ
        SetWidth(1000); RemoveOverlap()
        Select(0u3077); PasteWithOffset(18, 52) # ぷ
 #        Select(0u3077); PasteWithOffset(-22, 12) # ぷ
        SetWidth(1000); RemoveOverlap()
        Select(0u307d); PasteWithOffset(62, 52) # ぽ
 #        Select(0u307d); PasteWithOffset(12, 12) # ぽ
        SetWidth(1000); RemoveOverlap()
        Select(0u30d1); PasteWithOffset(  2, 27) # パ
 #        Select(0u30d1); PasteWithOffset(-48, 17) # パ
        SetWidth(1000); RemoveOverlap()
        Select(0u30d7); PasteWithOffset(52, 32) # プ
 #        Select(0u30d7); PasteWithOffset(12, 12) # プ
        SetWidth(1000); RemoveOverlap()
        Select(0u30da); PasteWithOffset(0, 0) # ペ
        SetWidth(1000); RemoveOverlap()
        Select(0u30dd); PasteWithOffset(42, 32) # ポ
 #        Select(0u30dd); PasteWithOffset(12, 12) # ポ
        SetWidth(1000); RemoveOverlap()
        Select(1114115); PasteWithOffset(62, 52) # か゚
        SetWidth(1000); RemoveOverlap()
        Select(1114116); PasteWithOffset(82, 72) # き゚
        SetWidth(1000); RemoveOverlap()
        Select(1114117); PasteWithOffset(-5, -175) # く゚
        SetWidth(1000); RemoveOverlap()
        Select(1114118); PasteWithOffset(82, 72) # け゚
        SetWidth(1000); RemoveOverlap()
        Select(1114119); PasteWithOffset(72, 72) # こ゚
        SetWidth(1000); RemoveOverlap()
        Select(1114120); PasteWithOffset(72, 85) # カ゚
        SetWidth(1000); RemoveOverlap()
        Select(1114121); PasteWithOffset(62, 85) # キ゚
        SetWidth(1000); RemoveOverlap()
        Select(1114122); PasteWithOffset(72, 72) # ク゚
        SetWidth(1000); RemoveOverlap()
        Select(1114123); PasteWithOffset(72, 72) # ケ゚
        SetWidth(1000); RemoveOverlap()
        Select(1114124); PasteWithOffset(72, 77) # コ゚
        SetWidth(1000); RemoveOverlap()
        Select(1114125); PasteWithOffset(72, 72) # セ゚
        SetWidth(1000); RemoveOverlap()
        Select(1114126); PasteWithOffset(72, 72) # ツ゚
        SetWidth(1000); RemoveOverlap()
        Select(1114127); PasteWithOffset(-50, 12) # ト゚
        SetWidth(1000); RemoveOverlap()
        Select(1114128); PasteWithOffset(18, -44) # ㇷ゚
        SetWidth(1000); RemoveOverlap()
    endif

# ぺ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Rotate(45)
    Move(-255, 15)
    PasteWithOffset(120, -290)
    RemoveOverlap()
    Copy()
    Select(0u307a); PasteInto() # ぺ
    OverlapIntersect()

    Select(65553); Copy()
    if (input_list[i] == "${input_kana_regular}")
        Select(0u307a); PasteWithOffset(  0,    0) # ぺ
    else
        Select(0u307a); PasteWithOffset(  0,    0) # ぺ
    endif
    SetWidth(1000); RemoveOverlap()

# ゛
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(260, 440); Rotate(45)
    Select(0u3079); Copy()# べ
    Select(65553);  PasteInto()
    OverlapIntersect();
    Scale(104, 104 ,610, 560)

    # 位置、間隔微調整
    # 左下
    Select(0u25a0); Copy() # Black square
    Select(65554);  Paste() # Temporary glyph
    Move(10, 0); Rotate(30)
    Select(65553);  Copy()
    Select(65554);  PasteInto() # Temporary glyph
    OverlapIntersect();

    # 右上
    Select(0u25a0); Copy() # Black square
    Select(65555);  Paste()
    Move(575, 350); Rotate(30)
    Select(65553);  Copy()
    Select(65555);  PasteInto() # Temporary glyph
    OverlapIntersect();
    Copy()

    # 合成
    Select(65553);  Paste()
    Move(5, 5)
    Select(65554);  Copy()
    Select(65553);  PasteWithOffset(-10, 0)

    Select(65554); Clear() # Temporary glyph
    Select(65555); Clear() # Temporary glyph

    Select(65553); Copy()

    if (input_list[i] == "${input_kana_regular}")
        Select(0u3094); PasteWithOffset( 99,   78) # ゔ
 #        Select(0u3094); PasteWithOffset( 89,   78) # ゔ
        SetWidth(1000); RemoveOverlap()

        Select(0u304c); PasteWithOffset( 81,   70) # が
 #        Select(0u304c); PasteWithOffset( 51,   60) # が
        SetWidth(1000); RemoveOverlap()
        Select(0u304e); PasteWithOffset(113,  128) # ぎ
 #        Select(0u304e); PasteWithOffset(103,  128) # ぎ
        SetWidth(1000); RemoveOverlap()
        Select(0u3050); PasteWithOffset( 14,  -93) # ぐ
 #        Select(0u3050); PasteWithOffset( 14, -143) # ぐ
        SetWidth(1000); RemoveOverlap()
        Select(0u3052); PasteWithOffset(151,  121) # げ
 #        Select(0u3052); PasteWithOffset(155,  111) # げ
        SetWidth(1000); RemoveOverlap()
        Select(0u3054); PasteWithOffset(145,  128) # ご
 #        Select(0u3054); PasteWithOffset( 55, -143) # ご
        SetWidth(1000); RemoveOverlap()

        Select(0u3056); PasteWithOffset(125,  128) # ざ
 #        Select(0u3056); PasteWithOffset(105,  131) # ざ
        SetWidth(1000); RemoveOverlap()
        Select(0u3058); PasteWithOffset(-43,   18) # じ
        SetWidth(1000); RemoveOverlap()
        Select(0u305a); PasteWithOffset(145,  128) # ず
 #        Select(0u305a); PasteWithOffset( 90, -186) # ず
        SetWidth(1000); RemoveOverlap()
        Select(0u305c); PasteWithOffset(149,  124) # ぜ
 #        Select(0u305c); PasteWithOffset(149,  114) # ぜ
        SetWidth(1000); RemoveOverlap()
        Select(0u305e); PasteWithOffset(145,   -4) # ぞ
        SetWidth(1000); RemoveOverlap()

        Select(0u3060); PasteWithOffset( 97,   98) # だ
 #        Select(0u3060); PasteWithOffset( 97,   88) # だ
        SetWidth(1000); RemoveOverlap()
        Select(0u3062); PasteWithOffset(108,  126) # ぢ
 #        Select(0u3062); PasteWithOffset(108,  131) # ぢ
        SetWidth(1000); RemoveOverlap()
        Select(0u3065); PasteWithOffset( 96,  122) # づ
        SetWidth(1000); RemoveOverlap()
        Select(0u3067); PasteWithOffset( 80, -180) # で
 #        Select(0u3067); PasteWithOffset( 80, -195) # で
        SetWidth(1000); RemoveOverlap()
        Select(0u3069); PasteWithOffset( 14,   81) # ど
        SetWidth(1000); RemoveOverlap()

        Select(0u3070); PasteWithOffset(149,  122) # ば
 #        Select(0u3070); PasteWithOffset(149,  112) # ば
        SetWidth(1000); RemoveOverlap()
        Select(0u3073); PasteWithOffset(107,   93) # び
 #        Select(0u3073); PasteWithOffset( 87,   93) # び
        SetWidth(1000); RemoveOverlap()
        Select(0u3076); PasteWithOffset(117,   98) # ぶ
        SetWidth(1000); RemoveOverlap()
        Select(0u307c); PasteWithOffset(149,  103) # ぼ
 #        Select(0u307c); PasteWithOffset(149,   93) # ぼ
        SetWidth(1000); RemoveOverlap()

        Select(0u30f4); PasteWithOffset(105,  128) # ヴ
        SetWidth(1000); RemoveOverlap()

        Select(0u30ac); PasteWithOffset( 91,  123) # ガ
 #        Select(0u30ac); PasteWithOffset( 81,  128) # ガ
        SetWidth(1000); RemoveOverlap()
        Select(0u30ae); PasteWithOffset( 81,  123) # ギ
 #        Select(0u30ae); PasteWithOffset( 81,  128) # ギ
        SetWidth(1000); RemoveOverlap()
        Select(0u30b0); PasteWithOffset(115,  110) # グ
 #        Select(0u30b0); PasteWithOffset(105,  110) # グ
        SetWidth(1000); RemoveOverlap()
        Select(0u30b2); PasteWithOffset( 81,  128) # ゲ
        SetWidth(1000); RemoveOverlap()
        Select(0u30b4); PasteWithOffset(114,  121) # ゴ
 #        Select(0u30b4); PasteWithOffset(104,  121) # ゴ
        SetWidth(1000); RemoveOverlap()

        Select(0u30b6); PasteWithOffset(151,  119) # ザ
 #        Select(0u30b6); PasteWithOffset(143,  109) # ザ
        SetWidth(1000); RemoveOverlap()
        Select(0u30b8); PasteWithOffset(114,  119) # ジ
 #        Select(0u30b8); PasteWithOffset( 84,  119) # ジ
        SetWidth(1000); RemoveOverlap()
        Select(0u30ba); PasteWithOffset(103,  128) # ズ
 #        Select(0u30ba); PasteWithOffset( 93,  128) # ズ
        SetWidth(1000); RemoveOverlap()
        Select(0u30bc); PasteWithOffset( 96,  128) # ゼ
        SetWidth(1000); RemoveOverlap()
        Select(0u30be); PasteWithOffset(114,  116) # ゾ
 #        Select(0u30be); PasteWithOffset( 84,  116) # ゾ
        SetWidth(1000); RemoveOverlap()

        Select(0u30c0); PasteWithOffset(112,  121) # ダ
 #        Select(0u30c0); PasteWithOffset(102,  121) # ダ
        SetWidth(1000); RemoveOverlap()
        Select(0u30c2); PasteWithOffset(103,  128) # ヂ
        SetWidth(1000); RemoveOverlap()
        Select(0u30c5); PasteWithOffset(114,  116) # ヅ
 #        Select(0u30c5); PasteWithOffset( 84,  116) # ヅ
        SetWidth(1000); RemoveOverlap()
        Select(0u30c7); PasteWithOffset(118,  101) # デ
        SetWidth(1000); RemoveOverlap()
        Select(0u30c9); PasteWithOffset(-36,    9) # ド
        SetWidth(1000); RemoveOverlap()

        Select(0u30d0); PasteWithOffset( 86,   56) # バ
 #        Select(0u30d0); PasteWithOffset( -4,   56) # バ
        SetWidth(1000); RemoveOverlap()
        Select(0u30d3); PasteWithOffset( 60,   86) # ビ
        SetWidth(1000); RemoveOverlap()
        Select(0u30d6); PasteWithOffset(121,  128) # ブ
 #        Select(0u30d6); PasteWithOffset(101,  128) # ブ
        SetWidth(1000); RemoveOverlap()
        Select(0u30d9); PasteWithOffset( 43,   14) # ベ
 #        Select(0u30d9); PasteWithOffset( 23,   14) # ベ
        SetWidth(1000); RemoveOverlap()
        Select(0u30dc); PasteWithOffset(103,  128) # ボ
        SetWidth(1000); RemoveOverlap()

        Select(0u30f7); PasteWithOffset(121,  128) # ヷ
 #        Select(0u30f7); PasteWithOffset(101,  129) # ヷ
        SetWidth(1000); RemoveOverlap()
        Select(0u30f8); PasteWithOffset(131,  128) # ヸ
 #        Select(0u30f8); PasteWithOffset(111,  129) # ヸ
        SetWidth(1000); RemoveOverlap()
        Select(0u30f9); PasteWithOffset(119,  128) # ヹ
 #        Select(0u30f9); PasteWithOffset( 99,  135) # ヹ
        SetWidth(1000); RemoveOverlap()
        Select(0u30fa); PasteWithOffset(122,  128) # ヺ
 #        Select(0u30fa); PasteWithOffset(102,  128) # ヺ
        SetWidth(1000); RemoveOverlap()

        Select(0u3032); PasteWithOffset(  0, -143) # 〲
        SetWidth(1000); RemoveOverlap()
        Select(0u3034); PasteWithOffset( 34, -343) # 〴
 #        Select(0u3034); PasteWithOffset( 14, -343) # 〴
        SetWidth(1000); RemoveOverlap()
        Select(0u309e); PasteWithOffset(-66,   -2) # ゞ
 #        Select(0u309e); PasteWithOffset(-86,  -22) # ゞ
        SetWidth(1000); RemoveOverlap()
        Select(0u30fe); PasteWithOffset(-86,  -22) # ヾ
        SetWidth(1000); RemoveOverlap()

    else
        Select(0u3094); PasteWithOffset( 87,   63) # ゔ
 #        Select(0u3094); PasteWithOffset( 67,   43) # ゔ
        SetWidth(1000); RemoveOverlap()

        Select(0u304c); PasteWithOffset( 90,   23) # が
 #        Select(0u304c); PasteWithOffset( 50,   13) # が
        SetWidth(1000); RemoveOverlap()
        Select(0u304e); PasteWithOffset( 86,  103) # ぎ
 #        Select(0u304e); PasteWithOffset( 76,   93) # ぎ
        SetWidth(1000); RemoveOverlap()
        Select(0u3050); PasteWithOffset(  9, -149) # ぐ
 #        Select(0u3050); PasteWithOffset(  9, -209) # ぐ
        SetWidth(1000); RemoveOverlap()
        Select(0u3052); PasteWithOffset( 98,   89) # げ
 #        Select(0u3052); PasteWithOffset( 80,   79) # げ
        SetWidth(1000); RemoveOverlap()
        Select(0u3054); PasteWithOffset( 80,  108) # ご
 #        Select(0u3054); PasteWithOffset( 30, -209) # ご
        SetWidth(1000); RemoveOverlap()

        Select(0u3056); PasteWithOffset(105,   88) # ざ
 #        Select(0u3056); PasteWithOffset( 75,   98) # ざ
        SetWidth(1000); RemoveOverlap()
        Select(0u3058); PasteWithOffset(-55,  -18) # じ
        SetWidth(1000); RemoveOverlap()
        Select(0u305a); PasteWithOffset( 89,  108) # ず
 #        Select(0u305a); PasteWithOffset( 71, -228) # ず
        SetWidth(1000); RemoveOverlap()
        Select(0u305c); PasteWithOffset( 94,  103) # ぜ
 #        Select(0u305c); PasteWithOffset( 76,   93) # ぜ
        SetWidth(1000); RemoveOverlap()
        Select(0u305e); PasteWithOffset( 89,  -25) # ぞ
 #        Select(0u305e); PasteWithOffset( 79,  -15) # ぞ
        SetWidth(1000); RemoveOverlap()

        Select(0u3060); PasteWithOffset( 67,   83) # だ
 #        Select(0u3060); PasteWithOffset( 67,   93) # だ
        SetWidth(1000); RemoveOverlap()
        Select(0u3062); PasteWithOffset( 67,   88) # ぢ
 #        Select(0u3062); PasteWithOffset( 67,   93) # ぢ
        SetWidth(1000); RemoveOverlap()
        Select(0u3065); PasteWithOffset( 67,   84) # づ
        SetWidth(1000); RemoveOverlap()
        Select(0u3067); PasteWithOffset( 66, -231) # で
 #        Select(0u3067); PasteWithOffset( 66, -246) # で
        SetWidth(1000); RemoveOverlap()
        Select(0u3069); PasteWithOffset( 13,   50) # ど
        SetWidth(1000); RemoveOverlap()

        Select(0u3070); PasteWithOffset(101,  94) # ば
 #        Select(0u3070); PasteWithOffset( 80,   84) # ば
        SetWidth(1000); RemoveOverlap()
        Select(0u3073); PasteWithOffset( 43,   59) # び
 #        Select(0u3073); PasteWithOffset( 23,   59) # び
        SetWidth(1000); RemoveOverlap()
        Select(0u3076); PasteWithOffset( 80,   58) # ぶ
 #        Select(0u3076); PasteWithOffset( 55,   38) # ぶ
        SetWidth(1000); RemoveOverlap()
        Select(0u307c); PasteWithOffset(103,   74) # ぼ
 #        Select(0u307c); PasteWithOffset( 73,   34) # ぼ
        SetWidth(1000); RemoveOverlap()

        Select(0u30f4); PasteWithOffset( 65,   94) # ヴ
        SetWidth(1000); RemoveOverlap()

        Select(0u30ac); PasteWithOffset( 84,   89) # ガ
 #        Select(0u30ac); PasteWithOffset( 74,   94) # ガ
        SetWidth(1000); RemoveOverlap()
        Select(0u30ae); PasteWithOffset( 74,   89) # ギ
 #        Select(0u30ae); PasteWithOffset( 74,   94) # ギ
        SetWidth(1000); RemoveOverlap()
        Select(0u30b0); PasteWithOffset( 88,   86) # グ
 #        Select(0u30b0); PasteWithOffset( 78,   86) # グ
        SetWidth(1000); RemoveOverlap()
        Select(0u30b2); PasteWithOffset( 74,   94) # ゲ
        SetWidth(1000); RemoveOverlap()
        Select(0u30b4); PasteWithOffset( 84,   94) # ゴ
 #        Select(0u30b4); PasteWithOffset( 74,   94) # ゴ
        SetWidth(1000); RemoveOverlap()

        Select(0u30b6); PasteWithOffset( 99,  95) # ザ
 #        Select(0u30b6); PasteWithOffset( 79,   80) # ザ
        SetWidth(1000); RemoveOverlap()
        Select(0u30b8); PasteWithOffset(104,   85) # ジ
 #        Select(0u30b8); PasteWithOffset( 74,   85) # ジ
        SetWidth(1000); RemoveOverlap()
        Select(0u30ba); PasteWithOffset( 84,   94) # ズ
 #        Select(0u30ba); PasteWithOffset( 74,   94) # ズ
        SetWidth(1000); RemoveOverlap()
        Select(0u30bc); PasteWithOffset( 72,   99) # ゼ
        SetWidth(1000); RemoveOverlap()
        Select(0u30be); PasteWithOffset(104,   95) # ゾ
 #        Select(0u30be); PasteWithOffset( 74,   85) # ゾ
        SetWidth(1000); RemoveOverlap()

        Select(0u30c0); PasteWithOffset( 90,   95) # ダ
 #        Select(0u30c0); PasteWithOffset( 80,   95) # ダ
        SetWidth(1000); RemoveOverlap()
        Select(0u30c2); PasteWithOffset( 84,   94) # ヂ
 #        Select(0u30c2); PasteWithOffset( 66,   94) # ヂ
        SetWidth(1000); RemoveOverlap()
        Select(0u30c5); PasteWithOffset(104,   85) # ヅ
 #        Select(0u30c5); PasteWithOffset( 74,   85) # ヅ
        SetWidth(1000); RemoveOverlap()
        Select(0u30c7); PasteWithOffset( 75,   83) # デ
 #        Select(0u30c7); PasteWithOffset( 65,   93) # デ
        SetWidth(1000); RemoveOverlap()
        Select(0u30c9); PasteWithOffset(-55,  -18) # ド
        SetWidth(1000); RemoveOverlap()

        Select(0u30d0); PasteWithOffset( 57,   31) # バ
 #        Select(0u30d0); PasteWithOffset(-23,   31) # バ
        SetWidth(1000); RemoveOverlap()
        Select(0u30d3); PasteWithOffset( 54,   68) # ビ
        SetWidth(1000); RemoveOverlap()
        Select(0u30d6); PasteWithOffset(104,   94) # ブ
 #        Select(0u30d6); PasteWithOffset( 84,   74) # ブ
        SetWidth(1000); RemoveOverlap()
        Select(0u30d9); PasteWithOffset( 45,    0) # ベ
 #        Select(0u30d9); PasteWithOffset( 25,    0) # ベ
        SetWidth(1000); RemoveOverlap()
        Select(0u30dc); PasteWithOffset( 74,   94) # ボ
        SetWidth(1000); RemoveOverlap()

        Select(0u30f7); PasteWithOffset(105,   94) # ヷ
 #        Select(0u30f7); PasteWithOffset( 86,   74) # ヷ
        SetWidth(1000); RemoveOverlap()
        Select(0u30f8); PasteWithOffset( 81,  109) # ヸ
 #        Select(0u30f8); PasteWithOffset( 71,  102) # ヸ
        SetWidth(1000); RemoveOverlap()
        Select(0u30f9); PasteWithOffset(104,  102) # ヹ
 #        Select(0u30f9); PasteWithOffset( 86,   82) # ヹ
        SetWidth(1000); RemoveOverlap()
        Select(0u30fa); PasteWithOffset(105,  100) # ヺ
 #        Select(0u30fa); PasteWithOffset( 87,   70) # ヺ
        SetWidth(1000); RemoveOverlap()

        Select(0u3032); PasteWithOffset(  0, -189) # 〲
        SetWidth(1000); RemoveOverlap()
        Select(0u3034); PasteWithOffset( 20, -421) # 〴
 #        Select(0u3034); PasteWithOffset(  0, -421) # 〴
        SetWidth(1000); RemoveOverlap()
        Select(0u309e); PasteWithOffset(-56,  -33) # ゞ
 #        Select(0u309e); PasteWithOffset(-76,  -53) # ゞ
        SetWidth(1000); RemoveOverlap()
        Select(0u30fe); PasteWithOffset(-75,  -53) # ヾ
        SetWidth(1000); RemoveOverlap()
    endif

# べ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Rotate(45)
    Move(-300, 80)
    PasteWithOffset(120, -200)
    RemoveOverlap()
    Copy()
    Select(0u3079); PasteInto() # べ
    OverlapIntersect()

    Select(65553); Copy()
    if (input_list[i] == "${input_kana_regular}")
        Select(0u3079); PasteWithOffset( 20,    0) # べ
 #        Select(0u3079); PasteWithOffset(  0,    0) # べ
    else
        Select(0u3079); PasteWithOffset( 20,    0) # べ
 #        Select(0u3079); PasteWithOffset(  0,    0) # べ
    endif
        SetWidth(1000); RemoveOverlap()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# 漢字部首のグリフ変更
    Print("Edit kanzi busyu")

# ⼣
    Select(0u2f23); Copy() # ⼣
    Select(${address_visi_kana} + 1); Paste() # 避難所

    Select(0u30fb); Copy() # ・
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Scale(60, 48); Copy()
        Select(0u2f23); PasteWithOffset(404, 285) # ⼣
    else
        Scale(65); Copy()
        Select(0u2f23); PasteWithOffset(385, 269) # ⼣
    endif
    SetWidth(1000)
    RemoveOverlap()
    Simplify()
    Select(65552); Clear() # Temporary glyph

# enダッシュ、emダッシュ加工
    Print("Edit en and em dashes")
# –
    Select(0u2013); Copy() # –
    Select(${address_visi_kana} + 2); Paste() # 避難所
    Move(0, 58)
    SetWidth(500)
    Copy()
    Select(${address_visi_kana} + 3); Paste() # 避難所
    Rotate(90)
    Move(230, 30)
    SetWidth(1000)

    Select(0u2013); Copy() # –
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(192, 0); PasteWithOffset(-192, 0)
    else
        PasteWithOffset(202, 0); PasteWithOffset(-202, 0)
    endif
    OverlapIntersect()

    Move(0, 58)
    SetWidth(500)

# ︲
    Select(0u2013); Copy() # –
    Select(0ufe32); Paste() # ︲
    Rotate(90)
    Move(230, 30)
    SetWidth(1000)

# —
    Select(0u2014); Copy() # —
    Select(${address_visi_kana} + 4); Paste() # 避難所
    Move(0, 45)
    SetWidth(1000)
    Copy()
    Select(${address_visi_kana} + 5); Paste() # 避難所
    Rotate(90)
    Move(0, 30)
    SetWidth(1000)

    Select(0u2014); Copy() # —
    PasteWithOffset(313, 0); PasteWithOffset(-637, 0)
    OverlapIntersect(); Copy()
    Rotate(180)
    PasteInto()
    OverlapIntersect()

    Move(0, 45)
    SetWidth(1000)

# ︱
    Select(0u2014); Copy() # —
    Select(0ufe31); Paste() # ︱
    Rotate(90)
    Move(0, 30)
    SetWidth(1000)

# 記号のグリフを加工
    Print("Edit symbols")
# ‖ (上に移動)
    Select(0u2016) # ‖
    Move(0, 60)
    SetWidth(500)

# ⇞ (追加)
    # 矢の延長部分
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(0, -350)
    Select(0u2191); Copy() # ↑
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u21de); Paste() # ⇞
    Move(0, -30)
    # その他
    Select(0u2191); Copy() # ↑
    Select(0u21de); PasteWithOffset(0, 10) # ⇞
    Select(0u003d); Copy() # =
    Select(65552);  Paste() # Temporary glyph
    Scale(80, 100)
    Copy()
    Select(0u21de); PasteWithOffset(228, -55) # ⇞
    SetWidth(1000)
    RemoveOverlap()
    Simplify()
    Select(65552); Clear() # Temporary glyph

# ⇟ (追加)
    Select(0u21de); Copy() # ⇞
    Select(0u21df); Paste() # ⇟
    VFlip()
    CorrectDirection()
    SetWidth(1000)

# ⇡ (追加)
    # 矢の延長部分
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(0, -350)
    Select(0u2191); Copy() # ↑
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u21e1); Paste() # ⇡
    Move(0, -30)
    # その他
    Select(0u2191); Copy() # ↑
    Select(0u21e1); PasteWithOffset(0, 10) # ⇡
    RemoveOverlap()
    # 点線にするためのスクリーン
    Select(0u003d); Copy() # =
    Select(65552);  Paste() # Temporary glyph
    Scale(50, 83)
    HFlip()
    Move(228,-20)
    Select(0u25a0); Copy() # Black square
    Select(65552);  PasteInto() # Temporary glyph
    Scale(100, 120)
    Copy()
    Select(0u21e1); PasteInto() # ⇡
    SetWidth(1000)
    OverlapIntersect()
    Simplify()
    Select(65552); Clear() # Temporary glyph

# ⇠ (追加)
    Select(0u21e1); Copy() # ⇡
    Select(0u21e0); Paste() # ⇠
    Rotate(90)
    SetWidth(1000)

# ⇢ (追加)
    Select(0u21e1); Copy() # ⇡
    Select(0u21e2); Paste() # ⇢
    Rotate(-90)
    SetWidth(1000)

# ⇣ (追加)
    Select(0u21e1); Copy() # ⇡
    Select(0u21e3); Paste() # ⇣
    VFlip()
    CorrectDirection()
    SetWidth(1000)

# ⇵ (追加)
    Select(0u21c5); Copy() # ⇅
    Select(0u21f5); Paste() # ⇵
    VFlip()
    CorrectDirection()
    SetWidth(1000)

# ∥ (全角にする)
    Select(0u2225) # ∥
    ChangeWeight(-2)
    CorrectDirection()
    Scale(110)
    Rotate(-15)
    Move(230, 0)
    SetWidth(1000)

# ∦ (全角にする)
    Select(0u2226) # ∦
    ChangeWeight(-2)
    CorrectDirection()
    Scale(110)
    Rotate(-15)
    Move(230, 0)
    SetWidth(1000)

# 〈〉⟨⟩⸨⸩ (少し上げる)
    Select(0u2329); Move(0, 20); SetWidth(500) # 〈
    Select(0u232a); Move(0, 20); SetWidth(500) # 〉
    Select(0u27e8); Move(0, 20); SetWidth(500) # ⟨
    Select(0u27e9); Move(0, 20); SetWidth(500) # ⟩
    Select(0u2e28); Move(0, 20); SetWidth(500) # ⸨
    Select(0u2e29); Move(0, 20); SetWidth(500) # ⸩

# ⏏ (小さくして下に移動)
    Select(0u23cf) # ⏏
    Scale(90)
    Move(0, -30)
    SetWidth(1000)

# ␥ (全角にする)
    Select(0u2425) # ␥
    ChangeWeight(-2)
    CorrectDirection()
    Scale(110)
    if (input_list[i] == "${input_kana_regular}")
        Rotate(-24)
    else
        Rotate(-28)
    endif
    Move(230, 0)
    SetWidth(1000)

# ▱ (全角にする)
    Select(0u25a1); Copy() # □
    Select(0u25b1); Paste() # ▱
    Transform(80, 0, 40, 70, -4000, 10000)
    if (input_list[i] == "${input_kana_regular}")
        ChangeWeight(22)
    else
        ChangeWeight(24)
    endif
    CorrectDirection()
    SetWidth(1000)

# ◯ (拡大)
    Select(0u25ef) # ◯
    Scale(102)
    SetWidth(1000)

# ✂ (縦書き用ダミー、後でグリフ上書き)
   Select(0u0020); Copy() # スペース
   Select(0u2702); Paste() # ✂

# ➀-➓ (下線を引く)
    j = 0
    while (j < 20)
        Select(0u2780 + j); Copy()
        Select(${address_visi_kana} + 6 + j); Paste() # 避難所
        j += 1
    endloop

    Select(0u005f); Copy() # _
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Scale(115, 100)
        Move(231, 133)
    else
        Scale(110, 70)
        Move(231, 144)
    endif
    j = 0
    while (j < 10)
        Select(65552);  Copy() # Temporary glyph
        Select(0u2780 + j); PasteInto()
        RemoveOverlap()
        SetWidth(1000)
        j += 1
    endloop
    Select(65552); VFlip() # Temporary glyph
    j = 0
    while (j < 10)
        Select(65552);  Copy() # Temporary glyph
        Select(0u278a + j); PasteInto()
        SetWidth(1000)
        j += 1
    endloop
    Select(65552); Clear() # Temporary glyph

# 演算子を下に移動
    math = [0u223c] # ∼
    j = 0
    while (j < SizeOf(math))
        Select(math[j]);
        Move(0,${y_pos_math})
        SetWidth(500)
        j += 1
    endloop

# --------------------------------------------------

# ボールド仮名等のウェイト調整
    if ("${draft_flag}" == "false")
        if (input_list[i] == "${input_kana_bold}")
            Print("Edit kana weight of glyphs")
 #            Select(0u2013, 0u2014) # –—
            Select(0u2025, 0u2026) # ‥…
            SelectMore(0u2e80, 0u2fdf) # 部首
            SelectMore(0u3001, 0u3002) # 、。
            SelectMore(0u3008, 0u3011) # 括弧
            SelectMore(0u3014, 0u301f) # 括弧、〜、引用符
            SelectMore(0u3030, 0u3035) # 繰り返し記号
            SelectMore(0u3040, 0u30ff) # ひらがなカタカナ
            SelectMore(0u31f0, 0u31ff) # カタカナ拡張
            SelectMore(0uff5e) # ～
            SelectMore(0u22ee, 0u22ef) # ⋮⋯
            SelectMore(0u2307) # ⌇
            SelectMore(0u2329, 0u232a) # 〈〉
            SelectMore(0u27e8, 0u27e9) # ⟨⟩
            SelectMore(0u2e28, 0u2e29) # ⸨⸩
            SelectMore(0ufe19) # ︙
            SelectMore(0ufe30) # ︰
 #            SelectMore(0ufe31, 0ufe32) # ︱︲
 #            SelectMore(0uff5f, 0uff9f) # 半角カタカナ
            SelectMore(0u1b000, 0u1b001) # 𛀀𛀁
            SelectMore(1114115, 1114128) # 合字ひらがなカタカナ
            SelectMore(1114384, 1114385) # 縦書き 、。
            SelectMore(1114386, 1114395) # 縦書き括弧
            SelectMore(1114397, 1114408) # 縦書き括弧、〜、引用符
            SelectMore(1114409, 1114432) # 縦書き小文字ひらがなカタカナ
            SelectMore(1114433) # 縦書き ー
            SelectMore(${address_visi_kana}) # 避難した゠
            SelectMore(${address_visi_kana} + 1) # 避難した⼣
            ChangeWeight(${weight_reduce_kana_bold}); CorrectDirection()
        endif
    endif

# ラテン文字、ギリシア文字、キリル文字等のウェイト調整
    if ("${draft_flag}" == "false")
        Print("Edit latin greek cyrillic weight of glyphs")
        if (input_list[i] == "${input_kana_regular}")
            Select(0u00a1, 0u0173) # Latin
            SelectMore(0u174, 0u0175) # W
            SelectMore(0u176, 0u017f)
            SelectMore(0u180, 0u01c3)
 #            SelectMore(0u01c4, 0u01cc) # リガチャ
            SelectMore(0u01cd, 0u01f0)
 #            SelectMore(0u01f1, 0u01f3) # リガチャ
            SelectMore(0u01f4)
 #            SelectMore(0u01f5) # g オープンテイル製作用、後で調整
            SelectMore(0u01f7, 0u024f)
            SelectMore(0u0250, 0u028c)
            SelectMore(0u028d) # w
            SelectMore(0u028e, 0u02a2)
 #            SelectMore(0u02a3, 0u02ac) # リガチャ
            SelectMore(0u02ad, 0u02af)
            SelectMore(0u02b9, 0u02ff) # 装飾文字
            SelectMore(0u0372, 0u03ff) # Greek
            SelectMore(0u0400, 0u04ff) # Cyrillic
            SelectMore(0u1d05) # Latin
            SelectMore(0u1d07)
            SelectMore(0u1e00, 0u1e3d)
            SelectMore(0u1e3e) # M
            SelectMore(0u1e3f)
            SelectMore(0u1e40) # M
            SelectMore(0u1e41)
            SelectMore(0u1e42) # M
            SelectMore(0u1e43, 0u1e7f)
            SelectMore(0u1e80, 0u1e89) # W
            SelectMore(0u1e8a, 0u1e97)
            SelectMore(0u1e98) # W
            SelectMore(0u1e99, 0u1eff)
            SelectMore(0u1f00, 0u1fff) # Greek
            SelectMore(0u2422) # ␢
            SelectMore(0u2c71) # ⱱ
            SelectMore(0ufb00, 0ufb04) # ﬀ

            SelectMore(0u20a0, 0u212d) # 記号類
 #            SelectMore(0u212e) # ℮
            SelectMore(0u212f, 0u214f) # 記号類
             SelectMore(0u2150, 0u21cf) # ローマ数字、矢印
             SelectMore(0u21e4, 0u21e5) # ⇤⇥
            SelectMore(0u21ee, 0u22ed) # 記号類
            SelectMore(0u22f0, 0u2306) # 記号類
            SelectMore(0u2308, 0u2312) # 記号類
 #            SelectMore(0u23cf) # ⏏
 #            SelectMore(0u2425) # ␥
            SelectMore(0u27e8, 0u27e9) # ⟨⟩
            SelectMore(0u2a2f) # ⨯
            SelectMore(0u339b, 0u33a6) # 単位
            ExpandStroke(${weight_reduce_kana_others_regular}, 0, 0, 0, 2)
            CorrectDirection() # ChangeWeight()だと形が崩れるグリフがある
        else
            Select(0u00a1, 0u0173) # Latin
            SelectMore(0u174, 0u0175) # W
            SelectMore(0u176, 0u01c3)
 #            SelectMore(0u01c4, 0u01cc) # リガチャ
            SelectMore(0u01cd, 0u01f0)
 #            SelectMore(0u01f1, 0u01f3) # リガチャ
            SelectMore(0u01f4)
 #            SelectMore(0u01f5) #  g オープンテイル製作用、後で調整
            SelectMore(0u01f7, 0u028c)
            SelectMore(0u028d) # w
            SelectMore(0u028e, 0u02a2)
 #            SelectMore(0u02a3, 0u02ac) # リガチャ
            SelectMore(0u02ad, 0u02af)
            SelectMore(0u02b9, 0u02ff) # 装飾文字
            SelectMore(0u0372, 0u03ff) # Greek
            SelectMore(0u0400, 0u04ff) # Cyrillic
            SelectMore(0u1d05) # Latin
            SelectMore(0u1d07)
            SelectMore(0u1e00, 0u1e3d)
            SelectMore(0u1e3e) # M
            SelectMore(0u1e3f)
            SelectMore(0u1e40) # M
            SelectMore(0u1e41)
            SelectMore(0u1e42) # M
            SelectMore(0u1e43, 0u1e7f)
            SelectMore(0u1e80, 0u1e89) # W
            SelectMore(0u1e8a, 0u1e97)
            SelectMore(0u1e98) # W
            SelectMore(0u1e99, 0u1eff)
            SelectMore(0u1f00, 0u1fff) # Greek
            SelectMore(0u2422) # ␢
            SelectMore(0u2c71) # ⱱ
            SelectMore(0ufb00, 0ufb04) # ﬀ
            ChangeWeight(${weight_reduce_kana_others_bold})
            CorrectDirection()
            Move(0, -9)

            Select(0u20a0, 0u212d) # 記号類
 #            SelectMore(0u212e) # ℮
            SelectMore(0u212f, 0u214f) # 記号類
            SelectMore(0u2150, 0u21cf) # ローマ数字、矢印
            SelectMore(0u21e4, 0u21e5) # ⇤⇥
            SelectMore(0u21ee, 0u22ed) # 記号類
            SelectMore(0u22f0, 0u2306) # 記号類
            SelectMore(0u2308, 0u2312) # 記号類
 #            SelectMore(0u23cf) # ⏏
            SelectMore(0u2425) # ␥
            SelectMore(0u27e8, 0u27e9) # ⟨⟩
            SelectMore(0u2a2f) # ⨯
            SelectMore(0u339b, 0u33a6) # 単位
            ChangeWeight(${weight_reduce_kana_others_bold})
            CorrectDirection()
        endif
    endif

# カタカナを少し下に移動 (カタカナ拡張は縦書き用が無いため移動不要)
    if ("${draft_flag}" == "false")
        Print("Move katakana glyphs")
        Select(0u30a1, 0u30fa) # カタカナ
        SelectMore(0u31f0, 0u31ff) # カナカナ拡張
        SelectMore(1114120, 1114128) # 合字カタカナ
        SelectMore(1114421, 1114432) # 縦書き小文字カタカナ
        SelectMore(0uff66, 0uff9d) # 半角カナ
        Move(0, -10)

        Select(0u30a7, 0u30a8) # ェ エ
        SelectMore(0uff74) # ｴ
        SelectMore(0uff6a) # ｪ
        SelectMore(1114424) # 縦書き ェ
        SelectMore(0u30a9, 0u30aa) # ォ オ
        SelectMore(0uff75) # ｵ
        SelectMore(0uff6b) # ｫ
        SelectMore(1114425) # 縦書き ォ
        SelectMore(0u30ab, 0u30ac) # カ ガ
        SelectMore(0u30f5) # ヵ
        SelectMore(0uff76) # ｶ
        SelectMore(1114431) # 縦書き ヵ
        SelectMore(0u30b3, 0u30b4) # コ ゴ
        SelectMore(0uff7a) # ｺ
        SelectMore(0u30bb, 0u30bc) # セ ゼ
        SelectMore(0uff7e) # ｾ
        SelectMore(0u30cb) # ニ
        SelectMore(0uff86) # ﾆ
        SelectMore(0u30d2, 0u30d4) # ヒ ビ ピ
        SelectMore(0uff8b) # ﾋ
        SelectMore(0u31f6) # ㇶ
        SelectMore(0u30df) # ミ
        SelectMore(0uff90) # ﾐ
        SelectMore(0u30e0) # ム
        SelectMore(0uff91) # ﾑ
        SelectMore(0u30e2) # モ
        SelectMore(0uff93) # ﾓ
        SelectMore(0u30e5, 0u30e6) # ュ ユ
        SelectMore(0uff95) # ﾕ
        SelectMore(0uff6d) # ｭ
        SelectMore(1114428) # 縦書き ュ
        SelectMore(0u30e7, 0u30e8) # ョ ヨ
        SelectMore(0uff96) # ﾖ
        SelectMore(0uff6e) # ｮ
        SelectMore(1114429) # 縦書き ョ
        SelectMore(0u30ed) # ロ
        SelectMore(0uff9b) # ﾛ
        SelectMore(0u31ff) # ㇿ
        SelectMore(0u30f1) # ヱ
        SelectMore(0u30f9) # ヹ
        Move(0, -10)

        Select(0u30ad, 0u30ae) # キ ギ
        SelectMore(0uff77) # ｷ
        Select(0u30c8, 0u30c9) # ト ド
        SelectMore(0uff84) # ﾄ
        SelectMore(0u31f3) # ㇳ
        SelectMore(0u30ea) # リ
        SelectMore(0uff98) # ﾘ
        SelectMore(0u31fc) # ㇼ
        Move(0, 5)
    endif

# 縦書き対応 (仮名小文字を改変した場合は要コピー)
    Print("Edit vert glyphs")
# ぁ (加工したグリフをコピー)
    Select(0u3041); Copy() # ぁ
    Select(1114409); Paste()
    Move(72, 73)
    SetWidth(1000)

# ぃ (加工したグリフをコピー)
    Select(0u3043); Copy() # ぃ
    Select(1114410); Paste()
    Move(72, 73)
    SetWidth(1000)

# ゎ (加工したグリフをコピー)
    Select(0u308e); Copy() # ゎ
    Select(1114418); Paste()
    Move(72, 73)
    SetWidth(1000)

# ゖ (加工したグリフをコピー)
    Select(0u3096); Copy() # ゖ
    Select(1114420); Paste()
    Move(72, 73)
    SetWidth(1000)

# Lookup追加
    Select(0u3041) # ぁ
    lookups = GetPosSub("*") # フィーチャを取り出す
# 全角横向 (後でグリフ上書き)
    hori = [0uff0d, 0uff1b, 0uff1c, 0uff1e,\
            0uff5f, 0uff60]  # －；＜＞,｟｠
    vert = ${address_vert_kana}
    j = 0
    while (j < SizeOf(hori))
        Select(hori[j]); Copy()
        Select(vert + j); Paste()
        glyphName = GlyphInfo("Name")
        Select(hori[j])
        AddPosSub(lookups[0][0],glyphName) # vertフィーチャを追加
        j += 1
    endloop
# 全角 (後でグリフ上書き)
    hori = [0u309b, 0u309c,\
            0uff0f, 0uff3c,\
            0uff01, 0uff02, 0uff03, 0uff04,\
            0uff05, 0uff06, 0uff07, 0uff0a,\
            0uff0b, 0uff10, 0uff11, 0uff12,\
            0uff13, 0uff14, 0uff15, 0uff16,\
            0uff17, 0uff18, 0uff19, 0uff1f,\
            0uff20, 0uff21, 0uff22, 0uff23,\
            0uff24, 0uff25, 0uff26, 0uff27,\
            0uff28, 0uff29, 0uff2a, 0uff2b,\
            0uff2c, 0uff2d, 0uff2e, 0uff2f,\
            0uff30, 0uff31, 0uff32, 0uff33,\
            0uff34, 0uff35, 0uff36, 0uff37,\
            0uff38, 0uff39, 0uff3a, 0uff3e,\
            0uff40, 0uff41, 0uff42, 0uff43,\
            0uff44, 0uff45, 0uff46, 0uff47,\
            0uff48, 0uff49, 0uff4a, 0uff4b,\
            0uff4c, 0uff4d, 0uff4e, 0uff4f,\
            0uff50, 0uff51, 0uff52, 0uff53,\
            0uff54, 0uff55, 0uff56, 0uff57,\
            0uff58, 0uff59, 0uff5a, 0uffe0,\
            0uffe1, 0uffe2, 0uffe4, 0uffe5,\
            0uffe6,\
            0u203c, 0u2047, 0u2048, 0u2049,\
            0u2702] # 濁点、半濁点, Solidus、Reverse solidus, ！-￦, ‼⁇⁈⁉, ✂
    vert += j
    j = 0
    while (j < SizeOf(hori))
        Select(hori[j]); Copy()
        Select(vert + j); Paste()
        glyphName = GlyphInfo("Name")
        Select(hori[j])
        AddPosSub(lookups[0][0],glyphName)
        j += 1
    endloop
# カナ (グリフそのまま)
    hori = [0u2016, 0u3030, 0u30a0,\
            0u31f0, 0u31f1, 0u31f2, 0u31f3,\
            0u31f4, 0u31f5, 0u31f6, 0u31f7,\
            0u31f8, 0u31f9, 0u31fa, 0u31fb,\
            0u31fc, 0u31fd, 0u31fe, 0u31ff,\
            1114128] # ‖〰゠, # カタカナ拡張
    vert += j
    j = 0
    while (j < SizeOf(hori))
        Select(hori[j]); Copy()
        Select(vert + j); Paste()
        if (j == 0) # ‖
            Rotate(-90, 490, 340)
            Move(0, -250)
            SetWidth(1000)
        elseif (j <= 2) # 〰゠
            Rotate(-90, 490, 340)
            SetWidth(1000)
        else
            Move(72, 73)
            SetWidth(1000)
        endif
        glyphName = GlyphInfo("Name")
        Select(hori[j])
        AddPosSub(lookups[0][0],glyphName)
        j += 1
    endloop

# --------------------------------------------------

# Proccess before saving
    Print("Process before saving")
    if (0 < SelectIf(".notdef"))
        Clear(); DetachAndRemoveGlyphs()
    endif
    RemoveDetachedGlyphs()
    if ("${draft_flag}" == "true")
        SelectWorthOutputting()
        RoundToInt()
    endif

# --------------------------------------------------

# Save modified kana font
    Print("Save " + output_list[i])
    Save("${tmpdir}/" + output_list[i])
 #    Generate("${tmpdir}/" + output_list[i], "", 0x04)
 #    Generate("${tmpdir}/" + output_list[i], "", 0x84)
    Close()
    Print("")

    i += 1
endloop

Quit()
_EOT_

################################################################################
# Generate script for modified kanzi fonts
################################################################################

cat > ${tmpdir}/${modified_kanzi_generator} << _EOT_
#!$fontforge_command -script

Print("- Generate modified kanzi fonts -")

# Set parameters
input_list  = ["${input_kanzi_regular}",    "${input_kanzi_bold}"]
output_list = ["${modified_kanzi_regular}", "${modified_kanzi_bold}"]

# Begin loop of regular and bold
i = 0
while (i < SizeOf(input_list))
# Open kanzi font
    Print("Open " + input_list[i])
    Open(input_list[i])
    SelectWorthOutputting()
    UnlinkReference()
    ScaleToEm(${typo_ascent1024}, ${typo_descent1024}) # OS/2テーブルを書き換えないと指定したem値にならない
    SetOS2Value("WinAscent",             ${win_ascent1024}) # Windows用(この範囲外は描画されない)
    SetOS2Value("WinDescent",            ${win_descent1024})
    SetOS2Value("TypoAscent",            ${typo_ascent1024}) # 組版用(em値と合わせる)
    SetOS2Value("TypoDescent",          -${typo_descent1024})
    SetOS2Value("TypoLineGap",           ${typo_linegap1024})
    SetOS2Value("HHeadAscent",           ${hhea_ascent1024}) # Mac用
    SetOS2Value("HHeadDescent",         -${hhea_descent1024})
    SetOS2Value("HHeadLineGap",          ${hhea_linegap1024})

# --------------------------------------------------

# 使用しないグリフクリア
    Print("Remove not used glyphs")
    Select(0, 31); Clear(); DetachAndRemoveGlyphs()

    Select(1114112, 1114815)
    SelectMore(1114826, 1114830)
    SelectMore(1114841, 1115183)
    SelectMore(1115493, 1115732)
 #    SelectMore(1115733, 1115734) # ∭印
    SelectMore(1115735, 1115760)
    SelectMore(1115764, 1115765)
    SelectMore(1115768, 1115769)
    SelectMore(1115772, 1115773)
    SelectMore(1115776, 1116302)
    SelectMore(1116304)
 #    SelectMore(1114112, 1115183) # 異体字のみ残す場合
 #    SelectMore(1115493, 1116304)
    Clear(); DetachAndRemoveGlyphs()

# Clear kerns, position, substitutions
    Print("Clear kerns, position, substitutions")
    RemoveAllKerns()

    lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups); j = 0
    while (j < numlookups)
        if (j == 2 \
          || j == 3 \
          || j == 4 \
          || j == 5 \
          || j == 7 \
          || j == 9 \
          || j == 16 \
          || j == 17 \
          || j == 18 \
          || j == 21 \
          || j == 23 \
          || j == 24) # aalt nalt vert 漢字異体字以外のLookupを削除
            Print("Remove GSUB_" + lookups[j])
            RemoveLookup(lookups[j])
        endif
        j++
    endloop

    lookups = GetLookups("GPOS"); numlookups = SizeOf(lookups); j = 0
    while (j < numlookups)
        Print("Remove GPOS_" + lookups[j])
        RemoveLookup(lookups[j]); j++
    endloop

# Lookup編集
    Print("Edit aalt lookups")
    # 全て削除
    Select(0u0000, 0u3002) # 。まで
    SelectMore(0u3004) # 〄
    SelectMore(0u3008, 0u3020) # 括弧、記号
    SelectMore(0u302a, 0u3037) # 記号、仮名
    SelectMore(0u303e, 0u33ff) # 仮名、組文字等
    SelectMore(1114112, 1115183) # 漢字以外
    SelectMore(1115493, 1116304)

    SelectMore(0u303c) # 〼
    SelectMore(0u5973) # 女 ♀
    SelectMore(0u66c7) # 曇
    SelectMore(0u74f1) # 瓱 mg
    SelectMore(0u7acf) # 竏 kL
    SelectMore(0u7ad3) # 竓 mL
    SelectMore(0u7ad5) # 竕 dL
    SelectMore(0u96e8) # 雨
    SelectMore(0u96ea) # 雪

    SelectMore(0u303d) # 〽
    SelectMore(0u544e) # 呎 feet
    SelectMore(0u5f17) # 弗 $
    SelectMore(0u74e9) # 瓩 kg
    SelectMore(0u74f2) # 瓲 t
    SelectMore(0u78c5) # 磅 £
    SelectMore(0u7acb) # 立 L
    SelectMore(0u7c73) # 米 m
    SelectMore(0u7c81) # 粁 km
    SelectMore(0u7c8d) # 粍 mm
    SelectMore(0u97f3) # 音
    RemovePosSub("*")

# aalt 1対1 (記号類を削除)
    Select(0u342e) # 㐮
    lookups = GetPosSub("*") # フィーチャを取り出す

    Select(0u96f6) # 零
    glyphName = GlyphInfo("Name")
    Select(0u3007); RemovePosSub("*") # 〇
    AddPosSub(lookups[0][0],glyphName)
    glyphName = GlyphInfo("Name")
    Select(0u96f6); RemovePosSub("*") # 零
    AddPosSub(lookups[0][0],glyphName)

    Select(0u5713) # 圓
    glyphName = GlyphInfo("Name")
    Select(0u5186); RemovePosSub("*") # 円
    AddPosSub(lookups[0][0],glyphName)
    glyphName = GlyphInfo("Name")
    Select(0u5713); RemovePosSub("*") # 圓
    AddPosSub(lookups[0][0],glyphName)

    Select(0u67a1) # 枡
    glyphName = GlyphInfo("Name")
    Select(0u685d); RemovePosSub("*") # 桝
    AddPosSub(lookups[0][0],glyphName)
    glyphName = GlyphInfo("Name")
    Select(0u67a1); RemovePosSub("*") # 枡
    AddPosSub(lookups[0][0],glyphName)

    Select(0u76a8) # 皨
    glyphName = GlyphInfo("Name")
    Select(0u661f); RemovePosSub("*") # 星
    AddPosSub(lookups[0][0],glyphName)
    glyphName = GlyphInfo("Name")
    Select(0u76a8); RemovePosSub("*") # 皨
    AddPosSub(lookups[0][0],glyphName)

# aalt 複数 (記号類を削除)
    Select(0u3402) # 㐂
    lookups = GetPosSub("*") # フィーチャを取り出す

    Select(0u38fa) # 㣺
    glyphName = GlyphInfo("Name")
    Select(0u5fc3); RemovePosSub("*") # 心
    AddPosSub(lookups[0][0],glyphName) # 1対複数のaaltフィーチャを追加
    Select(0u5fc4) # 忄
    glyphName = GlyphInfo("Name")
    Select(0u5fc3) # 心
    AddPosSub(lookups[0][0],glyphName)

    Select(0ufa12) # 晴
    glyphName = GlyphInfo("Name")
    Select(0u6674); RemovePosSub("*") # 晴
    AddPosSub(lookups[0][0],glyphName)
    Select(0u6692) # 暒
    glyphName = GlyphInfo("Name")
    Select(0u6674) # 晴
    AddPosSub(lookups[0][0],glyphName)

# aalt nalt 1対1
    Print("Edit aalt nalt lookups")
    Select(0u4e2d) # 中
    lookups = GetPosSub("*") # フィーチャを取り出す

    Select(0u32a4) # ㊤
    glyphName = GlyphInfo("Name")
    Select(0u4e0a); RemovePosSub("*") # 上
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)

    Select(0u32a6) # ㊦
    glyphName = GlyphInfo("Name")
    Select(0u4e0b); RemovePosSub("*") # 下
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)

    Select(0u32a8) # ㊨
    glyphName = GlyphInfo("Name")
    Select(0u53f3); RemovePosSub("*") # 右
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)

    Select(0u32a7) # ㊧
    glyphName = GlyphInfo("Name")
    Select(0u5de6); RemovePosSub("*") # 左
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)

    Select(0u3241) # ㉁
    glyphName = GlyphInfo("Name")
    Select(0u4f11); RemovePosSub("*") # 休
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)

    Select(0u322f) # ㈯
    glyphName = GlyphInfo("Name")
    Select(0u571f); RemovePosSub("*") # 土
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)

    Select(0u3230) # ㈰
    glyphName = GlyphInfo("Name")
    Select(0u65e5); RemovePosSub("*") # 日
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)

    Select(0u322a) # ㈪
    glyphName = GlyphInfo("Name")
    Select(0u6708); RemovePosSub("*") # 月
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)

    Select(0u322d) # ㈭
    glyphName = GlyphInfo("Name")
    Select(0u6728); RemovePosSub("*") # 木
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)

    Select(0u322c) # ㈬
    glyphName = GlyphInfo("Name")
    Select(0u6c34); RemovePosSub("*") # 水
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)

    Select(0u322b) # ㈫
    glyphName = GlyphInfo("Name")
    Select(0u706b); RemovePosSub("*") # 火
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)

    Select(0u3235) # ㈵
    glyphName = GlyphInfo("Name")
    Select(0u7279); RemovePosSub("*") # 特
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)

    Select(0u3237) # ㈷
    glyphName = GlyphInfo("Name")
    Select(0u795d); RemovePosSub("*") # 祝
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)

    Select(0u322e) # ㈮
    glyphName = GlyphInfo("Name")
    Select(0u91d1); RemovePosSub("*") # 金
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)

# Clear instructions, hints
    Print("Clear instructions, hints")
    SelectWorthOutputting()
    ClearInstrs()
    ClearHints()

# Proccess before editing
    if ("${draft_flag}" == "false")
        Print("Process before editing (it may take a few minutes)")
        SelectWorthOutputting()
        RemoveOverlap()
        CorrectDirection()
    endif

# --------------------------------------------------

# Scale down all glyphs
    Print("Scale down all glyphs")
    SelectWorthOutputting()
    Scale(87, 87, 0, 0); SetWidth(115, 2); SetWidth(1, 1)
    Move(33, 0); SetWidth(-33, 1)
 #    RemoveOverlap()

# --------------------------------------------------

# Edit kanzi (漢字のグリフ変更)
    Print("Edit kanzi")

# 〇 (上にうろこを追加)
    Select(0u3007); Copy() # 〇
    Select(${address_visi_kanzi}); Paste() # 避難所

    Select(0u002e); Copy() # Full stop
    Select(65552);  Paste() # Temporary glyph
    Scale(59); Copy()
    Select(0u3007) # 〇
    PasteWithOffset(319, 724)
    SetWidth(1024)
    RemoveOverlap()

    Select(65552); Clear() # Temporary glyph

# 一 (右にうろこを追加)
    Select(0u4e00); Copy() # 一
    Select(${address_visi_kanzi} + 1); Paste() # 避難所

    Select(0u002e); Copy() # Full stop
    Select(65552);  Paste() # Temporary glyph
    Scale(59); Copy()
    Select(0u4e00) # 一
    if (input_list[i] == "${input_kanzi_regular}")
        PasteWithOffset(695, 372)
    else
        PasteWithOffset(685, 385)
    endif
    RemoveOverlap()
    Simplify()
    SetWidth(1024)
    Select(65552); Clear() # Temporary glyph

# 二 (一に合わす)
    Select(0u4e8c); Copy() # 二
    Select(${address_visi_kanzi} + 2); Paste() # 避難所

    Select(0u002e); Copy() # Full stop
    Select(65552);  Paste() # Temporary glyph
    Scale(59); Copy()
    Select(0u4e8c) # 二
    if (input_list[i] == "${input_kanzi_regular}")
        PasteWithOffset(699, 77)
    else
        PasteWithOffset(689, 101)
    endif
    RemoveOverlap()
    Simplify()
    SetWidth(1024)
    Select(65552); Clear() # Temporary glyph

# 三 (デザイン統一のため一二に合わす)
    Select(0u4e09); Copy() # 三
    Select(${address_visi_kanzi} + 3); Paste() # 避難所

    Select(0u002e); Copy() # Full stop
    Select(65552);  Paste() # Temporary glyph
    Scale(59); Copy()
    Select(0u4e09) # 三
    if (input_list[i] == "${input_kanzi_regular}")
        PasteWithOffset(693, 45)
    else
        PasteWithOffset(676, 57)
    endif
    RemoveOverlap()
    Simplify()
    SetWidth(1024)
    Select(65552); Clear() # Temporary glyph

# 工 (右下にうろこを追加)
    Select(0u5de5); Copy() # 工
    Select(${address_visi_kanzi} + 4); Paste() # 避難所

    Select(0u002e); Copy() # Full stop
    Select(65552);  Paste() # Temporary glyph
    Scale(59); Copy()
    Select(0u5de5) # 工
    if (input_list[i] == "${input_kanzi_regular}")
        PasteWithOffset(706, 45)
    else
        PasteWithOffset(689, 62)
    endif
    RemoveOverlap()
    Simplify()
    SetWidth(1024)
    Select(65552); Clear() # Temporary glyph

# 力 (右上にうろこを追加)
    Select(0u529b); Copy() # 力
    Select(${address_visi_kanzi} + 5); Paste() # 避難所

    Select(0u002e); Copy() # Full stop
    Select(65552);  Paste() # Temporary glyph
    Scale(59); Copy()
    Select(0u529b) # 力
    if (input_list[i] == "${input_kanzi_regular}")
        PasteWithOffset(647, 545)
    else
        PasteWithOffset(637, 552)
        PasteWithOffset(622, 552)
    endif
    RemoveOverlap()
    Simplify()
    SetWidth(1024)
    Select(65552); Clear() # Temporary glyph

# 夕 (右上にうろこを追加)
    Select(0u5915); Copy() # 夕
    Select(${address_visi_kanzi} + 6); Paste() # 避難所

    Select(0u002e); Copy() # Full stop
    Select(65552);  Paste() # Temporary glyph
    Scale(59); Copy()
    Select(0u5915) # 夕
    if (input_list[i] == "${input_kanzi_regular}")
        PasteWithOffset(665, 583)
        PasteWithOffset(675, 583)
    else
        PasteWithOffset(659, 573)
        PasteWithOffset(669, 573)
    endif
    RemoveOverlap()
    Simplify()
    SetWidth(1024)
    Select(65552); Clear() # Temporary glyph

# 卜 (てっぺんにうろこを追加)
    Select(0u535c); Copy() # 卜
    Select(${address_visi_kanzi} + 7); Paste() # 避難所

    Select(0u002e); Copy() # Full stop
    Select(65552);  Paste() # Temporary glyph
    Scale(59); Copy()
    Select(0u535c) # 卜
    if (input_list[i] == "${input_kanzi_regular}")
        PasteWithOffset(168, 682)
    else
        PasteWithOffset(130, 668)
    endif
    RemoveOverlap()
    Simplify()
    SetWidth(1024)
    Select(65552); Clear() # Temporary glyph

# 口 (右上にうろこを追加)
    Select(0u53e3); Copy() # 口
    Select(${address_visi_kanzi} + 8); Paste() # 避難所

    Select(0u002e); Copy() # Full stop
    Select(65552);  Paste() # Temporary glyph
    Scale(59); Copy()
    Select(0u53e3) # 口
    if (input_list[i] == "${input_kanzi_regular}")
        PasteWithOffset(629, 650)
 #        PasteWithOffset(11, 650)
    else
        PasteWithOffset(604, 653)
        PasteWithOffset(616, 653)
 #        PasteWithOffset(3, 653)
 #        PasteWithOffset(15, 653)
    endif
    RemoveOverlap()
    Simplify()
    SetWidth(1024)
    Select(65552); Clear() # Temporary glyph

# 土吉 (追加)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(130, 100)
    Move(0, 370)
    Select(0u572d); Copy() # 圭
    Select(65552);  PasteInto()
    OverlapIntersect()
    Copy()
    Select(0u20bb7); Paste()

    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(130, 100)
    Move(0, -370)
    Select(0u5409); Copy() # 吉
    Select(65552);  PasteInto()
    OverlapIntersect()
    Copy()

    Select(0u20bb7); PasteInto()
    SetWidth(1024)
    Select(65552); Clear() # Temporary glyph

    # aalt追加
    Select(0u342e) # 㐮
    lookups = GetPosSub("*")

    Select(0u5409) # 吉
    glyphName = GlyphInfo("Name")
    Select(0u20bb7); RemovePosSub("*") # 𠮷
    AddPosSub(lookups[0][0],glyphName)
    glyphName = GlyphInfo("Name")
    Select(0u5409); RemovePosSub("*") # 吉
    AddPosSub(lookups[0][0],glyphName)

# 記号のグリフを加工
    Print("Edit symbols")

# 🎤 (追加) ※ ∪ の加工より前にすること
    # マイク
    Select(0u222a); Copy() # ∪
    Select(65552);  Paste() # Temporary glyph
    Scale(50, 50);  Copy()
    Select(65553);  Paste() # Temporary glyph
    VFlip(); CorrectDirection()
    Copy()
    Select(65552);  PasteWithOffset(0, 210) # Temporary glyph
    RemoveOverlap()
    ChangeWeight(28); CorrectDirection()
    Copy()
    Select(0u1f3a4); Paste() # 🎤
    Move(0, 30)

    # ホルダ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(0, -280)
    Select(0u222a); Copy() # ∪
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    if (input_list[i] == "${input_kanzi_bold}")
        ChangeWeight(-6); CorrectDirection()
    endif
    Copy()
    Select(0u1f3a4); PasteWithOffset(0, 30) # 🎤

    # スタンド
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(0, -500)
    Scale(60, 100, 478, 0)
    Select(0u22a5); Copy() # ⊥
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Scale(95, 95, 478, 0)
    Copy()
    Select(0u1f3a4); PasteWithOffset(0, -70) # 🎤
    RemoveOverlap()
    SetWidth(1024)

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ∅ (少し回転)
    Select(0u2205) # ∅
    Rotate(5, 256, 339)
    SetWidth(512)

# ∈ (半角にする)
    Select(0u2208) # ∈
    Select(0u25a0); Copy() # Black square
    Select(0u2208); PasteWithOffset(-301, 0) # ∈
    OverlapIntersect()
    Move(-108, 0)
    SetWidth(512)

# ∋ (半角にする)
    Select(0u220b) # ∋
    Select(0u25a0); Copy() # Black square
    Select(0u220b); PasteWithOffset(291, 0) # ∋
    OverlapIntersect()
    Move(-328, 0)
    SetWidth(512)

# ∧ (半角にする)
    Select(0u2227) # ∧
    Scale(75)
    if (input_list[i] == "${input_kanzi_regular}")
        ChangeWeight(10)
    else
        ChangeWeight(14)
    endif
    CorrectDirection()
    Move(-222, 0)
    SetWidth(512)

# ⊼ (追加) ※ ∧ の加工より後にすること
    Select(0u2227); Copy() # ∧
    Select(0u22bc); Paste() # ⊼
    Select(0u2212); Copy() # −
    Select(0u22bc); PasteWithOffset(0, 285) # ⊼
    SetWidth(512)

# ∨ (半角にする)
    Select(0u2228) # ∨
    Scale(75)
    if (input_list[i] == "${input_kanzi_regular}")
        ChangeWeight(10)
    else
        ChangeWeight(14)
    endif
    CorrectDirection()
    Move(-222, 0)
    SetWidth(512)

# ∩ (半角にする)
    Select(0u2229) # ∩
    Scale(75, 100)
    Move(-231, 0); Copy()
    PasteWithOffset(18, 0)
    RemoveOverlap()
    SetWidth(512)

# ∪ (半角にする)
    Select(0u222a) # ∪
    Scale(75, 100)
    Move(-231, 0); Copy()
    PasteWithOffset(18, 0)
    RemoveOverlap()
    SetWidth(512)

# ⊂ (半角にする)
    Select(0u25a0); Copy() # Black square
    Select(0u2282); PasteWithOffset(-301, 0) # ⊂
    OverlapIntersect()
    Move(-108, 0)
    SetWidth(512)

# ⊃ (半角にする)
    Select(0u25a0); Copy() # Black square
    Select(0u2283); PasteWithOffset(291, 0) # ⊃
    OverlapIntersect()
    Move(-328, 0)
    SetWidth(512)

# ⊆ (半角にする)
    Select(0u25a0); Copy() # Black square
    Select(0u2286); PasteWithOffset(-301, 0) # ⊆
    OverlapIntersect()
    Move(-108, 0)
    SetWidth(512)

# ⊇ (半角にする)
    Select(0u25a0); Copy() # Black square
    Select(0u2287); PasteWithOffset(291, 0) # ⊇
    OverlapIntersect()
    Move(-328, 0)
    SetWidth(512)

# ⊻ (追加) ※ ∨ の加工より後にすること
    Select(0u2228); Copy() # ∨
    Select(0u22bb); Paste() # ⊻
    Select(0u2212); Copy() # −
    Select(0u22bb); PasteWithOffset(0, -286) # ⊻
    SetWidth(512)

# ∫ (半角にする)
    Select(0u222b) # ∫
    Move(-222, 0)
    SetWidth(512)

# ∮ (半角にする)
    Select(0u222e) # ∮
    Move(-222, 0)
    SetWidth(512)

# ∭ (半角にする)
    Select(1115733); Copy()
    Select(0u222d); Paste() # ∭
    SetWidth(1024)
    Select(1115733)
    Clear(); DetachAndRemoveGlyphs()

# ≒ (半角にする)
    Select(0u2252) # ≒
    Scale(70, 100)
    Move(-222, 0)
    Select(0u00b7); Copy() # ·
    Select(65552);  Paste() # Temporary glyph
    Scale(70); Copy()
    Select(0u2252) # ≒
    PasteWithOffset(-87, 285)
    PasteWithOffset(87, -285)
    RemoveOverlap()
    SetWidth(512)
    Select(65552); Clear() # Temporary glyph

# ≢ (全角にする)
    Select(0u2261); Copy() # ≡
    Select(0u2262); Paste() # ≢
    Select(0u002f); Copy() # /
    Select(65552);  Paste() # Temporary glyph
    Scale(121)
    Move(230, 0)
    Copy()
    Select(0u2262); PasteInto() # ≢
    RemoveOverlap()
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(95)
    Copy()
    Select(0u2262); PasteInto() # ≢
    OverlapIntersect()
    SetWidth(1024)
    Select(65552); Clear() # Temporary glyph

# ≦ (半角にする)
    Select(0u2266) # ≦
    Scale(64, 100)
    Move(-220, 0)
    SetWidth(512)

# ≧ (半角にする)
    Select(0u2267) # ≧
    Scale(64, 100)
    Move(-224, 0)
    SetWidth(512)

# ⌃ (追加)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kanzi_regular}")
        Move(-100, -250)
    else
        Move(-100, -241)
    endif
    Select(0u2305); Copy() # ⌆
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u2303); Paste() # ⌃
    Scale(150, 100)
    if (input_list[i] == "${input_kanzi_regular}")
        ChangeWeight(-6)
    else
        ChangeWeight(-12)
    endif
    CorrectDirection()
    Move(240, 224)
    SetWidth(1024)
    Select(65552); Clear() # Temporary glyph

# ⌤ (追加) ※ ⌃ の加工より後にすること
    Select(0u2303); Copy() # ⌃
    Select(0u2324); Paste() # ⌤
    Select(0u002d); Copy() # -
    Select(65552);  Paste() # Temporary glyph
    Scale(60, 102); Copy()
    Select(0u2324)
    PasteWithOffset(11 ,294) # ⌤
    PasteWithOffset(470, 294) # ⌤
    SetWidth(1024)
    Select(65552); Clear() # Temporary glyph

# ⎧ (下を延ばす)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(0, -490)
    Select(0u23a7); Copy() # ⎧
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u23a7); PasteWithOffset(0, -311) # ⎧
    RemoveOverlap()
    Simplify()
    Move(-202, 0)
    SetWidth(512)

    Select(0u23a8); PasteWithOffset(0, -311) # ⎨

# ⎩ (上を延ばす)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(0, 501)
    Select(0u23a9); Copy() # ⎩
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u23a9); PasteWithOffset(0, 227) # ⎩
    RemoveOverlap()
    Simplify()
    Move(-202, 0)
    SetWidth(512)

# ⎨ (上下を延ばす)
    Select(0u23a8); PasteWithOffset(0, 227) # ⎨
    RemoveOverlap()
    Simplify()
    Move(-202, 0)
    SetWidth(512)

    Select(65552); Clear() # Temporary glyph

# ⎫ (下を延ばす)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(0, -490)
    Select(0u23ab); Copy() # ⎫
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u23ab); PasteWithOffset(0, -311) # ⎫
    RemoveOverlap()
    Simplify()
    Move(-242, 0)
    SetWidth(512)

    Select(0u23ac); PasteWithOffset(0, -311) # ⎬

# ⎭ (上を延ばす)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(0, 501)
    Select(0u23ad); Copy() # ⎭
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u23ad); PasteWithOffset(0, 227) # ⎭
    RemoveOverlap()
    Simplify()
    Move(-242, 0)
    SetWidth(512)

# ⎬ (上下を延ばす)
    Select(0u23ac); PasteWithOffset(0, 227) # ⎬
    RemoveOverlap()
    Simplify()
    Move(-242, 0)
    SetWidth(512)

    Select(65552); Clear() # Temporary glyph

# ⎾ (右を延ばす)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(100, 130)
    Move(700, 0)
    Select(0u23be); Copy() # ⎾
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u23be); PasteWithOffset(100, 0) # ⎾
    RemoveOverlap()
    Simplify()
    SetWidth(1024)

    Select(0u23c1); PasteWithOffset(100, 0) # ⏁
    Select(0u23c4); PasteWithOffset(100, 0) # ⏄
    Select(0u23c7); PasteWithOffset(100, 0) # ⏇
    Select(0u23c9); PasteWithOffset(100, 0) # ⏉

# ⏋ (左を延ばす)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(100, 130)
    Move(-700, 0)
    Select(0u23cb); Copy() # ⏋
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u23cb); PasteWithOffset(-100, 0) # ⏋
    RemoveOverlap()
    Simplify()
    SetWidth(1024)

# ⏁ (左右を延ばす)
    Select(0u23c1); PasteWithOffset(-100, 0) # ⏁
    RemoveOverlap()
    Simplify()
    SetWidth(1024)
# ⏄ (左右を延ばす)
    Select(0u23c4); PasteWithOffset(-100, 0) # ⏄
    RemoveOverlap()
    Simplify()
    SetWidth(1024)
# ⏇ (左右を延ばす)
    Select(0u23c7); PasteWithOffset(-100, 0) # ⏇
    RemoveOverlap()
    Simplify()
    SetWidth(1024)
# ⏉ (左右を延ばす)
    Select(0u23c9); PasteWithOffset(-100, 0) # ⏉
    RemoveOverlap()
    Simplify()
    SetWidth(1024)

    Select(65552); Clear() # Temporary glyph

# ⎿ (右を延ばす)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(100, 130)
    Move(700, 0)
    Select(0u23bf); Copy() # ⎿
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u23bf); PasteWithOffset(100, 0) # ⎿
    RemoveOverlap()
    Simplify()
    SetWidth(1024)

    Select(0u23c2); PasteWithOffset(100, 0) # ⏂
    Select(0u23c5); PasteWithOffset(100, 0) # ⏅
    Select(0u23c8); PasteWithOffset(100, 0) # ⏈
    Select(0u23ca); PasteWithOffset(100, 0) # ⏊

# ⏌ (左を延ばす)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(100, 130)
    Move(-700, 0)
    Select(0u23cc); Copy() # ⏌
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u23cc); PasteWithOffset(-100, 0) # ⏌
    RemoveOverlap()
    Simplify()
    SetWidth(1024)

# ⏂ (左右を延ばす)
    Select(0u23c2); PasteWithOffset(-100, 0) # ⏂
    RemoveOverlap()
    Simplify()
    SetWidth(1024)
# ⏅ (左右を延ばす)
    Select(0u23c5); PasteWithOffset(-100, 0) # ⏅
    RemoveOverlap()
    Simplify()
    SetWidth(1024)
# ⏈ (左右を延ばす)
    Select(0u23c8); PasteWithOffset(-100, 0) # ⏈
    RemoveOverlap()
    Simplify()
    SetWidth(1024)
# ⏊ (左右を延ばす)
    Select(0u23ca); PasteWithOffset(-100, 0) # ⏊
    RemoveOverlap()
    Simplify()
    SetWidth(1024)

    Select(65552); Clear() # Temporary glyph

# ☜-☟ (拡大)
    Select(0u261c, 0u261f); Scale(116) # ☜-☟
    SetWidth(1024)

# ♩ (全角にする)
    Select(0u2669) # ♩
    Scale(155)
    Move(240, 0)
    SetWidth(1024)

# ♫ (全角にする)
    Select(0u266b) # ♫
    Scale(155)
    Move(200, 0)
    SetWidth(1024)

# ♬ (全角にする)
    Select(0u266c) # ♬
    Scale(155)
    Move(200, 0)
    SetWidth(1024)

# ♭ (少し左に移動)
    Select(0u266d) # ♭
    Move(-10, 0)
    SetWidth(1024)

# ♮ (全角にする)
    Select(0u266e) # ♮
    Scale(155)
    Move(240, 0)
    SetWidth(1024)

# ♯ (全角にする)
    Select(0u266f) # ♯
    Scale(80,100)
    if (input_list[i] == "${input_kanzi_regular}")
        ChangeWeight(14)
    else
        ChangeWeight(12)
    endif
    CorrectDirection()
    Move(20, 0)
    SetWidth(1024)

# ⮕ (追加)
    Select(0u2b05); Copy() # ⬅
    Select(0u2b95); Paste() # ⮕
    HFlip()
    CorrectDirection()
    SetWidth(1024)

# ⤴ (全角にする)
    Select(0u2934) # ⤴
    Move(230, 0)
    SetWidth(1024)

# ⤵ (全角にする)
    Select(0u2935) # ⤵
    Move(230, 0)
    SetWidth(1024)

# ↩ (追加)
    # 先端
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-100, -360)
    Select(0u21c4); Copy() # ⇄
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u21a9);  Paste() # ↩
    Move(90, 0)
    # カーブ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(0, 210)
    Select(0u228b); Copy() # ⊋
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    if (input_list[i] == "${input_kanzi_regular}")
        ChangeWeight(3)
        CorrectDirection()
        Scale(107, 102)
    else
        ChangeWeight(-2)
        CorrectDirection()
    endif
    Copy()
    # 合成
    Select(0u21a9) # ↩
    if (input_list[i] == "${input_kanzi_regular}")
        PasteWithOffset(400, -84)
    else
        PasteWithOffset(400, -94)
    endif
    SetWidth(1024)
    RemoveOverlap()
    Simplify()
    Select(65552); Clear() # Temporary glyph

# ↪ (追加)
    Select(0u21a9);  Copy() # ↩
    Select(0u21aa); Paste() # ↪
    HFlip()
    CorrectDirection()
    SetWidth(1024)

# ㎟㎠㎡㎢ (数字拡大)
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(500, 550)
    Select(0u339f); Copy() # ㎟
    Select(65553);  PasteWithOffset(0, 20) # Temporary glyph
    OverlapIntersect()
    Scale(130)

    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-350, 150)
    PasteWithOffset(-350, -40)
    PasteWithOffset(100, -160)
    RemoveOverlap()
    Copy()
    Select(0u339f); PasteInto() # ㎟
    OverlapIntersect()
    Select(0u33a0); PasteInto() # ㎠
    OverlapIntersect()
    Select(0u33a1); PasteInto() # ㎡
    OverlapIntersect()
    Select(0u33a2); PasteInto() # ㎢
    OverlapIntersect()

    Select(65553);  Copy() # Temporary glyph
    Select(0u339f); PasteInto(); SetWidth(1024) # ㎟
    Select(0u33a0); PasteInto(); SetWidth(1024) # ㎠
    Select(0u33a1); PasteInto(); SetWidth(1024) # ㎡
    Select(0u33a2); PasteInto(); SetWidth(1024) # ㎢

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ㎣㎤㎥㎦ (数字拡大)
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(500, 550)
    Select(0u33a3); Copy() # ㎣
    Select(65553);  PasteWithOffset(0, 20) # Temporary glyph
    OverlapIntersect()
    Scale(130)

    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-350, 150)
    PasteWithOffset(-350, -40)
    PasteWithOffset(100, -160)
    RemoveOverlap()
    Copy()
    Select(0u33a3); PasteInto() # ㎣
    OverlapIntersect()
    Select(0u33a4); PasteInto() # ㎤
    OverlapIntersect()
    Select(0u33a5); PasteInto() # ㎥
    OverlapIntersect()
    Select(0u33a6); PasteInto() # ㎦
    OverlapIntersect()

    Select(65553);  Copy() # Temporary glyph
    Select(0u33a3); PasteInto(); SetWidth(1024) # ㎣
    Select(0u33a4); PasteInto(); SetWidth(1024) # ㎤
    Select(0u33a5); PasteInto(); SetWidth(1024) # ㎥
    Select(0u33a6); PasteInto(); SetWidth(1024) # ㎦

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# 🌐 (追加)
    Select(0u25cb); Copy() # ○
    Select(0u1f310); Paste() # 🌐

    Select(0u25cb); Copy() # ○
    Select(65552); Paste() # Temporary glyph
    Scale(55, 100, 478, 338); Copy()
    Select(0u1f310)
    PasteWithOffset(-12, 0)
    PasteWithOffset( 12, 0)

    Select(0u25cb); Copy() # ○
    Select(65552); Paste() # Temporary glyph
    Scale(100, 45, 478, 338); Copy()
    Select(0u1f310)
    if (input_list[i] == "${input_kanzi_regular}")
        PasteWithOffset(0,  328)
        PasteWithOffset(0,  315)
        PasteWithOffset(0,  302)
        PasteWithOffset(0, -302)
        PasteWithOffset(0, -315)
        PasteWithOffset(0, -328)
    else
        PasteWithOffset(0,  328)
        PasteWithOffset(0,  302)
        PasteWithOffset(0, -302)
        PasteWithOffset(0, -328)
    endif

    Select(0u254b); Copy() # ╋
    Select(65552); Paste() # Temporary glyph
    if (input_list[i] == "${input_kanzi_regular}")
        ChangeWeight(-50)
    else
        ChangeWeight(-38)
    endif
    CorrectDirection()
    Copy()
    Select(0u1f310); PasteInto()
    RemoveOverlap()

    Select(0u25cf); Copy() # ●
    Select(65552); Paste() # Temporary glyph
    if (input_list[i] == "${input_kanzi_regular}")
        Scale(99, 99, 478, 338)
    else
        Scale(97, 97, 478, 338)
    endif
    Copy()
    Select(0u1f310); PasteInto()
    SetWidth(1024)
    OverlapIntersect()
    Simplify()

    Select(65552); Clear() # Temporary glyph

# 演算子を下に移動
    math = [0u2243, 0u2248, 0u2252] # ≃≈≒
    j = 0
    while (j < SizeOf(math))
        Select(math[j]);
        Move(0,${y_pos_math})
        SetWidth(512)
        j += 1
    endloop

    math = [0u226a, 0u226b] # ≪≫
    j = 0
    while (j < SizeOf(math))
        Select(math[j]);
        Move(0,${y_pos_math})
        SetWidth(1024)
        j += 1
    endloop

# --------------------------------------------------

# calt 対応 (スロットの確保、後でグリフ上書き)
    j = 0
    k = ${address_calt_kanzi3} # 完成時の最後の異体字のアドレスより大きなアドレスを再利用しないとエラーが出る
    while (j < 52)
        Select(0u0041 + j % 26); Copy() # A
        Select(k); Paste()
        j += 1
        k += 1
    endloop
    j = 0
    while (j < 52)
        Select(0u0061 + j % 26); Copy() # a
        Select(k); Paste()
        j += 1
        k += 1
    endloop

    k = ${address_calt_kanzi2}
    j = 0
    while (j < 128)
        l = 0u00c0 + j % 64
        if (l != 0u00c6\
         && l != 0u00d7\
         && l != 0u00e6\
         && l != 0u00f7)
            Select(l); Copy() # Á
            Select(k); Paste()
            k += 1
        endif
        j += 1
    endloop

    k = ${address_calt_kanzi}
    j = 0
    while (j < 256)
        l = 0u0100 + j % 128
        if (l != 0u0132\
         && l != 0u0133\
         && l != 0u0149\
         && l != 0u0152\
         && l != 0u0153\
         && l != 0u017f)
            Select(l); Copy() # Ā
            Select(k); Paste()
            k += 1
        endif
        j += 1
    endloop

    j = 0
    while (j < 8)
        Select(0u0020); Copy() # Ș-ț のダミー
        Select(k); Paste()
        k += 1
        j += 1
    endloop

    Select(0u0020); Copy() # ẞ のダミー
    Select(k); Paste()
    k += 1
    Select(k); Paste()
    k += 1

    j = 0
    while (j < 40)
        Select(0u0030 + j % 10); Copy() # 0-9
        Select(k); Paste()
        k += 1
        j += 1
    endloop

    Select(0u002d); Copy() # -
    Select(k); Paste()
    k += 1
    Select(k); Paste()
    k += 1

    Select(0u002f); Copy() # solidus
    Select(k); Paste()
    k += 1
    Select(k); Paste()
    k += 1

    Select(0u003c); Copy() # <
    Select(k); Paste()
    k += 1
    Select(k); Paste()
    k += 1

    Select(0u003e); Copy() # >
    Select(k); Paste()
    k += 1
    Select(k); Paste()
    k += 1

    Select(0u005c); Copy() # reverse solidus
    Select(k); Paste()
    k += 1
    Select(k); Paste()
    k += 1

    Select(0u007c); Copy() # |
    Select(k); Paste()
    k += 1

    Select(0u007e); Copy() # ~
    Select(k); Paste()
    k += 1

    Select(0u003a); Copy() # :
    Select(k); Paste()
    k += 1

# ss 対応 (スロットの確保、後でグリフ上書き)
    k = ${address_calt_kanzi4}
    j = 0
    while (j < ${num_ss_glyphs})
        Select(0u0020); Copy() # 避難したグリフのダミー
        Select(k); Paste()
        k += 1
        j += 1
    endloop

# --------------------------------------------------

# ボールド漢字等のウェイト調整
    if ("${draft_flag}" == "false")
        if (input_list[i] == "${input_kanzi_bold}")
            Print("Edit kanzi weight of glyphs (it may take a few minutes)")
            Select(0u2e80, 0u2fdf)
            SelectMore(0u3003) # 〃
            SelectMore(0u3005, 0u3007) # 々〆〇
            SelectMore(0u3021, 0u3029) # 蘇州数字
            SelectMore(0u3038, 0u303d) # 蘇州数字
            SelectMore(0u3400, 0u4dbf)
            SelectMore(0u4e00, 0u9fff)
            SelectMore(0uf900, 0ufaff)
            SelectMore(0u20000, 0u3ffff)
            SelectMore(1115184, 1115492) # 異体字
            SelectMore(${address_visi_kanzi}, ${address_visi_kanzi} + 8) #避難した漢字
            ChangeWeight(${weight_extend_kanzi_bold}); CorrectDirection()
        endif
    endif

# 記号等のウェイト調整
    if ("${draft_flag}" == "false")
        Print("Edit symbol weight of glyphs")
        if (input_list[i] == "${input_kanzi_regular}")
            Select(0u20a0, 0u2120) # 記号類
            SelectMore(0u2122, 0u213a) # 記号類
            SelectMore(0u213c, 0u22ed) # 記号類
            SelectMore(0u22f0, 0u2306) # 記号類
            SelectMore(0u2308, 0u2312) # 記号類
            SelectMore(0u23a7, 0u23cc) # ⎧ -
            SelectMore(0u2640, 0u2642) # ♀♂
            SelectMore(0u2934, 0u2935) # ⤴⤵
            SelectMore(0u29fa, 0u29fb) # ⧺⧻
            ChangeWeight(${weight_extend_kanzi_symbols_regular}); CorrectDirection()
            Select(0u2602, 0u2603) # ☂☃
            SelectMore(0u261c, 0u261f) # ☜-☟
            ChangeWeight(${weight_extend_kanzi_bold}); CorrectDirection()
        else
            Select(0u20a0, 0u2120) # 記号類
            SelectMore(0u2122, 0u213a) # 記号類
            SelectMore(0u213c, 0u22ed) # 記号類
            SelectMore(0u22f0, 0u2306) # 記号類
            SelectMore(0u2308, 0u2312) # 記号類
            SelectMore(0u23a7, 0u23cc) # ⎧ -
            SelectMore(0u2640, 0u2642) # ♀♂
            SelectMore(0u2934, 0u2935) # ⤴⤵
            SelectMore(0u29fa, 0u29fb) # ⧺⧻
            ChangeWeight(${weight_extend_kanzi_symbols_bold}); CorrectDirection()
            Select(0u2602, 0u2603) # ☂☃
            SelectMore(0u261c, 0u261f) # ☜-☟
            ChangeWeight(${weight_extend_kanzi_bold}); CorrectDirection()
        endif
    endif

# Move all glyphs
    if ("${draft_flag}" == "false")
        Print("Move all glyphs")
        SelectWorthOutputting()
        Move(10, 0); SetWidth(-10, 1)
        RemoveOverlap()
    endif

# --------------------------------------------------

# Proccess before saving
    Print("Process before saving")
    if (0 < SelectIf(".notdef"))
        Clear(); DetachAndRemoveGlyphs()
    endif
    RemoveDetachedGlyphs()
    if ("${draft_flag}" == "true")
        SelectWorthOutputting()
        RoundToInt()
    endif

# --------------------------------------------------

# Save modified kanzi font
    Print("Save " + output_list[i])
    Save("${tmpdir}/" + output_list[i])
 #    Generate("${tmpdir}/" + output_list[i], "", 0x04)
 #    Generate("${tmpdir}/" + output_list[i], "", 0x84)
    Close()
    Print("")

    i += 1
endloop

Quit()
_EOT_

################################################################################
# Generate script for modified latin-kana fonts
################################################################################

cat > ${tmpdir}/${modified_latin_kana_generator} << _EOT_
#!$fontforge_command -script

Print("- Generate modified latin-kana fonts -")

# Set parameters
latin_sfd_list  = ["${tmpdir}/${modified_latin_regular}", \\
                   "${tmpdir}/${modified_latin_bold}"]
kana_sfd_list   = ["${tmpdir}/${modified_kana_regular}", \\
                   "${tmpdir}/${modified_kana_bold}"]
output_list = ["${modified_latin_kana_regular}", "${modified_latin_kana_bold}"]

# Begin loop of regular and bold
i = 0
while (i < SizeOf(latin_sfd_list))
# Open latin font
    Print("Open " + latin_sfd_list[i])
    Open(latin_sfd_list[i])

# Merge latin font with kana font
    Print("Merge " + latin_sfd_list[i]:t \\
          + " with " + kana_sfd_list[i]:t)
    MergeFonts(kana_sfd_list[i])

# --------------------------------------------------

# 使用しないグリフクリア
    Print("Remove not used glyphs")
    Select(0, 31); Clear(); DetachAndRemoveGlyphs()

# --------------------------------------------------

# 全角スペース可視化
    Print("Edit zenkaku space")
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste()
    Scale(92);      Copy()
    Select(0u3000); Paste() # Zenkaku space
    Select(0u25a1); Copy() # White square
    Select(0u3000); PasteInto()
    OverlapIntersect()

    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste()
    Move(-440, 440)
    PasteWithOffset(440, 440)
    PasteWithOffset(-440, -440)
    PasteWithOffset(440, -440)
    Copy()
    Select(0u3000); PasteInto() # Zenkaku space
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph

# 半角スペース可視化
    Print("Edit hankaku space")
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(100, 92);  Copy()
    Select(0u0020); Paste() # Space
    Select(0u25a1); Copy() # White square
    Select(0u0020); PasteInto() # Space
    OverlapIntersect()
    Scale(34, 100); Move(-228, 0)

    Select(0u25a0); Copy() # Black square
    Select(0u0020); PasteWithOffset(-150, -510) # Space
    Move(0, ${y_pos_space})
    SetWidth(500)
    OverlapIntersect()

    Copy()
    Select(0u00a0); Paste() # No-break space
    VFlip()
    CorrectDirection()
    SetWidth(500)

    Select(65552); Clear() # Temporary glyph

# ~ (少し上へ移動、M+ のグリフに置き換え)
    Print("Edit ~")
    Select(0uff5e); Copy() # Fullwidth tilde
    Select(0u007e); Paste(); Scale(50)
    Rotate(10)
    if (latin_sfd_list[i] == "${tmpdir}/${modified_latin_regular}")
        ExpandStroke(30, 0, 0, 0, 1); Simplify()
        Move(-220, 190)
    else
        ExpandStroke(38, 0, 0, 0, 1); Simplify()
        Move(-222, 204)
    endif
    SetWidth(500)
    RemoveOverlap()

# g (M+ のグリフを利用してオープンテイルに変更)
    Print("Edit g")
    # 上 ※ q を加工するとずれる可能性があるので注意
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-400, -12)
    PasteWithOffset(-315, 33)
    RemoveOverlap()
    Select(0u0071); Copy() # q
    Select(65552);  PasteInto()
    OverlapIntersect()
    Copy()
    Select(0u0067); Paste() # g
    # 下
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-150, -686)
    PasteWithOffset(167, -601)
    RemoveOverlap()
    Select(0u01f5); Copy() # Latin small letter g with acute
    Select(65552);  PasteInto()
    OverlapIntersect()
    Scale(107, 100)
    if (latin_sfd_list[i] == "${tmpdir}/${modified_latin_regular}")
        ChangeWeight(-4)
    else
        ChangeWeight(-22)
    endif
    CorrectDirection()
    Copy()
    Select(0u0067); # g
    if (latin_sfd_list[i] == "${tmpdir}/${modified_latin_regular}")
        PasteWithOffset(8, 12) # g
    else
        PasteWithOffset(5, 12) # g
        PasteWithOffset(5, 2) # g
    endif
    # 先っぽ追加 ※ y を加工するとずれる可能性があるので注意
    Select(0u25a0); Copy() # Black square
    Select(65552); Paste()
    Scale(15, 25)
    Move(-445, -470)
    Select(0u0079); Copy() # y
    Select(65552); PasteInto()
    OverlapIntersect()
    if (latin_sfd_list[i] == "${tmpdir}/${modified_latin_regular}")
        Scale(101)
        Rotate(12)
        Copy()
        Select(0u0067) # g
        PasteWithOffset(68, 2)
    else
        Scale(99)
        Rotate(13)
        Copy()
        Select(0u0067) # g
        PasteWithOffset(53, -2)
    endif

    SetWidth(500)
    RemoveOverlap()
    Simplify()
    RoundToInt()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

    Select(0u25a0); Copy() # Black square
    Select(0u011d); PasteWithOffset(-150, 490); OverlapIntersect() # ĝ
    Select(0u011f); PasteWithOffset(-150, 490); OverlapIntersect() # ğ
    Select(0u0121); PasteWithOffset(-150, 490); OverlapIntersect() # ġ
    Select(0u0123); PasteWithOffset(-150, 490); OverlapIntersect() # ģ
    Select(0u01e7); PasteWithOffset(-150, 490); OverlapIntersect() # ǧ
    Select(0u1e21); PasteWithOffset(-150, 490); OverlapIntersect() # ḡ
    Select(0u0067); Copy() # g
    Select(0u011d); PasteInto(); SetWidth(500)
    Select(0u011f); PasteInto(); SetWidth(500)
    Select(0u0121); PasteInto(); SetWidth(500)
    Select(0u0123); PasteInto(); SetWidth(500)
    Select(0u01e7); PasteInto(); SetWidth(500)
    Select(0u1e21); PasteInto(); SetWidth(500)
 #    Select(0u01e5) # ǥ
 #    Select(0u01f5) # ǵ
 #    Select(0u0260) # ɠ
 #    Select(0u1d83) # ᶃ
 #    Select(0ua7a1) # ꞡ

    if ("${draft_flag}" == "false") # 前の処理で実行しなかったウェイト調整を実行
        Print("Edit some weight of glyphs")
        if (latin_sfd_list[i] == "${tmpdir}/${modified_latin_regular}")
            Select(0u01f5) # ǵ
            ExpandStroke(${weight_reduce_kana_others_regular}, 0, 0, 0, 2)
            CorrectDirection()
        else
            Select(0u01f5) # ǵ
            ChangeWeight(${weight_reduce_kana_others_bold})
            CorrectDirection()
            Move(0, -9)
        endif
    endif

# 英数フォントの縦横比調整
    if ("${draft_flag}" == "false")
        Print("Edit latin aspect ratio")
        Select(0u0030, 0u0039) # 0 - 9
        SelectMore(0u0041, 0u005a) # A - Z
        SelectMore(0u0061, 0u007a) # a - z
        SelectMore(0u00c0, 0u00d6) # À - Ö
        SelectMore(0u00d8, 0u00f6) # Ø - ö
        SelectMore(0u00f8, 0u0131) # ø - ı
        SelectMore(0u0134, 0u0148) # Ĵ - ň
        SelectMore(0u014a, 0u017e) # Ŋ - ž
        SelectMore(0u018f) # Ə
        SelectMore(0u0192) # ƒ
        SelectMore(0u0198) # Ƙ
        SelectMore(0u01a0, 0u01a1) # Ơ - ơ
        SelectMore(0u01af, 0u01b0) # Ư - ư
        SelectMore(0u01b8, 0u01b9) # Ƹ - ƹ
        SelectMore(0u01c7, 0u01c9) # Ǉ - ǉ
        SelectMore(0u01e6, 0u01e7) # Ǧ - ǧ
        SelectMore(0u01ea, 0u01eb) # Ǫ - ǫ
        SelectMore(0u01fa, 0u021b) # Ǻ - ț
        SelectMore(0u022a, 0u022d) # Ȫ - ȭ
        SelectMore(0u0230, 0u0233) # Ȱ - ȳ
        SelectMore(0u0237) # ȷ
        SelectMore(0u024d) # ɍ
        SelectMore(0u0259) # ə
        SelectMore(0u027b) # ɻ
        SelectMore(0u0298) # ʘ
        SelectMore(0u029a) # ʚ
        SelectMore(0u1e08, 0u1e09) # Ḉ - ḉ
        SelectMore(0u1e0c, 0u1e0f) # Ḍ - ḏ
        SelectMore(0u1e14, 0u1e17) # Ḕ - ḗ
        SelectMore(0u1e1c, 0u1e1d) # Ḝ - ḝ
        SelectMore(0u1e20, 0u1e21) # Ḡ - ḡ
        SelectMore(0u1e24, 0u1e25) # Ḥ - ḥ
        SelectMore(0u1e2a, 0u1e2b) # Ḫ - ḫ
        SelectMore(0u1e2e, 0u1e2f) # Ḯ - ḯ
        SelectMore(0u1e36, 0u1e37) # Ḷ - ḷ
        SelectMore(0u1e3a, 0u1e3b) # Ḻ - ḻ
        SelectMore(0u1e42, 0u1e49) # Ṃ - ṉ
        SelectMore(0u1e4c, 0u1e53) # Ṍ - ṓ
        SelectMore(0u1e5a, 0u1e5b) # Ṛ - ṛ
        SelectMore(0u1e5e, 0u1e69) # Ṟ - ṩ
        SelectMore(0u1e6c, 0u1e6f) # Ṭ - ṯ
        SelectMore(0u1e78, 0u1e7b) # Ṹ - ṻ
        SelectMore(0u1e80, 0u1e85) # Ẁ - ẅ
        SelectMore(0u1e8e, 0u1e8f) # Ẏ - ẏ
        SelectMore(0u1e92, 0u1e93) # Ẓ - ẓ
        SelectMore(0u1e97) # ẗ
        SelectMore(0u1e9e) # ẞ
        SelectMore(0u1ea0, 0u1ef9) # Ạ - ỹ
        SelectMore(${address_dvz_latin}, ${address_dvz_latin} + 17)# 避難したDVZ
        Scale(${width_percent_latin}, ${height_percent_latin}, 250, 0); SetWidth(500)
    endif

# 記号のグリフを加工
    Print("Copy and edit symbols")

# ° (移動) # ℃℉ の前に加工すること
    Select(0u00b0) # °
    Move(-10, 80)
    SetWidth(500)

# Å (漢字フォントを置換)
    Select(0u00c5); Copy() # Å
    Select(0u212b); Paste() # Å
    SetWidth(500)

# ℃ (漢字フォントを置換)
    Select(0u00b0); Copy() # °
    Select(0u2103); Paste() # ℃
    Select(0u0043); Copy() # C
    Select(0u2103) # ℃
    PasteWithOffset(330, 0)
    SetWidth(1000)

# ℉ (追加)
    Select(0u00b0); Copy() # °
    Select(0u2109); Paste() # ℉
    Move(-10, 0)
    Select(0u0046); Copy() # F
    Select(0u2109) # ℉
    PasteWithOffset(340, 0)
    SetWidth(1000)

# ∀ (漢字フォントを置換)
    Select(0u0041); Copy() # A
    Select(0u2200); Paste() # ∀
    VFlip()
    CorrectDirection()
    SetWidth(500)

# ∃ (漢字フォントを置換)
    Select(0u0045); Copy() # E
    Select(0u2203); Paste() # ∃
    HFlip()
    CorrectDirection()
    SetWidth(500)

# 全角形加工 (半角英数記号を全角形にコピーし、下線を追加)
    Print("Copy hankaku to zenkaku and edit")

    # 下線作成
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste()
    Scale(91, 92)
    Select(0u25a1); Copy() # White square
    Select(65552);  PasteInto()
    OverlapIntersect()

    Select(0u25a0); Copy() # Black square
    Select(65552); PasteWithOffset(0, -510)
    Scale(120, 100)
    OverlapIntersect()
    Move(0, ${y_pos_space})
    SetWidth(1000)

    # 縦線作成
    Copy()
    Select(65553); Paste()
    Rotate(-90, 490, 340)
    SetWidth(1000)

    # 半角英数記号を全角形にコピー、加工
    # ! - }
    j = 0
    while (j < 93)
        if (j != 62) # ＿
          if (j == 91)
            Select(${address_visi_latin} + 1) # ｜ (全角縦棒を実線にする)
          else
            Select(0u0021 + j)
          endif
            Copy()
            Select(0uff01 + j); Paste()
            Move(230, 0)
        endif
        if (j == 7 || j == 58 || j == 90) # （ ［ ｛
            Move(100, 0)
        elseif (j == 8 || j == 60 || j == 92) # ） ］ ｝
            Move(-100, 0)
        elseif (j == 11 || j == 13) # ， ．
            Move(-250, 0)
        endif
        j += 1
    endloop

    # 〜
    Select(0uff5e); Rotate(10) # ～

    # ￠ - ￦
    Select(0u00a2);  Copy() # ¢
    Select(0uffe0); Paste() # ￠
    Move(230, 0)
    Select(0u00a3);  Copy() # £
    Select(0uffe1); Paste() # ￡
    Move(230, 0)
    Select(0u00ac);  Copy() # ¬
    Select(0uffe2); Paste() # ￢
    Move(230, 0)
 #    Select(0u00af);  Copy() # ¯
 #    Select(0uffe3); Paste() # ￣
 #    Move(230, 0)
    Select(0u00a6);  Copy() # ¦
    Select(0uffe4); Paste() # ￤
    Move(230, 0)
    Select(0u00a5);  Copy() # ¥
    Select(0uffe5); Paste() # ￥
    Move(230, 0)
    Select(0u20a9);  Copy() # ₩
    Select(0uffe6); Paste() # ￦
    Move(230, 0)

    # ‼
    Select(0u0021); Copy() # !
    Select(0u203c); Paste() # ‼
    Move(30, 0)
    Select(0u203c); PasteWithOffset(450, 0) # ‼

    # ⁇
    Select(0u003F); Copy() # ?
    Select(0u2047); Paste() # ⁇
    Move(10, 0)
    Select(0u2047); PasteWithOffset(430, 0) # ⁇

    # ⁈
    Select(0u003F); Copy() # ?
    Select(0u2048); Paste() # ⁈
    Move(10, 0)
    Select(0u0021); Copy() # !
    Select(0u2048); PasteWithOffset(450, 0) # ⁈

    # ⁉
    Select(0u0021); Copy() # !
    Select(0u2049); Paste() # ⁉
    Move(30, 0)
    Select(0u003F); Copy() # ?
    Select(0u2049); PasteWithOffset(430, 0) # ⁉

# 縦書き形句読点
    hori = [0uff0c, 0u3001, 0u3002] # ，、。
    vert = 0ufe10
    j = 0
    while (j < SizeOf(hori))
        Select(hori[j]); Copy()
        Select(vert + j); Paste()
        Move(580, 533)
        SetWidth(1000)
        j += 1
    endloop

# CJK互換形下線
    Select(0uff3f); Copy() # ＿
    Select(0ufe33); Paste() # ︳
    Rotate(-90, 490, 340)
    SetWidth(1000)

# CJK互換形括弧
    hori = [0u3016, 0u3017] # 〖〗
    vert = 0ufe17 # ︗
    j = 0
    while (j < SizeOf(hori))
        Select(hori[j]); Copy()
        Select(vert + j); Paste()
        Rotate(-90, 490, 340)
        SetWidth(1000)
        j += 1
    endloop

    hori = [0uff08, 0uff09, 0uff5b, 0uff5d,\
            0u3014, 0u3015, 0u3010, 0u3011,\
            0u300a, 0u300b, 0u3008, 0u3009,\
            0u300c, 0u300d, 0u300e, 0u300f] # （）｛｝, 〔〕【】, 《》〈〉, 「」『』
    vert = 0ufe35 # ︵
    j = 0
    while (j < SizeOf(hori))
        Select(hori[j]); Copy()
        Select(vert + j); Paste()
        Rotate(-90, 490, 340)
        SetWidth(1000)
        j += 1
    endloop

    hori = [0uff3b, 0uff3d] # ［］
    vert = 0ufe47 # ﹇
    j = 0
    while (j < SizeOf(hori))
        Select(hori[j]); Copy()
        Select(vert + j); Paste()
        Rotate(-90, 490, 340)
        SetWidth(1000)
        j += 1
    endloop

# 縦書き用全角形他 (vertフィーチャ用)
    Print("Edit vert glyphs")
    k = 0
    hori = [0uff08, 0uff09, 0uff0c, 0uff0e,\
            0uff1a, 0uff1d, 0uff3b, 0uff3d,\
            0uff3f, 0uff5b, 0uff5c, 0uff5d,\
            0uff5e, 0uffe3,\
            0uff0d, 0uff1b, 0uff1c, 0uff1e,\
            0uff5f, 0uff60] # （），．, ：＝［］, ＿｛｜｝, ～￣, －；＜＞, ｟｠
    vert = ${address_vert_latinkana}
    j = 0
    while (j < SizeOf(hori))
        Select(hori[j]); Copy()
        Select(vert + j); Paste()
        if (j == 2 || j == 3) # ， ．
            Move(580, 533)
        else
            Rotate(-90, 490, 340)
        endif
        Copy(); Select(${address_zenhan_latinkana} + k); Paste(); SetWidth(1000); k += 1
        Select(65553);  Copy() # 縦線追加
        Select(vert + j); PasteInto()
        SetWidth(1000)
        j += 1
    endloop

    hori = [0u309b, 0u309c,\
            0uff0f, 0uff3c,\
            0uff01, 0uff02, 0uff03, 0uff04,\
            0uff05, 0uff06, 0uff07, 0uff0a,\
            0uff0b, 0uff10, 0uff11, 0uff12,\
            0uff13, 0uff14, 0uff15, 0uff16,\
            0uff17, 0uff18, 0uff19, 0uff1f,\
            0uff20, 0uff21, 0uff22, 0uff23,\
            0uff24, 0uff25, 0uff26, 0uff27,\
            0uff28, 0uff29, 0uff2a, 0uff2b,\
            0uff2c, 0uff2d, 0uff2e, 0uff2f,\
            0uff30, 0uff31, 0uff32, 0uff33,\
            0uff34, 0uff35, 0uff36, 0uff37,\
            0uff38, 0uff39, 0uff3a, 0uff3e,\
            0uff40, 0uff41, 0uff42, 0uff43,\
            0uff44, 0uff45, 0uff46, 0uff47,\
            0uff48, 0uff49, 0uff4a, 0uff4b,\
            0uff4c, 0uff4d, 0uff4e, 0uff4f,\
            0uff50, 0uff51, 0uff52, 0uff53,\
            0uff54, 0uff55, 0uff56, 0uff57,\
            0uff58, 0uff59, 0uff5a, 0uffe0,\
            0uffe1, 0uffe2, 0uffe4, 0uffe5,\
            0uffe6,\
            0u203c, 0u2047, 0u2048, 0u2049] # 濁点、半濁点, Solidus、Reverse solidus, ！-￦, ‼⁇⁈⁉
    vert += j
    j = 0
    while (j < SizeOf(hori))
        Select(hori[j]); Copy()
        Select(vert + j); Paste()
        if (j == 0 || j == 1) # ゛゜
            Move(580, -533)
        elseif (j == 2 || j == 3) # ／＼
            Rotate(-90, 490, 340)
            VFlip()
            CorrectDirection()
        elseif (hori[j] == 0uff46\
             || hori[j] == 0uff4c) # ｆｌ
            Move(0, ${y_pos_vert_1})
        elseif (hori[j] == 0uff42\
             || hori[j] == 0uff44\
             || hori[j] == 0uff48\
             || hori[j] == 0uff4b) # ｂｄｈｋ
            Move(0, ${y_pos_vert_2})
        elseif (hori[j] == 0uff49\
             || hori[j] == 0uff54) # ｉｔ
            Move(0, ${y_pos_vert_3})
        elseif (hori[j] == 0uff41\
             || hori[j] == 0uff43\
             || hori[j] == 0uff45\
             || hori[j] == 0uff4d\
             || hori[j] == 0uff4e\
             || hori[j] == 0uff4f\
             || hori[j] == 0uff52\
             || hori[j] == 0uff53\
             || hori[j] == 0uff55\
             || hori[j] == 0uff56\
             || hori[j] == 0uff57\
             || hori[j] == 0uff58\
             || hori[j] == 0uff5a\
             || hori[j] == 0uffe0) # ａｃｅｍｎｏｒｓｕｖｗｘｚ￠
            Move(0, ${y_pos_vert_4})
        elseif (hori[j] == 0uff4a) # ｊ
            Move(0, ${y_pos_vert_5})
        elseif (hori[j] == 0uff50\
             || hori[j] == 0uff51\
             || hori[j] == 0uff59) # ｐｑｙ
            Move(0, ${y_pos_vert_6})
        elseif (hori[j] == 0uff47) # ｇ
            Move(0, ${y_pos_vert_7})
        endif
        Copy(); Select(${address_zenhan_latinkana} + k); Paste(); SetWidth(1000); k += 1 # 避難所
        Select(65553);  Copy() # 縦線追加
        Select(vert + j); PasteInto()
        SetWidth(1000)
        j += 1
    endloop

    vert += j
    Select(0u2702); Copy() # ✂
    Select(vert); Paste()
    Rotate(-90, 490, 340)
    SetWidth(1000)

# 横書き全角形に下線追加
    j = 0 # ！ - ｠
    while (j < 96)
        Select(0uff01 + j)
        Copy(); Select(${address_zenhan_latinkana} + k); Paste(); SetWidth(1000); k += 1
        Select(65552); Copy()
        Select(0uff01 + j); PasteInto()
        SetWidth(1000)
        j += 1
    endloop

# 保管しているDVZに下線追加
    j = 0
    while (j < 3)
        Select(${address_dvz_latinkana} + j)
        SetWidth(500)
        Copy()
        Select(${address_dvz_latinkana} + 9 + j); Paste()
        SetWidth(500)
        Select(${address_dvz_latinkana} + 3 + j); Paste()
        Move(230, 0)
        SetWidth(1000)
        Copy()
        Select(${address_dvz_latinkana} + 6 + j); Paste()
        SetWidth(1000)
        Select(${address_dvz_latinkana} + 12 + j); Paste()
        Select(${address_dvz_latinkana} + 15 + j); Paste()
        Select(65552); Copy() # 下線追加
        Select(${address_dvz_latinkana} + 12 + j); PasteInto()
        SetWidth(1000)
        Select(65553); Copy() # 縦線追加
        Select(${address_dvz_latinkana} + 15 + j); PasteInto()
        SetWidth(1000)
        j += 1
    endloop

# 半角文字に下線を追加
    Print("Edit hankaku")

    # 下線作成
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(100, 92)
    Select(0u25a1); Copy() # White square
    Select(65553);  PasteInto()
    OverlapIntersect()
    Scale(34, 100); Move(-228, 0)

    Select(0u25a0); Copy() # Black square
    Select(65553); PasteWithOffset(-150, -510)
    Move(0, ${y_pos_space})
    OverlapIntersect()

    j = 0
    while (j < 63)
        Select(0uff61 + j) # ｡-ﾟ
        Copy(); Select(${address_zenhan_latinkana} + k); Paste(); SetWidth(500); k += 1
        Select(65553); Copy()
        Select(0uff61 + j); PasteInto() # ｡-ﾟ
        SetWidth(500)
        j += 1
    endloop

# 横書き全角形に下線追加 (続き)
    Print("Edit zenkaku")
    j = 0 # ￠ - ￦
    while (j < 7)
        Select(0uffe0 + j)
        Copy(); Select(${address_zenhan_latinkana} + k); Paste(); SetWidth(1000); k += 1
        Select(65552); Copy()
        Select(0uffe0 + j); PasteInto()
        SetWidth(1000)
        j += 1
    endloop

    hori = [0u309b, 0u309c, 0u203c, 0u2047,\
            0u2048, 0u2049] # ゛゜‼⁇⁈⁉
    j = 0
    while (j < SizeOf(hori))
        Select(hori[j])
        Copy(); Select(${address_zenhan_latinkana} + k); Paste(); SetWidth(1000); k += 1
        Select(65552);  Copy()
        Select(hori[j]); PasteInto()
        SetWidth(1000)
        j += 1
    endloop

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# 保管している、改変されたグリフを元のグリフに置き換え
    Select(${address_visi_latin} + 1); Copy() # |
    Select(${address_zenhan_latinkana} + 10); Paste() # 縦書き
    Move(230, 0)
    Rotate(-90, 490, 340)
    SetWidth(1000)

 #    Select(${address_zenhan_latinkana} + 200); Paste() # 全角縦棒を破線にする場合有効にする
 #    Move(230, 0) # ただし ss06 に対応する処理の追加が必要
 #    SetWidth(1000)

    Select(${address_visi_kana}); Copy() # ゠
    Select(${address_zenhan_latinkana} + k); Paste() # 縦書き
    Rotate(-90, 490, 340)
    SetWidth(1000)

# --------------------------------------------------

# 漢字用フォントで上書きするグリフをクリア
    Print("Remove some glyphs")
    Select(0u00bc, 0u00be); Clear() # ¼½¾
    Select(0u2030); Clear() # ‰
    Select(0u2113); Clear() # ℓ
    Select(0u2205); Clear() # ∅
    Select(0u2208); Clear() # ∈
    Select(0u221d, 0u221e); Clear() # ∝∞
 #    Select(0u2225, 0u2226); Clear() # ∥∦
    Select(0u222b); Clear() # ∫
    Select(0u2264, 0u2265); Clear() # ≤≥
    Select(0u2295, 0u229d); Clear() # ⊕-⊝
    Select(0u2248); Clear() # ≈
    Select(0u3004); Clear() # 〄
    Select(0u3231, 0u3232); Clear() # ㈱㈲
    Select(0u339c, 0u33a6); Clear() # ㎜ - ㎦

# em値を1024に変更
    Print("Edit em value")
    ScaleToEm(${typo_ascent1024}, ${typo_descent1024})
    SetOS2Value("WinAscent",             ${win_ascent1024}) # Windows用(この範囲外は描画されない)
    SetOS2Value("WinDescent",            ${win_descent1024})
    SetOS2Value("TypoAscent",            ${typo_ascent1024}) # 組版用(em値と合わせる)
    SetOS2Value("TypoDescent",          -${typo_descent1024})
    SetOS2Value("TypoLineGap",           ${typo_linegap1024})
    SetOS2Value("HHeadAscent",           ${hhea_ascent1024}) # Mac用
    SetOS2Value("HHeadDescent",         -${hhea_descent1024})
    SetOS2Value("HHeadLineGap",          ${hhea_linegap1024})

# 罫線、ブロックを少し移動 (em値変更でのズレ修正)
    Print("Move box drawing and block")
    Select(0u2500, 0u259f)
    Move(0, ${y_pos_em_revice})
    Scale(102, 100, 256, 0) # 横幅を少し拡大

# Move all glyphs
 #    if ("${draft_flag}" == "false")
 #        Print("Move all glyphs")
 #        SelectWorthOutputting()
 #        Move(9, 0); SetWidth(-9, 1)
 #        RemoveOverlap()
 #    endif

# --------------------------------------------------

# Proccess before saving
    Print("Process before saving")
    if (0 < SelectIf(".notdef"))
        Clear(); DetachAndRemoveGlyphs()
    endif
    RemoveDetachedGlyphs()
    if ("${draft_flag}" == "true")
        SelectWorthOutputting()
        RoundToInt()
    endif

# --------------------------------------------------

# Save modified latin-kana font
    Print("Save " + output_list[i])
    Save("${tmpdir}/" + output_list[i])
 #    Generate("${tmpdir}/" + output_list[i], "", 0x04)
 #    Generate("${tmpdir}/" + output_list[i], "", 0x84)
    Close()
    Print("")

    i += 1
endloop

Quit()
_EOT_

################################################################################
# Generate script for custom fonts
################################################################################

cat > ${tmpdir}/${custom_font_generator} << _EOT_
#!$fontforge_command -script

Print("- Generate custom fonts -")

# Set parameters
latin_kana_sfd_list = ["${tmpdir}/${modified_latin_kana_regular}", \\
                       "${tmpdir}/${modified_latin_kana_bold}"]
kanzi_sfd_list      = ["${tmpdir}/${modified_kanzi_regular}", \\
                       "${tmpdir}/${modified_kanzi_bold}"]
fontfamily        = "${font_familyname}"
fontfamilysuffix  = "${font_familyname_suffix}"
fontstyle_list    = ["Regular", "Bold"]
fontweight_list   = [400,       700]
panoseweight_list = [5,         8]
copyright         = "${copyright9}" \\
                  + "${copyright2}" \\
                  + "${copyright3}" \\
                  + "${copyright4}" \\
                  + "${copyright0}"
version           = "${font_version}"

# Begin loop of regular and bold
i = 0
while (i < SizeOf(fontstyle_list))
# Open new file
    Print("Create new file")
    New()

# Set encoding to Unicode-bmp
    Reencode("unicode")

# Set configuration
    if (fontfamilysuffix != "")
        SetFontNames(fontfamily + fontfamilysuffix + "-" + fontstyle_list[i], \\
                     fontfamily + " " + fontfamilysuffix, \\
                     fontfamily + " " + fontfamilysuffix + " " + fontstyle_list[i], \\
                     fontstyle_list[i], \\
                     copyright, version)
    else
        SetFontNames(fontfamily + "-" + fontstyle_list[i], \\
                     fontfamily, \\
                     fontfamily + " " + fontstyle_list[i], \\
                     fontstyle_list[i], \\
                     copyright, version)
    endif
    SetTTFName(0x409, 2, fontstyle_list[i])
    SetTTFName(0x409, 3, "FontForge ${fontforge_version} : " + "FontTools ${ttx_version} : " + \$fullname + " : " + Strftime("%d-%m-%Y", 0))
    ScaleToEm(${typo_ascent1024}, ${typo_descent1024})
    SetOS2Value("Weight", fontweight_list[i]) # Book or Bold
    SetOS2Value("Width",                   5) # Medium
    SetOS2Value("FSType",                  0)
    SetOS2Value("VendorID",   "${vendor_id}")
    SetOS2Value("IBMFamily",            2057) # SS Typewriter Gothic
    SetOS2Value("WinAscentIsOffset",       0)
    SetOS2Value("WinDescentIsOffset",      0)
    SetOS2Value("TypoAscentIsOffset",      0)
    SetOS2Value("TypoDescentIsOffset",     0)
    SetOS2Value("HHeadAscentIsOffset",     0)
    SetOS2Value("HHeadDescentIsOffset",    0)
    SetOS2Value("WinAscent",             ${win_ascent1024}) # Windows用(この範囲外は描画されない)
    SetOS2Value("WinDescent",            ${win_descent1024})
    SetOS2Value("TypoAscent",            ${typo_ascent1024}) # 組版用(em値と合わせる)
    SetOS2Value("TypoDescent",          -${typo_descent1024})
    SetOS2Value("TypoLineGap",           ${typo_linegap1024})
    SetOS2Value("HHeadAscent",           ${hhea_ascent1024}) # Mac用
    SetOS2Value("HHeadDescent",         -${hhea_descent1024})
    SetOS2Value("HHeadLineGap",          ${hhea_linegap1024})
    SetPanose([2, 11, panoseweight_list[i], 9, 2, 2, 3, 2, 2, 7])

# Merge latin font with kana font
    Print("Merge " + latin_kana_sfd_list[i]:t \\
          + " with " + kanzi_sfd_list[i]:t)
    MergeFonts(latin_kana_sfd_list[i])
    MergeFonts(kanzi_sfd_list[i])

# --------------------------------------------------

# 使用しないグリフクリア
    Print("Remove not used glyphs")
    Select(0, 31); Clear(); DetachAndRemoveGlyphs()

# Clear kerns, position, substitutions
 #    Print("Clear kerns, position, substitutions")
 #    RemoveAllKerns()
 #
 #    lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups); j = 0
 #    while (j < numlookups)
 #        Print("Remove " + lookups[j])
 #        RemoveLookup(lookups[j]); j++
 #    endloop

 #    lookups = GetLookups("GPOS"); numlookups = SizeOf(lookups); j = 0
 #    while (j < numlookups)
 #        Print("Remove GPOS_" + lookups[j])
 #        RemoveLookup(lookups[j]); j++
 #    endloop

# Clear instructions, hints
 #    Print("Clear instructions, hints")
 #    SelectWorthOutputting()
 #    ClearInstrs()
 #    ClearHints()

# --------------------------------------------------

# Proccess before saving
    Print("Process before saving")
    if (0 < SelectIf(".notdef"))
        Clear(); DetachAndRemoveGlyphs()
    endif
    RemoveDetachedGlyphs()
    SelectWorthOutputting()
 #    RemoveOverlap()
    RoundToInt()
 #    AutoHint()
 #    AutoInstr()

# --------------------------------------------------

# Save custom font
    if (fontfamilysuffix != "")
        Print("Save " + fontfamily + fontfamilysuffix + "-" + fontstyle_list[i] + ".ttf")
        Generate(fontfamily + fontfamilysuffix + "-" + fontstyle_list[i] + ".ttf", "", 0x04)
 #        Generate(fontfamily + fontfamilysuffix + "-" + fontstyle_list[i] + ".ttf", "", 0x84)
    else
        Print("Save " + fontfamily + "-" + fontstyle_list[i] + ".ttf")
        Generate(fontfamily + "-" + fontstyle_list[i] + ".ttf", "", 0x04)
 #        Generate(fontfamily + "-" + fontstyle_list[i] + ".ttf", "", 0x84)
    endif
    Close()
    Print("")

    i += 1
endloop

Quit()
_EOT_

################################################################################
# Generate script for modified Nerd fonts
################################################################################

cat > ${tmpdir}/${modified_nerd_generator} << _EOT_
#!$fontforge_command -script

Print("- Generate modified Nerd fonts -")

# Set parameters
input_list  = ["${input_nerd}"]
output_list = ["${modified_nerd}"]

# Begin loop of regular and bold
i = 0
while (i < SizeOf(input_list))
# Open latin font
    Print("Open " + input_list[i])
    Open(input_list[i])
    SelectWorthOutputting()
    UnlinkReference()
    ScaleToEm(${typo_ascent1024}, ${typo_descent1024}) # OS/2テーブルを書き換えないと指定したem値にならない
    SetOS2Value("WinAscent",             ${win_ascent1024}) # Windows用(この範囲外は描画されない)
    SetOS2Value("WinDescent",            ${win_descent1024})
    SetOS2Value("TypoAscent",            ${typo_ascent1024}) # 組版用(em値と合わせる)
    SetOS2Value("TypoDescent",          -${typo_descent1024})
    SetOS2Value("TypoLineGap",           ${typo_linegap1024})
    SetOS2Value("HHeadAscent",           ${hhea_ascent1024}) # Mac用
    SetOS2Value("HHeadDescent",         -${hhea_descent1024})
    SetOS2Value("HHeadLineGap",          ${hhea_linegap1024})

# --------------------------------------------------

# 使用しないグリフクリア
    Print("Remove not used glyphs")
    Select(0, 31); Clear(); DetachAndRemoveGlyphs()
    Select(1114112, 1114114); Clear(); DetachAndRemoveGlyphs()

# Clear kerns, position, substitutions
    Print("Clear kerns, position, substitutions")
    RemoveAllKerns()

    lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups); j = 0
    while (j < numlookups)
        Print("Remove GSUB_" + lookups[j])
        RemoveLookup(lookups[j]); j++
    endloop

    lookups = GetLookups("GPOS"); numlookups = SizeOf(lookups); j = 0
    while (j < numlookups)
        Print("Remove GPOS_" + lookups[j])
        RemoveLookup(lookups[j]); j++
    endloop

# Clear instructions, hints
    Print("Clear instructions, hints")
    SelectWorthOutputting()
    ClearInstrs()
    ClearHints()

# Proccess before editing
    if ("${draft_flag}" == "false")
        Print("Process before editing (it may take a few minutes)")
        SelectWorthOutputting()
        RemoveOverlap()
        CorrectDirection()
    endif

# --------------------------------------------------

# 全て少し移動
    Print("Move all glyphs")
    SelectWorthOutputting(); Move(0, 30)

# IEC Power Symbols
    Print("Edit IEC Power Symbols")
    Select(0u23fb, 0u23fe); Scale(88); Move(-20, 0); SetWidth(1024)
    Select(0u2630);         Scale(88); Move(-20, 0); SetWidth(1024)
    Select(0u26a1);         Scale(88); Move(-20, 0); SetWidth(1024)
    Select(0u276c, 0u2771) #; Scale(88)
    Move(-20, 0); SetWidth(1024)
    Select(0u2b58);         Scale(88); Move(-20, 0); SetWidth(1024)

# Pomicons
    Print("Edit Pomicons")
    Select(0ue000, 0ue00a); Scale(91)
    Move(-20, 0); SetWidth(1024)

# Powerline Glyphs (Win(HHead)Ascent と Win(HHead)Descent の長さより少し大きくして位置を合わす)
    Print("Edit Powerline Glyphs")
    Select(0ue0a0, 0ue0a3)
    SelectMore(0ue0b0, 0ue0c8)
    SelectMore(0ue0ca)
    SelectMore(0ue0cc, 0ue0d2)
    SelectMore(0ue0d4)
    Move(0, -30)
    Move(0, ${y_pos_em_revice}) # em値変更でのズレ修正
    Select(0ue0b0, 0ue0b1); Scale(70,  ${height_percent_pl}, 0,    ${height_center_pl}); Move(0, ${y_pos_pl}); SetWidth(512)
    Select(0ue0b2, 0ue0b3); Scale(70,  ${height_percent_pl}, 1024, ${height_center_pl}); Move(-512, ${y_pos_pl}); SetWidth(512)
    Select(0ue0b4);         Scale(80,  ${height_percent_pl}, 0,    ${height_center_pl}); Move(0, ${y_pos_pl}); SetWidth(512)
    Select(0ue0b5);         Scale(95,  ${height_percent_pl}, 0,    ${height_center_pl}); Move(0, ${y_pos_pl}); SetWidth(512)
    Select(0ue0b6);         Scale(80,  ${height_percent_pl}, 1024, ${height_center_pl}); Move(-512, ${y_pos_pl}); SetWidth(512)
    Select(0ue0b7);         Scale(95,  ${height_percent_pl}, 1024, ${height_center_pl}); Move(-512, ${y_pos_pl}); SetWidth(512)
    Select(0ue0b8, 0ue0b9); Scale(50,  ${height_percent_pl}, 0,    ${height_center_pl}); Move(0, ${y_pos_pl}); SetWidth(512)
    Select(0ue0ba, 0ue0bb); Scale(50,  ${height_percent_pl}, 1024, ${height_center_pl}); Move(-512, ${y_pos_pl}); SetWidth(512)
    Select(0ue0bc, 0ue0bd); Scale(50,  ${height_percent_pl}, 0,    ${height_center_pl}); Move(0, ${y_pos_pl}); SetWidth(512)
    Select(0ue0be, 0ue0bf); Scale(50,  ${height_percent_pl}, 1024, ${height_center_pl}); Move(-512, ${y_pos_pl}); SetWidth(512)
    Select(0ue0c0, 0ue0c1); Scale(95,  ${height_percent_pl}, 0,    ${height_center_pl}); Move(0, ${y_pos_pl}); SetWidth(1024)
    Select(0ue0c2, 0ue0c3); Scale(95,  ${height_percent_pl}, 1024, ${height_center_pl}); Move(0, ${y_pos_pl}); SetWidth(1024)
    Select(0ue0c4);         Scale(105, ${height_percent_pl}, 0,    ${height_center_pl}); Move(0, ${y_pos_pl}); SetWidth(1024)
    Select(0ue0c5);         Scale(105, ${height_percent_pl}, 1024, ${height_center_pl}); Move(0, ${y_pos_pl}); SetWidth(1024)
    Select(0ue0c6);         Scale(105, ${height_percent_pl}, 0,    ${height_center_pl}); Move(0, ${y_pos_pl}); SetWidth(1024)
    Select(0ue0c7);         Scale(105, ${height_percent_pl}, 1024, ${height_center_pl}); Move(0, ${y_pos_pl}); SetWidth(1024)
    Select(0ue0c8);         Scale(95,  ${height_percent_pl}, 0,    ${height_center_pl}); Move(0, ${y_pos_pl}); SetWidth(1024)
    Select(0ue0ca);         Scale(95,  ${height_percent_pl}, 1024, ${height_center_pl}); Move(0, ${y_pos_pl}); SetWidth(1024)
    Select(0ue0cc, 0ue0cd); Scale(105, ${height_percent_pl}, 0,    ${height_center_pl}); Move(0, ${y_pos_pl}); SetWidth(1024)
    Select(0ue0ce, 0ue0d0); Move(0, ${y_pos_pl}); SetWidth(1024)
    Select(0ue0d1);         Scale(105, ${height_percent_pl}, 0,    ${height_center_pl}); Move(0, ${y_pos_pl}); SetWidth(1024)
    Select(0ue0d2);         Scale(105, ${height_percent_pl}, 0,    ${height_center_pl}); Move(0, ${y_pos_pl}); SetWidth(1024)
    Select(0ue0d4);         Scale(105, ${height_percent_pl}, 1024, ${height_center_pl}); Move(0, ${y_pos_pl});SetWidth(1024)

# Font Awesome Extension
    Print("Edit Font Awesome Extension")
    Select(0ue200, 0ue2a9); Scale(88)
    Move(-20, 0); SetWidth(1024)

# Weather Icons
    Print("Edit Weather Icons")
    Select(0ue339)
    SelectMore(0ue340, 0ue341)
    SelectMore(0ue344)
    SelectMore(0ue348, 0ue349)
    SelectMore(0ue34e)
    SelectMore(0ue350)
    SelectMore(0ue353, 0ue35b)
    SelectMore(0ue381, 0ue3a9)
    SelectMore(0ue3af, 0ue3bb)
    SelectMore(0ue3c4, 0ue3e3)
    Scale(88)

    Select(0ue300, 0ue3e3)
    Move(-20, 0); SetWidth(1024)

# Seti-UI + Customs
    Print("Edit Seti-UI + Costoms")
    Select(0ue5fa, 0ue6b2); Scale(88)
    Move(-20, 0); SetWidth(1024)

# Devicons
    Print("Edit Devicons")
    Select(0ue700, 0ue7bc)
    SelectMore(0ue7c4, 0ue7c5)
    Scale(88)

    Select(0ue700, 0ue7c5)
    Move(-20, 0); SetWidth(1024)

# Codicons
    Print("Edit Codicons")
    Select(0uea60, 0uebeb); Scale(88)
    Move(-20, 0); SetWidth(1024)
    Select(0uea89)
    SelectMore(0uea8d)
    SelectMore(0uea8e)
    SelectMore(0ueac8)
    SelectMore(0ueaca)
    SelectMore(0ueacb)
    SelectMore(0ueb0a)
    SelectMore(0ueb4f)
    DetachAndRemoveGlyphs(); Clear() # 元々存在しないグリフをクリア

# Font Awesome
    Print("Edit Font Awesome")
    Select(0uf000, 0uf2e0); Scale(88)
    Move(-20, 0); SetWidth(1024)
    Select(0uf00f)
    SelectMore(0uf01f)
    SelectMore(0uf020)
    SelectMore(0uf03f)
    SelectMore(0uf04f)
    SelectMore(0uf05f)
    SelectMore(0uf06f)
    SelectMore(0uf07f)
    SelectMore(0uf08f)
    SelectMore(0uf09f)
    SelectMore(0uf0af)
    SelectMore(0uf0b3, 0uf0bf)
    SelectMore(0uf0cf)
    SelectMore(0uf0df)
    SelectMore(0uf0ef)
    SelectMore(0uf0ff)
    SelectMore(0uf10f)
    SelectMore(0uf11f)
    SelectMore(0uf12f)
    SelectMore(0uf13f)
    SelectMore(0uf14f)
    SelectMore(0uf15f)
    SelectMore(0uf16f)
    SelectMore(0uf17f)
    SelectMore(0uf18f)
    SelectMore(0uf19f)
    SelectMore(0uf1af)
    SelectMore(0uf1bf)
    SelectMore(0uf1cf)
    SelectMore(0uf1df)
    SelectMore(0uf1ef)
    SelectMore(0uf1ff)
    SelectMore(0uf20f)
    SelectMore(0uf21f)
    SelectMore(0uf220)
    SelectMore(0uf23f)
    SelectMore(0uf24f)
    SelectMore(0uf25f)
    SelectMore(0uf26f)
    SelectMore(0uf27f)
    SelectMore(0uf28f)
    SelectMore(0uf29f)
    SelectMore(0uf2af)
    SelectMore(0uf2bf)
    SelectMore(0uf2cf)
    SelectMore(0uf2df)
    DetachAndRemoveGlyphs(); Clear() # 元々存在しないグリフをクリア

# Font Logos
    Print("Edit Font Logos")
    Select(0uf300, 0uf372); Scale(88)
    Move(-20, 0); SetWidth(1024)

# Octicons
    Print("Edit Octicons")
    Select(0uf400, 0uf533); Scale(88)
    Move(-20, 0); SetWidth(1024)

# Material Design Icons
    Print("Edit Material Design Icons")
 #    Select(0uf500, 0uf8ff); Scale(83) # v2.3.3まで 互換用
 #    SetWidth(1024)
    Select(0uf0001, 0uf1af0); Scale(88)
    Move(-20, 0)
    SetWidth(1024)

# ◢◣◤◥
    Select(0ue0b8); Copy() # 
    Select(0u25e3); Paste() # ◣
    Scale(161, 66, -10, -263)
    Move(5, 185)
    SetWidth(1024)
    Select(0ue0ba); Copy() # 
    Select(0u25e2); Paste() # ◢
    Scale(161, 66, 522, -263)
    Move(507, 185)
    SetWidth(1024)
    Select(0ue0bc); Copy() # 
    Select(0u25e4); Paste() # ◤
    Scale(161, 66, -10, 1009)
    Move(5, -248)
    SetWidth(1024)
    Select(0ue0be); Copy() # 
    Select(0u25e5); Paste() # ◥
    Scale(161, 66, 522, 1009)
    Move(507, -248)
    SetWidth(1024)

#  (Mac用)
    Select(0ue711); Copy() # 
    Select(0uf8ff); Paste() #  (私用領域)

# --------------------------------------------------

# Proccess before saving
    Print("Process before saving")
    if (0 < SelectIf(".notdef"))
        Clear(); DetachAndRemoveGlyphs()
    endif
    RemoveDetachedGlyphs()
    SelectWorthOutputting()
    RoundToInt()

# --------------------------------------------------

# Save modified nerd fonts (sfdで保存するとmergeしたときに一部のグリフが消える)
    Print("Save " + output_list[i])
 #    Save("${tmpdir}/" + output_list[i])
    Generate("${tmpdir}/" + output_list[i], "", 0x04)
 #    Generate("${tmpdir}/" + output_list[i], "", 0x84)
    Close()
    Print("")

    i += 1
endloop

Quit()
_EOT_

################################################################################
# Generate script to merge with Nerd fonts
################################################################################
cat > ${tmpdir}/${merged_nerd_generator} << _EOT_
#!$fontforge_command -script

# Set parameters
input_nerd = "${tmpdir}/${modified_nerd}"
copyright         = "${copyright9}" \\
                  + "${copyright2}" \\
                  + "${copyright3}" \\
                  + "${copyright4}" \\
                  + "${copyright5}" \\
                  + "${copyright0}"

usage = "Usage: ${merged_nerd_generator} fontfamily-fontstyle.ttf ..."

# Get arguments
if (\$argc == 1)
    Print(usage)
    Quit()
endif

Print("- Merge with Nerd fonts -")

# Begin loop
i = 1
while (i < \$argc)

# Check filename
    input_ttf = \$argv[i]
    input     = input_ttf:t:r # :t:r ファイル名のみ抽出
    if (input_ttf:t:e != "ttf") # :t:e 拡張子のみ抽出
        Print(usage)
        Quit()
    endif

    hypen_index = Strrstr(input, '-') # '-'を後ろから探す('-'から前の文字数を取得)
    if (hypen_index == -1)
        Print(usage)
        Quit()
    endif

# Get parameters
    input_family = Strsub(input, 0, hypen_index) # ファミリー名を取得
    input_style  = Strsub(input, hypen_index + 1) # スタイル名を取得

    output_family = input_family
    output_style = input_style

# Open file and set configuration
    Print("Open " + input_ttf)
    Open(input_ttf)

    SetFontNames("", "", "", "", copyright)

# Merge with nerd fonts
    Print("Merge " + input_ttf \\
          + " with " + input_nerd:t)
    MergeFonts(input_nerd)

# --------------------------------------------------

# ブロック要素を加工 (Powerline対応)
    Print("Edit box drawing and block")
    Select(0u2580, 0u259f)
    Scale(100, ${height_percent_block}, 0, ${height_center_pl}) # Powerlineに合わせて縦を縮小
    Move(0, ${y_pos_pl})

    Select(0ue0d1); RemoveOverlap(); Copy() # 
    Select(65552);  Paste()
    PasteWithOffset(-20, 0)
    RemoveOverlap()
    Copy()
    j = 0
    while (j < 32)
        Select(0u2580 + j); PasteInto()
        if ("${draft_flag}" == "false")
            OverlapIntersect()
        endif
        SetWidth(512)
        j += 1
    endloop

    Select(65552); Clear() # Temporary glyph

# --------------------------------------------------

# Proccess before saving
    Print("Process before saving")
    if (0 < SelectIf(".notdef"))
        Clear(); DetachAndRemoveGlyphs()
    endif
    RemoveDetachedGlyphs()
    SelectWorthOutputting()
 #    RemoveOverlap()
    RoundToInt()
 #    AutoHint()
 #    AutoInstr()

# --------------------------------------------------

# Save merged font
    Print("Save " + output_family + "-" + output_style + ".ttf")
    Generate(output_family + "-" + output_style + ".ttf", "", 0x04)
 #    Generate(output_family + "-" + output_style + ".ttf", "", 0x84)
    Close()
    Print("")

    i += 1
endloop

Quit()
_EOT_

################################################################################
# Generate script to modify font parameters
################################################################################
cat > ${tmpdir}/${parameter_modificator} << _EOT_
#!$fontforge_command -script

usage = "Usage: ${parameter_modificator} fontfamily-fontstyle.ttf ..."

# Get arguments
if (\$argc == 1)
    Print(usage)
    Quit()
endif

Print("- Modify font parameters -")

# Begin loop
i = 1
while (i < \$argc)

# Check filename
    input_ttf = \$argv[i]
    input     = input_ttf:t:r # :t:r ファイル名のみ抽出
    if (input_ttf:t:e != "ttf") # :t:e 拡張子のみ抽出
        Print(usage)
        Quit()
    endif

    hypen_index = Strrstr(input, '-') # '-'を後ろから探す('-'から前の文字数を取得)
    if (hypen_index == -1)
        Print(usage)
        Quit()
    endif

# Open file and set configuration
    Print("Open " + input_ttf)
    Open(input_ttf)

# --------------------------------------------------

# 失われたLookupを追加
    # vert
    Print("Add vert lookups")
    Select(0u3041) # ぁ
    lookups = GetPosSub("*") # フィーチャを取り出す

    # ✂
    Select(${address_vert_X}) # グリフの数によって変更の必要あり
    glyphName = GlyphInfo("Name")
    Select(0u2702) # ✂
    AddPosSub(lookups[0][0], glyphName) # vertフィーチャを追加

    # 組文字 (㍉-㍻)
    hori = [0u3349, 0u3314, 0u334d, 0u3327,\
            0u3336, 0u3351, 0u330d, 0u3326,\
            0u332b, 0u334a, 0u3322, 0u3303,\
            0u3318, 0u3357, 0u3323, 0u333b,\
            0u337e, 0u337d, 0u337c, 0u337b]
    vert = ${address_vert_mm} # グリフの数によって変更の必要あり
    j = 0
    while (j < SizeOf(hori))
        Select(vert + j)
        glyphName = GlyphInfo("Name")
        Select(hori[j])
        AddPosSub(lookups[0][0], glyphName)
        j += 1
    endloop
    # 組文字 (㍿-㋿)
    hori = [0u337f, 0u3316, 0u3305, 0u3333,\
            0u334e, 0u3315, 0u32ff]
    vert = ${address_vert_kabu} # グリフの数によって変更の必要あり
    j = 0
    while (j < SizeOf(hori))
        Select(vert + j)
        glyphName = GlyphInfo("Name")
        Select(hori[j])
        AddPosSub(lookups[0][0], glyphName)
        j += 1
    endloop

# calt 対応 (変更した時はパッチ側の変更も忘れないこと)
    Print("Add calt lookups")
    lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups)

    # グリフ変換用 lookup
    lookupName = "単純置換 (中)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1]) # lookup の最後に追加
    lookupSub0 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub0)

    lookupName = "単純置換 (左)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)
    k = ${address_calt}
    j = 0
    while (j < 26)
        Select(0u0041 + j); Copy() # A
        glyphName = GlyphInfo("Name")
        Select(k); Paste()
        Move(-${x_pos_calt}, 0)
        SetWidth(512)
        AddPosSub(lookupSub0, glyphName) # 左→中
        glyphName = GlyphInfo("Name")
        Select(0u0041 + j) # A
        AddPosSub(lookupSub1, glyphName) # 左←中
        j += 1
        k += 1
    endloop
    j = 0
    while (j < 26)
        Select(0u0061 + j); Copy() # a
        glyphName = GlyphInfo("Name")
        Select(k); Paste()
        Move(-${x_pos_calt}, 0)
        SetWidth(512)
        AddPosSub(lookupSub0, glyphName) # 左→中
        glyphName = GlyphInfo("Name")
        Select(0u0061 + j) # a
        AddPosSub(lookupSub1, glyphName) # 左←中
        j += 1
        k += 1
    endloop

    j = 0
    while (j < 64)
        l = 0u00c0 + j
        if (l != 0u00c6\
         && l != 0u00d7\
         && l != 0u00e6\
         && l != 0u00f7)
            Select(l); Copy() # À
            glyphName = GlyphInfo("Name")
            Select(k); Paste()
            Move(-${x_pos_calt}, 0)
            SetWidth(512)
            AddPosSub(lookupSub0, glyphName) # 左→中
            glyphName = GlyphInfo("Name")
            Select(l) # À
            AddPosSub(lookupSub1, glyphName) # 左←中
            k += 1
        endif
        j += 1
    endloop

    j = 0
    while (j < 128)
        l = 0u0100 + j
        if (l != 0u0132\
         && l != 0u0133\
         && l != 0u0149\
         && l != 0u0152\
         && l != 0u0153\
         && l != 0u017f)
            Select(l); Copy() # Ā
            glyphName = GlyphInfo("Name")
            Select(k); Paste()
            Move(-${x_pos_calt}, 0)
            SetWidth(512)
            AddPosSub(lookupSub0, glyphName) # 左→中
            glyphName = GlyphInfo("Name")
            Select(l) # Ā
            AddPosSub(lookupSub1, glyphName) # 左←中
            k += 1
        endif
        j += 1
    endloop

    j = 0
    while (j < 4)
        l = 0u0218 + j
        Select(l); Copy() # Ș
        glyphName = GlyphInfo("Name")
        Select(k); Paste()
        Move(-${x_pos_calt}, 0)
        SetWidth(512)
        AddPosSub(lookupSub0, glyphName) # 左→中
        glyphName = GlyphInfo("Name")
        Select(l) # Ș
        AddPosSub(lookupSub1, glyphName) # 左←中
        k += 1
        j += 1
    endloop

    Select(0u1e9e); Copy() # ẞ
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(-${x_pos_calt}, 0)
    SetWidth(512)
    AddPosSub(lookupSub0, glyphName) # 左←中
    glyphName = GlyphInfo("Name")
    Select(0u1e9e) # ẞ
    AddPosSub(lookupSub1, glyphName) # 左→中
    k += 1

    lookupName = "単純置換 (右)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)
    j = 0
    while (j < 26)
        Select(0u0041 + j); Copy() # A
        glyphName = GlyphInfo("Name")
        Select(k); Paste()
        Move(${x_pos_calt}, 0)
        SetWidth(512)
        AddPosSub(lookupSub0, glyphName) # 中←右
        glyphName = GlyphInfo("Name")
        Select(0u0041 + j) # A
        AddPosSub(lookupSub1, glyphName) # 中→右
        j += 1
        k += 1
    endloop
    j = 0
    while (j < 26)
        Select(0u0061 + j); Copy() # a
        glyphName = GlyphInfo("Name")
        Select(k); Paste()
        Move(${x_pos_calt}, 0)
        SetWidth(512)
        AddPosSub(lookupSub0, glyphName) # 中←右
        glyphName = GlyphInfo("Name")
        Select(0u0061 + j) # a
        AddPosSub(lookupSub1, glyphName) # 中→右
        j += 1
        k += 1
    endloop

    j = 0
    while (j < 64)
        l = 0u00c0 + j
        if (l != 0u00c6\
         && l != 0u00d7\
         && l != 0u00e6\
         && l != 0u00f7)
            Select(l); Copy() # À
            glyphName = GlyphInfo("Name")
            Select(k); Paste()
            Move(${x_pos_calt}, 0)
            SetWidth(512)
            AddPosSub(lookupSub0, glyphName) # 中←右
            glyphName = GlyphInfo("Name")
            Select(l) # À
            AddPosSub(lookupSub1, glyphName) # 中→右
            k += 1
        endif
        j += 1
    endloop

    j = 0
    while (j < 128)
        l = 0u0100 + j
        if (l != 0u0132\
         && l != 0u0133\
         && l != 0u0149\
         && l != 0u0152\
         && l != 0u0153\
         && l != 0u017f)
            Select(l); Copy() # Ā
            glyphName = GlyphInfo("Name")
            Select(k); Paste()
            Move(${x_pos_calt}, 0)
            SetWidth(512)
            AddPosSub(lookupSub0, glyphName) # 中←右
            glyphName = GlyphInfo("Name")
            Select(l) # Ā
            AddPosSub(lookupSub1, glyphName) # 中→右
            k += 1
        endif
        j += 1
    endloop

    j = 0
    while (j < 4)
        l = 0u0218 + j
        Select(l); Copy() # Ș
        glyphName = GlyphInfo("Name")
        Select(k); Paste()
        Move(${x_pos_calt}, 0)
        SetWidth(512)
        AddPosSub(lookupSub0, glyphName) # 中←右
        glyphName = GlyphInfo("Name")
        Select(l) # Ș
        AddPosSub(lookupSub1, glyphName) # 中→右
        k += 1
        j += 1
    endloop

    Select(0u1e9e); Copy() # ẞ
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(${x_pos_calt}, 0)
    SetWidth(512)
    AddPosSub(lookupSub0, glyphName) # 中←右
    glyphName = GlyphInfo("Name")
    Select(0u1e9e) # ẞ
    AddPosSub(lookupSub1, glyphName) # 中→右
    k += 1

    lookupName = "単純置換 (3桁)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)

    j = 0
    while (j < 10)
        Select(0u25b2); Copy() # ▲
        Select(k); Paste()
        Scale(15, 27)
        Move(-490, -510)
        Copy(); Select(k + 20); Paste() # 12桁用
        Select(0u0030 + j); Copy() # 0
        glyphName = GlyphInfo("Name")
        Select(k); PasteInto()
        SetWidth(512)
        AddPosSub(lookupSub0, glyphName) # ノーマル←3桁マーク付加
        glyphName = GlyphInfo("Name")
        Select(0u0030 + j) # 0
        AddPosSub(lookupSub1, glyphName) # 3桁マーク付加←ノーマル
 #        Select(k + 10) # 0
 #        AddPosSub(lookupSub1, glyphName) # 3桁マーク付加←4桁マーク付加
        Select(k + 20) # 0
        AddPosSub(lookupSub1, glyphName) # 3桁マーク付加←12桁マーク付加
        k += 1
        j += 1
    endloop

    lookupName = "単純置換 (4桁)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)

    j = 0
    while (j < 10)
        Select(0u25bc); Copy() # ▼
        Select(k); Paste()
        Scale(15, 27)
        Move(-490, 452)
        Copy(); Select(k + 10); PasteInto() # 12桁用
        Select(0u0030 + j); Copy() # 0
        glyphName = GlyphInfo("Name")
        Select(k); PasteInto()
        SetWidth(512)
        AddPosSub(lookupSub0, glyphName) # ノーマル←4桁マーク付加
        glyphName = GlyphInfo("Name")
        Select(0u0030 + j) # 0
        AddPosSub(lookupSub1, glyphName) # 4桁マーク付加←ノーマル
 #        Select(k - 10) # 0
 #        AddPosSub(lookupSub1, glyphName) # 4桁マーク付加←3桁マーク付加
 #        Select(k + 10) # 0
 #        AddPosSub(lookupSub1, glyphName) # 4桁マーク付加←12桁マーク付加
        k += 1
        j += 1
    endloop

    lookupName = "単純置換 (12桁)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)

    j = 0
    while (j < 10)
        Select(0u0030 + j); Copy() # 0
        glyphName = GlyphInfo("Name")
        Select(k); PasteInto()
        SetWidth(512)
        AddPosSub(lookupSub0, glyphName) # ノーマル←12桁マーク付加
        glyphName = GlyphInfo("Name")
        Select(0u0030 + j) # 0
        AddPosSub(lookupSub1, glyphName) # 12桁マーク付加←ノーマル
 #        Select(k - 20) # 0
 #        AddPosSub(lookupSub1, glyphName) # 12桁マーク付加←3桁マーク付加
 #        Select(k - 10) # 0
 #        AddPosSub(lookupSub1, glyphName) # 12桁マーク付加←4桁マーク付加
        k += 1
        j += 1
    endloop

    lookupName = "単純置換 (小数)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)

    j = 0
    while (j < 10)
        Select(0u0030 + j); Copy() # 0
        glyphName = GlyphInfo("Name")
        Select(k); Paste()
        Scale(${percent_calt_decimal}, ${percent_calt_decimal}, 256, 0)
        SetWidth(512)
 #        AddPosSub(lookupSub0, glyphName) # ノーマル←小数
        glyphName = GlyphInfo("Name")
        Select(0u0030 + j) # 0
        AddPosSub(lookupSub1, glyphName) # 小数←ノーマル
        k += 1
        j += 1
    endloop

    lookupName = "単純置換 (左・記号)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)

    Select(0u002d); Copy() # -
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(-${x_pos_calt_hyphen}, 0)
    SetWidth(512)
 #    AddPosSub(lookupSub0, glyphName) # 左→中
    glyphName = GlyphInfo("Name")
    Select(0u002d) # -
    AddPosSub(lookupSub1, glyphName) # 左←中
    k += 1

    Select(0u002f); Copy() # solidus
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(-${x_pos_calt}, 0)
    SetWidth(512)
 #    AddPosSub(lookupSub0, glyphName) # 左→中
    glyphName = GlyphInfo("Name")
    Select(0u002f) # solidus
    AddPosSub(lookupSub1, glyphName) # 左←中
    k += 1

    Select(0u003c); Copy() # <
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(-${x_pos_calt}, 0)
    SetWidth(512)
 #    AddPosSub(lookupSub0, glyphName) # 左→中
    glyphName = GlyphInfo("Name")
    Select(0u003c) # <
    AddPosSub(lookupSub1, glyphName) # 左←中
    k += 1

    Select(0u003e); Copy() # >
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(-${x_pos_calt}, 0)
    SetWidth(512)
 #    AddPosSub(lookupSub0, glyphName) # 左→中
    glyphName = GlyphInfo("Name")
    Select(0u003e) # >
    AddPosSub(lookupSub1, glyphName) # 左←中
    k += 1

    Select(0u005c); Copy() # reverse solidus
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(-${x_pos_calt}, 0)
    SetWidth(512)
 #    AddPosSub(lookupSub0, glyphName) # 左→中
    glyphName = GlyphInfo("Name")
    Select(0u005c) # reverse solidus
    AddPosSub(lookupSub1, glyphName) # 左←中
    k += 1

    lookupName = "単純置換 (右・記号)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)

    Select(0u002d); Copy() # -
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(${x_pos_calt_hyphen}, 0)
    SetWidth(512)
 #    AddPosSub(lookupSub0, glyphName) # 中←右
    glyphName = GlyphInfo("Name")
    Select(0u002d) # -
    AddPosSub(lookupSub1, glyphName) # 中→右
    k += 1

    Select(0u002f); Copy() # solidus
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(${x_pos_calt}, 0)
    SetWidth(512)
 #    AddPosSub(lookupSub0, glyphName) # 中←右
    glyphName = GlyphInfo("Name")
    Select(0u002f) # solidus
    AddPosSub(lookupSub1, glyphName) # 中→右
    k += 1

    Select(0u003c); Copy() # <
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(${x_pos_calt}, 0)
    SetWidth(512)
 #    AddPosSub(lookupSub0, glyphName) # 中←右
    glyphName = GlyphInfo("Name")
    Select(0u003c) # <
    AddPosSub(lookupSub1, glyphName) # 中→右
    k += 1

    Select(0u003e); Copy() # >
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(${x_pos_calt}, 0)
    SetWidth(512)
 #    AddPosSub(lookupSub0, glyphName) # 中←右
    glyphName = GlyphInfo("Name")
    Select(0u003e) # >
    AddPosSub(lookupSub1, glyphName) # 中→右
    k += 1

    Select(0u005c); Copy() # reverse solidus
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(${x_pos_calt}, 0)
    SetWidth(512)
 #    AddPosSub(lookupSub0, glyphName) # 中←右
    glyphName = GlyphInfo("Name")
    Select(0u005c) # reverse solidus
    AddPosSub(lookupSub1, glyphName) # 中→右
    k += 1

    lookupName = "単純置換 (下)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)

    Select(0u007c); Copy() # |
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(0, ${y_pos_calt_bar})
    SetWidth(512)
 #    AddPosSub(lookupSub0, glyphName) # 移動前←後
    glyphName = GlyphInfo("Name")
    Select(0u007c) # |
    AddPosSub(lookupSub1, glyphName) # 移動前→後
    k += 1

    Select(0u007e); Copy() # ~
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(0, ${y_pos_calt_tilde})
    SetWidth(512)
 #    AddPosSub(lookupSub0, glyphName) # 移動前←後
    glyphName = GlyphInfo("Name")
    Select(0u007e) # ~
    AddPosSub(lookupSub1, glyphName) # 移動前→後
    k += 1

    lookupName = "単純置換 (上)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)

    Select(0u003a); Copy() # :
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(20, ${y_pos_calt_colon})
    SetWidth(512)
 #    AddPosSub(lookupSub0, glyphName) # 移動前←後
    glyphName = GlyphInfo("Name")
    Select(0u003a) # :
    AddPosSub(lookupSub1, glyphName) # 移動前→後
    k += 1

    # calt をスクリプトで扱う方法が分からないので一旦ダミーをセットしてttxで上書きする
    j = 0
    while (j < ${num_calt_lookups}) # caltルックアップの数だけ確保する
        lookupName = "'zero' 文脈依存の異体字に後で換える " + ToString(j)
        AddLookup(lookupName, "gsub_single", 0, [["zero",[["DFLT",["dflt"]]]]], lookups[numlookups - 1])
        Select(0u00a0); glyphName = GlyphInfo("Name")
        Select(0u0020)

        lookupSub = lookupName + "サブテーブル"
        AddLookupSubtable(lookupName, lookupSub)
        AddPosSub(lookupSub, glyphName)
        j += 1
    endloop

# ss 対応 (lookup の数を変えた場合は table_modificator も変更すること)
    Print("Add ss lookups")
    lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups)

    j = ${num_ss_lookups}
    while (0 < j) # ssルックアップの数だけ確保する
        lookupName = "'ss0" + ToString(j) + "' スタイルセット" + ToString(j)
        AddLookup(lookupName, "gsub_single", 0, [["ss0" + ToString(j),[["DFLT",["dflt"]]]]], lookups[numlookups - 1])
        lookupSub = lookupName + "サブテーブル"
        AddLookupSubtable(lookupName, lookupSub)
        j -= 1
    endloop

    ss = 1
# ss01 全角スペース
    lookupName = "'ss0" + ToString(ss) + "' スタイルセット" + ToString(ss)
    lookupSub = lookupName + "サブテーブル"

    orig = [0u3000] # 全角スペース
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(k); Paste()
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop
    ss += 1

# ss02 半角スペース
    lookupName = "'ss0" + ToString(ss) + "' スタイルセット" + ToString(ss)
    lookupSub = lookupName + "サブテーブル"

    orig = [0u0020, 0u00a0] # space, no-break space
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(k); Paste()
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop
    ss += 1

# ss03・ss04・ss05 桁区切りマーク、小数
    j = 0
    while (j < 40)
        Select(${address_calt_figure} + j); Copy() # 桁区切りマーク付き数字
        Select(k); Paste()
        glyphName = GlyphInfo("Name")
        Select(${address_calt_figure} + j);
        if (j < 10) # 3桁 (3桁のみ変換)
            lookupName = "'ss0" + ToString(ss) + "' スタイルセット" + ToString(ss)
            lookupSub = lookupName + "サブテーブル"
            AddPosSub(lookupSub, glyphName)
        endif
        if (10 <= j && j < 20) # 4桁 (4桁のみ変換)
            lookupName = "'ss0" + ToString(ss + 1) + "' スタイルセット" + ToString(ss + 1)
            lookupSub = lookupName + "サブテーブル"
            AddPosSub(lookupSub, glyphName)
        endif
        if (20 <= j && j < 30) # 4桁 (12桁を4桁に変換)
            Select(k - 10)
            glyphName = GlyphInfo("Name")
            Select(${address_calt_figure} + j);
            lookupName = "'ss0" + ToString(ss + 1) + "' スタイルセット" + ToString(ss + 1)
            lookupSub = lookupName + "サブテーブル"
            AddPosSub(lookupSub, glyphName)
        endif
        if (30 <= j) # 小数
            lookupName = "'ss0" + ToString(ss + 2) + "' スタイルセット" + ToString(ss + 2)
            lookupSub = lookupName + "サブテーブル"
            AddPosSub(lookupSub, glyphName)
        endif
        j += 1
        k += 1
    endloop

    j = 0
    while (j < 10)
        Select(${address_calt_figure} + j); Copy() # 桁区切りマーク付き数字
        Select(k); Paste() # 3桁 (3桁に偽装した12桁を作成)
        glyphName = GlyphInfo("Name")
        Select(${address_calt_figure} + 20 + j);
        lookupName = "'ss0" + ToString(ss) + "' スタイルセット" + ToString(ss)
        lookupSub = lookupName + "サブテーブル"
        AddPosSub(lookupSub, glyphName)
        Select(k - 20); # 3桁 + 4桁 (偽装した3桁から12桁に戻す)
        glyphName = GlyphInfo("Name")
        Select(k)
        lookupName = "'ss0" + ToString(ss + 1) + "' スタイルセット" + ToString(ss + 1)
        lookupSub = lookupName + "サブテーブル"
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop
    ss += 3

# ss06 下線
    lookupName = "'ss0" + ToString(ss) + "' スタイルセット" + ToString(ss)
    lookupSub = lookupName + "サブテーブル"

    j = 0 # デフォルトで下線有りにする場合
    l = 0
    while (j < 109) # 全角縦書き
        if (j == 48)
            Select(${address_dvz} + 6)
        elseif (j == 66)
            Select(${address_dvz} + 7)
        elseif (j == 70)
            Select(${address_dvz} + 8)
        else
            Select(${address_zenhan_latinkana} + l)
        endif
        Copy()
        Select(k); Paste()
        glyphName = GlyphInfo("Name")
        Select(${address_vert} + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
        l += 1
    endloop

    j = 0
    while (j < 159) # 全角半角横書き
        if (j == 35)
            Select(${address_dvz} + 3)
        elseif (j == 53)
            Select(${address_dvz} + 4)
        elseif (j == 57)
            Select(${address_dvz} + 5)
        else
            Select(${address_zenhan_latinkana} + l)
        endif
        Copy()
        Select(k); Paste()
        glyphName = GlyphInfo("Name")
        Select(0uff01 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
        l += 1
    endloop

    j = 0
    while (j < 7) # ￠-￦
        Select(${address_zenhan_latinkana} + l)
        Copy()
        Select(k); Paste()
        glyphName = GlyphInfo("Name")
        Select(0uffe0 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
        l += 1
    endloop

    orig = [0u309b, 0u309c, 0u203c, 0u2047,\
            0u2048, 0u2049] # ゛゜‼⁇⁈⁉
    j = 0
    while (j < SizeOf(orig))
        Select(${address_zenhan_latinkana} + l)
        Copy()
        Select(k); Paste()
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
        l += 1
    endloop

 #      j = 0 # デフォルトで下線無しにする場合
 #      while (j < 109) # 全角縦書き
 #          if (j == 48)
 #              Select(${address_dvz} + 15) # Ｄ
 #          elseif (j == 66)
 #              Select(${address_dvz} + 16) # Ｖ
 #          elseif (j == 70)
 #              Select(${address_dvz} + 17) # Ｚ
 #          else
 #              Select(${address_vert} + j)
 #          endif
 #          Copy()
 #          Select(k); Paste()
 #          glyphName = GlyphInfo("Name")
 #          Select(${address_vert} + j)
 #          AddPosSub(lookupSub, glyphName)
 #          j += 1
 #          k += 1
 #      endloop
 #
 #    j = 0
 #    while (j < 159) # 全角半角横書き
 #        if (j == 35)
 #            Select(${address_dvz} + 12) # Ｄ
 #        elseif (j == 53)
 #            Select(${address_dvz} + 13) # Ｖ
 #        elseif (j == 57)
 #            Select(${address_dvz} + 14) # Ｚ
 #        else
 #            Select(0uff01 + j)
 #        endif
 #        Copy()
 #        Select(k); Paste()
 #        glyphName = GlyphInfo("Name")
 #        Select(0uff01 + j)
 #        AddPosSub(lookupSub, glyphName)
 #        j += 1
 #        k += 1
 #    endloop
 #
 #    j = 0
 #    while (j < 7) # ￠-￦
 #        Select(0uffe0 + j)
 #        Copy()
 #        Select(k); Paste()
 #        glyphName = GlyphInfo("Name")
 #        Select(0uffe0 + j)
 #        AddPosSub(lookupSub, glyphName)
 #        j += 1
 #        k += 1
 #    endloop
 #
 #    orig = [0u309b, 0u309c, 0u203c, 0u2047,\
 #            0u2048, 0u2049] # ゛゜‼⁇⁈⁉
 #    j = 0
 #    while (j < SizeOf(orig))
 #        Select(orig[j])
 #        Copy()
 #        Select(k); Paste()
 #        glyphName = GlyphInfo("Name")
 #        Select(orig[j])
 #        AddPosSub(lookupSub, glyphName)
 #        j += 1
 #        k += 1
 #    endloop
    ss += 1

# ss07 破線・ウロコ
    lookupName = "'ss0" + ToString(ss) + "' スタイルセット" + ToString(ss)
    lookupSub = lookupName + "サブテーブル"

    orig = [0u2044, 0u007c,\
            0u30a0, 0u2f23, 0u2013, 0ufe32, 0u2014, 0ufe31] # ⁄|゠⼣–︲—︱
    j = 0
    l = 0
    while (j < SizeOf(orig))
        Select(${address_visi} + l); Copy()
        Select(k); Paste()
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
        l += 1
    endloop

    j = 0
    while (j < 20) # ➀-➓
        Select(${address_visi} + l); Copy()
        Select(k); Paste()
        glyphName = GlyphInfo("Name")
        Select(0u2780 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
        l += 1
    endloop

    orig = [0u3007, 0u4e00, 0u4e8c, 0u4e09,\
            0u5de5, 0u529b, 0u5915, 0u535c,\
            0u53e3] # 〇一二三工力夕卜口
    j = 0
    while (j < SizeOf(orig))
        Select(${address_visi} + l); Copy()
        Select(k); Paste()
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
        l += 1
    endloop

    Select(${address_store_end}); Copy() # 縦書き゠
    Select(k); Paste()
    glyphName = GlyphInfo("Name")
    Select(${address_vert_dh})
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(${address_visi} + 1); Copy() # |
    Select(k); Paste()
    Move(0, ${y_pos_calt_bar})
    SetWidth(512)
    glyphName = GlyphInfo("Name")
    Select(${address_calt_end} - 2)
    AddPosSub(lookupSub, glyphName)
    k += 1
    ss += 1

# ss08 DVZ
    lookupName = "'ss0" + ToString(ss) + "' スタイルセット" + ToString(ss)
    lookupSub = lookupName + "サブテーブル"

    orig = [0u0044, 0u0056, 0u005A] # DVZ
    num = [3, 21, 25] # 左に移動したAからDVZまでの数
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(k); Paste()
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < SizeOf(orig)) # 左に移動したDVZ
        Select(orig[j]); Copy()
        Select(k); Paste()
        Move(-${x_pos_calt}, 0)
        SetWidth(512)
        glyphName = GlyphInfo("Name")
        Select(${address_calt} + num[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < SizeOf(orig)) # 右に移動したDVZ
        Select(orig[j]); Copy()
        Select(k); Paste()
        Move(${x_pos_calt}, 0)
        SetWidth(512)
        glyphName = GlyphInfo("Name")
        Select(${address_calt_middle} + num[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop
    ss += 1

 # (デフォルトで下線無しにする場合はコメントアウトを外し、glyphName を付加する Select 対象を変える)
    orig = [0uff24, 0uff36, 0uff3a] # 全角横書きDVZ(下線付き)
 #    num0 = [35, 53, 57] # 全角横書きDVZ(下線付き) ！から全角DVZまでの数
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(k); Paste()
        glyphName = GlyphInfo("Name")
        Select(orig[j])
 #        Select(${address_ss_zenhan} + num0[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    num1 = [48, 66, 70] # 全角縦書きDVZ(下線付き) （から全角DVZまでの数
    j = 0
    while (j < SizeOf(num))
        Select(${address_vert} + num1[j]); Copy()
        Select(k); Paste()
        glyphName = GlyphInfo("Name")
        Select(${address_vert} + num1[j])
 #        Select(${address_ss_vert} + num1[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    num0 = [35, 53, 57] # 全角横書きDVZ(下線付き) ！から全角DVZまでの数
    num1 = [48, 66, 70] # 全角縦書きDVZ(下線なし) （から全角DVZまでの数
    j = 0
    while (j < SizeOf(num))
        Select(${address_zenhan_latinkana} + num1[j]); Copy()
        Select(k); Paste()
        glyphName = GlyphInfo("Name")
        Select(${address_ss_zenhan} + num0[j])
 #        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        Select(${address_ss_vert} + num1[j])
 #        Select(${address_vert} + num1[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

# aalt 対応
    Print("Add aalt lookups")
# aalt 1対1
    Select(0u342e) # 㐮
    lookups = GetPosSub("*") # フィーチャを取り出す

    Select(0u1b001) # 𛀁
    glyphName = GlyphInfo("Name")
    Select(0u3048) # え
    AddPosSub(lookups[0][0],glyphName) # aaltフィーチャを追加
    glyphName = GlyphInfo("Name")
    Select(0u1b001) # 𛀁
    AddPosSub(lookups[0][0],glyphName) # aaltフィーチャを追加

    orig = [0u0069, 0u0061, 0u0065, 0u006f,\
            0u0078, 0u0259, 0u0068, 0u006b,\
            0u006c, 0u006d, 0u0070, 0u0073,\
            0u0074] #i-t
    supb = [0u2071, 0u2090, 0u2091, 0u2092,\
            0u2093, 0u2094, 0u2095, 0u2096,\
            0u2097, 0u2098, 0u209a, 0u209b,\
            0u209c] #ⁱ-ₜ
    j = 0
    while (j < SizeOf(orig))
        Select(supb[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        j += 1
    endloop
# aalt 複数
    Select(0u3402) # 㐂
    lookups = GetPosSub("*") # フィーチャを取り出す

    Select(0u4e2a) # 个
    glyphName = GlyphInfo("Name")
    Select(0u30f6); # ヶ vertフィーチャを消さないためにRemoveしない
    AddPosSub(lookups[0][0],glyphName) # 1対複数のaaltフィーチャを追加
    Select(0u500b) # 個
    glyphName = GlyphInfo("Name")
    Select(0u30f6) # ヶ
    AddPosSub(lookups[0][0],glyphName)
    Select(0u7b87) # 箇
    glyphName = GlyphInfo("Name")
    Select(0u30f6) # ヶ
    AddPosSub(lookups[0][0],glyphName)

    Select(0u30f6) # ヶ
    glyphName = GlyphInfo("Name")
    Select(0u4e2a); RemovePosSub("*") # 个
    AddPosSub(lookups[0][0],glyphName) # 1対複数のaaltフィーチャを追加
    Select(0u500b) # 個
    glyphName = GlyphInfo("Name")
    Select(0u4e2a) # 个
    AddPosSub(lookups[0][0],glyphName)
    Select(0u7b87) # 箇
    glyphName = GlyphInfo("Name")
    Select(0u4e2a) # 个
    AddPosSub(lookups[0][0],glyphName)

    Select(0u30f6) # ヶ
    glyphName = GlyphInfo("Name")
    Select(0u500b); RemovePosSub("*") # 個
    AddPosSub(lookups[0][0],glyphName) # 1対複数のaaltフィーチャを追加
    Select(0u4e2a) # 个
    glyphName = GlyphInfo("Name")
    Select(0u500b) # 個
    AddPosSub(lookups[0][0],glyphName)
    Select(0u7b87) # 箇
    glyphName = GlyphInfo("Name")
    Select(0u500b) # 個
    AddPosSub(lookups[0][0],glyphName)

    Select(0u30f6) # ヶ
    glyphName = GlyphInfo("Name")
    Select(0u7b87); RemovePosSub("*") # 箇
    AddPosSub(lookups[0][0],glyphName) # 1対複数のaaltフィーチャを追加
    Select(0u4e2a) # 个
    glyphName = GlyphInfo("Name")
    Select(0u7b87) # 箇
    AddPosSub(lookups[0][0],glyphName)
    Select(0u500b) # 個
    glyphName = GlyphInfo("Name")
    Select(0u7b87) # 箇
    AddPosSub(lookups[0][0],glyphName)

    Select(0u32d3) # ㋓
    glyphName = GlyphInfo("Name")
    Select(0u30a8) # エ
    AddPosSub(lookups[0][0],glyphName) # aaltフィーチャを追加
    Select(0u1b000) # 𛀀
    glyphName = GlyphInfo("Name")
    Select(0u30a8) # エ
    AddPosSub(lookups[0][0],glyphName) # aaltフィーチャを追加

    Select(0u30a8) # エ
    glyphName = GlyphInfo("Name")
    Select(0u1b000) # 𛀀
    AddPosSub(lookups[0][0],glyphName) # aaltフィーチャを追加

    orig = [0u0030, 0u0031, 0u0032, 0u0033,\
            0u0034, 0u0035, 0u0036, 0u0037,\
            0u0038, 0u0039, 0u002b, 0u002d,\
            0u003d, 0u0028, 0u0029, 0u006e] # 0-n
    sups = [0u2070, 0u00b9, 0u00b2, 0u00b3,\
            0u2074, 0u2075, 0u2076, 0u2077,\
            0u2078, 0u2079, 0u207a, 0u207b,\
            0u207c, 0u207d, 0u207e, 0u207f] #⁰-ⁿ
    subs = [0u2080, 0u2081, 0u2082, 0u2083,\
            0u2084, 0u2085, 0u2086, 0u2087,\
            0u2088, 0u2089, 0u208a, 0u208b,\
            0u208c, 0u208d, 0u208e, 0u2099] #₀-ₙ
    j = 0
    while (j < SizeOf(orig))
        Select(sups[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        Select(subs[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        j += 1
    endloop

    Print("Add aalt nalt lookups")
# aalt nalt 1対1
    Select(0u4e2d) # 中
    lookups = GetPosSub("*") # フィーチャを取り出す

    Select(0u00a9) # ©
    glyphName = GlyphInfo("Name")
    Select(0u0043) # C
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)

    Select(0u00ae) # ®
    glyphName = GlyphInfo("Name")
    Select(0u0052) # R
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)

    orig = [0u30a2, 0u30a4, 0u30a6, 0u30a8, 0u30aa,\
            0u30ab, 0u30ad, 0u30af, 0u30b1, 0u30b3,\
            0u30b5, 0u30b7, 0u30b9, 0u30bb, 0u30bd,\
            0u30bf, 0u30c1, 0u30c4, 0u30c6, 0u30c8,\
            0u30cb, 0u30cf, 0u30d8, 0u30db, 0u30ed] # ア-ロ
    circ = [0u32d0, 0u32d1, 0u32d2, 0u32d3, 0u32d4,\
            0u32d5, 0u32d6, 0u32d7, 0u32d8, 0u32d9,\
            0u32da, 0u32db, 0u32dc, 0u32dd, 0u32de,\
            0u32df, 0u32e0, 0u32e1, 0u32e2, 0u32e3,\
            0u32e5, 0u32e9, 0u32ec, 0u32ed, 0u32fa] # ㋐-㋺
    j = 0
    while (j < SizeOf(orig))
        Select(circ[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        if (j != 3) # エは𛀀があるため複数、前のルーチンで処理済
            AddPosSub(lookups[1][0],glyphName)
        endif
        j += 1
    endloop

# aalt nalt 複数
    Select(0u4f01) # 企
    lookups = GetPosSub("*") # フィーチャを取り出す

    Select(0u24ea) # ⓪
    glyphName = GlyphInfo("Name")
    Select(0uff10) # ０
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)
    Select(0u24ff) # ⓿
    glyphName = GlyphInfo("Name")
    Select(0uff10) # ０
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)
    Select(0u1f100) # 🄀
    glyphName = GlyphInfo("Name")
    Select(0uff10) # ０
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)

    Select(0u3020) # 〠
    glyphName = GlyphInfo("Name")
    Select(0u3012) # 〒
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)
    Select(0u3036) # 〶
    glyphName = GlyphInfo("Name")
    Select(0u3012) # 〒
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)

    orig = [0uff11, 0uff12, 0uff13, 0uff14,\
            0uff15, 0uff16, 0uff17, 0uff18, 0uff19] # １-９
    circ = [0u2460, 0u2461, 0u2462, 0u2463,\
            0u2464, 0u2465, 0u2466, 0u2467, 0u2468] # ①-⑨
    pare = [0u2474, 0u2475, 0u2476, 0u2477,\
            0u2478, 0u2479, 0u247a, 0u247b, 0u247c] # ⑴-⑼
    peri = [0u2488, 0u2489, 0u248a, 0u248b,\
            0u248c, 0u248d, 0u248e, 0u248f, 0u2490] # ⒈-⒐
    cir2 = [0u24f5, 0u24f6, 0u24f7, 0u24f8,\
            0u24f9, 0u24fa, 0u24fb, 0u24fc, 0u24fd] # ⓵-⓽
    cirN = [0u2776, 0u2777, 0u2778, 0u2779,\
            0u277a, 0u277b, 0u277c, 0u277d, 0u277e] # ❶-❾
    cirS = [0u2780, 0u2781, 0u2782, 0u2783,\
            0u2784, 0u2785, 0u2786, 0u2787, 0u2788] # ➀-➈
    ciSN = [0u278a, 0u278b, 0u278c, 0u278d,\
            0u278e, 0u278f, 0u2790, 0u2791, 0u2792] # ➊-➒
    j = 0
    while (j < SizeOf(orig))
        Select(circ[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        AddPosSub(lookups[1][0],glyphName)
        Select(pare[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        AddPosSub(lookups[1][0],glyphName)
        Select(peri[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        AddPosSub(lookups[1][0],glyphName)
        Select(cir2[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        AddPosSub(lookups[1][0],glyphName)
        Select(cirN[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        AddPosSub(lookups[1][0],glyphName)
        Select(cirS[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        AddPosSub(lookups[1][0],glyphName)
        Select(ciSN[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        AddPosSub(lookups[1][0],glyphName)
        j += 1
    endloop

    orig = [0uff41, 0uff42, 0uff43, 0uff44,\
            0uff45, 0uff46, 0uff47, 0uff48,\
            0uff49, 0uff4a, 0uff4b, 0uff4c,\
            0uff4d, 0uff4e, 0uff4f, 0uff50,\
            0uff51, 0uff52, 0uff53, 0uff54,\
            0uff55, 0uff56, 0uff57, 0uff58,\
            0uff59, 0uff5a] # ａ-ｚ
    pare =[0u249c, 0u249d, 0u249e, 0u249f,\
           0u24a0, 0u24a1, 0u24a2, 0u24a3,\
           0u24a4, 0u24a5, 0u24a6, 0u24a7,\
           0u24a8, 0u24a9, 0u24aa, 0u24ab,\
           0u24ac, 0u24ad, 0u24ae, 0u24af,\
           0u24b0, 0u24b1, 0u24b2, 0u24b3,\
           0u24b4, 0u24b5] # ⒜-⒵
    circ = [0u24d0, 0u24d1, 0u24d2, 0u24d3,\
           0u24d4, 0u24d5, 0u24d6, 0u24d7,\
           0u24d8, 0u24d9, 0u24da, 0u24db,\
           0u24dc, 0u24dd, 0u24de, 0u24df,\
           0u24e0, 0u24e1, 0u24e2, 0u24e3,\
           0u24e4, 0u24e5, 0u24e6, 0u24e7,\
           0u24e8, 0u24e9] # ⓐ-ⓩ
    j = 0
    while (j < SizeOf(orig))
        Select(pare[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        AddPosSub(lookups[1][0],glyphName)
        Select(circ[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        AddPosSub(lookups[1][0],glyphName)
        j += 1
    endloop

# .notdef加工
    Print("Edit .notdef")
    Select(1114112)
    Move(86, 0)
    SetWidth(512)

# 縦書きメトリクス追加 (問題が多いので中止)
 #    Print("Set vertical metrics")
 #    SetFontHasVerticalMetrics(1)
 #    RemoveAllVKerns()
 #    SelectWorthOutputting()
 #    SetVWidth(1024)

 #    j = 0u0020
 #    while (j < 0u0500)
 #        if (0 < SelectIf(j))
 #            SetVWidth(512)
 #        endif
 #        j += 1
 #    endloop

 #    j = 0u1d00
 #    while (j < 0u2000)
 #        if (0 < SelectIf(j))
 #            SetVWidth(512)
 #        endif
 #        j += 1
 #    endloop

 #    j = 0u2000
 #    while (j < 0u2e80)
 #        if (0 < SelectIf(j))
 #            SetVWidth(GlyphInfo("Width"))
 #            glyphWidth = GlyphInfo("Width")
 #            SetVWidth(glyphWidth)
 #        endif
 #        j += 1
 #    endloop

 #    j = 0uff61
 #    while (j < 0uffa0)
 #        Select(j)
 #        SetVWidth(512)
 #        j += 1
 #    endloop

 #    Select(1114112) # .notdef
 #    SetVWidth(512)

 #    #  正立するグリフは高さ1024emにする
 #    if (0 < SelectIf(0u00a7)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u00a9)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u00ae)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u00b1)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u00bc, 0u00be)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u00d7)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u00f7)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u02ea, 0u02eb)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u1100, 0u11ff)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u1401, 0u166c)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u166d)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u166e)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u166f, 0u167f)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u18b0, 0u18f5)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u18f6, 0u18ff)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2016)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2020, 0u2021)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2030, 0u2031)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u203b, 0u203c)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2042)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2047, 0u2049)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2051)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2065)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u20dd, 0u20e0)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u20e2, 0u20e4)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2100, 0u2101)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2103, 0u2106)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2107)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2108, 0u2109)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u210f)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2113)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2114)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2116, 0u2117)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u211e, 0u2123)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2125)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2127)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2129)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u212e)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2135, 0u2138)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2139)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u213a, 0u213b)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u213c, 0u213f)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2145, 0u2149)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u214a)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u214c, 0u214d)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u214f)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2150, 0u215f)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2160, 0u2182)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2183, 0u2184)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2185, 0u2188)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2189)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u218c, 0u218f)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u221e)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2234, 0u2235)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2300, 0u2307)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u230c, 0u231f)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2324, 0u2328)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u232b)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u237d, 0u239a)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u23be, 0u23cd)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u23cf)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u23d1, 0u23db)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u23e2, 0u23ff)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2400, 0u2422)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2424, 0u2426)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2427, 0u243f)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2440, 0u244a)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u244b, 0u245f)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2460, 0u249b)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u249c, 0u24e9)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u24ea, 0u24ff)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u25a0, 0u25b6)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u25b7)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u25b8, 0u25c0)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u25c1)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u25c2, 0u25f7)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u25f8, 0u25ff)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2600, 0u2619)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2620, 0u266e)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u266f)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2670, 0u26ff)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2700, 0u2767)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2776, 0u2793)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2b12, 0u2b2f)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2b50, 0u2b59)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2b97)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2bb8, 0u2bd1)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2bd3, 0u2beb)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2bf0, 0u2bff)); SetVWidth(1024); endif
 #    if (0 < SelectIf(0u2e50, 0u2e51)); SetVWidth(1024); endif

# --------------------------------------------------

# Save modified font
    Print("Save " + input_ttf)
    Generate(input_ttf, "", 0x04)
 #    Generate(input_ttf, "", 0x84)
    Close()
    Print("")

    i += 1
endloop

Quit()
_EOT_

################################################################################
# Generate script to convert to oblique style
################################################################################

cat > ${tmpdir}/${oblique_converter} << _EOT_
#!$fontforge_command -script

usage = "Usage: ${oblique_converter} fontfamily-fontstyle.ttf ..."

# Get arguments
if (\$argc == 1)
    Print(usage)
    Quit()
endif

Print("- Generate oblique style fonts -")

# Begin loop
i = 1
while (i < \$argc)

# Check filename
    input_ttf = \$argv[i]
    input     = input_ttf:t:r
    if (input_ttf:t:e != "ttf")
        Print(usage)
        Quit()
    endif

    hypen_index = Strrstr(input, '-')
    if (hypen_index == -1)
        Print(usage)
        Quit()
    endif

# Get parameters
    input_family = Strsub(input, 0, hypen_index)
    input_style  = Strsub(input, hypen_index + 1)

    output_family = input_family

    if (input_style == "Regular" || input_style == "Roman")
        output_style = "Oblique"
        style        = "Oblique"
    else
        output_style = input_style + "Oblique"
        style        = input_style + " Oblique"
    endif

# Open file and set configuration
    Print("Open " + input_ttf)
    Open(input_ttf)

    Reencode("unicode")

    SetFontNames(output_family + "-" + output_style, \
                 \$familyname, \
                 \$familyname + " " + style, \
                 style)
    SetTTFName(0x409, 2, style)
    SetTTFName(0x409, 3, "FontForge ${fontforge_version} : " + "FontTools ${ttx_version} : " + \$fullname + " : " + Strftime("%d-%m-%Y", 0))

# --------------------------------------------------

# Transform
    Print("Transform all glyphs (it may take a few minutes)")
    SelectWorthOutputting()
    Transform(100, 0, 20, 100, 0, 0)
    RemoveOverlap()
    RoundToInt()

# --------------------------------------------------

# Save oblique style font
    Print("Save " + output_family + "-" + output_style + ".ttf")
    Generate(output_family + "-" + output_style + ".ttf", "", 0x04)
 #    Generate(output_family + "-" + output_style + ".ttf", "", 0x84)
    Close()
    Print("")

    i += 1
endloop

Quit()
_EOT_

################################################################################
# Generate font patcher
################################################################################

cat > ${tmpdir}/${font_patcher} << _EOT_
#!$fontforge_command -script

usage = "Usage: ${font_patcher} fontfamily-fontstyle.nopatch.ttf ..."

# Get arguments
if (\$argc == 1)
    Print(usage)
    Quit()
endif

Print("- Patch the font -")

# Begin loop
i = 1
while (i < \$argc)
# Check filename
     input_ttf = \$argv[i]
    input_nop = input_ttf:t:r # :t:r ファイル名のみ抽出
    if (input_ttf:t:e != "ttf") # :t:e 拡張子のみ抽出
        Print(usage)
        Quit()
    endif
    input     = input_nop:t:r # :t:r ファイル名のみ抽出
    if (input_nop:t:e != "nopatch") # :t:e 拡張子のみ抽出
        Print(usage)
        Quit()
    endif

    hypen_index = Strrstr(input, '-') # '-'を後ろから探す('-'から前の文字数を取得、見つからないと-1)
    if (hypen_index == -1)
        Print(usage)
        Quit()
    endif

# Get parameters
    fontfamily = Strsub(input, 0, hypen_index) # 始めから'-'までを取得 (ファミリー名)
    input_style  = Strsub(input, hypen_index + 1) # '-'から後ろを取得 (スタイル)

    fontfamilysuffix = "${font_familyname_suffix}"
    version = "${font_version}"

    if (input_style == "BoldOblique")
        output_style = input_style
        style        = "Bold Oblique"
    else
        output_style = input_style
        style        = input_style
    endif

# Open file and set configuration
    Print("Open " + input_ttf)
    Open(input_ttf)

    if (fontfamilysuffix != "")
        SetFontNames(fontfamily + fontfamilysuffix + "-" + output_style, \
                     \$familyname + " " + fontfamilysuffix, \
                     \$familyname + " " + fontfamilysuffix + " " + style, \
                     style, \
                     "", version)
    else
        SetFontNames(fontfamily + "-" + output_style, \
                     \$familyname, \
                     \$familyname + " " + style, \
                     style, \
                     "", version)
    endif
    SetTTFName(0x409, 2, style)
    SetTTFName(0x409, 3, "FontForge ${fontforge_version} : " + "FontTools ${ttx_version} : " + \$fullname + " : " + Strftime("%d-%m-%Y", 0))

# --------------------------------------------------

# ss 用異体字消去
    if ("${ss_flag}" == "false")
        Print("Remove ss lookups and glyphs")
        lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups); j = 0
        while (j < numlookups)
            if (${lookupIndex_ss} <= j && j < ${lookupIndex_ss} + ${num_ss_lookups})
                Print("Remove GSUB_" + lookups[j])
                RemoveLookup(lookups[j])
            endif
            j++
        endloop

        Select(${address_ss}, ${address_ss_end})
        Clear(); DetachAndRemoveGlyphs()
    endif

# 全角スペース消去
    if ("${visible_zenkaku_space_flag}" == "false")
        Print("Option: Disable visible zenkaku space")
        Select(0u3000); Clear(); SetWidth(1024) # 全角スペース
    endif

# 半角スペース消去
    if ("${visible_hankaku_space_flag}" == "false")
        Print("Option: Disable visible hankaku space")
        Select(0u0020); Clear(); SetWidth(512) # 半角スペース
        Select(0u00a0); Clear(); SetWidth(512) # ノーブレークスペース
    endif

# 下線付きの全角・半角形を元に戻す
    if ("${underline_flag}" == "false")
        Print("Option: Disable zenkaku hankaku underline")
        k = 0
        # 全角縦書き
        j = 0
        while (j < 109)
            Select(${address_zenhan} + k); Copy()
            Select(${address_vert} + j); Paste()
            SetWidth(1024)
            j += 1
            k += 1
        endloop

        # 全角横書き
        j = 0 # ！-｠
        while (j < 96)
            Select(${address_zenhan} + k); Copy()
            Select(0uff01 + j); Paste()
            SetWidth(1024)
            j += 1
            k += 1
        endloop

        # 半角横書き
        j = 0 # ｡-ﾟ
        while (j < 63)
            Select(${address_zenhan} + k); Copy();
            Select(0uff61 + j); Paste()
            SetWidth(512)
            j += 1
            k += 1
        endloop

        # 全角横書き (続き)
        j = 0 # ￠-￦
        while (j < 7)
            Select(${address_zenhan} + k); Copy()
            Select(0uffe0 + j); Paste()
            SetWidth(1024)
            j += 1
            k += 1
        endloop
        orig = [0u309b, 0u309c, 0u203c, 0u2047,\
                0u2048, 0u2049] # ゛゜‼⁇⁈⁉
        j = 0
        while (j < SizeOf(orig))
            Select(${address_zenhan} + k); Copy()
            Select(orig[j]); Paste()
            SetWidth(1024)
            j += 1
            k += 1
        endloop
    endif

# 識別性向上グリフを元に戻す
    if ("${improve_visibility_flag}" == "false")
        Print("Option: Disable glyphs with improved visibility")
        # 破線・ウロコ等
        k = 0
        orig = [0u2044, 0u007c,\
                0u30a0, 0u2f23, 0u2013, 0ufe32, 0u2014, 0ufe31] # ⁄|゠⼣–︲—︱
        j = 0
        while (j < SizeOf(orig))
            Select(${address_visi} + k); Copy()
            Select(orig[j]); Paste()
            if (j <= 1 || j == 4)
                SetWidth(512)
            else
                SetWidth(1024)
            endif
            j += 1
            k += 1
        endloop
        j = 0
        while (j < 20) # ➀-➓
            Select(${address_visi} + k); Copy()
            Select(0u2780 + j); Paste()
            SetWidth(1024)
            j += 1
            k += 1
        endloop
        orig = [0u3007, 0u4e00, 0u4e8c, 0u4e09,\
                0u5de5, 0u529b, 0u5915, 0u535c,\
                0u53e3] # 〇一二三工力夕卜口
        j = 0
        while (j < SizeOf(orig))
            Select(${address_visi} + k); Copy()
            Select(orig[j]); Paste()
            SetWidth(1024)
            j += 1
            k += 1
        endloop

        Select(${address_store_end}); Copy() # 縦書き゠
        Select(${address_vert_dh}); Paste()
        SetWidth(1024)
    endif

# 桁区切りなし・小数を元に戻す
    if ("${separator_flag}" == "false")
        j = 0
        while (j < 40)
            Select(0u0030 + j % 10); Copy() # 0-9
            Select(${address_calt_figure} + j); Paste()
            j += 1
        endloop
    endif

# DVZのクロスバー等消去
    if ("${dvz_flag}" == "false")
        Print("Option: Disable modified D, V and Z")
        if ("${underline_flag}" == "false")
            k = 0
        else
            k = 9
        endif
        j = 0
        orig = [0u0044, 0u0056, 0u005a,\
                0uff24, 0uff36, 0uff3a,\
               "uniFF24.vert", "uniFF36.vert", "uniFF3A.vert"] # DVZ
        while (j < SizeOf(orig))
            Select(${address_dvz} + j + k); Copy()
            Select(orig[j]); Paste()
            if (j <= 2)
                SetWidth(512)
            else
                SetWidth(1024)
            endif
            j += 1
        endloop
    endif

# calt用異体字上書き
    if ("${calt_flag}" == "true")
        Print("Overwrite calt glyphs")
        k = ${address_calt}
        j = 0
        while (j < 26)
            Select(0u0041 + j); Copy() # A
            Select(k); Paste()
            Move(-${x_pos_calt}, 0)
            SetWidth(512)
            j += 1
            k += 1
        endloop
        j = 0
        while (j < 26)
            Select(0u0061 + j); Copy() # a
            Select(k); Paste()
            Move(-${x_pos_calt}, 0)
            SetWidth(512)
            j += 1
            k += 1
        endloop

        k = ${address_calt_middle}
        j = 0
        while (j < 26)
            Select(0u0041 + j); Copy() # A
            Select(k); Paste()
            Move(${x_pos_calt}, 0)
            SetWidth(512)
            j += 1
            k += 1
        endloop
        j = 0
        while (j < 26)
            Select(0u0061 + j); Copy() # a
            Select(k); Paste()
            Move(${x_pos_calt}, 0)
            SetWidth(512)
            j += 1
            k += 1
        endloop

        Select(0u007c); Copy() # |
        Select(${address_calt_end} - 2); Paste()
        Move(0, ${y_pos_calt_bar})
        SetWidth(512)

    else # calt非対応の場合ダミーのフィーチャを削除
        Print("Remove calt lookups and glyphs")
        lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups); j = 0
        while (j < numlookups)
            if (${lookupIndex_calt} <= j && j < ${lookupIndex_calt} + ${num_calt_lookups})
                Print("Remove GSUB_" + lookups[j])
                RemoveLookup(lookups[j])
            endif
            j++
        endloop

        Select(${address_calt}, ${address_calt_end})
        Clear(); DetachAndRemoveGlyphs()
    endif

# 保管したグリフ消去
    Print("Remove stored glyphs")
    Select(${address_dvz}, ${address_store_end}); Clear() # 保管したグリフを消去

# --------------------------------------------------

# Save oblique style font
    Print("Save " + fontfamily + fontfamilysuffix + "-" + output_style + ".ttf")
    Generate(fontfamily + fontfamilysuffix + "-" + output_style + ".ttf", "", 0x04)
 #    Generate(fontfamily + fontfamilysuffix + "-" + output_style + ".ttf", "", 0x84)
    Close()
    Print("")

    i += 1
endloop

Quit()
_EOT_

################################################################################
# Generate custom fonts
################################################################################

if [ "${patch_only_flag}" = "false" ]; then
    rm -f ${font_familyname}*.ttf

    # カスタムフォント生成
    $fontforge_command -script ${tmpdir}/${modified_latin_generator} \
        2> $redirection_stderr || exit 4
    $fontforge_command -script ${tmpdir}/${modified_kana_generator} \
        2> $redirection_stderr || exit 4
    $fontforge_command -script ${tmpdir}/${modified_kanzi_generator} \
        2> $redirection_stderr || exit 4
    $fontforge_command -script ${tmpdir}/${modified_latin_kana_generator} \
        2> $redirection_stderr || exit 4
    $fontforge_command -script ${tmpdir}/${custom_font_generator} \
        2> $redirection_stderr || exit 4

    # Nerd fonts追加
    if [ "${nerd_flag}" = "true" ]; then
        $fontforge_command -script ${tmpdir}/${modified_nerd_generator} \
            2> $redirection_stderr || exit 4
        $fontforge_command -script ${tmpdir}/${merged_nerd_generator} \
            ${font_familyname}${font_familyname_suffix}-Regular.ttf \
            2> $redirection_stderr || exit 4
        $fontforge_command -script ${tmpdir}/${merged_nerd_generator} \
            ${font_familyname}${font_familyname_suffix}-Bold.ttf \
            2> $redirection_stderr || exit 4
    fi

    # パラメータ調整
    $fontforge_command -script ${tmpdir}/${parameter_modificator} \
        ${font_familyname}${font_familyname_suffix}-Regular.ttf \
        2> $redirection_stderr || exit 4
    $fontforge_command -script ${tmpdir}/${parameter_modificator} \
        ${font_familyname}${font_familyname_suffix}-Bold.ttf \
        2> $redirection_stderr || exit 4

    # オブリーク作成
    if [ "${oblique_flag}" = "true" ]; then
    $fontforge_command -script ${tmpdir}/${oblique_converter} \
        ${font_familyname}${font_familyname_suffix}-Regular.ttf \
        2> $redirection_stderr || exit 4
    $fontforge_command -script ${tmpdir}/${oblique_converter} \
        ${font_familyname}${font_familyname_suffix}-Bold.ttf \
        2> $redirection_stderr || exit 4
    fi

    # ファイル名を変更
    find . -not -name "*.*.ttf" -maxdepth 1 | \
    grep -e "${font_familyname}${font_familyname_suffix}-.*\.ttf$" | while read line
    do
        style_ttf=${line#*-}; style=${style_ttf%%.ttf}
        echo "Rename to ${font_familyname}-${style}.nopatch.ttf"
        mv "${line}" "${font_familyname}-${style}.nopatch.ttf"
    done
    echo
fi

# パッチ適用
if [ "${patch_flag}" = "true" ]; then
  find . -name "${font_familyname}-*.nopatch.ttf" -maxdepth 1 | while read line
      do
        font_ttf=$(basename ${line})
        $fontforge_command -script ${tmpdir}/${font_patcher} \
          ${font_ttf} \
          2> $redirection_stderr || exit 4
    done
fi

# Remove temporary directory
if [ "${patch_only_flag}" = "false" ] && [ "${patch_flag}" = "true" ]; then
 rm -f "${font_familyname}*.nopatch.ttf"
fi
if [ "${leaving_tmp_flag}" = "false" ]; then
    echo "Remove temporary files"
    rm -rf $tmpdir
    echo
fi

# Exit
echo "Finished generating custom fonts."
echo
exit 0
