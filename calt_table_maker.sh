#!/bin/bash

# GSUB calt table maker
#
# Copyright (c) 2023 omonomo
#
# GSUB calt フィーチャテーブル作成プログラム
#
# font_generator にて、条件成立時に呼び出す異体字変換テーブルが生成済みであること
# また uvs_table_maker にて GSUB のリストファイルが生成済みであること


# ログをファイル出力させる場合は有効にする (<< "#LOG" をコメントアウトさせる)
<< "#LOG"
LOG_OUT=/tmp/calt_table_maker.log
LOG_ERR=/tmp/calt_table_maker_err.log
exec 1> >(tee -a $LOG_OUT)
exec 2> >(tee -a $LOG_ERR)
#LOG

glyphNo="15000" # calt用異体字の先頭glyphナンバー (仮)
listNo="-1"
optimizeListNo="4" # -o -O オプションが設定してある場合、指定の listNo 以下は最適化ルーチンを実行する
caltListName="caltList" # caltテーブルリストの名称
caltList="${caltListName}_${listNo}" # Lookupごとのcaltテーブルリスト
dict="dict" # 略字をグリフ名に変換する辞書
gsubList="gsubList" # 作成フォントのGSUBから抽出した置き換え用リスト
checkListName="checkList" # 設定の重複を避けるためのリストの名称
tmpdir_name="calt_table_maker_tmpdir" # 一時保管フォルダ名
karndir_name="karningSettings" # カーニング設定の保存フォルダ名
karnsetdir_name="" # 各カーニング設定と calt_table_maker 情報の保存フォルダ名
fileDataName="fileData" # calt_table_maker のサイズと変更日を保存するファイル名

# lookup の IndexNo. (GSUBを変更すると変わる可能性あり)
lookupIndex_calt="18" # caltテーブルのlookupナンバー
num_calt_lookups="20" # calt のルックアップ数
lookupIndex_replace=$((lookupIndex_calt + num_calt_lookups)) # 単純置換のlookupナンバー
lookupIndexRR=${lookupIndex_replace} # 変換先(右に移動させた記号のグリフ)
lookupIndexLL=$((lookupIndexRR + 1)) # 変換先(左に移動させた記号のグリフ)
lookupIndexUD=$((lookupIndexLL + 1)) # 変換先(上下に移動させた記号のグリフ)
lookupIndex0=$((lookupIndexUD + 1)) # 変換先(小数のグリフ)
lookupIndex2=$((lookupIndex0 + 1)) # 変換先(12桁マークを付けたグリフ)
lookupIndex4=$((lookupIndex2 + 1)) # 変換先(4桁マークを付けたグリフ)
lookupIndex3=$((lookupIndex4 + 1)) # 変換先(3桁マークを付けたグリフ)
lookupIndexR=$((lookupIndex3 + 1)) # 変換先(右に移動させたグリフ)
lookupIndexL=$((lookupIndexR + 1)) # 変換先(左に移動させたグリフ)
lookupIndexN=$((lookupIndexL + 1)) # 変換先(ノーマルなグリフに戻す)

leaving_tmp_flag="false" # 一時ファイル残す
basic_only_flag="false" # 基本ラテン文字のみ
symbol_only_flag="false" # 記号、桁区切りのみ
optimize_mode="void" # なんちゃって最適化ルーチンのモード (void: 実行しない、optional: 任意のみ、force: 強制)
glyphNo_flag="false" # glyphナンバーの指定があるか

# エラー処理
trap "exit 3" HUP INT QUIT

# [@]なしで 同じ基底文字のバリエーション (例: A À Á...) を取得する関数 ||||||||||||||||||||||||||||||||||||||||

letter_members() {
  local class # 基底文字
  class=(${2})

  if [ -n "${class}" ]; then
    class=(${class[@]/#/\$\{}) # 先頭に ${ を付加
    class=(${class[@]/%/[@]\}}) # 末尾に [@]} を付加
    eval "${1}=(${class[@]})" # 戻り値を入れる変数名を1番目の引数に指定する
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
  if [ ${listNo} -le ${optimizeListNo} ]; then # 最適化する listNo の場合、チェックリストを削除
    rm -f ${tmpdir}/${checkListName}*.txt # (デバッグで使えるかもしれないため最後のチェックリストは残す)
  fi
}

# グリフの略号を通し番号と名前に変換する関数 ||||||||||||||||||||||||||||||||||||||||

glyph_name() {
  echo $(grep -m 1 " ${1} " "${tmpdir}/${dict}.txt" | cut -d ' ' -f 1,3)
}

# グリフの通し番号と名前を backtrack、input、lookAhead の XML に変換する関数 ||||||||||||||||||||||||||||||||||||||||

glyph_value() {
  sort -n -u "${1}" | cut -d ' ' -f 2 | sed -E 's/([0-9a-zA-z]+)/<Glyph value="\1"\/>/g' # ソートしないとttxにしかられる
}

# LookupType 6 を作成するための関数 ||||||||||||||||||||||||||||||||||||||||

chain_context() {
  local optim optimCheck # 最適化を実行するか (optional の場合、0: 実行、1: データベース作成のみ、2: 完全スキップ)
  local substIndex # 設定番号
  local backtrack bt addBt removeBt # 1文字前
  local input ip removeIp # 入力
  local lookAhead la addLa removeLa # 1文字後
  local lookupIndex # ジャンプする(グリフを置換する)テーブル番号
  local backtrack1 bt1 # 2文字前
  local lookAhead1 la1 # 2文字後
  local lookAheadX laX # 3文字後以降
  local aheadMax # lookAheadのIndex2以降はその数(最大のIndexNo)を入れる(当然内容は全て同じになる)
  local overlap # 全ての設定が重複しているか
  local S T line0 line1
  optim="${1}"
  substIndex="${3}"
  backtrack=(${4})
  input=(${5})
  lookAhead=(${6})
  lookupIndex="${7}"
  backtrack1=(${8})
  lookAhead1=(${9})
  lookAheadX=(${10})
  aheadMax="${11}"

  for S in ${fixedGlyphL[@]} ${fixedGlyphR[@]} ${fixedGlyphN[@]}; do
    input=(${input[@]//${S}/}) # input から移動しないグリフを削除
  done

<< "#SUPPLEMENT" # 設定漏れを補完 (処理に時間がかかりすぎるため通常は無効) ====================

  S=${input: -1} # input と lookupIndex から文字がどちらに移動しようとしているか判定
  bt=(${backtrack[@]})
  la=(${lookAhead[@]})
  if [ "${S}" == "N" ]; then
    if [ "${lookupIndex}" == "${lookupIndexL}" ]; then
      T="moveLeft"
    elif [ "${lookupIndex}" == "${lookupIndexR}" ]; then
      T="moveRight"
    else
      T="doNotMove"
    fi
  elif [ "${S}" == "R" ]; then
    if [ "${lookupIndex}" == "${lookupIndexL}" ] || [ "${lookupIndex}" == "${lookupIndexN}" ]; then
      T="moveLeft"
    else
      T="doNotMove"
    fi
  else
    if [ "${lookupIndex}" == "${lookupIndexN}" ] || [ "${lookupIndex}" == "${lookupIndexR}" ]; then
      T="moveRight"
    else
      T="doNotMove"
    fi
  fi

  if [ "${T}" == "moveLeft" ]; then # 左に移動する場合、L と N を追加
    if [ -n "${backtrack}" ]; then
      U=(${backtrack[@]/%R/N})
      V=(${U[@]/%N/L})
      backtrack=(${backtrack[@]} ${U[@]} ${V[@]})
    fi
    if [ -n "${lookAhead}" ] && [ ${listNo} -gt 0 ]; then # listNo が1以上だと lookAhead についても L と N を追加
      U=(${lookAhead[@]/%R/N})
      V=(${U[@]/%N/L})
      lookAhead=(${lookAhead[@]} ${U[@]} ${V[@]})
    fi
  elif [ "${T}" == "moveRight" ]; then # 右に移動する場合 R と N を追加
    if [ -n "${backtrack}" ]; then
      U=(${backtrack[@]/%L/N})
      V=(${U[@]/%N/R})
      backtrack=(${backtrack[@]} ${U[@]} ${V[@]})
    fi
    if [ -n "${lookAhead}" ] && [ ${listNo} -gt 0 ]; then
      U=(${lookAhead[@]/%L/N})
      V=(${U[@]/%N/R})
      lookAhead=(${lookAhead[@]} ${U[@]} ${V[@]})
    fi
  fi

  addBt=(${backtrack[@]}) # 追加した設定を抽出
  for S in ${bt[@]}; do
    addBt=(${addBt[@]//${S}/})
  done
  if [ -n "${addBt}" ]; then
    addBt=$(printf '%s\n' "${addBt[@]}" | sort -u | tr '\n' ' ')
    echo "Add backtrack setting ${addBt//_/}"
  fi
  addLa=(${lookAhead[@]})
  for S in ${la[@]}; do
    addLa=(${addLa[@]//${S}/})
  done
  if [ -n "${addLa}" ]; then
    addLa=$(printf '%s\n' "${addLa[@]}" | sort -u | tr '\n' ' ')
    echo "Add lookAhead setting ${addLa//_/}"
  fi

#SUPPLEMENT
# 重複している配列要素を削除 ====================

  input=($(printf '%s\n' "${input[@]}" | sort -u))
  backtrack=($(printf '%s\n' "${backtrack[@]}" | sort -u))
  lookAhead=($(printf '%s\n' "${lookAhead[@]}" | sort -u))
  backtrack1=($(printf '%s\n' "${backtrack1[@]}" | sort -u))
  lookAhead1=($(printf '%s\n' "${lookAhead1[@]}" | sort -u))
  lookAheadX=($(printf '%s\n' "${lookAheadX[@]}" | sort -u))

# 重複している設定を削除 ====================

  if [ ${listNo} -le ${optimizeListNo} ]; then # 指定の listNo 以下で
    if [ "${optimize_mode}" == "force" ] || \
      [[ "${optimize_mode}" == "optional" && ${optim} -le 1 ]]; then # 最適化を実行する場合
      optimCheck=0

# input --------------------

      unset removeIp
      for S in ${input[@]}; do # input の各グリフについて調査
        rm -f ${tmpdir}/${checkListName}*.tmp.txt
        overlap="true"

        if [ -n "${backtrack}" ]; then bt="${backtrack[@]}"; else bt="@"; fi # eval とブレース展開を利用して順列を生成する
        bt=${bt// /,}
        if [ -n "${lookAhead}" ]; then la="${lookAhead[@]}"; else la="@"; fi
        la=${la// /,}
        if [ "${optimize_mode}" == "force" ] || [ ${optim} -eq 0 ]; then # 最適化処理を実行する場合
          eval echo ${S}{${bt}}"@" | tr -d '{}' | tr ' ' '\n' >> "${tmpdir}/${checkListName}.short.backOnly.tmp.txt" # lookAhead が無い設定のチェック用に保存
          eval echo ${S}"@"{${la}} | tr -d '{}' | tr ' ' '\n' >> "${tmpdir}/${checkListName}.short.aheadOnly.tmp.txt" # backtrack が無い設定のチェック用に保存
        fi
        eval echo ${S}{${bt}}{${la}} | tr -d '{}' | tr ' ' '\n' >> "${tmpdir}/${checkListName}.short.tmp.txt" # 前後2文字以上を省いた文字列を保存
        if [ -n "${backtrack1}" ]; then bt1="${backtrack1[@]}"; else bt1="@"; fi
        bt1=${bt1// /,}
        if [ -n "${lookAhead1}" ]; then la1="${lookAhead1[@]}"; else la1="@"; fi
        la1=${la1// /,}
        if [ -n "${lookAheadX}" ]; then laX="${lookAheadX[@]}"; else laX="@"; fi
        laX=${laX// /,}
        if [ "${bt1}${la1}${laX}" != "@@@" ]; then
          eval echo ${S}{${bt}}{${la}}{${bt1}}{${la1}}{${laX}} | tr -d '{}' | tr ' ' '\n' >> "${tmpdir}/${checkListName}.long.tmp.txt" # 前後2文字以上も含めた文字列を保存
        fi

        if [ "${optimize_mode}" == "optional" ] && [ ${optim} -ne 0 ]; then # 最適化処理をスキップする場合
          overlap="false" # 無条件でチェックリストに追加
          if [ -e "${tmpdir}/${checkListName}.long.tmp.txt" ]; then
            cat "${tmpdir}/${checkListName}.long.tmp.txt" >> "${tmpdir}/${checkListName}Long${S}.txt"
          else
            cat "${tmpdir}/${checkListName}.short.tmp.txt" >> "${tmpdir}/${checkListName}Short${S}.txt"
          fi

        else # "${optimize_mode}" == "optional" && ${optim} -ne 0
          if [[ ! -e "${tmpdir}/${checkListName}Short${S}.txt" ]]; then # 既設定ファイルがない場合は空のファイルを作成
            :>| "${tmpdir}/${checkListName}Short${S}.txt"
          fi

          while read line0; do # 前後1文字のみで lookAhead が無い設定がすでに存在しないかチェック
            if [ -z "$(grep -x -m 1 "${line0}" "${tmpdir}/${checkListName}Short${S}.txt")" ]; then
              while read line1; do # lookAhead が無い設定に抜けがあった場合、前後1文字のみで backtrack が無い設定がすでに存在しないかチェック
                if [ -z "$(grep -x -m 1 "${line1}" "${tmpdir}/${checkListName}Short${S}.txt")" ]; then
                  overlap="false" # backtrack と lookAhead の両方に重複していない設定があればフラグを立てて break
                  break 2
                fi # -z "${grep (backtrack 無し)
              done < "${tmpdir}/${checkListName}.short.aheadOnly.tmp.txt"
            fi # -z "${grep (lookAhead 無し)
          done < "${tmpdir}/${checkListName}.short.backOnly.tmp.txt" # backtrack か lookAhead 無しの設定のいずれかが全て重複していた場合、スルー

          if [ "${overlap}" == "false" ]; then # backtrack と lookAhead 両方の設定に抜けがあった場合追試
            overlap="true"
            while read line0; do
              if [ -z "$(grep -x -m 1 "${line0}" "${tmpdir}/${checkListName}Short${S}.txt")" ]; then # 前後1文字のみで重複する設定がないかチェック
                if [ -e "${tmpdir}/${checkListName}.long.tmp.txt" ]; then # 重複していない設定があった場合、前後2文字以上参照する設定の場合は追試
                  if [[ ! -e "${tmpdir}/${checkListName}Long${S}.txt" ]]; then # 既設定ファイルがない場合は空のファイルを作成
                    :>| "${tmpdir}/${checkListName}Long${S}.txt"
                  fi
                  while read line1; do
                    if [ -z "$(grep -x -m 1 "${line1}" "${tmpdir}/${checkListName}Long${S}.txt")" ]; then # 前後2文字以上で重複する設定がないかチェック
                      overlap="false" # 重複していない設定があればチェックリストに追加して break
                      cat "${tmpdir}/${checkListName}.long.tmp.txt" >> "${tmpdir}/${checkListName}Long${S}.txt"
                      break 2
                    fi # -z "${grep (前後2文字以上)
                  done  < "${tmpdir}/${checkListName}.long.tmp.txt"
                else # -e "${tmpdir}/${checkListName}.long.tmp.txt" 前後1文字のみ参照の場合、追試なしでチェックリストに追加して break
                  overlap="false"
                  cat "${tmpdir}/${checkListName}.short.tmp.txt" >> "${tmpdir}/${checkListName}Short${S}.txt"
                fi # -e "${tmpdir}/${checkListName}.long.tmp.txt"
                break
              fi # -z "${grep (前後1文字のみ)
            done < "${tmpdir}/${checkListName}.short.tmp.txt" # 重複する設定がない場合、スルー
          fi

          if [ "${overlap}" == "true" ]; then # すでに設定が全て存在していた場合、input から重複したグリフを削除
            input=(${input[@]/${S}/})
            removeIp+=" ${S}"
          fi

        fi # "${optimize_mode}" == "optional" && ${optim} -ne 0
      done # S

      if [ -n "${removeIp}" ]; then
        echo "Remove input setting${removeIp//_/}"
        optimCheck=$((optimCheck + 1)) # 最適化が有効なので + 1
      fi
      if [ -z "${input}" ]; then # input のグリフが全て重複していた場合、設定を追加せず ruturn
        echo "Removed all settings, skip ${caltList} index ${substIndex}: Lookup = ${lookupIndex}"
        eval "${2}=\${substIndex}" # 戻り値を入れる変数名を1番目の引数に指定する
        return
      fi

# backtrack --------------------

      unset removeBt
      if [ -n "${backtrack}" ]; then # backtrack がある場合
        for S in ${backtrack[@]}; do # backtrack の各グリフについて調査
          rm -f ${tmpdir}/${checkListName}*.tmp.txt
          overlap="true"

          ip="${input[@]}"
          ip=${ip// /,}
          if [ "${optimize_mode}" == "force" ] || [ ${optim} -eq 0 ]; then # 最適化処理を実行する場合
            eval echo ${S}{${ip}}"@@@@" | tr -d '{}' | tr ' ' '\n' >> "${tmpdir}/${checkListName}.backOnly.tmp.txt" # lookAhead がない設定のチェック用に保存
          fi
          if [ -n "${lookAhead}" ]; then la="${lookAhead[@]}"; else la="@"; fi
          la=${la// /,}
          if [ -n "${backtrack1}" ]; then bt1="${backtrack1[@]}"; else bt1="@"; fi
          bt1=${bt1// /,}
          if [ -n "${lookAhead1}" ]; then la1="${lookAhead1[@]}"; else la1="@"; fi
          la1=${la1// /,}
          if [ -n "${lookAheadX}" ]; then laX="${lookAheadX[@]}"; else laX="@"; fi
          laX=${laX// /,}
          eval echo ${S}{${ip}}{${la}}{${bt1}}{${la1}}{${laX}} | tr -d '{}' | tr ' ' '\n' >> "${tmpdir}/${checkListName}.back.tmp.txt" # 前後2文字以上も含めた文字列を保存

          if [ "${optimize_mode}" == "optional" ] && [ ${optim} -ne 0 ]; then # 最適化処理をスキップする場合
            overlap="false" # 無条件でチェックリストに追加
            cat "${tmpdir}/${checkListName}.back.tmp.txt" >> "${tmpdir}/${checkListName}Back${S}.txt"

          else # "${optimize_mode}" == "optional" && ${optim} -ne 0
            if [[ ! -e "${tmpdir}/${checkListName}Back${S}.txt" ]]; then # 既設定ファイルが無い場合は空のファイルを作成
              :>| "${tmpdir}/${checkListName}Back${S}.txt"
            fi
            while read line0; do
              if [ -z "$(grep -x -m 1 "${line0}" "${tmpdir}/${checkListName}Back${S}.txt")" ]; then # lookAhead が無い設定がすでに存在しないかチェック
                while read line1; do # lookAhead が無い設定に抜けがあった場合追試
                  if [ -z "$(grep -x -m 1 "${line1}" "${tmpdir}/${checkListName}Back${S}.txt")" ]; then # 重複する設定がないかチェック
                    overlap="false" # 重複していない設定があった場合チェックリストに追加して break
                    cat "${tmpdir}/${checkListName}.back.tmp.txt" >> "${tmpdir}/${checkListName}Back${S}.txt"
                    break 2
                  fi # -z "${T}" (重複する設定)
                done < "${tmpdir}/${checkListName}.back.tmp.txt" # 重複する設定が無い場合、何もせずに break
                break
              fi # -z "${grep (lookAhead が無い)
            done < "${tmpdir}/${checkListName}.backOnly.tmp.txt" # すでに lookAhead が無い設定が全て存在した場合、スルー

            if [ "${overlap}" == "true" ]; then # すでに設定が全て存在していた場合、backtrack から重複したグリフを削除
              backtrack=(${backtrack[@]/${S}/})
              removeBt+=" ${S}"
            fi

          fi # "${optimize_mode}" == "optional" && ${optim} -ne 0
        done # S

        if [ -n "${removeBt}" ]; then
          echo "Remove backtrack setting${removeBt//_/}"
          if [ " ${addBt}" == "${removeBt} " ]; then # 設定漏れ補完で追加したグリフと最適化で除去したグリフが同じ場合
            echo "Added and removed backtrack settings are the same"
          elif [ -n "${addBt}" ]; then # 異なる場合
            for S in ${removeBt}; do
              addBt=${addBt//${S}/}
            done
            printf "Difference in backtrack settings: %s\n" "$(echo ${addBt//_/} | tr -s "[:space:]")"
          fi
          optimCheck=$((optimCheck + 1)) # 最適化が有効なので + 1
        fi
        if [ "${bt}" != "|" ] && [ -z "${backtrack}" ]; then # backtrack のグリフが全て重複していた場合、設定を追加せず ruturn
          echo "Removed all settings, skip ${caltList} index ${substIndex}: Lookup = ${lookupIndex}"
          eval "${2}=\${substIndex}" # 戻り値を入れる変数名を1番目の引数に指定する
          return
        fi
      fi # -n "${backtrack}"

# lookAhead --------------------

      unset removeLa
      if [ -n "${lookAhead}" ]; then # lookAhead がある場合
        for S in ${lookAhead[@]}; do # lookAhead の各グリフについて調査
          rm -f ${tmpdir}/${checkListName}*.tmp.txt
          overlap="true"

          ip="${input[@]}"
          ip=${ip// /,}
          if [ "${optimize_mode}" == "force" ] || [ ${optim} -eq 0 ]; then # 最適化処理を実行する場合
            eval echo ${S}{${ip}}"@@@@" | tr -d '{}' | tr ' ' '\n' >> "${tmpdir}/${checkListName}.aheadOnly.tmp.txt" # backtrack が無い設定のチェック用に保存
          fi
          if [ -n "${backtrack}" ]; then bt="${backtrack[@]}"; else bt="@"; fi
          bt=${bt// /,}
          if [ -n "${backtrack1}" ]; then bt1="${backtrack1[@]}"; else bt1="@"; fi
          bt1=${bt1// /,}
          if [ -n "${lookAhead1}" ]; then la1="${lookAhead1[@]}"; else la1="@"; fi
          la1=${la1// /,}
          if [ -n "${lookAheadX}" ]; then laX="${lookAheadX[@]}"; else laX="@"; fi
          laX=${laX// /,}
          eval echo ${S}{${ip}}{${bt}}{${bt1}}{${la1}}{${laX}} | tr -d '{}' | tr ' ' '\n' >> "${tmpdir}/${checkListName}.ahead.tmp.txt" # 前後2文字以上も含めた文字列を保存

          if [ "${optimize_mode}" == "optional" ] && [ ${optim} -ne 0 ]; then # 最適化処理をスキップする場合
            overlap="false" # 無条件でチェックリストに追加
            cat "${tmpdir}/${checkListName}.ahead.tmp.txt" >> "${tmpdir}/${checkListName}Ahead${S}.txt"

          else # "${optimize_mode}" == "optional" && ${optim} -ne 0
            if [[ ! -e "${tmpdir}/${checkListName}Ahead${S}.txt" ]]; then # 既設定ファイルが無い場合は空のファイルを作成
              :>| "${tmpdir}/${checkListName}Ahead${S}.txt"
            fi
            while read line0; do
              if [ -z "$(grep -x -m 1 "${line0}" "${tmpdir}/${checkListName}Ahead${S}.txt")" ]; then # backtrack が無い設定がすでに存在しないかチェック
                while read line1; do # backtrack が無い設定に抜けがあった場合追試
                  if [ -z "$(grep -x -m 1 "${line1}" "${tmpdir}/${checkListName}Ahead${S}.txt")" ]; then # 重複する設定がないかチェック
                    overlap="false" # 重複してい無い設定があった場合チェックリストに追加して break
                    cat "${tmpdir}/${checkListName}.ahead.tmp.txt" >> "${tmpdir}/${checkListName}Ahead${S}.txt"
                    break 2
                  fi # -z "${grep (重複する設定)
                done < "${tmpdir}/${checkListName}.ahead.tmp.txt" # 重複する設定が無い場合、何もせずに break
                break
              fi # -z "${grep (lookAhead が無い)
            done < "${tmpdir}/${checkListName}.aheadOnly.tmp.txt" # すでに backtrack が無い設定が全て存在した場合、スルー

            if [ "${overlap}" == "true" ]; then # すでに設定が全て存在していた場合、lookAhead から重複したグリフを削除
              lookAhead=(${lookAhead[@]/${S}/})
              removeLa+=" ${S}"
            fi

          fi # "${optimize_mode}" == "optional" && ${optim} -ne 0
        done # S

        if [ -n "${removeLa}" ]; then
          echo "Remove lookAhead setting${removeLa//_/}"
          if [ " ${addLa}" == "${removeLa} " ]; then # 設定漏れ補完で追加したグリフと最適化で除去したグリフが同じ場合
            echo "Added and removed lookAhead settings are the same"
          elif [ -n "${addLa}" ]; then # 異なる場合
            for S in ${removeLa}; do
              addLa=${addLa//${S}/}
            done
            printf "Difference in lookAhead settings: %s\n" "$(echo ${addLa//_/} | tr -s "[:space:]")"
          fi
          optimCheck=$((optimCheck + 1)) # 最適化が有効なので + 1
        fi
        if [ "${la}" != "|" ] && [ -z "${lookAhead}" ]; then # lookAhead のグリフが全て重複していた場合、設定を追加せず ruturn
          echo "Removed all settings, skip ${caltList} index ${substIndex}: Lookup = ${lookupIndex}"
          eval "${2}=\${substIndex}" # 戻り値を入れる変数名を1番目の引数に指定する
          return
        fi
      fi # -n "${lookAhead}"

# ---

      if [ ${optim} -ge 1 ] && [ ${optimCheck} -ge 1 ]; then # input、backtrack、lookAhead のいずれかで最適化が有効な条件なのに
          echo "Attention: Optimization flag is set to false" # スキップするように設定してある場合、注意を表示
      elif [ ${optim} -eq 0 ] && [ ${optimCheck} -eq 0 ]; then # input、backtrack、lookAhead の全てで最適化が有効ではない条件なのに
        echo "Attention: Optimization flag is set to true" # スキップしないように設定してある場合、注意を表示
      fi

    fi # "${optimize_mode}" == "force" || "${optimize_mode}" == "optional"
  fi # ${listNo} -le ${optimizeListNo}

# 設定追加 ====================

  if [ -n "${lookupIndex}" ]; then
    echo "Make ${caltList} index ${substIndex}: Lookup = ${lookupIndex}"
  else
    echo "Make ${caltList} index ${substIndex}: Lookup = none"
  fi

  echo "<ChainContextSubst index=\"${substIndex}\" Format=\"3\">" >> "${caltList}.txt"

# backtrack --------------------

  if [ -n "${backtrack}" ]; then # 入力した文字の左側
    letter_members backtrack "${backtrack[*]}"
    rm -f ${tmpdir}/${caltListName}.tmp.txt
    for S in ${backtrack[@]}; do
      glyph_name "${S}" >> "${tmpdir}/${caltListName}.tmp.txt" # 略号から通し番号とグリフ名を取得
    done
    {
      echo "<BacktrackCoverage index=\"0\">"
      glyph_value "${tmpdir}/${caltListName}.tmp.txt" # 通し番号とグリフ名から XML を取得
      echo "</BacktrackCoverage>"
    } >> "${caltList}.txt"
  fi

  if [ -n "${backtrack1}" ]; then # 入力した文字の左側2つ目
    letter_members backtrack1 "${backtrack1[*]}"
    rm -f ${tmpdir}/${caltListName}.tmp.txt
    for S in ${backtrack1[@]}; do
      glyph_name "${S}" >> "${tmpdir}/${caltListName}.tmp.txt"
    done
    {
      echo "<BacktrackCoverage index=\"0\">"
      glyph_value "${tmpdir}/${caltListName}.tmp.txt"
      echo "</BacktrackCoverage>"
    } >> "${caltList}.txt"
  fi

# input --------------------

  letter_members input "${input[*]}"
  rm -f ${tmpdir}/${caltListName}.tmp.txt
  for S in ${input[@]}; do
    glyph_name "${S}" >> "${tmpdir}/${caltListName}.tmp.txt"
  done
  {
    echo "<InputCoverage index=\"0\">" # 入力した文字(グリフ変換対象)
    glyph_value "${tmpdir}/${caltListName}.tmp.txt"
    echo "</InputCoverage>"
  } >> "${caltList}.txt"

# lookAhead --------------------

  if [ -n "${lookAhead}" ]; then # 入力した文字の右側
    letter_members lookAhead "${lookAhead[*]}"
    rm -f ${tmpdir}/${caltListName}.tmp.txt
    for S in ${lookAhead[@]}; do
      glyph_name "${S}" >> "${tmpdir}/${caltListName}.tmp.txt"
    done
    {
      echo "<LookAheadCoverage index=\"0\">"
      glyph_value "${tmpdir}/${caltListName}.tmp.txt"
      echo "</LookAheadCoverage>"
    } >> "${caltList}.txt"
  fi

  if [ -n "${lookAhead1}" ]; then # 入力した文字の右側2つ目
    letter_members lookAhead1 "${lookAhead1[*]}"
    rm -f ${tmpdir}/${caltListName}.tmp.txt
    for S in ${lookAhead1[@]}; do
      glyph_name "${S}" >> "${tmpdir}/${caltListName}.tmp.txt"
    done
    {
      echo "<LookAheadCoverage index=\"0\">"
      glyph_value "${tmpdir}/${caltListName}.tmp.txt"
      echo "</LookAheadCoverage>"
    } >> "${caltList}.txt"
  fi

  if [ -n "${lookAheadX}" ]; then # 入力した文字の右側3つ目以降
    letter_members lookAheadX "${lookAheadX[*]}"
    for i in $(seq 2 "${aheadMax}"); do
      rm -f ${tmpdir}/${caltListName}.tmp.txt
      for S in ${lookAheadX[@]}; do
        glyph_name "${S}" >> "${tmpdir}/${caltListName}.tmp.txt"
      done
      {
        echo "<LookAheadCoverage index=\"0\">"
        glyph_value "${tmpdir}/${caltListName}.tmp.txt"
        echo "</LookAheadCoverage>"
      } >> "${caltList}.txt"
      done
    fi

# lookupIndex --------------------

  if [ -n "${lookupIndex}" ]; then # 条件がそろった時にジャンプするテーブル番号
    {
      echo "<SubstLookupRecord index=\"0\">"
      echo "<SequenceIndex value=\"0\"/>"
      echo "<LookupListIndex value=\"${lookupIndex}\"/>"
      echo "</SubstLookupRecord>"
    } >> "${caltList}.txt"
  fi

  echo "</ChainContextSubst>" >> "${caltList}.txt"

  eval "${2}=\$((substIndex + 1))" # 戻り値を入れる変数名を1番目の引数に指定する
}

# ヘルプを表示する関数 ||||||||||||||||||||||||||||||||||||||||

calt_table_maker_help()
{
    echo "Usage: calt_table_maker.sh [options]"
    echo ""
    echo "Options:"
    echo "  -h         Display this information"
    echo "  -x         Cleaning temporary files" # 一時作成ファイルの消去のみ
    echo "  -X         Cleaning temporary files and saved kerning settings" # 一時作成ファイルとカーニング設定の消去のみ
    echo "  -l         Leave (do NOT remove) temporary files"
    echo "  -n number  Set glyph number of \"A moved left\""
    echo "  -k         Don't make calt settings for latin characters"
    echo "  -b         Make kerning settings for basic latin characters only"
    echo "  -O         Enable force optimization process"
    echo "  -o         Enable optimization process"
}

# メイン ||||||||||||||||||||||||||||||||||||||||

echo
echo "- GSUB table [calt, LookupType 6] maker -"
echo

# Get options
while getopts hxXln:kbOo OPT
do
    case "${OPT}" in
        "h" )
            calt_table_maker_help
            exit 0
            ;;
        "x" )
            echo "Option: Cleaning temporary files"
            echo "Remove temporary files"
            rm -rf ${tmpdir_name}.*
            exit 0
            ;;
        "X" )
            echo "Option: Cleaning temporary files and saved kerning settings"
            echo "Remove temporary files"
            rm -rf ${tmpdir_name}.*
            echo "Remove kerning settings"
            rm -f ${caltListName}*.txt
            rm -rf "${karndir_name}"
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
        "k" )
            echo "Option: Don't make calt settings for latin characters"
            symbol_only_flag="true"
            ;;
        "b" )
            echo "Option: Make calt settings for basic latin characters only"
            basic_only_flag="true"
            ;;
        "O" )
            echo "Option: Enable force optimization process"
            optimize_mode="force"
            ;;
        "o" )
            echo "Option: Enable optimization process"
            optimize_mode="optional"
            ;;
        * )
            calt_table_maker_help
            exit 1
            ;;
    esac
done
echo

if [ "${glyphNo_flag}" = "false" ]; then
  gsubList_txt=$(find . -maxdepth 1 -name "${gsubList}.txt" | head -n 1)
  if [ -n "${gsubList_txt}" ]; then # gsubListがあり、
    echo "Found GSUB List"
    caltNo=$(grep -m 1 'Substitution in="A"' "${gsubList}.txt")
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

# calt_table_maker に変更が無く、すでに設定が作成されていた場合それを呼び出して終了
output_data=$(sha256sum calt_table_maker.sh | cut -d ' ' -f 1)
if [ "${symbol_only_flag}" = "true" ]; then
  karnsetdir_name="k"
fi
if [ "${basic_only_flag}" = "true" ]; then
  karnsetdir_name="${karnsetdir_name}b"
fi
if [ "${optimize_mode}" = "force" ]; then
  karnsetdir_name="${karnsetdir_name}O"
elif [ "${optimize_mode}" = "optional" ]; then
  karnsetdir_name="${karnsetdir_name}o"
fi
karnsetdir_name="${karnsetdir_name}${glyphNo}"
file_data_txt=$(find "./${karndir_name}/${karnsetdir_name}" -maxdepth 1 -name "${fileDataName}.txt" | head -n 1)
if [ -n "${file_data_txt}" ]; then
  input_data=$(head -n 1 "${karndir_name}/${karnsetdir_name}/${fileDataName}.txt")
  if [ "${input_data}" = "${output_data}" ]; then
    echo "calt_table_maker is unchanged"
    echo "Use saved kerning settings"
    cp -f ${karndir_name}/${karnsetdir_name}/${caltListName}_*.txt "."
    echo
    exit 0
  fi
fi
echo "calt_table_maker is changed or kerning settings not exist"
echo "Make new kerning settings"
echo

# 一時保管フォルダ作成
tmpdir=$(mktemp -d ./"${tmpdir_name}".XXXXXX) || exit 2

# グリフ名変換用辞書作成 (グリフのIDS順に並べること) ||||||||||||||||||||||||||||||||||||||||

# 略号と名前 ----------------------------------------

exclam=("EXC") # 直接扱えない記号があるため略号を使用
quotedbl=("QTD")
number=("NUM")
dollar=("DOL")
percent=("PCT")
and=("AND")
quote=("QTE")
asterisk=("AST")
plus=("PLS")
comma=("COM")
hyphen=("HYP")
fullStop=("DOT")
solidus=("SLH")
parenLeft=("LPN")
parenRight=("RPN")
symbol2x=("${exclam}" "${quotedbl}" "${number}" "${dollar}" "${percent}" "${and}" "${quote}" \
"${parenLeft}" "${parenRight}" "${asterisk}" "${plus}" "${comma}" "${hyphen}" "${fullStop}" "${solidus}")
symbol2x_name=("exclam" "quotedbl" "numbersign" "dollar" "percent" "ampersand" "quotesingle" \
"parenleft" "parenright" "asterisk" "plus" "comma" "hyphen" "period" "slash")

figure=(0 1 2 3 4 5 6 7 8 9)
figure_name=("zero" "one" "two" "three" "four" "five" "six" "seven" "eight" "nine")

colon=("CLN")
semicolon=("SCL")
less=("LES")
equal=("EQL")
greater=("GRT")
question=("QET")
symbol3x=("${colon}" "${semicolon}" "${less}" "${equal}" "${greater}" "${question}")
symbol3x_name=("colon" "semicolon" "less" "equal" "greater" "question")

at=("ATT")
symbol4x=("${at}")
symbol4x_name=("at")

# グリフ略号 (A B..y z, AL BL..yL zL, AR BR..yR zR 通常のグリフ、左に移動したグリフ、右に移動したグリフ)
# グリフ名 (A B..y z, glyphXXXXX..glyphYYYYY)
latin45=(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) # 略号の始めの文字
latin45_name=(${latin45[@]})

bracketLeft=("LBK")
rSolidus=("BSH")
bracketRight=("RBK")
circum=("CRC")
underscore=("USC")
grave=("GRV")
symbol5x=("${bracketLeft}" "${rSolidus}" "${bracketRight}" "${circum}" "${underscore}" "${grave}")
symbol5x_name=("bracketleft" "backslash" "bracketright" "asciicircum" "underscore" "grave")

latin67=(a b c d e f g h i j k l m n o p q r s t u v w x y z) # 略号の始めの文字
latin67_name=(${latin67[@]})

braceLeft=("LBC")
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

word=(${symbol2x[@]} ${figure[@]} ${symbol3x[@]} ${symbol4x[@]}) # 記号・数字
name=(${symbol2x_name[@]} ${figure_name[@]} ${symbol3x_name[@]} ${symbol4x_name[@]})
for j in ${!word[@]}; do
  echo "$i ${word[j]}N ${name[j]}" >> "${tmpdir}/${dict}.txt"
  i=$((i + 1))
done

word=(${latin45[@]}) # A-Z
name=(${latin45_name[@]})
for j in ${!word[@]}; do
  echo "$i ${word[j]}N ${name[j]}" >> "${tmpdir}/${dict}.txt"
  i=$((i + 1))
done

word=(${symbol5x[@]}) # 記号
name=(${symbol5x_name[@]})
for j in ${!word[@]}; do
  echo "$i ${word[j]}N ${name[j]}" >> "${tmpdir}/${dict}.txt"
  i=$((i + 1))
done

word=(${latin67[@]}) # a-z
name=(${latin67_name[@]})
for j in ${!word[@]}; do
  echo "$i ${word[j]}N ${name[j]}" >> "${tmpdir}/${dict}.txt"
  i=$((i + 1))
done

word=(${symbol7x[@]}) # 記号
name=(${symbol7x_name[@]})
for j in ${!word[@]}; do
  echo "$i ${word[j]}N ${name[j]}" >> "${tmpdir}/${dict}.txt"
  i=$((i + 1))
done

word=(${latinCx[@]}) # À-Å
name=(${latinCx_name[@]})
for j in ${!word[@]}; do
  echo "$i ${word[j]}N ${name[j]}" >> "${tmpdir}/${dict}.txt"
  i=$((i + 1))
done

echo "$i ${latinCy}N ${latinCy_name}" >> "${tmpdir}/${dict}.txt" # Æ
i=$((i + 1))
echo "$i ${latinCy}L ${latinCy_name}" >> "${tmpdir}/${dict}.txt" # Æ は移動しないため
i=$((i + 1))
echo "$i ${latinCy}R ${latinCy_name}" >> "${tmpdir}/${dict}.txt" # Æ は移動しないため
i=$((i + 1))

word=(${latinCz[@]} ${latinDx[@]} ${latinEx[@]}) # Ç-å
name=(${latinCz_name[@]} ${latinDx_name[@]} ${latinEx_name[@]})
for j in ${!word[@]}; do
  echo "$i ${word[j]}N ${name[j]}" >> "${tmpdir}/${dict}.txt"
  i=$((i + 1))
done

echo "$i ${latinEy}N ${latinEy_name}" >> "${tmpdir}/${dict}.txt" # æ
i=$((i + 1))
echo "$i ${latinEy}L ${latinEy_name}" >> "${tmpdir}/${dict}.txt" # æ は移動しないため
i=$((i + 1))
echo "$i ${latinEy}R ${latinEy_name}" >> "${tmpdir}/${dict}.txt" # æ は移動しないため
i=$((i + 1))

word=(${latinEz[@]} ${latinFx[@]} ${latin10x[@]} ${latin11x[@]} \
${latin12x[@]} ${latin13x[@]} ${latin14x[@]} ${latin15x[@]}) # ç-ő
name=(${latinEz_name[@]} ${latinFx_name[@]} ${latin10x_name[@]} ${latin11x_name[@]} \
${latin12x_name[@]} ${latin13x_name[@]} ${latin14x_name[@]} ${latin15x_name[@]})
for j in ${!word[@]}; do
  echo "$i ${word[j]}N ${name[j]}" >> "${tmpdir}/${dict}.txt"
  i=$((i + 1))
done

for j in ${!latin15y[@]}; do # Œ œ
  echo "$i ${latin15y[j]}N ${latin15y_name[j]}" >> "${tmpdir}/${dict}.txt"
  i=$((i + 1))
  echo "$i ${latin15y[j]}L ${latin15y_name[j]}" >> "${tmpdir}/${dict}.txt" # Œ œ は移動しないため
  i=$((i + 1))
  echo "$i ${latin15y[j]}R ${latin15y_name[j]}" >> "${tmpdir}/${dict}.txt" # Œ œ は移動しないため
  i=$((i + 1))
done

word=(${latin15z[@]} ${latin16x[@]} ${latin17x[@]} ${latin21x[@]} ${latin1E9x[@]}) # Ŕ-ẞ
name=(${latin15z_name[@]} ${latin16x_name[@]} ${latin17x_name[@]} ${latin21x_name[@]} ${latin1E9x_name[@]})
for j in ${!word[@]}; do
  echo "$i ${word[j]}N ${name[j]}" >> "${tmpdir}/${dict}.txt"
  i=$((i + 1))
done

# 左に移動した文字 ----------------------------------------

word=(${latin45[@]} ${latin67[@]} \
${latinCx[@]} ${latinCz[@]} ${latinDx[@]} ${latinEx[@]} ${latinEz[@]} ${latinFx[@]} \
${latin10x[@]} ${latin11x[@]} ${latin12x[@]} ${latin13x[@]} ${latin14x[@]} ${latin15x[@]} ${latin15z[@]} \
${latin16x[@]} ${latin17x[@]} ${latin21x[@]} ${latin1E9x[@]}) # A-ẞ

i=${glyphNo}

for S in ${word[@]}; do
  echo "$i ${S}L glyph${i}" >> "${tmpdir}/${dict}.txt"
  i=$((i + 1))
done

# 右に移動した文字 ----------------------------------------

for S in ${word[@]}; do
  echo "$i ${S}R glyph${i}" >> "${tmpdir}/${dict}.txt"
  i=$((i + 1))
done

# 3桁マークの付いた数字 ----------------------------------------

word=(${figure[@]}) # 0-9

for S in ${word[@]}; do
  echo "$i ${S}3 glyph${i}" >> "${tmpdir}/${dict}.txt"
  i=$((i + 1))
done

# 4桁マークの付いた数字 ----------------------------------------

for S in ${word[@]}; do
  echo "$i ${S}4 glyph${i}" >> "${tmpdir}/${dict}.txt"
  i=$((i + 1))
done

# 12桁マークの付いた数字 ----------------------------------------

for S in ${word[@]}; do
  echo "$i ${S}2 glyph${i}" >> "${tmpdir}/${dict}.txt"
  i=$((i + 1))
done

# 小数の数字 ----------------------------------------

for S in ${word[@]}; do
  echo "$i ${S}0 glyph${i}" >> "${tmpdir}/${dict}.txt"
  i=$((i + 1))
done

# 下に移動した記号 ----------------------------------------

word=(${bar} ${tilde}) # |~

for S in ${word[@]}; do
  echo "$i ${S}D glyph${i}" >> "${tmpdir}/${dict}.txt"
  echo "$i ${S}DN glyph${i}" >> "${tmpdir}/${dict}.txt" # |~ は左右にも動くため、左右移動設定時のノーマル状態として追加
  i=$((i + 1))
done

# 上に移動した記号 ----------------------------------------

word=(${colon} ${asterisk} ${plus} ${hyphen} ${equal}) # :*+-=

for S in ${word[@]}; do
  echo "$i ${S}U glyph${i}" >> "${tmpdir}/${dict}.txt"
  if [ "${S}" == "${colon}" ]; then # : は左右にも動くため追加
    echo "$i ${S}UN glyph${i}" >> "${tmpdir}/${dict}.txt"
  fi
  i=$((i + 1))
done

# 左に移動した記号 ----------------------------------------

word=(${asterisk} ${plus} ${hyphen} ${equal} ${underscore} ${solidus} ${rSolidus} ${less} ${greater} \
${parenLeft} ${parenRight} ${bracketLeft} ${bracketRight} ${braceLeft} ${braceRight} ${exclam} \
${quotedbl} ${quote} ${comma} ${fullStop} ${colon} ${semicolon} ${question} ${grave} ${bar} \
"${bar}D" "${tilde}D" "${colon}U") # 上下に動いた後、左右にも動く |~: を追加

for S in ${word[@]}; do
  echo "$i ${S}L glyph${i}" >> "${tmpdir}/${dict}.txt"
  i=$((i + 1))
done

# 右に移動した記号 ----------------------------------------

for S in ${word[@]}; do
  echo "$i ${S}R glyph${i}" >> "${tmpdir}/${dict}.txt"
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
 #  S="_AO_"; class+=("${S}"); eval ${S}=\(Æ Œ\) # Æ Œ エラーが出る場合はコメントアウト解除
 #  S="_TH_"; class+=("${S}"); eval ${S}=\(Þ\) # Þ

  S="__a"; class+=("${S}"); eval ${S}=\(a\) # a # 設定の重複チェック用ファイル作成時に区別するため
  S="__b"; class+=("${S}"); eval ${S}=\(b\) # b # 変数の命名規則を大文字と小文字で変える
  S="__c"; class+=("${S}"); eval ${S}=\(c\) # c # (通常の APFS だとファイル名の大文字と小文字を区別しないため)
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
 #  S="__ao"; class+=("${S}"); eval ${S}=\(æ œ\) # æ œ エラーが出る場合はコメントアウト解除
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
  S="_AO_"; class+=("${S}"); eval ${S}=\(Æ Œ\) # Æ Œ
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
  S="__ao"; class+=("${S}"); eval ${S}=\(æ œ\) # æ œ
  S="__th"; class+=("${S}"); eval ${S}=\(þ\) # þ
 #  S="__ss"; class+=("${S}"); eval ${S}=\(ß\) # ß
  S="__kg"; class+=("${S}"); eval ${S}=\(ĸ\) # ĸ
fi

# ラテン文字単独 (ここで定義した変数を使う) ====================

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
S="_AO"; class+=("${S}"); eval ${S}=\(_AO_\) # Æ Œ
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
S="_ao"; class+=("${S}"); eval ${S}=\(__ao\) # æ œ
S="_th"; class+=("${S}"); eval ${S}=\(__th\) # þ
 #S="_ss"; class+=("${S}"); eval ${S}=\(__ss\) # ß
S="_kg"; class+=("${S}"); eval ${S}=\(__kg\) # ĸ

# ラテン文字グループ (ここで定義した変数を使う) ====================

# 基本 --------------------

# 各グリフの重心、形状の違いから、左寄り、右寄り、中央寄り、中央寄りと均等の中間、均等、幅広、Vの字形に分類する

S="outBDLgravityCapitalL"; class+=("${S}"); eval ${S}=\(_E_ _F_ _K_ _P_ _R_ _TH_\) # BDL 以外の左寄りの大文字
S="outBDgravityCapitalL";  class+=("${S}"); eval ${S}=\(${outBDLgravityCapitalL[@]} _L_\) # BD 以外の左寄りの大文字
S="outLgravityCapitalL";   class+=("${S}"); eval ${S}=\(${outBDLgravityCapitalL[@]} _B_ _D_\) # L 以外の左寄りの大文字
S="gravityCapitalL";       class+=("${S}"); eval ${S}=\(${outBDLgravityCapitalL[@]} _B_ _D_ _L_\) # 左寄りの大文字
S="outhbpthgravitySmallL"; class+=("${S}"); eval ${S}=\(__k __kg\) # hbpþ を除く左寄りの小文字 (ß を除く)
S="outbpthgravitySmallL";  class+=("${S}"); eval ${S}=\(${outhbpthgravitySmallL[@]} __h\) # bpþ を除く左寄りの小文字 (ß を除く)
S="outhgravitySmallL";     class+=("${S}"); eval ${S}=\(${outhbpthgravitySmallL[@]} __b __p __th\) # h を除く左寄りの小文字 (ß を除く)
S="gravitySmallL";         class+=("${S}"); eval ${S}=\(${outhbpthgravitySmallL[@]} __h __b __p __th\) # 左寄りの小文字 (ß を除く)
 # gravityCapitalL=("_B" "_D" "_E" "_F" "_K" "_L" "_P" "_R" "_TH")
 # gravitySmallL=("_b" "_h" "_k" "_p" "_th" "_ss" "_kg")

S="outcgravitySmallR"; class+=("${S}"); eval ${S}=\(__a __d __g __q\) # c 以外の右寄りの小文字
S="gravityCapitalR";   class+=("${S}"); eval ${S}=\(_C_ _G_\) # 右寄りの大文字
S="gravitySmallR";     class+=("${S}"); eval ${S}=\(${outcgravitySmallR[@]} __c\) # 右寄りの小文字
 # gravityCapitalR=("_C" "_G")
 # gravitySmallR=("_a" "_c" "_d" "_g" "_q")

S="outWgravityCapitalW"; class+=("${S}"); eval ${S}=\(_M_ _AO_\) # W 以外の幅広の大文字
S="outwgravitySmallW";   class+=("${S}"); eval ${S}=\(__m __ao\) # w 以外の幅広の小文字
S="gravityCapitalW";     class+=("${S}"); eval ${S}=\(${outWgravityCapitalW[@]} _W_\) # 幅広の大文字
S="gravitySmallW";       class+=("${S}"); eval ${S}=\(${outwgravitySmallW[@]} __w\) # 幅広の小文字
 # gravityCapitalW=("_M" "_W" "_AO")
 # gravitySmallW=("_m" "_w" "_ao")

S="outOQgravityCapitalE"; class+=("${S}"); eval ${S}=\(_H_ _N_ _U_\) # OQ 以外の均等な大文字
S="gravityCapitalE";      class+=("${S}"); eval ${S}=\(${outOQgravityCapitalE[@]} _O_ _Q_\) # 均等な大文字
S="gravitySmallE";        class+=("${S}"); eval ${S}=\(__n __u\) # 均等な小文字
 # gravityCapitalE=("_H" "_N" "_O" "_Q" "_U")
 # gravitySmallE=("_n" "_u")

S="outAgravityCapitalM"; class+=("${S}"); eval ${S}=\(_S_ _X_ _Z_\) # A 以外の中間の大文字
S="gravityCapitalM";     class+=("${S}"); eval ${S}=\(${outAgravityCapitalM[@]} _A_\) # 中間の大文字
S="outeogravitySmallM";  class+=("${S}"); eval ${S}=\(__s __x __z\) # eo 以外の中間の小文字
S="gravitySmallM";       class+=("${S}"); eval ${S}=\(${outeogravitySmallM[@]} __e __o\) # 中間の小文字
 # gravityCapitalM=("_A" "_S" "_X" "_Z")
 # gravitySmallM=("_e" "_o" "_s" "_x" "_z")

S="gravityCapitalV"; class+=("${S}"); eval ${S}=\(_T_ _V_ _Y_\) # Vの大文字
S="outygravitySmallV";   class+=("${S}"); eval ${S}=\(__v\) # y 以外のvの字の小文字
S="gravitySmallV";   class+=("${S}"); eval ${S}=\(${outygravitySmallV[@]} __y\) # vの小文字
 # gravityCapitalV=("_T" "_V" "_Y")
 # gravitySmallV=("_v" "_y")

S="outJgravityCapitalC"; class+=("${S}"); eval ${S}=\(_I_\) # J 以外の狭い大文字
S="gravityCapitalC";     class+=("${S}"); eval ${S}=\(${outJgravityCapitalC[@]} _J_\) # 狭い大文字
S="outjrtgravitySmallC"; class+=("${S}"); eval ${S}=\(__f __i __l\) # jrt 以外の狭い小文字
S="outjgravitySmallC";   class+=("${S}"); eval ${S}=\(__f __i __l __r __t\) # j 以外の狭い小文字
S="outtgravitySmallC";   class+=("${S}"); eval ${S}=\(__f __i __j __l __r\) # t 以外の狭い小文字
S="outrtgravitySmallC";  class+=("${S}"); eval ${S}=\(__f __i __j __l\) # rt 以外の狭い小文字
S="gravitySmallC";       class+=("${S}"); eval ${S}=\(${outjrtgravitySmallC[@]} __j __r __t\) # 狭い小文字
 # gravityCapitalC=("_I" "_J")
 # gravitySmallC=("_f" "_i" "_j" "_l" "_r" "_t")

S="gravityL"; class+=("${S}"); eval ${S}=\(${gravityCapitalL[@]} ${gravitySmallL[@]}\) # 左寄り
S="gravityR"; class+=("${S}"); eval ${S}=\(${gravityCapitalR[@]} ${gravitySmallR[@]}\) # 右寄り
S="gravityW"; class+=("${S}"); eval ${S}=\(${gravityCapitalW[@]} ${gravitySmallW[@]}\) # 幅広
S="gravityE"; class+=("${S}"); eval ${S}=\(${gravityCapitalE[@]} ${gravitySmallE[@]}\) # 均等
S="gravityM"; class+=("${S}"); eval ${S}=\(${gravityCapitalM[@]} ${gravitySmallM[@]}\) # 中間
S="gravityV"; class+=("${S}"); eval ${S}=\(${gravityCapitalV[@]} ${gravitySmallV[@]}\) # Vの字
S="gravityC"; class+=("${S}"); eval ${S}=\(${gravityCapitalC[@]} ${gravitySmallC[@]}\) # 狭い

S="outBDLbpthgravityL"; class+=("${S}"); eval ${S}=\(${outBDLgravityCapitalL[@]} ${outbpthgravitySmallL[@]}\) # BDLbpþ 以外の左寄り
S="outLbpthgravityL";   class+=("${S}"); eval ${S}=\(${outLgravityCapitalL[@]} ${outbpthgravitySmallL[@]}\) # Lbpþ 以外の左寄り
S="outLhgravityL";      class+=("${S}"); eval ${S}=\(${outLgravityCapitalL[@]} ${outhgravitySmallL[@]}\) # Lh 以外の左寄り
S="outBDLgravityL";     class+=("${S}"); eval ${S}=\(${outBDLgravityCapitalL[@]} ${gravitySmallL[@]}\) # BDL 以外の左寄り
S="outBDgravityL";      class+=("${S}"); eval ${S}=\(${outBDgravityCapitalL[@]} ${gravitySmallL[@]}\) # BD 以外の左寄り
S="outLgravityL";       class+=("${S}"); eval ${S}=\(${outLgravityCapitalL[@]} ${gravitySmallL[@]}\) # L 以外の左寄り
S="outbpthgravityL";    class+=("${S}"); eval ${S}=\(${gravityCapitalL[@]} ${outbpthgravitySmallL[@]}\) # bpþ 以外の左寄り
S="outhgravityL";       class+=("${S}"); eval ${S}=\(${gravityCapitalL[@]} ${outhgravitySmallL[@]}\) # h 以外の左寄り

S="outcgravityR";   class+=("${S}"); eval ${S}=\(${gravityCapitalR[@]} ${outcgravitySmallR[@]}\) # c 以外の右寄り

S="outWwgravityW";  class+=("${S}"); eval ${S}=\(${outWgravityCapitalW[@]} ${outwgravitySmallW[@]}\) # Ww 以外の幅広

S="outOQgravityE";  class+=("${S}"); eval ${S}=\(${outOQgravityCapitalE[@]} ${gravitySmallE[@]}\) # OQ 以外の均等

S="outAgravityM";   class+=("${S}"); eval ${S}=\(${outAgravityCapitalM[@]} ${gravitySmallM[@]}\) # A 以外の中間
S="outeogravityM";  class+=("${S}"); eval ${S}=\(${gravityCapitalM[@]} ${outeogravitySmallM[@]}\) # eo 以外の中間
S="outAeogravityM"; class+=("${S}"); eval ${S}=\(${outAgravityCapitalM[@]} ${outeogravitySmallM[@]}\) # Aeo 以外の中間

S="outygravityV"; class+=("${S}"); eval ${S}=\(${gravityCapitalV[@]} ${outygravitySmallV[@]}\) # y 以外のVの字

S="outJjrtgravityC"; class+=("${S}"); eval ${S}=\(${outJgravityCapitalC[@]} ${outjrtgravitySmallC[@]}\) # Jjrt 以外の狭い
S="outJjgravityC";   class+=("${S}"); eval ${S}=\(${outJgravityCapitalC[@]} ${outjgravitySmallC[@]}\) # Jj 以外の狭い
S="outJgravityC";    class+=("${S}"); eval ${S}=\(${outJgravityCapitalC[@]} ${gravitySmallC[@]}\) # J 以外の狭い
S="outjgravityC";    class+=("${S}"); eval ${S}=\(${gravityCapitalC[@]} ${outjgravitySmallC[@]}\) # j 以外の狭い
S="outtgravityC";    class+=("${S}"); eval ${S}=\(${gravityCapitalC[@]} ${outtgravitySmallC[@]}\) # t 以外の狭い
S="outrtgravityC";   class+=("${S}"); eval ${S}=\(${gravityCapitalC[@]} ${outrtgravitySmallC[@]}\) # rt 以外の狭い

# 丸い文字 --------------------

S="circleCapitalC"; class+=("${S}"); eval ${S}=\(_O_ _Q_\) # 丸い大文字
S="circleSmallC";   class+=("${S}"); eval ${S}=\(__e __o\) # 丸い小文字

S="circleCapitalL"; class+=("${S}"); eval ${S}=\(_C_ _G_\) # 左が丸い大文字
S="circleSmallL";   class+=("${S}"); eval ${S}=\(__c __d __g __q\) # 左が丸い小文字

S="circleCapitalR"; class+=("${S}"); eval ${S}=\(_B_ _D_\) # 右が丸い大文字
S="circleSmallR";   class+=("${S}"); eval ${S}=\(__b __p __th\) # 右が丸い小文字 (ß を除く)
 #S="circleSmallR";   class+=("${S}"); eval ${S}=\(__b __p __th __ss\) # 右が丸い小文字

S="circleC"; class+=("${S}"); eval ${S}=\(${circleCapitalC[@]} ${circleSmallC[@]}\) # 丸い文字
S="circleL"; class+=("${S}"); eval ${S}=\(${circleCapitalL[@]} ${circleSmallL[@]}\) # 左が丸い文字
S="circleR"; class+=("${S}"); eval ${S}=\(${circleCapitalR[@]} ${circleSmallR[@]}\) # 右が丸い文字

# 上が開いている文字 --------------------

S="highSpaceCapitalC"; class+=("${S}"); eval ${S}=\(""\) # 両上が開いている大文字
 #S="highSpaceCapitalC"; class+=("${S}"); eval ${S}=\(_A_\) # 両上が開いている大文字
S="highSpaceSmallC";   class+=("${S}"); eval ${S}=\(__a __c __e __g __n \
__o __p __q __s __u __v __x __y __z __kg\) # 両上が開いている小文字 (幅広、狭いを除く)
 #S="highSpaceSmallC";   class+=("${S}"); eval ${S}=\(__a __c __e __g __i \
 #__j __m __n __o __p __q __r __s __u __v __w __x __y __z __kg\) # 両上が開いている小文字

S="highSpaceCapitalL"; class+=("${S}"); eval ${S}=\(""\) # 左上が開いている大文字
 #S="highSpaceCapitalL"; class+=("${S}"); eval ${S}=\(_J_\) # 左上が開いている大文字
S="highSpaceSmallL";   class+=("${S}"); eval ${S}=\(__d\) # 左上が開いている小文字

S="highSpaceCapitalR"; class+=("${S}"); eval ${S}=\(""\) # 右上が開いている大文字
 #S="highSpaceCapitalR"; class+=("${S}"); eval ${S}=\(_L_\) # 右上が開いている大文字
S="highSpaceSmallR";   class+=("${S}"); eval ${S}=\(__b __h __k __th\) # 右上が開いている小文字

S="highSpaceC"; class+=("${S}"); eval ${S}=\(${highSpaceCapitalC[@]} ${highSpaceSmallC[@]}\) # 両上が開いている文字
S="highSpaceL"; class+=("${S}"); eval ${S}=\(${highSpaceCapitalL[@]} ${highSpaceSmallL[@]}\) # 左上が開いている文字
S="highSpaceR"; class+=("${S}"); eval ${S}=\(${highSpaceCapitalR[@]} ${highSpaceSmallR[@]}\) # 右上が開いている文字

# 中が開いている文字 --------------------

S="midSpaceCapitalC"; class+=("${S}"); eval ${S}=\(_A_ _I_ _T_ _V_ _X_ _Y_ _Z_\) # 両側が開いている大文字
S="midSpaceSmallC";   class+=("${S}"); eval ${S}=\(__f __i __l __x\) # 両側が開いている小文字

S="midSpaceCapitalL"; class+=("${S}"); eval ${S}=\(_J_\) # 左側が開いている大文字
S="midSpaceSmallL";   class+=("${S}"); eval ${S}=\(__j\) # 左側が開いている小文字

S="midSpaceCapitalR"; class+=("${S}"); eval ${S}=\(_E_ _F_ _K_ _L_ _P_ _R_\) # 右側が開いている大文字
S="midSpaceSmallR";   class+=("${S}"); eval ${S}=\(__k __r __t __kg\) # 右側が開いている小文字

S="midSpaceC"; class+=("${S}"); eval ${S}=\(${midSpaceCapitalC[@]} ${midSpaceSmallC[@]}\) # 両側が開いている文字
S="midSpaceL"; class+=("${S}"); eval ${S}=\(${midSpaceCapitalL[@]} ${midSpaceSmallL[@]}\) # 左側が開いている文字
S="midSpaceR"; class+=("${S}"); eval ${S}=\(${midSpaceCapitalR[@]} ${midSpaceSmallR[@]}\) # 右側が開いている文字

# 下が開いている文字 --------------------

S="lowSpaceCapitalC"; class+=("${S}"); eval ${S}=\(_T_ _V_ _Y_\) # 両下が開いている大文字
S="lowSpaceSmallC";   class+=("${S}"); eval ${S}=\(__f __i __l __v\) # 両下が開いている小文字

S="lowSpaceCapitalL"; class+=("${S}"); eval ${S}=\(""\) # 左下が開いている大文字
S="lowSpaceSmallL";   class+=("${S}"); eval ${S}=\(__t\) # 左下が開いている小文字

S="lowSpaceCapitalR"; class+=("${S}"); eval ${S}=\(_F_ _J_ _P_ _TH_\) # 右下が開いている大文字
S="lowSpaceSmallR";   class+=("${S}"); eval ${S}=\(__j __r __y\) # 右下が開いている小文字

S="lowSpaceC"; class+=("${S}"); eval ${S}=\(${lowSpaceCapitalC[@]} ${lowSpaceSmallC[@]}\) # 両下が開いている文字
S="lowSpaceL"; class+=("${S}"); eval ${S}=\(${lowSpaceCapitalL[@]} ${lowSpaceSmallL[@]}\) # 左下が開いている文字
S="lowSpaceR"; class+=("${S}"); eval ${S}=\(${lowSpaceCapitalR[@]} ${lowSpaceSmallR[@]}\) # 右下が開いている文字

# 全て --------------------

S="capital"; class+=("${S}")
eval ${S}=\(${gravityCapitalL[@]} ${gravityCapitalR[@]} ${gravityCapitalW[@]} ${gravityCapitalE[@]}\)
eval ${S}+=\(${gravityCapitalM[@]} ${gravityCapitalV[@]} ${gravityCapitalC[@]}\) # 全ての大文字
S="small"; class+=("${S}")
eval ${S}=\(${gravitySmallL[@]} ${gravitySmallR[@]} ${gravitySmallW[@]} ${gravitySmallE[@]}\)
eval ${S}+=\(${gravitySmallM[@]} ${gravitySmallV[@]} ${gravitySmallC[@]}\) # 全ての小文字

 # 移動 (置換) しないグリフ (input[@]から除去)

S="fixedGlyph"; class+=("${S}"); eval ${S}=\(_AO_ __ao\)

# 略号生成 (N: 通常、L: 左移動後、R: 右移動後)

for S in ${class[@]}; do
  eval member=(\${${S}[@]})
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

# 数字単独 (ここで定義した変数を使う) ====================

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

# 数字グループ (ここで定義した変数を使う) ====================

S="figure"; class+=("${S}"); eval ${S}=\(_0_ _1_ _2_ _3_ _4_ _5_ _6_ _7_ _8_ _9_\) # 数字
S="figureB"; class+=("${S}"); eval ${S}=\(_0_ _1_\) # 数字 (2進数)

# 略号生成 (N: 通常、3: 3桁、4: 4桁、2: 12桁、0: 小数)

for S in ${class[@]}; do
  eval member=(\${${S}[@]})
  for T in ${member[@]}; do
    eval ${S}N+=\("${T}N"\)
    eval ${S}3+=\("${T}3"\)
    eval ${S}4+=\("${T}4"\)
    eval ${S}2+=\("${T}2"\)
    eval ${S}0+=\("${T}0"\)
  done
done

# 記号 (下左右移動あり、ここで定義した変数は直接使用しないこと) ====================
class=("")

S="_bar_";   class+=("${S}"); eval ${S}=\("${bar}"\) # |
S="_tilde_"; class+=("${S}"); eval ${S}=\("${tilde}"\) # ~

# 記号単独 (下左右移動あり、ここで定義した変数を使う) ====================

S="_bar";   class+=("${S}"); eval ${S}=\(_bar_\) # |
S="_tilde"; class+=("${S}"); eval ${S}=\(_tilde_\) # ~

# 略号生成 (N: 通常、D: 下移動後、L: 左移動後、R: 右移動後)

for S in ${class[@]}; do
  eval member=(\${${S}[@]})
  for T in ${member[@]}; do
    eval ${S}N+=\("${T}N"\)
    eval ${S}D+=\("${T}D"\)
    eval ${S}L+=\("${T}L"\)
    eval ${S}R+=\("${T}R"\)
  done
done

# 記号 (上左右移動あり、ここで定義した変数は直接使用しないこと) ====================
class=("")

S="_asterisk_"; class+=("${S}"); eval ${S}=\("${asterisk}"\) # *
S="_plus_";     class+=("${S}"); eval ${S}=\("${plus}"\) # +
S="_hyphen_";   class+=("${S}"); eval ${S}=\("${hyphen}"\) # -
S="_equal_";    class+=("${S}"); eval ${S}=\("${equal}"\) # =
S="_colon_";    class+=("${S}"); eval ${S}=\("${colon}"\) # :

# 記号単独 (上左右移動あり、ここで定義した変数を使う) ====================

S="_asterisk"; class+=("${S}"); eval ${S}=\(_asterisk_\) # *
S="_plus";     class+=("${S}"); eval ${S}=\(_plus_\) # +
S="_hyphen";   class+=("${S}"); eval ${S}=\(_hyphen_\) # -
S="_equal";    class+=("${S}"); eval ${S}=\(_equal_\) # =
S="_colon";    class+=("${S}"); eval ${S}=\(_colon_\) # :

# 略号生成 (N: 通常、U: 上移動後、L: 左移動後、R: 右移動後)

for S in ${class[@]}; do
  eval member=(\${${S}[@]})
  for T in ${member[@]}; do
    eval ${S}N+=\("${T}N"\)
    eval ${S}U+=\("${T}U"\)
    eval ${S}L+=\("${T}L"\)
    eval ${S}R+=\("${T}R"\)
  done
done

# 記号 (下移動あり、ここで定義した変数は直接使用しないこと) ====================
 #class=("")
 # (空席)

# 記号単独 (下移動あり、ここで定義した変数を使う) ====================
 # (空席)

# 略号生成 (N: 通常、D: 下移動後)

 #for S in ${class[@]}; do
 #  eval member=(\${${S}[@]})
 #  for T in ${member[@]}; do
 #    eval ${S}N+=\("${T}N"\)
 #    eval ${S}D+=\("${T}D"\)
 #  done
 #done

# 記号 (上移動あり、ここで定義した変数は直接使用しないこと) ====================
 #class=("")
 # (空席)

# 記号単独 (上移動あり、ここで定義した変数を使う) ====================
 # (空席)

# 略号生成 (N: 通常、U: 上移動後)

 #for S in ${class[@]}; do
 #  eval member=(\${${S}[@]})
 #  for T in ${member[@]}; do
 #    eval ${S}N+=\("${T}N"\)
 #    eval ${S}U+=\("${T}U"\)
 #  done
 #done

# 記号 (左右移動あり、ここで定義した変数は直接使用しないこと) ====================
class=("")

S="_solidus_";      class+=("${S}"); eval ${S}=\("${solidus}"\) # solidus
S="_less_";         class+=("${S}"); eval ${S}=\("${less}"\) # <
S="_greater_";      class+=("${S}"); eval ${S}=\("${greater}"\) # >
S="_rSolidus_";     class+=("${S}"); eval ${S}=\("${rSolidus}"\) # reverse solidus
S="_underscore_";   class+=("${S}"); eval ${S}=\("${underscore}"\) # _
S="_parenleft_";    class+=("${S}"); eval ${S}=\("${parenLeft}"\) # (
S="_parenright_";   class+=("${S}"); eval ${S}=\("${parenRight}"\) # )
S="_bracketleft_";  class+=("${S}"); eval ${S}=\("${bracketLeft}"\) # [
S="_bracketright_"; class+=("${S}"); eval ${S}=\("${bracketRight}"\) # ]
S="_braceleft_";    class+=("${S}"); eval ${S}=\("${braceLeft}"\) # {
S="_braceright_";   class+=("${S}"); eval ${S}=\("${braceRight}"\) # }
S="_exclam_";       class+=("${S}"); eval ${S}=\("${exclam}"\) # !
S="_quotedbl_";     class+=("${S}"); eval ${S}=\("${quotedbl}"\) # "
S="_quote_";        class+=("${S}"); eval ${S}=\("${quote}"\) # '
S="_comma_";        class+=("${S}"); eval ${S}=\("${comma}"\) # ,
S="_fullStop_";     class+=("${S}"); eval ${S}=\("${fullStop}"\) # .
S="_semicolon_";    class+=("${S}"); eval ${S}=\("${semicolon}"\) # ;
S="_question_";     class+=("${S}"); eval ${S}=\("${question}"\) # ?
S="_grave_";        class+=("${S}"); eval ${S}=\("${grave}"\) # `
S="_barD_";         class+=("${S}"); eval ${S}=\("${bar}D"\) # 下に移動した |
S="_tildeD_";       class+=("${S}"); eval ${S}=\("${tilde}D"\) # 下に移動した ~
S="_colonU_";       class+=("${S}"); eval ${S}=\("${colon}U"\) # 上に移動した :

# 記号単独 (左右移動あり、ここで定義した変数を使う) ====================

S="_solidus";      class+=("${S}"); eval ${S}=\(_solidus_\) # solidus
S="_less";         class+=("${S}"); eval ${S}=\(_less_\) # <
S="_greater";      class+=("${S}"); eval ${S}=\(_greater_\) # >
S="_rSolidus";     class+=("${S}"); eval ${S}=\(_rSolidus_\) # reverse solidus
S="_underscore";   class+=("${S}"); eval ${S}=\(_underscore_\) # _
S="_parenleft";    class+=("${S}"); eval ${S}=\(_parenleft_\) # (
S="_parenright";   class+=("${S}"); eval ${S}=\(_parenright_\) # )
S="_bracketleft";  class+=("${S}"); eval ${S}=\(_bracketleft_\) # [
S="_bracketright"; class+=("${S}"); eval ${S}=\(_bracketright_\) # ]
S="_braceleft";    class+=("${S}"); eval ${S}=\(_braceleft_\) # {
S="_braceright";   class+=("${S}"); eval ${S}=\(_braceright_\) # }
S="_exclam";       class+=("${S}"); eval ${S}=\(_exclam_\) # !
S="_quotedbl";     class+=("${S}"); eval ${S}=\(_quotedbl_\) # "
S="_quote";        class+=("${S}"); eval ${S}=\(_quote_\) # '
S="_comma";        class+=("${S}"); eval ${S}=\(_comma_\) # ,
S="_fullStop";     class+=("${S}"); eval ${S}=\(_fullStop_\) # .
S="_semicolon";    class+=("${S}"); eval ${S}=\(_semicolon_\) # ;
S="_question";     class+=("${S}"); eval ${S}=\(_question_\) # ?
S="_grave";        class+=("${S}"); eval ${S}=\(_grave_\) # `
S="_barD";         class+=("${S}"); eval ${S}=\(_barD_\) # 下に移動した |
S="_tildeD";       class+=("${S}"); eval ${S}=\(_tildeD_\) # 下に移動した ~
S="_colonU";       class+=("${S}"); eval ${S}=\(_colonU_\) # 上に移動した :

# 記号グループ (左右移動あり、ここで定義した変数を使う) ====================

S="operatorH";   class+=("${S}"); eval ${S}=\(_asterisk_ _plus_ _hyphen_ _equal_\) # 前後の記号が上下に移動する記号
S="bracketL";    class+=("${S}"); eval ${S}=\(_parenleft_ _bracketleft_ _braceleft_\) # 左括弧
S="bracketR";    class+=("${S}"); eval ${S}=\(_parenright_ _bracketright_ _braceright_\) # 右括弧
S="barDotComma"; class+=("${S}"); eval ${S}=\(_question_ _exclam_ _fullStop_ _colon_ \
                                              _comma_ _semicolon_ _bar_ _barD_ _colonU_\) # ?!.:,;|

# 略号生成 (N: 通常、L: 左移動後、R: 右移動後)

for S in ${class[@]}; do
  eval member=(\${${S}[@]})
  for T in ${member[@]}; do
    eval ${S}N+=\("${T}N"\)
    eval ${S}L+=\("${T}L"\)
    eval ${S}R+=\("${T}R"\)
  done
done

# 記号 (通常のみ、ここで定義した変数は直接使用しないこと) ====================
class=("")

S="_number_";     class+=("${S}"); eval ${S}=\("${number}"\) # #
S="_dollar_";     class+=("${S}"); eval ${S}=\("${dollar}"\) # $
S="_percent_";    class+=("${S}"); eval ${S}=\("${percent}"\) # %
S="_ampersand_";  class+=("${S}"); eval ${S}=\("${and}"\) # &
S="_at_";         class+=("${S}"); eval ${S}=\("${at}"\) # @
S="_circum_";     class+=("${S}"); eval ${S}=\("${circum}"\) # ^

# 記号単独 (通常のみ、ここで定義した変数を使う) ====================

S="_number";     class+=("${S}"); eval ${S}=\(_number_\) # #
S="_dollar";     class+=("${S}"); eval ${S}=\(_dollar_\) # $
S="_percent";    class+=("${S}"); eval ${S}=\(_percent_\) # %
S="_ampersand";  class+=("${S}"); eval ${S}=\(_ampersand_\) # &
S="_at";         class+=("${S}"); eval ${S}=\(_at_\) # @
S="_circum";     class+=("${S}"); eval ${S}=\(_circum_\) # ^

# 数字・記号グループ (通常のみ、ここで定義した変数を使う) ====================

S="figureE";   class+=("${S}"); eval ${S}=\(_0_ _2_ _3_ _4_ _5_ _6_ _7_ _8_ _9_\) # 幅のある数字
S="figureC";   class+=("${S}"); eval ${S}=\(_1_\) # 幅の狭い数字
S="symbolE";   class+=("${S}"); eval ${S}=\(_number_ _dollar_ _percent_ _ampersand_ \
                                            _asterisk_ _less_ _equal_ _greater_ _at_\) # 幅のある記号

# 略号生成 (N: 通常)

for S in ${class[@]}; do
  eval member=(\${${S}[@]})
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

# ●左が幅のある記号、数字で 右が左寄り、右寄り、幅広、均等、中間の文字の場合 左寄り、右寄り、幅広、均等、中間の文字 移動しない
backtrack=(${symbolEN[@]} ${figureEN[@]})
input=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が幅のある記号、数字で 右が Vの字の場合 幅広の文字 移動しない
backtrack=(${symbolEN[@]} ${figureEN[@]})
input=(${gravityWN[@]})
lookAhead=(${gravityVN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# もろもろ例外 ========================================

# 同じ文字を等間隔にさせる例外処理 ----------------------------------------

# 左が丸い文字、EFh
class=(_C _G _c _d _g _q _E _F _h)
for S in ${class[@]}; do
  # ○○○○ ○○○○ ○移動しない
  eval backtrack=(\${${S}L[@]})
  eval input=(\${${S}N[@]})
  eval lookAhead=(\${${S}N[@]})
  chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""
done

# A に関する例外処理 1 ----------------------------------------

# 左が W で 右が左寄り、幅広の文字の場合 A 左に移動
 #backtrack=(${_WL[@]} \
 #${_WN[@]})
 #input=(${_AN[@]})
 #lookAhead=(${gravityLN[@]} ${gravityWN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が W で 右が、左下が開いている大文字か I の場合 A 右に移動 (次の処理とセット)
 #backtrack=(${_WR[@]})
 #input=(${_AN[@]})
 #lookAhead=(${lowSpaceCapitalCN[@]} ${_IN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が W の場合 A 移動しない
 #backtrack=(${_WR[@]})
 #input=(${_AN[@]})
 #lookAhead=("")
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ---

# ○左が、右下が開いている大文字、I で 右が、左下が開いている大文字の場合 A 移動しない (次の処理とセット)
backtrack=(${lowSpaceCapitalRR[@]} ${lowSpaceCapitalCR[@]} ${_IR[@]} \
${_IN[@]})
input=(${_AN[@]})
lookAhead=(${lowSpaceCapitalCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が、右下が開いている大文字か W の場合 A 左に移動
backtrack=(${lowSpaceCapitalRL[@]} ${lowSpaceCapitalCL[@]} \
${lowSpaceCapitalRR[@]} ${lowSpaceCapitalCR[@]} \
${lowSpaceCapitalRN[@]} ${lowSpaceCapitalCN[@]})
 #backtrack=(${lowSpaceCapitalRL[@]} ${lowSpaceCapitalCL[@]} ${_WL[@]} \
 #${lowSpaceCapitalRR[@]} ${lowSpaceCapitalCR[@]} \
 #${lowSpaceCapitalRN[@]} ${lowSpaceCapitalCN[@]})
input=(${_AN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ---

# 左が A の場合 W 左に移動しない (次の処理とセット)
 #backtrack=(${_AR[@]})
 #input=(${_WN[@]})
 #lookAhead=("")
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が A の場合 左下が開いている大文字、W 左に移動
backtrack=(${_AL[@]} \
${_AR[@]} \
${_AN[@]})
input=(${lowSpaceCapitalCN[@]})
 #input=(${lowSpaceCapitalCN[@]} ${_WN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ---

# 左が左寄り、右寄り、均等、中間の大文字で 右が W の場合 A 右に移動しない
 #backtrack=(${gravityCapitalLL[@]} ${gravityCapitalRL[@]} ${gravityCapitalEL[@]} ${gravityCapitalML[@]})
 #input=(${_AN[@]})
 #lookAhead=(${_WN[@]})
 #chain_context 0 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が幅広以外の大文字で 右が A の場合 右下が開いている大文字、W 右に移動しない
backtrack=(${gravityCapitalLL[@]} ${gravityCapitalRL[@]} ${gravityCapitalEL[@]} ${gravityCapitalML[@]} ${gravityCapitalVL[@]} \
${gravityCapitalVN[@]} ${gravityCapitalCN[@]})
input=(${lowSpaceCapitalRN[@]} ${lowSpaceCapitalCN[@]})
 #input=(${lowSpaceCapitalRN[@]} ${lowSpaceCapitalCN[@]} ${_WN[@]})
lookAhead=(${_AN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# I に関する例外処理 1 ----------------------------------------

# ○左が BDR 以外の左寄り、Vの字、狭い文字、中間の小文字で 右が左寄り、右寄り、幅広、均等、中間の文字の場合 I 左に移動
backtrack=(${gravitySmallLN[@]} ${gravitySmallMN[@]} ${gravityVN[@]} ${gravityCN[@]} \
${_EN[@]} ${_FN[@]} ${_KN[@]} ${_LN[@]} ${_PN[@]} ${_THN[@]})
input=(${_IN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が均等な大文字、右寄りの文字で 右が右寄り、中間の大文字の場合 I 右に移動
backtrack=(${gravityRR[@]} ${gravityCapitalER[@]})
input=(${_IN[@]})
lookAhead=(${gravityCapitalRN[@]} ${gravityCapitalMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# J に関する例外処理 ----------------------------------------

# ○左が、右下が開いている文字で 右が狭い文字以外の場合 J 左に移動
backtrack=(${lowSpaceRR[@]} ${lowSpaceCR[@]})
input=(${_JN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が幅広の文字で 右が右寄り、中間の文字の場合 J 右に移動
backtrack=(${gravityWN[@]})
input=(${_JN[@]})
lookAhead=(${gravityRN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

#---

# ○左が J の場合 引き寄せない大文字、左寄り、幅広の文字 右に移動
backtrack=(${_JR[@]})
input=(${gravityLN[@]} ${gravityCapitalRN[@]} ${gravityWN[@]} ${gravityCapitalEN[@]} ${outAgravityCapitalMN[@]})
 #input=(${gravityLN[@]} ${gravityCapitalRN[@]} ${gravityWN[@]} ${gravityCapitalEN[@]} ${gravityCapitalMN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左が J で 右が中間、Vの字の場合 狭い文字 移動しない
backtrack=(${_JR[@]})
input=(${outJgravityCN[@]})
 #input=(${gravityCN[@]})
lookAhead=(${gravityMN[@]} ${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# L に関する例外処理 1 ----------------------------------------

# 左が L の場合 狭い文字以外 左に移動 (なんちゃって最適化により無くてもよさそう)
 #backtrack=(${_LL[@]} \
 #${_LN[@]})
 #input=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
 #lookAhead=("")
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が L で 右が左寄り、右寄り、幅広、均等、中間の文字の場合 右寄り、中間の文字 左に移動 (次とその次の処理とセット)
backtrack=(${_LR[@]})
input=(${gravityRN[@]} ${gravityMN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が L で 右が均等な大文字、L 以外の左寄り、幅広の文字の場合 左寄り、均等な文字 左に移動 (次の処理とセット)
 #backtrack=(${_LR[@]}) #  (なんちゃって最適化により無くてもよさそう)
 #input=(${gravityLN[@]} ${outOQgravityEN[@]})
 # # input=(${gravityLN[@]} ${gravityEN[@]})
 #lookAhead=(${outLgravitLN[@]} ${gravityWN[@]} ${gravityCapitalEN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が L の場合 引き寄せない文字 移動しない (なんちゃって最適化により無くてもよさそう)
 #backtrack=(${_LR[@]})
 #input=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]})
 #lookAhead=("")
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○両側が L の場合 L 左に移動しない
backtrack=(${_LR[@]})
input=(${_LN[@]})
lookAhead=(${_LN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が L で 右が Vの字、狭い文字の場合 j 以外の狭い文字 左に移動しない
backtrack=(${_LR[@]})
input=(${outjgravityCN[@]})
lookAhead=(${gravityVN[@]} ${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が L の場合 Vの字、狭い文字 左に移動
backtrack=(${_LR[@]})
input=(${gravityVN[@]} ${gravityCN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ---

# ○左が狭い文字の場合 L 右に移動しない (この後の処理とセット)
backtrack=(${gravityCL[@]})
input=(${_LN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○右が右寄り、中間、Vの字、狭い文字、LWw の場合 L 右に移動
backtrack=("")
input=(${_LN[@]})
lookAhead=(${gravityRN[@]} ${gravityMN[@]} ${gravityVN[@]} ${gravityCN[@]} \
${_LN[@]} ${_WN[@]} ${_wN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左が左寄り、右寄り、中間、Vの字、狭い文字で 右が左寄り、幅広、均等な文字の場合 L 右に移動
backtrack=(${gravityRL[@]} ${gravityEL[@]} \
${gravityVR[@]} ${outJgravityCR[@]} \
${outLgravityLN[@]} ${gravityRN[@]} ${gravityMN[@]} ${gravityVN[@]} ${gravityCN[@]})
 #backtrack=(${gravityRL[@]} ${gravityEL[@]} \
 #${gravityVR[@]} ${gravityCR[@]} \
 #${gravityLN[@]} ${gravityRN[@]} ${gravityMN[@]} ${gravityVN[@]} ${gravityCN[@]})
input=(${_LN[@]})
lookAhead=(${outLgravityLN[@]} ${outWwgravityWN[@]} ${gravityEN[@]})
 #lookAhead=(${gravityLN[@]} ${gravityWN[@]} ${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左が左寄り、中間、Vの字の場合 L 左に移動しない
backtrack=(${outLgravityLL[@]} ${gravityML[@]} ${gravityVL[@]})
 #backtrack=(${gravityLL[@]} ${gravityML[@]} ${gravityVL[@]})
input=(${_LN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# W に関する例外処理 ----------------------------------------

# ○左が Vの大文字で 右が左寄りの文字の場合 W 左に移動しない
backtrack=(${gravityCapitalVL[@]})
input=(${_WN[@]})
lookAhead=(${gravityLN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# c に関する例外処理 ----------------------------------------

# ○左が c で 右が c 以外の右寄りの文字、丸い小文字の場合 左寄り、幅広、均等、中間の小文字 右に移動しない
backtrack=(${_cN[@]})
input=(${gravitySmallLN[@]} ${gravitySmallWN[@]} ${gravitySmallEN[@]} ${gravitySmallMN[@]})
lookAhead=(${outcgravityRN[@]} \
${circleSmallCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# f に関する例外処理 ----------------------------------------

# ○左が f で 右が左寄り、幅広の文字、右寄り、均等な大文字の場合 左寄り、右寄り、均等、Vの大文字、bhkþ 左に移動 (次の処理とセット)
backtrack=(${_fN[@]})
input=(${gravityCapitalLN[@]} ${gravityCapitalRN[@]} ${gravityCapitalEN[@]} ${gravityCapitalVN[@]} \
${_bN[@]} ${_hN[@]} ${_kN[@]} ${_thN[@]})
lookAhead=(${gravityLN[@]} ${gravityCapitalRN[@]} ${gravityWN[@]} ${gravityCapitalEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が f の場合 左寄り、右寄り、均等、Vの大文字、bhkþ 左に移動しない
backtrack=(${_fR[@]} \
${_fN[@]})
input=(${gravityCapitalLN[@]} ${gravityCapitalRN[@]} ${gravityCapitalEN[@]} ${gravityCapitalVN[@]} \
${_bN[@]} ${_hN[@]} ${_kN[@]} ${_thN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# j に関する例外処理 ----------------------------------------

# ○両側が j の場合 j 移動しない
backtrack=(${_jR[@]})
input=(${_jN[@]})
lookAhead=(${_jN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が幅広の文字で 右が左寄り、右寄り、均等、中間の文字の場合 j 移動しない
backtrack=(${gravityWR[@]})
input=(${_jN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○両側が幅広の文字の場合 j 左に移動
backtrack=(${gravityWR[@]})
input=(${_jN[@]})
lookAhead=(${gravityWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が Ggq の場合 j 移動しない
backtrack=(${_GR[@]} ${_gR[@]} ${_qR[@]})
input=(${_jN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が Cc 以外の右寄りの文字、均等、中間の大文字、EKR で、右が il の場合 j 移動しない
backtrack=(${outcgravitySmallRR[@]} ${gravityCapitalER[@]} ${gravityCapitalMR[@]} \
${_ER[@]} ${_KR[@]} ${_RR[@]})
input=(${_jN[@]})
lookAhead=(${_iN[@]} ${_lN[@]})
chain_context 0 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が全ての文字の場合 j 左に移動
backtrack=(${gravityRL[@]} ${gravityWL[@]} ${gravityEL[@]} \
${outLgravityLR[@]} ${gravityRR[@]} ${gravityER[@]} ${gravityMR[@]} ${gravityVR[@]} ${gravityCR[@]} \
${capitalN[@]} ${smallN[@]})
 #backtrack=(${gravityRL[@]} ${gravityWL[@]} ${gravityEL[@]} \
 #${gravityLR[@]} ${gravityRR[@]} ${gravityER[@]} ${gravityMR[@]} ${gravityVR[@]} ${gravityCR[@]} \
 #${capitalN[@]} ${smallN[@]})
input=(${_jN[@]})
lookAhead=("")
chain_context 0 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ---

# ○左が Jjt で 右が j の場合 t 右に移動
backtrack=(${_JR[@]} ${_jR[@]} ${_tR[@]})
input=(${_tN[@]})
lookAhead=(${_jN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左が左寄り、中間、Vの字、IJijlrt で 右が j の場合 左寄り、均等な文字、中間の小文字、CcIfilr 右に移動
backtrack=(${_IR[@]} ${_JR[@]} ${_iR[@]} ${_jR[@]} ${_lR[@]} ${_rR[@]} ${_tR[@]} \
${gravityLN[@]} ${gravityMN[@]} ${gravityVN[@]} ${_JN[@]} ${_jN[@]} ${_tN[@]})
input=(${outLgravityLN[@]} ${gravityEN[@]} ${gravitySmallMN[@]} \
${_CN[@]} ${_cN[@]} ${_IN[@]} ${_fN[@]} ${_iN[@]} ${_lN[@]} ${_rN[@]})
 #input=(${gravityLN[@]} ${gravityEN[@]} ${gravitySmallMN[@]} \
 #${_CN[@]} ${_cN[@]} ${_IN[@]} ${_fN[@]} ${_iN[@]} ${_lN[@]} ${_rN[@]})
lookAhead=(${_jN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左が Ifil で 右が j の場合 左寄り、均等な文字、中間の小文字、Ifilr 右に移動
backtrack=(${_fR[@]} \
${_IN[@]} ${_fN[@]} ${_iN[@]} ${_lN[@]})
input=(${outLgravityLN[@]} \
${_IN[@]} ${_fN[@]} ${_iN[@]} ${_lN[@]} ${_rN[@]})
 #input=(${gravityLN[@]} \
 #${_IN[@]} ${_fN[@]} ${_iN[@]} ${_lN[@]} ${_rN[@]})
lookAhead=(${_jN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左が中間、Vの字で 右が j の場合 狭い文字 移動しない
backtrack=(${gravityML[@]} ${gravityVL[@]})
input=(${gravityCN[@]})
lookAhead=(${_jN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# rt に関する例外処理 1 ----------------------------------------

# ○両側が r の場合 r 左に移動しない (次の処理とセット)
backtrack=(${_rN[@]})
input=(${_rN[@]})
lookAhead=(${_rN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が Ifilr で 右が狭い文字の場合 rt 左に移動
backtrack=(${_IN[@]} ${_fN[@]} ${_iN[@]} ${_lN[@]} ${_rN[@]})
input=(${_rN[@]} ${_tN[@]})
lookAhead=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が幅広の文字で 右が引き離す文字の場合 t 移動しない
backtrack=(${gravityWL[@]})
input=(${_tN[@]})
lookAhead=(${gravityLN[@]} ${gravityWN[@]} ${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が左寄り、均等、中間、Vの小文字、ac で 右が左寄り、右寄り、均等、中間の文字の場合 t 移動しない
backtrack=(${gravitySmallLR[@]} ${gravitySmallER[@]} ${gravitySmallMR[@]} ${gravitySmallVR[@]} ${_aR[@]} ${_cR[@]})
input=(${_tN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が左寄り、右寄り、均等、中間、Vの小文字で 右が狭い文字の場合 t 移動しない
backtrack=(${gravitySmallLN[@]} ${gravitySmallRN[@]} ${gravitySmallEN[@]} ${gravitySmallMN[@]} ${gravitySmallVN[@]})
input=(${_tN[@]})
lookAhead=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が右寄り、均等な小文字で 右が左寄り、右寄り、均等、中間の文字の場合 rt 左に移動
backtrack=(${gravitySmallRN[@]} ${gravitySmallEN[@]})
input=(${_rN[@]} ${_tN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ---

# ○左が rt で 右が左寄り、幅広、均等な場合 幅広の文字 左に移動 (次の処理とセット)
backtrack=(${_rL[@]} ${_tL[@]} \
${_rN[@]} ${_tN[@]})
input=(${gravityWN[@]})
lookAhead=(${gravityLN[@]} ${gravityWN[@]} ${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が rt の場合 幅広の文字 左に移動しない
backtrack=(${_rL[@]} ${_tL[@]} \
${_rN[@]} ${_tN[@]})
input=(${gravityWN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が rt で 右が幅広の文字の場合 左寄り、均等な文字 左に移動 (この後の処理とセット)
backtrack=(${_tL[@]} \
${_rN[@]} ${_tN[@]})
input=(${gravityLN[@]} ${gravityEN[@]})
lookAhead=(${gravityWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が t で 右が左寄り、均等な文字の場合 左寄り、均等な文字 左に移動 (次の処理とセット)
backtrack=(${_tL[@]})
input=(${outLgravityLN[@]} ${gravityEN[@]})
 #input=(${gravityLN[@]} ${gravityEN[@]})
lookAhead=(${gravityLN[@]} ${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が rt の場合 左寄り、均等な文字 左に移動しない
backtrack=(${_tL[@]} \
${_rN[@]} ${_tN[@]})
input=(${gravityLN[@]} ${gravityEN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が t で 右が左寄り、右寄り、幅広、均等、中間の文字の場合 右寄り、中間、Vの字 左に移動 (次の処理とセット)
backtrack=(${_tN[@]})
input=(${gravityRN[@]} ${gravityMN[@]} ${gravityVN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が t の場合 右寄り、中間、Vの字 移動しない
backtrack=(${_tN[@]})
input=(${gravityRN[@]} ${gravityMN[@]} ${gravityVN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が r で 右が j の場合 右寄り、中間の文字 左に移動しない
backtrack=(${_rN[@]})
input=(${gravityRN[@]} ${gravityMN[@]})
lookAhead=(${_jN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が rt で 右が右寄り、中間の文字の場合 Vの字 移動しない
backtrack=(${_rR[@]} ${_tR[@]})
input=(${gravityVN[@]})
lookAhead=(${gravityRN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が rt で 右が狭い文字の場合 右寄りの文字 移動しない
backtrack=(${_rR[@]} ${_tR[@]})
input=(${gravityRN[@]})
lookAhead=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が rt で 右が左寄り、右寄り、均等、中間、Vの字の場合 狭い文字 左に移動
backtrack=(${_rR[@]} ${_tR[@]})
input=(${outjgravityCN[@]})
 #input=(${gravityCN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が rt で 右が幅広の文字の場合 幅広と狭い文字以外 左に移動 (次の処理とセット、なんちゃって最適化により無くてもよさそう)
 #backtrack=(${_rR[@]} ${_tR[@]})
 #input=(${outLgravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
 # #input=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
 #lookAhead=(${gravityWN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が rt の場合 幅広と狭い文字以外 左に移動しない (なんちゃって最適化により無くてもよさそう)
 #backtrack=(${_rR[@]} ${_tR[@]})
 #input=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
 #lookAhead=("")
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# il に関する例外処理 ----------------------------------------

# ○左が均等な大文字、右寄りの文字で、右が il の場合 j 以外の狭い文字 右に移動
backtrack=(${gravityRN[@]} ${gravityCapitalEN[@]})
input=(${outjgravityCN[@]})
lookAhead=(${_iN[@]} ${_lN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左が左寄り、中間、Vの字で 右が左寄り、均等な大文字、右が丸い文字の場合 il 左に移動
backtrack=(${outLgravityLR[@]} ${gravityMR[@]} ${gravityVR[@]})
 #backtrack=(${gravityLR[@]} ${gravityMR[@]} ${gravityVR[@]})
input=(${_iN[@]} ${_lN[@]})
lookAhead=(${gravityCapitalLN[@]} ${gravityCapitalEN[@]} \
${circleRN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# y に関する例外処理 1 ----------------------------------------

# ○左が、均等な大文字、左上が開いている文字、gjq の場合 y 左に移動しない
backtrack=(${gravityCapitalEL[@]} ${highSpaceLL[@]} ${_gL[@]} ${_jL[@]} ${_qL[@]})
input=(${_yN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が、均等な大文字、左上が開いている文字で 右が引き寄せない文字の場合 y 右に移動しない
backtrack=(${gravityCapitalEN[@]} ${highSpaceLN[@]})
input=(${_yN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が、均等な大文字、左上が開いている文字、gjpqþ の場合 y 右に移動
backtrack=(${gravityCapitalER[@]} ${highSpaceLR[@]} ${_gR[@]} ${_jR[@]} ${_pR[@]} ${_qR[@]} ${_thR[@]} \
${gravityCapitalEN[@]} ${highSpaceLN[@]} ${_gN[@]} ${_jN[@]} ${_qN[@]})
input=(${_yN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# xz に関する例外処理 ----------------------------------------

# ○左が右寄りで 右が右寄り、中間の文字の場合 xz 右に移動
backtrack=(${gravityRN[@]})
input=(${_xN[@]} ${_zN[@]})
lookAhead=(${gravityRN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左が xz の場合 右が丸い小文字 移動しない
backtrack=(${_xN[@]} ${_zN[@]})
input=(${circleSmallRN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# A に関する例外処理 2 ----------------------------------------

# ○左が左寄りの大文字で 右が左寄り、均等な大文字の場合 A 右に移動
backtrack=(${outLgravityCapitalLR[@]})
 #backtrack=(${gravityCapitalLR[@]})
input=(${_AN[@]})
lookAhead=(${gravityCapitalLN[@]} ${gravityCapitalEN[@]})
chain_context 0 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# I に関する例外処理 2 ----------------------------------------

# ○左が I で 右が、左が丸い文字の場合 右が丸い文字 左に移動しない
backtrack=(${_IR[@]} \
${_IN[@]})
input=(${circleRN[@]})
lookAhead=(${circleLN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が I で 右が左寄りの文字、均等な小文字の場合 hkĸ 左に移動しない
backtrack=(${_IR[@]} \
${_IN[@]})
input=(${outbpthgravitySmallLN[@]})
lookAhead=(${gravityLN[@]} ${gravitySmallEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が I で 右が左寄り、右寄り、幅広、均等、中間の文字の場合 左寄りの文字、均等な大文字 左に移動
backtrack=(${_IN[@]})
input=(${outLgravityLN[@]} ${gravityCapitalEN[@]})
 #input=(${gravityLN[@]} ${gravityCapitalEN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が I の場合 左寄り、均等な大文字 移動しない
backtrack=(${_IN[@]})
input=(${gravityLN[@]} ${gravityCapitalEN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# Jj に関する例外処理 1 ----------------------------------------

# ○左が Jj で 右がVの小文字で その右が狭い文字の場合 中間の小文字、h 左に移動しない (この後の処理とセット)
backtrack1=("")
backtrack=(${_JL[@]} ${_jL[@]} \
${_JN[@]} ${_jN[@]})
input=(${gravitySmallMN[@]} ${_hN[@]})
lookAhead=(${gravitySmallVN[@]})
lookAhead1=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○左が Jj で 右が左寄り、右寄り、幅広、均等、中間の文字、Vの小文字の場合 右寄り、幅広、均等、中間の小文字、Vの字、狭い文字、h 左に移動 (次の処理とセット)
backtrack=(${_JL[@]} ${_jL[@]} \
${_JN[@]} ${_jN[@]})
input=(${gravitySmallRN[@]} ${gravityWN[@]} ${gravitySmallEN[@]} ${gravitySmallMN[@]} ${gravityVN[@]} ${gravityCN[@]} ${_hN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravitySmallVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が Jj の場合 狭い文字以外 移動しない
backtrack=(${_JL[@]} ${_jL[@]} \
${_JN[@]} ${_jN[@]})
input=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# Ww に関する例外処理 ----------------------------------------

# 左が中間、右が丸い文字、hn で その左が左寄り、右寄り、均等、中間の文字の場合 Ww 右に移動しない
 #backtrack1=(${gravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} ${gravityML[@]} \
 #${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
 #backtrack=(${gravityML[@]} ${_hL[@]} ${_nL[@]} \
 #${circleRL[@]} ${circleCL[@]})
 #input=(${_WN[@]} ${_wN[@]})
 #lookAhead=("")
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "" "${backtrack1[*]}"

# 左が Ww で 右が左寄り、右寄り、均等、中間の文字の場合 中間、右が丸い文字 右に移動しない
 #backtrack=(${_WL[@]} ${_wL[@]})
 #input=(${gravityMN[@]} \
 #${circleLN[@]} ${circleCN[@]})
 #lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 大文字と小文字に関する例外処理 1 ----------------------------------------

# ○左が FPTÞ で 右が狭い文字の場合 狭い小文字、左上が開いている文字 移動しない
backtrack=(${_TR[@]} \
${_FN[@]} ${_PN[@]} ${_TN[@]} ${_THN[@]})
input=(${outjgravitySmallCN[@]} \
${highSpaceLN[@]} ${highSpaceCN[@]})
 #input=(${gravitySmallCN[@]} \
 #${highSpaceLN[@]} ${highSpaceCN[@]})
lookAhead=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が F で 右が幅広の文字以外の場合 均等、狭い小文字 移動しない
backtrack=(${_FR[@]})
input=(${gravitySmallEN[@]} ${outjgravitySmallCN[@]})
 #input=(${gravitySmallEN[@]} ${gravitySmallCN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]} ${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が FT で 右が幅広の文字以外の場合 幅広の小文字 移動しない
backtrack=(${_TR[@]} \
${_FN[@]} ${_TN[@]})
input=(${gravitySmallWN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]} ${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が FT の場合 左上が開いている文字 左に移動
backtrack=(${_FL[@]} ${_TL[@]} \
${_TN[@]})
input=(${highSpaceLN[@]} ${highSpaceCN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が、右上が開いている文字で 右が左寄り、幅広、均等な文字、右寄りの大文字の場合 両下が開いている大文字 左に移動
backtrack=(${highSpaceRR[@]} ${highSpaceCR[@]} \
${highSpaceRN[@]} ${highSpaceCN[@]})
input=(${lowSpaceCapitalCN[@]})
lookAhead=(${gravityLN[@]} ${gravityCapitalRN[@]} ${gravityWN[@]} ${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 丸い文字に関する例外処理 1 ----------------------------------------

# 左が W で 右が右寄りの大文字、A の場合 丸い大文字 右に移動しない (なんちゃって最適化でいらない子判定)
 #backtrack=(${_WL[@]})
 #input=(${circleCapitalCN[@]})
 #lookAhead=(${gravityCapitalRN[@]} ${_AN[@]})
 #chain_context 0 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 左が Ww で 右が左寄り、均等な小文字の場合 均等、丸い文字 右に移動しない (大文字と小文字の処理と統合)
 #backtrack=(${_WL[@]} ${_wL[@]})
 #input=(${gravitySmallEN[@]})
 # #input=(${gravitySmallEN[@]} \
 # #${circleSmallCN[@]})
 #lookAhead=(${gravitySmallLN[@]} ${gravitySmallEN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 左が Ww で 右が右寄り、中間、Vの字の場合 丸い文字 右に移動しない
 #backtrack=(${_WL[@]} ${_wL[@]})
 #input=(${circleSmallCN[@]})
 #lookAhead=(${gravitySmallVN[@]})
 # #lookAhead=(${gravitySmallRN[@]} ${gravitySmallMN[@]} ${gravitySmallVN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 左が右寄り、右が丸い文字、均等な大文字、h で 右が Ww の場合 丸い文字 移動しない
 #backtrack=(${gravityRL[@]} ${gravityCapitalEL[@]} ${_hL[@]} \
 #${circleRL[@]} ${circleCL[@]} \
 #${circleRN[@]} ${circleCN[@]})
 #input=(${circleCN[@]})
 #lookAhead=(${_WN[@]} ${_wN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が幅広、右が丸い文字で 右が、右が丸い文字の場合 丸い文字 移動しない
backtrack=(${gravityWL[@]} \
${circleRL[@]})
input=(${circleCN[@]})
lookAhead=(${circleRN[@]} ${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が幅広の文字で 右が、左が丸い小文字の場合 丸い小文字 移動しない
backtrack=(${gravityWL[@]})
 #backtrack=(${gravityWL[@]} \
 #${circleRL[@]})
input=(${circleSmallCN[@]})
lookAhead=(${circleSmallLN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が均等な文字、h で 右が左寄りの文字、Vの小文字の場合 丸い文字 移動しない
backtrack=(${gravityEN[@]} ${_hN[@]})
input=(${circleCN[@]})
lookAhead=(${gravityLN[@]} ${gravitySmallVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が、eo 以外の中間の小文字で 右が左寄りの文字、右寄り、均等な大文字の場合 丸い小文字 左に移動 (大文字と小文字の処理とセット)
backtrack=(${outeogravitySmallMN[@]})
input=(${circleSmallCN[@]})
lookAhead=(${gravityLN[@]} ${gravityCapitalRN[@]} ${gravityCapitalEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が、右が丸い文字、PRÞ の場合 丸い文字 右に移動 (大文字と小文字の処理と統合)
 #backtrack=(${circleRR[@]} ${_PR[@]} ${_RR[@]} ${_THR[@]})
 #input=(${circleCN[@]})
 #lookAhead=(${gravityLN[@]} ${gravityEN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が丸い文字に関する例外処理 1 ----------------------------------------

# ○左が、右が丸い文字で 右が中間の文字の場合 左が丸い小文字 右に移動
backtrack=(${circleRN[@]} ${circleCN[@]})
input=(${circleSmallLN[@]} ${circleSmallCN[@]})
lookAhead=(${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左が、右が丸い文字で 右が Vの字の場合 左が丸い文字 右に移動
backtrack=(${circleRN[@]} ${circleCN[@]})
input=(${circleLN[@]} ${circleCN[@]})
lookAhead=(${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左が EKXkxĸ で 右が左寄り、右寄り、均等、中間の文字の場合 左が丸い文字 移動しない
backtrack=(${_ER[@]} ${_KR[@]} ${_XR[@]} ${_kR[@]} ${_xR[@]} ${_kgR[@]})
input=(${circleLN[@]} ${circleCN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が右が丸い小文字、B で 右が左寄りの文字、均等、右寄りの大文字の場合 左が丸い文字 左に移動
backtrack=(${circleSmallRL[@]} ${circleSmallCL[@]} ${_BL[@]})
input=(${circleLN[@]})
lookAhead=(${gravityLN[@]} ${gravityCapitalRN[@]} ${gravityCapitalEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が EFKTXkxĸ で 右が左寄り、右寄り、均等、中間の文字の場合 左が丸い文字 左に移動
backtrack=(${_EL[@]} ${_FL[@]} ${_KL[@]} ${_TL[@]} ${_XL[@]} ${_kL[@]} ${_xL[@]} ${_kgL[@]} \
${_EN[@]} ${_FN[@]} ${_KN[@]} ${_TN[@]} ${_XN[@]} ${_kN[@]} ${_xN[@]} ${_kgN[@]})
input=(${circleLN[@]} ${circleCN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が z で 右が右寄りの文字の場合 左が丸い小文字、o 左に移動
backtrack=(${_zL[@]} \
${_zN[@]})
input=(${circleSmallLN[@]} ${_oN[@]})
lookAhead=(${gravityRN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が z で 右が均等、中間の文字の場合 左が丸い小文字 左に移動
backtrack=(${_zL[@]} \
${_zN[@]})
input=(${circleSmallLN[@]})
lookAhead=(${gravityEN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が EFKTXkxzĸ で 右が狭い文字で その右が狭い文字の場合 丸い文字 右に移動 (次の処理とセット)
backtrack1=("")
backtrack=(${_EN[@]} ${_FN[@]} ${_KN[@]} ${_TN[@]} ${_XN[@]} ${_kN[@]} ${_xN[@]} ${_zN[@]} ${_kgN[@]})
input=(${circleCN[@]})
lookAhead=(${gravityCN[@]})
lookAhead1=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○左が EFKTXkxzĸ で 右が Vの字、狭い文字の場合 左が丸い文字 右に移動しない
backtrack=(${_EN[@]} ${_FN[@]} ${_KN[@]} ${_TN[@]} ${_XN[@]} ${_kN[@]} ${_xN[@]} ${_zN[@]} ${_kgN[@]})
input=(${circleLN[@]} ${circleCN[@]})
lookAhead=(${gravityVN[@]} ${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 左が右寄り、均等な文字で 右が、左が丸い文字の場合 Vの字 左に移動 (左側基準の通常処理と統合)
 #backtrack=(${gravityRL[@]} ${gravityEL[@]})
 #input=(${gravityVN[@]})
 #lookAhead=(${circleLN[@]} ${circleCN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が左寄り、中間の文字、an で 右が、丸い大文字の場合 Vの字 左に移動
backtrack=(${outLgravityLN[@]} ${gravityMN[@]} ${_aN[@]} ${_nN[@]})
 #backtrack=(${gravityLN[@]} ${gravityMN[@]} ${_aN[@]} ${_nN[@]})
input=(${gravityVN[@]})
lookAhead=(${circleCapitalCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が Ww で 右が右寄り、左が丸い文字の場合 Mm 右に移動しない
 #backtrack=(${_WL[@]} ${_wL[@]})
 #input=(${_MN[@]} ${_mN[@]})
 #lookAhead=(${gravityRN[@]} \
 #${circleCN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 右が丸い文字に関する例外処理 1 ----------------------------------------

# 左が右寄り、均等な大文字で 右が Ww の場合 右が丸い大文字 移動しない
 #backtrack=(${gravityCapitalRL[@]} ${gravityCapitalEL[@]})
 #input=(${circleCapitalRN[@]})
 #lookAhead=(${_WN[@]} ${_wN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が、右が丸い大文字の場合 狭い文字 左に移動しない
backtrack=(${circleCapitalRN[@]} ${circleCapitalCN[@]})
input=(${outjgravityCN[@]})
 #input=(${gravityCN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が、右が丸い文字、均等、丸い小文字で 右が c 以外の右寄り、丸い文字で その右が幅広の文字の場合 左寄りの小文字、右が丸い文字 右に移動しない
backtrack1=("")
backtrack=(${gravitySmallEN[@]} \
${circleRN[@]} ${circleSmallCN[@]})
input=(${gravitySmallLN[@]} \
${circleRN[@]} ${circleCN[@]})
lookAhead=(${outcgravityRN[@]} \
${circleCN[@]})
lookAhead1=(${gravityWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○左が丸くない左寄り、丸くない中間の文字で 右が c 以外の右寄り、丸い文字の場合 左寄りの小文字、右が丸い文字 右に移動しない (大文字と小文字の処理と統合)
backtrack=(${outBDLbpthgravityLN[@]} ${outeogravityMN[@]})
input=(${gravitySmallLN[@]} \
${circleRN[@]} ${circleCN[@]})
lookAhead=(${outcgravityRN[@]} \
${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が c で その左が狭い文字、L で 右が左寄り、均等、左が丸い文字の場合 右寄り、均等、右が丸い文字 左に移動しない
backtrack1=(${gravityCL[@]} ${_LL[@]} \
${gravityCR[@]} ${_LR[@]} \
${gravityCN[@]} ${_LN[@]})
backtrack=(${_cL[@]})
input=(${gravityRN[@]} ${gravityEN[@]} \
${circleRN[@]} ${circleCN[@]})
lookAhead=(${gravityLN[@]} ${gravityEN[@]} \
${circleLN[@]} ${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "" "${backtrack1[*]}"

# ○左が右寄り、均等な文字、h で 右が左寄り、均等、左が丸い文字の場合 右寄り、均等、右が丸い文字 左に移動しない
backtrack=(${outcgravityRL[@]} ${gravityEL[@]} ${_hL[@]})
input=(${gravityRN[@]} ${gravityEN[@]} \
${circleRN[@]} ${circleCN[@]})
lookAhead=(${gravityLN[@]} ${gravityEN[@]} \
${circleLN[@]} ${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が、右が丸い文字で 右が幅広、狭い文字以外の場合 均等、左右が丸い文字 左に移動しない (左が丸い文字の処理と統合)
backtrack=(${circleRL[@]} ${circleCL[@]})
input=(${gravityEN[@]} \
${circleLN[@]} ${circleRN[@]} ${circleCN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 大文字と小文字で処理が異なる例外処理 1 ----------------------------------------

# ○左が均等な大文字で 右が左寄りの文字の場合 幅広、均等な大文字 右に移動
backtrack=(${gravityCapitalEN[@]})
input=(${gravityCapitalWN[@]} ${outOQgravityCapitalEN[@]})
 #input=(${gravityCapitalWN[@]} ${gravityCapitalEN[@]})
lookAhead=(${gravityLN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が均等な大文字で 右が左寄り文字の場合 均等な大文字 左に移動しない (なんちゃって最適化でいらない子判定)
 #backtrack=(${gravityCapitalEL[@]})
 #input=(${gravityCapitalEN[@]})
 #lookAhead=(${gravityLN[@]})
 #chain_context 0 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が中間の大文字で 右が狭い大文字の場合 中間の大文字 右に移動しない
backtrack=(${gravityCapitalMN[@]})
input=(${gravityCapitalMN[@]})
lookAhead=(${gravityCapitalCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が左寄り、中間の大文字で 右が幅広の文字の場合 右寄り、中間の文字 左に移動しない
backtrack=(${outLgravityCapitalLN[@]} ${gravityCapitalMN[@]})
 #backtrack=(${gravityCapitalLN[@]} ${gravityCapitalMN[@]})
input=(${gravityRN[@]} ${gravityMN[@]})
lookAhead=(${gravityWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が左寄り、中間の小文字で その左が左寄りの小文字、幅広、均等な文字で 右が幅広の小文字の場合 左寄り、均等な小文字 左に移動しない
backtrack1=(${gravityWL[@]} ${gravityEL[@]} \
${gravitySmallLN[@]} ${gravitySmallEN[@]})
backtrack=(${gravitySmallLN[@]} ${gravitySmallMN[@]})
input=(${gravitySmallLN[@]} ${gravitySmallEN[@]})
lookAhead=(${gravitySmallWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "" "${backtrack1[*]}"

# ○左が均等の小文字で 右が幅広の小文字の場合 右寄り、中間、Vの小文字 左に移動
backtrack=(${gravitySmallEN[@]})
input=(${gravitySmallRN[@]} ${gravitySmallMN[@]} ${gravitySmallVN[@]})
lookAhead=(${gravitySmallWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が均等な小文字で 右が左寄り、右寄り、均等な大文字の場合 狭い文字 左に移動
backtrack=(${gravitySmallEN[@]})
input=(${outjrtgravitySmallCN[@]} ${_JN[@]})
 #input=(${gravityCN[@]})
lookAhead=(${gravityCapitalLN[@]} ${gravityCapitalRN[@]} ${gravityCapitalEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が Ww で 右が左寄りの小文字の場合 均等な小文字 右に移動しない (丸い文字の処理と統合)
 #backtrack=(${_WL[@]} ${_wL[@]})
 #input=(${gravitySmallEN[@]})
 #lookAhead=(${gravitySmallLN[@]} ${gravitySmallEN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 左が左寄り、中間の文字で 右が右寄り、丸い文字の場合 左寄りの小文字 右に移動しない (右が丸い文字の処理と統合)
 #backtrack=(${gravityLN[@]} ${gravityMN[@]})
 #input=(${gravitySmallLN[@]})
 #lookAhead=(${gravityRN[@]} \
 #${circleCN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が、中間の文字で 右が左寄りの文字、右寄り、均等な大文字の場合 右寄り、eo 以外の中間の小文字 左に移動 (丸い文字の処理とセット)
backtrack=(${gravityMN[@]})
input=(${gravitySmallRN[@]} ${outeogravitySmallMN[@]})
lookAhead=(${gravityLN[@]} ${gravityCapitalRN[@]} ${gravityCapitalEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が幅広の文字で 右が左寄り、均等な大文字、k の場合 均等、中間の文字 右に移動しない
backtrack=(${gravityWL[@]})
input=(${gravityEN[@]} ${gravityMN[@]})
lookAhead=(${gravityCapitalLN[@]} ${gravityCapitalEN[@]} ${_kN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 左右を見て左に移動させる例外処理 ----------------------------------------

# ○左が均等、中間の小文字、EFKhkĸ で 右が均等な大文字の場合 幅広の文字 左に移動
backtrack=(${gravitySmallEL[@]} ${gravitySmallML[@]} ${_EL[@]} ${_FL[@]} ${_KL[@]} ${_hL[@]} ${_kL[@]} ${_kgL[@]})
input=(${gravityWN[@]})
lookAhead=(${gravityCapitalEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が FTfil で 右が狭い文字以外の場合 右寄り、中間、Vの小文字 左に移動
backtrack=(${_FR[@]} ${_TR[@]} ${_fR[@]} ${_iR[@]} ${_lR[@]} \
${_FN[@]})
 #backtrack=(${_FR[@]} ${_TR[@]} ${_fR[@]} ${_iR[@]} ${_lR[@]} \
 #${_FN[@]} ${_TN[@]})
input=(${gravitySmallRN[@]} ${gravitySmallMN[@]} ${gravitySmallVN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が h で 右が幅広の文字の場合 右寄りの文字 左に移動
backtrack=(${_hN[@]})
input=(${gravityRN[@]})
lookAhead=(${gravityWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 2つ右を見て移動させる例外処理 1 ----------------------------------------

# ○左が左寄り、中間の文字で 右が IJfrt で その右が狭い文字の場合 IJirt 右に移動 (この後の処理とセット)
backtrack1=("")
backtrack=(${outLgravityLR[@]} ${gravityMR[@]})
 #backtrack=(${gravityLR[@]} ${gravityMR[@]})
input=(${_IN[@]} ${_JN[@]} ${_iN[@]} ${_rN[@]} ${_tN[@]})
lookAhead=(${_IN[@]} ${_JN[@]} ${_fN[@]} ${_rN[@]} ${_tN[@]})
lookAhead1=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○左が左寄り、中間の文字で 右が IJfrt で その右が右寄り、中間、Vの字の場合 J 右に移動 (この後の処理とセット)
backtrack1=("")
backtrack=(${outLgravityLR[@]} ${gravityMR[@]})
 #backtrack=(${gravityLR[@]} ${gravityMR[@]})
input=(${_JN[@]})
lookAhead=(${_IN[@]} ${_JN[@]} ${_fN[@]} ${_rN[@]} ${_tN[@]})
lookAhead1=(${gravityRN[@]} ${gravityMN[@]} ${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○左が狭い文字で 右が狭い文字で その右が狭い文字の場合 左寄りの小文字 右に移動
backtrack1=("")
backtrack=(${outJgravityCR[@]})
 #backtrack=(${gravityCR[@]})
input=(${gravitySmallLN[@]})
lookAhead=(${gravityCN[@]})
lookAhead1=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 左右を見て右に移動させる例外処理 ----------------------------------------

# ○左が Jfj で 右が jl の場合 Ii 右に移動
backtrack=(${_JR[@]} ${_fR[@]} ${_jR[@]})
input=(${_IN[@]} ${_iN[@]})
lookAhead=(${_lN[@]})
 #lookAhead=(${_jN[@]} ${_lN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左が c 以外の右寄りの小文字、均等な大文字、右が丸い文字、G で 右が c 以外の右寄りの小文字、中間の大文字で その右が左寄り、右寄り、幅広、均等、中間の文字の場合 Ii 右に移動しない (この後の処理とセット)
backtrack1=("")
backtrack=(${outcgravitySmallRR[@]} ${gravityCapitalER[@]} ${_GR[@]} \
${circleRR[@]})
input=(${_IN[@]} ${_iN[@]})
lookAhead=(${outcgravitySmallRN[@]} ${gravityCapitalMN[@]})
lookAhead1=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○左が、右が丸い文字で 右が s の場合 Ifi 右に移動
backtrack=(${circleRR[@]})
input=(${_IN[@]} ${_fN[@]} ${_iN[@]})
lookAhead=(${_sN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左が c 以外の右寄りの小文字、均等な大文字、G で 右が右寄り、Vの小文字、中間の文字の場合 Ifi 右に移動
backtrack=(${outcgravitySmallRR[@]} ${gravityCapitalER[@]} ${_GR[@]})
input=(${_IN[@]} ${_fN[@]} ${_iN[@]})
lookAhead=(${gravitySmallRN[@]} ${gravityMN[@]} ${gravitySmallVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左が c 以外の右寄りの小文字、均等な大文字、G で 右が均等な小文字の場合 f 右に移動
backtrack=(${outcgravitySmallRR[@]} ${gravityCapitalER[@]} ${_GR[@]})
input=(${_fN[@]})
lookAhead=(${gravitySmallEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左が右寄り、均等、中間、Vの小文字、h で 右が右寄り、幅広、均等、中間、Vの小文字の場合 f 右に移動
backtrack=(${gravitySmallER[@]} ${gravitySmallMR[@]} ${gravitySmallVR[@]} ${_hR[@]})
 #backtrack=(${gravitySmallRR[@]} ${gravitySmallER[@]} ${gravitySmallMR[@]} ${gravitySmallVR[@]} ${_hR[@]})
input=(${_fN[@]})
lookAhead=(${gravitySmallRN[@]} ${gravitySmallEN[@]} ${gravityMN[@]} ${gravitySmallVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左が均等な大文字、右寄りの文字、BDER で 右が a で その右が左寄り、右寄り、幅広、均等、中間の文字の場合 狭い文字 右に移動しない (次の処理とセット)
backtrack1=("")
backtrack=(${gravityRR[@]} ${gravityCapitalER[@]} ${_BR[@]} ${_DR[@]} ${_ER[@]} ${_RR[@]})
input=(${outjgravityCN[@]})
 #input=(${gravityCN[@]})
lookAhead=(${_aN[@]})
lookAhead1=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○左が均等な大文字、右寄りの文字、BDER で 右が Vの大文字、acsxz の場合 狭い文字 右に移動
backtrack=(${gravityRR[@]} ${gravityCapitalER[@]} ${_BR[@]} ${_DR[@]} ${_ER[@]} ${_RR[@]})
input=(${outjgravityCN[@]})
 #input=(${gravityCN[@]})
lookAhead=(${gravityCapitalVN[@]} ${_aN[@]} ${_cN[@]} ${_sN[@]} ${_xN[@]} ${_zN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左が Cc 以外の右寄り、均等な大文字で 右が Vの大文字の場合 左寄り、均等な文字 右に移動
backtrack=(${outcgravitySmallRL[@]} ${gravityCapitalEL[@]} ${_GL[@]})
input=(${outLgravityLN[@]} ${gravityEN[@]})
 #input=(${gravityLN[@]} ${gravityEN[@]})
lookAhead=(${gravityCapitalVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左右を見て移動させない例外処理 ----------------------------------------

# ○左が幅広の文字で 右が丸くない中間の文字、Vの大文字の場合 狭い文字 左に移動しない
backtrack=(${gravityWL[@]})
input=(${outjgravityCN[@]})
 #input=(${gravityCN[@]})
lookAhead=(${outeogravityMN[@]} ${gravityCapitalVN[@]})
 #lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が FPÞ で 右が IJfrt の場合 IJi 右に移動しない
backtrack=(${_FR[@]} ${_PR[@]} ${_THR[@]})
input=(${_IN[@]} ${_JN[@]} ${_iN[@]})
lookAhead=(${_IN[@]} ${_JN[@]} ${_fN[@]} ${_rN[@]} ${_tN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が中間の文字、右が丸い文字で 右が IJfrt の場合 J 右に移動しない
backtrack=(${gravityMR[@]} \
${circleRR[@]})
input=(${_JN[@]})
lookAhead=(${_IN[@]} ${_JN[@]} ${_fN[@]} ${_rN[@]} ${_tN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が左寄り、中間の文字で 右が r の場合 irt 右に移動しない
backtrack=(${outLgravityLR[@]} ${gravityMR[@]})
 #backtrack=(${gravityLR[@]} ${gravityMR[@]})
input=(${_iN[@]} ${_rN[@]} ${_tN[@]})
lookAhead=(${_rN[@]})
chain_context 0 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が左寄り、中間の文字で 右が IJft の場合 rt 右に移動しない
backtrack=(${outLgravityLR[@]} ${gravityMR[@]})
 #backtrack=(${gravityLR[@]} ${gravityMR[@]})
input=(${_rN[@]} ${_tN[@]})
lookAhead=(${_IN[@]} ${_JN[@]} ${_fN[@]} ${_tN[@]})
chain_context 0 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が右寄りの文字で 右が右寄り、中間の文字の場合 filr 右に移動しない
backtrack=(${gravityRN[@]})
input=(${_fN[@]} ${_iN[@]} ${_lN[@]} ${_rN[@]})
lookAhead=(${gravityRN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が右寄り、中間の大文字、均等な文字で 右が左寄り、右寄り、均等、中間、Vの字の場合 IJf 左に移動しない (大文字と小文字で異なる処理と統合)
backtrack=(${gravityCapitalRR[@]} ${gravityCapitalER[@]} ${gravityCapitalMR[@]} \
${outOQgravityEN[@]})
 #backtrack=(${gravityCapitalRR[@]} ${gravityCapitalER[@]} ${gravityCapitalMR[@]} \
 #${gravityEN[@]})
input=(${outjgravityCN[@]})
 #input=(${gravityCN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が Ifrt で 右が狭い文字の場合 幅広の文字 左に移動しない
backtrack=(${_IL[@]} ${_fL[@]})
 #backtrack=(${_IL[@]} ${_fL[@]} ${_rL[@]} ${_tL[@]})
input=(${gravityWN[@]})
lookAhead=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 左が t で 右が狭い文字の場合 幅広と狭い文字以外 移動しない (統合した処理と統合)
 #backtrack=(${_tL[@]})
 #input=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
 #lookAhead=(${gravityCN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が、丸い文字で 右が左寄り、均等な大文字の場合 eo 以外の中間の文字 移動しない
backtrack=(${circleSmallCR[@]})
input=(${outeogravityMN[@]})
lookAhead=(${gravityCapitalLN[@]} ${gravityCapitalEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が Vの字で 右が狭い文字の場合 aSs 右に移動しない
backtrack=(${gravityVR[@]})
input=(${_aN[@]} ${_SN[@]} ${_sN[@]})
lookAhead=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が EKXkĸsxz で 右が左寄り、右寄り、均等、中間の文字の場合 SXZsxz 移動しない
backtrack=(${_ER[@]} ${_KR[@]} ${_XR[@]} ${_kR[@]} ${_sR[@]} ${_xR[@]} ${_zR[@]} ${_kgR[@]})
input=(${_SN[@]} ${_XN[@]} ${_ZN[@]} ${_sN[@]} ${_xN[@]} ${_zN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が中間の小文字、kĸ で 右が狭い文字の場合 中間の大文字、sxz 右に移動しない
backtrack=(${gravitySmallMN[@]} ${_kN[@]} ${_kgN[@]})
input=(${gravityCapitalMN[@]} ${_sN[@]} ${_xN[@]} ${_zN[@]})
lookAhead=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が狭い文字で 右が IJijlr の場合 左寄りの大文字 左に移動しない
backtrack=(${outJgravityCapitalCL[@]} ${outjrtgravitySmallCL[@]} ${_rL[@]})
 #backtrack=(${gravityCL[@]})
input=(${outLgravityCapitalLN[@]})
 #input=(${gravityCapitalLN[@]})
lookAhead=(${_IN[@]} ${_JN[@]} ${_iN[@]} ${_jN[@]} ${_lN[@]} ${_rN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が IJijlrt で 右が Jj の場合 左寄りの小文字 左に移動しない
backtrack=(${_IL[@]} ${_iL[@]} ${_lL[@]} ${_rL[@]})
 #backtrack=(${_IL[@]} ${_JL[@]} ${_iL[@]} ${_jL[@]} ${_lL[@]} ${_rL[@]} ${_tL[@]})
input=(${gravitySmallLN[@]})
lookAhead=(${_JN[@]} ${_jN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が f で 右が Jj の場合 bhkþ 左に移動しない
backtrack=(${_fL[@]})
input=(${_bN[@]} ${_hN[@]} ${_kN[@]} ${_thN[@]})
lookAhead=(${_JN[@]} ${_jN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 統合した通常処理 ----------------------------------------

# ○左が狭い文字で 右が右寄り、中間の文字の場合 右寄り、均等、中間、Vの字、狭い文字 左に移動 (次の2つの処理とセット、例外でrtを省く)
backtrack=(${outrtgravityCR[@]})
 #backtrack=(${gravityCR[@]})
input=(${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]} ${outjgravityCN[@]})
 #input=(${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]} ${gravityCN[@]})
lookAhead=(${gravityRN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が狭い文字で 右が左寄りの文字の場合 左寄り、中間、Vの字、狭い文字 左に移動 (例外でrtを省く)
backtrack=(${outrtgravityCR[@]})
 #backtrack=(${gravityCR[@]})
input=(${outLgravityLN[@]} ${gravityMN[@]} ${gravityVN[@]} ${outjgravityCN[@]})
 #input=(${outLgravityLN[@]} ${gravityMN[@]} ${gravityVN[@]} ${gravityCN[@]})
 #input=(${gravityLN[@]} ${gravityMN[@]} ${gravityVN[@]})
lookAhead=(${gravityLN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が狭い文字で 右が均等、Vの字の場合 Vの字、狭い文字 左に移動 (例外でrtを省く)
backtrack=(${outrtgravityCR[@]})
 #backtrack=(${gravityCR[@]})
input=(${gravityVN[@]} ${outjgravityCN[@]})
 #input=(${gravityVN[@]} ${gravityCN[@]})
lookAhead=(${gravityEN[@]} ${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が引き離す文字で 右が幅広の文字の場合 引き寄せない文字 移動しない (例外で h を追加)
backtrack=(${gravityWL[@]} \
${outLgravityLR[@]} ${gravityRR[@]} ${gravityER[@]} ${gravityMR[@]} ${gravityVR[@]} \
${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${_hN[@]})
 #backtrack=(${gravityWL[@]} \
 #${gravityLR[@]} ${gravityRR[@]} ${gravityER[@]} ${gravityMR[@]} ${gravityVR[@]} \
 #${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]})
input=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]})
lookAhead=(${gravityWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 両側が均等な文字の場合 右寄り、均等な文字 移動しない (なんちゃって最適化でいらない子判定)
 #backtrack=(${gravityEL[@]})
 #input=(${gravityRN[@]} ${gravityEN[@]})
 #lookAhead=(${gravityEN[@]})
 #chain_context 0 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○両側が中間の文字の場合 右寄り、均等な文字 移動しない
backtrack=(${gravityML[@]})
input=(${gravityRN[@]} ${gravityEN[@]})
lookAhead=(${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○両側が Vの字の場合 右寄り、均等な文字 移動しない
backtrack=(${gravityVL[@]})
input=(${gravityRN[@]} ${gravityEN[@]})
lookAhead=(${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が均等な小文字で 右が狭い文字の場合 狭い文字 右に移動しない (例外で h を追加、次とその次の処理とセット)
backtrack=(${gravitySmallEL[@]} ${_hL[@]})
input=(${gravityCN[@]})
lookAhead=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が均等な小文字で 右が frt の場合 幅広、狭い文字以外 右に移動しない (例外で h を追加、この後の処理とセット)
backtrack=(${gravitySmallEL[@]} ${_hL[@]})
input=(${outLgravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
 #input=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
lookAhead=(${_fN[@]} ${_rN[@]} ${_tN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が、左が丸い小文字で 右が t の場合 左寄り、右寄り、均等、中間の文字 右に移動しない (この後の処理とセット)
backtrack=(${circleSmallRL[@]} ${circleSmallCL[@]})
input=(${outLgravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
 #input=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
lookAhead=(${_tN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が右寄り、幅広、均等な文字で 右が狭い文字の場合 左寄り、右寄り、均等、中間、狭い文字 右に移動 (例外で h を追加、j を省く)
backtrack=(${gravityRL[@]} ${gravityWL[@]} ${gravityEL[@]} ${_hL[@]})
input=(${outLgravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${outjgravityCN[@]})
 #input=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${outjgravityCN[@]})
lookAhead=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左が左寄り、中間の文字で 右が ijl の場合 左寄りの文字、均等な大文字 右に移動 (次の処理とセット)
backtrack=(${outLhgravityLL[@]} ${gravityML[@]})
 #backtrack=(${gravityLL[@]} ${gravityML[@]})
input=(${outLgravityLN[@]} ${gravityCapitalEN[@]})
 #input=(${gravityLN[@]} ${gravityCapitalEN[@]})
lookAhead=(${_iN[@]} ${_jN[@]} ${_lN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左が左寄り、中間、Vの字、狭い文字、t で 右が狭い文字の場合 幅広と狭い文字以外 移動しない (左右を見て動かさない処理と統合)
backtrack=(${outLgravityLL[@]} ${gravityML[@]} ${gravityVL[@]} ${_tL[@]} \
${outrtgravityCR[@]})
 #backtrack=(${gravityLL[@]} ${gravityML[@]} ${gravityVL[@]} ${_tL[@]} \
 #${gravityCR[@]})
input=(${outLgravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
 #input=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
lookAhead=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 2つ右を見て移動させない例外処理 ----------------------------------------

# ○左が狭い文字で 右が狭い文字で その右が狭い文字の場合 左寄りの文字 左に移動しない
backtrack1=("")
backtrack=(${outJgravityCapitalCL[@]} ${outjrtgravitySmallCL[@]} ${_rL[@]})
 #backtrack=(${gravityCL[@]})
input=(${outLgravityLN[@]})
 #input=(${gravityLN[@]})
lookAhead=(${gravityCN[@]})
lookAhead1=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○左が IJijl で 右が IJijl で その右が 右寄りの小文字、中間、Vの字、狭い文字の場合 右寄り、均等な文字 移動しない
backtrack1=("")
backtrack=(${_IN[@]} ${_iN[@]} ${_lN[@]})
 #backtrack=(${_IN[@]} ${_JN[@]} ${_iN[@]} ${_jN[@]} ${_lN[@]})
input=(${gravityRN[@]} ${gravityEN[@]})
lookAhead=(${_IN[@]} ${_JN[@]} ${_iN[@]} ${_jN[@]} ${_lN[@]})
lookAhead1=(${gravitySmallRN[@]} ${gravityMN[@]} ${gravityVN[@]} ${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "" "${backtrack1[*]}" "${lookAhead1[*]}"

# 2つ左を見て移動させない例外処理 1 ----------------------------------------

# ○左が狭い文字で 右が狭い文字の場合 左寄りの文字 左に移動しない (次の処理とセット)
backtrack=(${outJgravityCapitalCL[@]} ${outjrtgravitySmallCL[@]} ${_rL[@]})
 #backtrack=(${gravityCL[@]})
input=(${outLgravityLN[@]})
 #input=(${gravityLN[@]})
lookAhead=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が狭い文字で 右が全ての文字の場合 左寄り、右寄り、幅広、均等、中間の文字 左に移動 (この後の処理とセット)
backtrack=(${outJjgravityCL[@]})
 #backtrack=(${gravityCL[@]})
input=(${outLgravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]})
 #input=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]})
lookAhead=(${capitalN[@]} ${smallN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が狭い文字で 右が左寄り、右寄り、幅広、均等、中間の文字の場合 左寄り、右寄り、均等、中間の文字 左に移動 (この後の処理とセット)
backtrack=(${outJgravityCapitalCN[@]} ${outjrtgravitySmallCN[@]} ${_rN[@]})
 #backtrack=(${gravityCN[@]})
input=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が狭い文字で 右が Vの字の場合 右寄り、均等、中間の文字 左に移動 (この後の処理とセット)
backtrack=(${outJgravityCapitalCN[@]} ${outjrtgravitySmallCN[@]} ${_rN[@]})
 #backtrack=(${gravityCN[@]})
input=(${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
lookAhead=(${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が狭い文字で 右が狭い文字の場合 右寄り、中間の文字、均等な小文字 左に移動 (この後の処理とセット)
backtrack=(${outJgravityCapitalCN[@]} ${outjrtgravitySmallCN[@]} ${_rN[@]})
 #backtrack=(${gravityCN[@]})
input=(${gravityRN[@]} ${gravitySmallEN[@]} ${gravityMN[@]})
lookAhead=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が Iilt で その左が狭い文字の場合 左寄り、右寄り、均等、中間の文字 移動しない
backtrack1=(${_JL[@]} ${_jL[@]} ${_tL[@]} \
${_IR[@]} ${_fR[@]} ${_iR[@]} ${_lR[@]} \
${gravityCN[@]})
backtrack=(${_IL[@]} ${_iL[@]} ${_tL[@]} \
${_IN[@]} ${_iN[@]} ${_lN[@]})
 #backtrack=(${_IL[@]} ${_iL[@]} ${_tL[@]} \
 #${_IN[@]} ${_iN[@]} ${_lN[@]} ${_tN[@]})
input=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "" "${backtrack1[*]}"

# ○左が狭い文字で その左が狭い文字の場合 幅広の文字 移動しない
backtrack1=(${_JL[@]} ${_jL[@]} ${_tL[@]} \
${gravityCR[@]} \
${gravityCN[@]})
backtrack=(${outJjrtgravityCL[@]} \
${outJjrtgravityCN[@]})
 #backtrack=(${gravityCL[@]} \
 #${gravityCN[@]})
input=(${gravityWN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "" "${backtrack1[*]}"

# ○左が Vの字、狭い文字で その左が L の場合 左寄り、均等な文字 左に移動しない
backtrack1=(${_LR[@]})
backtrack=(${gravityVL[@]} ${outJgravityCapitalCL[@]} ${outjrtgravitySmallCL[@]} ${_rL[@]})
 #backtrack=(${gravityVL[@]} ${gravityCL[@]})
input=(${outLgravityLN[@]} ${gravityEN[@]})
 #input=(${gravityLN[@]} ${gravityEN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "" "${backtrack1[*]}"

# ○左が Vの字で その左が L の場合 右寄り、中間、Vの字 左に移動しない
backtrack1=(${_LR[@]})
backtrack=(${gravityVL[@]})
input=(${gravityRN[@]} ${gravityMN[@]} ${gravityVN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "" "${backtrack1[*]}"

# ---

# 左が中間の文字で その左が Ww の場合 r 左に移動しない
 #backtrack1=(${_WL[@]} ${_wL[@]})
 #backtrack=(${gravityMR[@]})
 #input=(${_rN[@]})
 #lookAhead=("")
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "" "${backtrack1[*]}"

# ○左が幅広の小文字で その左が幅広の文字の場合 ijlr 右に移動しない
backtrack1=(${gravityWR[@]} \
${gravityWN[@]})
backtrack=(${gravitySmallWR[@]})
input=(${_iN[@]} ${_jN[@]} ${_lN[@]} ${_rN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "" "${backtrack1[*]}"

# ---

# ○左が t で 右が左寄り、均等な大文字、幅広の文字、bhkþ の場合 frt 左に移動 (次の処理とセット)
backtrack=(${_tN[@]})
input=(${_fN[@]} ${_rN[@]} ${_tN[@]})
lookAhead=(${gravityCaptalLN[@]} ${gravityWN[@]} ${gravityCapitalEN[@]} ${_bN[@]} ${_hN[@]} ${_kN[@]} ${_thN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が t で 右が左寄り、均等な大文字、幅広の文字、pĸ の場合 frt 左に移動 (次の処理とセット)
backtrack=(${_tN[@]})
input=(${_rN[@]} ${_tN[@]})
lookAhead=(${_pN[@]} ${_kgN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が t で その左が左寄り、右寄り、均等、中間、Vの字の場合 frt 左に移動しない
backtrack1=(${gravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} ${gravityML[@]} ${gravityVL[@]})
backtrack=(${_tR[@]} \
${_tN[@]})
input=(${_fN[@]} ${_rN[@]} ${_tN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "" "${backtrack1[*]}"

# ---

# ○左が左寄り、中間の小文字で 右が狭い文字の場合 acsxz 右に移動 (次の処理とセット)
backtrack=(${gravitySmallLR[@]} ${gravitySmallMR[@]})
input=(${_aN[@]} ${_cN[@]} ${_sN[@]} ${_xN[@]} ${_zN[@]})
lookAhead=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左が左寄り、中間の小文字、Vの字で その左が幅広の文字の場合 acsxz 右に移動しない
backtrack1=(${gravityWR[@]} \
${gravityWN[@]})
backtrack=(${gravitySmallLR[@]} ${gravitySmallMR[@]} ${gravityVR[@]})
input=(${_aN[@]} ${_cN[@]} ${_sN[@]} ${_xN[@]} ${_zN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "" "${backtrack1[*]}"

# 大文字と小文字に関する例外処理 2 ----------------------------------------

# ○左が、右上が開いている文字で 右が、左上が開いている文字の場合 T 右に移動しない
backtrack=(${highSpaceRR[@]} ${highSpaceCR[@]} \
${highSpaceRN[@]} ${highSpaceCN[@]})
input=(${_TN[@]})
lookAhead=(${highSpaceLN[@]} ${highSpaceCN[@]})
chain_context 0 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が、右が丸い文字、PRÞ の場合 右寄り、均等な小文字、丸い文字 右に移動 (丸い文字の処理と統合)
backtrack=(${circleRR[@]} ${_PR[@]} ${_RR[@]} ${_THR[@]})
input=(${gravitySmallRN[@]} ${gravitySmallEN[@]} \
${circleCN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# fr に関する例外処理 ----------------------------------------

# ○左が右寄り、幅広、均等な文字、右が丸い大文字で 右が左寄り、幅広、均等な文字、右寄りの大文字の場合 fr 左に移動 (この後の処理とセット)
backtrack=(${gravityRL[@]} ${gravityWL[@]} ${gravityEL[@]} \
${circleCapitalRL[@]})
input=(${_fN[@]} ${_rN[@]})
lookAhead=(${gravityLN[@]} ${gravityCapitalRN[@]} ${gravityWN[@]} ${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が右寄り、幅広の文字、均等な大文字の場合 fr 左に移動しない
backtrack=(${gravityRL[@]} ${gravityWL[@]} ${gravityCapitalEL[@]})
input=(${_fN[@]} ${_rN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が均等な小文字、右が丸い大文字の場合 f 左に移動しない
backtrack=(${gravitySmallEL[@]} \
${circleCapitalRL[@]})
input=(${_fN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 移動しない ========================================

# 左右を見て移動させない通常処理 ----------------------------------------

# ○左右を見て 左寄り、均等な文字 移動しない
backtrack=(${gravityRL[@]} ${gravityEL[@]} \
${gravityVN[@]})
input=(${outLgravityLN[@]} ${gravityEN[@]})
 #input=(${gravityLN[@]} ${gravityEN[@]})
lookAhead=(${gravityRN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左右を見て 左寄りの文字 移動しない
backtrack=(${gravityRL[@]} ${gravityEL[@]} \
${gravityVN[@]})
input=(${outLgravityLN[@]})
 #input=(${gravityLN[@]})
lookAhead=(${gravityLN[@]} ${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ---

# ○左右を見て 右寄り、中間の文字 移動しない (例外で丸くない中間の小文字を省く)
backtrack=(${outLgravityLN[@]} ${gravityMN[@]})
 #backtrack=(${gravityLN[@]} ${gravityMN[@]})
input=(${gravityRN[@]} ${gravityMN[@]})
lookAhead=(${outcgravityRN[@]} ${gravityCapitalMN[@]} \
${circleSmallCN[@]})
 #lookAhead=(${gravityRN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左右を見て 中間の文字 移動しない
backtrack=(${outLgravityLN[@]} ${gravityMN[@]})
 #backtrack=(${gravityLN[@]} ${gravityMN[@]})
input=(${gravityMN[@]})
lookAhead=(${gravityLN[@]} ${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 左側基準で左に移動 ========================================

# 左が丸い文字に関する例外処理 2 ----------------------------------------

# 左が、右が丸い小文字で 右が Ww の場合 左が丸い小文字 移動しない
 #backtrack=(${circleSmallRN[@]} ${circleSmallCN[@]})
 #input=(${circleSmallLN[@]})
 #lookAhead=(${_WN[@]} ${_wN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が、右が丸い文字で 右が幅広の文字の場合 左が丸い文字 左に移動 (この後の処理とセット)
backtrack=(${circleRL[@]} ${circleCL[@]} \
${circleRN[@]} ${circleSmallCN[@]})
 #backtrack=(${circleRL[@]} ${circleCL[@]} \
 #${circleRN[@]} ${circleCN[@]})
input=(${circleLN[@]} ${circleCN[@]})
lookAhead=(${gravityWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が、右が丸い文字で 右が左寄り、右寄り、均等、中間、Vの字の場合 左が丸い文字 左に移動しない (この後の処理とセット 右が丸い文字の処理と統合)
 #backtrack=(${circleRL[@]} ${circleCL[@]})
 #input=(${circleLN[@]} ${circleCN[@]})
 #lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が、右が丸い文字で その左が狭い文字、L の場合 左が丸い文字 右に移動 (この後の処理とセット)
backtrack1=(${gravityCL[@]} ${_LL[@]} \
${outJjrtgravityCR[@]} ${_rR[@]} ${_LR[@]} \
${gravityCN[@]} ${_LN[@]})
backtrack=(${circleRL[@]} ${circleCL[@]})
input=(${circleLN[@]} ${circleCN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}"

# ○左が、右が丸い文字の場合 左が丸い文字 左に移動しない (次の処理より前に置くこと)
backtrack=(${circleRL[@]} ${circleCL[@]})
input=(${circleLN[@]} ${circleCN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 2つ左を見て移動させない例外処理 2 ----------------------------------------

# ○左が左寄り、中間の文字で 右が狭い文字以外の場合 右寄り、中間、Vの字 左に移動 (前の処理より後に置くこと、次の処理とセット)
backtrack=(${outLgravityLL[@]} ${gravityML[@]})
 #backtrack=(${gravityLL[@]} ${gravityML[@]})
input=(${gravityRN[@]} ${gravityMN[@]} ${gravityVN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が左寄り、中間の文字で その左が狭い文字、L の場合 右寄り、中間、Vの字 移動しない
backtrack1=(${gravityCL[@]} ${_LL[@]} \
${gravityCR[@]} ${_LR[@]} \
${gravityCN[@]} ${_LN[@]})
backtrack=(${outLgravityLL[@]} ${gravityML[@]})
 #backtrack=(${gravityLL[@]} ${gravityML[@]})
input=(${gravityRN[@]} ${gravityMN[@]} ${gravityVN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "" "${backtrack1[*]}"

# 左右を見て左に移動させる通常処理 ----------------------------------------

# ○左側基準で 左寄り、均等な文字 左に移動
backtrack=(${outLgravityLL[@]} ${gravityML[@]})
 #backtrack=(${gravityLL[@]} ${gravityML[@]})
input=(${outLgravityLN[@]} ${gravityEN[@]})
 #input=(${gravityLN[@]} ${gravityEN[@]})
lookAhead=(${gravityWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左側基準で 右寄り、中間、Vの字 左に移動
backtrack=(${gravityRL[@]} ${gravityEL[@]})
input=(${gravityRN[@]} ${gravityMN[@]} ${gravityVN[@]})
lookAhead=(${gravityWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左側基準で 幅広の文字 左に移動
backtrack=(${gravityEL[@]})
input=(${gravityWN[@]})
lookAhead=(${gravityWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左側基準で 幅広の文字 左に移動
backtrack=(${outLgravityLL[@]} ${gravityML[@]} ${gravityVL[@]})
 #backtrack=(${gravityLL[@]} ${gravityML[@]} ${gravityVL[@]})
input=(${gravityWN[@]})
lookAhead=(${gravityLN[@]} ${gravityWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左側基準で Vの字 左に移動 (左が丸い文字の処理と統合)
backtrack=(${gravityRL[@]} ${gravityEL[@]})
input=(${gravityVN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} \
${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左側基準で 右寄り、中間の文字 左に移動
backtrack=(${gravityVN[@]})
input=(${gravityRN[@]} ${gravityMN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左側基準で 右寄りの文字 左に移動
backtrack=(${gravityVN[@]})
input=(${gravityRN[@]})
lookAhead=(${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左側基準で 狭い文字 左に移動
backtrack=(${gravityWL[@]})
input=(${outjgravityCN[@]})
 #input=(${gravityCN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravitySmallVN[@]} \
${circleCN[@]})
 #lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
chain_context 0 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ASsxz に関する例外処理 ----------------------------------------

# ○左が右寄り、均等な文字で 右が狭い文字の場合 ASsxz 右に移動
backtrack=(${gravityRN[@]} ${gravityEN[@]} ${_hN[@]})
input=(${_AN[@]} ${_SN[@]} ${_sN[@]} ${_xN[@]} ${_zN[@]})
lookAhead=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左が右寄り、均等な文字で 右が Vの字の場合 A 右に移動
backtrack=(${gravityRN[@]} ${gravityEN[@]} ${_hN[@]} )
input=(${_AN[@]})
lookAhead=(${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左が幅広、右寄り、均等な文字の場合 ASs 右に移動しない
backtrack=(${gravityWL[@]} ${gravityEL[@]} ${_hL[@]} \
${gravityRN[@]} ${gravityEN[@]})
input=(${_AN[@]} ${_SN[@]} ${_sN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が幅広、右寄り、均等な文字で 右が右寄り、中間、Vの字の場合 xz 右に移動しない
backtrack=(${gravityWL[@]} ${gravityEL[@]} \
${gravityRN[@]} ${gravityEN[@]})
input=(${_xN[@]} ${_zN[@]})
lookAhead=(${gravityRN[@]} ${gravityMN[@]} ${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 左右を見て左に移動させない通常処理 ----------------------------------------

# ○左側基準で 左寄り、均等な文字 左に移動しない
backtrack=(${outjrtgravitySmallCN[@]})
 #backtrack=(${gravityVL[@]} \
 #${gravityCN[@]})
input=(${outLgravityLN[@]} ${gravityCapitalEN[@]})
 #input=(${gravityLN[@]} ${gravityEN[@]})
lookAhead=(${outjgravityCN[@]})
 #lookAhead=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左側基準で 左寄りの文字 左に移動しない (左右を見て移動させない通常処理と統合)
backtrack=(${outLgravityLL[@]} ${gravityML[@]} ${gravityVL[@]} \
${gravityVN[@]} ${outjrtgravitySmallCN[@]})
 #backtrack=(${gravityLL[@]} ${gravityML[@]} ${gravityVL[@]} \
 #${gravityVN[@]} ${gravityCN[@]})
input=(${outLgravityLN[@]})
 #input=(${gravityLN[@]})
lookAhead=(${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左側基準で 右寄り、中間の文字 左に移動しない
backtrack=(${gravityVN[@]})
 #backtrack=(${gravityLL[@]} ${gravityML[@]} \
 #${gravityVN[@]})
input=(${gravityRN[@]} ${gravityMN[@]})
lookAhead=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左側基準で 中間の文字 左に移動しない (左右を見て移動させない通常処理と統合)
backtrack=(${outLgravityLN[@]} ${gravityMN[@]} ${gravityVN[@]})
 #backtrack=(${gravityLL[@]} ${gravityML[@]} \
 #${gravityLN[@]} ${gravityMN[@]} ${gravityVN[@]})
input=(${gravityMN[@]})
lookAhead=(${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左側基準で 幅広、狭い文字 左に移動しない (例外で j を省く)
backtrack=(${gravityCN[@]})
input=(${gravityWN[@]} ${outjgravityCN[@]})
lookAhead=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左側基準で 狭い文字 左に移動しない (例外で j を省く)
backtrack=(${gravityCR[@]} \
${outBDgravityLN[@]} ${gravityMN[@]} ${gravityVN[@]})
 #backtrack=(${gravityCR[@]} \
 #${gravityLN[@]} ${gravityMN[@]} ${gravityVN[@]})
input=(${outjgravityCN[@]})
lookAhead=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 左側基準で Vの字 左に移動しない (なんちゃって最適化でいらない子判定)
 #backtrack=(${gravityVL[@]})
 #input=(${gravityVN[@]})
 #lookAhead=(${gravityCN[@]})
 #chain_context 0 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 左を見て左に移動させる通常処理 ----------------------------------------

# ○左側基準で 全ての文字 左に移動 (例外で L を追加)
backtrack=(${gravityCL[@]} ${_LL[@]} \
${gravityCN[@]} ${_LN[@]})
input=(${capitalN[@]} ${smallN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左側基準で 幅広の文字以外 左に移動
backtrack=(${gravityVL[@]})
input=(${outLgravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]} ${gravityCN[@]})
 #input=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]} ${gravityCN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左側基準で 右寄り、中間、Vの字、狭い文字 左に移動
backtrack=(${outLgravityLL[@]} ${gravityML[@]})
 #backtrack=(${gravityLL[@]} ${gravityML[@]})
input=(${gravityRN[@]} ${gravityMN[@]} ${gravityVN[@]} ${gravityCN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左側基準で 狭い文字 左に移動 (例外で Ij を省く)
backtrack=(${outBDLgravityLN[@]} ${gravityMN[@]} ${gravityVN[@]})
 #backtrack=(${gravityLN[@]} ${gravityMN[@]} ${gravityVN[@]})
input=(${outjgravitySmallCN[@]} ${_JN[@]})
 #input=(${gravityCN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左側基準で 狭い文字 左に移動 (例外で il を追加)
backtrack=(${gravityRL[@]} ${gravityEL[@]} \
${_iR[@]} ${_lR[@]})
input=(${outjgravityCN[@]})
 #input=(${gravityCN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左を見て左に移動させる例外処理 ----------------------------------------

# ○左が If の場合 Jirt 左に移動
backtrack=(${_IR[@]} ${_fR[@]})
input=(${_JN[@]} ${_iN[@]} ${_rN[@]} ${_tN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が Irt の場合 IJil 左に移動
backtrack=(${_IR[@]} ${_rR[@]} ${_tR[@]})
input=(${_IN[@]} ${_JN[@]} ${_iN[@]} ${_lN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左側基準で右に移動 ========================================

# 数字と記号に関する処理 2 ----------------------------------------

# ○右が幅のある記号、数字の場合 左寄り、右寄り、幅広、均等、中間の文字 移動しない
backtrack=("")
input=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]})
lookAhead=(${symbolEN[@]} ${figureEN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 左が丸い文字に関する例外処理 3 ----------------------------------------

# ○左が、左右が丸い文字の場合 左が丸い文字 右に移動
backtrack=(${circleLR[@]} ${circleRR[@]} ${circleCR[@]})
input=(${circleLN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左右を見て右に移動させない通常処理 ----------------------------------------

# ○左側基準で 左寄り、均等な文字 右に移動しない
backtrack=(${gravityVR[@]} \
${outLgravityLN[@]} ${gravityMN[@]})
 #backtrack=(${gravityVR[@]} \
 #${gravityLN[@]} ${gravityMN[@]})
input=(${outLgravityLN[@]} ${gravityEN[@]})
 #input=(${gravityLN[@]} ${gravityEN[@]})
lookAhead=(${gravityLN[@]} ${gravityWN[@]} ${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左側基準で 均等な文字 右に移動しない
backtrack=(${gravityVR[@]} \
${outLgravityLN[@]} ${gravityMN[@]})
 #backtrack=(${gravityVR[@]} \
 #${gravityLN[@]} ${gravityMN[@]})
input=(${gravityEN[@]})
lookAhead=(${gravityRN[@]} ${gravityMN[@]} ${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左側基準で 幅広の文字 右に移動しない (例外で h を追加)
backtrack=(${gravityWL[@]} \
${gravityRN[@]} ${gravityEN[@]} ${_hN[@]})
input=(${gravityWN[@]})
lookAhead=(${gravityLN[@]} ${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左側基準で 右寄りの文字 右に移動しない (例外で h を追加)
backtrack=(${gravityWL[@]} \
${outBDLbpthgravityLR[@]} ${gravityRR[@]} ${gravityER[@]} ${gravityMR[@]} ${gravityVR[@]} \
${gravityRN[@]} ${gravityEN[@]} ${_hN[@]})
 #backtrack=(${gravityWL[@]} \
 #${gravityLR[@]} ${gravityRR[@]} ${gravityER[@]} ${gravityMR[@]} ${gravityVR[@]} \
 #${gravityRN[@]} ${gravityEN[@]})
input=(${gravityRN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左側基準で 幅広の文字 右に移動しない
backtrack=(${outLgravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} ${gravityML[@]} \
${outLgravityLN[@]} ${gravityMN[@]} ${gravityVN[@]})
 #backtrack=(${gravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} ${gravityML[@]} \
 #${gravityLN[@]} ${gravityMN[@]} ${gravityVN[@]})
input=(${gravityWN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左側基準で 均等、中間の文字 右に移動しない (例外で h を追加)
backtrack=(${outLgravityLR[@]} \
${gravityRN[@]} ${gravityEN[@]})
 #backtrack=(${gravityLR[@]} \
 #${gravityRN[@]} ${gravityEN[@]})
input=(${gravityEN[@]} ${gravityMN[@]} ${_hN[@]})
lookAhead=(${gravityLN[@]} ${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左側基準で 中間、Vの字 右に移動しない
backtrack=(${gravityVR[@]})
input=(${gravityMN[@]} ${gravityVN[@]})
lookAhead=(${gravityLN[@]} ${gravityEN[@]} ${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左側基準で 中間の文字 右に移動しない
backtrack=(${gravityVR[@]})
input=(${gravityMN[@]})
lookAhead=(${gravityRN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左側基準で Vの字 右に移動しない
backtrack=(${gravityVR[@]})
input=(${gravityVN[@]})
lookAhead=(${gravityWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左側基準で Vの字 右に移動しない
backtrack=(${gravityRR[@]} ${gravityER[@]})
input=(${gravityVN[@]})
lookAhead=(${gravityWN[@]} ${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左側基準で 狭い文字 右に移動しない
backtrack=(${gravityWR[@]})
input=(${outjgravityCN[@]})
 #input=(${gravityCN[@]})
lookAhead=(${gravityWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 左側基準で 均等な文字 右に移動しない (次の処理と統合)
 #backtrack=(${gravityEN[@]})
 #input=(${gravityEN[@]})
 #lookAhead=(${gravityRN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 丸い文字に関する例外処理 2 ----------------------------------------

# ○左が均等な文字で 右が右寄り、丸い文字の場合 幅広、均等な文字 右に移動しない (前の処理と統合)
backtrack=(${gravityEN[@]})
input=(${gravityWN[@]} ${gravityEN[@]})
lookAhead=(${gravityRN[@]} \
${circleSmallCN[@]})
 #lookAhead=(${gravityRN[@]} \
 #${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 左を見て右に移動させる通常処理 ----------------------------------------

# ○左側基準で 全ての文字 右に移動
backtrack=(${gravityWR[@]})
input=(${capitalN[@]} ${smallN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左側基準で 狭い文字以外 右に移動
backtrack=(${gravityRR[@]} ${gravityER[@]} ${gravityVR[@]} \
${gravityWN[@]})
input=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左側基準で 左寄り、右寄り、幅広、均等、中間の文字 右に移動
backtrack=(${outLgravityLR[@]} ${gravityMR[@]})
 #backtrack=(#${gravityLR[@]} ${gravityMR[@]})
input=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左側基準で 左寄り、右寄り、幅広、均等、中間の文字 右に移動 (例外で h を追加、ASs を省く)
backtrack=(${gravityWL[@]} \
${gravityRN[@]} ${gravityEN[@]} ${_hN[@]})
input=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${_XN[@]} ${_ZN[@]} ${_eN[@]} ${_oN[@]} ${_xN[@]} ${_zN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左側基準で 左寄り、幅広、均等な文字 右に移動
backtrack=(${outLhgravityLN[@]} ${gravityMN[@]})
 #backtrack=(${gravityLN[@]} ${gravityMN[@]})
input=(${gravityLN[@]} ${gravityWN[@]} ${gravityEN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左側基準で 幅広の文字 右に移動
backtrack=(${outLgravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} ${gravityML[@]} \
${gravityVN[@]})
 #backtrack=(${gravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} ${gravityML[@]} \
 #${gravityVN[@]})
input=(${gravityWN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# もろもろ例外 ========================================

# 2つ左を見て移動させる例外処理 1 ----------------------------------------

# ○左が BDLbpþ 以外の左寄り、eo 以外の中間、Vの字で 右が狭い文字の場合 狭い文字 移動しない
backtrack=(${outBDLbpthgravityLR[@]} ${outeogravityMR[@]} ${gravityVR[@]})
 #backtrack=(${gravityLR[@]} ${gravityRR[@]} ${gravityER[@]} ${gravityMR[@]} ${gravityVR[@]})
input=(${outjgravityCN[@]})
 #input=(${gravityCN[@]})
lookAhead=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○右が狭い文字の場合 狭い文字 右に移動
backtrack=("")
input=(${gravityCN[@]})
lookAhead=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左が左寄り、中間の文字で 右が右寄りの小文字、中間、Vの字の場合 fir 移動しない
backtrack=(${outLgravityLR[@]} ${gravitySmallMR[@]})
 #backtrack=(${gravityLR[@]} ${gravityMR[@]})
input=(${_fN[@]} ${_iN[@]} ${_rN[@]})
lookAhead=(${gravitySmallRN[@]} ${gravityMN[@]} ${gravityVN[@]})
chain_context 0 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が左寄り、中間、Vの字で その左が幅広の文字の場合 Jfijlrt 左に移動
backtrack1=(${gravityWL[@]} \
${gravityWR[@]} \
${gravityWN[@]})
backtrack=(${outLgravityLR[@]} ${gravityMR[@]} ${gravityVR[@]})
 #backtrack=(${gravityLR[@]} ${gravityMR[@]} ${gravityVR[@]})
input=(${_JN[@]} ${_fN[@]} ${_iN[@]} ${_lN[@]} ${_rN[@]} ${_tN[@]})
 #input=(${_JN[@]} ${_fN[@]} ${_iN[@]} ${_jN[@]} ${_lN[@]} ${_rN[@]} ${_tN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}"

# ○左が右寄り、均等な文字で その左が幅広の文字の場合 r 左に移動
backtrack1=(${gravityWL[@]} \
${gravityWR[@]} \
${gravityWN[@]})
backtrack=(${gravityRR[@]} ${gravityER[@]})
input=(${_rN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}"

# A に関する例外処理 3 ----------------------------------------

# 右が W の場合 A 右に移動しない
 #backtrack=("")
 #input=(${_AN[@]})
 #lookAhead=(${_WN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○右が、左下が開いている大文字の場合 A 右に移動
backtrack=("")
input=(${_AN[@]})
lookAhead=(${lowSpaceCapitalCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○右が A の場合 右下が開いている大文字か W 右に移動
backtrack=("")
input=(${lowSpaceCapitalRN[@]} ${lowSpaceCapitalCN[@]})
 #input=(${lowSpaceCapitalRN[@]} ${lowSpaceCapitalCN[@]} ${_WN[@]})
lookAhead=(${_AN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# EF に関する例外処理 ----------------------------------------

# ○左が EF で 右が左寄り、均等な文字の場合 左寄りの文字 左に移動
backtrack=(${_EL[@]} ${_FL[@]})
input=(${outLgravityLN[@]})
 #input=(${gravityLN[@]})
lookAhead=(${gravityLN[@]} ${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# L に関する例外処理 2 ----------------------------------------

# ○右が左寄り、幅広の文字、HNn の場合 L 右に移動しない
backtrack=("")
input=(${_LN[@]})
lookAhead=(${gravityLN[@]} ${gravityWN[@]} ${_HN[@]} ${_NN[@]} ${_nN[@]})
chain_context 0 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○右が L の場合 左寄り、中間の文字 左に移動しない
backtrack=("")
input=(${outLgravityLN[@]} ${gravityMN[@]})
 #input=(${gravityLN[@]} ${gravityMN[@]})
lookAhead=(${_LN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 大文字と小文字に関する例外処理 3 ----------------------------------------

# ○左が、右上が開いている文字、irt で 右が、左上が開いている文字、filrt の場合 両下が開いている大文字 移動しない
backtrack=(${highSpaceCL[@]} \
${highSpaceRN[@]} ${highSpaceCN[@]})
 #backtrack=(${highSpaceRL[@]} ${highSpaceCL[@]} \
 #${highSpaceRN[@]} ${highSpaceCN[@]} ${_iN[@]} ${_rN[@]} ${_tN[@]})
input=(${lowSpaceCapitalCN[@]})
lookAhead=(${highSpaceLN[@]} ${highSpaceCN[@]} ${_fN[@]} ${_iN[@]} ${_lN[@]} ${_rN[@]} ${_tN[@]})
chain_context 0 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○右が、幅広の小文字の場合 FT 移動しない
backtrack=("")
input=(${_FN[@]} ${_TN[@]})
lookAhead=(${gravitySmallWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○右が、左上が開いている文字の場合 FT 右に移動
backtrack=("")
input=(${_FN[@]} ${_TN[@]})
lookAhead=(${highSpaceLN[@]} ${highSpaceCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 右が丸い文字に関する例外処理 2 ----------------------------------------

# ○左が PRÞS で 右が左寄り、均等、左が丸い文字の場合 右が丸い文字 左に移動しない
backtrack=(${_PL[@]} ${_RL[@]} ${_THL[@]} ${_SL[@]})
input=(${circleRN[@]})
lookAhead=(${outLgravityLN[@]} ${gravityEN[@]} \
${circleLN[@]} ${circleCN[@]})
 #lookAhead=(${gravityLN[@]} ${gravityEN[@]} \
 #${circleLN[@]} ${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 2つ右を見て移動させる例外処理 2 ----------------------------------------

# ○左が左寄り、右寄り、均等、中間の文字で 右が右寄り、中間の文字の場合 右寄り、均等、右が丸い文字、PRÞShs 左に移動しない (次の処理とセット)
backtrack=(${gravityEL[@]} \
${outLhgravityLN[@]} ${gravityMN[@]})
 #backtrack=(${gravityEL[@]} \
 #${gravityLN[@]} ${gravityMN[@]})
input=(${gravityRN[@]} ${_PN[@]} ${_RN[@]} ${_THN[@]} ${_SN[@]} ${_sN[@]} \
${circleRN[@]} ${circleSmallCN[@]})
 #input=(${gravityRN[@]} ${gravityEN[@]} ${_PN[@]} ${_RN[@]} ${_THN[@]} ${_SN[@]} ${_hN[@]} ${_sN[@]} \
 #${circleRN[@]} ${circleCN[@]})
lookAhead=(${gravityRN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 右が A で その右が W の場合 Rh 左に移動しない (次の処理とセット)
 #backtrack1=("")
 #backtrack=("")
 #input=(${_RN[@]} ${_hN[@]})
 #lookAhead=(${_AN[@]})
 #lookAhead1=(${_WN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○右が L 以外の左寄り、右寄りの文字、均等、中間の大文字で その右が幅広の文字の場合 右寄り、均等、右が丸い文字、PRÞShs 左に移動
backtrack1=("")
backtrack=("")
input=(${gravityRN[@]} ${gravityEN[@]} ${_PN[@]} ${_RN[@]} ${_THN[@]} ${_SN[@]} ${_hN[@]} ${_sN[@]} \
${circleRN[@]} ${circleCN[@]})
lookAhead=(${outLgravityLN[@]} ${gravityRN[@]} ${gravityCapitalEN[@]} ${gravityCapitalMN[@]})
lookAhead1=(${gravityWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○右が均等、中間の文字で その右が幅広の文字の場合 右寄り、右が丸い文字、均等な小文字、PRÞS 左に移動
backtrack1=("")
backtrack=("")
input=(${gravityRN[@]} ${gravitySmallEN[@]} ${_PN[@]} ${_RN[@]} ${_THN[@]} ${_SN[@]} \
${circleCapitalRN[@]})
lookAhead=(${gravitySmallEN[@]} ${gravitySmallMN[@]})
 #lookAhead=(${gravityEN[@]} ${gravityMN[@]})
lookAhead1=(${gravityWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○右が L 以外の左寄り、均等、左が丸い文字で その右が左寄り、右寄り、均等、中間、Vの字、t の場合 均等な小文字、右が丸い文字 左に移動 (右が丸い文字の処理と統合)
backtrack1=("")
backtrack=("")
input=(${gravitySmallEN[@]} \
${circleSmallRN[@]} ${circleSmallCN[@]})
lookAhead=(${outLgravityLN[@]} ${gravityEN[@]} \
${circleLN[@]} ${circleCN[@]})
lookAhead1=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]} ${_tN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○右が 均等、左が丸い文字で その右が fr の場合 均等な小文字 左に移動
backtrack1=("")
backtrack=("")
input=(${gravitySmallEN[@]})
lookAhead=(${gravityEN[@]} \
${circleLN[@]} ${circleCN[@]})
lookAhead1=(${_fN[@]} ${_rN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 右が右寄り、均等、中間の文字の場合 均等な小文字 移動しない (右が丸い文字の処理と統合)
 #backtrack=("")
 #input=(${gravitySmallEN[@]})
 #lookAhead=(${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 右が丸い文字に関する例外処理 3 ----------------------------------------

# ○右が左寄り、均等、左が丸い文字で その右が filr で その右が幅広の文字の場合 右が丸い小文字 左に移動
backtrack1=("")
backtrack=("")
input=(${circleSmallRN[@]} ${circleSmallCN[@]})
lookAhead=(${outLgravityLN[@]} ${gravityEN[@]} \
${circleLN[@]} ${circleCN[@]})
lookAhead1=(${_fN[@]} ${_iN[@]} ${_lN[@]} ${_rN[@]})
lookAheadX=(${gravityWN[@]}); aheadMax="2"
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

# ○右が左寄り、均等、左が丸い文字で その右が幅広の文字、IJjt の場合 右が丸い小文字 左に移動
backtrack1=("")
backtrack=("")
input=(${circleSmallRN[@]} ${circleSmallCN[@]})
lookAhead=(${outLgravityLN[@]} ${gravityEN[@]} \
${circleLN[@]} ${circleCN[@]})
lookAhead1=(${gravityWN[@]} ${_IN[@]} ${_JN[@]} ${_jN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 右が左寄り、均等、左が丸い文字で その右が filr 以外の場合 右が丸い小文字 左に移動 (2つ右の処理と統合)
 #backtrack1=("")
 #backtrack=("")
 #input=(${circleSmallRN[@]} ${circleSmallCN[@]})
 #lookAhead=(${outLgravityLN[@]} ${gravityEN[@]} \
 #${circleLN[@]} ${circleCN[@]})
 #lookAhead1=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]} \
 #${_IN[@]} ${_JN[@]} ${_jN[@]} ${_tN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○右が右寄り、均等、中間の文字の場合 均等、右が丸い小文字 移動しない (2つ右の処理と統合)
backtrack=("")
input=(${gravitySmallEN[@]} \
${circleSmallRN[@]} ${circleSmallCN[@]})
lookAhead=(${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○右が左寄りの文字の場合 右が丸い小文字 移動しない
backtrack=("")
input=(${circleSmallRN[@]} ${circleSmallCN[@]})
lookAhead=(${outLgravityLN[@]})
 #lookAhead=(${gravityLN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○右が、左が丸い文字の場合 右が丸い大文字 左に移動
backtrack=("")
input=(${circleCapitalRN[@]} ${circleCapitalCN[@]})
lookAhead=(${circleLN[@]} ${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# I に関する例外処理 3 ----------------------------------------

# ○右が I で その右が左寄り、均等な文字で その右が左寄り、右寄り、幅広、均等、中間の文字の場合 右寄りの文字、均等な大文字 右に移動
backtrack1=("")
backtrack=("")
input=(${gravityRN[@]} ${gravityCapitalEN[@]})
lookAhead=(${_IN[@]})
lookAhead1=(${outLgravityLN[@]} ${gravityCapitalEN[@]})
 #lookAhead1=(${gravityLN[@]} ${gravityCapitalEN[@]})
lookAheadX=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]}); aheadMax="2"
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

# ○右が I で その右が左寄り、均等な文字の場合 右寄りの文字、均等な大文字 右に移動しない
backtrack1=("")
backtrack=("")
input=(${gravityRN[@]} ${gravityCapitalEN[@]})
lookAhead=(${_IN[@]})
lookAhead1=(${outLgravityLN[@]} ${gravityCapitalEN[@]})
 #lookAhead1=(${gravityLN[@]} ${gravityCapitalEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "" "${backtrack1[*]}" "${lookAhead1[*]}"

# Jj に関する例外処理 2 ----------------------------------------

# ○右が左寄り、幅広の文字、均等な大文字の場合 Jj 左に移動
backtrack=("")
input=(${_JN[@]} ${_jN[@]})
lookAhead=(${gravityLN[@]} ${gravityWN[@]} ${gravityCapitalEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○右が Vの大文字の場合 J 移動しない
backtrack=("")
input=(${_JN[@]})
lookAhead=(${gravityCapitalVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○右が右寄りの小文字の場合 Jj 右に移動
backtrack=("")
input=(${_JN[@]} ${_jN[@]})
lookAhead=(${gravitySmallRN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○右が右寄り、均等、中間の小文字で その右が左寄り、右寄り、幅広、均等、XZeoxz で その右が狭い文字以外の場合 Jj 右に移動
backtrack1=("")
backtrack=("")
input=(${_JN[@]} ${_jN[@]})
lookAhead=(${gravitySmallEN[@]} ${gravitySmallMN[@]})
lookAhead1=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${_XN[@]} ${_ZN[@]} ${_eN[@]} ${_oN[@]} ${_xN[@]} ${_zN[@]})
lookAheadX=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]} ); aheadMax="2"
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

# hkĸAaSsxz に関する例外処理 ----------------------------------------

# ○右が a で その右が a の場合 a 左に移動
backtrack1=("")
backtrack=("")
input=(${_aN[@]})
lookAhead=(${_aN[@]})
lookAhead1=(${_aN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○右が k で その右が k の場合 k 左に移動
backtrack1=("")
backtrack=("")
input=(${_kN[@]})
lookAhead=(${_kN[@]})
lookAhead1=(${_kN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○右が ĸ で その右が ĸ の場合 ĸ 左に移動
backtrack1=("")
backtrack=("")
input=(${_kgN[@]})
lookAhead=(${_kgN[@]})
lookAhead1=(${_kgN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○右が左寄り、均等な文字の場合 ASs 左に移動しない
backtrack=("")
input=(${_AN[@]} ${_SN[@]} ${_sN[@]})
lookAhead=(${outLgravityLN[@]} ${gravityEN[@]})
 #lookAhead=(${gravityLN[@]} ${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○右が Vの小文字で その右が左寄り、右寄り、均等、中間の文字の場合 s 右に移動 (次の処理とセット)
backtrack1=("")
backtrack=("")
input=(${_sN[@]})
lookAhead=(${gravitySmallVN[@]})
lookAhead1=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○右が Vの小文字、V の場合 s 右に移動しない
backtrack=("")
input=(${_sN[@]})
lookAhead=(${gravitySmallVN[@]} ${_VN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○右が hkĸ の場合 kĸxz 左に移動しない
backtrack=("")
input=(${_kN[@]} ${_kgN[@]} ${_xN[@]} ${_zN[@]})
lookAhead=(${_hN[@]} ${_kN[@]} ${_kgN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が EFKXkxzĸ で 右が a の場合 bhpþ 左に移動
backtrack=(${_EL[@]} ${_FL[@]} ${_KL[@]} ${_XL[@]} ${_kL[@]} ${_xL[@]} ${_zL[@]} ${_kgL[@]})
input=(${_hN[@]})
 #input=(${_bN[@]} ${_hN[@]} ${_pN[@]} ${_thN[@]})
lookAhead=(${_aN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# frt に関する例外処理 ----------------------------------------

# ○右が幅広の大文字の場合 frt 左に移動
backtrack=("")
input=(${_fN[@]} ${_rN[@]} ${_tN[@]})
lookAhead=(${gravityCapitalWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○右が幅広の小文字の場合 rt 左に移動
backtrack=("")
input=(${_rN[@]} ${_tN[@]})
lookAhead=(${gravitySmallWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○左が右寄り、均等、Vの字の場合 r 右に移動しない (次の処理とセット)
backtrack=(${gravityRR[@]} ${gravityER[@]} ${gravityVR[@]})
input=(${_rN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○右が、左が丸い小文字、AXZsで その右が幅広の文字の場合 r 右に移動
backtrack1=("")
backtrack=("")
input=(${_rN[@]})
lookAhead=(${circleSmallLN[@]} ${circleSmallCN[@]} ${_AN[@]} ${_XN[@]} ${_ZN[@]} ${_sN[@]})
lookAhead1=(${gravityWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○右が左寄り、右寄り、均等、Vの大文字、bhkþ の場合 f 右に移動しない
backtrack=("")
input=(${_fN[@]})
lookAhead=(${gravityCapitalLN[@]} ${gravityCapitalRN[@]} ${gravityCapitalEN[@]} ${gravityCapitalVN[@]} \
${_bN[@]} ${_hN[@]} ${_kN[@]} ${_thN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○右が左寄り、右寄り、均等、中間の文字の場合 rt 右に移動しない
backtrack=("")
input=(${_rN[@]} ${_tN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# y に関する例外処理 2 ----------------------------------------

# ○右が y の場合 jpþ 右に移動しない
backtrack=("")
input=(${_jN[@]} ${_pN[@]} ${_thN[@]})
lookAhead=(${_yN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 右を見て移動させる例外処理 ----------------------------------------

# ○右が中間の小文字の場合 均等な大文字 左に移動
backtrack=("")
input=(${gravityCapitalEN[@]})
lookAhead=(${gravitySmallMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 右を見て移動させない例外処理 ----------------------------------------

# ○右が均等な小文字の場合 中間の文字、EKPÞkĸ 左に移動しない
backtrack=("")
input=(${gravityMN[@]} ${_EN[@]} ${_KN[@]} ${_PN[@]} ${_THN[@]} ${_kN[@]} ${_kgN[@]})
lookAhead=(${gravitySmallEN[@]})
chain_context 0 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○右が、丸い大文字の場合 EFKXkxzĸ 左に移動しない
backtrack=("")
input=(${_EN[@]} ${_FN[@]} ${_KN[@]} ${_XN[@]} ${_kN[@]} ${_xN[@]} ${_zN[@]} ${_kgN[@]})
lookAhead=(${circleCapitalCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 右側基準で左に移動 ========================================

# 左右を見て左に移動させる通常処理 ----------------------------------------

# ○右側基準で 狭い文字 左に移動
backtrack=(${outLgravityLR[@]} ${gravityRR[@]} ${gravityER[@]} ${gravityMR[@]} ${gravityVR[@]} ${gravityCR[@]})
 #backtrack=(${gravityLR[@]} ${gravityRR[@]} ${gravityER[@]} ${gravityMR[@]} ${gravityVR[@]} ${gravityCR[@]})
input=(${outJjrtgravityCN[@]})
 #input=(${gravityCN[@]})
lookAhead=(${gravityWN[@]})
chain_context 0 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 大文字と小文字で処理が異なる例外処理 2 ----------------------------------------

# 左が右寄り、均等、中間の大文字で 右が左寄り、右寄り、均等、中間、Vの字の場合 Ifilrt 右に移動しない (次の処理とセット、左右を見て移動させない処理と統合)
 #backtrack=(${gravityCapitalRR[@]} ${gravityCapitalER[@]} ${gravityCapitalMR[@]})
 #input=(${_IN[@]} ${_fN[@]} ${_iN[@]} ${_lN[@]} ${_rN[@]} ${_tN[@]})
 #lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が右寄り、均等、中間の大文字の場合 Ifilrt 右に移動
backtrack=(${gravityCapitalRR[@]} ${gravityCapitalER[@]} ${gravityCapitalMR[@]})
input=(${_IN[@]} ${_fN[@]} ${_iN[@]} ${_lN[@]} ${_rN[@]} ${_tN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左右を見て移動させない通常処理 ----------------------------------------

# ○左右を見て 左寄り、中間の文字 移動しない
backtrack=(${gravityRL[@]} ${gravityEL[@]} \
${outrtgravityCR[@]})
 #backtrack=(${gravityRL[@]} ${gravityEL[@]} \
 #${gravityCR[@]})
input=(${outLgravityLN[@]} ${gravityMN[@]})
 #input=(${gravityLN[@]} ${gravityMN[@]})
lookAhead=(${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 左右を見て 左寄りの文字 移動しない (左右を見て左に移動させない通常処理と統合)
 #backtrack=(${gravityLL[@]} ${gravityML[@]} \
 #${gravityVN[@]})
 #input=(${gravityLN[@]})
 #lookAhead=(${gravityVN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 左右を見て 中間の文字 移動しない (左右を見て左に移動させない通常処理と統合)
 #backtrack=(${gravityLN[@]} ${gravityMN[@]})
 #input=(${gravityMN[@]})
 #lookAhead=(${gravityVN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 左右を見て左に移動させない通常処理 ----------------------------------------

# ○右側基準で 左寄り、均等な文字 左に移動しない
backtrack=(${gravityVN[@]})
input=(${outLgravityLN[@]} ${gravityEN[@]})
 #input=(${gravityLN[@]} ${gravityEN[@]})
lookAhead=(${gravityLN[@]} ${gravityWN[@]} ${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○右側基準で 右寄り、中間の文字 左に移動しない
backtrack=(${outLhgravityLN[@]} ${gravityMN[@]})
 #backtrack=(${gravityLN[@]} ${gravityMN[@]})
input=(${gravityRN[@]})
 #input=(${gravityRN[@]} ${gravityMN[@]})
lookAhead=(${gravityLN[@]} ${gravityEN[@]})
chain_context 0 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○右側基準で 左寄り、中間の文字 左に移動しない
backtrack=(${gravityRL[@]} ${gravityEL[@]})
input=(${_XN[@]} ${_ZN[@]} ${_xN[@]} ${_zN[@]})
 #input=(${gravityLN[@]} ${gravityMN[@]})
lookAhead=(${outLgravityLN[@]} ${gravityCapitalEN[@]})
 #lookAhead=(${gravityLN[@]} ${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○右側基準で 左寄り 左に移動しない (例外で h を省く)
backtrack=(${outLgravityLL[@]} ${gravityML[@]})
 #backtrack=(${gravityLL[@]} ${gravityML[@]})
input=(${outLgravityCapitalLN[@]} ${outhbpthgravitySmallLN[@]})
 #input=(${outhgravityLN[@]})
lookAhead=(${outLgravityLN[@]} ${gravityEN[@]})
 #lookAhead=(${gravityLN[@]} ${gravityEN[@]})
chain_context 0 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○右側基準で 幅広の文字 左に移動しない
backtrack=(${gravityVL[@]})
 #backtrack=(${gravityLL[@]} ${gravityEL[@]} ${gravityML[@]} ${gravityVL[@]})
input=(${gravityWN[@]})
lookAhead=(${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
 #lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○右側基準で Vの字 左に移動しない
backtrack=(${gravityWL[@]} \
${gravityRN[@]} ${gravityEN[@]})
input=(${gravityVN[@]})
lookAhead=(${gravityWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# I に関する例外処理 4 ----------------------------------------

# ○左が幅広の文字で 右が Vの字の場合 I 右に移動
backtrack=(${gravityWN[@]})
input=(${_IN[@]})
lookAhead=(${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○左が左寄り、右寄り、幅広、均等、中間、Vの字の場合 I 移動しない
backtrack=(${outLgravityLR[@]} ${gravitySmallRR[@]} ${gravitySmallER[@]} ${gravitySmallMR[@]} ${gravityVR[@]} \
${outBDLgravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${outOQgravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
 #backtrack=(${gravityLR[@]} ${gravityRR[@]} ${gravityER[@]} ${gravityMR[@]} ${gravityVR[@]} \
 #${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
input=(${_IN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○右が右寄り、中間、Vの小文字の場合 I 右に移動
backtrack=("")
input=(${_IN[@]})
lookAhead=(${gravitySmallRN[@]} ${gravitySmallMN[@]} ${gravitySmallVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○右が左寄り、均等な文字、右寄り、中間、Vの大文字で その右が Vの字、I 以外の狭い文字の場合 I 右に移動
backtrack1=("")
backtrack=("")
input=(${_IN[@]})
lookAhead=(${gravityLN[@]} ${gravityCapitalRN[@]} ${gravityEN[@]} ${gravityCapitalMN[@]} ${gravityCapitalVN[@]})
lookAhead1=(${gravityVN[@]} ${gravitySmallCN[@]} ${_JN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 左が丸い文字に関する例外処理 4 ----------------------------------------

# 左が、右が丸い文字で 右が、左が丸い文字の場合 均等、左が丸い文字 左に移動しない (右が丸い文字の処理と統合)
 #backtrack=(${circleRL[@]} ${circleCL[@]})
 #input=(${gravityEN[@]} \
 #${circleLN[@]})
 #lookAhead=(${circleLN[@]} ${circleCN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○右が、左が丸い文字の場合 右寄りの文字 左に移動
backtrack=("")
input=(${gravityRN[@]})
lookAhead=(${circleLN[@]} ${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 右を見て左に移動させる通常処理 ----------------------------------------

# ○右側基準で 狭い文字以外 左に移動
backtrack=("")
input=(${outLgravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
 #input=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
lookAhead=(${gravityWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○右側基準で 左寄り、右寄り、幅広、均等、中間の文字 左に移動
backtrack=("")
input=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]})
lookAhead=(${gravityLN[@]} ${gravityEN[@]})
chain_context 0 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ○右側基準で 幅広の文字 左に移動
backtrack=("")
input=(${gravityWN[@]})
lookAhead=(${gravityRN[@]} ${gravityMN[@]} ${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 右側基準で右に移動 ========================================

# 2つ右を見て移動させる例外処理 3 ----------------------------------------

# ○右が ilt で その右が ijl の場合 左寄り、中間の文字 右に移動
backtrack1=("")
backtrack=("")
input=(${outLgravityLN[@]} ${gravityMN[@]})
 #input=(${gravityLN[@]} ${gravityMN[@]})
lookAhead=(${_iN[@]} ${_lN[@]} ${_tN[@]})
lookAhead1=(${_iN[@]} ${_jN[@]} ${_lN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○右が Ifr で その右が ijl の場合 左寄り、右寄り、中間の文字 右に移動
backtrack1=("")
backtrack=("")
input=(${outLgravityLN[@]} ${gravityRN[@]} ${gravityMN[@]})
 #input=(${gravityLN[@]} ${gravityRN[@]} ${gravityMN[@]})
lookAhead=(${_IN[@]} ${_fN[@]} ${_rN[@]})
lookAhead1=(${_iN[@]} ${_jN[@]} ${_lN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○右が il で その右が IJfjrt の場合 左寄り、右寄り、中間の文字 右に移動
backtrack1=("")
backtrack=("")
input=(${outLgravityLN[@]} ${gravityRN[@]} ${gravityMN[@]})
 #input=(${gravityLN[@]} ${gravityRN[@]} ${gravityMN[@]})
lookAhead=(${_iN[@]} ${_lN[@]})
lookAhead1=(${_IN[@]} ${_JN[@]} ${_fN[@]} ${_jN[@]} ${_rN[@]} ${_tN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○右が Jj で その右が狭い文字の場合 左寄り、右寄り、均等、中間の文字 右に移動
backtrack1=("")
backtrack=("")
input=(${outLgravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
 #input=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
lookAhead=(${_JN[@]} ${_jN[@]})
lookAhead1=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○右が狭い文字で その右が狭い文字以外の場合 均等な小文字 右に移動
backtrack1=("")
backtrack=("")
input=(${gravitySmallEN[@]})
lookAhead=(${outJjgravityCN[@]})
 #lookAhead=(${gravityCN[@]})
lookAhead1=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○右が狭い文字で その右が狭い文字で その右が幅広、狭い文字の場合 左寄り、中間の文字 右に移動
backtrack1=("")
backtrack=("")
input=(${outLgravityLN[@]} ${gravityMN[@]})
 #input=(${gravityLN[@]} ${gravityMN[@]})
lookAhead=(${gravityCN[@]})
lookAhead1=(${gravityCN[@]})
lookAheadX=(${gravityWN[@]} ${gravityCN[@]}); aheadMax="2"
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

# ○右が狭い小文字で その右が狭い文字以外の場合 左寄り、右寄り、幅広、均等、中間の文字 右に移動
backtrack1=("")
backtrack=("")
input=(${outLgravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]})
 #input=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]})
lookAhead=(${gravitySmallCN[@]})
lookAhead1=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○右が I で その右が狭い文字以外の場合 左寄り、中間の文字 右に移動
backtrack1=("")
backtrack=("")
input=(${outLgravityLN[@]} ${gravityMN[@]})
 #input=(${gravityLN[@]} ${gravityMN[@]})
lookAhead=(${_IN[@]})
lookAhead1=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ---

# ○右が Vの小文字、VY で その右が幅広の文字以外の場合 左寄り、中間の大文字 右に移動
backtrack1=("")
backtrack=("")
input=(${outLgravityCapitalLN[@]} ${gravityCapitalMN[@]})
 #input=(${gravityCapitalLN[@]} ${gravityCapitalMN[@]})
lookAhead=(${gravitySmallVN[@]} ${_VN[@]} ${_YN[@]})
lookAhead1=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]} ${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○右が T の場合 左寄りの大文字、XZ 右に移動
backtrack=("")
input=(${outLgravityCapitalLN[@]} ${_XN[@]} ${_ZN[@]})
lookAhead=(${_TN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○右が Vの字で その右が狭い文字の場合 左寄り、中間の小文字 右に移動
backtrack1=("")
backtrack=("")
input=(${gravitySmallLN[@]} ${gravitySmallMN[@]})
lookAhead=(${gravityVN[@]})
lookAhead1=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# 左右を見て右に移動させる通常処理 ----------------------------------------

# ○右側基準で 左寄り、均等な文字 右に移動
backtrack=(${gravityVN[@]})
input=(${outLgravityLN[@]} ${gravityEN[@]})
 #input=(${gravityLN[@]} ${gravityEN[@]})
lookAhead=(${outjgravityCN[@]})
 #lookAhead=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○右側基準で 右寄り、中間の文字 右に移動
backtrack=(${outLhgravityLN[@]} ${gravityMN[@]})
 #backtrack=(${gravityLN[@]} ${gravityMN[@]})
input=(${gravityRN[@]} ${gravityMN[@]})
lookAhead=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○右側基準で 幅広の文字 右に移動
backtrack=(${outJgravityCR[@]})
 #backtrack=(${gravityEL[@]} \
 #${gravityCR[@]})
input=(${gravityWN[@]})
lookAhead=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左右を見て右に移動させない通常処理 ----------------------------------------

# ○右側基準で Vの字 右に移動しない
backtrack=(${gravityRL[@]} ${gravityEL[@]} \
${outLgravityLR[@]} ${gravityMR[@]} \
${outLgravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
 #backtrack=(${gravityRL[@]} ${gravityEL[@]} \
 #${gravityLR[@]} ${gravityMR[@]} ${gravityCR[@]} \
 #${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
input=(${gravityVN[@]})
lookAhead=(${gravityRN[@]} ${gravityLN[@]} ${gravityEN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○右側基準で 狭い文字 右に移動しない
backtrack=(${outLgravityLR[@]} ${gravitySmallRR[@]} ${gravitySmallER[@]} ${gravitySmallMR[@]} ${gravityVR[@]} \
${gravityRN[@]})
 #backtrack=(${gravityLR[@]} ${gravityRR[@]} ${gravityER[@]} ${gravityMR[@]} ${gravityVR[@]} \
 #${gravityRN[@]} ${gravityEN[@]})
input=(${outjgravitySmallCN[@]} ${_JN[@]})
 #input=(${gravityCN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
chain_context 0 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○右側基準で 狭い文字 右に移動しない
backtrack=(${gravityWN[@]})
input=(${outjrtgravitySmallCN[@]})
 #input=(${gravityCN[@]})
lookAhead=(${gravityLN[@]} ${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 右を見て右に移動させる通常処理 ----------------------------------------

# ○右側基準で Vの字 右に移動
backtrack=("")
input=(${gravityVN[@]})
lookAhead=(${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○右側基準で 狭い文字 右に移動 (例外で JIjrt を省く)
backtrack=("")
input=(${outjrtgravitySmallCN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# ○右側基準で 狭い文字 右に移動 (例外で I を省く)
backtrack=("")
input=(${gravitySmallCN[@]} ${_JN[@]})
lookAhead=(${gravityVN[@]})
 #lookAhead=(${gravityVN[@]} ${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 2つ右を見て移動させる例外処理 4 ----------------------------------------

# ○右が左寄り、均等な文字で その右が幅広の文字の場合 Vの字 左に移動
backtrack1=("")
backtrack=("")
input=(${gravityVN[@]})
lookAhead=(${gravityLN[@]} ${gravityEN[@]})
lookAhead1=(${gravityWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○右が右寄り、中間の文字で その右が Vの字、狭い文字の場合 Vの字 右に移動
backtrack1=("")
backtrack=("")
input=(${gravityVN[@]})
lookAhead=(${gravityRN[@]} ${gravityMN[@]})
lookAhead1=(${gravityVN[@]} ${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ○右が右寄り、均等、中間の小文字で その右が eo 以外の中間の小文字で その右が Vの小文字、狭い文字の場合 Vの字 右に移動
backtrack1=("")
backtrack=("")
input=(${gravityVN[@]})
lookAhead=(${gravitySmallRN[@]} ${gravitySmallEN[@]} ${gravitySmallMN[@]})
lookAhead1=(${outeogravitySmallMN[@]})
lookAheadX=(${gravitySmallVN[@]} ${gravityCN[@]}); aheadMax="2"
chain_context 0 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

# 2つ左を見て移動させる例外処理 2 ----------------------------------------

# ○右が右寄り、中間、Vの字の場合 左寄り、右寄り、均等、中間の文字 右に移動しない (次の処理とセット)
backtrack=("")
input=(${outLbpthgravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${outeogravityMN[@]})
 #input=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
lookAhead=(${gravityRN[@]} ${gravityMN[@]} ${gravityVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ○左が右寄り、均等、中間、右が丸い文字、Rh で その左が狭い文字、L の場合 左寄り、右寄り、均等、中間の文字 右に移動
backtrack1=(${gravityCL[@]} ${_LL[@]} \
${outJjrtgravityCR[@]} ${_rR[@]} ${_LR[@]} \
${gravityCN[@]} ${_LN[@]})
backtrack=(${gravityRL[@]} ${gravityEL[@]} ${gravityML[@]} ${_RL[@]} ${_hL[@]} \
${gravityMN[@]} ${_RN[@]} \
${circleRL[@]} \
${circleRN[@]})
input=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}"

# ○左が Vの字で その左が狭い文字、L の場合 幅広の文字 右に移動
backtrack1=(${gravityCL[@]} ${_LL[@]} \
${gravityCR[@]} ${_LR[@]} \
${gravityCN[@]} ${_LN[@]})
backtrack=(${gravityVL[@]})
input=(${gravityWN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}"

# ○左が HNUGadgq で その左が左寄り、中間、Vの字、丸い文字の場合 左寄りの文字、均等な大文字 右に移動
backtrack1=(${gravityLL[@]} ${gravityML[@]} ${gravityVL[@]} \
${gravityMN[@]} ${gravityVN[@]} \
${circleCL[@]})
backtrack=(${_HL[@]} ${_NL[@]} ${_UL[@]} ${_GL[@]} ${_aL[@]} ${_dL[@]} ${_gL[@]} ${_qL[@]})
input=(${gravityLN[@]} ${gravityCapitalEN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}" "${backtrack1[*]}"

# 左が丸い文字に関する例外処理 5 ----------------------------------------

# ○左が、右が丸い文字の場合 左が丸い文字 右に移動
backtrack=(${circleRN[@]} ${circleSmallCN[@]})
 #backtrack=(${circleRN[@]} ${circleCN[@]})
input=(${circleLN[@]} ${circleSmallCN[@]})
 #input=(${circleLN[@]} ${circleCN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左を見て移動させる例外処理 ----------------------------------------

# ○左が均等な小文字の場合 狭い文字 左に移動
backtrack=(${gravitySmallEN[@]})
input=(${outjgravitySmallCN[@]} ${_JN[@]})
 #input=(${gravityCN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

fi
# 記号類 ++++++++++++++++++++++++++++++++++++++++

# |: に関する処理 ----------------------------------------

# ○左が *+-=<>|~: の場合 | 下に : 上に移動
backtrack=(${_barD[@]} ${_tildeD[@]} ${_colonU[@]} \
${operatorHN[@]} ${_lessN[@]} ${_greaterN[@]})
input=(${_barN[@]} ${_colonN[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"

# ○右が *+-=<> の場合 | 下に : 上に移動
backtrack=("")
input=(${_barN[@]} ${_colonN[@]})
lookAhead=(${operatorHN[@]} ${_lessN[@]} ${_greaterN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"

# ○右が : の場合 | 下に移動
backtrack=("")
input=(${_barN[@]})
lookAhead=(${_colonN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"

# ○右が | の場合 : 上に移動
backtrack=("")
input=(${_colonN[@]})
lookAhead=(${_barN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"

# ○両側が数字の場合 : 上に移動
backtrack=(${figureN[@]})
input=(${_colonN[@]})
lookAhead=(${figureN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"

# ~ に関する処理 ----------------------------------------

# ○左が <>|~: の場合 ~ 下に移動
backtrack=(${_barD[@]} ${_tildeD[@]} ${_colonU[@]} \
${_lessN[@]} ${_greaterN[@]})
input=(${_tildeN[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"

# ○右が <> の場合 ~ 下に移動
backtrack=("")
input=(${_tildeN[@]})
lookAhead=(${_lessN[@]} ${_greaterN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"

# 括弧に関する処理の始め ----------------------------------------

# ○左が左丸括弧、左波括弧の場合 左丸括弧、左波括弧 左に移動
backtrack=(${_parenrightL[@]} ${_bracerightL[@]} \
${_parenrightN[@]} ${_bracerightN[@]})
input=(${_parenrightN[@]} ${_bracerightN[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"

# ○左が括弧の場合 左角括弧 左に移動
backtrack=(${bracketRL[@]} \
${bracketRN[@]})
input=(${_bracketrightN[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"

# ---

# ○右が右丸括弧、右波括弧の場合 右丸括弧、右波括弧 右に移動
backtrack=("")
input=(${_parenleftN[@]} ${_braceleftN[@]})
lookAhead=(${_parenleftN[@]} ${_braceleftN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

# ○右が左括弧の場合 左角括弧 右に移動
backtrack=("")
input=(${_bracketleftN[@]})
lookAhead=(${bracketLN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

#CALT0
#<< "#CALT1" # アルファベット・記号 ||||||||||||||||||||||||||||||||||||||||

pre_add_lookup

# アルファベット ++++++++++++++++++++++++++++++++++++++++
if [ "${symbol_only_flag}" = "false" ]; then

# 右側が元に戻って詰まった間隔を整える処理 1 ----------------------------------------

# ▲左が、丸い文字で 右が左寄り、右寄り、均等な大文字の場合 eo 以外の中間の文字 左に移動
backtrack=(${circleSmallCN[@]})
input=(${outeogravityMN[@]})
lookAhead=(${gravityCapitalLL[@]} ${gravityCapitalRL[@]} ${gravityCapitalEL[@]} \
${gravityCapitalLR[@]} ${gravityWR[@]} ${gravityCapitalER[@]} \
${gravityCapitalLN[@]} ${gravityCapitalEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が、丸い文字で 右が左寄り、均等な小文字、右寄りの大文字の場合 eo 以外の中間の文字 元に戻る
backtrack=(${circleSmallCR[@]})
input=(${outeogravityMR[@]})
lookAhead=(${gravitySmallLR[@]} ${gravityCapitalRR[@]} ${gravitySmallER[@]} \
${gravitySmallLN[@]} ${gravityCapitalRN[@]} ${gravitySmallEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# △左が中間の文字で 右が左寄り、均等な文字の場合 左寄り、均等な小文字 元に戻る
backtrack=(${gravityMN[@]})
input=(${gravitySmallLR[@]} ${gravitySmallER[@]})
lookAhead=(${gravityLR[@]} ${gravityER[@]} \
${gravityLN[@]} ${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 移動しない、元に戻らない処理 ----------------------------------------

# △右が、左が丸い文字、a の場合 EFKXkĸxz 左に移動しない
backtrack=("")
input=(${_EN[@]} ${_FN[@]} ${_KN[@]} ${_XN[@]} ${_kN[@]} ${_xN[@]} ${_zN[@]} ${_kgN[@]})
lookAhead=(${circleSmallLL[@]} ${circleSmallCL[@]} ${_aL[@]} \
${circleLN[@]} ${circleCN[@]} ${_aN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# △右が、左上が開いている文字、A の場合 FP 左に移動しない
backtrack=("")
input=(${_FN[@]} ${_PN[@]})
lookAhead=(${highSpaceLL[@]} ${highSpaceCL[@]} ${_AL[@]} \
${highSpaceLN[@]} ${highSpaceCN[@]} ${_AN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# △右が、左下が開いている文字、Ww の場合 A 左に移動しない
backtrack=("")
input=(${_AN[@]})
lookAhead=(${lowSpaceLL[@]} ${lowSpaceCL[@]} \
${lowSpaceLN[@]} ${lowSpaceCN[@]})
 #lookAhead=(${lowSpaceLL[@]} ${lowSpaceCL[@]} ${_WL[@]} ${_wL[@]} \
 #${lowSpaceLN[@]} ${lowSpaceCN[@]} ${_WN[@]} ${_wN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# △右が、左が丸い文字、a の場合 EFKXkĸxz 元に戻らない
backtrack=("")
input=(${_ER[@]} ${_FR[@]} ${_KR[@]} ${_XR[@]} ${_kR[@]} ${_xR[@]} ${_zR[@]} ${_kgR[@]})
lookAhead=(${circleLR[@]} ${circleCR[@]} ${_aR[@]} \
${circleSmallLN[@]} ${circleSmallCN[@]} ${_aN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# △右が、左上が開いている文字、A の場合 FP 元に戻らない
backtrack=("")
input=(${_FR[@]} ${_PR[@]})
lookAhead=(${highSpaceLL[@]} ${highSpaceCL[@]} ${_AL[@]} \
${highSpaceLN[@]} ${highSpaceCN[@]} ${_AN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# △右が、左下が開いている文字、Ww の場合 A 元に戻らない
backtrack=("")
input=(${_AR[@]})
lookAhead=(${lowSpaceLL[@]} ${lowSpaceCL[@]} \
${lowSpaceLN[@]} ${lowSpaceCN[@]})
 #lookAhead=(${lowSpaceLL[@]} ${lowSpaceCL[@]} ${_WL[@]} ${_wL[@]} \
 #${lowSpaceLN[@]} ${lowSpaceCN[@]} ${_WN[@]} ${_wN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 同じ文字を等間隔にさせる処理 ----------------------------------------

# △左が全ての文字の場合 狭い文字、L 元に戻らない
backtrack=(${gravityRL[@]} ${gravityWL[@]} ${gravityEL[@]} \
${outLgravityLR[@]} ${gravityRR[@]} ${gravityWR[@]} ${gravityER[@]} ${gravityMR[@]} ${gravityVR[@]} ${gravityCR[@]} \
${outLgravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
input=(${gravityCR[@]} ${_LR[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# △左が狭い文字の場合 左寄り、右寄り、幅広、均等、丸い文字 元に戻らない (開いた間隔を詰める処理と統合)
backtrack=(${gravityLL[@]} ${gravityML[@]} ${gravityVL[@]} ${gravityCL[@]} \
${gravityCR[@]} \
${gravityVN[@]} ${gravityCN[@]} ${_LN[@]})
input=(${outLgravityLL[@]} ${gravityRL[@]} ${gravityWL[@]} ${gravityEL[@]} \
${circleCL[@]})
 #input=(${outLgravityLL[@]} ${gravityRL[@]} ${gravityWL[@]} ${gravityEL[@]} \
 #${circleCL[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# △右が中間の大文字、Vの字、狭い文字の場合 左寄り、右寄り、幅広、均等、丸い文字 元に戻らない
backtrack=("")
input=(${gravityLR[@]} ${gravityRR[@]} ${gravityWR[@]} ${gravityER[@]} \
${circleCR[@]})
lookAhead=(${gravityCapitalMR[@]} ${gravityVR[@]} ${gravityCR[@]} \
${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# L
  # △右から元に戻る (広がる)
backtrack1=("")
backtrack=("")
input=(${_LR[@]})
lookAhead=(${_LN[@]})
lookAhead1=(${_LR[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"

  # △右から元に戻る (中) 左から元に戻る (広がる)
backtrack1=(${_LN[@]})
backtrack=(${_LN[@]})
input=(${_LL[@]} ${_LR[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"

  # △右から元に戻る (中)
backtrack=(${_LN[@]})
input=(${_LR[@]})
lookAhead=(${_LN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# j
  # △右から元に戻る (広がる)
backtrack1=("")
backtrack=("")
input=(${_jR[@]})
lookAhead=(${_jN[@]})
lookAhead1=(${_jL[@]})
lookAheadX=(${_jL[@]}); aheadMax="2"
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

# 丸い小文字
class=(_e _o)
for S in ${class[@]}; do
  # △△左から元に戻る (縮む)
  backtrack1=("")
  backtrack=("")
  eval input=(\${${S}L[@]})
  eval lookAhead=(\${${S}N[@]})
  eval lookAhead1=(\${${S}R[@]})
  eval lookAheadX=(\${${S}R[@]}); aheadMax="2"
  chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

  # △△右から元に戻る (縮む)
  eval backtrack1=(\${${S}N[@]})
  eval backtrack=(\${${S}N[@]})
  eval input=(\${${S}R[@]})
  lookAhead=("")
  chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"
done

# 丸くない右寄りの文字、kĸ
class=(_a _k _kg)
for S in ${class[@]}; do
  # △△△左から元に戻る (縮む)
  backtrack1=("")
  backtrack=("")
  eval input=(\${${S}L[@]})
  eval lookAhead=(\${${S}L[@]})
  eval lookAhead1=(\${${S}L[@]} \${${S}N[@]})
  chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"

  # △△△左から元に戻る (中)
  eval backtrack=(\${${S}N[@]})
  eval input=(\${${S}L[@]})
  eval lookAhead=(\${${S}N[@]})
  chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
done

#  L 以外の左寄りの大文字、左が丸い文字、右が丸い文字、h
class=(_B _D _E _F _K _P _R _TH _C _G _c _d _g _q _b _p _th _h)
for S in ${class[@]}; do
  # △△△△ △△△△ △△△△ △△△△ △△左から元に戻る (縮む)
  backtrack1=("")
  backtrack=("")
  eval input=(\${${S}L[@]})
  eval lookAhead=(\${${S}N[@]})
  eval lookAhead1=(\${${S}N[@]})
  chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"
done

#  L 以外の左寄りの文字、右寄りの文字
class=(_B _D _E _F _K _P _R _TH _b _h _k _p _th _kg \
_C _G _a _c _d _g _q)
for S in ${class[@]}; do
  # △△△△ △△△△ △△△△ △△△△ △△△△ △右から元に戻る (縮む)
  eval backtrack1=(\${${S}N[@]})
  eval backtrack=(\${${S}N[@]})
  eval input=(\${${S}R[@]})
  lookAhead=("")
  chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"
done

# 移動しない文字以外の幅広の文字
class=(_M _W _m _w)
for S in ${class[@]}; do
  # △△△△左から元に戻る (縮む)
  backtrack1=("")
  backtrack=("")
  eval input=(\${${S}L[@]})
  eval lookAhead=(\${${S}N[@]})
  eval lookAhead1=(\${${S}N[@]})
  chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"

  # △△△△右から元に戻る (縮む)
  eval backtrack1=(\${${S}N[@]})
  eval backtrack=(\${${S}N[@]})
  eval input=(\${${S}R[@]})
  lookAhead=("")
  chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"
done

# 均等な文字
class=(_H _N _O _Q _U _n _u)
for S in ${class[@]}; do
  # △△△△ △△△左から元に戻る (縮む)
  backtrack1=("")
  backtrack=("")
  eval input=(\${${S}L[@]})
  eval lookAhead=(\${${S}N[@]})
  eval lookAhead1=(\${${S}R[@]} \${${S}N[@]})
  eval lookAheadX=(\${${S}R[@]} \${${S}N[@]}); aheadMax="2"
  chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

  # △△△△ △△△右から元に戻る (縮む)
  eval backtrack1=(\${${S}N[@]})
  eval backtrack=(\${${S}N[@]})
  eval input=(\${${S}R[@]})
  lookAhead=("")
  chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"
done

# 狭い文字
class=(_I _J _f _i _j _l _r _t)
for S in ${class[@]}; do
  if [ "${S}" != "_j" ]; then
  # △△△△ △△△右から元に戻る (広がる) j 以外
    backtrack1=("")
    backtrack=("")
    eval input=(\${${S}R[@]})
    eval lookAhead=(\${${S}N[@]})
    eval lookAhead1=(\${${S}N[@]})
    chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"
  fi

  # △△△△ △△△△左から元に戻る (広がる)
  eval backtrack1=(\${${S}N[@]})
  eval backtrack=(\${${S}N[@]})
  eval input=(\${${S}L[@]})
  lookAhead=("")
  chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"
done

# 丸い文字と均等な文字が並んだ場合の処理 ----------------------------------------

# △左が、左が丸い文字の場合 均等な文字 元の位置に戻らない
backtrack=(${circleLN[@]})
input=(${gravityER[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# △右が c の場合 右が丸い、均等な小文字 元の位置に戻らない
backtrack=("")
input=(${gravitySmallER[@]} \
${circleSmallRR[@]} ${circleSmallCR[@]})
lookAhead=(${_cR[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 大文字 ----

# △左が、左右が丸い大文字で 右が、左右が丸い大文字の場合 左右が丸い、均等な大文字 元に戻る
backtrack=(${circleCapitalLN[@]} ${circleCapitalRN[@]} ${circleCapitalCN[@]})
input=(${circleCapitalLR[@]} ${circleCapitalRR[@]} ${circleCapitalCR[@]} \
${gravityCapitalER[@]})
lookAhead=(${circleCapitalLR[@]} ${circleCapitalRR[@]} ${circleCapitalCR[@]} \
${circleCapitalLN[@]} ${circleCapitalRN[@]} ${circleCapitalCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# △左が、右寄り、均等な大文字で 右が、均等な大文字の場合 左右が丸い、均等な大文字 元に戻る
backtrack=(${gravityCapitalRN[@]} ${gravityCapitalEN[@]})
input=(${circleCapitalLR[@]} ${circleCapitalRR[@]} ${circleCapitalCR[@]} \
${gravityCapitalER[@]})
lookAhead=(${gravityCapitalER[@]} \
${gravityCapitalEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 小文字 ---

# △左が、左右が丸い小文字で 右が、左右が丸い小文字の場合 左が丸い、均等な小文字 元に戻る
backtrack=(${circleSmallLN[@]} ${circleSmallRN[@]} ${circleSmallCN[@]})
input=(${circleSmallLR[@]} ${circleSmallCR[@]} \
${gravitySmallER[@]})
lookAhead=(${circleSmallLR[@]} ${circleSmallRR[@]} ${circleSmallCR[@]} \
${circleSmallLN[@]} ${circleSmallRN[@]} ${circleSmallCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# △左が、右が丸い、右寄り、均等な小文字で 右が、左寄り、均等な小文字の場合 左が丸い、均等な小文字 元に戻る
backtrack=(${circleSmallRN[@]} ${circleSmallCN[@]} \
${gravitySmallRN[@]} ${gravitySmallEN[@]})
input=(${circleSmallLR[@]} ${circleSmallCR[@]} \
${gravitySmallER[@]})
lookAhead=(${gravitySmallLR[@]} ${gravitySmallER[@]} \
${gravitySmallLN[@]} ${gravitySmallEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# △左が、右が丸い小文字で 右が、左右が丸い小文字の場合 右が丸い小文字 元に戻る
backtrack=(${circleSmallRN[@]} ${circleSmallCN[@]})
input=(${circleSmallRR[@]})
lookAhead=(${circleSmallLR[@]} ${circleSmallRR[@]} ${circleSmallCR[@]} \
${circleSmallLN[@]} ${circleSmallRN[@]} ${circleSmallCN[@]})
chain_context 0 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# △左が均等、右が丸い小文字で 右が、左寄り、均等な小文字の場合 右が丸い小文字 元に戻る
backtrack=(${gravitySmallEN[@]} \
${circleSmallRN[@]})
 #backtrack=(${gravitySmallEN[@]} \
 #${circleSmallRN[@]} ${circleSmallCN[@]})
input=(${circleSmallRR[@]})
lookAhead=(${gravitySmallLR[@]} ${gravitySmallER[@]} \
${gravitySmallLN[@]} ${gravitySmallEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右に幅広が来た時に左側を詰める処理の始め ----------------------------------------

# △左が幅広、均等、右が丸い文字で 右が右寄り、均等、右が丸い文字の場合 均等、右寄り、丸い文字 元に戻る 1回目 (右側が戻った処理と統合)
backtrack=(${gravityWL[@]} \
${gravityER[@]} \
${circleRR[@]} ${circleCR[@]})
input=(${gravityER[@]} ${gravityRR[@]} \
${circleCR[@]})
lookAhead=(${gravityRN[@]} ${gravityEN[@]} \
${circleRN[@]} ${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# ---

# 左が右寄り、均等な文字で 右が Ww の場合 左寄り、右寄り、均等、中間の文字 左に移動しない (次の処理とセット)
 #backtrack=(${gravityRN[@]} ${gravityEN[@]})
 #input=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
 #lookAhead=(${_WR[@]} ${_wR[@]} \
 #${_WN[@]} ${_wN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# △左が右寄りの文字で その左が左寄り、右寄り、均等、中間の文字で 右が幅広の文字の場合 L 以外の左寄りの文字 左に移動
backtrack1=(${gravityRL[@]} ${gravityEL[@]} \
${gravityLN[@]} ${gravityMN[@]})
backtrack=(${gravityRN[@]})
input=(${outLgravityLN[@]})
lookAhead=(${gravityWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}"

# △左が左寄り、右寄り、均等、中間、Vの字で 右が幅広の文字の場合 L 以外の左寄り、右寄り、均等、中間の文字 左に移動
backtrack=(${gravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} ${gravityML[@]} ${gravityVL[@]} \
${gravityLN[@]} ${gravitySmallEN[@]} ${gravityMN[@]} ${gravityVN[@]})
input=(${outLgravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
lookAhead=(${gravityWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が BD 以外の左寄り、右寄り、均等、中間の文字で 右が Ww 以外の幅広の文字の場合 右寄り、丸い文字 左に移動
backtrack=(${outBDgravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} ${gravityML[@]} \
${gravitySmallEN[@]})
input=(${gravityRN[@]} \
${circleCN[@]})
lookAhead=(${gravityWR[@]})
 #lookAhead=(${outWwgravityWR[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が中間の文字で 右が幅広の文字の場合 左寄り、均等な文字 左に移動
backtrack=(${gravityML[@]})
input=(${gravityLN[@]} ${outOQgravityEN[@]})
 #input=(${gravityLN[@]} ${gravityEN[@]})
lookAhead=(${gravityWR[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が左寄り、右寄り、中間の文字で 右が幅広の文字の場合 右寄り、均等、A 以外の中間の文字 左に移動
backtrack=(${gravityRN[@]} \
${gravityLR[@]} ${gravityMR[@]})
input=(${gravityRN[@]} ${gravityEN[@]} ${outAgravityMN[@]})
lookAhead=(${gravityWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が均等、右が丸い大文字の場合 右寄り、中間の文字 左に移動しない
backtrack=(${gravityCapitalEL[@]} \
${circleCapitalRL[@]})
input=(${gravityRN[@]} ${gravityMN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 右側が元に戻って詰まった間隔を整える処理 2 ----------------------------------------

# 左が幅広の文字で 右が右寄りの文字の場合 均等、丸い文字 元に戻る (右に幅広の処理と統合)
 #backtrack=(${gravityWL[@]})
 #input=(${gravityER[@]} \
 #${circleCR[@]})
 #lookAhead=(${gravityRN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# △左が、左が丸い小文字で 右が、左が丸い小文字の場合 均等、右が丸い文字 元に戻らない (次の処理とセット)
backtrack=(${circleSmallLN[@]})
input=(${circleRR[@]})
 #input=(${gravityER[@]} \
 #${circleRR[@]} ${circleCR[@]})
lookAhead=(${circleSmallLN[@]} ${circleSmallCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# △左が右寄り、均等、右が丸い小文字で 右が左寄り、右寄り、均等、丸い文字の場合 均等、右が丸い文字 元に戻る
backtrack=(${gravitySmallRN[@]} ${gravitySmallEN[@]} \
${circleSmallRN[@]} ${circleSmallCN[@]})
input=(${gravityER[@]} \
${circleRR[@]} ${circleCR[@]})
lookAhead=(${gravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} \
${circleCL[@]} \
${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} \
${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# △左が右寄り、均等、右が丸い小文字で 右が左寄り、右寄り、均等、中間の文字の場合 右寄り、中間の文字 元に戻る
backtrack=(${gravitySmallRN[@]} ${gravitySmallEN[@]} \
${circleSmallRN[@]} ${circleSmallCN[@]})
input=(${gravityRR[@]} ${gravityMR[@]})
lookAhead=(${gravityLR[@]} ${gravityER[@]} \
${circleLR[@]} ${circleCR[@]} \
${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# △左が、右が丸文字で 右が左寄り、均等な文字の場合 右が丸い文字 元に戻る
backtrack=(${circleRN[@]} ${circleCN[@]})
input=(${circleLR[@]} ${circleCR[@]})
lookAhead=(${gravityLR[@]} ${gravityER[@]} \
${gravityLN[@]} ${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# △左が eo 以外の中間の小文字で 右が右寄り、均等な大文字、丸い文字、dgq の場合 L 以外の左寄りの文字 元に戻る
backtrack=(${outeogravitySmallMR[@]})
input=(${outLgravityLR[@]})
lookAhead=(${gravityCapitalRN[@]} ${gravityCapitalEN[@]} ${_dN[@]} ${_gN[@]} ${_qN[@]} \
${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# △左が中間の小文字で 右が eo 以外の中間の文字の場合 BDLpbþ 以外の左寄りの文字 元に戻る
backtrack=(${gravitySmallMR[@]})
input=(${outBDLbpthgravityLR[@]})
lookAhead=(${outeogravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# △左が中間の文字、c で 右が c 以外の左が丸い小文字の場合 h 元に戻る
backtrack=(${gravityMN[@]} ${_cN[@]})
input=(${_hR[@]})
lookAhead=(${_dR[@]} ${_gR[@]} ${_qR[@]} \
${circleSmallCR[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# △左が狭い文字で 右が左寄り、右寄り、均等、丸い文字の場合 L 以外の左寄り、右寄り、均等、中間の文字 左に移動
backtrack=(${gravityCL[@]} \
${_IR[@]} ${_iR[@]} ${_lR[@]} \
${gravityCN[@]})
input=(${outLgravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
lookAhead=(${gravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} \
${circleCL[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が狭い文字で 右が左寄り、右寄り、均等、丸い文字の場合 右寄り、均等な文字、h 左に移動
backtrack=(${gravityCL[@]} \
${_IR[@]} ${_iR[@]} ${_lR[@]} \
${_IN[@]} ${_iN[@]} ${_lN[@]})
input=(${gravityRN[@]} ${gravityEN[@]} ${_hN[@]})
lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} \
${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 右側が左に寄った、または元に戻って詰まった間隔を整える処理 1回目----------------------------------------

# △左が EFKLXkĸxz で 右が左寄り、右寄り、均等、中間の文字の場合 右寄り、均等、中間の文字、h 左に移動
backtrack=(${_ER[@]} ${_FR[@]} ${_KR[@]} ${_LR[@]} ${_XR[@]} ${_kR[@]} ${_xR[@]} ${_zR[@]} ${_kgR[@]})
input=(${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${_hN[@]})
lookAhead=(${gravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} ${gravityML[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が Shs で 右が左寄り、右寄り、均等、中間の文字の場合 右寄り、中間の文字 左に移動
backtrack=(${_SR[@]} ${_hR[@]} ${_sR[@]})
input=(${gravityRN[@]} ${gravityMN[@]})
lookAhead=(${gravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} ${gravityML[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ---

# △左が左寄り、中間の文字で 右が左寄りの文字の場合 EFKkĸ 左に移動しない
backtrack=(${gravityLL[@]} ${gravityML[@]})
input=(${_EN[@]} ${_FN[@]} ${_KN[@]} ${_kN[@]} ${_kgN[@]})
lookAhead=(${gravityLN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# △左が均等な小文字、h で 右が左寄り、均等な文字の場合 hkĸ 左に移動しない
backtrack=(${gravitySmallEL[@]} ${_hL[@]})
input=(${_hN[@]} ${_kN[@]} ${_kgN[@]})
lookAhead=(${gravityLN[@]} ${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# △左が左寄り、均等な小文字、中間の文字、EFKPÞCc で 右が中間の大文字、左寄り、右寄り、均等な文字の場合 L 以外の左寄り、均等、Vの字 左に移動
backtrack=(${gravitySmallLL[@]} ${gravitySmallEL[@]} ${gravityML[@]} \
${_EL[@]} ${_FL[@]} ${_KL[@]} ${_PL[@]} ${_THL[@]} ${_CL[@]} ${_cL[@]})
input=(${outLgravityLN[@]} ${gravityEN[@]} ${gravityVN[@]})
lookAhead=(${gravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} ${gravityCapitalML[@]} \
${gravityLN[@]} ${gravityCapitalEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が左寄り、均等な小文字、中間の文字、EFKPÞCc で 右が均等、中間の文字の場合 均等な文字、右が丸い文字 左に移動
backtrack=(${gravitySmallLL[@]} ${gravitySmallEL[@]} ${gravityML[@]} \
${_EL[@]} ${_FL[@]} ${_KL[@]} ${_PL[@]} ${_THL[@]} ${_CL[@]} ${_cL[@]})
input=(${gravityEN[@]} \
${circleRN[@]})
lookAhead=(${gravitySmallML[@]} \
${gravitySmallEN[@]})
 #lookAhead=(${gravityML[@]} \
 #${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が、右が丸い大文字、R で 右が左寄り、右寄り、均等、中間の文字の場合 L 以外の左寄り、均等、Vの字 左に移動
backtrack=(${_RL[@]} \
${circleCapitalRL[@]} ${circleCapitalCL[@]})
input=(${outLgravityLN[@]} ${gravityEN[@]} ${gravityVN[@]})
lookAhead=(${gravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} ${gravityML[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が、右が丸い大文字、R で 右が左寄り、均等な文字で その右が左寄り、均等な文字の場合 L 以外の左寄り、均等な文字 左に移動
backtrack1=("")
backtrack=(${_RL[@]} \
${circleCapitalRL[@]} ${circleCapitalCL[@]})
input=(${outLgravityLN[@]} ${gravityEN[@]})
lookAhead=(${gravityLN[@]} ${gravityEN[@]})
lookAhead1=(${gravityLN[@]} ${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"

# △左が右寄りの小文字で 右が中間の大文字、左寄り、右寄り、均等な文字の場合 均等、丸い小文字、Vの字 左に移動
backtrack=(${outcgravitySmallRL[@]})
 #backtrack=(${gravitySmallRL[@]})
input=(${gravitySmallEN[@]} ${gravityVN[@]} \
${circleSmallCN[@]})
lookAhead=(${gravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} ${gravityCapitalML[@]} \
${gravityLN[@]} ${gravityCapitalEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が右寄り、均等な文字で 右が左寄りの文字、右寄り、均等、中間の大文字の場合 Vの字、丸い大文字、右が丸い文字 左に移動
backtrack=(${outcgravitySmallRL[@]} ${outOQgravityCapitalEL[@]} ${_GL[@]})
 #backtrack=(${gravityRL[@]} ${gravityEL[@]})
input=(${gravityVN[@]} \
${circleRN[@]} ${circleCapitalCN[@]})
lookAhead=(${gravityLL[@]} ${gravityCapitalRL[@]} ${gravityCapitalEL[@]} ${gravityCapitalML[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が左寄り、中間の文字、均等な小文字で 右が左寄り、右寄り、均等、左が丸い文字の場合 右寄り、中間の文字 左に移動
backtrack=(${outBDgravityLL[@]} ${gravitySmallEL[@]} ${gravityML[@]})
 #backtrack=(${gravityLL[@]} ${gravityEL[@]} ${gravityML[@]})
input=(${gravityRN[@]} ${gravityMN[@]})
lookAhead=(${gravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} \
${circleCL[@]} \
${gravityLN[@]} ${outcgravityRN[@]} ${gravityCapitalEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が右寄りの小文字で 右が左寄り、右寄り、均等、左が丸い文字の場合 右寄り、eo 以外の中間の文字 左に移動
backtrack=(${gravitySmallRL[@]})
input=(${gravityRN[@]} ${outeogravityMN[@]})
lookAhead=(${gravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} \
${circleCL[@]} \
${gravityLN[@]} ${outcgravityRN[@]} ${gravityCapitalEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が BD 以外の左寄り、中間の文字で 右が右寄り、均等、丸い文字の場合 右寄り、均等な小文字 左に移動
backtrack=(${outBDgravityLL[@]} ${gravityML[@]})
input=(${gravityRN[@]} ${gravitySmallEN[@]})
lookAhead=(${gravityRN[@]} ${gravityEN[@]} \
${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が中間の文字、c で 右が c 以外の左が丸い小文字の場合 h 左に移動
backtrack=(${gravityML[@]} ${_cL[@]})
input=(${_hN[@]})
lookAhead=(${_dN[@]} ${_gN[@]} ${_qN[@]} \
${circleSmallCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が BD 以外の左寄り、中間の文字で 右が中間の大文字の場合 右寄りの文字 左に移動
backtrack=(${outBDgravityLL[@]} ${gravityML[@]})
input=(${gravityRN[@]})
lookAhead=(${gravityCapitalMN[@]})
 #lookAhead=(${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が均等な小文字で 右が均等、丸い文字の場合 右寄り、丸い小文字 左に移動
backtrack=(${gravitySmallEL[@]})
input=(${circleSmallCN[@]} ${gravityRN[@]})
lookAhead=(${gravitySmallEN[@]} \
${circleSmallCN[@]})
 #lookAhead=(${gravityEN[@]} \
 #${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が右寄りの小文字で 右が均等、左が丸い文字の場合 右寄りの文字 左に移動
backtrack=(${gravitySmallRL[@]})
input=(${gravityRN[@]})
lookAhead=(${gravitySmallEN[@]} \
${circleSmallCN[@]} ${_cN[@]})
 #lookAhead=(${gravityEN[@]} \
 #${circleLN[@]} ${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が、BD 以外の左寄りの文字、中間の小文字で 右が右寄り、丸い文字の場合 丸い小文字 左に移動
backtrack=(${outBDgravityLL[@]} ${gravitySmallML[@]})
input=(${circleSmallCN[@]})
lookAhead=(${circleSmallCN[@]} ${_cN[@]})
 #lookAhead=(${gravityRN[@]} \
 #${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ---

# △左が EFKLXkĸxz で 右が左寄り、c 以外の右寄り、均等、左が丸い、Ww 以外の幅広の文字の場合 右寄り、均等、中間の文字 左に移動
backtrack=(${_EL[@]} ${_FL[@]} ${_KL[@]} ${_LL[@]} ${_XL[@]} ${_kL[@]} ${_kgL[@]} ${_xL[@]} ${_zL[@]} \
${_EN[@]} ${_FN[@]} ${_KN[@]} ${_LN[@]} ${_XN[@]} ${_kN[@]} ${_kgN[@]} ${_xN[@]} ${_zN[@]})
input=(${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
lookAhead=(${gravityLN[@]} ${outcgravityRN[@]} ${gravityEN[@]} \
${gravityWR[@]} \
${circleCN[@]})
 #lookAhead=(${gravityLN[@]} ${outcgravityRN[@]} ${gravityEN[@]} \
 #${outWwgravityWR[@]} \
 #${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が Vの大文字、狭い文字、EFKLX で 右が左寄り、c 以外の右寄り、均等、丸い文字の場合 右寄り、中間の文字、均等、Vの小文字、h 左に移動
backtrack=(${gravityCapitalVN[@]} ${gravityCN[@]} ${_EN[@]} ${_FN[@]} ${_KN[@]} ${_LN[@]} ${_XN[@]})
input=(${gravityRN[@]} ${gravitySmallEN[@]} ${gravityMN[@]} ${gravitySmallVN[@]} ${_hN[@]})
lookAhead=(${gravityLL[@]} ${outcgravityRL[@]} ${gravityEL[@]} \
${circleCL[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が Vの小文字、狭い文字、hkĸsxz で 右が左寄り、均等な文字の場合 c 以外の右寄り、均等、中間、y 以外の Vの字 左に移動
backtrack=(${gravitySmallVN[@]} ${gravityCN[@]} ${_hN[@]} ${_kN[@]} ${_kgN[@]} ${_sN[@]} ${_xN[@]} ${_zN[@]})
input=(${outcgravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${outygravityVN[@]})
lookAhead=(${gravityLL[@]} ${gravityEL[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が Vの小文字、狭い文字、hkĸsxz で 右が c 以外の右寄り、均等、丸い文字の場合 右寄り、均等、中間、y 以外の Vの字、h 左に移動
backtrack=(${gravitySmallVN[@]} ${gravityCN[@]} ${_hN[@]} ${_kN[@]} ${_kgN[@]} ${_sN[@]} ${_xN[@]} ${_zN[@]})
input=(${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${outygravityVN[@]} ${_hN[@]})
lookAhead=(${outcgravityRL[@]} ${gravityEL[@]} \
${circleCL[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が Vの小文字、狭い文字、hkĸsxz で 右が右寄り、均等な大文字、丸い文字、dgq の場合 L 以外の左寄りの文字 左に移動
backtrack=(${gravitySmallVN[@]} ${_hN[@]} ${_kN[@]} ${_kgN[@]} ${_sN[@]} ${_xN[@]} ${_zN[@]})
 #backtrack=(${gravitySmallVN[@]} ${gravityCN[@]} ${_hN[@]} ${_kN[@]} ${_kgN[@]} ${_sN[@]} ${_xN[@]} ${_zN[@]})
input=(${outLgravityLN[@]})
lookAhead=(${gravityCapitalRL[@]} ${gravityCapitalEL[@]} ${_dL[@]} ${_gL[@]} ${_qL[@]} \
${circleCL[@]})
chain_context 0 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が、L 以外の左寄り、中間の文字、an で 右が左寄り、ac 以外の右寄り、均等、ASs 以外の中間、Vの字の場合 Vの字 左に移動
backtrack=(${outLgravityLN[@]} ${gravityMN[@]} ${_aN[@]} ${_nN[@]})
input=(${gravityVN[@]})
lookAhead=(${gravityLL[@]} ${gravityCapitalRL[@]} ${gravityEL[@]} ${gravityVL[@]} \
${_XL[@]} ${_ZL[@]} ${_dL[@]} ${_gL[@]} ${_qL[@]} ${_xL[@]} ${_zL[@]} \
${circleSmallCL[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ---

# △左が EKPXhkĸsxz で 右が左寄り、右寄り、均等、丸い文字の場合 a 左に移動
backtrack=(${_EN[@]} ${_KN[@]} ${_PN[@]} ${_XN[@]} ${_hN[@]} ${_kN[@]} ${_sN[@]} ${_xN[@]} ${_zN[@]} ${_kgN[@]})
input=(${_aN[@]})
lookAhead=(${gravityRL[@]} \
${circleCL[@]} \
${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} \
${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が P で 右が左寄り、右寄り、均等、中間の文字の場合 左上が開いている文字 左に移動
backtrack=(${_PN[@]})
input=(${highSpaceSmallLN[@]} ${highSpaceSmallCN[@]})
lookAhead=(${gravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} ${gravityML[@]} \
${gravityLN[@]} ${gravityCapitalEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# △左が狭い小文字で 右が Vの字の場合 L 以外の左寄り、右寄り、均等、中間、Vの字 左に移動
backtrack=(${gravitySmallCL[@]} \
${gravitySmallCN[@]})
input=(${outLgravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
lookAhead=(${gravityVL[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 右側が右に移動したため開いた間隔を詰める処理 ----------------------------------------

# 左が Ww で 右が Vの字、狭い文字、s の場合 右寄り、中間の文字 右に移動
 #backtrack=(${_WL[@]} ${_wL[@]})
 #input=(${gravityRN[@]} ${gravityMN[@]})
 #lookAhead=(${gravityVR[@]} ${gravityCR[@]} ${_sR[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# △左が Vの大文字、狭い大文字で 右が狭い小文字、sv の場合 右寄り、均等な小文字 右に移動
backtrack=(${gravityCapitalVR[@]} ${gravityCapitalCR[@]})
input=(${gravitySmallRN[@]} ${gravitySmallEN[@]})
lookAhead=(${gravitySmallCR[@]} ${_sR[@]} ${_vR[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 左が左寄り、中間、Vの字、狭い文字の場合 左寄り、右寄り、幅広、均等、丸い文字 元に戻らない (等間隔に並べる処理と統合)
 #backtrack=(${gravityLL[@]} ${gravityML[@]} ${gravityVL[@]} ${gravityCL[@]} \
 #${gravityCR[@]} \
 #${gravityVN[@]} ${gravityCN[@]} ${_LN[@]})
 #input=(${gravityLL[@]} ${gravityRL[@]} ${gravityWL[@]} ${gravityEL[@]} \
 #${circleCL[@]})
 #lookAhead=("")
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# △左が EFKXkĸxz で 右が左寄りの場合 左が丸い文字、丸い大文字 元に戻らない
backtrack=(${_EN[@]} ${_FN[@]} ${_KN[@]} ${_XN[@]} ${_kN[@]} ${_xN[@]} ${_zN[@]} ${_kgN[@]})
input=(${circleLL[@]} ${circleCapitalCL[@]})
lookAhead=(${gravityLR[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# △左が左寄り、右寄り、均等、中間の文字で 右が左寄り、均等な文字の場合 左寄り、右寄り、均等、中間の文字 元に戻る
backtrack=(${gravityRL[@]} ${gravityEL[@]} \
${gravityLN[@]} ${gravityMN[@]})
input=(${gravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} ${gravityML[@]})
lookAhead=(${gravityLR[@]} ${gravityER[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# △左が、右が丸い文字で 右が幅広の文字の場合 右が丸い文字 元に戻る
backtrack=(${circleRN[@]} ${circleCN[@]})
input=(${circleRL[@]} ${circleCL[@]})
lookAhead=(${gravityWR[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# △左が右寄りの文字、均等な大文字で 右が幅広の文字の場合 左寄りの文字、均等な大文字 元に戻る
backtrack=(${gravityRL[@]} ${gravityCapitalEL[@]})
input=(${gravityLL[@]} ${gravityCapitalEL[@]})
lookAhead=(${gravityWR[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# △左が狭い文字、L の場合 f 右に移動しない (次の処理とセット)
backtrack=(${gravityCL[@]} ${_LL[@]} \
${_LR[@]} ${_IR[@]} ${_fR[@]} ${_iR[@]} ${_lR[@]} ${_rR[@]} \
${gravityCN[@]} ${_LN[@]})
input=(${_fN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# △右が狭い文字の場合 f 右に移動
backtrack=("")
input=(${_fN[@]})
lookAhead=(${_iL[@]} ${_rL[@]} ${_tL[@]} \
${gravityCR[@]} \
${gravityCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 右側が右に移動しないため開いた間隔を詰める処理 ----------------------------------------

# △左が右寄り、均等、中間、右が丸い、Vの大文字で 右が右寄り、均等、中間、Vの小文字の場合 Vの字 右に移動
backtrack=(${gravityCapitalMR[@]} \
${gravityCapitalRN[@]} ${gravityCapitalEN[@]} ${gravityCapitalVN[@]} \
${circleCapitalRR[@]})
input=(${gravityVN[@]})
lookAhead=(${gravitySmallRN[@]} ${gravitySmallEN[@]} ${gravitySmallMN[@]} ${gravitySmallVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# △左が EFKPRÞ で 右が右寄り、均等、中間、Vの小文字の場合 Vの大文字 右に移動
backtrack=(${_ER[@]} ${_FR[@]} ${_KR[@]} ${_PR[@]} ${_RR[@]} ${_THR[@]})
input=(${gravityCapitalVN[@]})
lookAhead=(${gravitySmallRN[@]} ${gravitySmallEN[@]} ${gravitySmallMN[@]} ${gravitySmallVN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

fi
# 記号類 ++++++++++++++++++++++++++++++++++++++++

# |~: に関する処理 2回目 ----------------------------------------

# △右が |~: の場合 |~ 下に : 上に移動
backtrack=("")
input=(${_barN[@]} ${_tildeN[@]} ${_colonN[@]})
lookAhead=(${_barD[@]} ${_tildeD[@]} ${_colonU[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"

# < に関する処理 ----------------------------------------

# △右が -=|~ の場合 < 右に移動
backtrack=("")
input=(${_lessN[@]})
lookAhead=(${_barD[@]} ${_tildeD[@]} \
${_hyphenN[@]} ${_equalN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

# > に関する処理 ----------------------------------------

# △左が -=>|~ の場合 > 左に移動
backtrack=(${_greaterL[@]} \
${_barD[@]} ${_tildeD[@]} \
${_hyphenN[@]} ${_equalN[@]})
input=(${_greaterN[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"

# 括弧に関する処理の続き ----------------------------------------

class=(_parenright _bracketright _braceright)
for S in ${class[@]}; do
  # △△△元に戻る
  backtrack1=("")
  eval backtrack=(\${${S}N[@]})
  eval input=(\${${S}L[@]})
  eval lookAhead=(\${${S}L[@]})
  eval lookAhead1=(\${${S}L[@]})
  chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"

  # △△△元に戻る
  eval backtrack1=(\${${S}N[@]})
  eval backtrack=(\${${S}N[@]})
  eval input=(\${${S}L[@]})
  lookAhead=("")
  chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"
done

class=(_parenleft _bracketleft _braceleft)
for S in ${class[@]}; do
  # △△△元に戻る
  backtrack1=("")
  backtrack=("")
  eval input=(\${${S}R[@]})
  eval lookAhead=(\${${S}R[@]})
  eval lookAhead1=(\${${S}R[@]})
  eval lookAheadX=(\${${S}R[@]} \${${S}N[@]}); aheadMax="2"
  chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

  # △△△元に戻る
  eval backtrack=(\${${S}N[@]})
  eval input=(\${${S}R[@]})
  eval lookAhead=(\${${S}R[@]} \${${S}N[@]})
  chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"
done

#CALT1
#<< "#CALT2" # アルファベット・記号 ||||||||||||||||||||||||||||||||||||||||

pre_add_lookup

# アルファベット ++++++++++++++++++++++++++++++++++++++++
if [ "${symbol_only_flag}" = "false" ]; then

# 移動しない、元に戻らない処理 ----------------------------------------

# ■右が、左が丸い文字、a の場合 EFKXkĸxz 左に移動しない
backtrack=("")
input=(${_EN[@]} ${_FN[@]} ${_KN[@]} ${_XN[@]} ${_kN[@]} ${_xN[@]} ${_zN[@]} ${_kgN[@]})
lookAhead=(${circleSmallLL[@]} ${circleSmallCL[@]} ${_aL[@]} \
${circleLN[@]} ${circleCN[@]} ${_aN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# □右が、左上が開いている文字、A の場合 FP 左に移動しない
backtrack=("")
input=(${_FN[@]} ${_PN[@]})
lookAhead=(${highSpaceLL[@]} ${highSpaceCL[@]} ${_AL[@]} \
${highSpaceLN[@]} ${highSpaceCN[@]} ${_AN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# □右が、左下が開いている文字、Ww の場合 A 左に移動しない
backtrack=("")
input=(${_AN[@]})
lookAhead=(${lowSpaceLL[@]} ${lowSpaceCL[@]} \
${lowSpaceLN[@]} ${lowSpaceCN[@]})
 #lookAhead=(${lowSpaceLL[@]} ${lowSpaceCL[@]} ${_WL[@]} ${_wL[@]} \
 #${lowSpaceLN[@]} ${lowSpaceCN[@]} ${_WN[@]} ${_wN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# □右が、左が丸い文字、a の場合 EFKXkĸxz 元に戻らない
backtrack=("")
input=(${_ER[@]} ${_FR[@]} ${_KR[@]} ${_XR[@]} ${_kR[@]} ${_xR[@]} ${_zR[@]} ${_kgR[@]})
lookAhead=(${circleLR[@]} ${circleCR[@]} ${_aR[@]} \
${circleSmallLN[@]} ${circleSmallCN[@]} ${_aN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# □右が、左上が開いている文字、A の場合 FP 元に戻らない
backtrack=("")
input=(${_FR[@]} ${_PR[@]})
lookAhead=(${highSpaceLL[@]} ${highSpaceCL[@]} ${_AL[@]} \
${highSpaceLN[@]} ${highSpaceCN[@]} ${_AN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# □右が、左下が開いている文字、Ww の場合 A 元に戻らない
backtrack=("")
input=(${_AR[@]})
lookAhead=(${lowSpaceLL[@]} ${lowSpaceCL[@]} \
${lowSpaceLN[@]} ${lowSpaceCN[@]})
 #lookAhead=(${lowSpaceLL[@]} ${lowSpaceCL[@]} ${_WL[@]} ${_wL[@]} \
 #${lowSpaceLN[@]} ${lowSpaceCN[@]} ${_WN[@]} ${_wN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# 右に幅広が来た時に左側を詰める処理の続き ----------------------------------------

# □左が幅広、均等、右が丸い文字で 右が右寄り、均等、右が丸い文字の場合 均等、右寄り、丸い文字 元に戻る 2回目
backtrack=(${gravityWL[@]} \
${gravityER[@]} \
${circleRR[@]} ${circleCR[@]})
input=(${gravityER[@]} ${gravityRR[@]} \
${circleCR[@]})
lookAhead=(${gravityRN[@]} ${gravityEN[@]} \
${circleRN[@]} ${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# ---

# □左が均等な文字で 右が幅広の文字の場合 左が丸い文字 左に移動
backtrack=(${gravityEL[@]} \
${gravitySmallEN[@]})
input=(${circleLN[@]} ${circleCN[@]})
lookAhead=(${gravityWL[@]} \
${gravityWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が均等、右が丸い大文字の場合 右寄り、中間の文字 左に移動しない
backtrack=(${gravityCapitalEL[@]} \
${circleCapitalRL[@]})
input=(${gravityRN[@]} ${gravityMN[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# □左が、左が丸い文字で 右が、右寄り、中間、Vの字の場合 幅広の文字 元に戻る
backtrack=(${circleLL[@]} ${circleCL[@]})
input=(${gravityWR[@]})
lookAhead=(${gravityLR[@]} ${gravityRR[@]} ${gravityER[@]} ${gravityMR[@]} ${gravityVR[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# ---

# □左が中間の文字、Ww で 右が左寄りの文字、右寄り、均等な大文字の場合 右寄り、中間の小文字 元に戻る
backtrack=(${gravityMR[@]})
 #backtrack=(${gravityMR[@]} \
 #${_WN[@]} ${_wN[@]})
input=(${gravitySmallRR[@]} ${gravitySmallMR[@]})
lookAhead=(${gravityLN[@]} ${gravityCapitalRN[@]} ${gravityCapitalEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# ---

# □左が左寄り、均等、中間、Vの字で 右が左寄り、幅広、均等な文字の場合 幅広の文字 左に移動 (右側が元に戻った処理と統合)
backtrack=(${gravityLL[@]} ${gravityEL[@]} ${gravityML[@]} ${gravityVL[@]})
input=(${gravityWN[@]})
lookAhead=(${gravityWL[@]} \
${gravityWR[@]} \
${gravityLN[@]} ${gravityWN[@]} ${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ---

# □右が右寄り、均等、中間の小文字の場合 L 以外の左寄り、中間の文字 元に戻る
backtrack=("")
input=(${outLgravityLR[@]} ${gravityMR[@]})
lookAhead=(${gravityRL[@]} ${gravityEL[@]} ${gravityML[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# □左が右寄り、幅広、均等な文字の場合 左寄りの文字 元に戻らない
backtrack=(${gravityRR[@]} ${gravityWR[@]} ${gravityER[@]} \
${gravityRN[@]} ${gravityWN[@]} ${gravityCapitalEN[@]})
input=(${gravityLR[@]})
lookAhead=("")
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# □右が左寄りの小文字の場合 L 以外の左寄りの文字 元に戻る
backtrack=("")
input=(${outLgravityLR[@]})
lookAhead=(${gravityLN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# □左が co で 右が Ww 以外の幅広の文字の場合 ce 左に移動
backtrack=(${_cN[@]} ${_oN[@]})
input=(${_cN[@]} ${_eN[@]})
lookAhead=(${gravityWR[@]})
 #lookAhead=(${outWwgravityWR[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 右側が左に寄って詰まった間隔を整える処理 ----------------------------------------

# □左が狭い文字で 右が rt の場合 右寄りの小文字 左に移動
backtrack=(${gravityCL[@]} \
${gravityCR[@]} \
${gravityCN[@]})
input=(${gravitySmallRN[@]})
lookAhead=(${_rL[@]} ${_tL[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が左寄り、右寄り、均等、中間、Vの字で 右が幅広の文字の場合 Iil 左に移動
backtrack=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
input=(${_IN[@]} ${_iN[@]} ${_lN[@]})
lookAhead=(${gravityWL[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が左寄り、均等、中間の小文字、EFKPÞX で 右が左寄りの文字、右寄り、均等な大文字の場合 Iil 左に移動
backtrack=(${gravitySmallLR[@]} ${gravitySmallMR[@]} \
${_KR[@]} ${_PR[@]} ${_THR[@]} ${_XR[@]})
input=(${_IN[@]} ${_iN[@]} ${_lN[@]})
lookAhead=(${gravityLL[@]} ${gravityCapitalRL[@]} ${gravityCapitalEL[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が左寄り、均等、中間の小文字、EFKPÞX で 右が左寄りの文字、右寄り、均等な大文字の場合 il 左に移動
backtrack=(${gravitySmallER[@]} \
${_ER[@]} ${_FR[@]})
input=(${_iN[@]} ${_lN[@]})
lookAhead=(${gravityLL[@]} ${gravityCapitalRL[@]} ${gravityCapitalEL[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が Vの大文字で 右が左寄りの文字、右寄り、均等な大文字の場合 i 左に移動
backtrack=(${gravityCapitalVR[@]})
input=(${_iN[@]})
lookAhead=(${gravityLL[@]} ${gravityCapitalRL[@]} ${gravityCapitalEL[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が左寄り、均等、中間、Vの小文字、ac で 右が狭い文字の場合 t 元に戻る
backtrack=(${gravitySmallLR[@]} ${gravitySmallER[@]} ${gravitySmallMR[@]} ${gravitySmallVR[@]} ${_aR[@]} ${_cR[@]})
input=(${_tR[@]})
lookAhead=(${gravityCL[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# □左が左寄り、均等、中間、Vの小文字、ac で 右が左寄り、右寄り、均等、中間の文字の場合 t 左に移動
backtrack=(${gravitySmallLR[@]} ${gravitySmallER[@]} ${gravitySmallMR[@]} ${gravitySmallVR[@]} ${_aR[@]} ${_cR[@]})
input=(${_tN[@]})
lookAhead=(${gravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} ${gravityML[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が Ifil で 右が j 以外の狭い文字の場合 t 左に移動
backtrack=(${_IR[@]} ${_fR[@]} ${_iR[@]} ${_lR[@]})
input=(${_tN[@]})
lookAhead=(${outjgravityCL[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 右側が元に戻って詰まった間隔を整える処理 ----------------------------------------

# 左側が左に移動したため開いた間隔を詰める処理 ----------------------------------------

# □左が幅広の文字で 右が左寄り、右寄り、幅広、均等、丸文字の場合 左寄りの小文字 元に戻る
backtrack=(${gravityWL[@]})
input=(${gravitySmallLR[@]})
lookAhead=(${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} \
${circleCN[@]})
 #lookAhead=(${gravityLN[@]} ${gravityRN[@]} ${gravityWN[@]} ${gravityEN[@]} \
 #${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が w で 右が右寄り、丸い小文字の場合 均等な小文字、h 元に戻る
 #backtrack=(${_wN[@]})
 # #backtrack=(${_wL[@]} \
 # #${_wN[@]})
 #input=(${gravitySmallER[@]})
 # #input=(${gravitySmallER[@]} ${_hR[@]})
 #lookAhead=(${gravitySmallRN[@]} \
 #${circleSmallCN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# □左が幅広の文字で 右が幅広の文字の場合 右寄りの小文字 左に移動
backtrack=(${gravityWL[@]})
input=(${gravitySmallRN[@]})
lookAhead=(${gravityWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 左が Ww で 右が左寄りの文字、右寄り、均等な大文字の場合 右寄りの小文字、中間の文字 左に移動
 #backtrack=(${_WL[@]} ${_wL[@]})
 #input=(${gravitySmallRN[@]} ${gravityMN[@]})
 #lookAhead=(${gravityLL[@]} ${gravityCapitalEL[@]} ${gravityCapitalRL[@]} \
 #${gravityLN[@]} ${gravityCapitalEN[@]} ${gravityCapitalRN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が幅広の小文字で 右が幅広の文字の場合 Vの字 元に戻る
backtrack=(${gravitySmallWR[@]} \
${gravitySmallWN[@]})
input=(${gravityVR[@]})
lookAhead=(${gravityWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# □左が幅広の文字、OQ 以外の均等な大文字で 右が左寄り、OQ 以外の均等な大文字、M の場合 幅広、均等な大文字、I 元に戻る
backtrack=(${gravityWN[@]} ${outOQgravityCapitalEN[@]})
input=(${gravityCapitalWR[@]} ${gravityCapitalER[@]} ${_IR[@]})
lookAhead=(${gravityCapitalLN[@]} ${outOQgravityCapitalEN[@]} ${_MN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 左が左寄り、均等、中間、Vの字で 右が左寄り、均等な文字の場合 幅広の文字 左に移動 (右に幅広の処理と統合)
 #backtrack=(${gravityLL[@]} ${gravityEL[@]} ${gravityML[@]} ${gravityVL[@]})
 #input=(${gravityWN[@]})
 #lookAhead=(${gravityLN[@]} ${gravityEN[@]})
 #chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# 右側が右に移動したため開いた間隔を詰める処理 ----------------------------------------

# □左が右寄り、均等、Vの小文字で 右が幅広の小文字の場合 f 元に戻る
backtrack=(${gravitySmallRR[@]} ${gravitySmallER[@]} ${gravitySmallVR[@]})
input=(${_fL[@]})
lookAhead=(${gravitySmallWL[@]} \
${gravitySmallWN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# □左が t で 右が jl の場合 Ii 右に移動
backtrack=(${_tR[@]})
input=(${_IN[@]} ${_iN[@]})
lookAhead=(${_jR[@]} ${_lR[@]} \
${_jN[@]} ${_lN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# □左が右寄り、均等な文字で 右が均等な文字の場合 e 右に移動
backtrack=(${gravityRN[@]} ${gravityEN[@]})
input=(${_eN[@]})
lookAhead=(${gravityER[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# □左が Cc 以外の右寄りの文字、均等な大文字で 右が OQUhkĸu の場合 AX 右に移動
backtrack=(${outcgravitySmallRN[@]} ${gravityCapitalEN[@]} ${_GN[@]})
input=(${_AN[@]} ${_XN[@]})
lookAhead=(${_OR[@]} ${_QR[@]} ${_UR[@]} ${_hR[@]} ${_kR[@]} ${_kgR[@]} ${_uR[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# □左が右寄りの文字、左寄り、中間の小文字、Vの字で 右が Vの字の場合 acsxz 右に移動
backtrack=(${gravitySmallLR[@]} ${gravityRR[@]} ${gravitySmallMR[@]} ${gravityVR[@]})
input=(${_aN[@]} ${_cN[@]} ${_sN[@]} ${_xN[@]} ${_zN[@]})
lookAhead=(${gravityVR[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# □左が Ww 以外の幅広の文字で 右が Ww の場合 左寄り、右寄り、均等、中間の文字 右に移動
backtrack=(${gravityWN[@]})
 #backtrack=(${outWwgravityWN[@]})
input=(${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
lookAhead=(${_WR[@]} ${_wR[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# □左が Ifilr で 右が IJijl の場合 Cc 元に戻る
backtrack=(${_IN[@]} ${_fN[@]} ${_iN[@]} ${_lN[@]} ${_rN[@]})
input=(${_CL[@]} ${_cL[@]})
lookAhead=(${_IR[@]} ${_JR[@]} ${_iR[@]} ${_jR[@]} ${_lR[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右側が左に寄った、または元に戻って詰まった間隔を整える処理 2回目 ----------------------------------------

# □左が EFKLXkĸxz で 右が左寄り、右寄り、均等、中間の文字の場合 右寄り、均等、中間の文字、h 左に移動
backtrack=(${_ER[@]} ${_FR[@]} ${_KR[@]} ${_LR[@]} ${_XR[@]} ${_kR[@]} ${_xR[@]} ${_zR[@]} ${_kgR[@]})
input=(${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${_hN[@]})
lookAhead=(${gravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} ${gravityML[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が Shs で 右が左寄り、右寄り、均等、中間の文字の場合 右寄り、中間の文字 左に移動
backtrack=(${_SR[@]} ${_hR[@]} ${_sR[@]})
input=(${gravityRN[@]} ${gravityMN[@]})
lookAhead=(${gravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} ${gravityML[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ---

# □左が左寄り、中間の文字で 右が左寄りの文字の場合 EFKkĸ 左に移動しない
backtrack=(${gravityLL[@]} ${gravityML[@]})
input=(${_EN[@]} ${_FN[@]} ${_KN[@]} ${_kN[@]} ${_kgN[@]})
lookAhead=(${gravityLN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# □左が均等な小文字、h で 右が左寄り、均等な文字の場合 hkĸ 左に移動しない
backtrack=(${gravitySmallEL[@]} ${_hL[@]})
input=(${_hN[@]} ${_kN[@]} ${_kgN[@]})
lookAhead=(${gravityLN[@]} ${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# □左が左寄り、均等な小文字、中間の文字、EFKPÞCc で 右が中間の大文字、左寄り、右寄り、均等な文字の場合 L 以外の左寄り、均等、Vの字 左に移動
backtrack=(${gravitySmallLL[@]} ${gravitySmallEL[@]} ${gravityML[@]} \
${_EL[@]} ${_FL[@]} ${_KL[@]} ${_PL[@]} ${_THL[@]} ${_CL[@]} ${_cL[@]})
input=(${outLgravityLN[@]} ${gravityEN[@]} ${gravityVN[@]})
lookAhead=(${gravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} ${gravityCapitalML[@]} \
${gravityLN[@]} ${gravityCapitalEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が左寄り、均等な小文字、中間の文字、EFKPÞCc で 右が均等、中間の文字の場合 均等な文字、右が丸い文字 左に移動
backtrack=(${gravitySmallLL[@]} ${gravitySmallEL[@]} ${gravityML[@]} \
${_EL[@]} ${_FL[@]} ${_KL[@]} ${_PL[@]} ${_THL[@]} ${_CL[@]} ${_cL[@]})
input=(${gravityEN[@]} \
${circleRN[@]})
lookAhead=(${gravitySmallML[@]} \
${gravitySmallEN[@]})
 #lookAhead=(${gravityML[@]} \
 #${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が、右が丸い大文字、R で 右が左寄り、右寄り、均等、中間の文字の場合 L 以外の左寄り、均等、Vの字 左に移動
backtrack=(${_RL[@]} \
${circleCapitalRL[@]} ${circleCapitalCL[@]})
input=(${outLgravityLN[@]} ${gravityEN[@]} ${gravityVN[@]})
lookAhead=(${gravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} ${gravityML[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が、右が丸い大文字、R で 右が左寄り、均等な文字で その右が左寄り、均等な文字の場合 L 以外の左寄り、均等な文字 左に移動
backtrack1=("")
backtrack=(${_RL[@]} \
${circleCapitalRL[@]} ${circleCapitalCL[@]})
input=(${outLgravityLN[@]} ${gravityEN[@]})
lookAhead=(${gravityLN[@]} ${gravityEN[@]})
lookAhead1=(${gravityLN[@]} ${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}" "${backtrack1[*]}" "${lookAhead1[*]}"

# □左が右寄りの小文字で 右が中間の大文字、左寄り、右寄り、均等な文字の場合 均等、丸い小文字、Vの字 左に移動
backtrack=(${outcgravitySmallRL[@]})
 #backtrack=(${gravitySmallRL[@]})
input=(${gravitySmallEN[@]} ${gravityVN[@]} \
${circleSmallCN[@]})
lookAhead=(${gravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} ${gravityCapitalML[@]} \
${gravityLN[@]} ${gravityCapitalEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が右寄り、均等な文字で 右が左寄りの文字、右寄り、均等、中間の大文字の場合 Vの字、丸い大文字、右が丸い文字 左に移動
backtrack=(${outcgravitySmallRL[@]} ${outOQgravityCapitalEL[@]} ${_GL[@]})
 #backtrack=(${gravityRL[@]} ${gravityEL[@]})
input=(${gravityVN[@]} \
${circleRN[@]} ${circleCapitalCN[@]})
lookAhead=(${gravityLL[@]} ${gravityCapitalRL[@]} ${gravityCapitalEL[@]} ${gravityCapitalML[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が左寄り、中間の文字、均等な小文字で 右が左寄り、右寄り、均等、左が丸い文字の場合 右寄り、中間の文字 左に移動
backtrack=(${outBDgravityLL[@]} ${gravitySmallEL[@]} ${gravityML[@]})
 #backtrack=(${gravityLL[@]} ${gravityEL[@]} ${gravityML[@]})
input=(${gravityRN[@]} ${gravityMN[@]})
lookAhead=(${gravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} \
${circleCL[@]} \
${gravityLN[@]} ${outcgravityRN[@]} ${gravityCapitalEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が右寄りの小文字で 右が左寄り、右寄り、均等、左が丸い文字の場合 右寄り、eo 以外の中間の文字 左に移動
backtrack=(${gravitySmallRL[@]})
input=(${gravityRN[@]} ${outeogravityMN[@]})
lookAhead=(${gravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} \
${circleCL[@]} \
${gravityLN[@]} ${outcgravityRN[@]} ${gravityCapitalEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が BD 以外の左寄り、中間の文字で 右が右寄り、均等、丸い文字の場合 右寄り、均等な小文字 左に移動
backtrack=(${outBDgravityLL[@]} ${gravityML[@]})
input=(${gravityRN[@]} ${gravitySmallEN[@]})
lookAhead=(${gravityRN[@]} ${gravityEN[@]} \
${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が中間の文字、c で 右が c 以外の左が丸い小文字の場合 h 左に移動
backtrack=(${gravityML[@]} ${_cL[@]})
input=(${_hN[@]})
lookAhead=(${_dN[@]} ${_gN[@]} ${_qN[@]} \
${circleSmallCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が BD 以外の左寄り、中間の文字で 右が中間の大文字の場合 右寄りの文字 左に移動
backtrack=(${outBDgravityLL[@]} ${gravityML[@]})
input=(${gravityRN[@]})
lookAhead=(${gravityCapitalMN[@]})
 #lookAhead=(${gravityMN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が均等な小文字で 右が均等、丸い文字の場合 右寄り、丸い小文字 左に移動
backtrack=(${gravitySmallEL[@]})
input=(${circleSmallCN[@]} ${gravityRN[@]})
lookAhead=(${gravitySmallEN[@]} \
${circleSmallCN[@]})
 #lookAhead=(${gravityEN[@]} \
 #${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が右寄りの小文字で 右が均等、左が丸い文字の場合 右寄りの文字 左に移動
backtrack=(${gravitySmallRL[@]})
input=(${gravityRN[@]})
lookAhead=(${gravitySmallEN[@]} \
${circleSmallCN[@]} ${_cN[@]})
 #lookAhead=(${gravityEN[@]} \
 #${circleLN[@]} ${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が、BD 以外の左寄りの文字、中間の小文字で 右が右寄り、丸い文字の場合 丸い小文字 左に移動
backtrack=(${outBDgravityLL[@]} ${gravitySmallML[@]})
input=(${circleSmallCN[@]})
lookAhead=(${circleSmallCN[@]} ${_cN[@]})
 #lookAhead=(${gravityRN[@]} \
 #${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ---

# □左が EFKLXkĸxz で 右が左寄り、c 以外の右寄り、均等、左が丸い、Ww 以外の幅広の文字の場合 右寄り、均等、中間の文字 左に移動
backtrack=(${_EL[@]} ${_FL[@]} ${_KL[@]} ${_LL[@]} ${_XL[@]} ${_kL[@]} ${_kgL[@]} ${_xL[@]} ${_zL[@]} \
${_EN[@]} ${_FN[@]} ${_KN[@]} ${_LN[@]} ${_XN[@]} ${_kN[@]} ${_kgN[@]} ${_xN[@]} ${_zN[@]})
input=(${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]})
lookAhead=(${gravityLN[@]} ${outcgravityRN[@]} ${gravityEN[@]} \
${gravityWR[@]} \
${circleCN[@]})
 #lookAhead=(${gravityLN[@]} ${outcgravityRN[@]} ${gravityEN[@]} \
 #${outWwgravityWR[@]} \
 #${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が Vの大文字、狭い文字、EFKLX で 右が左寄り、c 以外の右寄り、均等、丸い文字の場合 右寄り、中間の文字、均等、Vの小文字、h 左に移動
backtrack=(${gravityCapitalVN[@]} ${gravityCN[@]} ${_EN[@]} ${_FN[@]} ${_KN[@]} ${_LN[@]} ${_XN[@]})
input=(${gravityRN[@]} ${gravitySmallEN[@]} ${gravityMN[@]} ${gravitySmallVN[@]} ${_hN[@]})
lookAhead=(${gravityLL[@]} ${outcgravityRL[@]} ${gravityEL[@]} \
${circleCL[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が Vの小文字、狭い文字、hkĸsxz で 右が左寄り、均等な文字の場合 c 以外の右寄り、均等、中間、y 以外の Vの字 左に移動
backtrack=(${gravitySmallVN[@]} ${gravityCN[@]} ${_hN[@]} ${_kN[@]} ${_kgN[@]} ${_sN[@]} ${_xN[@]} ${_zN[@]})
input=(${outcgravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${outygravityVN[@]})
lookAhead=(${gravityLL[@]} ${gravityEL[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が Vの小文字、狭い文字、hkĸsxz で 右が c 以外の右寄り、均等、丸い文字の場合 右寄り、均等、中間、y 以外の Vの字、h 左に移動
backtrack=(${gravitySmallVN[@]} ${gravityCN[@]} ${_hN[@]} ${_kN[@]} ${_kgN[@]} ${_sN[@]} ${_xN[@]} ${_zN[@]})
input=(${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${outygravityVN[@]} ${_hN[@]})
lookAhead=(${outcgravityRL[@]} ${gravityEL[@]} \
${circleCL[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が Vの小文字、狭い文字、hkĸsxz で 右が右寄り、均等な大文字、丸い文字、dgq の場合 L 以外の左寄りの文字 左に移動
backtrack=(${gravitySmallVN[@]} ${gravityCN[@]} ${_hN[@]} ${_kN[@]} ${_kgN[@]} ${_sN[@]} ${_xN[@]} ${_zN[@]})
input=(${outLgravityLN[@]})
lookAhead=(${gravityCapitalRL[@]} ${gravityCapitalEL[@]} ${_dL[@]} ${_gL[@]} ${_qL[@]} \
${circleCL[@]})
chain_context 0 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が、L 以外の左寄り、中間の文字、an で 右が左寄り、ac 以外の右寄り、均等、ASs 以外の中間、Vの字の場合 Vの字 左に移動
backtrack=(${outLgravityLN[@]} ${gravityMN[@]} ${_aN[@]} ${_nN[@]})
input=(${gravityVN[@]})
lookAhead=(${gravityLL[@]} ${gravityCapitalRL[@]} ${gravityEL[@]} ${gravityVL[@]} \
${_XL[@]} ${_ZL[@]} ${_dL[@]} ${_gL[@]} ${_qL[@]} ${_xL[@]} ${_zL[@]} \
${circleSmallCL[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# ---

# □左が EKPXhkĸsxz で 右が左寄り、右寄り、均等、丸い文字の場合 a 左に移動
backtrack=(${_EN[@]} ${_KN[@]} ${_PN[@]} ${_XN[@]} ${_hN[@]} ${_kN[@]} ${_sN[@]} ${_xN[@]} ${_zN[@]} ${_kgN[@]})
input=(${_aN[@]})
lookAhead=(${gravityRL[@]} \
${circleCL[@]} \
${gravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} \
${circleCN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が P で 右が左寄り、右寄り、均等、中間の文字の場合 左上が開いている文字 左に移動
backtrack=(${_PN[@]})
input=(${highSpaceSmallLN[@]} ${highSpaceSmallCN[@]})
lookAhead=(${gravityLL[@]} ${gravityRL[@]} ${gravityEL[@]} ${gravityML[@]} \
${gravityLN[@]} ${gravityCapitalEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

# □左が狭い小文字で 右が Vの字の場合 L 以外の左寄り、右寄り、均等、中間、Vの字 左に移動
backtrack=(${gravitySmallCL[@]} \
${gravitySmallCN[@]})
input=(${outLgravityLN[@]} ${gravityRN[@]} ${gravityEN[@]} ${gravityMN[@]} ${gravityVN[@]})
lookAhead=(${gravityVL[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

fi
# 記号類 ++++++++++++++++++++++++++++++++++++++++

# |~: に関する処理 3回目 ----------------------------------------

# □右が |~: の場合 |~ 下に : 上に移動
backtrack=("")
input=(${_barN[@]} ${_tildeN[@]} ${_colonN[@]})
lookAhead=(${_barD[@]} ${_tildeD[@]} ${_colonU[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"

# < に関する処理 2回目----------------------------------------

# □右が < の場合 < 右に移動
backtrack=("")
input=(${_lessN[@]})
lookAhead=(${_lessR[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

#CALT2
#<< "#CALT3" # アルファベット・記号 ||||||||||||||||||||||||||||||||||||||||

pre_add_lookup

# アルファベット ++++++++++++++++++++++++++++++++++++++++
if [ "${symbol_only_flag}" = "false" ]; then

# 右側が左に寄って詰まった間隔を整える処理 ----------------------------------------

# ★左が EFKLXckĸxz で 右が IJfilrt の場合 右寄り、中間の文字 元に戻る
backtrack=(${_cL[@]} \
${_FR[@]} \
${_EN[@]} ${_FN[@]} ${_KN[@]} ${_LN[@]} ${_XN[@]} ${_kN[@]} ${_kgN[@]} ${_xN[@]} ${_zN[@]})
input=(${gravityRR[@]} ${gravityMR[@]})
lookAhead=(${_IL[@]} ${_JL[@]} ${_fL[@]} ${_iL[@]} ${_lL[@]} ${_rL[@]} ${_tL[@]} \
${_IN[@]} ${_JN[@]} ${_fN[@]} ${_iN[@]} ${_lN[@]} ${_rN[@]} ${_tN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右側が左に寄らず拡がった間隔を整える処理 ----------------------------------------

# ☆左が右寄り、均等な文字で 右が均等な文字の場合 e 元に戻る
backtrack=(${gravityRL[@]} ${gravityEL[@]})
input=(${_eL[@]})
lookAhead=(${gravityEN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 右側が右に移動したため開いた間隔を詰める処理 ----------------------------------------

# ☆左が Ww 以外の幅広の文字で 右が、左が丸い小文字の場合 丸い小文字 右に移動
backtrack=(${gravityWL[@]})
 #backtrack=(${outWwgravityWL[@]})
input=(${circleSmallCN[@]})
lookAhead=(${circleSmallLR[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexR}"

# 右側が左に寄った、または元に戻って詰まった間隔を整える処理 3回目 ----------------------------------------

# ☆左が EFKLXkĸxz で 右が左寄りの場合 均等な文字 左に移動
backtrack=(${_EL[@]} ${_FL[@]} ${_KL[@]} ${_LL[@]} ${_XL[@]} ${_kL[@]} ${_kgL[@]} ${_xL[@]} ${_zL[@]} \
${_EN[@]} ${_FN[@]} ${_KN[@]} ${_LN[@]} ${_XN[@]} ${_kN[@]} ${_kgN[@]} ${_xN[@]} ${_zN[@]})
input=(${gravityEN[@]})
lookAhead=(${gravityLN[@]})
chain_context 1 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexL}"

fi
# 記号類 ++++++++++++++++++++++++++++++++++++++++

# |~: に関する処理 4回目 ----------------------------------------

# ☆右が |~: の場合 |~ 下に : 上に移動
backtrack=("")
input=(${_barN[@]} ${_tildeN[@]} ${_colonN[@]})
lookAhead=(${_barD[@]} ${_tildeD[@]} ${_colonU[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"

# < に関する処理 3回目----------------------------------------

# ☆右が < の場合 < 右に移動
backtrack=("")
input=(${_lessN[@]})
lookAhead=(${_lessR[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

# *+-= に関する処理の始め ----------------------------------------

# ☆左が < で 右が > の場合 - 移動しない
backtrack=(${_lessR[@]})
input=(${_hyphenN[@]})
lookAhead=(${_greaterL[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ☆右が > の場合 - 右に移動
backtrack=("")
input=(${_hyphenN[@]})
lookAhead=(${_greaterL[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

# ☆左が < の場合 - 左に移動
backtrack=(${_lessR[@]})
input=(${_hyphenN[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"

# ☆左が、右が開いている文字、狭い文字で 右が、左が開いている文字、狭い文字の場合 *+-= 左に移動しない
backtrack=(${midSpaceRN[@]} ${midSpaceCN[@]} ${gravityCN[@]})
input=(${operatorHN[@]})
lookAhead=(${midSpaceLR[@]} ${midSpaceCR[@]} ${gravityCR[@]} \
${gravityCN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ☆左が、右が開いている文字、狭い文字の場合 *+-= 左に移動
backtrack=(${midSpaceRL[@]} ${midSpaceCL[@]} ${gravityCL[@]} \
${midSpaceRN[@]} ${midSpaceCN[@]} ${gravityCN[@]})
input=(${operatorHN[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"

# _ に関する処理の始め ----------------------------------------

# ☆左が、Vの字、狭い大文字、FPÞfijlr の場合 _ 左に移動
backtrack=(${gravityVL[@]} ${_IL[@]} ${_JL[@]} ${_FL[@]} ${_PL[@]} ${_THL[@]} \
${_fL[@]} ${_iL[@]} ${_jL[@]} ${_lL[@]} ${_rL[@]} \
${gravityVN[@]} ${_JN[@]} ${_FN[@]} ${_PN[@]} ${_THN[@]} \
${_fN[@]} ${_jN[@]} ${_rN[@]})
input=(${_underscoreN[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"

# ☆右が、左下が詰まっている文字の場合 _ 左に移動
backtrack=("")
input=(${_underscoreN[@]})
lookAhead=(${gravityLL[@]} ${outWwgravityWL[@]} ${_HL[@]} ${_NL[@]} ${_AL[@]} ${_XL[@]} ${_ZL[@]} \
${_gL[@]} ${_nL[@]} ${_xL[@]} ${_zL[@]} ${_yL[@]} ${_jL[@]} \
${gravityLN[@]} ${outWwgravityWN[@]} ${_HN[@]} ${_NN[@]} ${_AN[@]} ${_XN[@]} ${_ZN[@]} \
${_gN[@]} ${_nN[@]} ${_xN[@]} ${_zN[@]} ${_yN[@]} ${_jN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"

# reverse solidus に関する処理の始め ----------------------------------------

# ☆右が reverse solidus の場合 reverse solidus 右に移動
backtrack=("")
input=(${_rSolidusN[@]})
lookAhead=(${_rSolidusN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

# ☆左が、右上が開いている文字、狭い文字、A、reverse solidus の場合 reverse solidus 左に移動
backtrack=(${highSpaceRL[@]} ${highSpaceCL[@]} ${gravityCL[@]} ${_AL[@]} \
${highSpaceRN[@]} ${highSpaceCN[@]} ${gravityCN[@]} ${_AN[@]} \
${_rSolidusR[@]})
input=(${_rSolidusN[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"

# ☆左が、右上が開いている文字、狭い文字、A の場合 reverse solidus 左に移動しない
backtrack=(${highSpaceRR[@]} ${highSpaceCR[@]} ${gravityCR[@]} ${_AR[@]})
input=(${_rSolidusN[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# solidus に関する処理の始め ----------------------------------------

# ☆右が solidus の場合 solidus 右に移動
backtrack=("")
input=(${_solidusN[@]})
lookAhead=(${_solidusN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

# ☆左が、右下が開いている文字か W、solidus の場合 solidus 左に移動
backtrack=(${lowSpaceRL[@]} ${lowSpaceCL[@]} ${_WL[@]} \
${lowSpaceRN[@]} ${lowSpaceCN[@]} ${_WN[@]} \
${_solidusR[@]})
input=(${_solidusN[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"

# ☆左が、右下が開いている文字か W の場合 solidus 左に移動しない
backtrack=(${lowSpaceRR[@]} ${lowSpaceCR[@]} ${_WR[@]})
input=(${_solidusN[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# <> reverse solidus solidus に関する処理の始め ----------------------------------------

# ☆左が左寄り、右寄り、幅広、均等、中間の文字の場合 > reverse solidus solidus 右に移動
backtrack=(${gravityLR[@]} ${gravityRR[@]} ${gravityWR[@]} ${gravityER[@]} ${gravityMR[@]} \
${gravityWN[@]})
input=(${_greaterN[@]} ${_rSolidusN[@]} ${_solidusN[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

# ☆右が左寄り、右寄り、幅広、均等、中間の文字の場合 < 左に移動
backtrack=("")
input=(${_lessN[@]})
lookAhead=(${gravityLL[@]} ${gravityRL[@]} ${gravityWL[@]} ${gravityEL[@]} ${gravityML[@]} \
${gravityWN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"

# ., に関する処理の始め ----------------------------------------

# ☆左が >/ の場合 ., 移動しない
backtrack=(${_greaterL[@]} ${_solidusL[@]} \
${_greaterN[@]} ${_solidusN[@]})
input=(${_fullStopN[@]} ${_commaN[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ☆右が <\ の場合 ., 移動しない
backtrack=("")
input=(${_fullStopN[@]} ${_commaN[@]})
lookAhead=(${_lessR[@]} ${_rSolidusR[@]} \
${_lessN[@]} ${_rSolidusN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ?!.:,;|"'` に関する処理の始め ----------------------------------------

class=(_quotedbl _quote _grave)
for S in ${class[@]}; do
  # ☆☆☆左が "'` で、右が "'` の場合 "'` 右に移動
  eval backtrack=(\${${S}R[@]})
  eval input=(\${${S}N[@]})
  eval lookAhead=(\${${S}N[@]})
  chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

  # ☆☆☆左が "'` の場合 "'` 左に移動
  eval backtrack=(\${${S}L[@]} \
  \${${S}R[@]} \
  \${${S}N[@]})
  eval input=(\${${S}N[@]})
  lookAhead=("")
  chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"

  # ☆☆☆右が "'` の場合 "'` 右に移動
  backtrack=("")
  eval input=(\${${S}N[@]})
  eval lookAhead=(\${${S}N[@]})
  chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"
done

# ---

# ☆左が *+-=< の場合 ?!.:,;| 移動しない
backtrack=(${_hyphenL[@]} \
${_lessR[@]} \
${_lessN[@]} ${operatorHN[@]})
input=(${barDotCommaN[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ☆右が *+-=> の場合 ?!.:,;| 移動しない
backtrack=("")
input=(${barDotCommaN[@]})
lookAhead=(${_greaterL[@]} \
${_hyphenR[@]} \
${_greaterN[@]} ${operatorHN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ---

# ☆左が ?!.:,;| で、右が ?!.:,;| の場合 ?!.:,;| 右に移動
backtrack=(${barDotCommaR[@]})
input=(${barDotCommaN[@]})
lookAhead=(${barDotCommaN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

# ☆左が ?!.:,;| の場合 ?!.:,;| 左に移動
backtrack=(${barDotCommaL[@]} \
${barDotCommaR[@]} \
${barDotCommaN[@]})
input=(${barDotCommaN[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"

# ☆右が ?!.:,;| の場合 ?!.:,;| 右に移動
backtrack=("")
input=(${barDotCommaN[@]})
lookAhead=(${barDotCommaN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

#CALT3
#<< "#CALT4" # 記号 ||||||||||||||||||||||||||||||||||||||||

pre_add_lookup

# 記号類 ++++++++++++++++++++++++++++++++++++++++

# < に関する処理 4回目----------------------------------------

# ▼右が < の場合 < 右に移動
backtrack=("")
input=(${_lessN[@]})
lookAhead=(${_lessR[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

# *+-= に関する処理の続き ----------------------------------------

# ▽左が数字の場合 *+-= 右に移動しない
backtrack=(${figureN[@]})
input=(${operatorHN[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ▽右が、左が開いている文字、狭い文字の場合 *+-= 右に移動
backtrack=("")
input=(${operatorHN[@]})
lookAhead=(${midSpaceLR[@]} ${midSpaceCR[@]} ${gravityCR[@]} \
${midSpaceLN[@]} ${midSpaceCN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

# ▽左が、< の場合 - 元に戻らない
backtrack=(${_lessR[@]})
input=(${_hyphenL[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ▽左が、右が開いている文字、狭い文字で 右が、左が開いている文字、狭い文字の場合 *+-= 元に戻らない
backtrack=(${midSpaceRL[@]} ${midSpaceCL[@]} ${gravityCL[@]} \
${gravityCN[@]})
input=(${operatorHL[@]})
lookAhead=(${midSpaceLN[@]} ${midSpaceCN[@]} ${gravityCN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ▽右が、左が開いている文字、狭い文字、数字の場合 *+-= 元に戻る
backtrack=("")
input=(${operatorHL[@]})
lookAhead=(${midSpaceLR[@]} ${midSpaceCR[@]} ${gravityCR[@]} \
${midSpaceLN[@]} ${midSpaceCN[@]} ${gravityCN[@]} ${figureN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# _ に関する処理の続き ----------------------------------------

# ▽左が、数字、Iit_ の場合 _ 移動しない、元に戻る (この後の処理とセット)
backtrack=(${_IR[@]} ${_iR[@]} ${_tR[@]} \
${_tN[@]} \
${figureN[@]} ${_underscoreN[@]})
input=(${_underscoreL[@]} \
${_underscoreN[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# ▽右が Vの大文字、狭い小文字、Iv の場合 _ 右に移動
backtrack=("")
input=(${_underscoreN[@]})
lookAhead=(${gravityCapitalVR[@]} ${gravitySmallCR[@]} ${_IR[@]} ${_vR[@]} \
${gravityCapitalVN[@]} ${_vN[@]} ${_fN[@]} ${_lN[@]} ${_tN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

# ▽右が Vの大文字、狭い小文字、Iv の場合 _ 元に戻る
backtrack=("")
input=(${_underscoreL[@]})
lookAhead=(${gravityCapitalVR[@]} ${gravitySmallCR[@]} ${_IR[@]} ${_vR[@]} \
${gravityCapitalVN[@]} ${_vN[@]} ${_fN[@]} ${_lN[@]} ${_tN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# ▽右が、数字、JIi_ の場合 _ 移動しない、元に戻る (次の処理とセット)
backtrack=("")
input=(${_underscoreL[@]} \
${_underscoreN[@]})
lookAhead=(${_JL[@]} ${_IL[@]} ${_iL[@]} \
${_JN[@]} \
${figureN[@]} ${_underscoreN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# ▽左が、右下が詰まっている文字の場合 _ 右に移動
backtrack=(${outWwgravityWR[@]} ${_ER[@]} ${_KR[@]} ${_LR[@]} ${_RR[@]} ${_HR[@]} ${_NR[@]} ${_QR[@]} ${_AR[@]} ${_XR[@]} ${_ZR[@]} \
${outcgravitySmallRR[@]} ${_hR[@]} ${_kR[@]} ${_nR[@]} ${_uR[@]} ${_xR[@]} ${_zR[@]} \
${outWwgravityWN[@]} ${_EN[@]} ${_KN[@]} ${_LN[@]} ${_RN[@]} ${_HN[@]} ${_NN[@]} ${_QN[@]} ${_AN[@]} ${_XN[@]} ${_ZN[@]} \
${outcgravitySmallRN[@]} ${_hN[@]} ${_kN[@]} ${_nN[@]} ${_uN[@]} ${_xN[@]} ${_zN[@]})
input=(${_underscoreN[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

# ▽左が、右下が詰まっている文字の場合 _ 元に戻る
backtrack=(${outWwgravityWR[@]} ${_ER[@]} ${_KR[@]} ${_LR[@]} ${_RR[@]} ${_HR[@]} ${_NR[@]} ${_QR[@]} ${_AR[@]} ${_XR[@]} ${_ZR[@]} \
${outcgravitySmallRR[@]} ${_hR[@]} ${_kR[@]} ${_nR[@]} ${_uR[@]} ${_xR[@]} ${_zR[@]} \
${outWwgravityWN[@]} ${_EN[@]} ${_KN[@]} ${_LN[@]} ${_RN[@]} ${_HN[@]} ${_NN[@]} ${_QN[@]} ${_AN[@]} ${_XN[@]} ${_ZN[@]} \
${outcgravitySmallRN[@]} ${_hN[@]} ${_kN[@]} ${_nN[@]} ${_uN[@]} ${_xN[@]} ${_zN[@]})
input=(${_underscoreL[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# reverse solidus に関する処理の続き ----------------------------------------

# ▽左が reverse solidus で その左が reverse solidus の場合 reverse solidus 元に戻る
backtrack1=(${_rSolidusN[@]})
backtrack=(${_rSolidusN[@]})
input=(${_rSolidusL[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"

# ▽左が reverse solidus の場合 reverse solidus 元に戻らない
backtrack=(${_rSolidusR[@]} \
${_rSolidusN[@]})
input=(${_rSolidusL[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ▽右が reverse solidus で その右が reverse solidus の場合 reverse solidus 元に戻る
backtrack1=("")
backtrack=("")
input=(${_rSolidusR[@]})
lookAhead=(${_rSolidusR[@]})
lookAhead1=(${_rSolidusR[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ▽左が reverse solidus で 右が reverse solidus の場合 reverse solidus 元に戻る
backtrack=(${_rSolidusR[@]} \
${_rSolidusN[@]})
input=(${_rSolidusR[@]})
lookAhead=(${_rSolidusL[@]} \
${_rSolidusR[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# ▽右が、左下が開いている文字か W の場合 reverse solidus 右に移動
backtrack=("")
input=(${_rSolidusN[@]})
lookAhead=(${lowSpaceLR[@]} ${lowSpaceCR[@]} ${_WR[@]} \
${lowSpaceLN[@]} ${lowSpaceCN[@]} ${_WN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

# ▽右が、左下が開いている文字か W の場合 reverse solidus 右に移動しない
backtrack=("")
input=(${_rSolidusN[@]})
lookAhead=(${lowSpaceLL[@]} ${lowSpaceCL[@]} ${_WL[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ▽右が、左下が開いている文字か W の場合 reverse solidus 元に戻る
backtrack=("")
input=(${_rSolidusL[@]})
lookAhead=(${lowSpaceLR[@]} ${lowSpaceCR[@]} ${_WR[@]} \
${lowSpaceLN[@]} ${lowSpaceCN[@]} ${_WN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# solidus に関する処理の続き ----------------------------------------

# ▽左が solidus で その左が solidus の場合 solidus 元に戻る
backtrack1=(${_solidusN[@]})
backtrack=(${_solidusN[@]})
input=(${_solidusL[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"

# ▽左が solidus の場合 solidus 元に戻らない
backtrack=(${_solidusR[@]} \
${_solidusN[@]})
input=(${_solidusL[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ▽右が solidus で その右が solidus の場合 solidus 元に戻る
backtrack1=("")
backtrack=("")
input=(${_solidusR[@]})
lookAhead=(${_solidusR[@]})
lookAhead1=(${_solidusR[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ▽左が solidus で 右が solidus の場合 solidus 元に戻る
backtrack=(${_solidusR[@]} \
${_solidusN[@]})
input=(${_solidusR[@]})
lookAhead=(${_solidusL[@]} \
${_solidusR[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# ▽右が、左上が開いている文字、狭い文字、A の場合 solidus 右に移動
backtrack=("")
input=(${_solidusN[@]})
lookAhead=(${highSpaceLR[@]} ${highSpaceCR[@]} ${gravityCR[@]} ${_AR[@]} \
${highSpaceLN[@]} ${highSpaceCN[@]} ${gravityCN[@]} ${_AN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

# ▽右が、左上が開いている文字、狭い文字、A の場合 solidus 右に移動しない
backtrack=("")
input=(${_solidusN[@]})
lookAhead=(${highSpaceLL[@]} ${highSpaceCL[@]} ${gravityCL[@]} ${_AL[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ▽右が、左上が開いている文字、狭い文字、A の場合 solidus 元に戻る
backtrack=("")
input=(${_solidusL[@]})
lookAhead=(${highSpaceLR[@]} ${highSpaceCR[@]} ${gravityCR[@]} ${_AR[@]} \
${highSpaceLN[@]} ${highSpaceCN[@]} ${gravityCN[@]} ${_AN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# <> reverse solidus solidus に関する処理の続き ----------------------------------------

# ▽右が左寄り、右寄り、幅広、均等、中間の文字の場合 reverse solidus solidus 左に移動
backtrack=("")
input=(${_rSolidusN[@]} ${_solidusN[@]})
lookAhead=(${gravityLL[@]} ${gravityRL[@]} ${gravityWL[@]} ${gravityEL[@]} ${gravityML[@]} \
${gravityWN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"

# ▽右が左寄り、右寄り、幅広、均等、中間の文字の場合 > reverse solidus solidus 元に戻る
backtrack=("")
input=(${_greaterR[@]} ${_rSolidusR[@]} ${_solidusR[@]})
lookAhead=(${gravityLL[@]} ${gravityRL[@]} ${gravityWL[@]} ${gravityEL[@]} ${gravityML[@]} \
${gravityWN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# ▽左が左寄り、右寄り、幅広、均等、中間の文字の場合 < 元に戻る
backtrack=(${gravityLR[@]} ${gravityRR[@]} ${gravityWR[@]} ${gravityER[@]} ${gravityMR[@]} \
${gravityWN[@]})
input=(${_lessL[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# ?!.:,;|"'` に関する処理の続き ----------------------------------------

class=(_quotedbl _quote _grave)
for S in ${class[@]}; do
# ▽▽▽左が "'` で 右が "'` の場合 "'` 元に戻る
  eval backtrack=(\${${S}N[@]})
  eval input=(\${${S}L[@]} \
  \${${S}R[@]})
  eval lookAhead=(\${${S}R[@]} \
  \${${S}N[@]})
  chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

  # ▽▽▽左が "'` で その左が "'` の場合 "'` 元に戻る
  eval backtrack1=(\${${S}N[@]})
  eval backtrack=(\${${S}N[@]})
  eval input=(\${${S}L[@]} \
  \${${S}R[@]})
  lookAhead=("")
  chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"

  # ▽▽▽左が "'` で 右が "'` で その右が "'` の場合 "'` 元に戻る
  backtrack1=("")
  eval backtrack=(\${${S}N[@]})
  eval input=(\${${S}L[@]})
  eval lookAhead=(\${${S}L[@]})
  eval lookAhead1=(\${${S}L[@]} \
  \${${S}N[@]})
  chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"

  # ▽▽▽左が "'` で 右が "'` の場合 "'` 元に戻る
  eval backtrack=(\${${S}R[@]})
  eval input=(\${${S}R[@]})
  eval lookAhead=(\${${S}L[@]})
  chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

  # ▽▽▽右が "'` で その右が "'` の場合 "'` 元に戻る
  backtrack1=("")
  backtrack=("")
  eval input=(\${${S}R[@]})
  eval lookAhead=(\${${S}R[@]})
  eval lookAhead1=(\${${S}R[@]})
  chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"
done

# ---

# ▽左が ?!.:,;| で 右が ?!.:,;| の場合 ?!.:,;| 元に戻る
backtrack=(${barDotCommaN[@]})
input=(${barDotCommaL[@]} \
${barDotCommaR[@]})
lookAhead=(${barDotCommaR[@]} \
${barDotCommaN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# ▽左が ?!.:,;| で その左が ?!.:,;| の場合 ?!.:,;| 元に戻る
backtrack1=(${barDotCommaN[@]})
backtrack=(${barDotCommaN[@]})
input=(${barDotCommaL[@]} \
${barDotCommaR[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}"

# ▽左が ?!.:,;| で 右が ?!.:,;| で その右が ?!.:,;| の場合 ?!.:,;| 元に戻る
backtrack1=("")
backtrack=(${barDotCommaN[@]})
input=(${barDotCommaL[@]})
lookAhead=(${barDotCommaL[@]})
lookAhead1=(${barDotCommaL[@]} \
${barDotCommaN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ▽左が ?!.:,;| で 右が ?!.:,;| の場合 ?!.:,;| 元に戻る
backtrack=(${barDotCommaR[@]})
input=(${barDotCommaR[@]})
lookAhead=(${barDotCommaL[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# ▽右が ?!.:,;| で その右が ?!.:,;| の場合 ?!.:,;| 元に戻る
backtrack1=("")
backtrack=("")
input=(${barDotCommaR[@]})
lookAhead=(${barDotCommaR[@]})
lookAhead1=(${barDotCommaR[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}"

#CALT4
#<< "#CALT5" # 記号 ||||||||||||||||||||||||||||||||||||||||

pre_add_lookup

# 記号類 ++++++++++++++++++++++++++++++++++++++++

# *+-:= に関する処理 ----------------------------------------

# ◆左右が括弧の場合 *+-:= 上に移動
backtrack=(${bracketLN[@]})
input=(${_asteriskN[@]} ${_plusN[@]} ${_hyphenN[@]} ${_colonN[@]} ${_equalN[@]})
lookAhead=(${bracketRN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexUD}"

# *+-=~ に関する処理 ----------------------------------------

# ◇左が !.:|/\ で 右が !.:|/\ の場合 *+-=~ 移動しない
backtrack=(${_rSolidusL[@]} ${_solidusL[@]} \
${_exclamN[@]} ${_fullStopN[@]} ${_colonUN[@]} ${_barDN[@]})
input=(${operatorHN[@]} ${_tildeDN[@]})
lookAhead=(${_rSolidusR[@]} ${_solidusR[@]} \
${_exclamN[@]} ${_fullStopN[@]} ${_colonUN[@]} ${_barDN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" ""

# ◇左が !.:|/\ の場合 *+-=~ 左に移動
backtrack=(${_rSolidusL[@]} ${_solidusL[@]} \
${_exclamN[@]} ${_fullStopN[@]} ${_colonUN[@]} ${_barDN[@]})
input=(${operatorHN[@]} ${_tildeDN[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"

# ◇右が !.:|/\ の場合 *+-=~ 右に移動
backtrack=("")
input=(${operatorHN[@]} ${_tildeDN[@]})
lookAhead=(${_rSolidusR[@]} ${_solidusR[@]} \
${_exclamN[@]} ${_fullStopN[@]} ${_colonUN[@]} ${_barDN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

# ., に関する処理の続き ----------------------------------------

# ◇左が >/ で 右が <\ の場合 ., 移動しない
backtrack=(${_greaterL[@]} ${_solidusL[@]} \
${_greaterN[@]} ${_solidusN[@]})
input=(${_fullStopN[@]} ${_commaN[@]})
lookAhead=(${_lessR[@]} ${_rSolidusR[@]} \
${_lessN[@]} ${_rSolidusN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# ◇左が >/ の場合 ., 左に移動
backtrack=(${_greaterL[@]} ${_solidusL[@]} \
${_greaterN[@]} ${_solidusN[@]})
input=(${_fullStopN[@]} ${_commaN[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexLL}"

# ◇右が <\ の場合 ., 右に移動
backtrack=("")
input=(${_fullStopN[@]} ${_commaN[@]})
lookAhead=(${_lessR[@]} ${_rSolidusR[@]} \
${_lessN[@]} ${_rSolidusN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexRR}"

#CALT5
# 桁区切り設定作成 ||||||||||||||||||||||||||||||||||||||||

# 小数の処理 ----------------------------------------

pre_add_lookup

backtrack=(${_fullStopN[@]})
input=(${figureN[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex0}"

backtrack=(${figure0[@]})
input=(${figureN[@]})
lookAhead=("")
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex0}"

# 12桁マークを付ける処理 1 ----------------------------------------

pre_add_lookup

backtrack1=("")
backtrack=(${figure2[@]} ${figureN[@]})
input=(${figureN[@]})
lookAhead=(${figureN[@]})
lookAhead1=(${figureN[@]})
lookAheadX=(${figureN[@]}); aheadMax="10"
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex2}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

# ノーマルに戻す処理 1 ----------------------------------------

pre_add_lookup

backtrack=("")
input=(${figure2[@]})
lookAhead=(${figure2[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 12桁マークを付ける処理 2 ----------------------------------------

pre_add_lookup

backtrack1=("")
backtrack=(${figure2[@]} ${figureN[@]})
input=(${figureN[@]})
lookAhead=(${figureN[@]})
lookAhead1=(${figureN[@]})
lookAheadX=(${figureN[@]}); aheadMax="10"
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex2}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

# ノーマルに戻す処理 2 ----------------------------------------

pre_add_lookup

backtrack=("")
input=(${figure2[@]})
lookAhead=(${figure2[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 4桁マークを付ける処理 1 ----------------------------------------

pre_add_lookup

backtrack1=("")
backtrack=(${figure2[@]} ${figure4[@]} ${figureN[@]})
input=(${figureN[@]})
lookAhead=(${figureN[@]})
lookAhead1=(${figureN[@]})
lookAheadX=(${figureN[@]}); aheadMax="2"
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex4}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

# ノーマルに戻す処理 3 ----------------------------------------

pre_add_lookup

backtrack=("")
input=(${figure4[@]})
lookAhead=(${figure4[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 4桁マークを付ける処理 2 ----------------------------------------

pre_add_lookup

backtrack1=("")
backtrack=(${figure2[@]} ${figure4[@]} ${figureN[@]})
input=(${figureN[@]})
lookAhead=(${figureN[@]})
lookAhead1=(${figureN[@]})
lookAheadX=(${figureN[@]}); aheadMax="2"
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex4}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

# ノーマルに戻す処理 4 ----------------------------------------

pre_add_lookup

backtrack=("")
input=(${figure4[@]})
lookAhead=(${figure4[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 3桁マークを付ける処理 1 ----------------------------------------

pre_add_lookup

backtrack1=("")
backtrack=(${figure2[@]} ${figure3[@]} ${figure4[@]} ${figureN[@]})
input=(${figureN[@]})
lookAhead=(${figureN[@]})
lookAhead1=(${figureN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex3}" "${backtrack1[*]}" "${lookAhead1[*]}"

backtrack1=("")
backtrack=(${figure2[@]} ${figure3[@]} ${figure4[@]} ${figureN[@]})
input=(${figureN[@]})
lookAhead=(${figureN[@]})
lookAhead1=(${figure4[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex3}" "${backtrack1[*]}" "${lookAhead1[*]}"

backtrack1=("")
backtrack=(${figure2[@]} ${figure3[@]} ${figure4[@]} ${figureN[@]})
input=(${figureN[@]})
lookAhead=(${figure4[@]})
lookAhead1=(${figureN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex3}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ノーマルに戻す処理 5 ----------------------------------------

pre_add_lookup

backtrack=("")
input=(${figure3[@]})
lookAhead=(${figure3[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

backtrack1=("")
backtrack=("")
input=(${figure3[@]})
lookAhead=(${figure2[@]} ${figure3[@]} ${figure4[@]} ${figureN[@]})
lookAhead1=(${figure2[@]} ${figure3[@]} ${figure4[@]} ${figureN[@]})
lookAheadX=(${figureN[@]}); aheadMax="2"
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

# 3桁マークを付ける処理 2 ----------------------------------------

pre_add_lookup

backtrack1=("")
backtrack=(${figure2[@]} ${figure3[@]} ${figure4[@]} ${figureN[@]})
input=(${figureN[@]})
lookAhead=(${figureN[@]})
lookAhead1=(${figureN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex3}" "${backtrack1[*]}" "${lookAhead1[*]}"

backtrack1=("")
backtrack=(${figure2[@]} ${figure3[@]} ${figure4[@]} ${figureN[@]})
input=(${figureN[@]})
lookAhead=(${figureN[@]})
lookAhead1=(${figure4[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex3}" "${backtrack1[*]}" "${lookAhead1[*]}"

# ノーマルに戻す処理 6 ----------------------------------------

pre_add_lookup

backtrack=("")
input=(${figure3[@]})
lookAhead=(${figure3[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# 2進数のみ4桁区切りを有効にする処理 ----------------------------------------

pre_add_lookup

backtrack1=("")
backtrack=(${figureBN[@]})
input=(${figureB2[@]})
lookAhead=(${figureBN[@]})
lookAhead1=(${figureBN[@]})
lookAheadX=(${figureB3[@]}); aheadMax="2"
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex2}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

backtrack1=("")
backtrack=(${figureB3[@]} ${figureBN[@]})
input=(${figureB4[@]})
lookAhead=(${figureBN[@]})
lookAhead1=(${figureB3[@]})
lookAheadX=(${figureBN[@]}); aheadMax="2"
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex4}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

backtrack1=("")
backtrack=(${figureB3[@]} ${figureBN[@]})
input=(${figureB4[@]})
lookAhead=(${figureB3[@]})
lookAhead1=(${figureBN[@]})
lookAheadX=(${figureBN[@]}); aheadMax="2"
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex4}" "${backtrack1[*]}" "${lookAhead1[*]}" "${lookAheadX[*]}" "${aheadMax}"

backtrack=("")
input=(${figure2[@]})
lookAhead=(${figureN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndex3}"

backtrack=("")
input=(${figure4[@]})
lookAhead=(${figure3[@]} ${figureN[@]})
chain_context 2 index "${index}" "${backtrack[*]}" "${input[*]}" "${lookAhead[*]}" "${lookupIndexN}"

# ---

# 作成した設定と calt_table_maker の情報を保存
echo "Save kerning settings"
rm -rf "${karndir_name}/${karnsetdir_name}"
mkdir -p "${karndir_name}/${karnsetdir_name}"
printf "${output_data}" > "${karndir_name}/${karnsetdir_name}/${fileDataName}.txt"
cp -f ${caltListName}_*.txt "${karndir_name}/${karnsetdir_name}/."
echo

if [ "${leaving_tmp_flag}" = "false" ]; then
  echo "Remove temporary files"
  rm -rf ${tmpdir}
fi
echo

# Exit
echo "Finished making the GSUB table [calt, LookupType 6]."
echo
exit 0
