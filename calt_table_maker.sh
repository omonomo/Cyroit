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
    exit 0
}

# Get options
while getopts hln: OPT
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
_A=(A À Á Â Ã Ä Å) # A
_B=(B ẞ) # B ẞ
_C=(C Ç) # C
_D=(D Ð) # D Ð
_E=(E È É Ê Ë) # E
_I=(I Ì Í Î Ï) # I
_N=(N Ñ) # N
_O=(O Ò Ó Ô Õ Ö Ø) # O
_U=(U Ù Ú Û Ü) # U
_Y=(Y Ý Ÿ) # Y

_a=(a à á â ã ä å) # a
_c=(c ç) # c
_e=(e è é ê ë) # e
_i=(i ì í î ï) # i
_n=(n ñ) # n
_o=(o ò ó ô õ ö ø ð) # o ð
_u=(u ù ú û ü) # u
_y=(y ý ÿ) # y

# 各グリフの重心、形状の違いから、左寄り、右寄り、中央寄り、中央寄りと均等の中間、均等、幅広、Vの字形に分類する
grvyCapitalL=(F K L P R Þ "${_B[@]}" "${_D[@]}" "${_E[@]}") # 左寄りの大文字
grvySmallL=(b h k p þ ß) # 左寄りの小文字

grvyCapitalR=(G "${_C[@]}") # 右寄りの大文字
grvySmallR=(d g q "${_a[@]}" "${_c[@]}") # 右寄りの小文字

grvyCapitalW=(M W Æ Œ) # 幅広の大文字
grvySmallW=(m w æ œ) # 幅広の小文字

grvyCapitalE=(H Q "${_N[@]}" "${_O[@]}" "${_U[@]}") # 均等な大文字
grvySmallE=("${_n[@]}" "${_u[@]}") # 均等な小文字

grvyCapitalM=(S X Z "${_A[@]}") # 中間の大文字
grvySmallM=(s x z "${_e[@]}" "${_o[@]}") # 中間の小文字

grvyCapitalV=(T V "${_Y[@]}") # Vの字の大文字
grvySmallV=(v "${_y[@]}") # vの字の小文字

grvyCapitalC=(J "${_I[@]}") # 中寄りの大文字
grvySmallC=(f j l r t "${_i[@]}") # 中寄りの小文字

gravityL=("${grvyCapitalL[@]}" "${grvySmallL[@]}") # 左寄り(左に右寄り、幅広、均等があると離れようとする)
gravityR=("${grvyCapitalR[@]}" "${grvySmallR[@]}") # 右寄り(右に左寄り、幅広、均等があると離れようとする)
gravityW=("${grvyCapitalW[@]}" "${grvySmallW[@]}") # 幅広(全てが離れようとする)
gravityE=("${grvyCapitalE[@]}" "${grvySmallE[@]}") # 均等(左に右寄りか均等、幅広、右に左寄りか均等、幅広があると離れようとする)
gravityM=("${grvyCapitalM[@]}" "${grvySmallM[@]}") # 基本的には幅広以外からは離れようとしない
gravityV=("${grvyCapitalV[@]}" "${grvySmallV[@]}") # Vの字(幅広、均等、左にある右寄り、右にある左寄り以外は近づこうとする)
gravityC=("${grvyCapitalC[@]}" "${grvySmallC[@]}") # 中寄り(全てが近づこうとする)

# --------------------

gravity_rC=(J j) # 引き寄せるやや右寄り
gravity_rM=(j) # 引き寄せないやや右寄り

gravity_lM=(t "${_e[@]}") # 引き寄せないやや左寄り
gravity_lC=(f l r t "${_y[@]}") # 引き寄せるやや左寄り

grvyCapitalF=("${grvyCapitalL[@]}" "${grvyCapitalR[@]}" "${grvyCapitalW[@]}" "${grvyCapitalE[@]}" "${grvyCapitalM[@]}") # 引き寄せない大文字

# --------------------

crclCapitalC=(Q "${_O[@]}") # 丸い大文字
crclSmallC=("${_e[@]}" "${_o[@]}") # 丸い小文字

crclCapitalL=(G "${_C[@]}" "${crclCapitalC[@]}") # 左が丸い大文字
crclSmallL=(d g q "${_c[@]}" "${crclSmallC[@]}") # 左が丸い小文字

crclCapitalR=("${_B[@]}" "${_D[@]}" "${crclCapitalC[@]}") # 右が丸い大文字
crclSmallR=(b p þ "${crclSmallC[@]}") # 右が丸い小文字

circleC=("${crclCapitalC[@]}" "${crclSmallC[@]}") # 丸い文字
circleL=("${crclCapitalL[@]}" "${crclSmallL[@]}") # 左が丸い文字
circleR=("${crclCapitalR[@]}" "${crclSmallR[@]}") # 右が丸い文字

# --------------------

lowC=(g j m p q r s v w x z æ œ "${_a[@]}" "${_c[@]}" "${_e[@]}" "${_i[@]}" "${_n[@]}" "${_o[@]}" "${_u[@]}" "${_y[@]}") # 低い文字
lowL=(d "${lowC[@]}") # 左が低い文字
lowR=(b h k þ "${lowC[@]}") # 右が低い文字

# --------------------

spceCapitalL=(T V "${_I[@]}" "${_Y[@]}") # 左下が開いている大文字
spceSmallL=(f l t v "${_i[@]}") # 左下が開いている小文字

spceCapitalR=(F J P T V Þ "${_I[@]}" "${_Y[@]}") # 右下が開いている大文字
spceSmallR=(f j l r v "${_i[@]}" "${_y[@]}") # 右下が開いている小文字

# --------------------

capitalA=("${_A[@]}") # 大文字の A
capitalG=(G) # 大文字の G
capitalJ=(J) # 大文字の J
capitalL=(L) # 大文字の L
capitalW=(W) # 大文字の W
capitalX=(X) # 大文字の X
small_f=(f) # 小文字の f
small_gq=(g q) # 小文字の g q
small_j=(j) # 小文字の j
small_rt=(r t) # 小文字の r t
small_v=(v) # 小文字の v
small_x=(x) # 小文字の x

capitalAll=("${grvyCapitalL[@]}" "${grvyCapitalR[@]}" "${grvyCapitalW[@]}" "${grvyCapitalE[@]}" \
"${grvyCapitalM[@]}" "${grvyCapitalV[@]}" "${grvyCapitalC[@]}") # 全ての大文字
smallAll=("${grvySmallL[@]}" "${grvySmallR[@]}" "${grvySmallW[@]}" "${grvySmallE[@]}" \
"${grvySmallM[@]}" "${grvySmallV[@]}" "${grvySmallC[@]}") # 全ての小文字

# 小文字-大文字の関係で使用
smallxL=("${smallAll[@]}") # 左に移動した小文字(全ての小文字)
smallxC=("${grvySmallL[@]}" "${grvySmallM[@]}" "${grvySmallV[@]}" "${grvySmallC[@]}") # 移動していない小文字(右を引き離さない小文字)
smallxR=("${grvySmallV[@]}" "${grvySmallC[@]}") # 右に移動した小文字(右を引き寄せる小文字)

# --------------------

for S in ${gravityL[@]}; do
  gravityLC+=("${S}C") # 左寄り
  gravityLL+=("${S}L") # 左寄り左移動後
  gravityLR+=("${S}R") # 左寄り右移動後
done

for S in ${gravityR[@]}; do
  gravityRC+=("${S}C") # 右寄り
  gravityRL+=("${S}L") # 右寄り左移動後
  gravityRR+=("${S}R") # 右寄り右移動後
done

for S in ${gravityW[@]}; do
  gravityWC+=("${S}C") # 幅広
  gravityWL+=("${S}L") # 幅広左移動後
  gravityWR+=("${S}R") # 幅広右移動後
done

for S in ${gravityE[@]}; do
  gravityEC+=("${S}C") # 均等
  gravityEL+=("${S}L") # 均等左移動後
  gravityER+=("${S}R") # 均等右移動後
done

for S in ${gravityM[@]}; do
  gravityMC+=("${S}C") # 中間
  gravityML+=("${S}L") # 中間左移動後
  gravityMR+=("${S}R") # 中間右移動後
done

for S in ${gravityV[@]}; do
  gravityVC+=("${S}C") # Vの字
  gravityVL+=("${S}L") # Vの字左移動後
  gravityVR+=("${S}R") # Vの字右移動後
done

for S in ${gravityC[@]}; do
  gravityCC+=("${S}C") # 中寄り
  gravityCL+=("${S}L") # 中寄り左移動後
  gravityCR+=("${S}R") # 中寄り右移動後
done

# --------------------

for S in ${gravity_rM[@]}; do
  gravity_rMC+=("${S}C") # 引き寄せないやや右寄り
  gravity_rML+=("${S}L") # 引き寄せないやや右寄り左移動後
  gravity_rMR+=("${S}R") # 引き寄せないやや右寄り右移動後
done

for S in ${gravity_rC[@]}; do
  gravity_rCC+=("${S}C") # 引き寄せるやや右寄り
  gravity_rCL+=("${S}L") # 引き寄せるやや右寄り左移動後
  gravity_rCR+=("${S}R") # 引き寄せるやや右寄り右移動後
done

for S in ${gravity_lM[@]}; do
  gravity_lMC+=("${S}C") # 引き寄せないやや左寄り
  gravity_lML+=("${S}L") # 引き寄せないやや左寄り左移動後
  gravity_lMR+=("${S}R") # 引き寄せないやや左寄り右移動後
done

for S in ${gravity_lC[@]}; do
  gravity_lCC+=("${S}C") # 引き寄せるやや左寄り
  gravity_lCL+=("${S}L") # 引き寄せるやや左寄り左移動後
  gravity_lCR+=("${S}R") # 引き寄せるやや左寄り右移動後
done

for S in ${grvyCapitalF[@]}; do
  grvyCapitalFC+=("${S}C") # 引き寄せない大文字
  grvyCapitalFL+=("${S}L") # 引き寄せない大文字左移動後
  grvyCapitalFR+=("${S}R") # 引き寄せない大文字右移動後
done

# --------------------

for S in ${crclCapitalC[@]}; do
  crclCapitalCC+=("${S}C") # 丸い大文字
  crclCapitalCL+=("${S}L") # 丸い大文字左移動後
  crclCapitalCR+=("${S}R") # 丸い大文字右移動後
done

for S in ${crclSmallC[@]}; do
  crclSmallCC+=("${S}C") # 丸い小文字
  crclSmallCL+=("${S}L") # 丸い小文字左移動後
  crclSmallCR+=("${S}R") # 丸い小文字右移動後
done

for S in ${crclCapitalL[@]}; do
  crclCapitalLC+=("${S}C") # 左が丸い大文字
  crclCapitalLL+=("${S}L") # 左が丸い大文字左移動後左移動後
  crclCapitalLR+=("${S}R") # 左が丸い大文字右移動後右移動後
done

for S in ${crclSmallL[@]}; do
  crclSmallLC+=("${S}C") # 左が丸い小文字
  crclSmallLL+=("${S}L") # 左が丸い小文字左移動後
  crclSmallLR+=("${S}R") # 左が丸い小文字右移動後
done

for S in ${crclCapitalR[@]}; do
  crclCapitalRC+=("${S}C") # 右が丸い大文字
  crclCapitalRL+=("${S}L") # 右が丸い大文字左移動後
  crclCapitalRR+=("${S}R") # 右が丸い大文字右移動後
done

for S in ${crclSmallR[@]}; do
  crclSmallRC+=("${S}C") # 右が丸い小文字
  crclSmallRL+=("${S}L") # 右が丸い小文字左移動後
  crclSmallRR+=("${S}R") # 右が丸い小文字右移動後
done

for S in ${circleC[@]}; do
  circleCC+=("${S}C") # 丸い文字
  circleCL+=("${S}L") # 丸い文字左移動後
  circleCR+=("${S}R") # 丸い文字右移動後
done

for S in ${circleL[@]}; do
  circleLC+=("${S}C") # 左が丸い文字
  circleLL+=("${S}L") # 左が丸い文字左移動後
  circleLR+=("${S}R") # 左が丸い文字右移動後
done

for S in ${circleR[@]}; do
  circleRC+=("${S}C") # 右が丸い文字
  circleRL+=("${S}L") # 右が丸い文字左移動後
  circleRR+=("${S}R") # 右が丸い文字右移動後
done

# --------------------

for S in ${lowL[@]}; do
  lowLC+=("${S}C") # 左が低い文字
  lowLL+=("${S}L") # 左が低い文字左移動後
  lowLR+=("${S}R") # 左が低い文字右移動後
done

for S in ${lowC[@]}; do
  lowCC+=("${S}C") # 低い文字
  lowCL+=("${S}L") # 低い文字左移動後
  lowCR+=("${S}R") # 低い文字右移動後
done

for S in ${lowR[@]}; do
  lowRC+=("${S}C") # 右が低い文字
  lowRL+=("${S}L") # 右が低い文字左移動後
  lowRR+=("${S}R") # 右が低い文字右移動後
done

# --------------------

for S in ${spceCapitalL[@]}; do
  spceCapitalLC+=("${S}C") # 左下が開いている大文字
  spceCapitalLL+=("${S}L") # 左下が開いている大文字左移動後
  spceCapitalLR+=("${S}R") # 左下が開いている大文字右移動後
done

for S in ${spceSmallL[@]}; do
  spceSmallLC+=("${S}C") # 左下が開いている小文字
  spceSmallLL+=("${S}L") # 左下が開いている小文字左移動後
  spceSmallLR+=("${S}R") # 左下が開いている小文字右移動後
done

for S in ${spceCapitalR[@]}; do
  spceCapitalRC+=("${S}C") # 右下が開いている大文字
  spceCapitalRL+=("${S}L") # 右下が開いている大文字左移動後
  spceCapitalRR+=("${S}R") # 右下が開いている大文字右移動後
done

for S in ${spceSmallR[@]}; do
  spceSmallRC+=("${S}C") # 右下が開いている小文字
  spceSmallRL+=("${S}L") # 右下が開いている小文字左移動後
  spceSmallRR+=("${S}R") # 右下が開いている小文字右移動後
done

# --------------------

for S in ${capitalA[@]}; do
  capitalAC+=("${S}C") # A
  capitalAL+=("${S}L") # A 左移動後
  capitalAR+=("${S}R") # A 右移動後
done

for S in ${capitalG[@]}; do
  capitalGC+=("${S}C") # G
  capitalGL+=("${S}L") # G 左移動後
  capitalGR+=("${S}R") # G 右移動後
done

for S in ${capitalJ[@]}; do
  capitalJC+=("${S}C") # J
  capitalJL+=("${S}L") # J 左移動後
  capitalJR+=("${S}R") # J 右移動後
done

for S in ${capitalL[@]}; do
  capitalLC+=("${S}C") # L
  capitalLL+=("${S}L") # L 左移動後
  capitalLR+=("${S}R") # L 右移動後
done

for S in ${capitalW[@]}; do
  capitalWC+=("${S}C") # W
  capitalWL+=("${S}L") # W 左移動後
  capitalWR+=("${S}R") # W 右移動後
done

for S in ${capitalX[@]}; do
  capitalXC+=("${S}C") # X
  capitalXL+=("${S}L") # X 左移動後
  capitalXR+=("${S}R") # X 右移動後
done

for S in ${small_f[@]}; do
  small_fC+=("${S}C") # f
  small_fL+=("${S}L") # f 左移動後
  small_fR+=("${S}R") # f 右移動後
done

for S in ${small_gq[@]}; do
  small_gqC+=("${S}C") # gq
  small_gqL+=("${S}L") # gq 左移動後
  small_gqR+=("${S}R") # gq 右移動後
done

for S in ${small_j[@]}; do
  small_jC+=("${S}C") # gq
  small_jL+=("${S}L") # gq 左移動後
  small_jR+=("${S}R") # gq 右移動後
done

for S in ${small_rt[@]}; do
  small_rtC+=("${S}C") # rt
  small_rtL+=("${S}L") # rt 左移動後
  small_rtR+=("${S}R") # rt 右移動後
done

for S in ${small_v[@]}; do
  small_vC+=("${S}C") # v
  small_vL+=("${S}L") # v 左移動後
  small_vR+=("${S}R") # v 右移動後
done

for S in ${small_x[@]}; do
  small_xC+=("${S}C") # x
  small_xL+=("${S}L") # x 左移動後
  small_xR+=("${S}R") # x 右移動後
done

for S in ${capitalAll[@]}; do
  capitalAllC+=("${S}C") # 大文字
  capitalAllL+=("${S}L") # 大文字左移動後
  capitalAllR+=("${S}R") # 大文字右移動後
done

for S in ${smallAll[@]}; do
  smallAllC+=("${S}C") # 小文字
  smallAllL+=("${S}L") # 小文字左移動後
  smallAllR+=("${S}R") # 小文字右移動後
done

for S in ${smallxL[@]}; do
  smallXL+=("${S}L") # 小文字左移動後
done

for S in ${smallxC[@]}; do
  smallXC+=("${S}C") # 小文字通常
done

for S in ${smallxR[@]}; do
  smallXR+=("${S}R") # 小文字右移動後
done

# グリフ名変換用辞書作成 (グリフのIDS順に並べること) ========================================
 #space="SP" # 略号
 #space_name="space" # 実際の名前

solidus="/"
solidus_name="slash"

number=(0 1 2 3 4 5 6 7 8 9)
number_name=("zero" "one" "two" "three" "four" "five" "six" "seven" "eight" "nine")

colon=":"
colon_name="colon"

# グリフ略号 (AC BC..yC zC AL BL..yL zL AR BR..yR zR 通常のグリフ、左に移動したグリフ、右に移動したグリフ)
# グリフ名 (A B..y z glyphXXXXX..glyphYYYYY)
latin=(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z \
a b c d e f g h i j k l m n o p q r s t u v w x y z) # 略号の始めの文字

rSolidus="RS"
rSolidus_name="backslash"

 #nbspace="NS"
 #nbspace_name="uni00A0"

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

latin15x=(Œ œ)
latin15x_name=("OE" "oe")

latin17x=(Ÿ)
latin17x_name=("Ydieresis")

latin1E9x=(ẞ)
latin1E9x_name=("uni1E9E")

# 移動していない文字 ----------------------------------------

i=0
 #echo "$i ${space} ${space_name}" >> "${dict}.txt" # スペース
 #i=`expr ${i} + 1`

echo "$i ${solidus} ${solidus_name}" >> "${dict}.txt" # solidus
i=`expr ${i} + 1`

for j in ${!number[@]} # 数字
do
  echo "$i ${number[j]} ${number_name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

echo "$i ${colon} ${colon_name}" >> "${dict}.txt" # :
i=`expr ${i} + 1`

for S in ${latin[@]} # アルファベット基本
do
  echo "$i ${S}C ${S}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

echo "$i ${rSolidus} ${rSolidus_name}" >> "${dict}.txt" # reverse solidus
i=`expr ${i} + 1`

 #echo "$i ${nbspace} ${nbspace_name}" >> "${dict}.txt" # ノーブレークスペース
 #i=`expr ${i} + 1`

for j in ${!latinCx[@]} # À-Å
do
  echo "$i ${latinCx[j]}C ${latinCx_name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

echo "$i ${latinCy}C ${latinCy_name}" >> "${dict}.txt" # Æ
i=`expr ${i} + 1`
echo "$i ${latinCy}L ${latinCy_name}" >> "${dict}.txt" # Æ は移動しないため
i=`expr ${i} + 1`
echo "$i ${latinCy}R ${latinCy_name}" >> "${dict}.txt" # Æ は移動しないため
i=`expr ${i} + 1`

for j in ${!latinCz[@]} # Ç-Ï
do
  echo "$i ${latinCz[j]}C ${latinCz_name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

for j in ${!latinDx[@]} # Ð-ß
do
  echo "$i ${latinDx[j]}C ${latinDx_name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

for j in ${!latinEx[@]} # à-å
do
  echo "$i ${latinEx[j]}C ${latinEx_name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

echo "$i ${latinEy}C ${latinEy_name}" >> "${dict}.txt" # æ
i=`expr ${i} + 1`
echo "$i ${latinEy}L ${latinEy_name}" >> "${dict}.txt" # æ は移動しないため
i=`expr ${i} + 1`
echo "$i ${latinEy}R ${latinEy_name}" >> "${dict}.txt" # æ は移動しないため
i=`expr ${i} + 1`

for j in ${!latinEz[@]} # ç-ï
do
  echo "$i ${latinEz[j]}C ${latinEz_name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

for j in ${!latinFx[@]} # ð-ÿ
do
  echo "$i ${latinFx[j]}C ${latinFx_name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

for j in ${!latin15x[@]} # Œ œ は移動しないため
do
  echo "$i ${latin15x[j]}C ${latin15x_name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
  echo "$i ${latin15x[j]}L ${latin15x_name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
  echo "$i ${latin15x[j]}R ${latin15x_name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

for j in ${!latin17x[@]} # Ÿ
do
  echo "$i ${latin17x[j]}C ${latin17x_name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

for j in ${!latin1E9x[@]} # ẞ
do
  echo "$i ${latin1E9x[j]}C ${latin1E9x_name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

# 左に移動した文字 ----------------------------------------

i=${glyphNo}
for S in ${latin[@]} # 左に移動したアルファベット
do
  echo "$i ${S}L glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

echo "$i ${solidus}L glyph${i}" >> "${dict}.txt" # 左に移動した solidus
i=`expr ${i} + 1`

echo "$i ${rSolidus}L glyph${i}" >> "${dict}.txt" # 左に移動した reverse solidus
i=`expr ${i} + 1`

for S in ${latinCx[@]} # 左に移動した À-Å
do
  echo "$i ${S}L glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

for S in ${latinCz[@]} # 左に移動した Ç-Ï
do
  echo "$i ${S}L glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

for S in ${latinDx[@]} # 左に移動した Ð-ß
do
  echo "$i ${S}L glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

for S in ${latinEx[@]} # 左に移動した à-å
do
  echo "$i ${S}L glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

for S in ${latinEz[@]} # 左に移動した ç-ï
do
  echo "$i ${S}L glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

for S in ${latinFx[@]} # 左に移動した ð-ÿ
do
  echo "$i ${S}L glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

for S in ${latin17x[@]} # 左に移動した Ÿ
do
  echo "$i ${S}L glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

for S in ${latin1E9x[@]} # 左に移動した ẞ
do
  echo "$i ${S}L glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

# 右に移動した文字 ----------------------------------------

for S in ${latin[@]} # 右に移動したアルファベット
do
  echo "$i ${S}R glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

echo "$i ${solidus}R glyph${i}" >> "${dict}.txt" # 右に移動した solidus
i=`expr ${i} + 1`

echo "$i ${rSolidus}R glyph${i}" >> "${dict}.txt" # 右に移動した reverse solidus
i=`expr ${i} + 1`

for S in ${latinCx[@]} # 右に移動した À-Å
do
  echo "$i ${S}R glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

for S in ${latinCz[@]} # 右に移動した Ç-Ï
do
  echo "$i ${S}R glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

for S in ${latinDx[@]} # 右に移動した Ð-ß
do
  echo "$i ${S}R glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

for S in ${latinEx[@]} # 右に移動した à-å
do
  echo "$i ${S}R glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

for S in ${latinEz[@]} # 右に移動した ç-ï
do
  echo "$i ${S}R glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

for S in ${latinFx[@]} # 右に移動した ð-ÿ
do
  echo "$i ${S}R glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

for S in ${latin17x[@]} # 右に移動した Ÿ
do
  echo "$i ${latin17x[j]}R glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

for S in ${latin1E9x[@]} # 右に移動した ẞ
do
  echo "$i ${latin1E9x[j]}R glyph${i}" >> "${dict}.txt"
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

  if [ -n "${backtrack}" ] # 入力した文字の左側
  then
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

  if [ -n "${lookAhead}" ] # 入力した文字の右側
  then
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

# colon に関する処理 ----------------------------------------

# 両方が数字の場合 colon 上に移動
backtrack=("${number[@]}")
input=("${colon}")
lookAhead=("${number[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexU}"
index=`expr ${index} + 1`

# reverse solidus に関する処理 ----------------------------------------

# 左が、右が低い文字か A で 右が、左下が開いている文字 の場合 reverse solidus 移動しない
backtrack=("${lowRL[@]}" "${capitalAL[@]}" \
"${lowRC[@]}" "${capitalAC[@]}")
input=("${rSolidus}")
lookAhead=("${spceCapitalLC[@]}" "${spceSmallLC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右が、左下が開いている文字の場合 reverse solidus 右に移動
backtrack=("")
input=("${rSolidus}")
lookAhead=("${spceCapitalLC[@]}" "${spceSmallLC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が、右が低い文字か A で 右が寄せない文字の場合 reverse solidus 左に移動
backtrack=("${lowRL[@]}" "${capitalAL[@]}" \
"${lowRC[@]}" "${capitalAC[@]}")
input=("${rSolidus}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# solidus に関する処理 ----------------------------------------

# 左が 右下が開いている文字か W で 右が、左が低い文字か A の場合 solidus 移動しない
backtrack=("${spceCapitalRR[@]}" "${spceSmallRR[@]}" "${capitalWR[@]}" \
"${spceCapitalRC[@]}" "${spceSmallRC[@]}" "${capitalWC[@]}")
input=("${solidus}")
lookAhead=("${lowLC[@]}" "${capitalAC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が、右下が開いている文字か W の場合 solidus 左に移動
backtrack=("${spceCapitalRL[@]}" "${spceSmallRL[@]}" "${capitalWL[@]}" \
"${spceCapitalRC[@]}" "${spceSmallRC[@]}" "${capitalWC[@]}")
input=("${solidus}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が寄せない文字で 右が、左が低い文字か A の場合 solidus 右に移動
backtrack=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" \
"${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
input=("${solidus}")
lookAhead=("${lowLC[@]}" "${capitalAC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

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

# A に関する例外処理 1 ----------------------------------------

# 左が、右下が開いている大文字、右が W の場合 A 左に移動
backtrack=("${spceCapitalRR[@]}")
input=("${capitalAC[@]}")
lookAhead=("${capitalWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が W 右が、左下が開いている大文字の場合 A 右に移動
backtrack=("${capitalWR[@]}")
input=("${capitalAC[@]}")
lookAhead=("${spceCapitalLC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# A に関する例外処理 2 ----------------------------------------

# 左が、右下が開いている大文字と W の場合 A 左に移動しない
backtrack=("${spceCapitalRR[@]}" "${capitalWR[@]}")
input=("${capitalAC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が、右下が開いている大文字と W の場合 A 左に移動
backtrack=("${spceCapitalRL[@]}" "${capitalWL[@]}" \
"${spceCapitalRC[@]}" "${capitalWC[@]}")
input=("${capitalAC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右が、右下が開いている大文字と W の場合 A 右に移動
backtrack=("")
input=("${capitalAC[@]}")
lookAhead=("${spceCapitalRC[@]}" "${capitalWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# A に関する例外処理 3 ----------------------------------------

# 左が A の場合 左下が開いている大文字と W 左に移動しない
backtrack=("${capitalAR[@]}")
input=("${spceCapitalLC[@]}" "${capitalWC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が A の場合 左下が開いている大文字と W 左に移動
backtrack=("${capitalAL[@]}" \
"${capitalAC[@]}")
input=("${spceCapitalLC[@]}" "${capitalWC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右が A の場合 右下が開いている大文字と W 右に移動
backtrack=("")
input=("${spceCapitalRC[@]}" "${capitalWC[@]}")
lookAhead=("${capitalAC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左右を見て移動させない例外処理 ----------------------------------------

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

# 右が、左が丸い文字の場合 左寄りの文字 通常処理と異なり右に移動しない
backtrack=("${gravityLC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
input=("${gravityLC[@]}")
lookAhead=("${circleLC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右が、左が丸い文字の場合 中間の文字 通常処理と異なり右に移動しない
backtrack=("${gravityRC[@]}" "${gravityEC[@]}")
input=("${gravityMC[@]}")
lookAhead=("${circleLC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が幅広の文字 右が引き離す文字の場合 中寄り以外の文字と rt 移動しない
backtrack=("${gravityWL[@]}")
input=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}" "${small_rtC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が引き離す文字 右が幅広の文字の場合 中寄り以外の文字と rt 移動しない
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityRR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
input=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}" "${small_rtC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 大文字と小文字に関する例外処理 ----------------------------------------

# 左が、右下が開いている大文字 右が幅広、中寄り以外の文字の場合 左が低い文字 左に移動しない
backtrack=("${spceCapitalRR[@]}")
input=("${lowLC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が、右下が開いている大文字 右が中寄りの文字の場合 左が低い文字 左に移動しない
backtrack=("${spceCapitalRC[@]}")
input=("${lowLC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が、右下が開いている大文字の場合 左が低い文字 左に移動
backtrack=("${spceCapitalRL[@]}" \
"${spceCapitalRC[@]}")
input=("${lowLC[@]}")
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

# 左が小文字の場合 大文字 右に移動
 #backtrack=("${smallXR[@]}")
 #input=("${capitalAllC[@]}")
 #chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
 #index=`expr ${index} + 1`

# 左が丸い文字に関する例外処理 ----------------------------------------

# 左が幅広で 右が、右が丸い文字の場合 左が丸い文字 移動しない
backtrack=("${gravityWL[@]}")
input=("${circleLC[@]}")
lookAhead=("${circleRC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が、丸い文字か Xx で 右が引き寄せる文字の場合 左が丸い文字 移動しない
backtrack=("${circleCC[@]}" "${capitalXC[@]}" "${small_xC[@]}")
input=("${circleLC[@]}")
lookAhead=("${gravityVC[@]}" "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が、右が丸い文字で 右が幅広の文字場合 左が丸い文字 左に移動
backtrack=("${crclCapitalRL[@]}" \
"${circleRC[@]}")
input=("${circleLC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が、右が丸い文字で 右が引き寄せる文字の場合 左が丸い文字 右に移動
backtrack=("${crclCapitalRL[@]}" \
"${circleRC[@]}")
input=("${circleLC[@]}")
lookAhead=("${gravityVC[@]}" "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が右寄り、均等の文字の場合 左が丸い小文字 移動しない
backtrack=("${gravityRL[@]}" "${gravityEL[@]}")
input=("${crclSmallLC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が、右が丸い大文字か G の場合 左が丸い小文字 移動しない
backtrack=("${crclCapitalRL[@]}" "${capitalGL[@]}")
input=("${crclSmallLC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

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
lookAhead=("${lowLC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右が、左が低い文字の場合 f 右に移動
backtrack=("")
input=("${small_fC[@]}")
lookAhead=("${lowLC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# j に関する例外処理 ----------------------------------------

# 左が gq の場合 j 左に移動しない
backtrack=("${small_gqR[@]}")
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

# 右が幅広の文字の場合 rt 左に移動
backtrack=("")
input=("${small_rtC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# v に関する例外処理 ----------------------------------------

# 両方が丸い小文字の場合 v 移動しない
backtrack=("${crclSmallLC[@]}" "${crclSmallRC[@]}")
input=("${small_vC[@]}")
lookAhead=("${crclSmallLC[@]}" "${crclSmallRC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左を見て移動させない(絶対移動させない)通常処理 ----------------------------------------

# 左を見る 左寄りの文字、幅広な文字、均等な文字 移動しない
backtrack=("${gravityCR[@]}")
input=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左を見る 右寄りの文字、中間の文字 移動しない
backtrack=("${gravityVR[@]}" "${gravityCR[@]}")
input=("${gravityRC[@]}" "${gravityMC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左を見る 中寄りの文字 移動しない
backtrack=("${gravityLR[@]}" "${gravityMR[@]}")
input=("${gravityCC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

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

# 左右を見る 右寄りの文字 左に移動しない
backtrack=("${gravityLC[@]}" "${gravityMC[@]}")
input=("${gravityRC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
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
lookAhead=("${gravityVC[@]}" "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 中間の文字 左に移動しない
backtrack=("${gravityLC[@]}" "${gravityMC[@]}")
input=("${gravityMC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る Vの字 左に移動しない
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" "${gravityVL[@]}" \
"${gravityLC[@]}" "${gravityMC[@]}")
input=("${gravityVC[@]}")
lookAhead=("${gravityRC[@]}" "${gravityMC[@]}" "${gravityCC[@]}")
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
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}" "${gravityCC[@]}")
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
backtrack=("${gravityCL[@]}")
input=("${gravityWC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左を見る Vの字 左に移動
backtrack=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}" "${gravityVL[@]}" "${gravityCL[@]}" \
"${gravityLC[@]}" "${gravityMC[@]}" "${gravityCC[@]}")
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

# 左右を見て右に移動させない通常処理 ----------------------------------------

# 左右を見る 左寄りの文字、右に移動しない
backtrack=("${gravityLR[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityLC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
input=("${gravityLC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 右寄りの文字 右に移動しない
backtrack=("${gravityRR[@]}" "${gravityER[@]}" \
"${gravityRC[@]}" "${gravityEC[@]}")
input=("${gravityRC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 幅広な文字 右に移動しない
backtrack=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}" "${gravityVL[@]}" \
"${gravityLC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
input=("${gravityWC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 均等の文字 右に移動しない
backtrack=("${gravityLR[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityLC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
input=("${gravityEC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 中間の文字 右に移動しない
backtrack=("${gravityRR[@]}" "${gravityER[@]}" \
"${gravityRC[@]}" "${gravityEC[@]}")
input=("${gravityMC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る Vの字 右に移動しない
backtrack=("${gravityWL[@]}" \
"${gravityRR[@]}" "${gravityER[@]}" "${gravityVR[@]}" \
"${gravityRC[@]}" "${gravityEC[@]}" "${gravityVC[@]}")
input=("${gravityVC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左を見る Vの字 右に移動しない
backtrack=("${gravityLR[@]}" "${gravityMR[@]}" "${gravityCR[@]}")
input=("${gravityVC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見て右に移動させる通常処理 ----------------------------------------

# 左右を見る 中寄りの字 右に移動
backtrack=("${gravityRR[@]}" "${gravityER[@]}" "${gravityVR[@]}")
input=("${gravityCC[@]}")
lookAhead=("${gravityRC[@]}" "${gravityMC[@]}" "${gravityVC[@]}" "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左右を見る 中寄りの字 右に移動
backtrack=("${gravityWC[@]}")
input=("${gravityCC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}" "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左を見て右に移動させる通常処理 ----------------------------------------

# 左を見る 左寄りの文字、均等な文字 右に移動
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
input=("${gravityLC[@]}" "${gravityEC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左を見る 右寄りの文字、中間の文字 右に移動
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" \
"${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
input=("${gravityRC[@]}" "${gravityMC[@]}")
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

# 左を見る Vの字 右に移動
backtrack=("${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityVR[@]}" \
"${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
input=("${gravityVC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左を見る 中寄りの文字 右に移動
backtrack=("${gravityWR[@]}")
input=("${gravityCC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右が丸い大文字に関する例外処理 ----------------------------------------

## 右が引き離す文字の場合 右が丸い大文字 左に移動
backtrack=("")
input=("${crclCapitalRC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityEC[@]}" "${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右が、左が丸い文字の場合 右が丸い大文字 G 左に移動
backtrack=("")
input=("${crclCapitalRC[@]}" "${capitalGC[@]}")
lookAhead=("${circleLC[@]}")
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

# 大文字と小文字に関する例外処理 ----------------------------------------

# 右が、左が低い文字 右下が開いている大文字 右に移動
backtrack=("")
input=("${spceCapitalRC[@]}")
lookAhead=("${lowLC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右が大文字の場合 小文字 右に移動しない
backtrack=("")
input=("${smallAllC[@]}")
lookAhead=("${capitalAllC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右を見て右に移動させる通常処理 ----------------------------------------

# 右を見る 左寄りの文字、中間の文字 右に移動
backtrack=("")
input=("${gravityLC[@]}" "${gravityMC[@]}")
lookAhead=("${gravityVC[@]}" "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右を見る 右寄りの文字、均等な文字、Vの字、中寄りの文字 右に移動
backtrack=("")
input=("${gravityRC[@]}" "${gravityEC[@]}" "${gravityVC[@]}" "${gravityCC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# ---

echo "Remove temporary files"
rm -f ${listTemp}.txt
if [ "${leaving_tmp_flag}" = "false" ]
then
  rm -f ${dict}.txt
fi

echo
# Exit
echo "Finished making the GSUB table [calt, LookupType 6]."
echo
exit 0
