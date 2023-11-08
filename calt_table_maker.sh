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
S="grvyCapitalL"; class+=("${S}"); eval ${S}=\(`letter_members "${gCL[*]}"`\) # 左寄りの大文字
S="grvySmallL"; class+=("${S}"); eval ${S}=\(`letter_members "${gSL[*]}"`\) # 左寄りの小文字

gCR=("_C" "_G")
gSR=("_a" "_c" "_d" "_g" "_q")
S="grvyCapitalR"; class+=("${S}"); eval ${S}=\(`letter_members "${gCR[*]}"`\) # 右寄りの大文字
S="grvySmallR"; class+=("${S}"); eval ${S}=\(`letter_members "${gSR[*]}"`\) # 右寄りの小文字

gCW=("_M" "_W" "_AE" "_OE")
gSW=("_m" "_w" "_ae" "_oe")
S="grvyCapitalW"; class+=("${S}"); eval ${S}=\(`letter_members "${gCW[*]}"`\) # 幅広の大文字
S="grvySmallW"; class+=("${S}"); eval ${S}=\(`letter_members "${gSW[*]}"`\) # 幅広の小文字

gCE=("_H" "_N" "_O" "_Q" "_U")
gSE=("_n" "_u")
S="grvyCapitalE"; class+=("${S}"); eval ${S}=\(`letter_members "${gCE[*]}"`\) # 均等な大文字
S="grvySmallE"; class+=("${S}"); eval ${S}=\(`letter_members "${gSE[*]}"`\) # 均等な小文字

gCM=("_A" "_S" "_X" "_Z")
gSM=("_e" "_o" "_s" "_x" "_z")
S="grvyCapitalM"; class+=("${S}"); eval ${S}=\(`letter_members "${gCM[*]}"`\) # 中間の大文字
S="grvySmallM"; class+=("${S}"); eval ${S}=\(`letter_members "${gSM[*]}"`\) # 中間の小文字

gCV=("_T" "_V" "_Y")
gSV=("_v" "_y")
S="grvyCapitalV"; class+=("${S}"); eval ${S}=\(`letter_members "${gCV[*]}"`\) # Vの字の大文字
S="grvySmallV"; class+=("${S}"); eval ${S}=\(`letter_members "${gSV[*]}"`\) # vの字の小文字

gCC=("_I" "_J")
gSC=("_f" "_i" "_j" "_l" "_r" "_t")
S="grvyCapitalC"; class+=("${S}"); eval ${S}=\(`letter_members "${gCC[*]}"`\) # 狭い大文字
S="grvySmallC"; class+=("${S}"); eval ${S}=\(`letter_members "${gSC[*]}"`\) # 狭い小文字

S="gravityL"; class+=("${S}"); eval ${S}=\("${grvyCapitalL[@]}" "${grvySmallL[@]}"\) # 左寄り(幅広、左にある右寄り、均等は離れようとする)
S="gravityR"; class+=("${S}"); eval ${S}=\("${grvyCapitalR[@]}" "${grvySmallR[@]}"\) # 右寄り(幅広、右にある左寄り、均等は離れようとする)
S="gravityW"; class+=("${S}"); eval ${S}=\("${grvyCapitalW[@]}" "${grvySmallW[@]}"\) # 幅広(全てが離れようとする)
S="gravityE"; class+=("${S}"); eval ${S}=\("${grvyCapitalE[@]}" "${grvySmallE[@]}"\) # 均等(幅広、均等、左にある右寄り、右にある左寄りは離れようとする)
S="gravityM"; class+=("${S}"); eval ${S}=\("${grvyCapitalM[@]}" "${grvySmallM[@]}"\) # 中間(幅広以外は離れようとしない)
S="gravityV"; class+=("${S}"); eval ${S}=\("${grvyCapitalV[@]}" "${grvySmallV[@]}"\) # Vの字(中間、左にある左寄り、右にある右寄りは近づこうとする)
S="gravityC"; class+=("${S}"); eval ${S}=\("${grvyCapitalC[@]}" "${grvySmallC[@]}"\) # 狭い(全てが近づこうとする)

# やや寄り気味 --------------------

grC=("_J" "_j")
grM=("_j")
S="gravity_rC"; class+=("${S}"); eval ${S}=\(`letter_members "${grC[*]}"`\) # 引き寄せるやや右寄り
S="gravity_rM"; class+=("${S}"); eval ${S}=\(`letter_members "${grM[*]}"`\) # 引き寄せないやや右寄り(例外あり)

glM=("_e" "_t")
glC=("_f" "_l" "_r" "_t" "_y")
S="gravity_lM"; class+=("${S}"); eval ${S}=\(`letter_members "${glM[*]}"`\) # 引き寄せないやや左寄り(例外あり)
S="gravity_lC"; class+=("${S}"); eval ${S}=\(`letter_members "${glC[*]}"`\) # 引き寄せるやや左寄り

S="grvyCapitalF"; class+=("${S}")
eval ${S}=\("${grvyCapitalL[@]}" "${grvyCapitalR[@]}" "${grvyCapitalW[@]}" "${grvyCapitalE[@]}" "${grvyCapitalM[@]}"\) # 引き寄せない大文字

# 丸い文字 --------------------

cCC=("_O" "_Q")
cSC=("_e" "_o")
S="crclCapitalC"; class+=("${S}"); eval ${S}=\(`letter_members "${cCC[*]}"`\) # 丸い大文字
S="crclSmallC"; class+=("${S}"); eval ${S}=\(`letter_members "${cSC[*]}"`\) # 丸い小文字

cCL=("_C" "_G")
cSL=("_c" "_d" "_g" "_q")
S="crclCapitalL"; class+=("${S}"); eval ${S}=\(`letter_members "${cCL[*]}"`\) # 左が丸い大文字
S="crclSmallL"; class+=("${S}"); eval ${S}=\(`letter_members "${cSL[*]}"`\) # 左が丸い小文字

cCR=("_B" "_D")
cSR=("_b" "_p" "_th" "_ss")
S="crclCapitalR"; class+=("${S}"); eval ${S}=\(`letter_members "${cCR[*]}"`\) # 右が丸い大文字
S="crclSmallR"; class+=("${S}"); eval ${S}=\(`letter_members "${cSR[*]}"`\) # 右が丸い小文字

S="circleC"; class+=("${S}"); eval ${S}=\("${crclCapitalC[@]}" "${crclSmallC[@]}"\) # 丸い文字
S="circleL"; class+=("${S}"); eval ${S}=\("${crclCapitalL[@]}" "${crclSmallL[@]}"\) # 左が丸い文字
S="circleR"; class+=("${S}"); eval ${S}=\("${crclCapitalR[@]}" "${crclSmallR[@]}"\) # 右が丸い文字

# 低い文字 --------------------

lC=("_a" "_c" "_e" "_g" "_i" "_j" "_n" "_o" "_p" "_q" "_r" "_s" "_u" "_v" "_x" "_y" "_z" "_kg")
S="lowC"; class+=("${S}"); eval ${S}=\(`letter_members "${lC[*]}"`\) # 低い文字 (幅広除く)

lL=("_d")
S="lowL"; class+=("${S}"); eval ${S}=\(`letter_members "${lL[*]}"`\) # 左が低い文字

lR=("_b" "_h" "_k" "_th")
S="lowR"; class+=("${S}"); eval ${S}=\(`letter_members "${lR[*]}"`\) # 右が低い文字

# 下が開いている文字 --------------------

sCC=("_I" "_T" "_V" "_Y")
sSC=("_f" "_i" "_l" "_v")
S="spceCapitalC"; class+=("${S}"); eval ${S}=\(`letter_members "${sCC[*]}"`\) # 両下が開いている大文字
S="spceSmallC"; class+=("${S}"); eval ${S}=\(`letter_members "${sSC[*]}"`\) # 両下が開いている小文字

sCL=("")
sSL=("_t")
S="spceCapitalL"; class+=("${S}"); eval ${S}=\(`letter_members "${sCL[*]}"`\) # 左下が開いている大文字
S="spceSmallL"; class+=("${S}"); eval ${S}=\(`letter_members "${sSL[*]}"`\) # 左下が開いている小文字

sCR=("_F" "_J" "_P" "_TH")
sSR=("_j" "_r" "_y")
S="spceCapitalR"; class+=("${S}"); eval ${S}=\(`letter_members "${sCR[*]}"`\) # 右下が開いている大文字
S="spceSmallR"; class+=("${S}"); eval ${S}=\(`letter_members "${sSR[*]}"`\) # 右下が開いている小文字

S="spaceC"; class+=("${S}"); eval ${S}=\("${spceCapitalC[@]}" "${spceSmallC[@]}"\) # 両下が開いている文字
S="spaceL"; class+=("${S}"); eval ${S}=\("${spceCapitalL[@]}" "${spceSmallL[@]}"\) # 左下が開いている文字
S="spaceR"; class+=("${S}"); eval ${S}=\("${spceCapitalR[@]}" "${spceSmallR[@]}"\) # 右下が開いている文字

# 全て --------------------

S="capitalAll"; class+=("${S}")
eval ${S}=\("${grvyCapitalL[@]}" "${grvyCapitalR[@]}" "${grvyCapitalW[@]}" "${grvyCapitalE[@]}"\)
eval ${S}+=\("${grvyCapitalM[@]}" "${grvyCapitalV[@]}" "${grvyCapitalC[@]}"\) # 全ての大文字
S="smallAll"; class+=("${S}")
eval ${S}=\("${grvySmallL[@]}" "${grvySmallR[@]}" "${grvySmallW[@]}" "${grvySmallE[@]}"\)
eval ${S}+=\("${grvySmallM[@]}" "${grvySmallV[@]}" "${grvySmallC[@]}"\) # 全ての小文字

# 略号生成 (C 通常、L 左移動後、R 右移動後) --------------------

for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
  for T in ${member[@]}; do
    eval "${S}C+=(\"${T}C\")"
    eval "${S}L+=(\"${T}L\")"
    eval "${S}R+=(\"${T}R\")"
  done
done

 # 特殊 (通常と移動後で内容が異なる) --------------------

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

# 通常のみ --------------------

symbolFigure=("#" "$" "%" "&" "@" 0 2 3 4 5 6 7 8 9) # 幅のある記号と数字

# グリフ名変換用辞書作成 (グリフのIDS順に並べること) ||||||||||||||||||||||||||||||||||||||||

# 略号と名前 ----------------------------------------

solidus=("/") # 単独で変数を使用するため他と分けて代入
solidus_name=("slash")
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

# カーニング設定作成 ||||||||||||||||||||||||||||||||||||||||

echo "Make GSUB calt List"

echo "<LookupType value=\"6\"/>" >> "${caltList}.txt"
echo "<LookupFlag value=\"0\"/>" >> "${caltList}.txt"

index="0"

# 記号類 ========================================

# colon に関する処理 ----------------------------------------

# 両方が数字の場合 colon 上に移動
backtrack=("${figure[@]}")
input=("${colon}")
lookAhead=("${figure[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexU}"
index=`expr ${index} + 1`

# reverse solidus に関する処理 ----------------------------------------

# 左が、右が低い文字か A で 右が、左下が開いている文字か W の場合 reverse solidus 移動しない
backtrack=("${lowRL[@]}" "${lowCL[@]}" "${_AL[@]}" \
"${lowRC[@]}" "${lowCC[@]}" "${_AC[@]}")
input=("${rSolidus}")
lookAhead=("${spaceLC[@]}" "${spaceCC[@]}" "${_WC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が、右が低い文字か A で 右が寄せない文字の場合 reverse solidus 左に移動
backtrack=("${lowRL[@]}" "${lowCL[@]}" "${_AL[@]}" \
"${lowRC[@]}" "${lowCC[@]}" "${_AC[@]}")
input=("${rSolidus}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右が、左下が開いている文字か W の場合 reverse solidus 右に移動
backtrack=("")
input=("${rSolidus}")
lookAhead=("${spaceLC[@]}" "${spaceCC[@]}" "${_WC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# solidus に関する処理 ----------------------------------------

# 左が 右下が開いている文字か W で 右が、左が低い文字か A の場合 solidus 移動しない
backtrack=("${spaceRR[@]}" "${spaceCR[@]}" "${_WR[@]}" \
"${spaceRC[@]}" "${spaceCC[@]}" "${_WC[@]}")
input=("${solidus}")
lookAhead=("${lowLC[@]}" "${lowCC[@]}" "${_AC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が寄せない文字で 右が、左が低い文字か A の場合 solidus 右に移動
backtrack=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" \
"${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
input=("${solidus}")
lookAhead=("${lowLC[@]}" "${lowCC[@]}" "${_AC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が、右下が開いている文字か W の場合 solidus 左に移動
backtrack=("${spaceRL[@]}" "${spaceCL[@]}" "${_WL[@]}" \
"${spaceRC[@]}" "${spaceCC[@]}" "${_WC[@]}")
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

# 同じ文字の連続 ========================================

# 同じ文字を等間隔にさせる例外処理 1 ----------------------------------------

# B
backtrack=("${_BL[@]}")
input=("${_BC[@]}")
# 左右を見て B 左に移動しない
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`
# 左側を見て B 左に移動  (左側の B は左に移動するため)
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# D
backtrack=("${_DL[@]}")
input=("${_DC[@]}")
# 左右を見て D 左に移動しない
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`
# 左側を見て D 左に移動
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側を見て L 右に移動 (左側の L は右に移動するため)
backtrack=("${_LR[@]}")
input=("${_LC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

class=("${gCL[@]}" "${gSL[@]}")
# その他の左寄りの文字
for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
  backtrack=(""); input=("")
  for T in ${member[@]}; do
    backtrack+=("${T}C")
    input+=("${T}C")
  done
# 左右を見て 左寄りの文字 左に移動 (右に幅広の文字がある場合)
  lookAhead=("${gravityWC[@]}")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
  index=`expr ${index} + 1`
# 左右を見て 左寄りの文字 右に移動 (右に引き離さない文字がある場合)
  lookAhead=("${gravityRC[@]}" "${gravityMC[@]}" "${gravityVC[@]}" "${gravityCC[@]}")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
  index=`expr ${index} + 1`
# 左側を見て 左寄りの文字 移動しない (右がその他)
  lookAhead=("")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
  index=`expr ${index} + 1`
done

# 同じ文字を等間隔にさせる例外処理 2 ----------------------------------------

# G
backtrack=("${_GL[@]}")
input=("${_GC[@]}")
# 左右を見て G 左に移動しない
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`
# 左側を見て G 左に移動
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

class=("${gCR[@]}" "${gSR[@]}")
# その他の右寄りの文字
for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
  backtrack=(""); input=("")
  for T in ${member[@]}; do
    backtrack+=("${T}C")
    input+=("${T}C")
  done
# 左右を見て 右寄りの文字 右に移動 (右に狭い文字がある場合)
  lookAhead=("${gravityCC[@]}")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
  index=`expr ${index} + 1`
# 左側を見て 右寄りの文字 移動しない (右がその他)
  lookAhead=("")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
  index=`expr ${index} + 1`
done

# 同じ文字を等間隔にさせる例外処理 3 ----------------------------------------

class=("${gCW[@]}" "${gSW[@]}")
# 左右を見て 幅広な文字 移動しない (右に異なる幅広がある場合)
for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
  backtrack=(""); input=("")
  for T in ${member[@]}; do
    backtrack+=("${T}L")
    input+=("${T}C")
  done
  otherMembers=("")
  for T in ${class[@]}; do
    if [ "${S}" != "${T}" ]; then
      eval "otherMembers+=(\"\${${T}[@]}\")"
    fi
  done
  lookAhead=("")
  for T in ${otherMembers[@]}; do
    lookAhead+=("${T}C")
  done
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
  index=`expr ${index} + 1`
done

# その他の幅広の文字
for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
  backtrack=(""); input=("")
  for T in ${member[@]}; do
    backtrack+=("${T}L")
    input+=("${T}C")
  done
# 左右を見て 幅広な文字 右に移動 (右に幅広以外がある場合)
  lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}"  "${gravityCC[@]}")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
  index=`expr ${index} + 1`
# 左側を見て 幅広な文字 左に移動 (右がその他)
  lookAhead=("")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
  index=`expr ${index} + 1`
done

# 同じ文字を等間隔にさせる例外処理 4 ----------------------------------------

class=("${gCE[@]}" "${gSE[@]}")
# 左右を見て 均等な文字 移動しない (右に異なる均等な文字がある場合)
for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
  backtrack=(""); input=("")
  for T in ${member[@]}; do
    backtrack+=("${T}L")
    input+=("${T}C")
  done
  otherMembers=("")
  for T in ${class[@]}; do
    if [ "${S}" != "${T}" ]; then
      eval "otherMembers+=(\"\${${T}[@]}\")"
    fi
  done
  lookAhead=("")
  for T in ${otherMembers[@]}; do
    lookAhead+=("${T}C")
  done
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
  index=`expr ${index} + 1`
done

# その他の均等な文字
for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
  backtrack=(""); input=("")
  for T in ${member[@]}; do
    backtrack+=("${T}L")
    input+=("${T}C")
  done
# 左右を見て 均等な文字 左に移動しない (右に狭い文字がある場合)
  lookAhead=("${gravityCC[@]}")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
  index=`expr ${index} + 1`
# 左側を見て 均等な文字 左に移動 (右がその他)
  lookAhead=("")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
  index=`expr ${index} + 1`
done

# 同じ文字を等間隔にさせる例外処理 5 ----------------------------------------

class=("${gCC[@]}" "${gSC[@]}")
# 左右を見て 狭い文字 移動しない (右に異なる狭い文字がある場合)
for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
  backtrack=(""); input=("")
  for T in ${member[@]}; do
    backtrack+=("${T}R")
    input+=("${T}C")
  done
  otherMembers=("")
  for T in ${class[@]}; do
    if [ "${S}" != "${T}" ]; then
      eval "otherMembers+=(\"\${${T}[@]}\")"
    fi
  done
  lookAhead=("")
  for T in ${otherMembers[@]}; do
    lookAhead+=("${T}C")
  done
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
  index=`expr ${index} + 1`
done

# その他の狭い文字
for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
  backtrack=(""); input=("")
  for T in ${member[@]}; do
    backtrack+=("${T}R")
    input+=("${T}C")
  done
# 左右を見て 狭い文字 左に移動 (右に狭い文字以外がある場合)
  lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
  index=`expr ${index} + 1`
# 左側を見て 狭い文字 右に移動 (右がその他)
  lookAhead=("")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
  index=`expr ${index} + 1`
done

# 個別対応 ========================================

# A に関する例外処理 1 ----------------------------------------

# 左が、右下が開いている大文字 右が W の場合 A 左に移動
backtrack=("${spceCapitalRR[@]}" "${spceCapitalCR[@]}")
input=("${_AC[@]}")
lookAhead=("${_WC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が W で 右が、左下が開いている大文字の場合 A 右に移動
backtrack=("${_WR[@]}")
input=("${_AC[@]}")
lookAhead=("${spceCapitalLC[@]}" "${spceCapitalCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が右下が開いている大文字 右が、左下が開いている大文字の場合 A 移動しない
backtrack=("${spceCapitalRR[@]}" "${spceCapitalCR[@]}")
input=("${_AC[@]}")
lookAhead=("${spceCapitalLC[@]}" "${spceCapitalCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# A に関する例外処理 2 ----------------------------------------

# 左が、右下が開いている大文字の場合 A 左に移動
backtrack=("${spceCapitalRR[@]}" "${spceCapitalCR[@]}")
input=("${_AC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が W の場合 A 左に移動しない
backtrack=("${_WR[@]}")
input=("${_AC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が、右下が開いている大文字か W の場合 A 左に移動
backtrack=("${spceCapitalRL[@]}" "${spceCapitalCL[@]}" "${_WL[@]}" \
"${spceCapitalRC[@]}" "${spceCapitalCC[@]}" "${_WC[@]}")
input=("${_AC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# A に関する例外処理 3 ----------------------------------------

# 左が A の場合 左下が開いている大文字 左に移動する
backtrack=("${_AR[@]}")
input=("${spceCapitalLC[@]}" "${spceCapitalCC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が A の場合 W 左に移動しない
backtrack=("${_AR[@]}")
input=("${_WC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が A の場合 左下が開いている大文字か W 左に移動
backtrack=("${_AL[@]}" \
"${_AC[@]}")
input=("${spceCapitalLC[@]}" "${spceCapitalCC[@]}" "${_WC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# A に関する例外処理 4 ----------------------------------------

# 右が、右下が開いている大文字か W の場合 A 右に移動しない
backtrack=("${grvyCapitalLL[@]}" "${grvyCapitalRL[@]}" "${grvyCapitalEL[@]}" "${grvyCapitalML[@]}" "${grvyCapitalVL[@]}" "${grvyCapitalCL[@]}" \
"${grvyCapitalVC[@]}" "${grvyCapitalCC[@]}")
input=("${_AC[@]}")
lookAhead=("${spceCapitalRC[@]}" "${spceCapitalCC[@]}" "${_WC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右が A の場合 右下が開いている大文字か W 右に移動しない
backtrack=("${grvyCapitalLL[@]}" "${grvyCapitalRL[@]}" "${grvyCapitalEL[@]}" "${grvyCapitalML[@]}" "${grvyCapitalVL[@]}" "${grvyCapitalCL[@]}" \
"${grvyCapitalVC[@]}" "${grvyCapitalCC[@]}")
input=("${spceCapitalRC[@]}" "${spceCapitalCC[@]}" "${_WC[@]}")
lookAhead=("${_AC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# もろもろ例外 ========================================

# 左右を見て左に移動させる例外処理 ----------------------------------------

# 左が幅広、引き寄せる文字以外 右が、左が丸い文字の場合 Vの字 左に移動
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityLC[@]}" "${gravityMC[@]}")
input=("${gravityVC[@]}")
lookAhead=("${circleLC[@]}" "${circleCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が FTf で 右が狭い文字以外の場合 右寄りの小文字、中間の小文字、Vの字の小文字 左に移動
backtrack=("${_FR[@]}" "${_TR[@]}" "${_fR[@]}")
input=("${grvySmallRC[@]}" "${grvySmallMC[@]}" "${grvySmallVC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が filr で 右が狭い文字の場合 狭い以外の小文字 左に移動 (後の処理で両方狭い場合移動なしにしているため)
backtrack=("${_fL[@]}" "${_iL[@]}" "${_lL[@]}" "${_rL[@]}")
input=("${grvySmallLC[@]}" "${grvySmallRC[@]}" "${grvySmallWC[@]}" "${grvySmallEC[@]}" "${grvySmallMC[@]}" "${grvySmallVC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が左寄り、中間の大文字で 右が幅広の大文字の場合 右寄り、均等、中間、Vの字の大文字 左に移動
backtrack=("${grvyCapitalLC[@]}" "${grvyCapitalMC[@]}")
input=("${grvyCapitalRC[@]}" "${grvyCapitalEC[@]}" "${grvyCapitalMC[@]}" "${grvyCapitalVC[@]}")
lookAhead=("${grvyCapitalWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が左寄り、均等、中間の小文字で 右が幅広の小文字の場合 幅広と狭い以外の小文字 左に移動
backtrack=("${grvySmallLC[@]}" "${grvySmallEC[@]}" "${grvySmallMC[@]}")
input=("${grvySmallLC[@]}" "${grvySmallRC[@]}" "${grvySmallEC[@]}" "${grvySmallMC[@]}" "${grvySmallVC[@]}")
lookAhead=("${grvySmallWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左右を見て右に移動させる例外処理 ----------------------------------------

# 左が引き離す文字 右が狭い文字の場合 幅広以外の文字 右に移動
backtrack=("${gravityRL[@]}" "${gravityWL[@]}" "${gravityEL[@]}")
input=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}" "${gravityCC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左右を見て移動させない例外処理 1 ----------------------------------------

# 左が左寄り、中間、Vの字で 右が狭い文字の場合 幅広と狭い以外の文字 移動しない
backtrack=("${gravityLL[@]}" "${gravityML[@]}" "${gravityVL[@]}")
input=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 両方が左寄りの文字の場合 右寄り、均等な文字 移動しない
backtrack=("${gravityLL[@]}")
input=("${gravityRC[@]}" "${gravityEC[@]}")
lookAhead=("${gravityLC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 両方が均等な文字の場合 右寄り、均等な文字 移動しない
backtrack=("${gravityEL[@]}")
input=("${gravityRC[@]}" "${gravityEC[@]}")
lookAhead=("${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 両方が中間の文字の場合 右寄り、均等な文字 移動しない
backtrack=("${gravityML[@]}")
input=("${gravityRC[@]}" "${gravityEC[@]}")
lookAhead=("${gravityMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 両方がVの字の場合 右寄り、均等な文字 移動しない
backtrack=("${gravityVL[@]}")
input=("${gravityRC[@]}" "${gravityEC[@]}")
lookAhead=("${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 両方が狭い文字の場合 狭い以外の文字 移動しない
backtrack=("${gravityCL[@]}")
input=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

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

# 左が左寄り、中間、Vの字 右が、左が丸い文字の場合 左寄りの文字 右に移動しない
backtrack=("${gravityLC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
input=("${gravityLC[@]}")
lookAhead=("${circleLC[@]}" "${circleCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が丸い文字に関する例外処理 1 ----------------------------------------

# 左が幅広で 右が、右が丸い文字の場合 左が丸い文字 移動しない
backtrack=("${gravityWL[@]}")
input=("${circleLC[@]}" "${circleCC[@]}")
lookAhead=("${circleRC[@]}" "${circleCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が左寄り、均等、中間の文字で 右がVの字の場合 左が丸い文字 移動しない
backtrack=("${gravityLC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
input=("${circleLC[@]}" "${circleCC[@]}")
lookAhead=("${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左がVの字で 右が狭い文字の場合 左が丸い文字 右に移動
backtrack=("${gravityVR[@]}")
input=("${circleLC[@]}" "${circleCC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が Fkx で 右が幅広の文字の場合 左が丸い小文字 左に移動
backtrack=("${_FR[@]}" "${_kR[@]}" "${_xR[@]}")
input=("${crclSmallLC[@]}" "${crclSmallCC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が EFKXkx で 右が引き寄せない文字の場合 左が丸い文字 左に移動
backtrack=("${_EC[@]}" "${_FC[@]}" "${_KC[@]}" "${_XC[@]}" "${_kC[@]}" "${_xC[@]}")
input=("${circleLC[@]}" "${circleCC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が丸い文字か EFKXkx で 右が引き寄せる文字の場合 左が丸い文字 右に移動しない
backtrack=("${circleCC[@]}" "${_EC[@]}" "${_FC[@]}" "${_KC[@]}" "${_XC[@]}" "${_kC[@]}" "${_xC[@]}")
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

# 左が EFKTX で 右が引き寄せない大文字の場合 左が丸い文字 左に移動
backtrack=("${_EC[@]}" "${_FC[@]}" "${_KC[@]}" "${_TC[@]}" "${_XC[@]}")
input=("${circleLC[@]}" "${circleCC[@]}")
lookAhead=("${grvyCapitalLC[@]}" "${grvyCapitalRC[@]}" "${grvyCapitalWC[@]}" "${grvyCapitalEC[@]}" "${grvyCapitalMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が、右が丸い大文字か G の場合 左が丸い小文字 移動しない
backtrack=("${crclCapitalRL[@]}" "${crclCapitalCL[@]}" "${_GL[@]}")
input=("${crclSmallLC[@]}" "${crclSmallCC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 個別対応 ========================================

# J に関する例外処理 1 ----------------------------------------

# 左が大文字の場合 J 移動しない
backtrack=("${capitalAllR[@]}")
input=("${_JC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が大文字の場合 J 左に移動
backtrack=("${capitalAllL[@]}" \
"${capitalAllC[@]}")
input=("${_JC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が J の場合 引き寄せない大文字 移動しない
backtrack=("${_JL[@]}" \
"${_JC[@]}")
input=("${grvyCapitalFC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が J の場合 引き寄せない大文字 右に移動
backtrack=("${_JR[@]}")
input=("${grvyCapitalFC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# L に関する例外処理 ----------------------------------------

# 左が L の場合 Vの字 左に移動
backtrack=("${_LR[@]}")
input=("${gravityVC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が L の場合 全て 移動しない
backtrack=("${_LR[@]}")
input=("${capitalAllC[@]}" "${smallAllC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が L の場合 全て 左に移動
backtrack=("${_LL[@]}" \
"${_LC[@]}")
input=("${capitalAllC[@]}" "${smallAllC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右が全ての場合 L 右に移動
backtrack=("")
input=("${_LC[@]}")
lookAhead=("${capitalAllC[@]}" "${smallAllC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# c に関する例外処理 ----------------------------------------

# 左が c で 右が右寄りの小文字の場合 左寄り、幅広、均等、中間の文字 右に移動しない
backtrack=("${_cC[@]}")
input=("${grvySmallLC[@]}" "${grvySmallWC[@]}" "${grvySmallEC[@]}" "${grvySmallMC[@]}")
lookAhead=("${grvySmallRC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# f に関する例外処理 1 ----------------------------------------

# 左が引き寄せる文字で 右が、左が低い文字の場合 f 右に移動しない
backtrack=("${gravityCL[@]}" \
"${gravityCC[@]}")
input=("${_fC[@]}")
lookAhead=("${lowLC[@]}" "${lowCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# j に関する例外処理 ----------------------------------------

# 左が gpq の場合 j 左に移動しない
backtrack=("${_gR[@]}" "${_pR[@]}" "${_qR[@]}")
input=("${_jC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が全ての文字で 右が引き寄せる文字の場合 j 左に移動しない
backtrack=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}" "${gravityCR[@]}" \
"${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}" "${gravityCC[@]}")
input=("${_jC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が全ての文字の場合 j 左に移動
backtrack=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}" "${gravityCR[@]}" \
"${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}" "${gravityCC[@]}")
input=("${_jC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# rt に関する例外処理 1 ----------------------------------------

# 左が幅広の文字 右が引き離す文字の場合 rt 移動しない
backtrack=("${gravityWL[@]}")
input=("${_rC[@]}" "${_tC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が rt の場合 幅広な文字 左に移動しない
backtrack=("${_rL[@]}" "${_tL[@]}" \
"${_rC[@]}" "${_tC[@]}")
input=("${gravityWC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が rt の場合 左寄り、均等な文字 左に移動しない
backtrack=("${_rC[@]}" "${_tC[@]}")
input=("${gravityLC[@]}" "${gravityEC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が rt の場合 狭い文字以外 左に移動しない
backtrack=("${_rR[@]}" "${_tR[@]}")
input=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# y に関する例外処理 1 ----------------------------------------

# 左が、均等な大文字、左が低い文字、gpq の場合 y 左に移動しない
backtrack=("${grvyCapitalEL[@]}" "${lowLL[@]}" "${_gL[@]}" "${_pL[@]}" "${_qL[@]}")
input=("${_yC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が、均等な大文字、左が低い文字、gpq の場合 y 右に移動
backtrack=("${grvyCapitalER[@]}" "${lowLR[@]}" "${_gR[@]}" "${_pR[@]}" "${_qR[@]}" \
"${grvyCapitalEC[@]}" "${lowLC[@]}" "${_gC[@]}" "${_pC[@]}" "${_qC[@]}")
input=("${_yC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# x に関する例外処理 ----------------------------------------

# 左が、右が丸い小文字 右が幅広の文字の場合 x 左に移動
backtrack=("${crclSmallRR[@]}" "${crclSmallCR[@]}")
input=("${_xC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が、右が丸い小文字 右が引き離す文字の場合 x 左に移動
backtrack=("${crclSmallRC[@]}" "${crclSmallCC[@]}")
input=("${_xC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が x の場合 右が丸い小文字 移動しない
backtrack=("${_xC[@]}")
input=("${crclSmallRC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 大文字小文字 ========================================

# 大文字と小文字に関する例外処理 1 ----------------------------------------

# 左が、右下が開いている大文字 右が右寄り、中間、Vの字の場合 左が低い文字 左に移動しない (後の3つの処理とセット)
backtrack=("${spceCapitalRR[@]}" "${spceCapitalCR[@]}")
input=("${lowLC[@]}" "${lowCC[@]}")
lookAhead=("${gravityRC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が、右下が開いている大文字 右が狭い文字の場合 左が低い文字 左に移動しない
backtrack=("${spceCapitalRC[@]}" "${spceCapitalCC[@]}")
input=("${lowLC[@]}" "${lowCC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が PÞ で 左が低い文字 左に移動しない
backtrack=("${_PC[@]}" "${_THC[@]}")
input=("${lowLC[@]}" "${lowCC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が、右下が開いている大文字の場合 左が低い文字 左に移動
backtrack=("${spceCapitalRL[@]}" "${spceCapitalCL[@]}" \
"${spceCapitalRC[@]}" "${spceCapitalCC[@]}")
input=("${lowLC[@]}" "${lowCC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が、右下が開いている大文字 右が狭い文字の場合 左が低い文字 右に移動しない
backtrack=("${spceCapitalRR[@]}" "${spceCapitalCR[@]}")
input=("${lowLC[@]}" "${lowCC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左が小文字の場合 大文字 左に移動しない
backtrack=("${smallXL[@]}" \
"${smallXC[@]}")
input=("${capitalAllC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見て移動させない例外処理 2 ----------------------------------------

# 左が引き離す文字 右が幅広の文字の場合 引き寄せない文字 移動しない
backtrack=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
input=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 移動しない ========================================

# 左右を見て移動させない通常処理 ----------------------------------------

# 左右を見て 左寄りの文字 移動しない
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityCR[@]}" \
"${gravityVC[@]}")
input=("${gravityLC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見て 右寄りの文字 移動しない
backtrack=("${gravityVR[@]}" \
"${gravityLC[@]}" "${gravityMC[@]}")
input=("${gravityRC[@]}")
lookAhead=("${gravityRC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見て 均等な文字 移動しない
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityVC[@]}")
input=("${gravityEC[@]}")
lookAhead=("${gravityRC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見て 中間の文字 移動しない
backtrack=("${gravityVR[@]}" "${gravityCR[@]}" \
"${gravityLC[@]}" "${gravityMC[@]}")
input=("${gravityMC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左右を見て Vの字 移動しない
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityMR[@]}" \
"${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
input=("${gravityVC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityEC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左側基準で左に移動 ========================================

# 左右を見て左に移動させる通常処理 ----------------------------------------

# 左側基準で 左寄りの文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityML[@]}")
input=("${gravityLC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 右寄りの文字、均等な文字 左に移動
backtrack=("${gravityCR[@]}")
input=("${gravityRC[@]}" "${gravityEC[@]}")
lookAhead=("${gravityRC[@]}" "${gravityMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 右寄りの文字 左に移動
backtrack=("${gravityRL[@]}" "${gravityEL[@]}")
input=("${gravityRC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 幅広の文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityML[@]}" "${gravityVL[@]}")
input=("${gravityWC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 均等な文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityML[@]}")
input=("${gravityEC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 中間の文字 左に移動
backtrack=("${gravityRL[@]}" "${gravityEL[@]}")
input=("${gravityMC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で Vの字 左に移動
backtrack=("${gravityRL[@]}" "${gravityEL[@]}")
input=("${gravityVC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で Vの字 左に移動
backtrack=("${gravityCR[@]}")
input=("${gravityVC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 狭い文字 左に移動
backtrack=("${gravityWL[@]}")
input=("${gravityCC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左右を見て左に移動させない通常処理 ----------------------------------------

# 左側基準で 左寄りの文字 左に移動しない
backtrack=("${gravityVL[@]}" \
"${gravityCC[@]}")
input=("${gravityLC[@]}")
lookAhead=("${gravityVC[@]}" "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左側基準で 右寄りの文字 左に移動しない
backtrack=("${gravityLL[@]}" "${gravityML[@]}" \
"${gravityVC[@]}")
input=("${gravityRC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左側基準で 幅広の字 左に移動しない
backtrack=("${gravityCC[@]}")
input=("${gravityWC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左側基準で 均等な文字 左に移動しない
backtrack=("${gravityVL[@]}" \
"${gravityCC[@]}")
input=("${gravityEC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左側基準で 中間の文字 左に移動しない
backtrack=("${gravityLL[@]}" "${gravityML[@]}" \
"${gravityVC[@]}")
input=("${gravityMC[@]}")
lookAhead=("${gravityVC[@]}" "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左側基準で Vの字 左に移動しない
backtrack=("${gravityVL[@]}")
input=("${gravityVC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左側基準で 狭い文字 左に移動しない
backtrack=("${gravityCR[@]}" \
"${gravityLC[@]}" "${gravityMC[@]}" "${gravityVC[@]}" "${gravityCC[@]}")
input=("${gravityCC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左側基準で 狭い文字 左に移動しない
backtrack=("${gravityRC[@]}" "${gravityEC[@]}")
input=("${gravityCC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}" "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左を見て左に移動させる通常処理 ----------------------------------------

# 左側基準で 左寄りの文字、均等な文字 左に移動
backtrack=("${gravityVL[@]}" "${gravityCL[@]}" \
"${gravityCC[@]}")
input=("${gravityLC[@]}" "${gravityEC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 右寄りの文字、中間の文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityML[@]}" "${gravityVL[@]}" "${gravityCL[@]}" \
"${gravityVC[@]}" "${gravityCC[@]}")
input=("${gravityRC[@]}" "${gravityMC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 幅広な文字 左に移動
backtrack=("${gravityCL[@]}" \
"${gravityCC[@]}")
input=("${gravityWC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で Vの字 左に移動
backtrack=("${gravityLL[@]}" "${gravityML[@]}" "${gravityVL[@]}" "${gravityCL[@]}" \
"${gravityCC[@]}")
input=("${gravityVC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 狭い文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}" "${gravityVL[@]}" "${gravityCL[@]}" \
"${gravityCR[@]}" \
"${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}" "${gravityCC[@]}")
input=("${gravityCC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で右に移動 ========================================

# 左右を見て右に移動させる通常処理 ----------------------------------------

# 左側基準で 中間の文字 右に移動
backtrack=("${gravityRC[@]}" "${gravityEC[@]}")
input=("${gravityMC[@]}")
lookAhead=("${gravityRC[@]}" "${gravityMC[@]}" "${gravityVC[@]}"  "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左側基準で 狭い字 右に移動
backtrack=("${gravityWC[@]}")
input=("${gravityCC[@]}")
lookAhead=("${gravityRC[@]}" "${gravityMC[@]}" "${gravityVC[@]}"  "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左右を見て右に移動させない通常処理 ----------------------------------------

# 左側基準で 左寄りの文字 右に移動しない
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityLC[@]}" "${gravityMC[@]}")
input=("${gravityLC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左側基準で 右寄りの文字 右に移動しない
backtrack=("${gravityLR[@]}" "${gravityMR[@]}")
input=("${gravityRC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左側基準で 右寄りの文字 右に移動しない
backtrack=("${gravityWL[@]}" \
"${gravityRR[@]}" "${gravityER[@]}" \
"${gravityRC[@]}" "${gravityEC[@]}")
input=("${gravityRC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左側基準で 幅広な文字 右に移動しない
backtrack=("${gravityWL[@]}")
input=("${gravityWC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左側基準で 幅広な文字 右に移動しない
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityLC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
input=("${gravityWC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左側基準で 均等の文字 右に移動しない
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityLC[@]}" "${gravityMC[@]}")
input=("${gravityEC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左側基準で 中間の文字 右に移動しない
backtrack=("${gravityWL[@]}" \
"${gravityRR[@]}" "${gravityER[@]}" \
"${gravityRC[@]}" "${gravityEC[@]}")
input=("${gravityMC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左側基準で Vの字 右に移動しない
backtrack=("${gravityRR[@]}" "${gravityER[@]}" "${gravityVR[@]}")
input=("${gravityVC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左側基準で 狭い文字 右に移動しない
backtrack=("${gravityWR[@]}")
input=("${gravityCC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 左を見て右に移動させる通常処理 ----------------------------------------

# 左側基準で 左寄りの文字 右に移動
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
input=("${gravityLC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左側基準で 右寄りの文字 右に移動
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" \
"${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
input=("${gravityRC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左側基準で 幅広な文字 右に移動
backtrack=("${gravityRL[@]}" "${gravityWL[@]}" "${gravityEL[@]}" \
"${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
input=("${gravityWC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左側基準で 均等な文字 右に移動
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
input=("${gravityEC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左側基準で 中間の文字 右に移動
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" \
"${gravityWC[@]}")
input=("${gravityMC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左側基準で Vの字 右に移動
backtrack=("${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityVR[@]}" \
"${gravityWC[@]}")
input=("${gravityVC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左側基準で 狭い文字 右に移動
backtrack=("${gravityWR[@]}")
input=("${gravityCC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が丸い文字に関する例外処理 2 ----------------------------------------

# 左が、右寄りか均等な文字の場合 左が丸い文字 右に移動
backtrack=("${gravityRC[@]}" "${gravityEC[@]}")
input=("${circleLC[@]}" "${circleCC[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 個別対応 ========================================

# A に関する例外処理 5 ----------------------------------------

# 右が、右下が開いている大文字か W の場合 A 右に移動
backtrack=("")
input=("${_AC[@]}")
lookAhead=("${spceCapitalRC[@]}" "${spceCapitalCC[@]}" "${_WC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右が A の場合 右下が開いている大文字か W 右に移動
backtrack=("")
input=("${spceCapitalRC[@]}" "${spceCapitalCC[@]}" "${_WC[@]}")
lookAhead=("${_AC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# J に関する例外処理 2 ----------------------------------------

# 右が引き寄せない大文字の場合 J 左に移動
backtrack=("")
input=("${_JC[@]}")
lookAhead=("${grvyCapitalFC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右が J の場合 大文字 右に移動
backtrack=("")
input=("${capitalAllC[@]}")
lookAhead=("${_JC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# f に関する例外処理 2 ----------------------------------------

# 右が、左が低い文字の場合 f 右に移動
backtrack=("")
input=("${_fC[@]}")
lookAhead=("${lowLC[@]}" "${lowCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# rt に関する例外処理 2 ----------------------------------------

# 右が幅広の文字の場合 rt 左に移動
backtrack=("")
input=("${_rC[@]}" "${_tC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右が引き寄せない文字の場合 rt 右に移動しない
backtrack=("")
input=("${_rC[@]}" "${_tC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# y に関する例外処理 2 ----------------------------------------

# 右が y の場合 p 右に移動しない
backtrack=("")
input=("${_pC[@]}")
lookAhead=("${_yC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 大文字小文字 ========================================

# 大文字と小文字に関する例外処理 2 ----------------------------------------

# 右が、左が低い文字の場合 PÞ 右に移動しない
backtrack=("")
input=("${_PC[@]}" "${_THC[@]}")
lookAhead=("${lowLC[@]}" "${lowCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右が、左が低い文字の場合 右下が開いている大文字 右に移動
backtrack=("")
input=("${spceCapitalRC[@]}" "${spceCapitalCC[@]}")
lookAhead=("${lowLC[@]}" "${lowCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右が大文字の場合 小文字 右に移動しない
backtrack=("")
input=("${smallAllC[@]}")
lookAhead=("${capitalAllC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右側基準で左に移動 ========================================

# 左右を見て左に移動させる通常処理 ----------------------------------------

# 右側基準で 狭い文字 左に移動
backtrack=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}")
input=("${gravityCC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左右を見て左に移動させない通常処理 ----------------------------------------

# 右側基準で 左寄りの文字 左に移動しない
backtrack=("${gravityVC[@]}")
input=("${gravityLC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右側基準で 右寄りの文字 左に移動しない
backtrack=("${gravityVR[@]}" \
"${gravityLC[@]}" "${gravityMC[@]}")
input=("${gravityRC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右側基準で 幅広の文字 左に移動しない
backtrack=("${gravityLL[@]}" "${gravityML[@]}" "${gravityVL[@]}")
input=("${gravityWC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右側基準で 均等な文字 左に移動しない
backtrack=("${gravityVC[@]}")
input=("${gravityEC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右側基準で 中間の文字 左に移動しない
backtrack=("${gravityVR[@]}" \
"${gravityLC[@]}" "${gravityMC[@]}")
input=("${gravityMC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右側基準で Vの字 左に移動しない
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
input=("${crclCapitalRC[@]}" "${crclCapitalCC[@]}" "${_GC[@]}")
lookAhead=("${circleLC[@]}" "${circleCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右を見て左に移動させる通常処理 ----------------------------------------

# 右側基準で 左寄りの文字、中間の文字、Vの字 左に移動
backtrack=("")
input=("${gravityLC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
lookAhead=("${gravityWC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右側基準で 右寄りの文字、均等な文字 左に移動
backtrack=("")
input=("${gravityRC[@]}" "${gravityEC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityWC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右側基準で 幅広の文字 左に移動
backtrack=("")
input=("${gravityWC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityRC[@]}" "${gravityWC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右側基準で右に移動 ========================================

# 左右を見て右に移動させない通常処理 ----------------------------------------

# 右側基準で 左寄りの文字 右に移動しない
backtrack=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}" \
"${gravityCR[@]}" \
"${gravityVC[@]}")
input=("${gravityLC[@]}")
lookAhead=("${gravityVC[@]}" "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右側基準で 右寄りの文字 右に移動しない
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityVR[@]}" "${gravityCR[@]}")
input=("${gravityRC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右側基準で 幅広な文字 右に移動しない
backtrack=("${gravityLL[@]}" "${gravityML[@]}" "${gravityVL[@]}")
input=("${gravityWC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右側基準で 均等な文字 右に移動しない
backtrack=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}" \
"${gravityCR[@]}" \
"${gravityVC[@]}")
input=("${gravityEC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右側基準で 中間の文字 右に移動しない
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityVR[@]}" "${gravityCR[@]}")
input=("${gravityMC[@]}")
lookAhead=("${gravityVC[@]}" "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右側基準で Vの字 右に移動しない
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityLR[@]}" "${gravityMR[@]}" "${gravityCR[@]}" \
"${gravityLC[@]}" "${gravityRC[@]}" "${gravityEC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
input=("${gravityVC[@]}")
lookAhead=("${gravityRC[@]}" "${gravityMC[@]}" "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右側基準で 狭い字 右に移動しない
backtrack=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityWC[@]}")
input=("${gravityCC[@]}")
lookAhead=("${gravityLC[@]}" "${gravityEC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右側基準で 狭い字 右に移動しない
backtrack=("${gravityLR[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityWC[@]}")
input=("${gravityCC[@]}")
lookAhead=("${gravityRC[@]}" "${gravityMC[@]}" "${gravityVC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右側基準で 狭い字 右に移動しない
backtrack=("${gravityLR[@]}" "${gravityMR[@]}" \
"${gravityWC[@]}")
input=("${gravityCC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexC}"
index=`expr ${index} + 1`

# 右を見て右に移動させる通常処理 ----------------------------------------

# 右側基準で 左寄りの文字、中間の文字 右に移動
backtrack=("")
input=("${gravityLC[@]}" "${gravityMC[@]}")
lookAhead=("${gravityVC[@]}" "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右側基準で 右寄りの文字、幅広な文字、均等な文字 右に移動
backtrack=("")
input=("${gravityRC[@]}" "${gravityEC[@]}")
lookAhead=("${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# Vの字 右に移動
backtrack=("")
input=("${gravityVC[@]}")
lookAhead=("${gravityRC[@]}" "${gravityMC[@]}" "${gravityCC[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右側基準で 狭い文字 右に移動
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
