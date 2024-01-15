#!/bin/bash

# GSUB calt table maker
#
# Copyright (c) 2023 omonomo

# GSUB calt フィーチャテーブル作成プログラム
#
# 条件成立時に呼び出す異体字変換テーブルは font_generator にて生成済みであること

 #glyphNo="13706" # デフォルトのcalt用異体字の先頭glyphナンバー (Nerd Fontsなし)
glyphNo="22940" # デフォルトのcalt用異体字の先頭glyphナンバー (Nerd Fontsあり)
listNo="0"
caltL="caltList" # caltテーブルリストの名称
caltList="${caltL}_${listNo}" # Lookupごとのcaltテーブルリスト
listTemp="${caltL}.tmp"
dict="dict" # 略字をグリフ名に変換する辞書
gsubList="gsubList" # 作成フォントのGSUBから抽出した置き換え用リスト

# lookup の IndexNo. (GSUBを変更すると変わる可能性あり)
lookupIndex_replace="36" # caltの置き換え先の先頭テーブル
lookupIndexU=`expr ${lookupIndex_replace}` # 変換先(上に移動させた記号のグリフ)
lookupIndexD=`expr ${lookupIndex_replace} + 1` # 変換先(下に移動させた記号のグリフ)
lookupIndexRR=`expr ${lookupIndex_replace} + 2` # 変換先(右に移動させた記号のグリフ)
lookupIndexLL=`expr ${lookupIndex_replace} + 3` # 変換先(左に移動させた記号のグリフ)
lookupIndex0=`expr ${lookupIndex_replace} + 4` # 変換先(小数のグリフ)
lookupIndex2=`expr ${lookupIndex_replace} + 5` # 変換先(12桁マークを付けたグリフ)
lookupIndex4=`expr ${lookupIndex_replace} + 6` # 変換先(4桁マークを付けたグリフ)
lookupIndex3=`expr ${lookupIndex_replace} + 7` # 変換先(3桁マークを付けたグリフ)
lookupIndexR=`expr ${lookupIndex_replace} + 8` # 変換先(右に移動させたグリフ)
lookupIndexL=`expr ${lookupIndex_replace} + 9` # 変換先(左に移動させたグリフ)
lookupIndexN=`expr ${lookupIndex_replace} + 10` # 変換先(ノーマルなグリフに戻す)

leaving_tmp_flag="false" # 一時ファイル残す
basic_only_flag="false" # 基本ラテン文字のみ
symbol_only_flag="false" # 記号、桁区切りのみ
glyphNo_flag="false" # glyphナンバーの指定があるか

# エラー処理
trap "exit 3" HUP INT QUIT

remove_temp() {
  echo "Remove temporary files"
  rm -f ${dict}.txt
}

calt_table_maker_help()
{
    echo "Usage: calt_table_maker.sh [options]"
    echo ""
    echo "Options:"
    echo "  -h         Display this information"
    echo "  -x         Cleaning temporary files" # 一時作成ファイルの消去のみ
    echo "  -l         Leave (do NOT remove) temporary files"
    echo "  -n number  Set glyph number of \"A moved left\""
    echo "  -b         Make calt settings for basic Latin characters only"
    echo "  -s         Don't Make calt settings for Latin characters"
    exit 0
}

echo
echo "- GSUB table [calt, LookupType 6] maker -"
echo

# Get options
while getopts hxln:bs OPT
do
    case "${OPT}" in
        "h" )
            calt_table_maker_help
            ;;
        "x" )
            echo "Option: Cleaning temporary files"
            remove_temp
            exit 0
            ;;
        "l" )
            echo "Option: Leave (do NOT remove) temporary files"
            leaving_tmp_flag="true"
            ;;
        "n" )
            echo "Option: Set glyph number of \"A moved left\": glyph${OPTARG}"
            glyphNo_flag="true"
            glyphNo="${OPTARG}"
            ;;
        "b" )
            echo "Option: Make calt settings for basic Latin characters only"
            basic_only_flag="true"
            ;;
        "s" )
            echo "Option: Don't Make calt settings for Latin characters"
            symbol_only_flag="true"
            ;;
        * )
            exit 1
            ;;
    esac
done
echo

if [ "${glyphNo_flag}" = "false" ]; then
  gsubList_txt=`find . -name "${gsubList}.txt" -maxdepth 1 | head -n 1`
  if [ -n "${gsubList_txt}" ]; then # gsubListがあり、
    echo "Found GSUB List"
    caltNo=`grep 'Substitution in="A"' "${gsubList}.txt"`
    if [ -n "${caltNo}" ]; then # calt用の異体字があった場合gSubListからglyphナンバーを取得
      temp=${caltNo##*glyph} # glyphナンバーより前を削除
      glyphNo=${temp%\"*} # glyphナンバーより後を削除してオフセット値追加
      echo "Found glyph number of \"A moved left\": glyph${glyphNo}"
    else
      echo "Not found glyph number of \"A moved left\""
      echo "Use default number"
      echo
    fi
  else
    echo "Not found GSUB List"
    echo "Use default number"
    echo
  fi
fi

# txtファイルを削除
rm -f ${caltL}*.txt
rm -f ${listTemp}.txt
rm -f ${dict}.txt

# [@]なしで 同じ基底文字のメンバーを取得する関数 ||||||||||||||||||||||||||||||||||||||||

letter_members() {
  local class
  local member
  class=("${1}")
  member=("")

if [ -n "${class}" ]; then
  for S in ${class[@]}; do
      eval "member+=(\"\${${S}[@]}\")"
  done
  echo "${member[@]}"
fi
}

# 略号を通し番号と名前に変換する関数 ||||||||||||||||||||||||||||||||||||||||

glyph_name() {
  number=`grep " ${1} " "${dict}.txt" | head -n 1 | cut -d ' ' -f 1`
  word=`grep " ${1} " "${dict}.txt" | head -n 1 | cut -d ' ' -f 3`
  echo "${number} ${word}"
}

# LookupType 6 を作成するための関数 ||||||||||||||||||||||||||||||||||||||||

chain_context() {
  local substIndex
  local backtrack
  local input
  local lookAhead
  local lookupIndex
  local backtrack1
  local lookAhead1
  local lookAheadX
  local aheadMax
  substIndex="${1}"
  backtrack=("${2}")
  input=("${3}")
  lookAhead=("${4}")
  lookupIndex="${5}"
  backtrack1=("${6}")
  lookAhead1=("${7}")
  lookAheadX=("${8}")
  aheadMax="${9}" # lookAheadのIndex2以降はその数(最大のIndexNo)を入れる(当然内容は全て同じになる)

  echo "Make ${caltList} index ${substIndex}: Lookup = ${lookupIndex}"

  echo "<ChainContextSubst index=\"${substIndex}\" Format=\"3\">" >> "${caltList}.txt"

  if [ -n "${backtrack}" ]; then # 入力した文字の左側
    echo "<BacktrackCoverage index=\"0\">" >> "${caltList}.txt"
    rm -f ${listTemp}.txt
    for S in ${backtrack[@]}; do
      T=`glyph_name "${S}"` # 略号から通し番号とグリフ名を取得
      echo "${T}" >> "${listTemp}.txt"
    done
    sort -n -u "${listTemp}.txt" | while read line # ソートしないとttxにしかられる
    do
      T=`echo "${line}" | cut -d ' ' -f 2`
      echo "<Glyph value=\"${T}\"/>" >> "${caltList}.txt"
    done
    echo "</BacktrackCoverage>" >> "${caltList}.txt"
  fi

  if [ -n "${backtrack1}" ]; then # 入力した文字の左側2つ目
    echo "<BacktrackCoverage index=\"1\">" >> "${caltList}.txt"
    rm -f ${listTemp}.txt
    for S in ${backtrack1[@]}; do
      T=`glyph_name "${S}"` # 略号から通し番号とグリフ名を取得
      echo "${T}" >> "${listTemp}.txt"
    done
    sort -n -u "${listTemp}.txt" | while read line # ソートしないとttxにしかられる
    do
      T=`echo "${line}" | cut -d ' ' -f 2`
      echo "<Glyph value=\"${T}\"/>" >> "${caltList}.txt"
    done
    echo "</BacktrackCoverage>" >> "${caltList}.txt"
  fi

# ---

  echo "<InputCoverage index=\"0\">" >> "${caltList}.txt" # 入力した文字(グリフ変換対象)
  rm -f ${listTemp}.txt
  for S in ${input[@]}; do
#    T=`printf '%s\n' "${fixedGlyphN[@]}" | grep -x "${S}"` # 移動 (置換) しない文字を除く
#    if [ -z "${T}" ]; then # (有効にするとデータ量が減るが、逆に何故か Overfrow エラーが出る)
      T=`glyph_name "${S}"` # 略号から通し番号とグリフ名を取得
      echo "${T}" >> "${listTemp}.txt"
#    fi
  done
  sort -n -u "${listTemp}.txt" | while read line # ソートしないとttxにしかられる
  do
    T=`echo "${line}" | cut -d ' ' -f 2`
    echo "<Glyph value=\"${T}\"/>" >> "${caltList}.txt"
  done
  echo "</InputCoverage>" >> "${caltList}.txt"

  if [ -n "${lookAhead}" ]; then # 入力した文字の右側
    echo "<LookAheadCoverage index=\"0\">" >> "${caltList}.txt"
    rm -f ${listTemp}.txt
    for S in ${lookAhead[@]}; do
      T=`glyph_name "${S}"` # 略号から通し番号とグリフ名を取得
      echo "${T}" >> "${listTemp}.txt"
    done
    sort -n -u "${listTemp}.txt" | while read line # ソートしないとttxにしかられる
    do
      T=`echo "${line}" | cut -d ' ' -f 2`
      echo "<Glyph value=\"${T}\"/>" >> "${caltList}.txt"
    done
    echo "</LookAheadCoverage>" >> "${caltList}.txt"
  fi

# ---

  if [ -n "${lookAhead1}" ]; then # 入力した文字の右側2つ目
    echo "<LookAheadCoverage index=\"1\">" >> "${caltList}.txt"
    rm -f ${listTemp}.txt
    for S in ${lookAhead1[@]}; do
      T=`glyph_name "${S}"` # 略号から通し番号とグリフ名を取得
      echo "${T}" >> "${listTemp}.txt"
    done
    sort -n -u "${listTemp}.txt" | while read line # ソートしないとttxにしかられる
    do
      T=`echo "${line}" | cut -d ' ' -f 2`
      echo "<Glyph value=\"${T}\"/>" >> "${caltList}.txt"
    done
    echo "</LookAheadCoverage>" >> "${caltList}.txt"
  fi

  if [ -n "${lookAheadX}" ]; then # 入力した文字の右側3つ目以降
    for i in `seq 2 "${aheadMax}"`; do
      echo "<LookAheadCoverage index=\"${i}\">" >> "${caltList}.txt"
      rm -f ${listTemp}.txt
      for S in ${lookAheadX[@]}; do
        T=`glyph_name "${S}"` # 略号から通し番号とグリフ名を取得
        echo "${T}" >> "${listTemp}.txt"
      done
      sort -n -u "${listTemp}.txt" | while read line # ソートしないとttxにしかられる
      do
        T=`echo "${line}" | cut -d ' ' -f 2`
        echo "<Glyph value=\"${T}\"/>" >> "${caltList}.txt"
      done
      echo "</LookAheadCoverage>" >> "${caltList}.txt"
    done
  fi

  echo "<SubstLookupRecord index=\"0\">" >> "${caltList}.txt" # 条件がそろった時にジャンプするテーブル番号
  echo "<SequenceIndex value=\"0\"/>" >> "${caltList}.txt"
  echo "<LookupListIndex value=\"${lookupIndex}\"/>" >> "${caltList}.txt"
  echo "</SubstLookupRecord>" >> "${caltList}.txt"

  echo "</ChainContextSubst>" >> "${caltList}.txt"
}

# グリフ略号 作成 ||||||||||||||||||||||||||||||||||||||||

class=("")
if [ "${basic_only_flag}" = "true" ]; then
  S="_A"; class+=("${S}"); eval ${S}=\(A\) # A
  S="_B"; class+=("${S}"); eval ${S}=\(B\) # B
  S="_C"; class+=("${S}"); eval ${S}=\(C\) # C
  S="_D"; class+=("${S}"); eval ${S}=\(D\) # D
  S="_E"; class+=("${S}"); eval ${S}=\(E\) # E
  S="_F"; class+=("${S}"); eval ${S}=\(F\) # F
  S="_G"; class+=("${S}"); eval ${S}=\(G\) # G
  S="_H"; class+=("${S}"); eval ${S}=\(H\) # H
  S="_I"; class+=("${S}"); eval ${S}=\(I\) # I
  S="_J"; class+=("${S}"); eval ${S}=\(J\) # J
  S="_K"; class+=("${S}"); eval ${S}=\(K\) # K
  S="_L"; class+=("${S}"); eval ${S}=\(L\) # L
  S="_M"; class+=("${S}"); eval ${S}=\(M\) # M
  S="_N"; class+=("${S}"); eval ${S}=\(N\) # N
  S="_O"; class+=("${S}"); eval ${S}=\(O\) # O
  S="_P"; class+=("${S}"); eval ${S}=\(P\) # P
  S="_Q"; class+=("${S}"); eval ${S}=\(Q\) # Q
  S="_R"; class+=("${S}"); eval ${S}=\(R\) # R
  S="_S"; class+=("${S}"); eval ${S}=\(S\) # S
  S="_T"; class+=("${S}"); eval ${S}=\(T\) # T
  S="_U"; class+=("${S}"); eval ${S}=\(U\) # U
  S="_V"; class+=("${S}"); eval ${S}=\(V\) # V
  S="_W"; class+=("${S}"); eval ${S}=\(W\) # W
  S="_X"; class+=("${S}"); eval ${S}=\(X\) # X
  S="_Y"; class+=("${S}"); eval ${S}=\(Y\) # Y
  S="_Z"; class+=("${S}"); eval ${S}=\(Z\) # Z
  S="_AE"; class+=("${S}"); eval ${S}=\(Æ\) # Æ 以下、エラー回避のため
  S="_OE"; class+=("${S}"); eval ${S}=\(Œ\) # Œ
  S="_TH"; class+=("${S}"); eval ${S}=\(Þ\) # Þ

  S="_a"; class+=("${S}"); eval ${S}=\(a\) # a
  S="_b"; class+=("${S}"); eval ${S}=\(b\) # b
  S="_c"; class+=("${S}"); eval ${S}=\(c\) # c
  S="_d"; class+=("${S}"); eval ${S}=\(d\) # d
  S="_e"; class+=("${S}"); eval ${S}=\(e\) # e
  S="_f"; class+=("${S}"); eval ${S}=\(f\) # f
  S="_g"; class+=("${S}"); eval ${S}=\(g\) # g
  S="_h"; class+=("${S}"); eval ${S}=\(h\) # h
  S="_i"; class+=("${S}"); eval ${S}=\(i\) # i
  S="_j"; class+=("${S}"); eval ${S}=\(j\) # j
  S="_k"; class+=("${S}"); eval ${S}=\(k\) # k
  S="_l"; class+=("${S}"); eval ${S}=\(l\) # l
  S="_m"; class+=("${S}"); eval ${S}=\(m\) # m
  S="_n"; class+=("${S}"); eval ${S}=\(n\) # n
  S="_o"; class+=("${S}"); eval ${S}=\(o\) # o
  S="_p"; class+=("${S}"); eval ${S}=\(p\) # p
  S="_q"; class+=("${S}"); eval ${S}=\(q\) # q
  S="_r"; class+=("${S}"); eval ${S}=\(r\) # r
  S="_s"; class+=("${S}"); eval ${S}=\(s\) # s
  S="_t"; class+=("${S}"); eval ${S}=\(t\) # t
  S="_u"; class+=("${S}"); eval ${S}=\(u\) # u
  S="_v"; class+=("${S}"); eval ${S}=\(v\) # v
  S="_w"; class+=("${S}"); eval ${S}=\(w\) # w
  S="_x"; class+=("${S}"); eval ${S}=\(x\) # x
  S="_y"; class+=("${S}"); eval ${S}=\(y\) # y
  S="_z"; class+=("${S}"); eval ${S}=\(z\) # z
  S="_ae"; class+=("${S}"); eval ${S}=\(æ\) # æ 以下、エラー回避のため
  S="_oe"; class+=("${S}"); eval ${S}=\(œ\) # œ
  S="_th"; class+=("${S}"); eval ${S}=\(þ\) # þ
  S="_ss"; class+=("${S}"); eval ${S}=\(ß\) # ß
  S="_kg"; class+=("${S}"); eval ${S}=\(ĸ\) # ĸ
else
  S="_A"; class+=("${S}"); eval ${S}=\(A À Á Â Ã Ä Å Ā Ă Ą\) # A
  S="_B"; class+=("${S}"); eval ${S}=\(B ẞ\) # B ẞ
  S="_C"; class+=("${S}"); eval ${S}=\(C Ç Ć Ĉ Ċ Č\) # C
  S="_D"; class+=("${S}"); eval ${S}=\(D Ď Đ Ð\) # D Ð
  S="_E"; class+=("${S}"); eval ${S}=\(E È É Ê Ë Ē Ĕ Ė Ę Ě\) # E
  S="_F"; class+=("${S}"); eval ${S}=\(F\) # F
  S="_G"; class+=("${S}"); eval ${S}=\(G Ĝ Ğ Ġ Ģ\) # G
  S="_H"; class+=("${S}"); eval ${S}=\(H Ĥ Ħ\) # H
  S="_I"; class+=("${S}"); eval ${S}=\(I Ì Í Î Ï Ĩ Ī Ĭ Į İ\) # I
  S="_J"; class+=("${S}"); eval ${S}=\(J Ĵ\) # J
  S="_K"; class+=("${S}"); eval ${S}=\(K Ķ\) # K
  S="_L"; class+=("${S}"); eval ${S}=\(L Ĺ Ļ Ľ Ŀ Ł\) # L
  S="_M"; class+=("${S}"); eval ${S}=\(M\) # M
  S="_N"; class+=("${S}"); eval ${S}=\(N Ñ Ń Ņ Ň Ŋ\) # N
  S="_O"; class+=("${S}"); eval ${S}=\(O Ò Ó Ô Õ Ö Ø Ō Ŏ Ő\) # O
  S="_P"; class+=("${S}"); eval ${S}=\(P\) # P
  S="_Q"; class+=("${S}"); eval ${S}=\(Q\) # Q
  S="_R"; class+=("${S}"); eval ${S}=\(R Ŕ Ŗ Ř\) # R
  S="_S"; class+=("${S}"); eval ${S}=\(S Ś Ŝ Ş Š Ș\) # S
  S="_T"; class+=("${S}"); eval ${S}=\(T Ţ Ť Ŧ Ț\) # T
  S="_U"; class+=("${S}"); eval ${S}=\(U Ù Ú Û Ü Ũ Ū Ŭ Ů Ű Ų\) # U
  S="_V"; class+=("${S}"); eval ${S}=\(V\) # V
  S="_W"; class+=("${S}"); eval ${S}=\(W Ŵ\) # W
  S="_X"; class+=("${S}"); eval ${S}=\(X\) # X
  S="_Y"; class+=("${S}"); eval ${S}=\(Y Ý Ÿ Ŷ\) # Y
  S="_Z"; class+=("${S}"); eval ${S}=\(Z Ź Ż Ž\) # Z
  S="_AE"; class+=("${S}"); eval ${S}=\(Æ\) # Æ
  S="_OE"; class+=("${S}"); eval ${S}=\(Œ\) # Œ
  S="_TH"; class+=("${S}"); eval ${S}=\(Þ\) # Þ

  S="_a"; class+=("${S}"); eval ${S}=\(a à á â ã ä å ā ă ą\) # a
  S="_b"; class+=("${S}"); eval ${S}=\(b\) # b
  S="_c"; class+=("${S}"); eval ${S}=\(c ç ć ĉ ċ č\) # c
  S="_d"; class+=("${S}"); eval ${S}=\(d ď đ\) # d
  S="_e"; class+=("${S}"); eval ${S}=\(e è é ê ë ē ĕ ė ę ě\) # e
  S="_f"; class+=("${S}"); eval ${S}=\(f\) # f
  S="_g"; class+=("${S}"); eval ${S}=\(g ĝ ğ ġ ģ\) # g
  S="_h"; class+=("${S}"); eval ${S}=\(h ĥ ħ\) # h
  S="_i"; class+=("${S}"); eval ${S}=\(i ì í î ï ĩ ī ĭ į ı\) # i
  S="_j"; class+=("${S}"); eval ${S}=\(j ĵ\) # j
  S="_k"; class+=("${S}"); eval ${S}=\(k ķ\) # k
  S="_l"; class+=("${S}"); eval ${S}=\(l ĺ ļ ľ ŀ ł\) # l
  S="_m"; class+=("${S}"); eval ${S}=\(m\) # m
  S="_n"; class+=("${S}"); eval ${S}=\(n ñ ń ņ ň ŋ\) # n
  S="_o"; class+=("${S}"); eval ${S}=\(o ò ó ô õ ö ø ō ŏ ő ð\) # o ð
  S="_p"; class+=("${S}"); eval ${S}=\(p\) # p
  S="_q"; class+=("${S}"); eval ${S}=\(q\) # q
  S="_r"; class+=("${S}"); eval ${S}=\(r ŕ ŗ ř\) # r
  S="_s"; class+=("${S}"); eval ${S}=\(s ś ŝ ş š ș\) # s
  S="_t"; class+=("${S}"); eval ${S}=\(t ţ ť ŧ ț\) # t
  S="_u"; class+=("${S}"); eval ${S}=\(u ù ú û ü ũ ū ŭ ů ű ų\) # u
  S="_v"; class+=("${S}"); eval ${S}=\(v\) # v
  S="_w"; class+=("${S}"); eval ${S}=\(w ŵ\) # w
  S="_x"; class+=("${S}"); eval ${S}=\(x\) # x
  S="_y"; class+=("${S}"); eval ${S}=\(y ý ÿ ŷ\) # y
  S="_z"; class+=("${S}"); eval ${S}=\(z ź ż ž\) # z
  S="_ae"; class+=("${S}"); eval ${S}=\(æ\) # æ
  S="_oe"; class+=("${S}"); eval ${S}=\(œ\) # œ
  S="_th"; class+=("${S}"); eval ${S}=\(þ\) # þ
  S="_ss"; class+=("${S}"); eval ${S}=\(ß\) # ß
  S="_kg"; class+=("${S}"); eval ${S}=\(ĸ\) # ĸ
fi

# 基本 --------------------

# 各グリフの重心、形状の違いから、左寄り、右寄り、中央寄り、中央寄りと均等の中間、均等、幅広、Vの字形に分類する

gCL=("_B" "_D" "_E" "_F" "_K" "_L" "_P" "_R" "_TH")
gSL=("_b" "_h" "_k" "_p" "_th" "_ss" "_kg")
S="gravityCapitalL"; class+=("${S}"); eval ${S}=\(`letter_members "${gCL[*]}"`\) # 左寄りの大文字
S="gravitySmallL"; class+=("${S}"); eval ${S}=\(`letter_members "${gSL[*]}"`\) # 左寄りの小文字

gCR=("_C" "_G")
gSR=("_a" "_c" "_d" "_g" "_q")
S="gravityCapitalR"; class+=("${S}"); eval ${S}=\(`letter_members "${gCR[*]}"`\) # 右寄りの大文字
S="gravitySmallR"; class+=("${S}"); eval ${S}=\(`letter_members "${gSR[*]}"`\) # 右寄りの小文字

gCW=("_M" "_W" "_AE" "_OE")
gSW=("_m" "_w" "_ae" "_oe")
S="gravityCapitalW"; class+=("${S}"); eval ${S}=\(`letter_members "${gCW[*]}"`\) # 幅広の大文字
S="gravitySmallW"; class+=("${S}"); eval ${S}=\(`letter_members "${gSW[*]}"`\) # 幅広の小文字

gCE=("_H" "_N" "_O" "_Q" "_U")
gSE=("_n" "_u")
S="gravityCapitalE"; class+=("${S}"); eval ${S}=\(`letter_members "${gCE[*]}"`\) # 均等な大文字
S="gravitySmallE"; class+=("${S}"); eval ${S}=\(`letter_members "${gSE[*]}"`\) # 均等な小文字

gCM=("_A" "_S" "_X" "_Z")
gSM=("_e" "_o" "_s" "_x" "_z")
S="gravityCapitalM"; class+=("${S}"); eval ${S}=\(`letter_members "${gCM[*]}"`\) # 中間の大文字
S="gravitySmallM"; class+=("${S}"); eval ${S}=\(`letter_members "${gSM[*]}"`\) # 中間の小文字

gCV=("_T" "_V" "_Y")
gSV=("_v" "_y")
S="gravityCapitalV"; class+=("${S}"); eval ${S}=\(`letter_members "${gCV[*]}"`\) # Vの字の大文字
S="gravitySmallV"; class+=("${S}"); eval ${S}=\(`letter_members "${gSV[*]}"`\) # vの字の小文字

gCC=("_I" "_J")
gSC=("_f" "_i" "_j" "_l" "_r" "_t")
S="gravityCapitalC"; class+=("${S}"); eval ${S}=\(`letter_members "${gCC[*]}"`\) # 狭い大文字
S="gravitySmallC"; class+=("${S}"); eval ${S}=\(`letter_members "${gSC[*]}"`\) # 狭い小文字

S="gravityL"; class+=("${S}"); eval ${S}=\("${gravityCapitalL[@]}" "${gravitySmallL[@]}"\) # 左寄り(幅広、左にある右寄り、均等は離れようとする)
S="gravityR"; class+=("${S}"); eval ${S}=\("${gravityCapitalR[@]}" "${gravitySmallR[@]}"\) # 右寄り(幅広、右にある左寄り、均等は離れようとする)
S="gravityW"; class+=("${S}"); eval ${S}=\("${gravityCapitalW[@]}" "${gravitySmallW[@]}"\) # 幅広(全てが離れようとする)
S="gravityE"; class+=("${S}"); eval ${S}=\("${gravityCapitalE[@]}" "${gravitySmallE[@]}"\) # 均等(幅広、均等、左にある右寄り、右にある左寄りは離れようとする)
S="gravityM"; class+=("${S}"); eval ${S}=\("${gravityCapitalM[@]}" "${gravitySmallM[@]}"\) # 中間(幅広以外は離れようとしない)
S="gravityV"; class+=("${S}"); eval ${S}=\("${gravityCapitalV[@]}" "${gravitySmallV[@]}"\) # Vの字(中間、左にある左寄り、右にある右寄りは近づこうとする)
S="gravityC"; class+=("${S}"); eval ${S}=\("${gravityCapitalC[@]}" "${gravitySmallC[@]}"\) # 狭い(全てが近づこうとする)

# やや寄り気味 --------------------

grC=("_J" "_j")
grM=("_j")
S="gravity_rC"; class+=("${S}"); eval ${S}=\(`letter_members "${grC[*]}"`\) # 引き寄せるやや右寄り
S="gravity_rM"; class+=("${S}"); eval ${S}=\(`letter_members "${grM[*]}"`\) # 引き寄せないやや右寄り(例外あり)

glM=("_e" "_t")
glC=("_f" "_l" "_r" "_t" "_y")
S="gravity_lM"; class+=("${S}"); eval ${S}=\(`letter_members "${glM[*]}"`\) # 引き寄せないやや左寄り(例外あり)
S="gravity_lC"; class+=("${S}"); eval ${S}=\(`letter_members "${glC[*]}"`\) # 引き寄せるやや左寄り

# 丸い文字 --------------------

cCC=("_O" "_Q")
cSC=("_e" "_o")
S="circleCapitalC"; class+=("${S}"); eval ${S}=\(`letter_members "${cCC[*]}"`\) # 丸い大文字
S="circleSmallC"; class+=("${S}"); eval ${S}=\(`letter_members "${cSC[*]}"`\) # 丸い小文字

cCL=("_C" "_G")
cSL=("_c" "_d" "_g" "_q")
S="circleCapitalL"; class+=("${S}"); eval ${S}=\(`letter_members "${cCL[*]}"`\) # 左が丸い大文字
S="circleSmallL"; class+=("${S}"); eval ${S}=\(`letter_members "${cSL[*]}"`\) # 左が丸い小文字

cCR=("_B" "_D")
cSR=("_b" "_p" "_th" "_ss")
S="circleCapitalR"; class+=("${S}"); eval ${S}=\(`letter_members "${cCR[*]}"`\) # 右が丸い大文字
S="circleSmallR"; class+=("${S}"); eval ${S}=\(`letter_members "${cSR[*]}"`\) # 右が丸い小文字

S="circleC"; class+=("${S}"); eval ${S}=\("${circleCapitalC[@]}" "${circleSmallC[@]}"\) # 丸い文字
S="circleL"; class+=("${S}"); eval ${S}=\("${circleCapitalL[@]}" "${circleSmallL[@]}"\) # 左が丸い文字
S="circleR"; class+=("${S}"); eval ${S}=\("${circleCapitalR[@]}" "${circleSmallR[@]}"\) # 右が丸い文字

# 低い文字 --------------------

lC=("_a" "_c" "_e" "_g" "_n" "_o" "_p" "_q" "_s" "_u" "_v" "_x" "_y" "_z" "_kg")
 #lC=("_a" "_c" "_e" "_g" "_i" "_j" "_m" "_n" "_o" "_p" "_q" "_r" "_s" "_u" "_v" "_w" "_x" "_y" "_z" "_kg")
S="lowC"; class+=("${S}"); eval ${S}=\(`letter_members "${lC[*]}"`\) # 低い文字 (幅広、狭いを除く)

lL=("_d")
S="lowL"; class+=("${S}"); eval ${S}=\(`letter_members "${lL[*]}"`\) # 左が低い文字

lR=("_b" "_h" "_k" "_th")
S="lowR"; class+=("${S}"); eval ${S}=\(`letter_members "${lR[*]}"`\) # 右が低い文字

# 下が開いている文字 --------------------

sCC=("_I" "_T" "_V" "_Y")
sSC=("_f" "_i" "_l" "_v")
S="spaceCapitalC"; class+=("${S}"); eval ${S}=\(`letter_members "${sCC[*]}"`\) # 両下が開いている大文字
S="spaceSmallC"; class+=("${S}"); eval ${S}=\(`letter_members "${sSC[*]}"`\) # 両下が開いている小文字

sCL=("")
sSL=("_t")
S="spaceCapitalL"; class+=("${S}"); eval ${S}=\(`letter_members "${sCL[*]}"`\) # 左下が開いている大文字
S="spaceSmallL"; class+=("${S}"); eval ${S}=\(`letter_members "${sSL[*]}"`\) # 左下が開いている小文字

sCR=("_F" "_J" "_P" "_TH")
sSR=("_j" "_r" "_y")
S="spaceCapitalR"; class+=("${S}"); eval ${S}=\(`letter_members "${sCR[*]}"`\) # 右下が開いている大文字
S="spaceSmallR"; class+=("${S}"); eval ${S}=\(`letter_members "${sSR[*]}"`\) # 右下が開いている小文字

S="spaceC"; class+=("${S}"); eval ${S}=\("${spaceCapitalC[@]}" "${spaceSmallC[@]}"\) # 両下が開いている文字
S="spaceL"; class+=("${S}"); eval ${S}=\("${spaceCapitalL[@]}" "${spaceSmallL[@]}"\) # 左下が開いている文字
S="spaceR"; class+=("${S}"); eval ${S}=\("${spaceCapitalR[@]}" "${spaceSmallR[@]}"\) # 右下が開いている文字

# 全て --------------------

S="capitalAll"; class+=("${S}")
eval ${S}=\("${gravityCapitalL[@]}" "${gravityCapitalR[@]}" "${gravityCapitalW[@]}" "${gravityCapitalE[@]}"\)
eval ${S}+=\("${gravityCapitalM[@]}" "${gravityCapitalV[@]}" "${gravityCapitalC[@]}"\) # 全ての大文字
S="smallAll"; class+=("${S}")
eval ${S}=\("${gravitySmallL[@]}" "${gravitySmallR[@]}" "${gravitySmallW[@]}" "${gravitySmallE[@]}"\)
eval ${S}+=\("${gravitySmallM[@]}" "${gravitySmallV[@]}" "${gravitySmallC[@]}"\) # 全ての小文字

# ラテン文字の略号生成 (N: 通常、L: 左移動後、R: 右移動後) --------------------

for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
  for T in ${member[@]}; do
    eval "${S}N+=(\"${T}\")"
    eval "${S}L+=(\"${T}L\")"
    eval "${S}R+=(\"${T}R\")"
  done
done

# 数字の略号生成 (N: 通常、3: 3桁、4: 4桁、2: 12桁、0: 小数) --------------------

class=("")
S="figure"; class+=("${S}"); eval ${S}=\(0 1 2 3 4 5 6 7 8 9\) # 数字
S="figureB"; class+=("${S}"); eval ${S}=\(0 1\) # 数字 (2進数)

for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
  for T in ${member[@]}; do
    eval "${S}N+=(\"${T}\")"
    eval "${S}3+=(\"${T}3\")"
    eval "${S}4+=(\"${T}4\")"
    eval "${S}2+=(\"${T}2\")"
    eval "${S}0+=(\"${T}0\")"
  done
done

# 記号の略号生成 (N: 通常、L: 左移動後、R: 右移動後) --------------------

class=("")
S="hyphen"; class+=("${S}"); eval ${S}=\("-"\) # -
S="solidus"; class+=("${S}"); eval ${S}=\("/"\) # solidus
S="less"; class+=("${S}"); eval ${S}=\("\<"\) # <
S="greater"; class+=("${S}"); eval ${S}=\("\>"\) # >
S="rSolidus"; class+=("${S}"); eval ${S}=\("RS"\) # reverse solidus

for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
  for T in ${member[@]}; do
    eval "${S}N+=(\"${T}\")"
    eval "${S}L+=(\"${T}L\")"
    eval "${S}R+=(\"${T}R\")"
  done
done

# 記号の略号生成 (N: 通常、D: 下移動後) --------------------

class=("")
S="bar"; class+=("${S}"); eval ${S}=\("\|"\) # |
S="tilde"; class+=("${S}"); eval ${S}=\("\~"\) # ~

for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
  for T in ${member[@]}; do
    eval "${S}N+=(\"${T}\")"
    eval "${S}D+=(\"${T}D\")"
  done
done

# 記号の略号生成 (N: 通常、U: 上移動後) --------------------

class=("")
S="colon"; class+=("${S}"); eval ${S}=\(":"\) # :

for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
  for T in ${member[@]}; do
    eval "${S}N+=(\"${T}\")"
    eval "${S}U+=(\"${T}U\")"
  done
done

# 通常のみ --------------------

symbolFigureN=("#" "$" "%" "&" "@" 0 2 3 4 5 6 7 8 9) # 幅のある記号と数字
operatorHN=("AS" "+" "-" "=") # 記号が上下に移動する記号
S=("_AE" "_OE" "_ae" "_oe") # 移動 (置換) しないグリフ (input[@]から除去)
fixedGlyphN=(`letter_members "${S[*]}"`)

# グリフ名変換用辞書作成 (グリフのIDS順に並べること) ||||||||||||||||||||||||||||||||||||||||

# 略号と名前 ----------------------------------------

hyphen=("-") # 単独で変数を使用するため他と分けて代入
hyphen_name=("hyphen")
fullStop=("FS")
fullStop_name=("period")
solidus=("/")
solidus_name=("slash")
symbol2x=("!" "QD" "#" "$" "%" "&" "'" "(" ")" "AS" "+" "," "${hyphen}" "${fullStop}" "${solidus}")
symbol2x_name=("exclam" "quotedbl" "numbersign" "dollar" "percent" "ampersand" "quotesingle" \
"parenleft" "parenright" "asterisk" "plus" "comma" "${hyphen_name}" "${fullStop_name}" "${solidus_name}")

figure=(0 1 2 3 4 5 6 7 8 9)
figure_name=("zero" "one" "two" "three" "four" "five" "six" "seven" "eight" "nine")

colon=(":") # 単独で変数を使用するため他と分けて代入
colon_name=("colon")
less=("<")
less_name=("less")
greater=(">")
greater_name=("greater")
symbol3x=("${colon}" ";" "${less}" "=" "${greater}" "?")
symbol3x_name=("${colon_name}" "semicolon" "${less_name}" "equal" "${greater_name}" "question")

symbol4x=("@")
symbol4x_name=("at")

# グリフ略号 (AC BC..yC zC AL BL..yL zL AR BR..yR zR 通常のグリフ、左に移動したグリフ、右に移動したグリフ)
# グリフ名 (A B..y z glyphXXXXX..glyphYYYYY)
latin45=(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) # 略号の始めの文字
latin45_name=("${latin45[@]}")

rSolidus=("RS") # 単独で変数を使用するため他と分けて代入
rSolidus_name=("backslash")
symbol5x=("B<" "${rSolidus}" "B>" "^" "_" "GV")
symbol5x_name=("bracketleft" "${rSolidus_name}" "bracketright" "asciicircum" "underscore" "grave")

latin67=(a b c d e f g h i j k l m n o p q r s t u v w x y z) # 略号の始めの文字
latin67_name=("${latin67[@]}")

bar=("|") # 単独で変数を使用するため他と分けて代入
bar_name=("bar")
tilde=("~")
tilde_name=("asciitilde")
symbol7x=("{" "${bar}" "}" "${tilde}")
symbol7x_name=("braceleft" "${bar_name}" "braceright" "${tilde_name}")

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
 #latin13x=(İ ı Ĳ ĳ Ĵ ĵ Ķ ķ ĸ Ĺ ĺ Ļ ļ Ľ ľ Ŀ) # 除外した文字を入れる場合は、移動したグリフに対する処理を追加すること
 #latin13x_name=("Idotaccent" "dotlessi" "IJ" "ij" "Jcircumflex" "jcircumflex" "uni0136" "uni0137" \
 #"kgreenlandic" "Lacute" "lacute" "uni013B" "uni013C" "Lcaron" "lcaron" "Ldot")

latin14x=(ŀ Ł ł Ń ń Ņ ņ Ň ň Ŋ ŋ Ō ō Ŏ ŏ)
latin14x_name=("ldot" "Lslash" "lslash" "Nacute" "nacute" "uni0145" "uni0146" "Ncaron" \
"ncaron" "Eng" "eng" "Omacron" "omacron" "Obreve" "obreve")
 #latin14x=(ŀ Ł ł Ń ń Ņ ņ Ň ň ŉ Ŋ ŋ Ō ō Ŏ ŏ) # 除外した文字を入れる場合は、移動したグリフに対する処理を追加すること
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
 #latin17x=(Ű ű Ų ų Ŵ ŵ Ŷ ŷ Ÿ Ź ź Ż ż Ž ž ſ) # 除外した文字を入れる場合は、移動したグリフに対する処理を追加すること
 #latin17x_name=("Uhungarumlaut" "uhungarumlaut" "Uogonek" "uogonek" "Wcircumflex" "wcircumflex" "Ycircumflex" "ycircumflex" \
 #"Ydieresis" "Zacute" "zacute" "Zdotaccent" "zdotaccent" "Zcaron" "zcaron" "longs")

latin21x=(Ș ș Ț ț)
latin21x_name=("uni0218" "uni0219" "uni021A" "uni021B")

latin1E9x=(ẞ)
latin1E9x_name=("uni1E9E")

# 移動していない文字 ----------------------------------------

i=0

word=("${symbol2x[@]}" "${figure[@]}" "${symbol3x[@]}" "${symbol4x[@]}") # 記号・数字
name=("${symbol2x_name[@]}" "${figure_name[@]}" "${symbol3x_name[@]}" "${symbol4x_name[@]}")
for j in ${!word[@]}; do
  echo "$i ${word[j]} ${name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

word=("${latin45[@]}") # A-Z
name=("${latin45_name[@]}")
for j in ${!word[@]}; do
  echo "$i ${word[j]} ${name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

word=("${symbol5x[@]}") # 記号
name=("${symbol5x_name[@]}")
for j in ${!word[@]}; do
  echo "$i ${word[j]} ${name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

word=("${latin67[@]}") # a-z
name=("${latin67_name[@]}")
for j in ${!word[@]}; do
  echo "$i ${word[j]} ${name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

word=("${symbol7x[@]}") # 記号
name=("${symbol7x_name[@]}")
for j in ${!word[@]}; do
  echo "$i ${word[j]} ${name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

word=("${latinCx[@]}") # À-Å
name=("${latinCx_name[@]}")
for j in ${!word[@]}; do
  echo "$i ${word[j]} ${name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

echo "$i ${latinCy} ${latinCy_name}" >> "${dict}.txt" # Æ
i=`expr ${i} + 1`
echo "$i ${latinCy}L ${latinCy_name}" >> "${dict}.txt" # Æ は移動しないため
i=`expr ${i} + 1`
echo "$i ${latinCy}R ${latinCy_name}" >> "${dict}.txt" # Æ は移動しないため
i=`expr ${i} + 1`

word=("${latinCz[@]}" "${latinDx[@]}" "${latinEx[@]}") # Ç-å
name=("${latinCz_name[@]}" "${latinDx_name[@]}" "${latinEx_name[@]}")
for j in ${!word[@]}; do
  echo "$i ${word[j]} ${name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

echo "$i ${latinEy} ${latinEy_name}" >> "${dict}.txt" # æ
i=`expr ${i} + 1`
echo "$i ${latinEy}L ${latinEy_name}" >> "${dict}.txt" # æ は移動しないため
i=`expr ${i} + 1`
echo "$i ${latinEy}R ${latinEy_name}" >> "${dict}.txt" # æ は移動しないため
i=`expr ${i} + 1`

word=("${latinEz[@]}" "${latinFx[@]}" "${latin10x[@]}" "${latin11x[@]}" \
"${latin12x[@]}" "${latin13x[@]}" "${latin14x[@]}" "${latin15x[@]}") # ç-ő
name=("${latinEz_name[@]}" "${latinFx_name[@]}" "${latin10x_name[@]}" "${latin11x_name[@]}" \
"${latin12x_name[@]}" "${latin13x_name[@]}" "${latin14x_name[@]}" "${latin15x_name[@]}")
for j in ${!word[@]}; do
  echo "$i ${word[j]} ${name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

for j in ${!latin15y[@]}; do # Œ œ
  echo "$i ${latin15y[j]} ${latin15y_name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
  echo "$i ${latin15y[j]}L ${latin15y_name[j]}" >> "${dict}.txt" # Œ œ は移動しないため
  i=`expr ${i} + 1`
  echo "$i ${latin15y[j]}R ${latin15y_name[j]}" >> "${dict}.txt" # Œ œ は移動しないため
  i=`expr ${i} + 1`
done

word=("${latin15z[@]}" "${latin16x[@]}" "${latin17x[@]}" "${latin21x[@]}" "${latin1E9x[@]}") # Ŕ-ẞ
name=("${latin15z_name[@]}" "${latin16x_name[@]}" "${latin17x_name[@]}" "${latin21x_name[@]}" "${latin1E9x_name[@]}")
for j in ${!word[@]}; do
  echo "$i ${word[j]} ${name[j]}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

# 左に移動した文字 ----------------------------------------

word=("${latin45[@]}" "${latin67[@]}" \
"${latinCx[@]}" "${latinCz[@]}" "${latinDx[@]}" "${latinEx[@]}" "${latinEz[@]}" "${latinFx[@]}" \
"${latin10x[@]}" "${latin11x[@]}" "${latin12x[@]}" "${latin13x[@]}" "${latin14x[@]}" "${latin15x[@]}" "${latin15z[@]}" \
"${latin16x[@]}" "${latin17x[@]}" "${latin21x[@]}" "${latin1E9x[@]}") # A-ẞ

i=${glyphNo}

for S in ${word[@]}; do
  echo "$i ${S}L glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

# 右に移動した文字 ----------------------------------------

for S in ${word[@]}; do
  echo "$i ${S}R glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

# 3桁マークの付いた数字 ----------------------------------------

word=("${figure[@]}") # 0-9

for S in ${word[@]}; do
  echo "$i ${S}3 glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

# 4桁マークの付いた数字 ----------------------------------------

for S in ${word[@]}; do
  echo "$i ${S}4 glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

# 12桁マークの付いた数字 ----------------------------------------

for S in ${word[@]}; do
  echo "$i ${S}2 glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

# 小数の数字 ----------------------------------------

for S in ${word[@]}; do
  echo "$i ${S}0 glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

# 左に移動した記号 ----------------------------------------

word=("${hyphen}" "${solidus}" "${less}" "${greater}" "${rSolidus}")

for S in ${word[@]}; do
  echo "$i ${S}L glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

# 右に移動した記号 ----------------------------------------

for S in ${word[@]}; do
  echo "$i ${S}R glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

# 下に移動した記号 ----------------------------------------

word=("${bar[@]}" "${tilde[@]}") # | ~

for S in ${word[@]}; do
  echo "$i ${S}D glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

# 上に移動した記号 ----------------------------------------

word=("${colon[@]}") # :

for S in ${word[@]}; do
  echo "$i ${S}U glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

# カーニング設定作成 ||||||||||||||||||||||||||||||||||||||||

echo "Make GSUB calt List"

echo "<LookupType value=\"6\"/>" >> "${caltList}.txt"
echo "<LookupFlag value=\"0\"/>" >> "${caltList}.txt"
index="0"

# アルファベット ||||||||||||||||||||||||||||||||||||||||

# 数字と記号に関する処理 ----------------------------------------

# 左が幅のある記号、数字で 右が引き寄せない文字の場合 引き寄せない文字 左に移動しない
backtrack=("${symbolFigureN[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" )
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

if [ "${symbol_only_flag}" = "false" ]; then
# 同じ文字を等間隔にさせる例外処理 1 ----------------------------------------

# 左が丸い文字
class=("${cCL[@]}" "${cSL[@]}")
for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
# 左から元に戻る
  backtrack=(""); input=(""); lookAhead=("")
  for T in ${member[@]}; do
    backtrack+=("${T}L")
    input+=("${T}")
    lookAhead+=("${T}")
  done
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
  index=`expr ${index} + 1`
done

# A に関する例外処理 1 ----------------------------------------

# 左が W で 右が、左下が開いている大文字の場合 A 右に移動
backtrack=("${_WR[@]}")
input=("${_A[@]}")
lookAhead=("${spaceCapitalLN[@]}" "${spaceCapitalCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が W の場合 A 左に移動しない
backtrack=("${_WR[@]}")
input=("${_A[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# A に関する例外処理 2 ----------------------------------------

# 左が、右下が開いている大文字で 右が、左下が開いている大文字の場合 A 移動しない
backtrack=("${spaceCapitalRR[@]}" "${spaceCapitalCR[@]}")
input=("${_A[@]}")
lookAhead=("${spaceCapitalLN[@]}" "${spaceCapitalCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が、右下が開いている大文字か W の場合 A 左に移動
backtrack=("${spaceCapitalRL[@]}" "${spaceCapitalCL[@]}" "${_WL[@]}" \
"${spaceCapitalRR[@]}" "${spaceCapitalCR[@]}" \
"${spaceCapitalRN[@]}" "${spaceCapitalCN[@]}" "${_W[@]}")
input=("${_A[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# A に関する例外処理 3 ----------------------------------------

# 左が A の場合 W 左に移動しない
backtrack=("${_AR[@]}")
input=("${_W[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が A の場合 左下が開いている大文字 W 左に移動
backtrack=("${_AL[@]}" \
"${_AR[@]}" \
"${_A[@]}")
input=("${spaceCapitalLN[@]}" "${spaceCapitalCN[@]}" "${_W[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# A に関する例外処理 4 ----------------------------------------

# 左が大文字で 右が、左下が開いている大文字か W の場合 A 右に移動しない
backtrack=("${gravityCapitalLL[@]}" "${gravityCapitalRL[@]}" "${gravityCapitalEL[@]}" "${gravityCapitalML[@]}" "${gravityCapitalVL[@]}" "${gravityCapitalCL[@]}" \
"${gravityCapitalVN[@]}" "${gravityCapitalCN[@]}")
input=("${_A[@]}")
lookAhead=("${spaceCapitalLN[@]}" "${spaceCapitalCN[@]}" "${_W[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が大文字で 右が A の場合 右下が開いている大文字か W 右に移動しない
backtrack=("${gravityCapitalLL[@]}" "${gravityCapitalRL[@]}" "${gravityCapitalEL[@]}" "${gravityCapitalML[@]}" "${gravityCapitalVL[@]}" "${gravityCapitalCL[@]}" \
"${gravityCapitalVN[@]}" "${gravityCapitalCN[@]}")
input=("${spaceCapitalRN[@]}" "${spaceCapitalCN[@]}" "${_W[@]}")
lookAhead=("${_A[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# もろもろ例外 ========================================

# 2つ左を見て移動させる例外処理 1 ----------------------------------------

# 左が、左寄り、中間、Vの字で その左が幅広の文字で 右が幅広、狭い以外の文字の場合 I 以外の狭い文字 左に移動
backtrack1=("${gravityWL[@]}" \
"${gravityWR[@]}" \
"${gravityWN[@]}")
backtrack=("${gravityLR[@]}" "${gravityMR[@]}" "${gravityVR[@]}")
input=("${_J[@]}" "${_f[@]}" "${_i[@]}" "${_j[@]}" "${_l[@]}" "${_r[@]}" "${_t[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}"
index=`expr ${index} + 1`

# 左が、右寄り、均等な文字で その左が幅広の文字で 右が幅広、狭い以外の文字の場合 r 左に移動
backtrack1=("${gravityWL[@]}" \
"${gravityWR[@]}" \
"${gravityWN[@]}")
backtrack=("${gravityRR[@]}" "${gravityER[@]}")
input=("${_r[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}"
index=`expr ${index} + 1`

# 丸い文字に関する例外処理 1 ----------------------------------------

# 左が、右が丸い文字で 右が、右が丸い文字の場合 丸い文字 移動しない
backtrack=("${circleRL[@]}")
input=("${circleCN[@]}")
lookAhead=("${circleRN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が、右が丸い文字で 右が Ww の場合 丸い文字 左に移動しない
backtrack=("${circleRL[@]}" "${circleCL[@]}" \
"${circleRN[@]}" "${circleCN[@]}")
input=("${circleCN[@]}")
lookAhead=("${_W[@]}" "${_w[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が Ww で 右が幅広、狭い以外の文字の場合 丸い小文字 右に移動しない
backtrack=("${_WL[@]}" "${_wL[@]}")
input=("${circleSmallCN[@]}")
lookAhead=("${gravitySmallLN[@]}" "${gravitySmallRN[@]}" "${gravitySmallEN[@]}" "${gravitySmallMN[@]}" "${gravitySmallVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左右を見て移動させない例外処理 1 ----------------------------------------

# 左が、丸い文字で 右が幅広の場合 均等な文字 右に移動しない
backtrack=("${circleCN[@]}")
input=("${gravityEN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左右を見て左に移動させる例外処理 ----------------------------------------

# 左が幅広、引き寄せる文字以外で 右が、左が丸い文字の場合 Vの字 左に移動
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityLN[@]}" "${gravityMN[@]}" "${_a[@]}")
input=("${gravityVN[@]}")
lookAhead=("${circleLN[@]}" "${circleCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が FTf で 右が狭い文字以外の場合 右寄りの小文字、中間の小文字、Vの字の小文字 左に移動
backtrack=("${_FR[@]}" "${_TR[@]}" "${_fR[@]}")
input=("${gravitySmallRN[@]}" "${gravitySmallMN[@]}" "${gravitySmallVN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が filr で 右が狭い文字の場合 狭い以外の小文字 左に移動 (後の処理で両側狭い場合移動なしにしているため)
backtrack=("${_fL[@]}" "${_iL[@]}" "${_lL[@]}" "${_rL[@]}")
input=("${gravitySmallLN[@]}" "${gravitySmallRN[@]}" "${gravitySmallWN[@]}" "${gravitySmallEN[@]}" "${gravitySmallMN[@]}" "${gravitySmallVN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 大文字と小文字で処理が異なる例外処理 1 ----------------------------------------

# 左が左寄り、中間の大文字で 右が幅広の大文字の場合 右寄り、中間、Vの字の大文字 左に移動
backtrack=("${gravityCapitalLN[@]}" "${gravityCapitalMN[@]}")
input=("${gravityCapitalRN[@]}" "${gravityCapitalMN[@]}" "${gravityCapitalVN[@]}")
lookAhead=("${gravityCapitalWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が左寄り、均等、中間の小文字で 右が幅広の小文字の場合 右寄り、中間、Vの字の小文字 左に移動
backtrack=("${gravitySmallLN[@]}" "${gravitySmallEN[@]}" "${gravitySmallMN[@]}")
input=("${gravitySmallRN[@]}" "${gravitySmallMN[@]}" "${gravitySmallVN[@]}")
lookAhead=("${gravitySmallWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が左寄り、中間の小文字で 右が幅広の小文字の場合 左寄り、均等な小文字 左に移動
backtrack=("${gravitySmallLN[@]}" "${gravitySmallMN[@]}")
input=("${gravitySmallLN[@]}" "${gravitySmallEN[@]}")
lookAhead=("${gravitySmallWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左右を見て右に移動させる例外処理 ----------------------------------------

# 左が引き離す文字で 右が狭い文字の場合 幅広以外の文字 右に移動
backtrack=("${gravityRL[@]}" "${gravityWL[@]}" "${gravityEL[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}" "${gravityCN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左右を見て移動させない例外処理 2 ----------------------------------------

# 左が左寄り、中間、Vの字、狭い文字で 右が狭い文字の場合 幅広と狭い以外の文字 移動しない
backtrack=("${gravityLL[@]}" "${gravityML[@]}" "${gravityVL[@]}" "${gravityCL[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 両側が均等な文字の場合 右寄り、均等な文字 移動しない
backtrack=("${gravityEL[@]}")
input=("${gravityRN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 両側が中間の文字の場合 右寄り、均等な文字 移動しない
backtrack=("${gravityML[@]}")
input=("${gravityRN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 両側がVの字の場合 右寄り、均等な文字 移動しない
backtrack=("${gravityVL[@]}")
input=("${gravityRN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 両側が少しでも右に寄っている文字の場合 左寄りの文字他 左に移動しない
backtrack=("${gravity_rCN[@]}")
input=("${gravityLN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${gravity_rMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 両側が少しでも左に寄っている文字の場合 右寄りの文字他 右に移動しない
backtrack=("${gravity_lMN[@]}")
input=("${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${gravity_lCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 丸い文字に関する例外処理 2 ----------------------------------------

# 左が均等な文字で 右がVの字の場合 丸い文字 移動しない
backtrack=("${gravityEN[@]}")
input=("${circleCN[@]}")
lookAhead=("${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が右寄り、均等な文字で 右が左寄り、幅広の文字の場合 丸い文字 左に移動しない
backtrack=("${gravityRN[@]}" "${gravityEN[@]}")
input=("${circleCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が丸い文字に関する例外処理 1 ----------------------------------------

# 左が幅広で 右が、丸い文字の場合 左が丸い文字 移動しない
backtrack=("${gravityWL[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("${circleCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が、丸い文字か EFKTXkx で 右が引き寄せる文字の場合 左が丸い文字 右に移動しない
backtrack=("${circleCN[@]}" "${_E[@]}" "${_F[@]}" "${_K[@]}" "${_T[@]}" "${_X[@]}" "${_k[@]}" "${_x[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("${gravityVN[@]}" "${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が、右が丸い大文字か G の場合 左が丸い小文字 移動しない
backtrack=("${circleCapitalRL[@]}" "${circleCapitalCL[@]}" "${_GL[@]}")
input=("${circleSmallLN[@]}" "${circleSmallCN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が FTkx で 右が幅広の文字の場合 左が丸い小文字 左に移動
backtrack=("${_FR[@]}" "${_TR[@]}" "${_kR[@]}" "${_xR[@]}")
input=("${circleSmallLN[@]}" "${circleSmallCN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が EFKTXkx で 右が引き寄せない文字の場合 左が丸い文字 左に移動
backtrack=("${_E[@]}" "${_F[@]}" "${_K[@]}" "${_T[@]}" "${_X[@]}" "${_k[@]}" "${_x[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が、右が丸い文字で 右が幅広の文字の場合 左が丸い文字 左に移動
backtrack=("${circleRN[@]}" "${circleCN[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が幅広で 右が、左が丸い文字の場合 EFKTXkx 右に移動
backtrack=("${gravityWL[@]}")
input=("${_E[@]}" "${_F[@]}" "${_K[@]}" "${_TR[@]}" "${_X[@]}" "${_k[@]}" "${_x[@]}")
lookAhead=("${circleLN[@]}" "${circleCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左がVの字で 右が狭い文字の場合 左が丸い文字 右に移動
backtrack=("${gravityVR[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が、右が丸い文字で 右が引き寄せる文字の場合 左が丸い文字 右に移動
backtrack=("${circleRN[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("${gravityVN[@]}" "${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が、左右が丸い文字で 右が中間の文字の場合 左が丸い小文字 右に移動
backtrack=("${circleLN[@]}" "${circleRN[@]}" "${circleCN[@]}")
input=("${circleSmallLN[@]}" "${circleSmallCN[@]}")
lookAhead=("${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右が丸い文字に関する例外処理 1 ----------------------------------------

# 左が左寄り、中間の文字で 右が、左が丸い文字の場合 右が丸い文字 右に移動しない
backtrack=("${gravityLN[@]}" "${gravityMN[@]}")
input=("${circleRN[@]}" "${circleCN[@]}")
lookAhead=("${circleLN[@]}" "${circleCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 個別対応 ========================================

# J に関する例外処理 1 ----------------------------------------

# 左が幅広の大文字の場合 J 移動しない
backtrack=("${gravityCapitalWR[@]}" \
"${gravityCapitalWN[@]}")
input=("${_J[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が全ての大文字の場合 J 左に移動
backtrack=("${gravityCapitalWL[@]}" \
"${gravityCapitalRN[@]}" "${gravityCapitalLN[@]}" "${gravityCapitalEN[@]}" "${gravityCapitalMN[@]}" "${gravityCapitalVN[@]}" "${gravityCapitalCN[@]}")
input=("${_J[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が J で 右が中間、Vの字の場合 狭い文字 移動しない
backtrack=("${_JR[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が J の場合 引き寄せない大文字 移動しない
backtrack=("${_JL[@]}" \
"${_J[@]}")
input=("${gravityCapitalLN[@]}" "${gravityCapitalRN[@]}" "${gravityCapitalWN[@]}" "${gravityCapitalEN[@]}" "${gravityCapitalMN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が J の場合 引き寄せない大文字 右に移動
backtrack=("${_JR[@]}")
input=("${gravityCapitalLN[@]}" "${gravityCapitalRN[@]}" "${gravityCapitalWN[@]}" "${gravityCapitalEN[@]}" "${gravityCapitalMN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# L に関する例外処理 ----------------------------------------

# 左が L の場合 Vの字 左に移動
backtrack=("${_LR[@]}")
input=("${gravityVN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が L の場合 引き寄せない文字 移動しない
backtrack=("${_LR[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が L の場合 狭い以外の文字 左に移動
backtrack=("${_LL[@]}" \
"${_L[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右が全ての場合 L 右に移動
backtrack=("")
input=("${_L[@]}")
lookAhead=("${capitalAllN[@]}" "${smallAllN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# c に関する例外処理 ----------------------------------------

# 左が c で 右が右寄りの小文字の場合 左寄り、幅広、均等、中間の小文字 右に移動しない
backtrack=("${_c[@]}")
input=("${gravitySmallLN[@]}" "${gravitySmallWN[@]}" "${gravitySmallEN[@]}" "${gravitySmallMN[@]}")
lookAhead=("${gravitySmallRN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# j に関する例外処理 ----------------------------------------

# 両側が j の場合 j 移動しない
backtrack=("${_jR[@]}")
input=("${_j[@]}")
lookAhead=("${_j[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が gpq の場合 j 移動しない
backtrack=("${_gR[@]}" "${_pR[@]}" "${_qR[@]}")
input=("${_j[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が全ての文字の場合 j 左に移動
backtrack=("${gravityCL[@]}" \
"${capitalAllR[@]}" "${smallAllR[@]}" \
"${capitalAllN[@]}" "${smallAllN[@]}")
input=("${_j[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が左寄り、中間の文字で 右が j の場合 狭い文字 右に移動
backtrack=("${gravityLR[@]}" "${gravityMR[@]}")
input=("${gravityCN[@]}")
lookAhead=("${_j[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# rt に関する例外処理 1 ----------------------------------------

# 左が幅広の文字で 右が引き離す文字の場合 rt 移動しない
backtrack=("${gravityWL[@]}")
input=("${_r[@]}" "${_t[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が rt で 右が幅広の文字の場合 幅広の文字 左に移動
backtrack=("${_rL[@]}" "${_tL[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が rt の場合 幅広の文字 左に移動しない
backtrack=("${_rL[@]}" "${_tL[@]}" \
"${_r[@]}" "${_t[@]}")
input=("${gravityWN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が rt で 右が幅広の文字の場合 左寄り、均等な文字 左に移動
backtrack=("${_r[@]}" "${_t[@]}")
input=("${gravityLN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が rt の場合 左寄り、均等な文字 左に移動しない
backtrack=("${_r[@]}" "${_t[@]}")
input=("${gravityLN[@]}" "${gravityEN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が rt の場合 狭い文字以外 左に移動しない
backtrack=("${_rR[@]}" "${_tR[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# y に関する例外処理 1 ----------------------------------------

# 左が、均等な大文字、左が低い文字、gpq の場合 y 左に移動しない
backtrack=("${gravityCapitalEL[@]}" "${lowLL[@]}" "${_gL[@]}" "${_pL[@]}" "${_qL[@]}")
input=("${_y[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が、均等な大文字、左が低い文字、gpq の場合 y 右に移動
backtrack=("${gravityCapitalER[@]}" "${lowLR[@]}" "${_gR[@]}" "${_pR[@]}" "${_qR[@]}" \
"${gravityCapitalEN[@]}" "${lowLN[@]}" "${_g[@]}" "${_p[@]}" "${_q[@]}")
input=("${_y[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# x に関する例外処理 ----------------------------------------

# 左が、右が丸い小文字で 右が幅広の文字の場合 x 左に移動
backtrack=("${circleSmallRR[@]}" "${circleSmallCR[@]}")
input=("${_x[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が、右が丸い小文字で 右が引き離す文字の場合 x 左に移動
backtrack=("${circleSmallRN[@]}" "${circleSmallCN[@]}")
input=("${_x[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が x の場合 右が丸い小文字 移動しない
backtrack=("${_x[@]}")
input=("${circleSmallRN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 大文字小文字 ========================================

# 大文字と小文字に関する例外処理 1 ----------------------------------------

# 左が、右下が開いている大文字で 右が狭い文字の場合 左が低い文字 左に移動しない
backtrack=("${spaceCapitalRN[@]}" "${spaceCapitalCN[@]}")
input=("${lowLN[@]}" "${lowCN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が、右下が開いている大文字か PÞ の場合 左が低い文字 移動しない
backtrack=("${spaceCapitalRR[@]}" "${spaceCapitalCR[@]}" \
"${_P[@]}" "${_TH[@]}")
input=("${lowLN[@]}" "${lowCN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が、右下が開いている大文字の場合 左が低い文字 左に移動
backtrack=("${spaceCapitalRL[@]}" "${spaceCapitalCL[@]}" \
"${spaceCapitalRN[@]}" "${spaceCapitalCN[@]}")
input=("${lowLN[@]}" "${lowCN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 大文字と小文字で処理が異なる例外処理 2 ----------------------------------------

# 左が幅広の大文字で 右が左寄り、幅広、均等な大文字の場合 均等、中間の大文字 右に移動しない
backtrack=("${gravityCapitalWL[@]}")
input=("${gravityCapitalEN[@]}" "${gravityCapitalMN[@]}")
lookAhead=("${gravityCapitalLN[@]}" "${gravityCapitalWN[@]}" "${gravityCapitalEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が均等な大文字で 右が左寄りの大文字の場合 幅広の大文字 右に移動
backtrack=("${gravityCapitalEN[@]}")
input=("${gravityCapitalWN[@]}")
lookAhead=("${gravityCapitalLN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が均等な大文字で 右が左寄りの大文字の場合 均等な大文字 左に移動しない
backtrack=("${gravityCapitalEL[@]}")
input=("${gravityCapitalEN[@]}")
lookAhead=("${gravityCapitalLN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が中間の大文字で 右が狭い大文字の場合 中間の大文字 右に移動しない
backtrack=("${gravityCapitalMN[@]}")
input=("${gravityCapitalMN[@]}")
lookAhead=("${gravityCapitalCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が狭い大文字で 右が左寄り、右寄り、均等、中間の大文字の場合 左寄り、中間の大文字 左に移動しない
backtrack=("${gravityCapitalCR[@]}")
input=("${gravityCapitalLN[@]}" "${gravityCapitalMN[@]}")
lookAhead=("${gravityCapitalLN[@]}" "${gravityCapitalRN[@]}" "${gravityCapitalEN[@]}" "${gravityCapitalMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が狭い大文字で 右が右寄り、中間の大文字の場合 左寄り、中間の大文字 左に移動しない
backtrack=("${gravityCapitalCR[@]}")
input=("${gravityCapitalRN[@]}" "${gravityCapitalEN[@]}")
lookAhead=("${gravityCapitalRN[@]}" "${gravityCapitalMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が幅広の小文字で 右が左寄りの小文字の場合 均等な小文字 右に移動しない
backtrack=("${gravitySmallWL[@]}")
input=("${gravitySmallEN[@]}")
lookAhead=("${gravitySmallLN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が左寄り、中間の文字で 右が、左が丸い文字の場合 左寄りの小文字 右に移動しない
backtrack=("${gravityLN[@]}" "${gravityMN[@]}")
input=("${gravitySmallLN[@]}")
lookAhead=("${circleLN[@]}" "${circleCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左右を見て移動させない例外処理 3 ----------------------------------------

# 左が引き離す文字で 右が幅広の文字の場合 引き寄せない文字 移動しない
backtrack=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が右寄りの文字で 右が右寄り、中間の文字の場合 filr 移動しない
backtrack=("${gravityRN[@]}")
input=("${_f[@]}" "${_i[@]}" "${_l[@]}" "${_r[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 2つ左を見て移動させる例外処理 2 ----------------------------------------

# 左が狭い文字で その左が狭い文字で 右が狭い以外の文字の場合 引き寄せない文字 左に移動
backtrack1=("${gravityCR[@]}")
backtrack=("${gravityCL[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}"
index=`expr ${index} + 1`

# 2つ左を見て移動させない例外処理 ----------------------------------------

# 左が fr 以外の狭い文字で その左が狭い文字の場合 左寄り、右寄り、均等、中間の文字 移動しない
backtrack1=("${gravityCR[@]}")
backtrack=("${_IL[@]}" "${_JL[@]}" "${_iL[@]}" "${_jL[@]}" "${_lL[@]}" "${_tL[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"
index=`expr ${index} + 1`

# 左が狭い文字で その左が狭い文字の場合 幅広の文字 移動しない
backtrack1=("${gravityCR[@]}")
backtrack=("${gravityCL[@]}")
input=("${gravityWN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"
index=`expr ${index} + 1`

# 移動しない ========================================

# 左右を見て移動させない通常処理 ----------------------------------------

# 左右を見て 左寄りの文字 移動しない
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityVN[@]}")
input=("${gravityLN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左右を見て 右寄りの文字 移動しない
backtrack=("${gravityVR[@]}" \
"${gravityLN[@]}" "${gravityMN[@]}")
input=("${gravityRN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左右を見て 均等な文字 移動しない
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityVN[@]}")
input=("${gravityEN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左右を見て 中間の文字 移動しない
backtrack=("${gravityVR[@]}" \
"${gravityLN[@]}" "${gravityMN[@]}")
input=("${gravityMN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で左に移動 ========================================

# 右が丸い文字に関する例外処理 2 ----------------------------------------

# 左が、右が丸い文字で 右が左寄り、均等な文字の場合 均等な文字 左に移動しない
backtrack=("${circleRL[@]}" "${circleCL[@]}")
input=("${gravityEN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左右を見て右に移動させる通常処理 ----------------------------------------

# 左側基準で 狭い文字 右に移動
backtrack=("${gravityEN[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左右を見て左に移動させる通常処理 ----------------------------------------

# 左側基準で 左寄り、中間の文字 左に移動
backtrack=("${gravityCR[@]}")
input=("${gravityLN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 左寄りの文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityML[@]}")
input=("${gravityLN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 右寄りの文字、均等な文字 左に移動
backtrack=("${gravityCR[@]}")
input=("${gravityRN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 右寄りの文字 左に移動
backtrack=("${gravityRL[@]}" "${gravityEL[@]}")
input=("${gravityRN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 幅広の文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityEL[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 幅広の文字 左に移動
backtrack=("${gravityML[@]}" "${gravityVL[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 均等な文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityML[@]}")
input=("${gravityEN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 中間の文字 左に移動
backtrack=("${gravityRL[@]}" "${gravityEL[@]}")
input=("${gravityMN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で Vの字 左に移動
backtrack=("${gravityRL[@]}" "${gravityEL[@]}")
input=("${gravityVN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で Vの字 左に移動
backtrack=("${gravityCR[@]}")
input=("${gravityVN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 狭い文字 左に移動
backtrack=("${gravityWL[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左右を見て左に移動させない通常処理 ----------------------------------------

# 左側基準で 左寄りの文字 左に移動しない
backtrack=("${gravityVL[@]}" \
"${gravityCN[@]}")
input=("${gravityLN[@]}")
lookAhead=("${gravityVN[@]}" "${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 右寄りの文字 左に移動しない
backtrack=("${gravityLL[@]}" "${gravityML[@]}" \
"${gravityVN[@]}")
input=("${gravityRN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 幅広の字 左に移動しない
backtrack=("${gravityCL[@]}" \
"${gravityCN[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 均等な文字 左に移動しない
backtrack=("${gravityVL[@]}" \
"${gravityCN[@]}")
input=("${gravityEN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 中間の文字 左に移動しない
backtrack=("${gravityLL[@]}" "${gravityML[@]}" \
"${gravityVN[@]}")
input=("${gravityMN[@]}")
lookAhead=("${gravityVN[@]}" "${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で Vの字 左に移動しない
backtrack=("${gravityVL[@]}")
input=("${gravityVN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 狭い文字 左に移動しない
backtrack=("${gravityCR[@]}" \
"${gravityLN[@]}" "${gravityMN[@]}" "${gravityVN[@]}" "${gravityCN[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 狭い文字 左に移動しない
backtrack=("${gravityEN[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}" )
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が丸い文字に関する例外処理 2 ----------------------------------------

# 左が、右が丸い文字で 右が幅広の文字の場合 左が丸い文字 左に移動
backtrack=("${circleRL[@]}" "${circleCL[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が、右が丸い文字の場合 左が丸い文字 左に移動しない
backtrack=("${circleRL[@]}" "${circleCL[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左を見て左に移動させる通常処理 ----------------------------------------

# 左側基準で 左寄りの文字、均等な文字 左に移動
backtrack=("${gravityVL[@]}" "${gravityCL[@]}" \
"${gravityCN[@]}")
input=("${gravityLN[@]}" "${gravityEN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 右寄りの文字、中間の文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityML[@]}" "${gravityVL[@]}" "${gravityCL[@]}" \
"${gravityVN[@]}" "${gravityCN[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 幅広の文字 左に移動
backtrack=("${gravityCL[@]}" \
"${gravityCN[@]}")
input=("${gravityWN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で Vの字 左に移動
backtrack=("${gravityLL[@]}" "${gravityML[@]}" "${gravityVL[@]}" "${gravityCL[@]}" \
"${gravityCN[@]}")
input=("${gravityVN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 狭い文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}" "${gravityVL[@]}" "${gravityCL[@]}" \
"${gravityCR[@]}" \
"${gravityLN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}" "${gravityCN[@]}")
input=("${gravityCN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で右に移動 ========================================

# 左が丸い文字に関する例外処理 3 ----------------------------------------

# 左が、右が丸い文字の場合 左が丸い文字 右に移動
backtrack=("${circleLR[@]}" "${circleRR[@]}" "${circleCR[@]}")
input=("${circleLN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左右を見て右に移動させる通常処理 ----------------------------------------

# 左側基準で 中間の文字 右に移動
backtrack=("${gravityRN[@]}")
input=("${gravityMN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左側基準で 狭い文字 右に移動
backtrack=("${gravityRN[@]}" "${gravityWN[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}" "${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左右を見て右に移動させない通常処理 ----------------------------------------

# 左側基準で 左寄り、均等、中間の文字 右に移動しない
backtrack=("${gravityWL[@]}")
input=("${gravityLN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 左寄りの文字 右に移動しない
backtrack=("${gravityVR[@]}" \
"${gravityLN[@]}" "${gravityMN[@]}")
input=("${gravityLN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 右寄りの文字 右に移動しない
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityRR[@]}" "${gravityER[@]}" "${gravityMR[@]}" \
"${gravityRN[@]}" "${gravityEN[@]}")
input=("${gravityRN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 幅広の文字 右に移動しない
backtrack=("${gravityWL[@]}" \
"${gravityRN[@]}" "${gravityEN[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 幅広の文字 右に移動しない
backtrack=("${gravityRL[@]}" \
"${gravityLN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 均等な文字 右に移動しない
backtrack=("${gravityVR[@]}" \
"${gravityLN[@]}" "${gravityMN[@]}")
input=("${gravityEN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で Vの字 右に移動しない
backtrack=("${gravityRR[@]}" "${gravityER[@]}")
input=("${gravityVN[@]}")
lookAhead=("${gravityWN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で Vの字 右に移動しない
backtrack=("${gravityVR[@]}")
input=("${gravityVN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 狭い文字 右に移動しない
backtrack=("${gravityWR[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左を見て右に移動させる通常処理 ----------------------------------------

# 左側基準で 左寄り、均等な文字 右に移動
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
input=("${gravityLN[@]}" "${gravityEN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左側基準で 右寄りの文字 右に移動
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" \
"${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
input=("${gravityRN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左側基準で 幅広の文字 右に移動
backtrack=("${gravityRL[@]}" "${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
input=("${gravityWN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左側基準で 中間の文字 右に移動
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" \
"${gravityWN[@]}")
input=("${gravityMN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左側基準で Vの字 右に移動
backtrack=("${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityVR[@]}" \
"${gravityWN[@]}")
input=("${gravityVN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左側基準で 狭い文字 右に移動
backtrack=("${gravityWR[@]}")
input=("${gravityCN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が丸い文字に関する例外処理 4 ----------------------------------------

# 左が、右が丸い文字、右寄り、均等な文字の場合 左が丸い文字 右に移動
backtrack=("${circleRN[@]}" "${circleCN[@]}" \
"${gravityRN[@]}" "${gravityEN[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 個別対応 ========================================

# A に関する例外処理 5 ----------------------------------------

# 右が、左下が開いている大文字か W の場合 A 右に移動
backtrack=("")
input=("${_A[@]}")
lookAhead=("${spaceCapitalLN[@]}" "${spaceCapitalCN[@]}" "${_W[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右が A の場合 右下が開いている大文字か W 右に移動
backtrack=("")
input=("${spaceCapitalRN[@]}" "${spaceCapitalCN[@]}" "${_W[@]}")
lookAhead=("${_A[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# J に関する例外処理 2 ----------------------------------------

# 右が引き寄せない大文字の場合 J 左に移動
backtrack=("")
input=("${_J[@]}")
lookAhead=("${gravityCapitalLN[@]}" "${gravityCapitalRN[@]}" "${gravityCapitalWN[@]}" "${gravityCapitalEN[@]}" "${gravityCapitalMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# rt に関する例外処理 2 ----------------------------------------

# 右が幅広の文字の場合 rt 左に移動
backtrack=("")
input=("${_r[@]}" "${_t[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右が引き寄せない文字の場合 rt 右に移動しない
backtrack=("")
input=("${_r[@]}" "${_t[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# y に関する例外処理 2 ----------------------------------------

# 右が y の場合 p 右に移動しない
backtrack=("")
input=("${_p[@]}")
lookAhead=("${_y[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 大文字小文字 ========================================

# 大文字と小文字に関する例外処理 2 ----------------------------------------

# 右が、左が低い文字の場合 PÞ 右に移動しない
backtrack=("")
input=("${_P[@]}" "${_TH[@]}")
lookAhead=("${lowLN[@]}" "${lowCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右が、左が低い文字の場合 右下が開いている大文字 右に移動
backtrack=("")
input=("${spaceCapitalRN[@]}" "${spaceCapitalCN[@]}")
lookAhead=("${lowLN[@]}" "${lowCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 大文字と小文字で処理が異なる例外処理 3 ----------------------------------------

# 左が均等な小文字で 右が右寄り、中間、Vの字の小文字の場合 狭い小文字 右に移動しない
backtrack=("${gravitySmallER[@]}")
input=("${gravitySmallCN[@]}")
lookAhead=("${gravitySmallRN[@]}" "${gravitySmallMN[@]}" "${gravitySmallVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で左に移動 ========================================

# 右が丸い文字に関する例外処理 3 ----------------------------------------

# 左が、左右が丸い文字で 右が、左が丸い、左寄り、均等な文字の場合 右が丸い文字 左に移動しない
backtrack=("${circleLL[@]}" "${circleRL[@]}" "${circleCL[@]}")
input=("${circleRN[@]}" "${circleCN[@]}")
lookAhead=("${circleLN[@]}" "${circleCN[@]}" \
"${gravityLN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右が、左が丸い、引き離す文字の場合 右が丸い文字 左に移動
backtrack=("")
input=("${circleRN[@]}" "${circleCN[@]}")
lookAhead=("${circleLN[@]}" "${circleCN[@]}" \
"${gravityLN[@]}" "${gravityEN[@]}" "${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左右を見て左に移動させる通常処理 ----------------------------------------

# 右側基準で 狭い文字 左に移動
backtrack=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左右を見て左に移動させない通常処理 ----------------------------------------

# 右側基準で 左寄りの文字 左に移動しない
backtrack=("${gravityVN[@]}")
input=("${gravityLN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で 右寄りの文字 左に移動しない
backtrack=("${gravityVR[@]}" \
"${gravityLN[@]}" "${gravityMN[@]}")
input=("${gravityRN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で 幅広の文字 左に移動しない
backtrack=("${gravityLL[@]}" "${gravityEL[@]}" "${gravityML[@]}" "${gravityVL[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で 均等な文字 左に移動しない
backtrack=("${gravityVN[@]}")
input=("${gravityEN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で 中間の文字 左に移動しない
backtrack=("${gravityVR[@]}" \
"${gravityLN[@]}" "${gravityMN[@]}")
input=("${gravityMN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で Vの字 左に移動しない
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityMR[@]}" \
"${gravityRN[@]}" "${gravityEN[@]}")
input=("${gravityVN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右を見て左に移動させる通常処理 ----------------------------------------

# 右側基準で 左寄りの文字、中間の文字、Vの字 左に移動
backtrack=("")
input=("${gravityLN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右側基準で 右寄りの文字、均等な文字 左に移動
backtrack=("")
input=("${gravityRN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右側基準で 幅広の文字 左に移動
backtrack=("")
input=("${gravityWN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が丸い文字に関する例外処理 5 ----------------------------------------

# 左が、右が丸い文字で 右が、左が丸い文字の場合 右寄り、均等な文字 左に移動しない
backtrack=("${circleRL[@]}" "${circleCL[@]}")
input=("${gravityRN[@]}" "${gravityEN[@]}")
lookAhead=("${circleLN[@]}" "${circleCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右が、左が丸い文字の場合 右寄り、均等な文字 左に移動
backtrack=("")
input=("${gravityRN[@]}" "${gravityEN[@]}")
lookAhead=("${circleLN[@]}" "${circleCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右側基準で右に移動 ========================================

# 左右を見て右に移動させない通常処理 ----------------------------------------

# 右側基準で 左寄りの文字 右に移動しない
backtrack=("${gravityCR[@]}" \
"${gravityVN[@]}")
input=("${gravityLN[@]}")
lookAhead=("${gravityVN[@]}" "${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で 左寄りの文字 右に移動しない
backtrack=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}")
input=("${gravityLN[@]}")
lookAhead=("${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で 右寄りの文字 右に移動しない
backtrack=("${gravityVR[@]}" "${gravityCR[@]}")
input=("${gravityRN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で 幅広の文字 右に移動しない
backtrack=("${gravityVL[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で 均等な文字 右に移動しない
backtrack=("${gravityCR[@]}" \
"${gravityVN[@]}")
input=("${gravityEN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で 中間の文字 右に移動しない
backtrack=("${gravityVR[@]}" "${gravityCR[@]}")
input=("${gravityMN[@]}")
lookAhead=("${gravityVN[@]}" "${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で 中間の文字 右に移動しない
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityLN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
input=("${gravityMN[@]}")
lookAhead=("${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で Vの字 右に移動しない
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityLR[@]}" "${gravityMR[@]}" "${gravityCR[@]}" \
"${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
input=("${gravityVN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で 狭い文字 右に移動しない
backtrack=("${gravityLR[@]}" "${gravityMR[@]}" \
"${gravityWN[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}" "${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で 狭い文字 右に移動しない
backtrack=("${gravityVR[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で 狭い文字 右に移動しない
 #backtrack=("${gravityRR[@]}" "${gravityER[@]}" \
 #"${gravityRN[@]}")
 #input=("${gravityCN[@]}")
 #lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
 #chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
 #index=`expr ${index} + 1`

# 左右を見て右に移動させない例外処理 ----------------------------------------

# 左が右寄り、均等な文字で 右が、左が丸い文字の場合 狭い文字 右に移動しない (一つ前の処理と統合)
backtrack=("${gravityRR[@]}" "${gravityER[@]}" \
"${gravityRN[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}" "${circleLN[@]}" "${circleCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 2つ右を見て右に移動させる例外処理 ----------------------------------------

# 左が、左寄り、中間の文字で 右が狭い文字で その右が狭い文字の場合 右寄り、中間の文字 右に移動
backtrack1=("")
backtrack=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityMN[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityCN[@]}")
lookAhead1=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"
index=`expr ${index} + 1`

# 2つ右を見て右に移動させない例外処理 ----------------------------------------

# 右が il 以外の狭い文字で その右が狭い文字の場合 左寄り、右寄り、中間の文字 右に移動しない
backtrack1=("")
backtrack=("")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("${_I[@]}" "${_J[@]}" "${_f[@]}" "${_j[@]}" "${_r[@]}" "${_t[@]}")
lookAhead1=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"
index=`expr ${index} + 1`

# 右が il で その右が il の場合 左寄り、右寄り、中間の文字 右に移動しない
backtrack1=("")
backtrack=("")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("${_i[@]}" "${_l[@]}")
lookAhead1=("${_i[@]}" "${_l[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"
index=`expr ${index} + 1`

# 右が狭い文字で その右が狭い文字の場合 幅広の文字 右に移動しない
backtrack1=("")
backtrack=("")
input=("${gravityWN[@]}")
lookAhead=("${gravityCN[@]}")
lookAhead1=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"
index=`expr ${index} + 1`

# 右を見て右に移動させる通常処理 ----------------------------------------

# 右側基準で 左寄りの文字、中間の文字 右に移動
backtrack=("")
input=("${gravityLN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityVN[@]}" "${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右側基準で 右寄りの文字、幅広の文字、均等な文字 右に移動
backtrack=("")
input=("${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右側基準で Vの字 右に移動
backtrack=("")
input=("${gravityVN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右側基準で 狭い文字 右に移動
backtrack=("")
input=("${gravityCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}" "${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 2つ左を見て移動させる例外処理 3 ----------------------------------------

# 左が、左寄り、均等、中間、Vの字で その左が狭い文字の場合 幅広の文字 右に移動
backtrack1=("${gravityCL[@]}" \
"${gravityCR[@]}" \
"${gravityCN[@]}")
backtrack=("${gravityLL[@]}" "${gravityEL[@]}" "${gravityML[@]}" "${gravityVL[@]}")
input=("${gravityWN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}"
index=`expr ${index} + 1`

# 同じ文字を等間隔にさせる例外処理 2 ----------------------------------------

# 丸くない左寄り、右寄りの文字
set=("${gCL[@]}" "${gSL[@]}" "${gCR[@]}" "${gSR[@]}")
remove=("${cCL[@]}" "${cSL[@]}" "${cCR[@]}" "${cSR[@]}")

class=("") # 丸い文字を除去
for S in ${set[@]}; do
  T=`printf '%s\n' "${remove[@]}" | grep -x "${S}"`
  if [ -z "${T}" ]; then
    class+=("${S}")
  fi
done

for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
# 左に移動 (広がる 3文字限定)
  backtrack1=("")
  backtrack=("")
  input=(""); lookAhead=(""); lookAhead1=("")
  for T in ${member[@]}; do
    input+=("${T}")
    lookAhead+=("${T}")
    lookAhead1+=("${T}")
  done
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"
  index=`expr ${index} + 1`
done

# 再調整 ========================================

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
echo "<LookupType value=\"6\"/>" >> "${caltList}.txt"
echo "<LookupFlag value=\"0\"/>" >> "${caltList}.txt"
index="0"

# 同じ文字を等間隔にさせる処理 ----------------------------------------

# J
# 右から元に戻る (広がる)
backtrack1=("")
backtrack=("")
input=("${_JR[@]}")
lookAhead=("${_J[@]}")
lookAhead1=("${_JL[@]}")
lookAheadX=("${_JL[@]}"); aheadMax="2"
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"
index=`expr ${index} + 1`

# j
# 右から元に戻る (広がる)
backtrack1=("")
backtrack=("")
input=("${_jR[@]}")
lookAhead=("${_j[@]}")
lookAhead1=("${_jL[@]}")
lookAheadX=("${_jL[@]}"); aheadMax="2"
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"
index=`expr ${index} + 1`

# L
# 右から元に戻る (広がる)
backtrack1=("")
backtrack=("")
input=("${_LR[@]}")
lookAhead=("${_L[@]}")
lookAhead1=("${_LL[@]}")
lookAheadX=("${_LL[@]}"); aheadMax="2"
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"
index=`expr ${index} + 1`

# 左から元に戻る (広がる)
backtrack1=("${_L[@]}")
backtrack=("${_L[@]}")
input=("${_LL[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"
index=`expr ${index} + 1`

# 丸い小文字
class=("${cSC[@]}")
for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
# 左から元に戻る (縮む)
  backtrack1=("")
  backtrack=("")
  input=(""); lookAhead=(""); lookAhead1=(""); lookAheadX=(""); aheadMax="2"
  for T in ${member[@]}; do
    input+=("${T}L")
    lookAhead+=("${T}")
    lookAhead1+=("${T}R")
    lookAheadX+=("${T}R")
  done
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"
  index=`expr ${index} + 1`

# 右から元に戻る (縮む)
  backtrack1=(""); backtrack=(""); input=("")
  for T in ${member[@]}; do
    backtrack1+=("${T}")
    backtrack+=("${T}")
    input+=("${T}R")
  done
  lookAhead=("")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"
  index=`expr ${index} + 1`
done

# 左が丸い、右が丸い文字
class=("${cCL[@]}" "${cSL[@]}" "${cCR[@]}" "${cSR[@]}")
for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
# 左から元に戻る (縮む)
  backtrack1=("")
  backtrack=("")
  input=(""); lookAhead=(""); lookAhead1=("")
  for T in ${member[@]}; do
    input+=("${T}L")
    lookAhead+=("${T}")
    lookAhead1+=("${T}")
  done
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"
  index=`expr ${index} + 1`
done

# 丸くない左寄り、右寄りの文字
set=("${gCL[@]}" "${gSL[@]}" "${gCR[@]}" "${gSR[@]}")
remove=("${cCL[@]}" "${cSL[@]}" "${cCR[@]}" "${cSR[@]}")

class=("") # 丸い文字を除去
for S in ${set[@]}; do
  T=`printf '%s\n' "${remove[@]}" | grep -x "${S}"`
  if [ -z "${T}" ]; then
    class+=("${S}")
  fi
done

for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
# 左から元に戻る (縮む)
  backtrack1=("")
  backtrack=("")
  input=(""); lookAhead=(""); lookAhead1=("")
  for T in ${member[@]}; do
    input+=("${T}L")
    lookAhead+=("${T}L")
    lookAhead1+=("${T}L" "${T}")
  done
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"
  index=`expr ${index} + 1`

# 左から元に戻る
  backtrack=(""); input=(""); lookAhead=(""); lookAhead1=("")
  for T in ${member[@]}; do
    backtrack+=("${T}")
    input+=("${T}L")
    lookAhead+=("${T}")
  done
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
  index=`expr ${index} + 1`
done

# 左寄り、右寄りの文字
class=("${gCL[@]}" "${gSL[@]}" "${gCR[@]}" "${gSR[@]}")
for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
# 右から元に戻る (縮む)
  backtrack1=(""); backtrack=(""); input=("")
  for T in ${member[@]}; do
    backtrack1+=("${T}")
    backtrack+=("${T}")
    input+=("${T}R")
  done
  lookAhead=("")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"
  index=`expr ${index} + 1`
done

# 幅広の文字
class=("${gCW[@]}" "${gSW[@]}")
for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
# 左から元に戻る (縮む)
  backtrack1=("")
  backtrack=("")
  input=(""); lookAhead=(""); lookAhead1=("")
  for T in ${member[@]}; do
    input+=("${T}L")
    lookAhead+=("${T}")
    lookAhead1+=("${T}")
  done
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"
  index=`expr ${index} + 1`

# 右から元に戻る (縮む)
  backtrack1=(""); backtrack=(""); input=("")
  for T in ${member[@]}; do
    backtrack1+=("${T}")
    backtrack+=("${T}")
    input+=("${T}R")
  done
  lookAhead=("")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"
  index=`expr ${index} + 1`
done

# 均等な文字
class=("${gCE[@]}" "${gSE[@]}")
for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
# 左から元に戻る (縮む)
  backtrack1=("")
  backtrack=("")
  input=(""); lookAhead=(""); lookAhead1=(""); lookAheadX=(""); aheadMax="2"
  for T in ${member[@]}; do
    input+=("${T}L")
    lookAhead+=("${T}")
    lookAhead1+=("${T}R")
    lookAheadX+=("${T}R")
  done
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"
  index=`expr ${index} + 1`

# 右から元に戻る (縮む)
  backtrack1=(""); backtrack=(""); input=("")
  for T in ${member[@]}; do
    backtrack1+=("${T}")
    backtrack+=("${T}")
    input+=("${T}R")
  done
  lookAhead=("")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"
  index=`expr ${index} + 1`
done

# 狭い文字
class=("${gCC[@]}" "${gSC[@]}")
for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
  if [ "${S}" != "_J" ] && [ "${S}" != "_j" ]; then
# 右から元に戻る (広がる)
    backtrack1=("")
    backtrack=("")
    input=(""); lookAhead=(""); lookAhead1=("")
    for T in ${member[@]}; do
      input+=("${T}R")
      lookAhead+=("${T}")
      lookAhead1+=("${T}")
    done
    chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"
    index=`expr ${index} + 1`
  fi

# 左から元に戻る (広がる)
  backtrack1=(""); backtrack=(""); input=("")
  for T in ${member[@]}; do
    backtrack1+=("${T}")
    backtrack+=("${T}")
    input+=("${T}L")
  done
  lookAhead=("")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"
  index=`expr ${index} + 1`
done

# 丸い文字と均等な文字が並んだ場合の処理 ----------------------------------------

# 両側が、左右が丸い文字の場合 左右が丸い、均等な文字 左に移動
backtrack=("${circleLL[@]}" "${circleRL[@]}" "${circleCL[@]}")
input=("${circleLN[@]}" "${circleRN[@]}" "${circleCN[@]}" \
"${gravityEN[@]}")
lookAhead=("${circleLL[@]}" "${circleRL[@]}" "${circleCL[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 大文字 ----

# 左が、左が丸い大文字の場合 均等な大文字 元の位置に戻らない
backtrack=("${circleCapitalLN[@]}")
input=("${gravityCapitalER[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が、左右が丸い大文字で 右が、左右が丸い大文字の場合 左右が丸い、均等な大文字 元の位置に戻る
backtrack=("${circleCapitalLN[@]}" "${circleCapitalRN[@]}" "${circleCapitalCN[@]}")
input=("${circleCapitalLR[@]}" "${circleCapitalRR[@]}" "${circleCapitalCR[@]}" \
"${gravityCapitalER[@]}")
lookAhead=("${circleCapitalLR[@]}" "${circleCapitalRR[@]}" "${circleCapitalCR[@]}" \
"${circleCapitalLN[@]}" "${circleCapitalRN[@]}" "${circleCapitalCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が、右寄り、均等な大文字で 右が、均等な大文字の場合 左右が丸い、均等な大文字 元の位置に戻る
backtrack=("${gravityCapitalRN[@]}" "${gravityCapitalEN[@]}")
input=("${circleCapitalLR[@]}" "${circleCapitalRR[@]}" "${circleCapitalCR[@]}" \
"${gravityCapitalER[@]}")
lookAhead=("${gravityCapitalER[@]}" \
"${gravityCapitalEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 小文字 ---

# 左が、左が丸い小文字の場合 均等な小文字 元の位置に戻らない
backtrack=("${circleSmallLN[@]}")
input=("${gravitySmallER[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が、右が丸い小文字で 右が、左右が丸い小文字の場合 右が丸い小文字 元の位置に戻る
backtrack=("${circleSmallRN[@]}" "${circleSmallCN[@]}")
input=("${circleSmallRR[@]}")
lookAhead=("${circleSmallLR[@]}" "${circleSmallRR[@]}" "${circleSmallCR[@]}" \
"${circleSmallLN[@]}" "${circleSmallRN[@]}" "${circleSmallCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が、左右が丸い小文字で 右が、左右が丸い小文字の場合 左が丸い、均等な小文字 元の位置に戻る
backtrack=("${circleSmallLN[@]}" "${circleSmallRN[@]}" "${circleSmallCN[@]}")
input=("${circleSmallLR[@]}" "${circleSmallCR[@]}" \
"${gravitySmallER[@]}")
lookAhead=("${circleSmallLR[@]}" "${circleSmallRR[@]}" "${circleSmallCR[@]}" \
"${circleSmallLN[@]}" "${circleSmallRN[@]}" "${circleSmallCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が、右が丸い、均等な小文字で 右が、左寄り、均等な小文字の場合 右が丸い小文字 元の位置に戻る
backtrack=("${circleSmallRN[@]}" "${circleSmallCN[@]}" \
"${gravitySmallEN[@]}")
input=("${circleSmallRR[@]}")
lookAhead=("${gravitySmallLR[@]}" "${gravitySmallER[@]}" \
"${gravitySmallLN[@]}" "${gravitySmallEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が、右が丸い、右寄り、均等な小文字で 右が、左寄り、均等な小文字の場合 左が丸い、均等な小文字 元の位置に戻る
backtrack=("${circleSmallRN[@]}" "${circleSmallCN[@]}" \
"${gravitySmallRN[@]}" "${gravitySmallEN[@]}")
input=("${circleSmallLR[@]}" "${circleSmallCR[@]}" \
"${gravitySmallER[@]}")
lookAhead=("${gravitySmallLR[@]}" "${gravitySmallER[@]}" \
"${gravitySmallLN[@]}" "${gravitySmallEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# その他の処理 1 ----------------------------------------

# 左が、右が丸い、均等な文字で 右が、左右が丸い、均等な文字の場合 丸い、均等な文字 元の位置に戻る
backtrack=("${circleRR[@]}" "${circleCR[@]}" "${gravityER[@]}")
input=("${circleCR[@]}" "${gravityER[@]}")
lookAhead=("${circleRN[@]}" "${circleLN[@]}" "${circleCN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が、均等な文字で その左が、右が丸い文字で 右が幅広の文字の場合 左が丸い文字 左に移動
backtrack1=("${circleRR[@]}" "${circleCR[@]}")
backtrack=("${gravityEN[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("${gravityWR[@]}" \
"${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}"
index=`expr ${index} + 1`

# 左が、左が丸い文字で 右が、右寄り、中間、Vの字の場合 幅広の文字 元に戻る
backtrack=("${circleLL[@]}" "${circleCL[@]}")
input=("${gravityWR[@]}")
lookAhead=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# その他の処理 2 ----------------------------------------

# 左が引き寄せる文字の場合 左右が丸い、均等な文字 元の位置に戻らない
backtrack=("${gravityVL[@]}" "${gravityCL[@]}" \
"${gravityVN[@]}" "${gravityCN[@]}")
input=("${circleSmallRL[@]}" "${circleSmallCL[@]}" \
"${gravitySmallEL[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右が左寄り、均等な文字の場合 右が丸い小文字 元の位置に戻る
backtrack=("")
input=("${circleSmallRL[@]}" "${circleSmallCL[@]}")
lookAhead=("${gravityLR[@]}" "${gravityER[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右が均等な文字の場合 均等な小文字 元の位置に戻る
backtrack=("")
input=("${gravitySmallEL[@]}")
lookAhead=("${gravityER[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# その他の処理 3 ----------------------------------------

# 左が、右が丸い文字で 右が左寄り、均等な文字の場合 左が丸い、均等な文字 左に移動
backtrack=("${circleRL[@]}" "${circleCL[@]}")
input=("${circleLN[@]}" "${circleCN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityLL[@]}" "${gravityEL[@]}" \
"${gravityLN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# その他の処理 4 ----------------------------------------

# 左が左寄り、中間の文字で 右が幅広の文字の場合 Vの字 左に移動
backtrack=("${gravityLR[@]}" "${gravityMR[@]}")
input=("${gravityVN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左がVの字で 右が左寄り、幅広の文字の場合 幅広の文字 左に移動
backtrack=("${gravityVL[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityLR[@]}" "${gravityWR[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

fi
# 記号類 ||||||||||||||||||||||||||||||||||||||||

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
echo "<LookupType value=\"6\"/>" >> "${caltList}.txt"
echo "<LookupFlag value=\"0\"/>" >> "${caltList}.txt"
index="0"

# | に関する処理 ----------------------------------------

# 左が上下対称な演算子の場合 | 下に移動
backtrack=("${colonU[@]}" "${barD[@]}" \
"${operatorHN[@]}" "${lessN[@]}" "${greaterN[@]}")
input=("${bar}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexD}"
index=`expr ${index} + 1`

# 右が上下対称な演算子の場合 | 下に移動
backtrack=("")
input=("${bar}")
lookAhead=("${operatorHN[@]}" "${colonN[@]}" "${lessN[@]}" "${greaterN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexD}"
index=`expr ${index} + 1`

# ~ に関する処理 ----------------------------------------

# 左が < > の場合 ~ 下に移動
backtrack=("${tildeD[@]}" \
"${lessN[@]}" "${greaterN[@]}")
input=("${tilde}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexD}"
index=`expr ${index} + 1`

# 右が < > の場合 ~ 下に移動
backtrack=("")
input=("${tilde}")
lookAhead=("${lessN[@]}" "${greaterN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexD}"
index=`expr ${index} + 1`

# : に関する処理 ----------------------------------------

# 両側が数字の場合 : 上に移動
backtrack=("${figureN[@]}")
input=("${colon}")
lookAhead=("${figureN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexU}"
index=`expr ${index} + 1`

# 左が上下対称な演算子の場合 : 上に移動
backtrack=("${colonU[@]}" "${barD[@]}" \
"${operatorHN[@]}" "${lessN[@]}" "${greaterN[@]}")
input=("${colon}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexU}"
index=`expr ${index} + 1`

# 右が上下対称な演算子の場合 : 上に移動
backtrack=("")
input=("${colon}")
lookAhead=("${barN[@]}" "${operatorHN[@]}" "${lessN[@]}" "${greaterN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexU}"
index=`expr ${index} + 1`

# - に関する処理 ----------------------------------------

# 左が < で 右が > の場合 - 移動しない
backtrack=("${lessR[@]}" \
"${lessN[@]}")
input=("${hyphen}")
lookAhead=("${greaterN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が < の場合 - 左に移動
backtrack=("${lessR[@]}" \
"${lessN[@]}")
input=("${hyphen}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"
index=`expr ${index} + 1`

# 右が > の場合 - 右に移動
backtrack=("")
input=("${hyphen}")
lookAhead=("${greaterN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"
index=`expr ${index} + 1`

# < に関する処理 ----------------------------------------

# 右が - < の場合 < 右に移動
backtrack=("")
input=("${less}")
lookAhead=("${hyphenN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"
index=`expr ${index} + 1`

# > に関する処理 ----------------------------------------

# 左が - > の場合 > 左に移動
backtrack=("${hyphenR[@]}" \
"${hyphenN[@]}")
input=("${greater}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"
index=`expr ${index} + 1`

# reverse solidus に関する処理 ----------------------------------------

# 左が、右が低い文字、狭い文字、A で  右が、左下が開いている文字か W の場合 reverse solidus 移動しない
backtrack=("${lowRL[@]}" "${lowCL[@]}" "${gravityCL[@]}" "${_AL[@]}" \
"${lowRN[@]}" "${lowCN[@]}" "${gravityCN[@]}" "${_A[@]}")
input=("${rSolidus}")
lookAhead=("${spaceLR[@]}" "${spaceCR[@]}" "${_WR[@]}" \
"${spaceLN[@]}" "${spaceCN[@]}" "${_W[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が、右が低い文字、狭い文字、A で reverse solidus 左に移動
backtrack=("${lowRL[@]}" "${lowCL[@]}" "${gravityCL[@]}" "${_AL[@]}" \
"${lowRN[@]}" "${lowCN[@]}" "${gravityCN[@]}" "${_A[@]}")
input=("${rSolidus}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"
index=`expr ${index} + 1`

# 右が、左下が開いている文字か W の場合 reverse solidus 右に移動
backtrack=("")
input=("${rSolidus}")
lookAhead=("${spaceLR[@]}" "${spaceCR[@]}" "${_WR[@]}" \
"${spaceLN[@]}" "${spaceCN[@]}" "${_W[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"
index=`expr ${index} + 1`

# solidus に関する処理 ----------------------------------------

# 左が、右下が開いている文字か W で 右が、左が低い文字、狭い文字、A の場合 solidus 移動しない
backtrack=("${spaceRL[@]}" "${spaceCL[@]}" "${_WL[@]}" \
"${spaceRN[@]}" "${spaceCN[@]}" "${_W[@]}")
input=("${solidus}")
lookAhead=("${lowLR[@]}" "${lowCR[@]}" "${gravityCR[@]}" "${_AR[@]}" \
"${lowLN[@]}" "${lowCN[@]}" "${gravityCN[@]}" "${_A[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右が、左が低い文字、狭い文字、A の場合 solidus 右に移動
backtrack=("")
input=("${solidus}")
lookAhead=("${lowLR[@]}" "${lowCR[@]}" "${gravityCR[@]}" "${_AR[@]}" \
"${lowLN[@]}" "${lowCN[@]}" "${gravityCN[@]}" "${_A[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"
index=`expr ${index} + 1`

# 左が、右下が開いている文字か W の場合 solidus 左に移動
backtrack=("${spaceRL[@]}" "${spaceCL[@]}" "${_WL[@]}" \
"${spaceRN[@]}" "${spaceCN[@]}" "${_W[@]}")
input=("${solidus}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"
index=`expr ${index} + 1`

# 再調整 ========================================

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
echo "<LookupType value=\"6\"/>" >> "${caltList}.txt"
echo "<LookupFlag value=\"0\"/>" >> "${caltList}.txt"
index="0"

# | ~ : に関する処理 ----------------------------------------

# 右が | ~ の場合 | ~ 下に移動 (4個まで)
member=("${bar[@]}" "${tilde[@]}")
for T in ${member[@]}; do
  backtrack=("")
  input=("${T}")
  lookAhead=("${T}D")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexD}"
  index=`expr ${index} + 1`
done

for T in ${member[@]}; do
  backtrack1=("")
  backtrack=("")
  input=("${T}")
  lookAhead=("${T}D" \
  "${T}")
  lookAhead1=("${T}D")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexD}" "${backtrack1[*]}" "${lookAhead1[*]}"
  index=`expr ${index} + 1`
done

for T in ${member[@]}; do
  backtrack1=("")
  backtrack=("")
  input=("${T}")
  lookAhead=("${T}D" \
  "${T}")
  lookAhead1=("${T}D" \
  "${T}")
  lookAheadX=("${T}D"); aheadMax="2"
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexD}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"
  index=`expr ${index} + 1`
done

# 右が : の場合 : 上に移動 (4個まで)
member=("${colon[@]}")
for T in ${member[@]}; do
  backtrack=("")
  input=("${T}")
  lookAhead=("${T}U")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexU}"
  index=`expr ${index} + 1`
done

for T in ${member[@]}; do
  backtrack1=("")
  backtrack=("")
  input=("${T}")
  lookAhead=("${T}U" \
  "${T}")
  lookAhead1=("${T}U")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexU}" "${backtrack1[*]}" "${lookAhead1[*]}"
  index=`expr ${index} + 1`
done

for T in ${member[@]}; do
  backtrack1=("")
  backtrack=("")
  input=("${T}")
  lookAhead=("${T}U" \
  "${T}")
  lookAhead1=("${T}U" \
  "${T}")
  lookAheadX=("${T}U"); aheadMax="2"
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexU}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"
  index=`expr ${index} + 1`
done

# 桁区切り設定作成 ||||||||||||||||||||||||||||||||||||||||

# 小数の処理 ----------------------------------------

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
echo "<LookupType value=\"6\"/>" >> "${caltList}.txt"
echo "<LookupFlag value=\"0\"/>" >> "${caltList}.txt"
index="0"

backtrack=("${fullStop[@]}")
input=("${figureN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex0}"
index=`expr ${index} + 1`

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
echo "<LookupType value=\"6\"/>" >> "${caltList}.txt"
echo "<LookupFlag value=\"0\"/>" >> "${caltList}.txt"
index="0"

backtrack=("${figure0[@]}")
input=("${figureN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex0}"
index=`expr ${index} + 1`

# 12桁マークを付ける処理 1 ----------------------------------------

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
echo "<LookupType value=\"6\"/>" >> "${caltList}.txt"
echo "<LookupFlag value=\"0\"/>" >> "${caltList}.txt"
index="0"

backtrack1=("")
backtrack=("${figure2[@]}" "${figureN[@]}")
input=("${figureN[@]}")
lookAhead=("${figureN[@]}")
lookAhead1=("${figureN[@]}")
lookAheadX=("${figureN[@]}"); aheadMax="10"
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex2}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"
index=`expr ${index} + 1`

# ノーマルに戻す処理 1 ----------------------------------------

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
echo "<LookupType value=\"6\"/>" >> "${caltList}.txt"
echo "<LookupFlag value=\"0\"/>" >> "${caltList}.txt"
index="0"

backtrack=("")
input=("${figure2[@]}")
lookAhead=("${figure2[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 12桁マークを付ける処理 2 ----------------------------------------

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
echo "<LookupType value=\"6\"/>" >> "${caltList}.txt"
echo "<LookupFlag value=\"0\"/>" >> "${caltList}.txt"
index="0"

backtrack1=("")
backtrack=("${figure2[@]}" "${figureN[@]}")
input=("${figureN[@]}")
lookAhead=("${figureN[@]}")
lookAhead1=("${figureN[@]}")
lookAheadX=("${figureN[@]}"); aheadMax="10"
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex2}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"
index=`expr ${index} + 1`

# ノーマルに戻す処理 2 ----------------------------------------

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
echo "<LookupType value=\"6\"/>" >> "${caltList}.txt"
echo "<LookupFlag value=\"0\"/>" >> "${caltList}.txt"
index="0"

backtrack=("")
input=("${figure2[@]}")
lookAhead=("${figure2[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 4桁マークを付ける処理 1 ----------------------------------------

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
echo "<LookupType value=\"6\"/>" >> "${caltList}.txt"
echo "<LookupFlag value=\"0\"/>" >> "${caltList}.txt"
index="0"

backtrack1=("")
backtrack=("${figure2[@]}" "${figure4[@]}" "${figureN[@]}")
input=("${figureN[@]}")
lookAhead=("${figureN[@]}")
lookAhead1=("${figureN[@]}")
lookAheadX=("${figureN[@]}"); aheadMax="2"
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex4}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"
index=`expr ${index} + 1`

# ノーマルに戻す処理 3 ----------------------------------------

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
echo "<LookupType value=\"6\"/>" >> "${caltList}.txt"
echo "<LookupFlag value=\"0\"/>" >> "${caltList}.txt"
index="0"

backtrack=("")
input=("${figure4[@]}")
lookAhead=("${figure4[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 4桁マークを付ける処理 2 ----------------------------------------

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
echo "<LookupType value=\"6\"/>" >> "${caltList}.txt"
echo "<LookupFlag value=\"0\"/>" >> "${caltList}.txt"
index="0"

backtrack1=("")
backtrack=("${figure2[@]}" "${figure4[@]}" "${figureN[@]}")
input=("${figureN[@]}")
lookAhead=("${figureN[@]}")
lookAhead1=("${figureN[@]}")
lookAheadX=("${figureN[@]}"); aheadMax="2"
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex4}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"
index=`expr ${index} + 1`

# ノーマルに戻す処理 4 ----------------------------------------

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
echo "<LookupType value=\"6\"/>" >> "${caltList}.txt"
echo "<LookupFlag value=\"0\"/>" >> "${caltList}.txt"
index="0"

backtrack=("")
input=("${figure4[@]}")
lookAhead=("${figure4[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 3桁マークを付ける処理 1 ----------------------------------------

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
echo "<LookupType value=\"6\"/>" >> "${caltList}.txt"
echo "<LookupFlag value=\"0\"/>" >> "${caltList}.txt"
index="0"

backtrack1=("")
backtrack=("${figure2[@]}" "${figure3[@]}" "${figure4[@]}" "${figureN[@]}")
input=("${figureN[@]}")
lookAhead=("${figureN[@]}")
lookAhead1=("${figureN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex3}" "${backtrack1[*]}" "${lookAhead1[*]}"
index=`expr ${index} + 1`

backtrack1=("")
backtrack=("${figure2[@]}" "${figure3[@]}" "${figure4[@]}" "${figureN[@]}")
input=("${figureN[@]}")
lookAhead=("${figureN[@]}")
lookAhead1=("${figure4[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex3}" "${backtrack1[*]}" "${lookAhead1[*]}"
index=`expr ${index} + 1`

backtrack1=("")
backtrack=("${figure2[@]}" "${figure3[@]}" "${figure4[@]}" "${figureN[@]}")
input=("${figureN[@]}")
lookAhead=("${figure4[@]}")
lookAhead1=("${figureN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex3}" "${backtrack1[*]}" "${lookAhead1[*]}"
index=`expr ${index} + 1`

# ノーマルに戻す処理 5 ----------------------------------------

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
echo "<LookupType value=\"6\"/>" >> "${caltList}.txt"
echo "<LookupFlag value=\"0\"/>" >> "${caltList}.txt"
index="0"

backtrack=("")
input=("${figure3[@]}")
lookAhead=("${figure3[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

backtrack1=("")
backtrack=("")
input=("${figure3[@]}")
lookAhead=("${figure2[@]}" "${figure3[@]}" "${figure4[@]}" "${figureN[@]}")
lookAhead1=("${figure2[@]}" "${figure3[@]}" "${figure4[@]}" "${figureN[@]}")
lookAheadX=("${figureN[@]}"); aheadMax="2"
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"
index=`expr ${index} + 1`

# 3桁マークを付ける処理 2 ----------------------------------------

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
echo "<LookupType value=\"6\"/>" >> "${caltList}.txt"
echo "<LookupFlag value=\"0\"/>" >> "${caltList}.txt"
index="0"

backtrack1=("")
backtrack=("${figure2[@]}" "${figure3[@]}" "${figure4[@]}" "${figureN[@]}")
input=("${figureN[@]}")
lookAhead=("${figureN[@]}")
lookAhead1=("${figureN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex3}" "${backtrack1[*]}" "${lookAhead1[*]}"
index=`expr ${index} + 1`

backtrack1=("")
backtrack=("${figure2[@]}" "${figure3[@]}" "${figure4[@]}" "${figureN[@]}")
input=("${figureN[@]}")
lookAhead=("${figureN[@]}")
lookAhead1=("${figure4[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex3}" "${backtrack1[*]}" "${lookAhead1[*]}"
index=`expr ${index} + 1`

# ノーマルに戻す処理 6 ----------------------------------------

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
echo "<LookupType value=\"6\"/>" >> "${caltList}.txt"
echo "<LookupFlag value=\"0\"/>" >> "${caltList}.txt"
index="0"

backtrack=("")
input=("${figure3[@]}")
lookAhead=("${figure3[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 2進数のみ4桁区切りを有効にする処理 ----------------------------------------

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
echo "<LookupType value=\"6\"/>" >> "${caltList}.txt"
echo "<LookupFlag value=\"0\"/>" >> "${caltList}.txt"
index="0"

backtrack1=("")
backtrack=("${figureBN[@]}")
input=("${figureB2[@]}")
lookAhead=("${figureBN[@]}")
lookAhead1=("${figureBN[@]}")
lookAheadX=("${figureB3[@]}"); aheadMax="2"
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex2}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"
index=`expr ${index} + 1`

backtrack1=("")
backtrack=("${figureB3[@]}" "${figureBN[@]}")
input=("${figureB4[@]}")
lookAhead=("${figureBN[@]}")
lookAhead1=("${figureB3[@]}")
lookAheadX=("${figureBN[@]}"); aheadMax="2"
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex4}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"
index=`expr ${index} + 1`

backtrack1=("")
backtrack=("${figureB3[@]}" "${figureBN[@]}")
input=("${figureB4[@]}")
lookAhead=("${figureB3[@]}")
lookAhead1=("${figureBN[@]}")
lookAheadX=("${figureBN[@]}"); aheadMax="2"
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex4}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"
index=`expr ${index} + 1`

backtrack=("")
input=("${figure2[@]}")
lookAhead=("${figureN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex3}"
index=`expr ${index} + 1`

backtrack=("")
input=("${figure4[@]}")
lookAhead=("${figure3[@]}" "${figureN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# ---

rm -f ${listTemp}.txt
if [ "${leaving_tmp_flag}" = "false" ]; then
  remove_temp
fi
echo

# Exit
echo "Finished making the GSUB table [calt, LookupType 6]."
echo
exit 0
