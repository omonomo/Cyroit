#!/bin/bash

# GSUB calt table maker
#
# Copyright (c) 2023 omonomo

# GSUB calt フィーチャテーブル作成プログラム
#
# 条件成立時に呼び出す異体字変換テーブルは font_generator で生成済み

#glyphNo="13704" # calt用異体字の先頭glyphナンバー (Nerd Fontsなし)
glyphNo="22862" # calt用異体字の先頭glyphナンバー (Nerd Fontsあり)
caltList="caltList"
listTemp="${caltList}.tmp"
dict="dict" # 略字をグリフ名に変換する辞書

# lookup の IndexNo. (GSUBフィーチャを変更すると変わる可能性あり)
lookupIndex_calt="17" # caltフィーチャ条件の先頭テーブル
lookupIndexR=`expr ${lookupIndex_calt} + 1` # 変換先(右に移動させたグリフ)
lookupIndexL=`expr ${lookupIndex_calt} + 2` # 変換先(左に移動させたグリフ)
lookupIndexC=`expr ${lookupIndex_calt} + 3` # 変換先(移動させたグリフを元に戻す)

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
            echo "Option: Set glyph number of \"A moved left\": ${OPTARG}"
            glyphNo="${OPTARG}"
            ;;
        * )
            exit 1
            ;;
    esac
done

glyphNo=`expr ${glyphNo} - 1` # zshの配列対応
# txtファイルを削除
rm -f ${caltList}.txt
rm -f ${listTemp}.txt
rm -f ${dict}.txt

# 各グリフの重心、形状の違いから、左寄り、右寄り、中央寄り、中央寄りと均等の中間、均等 (幅広)、Vの字形に分類する
gravityL=(B D E F K L P R b h k p) # 左寄り(左に右寄り、均等があると離れようとする)
gravityR=(a d g q) # 右寄り(右に左寄り、均等があると離れようとする)
gravityW=(M W m w) # 幅広通常(全てが離れようとする)
gravityE=(C G H N O Q U X Z n u x z) # 均等通常(左に右寄りか均等、幅広、右に左寄りか均等、幅広があると離れようとする)
gravityM=(S c e o s) # 中-均等の中間通常(ノーマル、離れようとしない)
gravityA=(A) # Aの字通常(左に右寄りか均等、右に左寄りか均等があると離れようとする。Vに近づこうとする)
gravityV=(T V Y v y) # Vの字通常(均等、左にある右寄り、右にある左寄り以外は近づこうとする)
gravityC=(I J f i j l r t) # 中寄り通常(全てが近づこうとする)

gravityMl=(C G c e) # 寄せ付けないやや左寄り
gravityCl=(f r t y) # 寄せ付けるやや左寄り
gravityMr=() # 寄せ付けないやや右寄り
gravityCr=(J j) # 寄せ付けるやや右寄り

capitalM=(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) # 大文字(左にある小文字に近づかない)
smallM=(a b c d e f g h i j k l m n o p q r s t u v w x y z) # 小文字(右にある大文字に近づかない)
capitalC=(T V Y I J) # 寄せ付ける大文字
smallC=(f i j l r t v y) # 寄せ付ける小文字

rC=("rC") # r 視認性向上のため特別扱い

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

for S in ${gravityA[@]}; do
  gravityAC+=("${S}C") # Aの字通常
  gravityAL+=("${S}L") # Aの字左移動後
  gravityAR+=("${S}R") # Aの字右移動後
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

for S in ${gravityMl[@]}; do
  gravityMlC+=("${S}C") # 寄せ付けないやや左寄り通常
done

for S in ${gravityCl[@]}; do
  gravityClC+=("${S}C") # 寄せ付けるやや左寄り通常
done

for S in ${gravityMr[@]}; do
  gravityMrC+=("${S}C") # 寄せ付けないやや右寄り通常
done

for S in ${gravityCr[@]}; do
  gravityCrC+=("${S}C") # 寄せ付けるやや右寄り通常
done

for S in ${capitalM[@]}; do
  capitalMC+=("${S}C") # 大文字
done

for S in ${smallM[@]}; do
  smallMC+=("${S}C") # 小文字
done

for S in ${capitalC[@]}; do
  capitalCC+=("${S}C") # 寄せ付ける大文字
done

for S in ${smallC[@]}; do
  smallCC+=("${S}C") # 寄せ付ける小文字
done

# グリフ名変換用辞書作成
# グリフ略号 (AC BC..yC zC AL BL..yL zL AR BR..yR zR 左に移動したグリフ, 右に移動したグリフ, 通常のグリフ)
# グリフ名 (A B..y z glyphXXXXX..glyphYYYYY)
alphabet=(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z \
a b c d e f g h i j k l m n o p q r s t u v w x y z)

for S in ${alphabet[@]}
do
  echo "${S}C ${S}" >> "${dict}.txt"
done
i="1"
for S in ${alphabet[@]}
do
  j=`expr ${glyphNo} + ${i}`
  echo "${S}L glyph${j}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done
for S in ${alphabet[@]}
do
  j=`expr ${glyphNo} + ${i}`
  echo "${S}R glyph${j}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

# 略号を名前に変換する関数
glyph_name() {
  word=`grep "^${1}" "${dict}.txt" | head -n 1 | cut -d ' ' -f 2`
  echo "${word}"
}

# LookupType 6 を作成するための関数
chain_context() {
  local substIndex
  local backtrack
  local input
  local lookAhead
  local lookupIndex
  substIndex=("${1}")
  backtrack=("${2}")
  input=("${3}")
  lookAhead=("${4}")
  lookupIndex="${5}"

  echo "Make index ${substIndex}"

  echo "<ChainContextSubst index=\"${substIndex}\" Format=\"3\">" >> "${caltList}.txt"

  if [ -n "${backtrack}" ] # 入力した文字の左側
  then
    echo "<BacktrackCoverage index=\"0\">" >> "${caltList}.txt"
    rm -f ${listTemp}.txt
    for S in ${backtrack[@]}
    do
      T=`glyph_name "${S}"` # 略号からグリフ名を取得
      if [ ${#T} -eq 1 ] # IDS順に正しくソートさせるための判定
      then
        echo " <Glyph value=\"${T}\"/>" >> "${listTemp}.txt" # グリフ名が1文字の場合
      else
        echo "<Glyph value=\"${T}\"/>" >> "${listTemp}.txt"
      fi
    done
    sort "${listTemp}.txt" >> "${caltList}.txt" # ソートしないとttxにしかられる
    echo "</BacktrackCoverage>" >> "${caltList}.txt"
  fi

  echo "<InputCoverage index=\"0\">" >> "${caltList}.txt"
  rm -f ${listTemp}.txt
  for S in ${input[@]} ## 入力した文字(グリフ変換対象)
  do
    T=`glyph_name "${S}"`
    if [ ${#T} -eq 1 ]
    then
      echo " <Glyph value=\"${T}\"/>" >> "${listTemp}.txt"
    else
      echo "<Glyph value=\"${T}\"/>" >> "${listTemp}.txt"
    fi
  done
  sort "${listTemp}.txt" >> "${caltList}.txt"
  echo "</InputCoverage>" >> "${caltList}.txt"

  if [ -n "${lookAhead}" ] # 入力した文字の右側
  then
    echo "<LookAheadCoverage index=\"0\">" >> "${caltList}.txt"
    rm -f ${listTemp}.txt
    for S in ${lookAhead[@]}
    do
      T=`glyph_name "${S}"`
      if [ ${#T} -eq 1 ]
      then
        echo " <Glyph value=\"${T}\"/>" >> "${listTemp}.txt"
      else
        echo "<Glyph value=\"${T}\"/>" >> "${listTemp}.txt"
      fi
    done
    sort "${listTemp}.txt" >> "${caltList}.txt"
    echo "</LookAheadCoverage>" >> "${caltList}.txt"
  fi

  echo "<SubstLookupRecord index=\"0\">" >> "${caltList}.txt" # 条件がそろった時に指定したテーブルを元にグリフ置換
   echo "<SequenceIndex value=\"0\"/>" >> "${caltList}.txt"
   echo "<LookupListIndex value=\"${lookupIndex}\"/>" >> "${caltList}.txt"
  echo "</SubstLookupRecord>" >> "${caltList}.txt"

  echo "</ChainContextSubst>" >> "${caltList}.txt"
}

# メインルーチン
echo "Make GSUB calt List"

echo "<LookupType value=\"6\"/>" >> "${caltList}.txt"
echo "<LookupFlag value=\"0\"/>" >> "${caltList}.txt"

index="0"
# <==> ><

# 左右を見る 両方が少し右に寄っている文字 右、中寄り以外の文字 移動しない
backtrack=("${gravityCrC[@]}")
input=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityAC[@]}" "${gravityVC[@]}")
lookAhead=("${gravityRC[@]}" "${gravityMrC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 両方が少し左に寄っている文字 左、中寄り以外の文字 移動しない
backtrack=("${gravityLC[@]}" "${gravityMlC[@]}")
input=("${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityAC[@]}" "${gravityVC[@]}")
lookAhead=("${gravityClC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 両方寄せ付ける文字の場合 左右に寄っていない文字 移動しない
backtrack=("${gravityVC[@]}")
input=("${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityAC[@]}" "${gravityVC[@]}" "${gravityCC[@]}")
lookAhead=("${gravityVC[@]}" "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 両方寄せ付ける文字の場合 左右に寄っていない文字 移動しない
backtrack=("${gravityCC[@]}")
input=("${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityAC[@]}" "${gravityVC[@]}" "${gravityCC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見る 左がすでに逃げている となりが移動していない時でも逃げる文字 移動しない
backtrack=("${gravityWL[@]}" "${gravityEL[@]}" "${gravityRL[@]}")
input=("${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityAC[@]}")
lookAhead=("${gravityWC[@]}" "${gravityEC[@]}" "${gravityLC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# <=== ><

# 左を見る 大文字 移動しない
backtrack=("${smallCC[@]}")
input=("${capitalMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexC}"
index=`expr ${index} + 1`

# ===> ><

# 右を見る 小文字 移動しない
input=("${smallMC[@]}")
lookAhead=("${capitalCC[@]}")
chain_context "${index}" "" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# <=== ><

# 左を見る いろいろ 移動しない
backtrack=("${rC[@]}")
input=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexC}"
index=`expr ${index} + 1`

# <=== <-

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

# 左を見る 中間の文字 左に移動
for i in ${!gravityM[@]}
do
  backtrack="${gravityML[$i]}"
  input="${gravityMC[$i]}"
  chain_context "${index}" "${backtrack}" "${input}" "" "${lookupIndexL}"
  index=`expr ${index} + 1`
done

# 左を見る Aの字 左に移動
for i in ${!gravityA[@]}
do
  backtrack="${gravityAL[$i]}"
  input="${gravityAC[$i]}"
  chain_context "${index}" "${backtrack}" "${input}" "" "${lookupIndexL}"
  index=`expr ${index} + 1`
done

# <=== <-

# 左を見る 左寄りの文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityCL[@]}" "${gravityCC[@]}")
input=("${gravityLC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左を見る 右寄りの文字 左に移動
backtrack=("${gravityRL[@]}" "${gravityLL[@]}" "${gravityML[@]}" "${gravityVL[@]}" "${gravityVC[@]}" "${gravityCL[@]}" "${gravityCC[@]}")
input=("${gravityRC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左を見る 幅広な文字 左に移動
backtrack=("${gravityCL[@]}")
#backtrack=("${gravityWL[@]}" "${gravityCL[@]}")
input=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左を見る 均等な文字 左に移動
backtrack=("${gravityCL[@]}" "${gravityCC[@]}")
#backtrack=("${gravityEL[@]}" "${gravityCL[@]}" "${gravityCC[@]}")
input=("${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左を見る 中間の文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityVL[@]}" "${gravityVC[@]}" "${gravityCL[@]}" "${gravityCC[@]}")
#backtrack=("${gravityML[@]}" "${gravityLL[@]}" "${gravityVL[@]}" "${gravityVC[@]}" "${gravityCL[@]}" "${gravityCC[@]}")
input=("${gravityMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左を見る Aの字 左に移動
backtrack=("${gravityVL[@]}" "${gravityVC[@]}" "${gravityCL[@]}" "${gravityCC[@]}")
#backtrack=("${gravityAL[@]}" "${gravityVL[@]}" "${gravityVC[@]}" "${gravityCL[@]}" "${gravityCC[@]}")
input=("${gravityAC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左を見る Vの字 左に移動
backtrack=("${gravityVL[@]}" "${gravityLL[@]}" "${gravityML[@]}" "${gravityAL[@]}" "${gravityCL[@]}" "${gravityLC[@]}" "${gravityMC[@]}" "${gravityAC[@]}" "${gravityCC[@]}")
input=("${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左を見る 中寄りの文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityWL[@]}" "${gravityEL[@]}" "${gravityML[@]}" "${gravityAL[@]}" "${gravityVL[@]}" "${gravityCL[@]}" "${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityAC[@]}" "${gravityVC[@]}" "${gravityCC[@]}")
input=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexL}"
index=`expr ${index} + 1`

# <=== ->

# 左を見る 左寄りの文字、均等な文字 右に移動
backtrack=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityAR[@]}" "${gravityVR[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityRC[@]}")
input=("${gravityLC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左を見る 右寄りの文字 右に移動
backtrack=("${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityAR[@]}" "${gravityWC[@]}")
input=("${gravityRC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左を見る 幅広な文字 右に移動
backtrack=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityAR[@]}" "${gravityVR[@]}" "${gravityCR[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityRC[@]}")
input=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左を見る 中間の文字 右に移動
backtrack=("${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityAR[@]}" "${gravityWC[@]}")
input=("${gravityMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左を見る Aの字 右に移動
backtrack=("${gravityAR[@]}" "${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityRC[@]}")
input=("${gravityAC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左を見る Vの字 右に移動
backtrack=("${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityVR[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityRC[@]}")
input=("${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左を見る 中寄りの文字 右に移動
backtrack=("${gravityWR[@]}")
input=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexR}"
index=`expr ${index} + 1`

# <=== ><

# 左を見る 左寄りの文字 移動しない
backtrack=("${gravityML[@]}")
input=("${gravityLC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左を見る 右寄りの文字 移動しない
backtrack=("${gravityEL[@]}" "${gravityAL[@]}")
input=("${gravityRC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左を見る 均等な文字 移動しない
backtrack=("${gravityEL[@]}" "${gravityLL[@]}" "${gravityML[@]}")
#backtrack=("${gravityLL[@]}" "${gravityML[@]}")
input=("${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左を見る 中間の文字 移動しない
backtrack=("${gravityML[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityAL[@]}")
#backtrack=("${gravityRL[@]}" "${gravityEL[@]}" "${gravityAL[@]}")
input=("${gravityMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左を見る Aの字 移動しない
backtrack=("${gravityAL[@]}" "${gravityLL[@]}" "${gravityML[@]}")
#backtrack=("${gravityLL[@]}" "${gravityML[@]}")
input=("${gravityAC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexC}"
index=`expr ${index} + 1`

# <=== ><

# 左を見る Vの字 移動しない
backtrack=("${gravityLR[@]}" "${gravityMR[@]}" "${gravityAR[@]}" "${gravityCR[@]}")
input=("${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左を見る 中寄りの文字 移動しない
backtrack=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityAR[@]}" "${gravityVR[@]}" "${gravityCR[@]}")
input=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "" "${lookupIndexC}"
index=`expr ${index} + 1`

# ===> ->

# 右を見る 右寄りの文字、均等な文字 右に移動
input=("${gravityRC[@]}" "${gravityEC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右を見る 左寄りの文字、中間の文字、Aの字 右に移動
input=("${gravityLC[@]}" "${gravityMC[@]}" "${gravityAC[@]}")
lookAhead=("${gravityVC[@]}" "${gravityCC[@]}")
chain_context "${index}" "" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右を見る Vの字 右に移動
input=("${gravityVC[@]}")
lookAhead=("${gravityRC[@]}" "${gravityMC[@]}" "${gravityAC[@]}" "${gravityCC[@]}")
chain_context "${index}" "" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右を見る 中寄りの文字 右に移動
input=("${gravityCC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityAC[@]}" "${gravityVC[@]}" "${gravityCC[@]}")
chain_context "${index}" "" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# ===> <-

# 右を見る 中寄り以外の文字 左に移動
input=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityAC[@]}" "${gravityVC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
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
