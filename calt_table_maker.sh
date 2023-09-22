#!/bin/bash

# GSUB calt table maker
#
# Copyright (c) 2023 omonomo

# GSUB calt フィーチャテーブル作成プログラム
#
# 条件成立時に呼び出す異体字変換テーブルは font_generator で生成

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
# 各グリフの重心、形状の違いから、左寄り、右寄り、中央寄り、中央寄りと均等の中間、均等、幅広、Vの字形に分類する
gravityL=(B D E F K L P R b h k p) # 左寄り(左に右寄り、幅広、均等があると離れようとする)
gravityR=(C G a c d g q) # 右寄り(右に左寄り、幅広、均等があると離れようとする)
gravityW=(M W m w) # 幅広(全てが離れようとする)
gravityE=(H N O Q U n u) # 均等(左に右寄りか均等、幅広、右に左寄りか均等、幅広があると離れようとする)
gravityM=(A S X Z e o s x z) # 基本的には幅広以外からは離れようとしない
gravityV=(T V Y v y) # Vの字(幅広、均等、左にある右寄り、右にある左寄り以外は近づこうとする)
gravityC=(I J f i j l r t) # 中寄り(全てが近づこうとする)

gravity_rC=(J j) # 引き寄せるやや右寄り
gravity_rM=(j) # 引き寄せさせないやや右寄り

gravity_lM=(e t) # 引き寄せさせないやや左寄り
gravity_lC=(f r t) # 引き寄せるやや左寄り

circleL=(C G O Q c d e g o q) # 左が丸い文字
circleR=(D O Q b e o p) # 右が丸い文字

smallL=(a b c d e f g h i j k l m n o p q r s t u v w x y z) # 小文字
smallM=(b e f h i j k l o p r s t v x y z) # 右を引き離さない小文字
smallR=(f l) # 引き寄せる背の高い小文字
capital=(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) # 大文字

for S in ${gravityL[@]}; do
  gravityLC+=("${S}C") # 左寄り通常
  gravityLL+=("${S}L") # 左寄り左移動後
  gravityLR+=("${S}R") # 左寄り右移動後
done

for S in ${gravityR[@]}; do
  gravityRC+=("${S}C") # 右寄り通常
  gravityRL+=("${S}L") # 右寄り左移動後
  gravityRR+=("${S}R") # 右寄り右移動後
done

for S in ${gravityW[@]}; do
  gravityWC+=("${S}C") # 幅広通常
  gravityWL+=("${S}L") # 幅広左移動後
  gravityWR+=("${S}R") # 幅広右移動後
done

for S in ${gravityE[@]}; do
  gravityEC+=("${S}C") # 均等通常
  gravityEL+=("${S}L") # 均等左移動後
  gravityER+=("${S}R") # 均等右移動後
done

for S in ${gravityM[@]}; do
  gravityMC+=("${S}C") # 中間通常
  gravityML+=("${S}L") # 中間左移動後
  gravityMR+=("${S}R") # 中間右移動後
done

for S in ${gravityV[@]}; do
  gravityVC+=("${S}C") # Vの字通常
  gravityVL+=("${S}L") # Vの字左移動後
  gravityVR+=("${S}R") # Vの字右移動後
done

for S in ${gravityC[@]}; do
  gravityCC+=("${S}C") # 中寄り通常
  gravityCL+=("${S}L") # 中寄り左移動後
  gravityCR+=("${S}R") # 中寄り右移動後
done

for S in ${gravity_rM[@]}; do
  gravity_rMC+=("${S}C") # 引き寄せないやや右寄り
done

for S in ${gravity_rC[@]}; do
  gravity_rCC+=("${S}C") # 引き寄せるやや右寄り
done

for S in ${gravity_lM[@]}; do
  gravity_lMC+=("${S}C") # 引き寄せないやや左寄り
done

for S in ${gravity_lC[@]}; do
  gravity_lCC+=("${S}C") # 引き寄せるやや左寄り
done

for S in ${circleL[@]}; do
  circleLC+=("${S}C") # 左が丸い文字
done

for S in ${circleR[@]}; do
  circleRC+=("${S}C") # 右が丸い文字
done

for S in ${smallL[@]}; do
  smallML+=("${S}L") # 小文字左移動後
done

for S in ${smallM[@]}; do
  smallMC+=("${S}C") # 右を引き離さない小文字通常
done

for S in ${smallR[@]}; do
  smallMR+=("${S}R") # 引き寄せる背の高い小文字右移動後
done

for S in ${capital[@]}; do
  capitalMC+=("${S}C") # 大文字
done

# グリフ名変換用辞書作成 (グリフのIDS順に並べること) ========================================
number=(0 1 2 3 4 5 6 7 8 9) # 略号
number_name=("zero" "one" "two" "three" "four" "five" "six" "seven" "eight" "nine") # 実際の名前

colon=":"
colon_name="colon"

# グリフ略号 (AC BC..yC zC AL BL..yL zL AR BR..yR zR 左に移動したグリフ, 右に移動したグリフ, 通常のグリフ)
# グリフ名 (A B..y z glyphXXXXX..glyphYYYYY)
latin=(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z \
a b c d e f g h i j k l m n o p q r s t u v w x y z) # 略号の始めの文字

i=0
for j in ${!number[@]} # 数字
do
  echo "$i ${number[j]} ${number_name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

echo "$i ${colon} ${colon_name}" >> "${dict}.txt"
i=`expr ${i} + 1`

for S in ${latin[@]} # 移動していないアルファベット
do
  echo "$i ${S}C ${S}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

i=${glyphNo}
for S in ${latin[@]} # 左に移動したアルファベット
do
  echo "$i ${S}L glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

for S in ${latin[@]} # 右に移動したアルファベット
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

# 左右を見て上に移動させる通常処理 ----------------------------------------

# 左右を見る 両方が数字の場合 コロン 上に移動する
backtrack=("${number[@]}")
input=("${colon[@]}")
lookAhead=("${number[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexU}"
index=`expr ${index} + 1`

# 左を見て左に移動させない例外処理 ----------------------------------------

# 左が小文字の場合 大文字 左に移動しない
backtrack=("${smallML[@]}" "${smallMC[@]}")
input=("${capitalMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左を見て右に移動させる例外処理 ----------------------------------------

# 左が小文字の場合 大文字 右に移動する
backtrack=("${smallMR[@]}")
input=("${capitalMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左右を見て移動させない例外処理 ----------------------------------------

# 左右を見る 両方が少しでも右に寄っている文字の場合 左寄りの文字他 左に移動しない
backtrack=("${gravity_rCC[@]}")
input=("${gravityLC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
lookAhead=("${gravityRC[@]}" "${gravity_rMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 両方が少しでも左に寄っている文字の場合 右寄りの文字他 右に移動しない
backtrack=("${gravityLC[@]}" "${gravity_lMC[@]}")
input=("${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
lookAhead=("${gravity_lCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 左が幅広、右が右が丸い文字 左が丸い文字 移動しない
backtrack=("${gravityWL[@]}")
input=("${circleLC[@]}")
lookAhead=("${circleRC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 左が引き離す文字 右が幅広の文字の場合 幅広な文字、左寄りの文字、均等な文字、中間の文字 移動しない
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityER[@]}" "${gravityMR[@]}" \
"${gravityWC[@]}")
input=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左を見て左に移動させる例外処理 (同じ文字は等間隔にする) ----------------------------------------

# 左を見る 幅広な文字 左に移動
for i in ${!gravityW[@]}
do
  backtrack="${gravityWL[$i]}"
  input="${gravityWC[$i]}"
  chain_context "${index}" "${backtrack}" "${input}" "" "${lookupIndexL}"
  index=`expr ${index} + 1`
done

# 左を見る 均等な文字 左に移動
for i in ${!gravityE[@]}
do
  backtrack="${gravityEL[$i]}"
  input="${gravityEC[$i]}"
  chain_context "${index}" "${backtrack}" "${input}" "" "${lookupIndexL}"
  index=`expr ${index} + 1`
done

# 左を見て右に移動させる例外処理 (同じ文字は等間隔にする) ----------------------------------------

# 左を見る 中寄りの文字 右に移動
for i in ${!gravityC[@]}
do
  backtrack="${gravityCR[$i]}"
  input="${gravityCC[$i]}"
  chain_context "${index}" "${backtrack}" "${input}" "" "${lookupIndexR}"
  index=`expr ${index} + 1`
done

# 左を見て移動させない例外処理 (同じ文字は等間隔にする) ----------------------------------------

# 左を見る 左寄りの文字 移動しない
for i in ${!gravityL[@]}
do
  backtrack="${gravityLC[$i]}"
  input="${gravityLC[$i]}"
  chain_context "${index}" "${backtrack}" "${input}" "" "${lookupIndexC}"
  index=`expr ${index} + 1`
done

# 左を見る 右寄りの文字 移動しない
for i in ${!gravityR[@]}
do
  backtrack="${gravityRC[$i]}"
  input="${gravityRC[$i]}"
  chain_context "${index}" "${backtrack}" "${input}" "" "${lookupIndexC}"
  index=`expr ${index} + 1`
done

# 左を見て移動させない(絶対移動させない)通常処理 ----------------------------------------

# 左を見る 左寄りの文字、幅広な文字、均等な文字 移動しない
backtrack=("${gravityCR[@]}")
input=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左を見る 右寄りの文字、中間の文字 移動しない
backtrack=("${gravityVR[@]}" "${gravityCR[@]}" \
"${gravityLC[@]}" "${gravityMC[@]}")
input=("${gravityRC[@]}" "${gravityMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左を見る Vの字 移動しない
backtrack=("${gravityLR[@]}" "${gravityMR[@]}" "${gravityCR[@]}")
input=("${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左を見る 中寄りの文字 移動しない
backtrack=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}" "${gravityCR[@]}")
input=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexC}"
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

# 左右を見る Vの字 左に移動しない
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" "${gravityVL[@]}" \
"${gravityLC[@]}" "${gravityMC[@]}")
input=("${gravityVC[@]}")
lookAhead=("${gravityRC[@]}" "${gravityMC[@]}" "${gravityCC[@]}")
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
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左を見る 右寄りの文字、中間の文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}" "${gravityVL[@]}" "${gravityCL[@]}" \
"${gravityVC[@]}" "${gravityCC[@]}")
input=("${gravityRC[@]}" "${gravityMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左を見る 幅広な文字 左に移動
backtrack=("${gravityCL[@]}")
input=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左を見る Vの字 左に移動
backtrack=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}" "${gravityVL[@]}" "${gravityCL[@]}" \
"${gravityLC[@]}" "${gravityMC[@]}" "${gravityCC[@]}")
input=("${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左を見る 中寄りの文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityWL[@]}" "${gravityEL[@]}" "${gravityML[@]}" "${gravityVL[@]}" "${gravityCL[@]}" \
"${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}" "${gravityCC[@]}")
input=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左右を見て右に移動させない通常処理 ----------------------------------------

# 左右を見る 左寄りの文字、右に移動しない
backtrack=("${gravityLR[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityLC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
input=("${gravityLC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 右寄りの文字 右に移動しない
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityRR[@]}" "${gravityER[@]}" "${gravityMR[@]}" \
"${gravityRC[@]}" "${gravityEC[@]}")
input=("${gravityRC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 幅広な文字 右に移動しない
backtrack=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}" "${gravityVL[@]}" \
"${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}" )
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
backtrack=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityER[@]}" "${gravityMR[@]}" \
"${gravityRC[@]}" "${gravityEC[@]}")
input=("${gravityMC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
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

# 左右を見て右に移動させる通常処理 ----------------------------------------

# 左右を見る 中寄りの字 右に移動する
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
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左を見る 右寄りの文字、中間の文字 右に移動
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" \
"${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
input=("${gravityRC[@]}" "${gravityMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左を見る 幅広な文字 右に移動
backtrack=("${gravityRL[@]}" "${gravityWL[@]}" "${gravityEL[@]}" \
"${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
input=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左を見る Vの字 右に移動
backtrack=("${gravityWL[@]}" \
"${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityVR[@]}" \
"${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
input=("${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左を見る 中寄りの文字 右に移動
backtrack=("${gravityWR[@]}")
input=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右を見て左に移動させる通常処理 ----------------------------------------

# 右を見る 左寄りの文字、中間の文字、Vの字 左に移動
input=("${gravityLC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右を見る 右寄りの文字、均等な文字 左に移動
input=("${gravityRC[@]}" "${gravityEC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
chain_context "${index}" "" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右を見る 幅広の文字 左に移動
input=("${gravityWC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右を見て右に移動させる通常処理 ----------------------------------------

# 右を見る 左寄りの文字、中間の文字 右に移動
input=("${gravityLC[@]}" "${gravityMC[@]}")
lookAhead=("${gravityVC[@]}" "${gravityCC[@]}")
chain_context "${index}" "" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右を見る 右寄りの文字、均等な文字、Vの字、中寄りの文字 右に移動
input=("${gravityRC[@]}" "${gravityEC[@]}" "${gravityVC[@]}" "${gravityCC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
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
