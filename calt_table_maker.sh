#!/bin/bash

# GSUB calt table maker
#
# Copyright (c) 2023 omonomo

# GSUB calt フィーチャテーブル作成プログラム
#
# 条件成立時に呼び出す異体字変換テーブルは font_generator にて生成済みであること

#glyphNo="13704" # calt用異体字の先頭glyphナンバー (Nerd Fontsなし)
glyphNo="22862" # calt用異体字の先頭glyphナンバー (Nerd Fontsあり)
caltList="caltList"
listTemp="${caltList}.tmp"
dict="dict" # 略字をグリフ名に変換する辞書

# lookup の IndexNo. (GSUBフィーチャを変更すると変わる可能性あり)
lookupIndex_calt="17" # caltフィーチャ条件の先頭テーブル
lookupIndexU=`expr ${lookupIndex_calt} + 1` # 変換先(上に移動させたグリフ)
lookupIndexR=`expr ${lookupIndex_calt} + 2` # 変換先(右に移動させたグリフ)
lookupIndexL=`expr ${lookupIndex_calt} + 3` # 変換先(左に移動させたグリフ)
lookupIndexC=`expr ${lookupIndex_calt} + 4` # 変換先(移動させたグリフを元に戻す)

leaving_tmp_flag="false" # 一時ファイル残す
basic_only_flag="false" # 基本ラテン文字のみ

echo
echo "- GSUB table [calt, LookupType 6] maker -"
echo

calt_table_maker_help()
{
    echo "Usage: calt_table_maker.sh [options]"
    echo ""
    echo "Options:"
    echo "  -h         Display this information"
    echo "  -l         Leave (do NOT remove) temporary files"
    echo "  -n number  Set glyph number of \"A moved left\""
    echo "  -b         Set only basic Latin characters"
    exit 0
}

# Get options
while getopts hln:b OPT
do
    case "${OPT}" in
        "h" )
            calt_table_maker_help
            ;;
        "l" )
            echo "Option: Leave (do NOT remove) temporary files"
            leaving_tmp_flag="true"
            ;;
        "n" )
            echo "Option: Set glyph number of \"A moved left\": glyph${OPTARG}"
            glyphNo="${OPTARG}"
            ;;
        "b" )
            echo "Option: Set only basic Latin characters"
            basic_only_flag="true"
            ;;
        * )
            exit 1
            ;;
    esac
done

# txtファイルを削除
rm -f ${caltList}.txt
rm -f ${listTemp}.txt
rm -f ${dict}.txt

# グリフ略号 作成 ========================================
if [ "${basic_only_flag}" = "true" ]; then
  _A=(A) # A
  _B=(B) # B
  _C=(C) # C
  _D=(D) # D
  _E=(E) # E
  _F=(F) # F
  _G=(G) # G
  _H=(H) # H
  _I=(I) # I
  _J=(J) # J
  _K=(K) # K
  _L=(L) # L
  _M=(M) # M
  _N=(N) # N
  _O=(O) # O
  _P=(P) # P
  _Q=(Q) # Q
  _R=(R) # R
  _S=(S) # S
  _T=(T) # T
  _U=(U) # U
  _V=(V) # V
  _W=(W) # W
  _X=(X) # X
  _Y=(Y) # Y
  _Z=(Z) # Z
  _AE=("") # Æ
  _OE=("") # Œ
  _TH=("") # Þ

  _a=(a) # a
  _b=(b) # b
  _c=(c) # c
  _d=(d) # d
  _e=(e) # e
  _f=(f) # f
  _g=(g) # g
  _h=(h) # h
  _i=(i) # i
  _j=(j) # j
  _k=(k) # k
  _l=(l) # l
  _m=(m) # m
  _n=(n) # n
  _o=(o) # o
  _p=(p) # p
  _q=(q) # q
  _r=(r) # r
  _s=(s) # s
  _t=(t) # t
  _u=(u) # u
  _v=(v) # v
  _w=(w) # w
  _x=(x) # x
  _y=(y) # y
  _z=(z) # z
  _ae=("") # æ
  _oe=("") # œ
  _th=("") # þ
  _ss=("") # ß
  _kg=("") # ĸ
else
  _A=(A À Á Â Ã Ä Å Ā Ă Ą) # A
  _B=(B ẞ) # B ẞ
  _C=(C Ç Ć Ĉ Ċ Č) # C
  _D=(D Ď Đ Ð) # D Ð
  _E=(E È É Ê Ë Ē Ĕ Ė Ę Ě) # E
  _F=(F) # F
  _G=(G Ĝ Ğ Ġ Ģ) # G
  _H=(H Ĥ Ħ) # H
  _I=(I Ì Í Î Ï Ĩ Ī Ĭ Į İ) # I
  _J=(J Ĵ) # J
  _K=(K Ķ) # K
  _L=(L Ĺ Ļ Ľ Ŀ Ł) # L
  _M=(M) # M
  _N=(N Ñ Ń Ņ Ň Ŋ) # N
  _O=(O Ò Ó Ô Õ Ö Ø Ō Ŏ Ő) # O
  _P=(P) # P
  _Q=(Q) # Q
  _R=(R Ŕ Ŗ Ř) # R
  _S=(S Ś Ŝ Ş Š Ș) # S
  _T=(T Ţ Ť Ŧ Ț) # T
  _U=(U Ù Ú Û Ü Ũ Ū Ŭ Ů Ű Ų) # U
  _V=(V) # V
  _W=(W Ŵ) # W
  _X=(X) # X
  _Y=(Y Ý Ÿ Ŷ) # Y
  _Z=(Z Ź Ż Ž) # Z
  _AE=(Æ) # Æ
  _OE=(Œ) # Œ
  _TH=(Þ) # Þ

  _a=(a à á â ã ä å ā ă ą) # a
  _b=(b) # b
  _c=(c ç ć ĉ ċ č) # c
  _d=(d ď đ) # d
  _e=(e è é ê ë ē ĕ ė ę ě) # e
  _f=(f) # f
  _g=(g ĝ ğ ġ ģ) # g
  _h=(h ĥ ħ) # h
  _i=(i ì í î ï ĩ ī ĭ į ı) # i
  _j=(j ĵ) # j
  _k=(k ķ) # k
  _l=(l ĺ ļ ľ ŀ ł) # l
  _m=(m) # m
  _n=(n ñ ń ņ ň ŋ) # n
  _o=(o ò ó ô õ ö ø ō ŏ ő ð) # o ð
  _p=(p) # p
  _q=(q) # q
  _r=(r ŕ ŗ ř) # r
  _s=(s ś ŝ ş š ș) # s
  _t=(t ţ ť ŧ ț) # t
  _u=(u ù ú û ü ũ ū ŭ ů ű ų) # u
  _v=(v) # v
  _w=(w ŵ) # w
  _x=(x) # x
  _y=(y ý ÿ ŷ) # y
  _z=(z ź ż ž) # z
  _ae=(æ) # æ
  _oe=(œ) # œ
  _th=(þ) # þ
  _ss=(ß) # ß
  _kg=(ĸ) # ĸ
fi

# 各グリフの重心、形状の違いから、左寄り、右寄り、中央寄り、中央寄りと均等の中間、均等、幅広、Vの字形に分類する
S="grvyCapitalL"; eval class=("${S}")
eval ${S}=\("${_B[@]}" "${_D[@]}" "${_E[@]}" "${_F[@]}" "${_K[@]}" "${_L[@]}" "${_P[@]}" "${_R[@]}" "${_TH[@]}"\) # 左寄りの大文字
S="grvySmallL"; eval class+=("${S}")
eval ${S}=\("${_b[@]}" "${_h[@]}" "${_k[@]}" "${_p[@]}" "${_th[@]}" "${_ss[@]}" "${_kg[@]}"\) # 左寄りの小文字

S="grvyCapitalR"; eval class+=("${S}")
eval ${S}=\("${_C[@]}" "${_G[@]}"\) # 右寄りの大文字
S="grvySmallR"; eval class+=("${S}")
eval ${S}=\("${_a[@]}" "${_c[@]}" "${_d[@]}" "${_g[@]}" "${_q[@]}"\) # 右寄りの小文字

S="grvyCapitalW"; eval class+=("${S}")
eval ${S}=\("${_M[@]}" "${_W[@]}" "${_AE[@]}" "${_OE[@]}"\) # 幅広の大文字
S="grvySmallW"; eval class+=("${S}")
eval ${S}=\("${_m[@]}" "${_w[@]}" "${_ae[@]}" "${_oe[@]}"\) # 幅広の小文字

S="grvyCapitalE"; eval class+=("${S}")
eval ${S}=\("${_H[@]}" "${_N[@]}" "${_O[@]}" "${_Q[@]}" "${_U[@]}"\) # 均等な大文字
S="grvySmallE"; eval class+=("${S}")
eval ${S}=\("${_n[@]}" "${_u[@]}"\) # 均等な小文字

S="grvyCapitalM"; eval class+=("${S}")
eval ${S}=\("${_A[@]}" "${_S[@]}" "${_X[@]}" "${_Z[@]}"\) # 中間の大文字
S="grvySmallM"; eval class+=("${S}")
eval ${S}=\("${_e[@]}" "${_o[@]}" "${_s[@]}" "${_x[@]}" "${_z[@]}"\) # 中間の小文字

S="grvyCapitalV"; eval class+=("${S}")
eval ${S}=\("${_T[@]}" "${_V[@]}" "${_Y[@]}"\) # Vの字の大文字
S="grvySmallV"; eval class+=("${S}")
eval ${S}=\("${_v[@]}" "${_y[@]}"\) # vの字の小文字

S="grvyCapitalC"; eval class+=("${S}")
eval ${S}=\("${_I[@]}" "${_J[@]}"\) # 中寄りの大文字
S="grvySmallC"; eval class+=("${S}")
eval ${S}=\("${_f[@]}" "${_i[@]}" "${_j[@]}" "${_l[@]}" "${_r[@]}" "${_t[@]}"\) # 中寄りの小文字

S="gravityL"; eval class+=("${S}")
eval ${S}=\("${grvyCapitalL[@]}" "${grvySmallL[@]}"\) # 左寄り(左に右寄り、幅広、均等があると離れようとする)
S="gravityR"; eval class+=("${S}")
eval ${S}=\("${grvyCapitalR[@]}" "${grvySmallR[@]}"\) # 右寄り(右に左寄り、幅広、均等があると離れようとする)
S="gravityW"; eval class+=("${S}")
eval ${S}=\("${grvyCapitalW[@]}" "${grvySmallW[@]}"\) # 幅広(全てが離れようとする)
S="gravityE"; eval class+=("${S}")
eval ${S}=\("${grvyCapitalE[@]}" "${grvySmallE[@]}"\) # 均等(左に右寄りか均等、幅広、右に左寄りか均等、幅広があると離れようとする)
S="gravityM"; eval class+=("${S}")
eval ${S}=\("${grvyCapitalM[@]}" "${grvySmallM[@]}"\) # 基本的には幅広以外からは離れようとしない
S="gravityV"; eval class+=("${S}")
eval ${S}=\("${grvyCapitalV[@]}" "${grvySmallV[@]}"\) # Vの字(幅広、均等、左にある右寄り、右にある左寄り以外は近づこうとする)
S="gravityC"; eval class+=("${S}")
eval ${S}=\("${grvyCapitalC[@]}" "${grvySmallC[@]}"\) # 中寄り(全てが近づこうとする)

# --------------------

S="gravity_rC"; eval class+=("${S}")
eval ${S}=\("${_J[@]}" "${_j[@]}"\) # 引き寄せるやや右寄り
S="gravity_rM"; eval class+=("${S}")
eval ${S}=\("${_j[@]}"\) # 引き寄せないやや右寄り(例外あり)

S="gravity_lM"; eval class+=("${S}")
eval ${S}=\("${_e[@]}" "${_t[@]}"\) # 引き寄せないやや左寄り(例外あり)
S="gravity_lC"; eval class+=("${S}")
eval ${S}=\("${_f[@]}" "${_l[@]}" "${_r[@]}" "${_t[@]}" "${_y[@]}"\) # 引き寄せるやや左寄り

S="grvyCapitalF"; eval class+=("${S}")
eval ${S}=\("${grvyCapitalL[@]}" "${grvyCapitalR[@]}" "${grvyCapitalW[@]}" "${grvyCapitalE[@]}" "${grvyCapitalM[@]}"\) # 引き寄せない大文字

# --------------------

S="crclCapitalC"; eval class+=("${S}")
eval ${S}=\("${_O[@]}" "${_Q[@]}"\) # 丸い大文字
S="crclSmallC"; eval class+=("${S}")
eval ${S}=\("${_e[@]}" "${_o[@]}"\) # 丸い小文字

S="crclCapitalL"; eval class+=("${S}")
eval ${S}=\("${_C[@]}" "${_G[@]}"\) # 左が丸い大文字
S="crclSmallL"; eval class+=("${S}")
eval ${S}=\("${_c[@]}" "${_d[@]}" "${_g[@]}" "${_q[@]}"\) # 左が丸い小文字

S="crclCapitalR"; eval class+=("${S}")
eval ${S}=\("${_B[@]}" "${_D[@]}"\) # 右が丸い大文字
S="crclSmallR"; eval class+=("${S}")
eval ${S}=\("${_b[@]}" "${_p[@]}" "${_th[@]}" "${_ss[@]}"\) # 右が丸い小文字

S="circleC"; eval class+=("${S}")
eval ${S}=\("${crclCapitalC[@]}" "${crclSmallC[@]}"\) # 丸い文字
S="circleL"; eval class+=("${S}")
eval ${S}=\("${crclCapitalL[@]}" "${crclSmallL[@]}"\) # 左が丸い文字
S="circleR"; eval class+=("${S}")
eval ${S}=\("${crclCapitalR[@]}" "${crclSmallR[@]}"\) # 右が丸い文字

# --------------------

S="lowC"; eval class+=("${S}")
eval ${S}=\("${_a[@]}" "${_c[@]}" "${_e[@]}" "${_g[@]}" "${_i[@]}" "${_j[@]}" "${_n[@]}" "${_o[@]}" "${_p[@]}" "${_q[@]}"\)
eval ${S}+=\("${_r[@]}" "${_s[@]}" "${_u[@]}" "${_v[@]}" "${_x[@]}" "${_y[@]}" "${_z[@]}" "${_kg[@]}"\) # 低い文字 (幅広除く)
 #eval ${S}=\("${_a[@]}" "${_c[@]}" "${_e[@]}" "${_g[@]}" "${_i[@]}" "${_j[@]}" "${_m[@]}" "${_n[@]}" "${_o[@]}" "${_p[@]}" "${_q[@]}"\)
 #eval ${S}+=\("${_r[@]}" "${_s[@]}" "${_u[@]}" "${_v[@]}" "${_w[@]}" "${_x[@]}" "${_y[@]}" "${_z[@]}" "${_ae[@]}" "${_oe[@]}" "${_kg[@]}"\) # 低い文字
S="lowL"; eval class+=("${S}")
eval ${S}=\("${_d[@]}"\) # 左が低い文字
S="lowR"; eval class+=("${S}")
eval ${S}=\("${_b[@]}" "${_h[@]}" "${_k[@]}" "${_th[@]}"\) # 右が低い文字

# --------------------

S="spceCapitalC"; eval class+=("${S}")
eval ${S}=\("${_I[@]}" "${_T[@]}" "${_V[@]}" "${_Y[@]}"\) # 両下が開いている大文字
S="spceSmallC"; eval class+=("${S}")
eval ${S}=\("${_f[@]}" "${_i[@]}" "${_l[@]}" "${_v[@]}"\) # 両下が開いている小文字

S="spceCapitalL"; eval class+=("${S}")
eval ${S}=\(""\) # 左下が開いている大文字
S="spceSmallL"; eval class+=("${S}")
eval ${S}=\("${_t[@]}"\) # 左下が開いている小文字

S="spceCapitalR"; eval class+=("${S}")
eval ${S}=\("${_F[@]}" "${_J[@]}" "${_P[@]}" "${_TH[@]}"\) # 右下が開いている大文字
S="spceSmallR"; eval class+=("${S}")
eval ${S}=\("${_j[@]}" "${_r[@]}" "${_y[@]}"\) # 右下が開いている小文字

S="spaceC"; eval class+=("${S}")
eval ${S}=\("${spceCapitalC[@]}" "${spceSmallC[@]}"\) # 両下が開いている文字
S="spaceL"; eval class+=("${S}")
eval ${S}=\("${spceCapitalL[@]}" "${spceSmallL[@]}"\) # 左下が開いている文字
S="spaceR"; eval class+=("${S}")
eval ${S}=\("${spceCapitalR[@]}" "${spceSmallR[@]}"\) # 右下が開いている文字

# --------------------

S="capitalA"; eval class+=("${S}")
eval ${S}=\("${_A[@]}"\) # 大文字の A
S="capitalG"; eval class+=("${S}")
eval ${S}=\("${_G[@]}"\) # 大文字の G
S="capitalJ"; eval class+=("${S}")
eval ${S}=\("${_J[@]}"\) # 大文字の J
S="capitalK"; eval class+=("${S}")
eval ${S}=\("${_K[@]}"\) # 大文字の K
S="capitalL"; eval class+=("${S}")
eval ${S}=\("${_L[@]}"\) # 大文字の L
S="capitalW"; eval class+=("${S}")
eval ${S}=\("${_W[@]}"\) # 大文字の W
S="capitalX"; eval class+=("${S}")
eval ${S}=\("${_X[@]}"\) # 大文字の X
S="small_f"; eval class+=("${S}")
eval ${S}=\("${_f[@]}"\) # 小文字の f
S="small_gpq"; eval class+=("${S}")
eval ${S}=\("${_g[@]}" "${_p[@]}" "${_q[@]}"\) # 小文字の g p q
S="small_j"; eval class+=("${S}")
eval ${S}=\("${_j[@]}"\) # 小文字の j
S="small_r"; eval class+=("${S}")
eval ${S}=\("${_r[@]}"\) # 小文字の r
S="small_t"; eval class+=("${S}")
eval ${S}=\("${_t[@]}"\) # 小文字の t
S="small_w"; eval class+=("${S}")
eval ${S}=\("${_w[@]}"\) # 小文字の w
S="small_x"; eval class+=("${S}")
eval ${S}=\("${_x[@]}"\) # 小文字の x

S="capitalAll"; eval class+=("${S}")
eval ${S}=\("${grvyCapitalL[@]}" "${grvyCapitalR[@]}" "${grvyCapitalW[@]}" "${grvyCapitalE[@]}"\)
eval ${S}+=\("${grvyCapitalM[@]}" "${grvyCapitalV[@]}" "${grvyCapitalC[@]}"\) # 全ての大文字
S="smallAll"; eval class+=("${S}")
eval ${S}=\("${grvySmallL[@]}" "${grvySmallR[@]}" "${grvySmallW[@]}" "${grvySmallE[@]}"\)
eval ${S}+=\("${grvySmallM[@]}" "${grvySmallV[@]}" "${grvySmallC[@]}"\) # 全ての小文字

for S in ${class[@]}; do
	eval "member=(\"\${${S}[@]}\")"
	for T in ${member[@]}; do
		eval "${S}C+=(\"${T}C\")"
		eval "${S}L+=(\"${T}L\")"
		eval "${S}R+=(\"${T}R\")"
	done
done

# --------------------

smallxL=("${smallAll[@]}") # 左に移動した小文字(全ての小文字)
smallxC=("${grvySmallL[@]}" "${grvySmallM[@]}" "${grvySmallV[@]}" "${grvySmallC[@]}") # 移動していない小文字(右を引き離さない小文字)
smallxR=("${grvySmallV[@]}" "${grvySmallC[@]}") # 右に移動した小文字(右を引き寄せる小文字)

for S in ${smallxL[@]}; do
  smallXL+=("${S}L") # 小文字左移動後
done
for S in ${smallxC[@]}; do
  smallXC+=("${S}C") # 小文字通常
done
for S in ${smallxR[@]}; do
  smallXR+=("${S}R") # 小文字右移動後
done

# --------------------

symbolFigure=("#" "$" "%" "&" "@" 0 2 3 4 5 6 7 8 9) # 幅のある記号と数字

# グリフ名変換用辞書作成 (グリフのIDS順に並べること) ========================================
solidus="/" # 単独で変数を使用するため他と分けて代入
solidus_name="slash"
symbol2x=("#" "$" "%" "&" "${solidus}")
symbol2x_name=("numbersign" "dollar" "percent" "ampersand" "${solidus_name}")

figure=(0 1 2 3 4 5 6 7 8 9)
figure_name=("zero" "one" "two" "three" "four" "five" "six" "seven" "eight" "nine")

colon=(":")
colon_name=("colon")
symbol3x=("${colon}")
symbol3x_name=("${colon_name}")

symbol4x=("@")
symbol4x_name=("at")

# グリフ略号 (AC BC..yC zC AL BL..yL zL AR BR..yR zR 通常のグリフ、左に移動したグリフ、右に移動したグリフ)
# グリフ名 (A B..y z glyphXXXXX..glyphYYYYY)
latin=(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z \
a b c d e f g h i j k l m n o p q r s t u v w x y z) # 略号の始めの文字
latin_name=("${latin[@]}")

rSolidus=("RS")
rSolidus_name=("backslash")
symbol5x=("${rSolidus}")
symbol5x_name=("${rSolidus_name}")

latinCx=(À Á Â Ã Ä Å)
latinCx_name=("Agrave" "Aacute" "Acircumflex" "Atilde" "Adieresis" "Aring")
latinCy=(Æ)
latinCy_name=("AE")
latinCz=(Ç È É Ê Ë Ì Í Î Ï)
latinCz_name=("Ccedilla" "Egrave" "Eacute" "Ecircumflex" "Edieresis" \
"Igrave" "Iacute" "Icircumflex" "Idieresis")

latinDx=(Ð Ñ Ò Ó Ô Õ Ö Ø Ù Ú Û Ü Ý Þ ß)
latinDx_name=("Eth" "Ntilde" "Ograve" "Oacute" "Ocircumflex" "Otilde" "Odieresis" "Oslash" \
"Ugrave" "Uacute" "Ucircumflex" "Udieresis" "Yacute" "Thorn" "germandbls")

latinEx=(à á â ã ä å)
latinEx_name=("agrave" "aacute" "acircumflex" "atilde" "adieresis" "aring")
latinEy=(æ)
latinEy_name=("ae")
latinEz=(ç è é ê ë ì í î ï)
latinEz_name=("ccedilla" "egrave" "eacute" "ecircumflex" "edieresis" \
"igrave" "iacute" "icircumflex" "idieresis")

latinFx=(ð ñ ò ó ô õ ö ø ù ú û ü ý þ ÿ)
latinFx_name=("eth" "ntilde" "ograve" "oacute" "ocircumflex" "otilde" "odieresis" "oslash" \
"ugrave" "uacute" "ucircumflex" "udieresis" "yacute" "thorn" "ydieresis")

latin10x=(Ā ā Ă ă Ą ą Ć ć Ĉ ĉ Ċ ċ Č č Ď ď)
latin10x_name=("Amacron" "amacron" "Abreve" "abreve" "Aogonek" "aogonek" "Cacute" "cacute" \
"Ccircumflex" "ccircumflex" "Cdotaccent" "cdotaccent" "Ccaron" "ccaron" "Dcaron" "dcaron")

latin11x=(Đ đ Ē ē Ĕ ĕ Ė ė Ę ę Ě ě Ĝ ĝ Ğ ğ)
latin11x_name=("Dcroat" "dcroat" "Emacron" "emacron" "Ebreve" "ebreve" "Edotaccent" "edotaccent" \
"Eogonek" "eogonek" "Ecaron" "ecaron" "Gcircumflex" "gcircumflex" "Gbreve" "gbreve")

latin12x=(Ġ ġ Ģ ģ Ĥ ĥ Ħ ħ Ĩ ĩ Ī ī Ĭ ĭ Į į)
latin12x_name=("Gdotaccent" "gdotaccent" "uni0122" "uni0123" "Hcircumflex" "hcircumflex" "Hbar" "hbar" \
"Itilde" "itilde" "Imacron" "imacron" "Ibreve" "ibreve" "Iogonek" "iogonek")

latin13x=(İ ı Ĵ ĵ Ķ ķ ĸ Ĺ ĺ Ļ ļ Ľ ľ Ŀ)
latin13x_name=("Idotaccent" "dotlessi" "Jcircumflex" "jcircumflex" "uni0136" "uni0137" \
"kgreenlandic" "Lacute" "lacute" "uni013B" "uni013C" "Lcaron" "lcaron" "Ldot")
 #latin13x=(İ ı Ĳ ĳ Ĵ ĵ Ķ ķ ĸ Ĺ ĺ Ļ ļ Ľ ľ Ŀ)
 #latin13x_name=("Idotaccent" "dotlessi" "IJ" "ij" "Jcircumflex" "jcircumflex" "uni0136" "uni0137" \
 #"kgreenlandic" "Lacute" "lacute" "uni013B" "uni013C" "Lcaron" "lcaron" "Ldot")

latin14x=(ŀ Ł ł Ń ń Ņ ņ Ň ň Ŋ ŋ Ō ō Ŏ ŏ)
latin14x_name=("ldot" "Lslash" "lslash" "Nacute" "nacute" "uni0145" "uni0146" "Ncaron" \
"ncaron" "Eng" "eng" "Omacron" "omacron" "Obreve" "obreve")
 #latin14x=(ŀ Ł ł Ń ń Ņ ņ Ň ň ŉ Ŋ ŋ Ō ō Ŏ ŏ)
 #latin14x_name=("ldot" "Lslash" "lslash" "Nacute" "nacute" "uni0145" "uni0146" "Ncaron" \
 #"ncaron" "napostrophe" "Eng" "eng" "Omacron" "omacron" "Obreve" "obreve")

latin15x=(Ő ő)
latin15x_name=("Ohungarumlaut" "ohungarumlaut")
latin15y=(Œ œ)
latin15y_name=("OE" "oe")
latin15z=(Ŕ ŕ Ŗ ŗ Ř ř Ś ś Ŝ ŝ Ş ş)
latin15z_name=("Racute" "racute" "uni0156" "uni0157" \
"Rcaron" "rcaron" "Sacute" "sacute" "Scircumflex" "scircumflex" "Scedilla" "scedilla")

latin16x=(Š š Ţ ţ Ť ť Ŧ ŧ Ũ ũ Ū ū Ŭ ŭ Ů ů)
latin16x_name=("Scaron" "scaron" "uni0162" "uni0163" "Tcaron" "tcaron" "Tbar" "tbar" \
"Utilde" "utilde" "Umacron" "umacron" "Ubreve" "ubreve" "Uring" "uring")

latin17x=(Ű ű Ų ų Ŵ ŵ Ŷ ŷ Ÿ Ź ź Ż ż Ž ž)
latin17x_name=("Uhungarumlaut" "uhungarumlaut" "Uogonek" "uogonek" "Wcircumflex" "wcircumflex" "Ycircumflex" "ycircumflex" \
"Ydieresis" "Zacute" "zacute" "Zdotaccent" "zdotaccent" "Zcaron" "zcaron")
 #latin17x=(Ű ű Ų ų Ŵ ŵ Ŷ ŷ Ÿ Ź ź Ż ż Ž ž ſ)
 #latin17x_name=("Uhungarumlaut" "uhungarumlaut" "Uogonek" "uogonek" "Wcircumflex" "wcircumflex" "Ycircumflex" "ycircumflex" \
 #"Ydieresis" "Zacute" "zacute" "Zdotaccent" "zdotaccent" "Zcaron" "zcaron" "longs")

latin21x=(Ș ș Ț ț)
latin21x_name=("uni0218" "uni0219" "uni021A" "uni021B")

latin1E9x=(ẞ)
latin1E9x_name=("uni1E9E")

# 移動していない文字 ----------------------------------------

i=0

word=("${symbol2x[@]}" "${figure[@]}" "${symbol3x[@]}" "${symbol4x[@]}") # $ % & / 0-9 : @
name=("${symbol2x_name[@]}" "${figure_name[@]}" "${symbol3x_name[@]}" "${symbol4x_name[@]}")
for j in ${!word[@]}
do
  echo "$i ${word[j]} ${name[j]}" >> "${dict}.txt" # C無し注意
  i=`expr ${i} + 1`
done

word=("${latin[@]}") # A-z
name=("${latin_name[@]}")
for j in ${!word[@]}
do
  echo "$i ${word[j]}C ${name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

word=("${symbol5x[@]}") # reverse solidus
name=("${symbol5x_name[@]}")
for j in ${!word[@]}
do
  echo "$i ${word[j]} ${name[j]}" >> "${dict}.txt" # C無し注意
  i=`expr ${i} + 1`
done

word=("${latinCx[@]}") # À-Å
name=("${latinCx_name[@]}")
for j in ${!word[@]}
do
  echo "$i ${word[j]}C ${name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

echo "$i ${latinCy}C ${latinCy_name}" >> "${dict}.txt" # Æ
i=`expr ${i} + 1`
echo "$i ${latinCy}L ${latinCy_name}" >> "${dict}.txt" # Æ は移動しないため
i=`expr ${i} + 1`
echo "$i ${latinCy}R ${latinCy_name}" >> "${dict}.txt" # Æ は移動しないため
i=`expr ${i} + 1`

word=("${latinCz[@]}" "${latinDx[@]}" "${latinEx[@]}") # Ç-å
name=("${latinCz_name[@]}" "${latinDx_name[@]}" "${latinEx_name[@]}")
for j in ${!word[@]}
do
  echo "$i ${word[j]}C ${name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

echo "$i ${latinEy}C ${latinEy_name}" >> "${dict}.txt" # æ
i=`expr ${i} + 1`
echo "$i ${latinEy}L ${latinEy_name}" >> "${dict}.txt" # æ は移動しないため
i=`expr ${i} + 1`
echo "$i ${latinEy}R ${latinEy_name}" >> "${dict}.txt" # æ は移動しないため
i=`expr ${i} + 1`

word=("${latinEz[@]}" "${latinFx[@]}" "${latin10x[@]}" "${latin11x[@]}" \
"${latin12x[@]}" "${latin13x[@]}" "${latin14x[@]}" "${latin15x[@]}") # ç-ő
name=("${latinEz_name[@]}" "${latinFx_name[@]}" "${latin10x_name[@]}" "${latin11x_name[@]}" \
"${latin12x_name[@]}" "${latin13x_name[@]}" "${latin14x_name[@]}" "${latin15x_name[@]}")
for j in ${!word[@]}
do
  echo "$i ${word[j]}C ${name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

for j in ${!latin15y[@]} # Œ œ
do
  echo "$i ${latin15y[j]}C ${latin15y_name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
  echo "$i ${latin15y[j]}L ${latin15y_name[j]}" >> "${dict}.txt" # Œ œ は移動しないため
  i=`expr ${i} + 1`
  echo "$i ${latin15y[j]}R ${latin15y_name[j]}" >> "${dict}.txt" # Œ œ は移動しないため
  i=`expr ${i} + 1`
done

word=("${latin15z[@]}" "${latin16x[@]}" "${latin17x[@]}" "${latin21x[@]}" "${latin1E9x[@]}") # Ŕ-ẞ
name=("${latin15z_name[@]}" "${latin16x_name[@]}" "${latin17x_name[@]}" "${latin21x_name[@]}" "${latin1E9x_name[@]}")
for j in ${!word[@]}
do
  echo "$i ${word[j]}C ${name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

# 左に移動した文字 ----------------------------------------

word=("${latin[@]}" "${solidus}" "${rSolidus}" "${latinCx[@]}" "${latinCz[@]}" "${latinDx[@]}" "${latinEx[@]}" "${latinEz[@]}" "${latinFx[@]}" \
"${latin10x[@]}" "${latin11x[@]}" "${latin12x[@]}" "${latin13x[@]}" "${latin14x[@]}" "${latin15x[@]}" "${latin15z[@]}" \
"${latin16x[@]}" "${latin17x[@]}" "${latin21x[@]}" "${latin1E9x[@]}") # A-ẞ

i=${glyphNo}

for S in ${word[@]}
do
  echo "$i ${S}L glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

# 右に移動した文字 ----------------------------------------

for S in ${word[@]}
do
  echo "$i ${S}R glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

# 略号を通し番号と名前に変換する関数 ========================================
glyph_name() {
  number=`grep " ${1} " "${dict}.txt" | head -n 1 | cut -d ' ' -f 1`
  word=`grep " ${1} " "${dict}.txt" | head -n 1 | cut -d ' ' -f 3`
  echo "${number} ${word}"
}

# LookupType 6 を作成するための関数 ========================================
chain_context() {
  local substIndex
  local backtrack
  local input
  local lookAhead
  local lookupIndex
  substIndex="${1}"
  backtrack=("${2}")
  input=("${3}")
  lookAhead=("${4}")
  lookupIndex="${5}"

  echo "Make index ${substIndex}: Lookup = ${lookupIndex}"

  echo "<ChainContextSubst index=\"${substIndex}\" Format=\"3\">" >> "${caltList}.txt"

  if [ -n "${backtrack}" ]; then # 入力した文字の左側
    echo "<BacktrackCoverage index=\"0\">" >> "${caltList}.txt"
    rm -f ${listTemp}.txt
    for S in ${backtrack[@]}
    do
      T=`glyph_name "${S}"` # 略号から通し番号とグリフ名を取得
      echo "${T}" >> "${listTemp}.txt"
    done
    sort -n "${listTemp}.txt" | while read line  # ソートしないとttxにしかられる
    do
      T=`echo "${line}" | cut -d ' ' -f 2`
     echo "<Glyph value=\"${T}\"/>" >> "${caltList}.txt"
    done
    echo "</BacktrackCoverage>" >> "${caltList}.txt"
  fi

  echo "<InputCoverage index=\"0\">" >> "${caltList}.txt" # 入力した文字(グリフ変換対象)
  rm -f ${listTemp}.txt
  for S in ${input[@]}
    do
      T=`glyph_name "${S}"` # 略号から通し番号とグリフ名を取得
      echo "${T}" >> "${listTemp}.txt"
    done
    sort -n "${listTemp}.txt" | while read line  # ソートしないとttxにしかられる
    do
      T=`echo "${line}" | cut -d ' ' -f 2`
     echo "<Glyph value=\"${T}\"/>" >> "${caltList}.txt"
    done
  echo "</InputCoverage>" >> "${caltList}.txt"

  if [ -n "${lookAhead}" ]; then # 入力した文字の右側
    echo "<LookAheadCoverage index=\"0\">" >> "${caltList}.txt"
    rm -f ${listTemp}.txt
    for S in ${lookAhead[@]}
    do
      T=`glyph_name "${S}"` # 略号から通し番号とグリフ名を取得
      echo "${T}" >> "${listTemp}.txt"
    done
    sort -n "${listTemp}.txt" | while read line  # ソートしないとttxにしかられる
    do
      T=`echo "${line}" | cut -d ' ' -f 2`
     echo "<Glyph value=\"${T}\"/>" >> "${caltList}.txt"
    done
    echo "</LookAheadCoverage>" >> "${caltList}.txt"
  fi

  echo "<SubstLookupRecord index=\"0\">" >> "${caltList}.txt" # 条件がそろった時にグリフ置換を設定したテーブルにジャンプ
   echo "<SequenceIndex value=\"0\"/>" >> "${caltList}.txt"
   echo "<LookupListIndex value=\"${lookupIndex}\"/>" >> "${caltList}.txt"
  echo "</SubstLookupRecord>" >> "${caltList}.txt"

  echo "</ChainContextSubst>" >> "${caltList}.txt"
}

# メインルーチン ========================================
echo "Make GSUB calt List"

echo "<LookupType value=\"6\"/>" >> "${caltList}.txt"
echo "<LookupFlag value=\"0\"/>" >> "${caltList}.txt"

index="0"

# 記号類 ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

# colon に関する処理 ----------------------------------------

# 両方が数字の場合 colon 上に移動
backtrack=("${figure[@]}")
input=("${colon}")
lookAhead=("${figure[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexU}"
index=`expr ${index} + 1`

# reverse solidus に関する処理 ----------------------------------------

# 左が、右が低い文字か A で 右が、左下が開いている文字か W の場合 reverse solidus 移動しない
backtrack=("${lowRL[@]}" "${lowCL[@]}" "${capitalAL[@]}" \
"${lowRC[@]}" "${lowCC[@]}" "${capitalAC[@]}")
input=("${rSolidus}")
lookAhead=("${spaceLC[@]}" "${spaceCC[@]}" "${capitalWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が、右が低い文字か A で 右が寄せない文字の場合 reverse solidus 左に移動
backtrack=("${lowRL[@]}" "${lowCL[@]}" "${capitalAL[@]}" \
"${lowRC[@]}" "${lowCC[@]}" "${capitalAC[@]}")
input=("${rSolidus}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右が、左下が開いている文字か W の場合 reverse solidus 右に移動
backtrack=("")
input=("${rSolidus}")
lookAhead=("${spaceLC[@]}" "${spaceCC[@]}" "${capitalWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# solidus に関する処理 ----------------------------------------

# 左が 右下が開いている文字か W で 右が、左が低い文字か A の場合 solidus 移動しない
backtrack=("${spaceRR[@]}" "${spaceCR[@]}" "${capitalWR[@]}" \
"${spaceRC[@]}" "${spaceCC[@]}" "${capitalWC[@]}")
input=("${solidus}")
lookAhead=("${lowLC[@]}" "${lowCC[@]}" "${capitalAC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が寄せない文字で 右が、左が低い文字か A の場合 solidus 右に移動
backtrack=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" \
"${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
input=("${solidus}")
lookAhead=("${lowLC[@]}" "${lowCC[@]}" "${capitalAC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が、右下が開いている文字か W の場合 solidus 左に移動
backtrack=("${spaceRL[@]}" "${spaceCL[@]}" "${capitalWL[@]}" \
"${spaceRC[@]}" "${spaceCC[@]}" "${capitalWC[@]}")
input=("${solidus}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 数字と記号に関する例外処理 ----------------------------------------

# 左が幅のある記号、数字で 右が引き寄せない文字の場合 引き寄せない文字 左に移動しない
backtrack=("${symbolFigure[@]}")
input=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" )
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 同じ文字の連続 ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

# 同じ文字を等間隔にさせる例外処理 ----------------------------------------

# 左右を見る 幅広な文字 移動しない
for S in ${gravityW[@]}
do
  backtrack=("${S}L")
  input=("${S}C")
  lookAhead=("")
  for T in ${gravityW[@]}
  do
    if [ "${S}" != "${T}" ]; then
      lookAhead+=("${T}C")
    fi
  done
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
  index=`expr ${index} + 1`
done

# 左右を見る 幅広な文字 右に移動
for S in ${gravityW[@]}
do
  backtrack=("${S}L")
  input=("${S}C")
  lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}" "${gravityCC[@]}")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
  index=`expr ${index} + 1`
done

# 左を見る 幅広な文字 左に移動
for S in ${gravityW[@]}
do
  backtrack=("${S}L")
  input=("${S}C")
  lookAhead=("")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
  index=`expr ${index} + 1`
done

# 同じ文字を等間隔にさせる例外処理 ----------------------------------------

# 左を見る 均等な文字 左に移動
for S in ${gravityE[@]}
do
  backtrack=("${S}L")
  input=("${S}C")
  lookAhead=("")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
  index=`expr ${index} + 1`
done

# 同じ文字を等間隔にさせる例外処理 ----------------------------------------

# 左右を見る 中寄りの文字 移動しない
for S in ${gravityC[@]}
do
  backtrack=("${S}R")
  input=("${S}C")
  lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
  index=`expr ${index} + 1`
done

# 左右を見る 中寄りの文字 左に移動
for S in ${gravityC[@]}
do
  backtrack=("${S}R")
  input=("${S}C")
  lookAhead=("${gravityWC[@]}")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
  index=`expr ${index} + 1`
done

# 左を見る 中寄りの文字 右に移動
for S in ${gravityC[@]}
do
  backtrack=("${S}R")
  input=("${S}C")
  lookAhead=("")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
  index=`expr ${index} + 1`
done

# 同じ文字を等間隔にさせる例外処理 ----------------------------------------

# 左を見る L 右に移動
for S in ${capitalL[@]}
do
  backtrack=("${S}R")
  input=("${S}C")
  lookAhead=("")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
  index=`expr ${index} + 1`
done

# 左右を見る 左寄りの文字 右に移動
for S in ${gravityL[@]}
do
  backtrack=("${S}C")
  input=("${S}C")
  lookAhead=("${gravityVC[@]}" "${gravityCC[@]}")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
  index=`expr ${index} + 1`
done

# 左を見る 左寄りの文字 移動しない
for S in ${gravityL[@]}
do
  backtrack=("${S}C")
  input=("${S}C")
  lookAhead=("")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
  index=`expr ${index} + 1`
done

# 同じ文字を等間隔にさせる例外処理 ----------------------------------------

# 左右を見る 右寄りの文字 右に移動
for S in ${gravityR[@]}
do
  backtrack=("${S}C")
  input=("${S}C")
  lookAhead=("${gravityCC[@]}")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
  index=`expr ${index} + 1`
done

# 左を見る 右寄りの文字 移動しない
for S in ${gravityR[@]}
do
  backtrack=("${S}C")
  input=("${S}C")
  lookAhead=("")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
  index=`expr ${index} + 1`
done

# 個別対応 ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

# A に関する例外処理 1 ----------------------------------------

# 左が、右下が開いている大文字、右が W の場合 A 左に移動
backtrack=("${spceCapitalRR[@]}" "${spceCapitalCR[@]}")
input=("${capitalAC[@]}")
lookAhead=("${capitalWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が W 右が、左下が開いている大文字の場合 A 右に移動
backtrack=("${capitalWR[@]}")
input=("${capitalAC[@]}")
lookAhead=("${spceCapitalLC[@]}" "${spceCapitalCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# A に関する例外処理 2 ----------------------------------------

# 左が、右下が開いている大文字か W の場合 A 左に移動しない
backtrack=("${spceCapitalRR[@]}" "${spceCapitalCR[@]}" "${capitalWR[@]}")
input=("${capitalAC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が、右下が開いている大文字か W の場合 A 左に移動
backtrack=("${spceCapitalRL[@]}" "${spceCapitalCL[@]}" "${capitalWL[@]}" \
"${spceCapitalRC[@]}" "${spceCapitalCC[@]}" "${capitalWC[@]}")
input=("${capitalAC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# A に関する例外処理 3 ----------------------------------------

# 左が A の場合 左下が開いている大文字か W 左に移動しない
backtrack=("${capitalAR[@]}")
input=("${spceCapitalLC[@]}" "${spceCapitalCC[@]}" "${capitalWC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が A の場合 左下が開いている大文字か W 左に移動
backtrack=("${capitalAL[@]}" \
"${capitalAC[@]}")
input=("${spceCapitalLC[@]}" "${spceCapitalCC[@]}" "${capitalWC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# A に関する例外処理 4 ----------------------------------------

# 右が、右下が開いている大文字か W の場合 A 右に移動しない
backtrack=("${grvyCapitalLL[@]}" "${grvyCapitalRL[@]}" "${grvyCapitalEL[@]}" "${grvyCapitalML[@]}" "${grvyCapitalVL[@]}" "${grvyCapitalCL[@]}" \
"${grvyCapitalVC[@]}" "${grvyCapitalCC[@]}")
input=("${capitalAC[@]}")
lookAhead=("${spceCapitalRC[@]}" "${spceCapitalCC[@]}" "${capitalWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右が、右下が開いている大文字か W の場合 A 右に移動
backtrack=("")
input=("${capitalAC[@]}")
lookAhead=("${spceCapitalRC[@]}" "${spceCapitalCC[@]}" "${capitalWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右が A の場合 右下が開いている大文字か W 右に移動しない
backtrack=("${grvyCapitalLL[@]}" "${grvyCapitalRL[@]}" "${grvyCapitalEL[@]}" "${grvyCapitalML[@]}" "${grvyCapitalVL[@]}" "${grvyCapitalCL[@]}" \
"${grvyCapitalVC[@]}" "${grvyCapitalCC[@]}")
input=("${spceCapitalRC[@]}" "${spceCapitalCC[@]}" "${capitalWC[@]}")
lookAhead=("${capitalAC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右が A の場合 右下が開いている大文字か W 右に移動
backtrack=("")
input=("${spceCapitalRC[@]}" "${spceCapitalCC[@]}" "${capitalWC[@]}")
lookAhead=("${capitalAC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# もろもろ例外 ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

# 左右を見て左に移動させる例外処理 ----------------------------------------

# 左が幅広、引き寄せる文字以外 右が、左が丸い文字の場合 Vの字 左に移動
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityLC[@]}" "${gravityMC[@]}")
input=("${gravityVC[@]}")
lookAhead=("${circleLC[@]}" "${circleCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が r 右が中寄りの文字の場合 中寄り以外の文字 左に移動
backtrack=("${small_rL[@]}")
input=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}"  "${gravityVC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左右を見て移動させない例外処理 1 ----------------------------------------

# 両方が少しでも右に寄っている文字の場合 左寄りの文字他 左に移動しない
backtrack=("${gravity_rCC[@]}")
input=("${gravityLC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
lookAhead=("${gravity_rMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 両方が少しでも左に寄っている文字の場合 右寄りの文字他 右に移動しない
backtrack=("${gravity_lMC[@]}")
input=("${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
lookAhead=("${gravity_lCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 両方中寄りの文字の場合 中寄り以外の文字 移動しない
backtrack=("${gravityCL[@]}")
input=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}"  "${gravityVC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が左寄り、中間、Vの字 右が、左が丸い文字の場合 左寄りの文字 右に移動しない
backtrack=("${gravityLC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
input=("${gravityLC[@]}")
lookAhead=("${circleLC[@]}" "${circleCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が右寄り、均等な文字 右が、左が丸い文字の場合 中間の文字 右に移動しない
backtrack=("${gravityRC[@]}" "${gravityEC[@]}")
input=("${gravityMC[@]}")
lookAhead=("${circleLC[@]}" "${circleCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見て右に移動させる例外処理 ----------------------------------------

# 左が右寄り、均等な文字 右が、右寄り、中間の文字の場合 中間の文字 右に移動
backtrack=("${gravityRC[@]}" "${gravityEC[@]}")
input=("${gravityMC[@]}")
lookAhead=("${gravityRC[@]}" "${gravityMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が引き離す文字 右が中寄りの文字の場合 幅広以外の文字 右に移動
backtrack=("${gravityRL[@]}" "${gravityWL[@]}" "${gravityEL[@]}")
input=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}"  "${gravityCC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 丸い文字に関する例外処理 ----------------------------------------

# 左が右寄り、均等の文字 右が w の場合 丸い小文字 移動しない
backtrack=("${gravityRC[@]}" "${gravityEC[@]}")
input=("${crclSmallCC[@]}")
lookAhead=("${small_wC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が w 右が左寄り、均等の文字の場合 丸い小文字 移動しない
backtrack=("${small_wC[@]}")
input=("${crclSmallCC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が丸い文字に関する例外処理 1 ----------------------------------------

# 左が幅広で 右が丸い文字の場合 左が丸い文字 移動しない
backtrack=("${gravityWL[@]}")
input=("${circleLC[@]}" "${circleCC[@]}")
lookAhead=("${circleCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が左寄り、均等、中間の文字で 右がVの字の場合 左が丸い文字 移動しない
backtrack=("${gravityLC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
input=("${circleLC[@]}" "${circleCC[@]}")
lookAhead=("${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が Xx で 右が引き寄せない文字の場合 左が丸い文字 左に移動
backtrack=("${capitalXC[@]}" "${small_xC[@]}")
input=("${circleLC[@]}" "${circleCC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が丸い文字か Xx で 右が引き寄せる文字の場合 左が丸い文字 移動しない
backtrack=("${circleCC[@]}" "${capitalXC[@]}" "${small_xC[@]}")
input=("${circleLC[@]}" "${circleCC[@]}")
lookAhead=("${gravityVC[@]}" "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が、右が丸い文字で 右が引き寄せる文字の場合 左が丸い文字 右に移動
backtrack=("${circleRC[@]}")
input=("${circleLC[@]}" "${circleCC[@]}")
lookAhead=("${gravityVC[@]}" "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が、右が丸い文字で 右が幅広の文字の場合 左が丸い文字 左に移動
backtrack=("${circleRC[@]}" "${circleCC[@]}")
input=("${circleLC[@]}" "${circleCC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が KX 右が引き寄せない大文字の場合 左が丸い文字 左に移動
backtrack=("${capitalKC[@]}" "${capitalXC[@]}")
input=("${circleLC[@]}" "${circleCC[@]}")
lookAhead=("${grvyCapitalLC[@]}" "${grvyCapitalRC[@]}" "${grvyCapitalWC[@]}" "${grvyCapitalEC[@]}" "${grvyCapitalMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が、右が丸い大文字か G の場合 左が丸い小文字 移動しない
backtrack=("${crclCapitalRL[@]}" "${crclCapitalCL[@]}" "${capitalGL[@]}")
input=("${crclSmallLC[@]}" "${crclSmallCC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見て移動させない例外処理 2 ----------------------------------------

# 左が引き離す文字 右が幅広の文字の場合 Vの字、中寄り以外の文字と rt 移動しない
backtrack=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
input=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${small_rC[@]}" "${small_tC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 個別対応 ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

# J に関する例外処理 ----------------------------------------

# 左が大文字の場合 J 移動しない
backtrack=("${capitalAllR[@]}")
input=("${capitalJC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が大文字の場合 J 左に移動
backtrack=("${capitalAllL[@]}" \
"${capitalAllC[@]}")
input=("${capitalJC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右が引き寄せない大文字の場合 J 左に移動
backtrack=("")
input=("${capitalJC[@]}")
lookAhead=("${grvyCapitalFC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が J の場合 引き寄せない大文字 移動しない
backtrack=("${capitalJL[@]}" \
"${capitalJC[@]}")
input=("${grvyCapitalFC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が J の場合 引き寄せない大文字 右に移動
backtrack=("${capitalJR[@]}")
input=("${grvyCapitalFC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右が J の場合 大文字 右に移動
backtrack=("")
input=("${capitalAllC[@]}")
lookAhead=("${capitalJC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# L に関する例外処理 ----------------------------------------

# 左が L の場合 Vの字 左に移動
backtrack=("${capitalLR[@]}")
input=("${gravityVC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が L の場合 全て 移動しない
backtrack=("${capitalLR[@]}")
input=("${capitalAllC[@]}" "${smallAllC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が L の場合 全て 左に移動
backtrack=("${capitalLL[@]}" \
"${capitalLC[@]}")
input=("${capitalAllC[@]}" "${smallAllC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右が全ての場合 L 右に移動
backtrack=("")
input=("${capitalLC[@]}")
lookAhead=("${capitalAllC[@]}" "${smallAllC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# f に関する例外処理 ----------------------------------------

# 左が引き寄せる文字で 右が、左が低い文字の場合 f 右に移動しない
backtrack=("${gravityCL[@]}" \
"${gravityCC[@]}")
input=("${small_fC[@]}")
lookAhead=("${lowLC[@]}" "${lowCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右が、左が低い文字の場合 f 右に移動
backtrack=("")
input=("${small_fC[@]}")
lookAhead=("${lowLC[@]}" "${lowCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# j に関する例外処理 ----------------------------------------

# 左が gpq の場合 j 左に移動しない
backtrack=("${small_gpqR[@]}")
input=("${small_jC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が全ての文字で 右が引き寄せる文字の場合 j 左に移動しない
backtrack=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}" "${gravityCR[@]}" \
"${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}" "${gravityCC[@]}")
input=("${small_jC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が全ての文字の場合 j 左に移動
backtrack=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}" "${gravityCR[@]}" \
"${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}" "${gravityCC[@]}")
input=("${small_jC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# rt に関する例外処理 ----------------------------------------

# 左が幅広の文字 右が引き離す文字の場合 rt 移動しない
backtrack=("${gravityWL[@]}")
input=("${small_rC[@]}" "${small_tC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右が幅広の文字の場合 rt 左に移動
backtrack=("")
input=("${small_rC[@]}" "${small_tC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が rt の場合 幅広な文字 左に移動しない
backtrack=("${small_rL[@]}" "${small_tC[@]}")
input=("${gravityWC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# vy に関する例外処理 ----------------------------------------

# 左が、左が丸い小文字、右が丸い小文字の場合 vy 移動しない
backtrack=("${crclSmallRR[@]}" "${crclSmallCR[@]}" \
"${crclSmallLC[@]}" "${crclSmallRC[@]}" "${crclSmallCC[@]}")
input=("${grvySmallVC[@]}")
lookAhead=("${crclSmallLC[@]}" "${crclSmallRC[@]}" "${crclSmallCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# x に関する例外処理 ----------------------------------------

# 両方が丸い小文字の場合 x 移動しない
backtrack=("${crclSmallLL[@]}" "${crclSmallRL[@]}" "${crclSmallCL[@]}" \
"${crclSmallLC[@]}" "${crclSmallRC[@]}" "${crclSmallCC[@]}")
input=("${small_xC[@]}")
lookAhead=("${crclSmallLC[@]}" "${crclSmallRC[@]}" "${crclSmallCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が、右が丸い小文字 右が引き離す小文字の場合 x 左に移動
backtrack=("${crclSmallRC[@]}" "${crclSmallCC[@]}")
input=("${small_xC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 大文字小文字 ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

# 大文字と小文字に関する例外処理 ----------------------------------------

# 左が、右下が開いている大文字 右が幅広、中寄り以外の文字の場合 左が低い文字 左に移動しない
backtrack=("${spceCapitalRR[@]}" "${spceCapitalCR[@]}")
input=("${lowLC[@]}" "${lowCC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が、右下が開いている大文字 右が中寄りの文字の場合 左が低い文字 左に移動しない
backtrack=("${spceCapitalRC[@]}" "${spceCapitalCC[@]}")
input=("${lowLC[@]}" "${lowCC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が、右下が開いている大文字の場合 左が低い文字 左に移動
backtrack=("${spceCapitalRL[@]}" "${spceCapitalCL[@]}" \
"${spceCapitalRC[@]}" "${spceCapitalCC[@]}")
input=("${lowLC[@]}" "${lowCC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が小文字の場合 大文字 左に移動しない
backtrack=("${smallXL[@]}" \
"${smallXC[@]}")
input=("${capitalAllC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右が、左が低い文字 右下が開いている大文字 右に移動
backtrack=("")
input=("${spceCapitalRC[@]}" "${spceCapitalCC[@]}")
lookAhead=("${lowLC[@]}" "${lowCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 移動しない ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

# 左右を見て移動させない通常処理 ----------------------------------------

# 左右を見る 左寄りの文字 移動しない
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityVC[@]}")
input=("${gravityLC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 右寄りの文字 移動しない
backtrack=("${gravityVR[@]}" \
"${gravityRC[@]}" "${gravityLC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
input=("${gravityRC[@]}")
lookAhead=("${gravityRC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 均等な文字 移動しない
backtrack=("${gravityVC[@]}")
input=("${gravityEC[@]}")
lookAhead=("${gravityRC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 中間の文字 移動しない
backtrack=("${gravityVR[@]}" \
"${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
input=("${gravityMC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る Vの字 移動しない
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityMR[@]}" \
"${gravityVC[@]}")
input=("${gravityVC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左を見て右に移動させない例外処理 ----------------------------------------

# 左が、均等な大文字、左が低い文字、gpq の場合 Vの字 左に移動しない
backtrack=("${grvyCapitalEL[@]}" "${lowLL[@]}" "${small_gpqL[@]}")
input=("${gravityVC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左を見て左に移動 ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

# 左右を見て左に移動させない通常処理 ----------------------------------------

# 左右を見る 左寄りの文字 左に移動しない
backtrack=("${gravityLL[@]}" "${gravityML[@]}" "${gravityVL[@]}" \
"${gravityCC[@]}")
input=("${gravityLC[@]}")
lookAhead=("${gravityVC[@]}" "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 右寄りの文字 左に移動しない
backtrack=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}" \
"${gravityVC[@]}")
input=("${gravityRC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 幅広の字 左に移動しない
backtrack=("${gravityLL[@]}" "${gravityML[@]}" "${gravityVL[@]}")
input=("${gravityWC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}" "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 均等な文字 左に移動しない
backtrack=("${gravityLL[@]}" "${gravityML[@]}" "${gravityVL[@]}" \
"${gravityCC[@]}")
input=("${gravityEC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 中間の文字 左に移動しない
backtrack=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}" \
"${gravityVC[@]}")
input=("${gravityMC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る Vの字 左に移動しない
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" "${gravityVL[@]}")
input=("${gravityVC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 中寄りの文字 左に移動しない
backtrack=("${gravityCR[@]}" \
"${gravityLC[@]}" "${gravityMC[@]}" "${gravityVC[@]}" "${gravityCC[@]}")
input=("${gravityCC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 中寄りの文字 左に移動しない
backtrack=("${gravityRC[@]}" "${gravityEC[@]}")
input=("${gravityCC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}" "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左を見て左に移動させる通常処理 ----------------------------------------

# 左を見る 左寄りの文字、均等な文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityML[@]}" "${gravityVL[@]}" "${gravityCL[@]}" \
"${gravityCC[@]}")
input=("${gravityLC[@]}" "${gravityEC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左を見る 右寄りの文字、中間の文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}" "${gravityVL[@]}" "${gravityCL[@]}" \
"${gravityVC[@]}" "${gravityCC[@]}")
input=("${gravityRC[@]}" "${gravityMC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左を見る 幅広な文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityML[@]}" "${gravityVL[@]}" "${gravityCL[@]}")
input=("${gravityWC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左を見る Vの字 左に移動
backtrack=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}" "${gravityVL[@]}" "${gravityCL[@]}" \
"${gravityCC[@]}")
input=("${gravityVC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左を見る 中寄りの文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityWL[@]}" "${gravityEL[@]}" "${gravityML[@]}" "${gravityVL[@]}" "${gravityCL[@]}" \
"${gravityCR[@]}" \
"${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}" "${gravityCC[@]}")
input=("${gravityCC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左を見て右に移動 ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

# 左右を見て右に移動させない通常処理 ----------------------------------------

# 左右を見る 左寄りの文字 右に移動しない
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityLC[@]}" "${gravityMC[@]}")
input=("${gravityLC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 右寄りの文字 右に移動しない
backtrack=("${gravityWL[@]}" \
"${gravityRR[@]}" "${gravityER[@]}")
input=("${gravityRC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 幅広な文字 右に移動しない
backtrack=("${gravityRL[@]}" "${gravityWL[@]}" "${gravityEL[@]}" \
"${gravityLC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
input=("${gravityWC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 均等の文字 右に移動しない
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityLC[@]}" "${gravityMC[@]}")
input=("${gravityEC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 中間の文字 右に移動しない
backtrack=("${gravityWL[@]}" \
"${gravityRR[@]}" "${gravityER[@]}")
input=("${gravityMC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る Vの字 右に移動しない
backtrack=("${gravityRR[@]}" "${gravityER[@]}" "${gravityVR[@]}")
input=("${gravityVC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 中寄りの文字 右に移動しない
backtrack=("${gravityWR[@]}")
input=("${gravityCC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 中寄りの字 右に移動しない
backtrack=("${gravityWC[@]}")
input=("${gravityCC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が丸い文字に関する例外処理 2 ----------------------------------------

# 左が右寄り、均等の文字の場合 丸い小文字 右に移動
backtrack=("${gravityRC[@]}" "${gravityEC[@]}")
input=("${crclSmallCC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右が丸い小文字に関する例外処理 ----------------------------------------

# 左が x の場合 右が丸い小文字 移動しない
backtrack=("${small_xC[@]}")
input=("${crclSmallRC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左を見て右に移動させる例外処理 ----------------------------------------

# 左が、均等な大文字、左が低い文字、gpq の場合 Vの字 右に移動
backtrack=("${grvyCapitalER[@]}" "${lowLR[@]}" "${small_gpqR[@]}" \
"${grvyCapitalEC[@]}" "${lowLC[@]}" "${small_gpqC[@]}")
input=("${gravityVC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左を見て右に移動させる通常処理 ----------------------------------------

# 左を見る 左寄りの文字 右に移動
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
input=("${gravityLC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左を見る 右寄りの文字 右に移動
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" \
"${gravityWC[@]}")
input=("${gravityRC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左を見る 幅広な文字 右に移動
backtrack=("${gravityRL[@]}" "${gravityWL[@]}" "${gravityEL[@]}" \
"${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
input=("${gravityWC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左を見る 均等な文字 右に移動
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
input=("${gravityEC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左を見る 中間の文字 右に移動
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" \
"${gravityWC[@]}")
input=("${gravityMC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左を見る Vの字 右に移動
backtrack=("${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityVR[@]}" \
"${gravityWC[@]}")
input=("${gravityVC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左を見る 中寄りの文字 右に移動
backtrack=("${gravityWR[@]}" \
"${gravityWC[@]}")
input=("${gravityCC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右を見て左に移動 ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

# 左右を見て左に移動させない通常処理 ----------------------------------------

# 左右を見る 左寄りの文字 左に移動しない
backtrack=("${gravityVC[@]}")
input=("${gravityLC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 右寄りの文字 左に移動しない
backtrack=("${gravityVR[@]}" \
"${gravityRC[@]}" "${gravityLC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
input=("${gravityRC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 均等な文字 左に移動しない
backtrack=("${gravityVC[@]}")
input=("${gravityEC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 中間の文字 左に移動しない
backtrack=("${gravityVR[@]}" \
"${gravityRC[@]}" "${gravityLC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
input=("${gravityMC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る Vの字 左に移動しない
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityMR[@]}" \
"${gravityRC[@]}" "${gravityEC[@]}")
input=("${gravityVC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右が丸い大文字に関する例外処理 ----------------------------------------

# 右が引き離す文字の場合 右が丸い大文字 左に移動
backtrack=("")
input=("${crclCapitalRC[@]}" "${crclCapitalCC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityEC[@]}" "${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右が、左が丸い文字の場合 右が丸い大文字 G 左に移動
backtrack=("")
input=("${crclCapitalRC[@]}" "${crclCapitalCC[@]}" "${capitalGC[@]}")
lookAhead=("${circleLC[@]}" "${circleCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右を見て左に移動させる通常処理 ----------------------------------------

# 右を見る 左寄りの文字、中間の文字、Vの字 左に移動
backtrack=("")
input=("${gravityLC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右を見る 右寄りの文字、均等な文字 左に移動
backtrack=("")
input=("${gravityRC[@]}" "${gravityEC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右を見る 幅広の文字 左に移動
backtrack=("")
input=("${gravityWC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右を見て右に移動 ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

# 大文字と小文字に関する例外処理 ----------------------------------------

# 右が大文字の場合 小文字 右に移動しない
backtrack=("")
input=("${smallAllC[@]}")
lookAhead=("${capitalAllC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見て右に移動させない通常処理 ----------------------------------------

# 左右を見る 左寄りの文字 右に移動しない
backtrack=("${gravityCR[@]}" \
"${gravityVC[@]}")
input=("${gravityLC[@]}")
lookAhead=("${gravityVC[@]}" "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 右寄りの文字 右に移動しない
backtrack=("${gravityVR[@]}" "${gravityCR[@]}")
input=("${gravityRC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 均等な文字 右に移動しない
backtrack=("${gravityCR[@]}" \
"${gravityVC[@]}")
input=("${gravityEC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 中間の文字 右に移動しない
backtrack=("${gravityVR[@]}" "${gravityCR[@]}")
input=("${gravityMC[@]}")
lookAhead=("${gravityVC[@]}" "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る Vの字 右に移動しない
backtrack=("${gravityWL[@]}" \
"${gravityLC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
input=("${gravityVC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 中寄りの字 右に移動しない
backtrack=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}")
input=("${gravityCC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 中寄りの字 右に移動しない
backtrack=("${gravityLR[@]}" "${gravityMR[@]}" "${gravityVR[@]}")
input=("${gravityCC[@]}")
lookAhead=("${gravityRC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 中寄りの字 右に移動しない
backtrack=("${gravityLR[@]}" "${gravityMR[@]}")
input=("${gravityCC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右を見て右に移動させる通常処理 ----------------------------------------

# 右を見る 左寄りの文字、中間の文字 右に移動
backtrack=("")
input=("${gravityLC[@]}" "${gravityMC[@]}")
lookAhead=("${gravityVC[@]}" "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右を見る 右寄りの文字、均等な文字、Vの字 右に移動
backtrack=("")
input=("${gravityRC[@]}" "${gravityEC[@]}" "${gravityVC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右を見る 中寄りの文字 右に移動
backtrack=("")
input=("${gravityCC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}" "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# ---

echo "Remove temporary files"
rm -f ${listTemp}.txt
if [ "${leaving_tmp_flag}" = "false" ]; then
  rm -f ${dict}.txt
fi

echo
# Exit
echo "Finished making the GSUB table [calt, LookupType 6]."
echo
exit 0
