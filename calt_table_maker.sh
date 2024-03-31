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
lookupIndex_calt="18" # caltテーブルのlookupナンバー
num_calt_lookups="20" # calt のルックアップ数
lookupIndex_replace=`expr ${lookupIndex_calt} + ${num_calt_lookups}` # 単純置換のlookupナンバー
lookupIndexUD=`expr ${lookupIndex_replace}` # 変換先(上下に移動させた記号のグリフ)
lookupIndexRR=`expr ${lookupIndexUD} + 1` # 変換先(右に移動させた記号のグリフ)
lookupIndexLL=`expr ${lookupIndexRR} + 1` # 変換先(左に移動させた記号のグリフ)
lookupIndex0=`expr ${lookupIndexLL} + 1` # 変換先(小数のグリフ)
lookupIndex2=`expr ${lookupIndex0} + 1` # 変換先(12桁マークを付けたグリフ)
lookupIndex4=`expr ${lookupIndex2} + 1` # 変換先(4桁マークを付けたグリフ)
lookupIndex3=`expr ${lookupIndex4} + 1` # 変換先(3桁マークを付けたグリフ)
lookupIndexR=`expr ${lookupIndex3} + 1` # 変換先(右に移動させたグリフ)
lookupIndexL=`expr ${lookupIndexR} + 1` # 変換先(左に移動させたグリフ)
lookupIndexN=`expr ${lookupIndexL} + 1` # 変換先(ノーマルなグリフに戻す)

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
  echo `grep " ${1} " "${dict}.txt" | head -n 1 | cut -d ' ' -f 1,3`
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

# backtrack --------------------

  if [ -n "${backtrack}" ]; then # 入力した文字の左側
    rm -f ${listTemp}.txt
    for S in ${backtrack[@]}; do
      glyph_name "${S}" >> "${listTemp}.txt" # 略号から通し番号とグリフ名を取得
    done
    {
      echo "<BacktrackCoverage index=\"0\">"
      sort -n -u "${listTemp}.txt" | cut -d ' ' -f 2 | sed -E 's/([0-9a-zA-z]+)/<Glyph value="\1"\/>/g' # ソートしないとttxにしかられる
      echo "</BacktrackCoverage>"
    } >> "${caltList}.txt"
  fi

  if [ -n "${backtrack1}" ]; then # 入力した文字の左側2つ目
    rm -f ${listTemp}.txt
    for S in ${backtrack1[@]}; do
      glyph_name "${S}" >> "${listTemp}.txt" # 略号から通し番号とグリフ名を取得
    done
    {
      echo "<BacktrackCoverage index=\"0\">"
      sort -n -u "${listTemp}.txt" | cut -d ' ' -f 2 | sed -E 's/([0-9a-zA-z]+)/<Glyph value="\1"\/>/g' # ソートしないとttxにしかられる
      echo "</BacktrackCoverage>"
    } >> "${caltList}.txt"
  fi

# input --------------------

  rm -f ${listTemp}.txt
  for S in ${input[@]}; do
    T=`printf '%s\n' "${fixedGlyphN[@]}" | grep -x "${S}"` # (コレと) 移動 (置換) しない文字を除く
    if [ -z "${T}" ]; then # (コレと) 有効にするとデータ量が減るはずだが、何故か Overfrow エラーが出やすくなる場合がある
      glyph_name "${S}" >> "${listTemp}.txt" # 略号から通し番号とグリフ名を取得
    fi # (コレの3行)
  done
  {
    echo "<InputCoverage index=\"0\">" # 入力した文字(グリフ変換対象)
    sort -n -u "${listTemp}.txt" | cut -d ' ' -f 2 | sed -E 's/([0-9a-zA-z]+)/<Glyph value="\1"\/>/g'
    echo "</InputCoverage>"
  } >> "${caltList}.txt"

# lookAhead --------------------

  if [ -n "${lookAhead}" ]; then # 入力した文字の右側
    rm -f ${listTemp}.txt
    for S in ${lookAhead[@]}; do
      glyph_name "${S}" >> "${listTemp}.txt" # 略号から通し番号とグリフ名を取得
    done
    {
      echo "<LookAheadCoverage index=\"0\">"
      sort -n -u "${listTemp}.txt" | cut -d ' ' -f 2 | sed -E 's/([0-9a-zA-z]+)/<Glyph value="\1"\/>/g'
      echo "</LookAheadCoverage>"
    } >> "${caltList}.txt"
  fi

  if [ -n "${lookAhead1}" ]; then # 入力した文字の右側2つ目
    rm -f ${listTemp}.txt
    for S in ${lookAhead1[@]}; do
      glyph_name "${S}" >> "${listTemp}.txt" # 略号から通し番号とグリフ名を取得
    done
    {
      echo "<LookAheadCoverage index=\"0\">"
      sort -n -u "${listTemp}.txt" | cut -d ' ' -f 2 | sed -E 's/([0-9a-zA-z]+)/<Glyph value="\1"\/>/g'
      echo "</LookAheadCoverage>"
    } >> "${caltList}.txt"
  fi

  if [ -n "${lookAheadX}" ]; then # 入力した文字の右側3つ目以降
    for i in `seq 2 "${aheadMax}"`; do
      rm -f ${listTemp}.txt
      for S in ${lookAheadX[@]}; do
        glyph_name "${S}" >> "${listTemp}.txt" # 略号から通し番号とグリフ名を取得
      done
      {
        echo "<LookAheadCoverage index=\"0\">"
        sort -n -u "${listTemp}.txt" | cut -d ' ' -f 2 | sed -E 's/([0-9a-zA-z]+)/<Glyph value="\1"\/>/g'
        echo "</LookAheadCoverage>"
      } >> "${caltList}.txt"
    done
  fi

  {
    echo "<SubstLookupRecord index=\"0\">"
    echo "<SequenceIndex value=\"0\"/>"
    echo "<LookupListIndex value=\"${lookupIndex}\"/>"
    echo "</SubstLookupRecord>"

    echo "</ChainContextSubst>"
  } >> "${caltList}.txt" # 条件がそろった時にジャンプするテーブル番号
}

# グリフ名変換用辞書作成 (グリフのIDS順に並べること) ||||||||||||||||||||||||||||||||||||||||

# 略号と名前 ----------------------------------------

quotedbl=("QTD") # 直接扱えない記号
quotedbl_name=("quotedbl")
asterisk=("AST")
asterisk_name=("asterisk")
hyphen=("HYP")
hyphen_name=("hyphen")
fullStop=("DOT")
fullStop_name=("period")
solidus=("SLH")
solidus_name=("slash")
symbol2x=("!" "${quotedbl}" "#" "$" "%" "&" "'" \
"(" ")" "${asterisk}" "+" "," "${hyphen}" "${fullStop}" "${solidus}")
symbol2x_name=("exclam" "${quotedbl_name}" "numbersign" "dollar" "percent" "ampersand" "quotesingle" \
"parenleft" "parenright" "${asterisk_name}" "plus" "comma" "${hyphen_name}" "${fullStop_name}" "${solidus_name}")

figure=(0 1 2 3 4 5 6 7 8 9)
figure_name=("zero" "one" "two" "three" "four" "five" "six" "seven" "eight" "nine")

colon=(":") # 単独で変数を使用するため他と分けて代入
colon_name=("colon")
less=("LES")
less_name=("less")
greater=("GRT")
greater_name=("greater")
symbol3x=("${colon}" ";" "${less}" "=" "${greater}" "?")
symbol3x_name=("${colon_name}" "semicolon" "${less_name}" "equal" "${greater_name}" "question")

symbol4x=("@")
symbol4x_name=("at")

# グリフ略号 (A B..y z, AL BL..yL zL, AR BR..yR zR 通常のグリフ、左に移動したグリフ、右に移動したグリフ)
# グリフ名 (A B..y z, glyphXXXXX..glyphYYYYY)
latin45=(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) # 略号の始めの文字
latin45_name=("${latin45[@]}")

rSolidus=("BSH") # 単独で変数を使用するため他と分けて代入
rSolidus_name=("backslash")
bracketLeft=("LBK")
bracketLeft_name=("bracketleft")
bracketRight=("RBK")
bracketRight_name=("bracketright")
grave=("GRV")
grave_name=("grave")
symbol5x=("${bracketLeft}" "${rSolidus}" "${bracketRight}" "^" "_" "${grave}")
symbol5x_name=("${bracketLeft_name}" "${rSolidus_name}" "${bracketRight_name}" "asciicircum" "underscore" "${grave_name}")

latin67=(a b c d e f g h i j k l m n o p q r s t u v w x y z) # 略号の始めの文字
latin67_name=("${latin67[@]}")

bar=("BAR") # 単独で変数を使用するため他と分けて代入
bar_name=("bar")
tilde=("TLD")
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

word=("${bar}" "${tilde}") # | ~

for S in ${word[@]}; do
  echo "$i ${S}D glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

# 上に移動した記号 ----------------------------------------

word=("${colon}") # :

for S in ${word[@]}; do
  echo "$i ${S}U glyph${i}" >> "${dict}.txt"
  i=`expr ${i} + 1`
done

# 略号のグループ作成 ||||||||||||||||||||||||||||||||||||||||

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
 #  S="_ss"; class+=("${S}"); eval ${S}=\(ß\) # ß
  S="_kg"; class+=("${S}"); eval ${S}=\(ĸ\) # ĸ
else
  S="_A"; class+=("${S}"); eval ${S}=\(A À Á Â Ã Ä Å Ā Ă Ą\) # A
  S="_B"; class+=("${S}"); eval ${S}=\(B ẞ ß\) # B ẞ ß
 #  S="_B"; class+=("${S}"); eval ${S}=\(B ẞ\) # B ẞ
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
 #  S="_ss"; class+=("${S}"); eval ${S}=\(ß\) # ß
  S="_kg"; class+=("${S}"); eval ${S}=\(ĸ\) # ĸ
fi

# 基本 --------------------

# 各グリフの重心、形状の違いから、左寄り、右寄り、中央寄り、中央寄りと均等の中間、均等、幅広、Vの字形に分類する

gCL=("_B" "_D" "_E" "_F" "_K" "_L" "_P" "_R" "_TH")
gSL=("_b" "_h" "_k" "_p" "_th" "_kg")
 #gSL=("_b" "_h" "_k" "_p" "_th" "_ss" "_kg")
S="gravityCapitalL"; class+=("${S}"); eval ${S}=\(`letter_members "${gCL[*]}"`\) # 左寄りの大文字
S="gravitySmallL";   class+=("${S}"); eval ${S}=\(`letter_members "${gSL[*]}"`\) # 左寄りの小文字

gCR=("_C" "_G")
gSR=("_a" "_c" "_d" "_g" "_q")
S="gravityCapitalR"; class+=("${S}"); eval ${S}=\(`letter_members "${gCR[*]}"`\) # 右寄りの大文字
S="gravitySmallR";   class+=("${S}"); eval ${S}=\(`letter_members "${gSR[*]}"`\) # 右寄りの小文字

gCW=("_M" "_W" "_AE" "_OE")
gSW=("_m" "_w" "_ae" "_oe")
S="gravityCapitalW"; class+=("${S}"); eval ${S}=\(`letter_members "${gCW[*]}"`\) # 幅広の大文字
S="gravitySmallW";   class+=("${S}"); eval ${S}=\(`letter_members "${gSW[*]}"`\) # 幅広の小文字

gCE=("_H" "_N" "_O" "_Q" "_U")
gSE=("_n" "_u")
S="gravityCapitalE"; class+=("${S}"); eval ${S}=\(`letter_members "${gCE[*]}"`\) # 均等な大文字
S="gravitySmallE";   class+=("${S}"); eval ${S}=\(`letter_members "${gSE[*]}"`\) # 均等な小文字

gCM=("_A" "_S" "_X" "_Z")
gSM=("_e" "_o" "_s" "_x" "_z")
S="gravityCapitalM"; class+=("${S}"); eval ${S}=\(`letter_members "${gCM[*]}"`\) # 中間の大文字
S="gravitySmallM";   class+=("${S}"); eval ${S}=\(`letter_members "${gSM[*]}"`\) # 中間の小文字

gCV=("_T" "_V" "_Y")
gSV=("_v" "_y")
S="gravityCapitalV"; class+=("${S}"); eval ${S}=\(`letter_members "${gCV[*]}"`\) # Vの字の大文字
S="gravitySmallV";   class+=("${S}"); eval ${S}=\(`letter_members "${gSV[*]}"`\) # vの字の小文字

gCC=("_I" "_J")
gSC=("_f" "_i" "_j" "_l" "_r" "_t")
S="gravityCapitalC"; class+=("${S}"); eval ${S}=\(`letter_members "${gCC[*]}"`\) # 狭い大文字
S="gravitySmallC";   class+=("${S}"); eval ${S}=\(`letter_members "${gSC[*]}"`\) # 狭い小文字

S="gravityL"; class+=("${S}"); eval ${S}=\("${gravityCapitalL[@]}" "${gravitySmallL[@]}"\) # 左寄り
S="gravityR"; class+=("${S}"); eval ${S}=\("${gravityCapitalR[@]}" "${gravitySmallR[@]}"\) # 右寄り
S="gravityW"; class+=("${S}"); eval ${S}=\("${gravityCapitalW[@]}" "${gravitySmallW[@]}"\) # 幅広
S="gravityE"; class+=("${S}"); eval ${S}=\("${gravityCapitalE[@]}" "${gravitySmallE[@]}"\) # 均等
S="gravityM"; class+=("${S}"); eval ${S}=\("${gravityCapitalM[@]}" "${gravitySmallM[@]}"\) # 中間
S="gravityV"; class+=("${S}"); eval ${S}=\("${gravityCapitalV[@]}" "${gravitySmallV[@]}"\) # Vの字
S="gravityC"; class+=("${S}"); eval ${S}=\("${gravityCapitalC[@]}" "${gravitySmallC[@]}"\) # 狭い

# 丸い文字 --------------------

cCC=("_O" "_Q")
cSC=("_e" "_o")
S="circleCapitalC"; class+=("${S}"); eval ${S}=\(`letter_members "${cCC[*]}"`\) # 丸い大文字
S="circleSmallC";   class+=("${S}"); eval ${S}=\(`letter_members "${cSC[*]}"`\) # 丸い小文字

cCL=("_C" "_G")
cSL=("_c" "_d" "_g" "_q")
S="circleCapitalL"; class+=("${S}"); eval ${S}=\(`letter_members "${cCL[*]}"`\) # 左が丸い大文字
S="circleSmallL";   class+=("${S}"); eval ${S}=\(`letter_members "${cSL[*]}"`\) # 左が丸い小文字

cCR=("_B" "_D")
cSR=("_b" "_p" "_th")
 #cSR=("_b" "_p" "_th" "_ss")
S="circleCapitalR"; class+=("${S}"); eval ${S}=\(`letter_members "${cCR[*]}"`\) # 右が丸い大文字
S="circleSmallR";   class+=("${S}"); eval ${S}=\(`letter_members "${cSR[*]}"`\) # 右が丸い小文字

S="circleC"; class+=("${S}"); eval ${S}=\("${circleCapitalC[@]}" "${circleSmallC[@]}"\) # 丸い文字
S="circleL"; class+=("${S}"); eval ${S}=\("${circleCapitalL[@]}" "${circleSmallL[@]}"\) # 左が丸い文字
S="circleR"; class+=("${S}"); eval ${S}=\("${circleCapitalR[@]}" "${circleSmallR[@]}"\) # 右が丸い文字

# 上が開いている文字 --------------------

hCC=("")
 #hCC=("_A")
hSC=("_a" "_c" "_e" "_g" "_n" "_o" "_p" "_q" "_s" "_u" "_v" "_x" "_y" "_z" "_kg")
 #hSC=("_a" "_c" "_e" "_g" "_i" "_j" "_m" "_n" "_o" "_p" "_q" "_r" "_s" "_u" "_v" "_w" "_x" "_y" "_z" "_kg")
S="highSpaceCapitalC"; class+=("${S}"); eval ${S}=\(`letter_members "${hCC[*]}"`\) # 両上が開いている大文字
S="highSpaceSmallC";   class+=("${S}"); eval ${S}=\(`letter_members "${hSC[*]}"`\) # 両上が開いている小文字 (幅広、狭いを除く)

hCL=("")
 #hCL=("_J")
hSL=("_d")
S="highSpaceCapitalL"; class+=("${S}"); eval ${S}=\(`letter_members "${hCL[*]}"`\) # 左上が開いている大文字
S="highSpaceSmallL";   class+=("${S}"); eval ${S}=\(`letter_members "${hSL[*]}"`\) # 左上が開いている小文字

hSR=("")
 #hSR=("_L")
hSR=("_b" "_h" "_k" "_th")
S="highSpaceCapitalR"; class+=("${S}"); eval ${S}=\(`letter_members "${hSR[*]}"`\) # 右上が開いている大文字
S="highSpaceSmallR";   class+=("${S}"); eval ${S}=\(`letter_members "${hSR[*]}"`\) # 右上が開いている小文字

S="highSpaceC"; class+=("${S}"); eval ${S}=\("${highSpaceCapitalC[@]}" "${highSpaceSmallC[@]}"\) # 両上が開いている文字
S="highSpaceL"; class+=("${S}"); eval ${S}=\("${highSpaceCapitalL[@]}" "${highSpaceSmallL[@]}"\) # 左上が開いている文字
S="highSpaceR"; class+=("${S}"); eval ${S}=\("${highSpaceCapitalR[@]}" "${highSpaceSmallR[@]}"\) # 右上が開いている文字

# 中が開いている文字 --------------------

mCC=("_A" "_I" "_S" "_T" "_V" "_X" "_Y" "_Z")
mSC=("_i" "_l" "_x")
S="midSpaceCapitalC"; class+=("${S}"); eval ${S}=\(`letter_members "${mCC[*]}"`\) # 両側が開いている大文字
S="midSpaceSmallC";   class+=("${S}"); eval ${S}=\(`letter_members "${mSC[*]}"`\) # 両側が開いている小文字

mCL=("_J")
mSL=("_j")
S="midSpaceCapitalL"; class+=("${S}"); eval ${S}=\(`letter_members "${mCL[*]}"`\) # 左側が開いている大文字
S="midSpaceSmallL";   class+=("${S}"); eval ${S}=\(`letter_members "${mSL[*]}"`\) # 左側が開いている小文字

mCR=("_E" "_F" "_K" "_L" "_P" "_R")
mSR=("_f" "_k" "_r")
S="midSpaceCapitalR"; class+=("${S}"); eval ${S}=\(`letter_members "${mCR[*]}"`\) # 右側が開いている大文字
S="midSpaceSmallR";   class+=("${S}"); eval ${S}=\(`letter_members "${mSR[*]}"`\) # 右側が開いている小文字

S="midSpaceC"; class+=("${S}"); eval ${S}=\("${midSpaceCapitalC[@]}" "${midSpaceSmallC[@]}"\) # 両側が開いている文字
S="midSpaceL"; class+=("${S}"); eval ${S}=\("${midSpaceCapitalL[@]}" "${midSpaceSmallL[@]}"\) # 左側が開いている文字
S="midSpaceR"; class+=("${S}"); eval ${S}=\("${midSpaceCapitalR[@]}" "${midSpaceSmallR[@]}"\) # 右側が開いている文字

# 下が開いている文字 --------------------

lCC=("_T" "_V" "_Y")
 #lCC=("_I" "_T" "_V" "_Y")
lSC=("_f" "_i" "_l" "_v")
S="lowSpaceCapitalC"; class+=("${S}"); eval ${S}=\(`letter_members "${lCC[*]}"`\) # 両下が開いている大文字
S="lowSpaceSmallC";   class+=("${S}"); eval ${S}=\(`letter_members "${lSC[*]}"`\) # 両下が開いている小文字

lCL=("")
lSL=("_t")
S="lowSpaceCapitalL"; class+=("${S}"); eval ${S}=\(`letter_members "${lCL[*]}"`\) # 左下が開いている大文字
S="lowSpaceSmallL";   class+=("${S}"); eval ${S}=\(`letter_members "${lSL[*]}"`\) # 左下が開いている小文字

lCR=("_F" "_J" "_P" "_TH")
lSR=("_j" "_r" "_y")
S="lowSpaceCapitalR"; class+=("${S}"); eval ${S}=\(`letter_members "${lCR[*]}"`\) # 右下が開いている大文字
S="lowSpaceSmallR";   class+=("${S}"); eval ${S}=\(`letter_members "${lSR[*]}"`\) # 右下が開いている小文字

S="lowSpaceC"; class+=("${S}"); eval ${S}=\("${lowSpaceCapitalC[@]}" "${lowSpaceSmallC[@]}"\) # 両下が開いている文字
S="lowSpaceL"; class+=("${S}"); eval ${S}=\("${lowSpaceCapitalL[@]}" "${lowSpaceSmallL[@]}"\) # 左下が開いている文字
S="lowSpaceR"; class+=("${S}"); eval ${S}=\("${lowSpaceCapitalR[@]}" "${lowSpaceSmallR[@]}"\) # 右下が開いている文字

# 全て --------------------

S="capital"; class+=("${S}")
eval ${S}=\("${gravityCapitalL[@]}" "${gravityCapitalR[@]}" "${gravityCapitalW[@]}" "${gravityCapitalE[@]}"\)
eval ${S}+=\("${gravityCapitalM[@]}" "${gravityCapitalV[@]}" "${gravityCapitalC[@]}"\) # 全ての大文字
S="small"; class+=("${S}")
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
S="hyphen"; class+=("${S}"); eval ${S}=\("${hyphen}"\) # -
S="solidus"; class+=("${S}"); eval ${S}=\("${solidus}"\) # solidus
S="less"; class+=("${S}"); eval ${S}=\("${less}"\) # <
S="greater"; class+=("${S}"); eval ${S}=\("${greater}"\) # >
S="rSolidus"; class+=("${S}"); eval ${S}=\("${rSolidus}"\) # reverse solidus

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
S="bar"; class+=("${S}"); eval ${S}=\("${bar}"\) # |
S="tilde"; class+=("${S}"); eval ${S}=\("${tilde}"\) # ~

for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
  for T in ${member[@]}; do
    eval "${S}N+=(\"${T}\")"
    eval "${S}D+=(\"${T}D\")"
  done
done

# 記号の略号生成 (N: 通常、U: 上移動後) --------------------

class=("")
S="colon"; class+=("${S}"); eval ${S}=\("${colon}"\) # :

for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
  for T in ${member[@]}; do
    eval "${S}N+=(\"${T}\")"
    eval "${S}U+=(\"${T}U\")"
  done
done

# 通常のみ --------------------

symbolEN=("#" "$" "%" "&" "@") # 幅のある記号
figureEN=(0 2 3 4 5 6 7 8 9) # 幅のある数字
figureCN=(1) # 幅の狭い数字
operatorHN=("${asterisk}" "+" "${hyphen}" "=") # 記号が上下に移動する記号
fxG=("_AE" "_OE" "_ae" "_oe") # 移動 (置換) しないグリフ (input[@]から除去)
fixedGlyphN=(`letter_members "${fxG[*]}"`)

# カーニング設定作成 ||||||||||||||||||||||||||||||||||||||||

echo "Make GSUB calt List"

{
  echo "<LookupType value=\"6\"/>"
  echo "<LookupFlag value=\"0\"/>"
} >> "${caltList}.txt"
index="0"

# アルファベット ||||||||||||||||||||||||||||||||||||||||

# 数字と記号に関する処理 ----------------------------------------

# 左が幅のある記号、数字で 右が引き寄せない文字の場合 引き寄せない文字 左に移動しない
backtrack=("${symbolEN[@]}" "${figureEN[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

if [ "${symbol_only_flag}" = "false" ]; then
# もろもろ例外 ========================================

# 同じ文字を等間隔にさせる例外処理 1 ----------------------------------------

# 左が丸い文字、EF
class=("${cCL[@]}" "${cSL[@]}" "_E" "_F")
for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
  # 動かない
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

# 左が W で 右が 左寄り、幅広の文字の場合 A 左に移動
backtrack=("${_WN[@]}")
input=("${_AN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が W で 右が、左下が開いている大文字か I の場合 A 右に移動 (次の処理とセット)
backtrack=("${_WR[@]}")
input=("${_AN[@]}")
lookAhead=("${lowSpaceCapitalCN[@]}" "${_IN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が W の場合 A 移動しない
backtrack=("${_WR[@]}")
input=("${_AN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# A に関する例外処理 2 ----------------------------------------

# 左が、右下が開いている大文字で 右が、左下が開いている大文字の場合 A 移動しない (次の処理とセット)
backtrack=("${lowSpaceCapitalRR[@]}" "${lowSpaceCapitalCR[@]}")
input=("${_AN[@]}")
lookAhead=("${lowSpaceCapitalCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が、右下が開いている大文字か IW の場合 A 左に移動
backtrack=("${lowSpaceCapitalRL[@]}" "${lowSpaceCapitalCL[@]}" "${_WL[@]}" \
"${lowSpaceCapitalRR[@]}" "${lowSpaceCapitalCR[@]}" "${_IR[@]}" \
"${lowSpaceCapitalRN[@]}" "${lowSpaceCapitalCN[@]}")
input=("${_AN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# A に関する例外処理 3 ----------------------------------------

# 左が A の場合 W 左に移動しない (次の処理とセット)
backtrack=("${_AR[@]}")
input=("${_WN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が A の場合 左下が開いている大文字 W 左に移動
backtrack=("${_AL[@]}" \
"${_AR[@]}" \
"${_AN[@]}")
input=("${lowSpaceCapitalCN[@]}" "${_WN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# A に関する例外処理 4 ----------------------------------------

# 左が左寄り、右寄り、均等、中間の大文字で 右が W の場合 A 右に移動しない
backtrack=("${gravityCapitalLL[@]}" "${gravityCapitalRL[@]}" "${gravityCapitalEL[@]}" "${gravityCapitalML[@]}")
input=("${_AN[@]}")
lookAhead=("${_WN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が幅広以外の大文字で 右が A の場合 右下が開いている大文字 W 右に移動しない
backtrack=("${gravityCapitalLL[@]}" "${gravityCapitalRL[@]}" "${gravityCapitalEL[@]}" "${gravityCapitalML[@]}" "${gravityCapitalVL[@]}" \
"${gravityCapitalVN[@]}" "${gravityCapitalCN[@]}")
input=("${lowSpaceCapitalRN[@]}" "${lowSpaceCapitalCN[@]}" "${_WN[@]}")
lookAhead=("${_AN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# I に関する例外処理 ----------------------------------------

# 左が中間の大文字で 右がVの大文字の場合 I 左に移動しない
backtrack=("${gravityCapitalMN[@]}")
input=("${_IN[@]}")
lookAhead=("${gravityCapitalVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が均等な大文字、右寄りの文字で 右が右寄り、中間の大文字の場合 I 右に移動
backtrack=("${gravityCapitalER[@]}" "${gravityRR[@]}")
input=("${_IN[@]}")
lookAhead=("${gravityCapitalRN[@]}" "${gravityCapitalMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# J に関する例外処理 1 ----------------------------------------

# 左が J の場合 引き寄せない大文字、左寄り、幅広の文字 移動しない (次の処理とセット)
backtrack=("${_JL[@]}" \
"${_JN[@]}")
input=("${gravityLN[@]}" "${gravityCapitalRN[@]}" "${gravityWN[@]}" "${gravityCapitalEN[@]}" "${gravityCapitalMN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が J の場合 引き寄せない大文字、左寄り、幅広の文字 右に移動
backtrack=("${_JR[@]}")
input=("${gravityLN[@]}" "${gravityCapitalRN[@]}" "${gravityWN[@]}" "${gravityCapitalEN[@]}" "${gravityCapitalMN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が J で 右が中間、Vの字の場合 狭い文字 移動しない
backtrack=("${_JR[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# L に関する例外処理 1 ----------------------------------------

# 左が L の場合 狭い文字以外 左に移動
backtrack=("${_LL[@]}" \
"${_LN[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が L の場合 引き寄せない文字 移動しない
backtrack=("${_LR[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が L の場合 Vの字 左に移動
backtrack=("${_LR[@]}")
input=("${gravityVN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# W に関する例外処理 ----------------------------------------

# 左がVの大文字で 右が左寄りの文字の場合 W 左に移動しない
backtrack=("${gravityCapitalVL[@]}")
input=("${_WN[@]}")
lookAhead=("${gravityLN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# c に関する例外処理 ----------------------------------------

# 左が c で 右が c の場合 丸い文字 左に移動しない
backtrack=("${_cL[@]}")
input=("${circleCN[@]}")
lookAhead=("${_cN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が c で 右が c 以外の右寄り、丸い小文字の場合 左寄り、幅広、均等、中間の小文字 右に移動しない
backtrack=("${_cN[@]}")
input=("${gravitySmallLN[@]}" "${gravitySmallWN[@]}" "${gravitySmallEN[@]}" "${gravitySmallMN[@]}")
lookAhead=("${_CN[@]}" "${_GN[@]}" "${_aN[@]}" "${_dN[@]}" "${_gN[@]}" "${_qN[@]}" \
"${circleSmallCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# j に関する例外処理 ----------------------------------------

# 両側が j の場合 j 移動しない
backtrack=("${_jR[@]}")
input=("${_jN[@]}")
lookAhead=("${_jN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が gq の場合 j 移動しない
backtrack=("${_gR[@]}" "${_qR[@]}")
input=("${_jN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が ad で、右が il の場合 j 移動しない
backtrack=("${_aR[@]}" "${_dR[@]}")
input=("${_jN[@]}")
lookAhead=("${_iN[@]}" "${_lN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が全ての文字の場合 j 左に移動
backtrack=("${gravityRL[@]}" "${gravityWL[@]}" "${gravityEL[@]}" \
"${gravitySmallLR[@]}" "${gravitySmallRR[@]}" "${gravitySmallER[@]}" "${gravitySmallMR[@]}" "${gravityVR[@]}" "${gravityCR[@]}" \
"${lowSpaceCapitalRR[@]}" \
"${capitalN[@]}" "${smallN[@]}")
input=("${_jN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が中間、Vの字で 右が j の場合 狭い文字 移動しない
backtrack=("${gravityML[@]}" "${gravityVL[@]}")
input=("${gravityCN[@]}")
lookAhead=("${_jN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# il に関する例外処理 ----------------------------------------

# 左が均等な文字で、右が il の場合 狭い文字 右に移動
backtrack=("${gravityEN[@]}")
input=("${gravityCN[@]}")
lookAhead=("${_iN[@]}" "${_lN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が左寄り、中間、Vの字で 右が左寄り、均等な大文字、右が丸い文字の場合 il 左に移動
backtrack=("${gravityLR[@]}" "${gravityMR[@]}" "${gravityVR[@]}")
input=("${_iN[@]}" "${_lN[@]}")
lookAhead=("${gravityCapitalLN[@]}" "${gravityCapitalEN[@]}" \
"${circleRN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# rt に関する例外処理 1 ----------------------------------------

# 両側が r の場合 r 左に移動しない (次の処理とセット)
backtrack=("${_rN[@]}")
input=("${_rN[@]}")
lookAhead=("${_rN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が Ifilr で 右が狭い文字の場合 rt 左に移動
backtrack=("${_IN[@]}" "${_fN[@]}" "${_iN[@]}" "${_lN[@]}" "${_rN[@]}")
input=("${_rN[@]}" "${_tN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が均等な小文字で 右が左寄り、右寄り、均等な文字、中間の大文字、丸い文字の場合 t 左に移動
backtrack=("${gravitySmallER[@]}")
input=("${_tN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityCapitalMN[@]}" \
"${circleCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が幅広の文字で 右が引き離す文字の場合 rt 移動しない
backtrack=("${gravityWL[@]}")
input=("${_rN[@]}" "${_tN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が rt で 右が幅広の文字の場合 幅広の文字 左に移動 (次の処理とセット)
backtrack=("${_rL[@]}" "${_tL[@]}" \
"${_rN[@]}" "${_tN[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が rt の場合 幅広の文字 左に移動しない
backtrack=("${_rL[@]}" "${_tL[@]}" \
"${_rN[@]}" "${_tN[@]}")
input=("${gravityWN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が rt で 右が幅広の文字の場合 左寄り、均等な文字 左に移動 (次の処理とセット)
backtrack=("${_rN[@]}" "${_tN[@]}")
input=("${gravityLN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が rt の場合 左寄り、均等な文字 左に移動しない
backtrack=("${_rN[@]}" "${_tN[@]}")
input=("${gravityLN[@]}" "${gravityEN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が rt で 右が j の場合 右寄り、中間の文字 左に移動しない
backtrack=("${_rN[@]}" "${_tN[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("${_jN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が rt で 右が幅広の文字の場合 幅広と狭い文字以外 左に移動
backtrack=("${_rR[@]}" "${_tR[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が rt の場合 幅広と狭い文字以外 左に移動しない
backtrack=("${_rR[@]}" "${_tR[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# y に関する例外処理 1 ----------------------------------------

# 左が、均等な大文字、左上が開いている文字、gjq の場合 y 左に移動しない
backtrack=("${gravityCapitalEL[@]}" "${highSpaceLL[@]}" "${_gL[@]}" "${_jL[@]}" "${_qL[@]}")
input=("${_yN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が、均等な大文字、左上が開いている文字で 右が引き寄せない文字の場合 y 右に移動しない
backtrack=("${gravityCapitalEN[@]}" "${highSpaceLN[@]}")
input=("${_yN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が、均等な大文字、左上が開いている文字、gjpqþ の場合 y 右に移動
backtrack=("${gravityCapitalER[@]}" "${highSpaceLR[@]}" "${_gR[@]}" "${_jR[@]}" "${_pR[@]}" "${_qR[@]}" "${_thR[@]}" \
"${gravityCapitalEN[@]}" "${highSpaceLN[@]}" "${_gN[@]}" "${_jN[@]}" "${_qN[@]}")
input=("${_yN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# xz に関する例外処理 ----------------------------------------

# 左が、右が丸い小文字で 右が均等な文字の場合 xz 左に移動
backtrack=("${circleSmallRN[@]}" "${circleSmallCN[@]}")
input=("${_xN[@]}" "${_zN[@]}")
lookAhead=("${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が右寄りで 右が右寄り、中間の文字の場合 xz 右に移動
backtrack=("${gravityRN[@]}")
input=("${_xN[@]}" "${_zN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が xz で 右が MmÆŒæœ の場合 h 左に移動
backtrack=("${_xN[@]}" "${_zN[@]}")
input=("${_hN[@]}")
lookAhead=("${_MN[@]}" "${_AEN[@]}" "${_OEN[@]}" "${_mN[@]}" "${_aeN[@]}" "${_oeN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が xz の場合 右が丸い小文字 移動しない
backtrack=("${_xN[@]}" "${_zN[@]}")
input=("${circleSmallRN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# A に関する例外処理 5 ----------------------------------------

# 左が左寄りの大文字で 右が左寄り、均等な大文字の場合 A 右に移動
backtrack=("${gravityCapitalLR[@]}")
input=("${_AN[@]}")
lookAhead=("${gravityCapitalLN[@]}" "${gravityCapitalEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 大文字と小文字に関する例外処理 1 ----------------------------------------

# 左が FJPTÞ で 右が狭い文字の場合 左上が開いている文字 移動しない
backtrack=("${_TR[@]}" \
"${_FN[@]}" "${_JN[@]}" "${_PN[@]}" "${_TN[@]}" "${_THN[@]}")
input=("${highSpaceLN[@]}" "${highSpaceCN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が T の場合 左上が開いている文字 左に移動
backtrack=("${_TL[@]}" \
"${_TN[@]}")
input=("${highSpaceLN[@]}" "${highSpaceCN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 丸い文字に関する例外処理 1 ----------------------------------------

# 左が W で 右が右寄りの大文字 A の場合 丸い大文字 右に移動しない
backtrack=("${_WL[@]}")
input=("${circleCapitalCN[@]}")
lookAhead=("${gravityCapitalRN[@]}" "${_AN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が Ww で 右が左寄り、均等な小文字の場合 均等、丸い文字 右に移動しない (大文字と小文字の処理と統合)
backtrack=("${_WL[@]}" "${_wL[@]}")
input=("${gravitySmallEN[@]}" \
"${circleSmallCN[@]}")
lookAhead=("${gravitySmallLN[@]}" "${gravitySmallEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が Ww で 右が右寄り、中間、Vの字の場合 丸い文字 右に移動しない
backtrack=("${_WL[@]}" "${_wL[@]}")
input=("${circleSmallCN[@]}")
lookAhead=("${gravitySmallRN[@]}" "${gravitySmallMN[@]}" "${gravitySmallVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が、右が丸い文字で 右が Ww の場合 丸い文字 移動しない
backtrack=("${circleRL[@]}" "${circleCL[@]}" \
"${circleRN[@]}" "${circleCN[@]}")
input=("${circleCN[@]}")
lookAhead=("${_WN[@]}" "${_wN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が幅広、右が丸い文字で 右が、右が丸い文字の場合 丸い文字 移動しない
backtrack=("${gravityWL[@]}" \
"${circleRL[@]}")
input=("${circleCN[@]}")
lookAhead=("${circleRN[@]}" "${circleCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が均等な文字で 右が左寄りの文字、Vの小文字の場合 丸い文字 移動しない
backtrack=("${gravityEN[@]}")
input=("${circleCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravitySmallVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が、右が丸い文字、PRÞ の場合 丸い文字 右に移動 (大文字と小文字の処理と統合)
 #backtrack=("${circleRR[@]}" "${_PR[@]}" "${_RR[@]}" "${_THR[@]}")
 #input=("${circleCN[@]}")
 #lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
 #chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
 #index=`expr ${index} + 1`

# 左が丸い文字に関する例外処理 1 ----------------------------------------

# 左が FTkxz で 右が幅広の文字の場合 左が丸い小文字 左に移動
backtrack=("${_FR[@]}" "${_TR[@]}" "${_kR[@]}" "${_xR[@]}" "${_zR[@]}")
input=("${circleSmallLN[@]}" "${circleSmallCN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が、右が丸い文字で 右が中間の文字の場合 左が丸い小文字 右に移動
backtrack=("${circleRN[@]}" "${circleCN[@]}")
input=("${circleSmallLN[@]}" "${circleSmallCN[@]}")
lookAhead=("${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が、右が丸い文字で 右がVの字の場合 左が丸い文字 右に移動
backtrack=("${circleRN[@]}" "${circleCN[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が EFKTXkxĸ で 右が左寄り、右寄り、均等、中間の文字の場合 左が丸い文字 左に移動
backtrack=("${_EN[@]}" "${_FN[@]}" "${_KN[@]}" "${_TN[@]}" "${_XN[@]}" "${_kN[@]}" "${_xN[@]}" "${_kgN[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が EFKTX で 右が幅広の文字の場合 左が丸い文字 左に移動
backtrack=("${_EN[@]}" "${_FN[@]}" "${_KN[@]}" "${_TN[@]}" "${_XN[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が z で 右が右寄りの文字の場合 o 左に移動
backtrack=("${_zN[@]}")
input=("${_oN[@]}")
lookAhead=("${gravityRN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が z で 右が右寄り、均等、中間の文字の場合 左が丸い小文字 左に移動
backtrack=("${_zN[@]}")
input=("${circleSmallLN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が EFKTXkxĸ で 右がVの字、狭い文字の場合 左が丸い文字 右に移動しない
backtrack=("${_EN[@]}" "${_FN[@]}" "${_KN[@]}" "${_TN[@]}" "${_XN[@]}" "${_kN[@]}" "${_xN[@]}" "${_kgN[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("${gravityVN[@]}" "${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が z で 右がVの字の場合 左が丸い文字 右に移動しない
backtrack=("${_zN[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が幅広、引き寄せる文字以外、a で 右が、左が丸い文字の場合 Vの字 左に移動
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityLN[@]}" "${gravityMN[@]}" "${_aN[@]}")
input=("${gravityVN[@]}")
lookAhead=("${circleLN[@]}" "${circleCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が Ww で 右が右寄り、左が丸い文字の場合 Mm 右に移動しない
backtrack=("${_WL[@]}" "${_wL[@]}")
input=("${_MN[@]}" "${_mN[@]}")
lookAhead=("${gravityRN[@]}" \
"${circleCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右が丸い文字に関する例外処理 1 ----------------------------------------

# 左が右寄り、均等な大文字で 右が Ww の場合 右が丸い大文字 移動しない
backtrack=("${gravityCapitalRL[@]}" "${gravityCapitalEL[@]}")
input=("${circleCapitalRN[@]}")
lookAhead=("${_WN[@]}" "${_wN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が、右が丸い大文字の場合 狭い文字 左に移動しない
backtrack=("${circleCapitalRN[@]}" "${circleCapitalCN[@]}")
input=("${gravityCN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が左寄り、中間の文字で 右が右寄り、丸い文字の場合 左寄りの小文字、右が丸い文字 右に移動しない (大文字と小文字の処理と統合)
backtrack=("${gravityLN[@]}" "${gravityMN[@]}")
input=("${gravitySmallLN[@]}" \
"${circleRN[@]}" "${circleCN[@]}")
lookAhead=("${gravityRN[@]}" \
"${circleCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が c 以外の右寄りの文字で 右が左寄り、均等、左が丸い文字の場合 右寄り、均等、右が丸い文字 左に移動しない
backtrack=("${_CL[@]}" "${_GL[@]}" "${_aL[@]}" "${_dL[@]}" "${_gL[@]}" "${_qL[@]}")
input=("${gravityRN[@]}" "${gravityEN[@]}" \
"${circleRN[@]}" "${circleCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}" \
"${circleLN[@]}" "${circleCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が、右が丸い文字で 右が左寄り、均等、左が丸い文字の場合 均等、左右が丸い文字 左に移動しない (左が丸い文字の処理と統合)
backtrack=("${circleRL[@]}" "${circleCL[@]}")
input=("${gravityEN[@]}" \
"${circleLN[@]}" "${circleRN[@]}" "${circleCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}" \
"${circleLN[@]}" "${circleCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 大文字と小文字で処理が異なる例外処理 1 ----------------------------------------

# 左が均等な大文字で 右が左寄りの文字の場合 幅広、均等な大文字 右に移動
backtrack=("${gravityCapitalEN[@]}")
input=("${gravityCapitalWN[@]}" "${gravityCapitalEN[@]}")
lookAhead=("${gravityLN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が均等な大文字で 右が左寄り文字の場合 均等な大文字 左に移動しない
backtrack=("${gravityCapitalEL[@]}")
input=("${gravityCapitalEN[@]}")
lookAhead=("${gravityLN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が左寄り、中間の大文字で 右が幅広の大文字の場合 中間の大文字 左に移動
backtrack=("${gravityCapitalLN[@]}" "${gravityCapitalMN[@]}")
input=("${gravityCapitalMN[@]}")
lookAhead=("${gravityCapitalWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が中間の大文字で 右が狭い大文字の場合 中間の大文字 右に移動しない
backtrack=("${gravityCapitalMN[@]}")
input=("${gravityCapitalMN[@]}")
lookAhead=("${gravityCapitalCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が左寄り、中間の小文字で その左が左寄り、均等な小文字で 右が幅広の小文字の場合 左寄り、均等な小文字 左に移動しない (次の処理とセット)
backtrack1=("${gravitySmallEL[@]}" \
"${gravitySmallLN[@]}" "${gravitySmallEN[@]}")
backtrack=("${gravitySmallLN[@]}" "${gravitySmallMN[@]}")
input=("${gravitySmallLN[@]}" "${gravitySmallEN[@]}")
lookAhead=("${gravitySmallWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"
index=`expr ${index} + 1`

# 左が左寄り、中間の小文字で 右が幅広の小文字の場合 左寄り、右寄り、均等、中間、Vの小文字 左に移動
backtrack=("${gravitySmallLN[@]}" "${gravitySmallMN[@]}")
input=("${gravitySmallLN[@]}" "${gravitySmallRN[@]}" "${gravitySmallEN[@]}" "${gravitySmallMN[@]}" "${gravitySmallVN[@]}")
lookAhead=("${gravitySmallWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が均等の小文字で 右が幅広の小文字の場合 右寄り、中間、Vの小文字 左に移動
backtrack=("${gravitySmallEN[@]}")
input=("${gravitySmallRN[@]}" "${gravitySmallMN[@]}" "${gravitySmallVN[@]}")
lookAhead=("${gravitySmallWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が Ww で 右が左寄りの小文字の場合 均等な小文字 右に移動しない (丸い文字の処理と統合)
 #backtrack=("${_WL[@]}" "${_wL[@]}")
 #input=("${gravitySmallEN[@]}")
 #lookAhead=("${gravitySmallLN[@]}" "${gravitySmallEN[@]}")
 #chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
 #index=`expr ${index} + 1`

# 左が左寄り、中間の文字で 右が右寄り、丸い文字の場合 左寄りの小文字 右に移動しない (右が丸い文字の処理と統合)
 #backtrack=("${gravityLN[@]}" "${gravityMN[@]}")
 #input=("${gravitySmallLN[@]}")
 #lookAhead=("${gravityRN[@]}" \
 #"${circleCN[@]}")
 #chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
 #index=`expr ${index} + 1`

# 左が均等な大文字、右寄りの文字で 右がVの大文字 acsxz の場合 狭い小文字 右に移動
backtrack=("${gravityCapitalER[@]}" "${gravityRR[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityCapitalVN[@]}" "${_aN[@]}" "${_cN[@]}" "${_sN[@]}" "${_xN[@]}" "${_zN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が、中間の文字で 右が左寄りの文字、右寄り、均等な大文字の場合 右寄り、中間の小文字 左に移動
backtrack=("${gravityMN[@]}")
input=("${gravitySmallRN[@]}" "${gravitySmallMN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityCapitalRN[@]}" "${gravityCapitalEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が幅広の文字で 右が左寄り、均等な大文字か k の場合 均等、中間の文字 右に移動しない
backtrack=("${gravityWL[@]}")
input=("${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityCapitalLN[@]}" "${gravityCapitalEN[@]}" "${_kN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左右を見て左に移動させる例外処理 ----------------------------------------

# 左が EFKhkĸ で 右が均等な大文字の場合 幅広の文字 左に移動
backtrack=("${_EL[@]}" "${_FL[@]}" "${_KL[@]}" "${_hL[@]}" "${_kL[@]}" "${_kgL[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityCapitalEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が FTf で 右が狭い文字以外の場合 右寄り、中間、Vの小文字 左に移動
backtrack=("${_FR[@]}" "${_TR[@]}" "${_fR[@]}")
input=("${gravitySmallRN[@]}" "${gravitySmallMN[@]}" "${gravitySmallVN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 2つ右を見て移動させる例外処理 ----------------------------------------

# 左が左寄り、中間の文字で 右が IJfrt で その右が狭い文字の場合 Iirt 右に移動 (次の処理とセット)
backtrack1=("")
backtrack=("${gravityLR[@]}" "${gravityMR[@]}")
input=("${_IN[@]}" "${_iN[@]}" "${_rN[@]}" "${_tN[@]}")
lookAhead=("${_IN[@]}" "${_JN[@]}" "${_fN[@]}" "${_rN[@]}" "${_tN[@]}")
lookAhead1=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"
index=`expr ${index} + 1`

# 左右を見て移動させない例外処理 ----------------------------------------

# 左が左寄り、中間の文字で 右が IJfrt の場合 Iirt 右に移動しない
backtrack=("${gravityLR[@]}" "${gravityMR[@]}")
input=("${_IN[@]}" "${_iN[@]}" "${_rN[@]}" "${_tN[@]}")
lookAhead=("${_IN[@]}" "${_JN[@]}" "${_fN[@]}" "${_rN[@]}" "${_tN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が右寄りの文字で 右が右寄り、中間の文字の場合 filr 右に移動しない
backtrack=("${gravityRN[@]}")
input=("${_fN[@]}" "${_iN[@]}" "${_lN[@]}" "${_rN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が均等の文字で 右が左寄り、右寄り、均等、中間、Vの字の場合 IJf 左に移動しない
backtrack=("${gravityEN[@]}")
input=("${_IN[@]}" "${_JN[@]}" "${_fN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が IJfjrt で 右が狭い文字の場合 幅広の文字 左に移動しない
backtrack=("${_IL[@]}" "${_JL[@]}" "${_fL[@]}" "${_jL[@]}" "${_rL[@]}" "${_tL[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が Jjt で 右が狭い文字の場合 幅広と狭い文字以外 移動しない (統合した処理をさらに統合)
backtrack=("${gravityLL[@]}" "${gravityML[@]}" "${gravityVL[@]}" "${_JL[@]}" "${_jL[@]}" "${_tL[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左がVの字で 右が狭い文字の場合 aSs 右に移動しない
backtrack=("${gravityVR[@]}")
input=("${_aN[@]}" "${_SN[@]}" "${_sN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が et で 右が frt (両側が少しでも左に寄っている文字)の場合 右寄り、中間、Vの字 移動しない
backtrack=("${_eN[@]}" "${_tN[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${_fN[@]}" "${_rN[@]}" "${_tN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が t で 右が ly (両側が少しでも左に寄っている文字)の場合 右寄り、中間、Vの字 移動しない
backtrack=("${_tN[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${_lN[@]}" "${_yN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 統合した通常処理 ----------------------------------------

# 左が狭い文字で 右が右寄り、中間の文字の場合 右寄り、均等、中間、Vの字 左に移動 (次の2つの処理とセット)
backtrack=("${gravityCR[@]}")
input=("${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が狭い文字で 右が左寄りの文字の場合 左寄り、中間、Vの字 左に移動
backtrack=("${gravityCR[@]}")
input=("${gravityLN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${gravityLN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が狭い文字で 右が均等、Vの字の場合 Vの字 左に移動
backtrack=("${gravityCR[@]}")
input=("${gravityVN[@]}")
lookAhead=("${gravityEN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が引き離す文字で 右が幅広の文字の場合 引き寄せない文字 移動しない
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityRR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityWN[@]}")
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

# 左が引き離す文字で 右が狭い文字の場合 幅広の文字以外 右に移動 (次の処理とセット)
backtrack=("${gravityRL[@]}" "${gravityWL[@]}" "${gravityEL[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}" "${gravityCN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が左寄り、中間、Vの字で 右が狭い文字の場合 幅広と狭い文字以外 移動しない (左右を見て動かさない処理と統合)
 #backtrack=("${gravityLL[@]}" "${gravityML[@]}" "${gravityVL[@]}")
 #input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
 #lookAhead=("${gravityCN[@]}")
 #chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
 #index=`expr ${index} + 1`

# L に関する例外処理 2 ----------------------------------------

# 両側が狭い文字の場合 L 右に移動しない (次の処理とセット)
backtrack=("${gravityCL[@]}")
input=("${_LN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右が全ての文字の場合 L 右に移動
backtrack=("")
input=("${_LN[@]}")
lookAhead=("${capitalN[@]}" "${smallN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# ASs に関する例外処理 ----------------------------------------

# 左が右寄り、均等な文字で 右が狭い文字の場合 ASs 右に移動
backtrack=("${gravityRN[@]}" "${gravityEN[@]}")
input=("${_AN[@]}" "${_SN[@]}" "${_sN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が幅広、右寄り、均等な文字の場合 ASs 右に移動しない
backtrack=("${gravityWL[@]}" \
"${gravityRN[@]}" "${gravityEN[@]}")
input=("${_AN[@]}" "${_SN[@]}" "${_sN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 2つ左を見て移動させない例外処理 1 ----------------------------------------

# 左が狭い文字で 右が全ての文字の場合 引き寄せない文字 左に移動
backtrack=("${gravityCL[@]}" \
"${gravityCN[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${capitalN[@]}" "${smallN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が IJijlt で その左が狭い文字の場合 左寄り、右寄り、均等、中間の文字 移動しない
backtrack1=("${_JL[@]}" "${_jL[@]}" \
"${gravityCR[@]}" \
"${_JN[@]}" "${_jN[@]}")
backtrack=("${_IL[@]}" "${_JL[@]}" "${_iL[@]}" "${_jL[@]}" "${_tL[@]}" \
"${_IN[@]}" "${_JN[@]}" "${_iN[@]}" "${_jN[@]}" "${_lN[@]}" "${_tN[@]}")
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

# 左がVの字で その左が L の場合 幅広と狭い文字以外 左に移動しない
backtrack1=("${_LR[@]}")
backtrack=("${gravityVL[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"
index=`expr ${index} + 1`

# 左が中間の文字で その左が Ww の場合 r 左に移動しない
backtrack1=("${_WL[@]}" "${_wL[@]}")
backtrack=("${gravityMR[@]}")
input=("${_rN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"
index=`expr ${index} + 1`

# 左が幅広の小文字で その左が幅広の文字の場合 ijlr 右に移動しない
backtrack1=("${gravityWR[@]}" \
"${gravityWN[@]}")
backtrack=("${gravitySmallWR[@]}")
input=("${_iN[@]}" "${_jN[@]}" "${_lN[@]}" "${_rN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"
index=`expr ${index} + 1`

# 左が左寄り、中間の小文字、Vの字で その左が幅広の文字の場合 acsxz 右に移動しない
backtrack1=("${gravityWR[@]}" \
"${gravityWN[@]}")
backtrack=("${gravitySmallLR[@]}" "${gravitySmallMR[@]}" "${gravityVR[@]}")
input=("${_aN[@]}" "${_cN[@]}" "${_sN[@]}" "${_xN[@]}" "${_zN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"
index=`expr ${index} + 1`

# 大文字と小文字に関する例外処理 2 ----------------------------------------

# 左が、右が丸い文字、PRÞ の場合 右寄り、均等な小文字、丸い文字 右に移動 (丸い文字の処理と統合)
backtrack=("${circleRR[@]}" "${_PR[@]}" "${_RR[@]}" "${_THR[@]}")
input=("${gravitySmallRN[@]}" "${gravitySmallEN[@]}" \
"${circleCN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 移動しない ========================================

# 左右を見て移動させない通常処理 ----------------------------------------

# 左右を見て 左寄り、均等な文字 移動しない
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityVN[@]}")
input=("${gravityLN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左右を見て 左寄りの文字 移動しない
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityVN[@]}")
input=("${gravityLN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左右を見て 右寄り、中間の文字 移動しない
backtrack=("${gravityLN[@]}" "${gravityMN[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左右を見て 中間の文字 移動しない
backtrack=("${gravityLN[@]}" "${gravityMN[@]}")
input=("${gravityMN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で左に移動 ========================================

# 左が丸い文字に関する例外処理 2 ----------------------------------------

# 左が、右が丸い文字で 右が幅広の文字の場合 左が丸い文字 左に移動 (次の処理とセット)
backtrack=("${circleRL[@]}" "${circleCL[@]}" \
"${circleRN[@]}" "${circleCN[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が、右が丸い文字の場合 左が丸い文字 左に移動しない (次の処理より前に置くこと)
backtrack=("${circleRL[@]}" "${circleCL[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 2つ左を見て移動させない例外処理 2 ----------------------------------------

# 左が左寄り、中間の文字で 右が狭い文字以外の場合 右寄り、中間、Vの字 左に移動 (前の処理より後に置くこと、次の処理とセット)
backtrack=("${gravityLL[@]}" "${gravityML[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が左寄り、中間の文字で その左が狭い文字の場合 右寄り、中間、Vの字 移動しない
backtrack1=("${gravityCL[@]}" \
"${gravityCN[@]}")
backtrack=("${gravityLL[@]}" "${gravityML[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"
index=`expr ${index} + 1`

# 左右を見て左に移動させる通常処理 ----------------------------------------

# 左側基準で 左寄り、均等な文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityML[@]}")
input=("${gravityLN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 右寄り、中間、Vの字 左に移動
backtrack=("${gravityRL[@]}" "${gravityEL[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で Vの字 左に移動
backtrack=("${gravityRL[@]}" "${gravityEL[@]}")
input=("${gravityVN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 幅広の文字 左に移動
backtrack=("${gravityEL[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 幅広の文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityML[@]}" "${gravityVL[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 狭い文字 左に移動
backtrack=("${gravityWL[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左右を見て左に移動させない通常処理 ----------------------------------------

# 左側基準で 左寄り、均等な文字 左に移動しない
backtrack=("${gravityVL[@]}" \
"${gravityCN[@]}")
input=("${gravityLN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 左寄りの文字 左に移動しない
backtrack=("${gravityVL[@]}" \
"${gravityCN[@]}")
input=("${gravityLN[@]}")
lookAhead=("${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 右寄り、中間の文字 左に移動しない
backtrack=("${gravityLL[@]}" "${gravityML[@]}" \
"${gravityVN[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 中間の文字 左に移動しない
backtrack=("${gravityLL[@]}" "${gravityML[@]}" \
"${gravityVN[@]}")
input=("${gravityMN[@]}")
lookAhead=("${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 幅広、狭い文字 左に移動しない
backtrack=("${gravityCN[@]}")
input=("${gravityWN[@]}" "${gravityCN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 狭い文字 左に移動しない
backtrack=("${gravityCR[@]}" \
"${gravityLN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で Vの字 左に移動しない
backtrack=("${gravityVL[@]}")
input=("${gravityVN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左を見て左に移動させる通常処理 ----------------------------------------

# 左側基準で 全ての文字 左に移動
backtrack=("${gravityCL[@]}" \
"${gravityCN[@]}")
input=("${capitalN[@]}" "${smallN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 幅広の文字以外 左に移動
backtrack=("${gravityVL[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}" "${gravityCN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 右寄り、中間、Vの字、狭い文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityML[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}" "${gravityCN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 右寄り、中間、狭い文字 左に移動
backtrack=("${gravityVN[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityCN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で 狭い文字 左に移動
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityCR[@]}" \
"${gravityLN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
input=("${gravityCN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左側基準で右に移動 ========================================

# 左が丸い文字に関する例外処理 3 ----------------------------------------

# 左が、左右が丸い文字の場合 左が丸い文字 右に移動
backtrack=("${circleLR[@]}" "${circleRR[@]}" "${circleCR[@]}")
input=("${circleLN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左右を見て右に移動させる通常処理 ----------------------------------------

# 左側基準で 狭い文字 右に移動
backtrack=("${gravityRN[@]}" "${gravityWN[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}" "${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左右を見て右に移動させない通常処理 ----------------------------------------

# 左側基準で 左寄り、均等な文字 右に移動しない
backtrack=("${gravityVR[@]}" \
"${gravityLN[@]}" "${gravityMN[@]}")
input=("${gravityLN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 均等な文字 右に移動しない
backtrack=("${gravityVR[@]}" \
"${gravityLN[@]}" "${gravityMN[@]}")
input=("${gravityEN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 幅広の文字 右に移動しない
backtrack=("${gravityWL[@]}" \
"${gravityRN[@]}" "${gravityEN[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 右寄りの文字 右に移動しない
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityRR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityRN[@]}" "${gravityEN[@]}")
input=("${gravityRN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 幅広の文字 右に移動しない
backtrack=("${gravityRL[@]}" \
"${gravityLN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 均等、中間の文字 右に移動しない
backtrack=("${gravityLR[@]}" \
"${gravityRN[@]}" "${gravityEN[@]}")
input=("${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 中間、Vの字 右に移動しない
backtrack=("${gravityVR[@]}")
input=("${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 中間の文字 右に移動しない
backtrack=("${gravityVR[@]}")
input=("${gravityMN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で Vの字 右に移動しない
backtrack=("${gravityVR[@]}")
input=("${gravityVN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で Vの字 右に移動しない
backtrack=("${gravityRR[@]}" "${gravityER[@]}")
input=("${gravityVN[@]}")
lookAhead=("${gravityWN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 狭い文字 右に移動しない
backtrack=("${gravityWR[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側基準で 均等な文字 右に移動しない (次の処理と統合)
 #backtrack=("${gravityEN[@]}")
 #input=("${gravityEN[@]}")
 #lookAhead=("${gravityRN[@]}")
 #chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
 #index=`expr ${index} + 1`

# 丸い文字に関する例外処理 2 ----------------------------------------

# 左が均等な文字で 右が右寄り、丸い文字の場合 均等な文字 右に移動しない (前の処理と統合)
backtrack=("${gravityEN[@]}")
input=("${gravityEN[@]}")
lookAhead=("${gravityRN[@]}" \
"${circleCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が丸い文字に関する例外処理 4 ----------------------------------------

# 左が均等な文字で 右が、左が丸い文字の場合 幅広の文字 右に移動しない
backtrack=("${gravityEN[@]}")
input=("${gravityWN[@]}")
lookAhead=("${circleLN[@]}" "${circleCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が、右が丸い文字の場合 左が丸い文字 右に移動
backtrack=("${circleRN[@]}" "${circleCN[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左を見て右に移動させる通常処理 ----------------------------------------

# 左側基準で 全ての文字 右に移動
backtrack=("${gravityWR[@]}")
input=("${capitalN[@]}" "${smallN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左側基準で 狭い文字以外 右に移動
backtrack=("${gravityRR[@]}" "${gravityER[@]}" "${gravityVR[@]}" \
"${gravityWN[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左側基準で 左寄り、右寄り、幅広、均等、中間の文字 右に移動
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityMR[@]}" \
"${gravityRN[@]}" "${gravityEN[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左側基準で 左寄り、幅広、均等な文字 右に移動
backtrack=("${gravityLN[@]}" "${gravityMN[@]}")
input=("${gravityLN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左側基準で 幅広の文字 右に移動
backtrack=("${gravityRL[@]}" \
"${gravityVN[@]}")
input=("${gravityWN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# もろもろ例外 ========================================

# 2つ左を見て移動させる例外処理 1 ----------------------------------------

# 右が狭い文字の場合 狭い文字 右に移動
backtrack=("")
input=("${gravityCN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が左寄り、中間の文字で 右が右寄りの小文字、中間、Vの字の場合 fir 移動しない
backtrack=("${gravityLR[@]}" "${gravityMR[@]}")
input=("${_fN[@]}" "${_iN[@]}" "${_rN[@]}")
lookAhead=("${gravitySmallRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が左寄り、中間、Vの字で その左が幅広の文字の場合 Jfijlrt 左に移動
backtrack1=("${gravityWL[@]}" \
"${gravityWR[@]}" \
"${gravityWN[@]}")
backtrack=("${gravityLR[@]}" "${gravityMR[@]}" "${gravityVR[@]}")
input=("${_JN[@]}" "${_fN[@]}" "${_iN[@]}" "${_jN[@]}" "${_lN[@]}" "${_rN[@]}" "${_tN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}"
index=`expr ${index} + 1`

# 左が右寄り、均等な文字で その左が幅広の文字の場合 r 左に移動
backtrack1=("${gravityWL[@]}" \
"${gravityWR[@]}" \
"${gravityWN[@]}")
backtrack=("${gravityRR[@]}" "${gravityER[@]}")
input=("${_rN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}"
index=`expr ${index} + 1`

# A に関する例外処理 6 ----------------------------------------

# 右が W の場合 A 右に移動しない
backtrack=("")
input=("${_AN[@]}")
lookAhead=("${_WN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右が、左下が開いている大文字の場合 A 右に移動
backtrack=("")
input=("${_AN[@]}")
lookAhead=("${lowSpaceCapitalCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右が A の場合 右下が開いている大文字か W 右に移動
backtrack=("")
input=("${lowSpaceCapitalRN[@]}" "${lowSpaceCapitalCN[@]}" "${_WN[@]}")
lookAhead=("${_AN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# EF に関する例外処理 ----------------------------------------

# 左が EF で 右が 左寄り、均等な文字の場合 左寄りの文字 左に移動
backtrack=("${_EL[@]}" "${_FL[@]}")
input=("${gravityLN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# L に関する例外処理 3 ----------------------------------------

# 右が L の場合 左寄り、中間の文字 左に移動しない
backtrack=("")
input=("${gravityLN[@]}" "${gravityMN[@]}")
lookAhead=("${_LN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# Jj に関する例外処理 2 ----------------------------------------

# 右が引き寄せない大文字、左寄り、幅広の文字の場合 Jj 左に移動
backtrack=("")
input=("${_JN[@]}" "${_jN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityCapitalRN[@]}" "${gravityWN[@]}" "${gravityCapitalEN[@]}" "${gravityCapitalMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右がVの大文字の場合 J 移動しない
backtrack=("")
input=("${_JN[@]}")
lookAhead=("${gravityCapitalVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# hkĸAaSsxz に関する例外処理 ----------------------------------------

# 右が a で その右が a の場合 a 左に移動
backtrack1=("")
backtrack=("")
input=("${_aN[@]}")
lookAhead=("${_aN[@]}")
lookAhead1=("${_aN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"
index=`expr ${index} + 1`

# 右が h で その右が h の場合 h 左に移動
backtrack1=("")
backtrack=("")
input=("${_hN[@]}")
lookAhead=("${_hN[@]}")
lookAhead1=("${_hN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"
index=`expr ${index} + 1`

# 右が k で その右が k の場合 k 左に移動
backtrack1=("")
backtrack=("")
input=("${_kN[@]}")
lookAhead=("${_kN[@]}")
lookAhead1=("${_kN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"
index=`expr ${index} + 1`

# 右が ĸ で その右が ĸ の場合 ĸ 左に移動
backtrack1=("")
backtrack=("")
input=("${_kgN[@]}")
lookAhead=("${_kgN[@]}")
lookAhead1=("${_kgN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"
index=`expr ${index} + 1`

# 右が左寄り、均等な文字の場合 hASs 左に移動しない
backtrack=("")
input=("${_hN[@]}" "${_AN[@]}" "${_SN[@]}" "${_sN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右が hkĸ の場合 kĸxz 左に移動しない
backtrack=("")
input=("${_kN[@]}" "${_kgN[@]}" "${_xN[@]}" "${_zN[@]}")
lookAhead=("${_hN[@]}" "${_kN[@]}" "${_kgN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が EFKXkxzĸ で 右が a の場合 bhpþ 左に移動
backtrack=("${_EL[@]}" "${_FL[@]}" "${_KL[@]}" "${_XL[@]}" "${_kL[@]}" "${_xL[@]}" "${_zL[@]}" "${_kgL[@]}")
input=("${_bN[@]}" "${_hN[@]}" "${_pN[@]}" "${_thN[@]}")
lookAhead=("${_aN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# rt に関する例外処理 2 ----------------------------------------

# 右が幅広の文字の場合 rt 左に移動
backtrack=("")
input=("${_rN[@]}" "${_tN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右が左寄り、右寄り、均等、中間の文字の場合 rt 右に移動しない
backtrack=("")
input=("${_rN[@]}" "${_tN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# y に関する例外処理 2 ----------------------------------------

# 右が y の場合 jpþ 右に移動しない
backtrack=("")
input=("${_jN[@]}" "${_pN[@]}" "${_thN[@]}")
lookAhead=("${_yN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 大文字と小文字に関する例外処理 3 ----------------------------------------

# 左が、右上が開いている文字で 右が、左上が開いている文字の場合 T 右に移動しない (次の処理とセット)
backtrack=("${highSpaceRN[@]}" "${highSpaceCN[@]}")
input=("${_TN[@]}")
lookAhead=("${highSpaceLN[@]}" "${highSpaceCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右が、左上が開いている文字の場合 FT 右に移動
backtrack=("")
input=("${_FN[@]}" "${_TN[@]}")
lookAhead=("${highSpaceLN[@]}" "${highSpaceCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右が丸い文字に関する例外処理 2 ----------------------------------------

# 右が左寄り、均等、左が丸い文字で その右が filr で その右が幅広の文字の場合 右が丸い小文字 左に移動
backtrack1=("")
backtrack=("")
input=("${circleSmallRN[@]}" "${circleSmallCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}" \
"${circleLN[@]}" "${circleCN[@]}")
lookAhead1=("${_fN[@]}" "${_iN[@]}" "${_lN[@]}" "${_rN[@]}")
lookAheadX=("${gravityWN[@]}"); aheadMax="2"
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"
index=`expr ${index} + 1`

# 右が左寄り、均等、左が丸い文字で その右が filr の場合 右が丸い小文字 左に移動しない
backtrack1=("")
backtrack=("")
input=("${circleSmallRN[@]}" "${circleSmallCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}" \
"${circleLN[@]}" "${circleCN[@]}")
lookAhead1=("${_fN[@]}" "${_iN[@]}" "${_lN[@]}" "${_rN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"
index=`expr ${index} + 1`

# 左が PRÞ で 右が左寄り、均等、左が丸い文字の場合 右が丸い文字 左に移動しない
backtrack=("${_PL[@]}" "${_RL[@]}" "${_THL[@]}")
input=("${circleRN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}" \
"${circleLN[@]}" "${circleCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右が左寄り、均等、左が丸い文字の場合 右が丸い文字 左に移動
backtrack=("")
input=("${circleRN[@]}" "${circleCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}" \
"${circleLN[@]}" "${circleCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 大文字と小文字で処理が異なる例外処理 2 ----------------------------------------

# 右が中間の小文字の場合 均等な大文字 左に移動
backtrack=("")
input=("${gravityCapitalEN[@]}")
lookAhead=("${gravitySmallMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右が均等な小文字の場合 左寄り、中間の文字 左に移動しない
backtrack=("")
input=("${gravityLN[@]}" "${gravityMN[@]}")
lookAhead=("${gravitySmallEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右を見て移動させない例外処理 ----------------------------------------

# 右が、丸い大文字の場合 EFKXkxzĸ 左に移動しない
backtrack=("")
input=("${_EN[@]}" "${_FN[@]}" "${_KN[@]}" "${_XN[@]}" "${_kN[@]}" "${_xN[@]}" "${_zN[@]}" "${_kgN[@]}")
lookAhead=("${circleCapitalCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で左に移動 ========================================

# 左右を見て左に移動させる通常処理 ----------------------------------------

# 右側基準で 狭い文字 左に移動
backtrack=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左右を見て左に移動させない通常処理 ----------------------------------------

# 右側基準で 左寄り、均等な文字 左に移動しない
backtrack=("${gravityVN[@]}")
input=("${gravityLN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で 右寄り、中間の文字 左に移動しない
backtrack=("${gravityLN[@]}" "${gravityMN[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で 左寄り、中間の文字 左に移動しない
backtrack=("${gravityRL[@]}" "${gravityEL[@]}")
input=("${gravityLN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で 左寄り 左に移動しない
backtrack=("${gravityLL[@]}" "${gravityML[@]}")
input=("${gravityLN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で 幅広の文字 左に移動しない
backtrack=("${gravityLL[@]}" "${gravityEL[@]}" "${gravityML[@]}" "${gravityVL[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で Vの字 左に移動しない
backtrack=("${gravityWL[@]}" \
"${gravityRN[@]}" "${gravityEN[@]}")
input=("${gravityVN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が丸い文字に関する例外処理 5 ----------------------------------------

# 左が、右が丸い文字で 右が、左が丸い文字の場合 均等、左が丸い文字 左に移動しない (次の処理とセット、右が丸い文字の処理と統合)
 #backtrack=("${circleRL[@]}" "${circleCL[@]}")
 #input=("${gravityEN[@]}" \
 #"${circleLN[@]}")
 #lookAhead=("${circleLN[@]}" "${circleCN[@]}")
 #chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
 #index=`expr ${index} + 1`

# 右が、左が丸い文字の場合 右寄り、均等な文字 左に移動
backtrack=("")
input=("${gravityRN[@]}" "${gravityEN[@]}")
lookAhead=("${circleLN[@]}" "${circleCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右を見て左に移動させる通常処理 ----------------------------------------

# 右側基準で 狭い文字以外 左に移動
backtrack=("")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右側基準で 左寄り、右寄り、幅広、均等、中間の文字 左に移動
backtrack=("")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右側基準で 幅広の文字 左に移動
backtrack=("")
input=("${gravityWN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右側基準で右に移動 ========================================

# 2つ右を見て移動させない例外処理 ----------------------------------------

# 左が左寄り、中間の文字で 右が狭い文字の場合 右寄り、中間の文字 右に移動
backtrack=("${gravityLN[@]}" "${gravityMN[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右が t で その右が IJfrt の場合 左寄り、中間の文字 右に移動しない
backtrack1=("")
backtrack=("")
input=("${gravityLN[@]}" "${gravityMN[@]}")
lookAhead=("${_tN[@]}")
lookAhead1=("${_IN[@]}" "${_JN[@]}" "${_fN[@]}" "${_rN[@]}" "${_tN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"
index=`expr ${index} + 1`

# 右が Ifr で その右が IJfrt の場合 左寄り、右寄り、中間の文字 右に移動しない
backtrack1=("")
backtrack=("")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("${_IN[@]}" "${_fN[@]}" "${_rN[@]}")
lookAhead1=("${_IN[@]}" "${_JN[@]}" "${_fN[@]}" "${_rN[@]}" "${_tN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"
index=`expr ${index} + 1`

# 右が il で その右が il の場合 左寄り、右寄り、中間の文字 右に移動しない
backtrack1=("")
backtrack=("")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("${_iN[@]}" "${_lN[@]}")
lookAhead1=("${_iN[@]}" "${_lN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"
index=`expr ${index} + 1`

# 右が狭い文字で その右が狭い文字の場合 幅広の文字、均等な大文字 右に移動しない
backtrack1=("")
backtrack=("")
input=("${gravityWN[@]}" "${gravityCapitalEN[@]}")
lookAhead=("${gravityCN[@]}")
lookAhead1=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"
index=`expr ${index} + 1`

# 右が VY で その右が幅広の文字の場合 左寄り、中間の大文字 右に移動しない
backtrack1=("")
backtrack=("")
input=("${gravityCapitalLN[@]}" "${gravityCapitalMN[@]}")
lookAhead=("${_VN[@]}" "${_YN[@]}")
lookAhead1=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"
index=`expr ${index} + 1`

# 右がVの小文字で その右が幅広の文字の場合 BDS 右に移動しない
backtrack1=("")
backtrack=("")
input=("${_BN[@]}" "${_DN[@]}" "${_SN[@]}")
lookAhead=("${gravitySmallVN[@]}")
lookAhead1=("${gravityWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"
index=`expr ${index} + 1`

# 左右を見て右に移動させない通常処理 ----------------------------------------

# 右側基準で 均等、Vの字 右に移動しない
backtrack=("${gravityCR[@]}" \
"${gravityVN[@]}")
input=("${gravityEN[@]}" "${gravityLN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で 左寄りの文字 右に移動しない
backtrack=("${gravityCR[@]}" \
"${gravityVN[@]}")
input=("${gravityLN[@]}")
lookAhead=("${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で 右寄り、中間、Vの字 右に移動しない
backtrack=("${gravityCR[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で 中間の文字 右に移動しない
backtrack=("${gravityCR[@]}")
input=("${gravityMN[@]}")
lookAhead=("${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で Vの字 右に移動しない
backtrack=("${gravityCR[@]}")
input=("${gravityVN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で 左寄りの文字 右に移動しない
backtrack=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}")
input=("${gravityLN[@]}")
lookAhead=("${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で 幅広の文字 右に移動しない
backtrack=("${gravityVL[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で 中間の文字 右に移動しない
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityLN[@]}" "${gravityMN[@]}")
input=("${gravityMN[@]}")
lookAhead=("${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で Vの字 右に移動しない
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityLR[@]}" "${gravityMR[@]}" \
"${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
input=("${gravityVN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で 狭い文字 右に移動しない
backtrack=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右側基準で 狭い文字 右に移動しない
backtrack=("${gravityRN[@]}" "${gravityWN[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右を見て右に移動させる通常処理 ----------------------------------------

# 右側基準で 全ての文字 右に移動
backtrack=("")
input=("${capitalN[@]}" "${smallN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右側基準で 左寄り、中間、狭い文字 右に移動
backtrack=("")
input=("${gravityLN[@]}" "${gravityMN[@]}" "${gravityCN[@]}")
lookAhead=("${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右側基準で Vの字、狭い文字 右に移動
backtrack=("")
input=("${gravityVN[@]}" "${gravityCN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右側基準で 狭い文字 右に移動
backtrack=("")
input=("${gravityCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 2つ左を見て移動させる例外処理 2 ----------------------------------------

# 右が右寄り、中間、Vの字の場合 左寄り、右寄り、均等、中間の文字 右に移動しない (次の処理とセット)
backtrack=("")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が左寄り、右寄り、均等、中間の文字で その左が狭い文字の場合 左寄り、右寄り、均等、中間の文字 右に移動
backtrack1=("${gravityCL[@]}" \
"${gravityCN[@]}")
backtrack=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}"
index=`expr ${index} + 1`

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

# 丸くない右寄りの文字
set=("${gCR[@]}" "${gSR[@]}")
remove=("${cCL[@]}" "${cSL[@]}")

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
{
  echo "<LookupType value=\"6\"/>"
  echo "<LookupFlag value=\"0\"/>"
} >> "${caltList}.txt"
index="0"

# 同じ文字を等間隔にさせる処理 ----------------------------------------

# j
  # 右から元に戻る (広がる)
backtrack1=("")
backtrack=("")
input=("${_jR[@]}")
lookAhead=("${_jN[@]}")
lookAhead1=("${_jL[@]}")
lookAheadX=("${_jL[@]}"); aheadMax="2"
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"
index=`expr ${index} + 1`

# L
  # 右から元に戻る (広がる)
backtrack1=("")
backtrack=("")
input=("${_LR[@]}")
lookAhead=("${_LN[@]}")
lookAhead1=("${_LL[@]}")
lookAheadX=("${_LL[@]}"); aheadMax="2"
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"
index=`expr ${index} + 1`

  # 左から元に戻る (広がる)
backtrack1=("${_LN[@]}")
backtrack=("${_LN[@]}")
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

# 丸くない右寄りの文字、hkĸ
set=("${gCR[@]}" "${gSR[@]}" "_h" "_k" "_kg")
remove=("${cCL[@]}" "${cSL[@]}")

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

# L 以外の左寄りの大文字、左が丸い文字、右が丸い文字
class=("${cCL[@]}" "${cSL[@]}" "${cCR[@]}" "${cSR[@]}" "${gCL[@]}")
for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
  if [ "${S}" != "_L" ]; then
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
  fi
done

# L 以外の左寄りの文字、右寄りの文字
class=("${gCL[@]}" "${gSL[@]}" "${gCR[@]}" "${gSR[@]}")
for S in ${class[@]}; do
  eval "member=(\"\${${S}[@]}\")"
  if [ "${S}" != "_L" ]; then
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
  fi
done

# 幅広の文字
set=("${gCW[@]}" "${gSW[@]}")
remove=("${fxG[@]}")

class=("") # 移動しない文字を除去
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
    lookAhead1+=("${T}R" "${T}")
    lookAheadX+=("${T}R" "${T}")
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
  if [ "${S}" != "_j" ]; then
  # 右から元に戻る (広がる) j 以外
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

# 右側が左に寄って詰まった間隔を整える処理 ----------------------------------------

# 右が、左が丸い小文字の場合 xz 元に戻る
backtrack=("")
input=("${_xR[@]}" "${_zR[@]}")
lookAhead=("${circleSmallLL[@]}" "${circleSmallCL[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が、右が丸い文字で 右が左寄り、均等な文字の場合 左が丸い、均等な文字 左に移動
backtrack=("${circleRL[@]}" "${circleCL[@]}")
input=("${circleLN[@]}" "${circleCN[@]}" \
"${gravityEN[@]}")
lookAhead=("${gravityLL[@]}" "${gravityEL[@]}" \
"${gravityLN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が rt で 右が左寄り、右寄り、均等、丸い文字の場合 左寄り、均等な文字 左に移動
backtrack=("${_rN[@]}" "${_tN[@]}")
input=("${gravityLN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" \
"${circleCL[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右側が元に戻って詰まった間隔を整える処理 ----------------------------------------

# 左が幅広、均等、右が丸い文字で 右が右寄り、均等、右が丸い文字の場合 均等、丸い文字 元の位置に戻る (右に幅広の処理と統合)
backtrack=("${gravityWL[@]}" \
"${gravityER[@]}" \
"${circleRR[@]}" "${circleCR[@]}")
input=("${gravityER[@]}" \
"${circleCR[@]}")
lookAhead=("${gravityRN[@]}" "${gravityEN[@]}" \
"${circleRN[@]}" "${circleCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右に幅広が来た時に左側を詰める処理の始め ----------------------------------------

# 左が、右が丸い、均等な文字で 右が、左右が丸い、均等な文字の場合 丸い、均等な文字 元の位置に戻る (右側が戻った処理と統合)
 #backtrack=("${circleRR[@]}" "${circleCR[@]}" \
 #"${gravityER[@]}")
 #input=("${circleCR[@]}" \
 #"${gravityER[@]}")
 #lookAhead=("${circleRN[@]}" "${circleLN[@]}" "${circleCN[@]}" \
 #"${gravityEN[@]}")
 #chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
 #index=`expr ${index} + 1`

# ---

# 左が右寄り、均等な小文字で 右が w の場合 左寄り、右寄り、均等、中間の小文字 左に移動しない
backtrack=("${gravitySmallRN[@]}" "${gravitySmallEN[@]}")
input=("${gravitySmallLN[@]}" "${gravitySmallRN[@]}" "${gravitySmallEN[@]}" "${gravitySmallMN[@]}")
lookAhead=("${_wN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が右寄りの小文字で その左が左寄り、右寄り、均等、中間の小文字で 右が幅広の小文字の場合 左寄りの小文字 左に移動
backtrack1=("${gravitySmallRL[@]}" "${gravitySmallEL[@]}" \
"${gravitySmallLN[@]}" "${gravitySmallMN[@]}")
backtrack=("${gravitySmallRN[@]}")
input=("${gravitySmallLN[@]}")
lookAhead=("${gravitySmallWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}"
index=`expr ${index} + 1`

# 左が左寄り、均等、中間の小文字で 右が幅広の小文字の場合 左寄り、右寄り、均等、中間の小文字 左に移動
backtrack=("${gravitySmallLN[@]}" "${gravitySmallEN[@]}" "${gravitySmallMN[@]}")
input=("${gravitySmallLN[@]}" "${gravitySmallRN[@]}" "${gravitySmallEN[@]}" "${gravitySmallMN[@]}")
lookAhead=("${gravitySmallWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が左寄り、右寄り、中間の小文字で 右が幅広の小文字の場合 右寄り、均等、中間の小文字 左に移動
backtrack=("${gravitySmallRN[@]}" \
"${gravitySmallLR[@]}" "${gravitySmallMR[@]}")
input=("${gravitySmallRN[@]}" "${gravitySmallEN[@]}" "${gravitySmallMN[@]}")
lookAhead=("${gravitySmallWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 丸い文字と均等な文字が並んだ場合の処理 ----------------------------------------

# 両側が、左右が丸い文字の場合 左右が丸い、均等な文字 左に移動
backtrack=("${circleLL[@]}" "${circleRL[@]}" "${circleCL[@]}")
input=("${circleLN[@]}" "${circleRN[@]}" "${circleCN[@]}" \
"${gravityEN[@]}")
lookAhead=("${circleLL[@]}" "${circleRL[@]}" "${circleCL[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が、左が丸い文字の場合 均等な文字 元の位置に戻らない
backtrack=("${circleLN[@]}")
input=("${gravityER[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右が c の場合 右が丸い、均等な小文字 元の位置に戻らない
backtrack=("")
input=("${gravitySmallER[@]}" \
"${circleSmallRR[@]}" "${circleSmallCR[@]}")
lookAhead=("${_cR[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 大文字 ----

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

# 左が、左右が丸い小文字で 右が、左右が丸い小文字の場合 左が丸い、均等な小文字 元の位置に戻る
backtrack=("${circleSmallLN[@]}" "${circleSmallRN[@]}" "${circleSmallCN[@]}")
input=("${circleSmallLR[@]}" "${circleSmallCR[@]}" \
"${gravitySmallER[@]}")
lookAhead=("${circleSmallLR[@]}" "${circleSmallRR[@]}" "${circleSmallCR[@]}" \
"${circleSmallLN[@]}" "${circleSmallRN[@]}" "${circleSmallCN[@]}")
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

# 左が、右が丸い小文字で 右が、左右が丸い小文字の場合 右が丸い小文字 元の位置に戻る
backtrack=("${circleSmallRN[@]}" "${circleSmallCN[@]}")
input=("${circleSmallRR[@]}")
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

# 右側が右に移動したため開いた間隔を詰める処理 ----------------------------------------

# 左が引き寄せる文字の場合 均等な文字 元の位置に戻らない
backtrack=("${gravityVL[@]}" "${gravityCL[@]}" \
"${gravityCN[@]}")
input=("${gravitySmallEL[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右が右寄り、均等、中間の文字の場合 均等な小文字 元の位置に戻る
backtrack=("")
input=("${gravitySmallEL[@]}")
lookAhead=("${gravityRR[@]}" "${gravityER[@]}" "${gravityMR[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が右寄りで 右が左寄り、均等な文字の場合 右寄りの文字 元の位置に戻る
backtrack=("${gravityRL[@]}")
input=("${gravityRL[@]}")
lookAhead=("${gravityLR[@]}" "${gravityER[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が Ww で 右がVの字、狭い文字 s の場合 右寄り、中間の文字 右に移動
backtrack=("${_WL[@]}" "${_wL[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityVR[@]}" "${gravityCR[@]}" "${_sR[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左がVの大文字、狭い大文字で 右が狭い小文字 sv の場合 右寄り、均等な小文字 右に移動
backtrack=("${gravityCapitalVR[@]}" "${gravityCapitalCR[@]}")
input=("${gravitySmallRN[@]}" "${gravitySmallEN[@]}")
lookAhead=("${gravitySmallCR[@]}" "${_sR[@]}" "${_vR[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 右側が右に移動しないため開いた間隔を詰める処理 ----------------------------------------

# 左が右寄り、均等、中間、右が丸い、Vの大文字で 右が右寄り、均等、中間、Vの小文字の場合 Vの字 右に移動
backtrack=("${gravityCapitalMR[@]}" \
"${gravityCapitalRN[@]}" "${gravityCapitalEN[@]}" "${gravityCapitalVN[@]}" \
"${circleCapitalRR[@]}")
input=("${gravityVN[@]}")
lookAhead=("${gravitySmallRN[@]}" "${gravitySmallEN[@]}" "${gravitySmallMN[@]}" "${gravitySmallVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 左が EFKPRÞ で 右が右寄り、均等、中間、Vの小文字の場合 Vの大文字 右に移動
backtrack=("${_ER[@]}" "${_FR[@]}" "${_KR[@]}" "${_PR[@]}" "${_RR[@]}" "${_THR[@]}")
input=("${gravityCapitalVN[@]}")
lookAhead=("${gravitySmallRN[@]}" "${gravitySmallEN[@]}" "${gravitySmallMN[@]}" "${gravitySmallVN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"
index=`expr ${index} + 1`

# 再々調整 ========================================

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
{
  echo "<LookupType value=\"6\"/>"
  echo "<LookupFlag value=\"0\"/>"
} >> "${caltList}.txt"
index="0"

# 右側が元に戻って詰まった間隔を整える処理 ----------------------------------------

# 左が左寄り、均等、中間、Vの字で 右が左寄り、幅広、均等な文字の場合 幅広の文字 左に移動 (右に幅広の処理と統合)
backtrack=("${gravityLL[@]}" "${gravityEL[@]}" "${gravityML[@]}" "${gravityVL[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityWL[@]}" \
"${gravityWR[@]}" \
"${gravityLN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が、右が丸い小文字で 右が右寄り、丸い文字の場合 右寄り、丸い小文字 左に移動
backtrack=("${circleSmallRL[@]}" "${circleSmallCL[@]}")
input=("${gravitySmallRN[@]}" \
"${circleSmallCN[@]}")
lookAhead=("${gravityRN[@]}" \
"${circleCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 右に幅広が来た時に左側を詰める処理の続き ----------------------------------------

# 左が、左が丸い文字で 右が、右寄り、中間、Vの字の場合 幅広の文字 元に戻る
backtrack=("${circleLL[@]}" "${circleCL[@]}")
input=("${gravityWR[@]}")
lookAhead=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が、右が丸い、均等な文字で 右が、左右が丸い、均等な文字の場合 丸い、均等な文字 元の位置に戻る
backtrack=("${gravityER[@]}" \
"${circleRR[@]}" "${circleCR[@]}")
input=("${gravityER[@]}" \
"${circleCR[@]}")
lookAhead=("${gravityEN[@]}" \
"${circleRN[@]}" "${circleLN[@]}" "${circleCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左が均等な文字で 右が幅広の小文字の場合 左が丸い文字 左に移動
backtrack=("${gravityEN[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("${gravitySmallWL[@]}" \
"${gravitySmallWN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が均等な文字で 右が m の場合 左が丸い文字 左に移動
backtrack=("${gravityEN[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("${_mR[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# ---

# 左が中間の文字、Ww で 右が左寄りの文字、右寄り、均等な大文字の場合 右寄り、中間の小文字 元に戻る
backtrack=("${gravityMR[@]}" \
"${_WN[@]}" "${_wN[@]}")
input=("${gravitySmallRR[@]}" "${gravitySmallMR[@]}")
lookAhead=("${gravityLN[@]}" "${gravityCapitalRN[@]}" "${gravityCapitalEN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# ---

# 左が左寄り、右寄り、均等、中間の小文字で 右が左寄り、右寄り、均等、丸い小文字の場合 左寄り、均等、中間の小文字 左に移動
backtrack=("${gravitySmallLL[@]}" "${gravitySmallRL[@]}" "${gravitySmallEL[@]}" "${gravitySmallML[@]}")
input=("${gravitySmallLN[@]}" "${gravitySmallEN[@]}" "${gravitySmallMN[@]}")
lookAhead=("${gravitySmallLL[@]}" "${gravitySmallRL[@]}" "${gravitySmallEL[@]}" \
"${circleSmallCL[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が丸くない左寄り、丸くない中間の小文字で 右が左寄り、均等な小文字の場合 均等、中間の小文字 左に移動
backtrack=("${_hN[@]}" "${_kN[@]}" "${_kgN[@]}" "${_sN[@]}" "${_xN[@]}" "${_zN[@]}")
input=("${gravitySmallEN[@]}" "${gravitySmallMN[@]}")
lookAhead=("${gravitySmallLL[@]}" "${gravitySmallEL[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が丸くない左寄り、丸くない中間の小文字で 右が c 以外の右寄りの小文字の場合 均等な小文字 左に移動
backtrack=("${_hN[@]}" "${_kN[@]}" "${_kgN[@]}" "${_sN[@]}" "${_xN[@]}" "${_zN[@]}")
input=("${gravitySmallEN[@]}")
lookAhead=("${_aL[@]}" "${_dL[@]}" "${_gL[@]}" "${_qL[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が左寄り、右寄り、均等、中間の小文字で 右が左寄り、右寄り、均等、中間の小文字の場合 右寄りの小文字 左に移動
backtrack=("${gravitySmallLL[@]}" "${gravitySmallRL[@]}" "${gravitySmallEL[@]}" "${gravitySmallML[@]}" \
"${_hN[@]}" "${_kN[@]}" "${_kgN[@]}" "${_sN[@]}" "${_xN[@]}" "${_zN[@]}")
input=("${gravitySmallRN[@]}")
lookAhead=("${gravitySmallLL[@]}" "${gravitySmallRL[@]}" "${gravitySmallEL[@]}" "${gravitySmallML[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
index=`expr ${index} + 1`

# 左が左寄り、均等、中間の小文字で 右が幅広の小文字の場合 幅広の小文字 左に移動 (右側が元に戻った処理と統合)
 #backtrack=("${gravitySmallLL[@]}" "${gravitySmallEL[@]}" "${gravitySmallML[@]}")
 #input=("${gravitySmallWN[@]}")
 #lookAhead=("${gravitySmallWL[@]}" \
 #"${gravitySmallWR[@]}" \
 #"${gravitySmallWN[@]}")
 #chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"
 #index=`expr ${index} + 1`

# ---

# 右が右寄り、均等、中間の小文字の場合 左寄り、中間の小文字 元に戻る
backtrack=("")
input=("${gravitySmallLR[@]}" "${gravitySmallMR[@]}")
lookAhead=("${gravitySmallRL[@]}" "${gravitySmallEL[@]}" "${gravitySmallML[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右が左寄りの小文字の場合 左寄りの小文字 元に戻る
backtrack=("")
input=("${gravitySmallLR[@]}")
lookAhead=("${gravitySmallLN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 左側が元に戻って開いた間隔を整える処理 ----------------------------------------

# 左が cw で 右が右寄り、丸い小文字の場合 h 元に戻る
backtrack=("${_cN[@]}" "${_wN[@]}")
input=("${_hR[@]}")
lookAhead=("${gravitySmallRN[@]}" \
"${circleSmallCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

fi
# 記号類 ||||||||||||||||||||||||||||||||||||||||

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
{
  echo "<LookupType value=\"6\"/>"
  echo "<LookupFlag value=\"0\"/>"
} >> "${caltList}.txt"
index="0"

# |: に関する処理 ----------------------------------------

# 左が上下対称な演算子の場合 | 下に : 上に移動
backtrack=("${colonU[@]}" "${barD[@]}" "${greaterL[@]}" "${hyphenL[@]}" \
"${operatorHN[@]}" "${lessN[@]}" "${greaterN[@]}")
input=("${barN[@]}" "${colonN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"
index=`expr ${index} + 1`

# 右が上下対称な演算子の場合 | 下に : 上に移動
backtrack=("")
input=("${barN[@]}" "${colonN[@]}")
lookAhead=("${operatorHN[@]}" "${lessN[@]}" "${greaterN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"
index=`expr ${index} + 1`

# 右が : の場合 | 下に移動
backtrack=("")
input=("${barN[@]}")
lookAhead=("${colonN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"
index=`expr ${index} + 1`

# 右が | の場合 : 上に移動
backtrack=("")
input=("${colonN[@]}")
lookAhead=("${barN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"
index=`expr ${index} + 1`

# 両側が数字の場合 : 上に移動
backtrack=("${figureN[@]}")
input=("${colonN[@]}")
lookAhead=("${figureN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"
index=`expr ${index} + 1`

# ~ に関する処理 ----------------------------------------

# 左が < > の場合 ~ 下に移動
backtrack=("${tildeD[@]}" "${greaterL[@]}" \
"${lessN[@]}" "${greaterN[@]}")
input=("${tildeN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"
index=`expr ${index} + 1`

# 右が < > の場合 ~ 下に移動
backtrack=("")
input=("${tildeN[@]}")
lookAhead=("${lessN[@]}" "${greaterN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"
index=`expr ${index} + 1`

# < に関する処理 ----------------------------------------

# 右が - の場合 < 右に移動
backtrack=("")
input=("${lessN[@]}")
lookAhead=("${hyphenN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"
index=`expr ${index} + 1`

# > に関する処理 ----------------------------------------

# 左が - の場合 > 左に移動
backtrack=("${hyphenR[@]}" \
"${hyphenN[@]}")
input=("${greaterN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"
index=`expr ${index} + 1`

# - に関する処理の始め ----------------------------------------

# 左が < で 右が > の場合 - 移動しない
backtrack=("${lessR[@]}" \
"${lessN[@]}")
input=("${hyphenN[@]}")
lookAhead=("${greaterN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 右が > の場合 - 右に移動
backtrack=("")
input=("${hyphenN[@]}")
lookAhead=("${greaterN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"
index=`expr ${index} + 1`

# 左が、右が開いている文字、< の場合 - 左に移動
backtrack=("${lessR[@]}" \
"${lessN[@]}" \
"${midSpaceRL[@]}" "${midSpaceCL[@]}" \
"${midSpaceRN[@]}" "${midSpaceCN[@]}")
input=("${hyphenN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"
index=`expr ${index} + 1`

# reverse solidus に関する処理の始め ----------------------------------------

# 左が、右上が開いている文字、狭い文字、A の場合 reverse solidus 左に移動
backtrack=("${highSpaceRL[@]}" "${highSpaceCL[@]}" "${gravityCL[@]}" "${_AL[@]}" \
"${highSpaceRN[@]}" "${highSpaceCN[@]}" "${gravityCN[@]}" "${_AN[@]}")
input=("${rSolidusN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"
index=`expr ${index} + 1`

# solidus に関する処理の始め ----------------------------------------

# 左が、右下が開いている文字か W の場合 solidus 左に移動
backtrack=("${lowSpaceRL[@]}" "${lowSpaceCL[@]}" "${_WL[@]}" \
"${lowSpaceRN[@]}" "${lowSpaceCN[@]}" "${_WN[@]}")
input=("${solidusN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"
index=`expr ${index} + 1`

# 再調整 ========================================

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
{
  echo "<LookupType value=\"6\"/>"
  echo "<LookupFlag value=\"0\"/>"
} >> "${caltList}.txt"
index="0"

# |~: に関する処理 ----------------------------------------

# 右が |~ の場合 |~ 下に移動 (4個まで→3個まで)
member=("${barN[@]}" "${tildeN[@]}")
for T in ${member[@]}; do
  backtrack=("")
  input=("${T}")
  lookAhead=("${T}D")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"
  index=`expr ${index} + 1`
done

for T in ${member[@]}; do
  backtrack1=("")
  backtrack=("")
  input=("${T}")
  lookAhead=("${T}D" \
  "${T}")
  lookAhead1=("${T}D")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}" "${backtrack1[*]}" "${lookAhead1[*]}"
  index=`expr ${index} + 1`
done

 #for T in ${member[@]}; do
 #  backtrack1=("")
 #  backtrack=("")
 #  input=("${T}")
 #  lookAhead=("${T}D" \
 #  "${T}")
 #  lookAhead1=("${T}D" \
 #  "${T}")
 #  lookAheadX=("${T}D"); aheadMax="2"
 #  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "$ {aheadMax}"
 #  index=`expr ${index} + 1`
 #done

# 右が : の場合 : 上に移動 (4個まで→3個まで)
member=("${colonN[@]}")
for T in ${member[@]}; do
  backtrack=("")
  input=("${T}")
  lookAhead=("${T}U")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"
  index=`expr ${index} + 1`
done

for T in ${member[@]}; do
  backtrack1=("")
  backtrack=("")
  input=("${T}")
  lookAhead=("${T}U" \
  "${T}")
  lookAhead1=("${T}U")
  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}" "${backtrack1[*]}" "${lookAhead1[*]}"
  index=`expr ${index} + 1`
done

 #for T in ${member[@]}; do
 #  backtrack1=("")
 #  backtrack=("")
 #  input=("${T}")
 #  lookAhead=("${T}U" \
 #  "${T}")
 #  lookAhead1=("${T}U" \
 #  "${T}")
 #  lookAheadX=("${T}U"); aheadMax="2"
 #  chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "$ {aheadMax}"
 #  index=`expr ${index} + 1`
 #done

# - に関する処理の続き ----------------------------------------

# 右が、左が開いている文字の場合 - 右に移動
backtrack=("")
input=("${hyphenN[@]}")
lookAhead=("${midSpaceLR[@]}" "${midSpaceCR[@]}" \
"${midSpaceLN[@]}" "${midSpaceCN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"
index=`expr ${index} + 1`

# 右が、左が開いている文字、数字の場合 - 元に戻る
backtrack=("")
input=("${hyphenL[@]}")
lookAhead=("${midSpaceLR[@]}" "${midSpaceCR[@]}" \
"${midSpaceLN[@]}" "${midSpaceCN[@]}" "${figureN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# reverse solidus に関する処理の続き ----------------------------------------

# 右が、左下が開いている文字か W の場合 reverse solidus 右に移動
backtrack=("")
input=("${rSolidusN[@]}")
lookAhead=("${lowSpaceLR[@]}" "${lowSpaceCR[@]}" "${_WR[@]}" \
"${lowSpaceLN[@]}" "${lowSpaceCN[@]}" "${_WN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"
index=`expr ${index} + 1`

# 右が、左下が開いている文字か W の場合 reverse solidus 元に戻る
backtrack=("")
input=("${rSolidusL[@]}")
lookAhead=("${lowSpaceLR[@]}" "${lowSpaceCR[@]}" "${_WR[@]}" \
"${lowSpaceLN[@]}" "${lowSpaceCN[@]}" "${_WN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# solidus に関する処理の続き ----------------------------------------

# 右が、左上が開いている文字、狭い文字、A の場合 solidus 右に移動
backtrack=("")
input=("${solidusN[@]}")
lookAhead=("${highSpaceLR[@]}" "${highSpaceCR[@]}" "${gravityCR[@]}" "${_AR[@]}" \
"${highSpaceLN[@]}" "${highSpaceCN[@]}" "${gravityCN[@]}" "${_AN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"
index=`expr ${index} + 1`

# 右が、左上が開いている文字、狭い文字、A の場合 solidus 元に戻る
backtrack=("")
input=("${solidusL[@]}")
lookAhead=("${highSpaceLR[@]}" "${highSpaceCR[@]}" "${gravityCR[@]}" "${_AR[@]}" \
"${highSpaceLN[@]}" "${highSpaceCN[@]}" "${gravityCN[@]}" "${_AN[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 桁区切り設定作成 ||||||||||||||||||||||||||||||||||||||||

# 小数の処理 ----------------------------------------

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
{
  echo "<LookupType value=\"6\"/>"
  echo "<LookupFlag value=\"0\"/>"
} >> "${caltList}.txt"
index="0"

backtrack=("${fullStop[@]}")
input=("${figureN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex0}"
index=`expr ${index} + 1`

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
{
  echo "<LookupType value=\"6\"/>"
  echo "<LookupFlag value=\"0\"/>"
} >> "${caltList}.txt"
index="0"

backtrack=("${figure0[@]}")
input=("${figureN[@]}")
lookAhead=("")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex0}"
index=`expr ${index} + 1`

# 12桁マークを付ける処理 1 ----------------------------------------

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
{
  echo "<LookupType value=\"6\"/>"
  echo "<LookupFlag value=\"0\"/>"
} >> "${caltList}.txt"
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
{
  echo "<LookupType value=\"6\"/>"
  echo "<LookupFlag value=\"0\"/>"
} >> "${caltList}.txt"
index="0"

backtrack=("")
input=("${figure2[@]}")
lookAhead=("${figure2[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 12桁マークを付ける処理 2 ----------------------------------------

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
{
  echo "<LookupType value=\"6\"/>"
  echo "<LookupFlag value=\"0\"/>"
} >> "${caltList}.txt"
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
{
  echo "<LookupType value=\"6\"/>"
  echo "<LookupFlag value=\"0\"/>"
} >> "${caltList}.txt"
index="0"

backtrack=("")
input=("${figure2[@]}")
lookAhead=("${figure2[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 4桁マークを付ける処理 1 ----------------------------------------

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
{
  echo "<LookupType value=\"6\"/>"
  echo "<LookupFlag value=\"0\"/>"
} >> "${caltList}.txt"
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
{
  echo "<LookupType value=\"6\"/>"
  echo "<LookupFlag value=\"0\"/>"
} >> "${caltList}.txt"
index="0"

backtrack=("")
input=("${figure4[@]}")
lookAhead=("${figure4[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 4桁マークを付ける処理 2 ----------------------------------------

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
{
  echo "<LookupType value=\"6\"/>"
  echo "<LookupFlag value=\"0\"/>"
} >> "${caltList}.txt"
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
{
  echo "<LookupType value=\"6\"/>"
  echo "<LookupFlag value=\"0\"/>"
} >> "${caltList}.txt"
index="0"

backtrack=("")
input=("${figure4[@]}")
lookAhead=("${figure4[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 3桁マークを付ける処理 1 ----------------------------------------

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
{
  echo "<LookupType value=\"6\"/>"
  echo "<LookupFlag value=\"0\"/>"
} >> "${caltList}.txt"
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
{
  echo "<LookupType value=\"6\"/>"
  echo "<LookupFlag value=\"0\"/>"
} >> "${caltList}.txt"
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
{
  echo "<LookupType value=\"6\"/>"
  echo "<LookupFlag value=\"0\"/>"
} >> "${caltList}.txt"
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
{
  echo "<LookupType value=\"6\"/>"
  echo "<LookupFlag value=\"0\"/>"
} >> "${caltList}.txt"
index="0"

backtrack=("")
input=("${figure3[@]}")
lookAhead=("${figure3[@]}")
chain_context "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
index=`expr ${index} + 1`

# 2進数のみ4桁区切りを有効にする処理 ----------------------------------------

listNo=`expr ${listNo} + 1`
caltList="${caltL}_${listNo}"
{
  echo "<LookupType value=\"6\"/>"
  echo "<LookupFlag value=\"0\"/>"
} >> "${caltList}.txt"
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
