#!/bin/bash

# GSUB calt table maker
#
# Copyright (c) 2023 omonomo

# GSUB calt フィーチャテーブル作成プログラム
#
# 条件成立時に呼び出す異体字変換テーブルは font_generator にて生成済みであること

 #glyphNo="13706" # デフォルトのcalt用異体字の先頭glyphナンバー (Nerd Fontsなし)
glyphNo="22940" # デフォルトのcalt用異体字の先頭glyphナンバー (Nerd Fontsあり)
listNo="-1"
caltListName="caltList" # caltテーブルリストの名称
caltList="${caltListName}_${listNo}" # Lookupごとのcaltテーブルリスト
dict="dict" # 略字をグリフ名に変換する辞書
gsubList="gsubList" # 作成フォントのGSUBから抽出した置き換え用リスト
checkListName="checkList" # 設定の重複を避けるためのリストの名称

# lookup の IndexNo. (GSUBを変更すると変わる可能性あり)
lookupIndex_calt="18" # caltテーブルのlookupナンバー
num_calt_lookups="20" # calt のルックアップ数
lookupIndex_replace=$((lookupIndex_calt + num_calt_lookups)) # 単純置換のlookupナンバー
lookupIndexUD=${lookupIndex_replace} # 変換先(上下に移動させた記号のグリフ)
lookupIndexRR=$((lookupIndexUD + 1)) # 変換先(右に移動させた記号のグリフ)
lookupIndexLL=$((lookupIndexRR + 1)) # 変換先(左に移動させた記号のグリフ)
lookupIndex0=$((lookupIndexLL + 1)) # 変換先(小数のグリフ)
lookupIndex2=$((lookupIndex0 + 1)) # 変換先(12桁マークを付けたグリフ)
lookupIndex4=$((lookupIndex2 + 1)) # 変換先(4桁マークを付けたグリフ)
lookupIndex3=$((lookupIndex4 + 1)) # 変換先(3桁マークを付けたグリフ)
lookupIndexR=$((lookupIndex3 + 1)) # 変換先(右に移動させたグリフ)
lookupIndexL=$((lookupIndexR + 1)) # 変換先(左に移動させたグリフ)
lookupIndexN=$((lookupIndexL + 1)) # 変換先(ノーマルなグリフに戻す)

leaving_tmp_flag="false" # 一時ファイル残す
basic_only_flag="false" # 基本ラテン文字のみ
symbol_only_flag="false" # 記号、桁区切りのみ
optimize_flag="false" # なんちゃって最適化ルーチンを実行するか
optimize_no="3" # オプションが設定してある場合、指定の listNo 以下は最適化ルーチンを実行する
glyphNo_flag="false" # glyphナンバーの指定があるか

# エラー処理
trap "exit 3" HUP INT QUIT

# [@]なしで 同じ基底文字のメンバーを取得する関数 ||||||||||||||||||||||||||||||||||||||||

letter_members() {
  local class # 基底文字
  local member # 同じ基底文字を持つ文字のバリエーション (例: A À Á Â Ã Ä Å Ā Ă Ą) の配列
  local S
  class=("${2}")
  member=("")

  if [ -n "${class}" ]; then
    for S in ${class[@]}; do
      eval "member+=(\"\${${S}[@]}\")"
    done
    eval "${1}=\${member[@]}" # 戻り値を入れる変数名を1番目の引数に指定する
  fi
}

# Lookup を追加するための前処理をする関数 ||||||||||||||||||||||||||||||||||||||||

pre_add_lookup() {
  listNo=$((listNo + 1))
  caltList="${caltListName}_${listNo}"
  {
    echo "<LookupType value=\"6\"/>"
    echo "<LookupFlag value=\"0\"/>"
  } >> "${caltList}.txt"
  index="0"
  rm -f ${checkListName}*.txt
}

# グリフの略号を通し番号と名前に変換する関数 ||||||||||||||||||||||||||||||||||||||||

glyph_name() {
  echo $(grep " ${1} " "${dict}.txt" | head -n 1 | cut -d ' ' -f 1,3)
}

# グリフの通し番号と名前を backtrack、input、lookAhead の XML に変換する関数 ||||||||||||||||||||||||||||||||||||||||

glyph_value() {
  sort -n -u "${1}" | cut -d ' ' -f 2 | sed -E 's/([0-9a-zA-z]+)/<Glyph value="\1"\/>/g' # ソートしないとttxにしかられる
}

# LookupType 6 を作成するための関数 ||||||||||||||||||||||||||||||||||||||||

chain_context() {
  local substIndex # 設定番号
  local backtrack bt # 1文字前
  local input # 入力
  local lookAhead la # 1文字後
  local lookupIndex # ジャンプする(グリフを置換する)テーブル番号
  local backtrack1 bt1 # 2文字前
  local lookAhead1 la1 # 2文字後
  local lookAheadX laX # 3文字後以降
  local aheadMax # lookAheadのIndex2以降はその数(最大のIndexNo)を入れる(当然内容は全て同じになる)
  local overlap # 全ての設定が重複しているか
  local S T U V W X Y line0 line1
  substIndex="${2}"
  backtrack=("${3}")
  input=("${4}")
  lookAhead=("${5}")
  lookupIndex="${6}"
  backtrack1=("${7}")
  lookAhead1=("${8}")
  lookAheadX=("${9}")
  aheadMax="${10}"

  for S in "${fixedGlyphL[@]}" "${fixedGlyphR[@]}" "${fixedGlyphN[@]}"; do
    input=("${input[@]//${S}/}") # input から移動しないグリフを削除
  done
  input=("$(echo "${input[@]}" | tr ' ' '\n' | sort -u)") # 重複している配列要素を削除 (printf だとうまくいかない)
  backtrack=("$(echo "${backtrack[@]}" | tr ' ' '\n' | sort -u)")
  lookAhead=("$(echo "${lookAhead[@]}" | tr ' ' '\n' | sort -u)")
  backtrack1=("$(echo "${backtrack1[@]}" | tr ' ' '\n' | sort -u)")
  lookAhead1=("$(echo "${lookAhead1[@]}" | tr ' ' '\n' | sort -u)")
  lookAheadX=("$(echo "${lookAheadX[@]}" | tr ' ' '\n' | sort -u)")

# 重複している設定を削除 ====================

# input --------------------

if [ "${optimize_flag}" == "true" ] && [ ${listNo} -le ${optimize_no} ]; then
    for S in ${input[@]}; do # input の各グリフについて調査
      rm -f ${checkListName}*.tmp.txt
      overlap="true"
      if [ -n "${backtrack}" ]; then bt=("${backtrack[@]}"); else bt=("|"); fi
      for T in ${bt[@]}; do
        if [ -n "${lookAhead}" ]; then la=("${lookAhead[@]}"); else la=("|"); fi
        for U in ${la[@]}; do
          echo "${S},${T},${U},|,|,|" >> "${checkListName}.short.tmp.txt" # 前後2文字以上を省いた文字列を保存
          if [ -n "${backtrack1}" ]; then bt1=("${backtrack1[@]}"); else bt1=("|"); fi
          for V in ${bt1[@]}; do
            if [ -n "${lookAhead1}" ]; then la1=("${lookAhead1[@]}"); else la1=("|"); fi
            for W in ${la1[@]}; do
              if [ -n "${lookAheadX}" ]; then laX=("${lookAheadX[@]}"); else laX=("|"); fi
              for X in ${laX[@]}; do
                if [ "${bt1}${la1}${laX}" != "|||" ]; then
                  echo "${S},${T},${U},${V},${W},${X}" >> "${checkListName}.long.tmp.txt" # 前後2文字以上も含めた文字列を保存
                fi
              done # X
            done # W
          done # V
        done # U
      done # T

      if [[ ! -e "${checkListName}Short${S}.txt" ]]; then # 既設定ファイルがない場合は空のファイルを作成
        :>| "${checkListName}Short${S}.txt"
      fi
      while read line0; do
        Y=$(grep -x "${line0}" "${checkListName}Short${S}.txt") # 前後1文字のみで重複する設定がないかチェック
        if [ -z "${Y}" ]; then # 重複していない設定があった場合
          if [ -e "${checkListName}.long.tmp.txt" ]; then # 前後2文字以上参照する設定の場合は追試
            if [[ ! -e "${checkListName}Long${S}.txt" ]]; then # 既設定ファイルがない場合は空のファイルを作成
              :>| "${checkListName}Long${S}.txt"
            fi
            while read line1; do
              Y=$(grep -x "${line1}" "${checkListName}Long${S}.txt") # 前後2文字以上で重複する設定がないかチェック
              if [ -z "${Y}" ]; then # 重複していない設定があればチェックリストに追加して break
                overlap="false"
                cat "${checkListName}.long.tmp.txt" >> "${checkListName}Long${S}.txt"
                break 2
              fi # -z "${Y}" (前後2文字以上)
            done  < "${checkListName}.long.tmp.txt"
          else # -e "${checkListName}.long.tmp.txt" 前後1文字のみ参照の場合、追試なしでチェックリストに追加して break
            overlap="false"
            cat "${checkListName}.short.tmp.txt" >> "${checkListName}Short${S}.txt"
          fi # -e "${checkListName}.long.tmp.txt"
          break
        fi # -z "${Y}" (前後1文字のみ)
      done < "${checkListName}.short.tmp.txt" # 重複する設定がない場合、スルー

      if [ "${overlap}" == "true" ]; then # すでに設定が全て存在していた場合、input から重複したグリフを削除
        input=("${input[@]/${S}/}")
        echo "Removed input setting ${S//_/}"
      fi
    done # S

    if [ $(echo ${input} | wc -c) -le 1 ]; then # input のグリフが全て重複していた場合、設定を追加せず ruturn
      echo "Removed all settings, skip ${caltList} index ${substIndex}: Lookup = ${lookupIndex}"
      eval "${1}=\${substIndex}" # 戻り値を入れる変数名を1番目の引数に指定する
      return
    fi # (if 文について: test -z オプションだと他のスクリプトから呼び出したときにうまくいかない、同様に wc の結果も異なる)

# backtrack --------------------

    if [ -n "${backtrack}" ]; then # backtrack がある場合
      for S in ${backtrack[@]}; do # backtrack の各グリフについて調査
        rm -f ${checkListName}*.tmp.txt
        overlap="true"
        for T in ${input[@]}; do
          echo "${S},${T},|,|,|,|" >> "${checkListName}.backOnly.tmp.txt" # lookAhead がない設定のチェック用に保存
          if [ -n "${lookAhead}" ]; then la=("${lookAhead[@]}"); else la=("|"); fi
          for U in ${la[@]}; do
            if [ -n "${backtrack1}" ]; then bt1=("${backtrack1[@]}"); else bt1=("|"); fi
            for V in ${bt1[@]}; do
              if [ -n "${lookAhead1}" ]; then la1=("${lookAhead1[@]}"); else la1=("|"); fi
              for W in ${la1[@]}; do
                if [ -n "${lookAheadX}" ]; then laX=("${lookAheadX[@]}"); else laX=("|"); fi
                for X in ${laX[@]}; do
                  echo "${S},${T},${U},${V},${W},${X}" >> "${checkListName}.back.tmp.txt" # 前後2文字以上も含めた文字列を保存
                done # X
              done # W
            done # V
          done # U
        done # T

        if [[ ! -e "${checkListName}Back${S}.txt" ]]; then # 既設定ファイルがない場合は空のファイルを作成
          :>| "${checkListName}Back${S}.txt"
        fi
        while read line0; do
          Y=$(grep -x "${line0}" "${checkListName}Back${S}.txt") # lookAhead が無い設定がすでに存在しないかチェック
          if [ -z "${Y}" ]; then # lookAhead がない設定に抜けがあった場合追試
            while read line1; do
              Y=$(grep -x "${line1}" "${checkListName}Back${S}.txt") # 重複する設定がないかチェック
              if [ -z "${Y}" ]; then # 重複していない設定があった場合チェックリストに追加して break
                overlap="false"
                cat "${checkListName}.back.tmp.txt" >> "${checkListName}Back${S}.txt"
                break 2
              fi # -z "${Y}" (重複する設定)
            done < "${checkListName}.back.tmp.txt" # 重複する設定がない場合、何もせずに break
            break
          fi # -z "${Y}" (lookAhead が無い)
        done < "${checkListName}.backOnly.tmp.txt" # すでに lookAhead がない設定が全て存在した場合、スルー

        if [ "${overlap}" == "true" ]; then # すでに設定が全て存在していた場合、backtrack から重複したグリフを削除
          backtrack=("${backtrack[@]/${S}/}")
          echo "Removed backtrack setting ${S//_/}"
        fi
      done # S

      if [ "${bt}" != "|" ] && [ $(echo ${backtrack} | wc -c) -le 1 ]; then # backtrack のグリフが全て重複していた場合、設定を追加せず ruturn
        echo "Removed all settings, skip ${caltList} index ${substIndex}: Lookup = ${lookupIndex}"
        eval "${1}=\${substIndex}" # 戻り値を入れる変数名を1番目の引数に指定する
        return
      fi
    fi # -n "${backtrack}"

# lookAhead --------------------

    if [ -n "${lookAhead}" ]; then # lookAhead がある場合
      for S in ${lookAhead[@]}; do # lookAhead の各グリフについて調査
        rm -f ${checkListName}*.tmp.txt
        overlap="true"
        for T in ${input[@]}; do
          echo "${S},${T},|,|,|,|" >> "${checkListName}.aheadOnly.tmp.txt" # backtrack がない設定のチェック用に保存
          if [ -n "${backtrack}" ]; then bt=("${backtrack[@]}"); else bt=("|"); fi
          for U in ${bt[@]}; do
            if [ -n "${backtrack1}" ]; then bt1=("${backtrack1[@]}"); else bt1=("|"); fi
            for V in ${bt1[@]}; do
              if [ -n "${lookAhead1}" ]; then la1=("${lookAhead1[@]}"); else la1=("|"); fi
              for W in ${la1[@]}; do
                if [ -n "${lookAheadX}" ]; then laX=("${lookAheadX[@]}"); else laX=("|"); fi
                for X in ${laX[@]}; do
                  echo "${S},${T},${U},${V},${W},${X}" >> "${checkListName}.ahead.tmp.txt" # 前後2文字以上も含めた文字列を保存
                done # X
              done # W
            done # V
          done # U
        done # T

        if [[ ! -e "${checkListName}Ahead${S}.txt" ]]; then # 既設定ファイルがない場合は空のファイルを作成
          :>| "${checkListName}Ahead${S}.txt"
        fi
        while read line0; do
          Y=$(grep -x "${line0}" "${checkListName}Ahead${S}.txt") # backtrack が無い設定がすでに存在しないかチェック
          if [ -z "${Y}" ]; then # backtrack がない設定に抜けがあった場合追試
            while read line1; do
              Y=$(grep -x "${line1}" "${checkListName}Ahead${S}.txt") # 重複する設定がないかチェック
              if [ -z "${Y}" ]; then # 重複していない設定があった場合チェックリストに追加して break
                overlap="false"
                cat "${checkListName}.ahead.tmp.txt" >> "${checkListName}Ahead${S}.txt"
                break 2
              fi # -z "${Y}" (重複する設定)
            done < "${checkListName}.ahead.tmp.txt" # 重複する設定がない場合、何もせずに break
            break
          fi # -z "${Y}" (lookAhead が無い)
        done < "${checkListName}.aheadOnly.tmp.txt" # すでに backtrack がない設定が全て存在した場合、スルー

        if [ "${overlap}" == "true" ]; then # すでに設定が全て存在していた場合、lookAhead から重複したグリフを削除
          lookAhead=("${lookAhead[@]/${S}/}")
          echo "Removed lookAhead setting ${S//_/}"
        fi
      done # S

      if [ "${la}" != "|" ] && [ $(echo ${lookAhead} | wc -c) -le 1 ]; then # lookAhead のグリフが全て重複していた場合、設定を追加せず ruturn
        echo "Removed all settings, skip ${caltList} index ${substIndex}: Lookup = ${lookupIndex}"
        eval "${1}=\${substIndex}" # 戻り値を入れる変数名を1番目の引数に指定する
        return
      fi
    fi # -n "${lookAhead}"

  fi

# 設定追加 ====================

  echo "Make ${caltList} index ${substIndex}: Lookup = ${lookupIndex}"

  echo "<ChainContextSubst index=\"${substIndex}\" Format=\"3\">" >> "${caltList}.txt"

# backtrack --------------------

  if [ -n "${backtrack}" ]; then # 入力した文字の左側
    letter_members "backtrack" "${backtrack[*]}"
    rm -f ${caltListName}.tmp.txt
    for S in ${backtrack[@]}; do
      glyph_name "${S}" >> "${caltListName}.tmp.txt" # 略号から通し番号とグリフ名を取得
    done
    {
      echo "<BacktrackCoverage index=\"0\">"
      glyph_value "${caltListName}.tmp.txt" # 通し番号とグリフ名から XML を取得
      echo "</BacktrackCoverage>"
    } >> "${caltList}.txt"
  fi

  if [ -n "${backtrack1}" ]; then # 入力した文字の左側2つ目
    letter_members "backtrack1" "${backtrack1[*]}"
    rm -f ${caltListName}.tmp.txt
    for S in ${backtrack1[@]}; do
      glyph_name "${S}" >> "${caltListName}.tmp.txt"
    done
    {
      echo "<BacktrackCoverage index=\"0\">"
      glyph_value "${caltListName}.tmp.txt"
      echo "</BacktrackCoverage>"
    } >> "${caltList}.txt"
  fi

# input --------------------

  letter_members "input" "${input[*]}"
  rm -f ${caltListName}.tmp.txt
  for S in ${input[@]}; do
    glyph_name "${S}" >> "${caltListName}.tmp.txt"
  done
  {
    echo "<InputCoverage index=\"0\">" # 入力した文字(グリフ変換対象)
    glyph_value "${caltListName}.tmp.txt"
    echo "</InputCoverage>"
  } >> "${caltList}.txt"

# lookAhead --------------------

  if [ -n "${lookAhead}" ]; then # 入力した文字の右側
    letter_members "lookAhead" "${lookAhead[*]}"
    rm -f ${caltListName}.tmp.txt
    for S in ${lookAhead[@]}; do
      glyph_name "${S}" >> "${caltListName}.tmp.txt"
    done
    {
      echo "<LookAheadCoverage index=\"0\">"
      glyph_value "${caltListName}.tmp.txt"
      echo "</LookAheadCoverage>"
    } >> "${caltList}.txt"
  fi

  if [ -n "${lookAhead1}" ]; then # 入力した文字の右側2つ目
    letter_members "lookAhead1" "${lookAhead1[*]}"
    rm -f ${caltListName}.tmp.txt
    for S in ${lookAhead1[@]}; do
      glyph_name "${S}" >> "${caltListName}.tmp.txt"
    done
    {
      echo "<LookAheadCoverage index=\"0\">"
      glyph_value "${caltListName}.tmp.txt"
      echo "</LookAheadCoverage>"
    } >> "${caltList}.txt"
  fi

  if [ -n "${lookAheadX}" ]; then # 入力した文字の右側3つ目以降
    letter_members "lookAheadX" "${lookAheadX[*]}"
    for i in $(seq 2 "${aheadMax}"); do
      rm -f ${caltListName}.tmp.txt
      for S in ${lookAheadX[@]}; do
        glyph_name "${S}" >> "${caltListName}.tmp.txt"
      done
      {
        echo "<LookAheadCoverage index=\"0\">"
        glyph_value "${caltListName}.tmp.txt"
        echo "</LookAheadCoverage>"
      } >> "${caltList}.txt"
      done
    fi

# lookupIndex --------------------

  {
    echo "<SubstLookupRecord index=\"0\">"
    echo "<SequenceIndex value=\"0\"/>"
    echo "<LookupListIndex value=\"${lookupIndex}\"/>"
    echo "</SubstLookupRecord>"

    echo "</ChainContextSubst>"
  } >> "${caltList}.txt" # 条件がそろった時にジャンプするテーブル番号

  eval "${1}=\$((substIndex + 1))" # 戻り値を入れる変数名を1番目の引数に指定する
}

# 一時作成ファイルを削除する関数 ||||||||||||||||||||||||||||||||||||||||

remove_temp() {
  echo "Remove temporary files"
  rm -f ${dict}.txt
  rm -f ${checkListName}*.txt
}

# ヘルプを表示する関数 ||||||||||||||||||||||||||||||||||||||||

calt_table_maker_help()
{
    echo "Usage: calt_table_maker.sh [options]"
    echo ""
    echo "Options:"
    echo "  -h         Display this information"
    echo "  -x         Cleaning temporary files" # 一時作成ファイルの消去のみ
    echo "  -l         Leave (do NOT remove) temporary files"
    echo "  -n number  Set glyph number of \"A moved left\""
    echo "  -b         Make kerning settings for basic Latin characters only"
    echo "  -s         Don't Make calt settings for Latin characters"
    echo "  -o         Enable optimization process"
    exit 0
}

# メイン ||||||||||||||||||||||||||||||||||||||||

echo
echo "- GSUB table [calt, LookupType 6] maker -"
echo

# Get options
while getopts hxln:bso OPT
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
        "o" )
            echo "Option: Enable optimization process"
            optimize_flag="true"
            ;;
        * )
            exit 1
            ;;
    esac
done
echo

if [ "${glyphNo_flag}" = "false" ]; then
  gsubList_txt=$(find . -name "${gsubList}.txt" -maxdepth 1 | head -n 1)
  if [ -n "${gsubList_txt}" ]; then # gsubListがあり、
    echo "Found GSUB List"
    caltNo=$(grep 'Substitution in="A"' "${gsubList}.txt")
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
rm -f ${caltListName}*.txt
rm -f ${dict}.txt

# グリフ名変換用辞書作成 (グリフのIDS順に並べること) ||||||||||||||||||||||||||||||||||||||||

# 略号と名前 ----------------------------------------

quotedbl=("QTD") # 直接扱えない記号
number=("NUM")
dollar=("DOL")
percent=("PCT")
and=("AND")
asterisk=("AST")
plus=("PLS")
hyphen=("HYP")
fullStop=("DOT")
solidus=("SLH")
parenLeft=("LPN")
parenRight=("RPN")
symbol2x=("!" "${quotedbl}" "${number}" "${dollar}" "${percent}" "${and}" "'" \
"${parenLeft}" "${parenRight}" "${asterisk}" "${plus}" "," "${hyphen}" "${fullStop}" "${solidus}")
symbol2x_name=("exclam" "quotedbl" "numbersign" "dollar" "percent" "ampersand" "quotesingle" \
"parenleft" "parenright" "asterisk" "plus" "comma" "hyphen" "period" "slash")

figure=(0 1 2 3 4 5 6 7 8 9)
figure_name=("zero" "one" "two" "three" "four" "five" "six" "seven" "eight" "nine")

colon=("CLN") # 単独で変数を使用するため他と分けて代入
less=("LES")
equal=("EQL")
greater=("GRT")
symbol3x=("${colon}" ";" "${less}" "${equal}" "${greater}" "?")
symbol3x_name=("colon" "semicolon" "less" "equal" "greater" "question")

at=("ATT")
symbol4x=("${at}")
symbol4x_name=("at")

# グリフ略号 (A B..y z, AL BL..yL zL, AR BR..yR zR 通常のグリフ、左に移動したグリフ、右に移動したグリフ)
# グリフ名 (A B..y z, glyphXXXXX..glyphYYYYY)
latin45=(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) # 略号の始めの文字
latin45_name=("${latin45[@]}")

bracketLeft=("LBK") # 単独で変数を使用するため他と分けて代入
rSolidus=("BSH")
bracketRight=("RBK")
grave=("GRV")
symbol5x=("${bracketLeft}" "${rSolidus}" "${bracketRight}" "^" "_" "${grave}")
symbol5x_name=("bracketleft" "backslash" "bracketright" "asciicircum" "underscore" "grave")

latin67=(a b c d e f g h i j k l m n o p q r s t u v w x y z) # 略号の始めの文字
latin67_name=("${latin67[@]}")

braceLeft=("LBC") # 単独で変数を使用するため他と分けて代入
bar=("BAR")
braceRight=("RBC")
tilde=("TLD")
symbol7x=("${braceLeft}" "${bar}" "${braceRight}" "${tilde}")
symbol7x_name=("braceleft" "bar" "braceright" "asciitilde")

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
  echo "$i ${word[j]}N ${name[j]}" >> "${dict}.txt"
  i=$((i + 1))
done

word=("${latin45[@]}") # A-Z
name=("${latin45_name[@]}")
for j in ${!word[@]}; do
  echo "$i ${word[j]}N ${name[j]}" >> "${dict}.txt"
  i=$((i + 1))
done

word=("${symbol5x[@]}") # 記号
name=("${symbol5x_name[@]}")
for j in ${!word[@]}; do
  echo "$i ${word[j]}N ${name[j]}" >> "${dict}.txt"
  i=$((i + 1))
done

word=("${latin67[@]}") # a-z
name=("${latin67_name[@]}")
for j in ${!word[@]}; do
  echo "$i ${word[j]}N ${name[j]}" >> "${dict}.txt"
  i=$((i + 1))
done

word=("${symbol7x[@]}") # 記号
name=("${symbol7x_name[@]}")
for j in ${!word[@]}; do
  echo "$i ${word[j]}N ${name[j]}" >> "${dict}.txt"
  i=$((i + 1))
done

word=("${latinCx[@]}") # À-Å
name=("${latinCx_name[@]}")
for j in ${!word[@]}; do
  echo "$i ${word[j]}N ${name[j]}" >> "${dict}.txt"
  i=$((i + 1))
done

echo "$i ${latinCy}N ${latinCy_name}" >> "${dict}.txt" # Æ
i=$((i + 1))
echo "$i ${latinCy}L ${latinCy_name}" >> "${dict}.txt" # Æ は移動しないため
i=$((i + 1))
echo "$i ${latinCy}R ${latinCy_name}" >> "${dict}.txt" # Æ は移動しないため
i=$((i + 1))

word=("${latinCz[@]}" "${latinDx[@]}" "${latinEx[@]}") # Ç-å
name=("${latinCz_name[@]}" "${latinDx_name[@]}" "${latinEx_name[@]}")
for j in ${!word[@]}; do
  echo "$i ${word[j]}N ${name[j]}" >> "${dict}.txt"
  i=$((i + 1))
done

echo "$i ${latinEy}N ${latinEy_name}" >> "${dict}.txt" # æ
i=$((i + 1))
echo "$i ${latinEy}L ${latinEy_name}" >> "${dict}.txt" # æ は移動しないため
i=$((i + 1))
echo "$i ${latinEy}R ${latinEy_name}" >> "${dict}.txt" # æ は移動しないため
i=$((i + 1))

word=("${latinEz[@]}" "${latinFx[@]}" "${latin10x[@]}" "${latin11x[@]}" \
"${latin12x[@]}" "${latin13x[@]}" "${latin14x[@]}" "${latin15x[@]}") # ç-ő
name=("${latinEz_name[@]}" "${latinFx_name[@]}" "${latin10x_name[@]}" "${latin11x_name[@]}" \
"${latin12x_name[@]}" "${latin13x_name[@]}" "${latin14x_name[@]}" "${latin15x_name[@]}")
for j in ${!word[@]}; do
  echo "$i ${word[j]}N ${name[j]}" >> "${dict}.txt"
  i=$((i + 1))
done

for j in ${!latin15y[@]}; do # Œ œ
  echo "$i ${latin15y[j]}N ${latin15y_name[j]}" >> "${dict}.txt"
  i=$((i + 1))
  echo "$i ${latin15y[j]}L ${latin15y_name[j]}" >> "${dict}.txt" # Œ œ は移動しないため
  i=$((i + 1))
  echo "$i ${latin15y[j]}R ${latin15y_name[j]}" >> "${dict}.txt" # Œ œ は移動しないため
  i=$((i + 1))
done

word=("${latin15z[@]}" "${latin16x[@]}" "${latin17x[@]}" "${latin21x[@]}" "${latin1E9x[@]}") # Ŕ-ẞ
name=("${latin15z_name[@]}" "${latin16x_name[@]}" "${latin17x_name[@]}" "${latin21x_name[@]}" "${latin1E9x_name[@]}")
for j in ${!word[@]}; do
  echo "$i ${word[j]}N ${name[j]}" >> "${dict}.txt"
  i=$((i + 1))
done

# 左に移動した文字 ----------------------------------------

word=("${latin45[@]}" "${latin67[@]}" \
"${latinCx[@]}" "${latinCz[@]}" "${latinDx[@]}" "${latinEx[@]}" "${latinEz[@]}" "${latinFx[@]}" \
"${latin10x[@]}" "${latin11x[@]}" "${latin12x[@]}" "${latin13x[@]}" "${latin14x[@]}" "${latin15x[@]}" "${latin15z[@]}" \
"${latin16x[@]}" "${latin17x[@]}" "${latin21x[@]}" "${latin1E9x[@]}") # A-ẞ

i=${glyphNo}

for S in ${word[@]}; do
  echo "$i ${S}L glyph${i}" >> "${dict}.txt"
  i=$((i + 1))
done

# 右に移動した文字 ----------------------------------------

for S in ${word[@]}; do
  echo "$i ${S}R glyph${i}" >> "${dict}.txt"
  i=$((i + 1))
done

# 3桁マークの付いた数字 ----------------------------------------

word=("${figure[@]}") # 0-9

for S in ${word[@]}; do
  echo "$i ${S}3 glyph${i}" >> "${dict}.txt"
  i=$((i + 1))
done

# 4桁マークの付いた数字 ----------------------------------------

for S in ${word[@]}; do
  echo "$i ${S}4 glyph${i}" >> "${dict}.txt"
  i=$((i + 1))
done

# 12桁マークの付いた数字 ----------------------------------------

for S in ${word[@]}; do
  echo "$i ${S}2 glyph${i}" >> "${dict}.txt"
  i=$((i + 1))
done

# 小数の数字 ----------------------------------------

for S in ${word[@]}; do
  echo "$i ${S}0 glyph${i}" >> "${dict}.txt"
  i=$((i + 1))
done

# 左に移動した記号 ----------------------------------------

word=("${hyphen}" "${solidus}" "${less}" "${greater}" "${rSolidus}")

for S in ${word[@]}; do
  echo "$i ${S}L glyph${i}" >> "${dict}.txt"
  i=$((i + 1))
done

# 右に移動した記号 ----------------------------------------

for S in ${word[@]}; do
  echo "$i ${S}R glyph${i}" >> "${dict}.txt"
  i=$((i + 1))
done

# 下に移動した記号 ----------------------------------------

word=("${bar}" "${tilde}") # | ~

for S in ${word[@]}; do
  echo "$i ${S}D glyph${i}" >> "${dict}.txt"
  i=$((i + 1))
done

# 上に移動した記号 ----------------------------------------

word=("${colon}" "${asterisk}" "+" "${hyphen}" "=") # :

for S in ${word[@]}; do
  echo "$i ${S}U glyph${i}" >> "${dict}.txt"
  i=$((i + 1))
done

# 略号のグループ作成 ||||||||||||||||||||||||||||||||||||||||

# ラテン文字 (ここで定義した変数は直接使用しないこと) ====================
class=("")

if [ "${basic_only_flag}" = "true" ]; then
  S="_A_"; class+=("${S}"); eval ${S}=\(A\) # A
  S="_B_"; class+=("${S}"); eval ${S}=\(B\) # B
  S="_C_"; class+=("${S}"); eval ${S}=\(C\) # C
  S="_D_"; class+=("${S}"); eval ${S}=\(D\) # D
  S="_E_"; class+=("${S}"); eval ${S}=\(E\) # E
  S="_F_"; class+=("${S}"); eval ${S}=\(F\) # F
  S="_G_"; class+=("${S}"); eval ${S}=\(G\) # G
  S="_H_"; class+=("${S}"); eval ${S}=\(H\) # H
  S="_I_"; class+=("${S}"); eval ${S}=\(I\) # I
  S="_J_"; class+=("${S}"); eval ${S}=\(J\) # J
  S="_K_"; class+=("${S}"); eval ${S}=\(K\) # K
  S="_L_"; class+=("${S}"); eval ${S}=\(L\) # L
  S="_M_"; class+=("${S}"); eval ${S}=\(M\) # M
  S="_N_"; class+=("${S}"); eval ${S}=\(N\) # N
  S="_O_"; class+=("${S}"); eval ${S}=\(O\) # O
  S="_P_"; class+=("${S}"); eval ${S}=\(P\) # P
  S="_Q_"; class+=("${S}"); eval ${S}=\(Q\) # Q
  S="_R_"; class+=("${S}"); eval ${S}=\(R\) # R
  S="_S_"; class+=("${S}"); eval ${S}=\(S\) # S
  S="_T_"; class+=("${S}"); eval ${S}=\(T\) # T
  S="_U_"; class+=("${S}"); eval ${S}=\(U\) # U
  S="_V_"; class+=("${S}"); eval ${S}=\(V\) # V
  S="_W_"; class+=("${S}"); eval ${S}=\(W\) # W
  S="_X_"; class+=("${S}"); eval ${S}=\(X\) # X
  S="_Y_"; class+=("${S}"); eval ${S}=\(Y\) # Y
  S="_Z_"; class+=("${S}"); eval ${S}=\(Z\) # Z
 #  S="_AE_"; class+=("${S}"); eval ${S}=\(Æ\) # Æ エラーが出る場合はコメントアウト解除
 #  S="_OE_"; class+=("${S}"); eval ${S}=\(Œ\) # Œ
 #  S="_TH_"; class+=("${S}"); eval ${S}=\(Þ\) # Þ

  S="__a"; class+=("${S}"); eval ${S}=\(a\) # a # 設定の重複チェック用ファイル作成時に区別するため
  S="__b"; class+=("${S}"); eval ${S}=\(b\) # b # 変数の命名規則を大文字と小文字で変える
  S="__c"; class+=("${S}"); eval ${S}=\(c\) # c # (APFS だと通常ファイル名の大文字と小文字を区別しないため)
  S="__d"; class+=("${S}"); eval ${S}=\(d\) # d
  S="__e"; class+=("${S}"); eval ${S}=\(e\) # e
  S="__f"; class+=("${S}"); eval ${S}=\(f\) # f
  S="__g"; class+=("${S}"); eval ${S}=\(g\) # g
  S="__h"; class+=("${S}"); eval ${S}=\(h\) # h
  S="__i"; class+=("${S}"); eval ${S}=\(i\) # i
  S="__j"; class+=("${S}"); eval ${S}=\(j\) # j
  S="__k"; class+=("${S}"); eval ${S}=\(k\) # k
  S="__l"; class+=("${S}"); eval ${S}=\(l\) # l
  S="__m"; class+=("${S}"); eval ${S}=\(m\) # m
  S="__n"; class+=("${S}"); eval ${S}=\(n\) # n
  S="__o"; class+=("${S}"); eval ${S}=\(o\) # o
  S="__p"; class+=("${S}"); eval ${S}=\(p\) # p
  S="__q"; class+=("${S}"); eval ${S}=\(q\) # q
  S="__r"; class+=("${S}"); eval ${S}=\(r\) # r
  S="__s"; class+=("${S}"); eval ${S}=\(s\) # s
  S="__t"; class+=("${S}"); eval ${S}=\(t\) # t
  S="__u"; class+=("${S}"); eval ${S}=\(u\) # u
  S="__v"; class+=("${S}"); eval ${S}=\(v\) # v
  S="__w"; class+=("${S}"); eval ${S}=\(w\) # w
  S="__x"; class+=("${S}"); eval ${S}=\(x\) # x
  S="__y"; class+=("${S}"); eval ${S}=\(y\) # y
  S="__z"; class+=("${S}"); eval ${S}=\(z\) # z
 #  S="__ae"; class+=("${S}"); eval ${S}=\(æ\) # æ エラーが出る場合はコメントアウト解除
 #  S="__oe"; class+=("${S}"); eval ${S}=\(œ\) # œ
 #  S="__th"; class+=("${S}"); eval ${S}=\(þ\) # þ
 #  S="__ss"; class+=("${S}"); eval ${S}=\(ß\) # ß
 #  S="__kg"; class+=("${S}"); eval ${S}=\(ĸ\) # ĸ
else
  S="_A_"; class+=("${S}"); eval ${S}=\(A À Á Â Ã Ä Å Ā Ă Ą\) # A
  S="_B_"; class+=("${S}"); eval ${S}=\(B ẞ ß\) # B ẞ ß
 #  S="_B_"; class+=("${S}"); eval ${S}=\(B ẞ\) # B ẞ
  S="_C_"; class+=("${S}"); eval ${S}=\(C Ç Ć Ĉ Ċ Č\) # C
  S="_D_"; class+=("${S}"); eval ${S}=\(D Ď Đ Ð\) # D Ð
  S="_E_"; class+=("${S}"); eval ${S}=\(E È É Ê Ë Ē Ĕ Ė Ę Ě\) # E
  S="_F_"; class+=("${S}"); eval ${S}=\(F\) # F
  S="_G_"; class+=("${S}"); eval ${S}=\(G Ĝ Ğ Ġ Ģ\) # G
  S="_H_"; class+=("${S}"); eval ${S}=\(H Ĥ Ħ\) # H
  S="_I_"; class+=("${S}"); eval ${S}=\(I Ì Í Î Ï Ĩ Ī Ĭ Į İ\) # I
  S="_J_"; class+=("${S}"); eval ${S}=\(J Ĵ\) # J
  S="_K_"; class+=("${S}"); eval ${S}=\(K Ķ\) # K
  S="_L_"; class+=("${S}"); eval ${S}=\(L Ĺ Ļ Ľ Ŀ Ł\) # L
  S="_M_"; class+=("${S}"); eval ${S}=\(M\) # M
  S="_N_"; class+=("${S}"); eval ${S}=\(N Ñ Ń Ņ Ň Ŋ\) # N
  S="_O_"; class+=("${S}"); eval ${S}=\(O Ò Ó Ô Õ Ö Ø Ō Ŏ Ő\) # O
  S="_P_"; class+=("${S}"); eval ${S}=\(P\) # P
  S="_Q_"; class+=("${S}"); eval ${S}=\(Q\) # Q
  S="_R_"; class+=("${S}"); eval ${S}=\(R Ŕ Ŗ Ř\) # R
  S="_S_"; class+=("${S}"); eval ${S}=\(S Ś Ŝ Ş Š Ș\) # S
  S="_T_"; class+=("${S}"); eval ${S}=\(T Ţ Ť Ŧ Ț\) # T
  S="_U_"; class+=("${S}"); eval ${S}=\(U Ù Ú Û Ü Ũ Ū Ŭ Ů Ű Ų\) # U
  S="_V_"; class+=("${S}"); eval ${S}=\(V\) # V
  S="_W_"; class+=("${S}"); eval ${S}=\(W Ŵ\) # W
  S="_X_"; class+=("${S}"); eval ${S}=\(X\) # X
  S="_Y_"; class+=("${S}"); eval ${S}=\(Y Ý Ÿ Ŷ\) # Y
  S="_Z_"; class+=("${S}"); eval ${S}=\(Z Ź Ż Ž\) # Z
  S="_AE_"; class+=("${S}"); eval ${S}=\(Æ\) # Æ
  S="_OE_"; class+=("${S}"); eval ${S}=\(Œ\) # Œ
  S="_TH_"; class+=("${S}"); eval ${S}=\(Þ\) # Þ

  S="__a"; class+=("${S}"); eval ${S}=\(a à á â ã ä å ā ă ą\) # a
  S="__b"; class+=("${S}"); eval ${S}=\(b\) # b
  S="__c"; class+=("${S}"); eval ${S}=\(c ç ć ĉ ċ č\) # c
  S="__d"; class+=("${S}"); eval ${S}=\(d ď đ\) # d
  S="__e"; class+=("${S}"); eval ${S}=\(e è é ê ë ē ĕ ė ę ě\) # e
  S="__f"; class+=("${S}"); eval ${S}=\(f\) # f
  S="__g"; class+=("${S}"); eval ${S}=\(g ĝ ğ ġ ģ\) # g
  S="__h"; class+=("${S}"); eval ${S}=\(h ĥ ħ\) # h
  S="__i"; class+=("${S}"); eval ${S}=\(i ì í î ï ĩ ī ĭ į ı\) # i
  S="__j"; class+=("${S}"); eval ${S}=\(j ĵ\) # j
  S="__k"; class+=("${S}"); eval ${S}=\(k ķ\) # k
  S="__l"; class+=("${S}"); eval ${S}=\(l ĺ ļ ľ ŀ ł\) # l
  S="__m"; class+=("${S}"); eval ${S}=\(m\) # m
  S="__n"; class+=("${S}"); eval ${S}=\(n ñ ń ņ ň ŋ\) # n
  S="__o"; class+=("${S}"); eval ${S}=\(o ò ó ô õ ö ø ō ŏ ő ð\) # o ð
  S="__p"; class+=("${S}"); eval ${S}=\(p\) # p
  S="__q"; class+=("${S}"); eval ${S}=\(q\) # q
  S="__r"; class+=("${S}"); eval ${S}=\(r ŕ ŗ ř\) # r
  S="__s"; class+=("${S}"); eval ${S}=\(s ś ŝ ş š ș\) # s
  S="__t"; class+=("${S}"); eval ${S}=\(t ţ ť ŧ ț\) # t
  S="__u"; class+=("${S}"); eval ${S}=\(u ù ú û ü ũ ū ŭ ů ű ų\) # u
  S="__v"; class+=("${S}"); eval ${S}=\(v\) # v
  S="__w"; class+=("${S}"); eval ${S}=\(w ŵ\) # w
  S="__x"; class+=("${S}"); eval ${S}=\(x\) # x
  S="__y"; class+=("${S}"); eval ${S}=\(y ý ÿ ŷ\) # y
  S="__z"; class+=("${S}"); eval ${S}=\(z ź ż ž\) # z
  S="__ae"; class+=("${S}"); eval ${S}=\(æ\) # æ
  S="__oe"; class+=("${S}"); eval ${S}=\(œ\) # œ
  S="__th"; class+=("${S}"); eval ${S}=\(þ\) # þ
 #  S="__ss"; class+=("${S}"); eval ${S}=\(ß\) # ß
  S="__kg"; class+=("${S}"); eval ${S}=\(ĸ\) # ĸ
fi

# ラテン文字単独 ====================

S="_A"; class+=("${S}"); eval ${S}=\(_A_\) # A
S="_B"; class+=("${S}"); eval ${S}=\(_B_\) # B
S="_C"; class+=("${S}"); eval ${S}=\(_C_\) # C
S="_D"; class+=("${S}"); eval ${S}=\(_D_\) # D
S="_E"; class+=("${S}"); eval ${S}=\(_E_\) # E
S="_F"; class+=("${S}"); eval ${S}=\(_F_\) # F
S="_G"; class+=("${S}"); eval ${S}=\(_G_\) # G
S="_H"; class+=("${S}"); eval ${S}=\(_H_\) # H
S="_I"; class+=("${S}"); eval ${S}=\(_I_\) # I
S="_J"; class+=("${S}"); eval ${S}=\(_J_\) # J
S="_K"; class+=("${S}"); eval ${S}=\(_K_\) # K
S="_L"; class+=("${S}"); eval ${S}=\(_L_\) # L
S="_M"; class+=("${S}"); eval ${S}=\(_M_\) # M
S="_N"; class+=("${S}"); eval ${S}=\(_N_\) # N
S="_O"; class+=("${S}"); eval ${S}=\(_O_\) # O
S="_P"; class+=("${S}"); eval ${S}=\(_P_\) # P
S="_Q"; class+=("${S}"); eval ${S}=\(_Q_\) # Q
S="_R"; class+=("${S}"); eval ${S}=\(_R_\) # R
S="_S"; class+=("${S}"); eval ${S}=\(_S_\) # S
S="_T"; class+=("${S}"); eval ${S}=\(_T_\) # T
S="_U"; class+=("${S}"); eval ${S}=\(_U_\) # U
S="_V"; class+=("${S}"); eval ${S}=\(_V_\) # V
S="_W"; class+=("${S}"); eval ${S}=\(_W_\) # W
S="_X"; class+=("${S}"); eval ${S}=\(_X_\) # X
S="_Y"; class+=("${S}"); eval ${S}=\(_Y_\) # Y
S="_Z"; class+=("${S}"); eval ${S}=\(_Z_\) # Z
S="_AE"; class+=("${S}"); eval ${S}=\(_AE_\) # Æ
S="_OE"; class+=("${S}"); eval ${S}=\(_OE_\) # Œ
S="_TH"; class+=("${S}"); eval ${S}=\(_TH_\) # Þ

S="_a"; class+=("${S}"); eval ${S}=\(__a\) # a
S="_b"; class+=("${S}"); eval ${S}=\(__b\) # b
S="_c"; class+=("${S}"); eval ${S}=\(__c\) # c
S="_d"; class+=("${S}"); eval ${S}=\(__d\) # d
S="_e"; class+=("${S}"); eval ${S}=\(__e\) # e
S="_f"; class+=("${S}"); eval ${S}=\(__f\) # f
S="_g"; class+=("${S}"); eval ${S}=\(__g\) # g
S="_h"; class+=("${S}"); eval ${S}=\(__h\) # h
S="_i"; class+=("${S}"); eval ${S}=\(__i\) # i
S="_j"; class+=("${S}"); eval ${S}=\(__j\) # j
S="_k"; class+=("${S}"); eval ${S}=\(__k\) # k
S="_l"; class+=("${S}"); eval ${S}=\(__l\) # l
S="_m"; class+=("${S}"); eval ${S}=\(__m\) # m
S="_n"; class+=("${S}"); eval ${S}=\(__n\) # n
S="_o"; class+=("${S}"); eval ${S}=\(__o\) # o
S="_p"; class+=("${S}"); eval ${S}=\(__p\) # p
S="_q"; class+=("${S}"); eval ${S}=\(__q\) # q
S="_r"; class+=("${S}"); eval ${S}=\(__r\) # r
S="_s"; class+=("${S}"); eval ${S}=\(__s\) # s
S="_t"; class+=("${S}"); eval ${S}=\(__t\) # t
S="_u"; class+=("${S}"); eval ${S}=\(__u\) # u
S="_v"; class+=("${S}"); eval ${S}=\(__v\) # v
S="_w"; class+=("${S}"); eval ${S}=\(__w\) # w
S="_x"; class+=("${S}"); eval ${S}=\(__x\) # x
S="_y"; class+=("${S}"); eval ${S}=\(__y\) # y
S="_z"; class+=("${S}"); eval ${S}=\(__z\) # z
S="_ae"; class+=("${S}"); eval ${S}=\(__ae\) # æ
S="_oe"; class+=("${S}"); eval ${S}=\(__oe\) # œ
S="_th"; class+=("${S}"); eval ${S}=\(__th\) # þ
 #S="_ss"; class+=("${S}"); eval ${S}=\(__ss\) # ß
S="_kg"; class+=("${S}"); eval ${S}=\(__kg\) # ĸ

# ラテン文字グループ ====================

# 基本 --------------------

# 各グリフの重心、形状の違いから、左寄り、右寄り、中央寄り、中央寄りと均等の中間、均等、幅広、Vの字形に分類する

S="outLgravityCapitalL"; class+=("${S}"); eval ${S}=\("_B_" "_D_" "_E_" "_F_" "_K_" "_P_" "_R_" "_TH_"\) # L 以外の左寄りの大文字
S="gravityCapitalL";     class+=("${S}"); eval ${S}=\("${outLgravityCapitalL[@]}" "_L_"\) # 左寄りの大文字
S="gravitySmallL";       class+=("${S}"); eval ${S}=\("__b" "__h" "__k" "__p" "__th" "__kg"\) # 左寄りの小文字 (ß を除く)
 #S="gravitySmallL";       class+=("${S}"); eval ${S}=\("__b" "__h" "__k" "__p" "__th" "__ss" "__kg"\) # 左寄りの小文字

S="outcgravitySmallR"; class+=("${S}"); eval ${S}=\("__a" "__d" "__g" "__q"\) # c 以外の右寄りの小文字
S="gravityCapitalR";   class+=("${S}"); eval ${S}=\("_C_" "_G_"\) # 右寄りの大文字
S="gravitySmallR";     class+=("${S}"); eval ${S}=\("${outcgravitySmallR[@]}" "__c"\) # 右寄りの小文字

S="outWgravityCapitalW"; class+=("${S}"); eval ${S}=\("_M_" "_AE_" "_OE_"\) # W 以外の幅広の大文字
S="outwgravitySmallW";   class+=("${S}"); eval ${S}=\("__m" "__ae" "__oe"\) # w 以外の幅広の小文字
S="gravityCapitalW";     class+=("${S}"); eval ${S}=\("${outWgravityCapitalW[@]}" "_W_"\) # 幅広の大文字
S="gravitySmallW";       class+=("${S}"); eval ${S}=\("${outwgravitySmallW[@]}" "__w"\) # 幅広の小文字

S="gravityCapitalE"; class+=("${S}"); eval ${S}=\("_H_" "_N_" "_O_" "_Q_" "_U_"\) # 均等な大文字
S="gravitySmallE";   class+=("${S}"); eval ${S}=\("__n" "__u"\) # 均等な小文字

S="outAgravityCapitalM"; class+=("${S}"); eval ${S}=\("_S_" "_X_" "_Z_"\) # A 以外の中間の大文字
S="gravityCapitalM";     class+=("${S}"); eval ${S}=\("${outAgravityCapitalM[@]}" "_A_"\) # 中間の大文字
S="gravitySmallM";       class+=("${S}"); eval ${S}=\("__e" "__o" "__s" "__x" "__z"\) # 中間の小文字

S="gravityCapitalV"; class+=("${S}"); eval ${S}=\("_T_" "_V_" "_Y_"\) # Vの字の大文字
S="gravitySmallV";   class+=("${S}"); eval ${S}=\("__v" "__y"\) # vの字の小文字

S="gravityCapitalC"; class+=("${S}"); eval ${S}=\("_I_" "_J_"\) # 狭い大文字
S="gravitySmallC";   class+=("${S}"); eval ${S}=\("__f" "__i" "__j" "__l" "__r" "__t"\) # 狭い小文字

S="gravityL"; class+=("${S}"); eval ${S}=\("${gravityCapitalL[@]}" "${gravitySmallL[@]}"\) # 左寄り
S="gravityR"; class+=("${S}"); eval ${S}=\("${gravityCapitalR[@]}" "${gravitySmallR[@]}"\) # 右寄り
S="gravityW"; class+=("${S}"); eval ${S}=\("${gravityCapitalW[@]}" "${gravitySmallW[@]}"\) # 幅広
S="gravityE"; class+=("${S}"); eval ${S}=\("${gravityCapitalE[@]}" "${gravitySmallE[@]}"\) # 均等
S="gravityM"; class+=("${S}"); eval ${S}=\("${gravityCapitalM[@]}" "${gravitySmallM[@]}"\) # 中間
S="gravityV"; class+=("${S}"); eval ${S}=\("${gravityCapitalV[@]}" "${gravitySmallV[@]}"\) # Vの字
S="gravityC"; class+=("${S}"); eval ${S}=\("${gravityCapitalC[@]}" "${gravitySmallC[@]}"\) # 狭い
S="outLgravityL";  class+=("${S}"); eval ${S}=\("${outLgravityCapitalL[@]}" "${gravitySmallL[@]}"\) # L 以外の左寄り
S="outcgravityR";  class+=("${S}"); eval ${S}=\("${gravityCapitalR[@]}" "${outcgravitySmallR[@]}"\) # c 以外の右寄り
S="outWwgravityW"; class+=("${S}"); eval ${S}=\("${outWgravityCapitalW[@]}" "${outwgravitySmallW[@]}"\) # Ww 以外の幅広
S="outAgravityM";  class+=("${S}"); eval ${S}=\("${outAgravityCapitalM[@]}" "${gravitySmallM[@]}"\) # A 以外の中間

# 丸い文字 --------------------

S="circleCapitalC"; class+=("${S}"); eval ${S}=\("_O_" "_Q_"\) # 丸い大文字
S="circleSmallC";   class+=("${S}"); eval ${S}=\("__e" "__o"\) # 丸い小文字

S="circleCapitalL"; class+=("${S}"); eval ${S}=\("_C_" "_G_"\) # 左が丸い大文字
S="circleSmallL";   class+=("${S}"); eval ${S}=\("__c" "__d" "__g" "__q"\) # 左が丸い小文字

S="circleCapitalR"; class+=("${S}"); eval ${S}=\("_B_" "_D_"\) # 右が丸い大文字
S="circleSmallR";   class+=("${S}"); eval ${S}=\("__b" "__p" "__th"\) # 右が丸い小文字 (ß を除く)
 #S="circleSmallR";   class+=("${S}"); eval ${S}=\("__b" "__p" "__th" "__ss"\) # 右が丸い小文字

S="circleC"; class+=("${S}"); eval ${S}=\("${circleCapitalC[@]}" "${circleSmallC[@]}"\) # 丸い文字
S="circleL"; class+=("${S}"); eval ${S}=\("${circleCapitalL[@]}" "${circleSmallL[@]}"\) # 左が丸い文字
S="circleR"; class+=("${S}"); eval ${S}=\("${circleCapitalR[@]}" "${circleSmallR[@]}"\) # 右が丸い文字

# 上が開いている文字 --------------------

S="highSpaceCapitalC"; class+=("${S}"); eval ${S}=\(""\) # 両上が開いている大文字
 #S="highSpaceCapitalC"; class+=("${S}"); eval ${S}=\("_A_"\) # 両上が開いている大文字
S="highSpaceSmallC";   class+=("${S}"); eval ${S}=\("__a" "__c" "__e" "__g" "__n" \
"__o" "__p" "__q" "__s" "__u" "__v" "__x" "__y" "__z" "__kg"\) # 両上が開いている小文字 (幅広、狭いを除く)
 #S="highSpaceSmallC";   class+=("${S}"); eval ${S}=\("__a" "__c" "__e" "__g" "__i" \
 #"__j" "__m" "__n" "__o" "__p" "__q" "__r" "__s" "__u" "__v" "__w" "__x" "__y" "__z" "__kg"\) # 両上が開いている小文字

S="highSpaceCapitalL"; class+=("${S}"); eval ${S}=\(""\) # 左上が開いている大文字
 #S="highSpaceCapitalL"; class+=("${S}"); eval ${S}=\("_J_"\) # 左上が開いている大文字
S="highSpaceSmallL";   class+=("${S}"); eval ${S}=\("__d"\) # 左上が開いている小文字

S="highSpaceCapitalR"; class+=("${S}"); eval ${S}=\(""\) # 右上が開いている大文字
 #S="highSpaceCapitalR"; class+=("${S}"); eval ${S}=\("_L_"\) # 右上が開いている大文字
S="highSpaceSmallR";   class+=("${S}"); eval ${S}=\("__b" "__h" "__k" "__th"\) # 右上が開いている小文字

S="highSpaceC"; class+=("${S}"); eval ${S}=\("${highSpaceCapitalC[@]}" "${highSpaceSmallC[@]}"\) # 両上が開いている文字
S="highSpaceL"; class+=("${S}"); eval ${S}=\("${highSpaceCapitalL[@]}" "${highSpaceSmallL[@]}"\) # 左上が開いている文字
S="highSpaceR"; class+=("${S}"); eval ${S}=\("${highSpaceCapitalR[@]}" "${highSpaceSmallR[@]}"\) # 右上が開いている文字

# 中が開いている文字 --------------------

S="midSpaceCapitalC"; class+=("${S}"); eval ${S}=\("_A_" "_I_" "_S_" "_T_" "_V_" "_X_" "_Y_" "_Z_"\) # 両側が開いている大文字
S="midSpaceSmallC";   class+=("${S}"); eval ${S}=\("__i" "__l" "__x"\) # 両側が開いている小文字

S="midSpaceCapitalL"; class+=("${S}"); eval ${S}=\("_J_"\) # 左側が開いている大文字
S="midSpaceSmallL";   class+=("${S}"); eval ${S}=\("__j"\) # 左側が開いている小文字

S="midSpaceCapitalR"; class+=("${S}"); eval ${S}=\("_E_" "_F_" "_K_" "_L_" "_P_" "_R_"\) # 右側が開いている大文字
S="midSpaceSmallR";   class+=("${S}"); eval ${S}=\("__f" "__k" "__r"\) # 右側が開いている小文字

S="midSpaceC"; class+=("${S}"); eval ${S}=\("${midSpaceCapitalC[@]}" "${midSpaceSmallC[@]}"\) # 両側が開いている文字
S="midSpaceL"; class+=("${S}"); eval ${S}=\("${midSpaceCapitalL[@]}" "${midSpaceSmallL[@]}"\) # 左側が開いている文字
S="midSpaceR"; class+=("${S}"); eval ${S}=\("${midSpaceCapitalR[@]}" "${midSpaceSmallR[@]}"\) # 右側が開いている文字

# 下が開いている文字 --------------------

S="lowSpaceCapitalC"; class+=("${S}"); eval ${S}=\("_T_" "_V_" "_Y_"\) # 両下が開いている大文字
S="lowSpaceSmallC";   class+=("${S}"); eval ${S}=\("__f" "__i" "__l" "__v"\) # 両下が開いている小文字

S="lowSpaceCapitalL"; class+=("${S}"); eval ${S}=\(""\) # 左下が開いている大文字
S="lowSpaceSmallL";   class+=("${S}"); eval ${S}=\("__t"\) # 左下が開いている小文字

S="lowSpaceCapitalR"; class+=("${S}"); eval ${S}=\("_F_" "_J_" "_P_" "_TH_"\) # 右下が開いている大文字
S="lowSpaceSmallR";   class+=("${S}"); eval ${S}=\("__j" "__r" "__y"\) # 右下が開いている小文字

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

 # 移動 (置換) しないグリフ (input[@]から除去)

S="fixedGlyph"; class+=("${S}"); eval ${S}=\("_AE_" "_OE_" "__ae" "__oe"\)

# 略号生成 (N: 通常、L: 左移動後、R: 右移動後)

for S in ${class[@]}; do
  eval member=("\${${S}[@]}")
  for T in ${member[@]}; do
    eval ${S}N+=\("${T}N"\)
    eval ${S}L+=\("${T}L"\)
    eval ${S}R+=\("${T}R"\)
  done
done

# 数字 (ここで定義した変数は直接使用しないこと) ====================
class=("")

S="_0_"; class+=("${S}"); eval ${S}=\(0\) # 0
S="_1_"; class+=("${S}"); eval ${S}=\(1\) # 1
S="_2_"; class+=("${S}"); eval ${S}=\(2\) # 2
S="_3_"; class+=("${S}"); eval ${S}=\(3\) # 3
S="_4_"; class+=("${S}"); eval ${S}=\(4\) # 4
S="_5_"; class+=("${S}"); eval ${S}=\(5\) # 5
S="_6_"; class+=("${S}"); eval ${S}=\(6\) # 6
S="_7_"; class+=("${S}"); eval ${S}=\(7\) # 7
S="_8_"; class+=("${S}"); eval ${S}=\(8\) # 8
S="_9_"; class+=("${S}"); eval ${S}=\(9\) # 9

# 数字単独 ====================

S="_0"; class+=("${S}"); eval ${S}=\(_0_\) # 0
S="_1"; class+=("${S}"); eval ${S}=\(_1_\) # 1
S="_2"; class+=("${S}"); eval ${S}=\(_2_\) # 2
S="_3"; class+=("${S}"); eval ${S}=\(_3_\) # 3
S="_4"; class+=("${S}"); eval ${S}=\(_4_\) # 4
S="_5"; class+=("${S}"); eval ${S}=\(_5_\) # 5
S="_6"; class+=("${S}"); eval ${S}=\(_6_\) # 6
S="_7"; class+=("${S}"); eval ${S}=\(_7_\) # 7
S="_8"; class+=("${S}"); eval ${S}=\(_8_\) # 8
S="_9"; class+=("${S}"); eval ${S}=\(_9_\) # 9

# 数字グループ ====================

S="figure"; class+=("${S}"); eval ${S}=\(_0_ _1_ _2_ _3_ _4_ _5_ _6_ _7_ _8_ _9_\) # 数字
S="figureB"; class+=("${S}"); eval ${S}=\(_0_ _1_\) # 数字 (2進数)

# 略号生成 (N: 通常、3: 3桁、4: 4桁、2: 12桁、0: 小数)

for S in ${class[@]}; do
  eval member=("\${${S}[@]}")
  for T in ${member[@]}; do
    eval ${S}N+=\("${T}N"\)
    eval ${S}3+=\("${T}3"\)
    eval ${S}4+=\("${T}4"\)
    eval ${S}2+=\("${T}2"\)
    eval ${S}0+=\("${T}0"\)
  done
done

# 記号 (上左右移動、ここで定義した変数は直接使用しないこと) ====================
class=("")

S="_hyphen_";   class+=("${S}"); eval ${S}=\("${hyphen}"\) # -

# 記号 (上左右移動) 単独 ====================

S="_hyphen";   class+=("${S}"); eval ${S}=\("_hyphen_"\) # -

# 略号生成 (N: 通常、U: 上移動後、L: 左移動後、R: 右移動後)

for S in ${class[@]}; do
  eval member=("\${${S}[@]}")
  for T in ${member[@]}; do
    eval ${S}N+=\("${T}N"\)
    eval ${S}U+=\("${T}U"\)
    eval ${S}L+=\("${T}L"\)
    eval ${S}R+=\("${T}R"\)
  done
done

# 記号 (左右移動、ここで定義した変数は直接使用しないこと) ====================
class=("")

S="_solidus_";  class+=("${S}"); eval ${S}=\("${solidus}"\) # solidus
S="_less_";     class+=("${S}"); eval ${S}=\("${less}"\) # <
S="_greater_";  class+=("${S}"); eval ${S}=\("${greater}"\) # >
S="_rSolidus_"; class+=("${S}"); eval ${S}=\("${rSolidus}"\) # reverse solidus

# 記号 (左右移動) 単独 ====================

S="_solidus";  class+=("${S}"); eval ${S}=\("_solidus_"\) # solidus
S="_less";     class+=("${S}"); eval ${S}=\("_less_"\) # <
S="_greater";  class+=("${S}"); eval ${S}=\("_greater_"\) # >
S="_rSolidus"; class+=("${S}"); eval ${S}=\("_rSolidus_"\) # reverse solidus

# 略号生成 (N: 通常、L: 左移動後、R: 右移動後)

for S in ${class[@]}; do
  eval member=("\${${S}[@]}")
  for T in ${member[@]}; do
    eval ${S}N+=\("${T}N"\)
    eval ${S}L+=\("${T}L"\)
    eval ${S}R+=\("${T}R"\)
  done
done

# 記号 (下移動、ここで定義した変数は直接使用しないこと) ====================
class=("")

S="_bar_";   class+=("${S}"); eval ${S}=\("${bar}"\) # |
S="_tilde_"; class+=("${S}"); eval ${S}=\("${tilde}"\) # ~

# 記号 (下移動) 単独 ====================

S="_bar";   class+=("${S}"); eval ${S}=\("_bar_"\) # |
S="_tilde"; class+=("${S}"); eval ${S}=\("_tilde_"\) # ~

# 略号生成 (N: 通常、D: 下移動後)

for S in ${class[@]}; do
  eval member=("\${${S}[@]}")
  for T in ${member[@]}; do
    eval ${S}N+=\("${T}N"\)
    eval ${S}D+=\("${T}D"\)
  done
done

# 記号 (上移動、ここで定義した変数は直接使用しないこと) ====================
class=("")

S="_colon_";     class+=("${S}"); eval ${S}=\("${colon}"\) # :
S="_asterisk_";  class+=("${S}"); eval ${S}=\("${asterisk}"\) # *
S="_plus_";      class+=("${S}"); eval ${S}=\("${plus}"\) # +
S="_equal_";     class+=("${S}"); eval ${S}=\("${equal}"\) # =

# 記号 (上移動) 単独 ====================

S="_colon";     class+=("${S}"); eval ${S}=\("_colon_"\) # :
S="_asterisk";  class+=("${S}"); eval ${S}=\("_asterisk_"\) # *
S="_plus";      class+=("${S}"); eval ${S}=\("_plus_"\) # +
S="_equal";     class+=("${S}"); eval ${S}=\("_equal_"\) # =

# 略号生成 (N: 通常、U: 上移動後)

for S in ${class[@]}; do
  eval member=("\${${S}[@]}")
  for T in ${member[@]}; do
    eval ${S}N+=\("${T}N"\)
    eval ${S}U+=\("${T}U"\)
  done
done

# 記号 (通常のみ、ここで定義した変数は直接使用しないこと) ====================
class=("")

S="_number_";       class+=("${S}"); eval ${S}=\("${number}"\) # #
S="_dollar_";       class+=("${S}"); eval ${S}=\("${dollar}"\) # $
S="_percent_";      class+=("${S}"); eval ${S}=\("${percent}"\) # %
S="_ampersand_";    class+=("${S}"); eval ${S}=\("${and}"\) # &
S="_fullStop_";     class+=("${S}"); eval ${S}=\("${fullStop}"\) # .
S="_at_";           class+=("${S}"); eval ${S}=\("${at}"\) # @
S="_parenleft_";    class+=("${S}"); eval ${S}=\("${parenLeft}"\) # (
S="_parenright_";   class+=("${S}"); eval ${S}=\("${parenRight}"\) # )
S="_bracketleft_";  class+=("${S}"); eval ${S}=\("${bracketLeft}"\) # [
S="_bracketright_"; class+=("${S}"); eval ${S}=\("${bracketRight}"\) # ]
S="_braceleft_";    class+=("${S}"); eval ${S}=\("${braceLeft}"\) # {
S="_braceright_";   class+=("${S}"); eval ${S}=\("${braceRight}"\) # }

# 記号 (通常のみ) 単独 ====================

S="_number";       class+=("${S}"); eval ${S}=\("_number_"\) # #
S="_dollar";       class+=("${S}"); eval ${S}=\("_dollar_"\) # $
S="_percent";      class+=("${S}"); eval ${S}=\("_percent_"\) # %
S="_ampersand";    class+=("${S}"); eval ${S}=\("_ampersand_"\) # &
S="_fullStop";     class+=("${S}"); eval ${S}=\("_fullStop_"\) # .
S="_at";           class+=("${S}"); eval ${S}=\("_at_"\) # @
S="_parenleft";    class+=("${S}"); eval ${S}=\("_parenleft_"\) # (
S="_parenright";   class+=("${S}"); eval ${S}=\("_parenright_"\) # )
S="_bracketleft";  class+=("${S}"); eval ${S}=\("_bracketleft_"\) # [
S="_bracketright"; class+=("${S}"); eval ${S}=\("_bracketright_"\) # ]
S="_braceleft";    class+=("${S}"); eval ${S}=\("_braceleft_"\) # {
S="_braceright";   class+=("${S}"); eval ${S}=\("_braceright_"\) # }

# 数字・記号 (通常のみ) グループ ====================

S="symbolE";    class+=("${S}"); eval ${S}=\("_number_" "_dollar_" "_percent_" "_ampersand_" \
"_asterisk_" "_less_" "_equal_" "_greater_" "_at_"\) # 幅のある記号
S="figureE";    class+=("${S}"); eval ${S}=\(_0_ _2_ _3_ _4_ _5_ _6_ _7_ _8_ _9_\) # 幅のある数字
S="figureC";    class+=("${S}"); eval ${S}=\(_1_\) # 幅の狭い数字
S="operatorH";  class+=("${S}"); eval ${S}=\("_asterisk_" "_plus_" "_hyphen_" "_equal_"\) # 前後の記号が上下に移動する記号
S="bracketL";    class+=("${S}"); eval ${S}=\("_parenleft_" "_bracketleft_" "_braceleft_"\) # 左括弧
S="bracketR";    class+=("${S}"); eval ${S}=\("_parenright_" "_bracketright_" "_braceright_"\) # 右括弧

# 略号生成 (N: 通常)

for S in ${class[@]}; do
  eval member=("\${${S}[@]}")
  for T in ${member[@]}; do
    eval ${S}N+=\("${T}N"\)
  done
done

# カーニング設定作成 ||||||||||||||||||||||||||||||||||||||||

echo "Make GSUB calt List"

#<< "#CALT0" # アルファベット・記号 ||||||||||||||||||||||||||||||||||||||||

pre_add_lookup

# アルファベット ++++++++++++++++++++++++++++++++++++++++
if [ "${symbol_only_flag}" = "false" ]; then

# 数字と記号に関する処理 1 ----------------------------------------

# 左が幅のある記号、数字で 右が左寄り、右寄り、幅広、均等、中間の文字の場合 左寄り、右寄り、幅広、均等、中間の文字 移動しない
backtrack=("${symbolEN[@]}" "${figureEN[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が幅のある記号、数字で 右がVの字の場合 幅広の文字 移動しない
backtrack=("${symbolEN[@]}" "${figureEN[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# もろもろ例外 ========================================

# 同じ文字を等間隔にさせる例外処理 ----------------------------------------

# 左が丸い文字、EF
class=("_C" "_G" "_c" "_d" "_g" "_q" "_E" "_F")
for S in ${class[@]}; do
  # 動かない
  eval backtrack=("\${${S}L[@]}")
  eval input=("\${${S}N[@]}")
  eval lookAhead=("\${${S}N[@]}")
  chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
 done

# A に関する例外処理 1 ----------------------------------------

# 左が W で 右が 左寄り、幅広の文字の場合 A 左に移動
backtrack=("${_WN[@]}")
input=("${_AN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が W で 右が、左下が開いている大文字か I の場合 A 右に移動 (次の処理とセット)
backtrack=("${_WR[@]}")
input=("${_AN[@]}")
lookAhead=("${lowSpaceCapitalCN[@]}" "${_IN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が W の場合 A 移動しない
backtrack=("${_WR[@]}")
input=("${_AN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# ---

# 左が、右下が開いている大文字、I で 右が、左下が開いている大文字の場合 A 移動しない (次の処理とセット)
backtrack=("${lowSpaceCapitalRR[@]}" "${lowSpaceCapitalCR[@]}" "${_IR[@]}" \
"${_IN[@]}")
input=("${_AN[@]}")
lookAhead=("${lowSpaceCapitalCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が、右下が開いている大文字か W の場合 A 左に移動
backtrack=("${lowSpaceCapitalRL[@]}" "${lowSpaceCapitalCL[@]}" "${_WL[@]}" \
"${lowSpaceCapitalRR[@]}" "${lowSpaceCapitalCR[@]}" \
"${lowSpaceCapitalRN[@]}" "${lowSpaceCapitalCN[@]}")
input=("${_AN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ---

# 左が A の場合 W 左に移動しない (次の処理とセット)
backtrack=("${_AR[@]}")
input=("${_WN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が A の場合 左下が開いている大文字 W 左に移動
backtrack=("${_AL[@]}" \
"${_AR[@]}" \
"${_AN[@]}")
input=("${lowSpaceCapitalCN[@]}" "${_WN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ---

# 左が左寄り、右寄り、均等、中間の大文字で 右が W の場合 A 右に移動しない
backtrack=("${gravityCapitalLL[@]}" "${gravityCapitalRL[@]}" "${gravityCapitalEL[@]}" "${gravityCapitalML[@]}")
input=("${_AN[@]}")
lookAhead=("${_WN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が幅広以外の大文字で 右が A の場合 右下が開いている大文字 W 右に移動しない
backtrack=("${gravityCapitalLL[@]}" "${gravityCapitalRL[@]}" "${gravityCapitalEL[@]}" "${gravityCapitalML[@]}" "${gravityCapitalVL[@]}" \
"${gravityCapitalVN[@]}" "${gravityCapitalCN[@]}")
input=("${lowSpaceCapitalRN[@]}" "${lowSpaceCapitalCN[@]}" "${_WN[@]}")
lookAhead=("${_AN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# I に関する例外処理 ----------------------------------------

# 左が中間の大文字で 右がVの大文字の場合 I 左に移動しない
backtrack=("${gravityCapitalMN[@]}")
input=("${_IN[@]}")
lookAhead=("${gravityCapitalVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が均等な大文字、右寄りの文字で 右が右寄り、中間の大文字の場合 I 右に移動
backtrack=("${gravityCapitalER[@]}" "${gravityRR[@]}")
input=("${_IN[@]}")
lookAhead=("${gravityCapitalRN[@]}" "${gravityCapitalMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# J に関する例外処理 ----------------------------------------

# 左が、右下が開いている文字で 右が狭い文字以外の場合 J 左に移動
backtrack=("${lowSpaceRR[@]}" "${lowSpaceCR[@]}")
input=("${_JN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

#---

# 左が J の場合 引き寄せない大文字、左寄り、幅広の文字 右に移動
backtrack=("${_JR[@]}")
input=("${gravityLN[@]}" "${gravityCapitalRN[@]}" "${gravityWN[@]}" "${gravityCapitalEN[@]}" "${outAgravityCapitalMN[@]}")
 #input=("${gravityLN[@]}" "${gravityCapitalRN[@]}" "${gravityWN[@]}" "${gravityCapitalEN[@]}" "${gravityCapitalMN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が J で 右が中間、Vの字の場合 狭い文字 移動しない
backtrack=("${_JR[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityMN[@]}" "${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# L に関する例外処理 1 ----------------------------------------

# 左が L の場合 狭い文字以外 左に移動
backtrack=("${_LL[@]}" \
"${_LN[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が L で 右が左寄り、右寄り、幅広、均等、中間の文字の場合 右寄り、中間、丸い文字 左に移動 (次とその次の処理とセット)
backtrack=("${_LR[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}" \
"${circleCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が L で 右が幅広の文字の場合 左寄り、均等な文字 左に移動 (次の処理とセット)
backtrack=("${_LR[@]}")
input=("${gravityLN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が L の場合 引き寄せない文字 移動しない
backtrack=("${_LR[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が L で 右がVの字、狭い文字の場合 狭い文字 左に移動しない
backtrack=("${_LR[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityVN[@]}" "${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が L の場合 Vの字、狭い文字 左に移動
backtrack=("${_LR[@]}")
input=("${gravityVN[@]}" "${gravityCN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ---

# 左が狭い文字の場合 L 右に移動しない (この後の処理とセット)
backtrack=("${gravityCL[@]}")
input=("${_LN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右が右寄り、中間、Vの字、狭い文字、LWw の場合 L 右に移動
backtrack=("")
input=("${_LN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}" "${gravityCN[@]}" "${_LN[@]}" "${_WN[@]}" "${_wN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が左寄り、右寄り、中間、Vの字、狭い文字で 右が左寄り、幅広、均等な文字の場合 L 右に移動
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityVR[@]}" "${gravityCR[@]}" \
"${gravityLN[@]}" "${gravityRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}" "${gravityCN[@]}")
input=("${_LN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が左寄り、中間、Vの字の場合 L 左に移動しない
backtrack=("${outLgravityLL[@]}" "${gravityML[@]}" "${gravityVL[@]}")
 #backtrack=("${gravityLL[@]}" "${gravityML[@]}" "${gravityVL[@]}")
input=("${_LN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# W に関する例外処理 ----------------------------------------

# 左がVの大文字で 右が左寄りの文字の場合 W 左に移動しない
backtrack=("${gravityCapitalVL[@]}")
input=("${_WN[@]}")
lookAhead=("${gravityLN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# c に関する例外処理 ----------------------------------------

# 左が c で 右が c 以外の右寄りの文字、丸い小文字の場合 左寄り、幅広、均等、中間の小文字 右に移動しない
backtrack=("${_cN[@]}")
input=("${gravitySmallLN[@]}" "${gravitySmallWN[@]}" "${gravitySmallEN[@]}" "${gravitySmallMN[@]}")
lookAhead=("${outcgravityRN[@]}" \
"${circleSmallCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# il に関する例外処理 ----------------------------------------

# 左が均等な大文字で、右が il の場合 狭い文字 右に移動
backtrack=("${gravityCapitalEN[@]}")
input=("${gravityCN[@]}")
lookAhead=("${_iN[@]}" "${_lN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が左寄り、中間、Vの字で 右が左寄り、均等な大文字、右が丸い文字の場合 il 左に移動
backtrack=("${gravityLR[@]}" "${gravityMR[@]}" "${gravityVR[@]}")
input=("${_iN[@]}" "${_lN[@]}")
lookAhead=("${gravityCapitalLN[@]}" "${gravityCapitalEN[@]}" \
"${circleRN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# j に関する例外処理 ----------------------------------------

# 両側が j の場合 j 移動しない
backtrack=("${_jR[@]}")
input=("${_jN[@]}")
lookAhead=("${_jN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が gq の場合 j 移動しない
backtrack=("${_gR[@]}" "${_qR[@]}")
input=("${_jN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が ad で、右が il の場合 j 移動しない
backtrack=("${_aR[@]}" "${_dR[@]}")
input=("${_jN[@]}")
lookAhead=("${_iN[@]}" "${_lN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が幅広の文字で 右が右寄り、均等、中間の小文字の場合 j 移動しない
backtrack=("${gravityWR[@]}")
input=("${_jN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が全ての文字の場合 j 左に移動
backtrack=("${gravityRL[@]}" "${gravityWL[@]}" "${gravityEL[@]}" \
"${gravitySmallLR[@]}" "${gravitySmallRR[@]}" "${gravitySmallER[@]}" "${gravitySmallMR[@]}" "${gravityVR[@]}" "${gravityCR[@]}" \
"${midSpaceCapitalRR[@]}" "${lowSpaceCapitalRR[@]}" "${_CR[@]}" \
"${capitalN[@]}" "${smallN[@]}")
input=("${_jN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ---

# 左が左寄り、中間、Vの字、IJfilt で 右が j の場合 左寄り、均等な文字、中間の小文字、CcIfilrt 右に移動
backtrack=("${gravityLN[@]}" "${gravityMN[@]}" "${gravityVN[@]}" "${_IN[@]}" "${_JN[@]}" "${_fN[@]}" "${_iN[@]}" "${_lN[@]}" "${_tN[@]}")
input=("${gravityLN[@]}" "${gravityEN[@]}" "${gravitySmallMN[@]}" \
"${_CN[@]}" "${_cN[@]}" "${_IN[@]}" "${_fN[@]}" "${_iN[@]}" "${_lN[@]}" "${_rN[@]}" "${_tN[@]}")
lookAhead=("${_jN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が中間、Vの字で 右が j の場合 狭い文字 移動しない
backtrack=("${gravityML[@]}" "${gravityVL[@]}")
input=("${gravityCN[@]}")
lookAhead=("${_jN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# rt に関する例外処理 1 ----------------------------------------

# 両側が r の場合 r 左に移動しない (次の処理とセット)
backtrack=("${_rN[@]}")
input=("${_rN[@]}")
lookAhead=("${_rN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が Ifilr で 右が狭い文字の場合 rt 左に移動
backtrack=("${_IN[@]}" "${_fN[@]}" "${_iN[@]}" "${_lN[@]}" "${_rN[@]}")
input=("${_rN[@]}" "${_tN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が均等な小文字、h で 右が左寄り、右寄り、均等、丸い文字、中間の大文字の場合 t 左に移動
backtrack=("${gravitySmallER[@]}" "${_hR[@]}")
input=("${_tN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityCapitalMN[@]}" \
"${circleCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が幅広の文字で 右が引き離す文字の場合 rt 移動しない
backtrack=("${gravityWL[@]}")
input=("${_rN[@]}" "${_tN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が均等な小文字で 右が狭い文字の場合 t 移動しない
backtrack=("${gravitySmallEN[@]}")
input=("${_tN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が右寄り、均等な小文字で 右が左寄り、右寄り、均等、中間の文字の場合 rt 左に移動
backtrack=("${gravitySmallRN[@]}" "${gravitySmallEN[@]}")
input=("${_rN[@]}" "${_tN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ---

# 左が rt で 右が左寄り、幅広、均等な場合 幅広の文字 左に移動 (次の処理とセット)
backtrack=("${_rL[@]}" "${_tL[@]}" \
"${_rN[@]}" "${_tN[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が rt の場合 幅広の文字 左に移動しない
backtrack=("${_rL[@]}" "${_tL[@]}" \
"${_rN[@]}" "${_tN[@]}")
input=("${gravityWN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が rt で 右が幅広の文字の場合 左寄り、均等な文字 左に移動 (この後の処理とセット)
backtrack=("${_tL[@]}" \
"${_rN[@]}" "${_tN[@]}")
input=("${gravityLN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が t で 右が左寄り、均等な文字の場合 左寄り、均等な文字 左に移動 (次の処理とセット)
backtrack=("${_tL[@]}")
input=("${gravityLN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が rt の場合 左寄り、均等な文字 左に移動しない
backtrack=("${_tL[@]}" \
"${_rN[@]}" "${_tN[@]}")
input=("${gravityLN[@]}" "${gravityEN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が rt で 右が幅広の文字の場合 幅広と狭い文字以外 左に移動 (次の処理とセット)
backtrack=("${_rR[@]}" "${_tR[@]}")
input=("${outLgravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
 #input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が rt の場合 幅広と狭い文字以外 左に移動しない
backtrack=("${_rR[@]}" "${_tR[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が rt で 右が j の場合 右寄り、中間の文字 左に移動しない
backtrack=("${_rN[@]}" "${_tN[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("${_jN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# y に関する例外処理 1 ----------------------------------------

# 左が、均等な大文字、左上が開いている文字、gjq の場合 y 左に移動しない
backtrack=("${gravityCapitalEL[@]}" "${highSpaceLL[@]}" "${_gL[@]}" "${_jL[@]}" "${_qL[@]}")
input=("${_yN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が、均等な大文字、左上が開いている文字で 右が引き寄せない文字の場合 y 右に移動しない
backtrack=("${gravityCapitalEN[@]}" "${highSpaceLN[@]}")
input=("${_yN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が、均等な大文字、左上が開いている文字、gjpqþ の場合 y 右に移動
backtrack=("${gravityCapitalER[@]}" "${highSpaceLR[@]}" "${_gR[@]}" "${_jR[@]}" "${_pR[@]}" "${_qR[@]}" "${_thR[@]}" \
"${gravityCapitalEN[@]}" "${highSpaceLN[@]}" "${_gN[@]}" "${_jN[@]}" "${_qN[@]}")
input=("${_yN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# xz に関する例外処理 ----------------------------------------

# 左が右寄りで 右が右寄り、中間の文字の場合 xz 右に移動
backtrack=("${gravityRN[@]}")
input=("${_xN[@]}" "${_zN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が xz の場合 右が丸い小文字 移動しない
backtrack=("${_xN[@]}" "${_zN[@]}")
input=("${circleSmallRN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# A に関する例外処理 2 ----------------------------------------

# 左が左寄りの大文字で 右が左寄り、均等な大文字の場合 A 右に移動
backtrack=("${outLgravityCapitalLR[@]}")
 #backtrack=("${gravityCapitalLR[@]}")
input=("${_AN[@]}")
lookAhead=("${gravityCapitalLN[@]}" "${gravityCapitalEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# Jj に関する例外処理 1 ----------------------------------------

# 左が Jj で 右が狭い文字以外の場合 右寄り、均等、中間の小文字、Vの字、狭い文字 左に移動
backtrack=("${_JL[@]}" "${_jL[@]}")
input=("${gravitySmallRN[@]}" "${gravitySmallEN[@]}" "${gravitySmallMN[@]}" "${gravityVN[@]}" "${gravityCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が Jj の場合 狭い文字以外 移動しない
backtrack=("${_JL[@]}" "${_jL[@]}" \
"${_JN[@]}" "${_jN[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# Ww に関する例外処理 ----------------------------------------

# 左が中間、右が丸い文字、hn で その左が左寄り、右寄り、均等、中間の文字の場合 Ww 右に移動しない
backtrack1=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}" \
"${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
backtrack=("${gravityML[@]}" "${_hL[@]}" "${_nL[@]}" \
"${circleRL[@]}" "${circleCL[@]}")
input=("${_WN[@]}" "${_wN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"

# 左が Ww で 右が左寄り、右寄り、均等、中間の文字の場合 中間、右が丸い文字 右に移動しない
backtrack=("${_WL[@]}" "${_wL[@]}")
input=("${gravityMN[@]}" \
"${circleLN[@]}" "${circleCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 大文字と小文字に関する例外処理 1 ----------------------------------------

# 左が FPTÞ で 右が狭い文字の場合 左上が開いている文字 移動しない
backtrack=("${_TR[@]}" \
"${_FN[@]}" "${_PN[@]}" "${_TN[@]}" "${_THN[@]}")
input=("${highSpaceLN[@]}" "${highSpaceCN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が T の場合 左上が開いている文字 左に移動
backtrack=("${_TL[@]}" \
"${_TN[@]}")
input=("${highSpaceLN[@]}" "${highSpaceCN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が、右上が開いている文字で 右が左寄り、均等な文字の場合 両下が開いている大文字 左に移動
backtrack=("${highSpaceRN[@]}" "${highSpaceCN[@]}")
input=("${lowSpaceCapitalCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 丸い文字に関する例外処理 1 ----------------------------------------

# 左が W で 右が右寄りの大文字 A の場合 丸い大文字 右に移動しない (なんちゃって最適化でいらない子判定)
 #backtrack=("${_WL[@]}")
 #input=("${circleCapitalCN[@]}")
 #lookAhead=("${gravityCapitalRN[@]}" "${_AN[@]}")
 #chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が Ww で 右が左寄り、均等な小文字の場合 均等、丸い文字 右に移動しない (大文字と小文字の処理と統合)
backtrack=("${_WL[@]}" "${_wL[@]}")
input=("${gravitySmallEN[@]}" \
"${circleSmallCN[@]}")
lookAhead=("${gravitySmallLN[@]}" "${gravitySmallEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が Ww で 右が右寄り、中間、Vの字の場合 丸い文字 右に移動しない
backtrack=("${_WL[@]}" "${_wL[@]}")
input=("${circleSmallCN[@]}")
lookAhead=("${gravitySmallVN[@]}")
 #lookAhead=("${gravitySmallRN[@]}" "${gravitySmallMN[@]}" "${gravitySmallVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が、右が丸い文字で 右が Ww の場合 丸い文字 移動しない
backtrack=("${circleRL[@]}" "${circleCL[@]}" \
"${circleRN[@]}" "${circleCN[@]}")
input=("${circleCN[@]}")
lookAhead=("${_WN[@]}" "${_wN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が幅広、右が丸い文字で 右が、右が丸い文字の場合 丸い文字 移動しない
backtrack=("${outWwgravityWL[@]}" \
"${circleRL[@]}")
 #backtrack=("${gravityWL[@]}" \
 #"${circleRL[@]}")
input=("${circleCN[@]}")
lookAhead=("${circleRN[@]}" "${circleCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が均等な文字で 右が左寄りの文字、Vの小文字の場合 丸い文字 移動しない
backtrack=("${gravityEN[@]}")
input=("${circleCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravitySmallVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が h で 右が中間の文字、c の場合 丸い小文字 右に移動
backtrack=("${_hN[@]}")
input=("${circleSmallCN[@]}")
lookAhead=("${gravityMN[@]}" "${_cN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が、右が丸い文字、PRÞ の場合 丸い文字 右に移動 (大文字と小文字の処理と統合)
 #backtrack=("${circleRR[@]}" "${_PR[@]}" "${_RR[@]}" "${_THR[@]}")
 #input=("${circleCN[@]}")
 #lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
 #chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が丸い文字に関する例外処理 1 ----------------------------------------

# 左が、右が丸い文字で 右が中間の文字の場合 左が丸い小文字 右に移動
backtrack=("${circleRN[@]}" "${circleCN[@]}")
input=("${circleSmallLN[@]}" "${circleSmallCN[@]}")
lookAhead=("${gravityMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が、右が丸い文字、h で 右がVの字の場合 左が丸い文字 右に移動
backtrack=("${circleRN[@]}" "${circleCN[@]}" "${_hN[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が EKXkxĸ で 右が左寄り、右寄り、均等、中間の文字の場合 左が丸い文字 移動しない
backtrack=("${_ER[@]}" "${_KR[@]}" "${_XR[@]}" "${_kR[@]}" "${_xR[@]}" "${_kgR[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が右が丸い小文字、B で 右が左寄りの文字、均等、右寄りの大文字の場合 左が丸い文字 左に移動
backtrack=("${circleSmallRL[@]}" "${_BL[@]}")
input=("${circleLN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityCapitalEN[@]}" "${gravityCapitalRN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が EFKTXkxĸ で 右が左寄り、右寄り、均等、中間の文字の場合 左が丸い文字 左に移動
backtrack=("${_EN[@]}" "${_FN[@]}" "${_KN[@]}" "${_TN[@]}" "${_XN[@]}" "${_kN[@]}" "${_xN[@]}" "${_kgN[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が z で 右が右寄りの文字の場合 左が丸い小文字、o 左に移動
backtrack=("${_zN[@]}")
input=("${circleSmallLN[@]}" "${_oN[@]}")
lookAhead=("${gravityRN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が z で 右が均等、中間の文字の場合 左が丸い小文字 左に移動
backtrack=("${_zN[@]}")
input=("${circleSmallLN[@]}")
lookAhead=("${gravityEN[@]}" "${gravityMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が EFKTXkxzĸ で 右が狭い文字で その右が狭い文字の場合 丸い文字 右に移動 (次の処理とセット)
backtrack1=("")
backtrack=("${_EN[@]}" "${_FN[@]}" "${_KN[@]}" "${_TN[@]}" "${_XN[@]}" "${_kN[@]}" "${_xN[@]}" "${_zN[@]}" "${_kgN[@]}")
input=("${circleCN[@]}")
lookAhead=("${gravityCN[@]}")
lookAhead1=("${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 左が EFKTXkxzĸ で 右がVの字、狭い文字の場合 左が丸い文字 右に移動しない
backtrack=("${_EN[@]}" "${_FN[@]}" "${_KN[@]}" "${_TN[@]}" "${_XN[@]}" "${_kN[@]}" "${_xN[@]}" "${_zN[@]}" "${_kgN[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("${gravityVN[@]}" "${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が幅広、引き寄せる文字以外、a で 右が、左が丸い文字の場合 Vの字 左に移動
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityLN[@]}" "${gravityMN[@]}" "${_aN[@]}")
input=("${gravityVN[@]}")
lookAhead=("${circleLN[@]}" "${circleCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が Ww で 右が右寄り、左が丸い文字の場合 Mm 右に移動しない
backtrack=("${_WL[@]}" "${_wL[@]}")
input=("${_MN[@]}" "${_mN[@]}")
lookAhead=("${gravityRN[@]}" \
"${circleCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右が丸い文字に関する例外処理 1 ----------------------------------------

# 左が右寄り、均等な大文字で 右が Ww の場合 右が丸い大文字 移動しない
backtrack=("${gravityCapitalRL[@]}" "${gravityCapitalEL[@]}")
input=("${circleCapitalRN[@]}")
lookAhead=("${_WN[@]}" "${_wN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が、右が丸い大文字の場合 狭い文字 左に移動しない
backtrack=("${circleCapitalRN[@]}" "${circleCapitalCN[@]}")
input=("${gravityCN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が左寄り、中間の文字で 右が右寄り、丸い文字の場合 左寄りの小文字、右が丸い文字 右に移動しない (大文字と小文字の処理と統合)
backtrack=("${gravityLN[@]}" "${gravityMN[@]}")
input=("${gravitySmallLN[@]}" \
"${circleRN[@]}" "${circleCN[@]}")
lookAhead=("${gravityRN[@]}" \
"${circleCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が c で その左が狭い文字、L で 右が左寄り、均等、左が丸い文字の場合 右寄り、均等、右が丸い文字 左に移動しない
backtrack1=("${gravityCL[@]}" "${_LL[@]}" \
"${gravityCR[@]}" "${_LR[@]}" \
"${gravityCN[@]}" "${_LN[@]}")
backtrack=("${_cL[@]}")
input=("${gravityRN[@]}" "${gravityEN[@]}" \
"${circleRN[@]}" "${circleCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}" \
"${circleLN[@]}" "${circleCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"

# 左が右寄り、均等な文字で 右が左寄り、均等、左が丸い文字の場合 右寄り、均等、右が丸い文字 左に移動しない
backtrack=("${outcgravityRL[@]}" "${gravityEL[@]}")
input=("${gravityRN[@]}" "${gravityEN[@]}" \
"${circleRN[@]}" "${circleCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}" \
"${circleLN[@]}" "${circleCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が、右が丸い文字で 右が幅広、狭い文字以外の場合 均等、左右が丸い文字 左に移動しない (左が丸い文字の処理と統合)
backtrack=("${circleRL[@]}" "${circleCL[@]}")
input=("${gravityEN[@]}" \
"${circleLN[@]}" "${circleRN[@]}" "${circleCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 大文字と小文字で処理が異なる例外処理 1 ----------------------------------------

# 左が均等な大文字で 右が左寄りの文字の場合 幅広、均等な大文字 右に移動
backtrack=("${gravityCapitalEN[@]}")
input=("${gravityCapitalWN[@]}" "${gravityCapitalEN[@]}")
lookAhead=("${gravityLN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が均等な大文字で 右が左寄り文字の場合 均等な大文字 左に移動しない (なんちゃって最適化でいらない子判定)
 #backtrack=("${gravityCapitalEL[@]}")
 #input=("${gravityCapitalEN[@]}")
 #lookAhead=("${gravityLN[@]}")
 #chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が中間の大文字で 右が狭い大文字の場合 中間の大文字 右に移動しない
backtrack=("${gravityCapitalMN[@]}")
input=("${gravityCapitalMN[@]}")
lookAhead=("${gravityCapitalCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が左寄り、中間の大文字で 右が幅広の文字の場合 右寄り、中間の文字 左に移動しない
backtrack=("${gravityCapitalLN[@]}" "${gravityCapitalMN[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が左寄り、中間の小文字で その左が左寄りの小文字、幅広、均等な文字で 右が幅広の小文字の場合 左寄り、均等な小文字 左に移動しない
backtrack1=("${gravityWL[@]}" "${gravityEL[@]}" \
"${gravitySmallLN[@]}" "${gravitySmallEN[@]}")
backtrack=("${gravitySmallLN[@]}" "${gravitySmallMN[@]}")
input=("${gravitySmallLN[@]}" "${gravitySmallEN[@]}")
lookAhead=("${gravitySmallWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"

# 左が均等の小文字で 右が幅広の小文字の場合 右寄り、中間、Vの小文字 左に移動
backtrack=("${gravitySmallEN[@]}")
input=("${gravitySmallRN[@]}" "${gravitySmallMN[@]}" "${gravitySmallVN[@]}")
lookAhead=("${gravitySmallWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が均等な小文字で 右が左寄り、右寄り、均等、中間の小文字の場合 狭い文字 左に移動
backtrack=("${gravitySmallEN[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityCapitalLN[@]}" "${gravityCapitalRN[@]}" "${gravityCapitalEN[@]}" "${gravityCapitalMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が Ww で 右が左寄りの小文字の場合 均等な小文字 右に移動しない (丸い文字の処理と統合)
 #backtrack=("${_WL[@]}" "${_wL[@]}")
 #input=("${gravitySmallEN[@]}")
 #lookAhead=("${gravitySmallLN[@]}" "${gravitySmallEN[@]}")
 #chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が左寄り、中間の文字で 右が右寄り、丸い文字の場合 左寄りの小文字 右に移動しない (右が丸い文字の処理と統合)
 #backtrack=("${gravityLN[@]}" "${gravityMN[@]}")
 #input=("${gravitySmallLN[@]}")
 #lookAhead=("${gravityRN[@]}" \
 #"${circleCN[@]}")
 #chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が均等な大文字、右寄りの文字で 右が ac で その右が左寄り、右寄り、幅広、均等、中間の文字の場合 狭い文字 右に移動しない (次の処理とセット)
backtrack1=("")
backtrack=("${gravityCapitalER[@]}" "${gravityRR[@]}")
input=("${gravityCN[@]}")
lookAhead=("${_aN[@]}" "${_cN[@]}")
lookAhead1=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 左が均等な大文字、右寄りの文字で 右がVの大文字、acsxz の場合 狭い文字 右に移動
backtrack=("${gravityCapitalER[@]}" "${gravityRR[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityCapitalVN[@]}" "${_aN[@]}" "${_cN[@]}" "${_sN[@]}" "${_xN[@]}" "${_zN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が、中間の文字で 右が左寄りの文字、右寄り、均等な大文字の場合 右寄り、中間の小文字 左に移動
backtrack=("${gravityMN[@]}")
input=("${gravitySmallRN[@]}" "${gravitySmallMN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityCapitalRN[@]}" "${gravityCapitalEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が幅広の文字で 右が左寄り、均等な大文字か k の場合 均等、中間の文字 右に移動しない
backtrack=("${gravityWL[@]}")
input=("${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityCapitalLN[@]}" "${gravityCapitalEN[@]}" "${_kN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左右を見て左に移動させる例外処理 ----------------------------------------

# 左が均等、中間の小文字 EFKhkĸ で 右が均等な大文字の場合 幅広の文字 左に移動
backtrack=("${gravitySmallEL[@]}" "${gravitySmallML[@]}" "${_EL[@]}" "${_FL[@]}" "${_KL[@]}" "${_hL[@]}" "${_kL[@]}" "${_kgL[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityCapitalEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が FTf で 右が狭い文字以外の場合 右寄り、中間、Vの小文字 左に移動
backtrack=("${_FR[@]}" "${_TR[@]}" "${_fR[@]}" \
"${_FN[@]}" "${_TN[@]}")
input=("${gravitySmallRN[@]}" "${gravitySmallMN[@]}" "${gravitySmallVN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 2つ右を見て移動させる例外処理 1 ----------------------------------------

# 左が左寄り、中間の文字で 右が IJfrt で その右が狭い文字の場合 IJirt 右に移動 (この後の処理とセット)
backtrack1=("")
backtrack=("${gravityLR[@]}" "${gravityMR[@]}")
input=("${_IN[@]}" "${_JN[@]}" "${_iN[@]}" "${_rN[@]}" "${_tN[@]}")
lookAhead=("${_IN[@]}" "${_JN[@]}" "${_fN[@]}" "${_rN[@]}" "${_tN[@]}")
lookAhead1=("${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 左が左寄り、中間の文字で 右が IJfrt で その右が右寄り、中間、Vの字の場合 J 右に移動 (この後の処理とセット)
backtrack1=("")
backtrack=("${gravityLR[@]}" "${gravityMR[@]}")
input=("${_JN[@]}")
lookAhead=("${_IN[@]}" "${_JN[@]}" "${_fN[@]}" "${_rN[@]}" "${_tN[@]}")
lookAhead1=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 左右を見て移動させない例外処理 ----------------------------------------

# 左が F で 右が IJfrt の場合 IJi 右に移動しない
backtrack=("${_FR[@]}")
input=("${_IN[@]}" "${_JN[@]}" "${_iN[@]}")
lookAhead=("${_IN[@]}" "${_JN[@]}" "${_fN[@]}" "${_rN[@]}" "${_tN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が中間の文字、右が丸い文字、PÞ で 右が IJfrt の場合 J 右に移動しない
backtrack=("${gravityMR[@]}" "${_PR[@]}" "${_THR[@]}" \
"${circleRR[@]}")
input=("${_JN[@]}")
lookAhead=("${_IN[@]}" "${_JN[@]}" "${_fN[@]}" "${_rN[@]}" "${_tN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が左寄り、中間の文字で 右が r の場合 irt 右に移動しない
backtrack=("${outLgravityLR[@]}" "${gravityMR[@]}")
 #backtrack=("${gravityLR[@]}" "${gravityMR[@]}")
input=("${_iN[@]}" "${_rN[@]}" "${_tN[@]}")
lookAhead=("${_rN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が左寄り、中間の文字で 右が IJft の場合 rt 右に移動しない
backtrack=("${outLgravityLR[@]}" "${gravityMR[@]}")
 #backtrack=("${gravityLR[@]}" "${gravityMR[@]}")
input=("${_rN[@]}" "${_tN[@]}")
lookAhead=("${_IN[@]}" "${_JN[@]}" "${_fN[@]}" "${_tN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が右寄りの文字で 右が右寄り、中間の文字の場合 filr 右に移動しない
backtrack=("${gravityRN[@]}")
input=("${_fN[@]}" "${_iN[@]}" "${_lN[@]}" "${_rN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が均等の文字で 右が左寄り、右寄り、均等、中間、Vの字の場合 IJf 左に移動しない
backtrack=("${gravityEN[@]}")
input=("${_IN[@]}" "${_JN[@]}" "${_fN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が Ifrt で 右が狭い文字の場合 幅広の文字 左に移動しない
backtrack=("${_IL[@]}" "${_fL[@]}" "${_rL[@]}" "${_tL[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が t で 右が狭い文字の場合 幅広と狭い文字以外 移動しない (統合した処理と統合)
 #backtrack=("${_tL[@]}")
 #input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
 #lookAhead=("${gravityCN[@]}")
 #chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左がVの字で 右が狭い文字の場合 aSs 右に移動しない
backtrack=("${gravityVR[@]}")
input=("${_aN[@]}" "${_SN[@]}" "${_sN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が et で 右が frt (両側が少しでも左に寄っている文字)の場合 右寄り、中間、Vの字 移動しない
backtrack=("${_eN[@]}" "${_tN[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${_fN[@]}" "${_rN[@]}" "${_tN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が t で 右が ly (両側が少しでも左に寄っている文字)の場合 右寄り、中間、Vの字 移動しない
backtrack=("${_tN[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${_lN[@]}" "${_yN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が EKXkĸsxz で 右が左寄り、右寄り、均等、中間の文字の場合 SXZhsxz 移動しない
backtrack=("${_ER[@]}" "${_KR[@]}" "${_XR[@]}" "${_kR[@]}" "${_sR[@]}" "${_xR[@]}" "${_zR[@]}" "${_kgR[@]}")
input=("${_SN[@]}" "${_XN[@]}" "${_ZN[@]}" "${_hN[@]}" "${_sN[@]}" "${_xN[@]}" "${_zN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が中間の小文字 kĸ で 右が狭い文字の場合 中間の大文字 sxz 右に移動しない
backtrack=("${gravitySmallMN[@]}" "${_kN[@]}" "${_kgN[@]}")
input=("${gravityCapitalMN[@]}" "${_sN[@]}" "${_xN[@]}" "${_zN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 統合した通常処理 ----------------------------------------

# 左が狭い文字で 右が右寄り、中間の文字の場合 右寄り、均等、中間、Vの字 左に移動 (次の2つの処理とセット)
backtrack=("${gravityCR[@]}")
input=("${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が狭い文字で 右が左寄りの文字の場合 左寄り、中間、Vの字 左に移動
backtrack=("${gravityCR[@]}")
input=("${outLgravityLN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
 #input=("${gravityLN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${gravityLN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が狭い文字で 右が均等、Vの字の場合 Vの字 左に移動
backtrack=("${gravityCR[@]}")
input=("${gravityVN[@]}")
lookAhead=("${gravityEN[@]}" "${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が引き離す文字で 右が幅広の文字の場合 引き寄せない文字 移動しない
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityRR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 両側が均等な文字の場合 右寄り、均等な文字 移動しない (なんちゃって最適化でいらない子判定)
 #backtrack=("${gravityEL[@]}")
 #input=("${gravityRN[@]}" "${gravityEN[@]}")
 #lookAhead=("${gravityEN[@]}")
 #chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 両側が中間の文字の場合 右寄り、均等な文字 移動しない
backtrack=("${gravityML[@]}")
input=("${gravityRN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 両側がVの字の場合 右寄り、均等な文字 移動しない
backtrack=("${gravityVL[@]}")
input=("${gravityRN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が均等な小文字、h で 右が狭い文字の場合 狭い文字 右に移動しない (次とその次の処理とセット)
backtrack=("${gravitySmallEL[@]}" "${_hL[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が均等な小文字、h で 右が frt の場合 幅広、狭い文字以外 右に移動しない (この後の処理とセット)
backtrack=("${gravitySmallEL[@]}" "${_hL[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${_fN[@]}" "${_rN[@]}" "${_tN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が、左が丸い小文字で 右が t の場合 左寄り、右寄り、均等、中間の文字 右に移動しない (この後の処理とセット)
backtrack=("${circleSmallRL[@]}" "${circleSmallCL[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${_tN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が右寄り、幅広、均等な文字、h で 右が狭い文字の場合 左寄り、右寄り、均等、中間、狭い文字 右に移動
backtrack=("${gravityRL[@]}" "${gravityWL[@]}" "${gravityEL[@]}" "${_hL[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityCN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が左寄り、中間の文字で 右が ijl の場合 左寄りの文字、均等な大文字 右に移動 (次の処理とセット)
backtrack=("${gravityLL[@]}" "${gravityML[@]}")
input=("${gravityLN[@]}" "${gravityCapitalEN[@]}")
lookAhead=("${_iN[@]}" "${_jN[@]}" "${_lN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が左寄り、中間、Vの字、狭い文字、t で 右が狭い文字の場合 幅広と狭い文字以外 移動しない (左右を見て動かさない処理と統合)
backtrack=("${gravityLL[@]}" "${gravityML[@]}" "${gravityVL[@]}" "${_tL[@]}" \
"${gravityCR[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# ASs に関する例外処理 ----------------------------------------

# 左が右寄り、均等な文字で 右が狭い文字の場合 ASs 右に移動
backtrack=("${gravityRN[@]}" "${gravityEN[@]}")
input=("${_AN[@]}" "${_SN[@]}" "${_sN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が右寄り、均等な文字で 右がVの字の場合 A 右に移動
backtrack=("${gravityRN[@]}" "${gravityEN[@]}")
input=("${_AN[@]}")
lookAhead=("${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が幅広、右寄り、均等な文字の場合 ASs 右に移動しない
backtrack=("${gravityWL[@]}" \
"${gravityRN[@]}" "${gravityEN[@]}")
input=("${_AN[@]}" "${_SN[@]}" "${_sN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 2つ右を見て移動させない例外処理 ----------------------------------------

# 左が IJijl で 右が IJijl で その右がVの字、狭い文字の場合 右寄り、均等、中間の文字 移動しない
backtrack1=("")
backtrack=("${_IN[@]}" "${_JN[@]}" "${_iN[@]}" "${_jN[@]}" "${_lN[@]}")
input=("${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${_IN[@]}" "${_JN[@]}" "${_iN[@]}" "${_jN[@]}" "${_lN[@]}")
lookAhead1=("${gravityVN[@]}" "${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 2つ左を見て移動させない例外処理 1 ----------------------------------------

# 左が狭い文字で 右が全ての文字の場合 引き寄せない文字 左に移動 (この後の処理とセット)
backtrack=("${gravityCL[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${capitalN[@]}" "${smallN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が狭い文字で 右が左寄り、右寄り、幅広、均等、中間の文字の場合 左寄り、右寄り、均等、中間の文字 左に移動 (この後の処理とセット)
backtrack=("${gravityCN[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が狭い文字で 右がVの字の場合 右寄り、均等、中間の文字 左に移動 (この後の処理とセット)
backtrack=("${gravityCN[@]}")
input=("${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が狭い文字で 右が狭い文字の場合 右寄り、中間の文字、均等な小文字 左に移動 (この後の処理とセット)
backtrack=("${gravityCN[@]}")
input=("${gravityRN[@]}" "${gravitySmallEN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が Iilt で その左が狭い文字の場合 左寄り、右寄り、均等、中間の文字 移動しない
backtrack1=("${_JL[@]}" "${_jL[@]}" "${_tL[@]}" \
"${_IR[@]}" "${_JR[@]}" "${_fR[@]}" "${_iR[@]}" "${_lR[@]}" "${_rR[@]}" \
"${gravityCN[@]}")
backtrack=("${_IL[@]}" "${_iL[@]}" "${_tL[@]}" \
"${_IN[@]}" "${_iN[@]}" "${_lN[@]}" "${_tN[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"

# 左が狭い文字で その左が狭い文字の場合 幅広の文字 移動しない
backtrack1=("${_JL[@]}" "${_jL[@]}" "${_tL[@]}" \
"${gravityCR[@]}" \
"${gravityCN[@]}")
backtrack=("${gravityCL[@]}")
input=("${gravityWN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"

# 左がVの字、狭い文字で その左が L の場合 左寄り、均等な文字 左に移動しない
backtrack1=("${_LR[@]}")
backtrack=("${gravityVL[@]}" "${gravityCL[@]}")
input=("${outLgravityLN[@]}" "${gravityEN[@]}")
 #input=("${gravityLN[@]}" "${gravityEN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"

# 左がVの字で その左が L の場合 右寄り、中間、Vの字 左に移動しない
backtrack1=("${_LR[@]}")
backtrack=("${gravityVL[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"

# ---

# 左が中間の文字で その左が Ww の場合 r 左に移動しない
backtrack1=("${_WL[@]}" "${_wL[@]}")
backtrack=("${gravityMR[@]}")
input=("${_rN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"

# 左が幅広の小文字で その左が幅広の文字の場合 ijlr 右に移動しない
backtrack1=("${gravityWR[@]}" \
"${gravityWN[@]}")
backtrack=("${gravitySmallWR[@]}")
input=("${_iN[@]}" "${_jN[@]}" "${_lN[@]}" "${_rN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"

# ---

# 左が左寄り、中間の小文字で 右が狭い文字の場合 acsxz 右に移動 (次の処理とセット)
backtrack=("${gravitySmallLR[@]}" "${gravitySmallMR[@]}")
input=("${_aN[@]}" "${_cN[@]}" "${_sN[@]}" "${_xN[@]}" "${_zN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が左寄り、中間の小文字、Vの字で その左が幅広の文字の場合 acsxz 右に移動しない
backtrack1=("${gravityWR[@]}" \
"${gravityWN[@]}")
backtrack=("${gravitySmallLR[@]}" "${gravitySmallMR[@]}" "${gravityVR[@]}")
input=("${_aN[@]}" "${_cN[@]}" "${_sN[@]}" "${_xN[@]}" "${_zN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"

# 大文字と小文字に関する例外処理 2 ----------------------------------------

# 左が、右が丸い文字、PRÞ の場合 右寄り、均等な小文字、丸い文字 右に移動 (丸い文字の処理と統合)
backtrack=("${circleRR[@]}" "${_PR[@]}" "${_RR[@]}" "${_THR[@]}")
input=("${gravitySmallRN[@]}" "${gravitySmallEN[@]}" \
"${circleCN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 移動しない ========================================

# 左右を見て移動させない通常処理 ----------------------------------------

# 左右を見て 左寄り、均等な文字 移動しない
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityVN[@]}")
input=("${gravityLN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左右を見て 左寄りの文字 移動しない
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityVN[@]}")
input=("${outLgravityLN[@]}")
 #input=("${gravityLN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# ---

# 左右を見て 右寄り、中間の文字 移動しない
backtrack=("${gravityLN[@]}" "${gravityMN[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左右を見て 中間の文字 移動しない
backtrack=("${gravityLN[@]}" "${gravityMN[@]}")
input=("${gravityMN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左側基準で左に移動 ========================================

# 左が丸い文字に関する例外処理 2 ----------------------------------------

# 左が、右が丸い文字で 右が幅広の文字の場合 左が丸い文字 左に移動 (この後の処理とセット)
backtrack=("${circleRL[@]}" "${circleCL[@]}" \
"${circleRN[@]}" "${circleCN[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が、右が丸い文字で 右が左寄り、右寄り、均等、中間、Vの字の場合 左が丸い文字 左に移動しない (この後の処理とセット 右が丸い文字の処理と統合)
 #backtrack=("${circleRL[@]}" "${circleCL[@]}")
 #input=("${circleLN[@]}" "${circleCN[@]}")
 #lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
 #chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が、右が丸い文字で その左が狭い文字、L の場合 左が丸い文字 右に移動 (この後の処理とセット)
backtrack1=("${gravityCL[@]}" "${_LL[@]}" \
"${gravityCR[@]}" "${_LR[@]}" \
"${gravityCN[@]}" "${_LN[@]}")
backtrack=("${circleRL[@]}" "${circleCL[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}"

# 左が、右が丸い文字の場合 左が丸い文字 左に移動しない (次の処理より前に置くこと)
backtrack=("${circleRL[@]}" "${circleCL[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 2つ左を見て移動させない例外処理 2 ----------------------------------------

# 左が左寄り、中間の文字で 右が狭い文字以外の場合 右寄り、中間、Vの字 左に移動 (前の処理より後に置くこと、次の処理とセット)
backtrack=("${gravityLL[@]}" "${gravityML[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が左寄り、中間の文字で その左が狭い文字、L の場合 右寄り、中間、Vの字 移動しない
backtrack1=("${gravityCL[@]}" "${_LL[@]}" \
"${gravityCR[@]}" "${_LR[@]}" \
"${gravityCN[@]}" "${_LN[@]}")
backtrack=("${gravityLL[@]}" "${gravityML[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"

# 左右を見て左に移動させる通常処理 ----------------------------------------

# 左側基準で 左寄り、均等な文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityML[@]}")
input=("${gravityLN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左側基準で 右寄り、中間、Vの字 左に移動
backtrack=("${gravityRL[@]}" "${gravityEL[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左側基準で Vの字 左に移動
backtrack=("${gravityRL[@]}" "${gravityEL[@]}")
input=("${gravityVN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左側基準で 幅広の文字 左に移動
backtrack=("${gravityEL[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左側基準で 幅広の文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityML[@]}" "${gravityVL[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左側基準で 狭い文字 左に移動
backtrack=("${gravityWL[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左右を見て左に移動させない通常処理 ----------------------------------------

# 左側基準で 左寄り、均等な文字 左に移動しない
backtrack=("${gravityCN[@]}")
 #backtrack=("${gravityVL[@]}" \
 #"${gravityCN[@]}")
input=("${gravityLN[@]}" "${gravityCapitalEN[@]}")
 #input=("${gravityLN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左側基準で 左寄りの文字 左に移動しない (左右を見て移動させない通常処理と統合)
backtrack=("${gravityLL[@]}" "${gravityML[@]}" "${gravityVL[@]}" \
"${gravityVN[@]}" "${gravityCN[@]}")
input=("${gravityLN[@]}")
lookAhead=("${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左側基準で 右寄り、中間の文字 左に移動しない
backtrack=("${gravityVN[@]}")
 #backtrack=("${gravityLL[@]}" "${gravityML[@]}" \
 #"${gravityVN[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左側基準で 中間の文字 左に移動しない (左右を見て移動させない通常処理と統合)
backtrack=("${gravityLN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
 #backtrack=("${gravityLL[@]}" "${gravityML[@]}" \
 #"${gravityLN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
input=("${gravityMN[@]}")
lookAhead=("${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左側基準で 幅広、狭い文字 左に移動しない
backtrack=("${gravityCN[@]}")
input=("${gravityWN[@]}" "${gravityCN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左側基準で 狭い文字 左に移動しない
backtrack=("${gravityCR[@]}" \
"${gravityLN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左側基準で Vの字 左に移動しない (なんちゃって最適化でいらない子判定)
 #backtrack=("${gravityVL[@]}")
 #input=("${gravityVN[@]}")
 #lookAhead=("${gravityCN[@]}")
 #chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左を見て左に移動させる通常処理 ----------------------------------------

# 左側基準で 全ての文字 左に移動
backtrack=("${gravityCL[@]}" \
"${gravityCN[@]}")
input=("${capitalN[@]}" "${smallN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左側基準で 幅広の文字以外 左に移動
backtrack=("${gravityVL[@]}")
input=("${outLgravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}" "${gravityCN[@]}")
 #input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}" "${gravityCN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左側基準で 右寄り、中間、Vの字、狭い文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityML[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}" "${gravityCN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左側基準で 右寄り、中間、狭い文字 左に移動
backtrack=("${gravityVN[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityCN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左側基準で 狭い文字 左に移動
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityCR[@]}" \
"${gravityLN[@]}" "${gravityMN[@]}")
input=("${gravityCN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左側基準で右に移動 ========================================

# 数字と記号に関する処理 2 ----------------------------------------

# 右が幅のある記号、数字の場合 左寄り、右寄り、幅広、均等、中間の文字 移動しない
backtrack=("")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${symbolEN[@]}" "${figureEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が丸い文字に関する例外処理 3 ----------------------------------------

# 左が、左右が丸い文字の場合 左が丸い文字 右に移動
backtrack=("${circleLR[@]}" "${circleRR[@]}" "${circleCR[@]}")
input=("${circleLN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左右を見て右に移動させない通常処理 ----------------------------------------

# 左側基準で 左寄り、均等な文字 右に移動しない
backtrack=("${gravityVR[@]}" \
"${gravityLN[@]}" "${gravityMN[@]}")
input=("${outLgravityLN[@]}" "${gravityEN[@]}")
 #input=("${gravityLN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左側基準で 均等な文字 右に移動しない
backtrack=("${gravityVR[@]}" \
"${gravityLN[@]}" "${gravityMN[@]}")
input=("${gravityEN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左側基準で 幅広の文字 右に移動しない
backtrack=("${gravityWL[@]}" \
"${gravityRN[@]}" "${gravityEN[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左側基準で 右寄りの文字 右に移動しない
backtrack=("${gravityWL[@]}" \
"${gravityLR[@]}" "${gravityRR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityRN[@]}" "${gravityEN[@]}")
input=("${gravityRN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左側基準で 幅広の文字 右に移動しない
backtrack=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}" \
"${gravityLN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左側基準で 均等、中間の文字 右に移動しない
backtrack=("${gravityLR[@]}" \
"${gravityRN[@]}" "${gravityEN[@]}")
input=("${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左側基準で 中間、Vの字 右に移動しない
backtrack=("${gravityVR[@]}")
input=("${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}" "${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左側基準で 中間の文字 右に移動しない
backtrack=("${gravityVR[@]}")
input=("${gravityMN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左側基準で Vの字 右に移動しない
backtrack=("${gravityVR[@]}")
input=("${gravityVN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左側基準で Vの字 右に移動しない
backtrack=("${gravityRR[@]}" "${gravityER[@]}")
input=("${gravityVN[@]}")
lookAhead=("${gravityWN[@]}" "${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左側基準で 狭い文字 右に移動しない
backtrack=("${gravityWR[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左側基準で 均等な文字 右に移動しない (次の処理と統合)
 #backtrack=("${gravityEN[@]}")
 #input=("${gravityEN[@]}")
 #lookAhead=("${gravityRN[@]}")
 #chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 丸い文字に関する例外処理 2 ----------------------------------------

# 左が均等な文字で 右が右寄り、丸い文字の場合 幅広、均等な文字 右に移動しない (前の処理と統合)
backtrack=("${gravityEN[@]}")
input=("${gravityWN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityRN[@]}" \
"${circleCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左を見て右に移動させる通常処理 ----------------------------------------

# 左側基準で 全ての文字 右に移動
backtrack=("${gravityWR[@]}")
input=("${capitalN[@]}" "${smallN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左側基準で 狭い文字以外 右に移動
backtrack=("${gravityRR[@]}" "${gravityER[@]}" "${gravityVR[@]}" \
"${gravityWN[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左側基準で 左寄り、右寄り、幅広、均等、中間の文字 右に移動
backtrack=("${gravityWL[@]}" \
"${outLgravityLR[@]}" "${gravityMR[@]}" \
"${gravityRN[@]}" "${gravityEN[@]}")
 #backtrack=("${gravityWL[@]}" \
 #"${gravityLR[@]}" "${gravityMR[@]}" \
 #"${gravityRN[@]}" "${gravityEN[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左側基準で 左寄り、幅広、均等な文字 右に移動
backtrack=("${outLgravityLN[@]}" "${gravityMN[@]}")
 #backtrack=("${gravityLN[@]}" "${gravityMN[@]}")
input=("${gravityLN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左側基準で 幅広の文字 右に移動
backtrack=("${outLgravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}" \
"${gravityVN[@]}")
 #backtrack=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}" \
 #"${gravityVN[@]}")
input=("${gravityWN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# もろもろ例外 ========================================

# 2つ左を見て移動させる例外処理 1 ----------------------------------------

# 右が狭い文字の場合 狭い文字 右に移動
backtrack=("")
input=("${gravityCN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が左寄り、中間の文字で 右が右寄りの小文字、中間、Vの字の場合 fir 移動しない
backtrack=("${gravityLR[@]}" "${gravityMR[@]}")
input=("${_fN[@]}" "${_iN[@]}" "${_rN[@]}")
lookAhead=("${gravitySmallRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が左寄り、中間、Vの字で その左が幅広の文字の場合 Jfijlrt 左に移動
backtrack1=("${gravityWL[@]}" \
"${gravityWR[@]}" \
"${gravityWN[@]}")
backtrack=("${gravityLR[@]}" "${gravityMR[@]}" "${gravityVR[@]}")
input=("${_JN[@]}" "${_fN[@]}" "${_iN[@]}" "${_jN[@]}" "${_lN[@]}" "${_rN[@]}" "${_tN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}"

# 左が右寄り、均等な文字で その左が幅広の文字の場合 r 左に移動
backtrack1=("${gravityWL[@]}" \
"${gravityWR[@]}" \
"${gravityWN[@]}")
backtrack=("${gravityRR[@]}" "${gravityER[@]}")
input=("${_rN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}"

# A に関する例外処理 3 ----------------------------------------

# 右が W の場合 A 右に移動しない
backtrack=("")
input=("${_AN[@]}")
lookAhead=("${_WN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右が、左下が開いている大文字の場合 A 右に移動
backtrack=("")
input=("${_AN[@]}")
lookAhead=("${lowSpaceCapitalCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 右が A の場合 右下が開いている大文字か W 右に移動
backtrack=("")
input=("${lowSpaceCapitalRN[@]}" "${lowSpaceCapitalCN[@]}" "${_WN[@]}")
lookAhead=("${_AN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# EF に関する例外処理 ----------------------------------------

# 左が EF で 右が 左寄り、均等な文字の場合 左寄りの文字 左に移動
backtrack=("${_EL[@]}" "${_FL[@]}")
input=("${gravityLN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# L に関する例外処理 2 ----------------------------------------

# 右が左寄り、幅広、均等な文字の場合 L 右に移動しない
backtrack=("")
input=("${_LN[@]}")
lookAhead=("${outLgravityLN[@]}" "${outWwgravityWN[@]}" "${gravityEN[@]}")
 #lookAhead=("${gravityLN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右が L の場合 左寄り、中間の文字 左に移動しない
backtrack=("")
input=("${outLgravityLN[@]}" "${gravityMN[@]}")
 #input=("${gravityLN[@]}" "${gravityMN[@]}")
lookAhead=("${_LN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 大文字と小文字に関する例外処理 3 ----------------------------------------

# 左が、右上が開いている文字、irt で 右が、左上が開いている文字、filrt の場合 両下が開いている大文字 移動しない
backtrack=("${highSpaceCL[@]}" \
"${highSpaceRN[@]}" "${highSpaceCN[@]}" "${_iN[@]}" "${_rN[@]}" "${_tN[@]}")
 #backtrack=("${highSpaceRL[@]}" "${highSpaceCL[@]}" \
 #"${highSpaceRN[@]}" "${highSpaceCN[@]}" "${_iN[@]}" "${_rN[@]}" "${_tN[@]}")
input=("${lowSpaceCapitalCN[@]}")
lookAhead=("${highSpaceLN[@]}" "${highSpaceCN[@]}" "${_fN[@]}" "${_iN[@]}" "${_lN[@]}" "${_rN[@]}" "${_tN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右が、左上が開いている文字の場合 FT 右に移動
backtrack=("")
input=("${_FN[@]}" "${_TN[@]}")
lookAhead=("${highSpaceLN[@]}" "${highSpaceCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 右が丸い文字に関する例外処理 2 ----------------------------------------

# 左が PRÞS で 右が左寄り、均等、左が丸い文字の場合 右が丸い文字 左に移動しない
backtrack=("${_PL[@]}" "${_RL[@]}" "${_THL[@]}" "${_SL[@]}")
input=("${circleRN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}" \
"${circleLN[@]}" "${circleCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 2つ右を見て移動させる例外処理 2 ----------------------------------------

# 左が左寄り、右寄り、均等、中間の文字で 右が右寄り、中間の文字の場合 右寄り、均等、右が丸い文字、PRÞShs 左に移動しない (次の処理とセット)
backtrack=("${gravityEL[@]}" \
"${gravityLN[@]}" "${gravityMN[@]}")
input=("${gravityRN[@]}" "${_PN[@]}" "${_RN[@]}" "${_THN[@]}" "${_SN[@]}" "${_hN[@]}" "${_sN[@]}" \
"${circleRN[@]}" "${circleCN[@]}")
 #input=("${gravityRN[@]}" "${gravityEN[@]}" "${_PN[@]}" "${_RN[@]}" "${_THN[@]}" "${_SN[@]}" "${_hN[@]}" "${_sN[@]}" \
 #"${circleRN[@]}" "${circleCN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右が L 以外の左寄り、右寄りの文字、均等、中間の大文字で その右が幅広の文字の場合 右寄り、均等、右が丸い文字、PRÞShs 左に移動
backtrack1=("")
backtrack=("")
input=("${gravityRN[@]}" "${gravityEN[@]}" "${_PN[@]}" "${_RN[@]}" "${_THN[@]}" "${_SN[@]}" "${_hN[@]}" "${_sN[@]}" \
"${circleRN[@]}" "${circleCN[@]}")
lookAhead=("${outLgravityLN[@]}" "${gravityRN[@]}" "${gravityCapitalEN[@]}" "${gravityCapitalMN[@]}")
lookAhead1=("${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 右が均等、中間の文字で その右が幅広の文字の場合 右寄り、右が丸い文字、均等な小文字、PRÞS 左に移動
backtrack1=("")
backtrack=("")
input=("${gravityRN[@]}" "${gravitySmallEN[@]}" "${_PN[@]}" "${_RN[@]}" "${_THN[@]}" "${_SN[@]}" \
"${circleCapitalRN[@]}")
lookAhead=("${gravitySmallEN[@]}" "${gravitySmallMN[@]}")
 #lookAhead=("${gravityEN[@]}" "${gravityMN[@]}")
lookAhead1=("${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 右が L 以外の左寄り、均等、左が丸い文字で その右が左寄り、右寄り、均等、中間、Vの字 t の場合 均等な小文字、右が丸い文字 左に移動 (右が丸い文字の処理と統合)
backtrack1=("")
backtrack=("")
input=("${gravitySmallEN[@]}" \
"${circleSmallRN[@]}" "${circleSmallCN[@]}")
lookAhead=("${outLgravityLN[@]}" "${gravityEN[@]}" \
"${circleLN[@]}" "${circleCN[@]}")
lookAhead1=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}" "${_tN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 右が L 以外の左寄り、均等、左が丸い文字で その右が fr の場合 均等な小文字 左に移動
backtrack1=("")
backtrack=("")
input=("${gravitySmallEN[@]}")
lookAhead=("${outLgravityLN[@]}" "${gravityEN[@]}" \
"${circleLN[@]}" "${circleCN[@]}")
lookAhead1=("${_fN[@]}" "${_rN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 右が右寄り、均等、中間の文字の場合 均等な小文字 移動しない (右が丸い文字の処理と統合)
 #backtrack=("")
 #input=("${gravitySmallEN[@]}")
 #lookAhead=("${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
 #chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右が丸い文字に関する例外処理 3 ----------------------------------------

# 右が左寄り、均等、左が丸い文字で その右が filr で その右が幅広の文字の場合 右が丸い小文字 左に移動
backtrack1=("")
backtrack=("")
input=("${circleSmallRN[@]}" "${circleSmallCN[@]}")
lookAhead=("${outLgravityLN[@]}" "${gravityEN[@]}" \
"${circleLN[@]}" "${circleCN[@]}")
lookAhead1=("${_fN[@]}" "${_iN[@]}" "${_lN[@]}" "${_rN[@]}")
lookAheadX=("${gravityWN[@]}"); aheadMax="2"
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

# 右が左寄り、均等、左が丸い文字で その右が幅広の文字、IJjt の場合 右が丸い小文字 左に移動
backtrack1=("")
backtrack=("")
input=("${circleSmallRN[@]}" "${circleSmallCN[@]}")
lookAhead=("${outLgravityLN[@]}" "${gravityEN[@]}" \
"${circleLN[@]}" "${circleCN[@]}")
lookAhead1=("${gravityWN[@]}" "${_IN[@]}" "${_JN[@]}" "${_jN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 右が左寄り、均等、左が丸い文字で その右が filr 以外の場合 右が丸い小文字 左に移動 (2つ右の処理と統合)
 #backtrack1=("")
 #backtrack=("")
 #input=("${circleSmallRN[@]}" "${circleSmallCN[@]}")
 #lookAhead=("${outLgravityLN[@]}" "${gravityEN[@]}" \
 #"${circleLN[@]}" "${circleCN[@]}")
 #lookAhead1=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}" \
 #"${_IN[@]}" "${_JN[@]}" "${_jN[@]}" "${_tN[@]}")
 #chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 右が右寄り、均等、中間の文字の場合 均等、右が丸い小文字 移動しない (2つ右の処理と統合)
backtrack=("")
input=("${gravitySmallEN[@]}" \
"${circleSmallRN[@]}" "${circleSmallCN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右が左寄りの文字の場合 右が丸い小文字 移動しない
backtrack=("")
input=("${circleSmallRN[@]}" "${circleSmallCN[@]}")
lookAhead=("${outLgravityLN[@]}")
 #lookAhead=("${gravityLN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右が、左が丸い文字の場合 右が丸い大文字 左に移動
backtrack=("")
input=("${circleCapitalRN[@]}" "${circleCapitalCN[@]}")
lookAhead=("${circleLN[@]}" "${circleCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# Jj に関する例外処理 2 ----------------------------------------

# 右が引き寄せない大文字、左寄り、幅広の文字の場合 Jj 左に移動
backtrack=("")
input=("${_JN[@]}" "${_jN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityCapitalRN[@]}" "${gravityWN[@]}" "${gravityCapitalEN[@]}" "${gravityCapitalMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 右がVの大文字の場合 J 移動しない
backtrack=("")
input=("${_JN[@]}")
lookAhead=("${gravityCapitalVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# hkĸAaSsxz に関する例外処理 ----------------------------------------

# 右が a で その右が a の場合 a 左に移動
backtrack1=("")
backtrack=("")
input=("${_aN[@]}")
lookAhead=("${_aN[@]}")
lookAhead1=("${_aN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 右が h で その右が h の場合 h 左に移動
backtrack1=("")
backtrack=("")
input=("${_hN[@]}")
lookAhead=("${_hN[@]}")
lookAhead1=("${_hN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 右が k で その右が k の場合 k 左に移動
backtrack1=("")
backtrack=("")
input=("${_kN[@]}")
lookAhead=("${_kN[@]}")
lookAhead1=("${_kN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 右が ĸ で その右が ĸ の場合 ĸ 左に移動
backtrack1=("")
backtrack=("")
input=("${_kgN[@]}")
lookAhead=("${_kgN[@]}")
lookAhead1=("${_kgN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 右が左寄り、均等な文字の場合 hASs 左に移動しない
backtrack=("")
input=("${_hN[@]}" "${_AN[@]}" "${_SN[@]}" "${_sN[@]}")
lookAhead=("${outLgravityLN[@]}" "${gravityEN[@]}")
 #lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右が hkĸ の場合 kĸxz 左に移動しない
backtrack=("")
input=("${_kN[@]}" "${_kgN[@]}" "${_xN[@]}" "${_zN[@]}")
lookAhead=("${_hN[@]}" "${_kN[@]}" "${_kgN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が EFKXkxzĸ で 右が a の場合 bhpþ 左に移動
backtrack=("${_EL[@]}" "${_FL[@]}" "${_KL[@]}" "${_XL[@]}" "${_kL[@]}" "${_xL[@]}" "${_zL[@]}" "${_kgL[@]}")
input=("${_bN[@]}" "${_hN[@]}" "${_pN[@]}" "${_thN[@]}")
lookAhead=("${_aN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# rt に関する例外処理 2 ----------------------------------------

# 右が幅広の文字の場合 rt 左に移動
backtrack=("")
input=("${_rN[@]}" "${_tN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 右が、左が丸い小文字、AXZsで その右が幅広の文字の場合 r 右に移動
backtrack1=("")
backtrack=("")
input=("${_rN[@]}")
lookAhead=("${circleSmallLN[@]}" "${circleSmallCN[@]}" "${_AN[@]}" "${_XN[@]}" "${_ZN[@]}" "${_sN[@]}")
lookAhead1=("${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 右が左寄り、右寄り、均等、中間の文字の場合 rt 右に移動しない
backtrack=("")
input=("${_rN[@]}" "${_tN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# y に関する例外処理 2 ----------------------------------------

# 右が y の場合 jpþ 右に移動しない
backtrack=("")
input=("${_jN[@]}" "${_pN[@]}" "${_thN[@]}")
lookAhead=("${_yN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 大文字と小文字で処理が異なる例外処理 2 ----------------------------------------

# 右が中間の小文字の場合 均等な大文字 左に移動
backtrack=("")
input=("${gravityCapitalEN[@]}")
lookAhead=("${gravitySmallMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 右が均等な小文字の場合 中間の文字 EKPÞkĸ 左に移動しない
backtrack=("")
input=("${outAgravityMN[@]}" "${_EN[@]}" "${_KN[@]}" "${_PN[@]}" "${_THN[@]}" "${_kN[@]}" "${_kgN[@]}")
 #input=("${gravityMN[@]}" "${_EN[@]}" "${_KN[@]}" "${_PN[@]}" "${_THN[@]}" "${_kN[@]}" "${_kgN[@]}")
lookAhead=("${gravitySmallEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右を見て移動させない例外処理 ----------------------------------------

# 右が、丸い大文字の場合 EFKXkxzĸ 左に移動しない
backtrack=("")
input=("${_EN[@]}" "${_FN[@]}" "${_KN[@]}" "${_XN[@]}" "${_kN[@]}" "${_xN[@]}" "${_zN[@]}" "${_kgN[@]}")
lookAhead=("${circleCapitalCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右側基準で左に移動 ========================================

# 左右を見て左に移動させる通常処理 ----------------------------------------

# 右側基準で 狭い文字 左に移動
backtrack=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 大文字と小文字で処理が異なる例外処理 3 ----------------------------------------

# 左が右寄り、均等、中間の大文字で 右が左寄り、右寄り、均等、中間、Vの字の場合 Ifilrt 右に移動しない (次の処理とセット)
backtrack=("${gravityCapitalRR[@]}" "${gravityCapitalER[@]}" "${gravityCapitalMR[@]}")
input=("${_IN[@]}" "${_fN[@]}" "${_iN[@]}" "${_lN[@]}" "${_rN[@]}" "${_tN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が右寄り、均等、中間の大文字の場合 Ifil 右に移動
backtrack=("${gravityCapitalRR[@]}" "${gravityCapitalER[@]}" "${gravityCapitalMR[@]}")
input=("${_IN[@]}" "${_fN[@]}" "${_iN[@]}" "${_lN[@]}" "${_rN[@]}" "${_tN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左右を見て移動させない通常処理 ----------------------------------------

# 左右を見て 左寄り、中間の文字 移動しない
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityCR[@]}")
input=("${gravityLN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左右を見て 左寄りの文字 移動しない (左右を見て左に移動させない通常処理と統合)
 #backtrack=("${gravityLL[@]}" "${gravityML[@]}" \
 #"${gravityVN[@]}")
 #input=("${gravityLN[@]}")
 #lookAhead=("${gravityVN[@]}")
 #chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左右を見て 中間の文字 移動しない (左右を見て左に移動させない通常処理と統合)
 #backtrack=("${gravityLN[@]}" "${gravityMN[@]}")
 #input=("${gravityMN[@]}")
 #lookAhead=("${gravityVN[@]}")
 #chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左右を見て左に移動させない通常処理 ----------------------------------------

# 右側基準で 左寄り、均等な文字 左に移動しない
backtrack=("${gravityVN[@]}")
input=("${outLgravityLN[@]}" "${gravityEN[@]}")
 #input=("${gravityLN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右側基準で 右寄り、中間の文字 左に移動しない
backtrack=("${gravityLN[@]}" "${gravityMN[@]}")
input=("${gravityRN[@]}")
 #input=("${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右側基準で 左寄り、中間の文字 左に移動しない
backtrack=("${gravityRL[@]}" "${gravityEL[@]}")
input=("${gravityMN[@]}")
 #input=("${gravityLN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右側基準で 左寄り 左に移動しない
backtrack=("${gravityLL[@]}" "${gravityML[@]}")
input=("${gravityLN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右側基準で 幅広の文字 左に移動しない
backtrack=("${gravityVL[@]}")
 #backtrack=("${gravityLL[@]}" "${gravityEL[@]}" "${gravityML[@]}" "${gravityVL[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
 #lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右側基準で Vの字 左に移動しない
backtrack=("${gravityWL[@]}" \
"${gravityRN[@]}" "${gravityEN[@]}")
input=("${gravityVN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が丸い文字に関する例外処理 4 ----------------------------------------

# 左が、右が丸い文字で 右が、左が丸い文字の場合 均等、左が丸い文字 左に移動しない (右が丸い文字の処理と統合)
 #backtrack=("${circleRL[@]}" "${circleCL[@]}")
 #input=("${gravityEN[@]}" \
 #"${circleLN[@]}")
 #lookAhead=("${circleLN[@]}" "${circleCN[@]}")
 #chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右が、左が丸い文字の場合 右寄りの文字 左に移動
backtrack=("")
input=("${gravityRN[@]}")
lookAhead=("${circleLN[@]}" "${circleCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 右を見て左に移動させる通常処理 ----------------------------------------

# 右側基準で 狭い文字以外 左に移動
backtrack=("")
input=("${outLgravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
 #input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 右側基準で 左寄り、右寄り、幅広、均等、中間の文字 左に移動
backtrack=("")
input=("${outLgravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${outAgravityMN[@]}")
 #input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 右側基準で 幅広の文字 左に移動
backtrack=("")
input=("${gravityWN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 右側基準で右に移動 ========================================

# 2つ右を見て移動させる例外処理 3 ----------------------------------------

# 右が t で その右が ijl の場合 左寄り、中間の文字 右に移動
backtrack1=("")
backtrack=("")
input=("${outLgravityLN[@]}" "${gravityMN[@]}")
 #input=("${gravityLN[@]}" "${gravityMN[@]}")
lookAhead=("${_tN[@]}")
lookAhead1=("${_iN[@]}" "${_jN[@]}" "${_lN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 右が Ifr で その右が ijl の場合 左寄り、右寄り、中間の文字 右に移動
backtrack1=("")
backtrack=("")
input=("${outLgravityLN[@]}" "${gravityRN[@]}" "${gravityMN[@]}")
 #input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("${_IN[@]}" "${_fN[@]}" "${_rN[@]}")
lookAhead1=("${_iN[@]}" "${_jN[@]}" "${_lN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 右が il で その右が IJfjrt の場合 左寄り、右寄り、中間の文字 右に移動
backtrack1=("")
backtrack=("")
input=("${outLgravityLN[@]}" "${gravityRN[@]}" "${gravityMN[@]}")
 #input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("${_iN[@]}" "${_lN[@]}")
lookAhead1=("${_IN[@]}" "${_JN[@]}" "${_fN[@]}" "${_jN[@]}" "${_rN[@]}" "${_tN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 右が Jj で その右が狭い文字の場合 左寄り、右寄り、均等、中間の文字 右に移動
backtrack1=("")
backtrack=("")
input=("${outLgravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
 #input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${_JN[@]}" "${_jN[@]}")
lookAhead1=("${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 右が狭い文字で その右が狭い文字以外の場合 均等な小文字 右に移動
backtrack1=("")
backtrack=("")
input=("${gravitySmallEN[@]}")
lookAhead=("${gravityCN[@]}")
lookAhead1=("${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 右が狭い文字で その右が狭い文字で その右が幅広、狭い文字の場合 左寄り、中間の文字 右に移動
backtrack1=("")
backtrack=("")
input=("${outLgravityLN[@]}" "${gravityMN[@]}")
 #input=("${gravityLN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityCN[@]}")
lookAhead1=("${gravityCN[@]}")
lookAheadX=("${gravityWN[@]}" "${gravityCN[@]}"); aheadMax="2"
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

# 右が狭い文字で その右が狭い文字以外の場合 左寄り、右寄り、幅広、均等、中間の文字 右に移動
backtrack1=("")
backtrack=("")
input=("${outLgravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
 #input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityCN[@]}")
lookAhead1=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityWN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ---

# 右が VY で その右が幅広の文字以外の場合 左寄り、中間の大文字 右に移動
backtrack1=("")
backtrack=("")
input=("${outLgravityCapitalLN[@]}" "${outAgravityCapitalMN[@]}")
 #input=("${gravityCapitalLN[@]}" "${gravityCapitalMN[@]}")
lookAhead=("${_VN[@]}" "${_YN[@]}")
lookAhead1=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}" "${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 右が T の場合 左寄り、中間の大文字 右に移動
backtrack=("")
input=("${outLgravityCapitalLN[@]}" "${outAgravityCapitalMN[@]}")
 #input=("${gravityCapitalLN[@]}" "${gravityCapitalMN[@]}")
lookAhead=("${_TN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 右がVの小文字で その右が幅広の文字以外の場合 BDS 右に移動
backtrack1=("")
backtrack=("")
input=("${_BN[@]}" "${_DN[@]}" "${_SN[@]}")
lookAhead=("${gravitySmallVN[@]}")
lookAhead1=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}" "${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 右がVの小文字の場合 EFKPRÞXZ 右に移動
backtrack=("")
input=("${_EN[@]}" "${_KN[@]}" "${_PN[@]}" "${_RN[@]}" "${_THN[@]}" "${_XN[@]}" "${_ZN[@]}")
 #input=("${_EN[@]}" "${_FN[@]}" "${_KN[@]}" "${_PN[@]}" "${_RN[@]}" "${_THN[@]}" "${_XN[@]}" "${_ZN[@]}")
lookAhead=("${gravitySmallVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 右が Vの字の場合 左寄り、中間の小文字 右に移動
backtrack=("")
input=("${gravitySmallLN[@]}" "${gravitySmallMN[@]}")
lookAhead=("${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左右を見て右に移動させる通常処理 ----------------------------------------

# 右側基準で 左寄り、均等な文字 右に移動
backtrack=("${gravityVN[@]}")
input=("${gravityLN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 右側基準で 右寄り、中間の文字 右に移動
backtrack=("${gravityLN[@]}" "${gravityMN[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 右側基準で 幅広の文字 右に移動
backtrack=("${gravityEL[@]}" \
"${gravityCR[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左右を見て右に移動させない通常処理 ----------------------------------------

# 右側基準で Vの字 右に移動しない
backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityLR[@]}" "${gravityMR[@]}" \
"${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
 #backtrack=("${gravityRL[@]}" "${gravityEL[@]}" \
 #"${gravityLR[@]}" "${gravityMR[@]}" "${gravityCR[@]}" \
 #"${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
input=("${gravityVN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右側基準で 狭い文字 右に移動しない
backtrack=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}" \
"${gravityRN[@]}" "${gravityEN[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右側基準で 狭い文字 右に移動しない
backtrack=("${gravityWN[@]}")
input=("${gravityCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右を見て右に移動させる通常処理 ----------------------------------------

# 右側基準で Vの字、狭い文字 右に移動
backtrack=("")
input=("${gravityVN[@]}" "${gravityCN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 右側基準で 狭い文字 右に移動
backtrack=("")
input=("${gravityCN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}" "${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 2つ左を見て移動させる例外処理 2 ----------------------------------------

# 右が右寄り、中間、Vの字、幅のある記号、数字の場合の場合 左寄り、右寄り、均等、中間の文字 右に移動しない (次の処理とセット)
backtrack=("")
input=("${outLgravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
 #input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityRN[@]}" "${gravityMN[@]}" "${gravityVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が左寄り、右寄り、均等、中間の文字で その左が狭い文字、L の場合 左寄り、右寄り、均等、中間の文字 右に移動
backtrack1=("${gravityCL[@]}" "${_LL[@]}" \
"${gravityCR[@]}" "${_LR[@]}" \
"${gravityCN[@]}" "${_LN[@]}")
backtrack=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}"

# 左がVの字で その左が狭い文字、L の場合 幅広の文字 右に移動
backtrack1=("${gravityCL[@]}" "${_LL[@]}" \
"${gravityCR[@]}" "${_LR[@]}" \
"${gravityCN[@]}" "${_LN[@]}")
backtrack=("${gravityVL[@]}")
input=("${gravityWN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}"

# 左が HNUGadgq で その左が左寄り、中間、Vの字、丸い文字の場合 左寄りの文字、均等な大文字 右に移動
backtrack1=("${gravityLL[@]}" "${gravityML[@]}" "${gravityVL[@]}" \
"${circleCL[@]}")
backtrack=("${_HL[@]}" "${_NL[@]}" "${_UL[@]}" "${_GL[@]}" "${_aL[@]}" "${_dL[@]}" "${_gL[@]}" "${_qL[@]}")
input=("${gravityLN[@]}" "${gravityCapitalEN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}"

# 左が丸い文字に関する例外処理 5 ----------------------------------------

# 左が、右が丸い文字、h の場合 左が丸い文字 右に移動
backtrack=("${circleRN[@]}" "${circleSmallCN[@]}" "${_hN[@]}")
 #backtrack=("${circleRN[@]}" "${circleCN[@]}" "${_hN[@]}")
input=("${circleLN[@]}" "${circleSmallCN[@]}")
 #input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左を見て移動させる例外処理 ----------------------------------------

# 左が均等な小文字の場合 狭い文字 左に移動
backtrack=("${gravitySmallEN[@]}")
input=("${gravityCN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

fi
# 記号類 ++++++++++++++++++++++++++++++++++++++++

# |: に関する処理 ----------------------------------------

# 左が上下対称な演算子、|~: の場合 | 下に : 上に移動
backtrack=("${_barD[@]}" "${_tildeD[@]}" "${_colonU[@]}" \
"${operatorHN[@]}" "${_lessN[@]}" "${_greaterN[@]}")
input=("${_barN[@]}" "${_colonN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"

# 右が上下対称な演算子、<> の場合 | 下に : 上に移動
backtrack=("")
input=("${_barN[@]}" "${_colonN[@]}")
lookAhead=("${operatorHN[@]}" "${_lessN[@]}" "${_greaterN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"

# 右が : の場合 | 下に移動
backtrack=("")
input=("${_barN[@]}")
lookAhead=("${_colonN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"

# 右が | の場合 : 上に移動
backtrack=("")
input=("${_colonN[@]}")
lookAhead=("${_barN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"

# 両側が数字の場合 : 上に移動
backtrack=("${figureN[@]}")
input=("${_colonN[@]}")
lookAhead=("${figureN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"

# ~ に関する処理 ----------------------------------------

# 左が <>|~: の場合 ~ 下に移動
backtrack=("${_barD[@]}" "${_tildeD[@]}" "${_colonU[@]}" \
"${_lessN[@]}" "${_greaterN[@]}")
input=("${_tildeN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"

# 右が <> の場合 ~ 下に移動
backtrack=("")
input=("${_tildeN[@]}")
lookAhead=("${_lessN[@]}" "${_greaterN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"

#CALT0
#<< "#CALT1" # アルファベット・記号 ||||||||||||||||||||||||||||||||||||||||

pre_add_lookup

# アルファベット ++++++++++++++++++++++++++++++++++++++++
if [ "${symbol_only_flag}" = "false" ]; then

# 同じ文字を等間隔にさせる処理 ----------------------------------------

# j
  # 右から元に戻る (広がる)
backtrack1=("")
backtrack=("")
input=("${_jR[@]}")
lookAhead=("${_jN[@]}")
lookAhead1=("${_jL[@]}")
lookAheadX=("${_jL[@]}"); aheadMax="2"
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

# L
  # 右から元に戻る (広がる)
backtrack1=("")
backtrack=("")
input=("${_LR[@]}")
lookAhead=("${_LN[@]}")
lookAhead1=("${_LL[@]}")
lookAheadX=("${_LL[@]}"); aheadMax="2"
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

  # 左から元に戻る (広がる)
backtrack1=("${_LN[@]}")
backtrack=("${_LN[@]}")
input=("${_LL[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"

# 丸い小文字
class=("_e" "_o")
for S in ${class[@]}; do
  # 左から元に戻る (縮む)
  backtrack1=("")
  backtrack=("")
  eval input=("\${${S}L[@]}")
  eval lookAhead=("\${${S}N[@]}")
  eval lookAhead1=("\${${S}R[@]}")
  eval lookAheadX=("\${${S}R[@]}"); aheadMax="2"
  chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

  # 右から元に戻る (縮む)
  eval backtrack1=("\${${S}N[@]}")
  eval backtrack=("\${${S}N[@]}")
  eval input=("\${${S}R[@]}")
  lookAhead=("")
  chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"
done

# 丸くない右寄りの文字、hkĸ
class=("_a" "_h" "_k" "_kg")
for S in ${class[@]}; do
  # 左から元に戻る (縮む)
  backtrack1=("")
  backtrack=("")
  eval input=("\${${S}L[@]}")
  eval lookAhead=("\${${S}L[@]}")
  eval lookAhead1=("\${${S}L[@]}" "\${${S}N[@]}")
  chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"

  # 左から元に戻る
  eval backtrack=("\${${S}N[@]}")
  eval input=("\${${S}L[@]}")
  eval lookAhead=("\${${S}N[@]}")
  chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
 done

# L 以外の左寄りの大文字、左が丸い文字、右が丸い文字
class=("_B" "_D" "_E" "_F" "_K" "_P" "_R" "_TH" "_C" "_G" "_c" "_d" "_g" "_q" "_b" "_p" "_th")
for S in ${class[@]}; do
  # 左から元に戻る (縮む)
  backtrack1=("")
  backtrack=("")
  eval input=("\${${S}L[@]}")
  eval lookAhead=("\${${S}N[@]}")
  eval lookAhead1=("\${${S}N[@]}")
  chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"
 done

# L 以外の左寄りの文字、右寄りの文字
class=("_B" "_D" "_E" "_F" "_K" "_P" "_R" "_TH" "_b" "_h" "_k" "_p" "_th" "_kg" \
"_C" "_G" "_a" "_c" "_d" "_g" "_q")
for S in ${class[@]}; do
  # 右から元に戻る (縮む)
  eval backtrack1=("\${${S}N[@]}")
  eval backtrack=("\${${S}N[@]}")
  eval input=("\${${S}R[@]}")
  lookAhead=("")
  chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"
 done

# 移動しない文字以外の幅広の文字
class=("_M" "_W" "_m" "_w")
for S in ${class[@]}; do
  # 左から元に戻る (縮む)
  backtrack1=("")
  backtrack=("")
  eval input=("\${${S}L[@]}")
  eval lookAhead=("\${${S}N[@]}")
  eval lookAhead1=("\${${S}N[@]}")
  chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"

  # 右から元に戻る (縮む)
  eval backtrack1=("\${${S}N[@]}")
  eval backtrack=("\${${S}N[@]}")
  eval input=("\${${S}R[@]}")
  lookAhead=("")
  chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"
 done

# 均等な文字
class=("_H" "_N" "_O" "_Q" "_U" "_n" "_u")
for S in ${class[@]}; do
  # 左から元に戻る (縮む)
  backtrack1=("")
  backtrack=("")
  eval input=(\"\${${S}L[@]}\")
  eval lookAhead=("\${${S}N[@]}")
  eval lookAhead1=("\${${S}R[@]}" "\${${S}N[@]}")
  eval lookAheadX=("\${${S}R[@]}" "\${${S}N[@]}"); aheadMax="2"
  chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

  # 右から元に戻る (縮む)
  eval backtrack1=("\${${S}N[@]}")
  eval backtrack=("\${${S}N[@]}")
  eval input=("\${${S}R[@]}")
  lookAhead=("")
  chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"
 done

# 狭い文字
class=("_I" "_J" "_f" "_i" "_j" "_l" "_r" "_t")
for S in ${class[@]}; do
  if [ "${S}" != "_j" ]; then
  # 右から元に戻る (広がる) j 以外
    backtrack1=("")
    backtrack=("")
    eval input=("\${${S}R[@]}")
    eval lookAhead=("\${${S}N[@]}")
    eval lookAhead1=("\${${S}N[@]}")
    chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"
     fi

  # 左から元に戻る (広がる)
  eval backtrack1=("\${${S}N[@]}")
  eval backtrack=("\${${S}N[@]}")
  eval input=("\${${S}L[@]}")
  lookAhead=("")
  chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"
 done

# 移動しない、元に戻らない処理 ----------------------------------------

# 左が均等、右が丸い大文字の場合 右寄り、中間の文字 左に移動しない
backtrack=("${gravityCapitalEL[@]}" \
"${circleCapitalRL[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右が、左が丸い文字の場合 EFKXkĸxz 左に移動しない
backtrack=("")
input=("${_EN[@]}" "${_FN[@]}" "${_KN[@]}" "${_XN[@]}" "${_kN[@]}" "${_xN[@]}" "${_zN[@]}" "${_kgN[@]}")
lookAhead=("${circleLL[@]}" "${circleCL[@]}" \
"${circleLN[@]}" "${circleCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右が、左上が開いている文字 A の場合 FP 左に移動しない
backtrack=("")
input=("${_FN[@]}" "${_PN[@]}")
lookAhead=("${highSpaceLL[@]}" "${highSpaceCL[@]}" "${_AL[@]}" \
"${highSpaceLN[@]}" "${highSpaceCN[@]}" "${_AN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右が、左下が開いている文字 Ww の場合 A 左に移動しない
backtrack=("")
input=("${_AN[@]}")
lookAhead=("${lowSpaceLL[@]}" "${lowSpaceCL[@]}" "${_WL[@]}" "${_wL[@]}" \
"${lowSpaceLN[@]}" "${lowSpaceCN[@]}" "${_WN[@]}" "${_wN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右が、左上が開いている文字 A の場合 FP 元に戻らない
backtrack=("")
input=("${_FR[@]}" "${_PR[@]}")
lookAhead=("${highSpaceLL[@]}" "${highSpaceCL[@]}" "${_AL[@]}" \
"${highSpaceLN[@]}" "${highSpaceCN[@]}" "${_AN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 右が、左下が開いている文字 Ww の場合 A 元に戻らない
backtrack=("")
input=("${_AR[@]}")
lookAhead=("${lowSpaceLL[@]}" "${lowSpaceCL[@]}" "${_WL[@]}" "${_wL[@]}" \
"${lowSpaceLN[@]}" "${lowSpaceCN[@]}" "${_WN[@]}" "${_wN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 丸い文字と均等な文字が並んだ場合の処理 ----------------------------------------

# 左が、左が丸い文字の場合 均等な文字 元の位置に戻らない
backtrack=("${circleLN[@]}")
input=("${gravityER[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 右が c の場合 右が丸い、均等な小文字 元の位置に戻らない
backtrack=("")
input=("${gravitySmallER[@]}" \
"${circleSmallRR[@]}" "${circleSmallCR[@]}")
lookAhead=("${_cR[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 大文字 ----

# 左が、左右が丸い大文字で 右が、左右が丸い大文字の場合 左右が丸い、均等な大文字 元に戻る
backtrack=("${circleCapitalLN[@]}" "${circleCapitalRN[@]}" "${circleCapitalCN[@]}")
input=("${circleCapitalLR[@]}" "${circleCapitalRR[@]}" "${circleCapitalCR[@]}" \
"${gravityCapitalER[@]}")
lookAhead=("${circleCapitalLR[@]}" "${circleCapitalRR[@]}" "${circleCapitalCR[@]}" \
"${circleCapitalLN[@]}" "${circleCapitalRN[@]}" "${circleCapitalCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が、右寄り、均等な大文字で 右が、均等な大文字の場合 左右が丸い、均等な大文字 元に戻る
backtrack=("${gravityCapitalRN[@]}" "${gravityCapitalEN[@]}")
input=("${circleCapitalLR[@]}" "${circleCapitalRR[@]}" "${circleCapitalCR[@]}" \
"${gravityCapitalER[@]}")
lookAhead=("${gravityCapitalER[@]}" \
"${gravityCapitalEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 小文字 ---

# 左が、左右が丸い小文字で 右が、左右が丸い小文字の場合 左が丸い、均等な小文字 元に戻る
backtrack=("${circleSmallLN[@]}" "${circleSmallRN[@]}" "${circleSmallCN[@]}")
input=("${circleSmallLR[@]}" "${circleSmallCR[@]}" \
"${gravitySmallER[@]}")
lookAhead=("${circleSmallLR[@]}" "${circleSmallRR[@]}" "${circleSmallCR[@]}" \
"${circleSmallLN[@]}" "${circleSmallRN[@]}" "${circleSmallCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が、右が丸い、右寄り、均等な小文字で 右が、左寄り、均等な小文字の場合 左が丸い、均等な小文字 元に戻る
backtrack=("${circleSmallRN[@]}" "${circleSmallCN[@]}" \
"${gravitySmallRN[@]}" "${gravitySmallEN[@]}")
input=("${circleSmallLR[@]}" "${circleSmallCR[@]}" \
"${gravitySmallER[@]}")
lookAhead=("${gravitySmallLR[@]}" "${gravitySmallER[@]}" \
"${gravitySmallLN[@]}" "${gravitySmallEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が、右が丸い小文字で 右が、左右が丸い小文字の場合 右が丸い小文字 元に戻る
backtrack=("${circleSmallRN[@]}" "${circleSmallCN[@]}")
input=("${circleSmallRR[@]}")
lookAhead=("${circleSmallLR[@]}" "${circleSmallRR[@]}" "${circleSmallCR[@]}" \
"${circleSmallLN[@]}" "${circleSmallRN[@]}" "${circleSmallCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が均等、右が丸い小文字で 右が、左寄り、均等な小文字の場合 右が丸い小文字 元に戻る
backtrack=("${gravitySmallEN[@]}" \
"${circleSmallRN[@]}" "${circleSmallCN[@]}")
input=("${circleSmallRR[@]}")
lookAhead=("${gravitySmallLR[@]}" "${gravitySmallER[@]}" \
"${gravitySmallLN[@]}" "${gravitySmallEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右に幅広が来た時に左側を詰める処理の始め ----------------------------------------

# 左が幅広、均等、右が丸い文字で 右が右寄り、均等、右が丸い文字の場合 均等、丸い文字 元に戻る (右側が戻った処理と統合)
backtrack=("${gravityWL[@]}" \
"${gravityER[@]}" \
"${circleRR[@]}" "${circleCR[@]}")
input=("${gravityER[@]}" \
"${circleCR[@]}")
lookAhead=("${gravityRN[@]}" "${gravityEN[@]}" \
"${circleRN[@]}" "${circleCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# ---

# 左が右寄り、均等な文字で 右が Ww の場合 左寄り、右寄り、均等、中間の文字 左に移動しない (次の処理とセット)
backtrack=("${gravityRN[@]}" "${gravityEN[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${_WN[@]}" "${_wN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が右寄りの文字で その左が左寄り、右寄り、均等、中間の文字で 右が幅広の文字の場合 L 以外の左寄りの文字 左に移動
backtrack1=("${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityLN[@]}" "${gravityMN[@]}")
backtrack=("${gravityRN[@]}")
input=("${outLgravityLN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}"

# 左が左寄り、右寄り、均等、中間の文字で 右が幅広の文字の場合 L 以外の左寄り、右寄り、均等、中間の文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}" \
"${gravityLN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
input=("${outLgravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が左寄り、右寄り、均等、中間の文字で 右が Ww 以外の幅広の文字の場合 右寄りの文字 左に移動
backtrack=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}" \
"${gravityEN[@]}")
input=("${gravityRN[@]}")
lookAhead=("${outWwgravityWR[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が左寄り、右寄り、中間の文字で 右が幅広の文字の場合 右寄り、均等、A 以外の中間の文字 左に移動
backtrack=("${gravityRN[@]}" \
"${gravityLR[@]}" "${gravityMR[@]}")
input=("${gravityRN[@]}" "${gravityEN[@]}" "${outAgravityMN[@]}")
lookAhead=("${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 右側が元に戻って詰まった間隔を整える処理 ----------------------------------------

# 左が幅広の文字で 右が右寄りの文字の場合 均等、丸い文字 元に戻る (右に幅広の処理と統合)
 #backtrack=("${gravityWL[@]}")
 #input=("${gravityER[@]}" \
 #"${circleCR[@]}")
 #lookAhead=("${gravityRN[@]}")
 #chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が、左が丸い小文字で 右が、左が丸い小文字の場合 均等、右が丸い文字 元に戻らない (次の処理とセット)
backtrack=("${circleSmallLN[@]}")
input=("${gravityCapitalER[@]}" \
"${circleRR[@]}")
 #input=("${gravityER[@]}" \
 #"${circleRR[@]}" "${circleCR[@]}")
lookAhead=("${circleSmallLN[@]}" "${circleSmallCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が右寄り、均等な小文字で 右が左寄り、右寄り、均等、丸い文字の場合 均等、右が丸い文字 元に戻る
backtrack=("${gravitySmallRN[@]}" "${gravitySmallEN[@]}")
input=("${gravityER[@]}" \
"${circleRR[@]}" "${circleCR[@]}")
lookAhead=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" \
"${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" \
"${circleCL[@]}" \
"${circleCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右側が左に寄った、または元に戻って詰まった間隔を整える処理 1回目----------------------------------------

# 左が EFKLXkĸxz で 右が左寄り、右寄り、均等、中間の文字の場合 右寄り、均等、中間の文字、h 左に移動
backtrack=("${_ER[@]}" "${_FR[@]}" "${_KR[@]}" "${_LR[@]}" "${_XR[@]}" "${_kR[@]}" "${_xR[@]}" "${_zR[@]}" "${_kgR[@]}")
input=("${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${_hN[@]}")
lookAhead=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が Shs で 右が左寄り、右寄り、均等、中間の文字の場合 右寄り、中間の文字 左に移動
backtrack=("${_SR[@]}" "${_hR[@]}" "${_sR[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ---

# 左が左寄り、均等、中間の文字、右寄りの小文字で 右が左寄り、右寄り、均等、左が丸い文字の場合 右寄り、中間の文字 左に移動
backtrack=("${gravityLL[@]}" "${gravitySmallRL[@]}" "${gravityEL[@]}" "${gravityML[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" \
"${circleCL[@]}" \
"${gravityLN[@]}" "${outcgravityRN[@]}" "${gravityCapitalEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が左寄り、均等、中間の文字、右寄りの小文字で 右が均等、左が丸い文字の場合 右寄りの文字 左に移動
backtrack=("${gravityLL[@]}" "${gravitySmallRL[@]}" "${gravityEL[@]}" "${gravityML[@]}")
input=("${gravityRN[@]}")
lookAhead=("${gravitySmallEN[@]}" \
"${circleCN[@]}" "${_cN[@]}")
 #lookAhead=("${gravityEN[@]}" \
 #"${circleLN[@]}" "${circleCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が、右が丸い小文字で 右が右寄り、丸い文字の場合 丸い小文字 左に移動
backtrack=("${circleSmallRL[@]}" "${circleSmallCL[@]}")
input=("${circleSmallCN[@]}")
lookAhead=("${circleSmallCN[@]}" "${_cN[@]}")
 #lookAhead=("${gravityRN[@]}" \
 #"${circleCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が、右が丸い大文字、R で 右が左寄り、均等な文字の場合 左寄りの文字 左に移動しない
backtrack=("${_RL[@]}" \
"${circleCapitalRL[@]}")
input=("${gravityLN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が左寄り、中間の文字で 右が左寄りの文字の場合 EFKkĸ 左に移動しない
backtrack=("${gravityLL[@]}" "${gravityML[@]}")
input=("${_EN[@]}" "${_FN[@]}" "${_KN[@]}" "${_kN[@]}" "${_kgN[@]}")
lookAhead=("${gravityLN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が均等な小文字、h で 右が左寄り、均等な文字の場合 hkĸ 左に移動しない
backtrack=("${gravitySmallEL[@]}" "${_hL[@]}")
input=("${_hN[@]}" "${_kN[@]}" "${_kgN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が均等、中間の小文字、左寄り、中間、丸い文字、Cc で 右が中間の大文字、左寄り、右寄り、均等な文字の場合 L 以外の左寄り、均等な文字 左に移動
backtrack=("${gravityLL[@]}" "${gravitySmallEL[@]}" "${gravityML[@]}" \
"${circleCL[@]}" \
"${_CL[@]}" "${_cL[@]}")
input=("${outLgravityLN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityCapitalML[@]}" \
"${gravityLN[@]}" "${gravityCapitalEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が右寄りの小文字で 右が中間の大文字、左寄り、右寄り、均等な文字の場合 均等な小文字 左に移動
backtrack=("${outcgravitySmallRL[@]}")
 #backtrack=("${gravitySmallRL[@]}")
input=("${gravitySmallEN[@]}")
lookAhead=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityCapitalML[@]}" \
"${gravityLN[@]}" "${gravityCapitalEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が均等な小文字、左寄り、中間、丸い文字、Cc で 右が均等、中間の文字の場合 均等な文字、右が丸い文字 左に移動
backtrack=("${gravityLL[@]}" "${gravitySmallEL[@]}" "${gravityML[@]}" \
"${circleCL[@]}" \
"${_CL[@]}" "${_cL[@]}")
input=("${gravityEN[@]}" \
"${circleRN[@]}")
lookAhead=("${gravitySmallML[@]}" \
"${gravitySmallEN[@]}")
 #lookAhead=("${gravityML[@]}" \
 #"${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が右寄り、均等な文字で 右が左寄りの文字、右寄り、均等、中間の大文字の場合 丸い大文字、右が丸い文字 左に移動
backtrack=("${outcgravityRL[@]}" "${gravityCapitalEL[@]}")
 #backtrack=("${gravityRL[@]}" "${gravityEL[@]}")
input=("${circleRN[@]}" "${circleCapitalCN[@]}")
lookAhead=("${gravityLL[@]}" "${gravityCapitalRL[@]}" "${gravityCapitalEL[@]}" "${gravityCapitalML[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ---

# 左が EFKLXkĸxz で 右が左寄り、c 以外の右寄り、均等、左が丸い、Ww 以外の幅広の文字の場合 右寄り、均等、中間の文字 左に移動
backtrack=("${_EN[@]}" "${_FN[@]}" "${_KN[@]}" "${_LN[@]}" "${_XN[@]}" "${_kN[@]}" "${_kgN[@]}" "${_xN[@]}" "${_zN[@]}")
input=("${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityLN[@]}" "${outcgravityRN[@]}" "${gravityEN[@]}" \
"${outWwgravityWR[@]}" \
"${circleCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が Vの大文字、EFKLX で 右が左寄り、c 以外の右寄り、均等、丸い文字の場合 右寄り、中間の文字、均等な小文字、h 左に移動
backtrack=("${gravitCapitalVN[@]}" "${_EN[@]}" "${_FN[@]}" "${_KN[@]}" "${_LN[@]}" "${_XN[@]}")
input=("${gravityRN[@]}" "${gravitySmallEN[@]}" "${gravityMN[@]}" "${_hN[@]}")
lookAhead=("${gravityLL[@]}" "${outcgravityRL[@]}" "${gravityEL[@]}" \
"${circleCL[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左がVの小文字、hkĸsxz で 右が左寄り、均等な文字の場合 L 以外の左寄り、c 以外の右寄り、均等、中間の文字 左に移動
backtrack=("${gravitySmallVN[@]}" "${_hN[@]}" "${_kN[@]}" "${_kgN[@]}" "${_sN[@]}" "${_xN[@]}" "${_zN[@]}")
input=("${outLgravityLN[@]}" "${outcgravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityLL[@]}" "${gravityEL[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左がVの小文字、hkĸsxz で 右が c 以外の右寄り、均等、丸い文字の場合 右寄り、均等、中間の文字、h 左に移動
backtrack=("${gravitySmallVN[@]}" "${_hN[@]}" "${_kN[@]}" "${_kgN[@]}" "${_sN[@]}" "${_xN[@]}" "${_zN[@]}")
input=("${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${_hN[@]}")
lookAhead=("${outcgravityRL[@]}" "${gravityEL[@]}" \
"${circleCL[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ---

# 左が EKPXhkĸsxz で 右が左寄り、右寄り、均等、丸い文字の場合 a 左に移動
backtrack=("${_EN[@]}" "${_KN[@]}" "${_PN[@]}" "${_XN[@]}" "${_hN[@]}" "${_kN[@]}" "${_sN[@]}" "${_xN[@]}" "${_zN[@]}" "${_kgN[@]}")
input=("${_aN[@]}")
lookAhead=("${gravityRL[@]}" \
"${circleCL[@]}" \
"${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" \
"${circleCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が P で 右が左寄り、右寄り、均等、中間の文字の場合 左上が開いている文字 左に移動
backtrack=("${_PN[@]}")
input=("${highSpaceSmallLN[@]}" "${highSpaceSmallCN[@]}")
lookAhead=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}" \
"${gravityLN[@]}" "${gravityCapitalEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 右側が右に移動したため開いた間隔を詰める処理 ----------------------------------------

# 左が Ww で 右がVの字、狭い文字 s の場合 右寄り、中間の文字 右に移動
backtrack=("${_WL[@]}" "${_wL[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityVR[@]}" "${gravityCR[@]}" "${_sR[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左がVの大文字、狭い大文字で 右が狭い小文字 sv の場合 右寄り、均等な小文字 右に移動
backtrack=("${gravityCapitalVR[@]}" "${gravityCapitalCR[@]}")
input=("${gravitySmallRN[@]}" "${gravitySmallEN[@]}")
lookAhead=("${gravitySmallCR[@]}" "${_sR[@]}" "${_vR[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が、右が丸い文字で 右が幅広の文字の場合 右が丸い文字 元に戻る
backtrack=("${circleRN[@]}" "${circleCN[@]}")
input=("${circleRL[@]}" "${circleCL[@]}")
lookAhead=("${gravityWR[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が右寄り、均等な文字で 右が左寄り、均等な文字の場合 左寄り、右寄り、均等、中間の文字 元に戻る
backtrack=("${gravityRL[@]}" "${gravityEL[@]}")
input=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}")
lookAhead=("${gravityLR[@]}" "${gravityER[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が右寄り、均等な文字で 右が幅広の文字の場合 左寄り、丸い文字、均等な大文字 元に戻る
backtrack=("${gravityRL[@]}" "${gravityEL[@]}")
input=("${gravityLL[@]}" "${gravityCapitalEL[@]}" \
"${circleCL[@]}")
lookAhead=("${gravityWR[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右側が右に移動しないため開いた間隔を詰める処理 ----------------------------------------

# 左が右寄り、均等、中間、右が丸い、Vの大文字で 右が右寄り、均等、中間、Vの小文字の場合 Vの字 右に移動
backtrack=("${gravityCapitalMR[@]}" \
"${gravityCapitalRN[@]}" "${gravityCapitalEN[@]}" "${gravityCapitalVN[@]}" \
"${circleCapitalRR[@]}")
input=("${gravityVN[@]}")
lookAhead=("${gravitySmallRN[@]}" "${gravitySmallEN[@]}" "${gravitySmallMN[@]}" "${gravitySmallVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が EFKPRÞ で 右が右寄り、均等、中間、Vの小文字の場合 Vの大文字 右に移動
backtrack=("${_ER[@]}" "${_FR[@]}" "${_KR[@]}" "${_PR[@]}" "${_RR[@]}" "${_THR[@]}")
input=("${gravityCapitalVN[@]}")
lookAhead=("${gravitySmallRN[@]}" "${gravitySmallEN[@]}" "${gravitySmallMN[@]}" "${gravitySmallVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

fi
# 記号類 ++++++++++++++++++++++++++++++++++++++++

# |~: に関する処理 2回目 ----------------------------------------

# 右が |~: の場合 |~ 下に : 上に移動
backtrack=("")
input=("${_barN[@]}" "${_tildeN[@]}" "${_colonN[@]}")
lookAhead=("${_barD[@]}" "${_tildeD[@]}" "${_colonU[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"

#CALT1
#<< "#CALT2" # アルファベット・記号 ||||||||||||||||||||||||||||||||||||||||

pre_add_lookup

# アルファベット ++++++++++++++++++++++++++++++++++++++++
if [ "${symbol_only_flag}" = "false" ]; then

# 移動しない、元に戻らない処理 ----------------------------------------

# 左が均等、右が丸い大文字の場合 右寄り、中間の文字 左に移動しない
backtrack=("${gravityCapitalEL[@]}" \
"${circleCapitalRL[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右が、左が丸い文字の場合 EFKXkĸxz 左に移動しない
backtrack=("")
input=("${_EN[@]}" "${_FN[@]}" "${_KN[@]}" "${_XN[@]}" "${_kN[@]}" "${_xN[@]}" "${_zN[@]}" "${_kgN[@]}")
lookAhead=("${circleLL[@]}" "${circleCL[@]}" \
"${circleLN[@]}" "${circleCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右が、左上が開いている文字 A の場合 FP 左に移動しない
backtrack=("")
input=("${_FN[@]}" "${_PN[@]}")
lookAhead=("${highSpaceLL[@]}" "${highSpaceCL[@]}" "${_AL[@]}" \
"${highSpaceLN[@]}" "${highSpaceCN[@]}" "${_AN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右が、左下が開いている文字 Ww の場合 A 左に移動しない
backtrack=("")
input=("${_AN[@]}")
lookAhead=("${lowSpaceLL[@]}" "${lowSpaceCL[@]}" "${_WL[@]}" "${_wL[@]}" \
"${lowSpaceLN[@]}" "${lowSpaceCN[@]}" "${_WN[@]}" "${_wN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右が、左上が開いている文字 A の場合 FP 元に戻らない
backtrack=("")
input=("${_FR[@]}" "${_PR[@]}")
lookAhead=("${highSpaceLL[@]}" "${highSpaceCL[@]}" "${_AL[@]}" \
"${highSpaceLN[@]}" "${highSpaceCN[@]}" "${_AN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 右が、左下が開いている文字 Ww の場合 A 元に戻らない
backtrack=("")
input=("${_AR[@]}")
lookAhead=("${lowSpaceLL[@]}" "${lowSpaceCL[@]}" "${_WL[@]}" "${_wL[@]}" \
"${lowSpaceLN[@]}" "${lowSpaceCN[@]}" "${_WN[@]}" "${_wN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左側が元に戻って開いた間隔を整える処理 ----------------------------------------

# 左が cw で 右が右寄り、丸い小文字の場合 h 元に戻る
backtrack=("${_cN[@]}" "${_wN[@]}")
input=("${_hR[@]}")
lookAhead=("${gravitySmallRN[@]}" \
"${circleSmallCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左右が中間の小文字の場合 h 元に戻る
backtrack=("${gravitySmallMN[@]}")
input=("${_hR[@]}")
lookAhead=("${gravitySmallMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右に幅広が来た時に左側を詰める処理の続き ----------------------------------------

# 左が均等、右が丸い文字で 右が均等、左右が丸い文字の場合 均等、丸い文字 元に戻る
backtrack=("${gravityER[@]}" \
"${circleRR[@]}" "${circleCR[@]}")
input=("${gravityER[@]}" \
"${circleCR[@]}")
lookAhead=("${gravityEN[@]}" \
"${circleRN[@]}" "${circleLN[@]}" "${circleCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が均等な文字で 右が幅広の文字の場合 左が丸い文字 左に移動
backtrack=("${gravityEL[@]}" \
"${gravitySmallEN[@]}")
input=("${circleLN[@]}" "${circleCN[@]}")
lookAhead=("${gravityWL[@]}" \
"${_MR[@]}" "${_mR[@]}" \
"${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が、左が丸い文字で 右が、右寄り、中間、Vの字の場合 幅広の文字 元に戻る
backtrack=("${circleLL[@]}" "${circleCL[@]}")
input=("${gravityWR[@]}")
lookAhead=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityER[@]}" "${gravityMR[@]}" "${gravityVR[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# ---

# 左が中間の文字、Ww で 右が左寄りの文字、右寄り、均等な大文字の場合 右寄り、中間の小文字 元に戻る
backtrack=("${gravityMR[@]}" \
"${_WN[@]}" "${_wN[@]}")
input=("${gravitySmallRR[@]}" "${gravitySmallMR[@]}")
lookAhead=("${gravityLN[@]}" "${gravityCapitalRN[@]}" "${gravityCapitalEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# ---

# 左が左寄り、均等、中間、Vの字で 右が左寄り、幅広、均等な文字の場合 幅広の文字 左に移動 (右側が元に戻った処理と統合)
backtrack=("${gravityLL[@]}" "${gravityEL[@]}" "${gravityML[@]}" "${gravityVL[@]}")
input=("${gravityWN[@]}")
lookAhead=("${gravityWL[@]}" \
"${gravityWR[@]}" \
"${gravityLN[@]}" "${gravityWN[@]}" "${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ---

# 右が右寄り、均等、中間の小文字の場合 L 以外の左寄り、中間の文字 元に戻る
backtrack=("")
input=("${outLgravityLR[@]}" "${gravityMR[@]}")
lookAhead=("${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が右寄り、幅広、均等な文字の場合 左寄りの文字 元に戻らない
backtrack=("${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" \
"${gravityRN[@]}" "${gravityWN[@]}" "${gravityCapitalEN[@]}")
input=("${gravityLR[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 右が左寄りの小文字の場合 L 以外の左寄りの文字 元に戻る
backtrack=("")
input=("${outLgravityLR[@]}")
lookAhead=("${gravityLN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が co で 右が Ww 以外の幅広の文字の場合 ce 左に移動
backtrack=("${_cN[@]}" "${_oN[@]}")
input=("${_cN[@]}" "${_eN[@]}")
lookAhead=("${outWwgravityWR[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 右側が左に寄って詰まった間隔を整える処理 ----------------------------------------

# 左が rt で 右が左寄り、右寄り、均等、丸い文字の場合 L 以外の左寄り、均等な文字 左に移動
backtrack=("${_rN[@]}" "${_tN[@]}")
input=("${outLgravityLN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" \
"${circleCL[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が左寄り、均等、中間の小文字、EFKPÞX で 右が左寄りの文字、右寄り、均等な大文字の場合 Iil 左に移動
backtrack=("${gravitySmallLR[@]}" "${gravitySmallMR[@]}" \
"${_KR[@]}" "${_PR[@]}" "${_THR[@]}" "${_XR[@]}")
input=("${_IN[@]}" "${_iN[@]}" "${_lN[@]}")
lookAhead=("${gravityLL[@]}" "${gravityCapitalRL[@]}" "${gravityCapitalEL[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が左寄り、均等、中間の小文字、EFKPÞX で 右が左寄りの文字、右寄り、均等な大文字の場合 Iil 左に移動
backtrack=("${gravitySmallER[@]}" \
"${_ER[@]}" "${_FR[@]}")
input=("${_iN[@]}" "${_lN[@]}")
lookAhead=("${gravityLL[@]}" "${gravityCapitalRL[@]}" "${gravityCapitalEL[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左がVの大文字で 右が左寄りの文字、右寄り、均等な大文字の場合 i 左に移動
backtrack=("${gravityCapitalVR[@]}")
input=("${_iN[@]}")
lookAhead=("${gravityLL[@]}" "${gravityCapitalRL[@]}" "${gravityCapitalEL[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が均等な大文字、G で 右が右寄り、均等、Vの小文字、中間の文字の場合 Ifi 右に移動
backtrack=("${gravityCapitalER[@]}" "${_GR[@]}")
input=("${_IN[@]}" "${_fN[@]}" "${_iN[@]}")
lookAhead=("${gravitySmallRL[@]}" "${gravitySmallEL[@]}" "${gravityML[@]}" "${gravitySmallVL[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が右寄り、均等、中間、Vの小文字で 右が右寄り、幅広、均等、中間、Vの小文字の場合 f 右に移動
backtrack=("${gravitySmallRR[@]}" "${gravitySmallER[@]}" "${gravitySmallMR[@]}" "${gravitySmallVR[@]}")
input=("${_fN[@]}")
lookAhead=("${gravitySmallRL[@]}" "${gravitySmallEL[@]}" "${gravitySmallML[@]}" "${gravitySmallVL[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が右寄り、均等、中間、Vの小文字で 右が幅広の小文字の場合 f 元に戻る
backtrack=("${gravitySmallRR[@]}" "${gravitySmallER[@]}" "${gravitySmallMR[@]}" "${gravitySmallVR[@]}")
input=("${_fL[@]}")
lookAhead=("${gravitySmallWL[@]}" \
"${gravitySmallWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が幅広の文字で 右が中間の文字の場合 J 元に戻らない
backtrack=("${gravityWR[@]}" \
"${gravityWN[@]}")
input=("${_JR[@]}")
lookAhead=("${gravityML[@]}" \
"${gravityMN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 右が中間の文字で その右が中間、Vの字の場合 Jj 元に戻る
backtrack1=("")
backtrack=("")
input=("${_JR[@]}" "${_jR[@]}")
lookAhead=("${gravityML[@]}" \
"${gravityMN[@]}")
lookAhead1=("${gravityVR[@]}" \
"${gravityMN[@]}" "${gravityCapitalVN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 右側が元に戻って詰まった間隔を整える処理 ----------------------------------------

# 左が HMNU で 右が BDEFHKLMNPRU の場合 HMNOQU 元に戻る
backtrack=("${_HN[@]}" "${_MN[@]}" "${_NN[@]}" "${_UN[@]}")
input=("${_HR[@]}" "${_MR[@]}" "${_NR[@]}" "${_OR[@]}" "${_QR[@]}" "${_UR[@]}")
lookAhead=("${_BN[@]}" "${_DN[@]}" "${_EN[@]}" "${_FN[@]}" "${_HN[@]}" "${_KN[@]}" "${_LN[@]}" "${_MN[@]}" "${_NN[@]}" "${_PN[@]}" "${_RN[@]}" "${_UN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が左寄り、均等、中間、Vの字で 右が左寄り、均等な文字の場合 幅広の文字 左に移動 (右に幅広の処理と統合)
 #backtrack=("${gravityLL[@]}" "${gravityEL[@]}" "${gravityML[@]}" "${gravityVL[@]}")
 #input=("${gravityWN[@]}")
 #lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
 #chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 右側が左に寄った、または元に戻って詰まった間隔を整える処理 2回目 ----------------------------------------

# 左が EFKLXkĸxz で 右が左寄り、右寄り、均等、中間の文字の場合 右寄り、均等、中間の文字、h 左に移動
backtrack=("${_ER[@]}" "${_FR[@]}" "${_KR[@]}" "${_LR[@]}" "${_XR[@]}" "${_kR[@]}" "${_xR[@]}" "${_zR[@]}" "${_kgR[@]}")
input=("${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${_hN[@]}")
lookAhead=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が Shs で 右が左寄り、右寄り、均等、中間の文字の場合 右寄り、中間の文字 左に移動
backtrack=("${_SR[@]}" "${_hR[@]}" "${_sR[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ---

# 左が左寄り、均等、中間の文字、右寄りの小文字で 右が左寄り、右寄り、均等、左が丸い文字の場合 右寄り、中間の文字 左に移動
backtrack=("${gravityLL[@]}" "${gravitySmallRL[@]}" "${gravityEL[@]}" "${gravityML[@]}")
input=("${gravityRN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" \
"${circleCL[@]}" \
"${gravityLN[@]}" "${outcgravityRN[@]}" "${gravityCapitalEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が左寄り、均等、中間の文字、右寄りの小文字で 右が均等、左が丸い文字の場合 右寄りの文字 左に移動
backtrack=("${gravityLL[@]}" "${gravitySmallRL[@]}" "${gravityEL[@]}" "${gravityML[@]}")
input=("${gravityRN[@]}")
lookAhead=( "${gravitySmallEN[@]}" "${_cN[@]}" \
"${circleSmallCN[@]}")
 #lookAhead=( "${gravityEN[@]}" \
 #"${circleLN[@]}" "${circleCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が、右が丸い小文字で 右が右寄り、丸い文字の場合 丸い小文字 左に移動
backtrack=("${circleSmallRL[@]}" "${circleSmallCL[@]}")
input=("${circleSmallCN[@]}")
lookAhead=("${circleSmallCN[@]}" "${_cN[@]}")
 #lookAhead=("${gravityRN[@]}" "${circleCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が、右が丸い大文字、R で 右が左寄り、均等な文字の場合 左寄りの文字 左に移動しない
backtrack=("${_RL[@]}" \
"${circleCapitalRL[@]}")
input=("${gravityLN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が左寄り、中間の文字で 右が左寄りの文字の場合 EFKkĸ 左に移動しない
backtrack=("${gravityLL[@]}" "${gravityML[@]}")
input=("${_EN[@]}" "${_FN[@]}" "${_KN[@]}" "${_kN[@]}" "${_kgN[@]}")
lookAhead=("${gravityLN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が均等な小文字、h で 右が左寄り、均等な文字の場合 hkĸ 左に移動しない
backtrack=("${gravitySmallEL[@]}" "${_hL[@]}")
input=("${_hN[@]}" "${_kN[@]}" "${_kgN[@]}")
lookAhead=("${gravityLN[@]}" "${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が均等、中間の小文字、左寄り、中間、丸い文字、Cc で 右が中間の大文字、左寄り、右寄り、均等な文字の場合 L 以外の左寄り、均等な文字 左に移動
backtrack=("${gravityLL[@]}" "${gravitySmallEL[@]}" "${gravityML[@]}" \
"${circleCL[@]}" \
"${_CL[@]}" "${_cL[@]}")
input=("${outLgravityLN[@]}" "${gravityEN[@]}")
lookAhead=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityCapitalML[@]}" \
"${gravityLN[@]}" "${gravityCapitalEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が右寄りの小文字で 右が中間の大文字、左寄り、右寄り、均等な文字の場合 均等な小文字 左に移動
backtrack=("${outcgravitySmallRL[@]}")
 #backtrack=("${gravitySmallRL[@]}")
input=("${gravitySmallEN[@]}")
lookAhead=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityCapitalML[@]}" \
"${gravityLN[@]}" "${gravityCapitalEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が均等な小文字、左寄り、中間、丸い文字、Cc で 右が均等、中間の文字の場合 均等な文字、右が丸い文字 左に移動
backtrack=("${gravityLL[@]}" "${gravitySmallEL[@]}" "${gravityML[@]}" \
"${circleCL[@]}" \
"${_CL[@]}" "${_cL[@]}")
input=("${gravityEN[@]}" \
"${circleRN[@]}")
lookAhead=("${gravitySmallML[@]}" \
"${gravitySmallEN[@]}")
 #lookAhead=("${gravityML[@]}" \
 #"${gravityEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が右寄り、均等な文字で 右が左寄りの文字、右寄り、均等、中間の大文字の場合 丸い大文字、右が丸い文字 左に移動
backtrack=("${outcgravityRL[@]}" "${gravityCapitalEL[@]}")
 #backtrack=("${gravityRL[@]}" "${gravityEL[@]}")
input=("${circleRN[@]}" "${circleCapitalCN[@]}")
lookAhead=("${gravityLL[@]}" "${gravityCapitalRL[@]}" "${gravityCapitalEL[@]}" "${gravityCapitalML[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ---

# 左が EFKLXkĸxz で 右が左寄り、c 以外の右寄り、均等、左が丸い、Ww 以外の幅広の文字の場合 右寄り、均等、中間の文字 左に移動
backtrack=("${_EN[@]}" "${_FN[@]}" "${_KN[@]}" "${_LN[@]}" "${_XN[@]}" "${_kN[@]}" "${_kgN[@]}" "${_xN[@]}" "${_zN[@]}")
input=("${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityLN[@]}" "${outcgravityRN[@]}" "${gravityEN[@]}" \
"${outWwgravityWR[@]}" \
"${circleCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が Vの大文字、EFKLX で 右が左寄り、c 以外の右寄り、均等、丸い文字の場合 右寄り、中間の文字、均等な小文字、h 左に移動
backtrack=("${gravitCapitalVN[@]}" "${_EN[@]}" "${_FN[@]}" "${_KN[@]}" "${_LN[@]}" "${_XN[@]}")
input=("${gravityRN[@]}" "${gravitySmallEN[@]}" "${gravityMN[@]}" "${_hN[@]}")
lookAhead=("${gravityLL[@]}" "${outcgravityRL[@]}" "${gravityEL[@]}" \
"${circleCL[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左がVの小文字、hkĸsxz で 右が左寄り、均等な文字の場合 L 以外の左寄り、c 以外の右寄り、均等、中間の文字 左に移動
backtrack=("${gravitySmallVN[@]}" "${_hN[@]}" "${_kN[@]}" "${_kgN[@]}" "${_sN[@]}" "${_xN[@]}" "${_zN[@]}")
input=("${outLgravityLN[@]}" "${outcgravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${gravityLL[@]}" "${gravityEL[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左がVの小文字、hkĸsxz で 右が c 以外の右寄り、均等、丸い文字の場合 右寄り、均等、中間の文字、h 左に移動
backtrack=("${gravitySmallVN[@]}" "${_hN[@]}" "${_kN[@]}" "${_kgN[@]}" "${_sN[@]}" "${_xN[@]}" "${_zN[@]}")
input=("${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}" "${_hN[@]}")
lookAhead=("${outcgravityRL[@]}" "${gravityEL[@]}" \
"${circleCL[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ---

# 左が EKPXhkĸsxz で 右が左寄り、右寄り、均等、丸い文字の場合 a 左に移動
backtrack=("${_EN[@]}" "${_KN[@]}" "${_PN[@]}" "${_XN[@]}" "${_hN[@]}" "${_kN[@]}" "${_sN[@]}" "${_xN[@]}" "${_zN[@]}" "${_kgN[@]}")
input=("${_aN[@]}")
lookAhead=("${gravityRL[@]}" \
"${circleCL[@]}" \
"${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" \
"${circleCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が P で 右が左寄り、右寄り、均等、中間の文字の場合 左上が開いている文字 左に移動
backtrack=("${_PN[@]}")
input=("${highSpaceSmallLN[@]}" "${highSpaceSmallCN[@]}")
lookAhead=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityEL[@]}" "${gravityML[@]}" \
"${gravityLN[@]}" "${gravityCapitalEN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 右側が右に移動したため開いた間隔を詰める処理 ----------------------------------------

# 左が Cc 以外の右寄りの文字で 右が OQUhkĸu の場合 AX 右に移動
backtrack=("${outcgravitySmallRN[@]}" "${_GN[@]}")
input=("${_AN[@]}" "${_XN[@]}")
lookAhead=("${_OR[@]}" "${_QR[@]}" "${_UR[@]}" "${_hR[@]}" "${_kR[@]}" "${_kgR[@]}" "${_uR[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が左寄り、中間の小文字、Vの字で 右がVの字の場合 acsxz 右に移動
backtrack=("${gravitySmallLR[@]}" "${gravitySmallMR[@]}" "${gravityVR[@]}")
input=("${_aN[@]}" "${_cN[@]}" "${_sN[@]}" "${_xN[@]}" "${_zN[@]}")
lookAhead=("${gravityVR[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が Ww 以外の幅広の文字で 右が Ww の場合 左寄り、右寄り、均等、中間の文字 右に移動
backtrack=("${outWwgravityWN[@]}")
input=("${gravityLN[@]}" "${gravityRN[@]}" "${gravityEN[@]}" "${gravityMN[@]}")
lookAhead=("${_WR[@]}" "${_wR[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が t で 右が IJijl の場合 右寄り、中間の文字 元に戻る
backtrack=("${_tN[@]}")
input=("${gravityRL[@]}" "${gravityML[@]}")
lookAhead=("${_IR[@]}" "${_JR[@]}" "${_iR[@]}" "${_jR[@]}" "${_lR[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が Ifilr で 右が IJijl の場合 Cc 元に戻る
backtrack=("${_IN[@]}" "${_fN[@]}" "${_iN[@]}" "${_lN[@]}" "${_rN[@]}")
input=("${_CL[@]}" "${_cL[@]}")
lookAhead=("${_IR[@]}" "${_JR[@]}" "${_iR[@]}" "${_jR[@]}" "${_lR[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

fi
# 記号類 ++++++++++++++++++++++++++++++++++++++++

# |~: に関する処理 3回目 ----------------------------------------

# 右が |~: の場合 |~ 下に : 上に移動
backtrack=("")
input=("${_barN[@]}" "${_tildeN[@]}" "${_colonN[@]}")
lookAhead=("${_barD[@]}" "${_tildeD[@]}" "${_colonU[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"

#CALT2
#<< "#CALT3" # アルファベット・記号 ||||||||||||||||||||||||||||||||||||||||

pre_add_lookup

# アルファベット ++++++++++++++++++++++++++++++++++++++++

# 右側が左に寄って詰まった間隔を整える処理 ----------------------------------------

# 左が EFKLXckĸxz で 右が IJfilrt の場合 右寄り、中間の文字 元に戻る
backtrack=("${_cL[@]}" \
"${_FR[@]}" \
"${_EN[@]}" "${_FN[@]}" "${_KN[@]}" "${_LN[@]}" "${_XN[@]}" "${_cN[@]}" "${_kN[@]}" "${_kgN[@]}" "${_xN[@]}" "${_zN[@]}")
input=("${gravityRR[@]}" "${gravityMR[@]}")
lookAhead=("${_IL[@]}" "${_JL[@]}" "${_fL[@]}" "${_iL[@]}" "${_lL[@]}" "${_rL[@]}" "${_tL[@]}" \
"${_IN[@]}" "${_JN[@]}" "${_fN[@]}" "${_iN[@]}" "${_lN[@]}" "${_rN[@]}" "${_tN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右側が左に寄った、または元に戻って詰まった間隔を整える処理 3回目 ----------------------------------------

# 左が EFKLXkĸxz で 右が左寄りの場合 均等な文字 左に移動
backtrack=("${_EN[@]}" "${_FN[@]}" "${_KN[@]}" "${_LN[@]}" "${_XN[@]}" "${_kN[@]}" "${_kgN[@]}" "${_xN[@]}" "${_zN[@]}")
input=("${gravityEN[@]}")
lookAhead=("${gravityLN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 記号類 ++++++++++++++++++++++++++++++++++++++++

# |~: に関する処理 4回目 ----------------------------------------

# 右が |~: の場合 |~ 下に : 上に移動
backtrack=("")
input=("${_barN[@]}" "${_tildeN[@]}" "${_colonN[@]}")
lookAhead=("${_barD[@]}" "${_tildeD[@]}" "${_colonU[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"

# < に関する処理 ----------------------------------------

# 右が - の場合 < 右に移動
backtrack=("")
input=("${_lessN[@]}")
lookAhead=("${_hyphenN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

# > に関する処理 ----------------------------------------

# 左が - の場合 > 左に移動
backtrack=("${_hyphenR[@]}" \
"${_hyphenN[@]}")
input=("${_greaterN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"

# *+-= に関する処理 ----------------------------------------

# 左右が括弧の場合 *+-= 上に移動
backtrack=("${bracketLN[@]}")
input=("${_asteriskN[@]}" "${_plusN[@]}" "${_hyphenN[@]}" "${_equalN[@]}")
lookAhead=("${bracketRN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"

# - に関する処理の始め ----------------------------------------

# 左が < で 右が > の場合 - 移動しない
backtrack=("${_lessR[@]}" \
"${_lessN[@]}")
input=("${_hyphenN[@]}")
lookAhead=("${_greaterN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右が > の場合 - 右に移動
backtrack=("")
input=("${_hyphenN[@]}")
lookAhead=("${_greaterN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

# 左が、右が開いている文字、< の場合 - 左に移動
backtrack=("${_lessR[@]}" \
"${_lessN[@]}" \
"${midSpaceRL[@]}" "${midSpaceCL[@]}" \
"${midSpaceRN[@]}" "${midSpaceCN[@]}")
input=("${_hyphenN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"

# reverse solidus に関する処理の始め ----------------------------------------

# 左が、右上が開いている文字、狭い文字、A の場合 reverse solidus 左に移動
backtrack=("${highSpaceRL[@]}" "${highSpaceCL[@]}" "${gravityCL[@]}" "${_AL[@]}" \
"${highSpaceRN[@]}" "${highSpaceCN[@]}" "${gravityCN[@]}" "${_AN[@]}")
input=("${_rSolidusN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"

# 左が、右上が開いている文字、狭い文字、A の場合 reverse solidus 左に移動しない
backtrack=("${highSpaceRR[@]}" "${highSpaceCR[@]}" "${gravityCR[@]}" "${_AR[@]}")
input=("${_rSolidusN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# solidus に関する処理の始め ----------------------------------------

# 左が、右下が開いている文字か W の場合 solidus 左に移動
backtrack=("${lowSpaceRL[@]}" "${lowSpaceCL[@]}" "${_WL[@]}" \
"${lowSpaceRN[@]}" "${lowSpaceCN[@]}" "${_WN[@]}")
input=("${_solidusN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"

# 左が、右下が開いている文字か W の場合 solidus 左に移動しない
backtrack=("${lowSpaceRR[@]}" "${lowSpaceCR[@]}" "${_WR[@]}")
input=("${_solidusN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# <> reverse solidus solidus に関する処理の始め ----------------------------------------

# 左が左寄り、右寄り、幅広、均等、中間の文字の場合 <> reverse solidus solidus 右に移動
backtrack=("${gravityLR[@]}" "${gravityRR[@]}" "${gravityWR[@]}" "${gravityER[@]}" "${gravityMR[@]}" \
"${gravityWN[@]}")
input=("${_lessN[@]}" "${_greaterN[@]}" "${_rSolidusN[@]}" "${_solidusN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

#CALT3
#<< "#CALT4"  # 記号 ||||||||||||||||||||||||||||||||||||||||

pre_add_lookup

# 記号類 ++++++++++++++++++++++++++++++++++++++++

# - に関する処理の続き ----------------------------------------

# 右が、左が開いている文字の場合 - 右に移動
backtrack=("")
input=("${_hyphenN[@]}")
lookAhead=("${midSpaceLR[@]}" "${midSpaceCR[@]}" \
"${midSpaceLN[@]}" "${midSpaceCN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

# 右が、左が開いている文字、数字の場合 - 元に戻る
backtrack=("")
input=("${_hyphenL[@]}")
lookAhead=("${midSpaceLR[@]}" "${midSpaceCR[@]}" \
"${midSpaceLN[@]}" "${midSpaceCN[@]}" "${figureN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# reverse solidus に関する処理の続き ----------------------------------------

# 右が、左下が開いている文字か W の場合 reverse solidus 右に移動
backtrack=("")
input=("${_rSolidusN[@]}")
lookAhead=("${lowSpaceLR[@]}" "${lowSpaceCR[@]}" "${_WR[@]}" \
"${lowSpaceLN[@]}" "${lowSpaceCN[@]}" "${_WN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

# 右が、左下が開いている文字か W の場合 reverse solidus 右に移動しない
backtrack=("")
input=("${_rSolidusN[@]}")
lookAhead=("${lowSpaceLL[@]}" "${lowSpaceCL[@]}" "${_WL[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右が、左下が開いている文字か W の場合 reverse solidus 元に戻る
backtrack=("")
input=("${_rSolidusL[@]}")
lookAhead=("${lowSpaceLR[@]}" "${lowSpaceCR[@]}" "${_WR[@]}" \
"${lowSpaceLN[@]}" "${lowSpaceCN[@]}" "${_WN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# solidus に関する処理の続き ----------------------------------------

# 右が、左上が開いている文字、狭い文字、A の場合 solidus 右に移動
backtrack=("")
input=("${_solidusN[@]}")
lookAhead=("${highSpaceLR[@]}" "${highSpaceCR[@]}" "${gravityCR[@]}" "${_AR[@]}" \
"${highSpaceLN[@]}" "${highSpaceCN[@]}" "${gravityCN[@]}" "${_AN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

# 右が、左上が開いている文字、狭い文字、A の場合 solidus 右に移動しない
backtrack=("")
input=("${_solidusN[@]}")
lookAhead=("${highSpaceLL[@]}" "${highSpaceCL[@]}" "${gravityCL[@]}" "${_AL[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右が、左上が開いている文字、狭い文字、A の場合 solidus 元に戻る
backtrack=("")
input=("${_solidusL[@]}")
lookAhead=("${highSpaceLR[@]}" "${highSpaceCR[@]}" "${gravityCR[@]}" "${_AR[@]}" \
"${highSpaceLN[@]}" "${highSpaceCN[@]}" "${gravityCN[@]}" "${_AN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# <> reverse solidus solidus に関する処理の続き ----------------------------------------

# 右が左寄り、右寄り、幅広、均等、中間の文字の場合 <> reverse solidus solidus 左に移動
backtrack=("")
input=("${_lessN[@]}" "${_greaterN[@]}" "${_rSolidusN[@]}" "${_solidusN[@]}")
lookAhead=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityWL[@]}" "${gravityEL[@]}" "${gravityML[@]}" \
"${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"

# 右が左寄り、右寄り、幅広、均等、中間の文字の場合 <> reverse solidus solidus 元に戻る
backtrack=("")
input=("${_lessR[@]}" "${_greaterR[@]}" "${_rSolidusR[@]}" "${_solidusR[@]}")
lookAhead=("${gravityLL[@]}" "${gravityRL[@]}" "${gravityWL[@]}" "${gravityEL[@]}" "${gravityML[@]}" \
"${gravityWN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

#CALT4

# 桁区切り設定作成 ||||||||||||||||||||||||||||||||||||||||

# 小数の処理 ----------------------------------------

pre_add_lookup

backtrack=("${_fullStopN[@]}")
input=("${figureN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex0}"

pre_add_lookup

backtrack=("${figure0[@]}")
input=("${figureN[@]}")
lookAhead=("")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex0}"

# 12桁マークを付ける処理 1 ----------------------------------------

pre_add_lookup

backtrack1=("")
backtrack=("${figure2[@]}" "${figureN[@]}")
input=("${figureN[@]}")
lookAhead=("${figureN[@]}")
lookAhead1=("${figureN[@]}")
lookAheadX=("${figureN[@]}"); aheadMax="10"
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex2}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

# ノーマルに戻す処理 1 ----------------------------------------

pre_add_lookup

backtrack=("")
input=("${figure2[@]}")
lookAhead=("${figure2[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 12桁マークを付ける処理 2 ----------------------------------------

pre_add_lookup

backtrack1=("")
backtrack=("${figure2[@]}" "${figureN[@]}")
input=("${figureN[@]}")
lookAhead=("${figureN[@]}")
lookAhead1=("${figureN[@]}")
lookAheadX=("${figureN[@]}"); aheadMax="10"
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex2}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

# ノーマルに戻す処理 2 ----------------------------------------

pre_add_lookup

backtrack=("")
input=("${figure2[@]}")
lookAhead=("${figure2[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 4桁マークを付ける処理 1 ----------------------------------------

pre_add_lookup

backtrack1=("")
backtrack=("${figure2[@]}" "${figure4[@]}" "${figureN[@]}")
input=("${figureN[@]}")
lookAhead=("${figureN[@]}")
lookAhead1=("${figureN[@]}")
lookAheadX=("${figureN[@]}"); aheadMax="2"
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex4}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

# ノーマルに戻す処理 3 ----------------------------------------

pre_add_lookup

backtrack=("")
input=("${figure4[@]}")
lookAhead=("${figure4[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 4桁マークを付ける処理 2 ----------------------------------------

pre_add_lookup

backtrack1=("")
backtrack=("${figure2[@]}" "${figure4[@]}" "${figureN[@]}")
input=("${figureN[@]}")
lookAhead=("${figureN[@]}")
lookAhead1=("${figureN[@]}")
lookAheadX=("${figureN[@]}"); aheadMax="2"
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex4}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

# ノーマルに戻す処理 4 ----------------------------------------

pre_add_lookup

backtrack=("")
input=("${figure4[@]}")
lookAhead=("${figure4[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 3桁マークを付ける処理 1 ----------------------------------------

pre_add_lookup

backtrack1=("")
backtrack=("${figure2[@]}" "${figure3[@]}" "${figure4[@]}" "${figureN[@]}")
input=("${figureN[@]}")
lookAhead=("${figureN[@]}")
lookAhead1=("${figureN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex3}" "${backtrack1[*]}" "${lookAhead1[*]}"

backtrack1=("")
backtrack=("${figure2[@]}" "${figure3[@]}" "${figure4[@]}" "${figureN[@]}")
input=("${figureN[@]}")
lookAhead=("${figureN[@]}")
lookAhead1=("${figure4[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex3}" "${backtrack1[*]}" "${lookAhead1[*]}"

backtrack1=("")
backtrack=("${figure2[@]}" "${figure3[@]}" "${figure4[@]}" "${figureN[@]}")
input=("${figureN[@]}")
lookAhead=("${figure4[@]}")
lookAhead1=("${figureN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex3}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ノーマルに戻す処理 5 ----------------------------------------

pre_add_lookup

backtrack=("")
input=("${figure3[@]}")
lookAhead=("${figure3[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

backtrack1=("")
backtrack=("")
input=("${figure3[@]}")
lookAhead=("${figure2[@]}" "${figure3[@]}" "${figure4[@]}" "${figureN[@]}")
lookAhead1=("${figure2[@]}" "${figure3[@]}" "${figure4[@]}" "${figureN[@]}")
lookAheadX=("${figureN[@]}"); aheadMax="2"
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

# 3桁マークを付ける処理 2 ----------------------------------------

pre_add_lookup

backtrack1=("")
backtrack=("${figure2[@]}" "${figure3[@]}" "${figure4[@]}" "${figureN[@]}")
input=("${figureN[@]}")
lookAhead=("${figureN[@]}")
lookAhead1=("${figureN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex3}" "${backtrack1[*]}" "${lookAhead1[*]}"

backtrack1=("")
backtrack=("${figure2[@]}" "${figure3[@]}" "${figure4[@]}" "${figureN[@]}")
input=("${figureN[@]}")
lookAhead=("${figureN[@]}")
lookAhead1=("${figure4[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex3}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ノーマルに戻す処理 6 ----------------------------------------

pre_add_lookup

backtrack=("")
input=("${figure3[@]}")
lookAhead=("${figure3[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 2進数のみ4桁区切りを有効にする処理 ----------------------------------------

pre_add_lookup

backtrack1=("")
backtrack=("${figureBN[@]}")
input=("${figureB2[@]}")
lookAhead=("${figureBN[@]}")
lookAhead1=("${figureBN[@]}")
lookAheadX=("${figureB3[@]}"); aheadMax="2"
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex2}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

backtrack1=("")
backtrack=("${figureB3[@]}" "${figureBN[@]}")
input=("${figureB4[@]}")
lookAhead=("${figureBN[@]}")
lookAhead1=("${figureB3[@]}")
lookAheadX=("${figureBN[@]}"); aheadMax="2"
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex4}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

backtrack1=("")
backtrack=("${figureB3[@]}" "${figureBN[@]}")
input=("${figureB4[@]}")
lookAhead=("${figureB3[@]}")
lookAhead1=("${figureBN[@]}")
lookAheadX=("${figureBN[@]}"); aheadMax="2"
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex4}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

backtrack=("")
input=("${figure2[@]}")
lookAhead=("${figureN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex3}"

backtrack=("")
input=("${figure4[@]}")
lookAhead=("${figure3[@]}" "${figureN[@]}")
chain_context "index" "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# ---

rm -f ${caltListName}.tmp.txt
rm -f ${checkListName}*.txt
if [ "${leaving_tmp_flag}" = "false" ]; then
  remove_temp
fi
echo

# Exit
echo "Finished making the GSUB table [calt, LookupType 6]."
echo
exit 0
