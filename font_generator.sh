#!/bin/bash

# Custom font generator for Cyroit
#
# Copyright (c) 2023 omonomo
#
# [Original Script]
# Ricty Generator (ricty_generator-4.1.1.sh)
#
# Copyright (c) 2011-2017 Yasunori Yusa
# All rights reserved.
# (https://rictyfonts.github.io)


# ログをファイル出力させる場合は有効にする (<< "#LOG" をコメントアウトさせる)
<< "#LOG"
LOG_OUT=/tmp/font_generator.log
LOG_ERR=/tmp/font_generator_err.log
exec 1> >(tee -a $LOG_OUT)
exec 2> >(tee -a $LOG_ERR)
#LOG

font_familyname="Cyroit"
font_familyname_suffix=""

font_version="0.1.0"
vendor_id="PfEd"

tmpdir_name="font_generator_tmpdir" # 一時保管フォルダ名
nopatchdir_name="nopatchFonts" # パッチ前フォントの保存フォルダ名
nopatchsetdir_name="" # 各パッチ前フォントの設定と font_generator 情報の保存フォルダ名
fileDataName="fileData" # font_generator と 設定ファイルのハッシュ値を保存するファイル名

# グリフ保管アドレス
num_mod_glyphs="4" # -t オプションで改変するグリフ数
address_store_start="64336" # 0ufb50 保管したグリフの最初のアドレス
address_store_g=${address_store_start} # 保管したgアドレス
address_store_b_diagram=$((address_store_g + 1)) # 保管した▲▼■アドレス
address_store_underline=$((address_store_b_diagram + 3)) # 保管した下線アドレス
address_store_mod=$((address_store_underline + 3)) # 保管したDQVZアドレス
address_store_braille=$((address_store_mod + num_mod_glyphs * 6)) # 保管した点字アドレス
address_store_zero=$((address_store_braille + 256)) # 保管したスラッシュ無し0・ドット0アドレス
address_store_visi_latin=$((address_store_zero + 12)) # latinフォントの保管した識別性向上アドレス ⁄|
address_store_visi_kana=$((address_store_visi_latin + 2)) # 仮名フォントの保管した識別性向上アドレス ゠ - ➓
address_store_visi_kanzi=$((address_store_visi_kana + 25)) # 漢字フォントの保管した識別性向上アドレス 〇 - 口
address_store_line=$((address_store_visi_kanzi + 12)) # 保管した罫線アドレス
address_store_arrow=$((address_store_line + 32)) # 保管した矢印アドレス
address_store_vert=$((address_store_arrow + 4)) # 保管した縦書きアドレス(縦書きの縦線無し（ - 縦書きの縦線無し⁉)
address_store_zenhan=$((address_store_vert + 109)) # 保管した全角半角アドレス(！゠⁉)
address_store_d_hyphen=$((address_store_zenhan + 172)) # 保管した縦書き゠アドレス
address_store_otherspace=$((address_store_d_hyphen + 1)) # 保管したその他のスペースアドレス
address_store_escape=$((address_store_otherspace + 2)) # 保管したエスケープ文字アドレス
address_store_liga=$((address_store_escape + 1)) # 保管したリガチャアドレス
address_store_end=$((address_store_liga + 2 - 1)) # 保管したグリフの最終アドレス

address_vert_start_kana="1114129" # 仮名フォントのvert置換の先頭アドレス －
 #address_vert_start_latinkana="65682" # latin仮名フォントのvert置換の先頭アドレス （ (𛀁を残した場合)
address_vert_start_latinkana="65681" # latin仮名フォントのvert置換の先頭アドレス （ (𛀁を削除した場合)
address_vert_start="1114179" # 合成後のvert置換の先頭アドレス
address_vert_bracket=${address_vert_start} # vert置換アドレス （
address_vert_X=$((address_vert_bracket + 109)) # vert置換アドレス ✂
address_vert_dh=$((address_vert_X + 3)) # vert置換アドレス ゠
address_vert_mm=$((address_vert_dh + 75)) # vert置換アドレス ㍉
address_vert_kabu=$((address_vert_mm + 333)) # vert置換アドレス ㍿
address_vert_end=$((address_vert_kabu + 7 - 1)) # vert置換の最終アドレス ㋿

address_calt_start_kanzi="1114841" # 漢字フォントのcalt置換の先頭アドレス (既存のグリフを避けるため収納場所を分割)
address_calt_start2_kanzi="1115493" # 漢字フォントのcalt置換の先頭アドレス2
address_calt_start3_kanzi="1115623" # 漢字フォントのcalt置換の先頭アドレス3
address_calt_start4_kanzi="1115776" # 漢字フォントのcalt置換の先頭アドレス4
address_ss_start_kanzi=$((address_calt_start4_kanzi + 70)) # 漢字フォントのss置換の先頭アドレス
address_ss_start_dummy="1114336" # ダミーフォントのss置換の先頭アドレス (変体仮名の最終アドレス + 1)

address_calt_start=$((address_vert_end + 1)) # calt置換の先頭アドレス
address_calt_AL=${address_calt_start} # calt置換アドレス(左に移動した A)
address_calt_AR=$((address_calt_AL + 239)) # calt置換アドレス(右に移動した A)
address_calt_figure=$((address_calt_AR + 239)) # calt置換アドレス(桁区切り付きの数字)
address_calt_barD=$((address_calt_figure + 40)) # calt置換アドレス(下に移動した |)
address_calt_hyphenL=$((address_calt_barD + 9)) # calt置換アドレス(左に移動した *、数を変更した場合スロットの確保数を変更すること)
address_calt_hyphenR=$((address_calt_hyphenL + 30)) # calt置換アドレス(右に移動した *)
address_calt_escape=$((address_calt_hyphenR + 30)) # calt置換アドレス (エスケープ文字)
address_calt_end=$((address_calt_escape + 3 - 1)) # calt置換の最終アドレス (右に移動した 2つ並んだ時用のバックスラッシュ)
address_calt_barDLR="24" # calt置換アドレス(左右に移動した * から、左右に移動した | までの増分)

address_ss_start=$((address_calt_end + 1)) # ss置換の先頭アドレス
address_ss_space=${address_ss_start} # ss置換アドレス(全角スペース)
address_ss_figure=$((address_ss_space + 3)) # ss置換アドレス(桁区切り付きの数字)
address_ss_vert=$((address_ss_figure + 50)) # ss置換の縦書き全角アドレス(縦書きの（)
address_ss_zenhan=$((address_ss_vert + 109)) # ss置換の横書き全角半角アドレス(！)
address_ss_braille=$((address_ss_zenhan + 172)) # ss置換の点字アドレス(点なし)
address_ss_visibility=$((address_ss_braille + 256)) # ss置換の識別性向上アドレス(/)
address_ss_liga=$((address_ss_visibility + 48)) # ss置換の識別性向上リガチャアドレス(フォントによってはダミースペース)
address_ss_mod=$((address_ss_liga + 2)) # ss置換のDQVZアドレス(ストローク D)
address_ss_line=$((address_ss_mod + num_mod_glyphs * 6)) # ss置換の罫線アドレス(全角─)
address_ss_arrow=$((address_ss_line + 32)) # ss置換の矢印アドレス(←)
address_ss_zero=$((address_ss_arrow + 4)) # ss置換のスラッシュ無し0アドレス
address_ss_otherspace=$((address_ss_zero + 10)) # ss置換のその他のスペースアドレス
address_ss_ambiguous=$((address_ss_otherspace + 2)) # ss置換のあいまい文字アドレス(半角‥)
address_ss_escape=$((address_ss_ambiguous + 116)) # ss置換のエスケープ文字アドレス(細いバックスラッシュ)
address_ss_zero2=$((address_ss_escape + 3)) # ss置換のドット0アドレス
address_ss_end=$((address_ss_zero2 + 10 - 1)) # ss置換の最終アドレス
num_ss_glyphs_former=$((address_ss_braille - address_ss_start)) # ss置換のグリフ数(点字の前まで)
num_ss_glyphs_latter=$((address_ss_end + 1 - address_ss_braille)) # ss置換のグリフ数(点字から後)
num_ss_glyphs=$((address_ss_end + 1 - address_ss_start)) # ss置換の総グリフ数

lookupIndex_calt="18" # caltテーブルのlookupナンバー (lookupの種類を増やした場合変更)
num_calt_lookups="20" # caltのルックアップ数 (calt_table_makerでlookupを変更した場合、それに合わせる。table_modificatorも変更すること)

lookupIndex_replace=$((lookupIndex_calt + num_calt_lookups)) # 単純置換のlookupナンバー
num_replace_lookups="12" # 単純置換のルックアップ数 (lookupの数を変えた場合はcalt_table_makerも変更すること)

lookupIndex_ss=$((lookupIndex_replace + num_replace_lookups)) # ssテーブルのlookupナンバー
num_ss_lookups="14" # ssのルックアップ数 (lookupの数を変えた場合はtable_modificatorも変更すること)

# 著作権
copyright="Copyright (c) 2023 omonomo\n\n"
copyright="${copyright}\" + \"[Inconsolata]\nCopyright 2006 The Inconsolata Project Authors (https://github.com/cyrealtype/Inconsolata)\n\n"
copyright="${copyright}\" + \"[Circle M+]\nCopyright(c) 2020 M+ FONTS PROJECT, itouhiro\n\n"
copyright="${copyright}\" + \"[BIZ UDGothic]\nCopyright 2022 The BIZ UDGothic Project Authors (https://github.com/googlefonts/morisawa-biz-ud-gothic)\n\n"
copyright="${copyright}\" + \"[NINJAL Hentaigana]\nCopyright(c) National Institute for Japanese Language and Linguistics (NINJAL), 2018.\n\n"
copyright_nerd_fonts="[Symbols Nerd Font]\nCopyright (c) 2016, Ryan McIntyre\n\n"
copyright_license="SIL Open Font License Version 1.1 (http://scripts.sil.org/ofl)"

# Set ascent and descent (line width parameters)
em_ascent1000="860" # em値1000用
em_descent1000="140"
typo_ascent1000="${em_ascent1000}"
typo_descent1000="${em_descent1000}"
typo_linegap1000="0"
win_ascent1000="835"
win_descent1000="215"
hhea_ascent1000="${typo_ascent1000}"
hhea_descent1000="${typo_descent1000}"
hhea_linegap1000="${typo_linegap1000}"

em_ascent1024="827" # em値1024用 ※ win_ascent - (設定したい typo_linegap) / 2 が適正っぽい
em_descent1024="197" # win_descent - (設定したい typo_linegap) / 2 が適正っぽい
typo_ascent1024="${em_ascent1024}" # typo_ascent + typo_descent = em値にしないと縦書きで文字間隔が崩れる
typo_descent1024="${em_descent1024}" # 縦書きに対応させない場合、linegap = 0で typo、win、hhea 全てを同じにするのが無難
 #typo_linegap1024="224" # 本来設定したい値 (win_ascent + win_descent = typo_ascent + typo_descent + typo_linegap)
typo_linegap1024="150" # 数値が大きすぎると Excel (Windows版、Mac版については不明) で文字コード 80h 以上 (おそらく) の文字がずれる
win_ascent1024="939"
win_descent1024="309"
hhea_ascent1024="${win_ascent1024}"
hhea_descent1024="${win_descent1024}"
hhea_linegap1024="0"

# em値変更でのY座標のズレ修正用
move_y_em_revise="-10" # Y座標移動量

# NerdFonts 用
move_y_nerd="30" # 全体Y座標移動量

scale_height_pl="120.7" # PowerlineY座標拡大率
scale_height_pl2="121.9" # PowerlineY座標拡大率 2
scale_height_block="89" # ボックス要素Y座標拡大率
scale_height_pl_revise="100" # 画面表示のずれを修正するための拡大率
center_height_pl=$((277 + move_y_nerd + move_y_em_revise)) # PowerlineリサイズY座標中心
move_y_pl="18" # PowerlineY座標移動量 (上端から ascent までと 下端から descent までの距離が同じになる移動量)
move_y_pl_revise="-10" # 画面表示のずれを修正するための移動量

scale_pomicons="91" # Pomicons の拡大率
scale_nerd="89" # Pomicons Powerline 以外の拡大率

# 可視化したスペース等、下線のY座標移動量
move_y_space="-235"

# ウェイト調整用
weight_kanzi_regular="8" # 主に漢字レギュラー
weight_kanzi_bold="8" # 主に漢字ボールド
weight_kanzi_symbols_regular="6" # 漢字フォントの記号類レギュラー
weight_kanzi_symbols_bold="12" # 漢字フォントの記号類ボールド
weight_kanzi_roman_regular="-6" # 漢字フォントのローマ数字レギュラー
weight_kanzi_roman_bold="-8" # 漢字フォントのローマ数字ボールド

weight_kana_geometry_regular="16" # 仮名フォントの幾何学模様レギュラー
weight_kana_geometry_bold="16" # 仮名フォントの幾何学模様ボールド
weight_kana_bold="-8" # 主に仮名ボールド
weight_kana_others_regular="-2" # 仮名フォントのその他レギュラー
weight_kana_others_bold="-12" # 仮名フォントのその他ボールド

weight_small_kana_regular="10" # 小仮名拡張レギュラー
weight_small_kana_bold="4" # 小仮名拡張ボールド(weight_kana_boldは適用しない)

# 直角二等辺三角形用
scale_width_triangle="94.8" # 直角二等辺三角形のX座標拡大率
scale_height_triangle="94.8" # 直角二等辺三角形のY座標拡大率
move_y_upper_triangle="-39" # 直角二等辺三角形のY座標移動量 (上側)
move_y_lower_triangle="10" # 直角二等辺三角形のY座標移動量 (下側)

# 全角から半角に変換する場合の拡大率
scale_zenkaku2hankaku="70"

# 上付き、下付き、ルート、分数用
scale_super_sub="75" # 拡大率
weight_super_sub="12" # ウェイト調整

# 上付き、下付き用
move_y_super="273" # 上付きY座標移動量
move_y_sub="-166" # 下付きY座標移動量

# 分数用
move_x_numerator="0" # 分子のX座標移動量
move_y_numerator="260" # 分子のY座標移動量
move_x_denominator="480" # 分母のX座標移動量
move_y_denominator="-30" # 分母のY座標移動量

# latin 括弧移動量
move_y_latin_bracket="0"

# latin アンダーバー移動量
move_y_latin_underbar="0"

# 全角アンダーバー移動量
move_y_zenkaku_underbar="52"

# 縦書き全角記号移動量
move_x_vert_colon="72" # ：；
move_x_vert_bar="-5" # ｜
move_x_vert_solidus="-4" # ／＼
move_x_vert_math="18" # ＝－＜＞
move_y_vert_bbar="-5" # ￤

# 縦書き全角ラテン小文字移動量
move_y_vert_1="-10"
move_y_vert_2="10"
move_y_vert_3="30"
move_y_vert_4="80"
move_y_vert_5="120"
move_y_vert_6="140"
move_y_vert_7="160"

# 全角移動量
move_x_zenkaku_latin="20"
move_x_zenkaku_kana="22"
move_x_zenkaku_kanzi="34"

# オブリーク体 (Transform()) 用
tan_oblique="16" # 傾きの係数 (tanθ * 100)
move_x_oblique="-48" # 移動量 (後の処理で * 100 にする)

# 演算子移動量
move_y_math="-25" # 通常
move_y_s_math="-10" # 上付き、下付き
move_y_zenkaku_math="0" # ベースフォントの演算子上下移動量 (Latin フォントと高さを合わせる)

# calt用
move_y_calt_separate3="-510" # 3桁区切り表示のY座標
move_y_calt_separate4="452" # 4桁区切り表示のY座標
scale_calt_decimal="93" # 小数の拡大率
calt_init() {
    move_x_calt_colon="14" # : のX座標移動量
    move_y_calt_colon=$((move_y_math + 78)) # : のY座標移動量 (= 基準)
    move_y_calt_colon=$(bc <<< "scale=0; ${move_y_calt_colon} * ${scale_height_latin} / 100") # : のY座標移動量
    move_y_calt_colon=$(bc <<< "scale=0; ${move_y_calt_colon} * ${scale_height_hankaku} / 100") # : のY座標移動量
    move_y_calt_bar=$((move_y_math - 5)) # | のY座標移動量 (= 基準)
    move_y_calt_bar=$(bc <<< "scale=0; ${move_y_calt_bar} * ${scale_height_latin} / 100") # | のY座標移動量
    move_y_calt_bar=$(bc <<< "scale=0; ${move_y_calt_bar} * ${scale_height_hankaku} / 100") # | のY座標移動量
    move_y_calt_tilde=$((move_y_math - 169)) # ~ のY座標移動量 (> 基準)
    move_y_calt_tilde=$(bc <<< "scale=0; ${move_y_calt_tilde} * ${scale_height_latin} / 100") # ~ のY座標移動量
    move_y_calt_tilde=$(bc <<< "scale=0; ${move_y_calt_tilde} * ${scale_height_hankaku} / 100") # ~ のY座標移動量
    move_y_calt_math=$((- move_y_math + 2)) # *+-= のY座標移動量 (括弧基準)
    move_y_calt_math=$(bc <<< "scale=0; ${move_y_calt_math} * ${scale_height_latin} / 100") # *+-= のY座標移動量
    move_y_calt_math=$(bc <<< "scale=0; ${move_y_calt_math} * ${scale_height_hankaku} / 100") # *+-= のY座標移動量
    move_y_calt_colon2="68" # : のY座標移動量 (括弧基準)
    move_y_calt_colon2=$(bc <<< "scale=0; ${move_y_calt_colon2} * ${scale_height_latin} / 100") # : のY座標移動量
    move_y_calt_colon2=$(bc <<< "scale=0; ${move_y_calt_colon2} * ${scale_height_hankaku} / 100") # : のY座標移動量
    move_y_calt_bar2="-8" # | のY座標移動量 (括弧基準)
    move_y_calt_bar2=$(bc <<< "scale=0; ${move_y_calt_bar2} * ${scale_height_latin} / 100") # | のY座標移動量
    move_y_calt_bar2=$(bc <<< "scale=0; ${move_y_calt_bar2} * ${scale_height_hankaku} / 100") # | のY座標移動量
}
# 通常版・Loose版共通
center_height_hankaku="373" # 半角文字Y座標中心
move_x_calt_separate="-512" # 桁区切り表示のX座標移動量 (下書きモードとその他で位置が変わるので注意)
width_zenkaku="1024" # 全角文字幅
move_x_calt_quote="8" # クォートのX座標戻り量 (move_x_calt_symbol から引く)

# 通常版用
scale_width_latin="98" # Latin フォントの半角英数文字の横拡大率
scale_height_latin="102" # Latin フォントの半角英数文字の縦拡大率
scale_width_kana="102" # 仮名フォントの半角英数文字の横拡大率
scale_height_kana="100" # 仮名フォントの半角英数文字の縦拡大率
scale_width_hankaku="100" # 半角英数文字の横拡大率
scale_height_hankaku="100" # 半角英数文字の縦拡大率
width_hankaku="512" # 半角文字幅
center_width=$((width_hankaku / 2)) # 半角文字X座標中心
move_x_calt_latin="16" # ラテン文字のカーニングX座標移動量
move_x_calt_symbol="32" # 記号のカーニングX座標移動量
move_x_hankaku="0" # 半角文字移動量

# Loose 版用
scale_width_latin_loose="102" # Latin フォントの半角英数文字の横拡大率 (Loose 版)
scale_height_latin_loose="102" # Latin フォントの半角英数文字の縦拡大率 (Loose 版)
scale_width_kana_loose="102" # 仮名フォントの半角英数文字の横拡大率 (Loose 版)
scale_height_kana_loose="100" # 仮名フォントの半角英数文字の縦拡大率 (Loose 版)
scale_width_hankaku_loose="104" # 半角英数文字の横拡大率 (Loose 版)
scale_height_hankaku_loose="104" # 半角英数文字の縦拡大率 (Loose 版)
width_hankaku_loose="576" # 半角文字幅 (Loose 版)
center_width_loose=$((width_hankaku_loose / 2)) # 半角文字X座標中心 (Loose 版)
move_x_calt_latin_loose="18" # ラテン文字のカーニングX座標移動量 (Loose 版)
move_x_calt_symbol_loose="36" # 記号のカーニングX座標移動量 (Loose 版)
move_x_hankaku_loose=$(((width_hankaku_loose - ${width_hankaku}) / 2)) # 半角文字移動量 (Loose 版)

# デバッグ用

 # NerdFonts
 #scale_pomicons="150" # Pomicons の拡大率
 #scale_nerd="150" # その他の拡大率

 # ウェイト調整
 #weight_kanzi_regular="50" # 主に漢字レギュラー
 #weight_kanzi_bold="50" # 主に漢字ボールド
 #weight_kanzi_symbols_regular="50" # 漢字フォントの記号類レギュラー
 #weight_kanzi_symbols_bold="50" # 漢字フォントの記号類ボールド
 #weight_kanzi_roman_regular="50" # 漢字フォントのローマ数字レギュラー
 #weight_kanzi_roman_bold="50" # 漢字フォントのローマ数字ボールド

 #weight_kana_geometry_regular="50" # 仮名フォントの幾何学模様レギュラー
 #weight_kana_geometry_bold="50" # 仮名フォントの幾何学模様ボールド
 #weight_kana_bold="50" # 主に仮名ボールド
 #weight_kana_others_regular="50" # 仮名フォントのその他レギュラー
 #weight_kana_others_bold="50" # 仮名フォントのその他ボールド

 #weight_small_kana_regular="50" # 小仮名拡張レギュラー
 #weight_small_kana_bold="50" # 小仮名拡張ボールド(weight_kana_boldは適用しない)

 # 通常版用
 #scale_width_latin="150" # 半角 Latin フォント英数文字の横拡大率
 #scale_height_latin="50" # 半角 Latin フォント英数文字の縦拡大率

# デバッグ用ここまで

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

compose_flag="true" # フォントを合成 (既に同じ設定で作成したパッチ前フォントがない)
leaving_tmp_flag="false" # 一時ファイル残す
loose_flag="false" # Loose 版にする
term_flag="false" # あいまい文字等を半角にする
visible_zenkaku_space_flag="true" # 全角スペース可視化
visible_hankaku_space_flag="true" # 半角スペース可視化
improve_visibility_flag="true" # ダッシュ破線化
underline_flag="true" # 全角半角に下線
mod_flag="true" # DVQZ改変
calt_flag="true" # calt対応
ss_flag="false" # ss対応
nerd_flag="true" # Nerd fonts 追加
separator_flag="true" # 桁区切りあり
zero_mode="1" # 0の形状(0: スラッシュ・ドット無し、1: 標準 2: 別バージョン)
oblique_flag="true" # オブリーク作成
emoji_flag="true" # 絵文字を減らさない
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
origin_hentai_kana="ninjal_hentaigana.ttf"
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

modified_dummy_generator="modified_dummy_generator.pe"
modified_dummy="modified-dummy.sfd"

modified_hentai_kana_generator="modified_hentai_kana_generator.pe"
modified_hentai_kana="modified-hentai-kana.ttf"

modified_nerd_generator="modified_nerd_generator.pe"
modified_nerd="modified-nerd.ttf"
merged_nerd_generator="merged_nerd_generator.pe"

font_patcher="font_patcher.pe"

################################################################################
# Pre-process
################################################################################

# 設定読み込み
settings="settings" # 設定ファイル名
settings_txt=$(find . -maxdepth 1 -name "${settings}.txt" | head -n 1)
if [ -n "${settings_txt}" ]; then
    S=$(grep -m 1 "^FONT_VERSION=" "${settings_txt}") # フォントバージョン
    if [ -n "${S}" ]; then font_version="${S#FONT_VERSION=}"; fi
    S=$(grep -m 1 "^FONT_FAMILYNAME=" "${settings_txt}") # フォントファミリー名
    if [ -n "${S}" ]; then font_familyname="${S#FONT_FAMILYNAME=}"; fi
    S=$(grep -m 1 "^FONT_FAMILYNAME_SUFFIX=" "${settings_txt}") # フォントファミリー名接尾語
    if [ -n "${S}" ]; then font_familyname_suffix="${S#FONT_FAMILYNAME_SUFFIX=}"; fi
    S=$(grep -m 1 "^VENDOR_ID=" "${settings_txt}") # ベンダー ID
    if [ -n "${S}" ]; then vendor_id="${S#VENDOR_ID=}"; fi
    S=$(grep "^COPYRIGHT=" "${settings_txt}") # 著作権
    if [ -n "${S}" ]; then
        copyright="${S//COPYRIGHT=/}";
        copyright="${copyright//
/\\n\\n\" + \"}\n\n";
    fi
    S=$(grep -m 1 "^COPYRIGHT_NERD_FONTS=" "${settings_txt}") # 著作権 (Nerd fonts)
    if [ -n "${S}" ]; then copyright_nerd_fonts="${S#COPYRIGHT_NERD_FONTS=}\n\n"; fi
    S=$(grep -m 1 "^COPYRIGHT_LICENSE=" "${settings_txt}") # ライセンス
    if [ -n "${S}" ]; then copyright_license="${S#COPYRIGHT_LICENSE=}"; fi
    S=$(grep -m 1 "^SCALE_WIDTH_HANKAKU=" "${settings_txt}") # 通常版の半角文字 横幅拡大率
    if [ -n "${S}" ]; then scale_width_hankaku="${S#SCALE_WIDTH_HANKAKU=}"; fi
    S=$(grep -m 1 "^SCALE_HEIGHT_HANKAKU=" "${settings_txt}") # 通常版の半角文字 高さ拡大率
    if [ -n "${S}" ]; then scale_height_hankaku="${S#SCALE_HEIGHT_HANKAKU=}"; fi
    S=$(grep -m 1 "^SCALE_WIDTH_HANKAKU_LOOSE=" "${settings_txt}") # Loose 版の半角文字 横幅拡大率
    if [ -n "${S}" ]; then scale_width_hankaku_loose="${S#SCALE_WIDTH_HANKAKU_LOOSE=}"; fi
    S=$(grep -m 1 "^SCALE_HEIGHT_HANKAKU_LOOSE=" "${settings_txt}") # Loose 版の半角文字 高さ拡大率
    if [ -n "${S}" ]; then scale_height_hankaku_loose="${S#SCALE_HEIGHT_HANKAKU_LOOSE=}"; fi
    S=$(grep -m 1 "^MOVE_X_KERN_LATIN=" "${settings_txt}") # 通常版のラテン文字 カーニング横移動量
    if [ -n "${S}" ]; then move_x_calt_latin="${S#MOVE_X_KERN_LATIN=}"; fi
    S=$(grep -m 1 "^MOVE_X_KERN_SYMBOL=" "${settings_txt}") # 通常版の記号 カーニング横移動量
    if [ -n "${S}" ]; then move_x_calt_symbol="${S#MOVE_X_KERN_SYMBOL=}"; fi
    S=$(grep -m 1 "^MOVE_X_KERN_LATIN_LOOSE=" "${settings_txt}") # Loose 版のラテン文字 カーニング横移動量
    if [ -n "${S}" ]; then move_x_calt_latin_loose="${S#MOVE_X_KERN_LATIN_LOOSE=}"; fi
    S=$(grep -m 1 "^MOVE_X_KERN_SYMBOL_LOOSE=" "${settings_txt}") # Loose 版の記号 カーニング横移動量
    if [ -n "${S}" ]; then move_x_calt_symbol_loose="${S#MOVE_X_KERN_SYMBOL_LOOSE=}"; fi
    S=$(grep -m 1 "^TAN_OBLIQUE=" "${settings_txt}") # オブリーク体の傾き
    if [ -n "${S}" ]; then tan_oblique="${S#TAN_OBLIQUE=}"; fi
    S=$(grep -m 1 "^MOVE_X_OBLIQUE=" "${settings_txt}") # オブリーク体横移動量
    if [ -n "${S}" ]; then move_x_oblique="${S#MOVE_X_OBLIQUE=}"; fi
    S=$(grep -m 1 "^SCALE_HEIGHT_POWERLINE=" "${settings_txt}") # Powerline 高さ拡大率
    if [ -n "${S}" ]; then scale_height_pl_revise="${S#SCALE_HEIGHT_POWERLINE=}"; fi
    S=$(grep -m 1 "^MOVE_Y_POWERLINE=" "${settings_txt}") # Powerline 縦移動量
    if [ -n "${S}" ]; then move_y_pl_revise="${S#MOVE_Y_POWERLINE=}"; fi
    S=$(grep -m 1 "^SCALE_DECIMAL=" "${settings_txt}") # 小数拡大率
    if [ -n "${S}" ]; then scale_calt_decimal="${S#SCALE_DECIMAL=}"; fi
    S=$(grep -m 1 "^MOVE_Y_MATH=" "${settings_txt}") # 通常の演算子縦移動量
    if [ -n "${S}" ]; then move_y_math="${S#MOVE_Y_MATH=}"; fi
    S=$(grep -m 1 "^MOVE_Y_S_MATH=" "${settings_txt}") # 上付き、下付きの演算子縦移動量
    if [ -n "${S}" ]; then move_y_s_math="${S#MOVE_Y_S_MATH=}"; fi
fi

# Powerline の Y座標移動量
move_y_pl=$((move_y_pl + move_y_pl_revise)) # 実際の移動量
move_y_pl2=$((move_y_pl + 3)) # 実際の移動量 2

# Powerline、ボックス要素の Y座標拡大率
scale_height_pl=$(bc <<< "scale=1; ${scale_height_pl} * ${scale_height_pl_revise} / 100") # PowerlineY座標拡大率
scale_height_pl2=$(bc <<< "scale=1; ${scale_height_pl2} * ${scale_height_pl_revise} / 100") # PowerlineY座標拡大率 2
scale_height_block=$(bc <<< "scale=1; ${scale_height_block} * ${scale_height_pl_revise} / 100") # ボックス要素Y座標拡大率

# オブリーク体用
move_x_oblique=$((move_x_oblique * 100)) # Transform()用 (移動量 * 100)

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
    echo "       font_generator.sh [options] [font1]-{Regular,Bold}.ttf [font2]-{regular,bold}.ttf ..."
    echo ""
    echo "Options:"
    echo "  -h                     Display this information"
    echo "  -V                     Display version number"
    echo "  -x                     Cleaning temporary files" # 一時作成ファイルの消去のみ
    echo "  -X                     Cleaning temporary files and saved nopatch fonts" # 一時作成ファイルとパッチ前フォントの消去のみ
    echo "  -f /path/to/fontforge  Set path to fontforge command"
    echo "  -v                     Enable verbose mode (display fontforge's warning)"
    echo "  -l                     Leave (do NOT remove) temporary files"
    echo "  -N string              Set fontfamily (\"string\")"
    echo "  -n string              Set fontfamily suffix (\"string\")"
    echo "  -w                     Set the ratio of hankaku to zenkaku characters to 9:16"
    echo "  -a                     Set neutral and ambiguous characters to hankaku (excluding private use areas)"
    echo "  -Z                     Disable visible zenkaku space"
    echo "  -z                     Disable visible hankaku space"
    echo "  -u                     Disable zenkaku hankaku underline"
    echo "  -b                     Disable glyphs with improved visibility"
    echo "  -t                     Disable modified D,Q,V and Z"
    echo "  -s                     Disable thousands separator"
    echo "  -O                     Disable slashed zero"
    echo "  -Q                     Enable another zero"
    echo "  -c                     Disable calt feature"
    echo "  -e                     Disable add Nerd fonts"
    echo "  -o                     Disable generate oblique style fonts"
    echo "  -j                     Reduce the number of emoji glyphs"
    echo "  -S                     Enable ss feature"
    echo "  -d                     Enable draft mode (skip time-consuming processes)"
    echo "  -P                     End just before patching"
    echo "  -p                     Run font patch only"
}

# Get options
while getopts hVxXf:vlN:n:waZzubtsOQceojSdPp OPT
do
    case "${OPT}" in
        "h" )
            font_generator_help
            exit 0
            ;;
        "V" )
            exit 0
            ;;
        "x" )
            echo "Option: Cleaning temporary files"
            echo "Remove temporary files"
            rm -rf ${tmpdir_name}.*
            exit 0
            ;;
        "X" )
            echo "Option: Cleaning temporary files and saved nopatch fonts"
            echo "Remove temporary files"
            rm -rf ${tmpdir_name}.*
            echo "Remove nopatch fonts"
            rm -rf "${nopatchdir_name}"
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
            font_familyname=${OPTARG// /}
            ;;
        "n" )
            echo "Option: Set fontfamily suffix: ${OPTARG}"
            font_familyname_suffix=${OPTARG// /}
            ;;
        "w" )
            echo "Option: Set the ratio of hankaku to zenkaku characters to 9:16"
            loose_flag="true"
            scale_width_latin=${scale_width_latin_loose} # Latin フォントの半角英数文字の横拡大率
            scale_height_latin=${scale_height_latin_loose} # Latin フォントの半角英数文字の縦拡大率
            scale_width_kana=${scale_width_kana_loose} # 仮名フォントの半角英数文字の横拡大率
            scale_height_kana=${scale_height_kana_loose} # 仮名フォントの半角英数文字の縦拡大率
            scale_width_hankaku=${scale_width_hankaku_loose} # 半角英数文字の横拡大率
            scale_height_hankaku=${scale_height_hankaku_loose} # 半角英数文字の縦拡大率
            width_hankaku=${width_hankaku_loose} # 半角文字幅
            move_x_hankaku=${move_x_hankaku_loose} # 半角文字移動量
            move_x_calt_latin=${move_x_calt_latin_loose} # ラテン文字のX座標移動量
            move_x_calt_symbol=${move_x_calt_symbol_loose} # 記号のX座標移動量
            ;;
        "a" )
            echo "Option: Set neutral and ambiguous characters to hankaku (excluding private use areas)"
            term_flag="true"
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
            echo "Option: Disable modified D,Q,V and Z"
            mod_flag="false"
            ;;
        "s" )
            echo "Option: Disable thousands separator"
            separator_flag="false"
            ;;
        "O" )
            echo "Option: Disable slashed zero"
            if [ "${ss_flag}" = "true" ]; then
                echo "Can't be disabled"
            else
                zero_mode="0"
            fi
            ;;
        "Q" )
            echo "Option: Enable another zero"
            if [ "${ss_flag}" = "true" ]; then
                echo "Can't be enabled"
            else
                zero_mode="2"
            fi
            ;;
        "c" )
            echo "Option: Disable calt feature"
            if [ "${ss_flag}" = "true" ]; then
                echo "Can't be disabled"
            else
                calt_flag="false"
            fi
            ;;
        "e" )
            echo "Option: Disable add Nerd fonts"
            nerd_flag="false"
            ;;
        "o" )
            echo "Option: Disable generate oblique style fonts"
            oblique_flag="false"
            ;;
        "j" )
            echo "Option: Reduce the number of emoji glyphs"
            emoji_flag="false"
            ;;
        "S" )
            echo "Option: Enable ss feature"
            visible_zenkaku_space_flag="false"
            visible_hankaku_space_flag="false"
            underline_flag="true"
 #            underline_flag="false" # デフォルトで下線無しにする場合
            improve_visibility_flag="true"
            mod_flag="false"
            zero_mode="1"
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

calt_init
shift $(($OPTIND - 1))

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
        input_latin_regular=$(find $fonts_directories -follow -name "${origin_latin_regular}" | head -n 1)
        input_latin_bold=$(find $fonts_directories -follow -name "${origin_latin_bold}" | head -n 1)
        if [ -z "${input_latin_regular}" -o -z "${input_latin_bold}" ]; then
            echo "Error: ${origin_latin_regular} and/or ${origin_latin_bold} not found" >&2
            exit 1
        fi
        # Search kana fonts
        input_kana_regular=$(find $fonts_directories -follow -iname "${origin_kana_regular}" | head -n 1)
        input_kana_bold=$(find $fonts_directories -follow -iname "${origin_kana_bold}"    | head -n 1)
        if [ -z "${input_kana_regular}" -o -z "${input_kana_bold}" ]; then
            echo "Error: ${origin_kana_regular} and/or ${origin_kana_bold} not found" >&2
            exit 1
        fi
        # Search kanzi fonts
        input_kanzi_regular=$(find $fonts_directories -follow -iname "${origin_kanzi_regular}" | head -n 1)
        input_kanzi_bold=$(find $fonts_directories -follow -iname "${origin_kanzi_bold}"    | head -n 1)
        if [ -z "${input_kanzi_regular}" -o -z "${input_kanzi_bold}" ]; then
            echo "Error: ${origin_kanzi_regular} and/or ${origin_kanzi_bold} not found" >&2
            exit 1
        fi
        # Search hentai kana fonts
        input_hentai_kana=$(find $fonts_directories -follow -iname "${origin_hentai_kana}" | head -n 1)
        if [ -z "${input_hentai_kana}" ]; then
            echo "Error: ${origin_hentai_kana} not found" >&2
            exit 1
        fi
        if [ ${nerd_flag} = "true" ]; then
            # Search nerd fonts
            input_nerd=$(find $fonts_directories -follow -iname "${origin_nerd}" | head -n 1)
            if [ -z "${input_nerd}" ]; then
                echo "Error: ${origin_nerd} not found" >&2
                exit 1
            fi
        fi
    elif ( [ ${nerd_flag} = "false" ] && [ $# -eq 7 ] ) || ( [ ${nerd_flag} = "true" ] && [ $# -eq 8 ] ); then
        # Get arguments
        input_latin_regular=$1
        input_latin_bold=$2
        input_kana_regular=$3
        input_kana_bold=$4
        input_kanzi_regular=$5
        input_kanzi_bold=$6
        input_hentai_kana=$7
        if [ ${nerd_flag} = "true" ]; then
            input_nerd=$8
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
        elif [ ! -r "${input_hentai_kana}" ]; then
            echo "Error: ${input_hentai_kana} not found" >&2
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
        [ "$(basename $input_hentai_kana)" != "${origin_hentai_kana}" ] &&
            echo "Warning: ${input_hentai_kana} does not seem to be ${origin_hentai_kana}" >&2
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
fontforge_v=$(${fontforge_command} -version)
fontforge_version=$(echo ${fontforge_v} | cut -d ' ' -f2)

# Check ttx existance
if ! which $ttx_command > /dev/null 2>&1
then
    echo "Error: ${ttx_command} command not found" >&2
    exit 1
fi
ttx_version=$(${ttx_command} --version)

# Make temporary directory
if [ -w "/tmp" -a "${leaving_tmp_flag}" = "false" ]; then
    tmpdir=$(mktemp -d /tmp/"${tmpdir_name}".XXXXXX) || exit 2
else
    tmpdir=$(mktemp -d ./"${tmpdir_name}".XXXXXX)    || exit 2
fi

# Remove temporary directory by trapping
if [ "${leaving_tmp_flag}" = "false" ]; then
    trap "if [ -d \"$tmpdir\" ]; then echo 'Remove temporary files'; rm -rf $tmpdir; echo 'Abnormally terminated'; fi; exit 3" HUP INT QUIT
    trap "if [ -d \"$tmpdir\" ]; then echo 'Remove temporary files'; rm -rf $tmpdir; echo 'Abnormally terminated'; fi" EXIT
else
    trap "echo 'Abnormally terminated'; exit 3" HUP INT QUIT
fi
echo

# フォントバージョンにビルドNo追加
buildNo=$(date "+%s")
buildNo=$((buildNo % 315360000 / 60))
buildNo=$(bc <<< "obase=16; ibase=10; ${buildNo}")
font_version="${font_version} (${buildNo})"

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
    ScaleToEm(${em_ascent1000}, ${em_descent1000})
    SetOS2Value("WinAscent",             ${win_ascent1000}) # WindowsGDI用(この範囲外は描画されない)
    SetOS2Value("WinDescent",            ${win_descent1000})
    SetOS2Value("TypoAscent",            ${typo_ascent1000}) # 組版・DirectWrite用(em値と合わせる)
    SetOS2Value("TypoDescent",          -${typo_descent1000})
    SetOS2Value("TypoLineGap",           ${typo_linegap1000})
    SetOS2Value("HHeadAscent",           ${hhea_ascent1000}) # Mac用
    SetOS2Value("HHeadDescent",         -${hhea_descent1000})
    SetOS2Value("HHeadLineGap",          ${hhea_linegap1000})

# --------------------------------------------------

# 使用しないグリフクリア
    Print("Remove not used glyphs")
    Select(0, 31); Clear(); DetachAndRemoveGlyphs()
    Select(0u018f); Clear(); DetachAndRemoveGlyphs() # Ə (グリフが間違っている)
    Select(65536, 65539); Clear(); DetachAndRemoveGlyphs()
 #    Select(65540); Clear(); DetachAndRemoveGlyphs() # ドット0
 #    Select(65541); Clear(); DetachAndRemoveGlyphs() # スラッシュ無し0
    Select(65542, 65615); Clear(); DetachAndRemoveGlyphs()

# Clear kerns, position, substitutions
    Print("Clear kerns, position, substitutions")
    RemoveAllKerns()

    lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups); j = 0
    while (j < numlookups)
        Print("Remove GSUB_" + lookups[j])
        RemoveLookup(lookups[j])
        j += 1
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
# ダイアクリティカルマークの width 変更
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

    Print("Edit numbers")
# 2 (全体を横に少し狭くして少し左に移動)
    Select(0u0032) # 2
    Scale(96, 100)
    # 細くなった縦線を戻す
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Scale(25, 20)
    Move(55, 145)
    PasteWithOffset(-350,-750)
    Select(65553);  Paste() # Temporary glyph
    Scale(25, 20)
    Rotate(-43)
    Move(-30, -60)
    Copy()
    Select(65552);  PasteInto() # Temporary glyph
    RemoveOverlap()
    Select(0u0032); Copy() # 2
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u0032) # 2
    if (input_list[i] == "${input_latin_regular}")
        PasteWithOffset(-3, 0)
    else
        PasteWithOffset(-5, 0)
    endif
    RemoveOverlap()
    # 左下が左に延びるのでカット
    Select(0u2588); Copy() # Full block
    Select(0u0032); PasteInto() # 2
    Select(65552);  Paste() # Temporary glyph
    Scale(15, 20)
    HFlip()
    if (input_list[i] == "${input_latin_regular}")
        Move(-208, -280)
    else
        Move(-223, -280)
    endif
    Copy()
    Select(0u0032); PasteInto() # 2
    OverlapIntersect()

    Move(-5, 0)
    SetWidth(500)

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# 3 (全体を少し横に拡げ、少し左に移動)
    # 太くなった縦線を元に戻すための準備
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Scale(50, 15);  Copy()
    if (input_list[i] == "${input_latin_regular}")
        Move(-77, 20)
        PasteWithOffset(-131, 222)
        PasteWithOffset(-135, -206)
        PasteWithOffset(-31, 169)
        PasteWithOffset(-10, -153)
        PasteWithOffset(-30, -108)
    else
        Move(-58, 30)
        PasteWithOffset(-139, 227)
        PasteWithOffset(-139, -207)
        PasteWithOffset(-50, 154)
        PasteWithOffset(-35, -124)
    endif
    Select(0u0033); Copy() # 3
    Select(65552);  PasteInto() # Temporary glyph
    RemoveOverlap()
    # 拡大
    Select(0u0033) # 3
    Scale(105, 100)
    # 縦線を元に戻す
    Select(65552) # Temporary glyph
    Copy()
    Select(0u0033); PasteWithOffset(4, 0) # 3
    OverlapIntersect()
    Simplify()
    Move(-5, 0)
    SetWidth(500)

    Select(65552); Clear() # Temporary glyph

# 4 (縦線を少し細くして横棒の右を少し延ばし、少し左に移動)
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
    Move(-10, 0)
    SetWidth(500)

    Select(65552); Clear() # Temporary glyph

# 7 (左上を折り曲げる、太さ変更し、少し右に移動)
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

    Move(5, 0)
    SetWidth(500)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph

# 6 (上端を少しカットして少し右に移動)
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
    Simplify()

    Move(5, 0)
    SetWidth(500)

    Select(65552); Clear() # Temporary glyph

# 9 (下端を少しカットして少し左に移動)
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
    Simplify()

    Move(-5, 0)
    SetWidth(500)

    Select(65552); Clear() # Temporary glyph

    Print("Edit alphabets")
# A (縦に延ばして上をカット、Regularは横棒を少し下げる)
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

# D (ss 用、クロスバーを付加することで少しくどい感じに)
    Select(0u0044); Copy() # D
    Select(${address_store_mod}); Paste() # 保管所
    Select(${address_store_mod} + ${num_mod_glyphs} * 1); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 2); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 3); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 4); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 5); Paste()

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

# H (縦の線を少し細くして横棒を少し太くする)
    # H
    # 左右に分解、横棒を作成
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Move(-230, 0)
    Select(65553);  Paste() # Temporary glyph
    Move(230, 0)
    Select(65554);  Paste() # Temporary glyph
    Scale(70, 1)

    Select(0u0048) # H
    Scale(96, 100); Copy()
    Select(65552);  PasteWithOffset(-11, 0) # Temporary glyph
    OverlapIntersect()
    Select(65553);  PasteWithOffset(11, 0) # Temporary glyph
    OverlapIntersect()
    Copy()
    # 合成
    Select(0u0048); Paste() # H
    Select(65552);  Copy() # Temporary glyph
    Select(0u0048); PasteInto() # H
    RemoveOverlap()
    Select(65554);  Copy() # Temporary glyph
    Select(0u0048) # H
    if (input_list[i] == "${input_latin_regular}")
        PasteWithOffset(0, 52)
        PasteWithOffset(0, 2)
        Move(4, 0)
    else
        PasteWithOffset(0, 65)
        PasteWithOffset(0, -15)
    endif
    RemoveOverlap()
    Simplify()
    SetWidth(500)

    # Ħ
    # 左右に分解、横棒を保存
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Move(-230, 0)
    Select(65553);  Paste() # Temporary glyph
    Move(230, 0)
    Select(65554);  Paste() # Temporary glyph
    Scale(70, 1)

    Select(0u0126) # Ħ
    Scale(96, 100); Copy()
    Select(65552);  PasteWithOffset(-11, 0) # Temporary glyph
    OverlapIntersect()
    Select(65553);  PasteWithOffset(11, 0) # Temporary glyph
    OverlapIntersect()
    Copy()
    # 合成
    Select(0u0126); Paste() # Ħ
    Select(65552);  Copy() # Temporary glyph
    Select(0u0126); PasteInto() # Ħ
    RemoveOverlap()
    Select(65554);  Copy() # Temporary glyph
    Select(0u0126) # Ħ
    if (input_list[i] == "${input_latin_regular}")
        PasteWithOffset(0, 52)
        PasteWithOffset(0, 2)
        Move(4, 0)
    else
        PasteWithOffset(0, 65)
        PasteWithOffset(0, -15)
    endif
    RemoveOverlap()
    Simplify()
    SetWidth(500)

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph
    Select(65554); Clear() # Temporary glyph

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

# I (頭とつま先を少しスリムに)
    # 中心の棒を保管
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Scale(50, 100)
    Select(0u0049); Copy() # I
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    # 頭とつま先をカット
    Select(0u0049); Copy() # I
    Move(10, 0)
    PasteWithOffset(-10, 0)
    OverlapIntersect()
    # 合成
    Select(65552);  Copy() # Temporary glyph
    Select(0u0049); PasteInto()
    if (input_list[i] == "${input_latin_regular}")
      Move(6, 0)
    endif
    SetWidth(500)
    RemoveOverlap()

    Select(65552); Clear() # Temporary glyph

    Select(0u2588); Copy() # Full block
    Select(0u00cc); PasteWithOffset(0,  1035); OverlapIntersect() # Ì
    Select(0u00cd); PasteWithOffset(0,  1035); OverlapIntersect() # Í
    Select(0u00ce); PasteWithOffset(0,  1035); OverlapIntersect() # Î
    Select(0u00cf); PasteWithOffset(0,  1035); OverlapIntersect() # Ï
    Select(0u0128); PasteWithOffset(0,  1035); OverlapIntersect() # Ĩ
    Select(0u012a); PasteWithOffset(0,  1035); OverlapIntersect() # Ī
    Select(0u012c); PasteWithOffset(0,  1035); OverlapIntersect() # Ĭ
    Select(0u012e); PasteWithOffset(0, -1000); OverlapIntersect() # Į
    if (input_list[i] == "${input_latin_regular}")
        Move(-4, 0)
    else
        Move(-16, 0)
    endif
    Select(0u0130); PasteWithOffset(0,  1035); OverlapIntersect() # İ
    Select(0u0208); PasteWithOffset(0,  1035); OverlapIntersect() # Ȉ
    Select(0u020a); PasteWithOffset(0,  1035); OverlapIntersect() # Ȋ
    Select(0u1e2e); PasteWithOffset(0,  1035); OverlapIntersect() # Ḯ
    Select(0u1ec8); PasteWithOffset(0,  1035); OverlapIntersect() # Ỉ
    Select(0u1eca); PasteWithOffset(0, -1001); OverlapIntersect() # Ị
    Select(0u0049); Copy() # I
    Select(0u00cc); PasteInto(); SetWidth(500) # Ì
    Select(0u00cd); PasteInto(); SetWidth(500) # Í
    Select(0u00ce); PasteInto(); SetWidth(500) # Î
    Select(0u00cf); PasteInto(); SetWidth(500) # Ï
    Select(0u0128); PasteInto(); SetWidth(500) # Ĩ
    Select(0u012a); PasteInto(); SetWidth(500) # Ī
    Select(0u012c); PasteInto(); SetWidth(500) # Ĭ
    Select(0u012e); PasteInto(); RemoveOverlap(); SetWidth(500) # Į
    Select(0u0130); PasteInto(); SetWidth(500) # İ
    Select(0u0208); PasteInto(); SetWidth(500) # Ȉ
    Select(0u020a); PasteInto(); SetWidth(500) # Ȋ
    Select(0u1e2e); PasteInto(); SetWidth(500) # Ḯ
    Select(0u1ec8); PasteInto(); SetWidth(500) # Ỉ
    Select(0u1eca); PasteInto(); SetWidth(500) # Ị
 #    Select(0u0197) # Ɨ
 #    Select(0u01cf) # Ǐ
 #    Select(0u1e2c) # Ḭ

# K (縦線をほんの少し細くして少し右へ移動)
    if (input_list[i] == "${input_latin_regular}")
        Select(0u2588); Copy() # Full block
        Select(0u004b) # K
        SelectMore(0u0136) # Ķ
        SelectMore(0u0198) # Ƙ
        PasteWithOffset(44, 0)
        OverlapIntersect()
    endif

    Select(0u004b) # K
    SelectMore(0u0136) # Ķ
    SelectMore(0u0198) # Ƙ
 #    SelectMore(0u01e8) # Ǩ
 #    SelectMore(0u1e30) # Ḱ
 #    SelectMore(0u1e32) # Ḳ
 #    SelectMore(0u1e34) # Ḵ
 #    SelectMore(0u2c69) # Ⱪ
 #    SelectMore(0ua740) # Ꝁ
 #    SelectMore(0ua742) # Ꝃ
 #    SelectMore(0ua744) # Ꝅ
 #    SelectMore(0ua7a2) # Ꞣ
    Move(10, 0)
    SetWidth(500)

# L (横棒をほんの少し太く)
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Move(0, -880)
    Select(0u004c); Copy() # L
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u004c) # L
    SelectMore(0u0139) # Ĺ
    SelectMore(0u013b) # Ļ
    SelectMore(0u013d) # Ľ
    SelectMore(0u013f) # Ŀ
    SelectMore(0u1e36) # Ḷ
    SelectMore(0u1e3a) # Ḻ
    PasteWithOffset(0, 4)
    RemoveOverlap()
    SetWidth(500)

    Select(0u0141) # Ł
    if (input_list[i] == "${input_latin_regular}")
        PasteWithOffset(7, 4)
    else
        PasteWithOffset(10, 0)
        RemoveOverlap()
        PasteWithOffset(10, 4)
    endif
    RemoveOverlap()
    SetWidth(500)

    Select(65552); Clear() # Temporary glyph

 #    Select(0u01c8) # ǈ
 #    Select(0u023d) # Ƚ
 #    Select(0u1e38) # Ḹ
 #    Select(0u1e3c) # Ḽ
 #    Select(0u2c60) # Ⱡ
 #    Select(0u2c62) # Ɫ
 #    Select(0ua748) # Ꝉ
 #    Select(0ua7ad) # Ɬ

# M (縦棒をほんの少し太く)
    if (input_list[i] == "${input_latin_regular}")
        # 左縦棒
        Select(0u2588); Copy() # Full block
        Select(65552);  Paste() # Temporary glyph
        Move(-420, 0)
        Select(0u004d); Copy() # M
        Select(65552);  PasteInto() # Temporary glyph
        OverlapIntersect()
        Copy()
        Select(0u004d); PasteWithOffset(-1, 0) # M
        # 右縦棒
        Select(0u2588); Copy() # Full block
        Select(65553);  Paste() # Temporary glyph
        Move(430, 0)
        Select(0u004d); Copy() # M
        Select(65553);  PasteInto() # Temporary glyph
        OverlapIntersect()
        Copy()
        Select(0u004d); PasteWithOffset(1, 0) # M
        RemoveOverlap()
        Move(-1, 0)
    else
        Select(0u004d); Move(-2, 0) # M
    endif
    SetWidth(500)

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

    Select(0u2588); Copy() # Full block
    Select(0u1e42); PasteWithOffset(0, -1020); OverlapIntersect() # Ṃ
    Select(0u004d); Copy() # M
    Select(0u1e42); PasteInto(); SetWidth(500) # Ṃ

 #    Select(0u1e3e) # Ḿ
 #    Select(0u1e40) # Ṁ
 #    Select(0u2c6e) # Ɱ

# N (縦棒をほんの少し太く)
    if (input_list[i] == "${input_latin_regular}")
        # 左縦棒
        Select(0u2588); Copy() # Full block
        Select(65552);  Paste() # Temporary glyph
        Move(-383, 0)
        Select(0u004e); Copy() # N
        Select(65552);  PasteInto() # Temporary glyph
        OverlapIntersect()
        Copy()
        Select(0u004e); PasteWithOffset(-1, 0) # N
        # 右縦棒
        Select(0u2588); Copy() # Full block
        Select(65553);  Paste() # Temporary glyph
        Move(392, 0)
        Select(0u004e); Copy() # N
        Select(65553);  PasteInto() # Temporary glyph
        OverlapIntersect()
        Copy()
        Select(0u004e); PasteWithOffset(1, 0) # N
        RemoveOverlap()
        Move(1, 0)
        SetWidth(500)

        Select(65552); Clear() # Temporary glyph
        Select(65553); Clear() # Temporary glyph

        Select(0u2588); Copy() # Full block
        Select(0u00d1); PasteWithOffset(0,  1035); OverlapIntersect() # Ñ
        Select(0u0143); PasteWithOffset(0,  1035); OverlapIntersect() # Ń
        Select(0u0145); PasteWithOffset(0, -1020); OverlapIntersect() # Ņ
        Select(0u0147); PasteWithOffset(0,  1035); OverlapIntersect() # Ň
        Select(0u1e44); PasteWithOffset(0,  1035); OverlapIntersect() # Ṅ
        Select(0u1e46); PasteWithOffset(0, -1020); OverlapIntersect() # Ṇ
        Select(0u1e48); PasteWithOffset(0, -1020); OverlapIntersect() # Ṉ
        Select(0u004e); Copy() # N
        Select(0u00d1); PasteInto(); SetWidth(500) # Ñ
        Select(0u0143); PasteInto(); SetWidth(500) # Ń
        Select(0u0145); PasteInto(); SetWidth(500) # Ņ
        Select(0u0147); PasteInto(); SetWidth(500) # Ň
        Select(0u1e44); PasteInto(); SetWidth(500) # Ṅ
        Select(0u1e46); PasteInto(); SetWidth(500) # Ṇ
        Select(0u1e48); PasteInto(); SetWidth(500) # Ṉ

 #        Select(0u019d) # Ɲ
 #        Select(0u0220) # Ƞ
 #        Select(0u01cb) # ǋ
 #        Select(0u01f8) # Ǹ
 #        Select(0u1e4a) # Ṋ
 #        Select(0ua790) # Ꞑ
 #        Select(0ua7a4) # Ꞥ
    endif

# Q (尻尾を下に延ばす)
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

# Q (ss用、突き抜けた尻尾でOと区別しやすく)
    Select(0u0051); Copy() # Q
    Select(${address_store_mod} + 1); Paste() # 保管所
    Select(${address_store_mod} + ${num_mod_glyphs} * 1 + 1); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 2 + 1); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 3 + 1); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 4 + 1); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 5 + 1); Paste()

    Select(0u002d); Copy() # Hyphen-minus
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Scale(22, 300); Copy()
        Select(0u0051); PasteWithOffset(6, -200) # Q
    else
        Scale(36, 230); Copy()
        Select(0u0051); PasteWithOffset(3, -170) # Q
    endif

    SetWidth(500)
    RemoveOverlap()

# V (ss用、左上にセリフを追加してYやレと区別しやすく)
    Select(0u0056); Copy() # V
    Select(${address_store_mod} + 2); Paste() # 保管所
    Select(${address_store_mod} + ${num_mod_glyphs} * 1 + 2); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 2 + 2); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 3 + 2); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 4 + 2); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 5 + 2); Paste()

    # 右上の先端を少し延ばす
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

# W (右の線を少し太くして真ん中を少しへこます)
    # 右の線を少し太くする
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
        RemoveOverlap()

        Select(0u2588); Copy() # Full block
        Select(65552);  Paste() # Temporary glyph
        Scale(22, 50); Rotate(-8); Move(220, 0)
        Select(0u0057); Copy() # W
        Select(65552);  PasteInto() # Temporary glyph
        OverlapIntersect()
        Copy()
        Select(0u0057) # W
        PasteWithOffset(4, 0)
        RemoveOverlap()

        Simplify()
    endif

    # 真ん中を少しへこます
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Move(-350, 0)
    PasteWithOffset(   0, -440)
    PasteWithOffset( 350, 0)
    RemoveOverlap()
    Copy()
    Select(0u0057); PasteInto() # W
    OverlapIntersect()
    if (input_list[i] == "${input_latin_regular}")
        Move(-5, 0)
    else
        Move(-2, 0)
    endif
    SetWidth(500)

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
 #    Select(0u1e86) # Ẇ
 #    Select(0u1e88) # Ẉ
 #    Select(0u2c72) # Ⱳ

# Ẕẕ (kana フォントを上書き)
    Select(0u1e5f); Copy()# ṟ
    Select(0u1e94, 0u1e95); Paste()# Ẕẕ
    Select(0u2588); Copy() # Full block
    Select(0u1e94, 0u1e95); PasteWithOffset(0, -1001); OverlapIntersect() # Ẕẕ
    Select(0u005a); Copy() # Z
    Select(0u1e94); PasteInto(); SetWidth(500) # Ẕ
    Select(0u007a); Copy() # z
    Select(0u1e95); PasteInto(); SetWidth(500) # ẕ

# Z (ss用、クロスバーを付加してゼェーットな感じに)
    Select(0u005a); Copy() # Z
    Select(${address_store_mod} + 3); Paste() # 保管所
    Select(${address_store_mod} + ${num_mod_glyphs} * 1 + 3); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 2 + 3); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 3 + 3); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 4 + 3); Paste()
    Select(${address_store_mod} + ${num_mod_glyphs} * 5 + 3); Paste()

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

# e (少し左に移動)
    Select(0u0065) # e
    SelectMore(0u00e8) # è
    SelectMore(0u00e9) # é
    SelectMore(0u00ea) # ê
    SelectMore(0u00eb) # ë
    SelectMore(0u0113) # ē
    SelectMore(0u0115) # ĕ
    SelectMore(0u0117) # ė
    SelectMore(0u0119) # ę
    SelectMore(0u011b) # ě
    SelectMore(0u0205) # ȅ
    SelectMore(0u0207) # ȇ
    SelectMore(0u1e15) # ḕ
    SelectMore(0u1e17) # ḗ
    SelectMore(0u1e1d) # ḝ
    SelectMore(0u1eb9) # ẹ
    SelectMore(0u1ebb) # ẻ
    SelectMore(0u1ebd) # ẽ
    SelectMore(0u1ebf) # ế
    SelectMore(0u1ec1) # ề
    SelectMore(0u1ec3) # ể
    SelectMore(0u1ec5) # ễ
    SelectMore(0u1ec7) # ệ
    if (input_list[i] == "${input_latin_regular}")
        Move(-2, 0)
 #        Move(3, 0)
    else
 #        Move(-3, 0)
        Move(2, 0)
    endif
        SetWidth(500)

 #    SelectMore(0u0247) # ɇ
 #    SelectMore(0u0229) # ȩ
 #    SelectMore(0u1d92) # ᶒ
 #    SelectMore(0u1e19) # ḙ
 #    SelectMore(0u1e1b) # ḛ
 #    SelectMore(0u2c78) # ⱸ
 #    SelectMore(0uab34) # ꬴ

# f (右端を少しカット、首を長くして少し右にずらす、Regular は横棒を少し太くする)
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

    # 首を長くする
    # 上
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Move(0, 858)
    else
        Move(0, 866)
    endif
    Select(0u0066); Copy() # f
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    # 下
    Select(0u2588); Copy() # Full block
    Select(0u0066) # f
    if (input_list[i] == "${input_latin_regular}")
        PasteWithOffset(0, -521)
    else
        PasteWithOffset(0, -513)
    endif
    OverlapIntersect()
    if (input_list[i] == "${input_latin_regular}") # 横棒を太くする
        Select(0u2588); Copy() # Full block
        Select(0u0066) # f
        PasteWithOffset(0, 403)
        OverlapIntersect()
        Copy()
        PasteWithOffset(0, -3)
        RemoveOverlap()
    endif
    # 合成
    Select(65552) # Temporary glyph
    Copy()
    Select(0u0066) # f
    if (input_list[i] == "${input_latin_regular}")
        PasteWithOffset(0, 5)
    else
        PasteWithOffset(0, 10)
    endif
    RemoveOverlap()

    Move(10, 0)
    SetWidth(500)
    Simplify()

    Select(65552); Clear() # Temporary glyph

 #    Select(0u0192) # ƒ
 #    Select(0u1d6e) # ᵮ
 #    Select(0u1d82) # ᶂ
 #    Select(0u1e1f) # ḟ
 #    Select(0ua799) # ꞙ

# h (ほんの少し横幅を拡げる)
    if (input_list[i] == "${input_latin_regular}")
        Select(0u0068) # h
        SelectMore(0u0127) # ħ
        Scale(101, 100)
        SetWidth(500)

        Select(0u2588); Copy() # Full block
        Select(0u0125); PasteWithOffset(-50,  1080); OverlapIntersect() # ĥ
        Select(0u1e25); PasteWithOffset(  0, -1020); OverlapIntersect() # ḥ
        Select(0u1e2b); PasteWithOffset(  0, -1020); OverlapIntersect() # ḥ
        Select(0u0068); Copy() # h
        Select(0u0125); PasteInto(); SetWidth(500) # ĥ
        Select(0u1e25); PasteInto(); SetWidth(500) # ḥ
        Select(0u1e2b); PasteInto(); SetWidth(500) # ḥ

 #        Select(0u021f) # ȟ
 #        Select(0u0266) # ɦ
 #        Select(0ua795) # ꞕ
 #        Select(0u1e23) # ḣ
 #        Select(0u1e29) # ḩ
 #        Select(0u1e27) # ḧ
 #        Select(0u1e96) # ẖ
 #        Select(0u2c68) # ⱨ
    endif

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
    SelectMore(0u0131) # ı
    SelectMore(0u0209) # ȉ
    SelectMore(0u020b) # ȋ
    SelectMore(0u1e2f) # ḯ
    SelectMore(0u1ec9) # ỉ
    SelectMore(0u1ecb) # ị
 #    Select(0u0268) # ɨ
 #    Select(0u01d0) # ǐ
 #    Select(0u1d96) # ᶖ
 #    Select(0u1e2d) # ḭ
    Move(5, 0)
    SetWidth(500)

# k (くの線を調整)
    if (input_list[i] == "${input_latin_regular}")
        # 右上
        Select(0u2588); Copy() # Full block
        Select(65552);  Paste() # Temporary glyph
        Scale(20, 25)
        Move(-10, 95)
        Rotate(-47)
        Select(0u006b); Copy() # k
        Select(65552);  PasteInto() # Temporary glyph
        OverlapIntersect()

        # 右下
        Select(0u2588); Copy() # Full block
        Select(65553);  Paste() # Temporary glyph
        Scale(20, 30)
        Move(100, -210)
        Rotate(40)
        Select(0u006b); Copy() # k
        Select(65553);  PasteInto() # Temporary glyph
        OverlapIntersect()
        Move(-7, 0)
        Select(0u006b); Copy() # k
        Select(65553);  PasteInto() # Temporary glyph
        OverlapIntersect()
        Copy()

       # 縦棒と右上
        Select(0u2588); Copy() # Full block
        Select(65554);  Paste() # Temporary glyph
        Scale(20, 25)
        Move(40, 74)
        Rotate(-47)
        PasteWithOffset(-305, 0)
        RemoveOverlap()
        Select(0u006b); Copy() # k
        Select(65554);  PasteInto() # Temporary glyph
        OverlapIntersect()
        Copy()

        # 合成
        Select(0u006b) # k
        Paste()
        Select(65552); Copy() # Temporary glyph
        Select(0u006b) # k
        PasteWithOffset(-2, 0)
        Select(65553); Copy() # Temporary glyph
        Select(0u006b) # k
        PasteWithOffset(0, 0)

        SetWidth(500)
        RemoveOverlap()
        Simplify()

        Select(65552); Clear() # Temporary glyph
        Select(65553); Clear() # Temporary glyph
        Select(65554); Clear() # Temporary glyph

        Select(0u2588); Copy() # Full block
        Select(0u0137); PasteWithOffset(0, -1015); OverlapIntersect() # ķ
        Select(0u006b); Copy() # k
        Select(0u0137); PasteInto(); SetWidth(500)

 #        Select(0u0199) # ƙ
 #        Select(0u01e9) # ǩ
 #        Select(0u1d84) # ᶄ
 #        Select(0u1e31) # ḱ
 #        Select(0u1e33) # ḳ
 #        Select(0u1e35) # ḵ
 #        Select(0u2c6a) # ⱪ
 #        Select(0ua741) # ꝁ
 #        Select(0ua743) # ꝃ
 #        Select(0ua745) # ꝅ
 #        Select(0ua7a3) # ꞣ
    endif

# ĸ (くの線を調整)
    if (input_list[i] == "${input_latin_regular}")
        # 右上
        Select(0u2588); Copy() # Full blocĸ
        Select(65552);  Paste() # Temporary glyph
        Scale(20, 25)
        Move(-10, 95)
        Rotate(-47)
        Select(0u0138); Copy() # ĸ
        Select(65552);  PasteInto() # Temporary glyph
        OverlapIntersect()

        # 右下
        Select(0u2588); Copy() # Full blocĸ
        Select(65553);  Paste() # Temporary glyph
        Scale(20, 30)
        Move(100, -210)
        Rotate(40)
        Select(0u0138); Copy() # ĸ
        Select(65553);  PasteInto() # Temporary glyph
        OverlapIntersect()
        Move(-7, 0)
        Select(0u0138); Copy() # ĸ
        Select(65553);  PasteInto() # Temporary glyph
        OverlapIntersect()
        Copy()

       # 縦棒と右上
        Select(0u2588); Copy() # Full blocĸ
        Select(65554);  Paste() # Temporary glyph
        Scale(20, 25)
        Move(40, 74)
        Rotate(-47)
        PasteWithOffset(-305, 0)
        RemoveOverlap()
        Select(0u0138); Copy() # ĸ
        Select(65554);  PasteInto() # Temporary glyph
        OverlapIntersect()
        Copy()

        # 合成
        Select(0u0138) # ĸ
        Paste()
        Select(65552); Copy() # Temporary glyph
        Select(0u0138) # ĸ
        PasteWithOffset(-2, 0)
        Select(65553); Copy() # Temporary glyph
        Select(0u0138) # ĸ
        PasteWithOffset(0, 0)

        SetWidth(500)
        RemoveOverlap()
        Simplify()

        Select(65552); Clear() # Temporary glyph
        Select(65553); Clear() # Temporary glyph
        Select(65554); Clear() # Temporary glyph
    endif

# l (縦線を少し細くし、セリフを少しカットして少し左へ移動)
    Select(0u006c); Copy() # l
    PasteWithOffset(-1, 0)
    OverlapIntersect()

    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Scale(30, 25)
    HFlip()
    if (input_list[i] == "${input_latin_regular}")
        Move(223, -200)
        PasteWithOffset(121, 600)
        PasteWithOffset(164, 0)
 #        Move(244, -200)
 #        PasteWithOffset(116, 600)
 #        PasteWithOffset(214, 0)
    else
        Move(244, -200)
        PasteWithOffset(101, 600)
        PasteWithOffset(144, 0)
 #        Move(261, -200)
 #        PasteWithOffset(96, 600)
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

# n (ほんの少し横幅を拡げる)
    if (input_list[i] == "${input_latin_regular}")
        Select(0u006e) # n
        Scale(101, 100)
        SetWidth(500)

        Select(0u2588); Copy() # Full block
        Select(0u00f1); PasteWithOffset(  0,   890); OverlapIntersect() # ñ
        Select(0u0144); PasteWithOffset(  0,   890); OverlapIntersect() # ń
        Select(0u0146); PasteWithOffset(  0, -1020); OverlapIntersect() # ņ
        Select(0u0148); PasteWithOffset(  0,   890); OverlapIntersect() # ň
        Select(0u1e45); PasteWithOffset(  0,   890); OverlapIntersect() # ṅ
        Select(0u1e47); PasteWithOffset(  0, -1020); OverlapIntersect() # ṇ
        Select(0u1e49); PasteWithOffset(  0, -1020); OverlapIntersect() # ṉ
        Select(0u006e); Copy() # n
        Select(0u00f1); PasteInto(); SetWidth(500) # ñ
        Select(0u0144); PasteInto(); SetWidth(500) # ń
        Select(0u0146); PasteInto(); SetWidth(500) # ņ
        Select(0u0148); PasteInto(); SetWidth(500) # ň
        Select(0u1e45); PasteInto(); SetWidth(500) # ṅ
        Select(0u1e47); PasteInto(); SetWidth(500) # ṇ
        Select(0u1e49); PasteInto(); SetWidth(500) # ṉ

 #        Select(0u0149) # ŉ
 #        Select(0u019e) # ƞ
 #        Select(0u01f9) # ǹ
 #        Select(0u0235) # ȵ
 #        Select(0u0272) # ɲ
 #        Select(0u0273) # ɳ
 #        Select(0u1d70) # ᵰ
 #        Select(0u1d87) # ᶇ
 #        Select(0u1e4b) # ṋ
 #        Select(0ua791) # ꞑ
 #        Select(0ua7a5) # ꞥ
 #        Select(0uab3b) # ꬻ
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
    Select(0u1e5f); PasteWithOffset(0, -1001); OverlapIntersect() # ṟ
    Select(0u0072); Copy() # r
    Select(0u0155); PasteInto(); SetWidth(500)
    Select(0u0157); PasteInto(); SetWidth(500)
    Select(0u0159); PasteInto(); SetWidth(500)
    Select(0u0211); PasteInto(); SetWidth(500)
    Select(0u0213); PasteInto(); SetWidth(500)
    Select(0u1e5b); PasteInto(); SetWidth(500)
    Select(0u1e5f); PasteInto(); SetWidth(500)
 #    Select(0u027c, 0u027e) # ɼɽɾ
 #    Select(0u1d72, 0u1d73) # ᵲᵳ
 #    Select(0u1d89) # ᶉ
 #    Select(0u1e5d) # ṝ
 #    Select(0ua75b) # ꝛ
 #    Select(0ua7a7) # ꞧ
 #    Select(0uab47) # ꭇ
 #    Select(0uab49) # ꭉ

# t (全体を少し起こして、ちょんまげを少し延ばす)
    # 横棒とその他を分ける
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Scale(100, 4.2)
        Move(0, 128)
    else
        Scale(100, 6.3)
        Move(0, 121)
    endif
    Copy()
    Select(65553);  Paste() # Temporary glyph
    Scale(95, 103)
    Move(0, -1)
    VFlip()
    Select(0u2588); Copy() # Full block
    Select(65553);  PasteInto() # その他を取り出すスクリーン

    # 横棒
    Select(0u0074); Copy() # t
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()

    # その他
    Select(65553); Copy() # Temporary glyph
    Select(0u0074); PasteInto() # t
    OverlapIntersect()
    if (input_list[i] == "${input_latin_regular}")
        Rotate(1, 299, -7)
    else
        Rotate(1, 299, -10)
    endif

    # ちょんまげ
    Select(0u2588); Copy() # Full block
    Select(65553);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Move(0, 857)
    else
        Move(0, 865)
    endif
    Select(0u0074); Copy() # t
    Select(65553);  PasteInto() # Temporary glyph
    OverlapIntersect()
    if (input_list[i] == "${input_latin_regular}")
        Scale(101, 106, 100, 457)
    else
        Scale(101, 106, 100, 465)
    endif

    # 下部
    Select(0u2588); Copy() # Full block
    Select(0u0074) # t
    PasteWithOffset(0, -560)
    OverlapIntersect()
    if (input_list[i] == "${input_latin_regular}")
        Scale(100, 102, 0, -7)
    else
        Scale(100, 102, 0, -10)
    endif

    # ちょんまげを貼り付け
    Select(65553);  Copy() # Temporary glyph
    Select(0u0074); PasteInto() # t
    Copy()
    Select(0u0167); Paste() # ŧ

    # 横棒を貼り付け
    Select(65552);  Copy() # Temporary glyph
    Select(0u0074); PasteWithOffset(-10, 0) # t
    Select(0u0167); PasteWithOffset(-10, 0) # ŧ
    if (input_list[i] == "${input_latin_regular}")
        PasteWithOffset(-10, -180)
    else
        PasteWithOffset(-10, -170)
    endif

    # 仕上げ
    Select(0u0074) # t
    SelectMore(0u0167) # ŧ
    RemoveOverlap()
    Simplify()
    RoundToInt()
    Move(5, 0)
    SetWidth(500)

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

    Select(0u0074); Copy() # t
    Select(0u0163); Paste() # ţ
    Select(0u00b8); Copy() # ¸
    Select(0u0163); PasteInto() # ţ
    RemoveOverlap()
    SetWidth(500)

    Select(0u2588); Copy() # Full block
    Select(0u0165); PasteWithOffset(320, 870); OverlapIntersect() # ť
    Select(0u021b); PasteWithOffset(0, -1013); OverlapIntersect() # ț
    Select(0u1e6d); PasteWithOffset(0, -1013); OverlapIntersect() # ṭ
    Select(0u1e6f); PasteWithOffset(0, -1013); OverlapIntersect() # ṯ
    Select(0u1e97); PasteWithOffset(0,  1030); OverlapIntersect() # ẗ
    Select(0u0074); Copy() # t
    Select(0u0165); PasteInto(); SetWidth(500)
    Select(0u021b); PasteInto(); SetWidth(500)
    Select(0u1e6d); PasteInto(); SetWidth(500)
    Select(0u1e6f); PasteInto(); SetWidth(500)
    Select(0u1e97); PasteInto(); SetWidth(500)
 #    Select(0u01ab) # ƫ
 #    Select(0u01ad) # ƭ
 #    Select(0u0236) # ȶ
 #    Select(0u0288) # ʈ
 #    Select(0u1d75) # ᵵ
 #    Select(0u1e6b) # ṫ
 #    Select(0u1e71) # ṱ
 #    Select(0u2c66) # ⱦ

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

# g をオープンテイルに変更するため、それに合わせてjpqyの尻尾を延ばす
# j (ついでに少し左に移動)
    # 下
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    Move(0, -935)
    Select(0u006a); Copy() # j
    Select(65552);  PasteInto()
    OverlapIntersect()
    # 上
    Select(0u2588); Copy() # Full block
    Select(0u006a) # j
    SelectMore(0u0135) # ĵ
    SelectMore(0u0237) # ȷ
    PasteWithOffset(0, 420)
    OverlapIntersect()
    # 合成
    Select(65552);  Copy()
    Select(0u006a) # j
    SelectMore(0u0135) # ĵ
    SelectMore(0u0237) # ȷ
    PasteWithOffset(0, -23)

    RemoveOverlap()
    Simplify()
    Move(-10, 0)
    SetWidth(500)

 #    Select(0u006a); Copy() # j
 #    Select(0u01f0) # ǰ
 #    Select(0u0249) # ɉ
 #    Select(0u029d) # ʝ

# p (ついでに縦線を少し細くして左に少し移動)
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
        Move(-3, 0)
    else
        PasteWithOffset(55, 0)
        Move(-2, 0)
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

# 点字 (追加)
    Print("Edit braille pattern dots")
    # 点
    Select(0u002e); Copy()
    Select(65552); Paste() # Temporary glyph
    Scale(90); Copy()
    j = 0
    while (j < 256)
        Select(0u2800 + j); Clear()
        if (0 != j % 2)
            PasteWithOffset( -87,  460)
        endif
        if (2 <= j % 4)
            PasteWithOffset( -87,  260)
        endif
        if (4 <= j % 8)
            PasteWithOffset( -87,   60)
        endif
        if (8 <= j % 16)
            PasteWithOffset( 113,  460)
        endif
        if (16 <= j % 32)
            PasteWithOffset( 113,  260)
        endif
        if (32 <= j % 64)
            PasteWithOffset( 113,   60)
        endif
        if (64 <= j % 128)
            PasteWithOffset( -87, -140)
        endif
        if (128 <= j % 256)
            PasteWithOffset( 113, -140)
        endif
        if (input_list[i] == "${input_latin_bold}")
            Move(0, -17)
        endif
        SetWidth(500)
        j += 1
    endloop

    j = 0
    while (j < 256)
        Select(0u2800 + j); Copy()
        Select(${address_store_braille} + j); Paste() # 保管所
        j += 1
    endloop

 #    # ブランク (全ての点字に枠を付けたため無効)
 #    # 点
 #    Select(0u002e); Copy()
 #    Select(65552); Paste() # Temporary glyph
 #    Scale(25); Copy()
 #    Select(0u2800)
 #    PasteWithOffset( -87,  460)
 #    PasteWithOffset( -87,  260)
 #    PasteWithOffset( -87,   60)
 #    PasteWithOffset( 113,  460)
 #    PasteWithOffset( 113,  260)
 #    PasteWithOffset( 113,   60)
 #    if (input_list[i] == "${input_latin_bold}")
 #        Move(0, -17)
 #    endif
 #    # 外枠
 #    Select(0u2588); Copy() # Full block
 #    Select(65553); Paste() # Temporary glyph
 #    Scale(103, 65)
 # #    Scale(103, 51)
 #    Select(65552); Paste() # Temporary glyph
 #    VFlip()
 #    Scale(97, 63)
 # #    Scale(97, 49)
 #    Copy()
 #    Select(65553); PasteInto() # Temporary glyph
 #    Move(0, 5)
 #    Copy()
 #    # 合成
 #    Select(0u2800); PasteInto()
 #    Scale(70)
 #    SetWidth(500)

    # 8点用外枠
    Select(0u2588); Copy() # Full block
    Select(65553); Paste() # Temporary glyph
    Scale(103, 65)
    Select(65552); Paste() # Temporary glyph
    VFlip()
    Scale(97, 63)
    Copy()
    Select(65553); PasteInto() # Temporary glyph
    ChangeWeight(-6)
    CorrectDirection()
    Move(0, -94)
    # 8点点字にコピー
    Copy()
    j = 0
    while (j < 192)
        Select(0u2840 + j); PasteInto()
        SetWidth(500)
        j += 1
    endloop

    # 6点用外枠
    # 8点用の外枠の下線を上側に複製
    Select(0u2588); Copy() # Full block
    Select(65552); Paste() # Temporary glyph
    Scale(105, 100)
    Move(0, -800)
    Select(65553); Copy() # Temporary glyph
    Select(65552); PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(65553); PasteWithOffset(0, 200) # Temporary glyph
 #    Select(65553); PasteWithOffset(0, 248) # Temporary glyph
    RemoveOverlap()
    # 複製した下線から下を削除
    Select(0u2588); Copy() # Full block
    Select(65552); Paste() # Temporary glyph
    Scale(105, 100)
    Copy()
    Select(65553); PasteWithOffset(0, 354) # Temporary glyph
 #    Select(65553); PasteWithOffset(0, 402) # Temporary glyph
    OverlapIntersect()
    # 6点点字にコピー
    Copy()
    j = 0
    while (j < 64)
        Select(0u2800 + j); PasteInto()
        SetWidth(500)
        j += 1
    endloop

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

    # Loose 版対応 (とりあえず拡大しておく)
    if ("${loose_flag}" == "true")
        Select(0u2800, 0u28ff)
        SelectMore(${address_store_braille}, ${address_store_braille} + 255) # 保管した点字
        Scale(112.5, 112.5, 256, 211)
        SetWidth(500)
    endif

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

# . -> magnified . ※ 点字より後に加工すること
    Select(0u002e); Scale(115, 115, 250, 0); SetWidth(500)

# : -> magnified :
    Select(0u003a); Scale(115, 115, 250, 0); SetWidth(500)

# ; -> magnified ;
    Select(0u003b); Scale(115, 115, 250, 0); SetWidth(500)

# \`´ (拡大して少し下に下げる)
    Select(0u0060) # \`
    SelectMore(0u00b4) # ´
    Scale(135, 135, 250, 600); Move(0, -20); SetWidth(500)

# ¨¯° ‘’ “” (拡大)
    Select(0u00a8) # ¨
    SelectMore(0u00af) # ¯ (英数文字より後に加工すること)
    SelectMore(0u00b0) # °
    SelectMore(0u2018, 0u2019) # ‘’
    SelectMore(0u201c, 0u201d) # “”
    Scale(115, 115, 250, 600); SetWidth(500)

# ¸͵ ‚„ ⸒ (拡大)
    Select(0u00b8) # ¸
 #    SelectMore(0u0375) # ͵(仮名フォント優先)
    SelectMore(0u201a) # ‚
    SelectMore(0u201e) # „
    SelectMore(0u2e12) # ⸒
    Scale(115, 115, 250, 0); SetWidth(500)

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

# ⟌ (追加)
    Select(0u005f); Copy() # _
    Select(0u27cc); Paste() # ⟌
    Scale(80, 100)
    Move(22, 780)
    Select(0u0029); Copy() # )
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Scale(70, 100)
    else
        Scale(70, 98)
    endif
    Select(0u27cc) # ⟌
    if (input_list[i] == "${input_latin_regular}")
        PasteWithOffset(-39, 26)
        Move(0, -7)
    else
        PasteWithOffset(-41, 30)
        Move(0, -5)
    endif
    RemoveOverlap()
    SetWidth(500)

# () ※ ⟌ より後で加工すること
    Select(0u0028); Move(0, 0); SetWidth(500) # (
    Select(0u0029); Move(-28, 0); SetWidth(500) # )

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

    Move(0, -14); SetWidth(500)
    RemoveOverlap()

    Select(65552); Clear()

# + (少し下げる)
    Select(0u002b); Move(0, -7); SetWidth(500) # +

# - (少し長くする)
    Select(0u002d) # -
    Scale(110, 100)
    SetWidth(500)

# <> (少し拡大して少し下げる)
    Select(0u003c, 0u003e) # <>
    Move(0, -5)
    Scale(104)
    if (input_list[i] == "${input_latin_regular}")
        ChangeWeight(-4)
    else
        ChangeWeight(-6)
    endif
    CorrectDirection()
    SetWidth(500)

# = (少し上げる)
    Select(0u003d); Move(0, 3); SetWidth(500) # -

# [] (少し上げる)
    Select(0u005b); Move(0, 15); SetWidth(500) # [
    Select(0u005d); Move(-49, 15); SetWidth(500) # ]

# _ (少し短くする) ※ ⟌ より後で加工すること
    Select(0u005f) # _
    Scale(94, 100)
    SetWidth(500)

# { } (上下の先端を短くし中央先端を延ばす、右上に少し移動)
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
    Move(22, 1); SetWidth(500)
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
    Move(16, 1); SetWidth(500)
    Simplify()

    Select(65552); Clear() # Temporary glyph

# × (少し下げる)
    Select(0u00d7); Move(0, -11); SetWidth(500) # ×

# ¿ (上に移動)
    Select(0u00bf) # ¿
    Move(0, 45)
    SetWidth(500)

# ‑ (追加)
    Select(0u2010); Copy() # ‐
    Select(0u2011); Paste() # ‑
    SetWidth(500)

# Ǝ (追加、後でグリフ上書き)
    Select(0u0045); Copy() # E
    Select(0u018e); Paste() # Ǝ
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
    Select(${address_store_visi_latin}); Paste() # 保管所

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

# ₤ (横線を2本にする)
    # 横棒を取り出す
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Scale(100, 4)
        Move(0, 50)
    else
        Scale(100, 6.3)
        Move(0, 51)
    endif
    Select(0u20a4); Copy() # ₤
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u20a4) # ₤
    if (input_list[i] == "${input_latin_regular}")
        PasteWithOffset(0, -110)
        RemoveOverlap()
        PasteWithOffset(0, -111)
    else
        PasteWithOffset(0, -140)
    endif
    RemoveOverlap()
    SetWidth(500)

# ℊ (追加)
    Select(0u0067); Copy() # g
    Select(0u210a); Paste() # ℊ
    SetWidth(500)

# ℗ (追加)
    # R を P にするスクリーン
    Select(0u2588); Copy() # Full block
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Scale(20, 10)
        Rotate(-9)
        Move(73, -106)
    else
        Scale(20, 9)
        Rotate(-9)
        Move(59, -105)
    endif
    VFlip()
    Select(0u2588); Copy() # Full block
    Select(65552);  PasteInto() # Temporary glyph
    Copy()
    Select(0u2117); Paste() # ℗
    # 合成
    Select(0u00ae); Copy() # ®
    Select(0u2117); PasteInto() # ℗
    OverlapIntersect()
    Simplify()
    SetWidth(500)

    Select(65552); Clear() # Temporary glyph

# ⅋ (追加)
    Select(0u0026); Copy() # &
    Select(0u214b); Paste() # ⅋
    Rotate(180)
    SetWidth(500)

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

# − (少し下げる)
    Select(0u2212); Move(0, -7); SetWidth(500) # −

# ∓ (漢字フォントを置換)
    Select(0u00b1); Copy() # ±
    Select(0u2213); Paste() # ∓
    VFlip()
    CorrectDirection()
    SetWidth(500)

# ∗ (少し下げる)
    Select(0u2217); Move(0, -30); SetWidth(500) # ∗

# √ (ボールドのウェイト調整)
    Select(0u221a) # √
    if (input_list[i] == "${input_latin_bold}")
        ChangeWeight(-14)
        CorrectDirection()
        SetWidth(500)
    endif

# ∛ (追加) ※ √ より後に加工すること
    Select(0u0033); Copy() # 3
    Select(0u221b); Paste() # ∛
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(-95, 400)

    Select(0u221a); Copy() # √
    Select(0u221b); PasteInto() # ∛
    SetWidth(500)

# ∜ (追加) ※ √ より後に加工すること
    Select(0u0034); Copy() # 4
    Select(0u221c); Paste() # ∜
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(-95, 400)

    Select(0u221a); Copy() # √
    Select(0u221c); PasteInto() # ∜
    SetWidth(500)

# ≠ (少し下げる)
    Select(0u2260); Move(0, -2); SetWidth(500) # ≠

# ⌀ (追加)
    # 丸
    Select(0u25cb); Copy() # ○
    Select(0u2300); Paste() # ⌀
    Move(1, 18)
    Scale(130)
    if (input_list[i] == "${input_latin_regular}")
        ChangeWeight(6)
    else
        Scale(110)
        ChangeWeight(-24)
    endif
    CorrectDirection()
    # 斜線
    Select(0u007c); Copy() # |
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Scale(98)
        ChangeWeight(-6)
    else
        Scale(101)
        ChangeWeight(-24)
    endif
    CorrectDirection()
    Move(0, 76)
    Rotate(-45)
    Copy()
    Select(0u2300); PasteInto() # ⌀
    Move(230, 0)
    SetWidth(1000)
    RemoveOverlap()
    Select(65552); Clear() # Temporary glyph

# ⌖ (追加)
    # 丸
    Select(0u25cb); Copy() # ○
    Select(0u2316); Paste() # ⌖
    Move(1, 18)
    Scale(130)
    if (input_list[i] == "${input_latin_regular}")
        ChangeWeight(6)
    else
        Scale(110)
        ChangeWeight(-24)
    endif
    CorrectDirection()
    # 縦棒・横棒
    Select(0u007c); Copy() # |
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Scale(98)
        ChangeWeight(-6)
    else
        Scale(101)
        ChangeWeight(-24)
    endif
    CorrectDirection()
    Move(0, 76); Copy()
    Rotate(90);  PasteInto()
    Copy()
    Select(0u2316); PasteInto() # ⌖
    Move(230, 0)
    SetWidth(1000)
    RemoveOverlap()
    Select(65552); Clear() # Temporary glyph

# ⌭ (追加)
    # 丸
    Select(0u25cb); Copy() # ○
    Select(0u232d); Paste() # ⌭
    Move(1, 18)
    Scale(130)
    if (input_list[i] == "${input_latin_regular}")
        ChangeWeight(6)
    else
        Scale(110)
        ChangeWeight(-24)
    endif
    CorrectDirection()
    # 斜線
    Select(0u007c); Copy() # |
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Scale(98)
        ChangeWeight(-6)
    else
        Scale(101)
        ChangeWeight(-24)
    endif
    CorrectDirection()
    Move(0, 76)
    Rotate(-30)
    Copy()
    Select(0u232d) # ⌭
    PasteWithOffset(-265, 48)
    PasteWithOffset(265, -48)
    Move(230, 0)
    SetWidth(1000)
    RemoveOverlap()
    Select(65552); Clear() # Temporary glyph

# ⌴ (追加)
    Select(0u2302); Copy() # ⌂
    Select(0u2334); Paste() # ⌴
    Select(0u2588); Copy() # Full block
    Select(0u2334); PasteWithOffset(0, -750) # ⌴
    OverlapIntersect()
    Scale(150)
    CorrectDirection()
    Move(230, 170)
    SetWidth(1000)

# ⌂ (全角にする) ※ ⌴ より後に加工すること
    Select(0u2302) # ⌂
    Scale(150)
    CorrectDirection()
    Move(230, 120)
    SetWidth(1000)

# ⌘ (全角にする)
    Select(0u2318) # ⌘
    Scale(150)
    Move(230, 120)
    SetWidth(1000)

# ⌥ (ウェイトを調整して全角にする)
    Select(0u2325) # ⌥
    Scale(140, 130)
    if (input_list[i] == "${input_latin_regular}")
        ChangeWeight(2)
    else
        ChangeWeight(8)
    endif
    CorrectDirection()
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

# ⎇ (追加 ) ※ ⌥ より後に加工すること
    Select(0u2325); Copy() # ⌥
    Select(0u2387); Paste() # ⎇
    VFlip()
    CorrectDirection()
    SetWidth(1000)

# ⎈ (追加)
    # 丸
    Select(0u25cb); Copy() # ○
    Select(0u2388); Paste() # ⎈
    Move(1, 18)
    Scale(130)
    if (input_list[i] == "${input_latin_regular}")
        ChangeWeight(6)
    else
        Scale(110)
        ChangeWeight(-24)
    endif
    CorrectDirection()
    # アスタリスク
    Select(0u007c); Copy() # |
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_latin_regular}")
        Scale(98)
        ChangeWeight(-6)
    else
        Scale(101)
        ChangeWeight(-24)
    endif
    CorrectDirection()
    Move(0, 76); Copy()
    Rotate(-60); PasteInto()
    Rotate(120); PasteInto()
    Copy()
    Select(0u2388); PasteInto() # ⎈
    Move(230, 0)
    SetWidth(1000)
    RemoveOverlap()
    Select(65552); Clear() # Temporary glyph

# ⎋ (全角にする)
    Select(0u238b) # ⎋
    Scale(150)
    Move(250, 18)
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

# ⚹ (カナフォントを置換) ※ * より後に加工すること
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
    Select(0u2702); PasteWithOffset(3, -520) # ✂
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

    Print("Edit zero")
# スラッシュ無し0を保管 ※分数より前に加工すること
    Select(65541); Copy() # スラッシュ無し0
    Select(${address_store_zero}); Paste(); SetWidth(500) # 保管所
    Select(${address_store_zero} + 3); Paste() # 下線無し全角
    Select(${address_store_zero} + 4); Paste() # 下線付き全角横書き
    Select(${address_store_zero} + 5); Paste() # 下線付き全角縦書き

    Select(65541); Copy() # スラッシュ無し0
    Select(${address_store_zero} + 1); Paste()
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_super})
    SetWidth(500)

    Select(65541); Copy() # スラッシュ無し0
    Select(${address_store_zero} + 2); Paste()
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_sub})
    SetWidth(500)

# ドット0を保管
    Select(65540); Copy() # ドット0
    Select(${address_store_zero} + 6); Paste(); SetWidth(500) # 保管所
    Select(${address_store_zero} + 3 + 6); Paste() # 下線無し全角
    Select(${address_store_zero} + 4 + 6); Paste() # 下線付き全角横書き
    Select(${address_store_zero} + 5 + 6); Paste() # 下線付き全角縦書き

    Select(65540); Copy() # ドット0
    Select(${address_store_zero} + 1 + 6); Paste()
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_super})
    SetWidth(500)

    Select(65540); Copy() # ドット0
    Select(${address_store_zero} + 2 + 6); Paste()
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_sub})
    SetWidth(500)
    Select(65540); Clear() # ドット0

# 分数 (追加、全角化)
    Print("Edit fraction")
 #    Select(0u004f); Copy() # O スラッシュ無し0を作成
 #    if (input_list[i] == "${input_latin_regular}")
 #        Select(65552); Paste() # Temporary glyph
 #        Scale(80, 100)
 #        Select(65553); Paste() # Temporary glyph
 #        Scale(87, 100)
 #        Select(65552); Copy() # Temporary glyph
 #        Select(65553); PasteInto() # Temporary glyph
 #        RemoveOverlap()
 #    else
 #        Select(65552);  Paste() # Temporary glyph
 #        Scale(92, 100)
 #    endif
    Select(65541) # スラッシュ無し0
    Copy()
    Select(0u2189); Paste() # ↉
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(${move_x_numerator}, ${move_y_numerator}); Copy()
    Select(0u2152); Paste()
    Move(-(${move_x_numerator}) + ${move_x_denominator} + 150, -(${move_y_numerator}) + ${move_y_denominator}) # ⅒

    Select(0u0031); Copy() # 1
    Select(0u00bc); Paste() # ¼
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(${move_x_numerator} + 30, ${move_y_numerator}); Copy()
    Select(0u00bd); Paste() # ½
    Select(0u2150); Paste() # ⅐
    Select(0u2151); Paste() # ⅑
    Select(0u2153); Paste() # ⅓
    Select(0u2155); Paste() # ⅕
    Select(0u2159); Paste() # ⅙
    Select(0u215b); Paste() # ⅛
    Select(0u215f); Paste() # ⅟
    Select(0u2152); PasteWithOffset(-(${move_x_numerator}) + ${move_x_denominator} - 130, -(${move_y_numerator}) + ${move_y_denominator}) # ⅒
    Scale(75, 100)
    Select(0u2152); PasteInto() # ⅒

    Select(0u0032); Copy() # 2
    Select(0u2154); Paste() # ⅔
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(${move_x_numerator}, ${move_y_numerator}); Copy()
    Select(0u2156); Paste() # ⅖

    Select(0u0032); Copy() # 2
    Select(0u2154); Paste() # ⅔
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(${move_x_numerator}, ${move_y_numerator}); Copy()
    Select(0u2156); Paste() # ⅖
    Select(0u00bd); PasteWithOffset(-(${move_x_numerator}) + ${move_x_denominator}, -(${move_y_numerator}) + ${move_y_denominator}) # ½

    Select(0u0033); Copy() # 3
    Select(0u00be); Paste() # ¾
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(${move_x_numerator}, ${move_y_numerator}); Copy()
    Select(0u2157); Paste() # ⅗
    Select(0u215c); Paste() # ⅜
    Select(0u2153); PasteWithOffset(-(${move_x_numerator}) + ${move_x_denominator}, -(${move_y_numerator}) + ${move_y_denominator}) # ⅓
    Select(0u2154); PasteWithOffset(-(${move_x_numerator}) + ${move_x_denominator}, -(${move_y_numerator}) + ${move_y_denominator}) # ⅔
    Select(0u2189); PasteWithOffset(-(${move_x_numerator}) + ${move_x_denominator}, -(${move_y_numerator}) + ${move_y_denominator}) # ↉

    Select(0u0034); Copy() # 4
    Select(0u2158); Paste() # ⅘
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(${move_x_numerator} -10, ${move_y_numerator}); Copy()
    Select(0u00bc); PasteWithOffset(-(${move_x_numerator}) + ${move_x_denominator} - 50, -(${move_y_numerator}) + ${move_y_denominator}) # ¼
    Select(0u00be); PasteWithOffset(-(${move_x_numerator}) + ${move_x_denominator} - 50, -(${move_y_numerator}) + ${move_y_denominator}) # ¾

    Select(0u0035); Copy() # 5
    Select(0u215a); Paste() # ⅚
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(${move_x_numerator} - 20, ${move_y_numerator}); Copy()
    Select(0u215d); Paste() # ⅝
    Select(0u2155); PasteWithOffset(-(${move_x_numerator}) + ${move_x_denominator} + 20, -(${move_y_numerator}) + ${move_y_denominator}) # ⅕
    Select(0u2156); PasteWithOffset(-(${move_x_numerator}) + ${move_x_denominator} + 20, -(${move_y_numerator}) + ${move_y_denominator}) # ⅖
    Select(0u2157); PasteWithOffset(-(${move_x_numerator}) + ${move_x_denominator} + 20, -(${move_y_numerator}) + ${move_y_denominator}) # ⅗
    Select(0u2158); PasteWithOffset(-(${move_x_numerator}) + ${move_x_denominator} + 20, -(${move_y_numerator}) + ${move_y_denominator}) # ⅘

    Select(0u0036); Copy() # 6
    Select(65552);  Paste() # Temporary glyph
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(${move_x_denominator}, ${move_y_denominator}); Copy()
    Select(0u2159); PasteInto() # ⅙
    Select(0u215a); PasteInto() # ⅚

    Select(0u0037); Copy() # 7
    Select(0u215e); Paste() # ⅞
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(${move_x_numerator} + 40, ${move_y_numerator}); Copy()
    Select(0u2150); PasteWithOffset(-(${move_x_numerator}) + ${move_x_denominator} - 20, -(${move_y_numerator}) + ${move_y_denominator}) # ⅐

    Select(0u0038); Copy() # 8
    Select(65552);  Paste() # Temporary glyph
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(${move_x_denominator}, ${move_y_denominator}); Copy()
    Select(0u215b); PasteInto() # ⅛
    Select(0u215c); PasteInto() # ⅜
    Select(0u215d); PasteInto() # ⅝
    Select(0u215e); PasteInto() # ⅞

    Select(0u0039); Copy() # 9
    Select(65552);  Paste() # Temporary glyph
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(${move_x_denominator}, ${move_y_denominator}); Copy()
    Select(0u2151); PasteInto() # ⅑

    # 斜線
    Select(0u007c); Copy() # |
    Select(65552);  Paste() # Temporary glyph
    Scale(85, 110)
    Rotate(-35)
    Move(230, 90)
    Copy()
    Select(0u00bc); # ¼
    SelectMore(0u00bd); # ½
    SelectMore(0u00be); # ¾
    SelectMore(0u2189); # ↉
    PasteInto()
    SetWidth(1000)

    j = 0
    while (j < 16)
      Select(0u2150 + j); PasteInto() # ⅐ - ⅟
      SetWidth(1000)
      j += 1
    endloop

    Select(65541); Clear() # スラッシュ無し0
    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# | (破線にし、縦を短くして少し上へ移動) ※ ⌀⌖⌭⎈、分数 より後に加工すること
# ¦ (隙間を開ける)

    # 破線無しを保管して加工
    Select(0u007c); Copy() # |
    Select(${address_store_visi_latin} + 1); Paste() # 保管所
    if (input_list[i] == "${input_latin_regular}")
        Move(0, 40)
        PasteWithOffset(0, 58)
    else
        Move(0, 45)
        PasteWithOffset(0, 58)
    endif
    Move(0, 13)
    SetWidth(500)
    OverlapIntersect()

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

    # 保管したグリフを利用して高さを統一
    Select(${address_store_visi_latin} + 1); Copy() # 保管所
    Select(0u007c); PasteInto() # |
    SetWidth(500)
    OverlapIntersect()

    Select(0u00a6); PasteInto() # ¦
    SetWidth(500)
    OverlapIntersect()

# プログレスバー (追加)
    # 外枠
    Select(0u2588); Copy() # Full block
    Select(65553); Paste() # Temporary glyph
    Scale(106, 50)
    Select(65552); Paste() # Temporary glyph
    VFlip()
    Scale(94, 46)
    Copy()
    Select(65553); PasteInto() # Temporary glyph
    CorrectDirection()
    Move(0, 6)
    Copy()
    Select(0uee00, 0uee02); Paste() # 私用領域
    # 外枠の左右の線を削除
    Select(0u2588); Copy() # Full block
    Select(65553); Paste() # Temporary glyph
    Scale(130, 52)
    Select(65552); Paste() # Temporary glyph
    VFlip()
    Scale(110, 46)
    Copy()
    Select(65553); PasteInto() # Temporary glyph
    CorrectDirection()
    Move(0, 6)
    Copy()
    Select(0uee00); PasteWithOffset(50, 0) # 
    OverlapIntersect(); Move(60, 0)
    Select(0uee01); PasteInto() # 
    OverlapIntersect(); Scale(120, 100)
    Select(0uee02); PasteWithOffset(-50, 0) # 
    OverlapIntersect(); Move(-60, 0)
    # 外枠を複製
    Select(0uee00); Copy(); Select(0uee03); Paste() #  
    Select(0uee01); Copy(); Select(0uee04); Paste() #  
    Select(0uee02); Copy(); Select(0uee05); Paste() #  
    # バーの中身
    Select(0u2588); Copy() # Full block
    Select(65552); Paste() # Temporary glyph
    Scale(106, 37)
    Copy()
    Select(0uee03); PasteWithOffset(99 + 60, 0) # 
    Select(0uee04); PasteInto(); Scale(120, 100) # 
    Select(0uee05); PasteWithOffset(-99 - 60, 0) # 
    # はみ出た部分をカット
    Select(0u2588); Copy() # Full block
    Select(65552); Paste() # Temporary glyph
    Scale(120, 52)
    Copy()
    Select(0uee00); PasteInto() # 
    OverlapIntersect(); SetWidth(500)
    Select(0uee01); PasteInto() # 
    OverlapIntersect(); SetWidth(500)
    Select(0uee02); PasteInto() # 
    OverlapIntersect(); SetWidth(500)
    Select(0uee03); PasteInto() # 
    OverlapIntersect(); SetWidth(500)
    Select(0uee04); PasteInto() # 
    OverlapIntersect(); SetWidth(500)
    Select(0uee05); PasteInto() # 
    OverlapIntersect(); SetWidth(500)

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# スピニングホイール (追加)
    Select(0u25cf); Copy() # ●
    Select(0uee06); Paste() # 
    Scale(115)
    Select(0u25c6); Copy() # ◆
    Select(65552); Paste() # Temporary glyph
    Scale(100, 173)
    Copy()
    Select(0uee06) # 
    PasteWithOffset(0, 389 + 30)
    PasteWithOffset(0, -389 + 30)
    OverlapIntersect()
    SetWidth(500)
    Copy()
    Select(0uee07); Paste() # 
    Rotate(-30, 250, 308)
    SetWidth(500)
    Select(0uee08); Paste() # 
    Rotate(-60, 250, 308)
    SetWidth(500)
    Select(0uee09); Paste() # 
    Rotate(-90, 250, 308)
    SetWidth(500)
    Select(0uee0a); Paste() # 
    Rotate(-120, 250, 308)
    SetWidth(500)
    Select(0uee0b); Paste() # 
    Rotate(-150, 250, 308)
    SetWidth(500)

    Select(65552); Clear() # Temporary glyph

# 上付き、下付き文字を置き換え
    Print("Edit superscrips and subscripts")

    # 下付き
    lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups)
    lookupName = "'subs' 下つき文字"
    AddLookup(lookupName, "gsub_single", 0, [["subs",[["DFLT",["dflt"]]]]])
    lookupSub = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub)

    # ᵢ-ᵥ
    orig = [0u0069, 0u0072, 0u0075, 0u0076]
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(0u1d62 + j); Paste()
        Scale(${scale_super_sub}, 250, 0)
        ChangeWeight(${weight_super_sub})
        CorrectDirection()
        Move(0, ${move_y_sub})
        SetWidth(500)
        glyphName = GlyphInfo("Name") # subs フィーチャ追加
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
    endloop

    # ₀-₉
    j = 0
    while (j < 10)
        Select(0u0030 + j); Copy()
        Select(0u2080 + j); Paste()
        Scale(${scale_super_sub}, 250, 0)
        ChangeWeight(${weight_super_sub})
        CorrectDirection()
        Move(0, ${move_y_sub})
        SetWidth(500)
        glyphName = GlyphInfo("Name") # subs フィーチャ追加
        Select(0u0030 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
    endloop

    # ₊-ₜ
    orig = [0u002b, 0u2212, 0u003d, 0u0028, 0u0029, 0u0000,\
            0u0061, 0u0065, 0u006f, 0u0078, 0u0259,\
            0u0068, 0u006b, 0u006c, 0u006d,\
            0u006e, 0u0070, 0u0073, 0u0074] # 0u0000はダミー
    j = 0
    while (j < SizeOf(orig))
        if (orig[j] != 0u0000)
            Select(orig[j]); Copy()
            Select(0u208a + j); Paste()
            Scale(${scale_super_sub}, 250, 0)
            ChangeWeight(${weight_super_sub})
            CorrectDirection()
            Move(0, ${move_y_sub})
            SetWidth(500)
            glyphName = GlyphInfo("Name") # subs フィーチャ追加
            Select(orig[j])
            AddPosSub(lookupSub, glyphName)
        endif
        j += 1
    endloop

    # ₋
    Select(0u208b) # ₋
    glyphName = GlyphInfo("Name") # subs フィーチャ追加
    Select(0u002d) # -
    AddPosSub(lookupSub, glyphName)

    # ⱼ
    Select(0u006a); Copy() # j
    Select(0u2c7c); Paste() # ⱼ
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_sub})
    SetWidth(500)
    glyphName = GlyphInfo("Name") # subs フィーチャ追加
    Select(0u006a) # j
    AddPosSub(lookupSub, glyphName)

    # 上付き
    lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups)
    lookupName = "'sups' 上つき文字"
    AddLookup(lookupName, "gsub_single", 0, [["sups",[["DFLT",["dflt"]]]]])
    lookupSub = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub)

    # ¹
    Select(0u0031); Copy() # 1
    Select(0u00b9); Paste() # ¹
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_super})
    SetWidth(500)
    glyphName = GlyphInfo("Name") # sups フィーチャ追加
    Select(0u0031) # 1
    AddPosSub(lookupSub, glyphName)

    # ²
    Select(0u0032); Copy() # 2
    Select(0u00b2); Paste() # ²
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_super})
    SetWidth(500)
    glyphName = GlyphInfo("Name") # sups フィーチャ追加
    Select(0u0032) # 2
    AddPosSub(lookupSub, glyphName)

    # ³
    Select(0u0033); Copy() # 3
    Select(0u00b3); Paste() # ³
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_super})
    SetWidth(500)
    glyphName = GlyphInfo("Name") # sups フィーチャ追加
    Select(0u0033) # 3
    AddPosSub(lookupSub, glyphName)

    # ʰ-ʸ
    orig = [0u0068, 0u0000, 0u006a, 0u0072,\
            0u0000, 0u027b, 0u0000, 0u0077,\
            0u0079] # 0u0000はダミー
    j = 0
    while (j < SizeOf(orig))
        if (orig[j] != 0u0000)
            Select(orig[j]); Copy()
            Select(0u02b0 + j); Paste()
            Scale(${scale_super_sub}, 250, 0)
            ChangeWeight(${weight_super_sub})
            CorrectDirection()
            Move(0, ${move_y_super})
            SetWidth(500)
            glyphName = GlyphInfo("Name") # sups フィーチャ追加
            Select(orig[j])
            AddPosSub(lookupSub, glyphName)
        endif
        j += 1
    endloop

    # ˡ-ˣ
    orig = [0u006c, 0u0073, 0u0078]
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(0u02e1 + j); Paste()
        Scale(${scale_super_sub}, 250, 0)
        ChangeWeight(${weight_super_sub})
        CorrectDirection()
        Move(0, ${move_y_super})
        SetWidth(500)
        glyphName = GlyphInfo("Name") # sups フィーチャ追加
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
    endloop

    # ᴬ-ᵛ
    orig = [0u0041, 0u00c6, 0u0042, 0u0000,\
            0u0044, 0u0045, 0u018e, 0u0047,\
            0u0048, 0u0049, 0u004a, 0u004b,\
            0u004c, 0u004d, 0u004e, 0u0000,\
            0u004f, 0u0000, 0u0050, 0u0052,\
            0u0054, 0u0055, 0u0057, 0u0061,\
            0u0000, 0u0000, 0u0000, 0u0062,\
            0u0064, 0u0065, 0u0259, 0u0000,\
            0u0000, 0u0067, 0u0000, 0u006b,\
            0u006d, 0u014b, 0u006f, 0u0000,\
            0u0000, 0u0000, 0u0070, 0u0074,\
            0u0075, 0u0000, 0u0000, 0u0076] # 0u0000はダミー
    j = 0
    while (j < SizeOf(orig))
        if (orig[j] != 0u0000)
            if (orig[j] == 0u0044) # D
                Select(${address_store_mod}); Copy() # 保管した D
            else
                Select(orig[j]); Copy()
            endif
            Select(0u1d2c + j); Paste()
            Scale(${scale_super_sub}, 250, 0)
            ChangeWeight(${weight_super_sub})
            CorrectDirection()
            Move(0, ${move_y_super})
            SetWidth(500)
            glyphName = GlyphInfo("Name") # sups フィーチャ追加
            Select(orig[j])
            AddPosSub(lookupSub, glyphName)
        endif
        j += 1
    endloop

    # ᴻ (グリフ作成のみ)
    Select(0u004e); Copy() # N
    Select(0u1d3b); Paste() # ᴻ
    HFlip(); CorrectDirection()
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_super})
    SetWidth(500)

    # ᵆ (グリフ作成のみ)
    Select(0u00e6); Copy() # æ
    Select(0u1d46); Paste() # ᵆ
    Rotate(180)
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_super})
    SetWidth(500)

    # ᵎ (グリフ作成のみ)
    Select(0u0069); Copy() # i
    Select(0u1d4e); Paste() # ᵎ
    Rotate(180)
    if (input_list[i] == "${input_latin_regular}")
        Move(0, -199)
    else
        Move(0, -212)
    endif
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_super})
    SetWidth(500)

    # ᵙ (グリフ作成のみ)
    Select(0u0075); Copy() # u
    Select(0u1d59); Paste() # ᵙ
    Rotate(90)
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_super})
    SetWidth(500)

    # ᶜ-ᶞ
    orig = [0u0063, 0u0000, 0u00f0] # 0u0000はダミー
    j = 0
    while (j < SizeOf(orig))
        if (orig[j] != 0u0000)
            Select(orig[j]); Copy()
            Select(0u1d9c + j); Paste()
            Scale(${scale_super_sub}, 250, 0)
            ChangeWeight(${weight_super_sub})
            CorrectDirection()
            Move(0, ${move_y_super})
            SetWidth(500)
            glyphName = GlyphInfo("Name") # sups フィーチャ追加
            Select(orig[j])
            AddPosSub(lookupSub, glyphName)
        endif
        j += 1
    endloop

    # ᶠ
    Select(0u0066); Copy() # f
    Select(0u1da0); Paste() # ᶠ
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_super})
    SetWidth(500)
    glyphName = GlyphInfo("Name") # sups フィーチャ追加
    Select(0u0066) # f
    AddPosSub(lookupSub, glyphName)

    # ᶻ
    Select(0u007a); Copy() # z
    Select(0u1dbb); Paste() # ᶻ
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_super})
    SetWidth(500)
    glyphName = GlyphInfo("Name") # sups フィーチャ追加
    Select(0u007a) # z
    AddPosSub(lookupSub, glyphName)

    # ⁱ
    Select(0u0069); Copy() # i
    Select(0u2071); Paste() # ⁱ
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_super})
    SetWidth(500)
    glyphName = GlyphInfo("Name") # sups フィーチャ追加
    Select(0u0069) # i
    AddPosSub(lookupSub, glyphName)

    # ⁰, ⁴-⁹
    j = 0
    while (j < 10)
        if (j < 1 || 3 < j)
            Select(0u0030 + j); Copy()
            Select(0u2070 + j); Paste()
            Scale(${scale_super_sub}, 250, 0)
            ChangeWeight(${weight_super_sub})
            CorrectDirection()
            Move(0, ${move_y_super})
            SetWidth(500)
            glyphName = GlyphInfo("Name") # sups フィーチャ追加
            Select(0u0030 + j)
            AddPosSub(lookupSub, glyphName)
        endif
        j += 1
    endloop

    # ⁺-ⁿ
    orig = [0u002b, 0u2212, 0u003d, 0u0028, 0u0029, 0u006e]
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(0u207a + j); Paste()
        Scale(${scale_super_sub}, 250, 0)
        ChangeWeight(${weight_super_sub})
        CorrectDirection()
        Move(0, ${move_y_super})
        SetWidth(500)
        glyphName = GlyphInfo("Name") # sups フィーチャ追加
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
    endloop

    # ⁻
    Select(0u207b) # ⁻
    glyphName = GlyphInfo("Name") # sups フィーチャ追加
    Select(0u002d) # -
    AddPosSub(lookupSub, glyphName)

    # ⱽ
    Select(${address_store_mod} + 2); Copy() # 保管した V
    Select(0u2c7d); Paste() # ⱽ
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_super})
    SetWidth(500)
    glyphName = GlyphInfo("Name") # sups フィーチャ追加
    Select(0u0056) # V
    AddPosSub(lookupSub, glyphName)

# 演算子を上下に移動
    math = [0u002a, 0u002b, 0u002d, 0u003c,\
            0u003d, 0u003e, 0u00d7, 0u00f7,\
            0u2212, 0u2217, 0u2260] # *+-< =>×÷ −∗≠
    j = 0
    while (j < SizeOf(math))
        Select(math[j]);
        Move(0, ${move_y_math})
        SetWidth(500)
        j += 1
    endloop

    math = [0u207a, 0u207b, 0u207c,\
            0u208a, 0u208b, 0u208c] # ⁺⁻⁼ ₊₋₌
    j = 0
    while (j < SizeOf(math))
        Select(math[j]);
        Move(0, ${move_y_s_math})
        SetWidth(500)
        j += 1
    endloop

# \ (ss13 用のグリフを作る)
    Select(0u005c); Copy() # reverse solidus
    Select(${address_store_escape}); Paste() # 保管所
    Select(65552); Paste() # Temporary glyph
    Scale(120); Copy()
    if (input_list[i] == "${input_latin_regular}")
        Move(-30, 0); PasteWithOffset(30, 0)
    else
        Move(-50, 0); PasteWithOffset(50, 0)
    endif
    OverlapIntersect(); Copy()
    Select(${address_store_escape}); PasteInto() # 保管所
    OverlapIntersect()
    SetWidth(500)
    Select(65552); Clear() # Temporary glyph

# --------------------------------------------------

# 記号を一部クリア
    Print("Remove some glyphs")
    Select(0u0020); Clear() # 半角スペース (仮名フォントを優先)
    Select(0u00a0); Clear() # ノーブレークスペース (仮名フォントを優先)
    Select(0u0375); Clear() # ͵ (仮名フォントを優先)
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
 #    Select(0u2153, 0u2154); Clear() # ⅓⅔
 #    Select(0u215b, 0u215e); Clear() # ⅛⅜⅞
    Select(0u2160, 0u216b); Clear() # Ⅰ-Ⅻ
    Select(0u2170, 0u2179); Clear() # ⅰ-ⅹ
 #    Select(0u2189); Clear() # ↉
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
    Select(0ue000, 0uedff); Clear() # -
 #    Select(0uee00, 0uee0b); Clear() # -
    Select(0uee0c, 0uf8ff); Clear() # -
    Select(0ufe00, 0ufe0f); Clear()
 #    Select(0ufffd); Clear()

# --------------------------------------------------

# 全角文字を移動
    if ("${draft_flag}" == "false")
        Print("Move zenkaku glyphs")
        SelectWorthOutputting()
        foreach
            if (800 <= GlyphInfo("Width"))
                Move(${move_x_zenkaku_latin}, 0)
                SetWidth(-${move_x_zenkaku_latin}, 1)
            endif
        endloop
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
    ScaleToEm(${em_ascent1000}, ${em_descent1000})
    SetOS2Value("WinAscent",             ${win_ascent1000}) # WindowsGDI用(この範囲外は描画されない)
    SetOS2Value("WinDescent",            ${win_descent1000})
    SetOS2Value("TypoAscent",            ${typo_ascent1000}) # 組版・DirectWrite用(em値と合わせる)
    SetOS2Value("TypoDescent",          -${typo_descent1000})
    SetOS2Value("TypoLineGap",           ${typo_linegap1000})
    SetOS2Value("HHeadAscent",           ${hhea_ascent1000}) # Mac用
    SetOS2Value("HHeadDescent",         -${hhea_descent1000})
    SetOS2Value("HHeadLineGap",          ${hhea_linegap1000})

# --------------------------------------------------

# 漢字のグリフクリア
    Print("Remove kanji glyphs")
 #    Select(0u2e80, 0u2fdf) # 部首
    Select(0u3003) # 〃
    SelectMore(0u3005, 0u3007) # 々〆〇
    SelectMore(0u3021, 0u3029) # 蘇州数字
    SelectMore(0u3038, 0u303d) # 蘇州数字他
    SelectMore(0u3400, 0u4dbf)
    SelectMore(0u4e00, 0u4e94)
 #    SelectMore(0u4e95) # 井 (𛄨の作成で使用、作成後削除)
    SelectMore(0u4e96, 0u5209)
 #    SelectMore(0u520a) # 刊 (ﾖﾘの作成で使用、作成後削除)
    SelectMore(0u520b, 0u5b4f)
 #    SelectMore(0u5b50) # 子 (𛄧の作成で使用、作成後削除)
    SelectMore(0u5b51, 0u5e71)
 #    SelectMore(0u5e72) # 干 (𛄢の作成で使用、作成後削除)
    SelectMore(0u5e73, 0u9fff)
    SelectMore(0uf900, 0ufaff)
    SelectMore(0u20000, 0u3ffff)
    Clear(); DetachAndRemoveGlyphs()

# 使用しないグリフクリア
    Print("Remove not used glyphs")
    Select(0, 31)
 #    SelectMore(0u2060) # WJ
    SelectMore(0u2160, 0u217f) # Ⅰ-ⅿ
 #    SelectMore(0ufeff) # zero width no-brake space
    SelectMore(0u1b001) # 𛀁 (変体仮名フォント追加のため削除)
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

# g をオープンテイルに改変するため、一旦保管
# 後で使うため ▲▼■ を保管
    Print("Store some glyphs")
    Select(0u0067); Copy() # g
    Select(${address_store_g}); Paste() # 保管所
    Select(0u25b2); Copy() # ▲
    Select(${address_store_b_diagram}); Paste() # 保管所
    Select(0u25bc); Copy() # ▼
    Select(${address_store_b_diagram} + 1); Paste() # 保管所
    Select(0u25a0); Copy() # ■
    Select(${address_store_b_diagram} + 2); Paste() # 保管所

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
    Move(0, ${move_y_space})
    SetWidth(500)
    OverlapIntersect()

    Copy()
    Select(${address_store_underline} + 1); Paste() # 保管所 (後で使うために保管)
    Select(0u00a0); Paste() # No-break space
    VFlip()
    CorrectDirection()
    SetWidth(500)

    Select(65552); Clear() # Temporary glyph

# 全角形加工用下線作成
    Print("Make underline for zenkaku")

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
    Move(0, ${move_y_space})
    Copy()
    Select(${address_store_underline}); Paste() # 保管所 (後で使うために保管)
    SetWidth(1000)

    Select(65552); Clear() # Temporary glyph

# その他のスペース用グリフ (ss 用) 作成
    Print("Make other space")

# 全角
    Select(0u25a0); Copy() # ■
    Select(${address_store_otherspace}); Paste()
    Scale(100, 50, 0, 0)
    Select(0u25a0); Copy() # ■
    Select(65552, 65553);  Paste()
    Select(65553)
    Scale(68, 70); HFlip(); Copy()
    Select(65552);  PasteInto()
    Scale(92, 100)
    Copy()
    Select(${address_store_otherspace}); PasteInto()
    OverlapIntersect()
    Move(0, -208)
    SetWidth(1000)

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# 半角
    Select(0u25a0); Copy() # ■
    Select(${address_store_otherspace} + 1); Paste()
    Scale(100, 50, 0, 0)
    Select(0u25a0); Copy() # ■
    Select(65552, 65553);  Paste()
    Select(65553)
    Scale(55, 70); HFlip(); Copy()
    Select(65552);  PasteInto()
    Scale(65, 100)
    Copy()
    Select(${address_store_otherspace} + 1); PasteInto()
    OverlapIntersect()
    Move(-228, -208)
    SetWidth(500)

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ひらがなのグリフ変更
    Print("Edit hiragana and katakana")
# ゠ (左上を折り曲げる)
    Select(0u30a0); Copy() # ゠
    Select(${address_store_visi_kana}); Paste() # 保管所

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
    SetWidth(1000)

# 縦書き ー (少し左に移動)
    Select(1114433); Move(-5, 0)
    SetWidth(1000)

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

# き (切り離して右下を少しカット)
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
    RemoveOverlap()

    # 右下をカット
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-100, 140)
    PasteWithOffset(-100, -100)
    PasteWithOffset(190, 140)
    PasteWithOffset(190, -100)
    RemoveOverlap()
    Copy()
    # スクリーンに穴を空ける
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(10, 20)
    HFlip()
    if (input_list[i] == "${input_kana_regular}")
        Rotate(8)
        Move(260, -321)
    else
        Rotate(8)
        Move(270, -312)
    endif
    Copy()
    Select(65552);  PasteInto() # Temporary glyph
    Copy()
    Select(0u304d); PasteInto() # き
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ぎ (切り離して右下を少しカット)
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
    RemoveOverlap()

    # 右下をカット
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-100, 140)
    PasteWithOffset(-100, -100)
    PasteWithOffset(190, 140)
    PasteWithOffset(190, -100)
    RemoveOverlap()
    Copy()
    # スクリーンに穴を空ける
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(10, 20)
    HFlip()
    if (input_list[i] == "${input_kana_regular}")
        Rotate(8)
        Move(241, -331)
    else
        Rotate(8)
        Move(261, -321)
    endif
    Copy()
    Select(65552);  PasteInto() # Temporary glyph
    Copy()
    Select(0u304e); PasteInto() # ぎ
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# けげ (はねて右上と右下を延ばす) こ ご (はねて左中を少しカット)
    # はねる
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(50, 45 ,153, 0); Move(-180, -60)

    # け
    Select(0u3051); Copy() # け
    Select(65552);  PasteInto()
    OverlapIntersect()
    if (input_list[i] == "${input_kana_regular}")
        Rotate(-15, 236, -35)
        Scale(80, 236, -35)
    else
        Rotate(-15, 279, -35)
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

    Select(65552); Rotate(-55); Copy() # け のはねを こ 流用

    # こ
    Select(0u3053) # こ
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(413, 478)
    else
        PasteWithOffset(393, 460)
    endif
    SetWidth(1000)
    RemoveOverlap()

    # ご
    Select(0u3054) # ご
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(404, 496)
    else
        PasteWithOffset(384, 478)
    endif
    SetWidth(1000)
    RemoveOverlap()

    # けの右上と右下を延ばす
    # 右下以外
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-250, 140)
    PasteWithOffset(-450, -100)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(190, 440)
    else
        PasteWithOffset(190, 410)
    endif
    RemoveOverlap()
    Select(0u3051); Copy() # け
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    # 右上
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(190, 550)
    Select(0u3051); Copy() # け
    Select(65553);  PasteInto() # Temporary glyph
    OverlapIntersect()
    # 右下
    Select(0u25a0); Copy() # Black square
    Select(0u3051) # け
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(190, -195)
    else
        PasteWithOffset(190, -225)
    endif
    OverlapIntersect()
    Move(0, -15)
    # 合成
    Select(65552); Copy() # Temporary glyph
    Select(0u3051); PasteInto() # け
    Select(65553); Copy() # Temporary glyph
    Select(0u3051); PasteWithOffset(0, 10) # け
    SetWidth(1000)
    RemoveOverlap()

    # げの右下を延ばす
    # 右下以外
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-250, 140)
    PasteWithOffset(-450, -100)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(190, 430)
    else
        PasteWithOffset(190, 390)
    endif
    RemoveOverlap()
    Select(0u3052); Copy() # げ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    # 右下
    Select(0u25a0); Copy() # Black square
    Select(0u3052) # げ
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(190, -207)
    else
        PasteWithOffset(190, -249)
    endif
    OverlapIntersect()
    Move(0, -15)
    # 合成
    Select(65552); Copy() # Temporary glyph
    Select(0u3052); PasteInto() # げ
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
    RoundToInt()

    Select(0u3054) # ご
    PasteWithOffset(-9, 0)
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ゖ (はねて右上と右下を少し延ばす)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(50, 40 ,153, 0); Move(-150, -60)
    Select(0u3096); Copy() # ゖ
    Select(65552);  PasteInto()
    OverlapIntersect()
    if (input_list[i] == "${input_kana_regular}")
        Rotate(-15, 293, -35)
        Scale(80, 293, -35)
    else
        Rotate(-15, 329, -35)
        Scale(80, 329, -35)
    endif
    Copy()
    Select(0u3096); PasteInto() # ゖ
    SetWidth(1000)
    RemoveOverlap()

    # ゖの右上と右下を延ばす
    # 右下以外
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-250, 140)
    PasteWithOffset(-420, -100)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(190, 333)
    else
        PasteWithOffset(190, 308)
    endif
    RemoveOverlap()
    Select(0u3096); Copy() # ゖ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    # 右上
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(250, 450)
    Select(0u3096); Copy() # ゖ
    Select(65553);  PasteInto() # Temporary glyph
    OverlapIntersect()
    # 右下
    Select(0u25a0); Copy() # Black square
    Select(0u3096) # ゖ
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(250, -302)
    else
        PasteWithOffset(250, -327)
    endif
    OverlapIntersect()
    Move(0, -10)
    # 合成
    Select(65552); Copy() # Temporary glyph
    Select(0u3096); PasteInto() # ゖ
    Select(65553); Copy() # Temporary glyph
    Select(0u3096); PasteWithOffset(0, 7) # ゖ
    SetWidth(1000)
    RemoveOverlap()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# さ (切り離す、左上と右下を少しカット)
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
    RemoveOverlap()

    # 右下をカット
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-100, 140)
    PasteWithOffset(-100, -100)
    PasteWithOffset(190, 140)
    PasteWithOffset(190, -100)
    RemoveOverlap()
    Copy()
    # スクリーンに穴を空ける
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(10, 20)
    HFlip()
    if (input_list[i] == "${input_kana_regular}")
        Rotate(10)
        Move(259, -310)
    else
        Rotate(10)
        Move(270, -300)
    endif
    Copy()
    Select(65552);  PasteInto() # Temporary glyph
    Copy()
    Select(0u3055); PasteInto() # さ
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ざ (切り離す、左上と右下を少しカット)
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
    RemoveOverlap()

    # 右下をカット
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-100, 140)
    PasteWithOffset(-100, -100)
    PasteWithOffset(190, 140)
    PasteWithOffset(190, -100)
    RemoveOverlap()
    Copy()
    # スクリーンに穴を空ける
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(10, 20)
    HFlip()
    if (input_list[i] == "${input_kana_regular}")
        Rotate(10)
        Move(250, -320)
    else
        Rotate(10)
        Move(258, -309)
    endif
    Copy()
    Select(65552);  PasteInto() # Temporary glyph
    Copy()
    Select(0u3056); PasteInto() # ざ
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# せぜ (アウトラインの修正と折り曲げの先と右下を少しカット)
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
    Move(-100, -100)
    Rotate(6)
    PasteWithOffset(-100, 140)
    PasteWithOffset(-100, -100)
    PasteWithOffset(190, 140)
    RemoveOverlap()
    Copy()
    # 折り曲げの先をカットするため穴を空ける
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(15, 22)
    HFlip()
    if (input_list[i] == "${input_kana_regular}")
        Rotate(-16)
        Move(-64, -55)
    else
        Rotate(-13)
        Move(-63, -55)
    endif
    Copy()
    Select(65552);  PasteInto() # Temporary glyph
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
    Select(65553); Clear() # Temporary glyph

# そぞ (右下を少しカット)
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

# ちぢ (左下を少しカット)
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
        Rotate(-15, 246, -35)
        Scale(80, 246, -35)
    else
        Rotate(-15, 288, -35)
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
    PasteWithOffset(15, 0)

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

# はばぱ (はねる、は は右上を少し延ばす)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(50, 45 ,153, 0); Move(-180, -60)
    Select(0u306f); Copy() # は
    Select(65552);  PasteInto()
    OverlapIntersect()
    if (input_list[i] == "${input_kana_regular}")
        Rotate(-15, 222, -35)
        Scale(80, 222, -35)
    else
        Rotate(-15, 258, -35)
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

    # はの右上を延ばす
    # 右上
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(190, 550)
    Select(0u306f); Copy() # は
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u306f); PasteWithOffset(0, 10) # は
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

# ほぼぽ (はねる)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(50, 45 ,153, 0); Move(-180, -60)
    Select(0u307b); Copy() # ほ
    Select(65552);  PasteInto()
    OverlapIntersect()
    if (input_list[i] == "${input_kana_regular}")
        Rotate(-15, 222, -35)
        Scale(80, 222, -35)
    else
        Rotate(-15, 258, -35)
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

# ゅ (巻いているところを少しカット)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-100, 140)
    PasteWithOffset(-100, -100)
    PasteWithOffset(190, 140)
    PasteWithOffset(190, -100)
    RemoveOverlap()
    Copy()
    # スクリーンに穴を空ける
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(5, 20)
    HFlip()
    if (input_list[i] == "${input_kana_regular}")
        Rotate(-43)
        Move(-142, -118)
    else
        Rotate(-37)
        Move(-133, -123)
    endif
    Copy()
    Select(65552);  PasteInto() # Temporary glyph
    Copy()

    Select(0u3085) # ゅ
    PasteInto()
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ゆ (巻いているところを少しカット)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-100, 140)
    PasteWithOffset(-100, -100)
    PasteWithOffset(190, 140)
    PasteWithOffset(190, -100)
    RemoveOverlap()
    Copy()
    # スクリーンに穴を空ける
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(10, 20)
    HFlip()
    if (input_list[i] == "${input_kana_regular}")
        Rotate(-43)
        Move(-190, -55)
    else
        Rotate(-35)
        Move(-180, -60)
    endif
    Copy()
    Select(65552);  PasteInto() # Temporary glyph
    Copy()

    Select(0u3086) # ゆ
    PasteInto()
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

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

# ゟ (右に移動)
    Select(0u309f)
    Move(25, 0)
    SetWidth(1000)

# ア (ノの上を少しカットして少し右に移動)
    # ノの上をカット
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-100, 180)
    PasteWithOffset(-100, -100)
    PasteWithOffset(190, 180)
    PasteWithOffset(190, -100)
    RemoveOverlap()
    # スクリーンに穴を空ける
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(25, 10)
    HFlip()
    if (input_list[i] == "${input_kana_regular}")
        Move(-55, 171)
    else
        Move(-55, 153)
    endif
    Copy()
    Select(65552);  PasteInto() # Temporary glyph
    Copy()

    Select(0u30a2); PasteInto() # ア
    OverlapIntersect()

    # ノを右に移動
    # 左下
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-280, -140)
    Select(0u30a2); Copy() # ア
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    # 左下以外
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(-130, 500)
    PasteWithOffset(380, 200)
    RemoveOverlap()
    Copy()
    Select(0u30a2); PasteInto() # ア
    OverlapIntersect()
    # 合成
    Select(65552);  Copy() # Temporary glyph
    Select(0u30a2) # ア
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(10, 0)
    else
        PasteWithOffset(20, 0)
    endif

    SetWidth(1000)

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ァ (ノの上を少しカットして少し右に移動)
    # ノの上をカット
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-100, 180)
    PasteWithOffset(-100, -100)
    PasteWithOffset(190, 180)
    PasteWithOffset(190, -100)
    RemoveOverlap()
    # スクリーンに穴を空ける
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(25, 10)
    HFlip()
    if (input_list[i] == "${input_kana_regular}")
        Move(-55, 70)
    else
        Move(-55, 56)
    endif
    Copy()
    Select(65552);  PasteInto() # Temporary glyph
    Copy()

    Select(0u30a1); PasteInto() # ァ
    OverlapIntersect()

    # ノを右に移動
    # 左下
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-300, -280)
    Select(0u30a1); Copy() # ァ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    # 左下以外
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(-130, 390)
    PasteWithOffset(365, 60)
    RemoveOverlap()
    Copy()
    Select(0u30a1); PasteInto() # ァ
    OverlapIntersect()
    # 合成
    Select(65552);  Copy() # Temporary glyph
    Select(0u30a1); # ァ
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(7, 0)
    else
        PasteWithOffset(14, 0)
    endif

    SetWidth(1000)

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ｱ (ノの上を少しカット)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-100, 180)
    PasteWithOffset(-100, -100)
    PasteWithOffset(190, 180)
    PasteWithOffset(190, -100)
    RemoveOverlap()
    # スクリーンに穴を空ける
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(25, 10)
    HFlip()
    if (input_list[i] == "${input_kana_regular}")
        Move(-255, 171)
    else
        Move(-255, 153)
    endif
    Copy()
    Select(65552);  PasteInto() # Temporary glyph
    Copy()

    Select(0uff71); PasteInto() # ｱ
    SetWidth(500)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ｧ (ノの上を少しカット)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-100, 180)
    PasteWithOffset(-100, -100)
    PasteWithOffset(190, 180)
    PasteWithOffset(190, -100)
    RemoveOverlap()
    # スクリーンに穴を空ける
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(25, 10)
    HFlip()
    if (input_list[i] == "${input_kana_regular}")
        Move(-260, 74)
    else
        Move(-260, 60)
    endif
    Copy()
    Select(65552);  PasteInto() # Temporary glyph
    Copy()

    Select(0uff67); PasteInto() # ｧ
    SetWidth(500)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# イ (縦棒を少し延ばして少し上に移動)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(0, -500)
    Select(0u30a4); Copy() # イ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u30a4); PasteWithOffset(0, -10) # イ
    Move(0, 10)
    SetWidth(1000)
    RemoveOverlap()

    Select(65552); Clear() # Temporary glyph

# ィ (縦棒を少し延ばして少し上に移動)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(0, -500)
    Select(0u30a3); Copy() # ィ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u30a3); PasteWithOffset(0, -7) # イ
    Move(0, 7)
    SetWidth(1000)
    RemoveOverlap()

    Select(65552); Clear() # Temporary glyph

# ｲ (縦棒を少し延ばして少し上に移動)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(0, -500)
    Select(0uff72); Copy() # ｲ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0uff72); PasteWithOffset(0, -10) # ｲ
    Move(0, 10)
    SetWidth(500)
    RemoveOverlap()

    Select(65552); Clear() # Temporary glyph

# ｨ (縦棒を少し延ばして少し上に移動)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(0, -500)
    Select(0uff68); Copy() # ｨ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0uff68); PasteWithOffset(0, -7) # ｨ
    Move(0, 7)
    SetWidth(500)
    RemoveOverlap()

    Select(65552); Clear() # Temporary glyph

# クグク゚ (はらいの部分を少し短くする)
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

# セゼ (右下と折り曲げの先を少しカット、セ゚はゼをコピーするので改変不要)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-20, -100)
    Rotate(5)
    PasteWithOffset(-100, 140)
    PasteWithOffset(-100, -100)
    PasteWithOffset(190, 140)
    RemoveOverlap()

    # 折り曲げの先をカットするため穴を空ける
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(22, 22)
    HFlip()
    if (input_list[i] == "${input_kana_regular}")
        Rotate(39)
        Move(88, -122)
    else
        Rotate(43)
        Move(84, -126)
    endif
    Copy()
    Select(65552);  PasteInto() # Temporary glyph
    Copy()

    Select(0u30bb) # セ
    PasteInto()
    SetWidth(1000)
    OverlapIntersect()

    Select(0u30bc) # ゼ
    PasteWithOffset(-9, -9)
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ｾ (折り曲げの先を少しカット)

    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-150, 140)
    PasteWithOffset(-150, -100)
    RemoveOverlap()

    # 折り曲げの先をカットするため穴を空ける
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Scale(12, 12)
        HFlip()
        Rotate(59)
        Move(-168, -112)
    else
        Scale(10, 20)
        HFlip()
        Rotate(62)
        Move(-160, -115)
    endif
    Copy()
    Select(65552);  PasteInto() # Temporary glyph
    Copy()

    Select(0uff7e) # ｾ
    PasteInto()
    SetWidth(500)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# タダ (はらいの部分を少し短くする)
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

# トド (鼻先を少し短くする、ト゚はドをコピーするので改変不要)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-100, 140)
    PasteWithOffset(-100, -100)
    PasteWithOffset(190, 140)
    PasteWithOffset(190, -100)
    RemoveOverlap()
    Copy()
    # スクリーンに穴を空ける
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(10, 25)
    HFlip()
    if (input_list[i] == "${input_kana_regular}")
        Rotate(-18)
        Move(360, -90)
    else
        Rotate(-18)
        Move(369, -90)
    endif
    Copy()
    Select(65552);  PasteInto() # Temporary glyph
    Copy()

    Select(0u30c8); PasteInto() # ト
    Move(10, 0)
    SetWidth(1000)
    OverlapIntersect()

    Select(0u30c9) # ド
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-15, -9)
    else
        PasteWithOffset(-18, -9)
    endif
    Move(10, 0)
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ㇳ (鼻先を少し短くする)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-100, 140)
    PasteWithOffset(-100, -100)
    PasteWithOffset(190, 140)
    PasteWithOffset(190, -100)
    RemoveOverlap()
    # スクリーンに穴を空ける
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(10, 25)
    HFlip()
    if (input_list[i] == "${input_kana_regular}")
        Rotate(-18)
        Move(293, -160)
    else
        Rotate(-18)
        Move(299, -160)
    endif
    Copy()
    Select(65552);  PasteInto() # Temporary glyph
    Copy()

    Select(0u31f3); PasteInto() # ㇳ
    Move(7, 0)
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ヌ (右下を少しカット)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Rotate(52)
    Move(50, -50)
    PasteWithOffset(-100, 150)
    PasteWithOffset(100, 150)
    PasteWithOffset(-100, -100)
    RemoveOverlap()
    Copy()
    Select(0u30cc); PasteInto() # ヌ
    OverlapIntersect()
    SetWidth(1000)

# ㇴ (右下を少しカット)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Rotate(52)
    Move(50, -50)
    PasteWithOffset(-100, 150)
    PasteWithOffset(100, 150)
    PasteWithOffset(-100, -100)
    RemoveOverlap()
    Copy()
    Select(0u31f4); PasteWithOffset(-45, 0) # ㇴ
    OverlapIntersect()
    SetWidth(1000)

# ﾇ (右下を少しカット)
 #    Select(0u25a0); Copy() # Black square
 #    Select(65552);  Paste() # Temporary glyph
 #    if (input_list[i] == "${input_kana_regular}")
 #        Rotate(47)
 #        Move(50, -50)
 #    else
 #        Rotate(52)
 #        Move(40, -50)
 #    endif
 #    PasteWithOffset(-100, 150)
 #    PasteWithOffset(100, 150)
 #    PasteWithOffset(-100, -100)
 #    RemoveOverlap()
 #    Copy()
 #    Select(0uff87); PasteWithOffset(-360, 0) # ﾇ
 #    OverlapIntersect()
 #    SetWidth(500)

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

# ヒビピ (横棒を少し上に移動)
    # ヒ
    # 横棒から上
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-100, 300)
    PasteWithOffset(190, 300)
    RemoveOverlap()
    Select(0u30d2); Copy() # ヒ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    # 横棒の下から下
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(-100, -330)
    PasteWithOffset(190, -330)
    RemoveOverlap()
    Copy()
    Select(0u30d2); PasteInto() # ヒ
    OverlapIntersect()
    # 合成
    Select(65552);  Copy() # Temporary glyph
    Select(0u30d2); PasteWithOffset(0, 10) # ヒ
    RemoveOverlap()

    # ビ
    # 横棒から上
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-100, 300)
    PasteWithOffset(190, 300)
    RemoveOverlap()
    Move(-18, -36)
    Select(0u30d3); Copy() # ビ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    # 横棒の下から下
    Select(65553);  Copy() # Temporary glyph
    Select(0u30d3); PasteWithOffset(-18, -36) # ビ
    OverlapIntersect()
    # 合成
    Select(65552);  Copy() # Temporary glyph
    Select(0u30d3); PasteWithOffset(0, 17) # ビ
    RemoveOverlap()

    # ピ
    # 横棒から上
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-100, 300)
    PasteWithOffset(190, 300)
    RemoveOverlap()
    Move(-18, -36)
    Select(0u30d4); Copy() # ピ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    # 横棒の下から下
    Select(65553);  Copy() # Temporary glyph
    Select(0u30d4); PasteWithOffset(-18, -36) # ピ
    OverlapIntersect()
    # 合成
    Select(65552);  Copy() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Select(0u30d4); PasteWithOffset(0, 20) # ピ
    else
        Select(0u30d4); PasteWithOffset(0, 17) # ピ
    endif
    RemoveOverlap()

    # 上をカットして元の高さに戻す
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-100, 180)
    PasteWithOffset(-100, -100)
    PasteWithOffset(190, 180)
    PasteWithOffset(190, -100)
    RemoveOverlap()
    # スクリーンに穴を空ける
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(25, 20)
    HFlip()
    if (input_list[i] == "${input_kana_regular}")
        Move(-265, 414)
    else
        Move(-250, 419)
    endif
    Copy()
    Select(65552);  PasteInto() # Temporary glyph
    Copy()

    Select(0u30d2); PasteInto() # ヒ
    SetWidth(1000)
    OverlapIntersect()
    Select(0u30d3); PasteWithOffset(-18, -9) # ビ
    SetWidth(1000)
    OverlapIntersect()
    Select(0u30d4); PasteWithOffset(-18, -9) # ピ
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ㇶ (横棒を少し上に移動)
    # 横棒から上
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-100, 220)
    PasteWithOffset(190, 220)
    RemoveOverlap()
    Select(0u31f6); Copy() # ㇶ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    # 横棒の下から下
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(-100, -410)
    PasteWithOffset(190, -410)
    RemoveOverlap()
    Copy()
    Select(0u31f6); PasteInto() # ㇶ
    OverlapIntersect()
    # 合成
    Select(65552);  Copy() # Temporary glyph
    Select(0u31f6); PasteWithOffset(0, 7) # ㇶ
    RemoveOverlap()

    # 上をカットして元の高さに戻す
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-100, 180)
    PasteWithOffset(-100, -100)
    PasteWithOffset(190, 180)
    PasteWithOffset(190, -100)
    RemoveOverlap()
    # スクリーンに穴を空ける
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(25, 20)
    HFlip()
    if (input_list[i] == "${input_kana_regular}")
        Move(-215, 272)
    else
        Move(-200, 276)
    endif
    Copy()
    Select(65552);  PasteInto() # Temporary glyph
    Copy()

    Select(0u31f6); PasteInto() # ㇶ
    SetWidth(1000)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ﾋ (横棒を少し上に移動)
    # 横棒から上
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-100, 300)
    PasteWithOffset(190, 300)
    RemoveOverlap()
    Select(0uff8b); Copy() # ﾋ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    # 横棒の下から下
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(-100, -330)
    PasteWithOffset(190, -330)
    RemoveOverlap()
    Copy()
    Select(0uff8b); PasteInto() # ﾋ
    OverlapIntersect()
    # 合成
    Select(65552);  Copy() # Temporary glyph
    Select(0uff8b); PasteWithOffset(0, 10) # ﾋ
    RemoveOverlap()

    # 上をカットして元の高さに戻す
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-100, 180)
    PasteWithOffset(-100, -100)
    PasteWithOffset(190, 180)
    PasteWithOffset(190, -100)
    RemoveOverlap()
    # スクリーンに穴を空ける
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(25, 20)
    HFlip()
    if (input_list[i] == "${input_kana_regular}")
        Move(-330, 414)
    else
        Move(-325, 419)
    endif
    Copy()
    Select(65552);  PasteInto() # Temporary glyph
    Copy()
    Select(0uff8b); PasteInto() # ﾋ
    SetWidth(500)
    OverlapIntersect()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ホボポ (はねを少しカット)
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

# マ (つま先を少し右に移動)
    # つま先
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Rotate(35)
    if (input_list[i] == "${input_kana_regular}")
        Move(-332,-300)
    else
        Move(-301,-300)
    endif
    Select(0u30de); Copy() # マ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()

    # その他
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Rotate(35)
    if (input_list[i] == "${input_kana_regular}")
        Move(201, 100)
    else
        Move(232, 100)
    endif
    PasteWithOffset(-100, 500)
    RemoveOverlap()
    Copy()
    Select(0u30de) # マ
    PasteInto()
    OverlapIntersect()

    # 合成
    Select(65552); Copy() # Temporary glyph
    Select(0u30de) # マ
    PasteWithOffset(15, 10)
    Move(0, -5)
    SetWidth(1000)
    RemoveOverlap()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

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
    Move(15, 0)
    Select(65552);  Copy() # Temporary glyph
    Select(0u30eb); PasteWithOffset(-15, 0) # ル

    # 上を延ばす
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
    Move(10, 0)
    Select(65552);  Copy() # Temporary glyph
    Select(0u31fd); PasteWithOffset(-10, 0) # ㇽ

    # 上を延ばす
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
    SetWidth(500)
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
    SetWidth(500)
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
    if (input_list[i] == "${input_kana_regular}")
        Move(-50, 455)
    else
        Move(-50, 435)
    endif
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
    Move(0, -9)

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
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-120, -42)
        PasteWithOffset(-120, -90)
        PasteWithOffset(60, -90)
    else
        PasteWithOffset(-125, -42) # 濁点を避けるために削る
        PasteWithOffset(-125, -90)
        PasteWithOffset(60, -170)
    endif
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
        PasteWithOffset(-70, -63)
 #        PasteWithOffset(26, -63)
    endif
    PasteWithOffset(60, -200)
    RemoveOverlap()
    Copy()
    Select(0u3062); PasteInto() # ぢ
    OverlapIntersect()
    Simplify(); RoundToInt()

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
    Simplify(); RoundToInt()

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
    Simplify(); RoundToInt()

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
    if (input_list[i] == "${input_kana_regular}")
        Move(-70, -70)
        Rotate(15)
        PasteWithOffset(-200, -2)
        PasteWithOffset(70, -190)
    else
        Move(-82, -75)
 #        Move(-37, -70)
        Rotate(15)
        PasteWithOffset(-180, -2)
        PasteWithOffset(70, -120)
 #    PasteWithOffset(-160, -2)
 #    PasteWithOffset(70, -90)
    endif
    RemoveOverlap()
    Copy()
    Select(0u30c2); PasteInto() # ヂ
    OverlapIntersect()

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
        Move(-148, 3)
 #        Move(-110, 3)
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
        Move(60, -220)
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
    Rotate(20)
    Move(105, -175)
    PasteWithOffset(-250, 30)
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
        Select(0u30da); PasteWithOffset(10, 0) # ペ
 #        Select(0u30da); PasteWithOffset(0, 0) # ペ
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
        Select(0u30da); PasteWithOffset(10, 0) # ペ
 #        Select(0u30da); PasteWithOffset(0, 0) # ペ
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
        Select(0u307a); PasteWithOffset( 10,    0) # ぺ
 #        Select(0u307a); PasteWithOffset(  0,    0) # ぺ
    else
        Select(0u307a); PasteWithOffset( 10,    0) # ぺ
 #        Select(0u307a); PasteWithOffset(  0,    0) # ぺ
    endif
    SetWidth(1000); RemoveOverlap()

# 濁点の周囲の縁取り (一部に適用)
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(-200, 200)
    PasteWithOffset(-200, -200)
    PasteWithOffset(200, 200)
    PasteWithOffset(200, -200)
    RemoveOverlap()
    # スクリーンに穴を空ける
    Select(0u25a0); Copy() # Black square
    Select(65554);  Paste() # Temporary glyph
    HFlip()
    if (input_list[i] == "${input_kana_regular}")
        Scale(50, 40)
        Rotate(29)
        Move(245, 285)
    else
        Scale(50, 40)
        Rotate(27)
        Move(214, 321)
    endif
    Copy()
    Select(65553);  PasteInto() # Temporary glyph
    Copy()

    if (input_list[i] == "${input_kana_bold}")
 #        Select(0u3052); PasteWithOffset(108,  104) # げ
 #        OverlapIntersect()
        Select(0u3054); PasteWithOffset(104,  76) # ご
 #        Select(0u3054); PasteWithOffset( 80, 103) # ご
        OverlapIntersect()

 #        Select(0u305c); PasteWithOffset(104, 103) # ぜ
 #        OverlapIntersect()
        Select(0u305e); PasteWithOffset( 64,  78) # ぞ
 #        Select(0u305e); PasteWithOffset( 79,  93) # ぞ
        OverlapIntersect()

 #        Select(0u3070); PasteWithOffset(111, 104) # ば
 #        OverlapIntersect()
 #        Select(0u307c); PasteWithOffset(103,  104) # ぼ
 #        OverlapIntersect()

 #        Select(0u30b6); PasteWithOffset(109, 105) # ザ
 #        OverlapIntersect()

 #        Select(0u30f8); PasteWithOffset(101,  119) # ヸ
 #        OverlapIntersect()
    endif

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
        Select(0u3094); PasteWithOffset(129,   78) # ゔ
 #        Select(0u3094); PasteWithOffset( 89,   78) # ゔ
        SetWidth(1000); RemoveOverlap()

        Select(0u304c); PasteWithOffset(111,   70) # が
 #        Select(0u304c); PasteWithOffset( 51,   60) # が
        SetWidth(1000); RemoveOverlap()
        Select(0u304e); PasteWithOffset(113,  128) # ぎ
 #        Select(0u304e); PasteWithOffset(103,  128) # ぎ
        SetWidth(1000); RemoveOverlap()
        Select(0u3050); PasteWithOffset( 24,  -93) # ぐ
 #        Select(0u3050); PasteWithOffset( 14, -143) # ぐ
        SetWidth(1000); RemoveOverlap()
        Select(0u3052); PasteWithOffset(151,  121) # げ
 #        Select(0u3052); PasteWithOffset(155,  111) # げ
        SetWidth(1000); RemoveOverlap()
        Select(0u3054); PasteWithOffset(145,  128) # ご
 #        Select(0u3054); PasteWithOffset( 55, -143) # ご
        SetWidth(1000); RemoveOverlap()

        Select(0u3056); PasteWithOffset(135,  128) # ざ
 #        Select(0u3056); PasteWithOffset(105,  131) # ざ
        SetWidth(1000); RemoveOverlap()
        Select(0u3058); PasteWithOffset(-33,   18) # じ
 #        Select(0u3058); PasteWithOffset(-43,   18) # じ
        SetWidth(1000); RemoveOverlap()
        Select(0u305a); PasteWithOffset(145,  128) # ず
 #        Select(0u305a); PasteWithOffset( 90, -186) # ず
        SetWidth(1000); RemoveOverlap()
        Select(0u305c); PasteWithOffset(149,  124) # ぜ
 #        Select(0u305c); PasteWithOffset(149,  114) # ぜ
        SetWidth(1000); RemoveOverlap()
        Select(0u305e); PasteWithOffset(125,  114) # ぞ
 #        Select(0u305e); PasteWithOffset(145,   -4) # ぞ
        SetWidth(1000); RemoveOverlap()

        Select(0u3060); PasteWithOffset( 97,   98) # だ
 #        Select(0u3060); PasteWithOffset( 97,   88) # だ
        SetWidth(1000); RemoveOverlap()
        Select(0u3062); PasteWithOffset(108,  126) # ぢ
 #        Select(0u3062); PasteWithOffset(108,  131) # ぢ
        SetWidth(1000); RemoveOverlap()
        Select(0u3065); PasteWithOffset(116,  112) # づ
 #        Select(0u3065); PasteWithOffset( 96,  122) # づ
        SetWidth(1000); RemoveOverlap()
        Select(0u3067); PasteWithOffset(110, -175) # で
 #        Select(0u3067); PasteWithOffset( 80, -195) # で
        SetWidth(1000); RemoveOverlap()
        Select(0u3069); PasteWithOffset( 34,   76) # ど
 #        Select(0u3069); PasteWithOffset( 14,   81) # ど
        SetWidth(1000); RemoveOverlap()

        Select(0u3070); PasteWithOffset(149,  122) # ば
 #        Select(0u3070); PasteWithOffset(149,  112) # ば
        SetWidth(1000); RemoveOverlap()
        Select(0u3073); PasteWithOffset(107,   93) # び
 #        Select(0u3073); PasteWithOffset( 87,   93) # び
        SetWidth(1000); RemoveOverlap()
        Select(0u3076); PasteWithOffset(127,   98) # ぶ
        SetWidth(1000); RemoveOverlap()
        Select(0u307c); PasteWithOffset(149,  103) # ぼ
 #        Select(0u307c); PasteWithOffset(149,   93) # ぼ
        SetWidth(1000); RemoveOverlap()

        Select(0u30f4); PasteWithOffset(125,  128) # ヴ
 #        Select(0u30f4); PasteWithOffset(105,  128) # ヴ
        SetWidth(1000); RemoveOverlap()

        Select(0u30ac); PasteWithOffset(121,  123) # ガ
 #        Select(0u30ac); PasteWithOffset( 81,  128) # ガ
        SetWidth(1000); RemoveOverlap()
        Select(0u30ae); PasteWithOffset( 91,  123) # ギ
 #        Select(0u30ae); PasteWithOffset( 81,  128) # ギ
        SetWidth(1000); RemoveOverlap()
        Select(0u30b0); PasteWithOffset(125,  110) # グ
 #        Select(0u30b0); PasteWithOffset(105,  110) # グ
        SetWidth(1000); RemoveOverlap()
        Select(0u30b2); PasteWithOffset(101,  128) # ゲ
        SetWidth(1000); RemoveOverlap()
        Select(0u30b4); PasteWithOffset(114,  121) # ゴ
 #        Select(0u30b4); PasteWithOffset(104,  121) # ゴ
        SetWidth(1000); RemoveOverlap()

        Select(0u30b6); PasteWithOffset(151,  119) # ザ
 #        Select(0u30b6); PasteWithOffset(143,  109) # ザ
        SetWidth(1000); RemoveOverlap()
        Select(0u30b8); PasteWithOffset(139,  119) # ジ
 #        Select(0u30b8); PasteWithOffset( 84,  119) # ジ
        SetWidth(1000); RemoveOverlap()
        Select(0u30ba); PasteWithOffset(103,  128) # ズ
 #        Select(0u30ba); PasteWithOffset( 93,  128) # ズ
        SetWidth(1000); RemoveOverlap()
        Select(0u30bc); PasteWithOffset(106,  128) # ゼ
        SetWidth(1000); RemoveOverlap()
        Select(0u30be); PasteWithOffset(139,  116) # ゾ
 #        Select(0u30be); PasteWithOffset( 84,  116) # ゾ
        SetWidth(1000); RemoveOverlap()

        Select(0u30c0); PasteWithOffset(122,  121) # ダ
 #        Select(0u30c0); PasteWithOffset(102,  121) # ダ
        SetWidth(1000); RemoveOverlap()
        Select(0u30c2); PasteWithOffset(103,  123) # ヂ
        SetWidth(1000); RemoveOverlap()
        Select(0u30c5); PasteWithOffset(124,  116) # ヅ
 #        Select(0u30c5); PasteWithOffset( 84,  116) # ヅ
        SetWidth(1000); RemoveOverlap()
        Select(0u30c7); PasteWithOffset(118,  101) # デ
        SetWidth(1000); RemoveOverlap()
        Select(0u30c9); PasteWithOffset(-36,    9) # ド
        SetWidth(1000); RemoveOverlap()

        Select(0u30d0); PasteWithOffset( 86,   76) # バ
 #        Select(0u30d0); PasteWithOffset( -4,   56) # バ
        SetWidth(1000); RemoveOverlap()
        Select(0u30d3); PasteWithOffset( 60,   103) # ビ
        SetWidth(1000); RemoveOverlap()
        Select(0u30d6); PasteWithOffset(141,  128) # ブ
 #        Select(0u30d6); PasteWithOffset(101,  128) # ブ
        SetWidth(1000); RemoveOverlap()
        Select(0u30d9); PasteWithOffset( 43,   14) # ベ
 #        Select(0u30d9); PasteWithOffset( 23,   14) # ベ
        SetWidth(1000); RemoveOverlap()
        Select(0u30dc); PasteWithOffset(103,  128) # ボ
        SetWidth(1000); RemoveOverlap()

        Select(0u30f7); PasteWithOffset(141,  128) # ヷ
 #        Select(0u30f7); PasteWithOffset(101,  129) # ヷ
        SetWidth(1000); RemoveOverlap()
        Select(0u30f8); PasteWithOffset(141,  128) # ヸ
 #        Select(0u30f8); PasteWithOffset(111,  129) # ヸ
        SetWidth(1000); RemoveOverlap()
        Select(0u30f9); PasteWithOffset(139,  128) # ヹ
 #        Select(0u30f9); PasteWithOffset( 99,  135) # ヹ
        SetWidth(1000); RemoveOverlap()
        Select(0u30fa); PasteWithOffset(142,  128) # ヺ
 #        Select(0u30fa); PasteWithOffset(102,  128) # ヺ
        SetWidth(1000); RemoveOverlap()

        Select(0u3032); PasteWithOffset( 10, -143) # 〲
 #        Select(0u3032); PasteWithOffset(  0, -143) # 〲
        SetWidth(1000); RemoveOverlap()
        Select(0u3034); PasteWithOffset( 34, -343) # 〴
 #        Select(0u3034); PasteWithOffset( 14, -343) # 〴
        SetWidth(1000); RemoveOverlap()
        Select(0u309e); PasteWithOffset(-66,   -2) # ゞ
 #        Select(0u309e); PasteWithOffset(-86,  -22) # ゞ
        SetWidth(1000); RemoveOverlap()
        Select(0u30fe); PasteWithOffset(-76,  -22) # ヾ
 #        Select(0u30fe); PasteWithOffset(-86,  -22) # ヾ
        SetWidth(1000); RemoveOverlap()

    else
        Select(0u3094); PasteWithOffset(107,   63) # ゔ
 #        Select(0u3094); PasteWithOffset( 67,   43) # ゔ
        SetWidth(1000); RemoveOverlap()

        Select(0u304c); PasteWithOffset(105,   33) # が
 #        Select(0u304c); PasteWithOffset( 50,   13) # が
        SetWidth(1000); RemoveOverlap()
        Select(0u304e); PasteWithOffset( 86,  103) # ぎ
 #        Select(0u304e); PasteWithOffset( 76,   93) # ぎ
        SetWidth(1000); RemoveOverlap()
        Select(0u3050); PasteWithOffset( 19, -149) # ぐ
 #        Select(0u3050); PasteWithOffset(  9, -209) # ぐ
        SetWidth(1000); RemoveOverlap()
        Select(0u3052); PasteWithOffset(108,   99) # げ
 #        Select(0u3052); PasteWithOffset( 80,   79) # げ
        SetWidth(1000); RemoveOverlap()
        Select(0u3054); PasteWithOffset(100,  108) # ご
 #        Select(0u3054); PasteWithOffset( 30, -209) # ご
        SetWidth(1000); RemoveOverlap()

        Select(0u3056); PasteWithOffset(105,   98) # ざ
 #        Select(0u3056); PasteWithOffset( 75,   98) # ざ
        SetWidth(1000); RemoveOverlap()
        Select(0u3058); PasteWithOffset(-45,  -18) # じ
 #        Select(0u3058); PasteWithOffset(-55,  -18) # じ
        SetWidth(1000); RemoveOverlap()
        Select(0u305a); PasteWithOffset( 99,  103) # ず
 #        Select(0u305a); PasteWithOffset( 71, -228) # ず
        SetWidth(1000); RemoveOverlap()
        Select(0u305c); PasteWithOffset(104, 103) # ぜ
 #        Select(0u305c); PasteWithOffset( 76,   93) # ぜ
        SetWidth(1000); RemoveOverlap()
        Select(0u305e); PasteWithOffset( 79,  93) # ぞ
 #        Select(0u305e); PasteWithOffset( 79,  -15) # ぞ
        SetWidth(1000); RemoveOverlap()

        Select(0u3060); PasteWithOffset( 67,   83) # だ
 #        Select(0u3060); PasteWithOffset( 67,   93) # だ
        SetWidth(1000); RemoveOverlap()
        Select(0u3062); PasteWithOffset( 97,   98) # ぢ
 #        Select(0u3062); PasteWithOffset( 67,   93) # ぢ
        SetWidth(1000); RemoveOverlap()
        Select(0u3065); PasteWithOffset( 87,   74) # づ
 #        Select(0u3065); PasteWithOffset( 67,   84) # づ
        SetWidth(1000); RemoveOverlap()
        Select(0u3067); PasteWithOffset( 86, -226) # で
 #        Select(0u3067); PasteWithOffset( 66, -246) # で
        SetWidth(1000); RemoveOverlap()
        Select(0u3069); PasteWithOffset( 33,   45) # ど
 #        Select(0u3069); PasteWithOffset( 13,   50) # ど
        SetWidth(1000); RemoveOverlap()

        Select(0u3070); PasteWithOffset(109, 104) # ば
 #        Select(0u3070); PasteWithOffset( 80,   84) # ば
        SetWidth(1000); RemoveOverlap()
        Select(0u3073); PasteWithOffset( 43,   59) # び
 #        Select(0u3073); PasteWithOffset( 23,   59) # び
        SetWidth(1000); RemoveOverlap()
        Select(0u3076); PasteWithOffset( 80,   58) # ぶ
 #        Select(0u3076); PasteWithOffset( 55,   38) # ぶ
        SetWidth(1000); RemoveOverlap()
        Select(0u307c); PasteWithOffset(103,  104) # ぼ
 #        Select(0u307c); PasteWithOffset( 73,   34) # ぼ
        SetWidth(1000); RemoveOverlap()

        Select(0u30f4); PasteWithOffset( 85,  104) # ヴ
 #        Select(0u30f4); PasteWithOffset( 65,  104) # ヴ
        SetWidth(1000); RemoveOverlap()

        Select(0u30ac); PasteWithOffset( 94,   99) # ガ
 #        Select(0u30ac); PasteWithOffset( 74,   94) # ガ
        SetWidth(1000); RemoveOverlap()
        Select(0u30ae); PasteWithOffset( 74,   89) # ギ
 #        Select(0u30ae); PasteWithOffset( 74,   94) # ギ
        SetWidth(1000); RemoveOverlap()
        Select(0u30b0); PasteWithOffset( 88,   91) # グ
 #        Select(0u30b0); PasteWithOffset( 78,   86) # グ
        SetWidth(1000); RemoveOverlap()
        Select(0u30b2); PasteWithOffset( 74,   99) # ゲ
 #        Select(0u30b2); PasteWithOffset( 74,   94) # ゲ
        SetWidth(1000); RemoveOverlap()
        Select(0u30b4); PasteWithOffset( 84,   94) # ゴ
 #        Select(0u30b4); PasteWithOffset( 74,   94) # ゴ
        SetWidth(1000); RemoveOverlap()

        Select(0u30b6); PasteWithOffset(109, 105) # ザ
 #        Select(0u30b6); PasteWithOffset( 79,   80) # ザ
        SetWidth(1000); RemoveOverlap()
        Select(0u30b8); PasteWithOffset(104,   95) # ジ
 #        Select(0u30b8); PasteWithOffset( 74,   85) # ジ
        SetWidth(1000); RemoveOverlap()
        Select(0u30ba); PasteWithOffset(104,  114) # ズ
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
        Select(0u30c5); PasteWithOffset(104,   95) # ヅ
 #        Select(0u30c5); PasteWithOffset( 74,   85) # ヅ
        SetWidth(1000); RemoveOverlap()
        Select(0u30c7); PasteWithOffset( 75,   97) # デ
 #        Select(0u30c7); PasteWithOffset( 65,   93) # デ
        SetWidth(1000); RemoveOverlap()
        Select(0u30c9); PasteWithOffset(-55,  -18) # ド
        SetWidth(1000); RemoveOverlap()

        Select(0u30d0); PasteWithOffset( 57,   51) # バ
 #        Select(0u30d0); PasteWithOffset(-23,   31) # バ
        SetWidth(1000); RemoveOverlap()
        Select(0u30d3); PasteWithOffset( 54,   85) # ビ
        SetWidth(1000); RemoveOverlap()
        Select(0u30d6); PasteWithOffset(104,  114) # ブ
 #        Select(0u30d6); PasteWithOffset( 84,   74) # ブ
        SetWidth(1000); RemoveOverlap()
        Select(0u30d9); PasteWithOffset( 45,    0) # ベ
 #        Select(0u30d9); PasteWithOffset( 25,    0) # ベ
        SetWidth(1000); RemoveOverlap()
        Select(0u30dc); PasteWithOffset( 74,   94) # ボ
        SetWidth(1000); RemoveOverlap()

        Select(0u30f7); PasteWithOffset(105,  114) # ヷ
 #        Select(0u30f7); PasteWithOffset( 86,   74) # ヷ
        SetWidth(1000); RemoveOverlap()
        Select(0u30f8); PasteWithOffset(101,  119) # ヸ
 #        Select(0u30f8); PasteWithOffset( 71,  102) # ヸ
        SetWidth(1000); RemoveOverlap()
        Select(0u30f9); PasteWithOffset(104,  112) # ヹ
 #        Select(0u30f9); PasteWithOffset( 86,   82) # ヹ
        SetWidth(1000); RemoveOverlap()
        Select(0u30fa); PasteWithOffset(105,  110) # ヺ
 #        Select(0u30fa); PasteWithOffset( 87,   70) # ヺ
        SetWidth(1000); RemoveOverlap()

        Select(0u3032); PasteWithOffset( 10, -189) # 〲
 #        Select(0u3032); PasteWithOffset(  0, -189) # 〲
        SetWidth(1000); RemoveOverlap()
        Select(0u3034); PasteWithOffset( 20, -421) # 〴
 #        Select(0u3034); PasteWithOffset(  0, -421) # 〴
        SetWidth(1000); RemoveOverlap()
        Select(0u309e); PasteWithOffset(-56,  -33) # ゞ
 #        Select(0u309e); PasteWithOffset(-76,  -53) # ゞ
        SetWidth(1000); RemoveOverlap()
        Select(0u30fe); PasteWithOffset(-65,  -53) # ヾ
 #        Select(0u30fe); PasteWithOffset(-75,  -53) # ヾ
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
        Select(0u3079); PasteWithOffset( 40,    0) # べ
 #        Select(0u3079); PasteWithOffset(  0,    0) # べ
    else
        Select(0u3079); PasteWithOffset( 40,    0) # べ
 #        Select(0u3079); PasteWithOffset(  0,    0) # べ
    endif
        SetWidth(1000); RemoveOverlap()

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# 漢字部首のグリフ変更
    Print("Edit kanji busyu")

# ⼣
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
    Select(${address_store_visi_kana} + 1); Paste() # 保管所
    Move(0, 58)
    SetWidth(500)
    Copy()
    Select(${address_store_visi_kana} + 2); Paste() # 保管所
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
    Select(${address_store_visi_kana} + 3); Paste() # 保管所
    Move(0, 45)
    SetWidth(1000)
    Copy()
    Select(${address_store_visi_kana} + 4); Paste() # 保管所
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

# ↥ (追加)
    # 矢印
    Select(0u2191); Copy() # ↑
    Select(0u21a5); Paste() # ↥
    # 下線
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(0, -671)
    else
        Move(0, -678)
    endif
    Select(0u21a8); Copy() # ↨
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    # 合成
    Select(0u21a5) # ↥
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(0, 64)
        PasteWithOffset(0, 44)
    else
        PasteWithOffset(0, 75)
        PasteWithOffset(0, 55)
    endif
    Move(0, 10)
    SetWidth(1000)
    RemoveOverlap()
    Simplify()
    Select(65552); Clear() # Temporary glyph

# ↤ (追加)
    Select(0u21a5); Copy() # ↥
    Select(0u21a4); Paste() # ↤
    Rotate(90)
    Move(-20, 0)
    SetWidth(1000)

# ↦ (追加)
    Select(0u21a5); Copy() # ↥
    Select(0u21a6); Paste() # ↦
    Rotate(-90)
    Move(20, 0)
    SetWidth(1000)

# ↧ (追加)
    Select(0u21a5); Copy() # ↥
    Select(0u21a7); Paste() # ↧
    VFlip()
    CorrectDirection()
    Move(0, -20)
    SetWidth(1000)

# ↥ (加工の続き)
    Select(0u21a5) # ↥
    Move(0, 20)
    SetWidth(1000)

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
    Select(0u2329) # 〈
    SelectMore(0u232a) # 〉
    SelectMore(0u27e8) # ⟨
    SelectMore(0u27e9) # ⟩
    SelectMore(0u2e28) # ⸨
    SelectMore(0u2e29) # ⸩
    Move(0, 40)
    SetWidth(500)

# ⌒⌓ (漢字フォントを置換・追加)
    Select(0u25cb); Copy() # ○
    Select(0u2312, 0u2313); Paste() # ⌒⌓
    # 中心線
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(95, 20)
    if (input_list[i] == "${input_kana_regular}")
        Move(0, -191)
    else
        Move(0, -179)
    endif
    Select(0u25ad); Copy() # ▭
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    # 合成
    Select(0u2313) # ⌓
    PasteWithOffset(0, 166)
    RemoveOverlap()
    # ⌒⌓ の下をカット
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(150, 100)
    Copy()
    Select(0u2312, 0u2313) # ⌒⌓
    PasteWithOffset(0, 332)
    OverlapIntersect()
    # ウェイト調整
    if (input_list[i] == "${input_kana_regular}")
        ChangeWeight(16)
    else
        ChangeWeight(24)
    endif
    CorrectDirection()
    Move(0, -220)
    SetWidth(1000)
    Select(65552); Clear() # Temporary glyph

# ◠ (追加)
    Select(0u25cb); Copy() # ○
    Select(0u25e0); Paste() # ◠
    # 下をカット
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(150, 100)
    Copy()
    Select(0u25e0) # ◠
    PasteWithOffset(0, 332)
    OverlapIntersect()
    SetWidth(1000)
    Select(65552); Clear() # Temporary glyph

# ◡ (追加)
    Select(0u25cb); Copy() # ○
    Select(0u25e1); Paste() # ◡
    # 上をカット
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(150, 100)
    Copy()
    Select(0u25e1) # ◡
    PasteWithOffset(0, -332)
    OverlapIntersect()
    SetWidth(1000)
    Select(65552); Clear() # Temporary glyph

# ⌰ (追加)
    # 下線
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(320, 0)
    Select(0u2190); Copy() # ←
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    # 合成
    Select(0u2197); Copy() # ↗
    Select(0u2330); Paste() # ⌰
    Rotate(15); Copy()
    Move(-230, 0)
    PasteWithOffset(230, 0)
    Select(65552); Copy() # Temporary glyph
    Select(0u2330) # ⌰
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-360, -224)
        PasteWithOffset(-210, -224)
    else
        PasteWithOffset(-360, -201)
        PasteWithOffset(-205, -201)
    endif
    RemoveOverlap()
    # 下のはみ出した部分を削除
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(150); Copy()
    Select(0u2330) # ⌰
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(25, 243)
    else
        PasteWithOffset(25, 245)
    endif
    OverlapIntersect()
    if (input_list[i] == "${input_kana_regular}")
        ChangeWeight(-4)
        Move(-30, -30)
    else
        ChangeWeight(-26)
        Move(-30, -35)
    endif
    CorrectDirection()
    SetWidth(1000)
    Select(65552); Clear() # Temporary glyph

# ⌲⌳ (追加)
    Select(0u25b7); Copy() # ▷
    Select(0u2332); Paste() # ⌲
    Select(0u2333); Paste() # ⌳
    # 中心線
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(85, 20)
    if (input_list[i] == "${input_kana_regular}")
        Move(0, -191)
    else
        Move(0, -179)
    endif
    Select(0u25ad); Copy() # ▭
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    # 合成
    Select(0u2332) # ⌲
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(10, 145)
    else
        PasteWithOffset(10, 139)
    endif
    RemoveOverlap()
    Select(0u2333) # ⌳
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(10, 174) # ウェイト調整で太くなる分上にずらす
 #        PasteWithOffset(10, 166)
    else
        PasteWithOffset(0, 178)
 #        PasteWithOffset(0, 166)
    endif
    RemoveOverlap()
    # ウェイト調整
    Select(0u2332,0u2333) # ⌲⌳
    if (input_list[i] == "${input_kana_regular}")
        ChangeWeight(16)
    else
        ChangeWeight(24)
    endif
    CorrectDirection()
    # ⌳ の下をカット (鋭角の先端がつぶれるのでウェイト調整の後でカット)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(150, 100)
    Copy()
    Select(0u2333) # ⌳
    PasteWithOffset(0, 332)
    OverlapIntersect()
    Move(0, -220)

    Select(0u2332,0u2333) # ⌲⌳
    SetWidth(1000)
    Select(65552); Clear() # Temporary glyph

# ⏏ (小さくして下に移動)
    Select(0u23cf) # ⏏
    Scale(90)
    Move(0, -30)
    SetWidth(1000)

# ␥ (ウェイトを調整して全角にする)
    Select(0u2425) # ␥
    if (input_list[i] == "${input_kana_regular}")
        ChangeWeight(-10)
    else
        ChangeWeight(-20)
    endif
    CorrectDirection()
    Scale(110)
    if (input_list[i] == "${input_kana_regular}")
        Rotate(-24)
    else
        Rotate(-28)
    endif
    Move(230, 0)
    SetWidth(1000)

# ⌯ (追加) ※ ␥ より後に加工すること
    Select(0u2425); Copy() # ␥
    Select(0u232f); Paste() # ⌯
    # 回転
    if (input_list[i] == "${input_kana_regular}")
        Rotate(-46)
    else
        Rotate(-47)
    endif

    # 間隔を拡げる
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(0, 400)
    Select(65553);  Paste() # Temporary glyph
    Move(0, -400)
    Select(0u232f); Copy() # ⌯
    Select(65552, 65553);  PasteInto() # Temporary glyph
    # 中
    Select(0u2501); Copy() # ━
    Select(0u232f); PasteWithOffset(0, 4) # ⌯
    OverlapIntersect()
    # 上
    Select(65552) # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u232f); PasteWithOffset(0, 20) # ⌯
    # 下
    Select(65553) # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u232f); PasteWithOffset(0, -20) # ⌯

    SetWidth(1000)
    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ␥ (加工の続き)
    Select(0u232f); Copy() # ⌯
    Select(0u2425); Paste() # ␥
    # 回転
    if (input_list[i] == "${input_kana_regular}")
        Rotate(46)
    else
        Rotate(47)
    endif
    SetWidth(1000)

# ⏤ (追加) ※ ␥ より後に加工すること
    Select(0u232f); Copy() # ⌯
    Select(0u23e4); Paste() # ⏤
    Select(0u2501); Copy() # ━
    Select(0u23e4); PasteWithOffset(0, 4) # ⏤
    OverlapIntersect()
    Move(-50, 0)
    Copy()
    PasteWithOffset(100, 0)
    RemoveOverlap()
    SetWidth(1000)

# ⏥ (追加)
    Select(0u25a1); Copy() # □
    Select(0u23e5); Paste() # ⏥
    Scale(101, 80)
    Transform(80, 0, 40, 70, -4000, 10000)
    if (input_list[i] == "${input_kana_regular}")
        ChangeWeight(36)
        CorrectDirection()
        Move(-2, 0)
        Copy()
        PasteWithOffset(4, 0)
    else
        ChangeWeight(46)
        CorrectDirection()
        Move(-4, 0)
        Copy()
        PasteWithOffset(8, 0)
    endif
    OverlapIntersect()
    SetWidth(1000)

# ▰ (追加)
    Select(0u25a0); Copy() # ■
    Select(0u25b0); Paste() # ▰
    Transform(80, 0, 40, 70, -4000, 10000)
    if (input_list[i] == "${input_kana_regular}")
        ChangeWeight(14)
    else
        ChangeWeight(18)
    endif
    CorrectDirection()
    SetWidth(1000)

# ▱ (追加)
    Select(0u25a1); Copy() # □
    Select(0u25b1); Paste() # ▱
    Transform(80, 0, 40, 70, -4000, 10000)
    if (input_list[i] == "${input_kana_regular}")
        ChangeWeight(14)
    else
        ChangeWeight(18)
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
        Select(${address_store_visi_kana} + 5 + j); Paste() # 保管所
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

# 漢字構成記述文字 (追加)
    # 下準備 (ドットで埋め尽くす)
    Select(0u25a0); Copy() # Black square
    Select(0u2ff0); Paste() # ⿰
    Scale(5.5, 5.5)
    Move(-398, -392)
    Copy()
    j = 0
    while (j < 13)
        k = 0
        while (k < 13)
            if (!(j == 0 && k == 0))
                PasteWithOffset(k * 70, j * 70)
            endif
            k += 1
        endloop
        j += 1
    endloop
    SetWidth(1000)
    Copy()
    Select(0u2ff1, 0u2fff); Paste() # ⿱-⿿
    Select(0u31ef); Paste() # ㇯

# 2等分
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(52, 52)
    Move(-189, -182); Copy()
    PasteWithOffset(420,   0)
    PasteWithOffset(  0, 420)
    PasteWithOffset(420, 420)
    PasteWithOffset(  0, 210) # 中間
    PasteWithOffset(420, 210) # 中間
    RemoveOverlap()
    HFlip()

    # 貼り付け
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(150, 150)
    Select(65552); Copy() # Temporary glyph
    Select(65553); PasteInto() # Temporary glyph
    Copy()
    Select(0u2ff0); PasteInto() # ⿰
    OverlapIntersect()
    SetWidth(1000)
    Copy()
    Select(0u2ff1); Paste() # ⿱
    Rotate(90)
    SetWidth(1000)

# 3等分
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(32, 32)
    Move(-258,-252); Copy()
    PasteWithOffset(280,   0)
    PasteWithOffset(560,   0)
    PasteWithOffset(  0, 280)
    PasteWithOffset(280, 280)
    PasteWithOffset(560, 280)
    PasteWithOffset(  0, 560)
    PasteWithOffset(280, 560)
    PasteWithOffset(560, 560)
    PasteWithOffset(  0, 140) # 中間
    PasteWithOffset(280, 140) # 中間
    PasteWithOffset(560, 140) # 中間
    PasteWithOffset(  0, 420) # 中間
    PasteWithOffset(280, 420) # 中間
    PasteWithOffset(560, 420) # 中間
    RemoveOverlap()
    HFlip()

    # 貼り付け
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(150, 150)
    Select(65552); Copy() # Temporary glyph
    Select(65553); PasteInto() # Temporary glyph
    Copy()
    Select(0u2ff2); PasteInto() # ⿲
    OverlapIntersect()
    SetWidth(1000)
    Copy()
    Select(0u2ff3); Paste() # ⿳
    Rotate(90)
    SetWidth(1000)

# 囗
    # 中心
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(52, 52)
    Move(-189 + 210, -182 + 210)
    HFlip()

    # 周辺
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(21, 21)
    Move(-293,-287); Copy()
    PasteWithOffset(210,   0)
    PasteWithOffset(420,   0)
    PasteWithOffset(630,   0)
    PasteWithOffset(  0, 210)
    PasteWithOffset(630, 210)
    PasteWithOffset(  0, 420)
    PasteWithOffset(630, 420)
    PasteWithOffset(  0, 630)
    PasteWithOffset(210, 630)
    PasteWithOffset(420, 630)
    PasteWithOffset(630, 630)
    PasteWithOffset(105,   0) # 中間
    PasteWithOffset(315,   0) # 中間
    PasteWithOffset(525,   0) # 中間
    PasteWithOffset(105, 630) # 中間
    PasteWithOffset(315, 630) # 中間
    PasteWithOffset(525, 630) # 中間
    PasteWithOffset(  0, 105) # 中間
    PasteWithOffset(  0, 315) # 中間
    PasteWithOffset(  0, 525) # 中間
    PasteWithOffset(630, 105) # 中間
    PasteWithOffset(630, 315) # 中間
    PasteWithOffset(630, 525) # 中間
    RemoveOverlap()
    HFlip()

    # 合成・貼り付け
    Select(0u25a0); Copy() # Black square
    Select(65554);  Paste() # Temporary glyph
    Scale(150, 150)
    Select(65552); Copy() # Temporary glyph
    Select(65554); PasteInto() # Temporary glyph
    Select(65553); Copy() # Temporary glyph
    Select(65554); PasteInto() # Temporary glyph
    Copy()
    Select(0u2ff4); PasteInto() # ⿴
    OverlapIntersect()
    SetWidth(1000)

# 冂
    # 中下
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(52, 52)
    Move(-189, -182); Copy()
    Move(210, 210)
    PasteWithOffset(210,   0)
    RemoveOverlap()
    HFlip()

    # 周辺
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(21, 21)
    Move(-293,-287); Copy()
    PasteWithOffset(210,   0)
    PasteWithOffset(420,   0)
    PasteWithOffset(630,   0)
    PasteWithOffset(  0, 630)
    PasteWithOffset(210, 630)
    PasteWithOffset(420, 630)
    PasteWithOffset(630, 630)
    PasteWithOffset(  0, 210)
    PasteWithOffset(  0, 420)
    PasteWithOffset(630, 210)
    PasteWithOffset(630, 420)
    PasteWithOffset(105, 630) # 中間
    PasteWithOffset(315, 630) # 中間
    PasteWithOffset(525, 630) # 中間
    PasteWithOffset(  0, 105) # 中間
    PasteWithOffset(  0, 315) # 中間
    PasteWithOffset(  0, 525) # 中間
    PasteWithOffset(630, 105) # 中間
    PasteWithOffset(630, 315) # 中間
    PasteWithOffset(630, 525) # 中間
    RemoveOverlap()
    HFlip()

    # 合成・貼り付け
    Select(0u25a0); Copy() # Black square
    Select(65554);  Paste() # Temporary glyph
    Scale(150, 150)
    Select(65552); Copy() # Temporary glyph
    Select(65554); PasteInto() # Temporary glyph
    Select(65553); Copy() # Temporary glyph
    Select(65554); PasteInto() # Temporary glyph
    Copy()
    Select(0u2ff5); PasteInto() # ⿵
    OverlapIntersect()
    SetWidth(1000)
    Copy()
    Select(0u2ff6); Paste() # ⿶
    Rotate(180)
    SetWidth(1000)
    Select(0u2ff7); Paste() # ⿷
    Rotate(90)
    SetWidth(1000)
    Select(0u2ffc); Paste() # ⿼
    Rotate(-90)
    SetWidth(1000)

# 厂
    # 右下
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(52, 52)
    Move(-189, -182); Copy()
    Move(210, 210)
    PasteWithOffset(210,   0)
    PasteWithOffset(420,   0)
    PasteWithOffset(420, 210)
    RemoveOverlap()
    HFlip()

    # 左上 (ひっくり返すので座標注意)
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(21, 21)
    Move(-293,-287); Copy()
    Move(  0, 630)
    PasteWithOffset(210, 630)
    PasteWithOffset(420, 630)
    PasteWithOffset(630, 630)
    PasteWithOffset(630,   0)
    PasteWithOffset(630, 210)
    PasteWithOffset(630, 420)
    PasteWithOffset(630, 630)
    PasteWithOffset(105, 630) # 中間
    PasteWithOffset(315, 630) # 中間
    PasteWithOffset(525, 630) # 中間
    PasteWithOffset(630, 105) # 中間
    PasteWithOffset(630, 315) # 中間
    PasteWithOffset(630, 525) # 中間
    RemoveOverlap()
    HFlip()

    # 合成・貼り付け
    Select(0u25a0); Copy() # Black square
    Select(65554);  Paste() # Temporary glyph
    Scale(150, 150)
    Select(65552); Copy() # Temporary glyph
    Select(65554); PasteInto() # Temporary glyph
    Select(65553); Copy() # Temporary glyph
    Select(65554); PasteInto() # Temporary glyph
    Copy()
    Select(0u2ff8); PasteInto() # ⿸
    OverlapIntersect()
    SetWidth(1000)
    Copy()
    Select(0u2ff9); Paste() # ⿹
    Rotate(-90)
    SetWidth(1000)
    Select(0u2ffa); Paste() # ⿺
    Rotate(90)
    SetWidth(1000)
    Select(0u2ffd); Paste() # ⿽
    Rotate(180)
    SetWidth(1000)

# 「」
    # 中心
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(52, 52)
    Move(-189 + 210, -182 + 210)
    HFlip()

    # 周辺 (ひっくり返すので座標注意)
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(21, 21)
    Move(-293,-287); Copy()
    PasteWithOffset(210,   0)
    PasteWithOffset(420,   0)
    PasteWithOffset(  0, 210)
    PasteWithOffset(630, 210)
    PasteWithOffset(  0, 420)
    PasteWithOffset(630, 420)
    PasteWithOffset(210, 630)
    PasteWithOffset(420, 630)
    PasteWithOffset(630, 630)
    PasteWithOffset(105,   0) # 中間
    PasteWithOffset(315,   0) # 中間
    PasteWithOffset(315, 630) # 中間
    PasteWithOffset(525, 630) # 中間
    PasteWithOffset(  0, 105) # 中間
    PasteWithOffset(  0, 315) # 中間
    PasteWithOffset(630, 315) # 中間
    PasteWithOffset(630, 525) # 中間
    RemoveOverlap()
    HFlip()

    # 右上と左下のカット部分 (ひっくり返すので座標注意)
    Select(0u25a0); Copy() # Black square
    Select(65554);  Paste() # Temporary glyph
    Scale(32, 32)
    Move(-258,-252); Copy()
    Move(630, -70)
    PasteWithOffset(-70, 630)
    HFlip()

    # 合成・貼り付け
    Select(0u25a0); Copy() # Black square
    Select(65555);  Paste() # Temporary glyph
    Scale(150, 150)
    Select(65552); Copy() # Temporary glyph
    Select(65555); PasteInto() # Temporary glyph
    Select(65553); Copy() # Temporary glyph
    Select(65555); PasteInto() # Temporary glyph
    Select(65554); Copy() # Temporary glyph
    Select(65555); PasteInto() # Temporary glyph
    Copy()
    Select(0u2ffb); PasteInto() # ⿻
    OverlapIntersect()
    SetWidth(1000)

    Select(0u2ff0, 0u2ffd) # ⿰-⿽
    Move(-${move_x_zenkaku_kana}, -52)
    SetWidth(1000)

# 分割無し(⌒加工後に加工すること)
    # 中心
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(115, 115)
    Move(-189 + 210, -182 + 210)
    HFlip()

    # 貼り付け
    Select(0u25a0); Copy() # Black square
    Select(65554);  Paste() # Temporary glyph
    Scale(150, 150)
    Select(65552); Copy() # Temporary glyph
    Select(65554); PasteInto() # Temporary glyph
    Copy()
    Select(0u2ffe); PasteInto() # ⿾
    OverlapIntersect()
    Copy()
    Select(0u2fff); Paste() # ⿿

    # ↔
    Select(0uff0d); Copy() # －
    Select(65552);  Paste() # Temporary glyph
    Scale(66)
    Move(0, 4)
    Select(0u25c0); Copy() # ◀
    Select(65553); Paste() # Temporary glyph
    Scale(25, 30)
    Copy()
    Select(65552)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-190, 0) # Temporary glyph
    else
        PasteWithOffset(-190, 0) # Temporary glyph
    endif
    Select(65553) # Temporary glyph
    Rotate(180)
    Copy()
    Select(65552)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(271, -1) # Temporary glyph
    else
        PasteWithOffset(271, 0) # Temporary glyph
    endif
    RemoveOverlap()
    Copy()
    Select(0u2ffe); PasteWithOffset(22, 28) # ⿾
    Move(-${move_x_zenkaku_kana}, -52)
    SetWidth(1000)

    # 回転矢印
    Select(0u2312); Copy() # ⌒
    Select(65552); Paste() # Temporary glyph
    Rotate(-90)
    Scale(70)
    Select(0u25c0); Copy() # ◀
    Select(65553); Paste() # Temporary glyph
    Scale(25, 30)
    Copy()
    Select(65552)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-150, -271) # Temporary glyph
    else
        PasteWithOffset(-150, -267) # Temporary glyph
    endif
    RemoveOverlap()
    Copy()
    Select(0u2fff); PasteWithOffset(150, 80) # ⿿
    Move(-${move_x_zenkaku_kana}, -52)
    SetWidth(1000)

# 回
    # 中心の隙間
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(74, 74)
    Move(-189 + 210, -182 + 210)
    HFlip()

    # 内側の線
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(95, 95)
    Move(-189 + 210, -182 + 210)
    Copy()
    Select(65552);  PasteInto() # Temporary glyph

    # 外側の隙間
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(115, 115)
    Move(-189 + 210, -182 + 210)
    HFlip()

    # 合成・貼り付け
    Select(0u25a0); Copy() # Black square
    Select(65554);  Paste() # Temporary glyph
    Scale(150, 150)
    Select(65552); Copy() # Temporary glyph
    Select(65554); PasteInto() # Temporary glyph
    Select(65553); Copy() # Temporary glyph
    Select(65554); PasteInto() # Temporary glyph
    Copy()
    Select(0u31ef); PasteInto() # ㇯
    OverlapIntersect()

    # -
    Select(0uff0d); Copy() # －
    Select(65552);  Paste() # Temporary glyph
    Scale(56, 62)
    Copy()
    Select(0u31ef); PasteWithOffset(22, 32) # ㇯
    Move(-${move_x_zenkaku_kana}, -52)
    SetWidth(1000)

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph
    Select(65554); Clear() # Temporary glyph
    Select(65555); Clear() # Temporary glyph

# 演算子を上下に移動
    math = [0u223c] # ∼
    j = 0
    while (j < SizeOf(math))
        Select(math[j]);
        Move(0, ${move_y_math} + 42)
        SetWidth(500)
        j += 1
    endloop

# 矢印 (ss用)
    arrow = [0u2190, 0u2191, 0u2192, 0u2193] # ←↑→↓
    j = 0
    while (j < SizeOf(arrow))
        Select(arrow[j]); Copy()
        Select(${address_store_arrow} + j); Paste() # 保管所
        SetWidth(1000)
        j += 1
    endloop

    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(330, 0)
    Select(${address_store_arrow}); Copy() # 保管した ←
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(${address_store_arrow}) # 保管した ←
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(216, 0)
        RemoveOverlap()
        ChangeWeight(-27); CorrectDirection()
    else
        PasteWithOffset(190, 0)
        RemoveOverlap()
    endif
    Move(0, -1)
    SetWidth(1000)

    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(0, -310)
    Select(${address_store_arrow} + 1); Copy() # 保管した ↑
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    PasteWithOffset(0, 180)
    RemoveOverlap()
    Copy()
    Select(${address_store_arrow} + 1) # 保管した ↑
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(0, -311)
        RemoveOverlap()
        ChangeWeight(-29); CorrectDirection()
    else
        PasteWithOffset(0, -284)
        RemoveOverlap()
    endif
    SetWidth(1000)

    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-330, 0)
    Select(${address_store_arrow} + 2); Copy() # 保管した →
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(${address_store_arrow} + 2) # 保管した →
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-216, 0)
        RemoveOverlap()
        ChangeWeight(-27); CorrectDirection()
    else
        PasteWithOffset(-190, 0)
        RemoveOverlap()
    endif
    Move(0, -1)
    SetWidth(1000)

    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(0, 310)
    Select(${address_store_arrow} + 3); Copy() # 保管した ↓
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    PasteWithOffset(0, -180)
    RemoveOverlap()
    Copy()
    Select(${address_store_arrow} + 3) # 保管した ↓
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(0, 311)
        RemoveOverlap()
        ChangeWeight(-29); CorrectDirection()
    else
        PasteWithOffset(0, 284)
        RemoveOverlap()
        Move(1, 0)
    endif
    SetWidth(1000)

        Select(65552); Clear() # Temporary glyph
#    endif

# 仮名拡張 A (追加)
    Print("Edit hentaigana")
# 𛄠
    # 縦棒
    Select(0u30a4); Copy() # イ
    Select(65552);  Paste() # Temporary glyph
    Rotate(180)
    if (input_list[i] == "${input_kana_regular}")
        Move(6, 0)
    else
        Move(-2, 0)
    endif
    Select(0u25a0); Copy() # Black square
    Select(65552);  PasteWithOffset(0, 390) # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u1b120) # 𛄠
    Paste()
    PasteWithOffset(0, -240)

    # 跳ね
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Rotate(42)
        Move(275, -313)
        PasteWithOffset(-80, -223)
    else
        Rotate(40)
        Move(235, -315)
        PasteWithOffset(-100, -264)
    endif
    RemoveOverlap()
    Select(0u1b000); Copy() # 𛀀
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()

    # 合成
    Select(0u1b120); PasteWithOffset(15, 0) # 𛄠
    RemoveOverlap()
    Simplify()
    SetWidth(1000)

    Select(65552); Clear() # Temporary glyph

# 𛀀 (点を短くして角度を付ける ※𛄠の後に加工すること)
    # 点
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(50, 100); Copy()
    if (input_list[i] == "${input_kana_regular}")
        Rotate(-5)
        Move(13, 540)
        PasteWithOffset(51, 540)
        Rotate(-1)
    else
        Rotate(-5)
        Move(6, 540)
        PasteWithOffset(61, 540)
        Rotate(-1)
    endif
    RemoveOverlap()
    Select(0u1b000); Copy() # 𛀀
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Rotate(-10, 500, 600)
    Move(-40, 10)

    # その他
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Scale(150, 100)
    Copy()
    Select(0u1b000) # 𛀀
    PasteWithOffset(0, -120)
    OverlapIntersect()

    # 合成
    Select(65552); Copy() # Temporary glyph
    Select(0u1b000) # 𛀀
    PasteWithOffset(0, 0)
    SetWidth(1000)
    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# 𛄡
    # 上
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Rotate(8)
        Move(-20, 110)
        PasteWithOffset(100, 70)
    else
        Rotate(8)
        Move(-20, 140)
        PasteWithOffset(100, 100)
    endif
    RemoveOverlap()
    Select(0u30a4); Copy() # イ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u1b121); Paste()# 𛄡
    Move(-20, 10)

    # 下
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(-100, -579)
        PasteWithOffset(100, -579)
    else
        Move(-100, -548)
        PasteWithOffset(100, -548)
    endif
    RemoveOverlap()
    Select(0u30a8); Copy() # エ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()

    # 合成
    Select(0u1b121) # 𛄡
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-4, 0)
        PasteWithOffset(26, 0)
    else
        PasteWithOffset(-5, 0)
        PasteWithOffset(25, 0)
    endif
    RemoveOverlap()
    SetWidth(1000)

    Select(65552); Clear() # Temporary glyph

# 𛄢
    # 上横棒
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(-100, 480)
        PasteWithOffset(100, 480)
    else
        Move(-100, 510)
        PasteWithOffset(100, 510)
    endif
    RemoveOverlap()
    Select(0u5e72); Copy() # 干
    Select(65552);  PasteWithOffset(9, 0) # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u1b122); Paste() # 𛄢

    # 下横棒
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(100, 50)
    Copy()
    Move(-100, 0)
    PasteWithOffset(100, 0)
    RemoveOverlap()
    Select(0u5e72); Copy() # 干
    Select(65552);  PasteWithOffset(9, 0) # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u1b122); PasteWithOffset(0, 20) # 𛄢

    # 中心線
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Scale(10.9, 100)
        Move(10, 0)
    else
        Scale(19, 100)
        Move(10, 0)
    endif
    Select(0u25ae); Copy() # Black vertical rectangle
    Select(65552)
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(-10, -320) # Temporary glyph
    else
        PasteWithOffset(-10, -360) # Temporary glyph
    endif
    RemoveOverlap()
    Select(0u30db); Copy() # ホ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()

    # 合成
    Select(0u1b122) # 𛄢
    PasteInto()
    RemoveOverlap()
    Simplify()
    SetWidth(1000)

    Select(65552); Clear() # Temporary glyph
    Select(0u5e72) # 干
    Clear(); DetachAndRemoveGlyphs()

# 𛄣 (こと)
    # こ
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(-50, -80)
        PasteWithOffset(50, -80)
        PasteWithOffset(-50, 70)
        PasteWithOffset(50, 70)
        RemoveOverlap()
        Rotate(27)
        Move(-10, 280)
    else
        Move(-50, -80)
        PasteWithOffset(50, -80)
        PasteWithOffset(-50, 70)
        PasteWithOffset(50, 70)
        RemoveOverlap()
        Rotate(28)
        Move(-10, 270)
    endif
    RemoveOverlap()
    Select(0u3066); Copy() # て
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Scale(60, 60, 500, 0)
    if (input_list[i] == "${input_kana_regular}")
        ChangeWeight(24)
    else
        ChangeWeight(42)
    endif
    CorrectDirection()
    Copy()
    Select(0u1b123); Paste()
    if (input_list[i] == "${input_kana_regular}")
        Move(-30, 282)
    else
        Move(-30, 290)
    endif
    # と
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(-70, -80)
        PasteWithOffset(70, -80)
        PasteWithOffset(-70, 70)
        PasteWithOffset(70, 70)
        RemoveOverlap()
        Rotate(27)
        Move(130, -253)
    else
        Move(-70, -80)
        PasteWithOffset(70, -80)
        PasteWithOffset(-70, 70)
        PasteWithOffset(70, 70)
        RemoveOverlap()
        Rotate(28)
        Move(130, -233)
    endif
    Select(0u3068); Copy() # と
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Scale(80, 80, 500, 0)
    if (input_list[i] == "${input_kana_regular}")
        ChangeWeight(12)
    else
        ChangeWeight(20)
    endif
    CorrectDirection()
    Copy()
    Select(0u1b123); PasteInto()
    RemoveOverlap()
    SetWidth(1000)

    Select(65552); Clear() # Temporary glyph

# 𛄤 (ﾄｷ)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(-616, 50)
        PasteWithOffset(-616, -50)
    else
        Move(-589, 55)
        PasteWithOffset(-589, -55)
    endif
    RemoveOverlap()
    Select(0uff84); Copy() # ﾄ
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    PasteWithOffset(-10, 0)
    Select(0u1b124); Paste()
    Select(0u30ad); Copy() # キ
    Select(0u1b124); PasteWithOffset(70, 0)
    RemoveOverlap()
    SetWidth(1000)

# 𛄥 (ﾄﾃ) (ﾄｷの後で加工すること)
    Select(65552);  Copy() # Temporary glyph (ﾄｷのト)
    Select(0u1b125); Paste()
    Select(0u30c6); Copy() # テ
    Select(0u1b125); PasteWithOffset(70, 0)
    RemoveOverlap()
    SetWidth(1000)

# 𪜈 (ﾄﾓ) (ﾄｷの後で加工すること)
    Select(65552);  Copy() # Temporary glyph (ﾄｷのト)
    Select(0u2a708); Paste()
    Select(0u30e2); Copy() # モ
    Select(0u2a708); PasteWithOffset(70, 0)
    RemoveOverlap()
    SetWidth(1000)

    Select(65552); Clear() # Temporary glyph

# 𛄦 (ﾖﾘ)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(380, 100)
    PasteWithOffset(380, -100)
    RemoveOverlap()
    Select(0u520a); Copy() # 刊
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u1b126); Paste() # ﾖﾘ
    Move(-5, 0)
    Select(0uff96); Copy() # ﾖ
    Select(0u1b126) # ﾖﾘ
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(5, 20)
        Move(0, -20)
    else
        PasteWithOffset(5, 15)
        Move(0, -15)
    endif
    SetWidth(1000)

    Select(65552); Clear() # Temporary glyph
    Select(0u520a) # 刊
    Clear(); DetachAndRemoveGlyphs()

# 𛄧 (ネ)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Move(191, -100)
        Rotate(-4)
        PasteWithOffset(-100, 150)
        PasteWithOffset(100, 150)
        PasteWithOffset(220, -90)
    else
        Move(185, -100)
        Rotate(-3)
        PasteWithOffset(-100, 150)
        PasteWithOffset(100, 150)
        PasteWithOffset(220, -90)
    endif
    RemoveOverlap()
    Select(0u5b50); Copy() # 子
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u1b127); Paste() # 𛄧
    SetWidth(1000)

    Select(65552); Clear() # Temporary glyph
    Select(0u5b50) # 子
    Clear(); DetachAndRemoveGlyphs()

# 𛄨 (ヰ)
    Select(0u4e95); Copy() # 井
    Select(0u1b128); Paste() # 𛄨
    SetWidth(1000)
    Select(0u4e95) # 井
    Clear(); DetachAndRemoveGlyphs()

# 𬼀 (ｼﾃ)
    Select(0u30e1);  Copy() # メ
    Select(0u2cf00); Paste() # ｼﾃ

    Select(0u30ce);  Copy() # ノ
    Select(65552);  Paste() # Temporary glyph
    Scale(300)
    if (input_list[i] == "${input_kana_regular}")
        Rotate(3)
        Move(-330, 329) # Temporary glyph
    else
        Rotate(5)
        Move(-354, 350) # Temporary glyph
    endif
    Select(0u25a0); Copy() # Black square
    Select(65552)
    PasteWithOffset(-270, 300)
    RemoveOverlap()
    Copy()
    Select(0u2cf00); PasteInto() # ｼﾃ
    OverlapIntersect()
    Simplify()
    Move(65, 0)
    SetWidth(1000)

    Select(65552); Clear() # Temporary glyph

# 𬼂 (なり)
    # はらい
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Rotate(41)
        Move(120, -328)
    else
        Rotate(39)
        Move(91, -341)
    endif
    PasteWithOffset(150, -470)
    RemoveOverlap()
    Select(0u2ecc); Copy() # ⻌
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u2cf02); Paste() # なり
    # 斜め線
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Rotate(-22)
        Move(-382, 373)
    else
        Rotate(-22)
        Move(-357, 335)
    endif
    Select(0u3093); Copy() # ん
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Rotate(-20)
    Copy()
    Select(0u2cf02) # ﾅﾘ
    if (input_list[i] == "${input_kana_regular}")
        PasteWithOffset(47, -243)
        RemoveOverlap()
        Simplify()
        ChangeWeight(8)
    else
        PasteWithOffset(47, -229)
        RemoveOverlap()
        Simplify()
        ChangeWeight(20)
    endif
    CorrectDirection()
    Move(-25, 120)
    SetWidth(1000)

    Select(65552); Clear() # Temporary glyph

# 𬻿 (ﾅﾘ)
    # はらい
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Rotate(41)
        Move(120, -328)
    else
        Rotate(39)
        Move(91, -341)
    endif
    PasteWithOffset(150, -470)
    RemoveOverlap()
    Select(0u2ecc); Copy() # ⻌
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u2ceff); Paste() # ﾅﾘ

    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kana_regular}")
        Rotate(39)
        Move(-290, -655)
        PasteWithOffset(140, -470)
    else
        Rotate(39)
        Move(-290, -622)
        PasteWithOffset(160, -470)
    endif
    RemoveOverlap()
    Copy()
    Select(0u2ceff); PasteInto() # ﾅﾘ
    OverlapIntersect()

    # 点
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-150, 430)
    Select(0u2ecc); Copy() # ⻌
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Simplify()
    Copy()
    Select(0u2ceff); PasteWithOffset(280, -200) # ﾅﾘ
    if (input_list[i] == "${input_kana_regular}")
        ChangeWeight(8)
    else
        ChangeWeight(20)
    endif
    CorrectDirection()
    Move(-25, 120)
    SetWidth(1000)

    Select(65552); Clear() # Temporary glyph

# ひらがなを少し左右に移動
    if ("${draft_flag}" == "false")
        Print("Move hiragana glyphs")
        Select(0u3044) # い
        Move(-10, 0)
        SetWidth(1000)
        Select(0u3043) # ぃ
        SelectMore(1114410) # 縦書き ぃ
        Move(-7, 0)
        SetWidth(1000)

        Select(0u3046) # う
        SelectMore(0u3094) # ゔ
        Move(-10, 0)
        SetWidth(1000)
        Select(0u3045) # ぅ
        SelectMore(1114411) # 縦書き ぅ
        Move(-7, 0)
        SetWidth(1000)

        Select(0u304d, 0u304e) # きぎ
        SelectMore(1114116) # き゚
        Move(-5, 0)
        SetWidth(1000)

        Select(0u304f) # く
        Move(10, 0)
        SetWidth(1000)
        Select(0u3050) # ぐ
        SelectMore(1114117) # く゚
        Move(40, 0)
        SetWidth(1000)

        Select(0u3051, 0u3052) # けげ
        SelectMore(1114118) # け゚
        Move(10, 0)
        SetWidth(1000)
        Select(0u3096) # ゖ
        SelectMore(1114420) # 縦書き ゖ
        Move(7, 0)
        SetWidth(1000)

        Select(0u3055, 0u3056) # さざ
        Move(-5, 0)
        SetWidth(1000)

        Select(0u3059, 0u305a) # すず
        Move(-10, 0)
        SetWidth(1000)

        Select(0u305f, 0u3060) # ただ
        Move(10, 0)
        SetWidth(1000)

        Select(0u3064, 0u3065) # つづ
        Move(-10, 0)
        SetWidth(1000)
        Select(0u3063) # っ
        SelectMore(1114414) # 縦書き っ
        Move(-7, 0)
        SetWidth(1000)

        Select(0u306a) # な
        Move(10, 0)
        SetWidth(1000)

        Select(0u306e) # の
        Move(-5, 0)
        SetWidth(1000)

        Select(0u306f, 0u3071) # はばぱ
        Move(10, 0)
        SetWidth(1000)

        Select(0u307b, 0u307d) # ほぼぽ
        Move(10, 0)
        SetWidth(1000)

        Select(0u307e) # ま
        Move(-10, 0)
        SetWidth(1000)

        Select(0u3082) # も
        Move(-10, 0)
        SetWidth(1000)

        Select(0u3088) # よ
        Move(-10, 0)
        SetWidth(1000)
        Select(0u3087) # ょ
        SelectMore(1114417) # 縦書き ょ
        Move(-7, 0)
        SetWidth(1000)

        Select(0u308a) # り
        Move(-5, 0)
        SetWidth(1000)

        Select(0u308c) # れ
        Move(10, 0)
        SetWidth(1000)

        Select(0u3092) # を
        Move(5, 0)
        SetWidth(1000)

        Select(0u3093) # ん
        Move(5, 0)
        SetWidth(1000)
    endif

    if ("${draft_flag}" == "false")
# カタカナを少し下に移動 (カタカナ拡張は縦書き用の移動不要(グリフが無い))
        Print("Move katakana glyphs")
        Select(0u30a1, 0u30fa) # カタカナ
        SelectMore(0u31f0, 0u31ff) # カナカナ拡張
        SelectMore(1114120, 1114128) # 合字カタカナ
        SelectMore(1114421, 1114432) # 縦書き小文字カタカナ
        SelectMore(0uff66, 0uff9d) # 半角カナ
        SelectMore(0u1b000) # 𛀀
        SelectMore(0u1b120, 0u1b122) # 𛄠𛄡𛄢
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
        SelectMore(1114120) # カ゚
        SelectMore(1114431) # 縦書き ヵ
        SelectMore(0u30b3, 0u30b4) # コ ゴ
        SelectMore(0uff7a) # ｺ
        SelectMore(1114124) # コ゚
        SelectMore(0u30bb, 0u30bc) # セ ゼ
        SelectMore(0uff7e) # ｾ
        SelectMore(1114125) # セ゚
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
        SelectMore(0u1b121 , 0u1b122) # 𛄡𛄢
        Move(0, -10)

        Select(0u30a3, 0u30a4) # ィ イ
        SelectMore(0uff72) # ｲ
        SelectMore(0uff68) # ｨ
        SelectMore(1114422) # 縦書き ィ
        SelectMore(0u30ad, 0u30ae) # キ ギ
        SelectMore(0uff77) # ｷ
        SelectMore(1114121) # キ゚
        SelectMore(0u30c8, 0u30c9) # ト ド
        SelectMore(0uff84) # ﾄ
        SelectMore(0u31f3) # ㇳ
        SelectMore(1114127) # ト゚
        SelectMore(0u30ea) # リ
        SelectMore(0uff98) # ﾘ
        SelectMore(0u31fc) # ㇼ
        Move(0, 5)

# カタカナを少し左右に移動
        Select(0u30a4) # イ
        Move(-10, 0)
        SetWidth(1000)
        Select(0u30a3) # ィ
        SelectMore(1114422) # 縦書き ィ
        Move(-7, 0)
        SetWidth(1000)

        Select(0u30af, 0u30b0) # ク グ
        SelectMore(1114122) # ク゚
        Move(-5, 0)
        SetWidth(1000)
        Select(0u31f0) # ㇰ
        Move(-3, 0)
        SetWidth(1000)

        Select(0u30b3, 0u30b4) # コ ゴ
        SelectMore(1114124) # コ゚
        Move(-10, 0)
        SetWidth(1000)

        Select(0u30eb) # ル
        Move(5, 0)
        SetWidth(1000)
        Select(0u31fd) # ㇽ
        Move(3, 0)
        SetWidth(1000)

        Select(0u1b000) # 𛀀
        Move(20, 0)
        SetWidth(1000)
    endif

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
            SelectMore(0u1b000) # 𛀀
            SelectMore(0u1b120, 0u1b122) # 𛄠𛄡𛄢
            SelectMore(0u1b123) # 𛄣
            SelectMore(0u1b124, 0u1b126) # 𛄤𛄥𛄦
            SelectMore(0u1b127, 0u1b128) # 𛄧𛄨
            SelectMore(0u2a708) # 𪜈
            SelectMore(0u2ceff) # 𬻿
            SelectMore(0u2cf00) # 𬼀
            SelectMore(0u2cf02) # 𬼂
 #            SelectMore(0u1b001) # 𛀁 (変体仮名フォント追加のため削除済み)
            SelectMore(1114115, 1114128) # 合字ひらがなカタカナ
            SelectMore(1114384, 1114385) # 縦書き 、。
            SelectMore(1114386, 1114395) # 縦書き括弧
            SelectMore(1114397, 1114408) # 縦書き括弧、〜、引用符
            SelectMore(1114409, 1114432) # 縦書き小文字ひらがなカタカナ
            SelectMore(1114433) # 縦書き ー
            SelectMore(${address_store_visi_kana}) # 保管した゠
            ChangeWeight(${weight_kana_bold}); CorrectDirection()
        endif
    endif

# ラテン文字、ギリシア文字、キリル文字等のウェイト調整
    if ("${draft_flag}" == "false")
        Print("Edit latin greek cyrillic weight of glyphs")
        Select(0u00a1, 0u0173) # Latin
        SelectMore(0u0174, 0u0175) # Ŵŵ
        SelectMore(0u0176, 0u0179) # ŶŷŸŹ
        SelectMore(0u017a) # ź latin フォント優先、kana フォントで上書きの場合、形が崩れるので注意
        SelectMore(0u017b) # Ż
        SelectMore(0u017c) # ż latin フォント優先、kana フォントで上書きの場合、形が崩れるので注意
        SelectMore(0u017d) # Ž
        SelectMore(0u017e) # ž latin フォント優先、kana フォントで上書きの場合、形が崩れるので注意
        SelectMore(0u017f, 0u019c)
        SelectMore(0u019e, 0u01c3)
 #        SelectMore(0u01c4, 0u01cc) # リガチャ
        SelectMore(0u01cd, 0u01ee)
        SelectMore(0u01f0) # ǰ
 #        SelectMore(0u01f1, 0u01f3) # リガチャ
        SelectMore(0u01f4, 0u01f5) # Ǵǵ
        SelectMore(0u01f7, 0u026d)
 #        SelectMore(0u026e) # リガチャ
        SelectMore(0u026f, 0u028c)
        SelectMore(0u028d) # ʍ
        SelectMore(0u028e, 0u028f) # ʎʏ
        SelectMore(0u0294, 0u02a2)
 #        SelectMore(0u02a3, 0u02ac) # リガチャ
        SelectMore(0u02ad, 0u02af) # ʭʮʯ
        SelectMore(0u02b9, 0u02bf) # 装飾文字
 #        SelectMore(0u02c0, 0u02c1) # ˀˁ
        SelectMore(0u02c2, 0u02df) # 装飾文字
        SelectMore(0u02e5, 0u02ff) # 装飾文字
        SelectMore(0u0372, 0u03ff) # Greek
        SelectMore(0u0400, 0u04ff) # Cyrillic
        SelectMore(0u1d05) # ᴅ
        SelectMore(0u1d07) # ᴇ
        SelectMore(0u1e00, 0u1e3d)
        SelectMore(0u1e3e) # Ḿ
        SelectMore(0u1e3f) # ḿ
        SelectMore(0u1e40) # Ṁ
        SelectMore(0u1e41) # ṁ
        SelectMore(0u1e42) # Ṃ
        SelectMore(0u1e43, 0u1e7f)
        SelectMore(0u1e80, 0u1e89) # Ẁ-ẉ
        SelectMore(0u1e8a, 0u1e92)
        SelectMore(0u1e93) # ẓ latin フォント優先、kana フォントで上書きの場合、形が崩れるので注意
        SelectMore(0u1e94) # Ẕ
        SelectMore(0u1e95) # ẕ latin フォント優先、kana フォントで上書きの場合、形が崩れるので注意
        SelectMore(0u1e96, 0u1e97)
        SelectMore(0u1e98) # ẘ
        SelectMore(0u1e99, 0u1efe)
        SelectMore(0u1f00, 0u1f0e) # Greek
        SelectMore(0u1f10, 0u1f8e) # Greek
        SelectMore(0u1f90, 0u1fff) # Greek
        SelectMore(0u2422) # ␢
        SelectMore(0u2c71) # ⱱ
        SelectMore(0ufb00, 0ufb04) # ﬀ-ﬄ
        if (input_list[i] == "${input_kana_regular}")
            ChangeWeight(${weight_kana_others_regular})
            Move(0, -2)
        else
            ChangeWeight(${weight_kana_others_bold})
            Move(0, -9)
        endif
        CorrectDirection()

        Select(0u1f0f) # Ἇ
        SelectMore(0u1f8f) # ᾏ
        if (input_list[i] == "${input_kana_regular}")
            ExpandStroke(1, 0, 0, 0, 1) # いきなりChangeWeight()だと形が崩れる
            ChangeWeight(${weight_kana_others_regular} - 1)
            Move(0, -2)
        else
            ChangeWeight(${weight_kana_others_bold})
            Move(0, -9)
        endif
        CorrectDirection()

        Select(0u0291) # ʑ
        if (input_list[i] == "${input_kana_regular}")
            ExpandStroke(1, 0, 0, 0, 1) # いきなりChangeWeight()だと形が崩れる
            CorrectDirection()
            ExpandStroke(-1, 0, 0, 0, 2)
            CorrectDirection()
            ChangeWeight(${weight_kana_others_regular})
            Move(0, -2)
        else
            ChangeWeight(${weight_kana_others_bold})
            Move(0, -9)
        endif
        CorrectDirection()

        Select(0u019d) # Ɲ
        SelectMore(0u01ef) # ǯ
        SelectMore(0u0290) # ʐ
        SelectMore(0u0292) # ʒ
        SelectMore(0u0293) # ʓ
        SelectMore(0u1eff) # ỿ
        if (input_list[i] == "${input_kana_regular}")
            Scale(200) # いきなりChangeWeight()だと形が崩れる
            ChangeWeight(${weight_kana_others_regular} * 2)
            Scale(50)
            Move(0, -2)
        else
            ChangeWeight(${weight_kana_others_bold})
            Move(0, -9)
        endif
        CorrectDirection()
        SetWidth(500)

        Select(0u20a0, 0u212d) # 記号類
 #        SelectMore(0u212e) # ℮
        SelectMore(0u212f, 0u214f) # 記号類
        SelectMore(0u2150, 0u21cf) # ローマ数字、矢印
        SelectMore(0u21dc, 0u21e5) # 矢印
        SelectMore(0u21f0, 0u22ed) # 記号類
        SelectMore(0u22f0, 0u2306) # 記号類
        SelectMore(0u2308, 0u2311) # 記号類
 #        SelectMore(0u2312, 0u2313) # ⌒⌓ # グリフ加工でウェイト調整済
        SelectMore(0u2329, 0u232a) # 〈〉
 #        SelectMore(0u2330, 0u2333) # ⌰⌱⌲⌳ # グリフ加工でウェイト調整済
 #        SelectMore(0u23cf) # ⏏
 #        SelectMore(0u23e4, 0u23e5) # ⏤⏥ # グリフ加工でウェイト調整済
 #        SelectMore(0u2425) # ␥ # グリフ加工でウェイト調整済
        SelectMore(0u27e8, 0u27e9) # ⟨⟩
        SelectMore(0u2a2f) # ⨯
        SelectMore(0u339b, 0u339d) # ㎛㎜㎝
        SelectMore(0u339f, 0u33a1) # ㎟㎠㎡
        SelectMore(0u33a3, 0u33a5) # ㎣㎤㎥
        if (input_list[i] == "${input_kana_regular}")
            ChangeWeight(${weight_kana_others_regular})
        else
            ChangeWeight(${weight_kana_others_bold})
        endif
        CorrectDirection()

        Select(0u339e) # ㎞
        SelectMore(0u33a2) # ㎢
        SelectMore(0u33a6) # ㎦
        if (input_list[i] == "${input_kana_regular}")
            ExpandStroke(${weight_kana_others_regular}, 0, 0, 0, 2) # ChangeWeight()だと形が崩れる
        else
            ChangeWeight(${weight_kana_others_bold})
        endif
        CorrectDirection()

        Select(0u25a0, 0u25cb) # 幾何学模様
 #        SelectMore(0u25cc) # ◌
        SelectMore(0u25cd, 0u25d8) # 幾何学模様
 #        SelectMore(0u25d9) # ◙
        SelectMore(0u25da, 0u2667) # 幾何学模様
        if (input_list[i] == "${input_kana_regular}")
            ChangeWeight(${weight_kana_geometry_regular})
        else
            ChangeWeight(${weight_kana_geometry_bold})
        endif
        CorrectDirection()

    endif

# 縦書き対応 (カタカナ拡張、小仮名拡張以外の小文字を改変した場合は要コピー)
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

# ゅ (加工したグリフをコピー)
    Select(0u3085); Copy() # ゅ
    Select(1114416); Paste()
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

# ァ (加工したグリフをコピー)
    Select(0u30a1); Copy() # ァ
    Select(1114421); Paste()
    Move(72, 73)
    SetWidth(1000)

# ィ (加工したグリフをコピー)
    Select(0u30a3); Copy() # ィ
    Select(1114422); Paste()
    Move(72, 73)
    SetWidth(1000)

# Lookup追加
    Select(0u3041) # ぁ
    lookups = GetPosSub("*") # フィーチャを取り出す
# 全角横向 (後でグリフ上書き)
    hori = [0uff0d, 0uff1b, 0uff1c, 0uff1e,\
            0uff5f, 0uff60]  # －；＜＞,｟｠
    vert = ${address_vert_start_kana}
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

# カナ (‖〰゠ (回転させる文字) は後でグリフ上書き、その他はグリフそのまま)
    hori = [0u2016, 0u3030, 0u30a0,\
            0u31f0, 0u31f1, 0u31f2, 0u31f3,\
            0u31f4, 0u31f5, 0u31f6, 0u31f7,\
            0u31f8, 0u31f9, 0u31fa, 0u31fb,\
            0u31fc, 0u31fd, 0u31fe, 0u31ff,\
            1114128] # ‖〰゠, カタカナ拡張
    vert += j
    j = 0
    while (j < SizeOf(hori))
        Select(hori[j]); Copy()
        Select(vert + j); Paste()
        if (3 <= j) # カタカナ拡張
            Move(72, 73)
        endif
        SetWidth(1000)
        glyphName = GlyphInfo("Name")
        Select(hori[j])
        AddPosSub(lookups[0][0],glyphName)
        j += 1
    endloop

# 小仮名拡張追加 (address_vert_mm が変化するので注意)
    Print("Edit small kana glyphs")

    kana = [0u304d, 0u304f, 0u3053, 0u3055, 0u3057, 0u3059, 0u305b, 0u305d,\
            0u305f, 0u3061, 0u3066, 0u3068, 0u306a, 0u306b, 0u306c, 0u306d,\
            0u306e, 0u306f, 0u3072, 0u3075, 0u3078, 0u307b, 0u307e, 0u307f,\
            0u3080, 0u3081, 0u3082, 0u3089, 0u308a, 0u308b, 0u308c, 0u308d,\
            0u3090, 0u3091, 0u3092, 0u3093, 0u30ad, 0u30b3, 0u30b5, 0u30bb,\
            0u30bd, 0u30bf, 0u30c1, 0u30c6, 0u30ca, 0u30cb, 0u30cd, 0u30ce,\
            0u30de, 0u30df, 0u30e1, 0u30e2, 0u30f0, 0u30f1, 0u30f2, 0u30f3,\
            0u1b121] # き-そ, た-ね, の-み, む-ろ, ゐ-セ, ソ-ノ, マ-ン, 𛄡
    k = 0
    while (k < SizeOf(kana))
        Select(kana[k]); Copy()
        Select(0u1b130 + k); Paste()
        Scale(80, 80, 500, 0)
        if (input_list[i] == "${input_kana_regular}")
            ChangeWeight(${weight_small_kana_regular})
        else
            ChangeWeight(${weight_small_kana_bold}) # 他のグリフとは別でウェイトを調整
        endif
        CorrectDirection()
        Move(0, -9)
        SetWidth(1000)
        k += 1
    endloop

    # 縦書き対応 (グリフそのまま、前の縦書き対応のカウンタ等をそのまま利用)
    vert += j
    j = 0
    while (j < 57)
        Select(0u1b130 + j); Copy()
        Select(vert + j); Paste()
        Move(72, 73)
        SetWidth(1000)
        glyphName = GlyphInfo("Name")
        Select(0u1b130 + j)
        AddPosSub(lookups[0][0],glyphName)
        j += 1
    endloop

# --------------------------------------------------

# 一部を除いた半角文字を拡大
    if ("${draft_flag}" == "false")
        if (${scale_width_kana} != 100 || ${scale_height_kana} != 100)
            Print("Edit hankaku aspect ratio")

            Select(0u0021, 0u1fff) # 基本ラテン - ギリシャ文字拡張
            SelectFewer(0u00a0) # ノーブレークスペースを除外
            SelectMore(0u2010, 0u218f) # 一般句読点 - 数字の形
            SelectMore(0u2200, 0u22ff) # 数学記号
            SelectMore(0u27c0, 0u27ef) # その他の数学記号 A
            SelectMore(0u2980, 0u2aff) # その他の数学記号 B - 補助数学記号
            SelectMore(0u2c60, 0u2c7f) # ラテン文字拡張 C
            SelectMore(0u2e00, 0u2e7f) # 補助句読点
            SelectMore(0ua700, 0ua7ff) # 声調装飾文字 - ラテン文字拡張 D
            SelectMore(0ufb00, 0ufb4f) # アルファベット表示形
            foreach
                if (WorthOutputting())
                    if (GlyphInfo("Width") <= 700)
                        Scale(${scale_width_kana}, ${scale_height_kana}, 250, 0)
                        SetWidth(500)
                    endif
                endif
            endloop

            Select(0u2190, 0u21ff) # 矢印
            SelectMore(0u2300, 0u231f) # その他の技術用記号 1
            SelectMore(0u2322, 0u239a) # その他の技術用記号 2
            SelectMore(0u23af) # その他の技術用記号 3
            SelectMore(0u23b4, 0u23bd) # その他の技術用記号 4
            SelectMore(0u23cd, 0u23ff) # その他の技術用記号 5
            SelectMore(0u2400, 0u24ff) # 制御機能用記号 - 囲み英数字
            SelectMore(0u25a0, 0u25ff) # 幾何学模様
            SelectMore(0u2600, 0u27bf) # その他の記号 - 装飾記号
            SelectMore(0u27f0, 0u27ff) # 補助矢印 A
            SelectMore(0u2900, 0u297f) # 補助矢印 B
            SelectMore(0u2b00, 0u2bff) # その他の記号および矢印
            SelectMore(0ufffd) # 特殊用途文字
            foreach
                if (WorthOutputting())
                    if (GlyphInfo("Width") <= 700)
                        Scale(${scale_width_kana}, ${scale_height_kana}, 250, 332)
                        SetWidth(500)
                    endif
                endif
            endloop

            Select(0u2320, 0u2321) # インテグラル
            SelectMore(0u239b, 0u23ae) # 括弧・インテグラル
            SelectMore(0u23b0, 0u23b3) # 括弧括弧素片・総和記号部分
            SelectMore(0u23be, 0u23cc) # 歯科表記記号
            foreach
                if (WorthOutputting())
                    if (GlyphInfo("Width") <= 700)
                        Scale(${scale_width_kana}, 100, 250, 332)
                        SetWidth(500)
                    endif
                endif
            endloop

        endif
    endif

# 全角文字を移動
    if ("${draft_flag}" == "false")
        Print("Move zenkaku glyphs")
        SelectWorthOutputting()
        foreach
            if (800 <= GlyphInfo("Width"))
                Move(${move_x_zenkaku_kana}, 0)
                SetWidth(-${move_x_zenkaku_kana}, 1)
            endif
        endloop
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

Print("- Generate modified kanji fonts -")

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
    ScaleToEm(${em_ascent1024}, ${em_descent1024}) # OS/2テーブルを書き換えないと指定したem値にならない
    SetOS2Value("WinAscent",             ${win_ascent1024}) # WindowsGDI用 (この範囲外は描画されない)
    SetOS2Value("WinDescent",            ${win_descent1024})
    SetOS2Value("TypoAscent",            ${typo_ascent1024}) # 組版・DirectWrite用 (Mac も使っているっぽい)
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
    SelectMore(1115735, 1115737)
 #    SelectMore(1115738, 1115741) # ◢◣◥◤
    SelectMore(1115742, 1115760)
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
        j += 1
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
    Print("Edit kanji")

# 〇 (上にうろこを追加)
    Select(0u3007); Copy() # 〇
    Select(${address_store_visi_kanzi}); Paste() # 保管所

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
    Select(${address_store_visi_kanzi} + 1); Paste() # 保管所

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
    Select(${address_store_visi_kanzi} + 2); Paste() # 保管所

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
    Select(${address_store_visi_kanzi} + 3); Paste() # 保管所

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
    Select(${address_store_visi_kanzi} + 4); Paste() # 保管所

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
    Select(${address_store_visi_kanzi} + 5); Paste() # 保管所

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
    Select(${address_store_visi_kanzi} + 6); Paste() # 保管所

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
    Select(${address_store_visi_kanzi} + 7); Paste() # 保管所

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
    Select(${address_store_visi_kanzi} + 8); Paste() # 保管所

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

# 于 (横棒にうろこを追加)
    Select(0u4e8e); Copy() # 于
    Select(${address_store_visi_kanzi} + 9); Paste() # 保管所

    Select(0u002e); Copy() # Full stop
    Select(65552);  Paste() # Temporary glyph
    Scale(59); Copy()
    Select(0u4e8e) # 于
    if (input_list[i] == "${input_kanzi_regular}")
        PasteWithOffset(708, 376)
    else
        PasteWithOffset(682, 385)
        PasteWithOffset(694, 385)
    endif
    RemoveOverlap()
    Simplify()
    SetWidth(1024)
    Select(65552); Clear() # Temporary glyph

# 井 (横棒にうろこを追加)
    Select(0u4e95); Copy() # 井
    Select(${address_store_visi_kanzi} + 10); Paste() # 保管所

    Select(0u002e); Copy() # Full stop
    Select(65552);  Paste() # Temporary glyph
    Scale(59); Copy()
    Select(0u4e95) # 井
    if (input_list[i] == "${input_kanzi_regular}")
        PasteWithOffset(706, 265)
    else
        PasteWithOffset(677, 266)
        PasteWithOffset(689, 266)
    endif
    RemoveOverlap()
    Simplify()
    SetWidth(1024)
    Select(65552); Clear() # Temporary glyph

# 子 (横棒にうろこを追加)
    Select(0u5b50); Copy() # 子
    Select(${address_store_visi_kanzi} + 11); Paste() # 保管所

    Select(0u002e); Copy() # Full stop
    Select(65552);  Paste() # Temporary glyph
    Scale(59); Copy()
    Select(0u5b50) # 子
    if (input_list[i] == "${input_kanzi_regular}")
        PasteWithOffset(702, 348)
    else
        PasteWithOffset(669, 342)
        PasteWithOffset(681, 342)
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
    lookups = GetPosSub("*") # フィーチャを取り出す

    Select(0u5409) # 吉
    glyphName = GlyphInfo("Name")
    Select(0u20bb7); RemovePosSub("*") # 𠮷
    AddPosSub(lookups[0][0],glyphName)
    glyphName = GlyphInfo("Name")
    Select(0u5409); RemovePosSub("*") # 吉
    AddPosSub(lookups[0][0],glyphName)

# 記号のグリフを加工
    Print("Edit symbols")

# ‱ (追加)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(150); Move(-385, 0)
    Select(0u2030); Copy() # ‰
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u2031); Paste() # ‰
    Move(-30, 0)

    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(150); Move(685, 0)
    Select(0u2030); Copy() # ‰
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u2031) # ‰
    PasteWithOffset(-65, 0)
    PasteWithOffset(198, 0)

    Scale(90.5, 100, 0, 0)
    SetWidth(1024)
    Select(65552); Clear() # Temporary glyph

# 🎤 (追加)
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

# Ⅰⅰ(縦線を少し細く)
    Select(0u2160) # Ⅰ
    SelectMore(0u2170) # ⅰ
    if (input_list[i] == "${input_kanzi_regular}")
        Scale(86, 100)
    else
        Scale(91, 100)
    endif
    SetWidth(1024)

# Ⅱⅱ(縦線を少し細く)
    Select(0u2161) # Ⅱ
    SelectMore(0u2171) # ⅱ
    if (input_list[i] == "${input_kanzi_regular}")
        Scale(88, 100)
    else
        Scale(96, 100)
    endif
    SetWidth(1024)

# Ⅲⅲ(縦線を少し細く)
    Select(0u2162) # Ⅲ
    SelectMore(0u2172) # ⅲ
    if (input_list[i] == "${input_kanzi_regular}")
        Scale(93, 100)
    endif
    SetWidth(1024)

# Ⅼ-Ⅿ (ローマ数字、全角英数をコピー)
    Select(0uff2c); Copy() # Ｌ
    Select(0u216c); Paste() # ローマ数字Ⅼ
    Select(0uff23); Copy() # Ｃ
    Select(0u216d); Paste() # ローマ数字Ⅽ
    Select(0u2183); Paste() # ローマ数字Ↄ
    HFlip()
    CorrectDirection()
    Move(4, 0)
    SetWidth(1024)
    Select(0uff24); Copy() # Ｄ
    Select(0u216e); Paste() # ローマ数字Ⅾ
    Select(0uff2d); Copy() # Ｍ
    Select(0u216f); Paste() # ローマ数字Ⅿ

# ⅼ-ⅿ (ローマ数字、全角英数をコピー)
    Select(0uff4c); Copy() # ｌ
    Select(0u217c); Paste() # ローマ数字ⅼ
    Select(0uff43); Copy() # ｃ
    Select(0u217d); Paste() # ローマ数字ⅽ
    Select(0u2184); Paste() # ローマ数字ↄ
    HFlip()
    CorrectDirection()
    Move(-8, 0)
    SetWidth(1024)
    Select(0uff44); Copy() # ｄ
    Select(0u217e); Paste() # ローマ数字ⅾ
    Select(0uff4d); Copy() # ｍ
    Select(0u217f); Paste() # ローマ数字ⅿ

# ∅ (少し回転)
    Select(0u2205) # ∅
    Rotate(5, 256, 339)
    SetWidth(512)

# ∈ (半角にする)
    Select(0u2208) # ∈
    Select(0u25a0); Copy() # Black square
    Select(0u2208); PasteWithOffset(-301, 0) # ∈
    OverlapIntersect()
    Move(-106, 0)
    SetWidth(512)

# ∋ (半角にする)
    Select(0u220b) # ∋
    Select(0u25a0); Copy() # Black square
    Select(0u220b); PasteWithOffset(291, 0) # ∋
    OverlapIntersect()
    Move(-326, 0)
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

# ⊼ (追加) ※ ∧ より後に加工すること
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

# ∩ (半角にする) ※ 🎤 より後に加工すること
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
    Move(-106, 0)
    SetWidth(512)

# ⊃ (半角にする)
    Select(0u25a0); Copy() # Black square
    Select(0u2283); PasteWithOffset(291, 0) # ⊃
    OverlapIntersect()
    Move(-326, 0)
    SetWidth(512)

# ⊆ (半角にする)
    Select(0u25a0); Copy() # Black square
    Select(0u2286); PasteWithOffset(-301, 0) # ⊆
    OverlapIntersect()
    Move(-106, 0)
    SetWidth(512)

# ⊇ (半角にする)
    Select(0u25a0); Copy() # Black square
    Select(0u2287); PasteWithOffset(291, 0) # ⊇
    OverlapIntersect()
    Move(-326, 0)
    SetWidth(512)

# ⊻ (追加) ※ ∨ より後に加工すること
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

# ∭ (追加)
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

# ≡ (半角にする)
    Select(0u2261); Copy() # ≡
    Scale(70, 100)
    Move(-222, 0)
    SetWidth(512)

# ≢ (横棒を延ばす)
    Select(0u2261); Copy() # ≡
    Select(0u2262); Paste() # ≢
    Select(0u002f); Copy() # /
    Select(65552);  Paste() # Temporary glyph
    Scale(121)
    Copy()
    Select(0u2262); PasteInto() # ≢
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Scale(95)
    Copy()
    Select(0u2262); PasteWithOffset(-140, 0) # ≢
    OverlapIntersect()
    RemoveOverlap()
    SetWidth(512)
    Select(65552); Clear() # Temporary glyph

# ≢ (全角にする)
 #    Select(0u2261); Copy() # ≡
 #    Select(0u2262); Paste() # ≢
 #    Select(0u002f); Copy() # /
 #    Select(65552);  Paste() # Temporary glyph
 #    Scale(121)
 #    Move(230, 0)
 #    Copy()
 #    Select(0u2262); PasteInto() # ≢
 #    RemoveOverlap()
 #    Select(0u25a0); Copy() # Black square
 #    Select(65552);  Paste() # Temporary glyph
 #    Scale(95)
 #    Copy()
 #    Select(0u2262); PasteInto() # ≢
 #    OverlapIntersect()
 #    SetWidth(1024)
 #    Select(65552); Clear() # Temporary glyph

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

# ⊢ (追加)
    Select(0u22a5); Copy() # ⊥
    Select(0u22a2); Paste() # ⊥
    Rotate(-90)
    SetWidth(1024)

# ⊣ (追加)
    Select(0u22a5); Copy() # ⊥
    Select(0u22a3); Paste() # ⊣
    Rotate(90)
    SetWidth(1024)

# ⊤ (追加)
    Select(0u22a5); Copy() # ⊥
    Select(0u22a4); Paste() # ⊤
    Rotate(180)
    SetWidth(1024)

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
        ChangeWeight(-8)
    else
        ChangeWeight(-10)
    endif
    CorrectDirection()
    Move(240, 224)
    SetWidth(1024)
    Select(65552); Clear() # Temporary glyph

# ⌤ (追加) ※ ⌃ より後に加工すること
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

# ⌵ (追加)
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(627, -130)
    PasteWithOffset(140, -613)
    RemoveOverlap()
    Select(0u22bf); Copy() # ⊿
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Rotate(-45)
    if (input_list[i] == "${input_kanzi_regular}")
        Move(-42, 195)
    else
        Move(-55, 195)
    endif
    Copy()
    Select(0u2335); Paste() # ⌵
    if (input_list[i] == "${input_kanzi_regular}")
        ChangeWeight(8)
    else
        ChangeWeight(16)
    endif
    CorrectDirection()
    SetWidth(1024)
    Select(65552); Clear() # Temporary glyph

# ⌨ (追加)
    Select(0u25a1); Copy() # □
    Select(0u2328); Paste() # ⌨
    if (input_list[i] == "${input_kanzi_regular}")
        Scale(122, 88)
        Copy()
        Move(0, 11)
        Select(0u2328); PasteWithOffset(0, -11) # ⌨
        RemoveOverlap()
        ChangeWeight(-10)
    else
        Scale(126, 92)
        Copy()
        Move(0, 15)
        Select(0u2328); PasteWithOffset(0, -15) # ⌨
        RemoveOverlap()
        ChangeWeight(-28)
    endif
    CorrectDirection()
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    if (input_list[i] == "${input_kanzi_regular}")
        Scale(12, 12)
    else
        Scale(13, 13)
    endif
    Copy()
    Select(0u2328) # ⌨
    PasteWithOffset(-260, 150)
    PasteWithOffset(-245, 150)
    PasteWithOffset( -95, 150)
    PasteWithOffset(  55, 150)
    PasteWithOffset( 205, 150)
    PasteWithOffset( 260, 150)

    PasteWithOffset(-260,   0)
    PasteWithOffset(-210,   0)
    PasteWithOffset( -60,   0)
    PasteWithOffset(  90,   0)
    PasteWithOffset( 240,   0)
    PasteWithOffset( 260,   0)

    PasteWithOffset(-260, -150)
    PasteWithOffset(-110, -150)
    PasteWithOffset( -50, -150)
    PasteWithOffset(   0, -150)
    PasteWithOffset(  50, -150)
    PasteWithOffset( 110, -150)
    PasteWithOffset( 260, -150)

    RemoveOverlap()
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

# Ⓐ-Ⓩ (追加)
    j = 0
    while (j < 26)
        Select(0uff21 + j); Copy() # Ａ-Ｚ
        Select(0u24b6 + j); Paste() # Ⓐ-Ⓩ
        Scale(74)
        ChangeWeight(12)
        CorrectDirection()
        if (j == 2 || j == 5 || j == 6 || j == 10 || j == 11) #CFGKL
          Move(-20, 0)
        elseif (j == 4) # E
          Move(-10, 0)
        elseif (j == 1 || j == 3) # BD
          Move(10, 0)
        elseif (j == 9) # J
          Move(20, 0)
        elseif (j == 20) # U
          Move(0, -10)
        elseif (j == 21 || j == 22) # VW
          Move(0, -20)
        elseif (j == 19 || j == 24) # TY
          Move(0, -30)
        elseif (j == 0) # A
          Move(0, 20)
        endif
        Select(0u25ef); Copy() # ◯
        Select(0u24b6 + j); PasteInto() # Ⓐ-Ⓩ
        SetWidth(1024)
        j += 1
    endloop

# ◢◣◤◥ (追加)
    Select(1115738); Copy()
    Select(0u25e2); Paste() # ◢
    Scale(${scale_width_triangle}, ${scale_height_triangle} + 0.1, 924, -170)
    Move(105 -${move_x_zenkaku_kanzi}, ${move_y_lower_triangle})
    SetWidth(1024)
    Select(1115739); Copy()
    Select(0u25e3); Paste() # ◣
    Scale(${scale_width_triangle}, ${scale_height_triangle} + 0.1, 33, -170)
    Move(-38 -${move_x_zenkaku_kanzi}, ${move_y_lower_triangle})
    SetWidth(1024)
    Select(1115741); Copy()
    Select(0u25e4); Paste() # ◤
    Scale(${scale_width_triangle}, ${scale_height_triangle}, 33, 784)
    Move(-38 -${move_x_zenkaku_kanzi}, ${move_y_upper_triangle})
    SetWidth(1024)
    Select(1115740); Copy()
    Select(0u25e5); Paste() # ◥
    Scale(${scale_width_triangle}, ${scale_height_triangle}, 924, 784)
    Move(105 -${move_x_zenkaku_kanzi}, ${move_y_upper_triangle})
    SetWidth(1024)
    Select(1115738, 1115741)
    Clear(); DetachAndRemoveGlyphs()

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
    # 数字
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(500, 570)
    Select(0u339f); Copy() # ㎟
    Select(65553);  PasteWithOffset(0, 20) # Temporary glyph
    OverlapIntersect()
    Scale(130)
    # その他
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
    # 合成
    Select(65553);  Copy() # Temporary glyph
    Select(0u339f); PasteInto(); SetWidth(1024) # ㎟
    Select(0u33a0); PasteInto(); SetWidth(1024) # ㎠
    Select(0u33a1); PasteInto(); SetWidth(1024) # ㎡
    Select(0u33a2); PasteInto(); SetWidth(1024) # ㎢

    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# ㎣㎤㎥㎦ (数字拡大)
    # 数字
    Select(0u25a0); Copy() # Black square
    Select(65553);  Paste() # Temporary glyph
    Move(500, 570)
    Select(0u33a3); Copy() # ㎣
    Select(65553);  PasteWithOffset(0, 20) # Temporary glyph
    OverlapIntersect()
    Scale(130)
    # その他
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
    # 合成
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

# 演算子を上下に移動
    math = [0u2243, 0u2248, 0u2252] # ≃≈≒
    j = 0
    while (j < SizeOf(math))
        Select(math[j]);
        Move(0, ${move_y_math} - 17)
        SetWidth(512)
        j += 1
    endloop

    math = [0u226a, 0u226b] # ≪≫
    j = 0
    while (j < SizeOf(math))
        Select(math[j]);
        Move(0, ${move_y_math} - 17)
        SetWidth(1024)
        j += 1
    endloop

# 罫線 (ss用、上下左右を延ばす)
    # 上の細い横線
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(0, 570)
    Select(0u253c); Copy() # ┼
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u2502) # │
    SelectMore(0u2514) # └
    SelectMore(0u2518) # ┘
    SelectMore(0u251c) # ├
    SelectMore(0u251d) # ┝
    SelectMore(0u2524) # ┤
    SelectMore(0u2525) # ┥
    SelectMore(0u2534) # ┴
    SelectMore(0u2537) # ┷
    SelectMore(0u253c) # ┼
    SelectMore(0u253f) # ┿
    PasteWithOffset(0, 230)
    RemoveOverlap()
    Simplify()
    SetWidth(1024)

    # 下の細い横線
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(0, -570)
    Select(0u253c); Copy() # ┼
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u2502) # │
    SelectMore(0u250c) # ┌
    SelectMore(0u2510) # ┐
    SelectMore(0u251c) # ├
    SelectMore(0u251d) # ┝
    SelectMore(0u2524) # ┤
    SelectMore(0u2525) # ┥
    SelectMore(0u252c) # ┬
    SelectMore(0u252f) # ┯
    SelectMore(0u253c) # ┼
    SelectMore(0u253f) # ┿
    PasteWithOffset(0, -230)
    RemoveOverlap()
    Simplify()
    SetWidth(1024)

    # 左の細い横線
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-700, 0)
    Select(0u253c); Copy() # ┼
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u2500) # ─
    SelectMore(0u2510) # ┐
    SelectMore(0u2518) # ┘
    SelectMore(0u2524) # ┤
    SelectMore(0u2528) # ┨
    SelectMore(0u252c) # ┬
    SelectMore(0u2530) # ┰
    SelectMore(0u2534) # ┴
    SelectMore(0u2538) # ┸
    SelectMore(0u253c) # ┼
    SelectMore(0u2542) # ╂
    PasteWithOffset(-100, 0)
    RemoveOverlap()
    Simplify()
    SetWidth(1024)

    # 右の細い横線
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(700, 0)
    Select(0u253c); Copy() # ┼
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u2500) # ─
    SelectMore(0u250c) # ┌
    SelectMore(0u2514) # └
    SelectMore(0u251c) # ├
    SelectMore(0u2520) # ┠
    SelectMore(0u252c) # ┬
    SelectMore(0u2530) # ┰
    SelectMore(0u2534) # ┴
    SelectMore(0u2538) # ┸
    SelectMore(0u253c) # ┼
    SelectMore(0u2542) # ╂
    PasteWithOffset(100, 0)
    RemoveOverlap()
    Simplify()
    SetWidth(1024)

    # 上の太い横線
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(0, 570)
    Select(0u254b); Copy() # ╋
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u2503) # ┃
    SelectMore(0u2517) # ┗
    SelectMore(0u251b) # ┛
    SelectMore(0u2520) # ┠
    SelectMore(0u2523) # ┣
    SelectMore(0u2528) # ┨
    SelectMore(0u252b) # ┫
    SelectMore(0u2538) # ┸
    SelectMore(0u253b) # ┻
    SelectMore(0u2542) # ╂
    SelectMore(0u254b) # ╋
    PasteWithOffset(0, 230)
    RemoveOverlap()
    Simplify()
    SetWidth(1024)

    # 下の太い横線
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(0, -570)
    Select(0u254b); Copy() # ╋
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u2503) # ┃
    SelectMore(0u250f) # ┏
    SelectMore(0u2513) # ┓
    SelectMore(0u2520) # ┠
    SelectMore(0u2523) # ┣
    SelectMore(0u2528) # ┨
    SelectMore(0u252b) # ┫
    SelectMore(0u2530) # ┰
    SelectMore(0u2533) # ┳
    SelectMore(0u2542) # ╂
    SelectMore(0u254b) # ╋
    PasteWithOffset(0, -230)
    RemoveOverlap()
    Simplify()
    SetWidth(1024)

    # 左の太い横線
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-700, 0)
    Select(0u254b); Copy() # ╋
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u2501) # ━
    SelectMore(0u2513) # ┓
    SelectMore(0u251b) # ┛
    SelectMore(0u2525) # ┥
    SelectMore(0u252b) # ┫
    SelectMore(0u252f) # ┯
    SelectMore(0u2533) # ┳
    SelectMore(0u2537) # ┷
    SelectMore(0u253b) # ┻
    SelectMore(0u253f) # ┿
    SelectMore(0u254b) # ╋
    PasteWithOffset(-100, 0)
    RemoveOverlap()
    Simplify()
    SetWidth(1024)

    # 右の太い横線
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(700, 0)
    Select(0u254b); Copy() # ╋
    Select(65552);  PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    Select(0u2501) # ━
    SelectMore(0u250f) # ┏
    SelectMore(0u2517) # ┗
    SelectMore(0u251d) # ┝
    SelectMore(0u2523) # ┣
    SelectMore(0u252f) # ┯
    SelectMore(0u2533) # ┳
    SelectMore(0u2537) # ┷
    SelectMore(0u253b) # ┻
    SelectMore(0u253f) # ┿
    SelectMore(0u254b) # ╋
    PasteWithOffset(100, 0)
    RemoveOverlap()
    Simplify()
    SetWidth(1024)

# 全角罫線を保存 (ss用)
    line = [0u2500, 0u2501, 0u2502, 0u2503, 0u250c, 0u250f,\
            0u2510, 0u2513, 0u2514, 0u2517, 0u2518, 0u251b, 0u251c, 0u251d,\
            0u2520, 0u2523, 0u2524, 0u2525, 0u2528, 0u252b, 0u252c, 0u252f,\
            0u2530, 0u2533, 0u2534, 0u2537, 0u2538, 0u253b, 0u253c, 0u253f,\
            0u2542, 0u254b] # 全角罫線
    j = 0
    while (j < SizeOf(line))
        Select(line[j]); Copy()
        Select(${address_store_line} + j); Paste() # 保管所
        SetWidth(1024)
        j += 1
    endloop

# --------------------------------------------------

# ボールド漢字等のウェイト調整
    if ("${draft_flag}" == "false" && input_list[i] == "${input_kanzi_bold}")
        Print("Edit kanji weight of glyphs (it may take a few minutes)")
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
        SelectMore(${address_store_visi_kanzi}, ${address_store_visi_kanzi} + 11) #保管した漢字
        ChangeWeight(${weight_kanzi_bold}); CorrectDirection()
    endif

# 記号等のウェイト調整
    if ("${draft_flag}" == "false")
        Print("Edit symbol weight of glyphs")
        Select(0u20a0, 0u2120) # 記号類
        SelectMore(0u2122, 0u213a) # 記号類
        SelectMore(0u213c, 0u215f) # 記号類
        SelectMore(0u2189, 0u22ed) # 記号類
        SelectMore(0u22f0, 0u2302) # 記号類
 #        SelectMore(0u2303) # ⌃ グリフ改変時にウェイト調整済
        SelectMore(0u2304, 0u2306) # 記号類
        SelectMore(0u2308, 0u2323) # 記号類
 #        SelectMore(0u2324) # ⌤ グリフ改変時にウェイト調整済
        SelectMore(0u2325, 0u2327) # 記号類
 #        SelectMore(0u2328) # ⌨ グリフ改変時にウェイト調整済 # 記号類
        SelectMore(0u2329, 0u2334) # 記号類
 #        SelectMore(0u2335) # ⌵ グリフ改変時にウェイト調整済
        SelectMore(0u23a7, 0u23cc) # ⎧ -
        SelectMore(0u2640, 0u2642) # ♀♂
        SelectMore(0u2934, 0u2935) # ⤴⤵
        SelectMore(0u29fa, 0u29fb) # ⧺⧻
        if (input_list[i] == "${input_kanzi_regular}")
            ChangeWeight(${weight_kanzi_symbols_regular}); CorrectDirection()
        else
            ChangeWeight(${weight_kanzi_symbols_bold}); CorrectDirection()
        endif
        Select(0u2602, 0u2603) # ☂☃
        SelectMore(0u261c, 0u261f) # ☜-☟
        if (input_list[i] == "${input_kanzi_regular}")
            ChangeWeight(${weight_kanzi_regular}); CorrectDirection()
        else
            ChangeWeight(${weight_kanzi_bold}); CorrectDirection()
        endif
 #        Select(0u2160, 0u2188) # ローマ数字
        Select(0u216c, 0u216f) # Ⅼ-Ⅿ
        SelectMore(0u217c, 0u2184) # ⅼ-ↄ
        if (input_list[i] == "${input_kanzi_regular}")
            ChangeWeight(${weight_kanzi_roman_regular}); CorrectDirection()
        else
            ChangeWeight(${weight_kanzi_roman_bold}); CorrectDirection()
        endif
    endif

# --------------------------------------------------

# 全角文字を移動
    if ("${draft_flag}" == "false")
        Print("Move zenkaku glyphs (it may take a few minutes)")
        SelectWorthOutputting()
        foreach
            if (800 <= GlyphInfo("Width"))
                Move(${move_x_zenkaku_kanzi}, 0)
                SetWidth(-${move_x_zenkaku_kanzi}, 1)
            endif
        endloop
    endif

# --------------------------------------------------

# calt 対応 (スロットの確保、後でグリフ上書き)
    j = 0
    k = ${address_calt_start3_kanzi} # 完成時の最後の異体字のアドレスより大きなアドレスを再利用しないとエラーが出る
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

    k = ${address_calt_start2_kanzi}
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

    k = ${address_calt_start_kanzi}
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
        Select(0u0063); Copy() # Ș-ț のダミー
        Select(k); Paste()
        k += 1
        j += 1
    endloop

    Select(0u0063); Copy() # ẞ のダミー
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

    symb = [0u007c, 0u007e,\
            0u003a, 0u002a, 0u002b, 0u002d,\
            0u003d, 0u007c, 0u003a] # |~ :*+- =|:
    j = 0
    while (j < SizeOf(symb))
        Select(symb[j]); Copy()
        Select(k); Paste()
        j += 1
        k += 1
    endloop

    symb = [0u002a, 0u002b, 0u002d, 0u003d, 0u005f,\
            0u002f, 0u005c, 0u003c, 0u003e,\
            0u0028, 0u0029, 0u005b, 0u005d,\
            0u007b, 0u007d,\
            0u0021, 0u0022, 0u0027, 0u002c,\
            0u002e, 0u003a, 0u003b, 0u003f,\
            0u0060, 0u007c, 0u007c, 0u003a,\
            0u007e, 0u007c, 0u003a] # *+-=_ SolidusReversesolidus<> ()[] {} !QuoteApostrophe, .:;? grave|移動した|: ~|:
    k = ${address_calt_start4_kanzi}
    j = 0
    while (j < SizeOf(symb) * 2)
        Select(symb[j % SizeOf(symb)]); Copy()
        Select(k); Paste()
        j += 1
        k += 1
    endloop

    symb = [0u005c, 0u005c, 0u005c] # Reversesolidus 3個
    j = 0
    while (j < SizeOf(symb))
        Select(symb[j]); Copy()
        Select(k); Paste()
        j += 1
        k += 1
    endloop

# ss 対応 (スロットの確保、後でグリフ上書き)
    k = ${address_ss_start_kanzi}
    j = 0
    while (j < ${num_ss_glyphs_former})
        Select(0u0073); Copy() # 保管したグリフのダミー
        Select(k); Paste()
        k += 1
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
# Generate script for dummy fonts
################################################################################
# ss 用のエンコーディングスロットが足りなくなり、追加しようとしてもエラーになるため
# 苦肉の策として空のグリフのみのフォントを作成して後でマージする

cat > ${tmpdir}/${modified_dummy_generator} << _EOT_
#!$fontforge_command -script

Print("- Generate dummy fonts -")

# Set parameters
input_list  = ["${input_kanzi_regular}"]
output_list = ["${modified_dummy}"]

# Begin loop of regular and bold
i = 0
while (i < SizeOf(input_list))
# Open kanzi font
    Print("Open " + input_list[i])
    Open(input_list[i])
    SelectWorthOutputting()
    UnlinkReference()
    ScaleToEm(${em_ascent1024}, ${em_descent1024})
    SetOS2Value("WinAscent",             ${win_ascent1024})
    SetOS2Value("WinDescent",            ${win_descent1024})
    SetOS2Value("TypoAscent",            ${typo_ascent1024})
    SetOS2Value("TypoDescent",          -${typo_descent1024})
    SetOS2Value("TypoLineGap",           ${typo_linegap1024})
    SetOS2Value("HHeadAscent",           ${hhea_ascent1024})
    SetOS2Value("HHeadDescent",         -${hhea_descent1024})
    SetOS2Value("HHeadLineGap",          ${hhea_linegap1024})

# --------------------------------------------------

# 全てのグリフクリア
    Print("Remove all glyphs")
    SelectWorthOutputting(); Clear(); DetachAndRemoveGlyphs()

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

# --------------------------------------------------

    Print("Add encoding slots")
# ss 対応 (スロットの確保、後でグリフ上書き)
    k = 0

    j = 0
    while (j < ${num_ss_glyphs_latter} - 2) # 計算が合っているはずなのに余りが出るので-2
        Select(${address_ss_start_dummy} + k); SetWidth(512) # 保管したグリフのダミー
        j += 1
        k += 1
    endloop

# --------------------------------------------------

# Proccess before saving
 #    Print("Process before saving")
 #    if (0 < SelectIf(".notdef"))
 #        Clear(); DetachAndRemoveGlyphs()
 #    endif
 #    RemoveDetachedGlyphs()
 #    SelectWorthOutputting()
 #    RoundToInt()

# --------------------------------------------------

# Save modified dummy fonts
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
# Generate script for hentai kana fonts
################################################################################

cat > ${tmpdir}/${modified_hentai_kana_generator} << _EOT_
#!$fontforge_command -script

Print("- Generate modified hentai kana fonts -")

# Set parameters
input_list  = ["${input_hentai_kana}"]
output_list = ["${modified_hentai_kana}"]

# Begin loop of regular and bold
i = 0
while (i < SizeOf(input_list))
# Open hentai kana font
    Print("Open " + input_list[i])
    Open(input_list[i])
    SelectWorthOutputting()
    UnlinkReference()
    ScaleToEm(${em_ascent1024}, ${em_descent1024})
    SetOS2Value("WinAscent",             ${win_ascent1024})
    SetOS2Value("WinDescent",            ${win_descent1024})
    SetOS2Value("TypoAscent",            ${typo_ascent1024})
    SetOS2Value("TypoDescent",          -${typo_descent1024})
    SetOS2Value("TypoLineGap",           ${typo_linegap1024})
    SetOS2Value("HHeadAscent",           ${hhea_ascent1024})
    SetOS2Value("HHeadDescent",         -${hhea_descent1024})
    SetOS2Value("HHeadLineGap",          ${hhea_linegap1024})

# --------------------------------------------------

# 使用しないグリフクリア
    Print("Remove not used glyphs")
    Select(0, 31); Clear(); DetachAndRemoveGlyphs()

    Select(1114112, 1114114)
    Clear(); DetachAndRemoveGlyphs()

# Clear kerns, position, substitutions
    Print("Clear kerns, position, substitutions")
    RemoveAllKerns()

 #    lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups); j = 0
 #    while (j < numlookups)
 #        Print("Remove GSUB_" + lookups[j])
 #        RemoveLookup(lookups[j]); j++
 #    endloop

 #    lookups = GetLookups("GPOS"); numlookups = SizeOf(lookups); j = 0
 #    while (j < numlookups)
 #        Print("Remove GPOS_" + lookups[j])
 #        RemoveLookup(lookups[j]); j++
 #    endloop

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

# Edit hentai kana
    Print("Edit hentaigana")
    SelectWorthOutputting()
    Move(0, -40)
    SetWidth(1024)

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

# Save modified hentai kana fonts (sfdで保存するとmergeしたときにccmpが消える)
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

# ~ (少し上へ移動、M+ のグリフに置き換え)
    Print("Edit ~")
    Select(0uff5e); Copy() # Fullwidth tilde
    Select(0u007e); Paste()
    if ("${draft_flag}" == "false"); Move(-${move_x_zenkaku_kana}, 0); endif
    Scale(50)
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
    if ("${draft_flag}" == "false"); Move(-${move_x_zenkaku_kana}, 0); endif
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
    if ("${draft_flag}" == "false"); Move(-${move_x_zenkaku_kana}, 0); endif
    Select(${address_store_g}); Copy() # 保管したg
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
    if ("${draft_flag}" == "false"); Move(-${move_x_zenkaku_kana}, 0); endif
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

    # 上付き文字を置き換え
    Select(0u0067); Copy() # g
    Select(0u1d4d); Paste() # ᵍ
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_super})
    SetWidth(500)

# ₿ (追加)
    Print("Edit bitcoin sign")
    # 小さくした B
    Select(0u0042); Copy() # B
    Select(0u20bf); Paste() # ₿
    Scale(95)
    # 縦棒
    Select(0u25a0); Copy() # Black square
    Select(65552);  Paste() # Temporary glyph
    Move(-200, 560)
    PasteWithOffset(-200, -600)
    Select(0u01c1); Copy() # ǁ
    Select(65553);  Paste() # Temporary glyph
    Scale(90, 82)
    if (latin_sfd_list[i] == "${tmpdir}/${modified_latin_regular}")
        Move(-15, 43)
    else
        Move(-9, 43)
    endif
    Copy()
    Select(65552); PasteInto() # Temporary glyph
    OverlapIntersect()
    Copy()
    # 合成
    Select(0u20bf); PasteInto() # ₿
    RemoveOverlap()
    SetWidth(500)
    Select(65552); Clear() # Temporary glyph
    Select(65553); Clear() # Temporary glyph

# latin フォントの縦横比調整 (kana フォントの欧文グリフは調整しない)
    if ("${draft_flag}" == "false")
        if (${scale_width_latin} != 100 || ${scale_height_latin} != 100)
            Print("Edit latin aspect ratio")
 #            Select(0u0024) # $ 通貨記号
            Select(0u0030, 0u0039) # 0 - 9
            SelectMore(0u0041, 0u005a) # A - Z
            SelectMore(0u0061, 0u007a) # a - z
 #            SelectMore(0u00a2, 0u00a3) # ¢£ 通貨記号
 #            SelectMore(0u00a5) # ¥ 通貨記号
            SelectMore(0u00c0, 0u00d6) # À - Ö
            SelectMore(0u00d8, 0u00f6) # Ø - ö
            SelectMore(0u00f8, 0u0131) # ø - ı
            SelectMore(0u0134, 0u0148) # Ĵ - ň
            SelectMore(0u014a, 0u017e) # Ŋ - ž
            SelectMore(0u018e) # Ǝ
 #            SelectMore(0u018f) # Ə (グリフが間違っている)
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
            SelectMore(0u02b9, 0u02bc) # ʹ - ʼ
            SelectMore(0u02be, 0u02bf) # ʾ - ʿ
            SelectMore(0u02c6, 0u02cc) # ˆ - ˌ
            SelectMore(0u02d8, 0u02dd) # ˘ - ˝
            SelectMore(0u0300, 0u0304) #  ̀ -  ̄
            SelectMore(0u0306, 0u030c) #  ̆ -  ̌
            SelectMore(0u030f) #  ̏
            SelectMore(0u0311, 0u0312) #  ̑ -  ̒
            SelectMore(0u031b) #  ̛
            SelectMore(0u0323, 0u0324) #  ̣ -  ̤
            SelectMore(0u0326, 0u0328) #  ̦ -  ̨
            SelectMore(0u032e) #  ̮
            SelectMore(0u0331) #  ̱
            SelectMore(0u0335, 0u0336) #  ̵ -  ̶
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
            SelectMore(0u1e94, 0u1e95) # Ẕ - ẕ kana フォントを使用するとウェイト調整時に形が崩れるため latin フォントに追加したグリフ
            SelectMore(0u1e97) # ẗ
            SelectMore(0u1e9e) # ẞ
            SelectMore(0u1ea0, 0u1ef9) # Ạ - ỹ
 #            SelectMore(0u20a1) # ₡ 通貨記号
 #            SelectMore(0u20a3, 0u20a4) # ₣₤ 通貨記号
 #            SelectMore(0u20a6, 0u20a7) # ₦₧ 通貨記号
 #            SelectMore(0u20a9) # ₩ 通貨記号
 #            SelectMore(0u20ab, 0u20ad) # ₫€₭ 通貨記号
 #            SelectMore(0u20b1, 0u20b2) # ₱₲ 通貨記号
 #            SelectMore(0u20b5) # ₵ 通貨記号
 #            SelectMore(0u20b9, 0u20ba) # ₹₺ 通貨記号
 #            SelectMore(0u20bc, 0u20bd) # ₼₽ 通貨記号
            SelectMore(0u210a) # ℊ
            SelectMore(0u2124) # ℤ
            SelectMore(${address_store_mod}, ${address_store_mod} + ${num_mod_glyphs} * 6 - 1) # 保管したDQVZ
            SelectMore(${address_store_zero}) # 保管したスラッシュ無し0
            SelectMore(${address_store_zero} + 3, ${address_store_zero} + 5) # 保管したスラッシュ無し全角0
            SelectMore(${address_store_zero} + 6) # 保管したドット0
            SelectMore(${address_store_zero} + 3 + 6, ${address_store_zero} + 5 + 6) # 保管したドット全角0
            Scale(${scale_width_latin}, ${scale_height_latin}, 250, 0); SetWidth(500)
        endif
    endif

# 記号のグリフを加工
    Print("Copy and edit symbols")

# ° (移動)
    Select(0u00b0) # °
    Move(-10, 80)
    SetWidth(500)

# Ɔ (C をコピーして裏返す)
    Select(0u0043); Copy() # C
    Select(0u0186); Paste() # Ɔ
    HFlip()
    CorrectDirection()
    Move(-35, 0)
    SetWidth(500)

# ɔ (c をコピーして裏返す)
    Select(0u0063); Copy() # c
    Select(0u0254); Paste() # ɔ
    HFlip()
    CorrectDirection()
    Move(-11, 0)
    SetWidth(500)

# ℄ (追加)
    Select(0u004c); Copy() # L
    Select(0u2104); Paste() # ℄
    Select(0u0063); Copy() # c
    Select(0u2104); PasteWithOffset(-160, 120) # ℄
    Move(90, 0)
    RemoveOverlap()
    Scale(98, 100, 250, 0)
    SetWidth(500)

# K (追加)
    Select(0u004b); Copy() # K
    Select(0u212a); Paste() # K
    SetWidth(500)

# Å (漢字フォントを置換)
    Select(0u00c5); Copy() # Å
    Select(0u212b); Paste() # Å
    SetWidth(500)

# ℃ (漢字フォントを置換) ※ ° より後に加工すること
    Select(0u00b0); Copy() # °
    Select(0u2103); Paste() # ℃
    Select(0u0043); Copy() # C
    Select(0u2103) # ℃
    PasteWithOffset(330, 0)
    if ("${draft_flag}" == "false"); Move(${move_x_zenkaku_kana}, 0); endif
    SetWidth(1000)

# ℉ (追加) ※ ° より後に加工すること
    Select(0u00b0); Copy() # °
    Select(0u2109); Paste() # ℉
    Move(-10, 0)
    Select(0u0046); Copy() # F
    Select(0u2109) # ℉
    PasteWithOffset(340, 0)
    if ("${draft_flag}" == "false"); Move(${move_x_zenkaku_kana}, 0); endif
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

# 上付き、下付き文字を置き換え
    Print("Edit superscrips and subscripts")
    Select(0u0031) # 1
    lookups = GetPosSub("*") # フィーチャを取り出す

    # ʱ-ʁ
    orig = [0u0266, 0u0000, 0u0000, 0u0279,\
            0u0000, 0u0281] # 0u0000はダミー
    j = 0
    while (j < SizeOf(orig))
        if (orig[j] != 0u0000)
            Select(orig[j]); Copy()
            Select(0u02b1 + j); Paste()
            Scale(${scale_super_sub}, 250, 0)
            ChangeWeight(${weight_super_sub})
            CorrectDirection()
            Move(0, ${move_y_super})
            SetWidth(500)
            glyphName = GlyphInfo("Name") # sups フィーチャ追加
            Select(orig[j])
            AddPosSub(lookups[0][0],glyphName)
        endif
        j += 1
    endloop

    # ˁˤ
    Select(0u0295); Copy() # ʕ
    Select(0u02c1) # ˁ
    SelectMore(0u02e4); Paste() # ˤ
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_super})
    SetWidth(500)
    Select(0u02c1) # ˁ
    glyphName = GlyphInfo("Name") # sups フィーチャ追加
    Select(0u0295) # ʕ
    AddPosSub(lookups[0][0],glyphName)

    # ˀ
    Select(0u0294); Copy() # ʔ
    Select(0u02c0); Paste() # ˀ
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_super})
    SetWidth(500)
    glyphName = GlyphInfo("Name") # sups フィーチャ追加
    Select(0u0294) # ʔ
    AddPosSub(lookups[0][0],glyphName)

    # ˠ
    Select(0u0263); Copy() # ɣ
    Select(0u02e0); Paste() # ˠ
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_super})
    SetWidth(500)
    glyphName = GlyphInfo("Name") # sups フィーチャ追加
    Select(0u0263) # ɣ
    AddPosSub(lookups[0][0],glyphName)

    # ᵄ-ᵅ
    orig = [0u0250, 0u0251]
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(0u1d44 + j); Paste()
        Scale(${scale_super_sub}, 250, 0)
        ChangeWeight(${weight_super_sub})
        CorrectDirection()
        Move(0, ${move_y_super})
        SetWidth(500)
        glyphName = GlyphInfo("Name") # sups フィーチャ追加
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        j += 1
    endloop

    # ᵋ
    Select(0u025b); Copy() # ɛ
    Select(0u1d4b); Paste() # ᵋ
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_super})
    SetWidth(500)
    glyphName = GlyphInfo("Name") # sups フィーチャ追加
    Select(0u025b) # ɛ
    AddPosSub(lookups[0][0],glyphName)

    # ᵌ
    Select(0u025b); Copy() # ɛ
    Select(0u1d4c); Paste() # ᵌ
    Rotate(180)
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_super})
    SetWidth(500)

    # ᵓ
    Select(0u0254); Copy() # ɔ
    Select(0u1d53); Paste() # ᵓ
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_super})
    SetWidth(500)
    glyphName = GlyphInfo("Name") # sups フィーチャ追加
    Select(0u0254) # ɔ
    AddPosSub(lookups[0][0],glyphName)

    # ᵚ
    Select(0u026f); Copy() # ɯ
    Select(0u1d5a); Paste() # ᵚ
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_super})
    SetWidth(500)
    glyphName = GlyphInfo("Name") # sups フィーチャ追加
    Select(0u026f) # ɯ
    AddPosSub(lookups[0][0],glyphName)

    # ᵝ-ᵡ
    orig = [0u03b2, 0u03b3, 0u03b4, 0u03c6,\
            0u03c7]
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(0u1d5d + j); Paste()
        Scale(${scale_super_sub}, 250, 0)
        ChangeWeight(${weight_super_sub})
        CorrectDirection()
        Move(0, ${move_y_super})
        SetWidth(500)
        glyphName = GlyphInfo("Name") # sups フィーチャ追加
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        j += 1
    endloop

    # н
    Select(0u043d); Copy() # н
    Select(0u1d78); Paste() # ᵸ
    Scale(${scale_super_sub}, 250, 0)
    ChangeWeight(${weight_super_sub})
    CorrectDirection()
    Move(0, ${move_y_super})
    SetWidth(500)
    glyphName = GlyphInfo("Name") # sups フィーチャ追加
    Select(0u043d) # н
    AddPosSub(lookups[0][0],glyphName)

    # ᶛ-ᶝ
    orig = [0u0252, 0u0000, 0u0255,\
            0u0000, 0u025c] # 0u0000はダミー
    j = 0
    while (j < SizeOf(orig))
        if (orig[j] != 0u0000)
            Select(orig[j]); Copy()
            Select(0u1d9b + j); Paste()
            Scale(${scale_super_sub}, 250, 0)
            ChangeWeight(${weight_super_sub})
            CorrectDirection()
            Move(0, ${move_y_super})
            SetWidth(500)
            glyphName = GlyphInfo("Name") # sups フィーチャ追加
            Select(orig[j])
            AddPosSub(lookups[0][0],glyphName)
        endif
        j += 1
    endloop

    # ᶡ-ᶿ
    orig = [0u025f, 0u0261, 0u0265, 0u0268,\
            0u0269, 0u026a, 0u0000, 0u029d,\
            0u026d, 0u0000, 0u029f, 0u0271,\
            0u0270, 0u0272, 0u0273, 0u0274,\
            0u0275, 0u0278, 0u0282, 0u0283,\
            0u0000, 0u0289, 0u028a, 0u0000,\
            0u028b, 0u028c, 0u0000, 0u0290,\
            0u0291, 0u0292, 0u03b8] # 0u0000はダミー
    j = 0
    while (j < SizeOf(orig))
        if (orig[j] != 0u0000)
            Select(orig[j]); Copy()
            Select(0u1da1 + j); Paste()
            Scale(${scale_super_sub}, 250, 0)
            ChangeWeight(${weight_super_sub})
            CorrectDirection()
            Move(0, ${move_y_super})
            SetWidth(500)
            glyphName = GlyphInfo("Name") # sups フィーチャ追加
            Select(orig[j])
            AddPosSub(lookups[0][0],glyphName)
        endif
        j += 1
    endloop

    # ᵦ-ᵧ
    orig = [0u03b2, 0u03b3, 0u03c1, 0u03c6, 0u03c7]
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(0u1d66 + j); Paste()
        Scale(${scale_super_sub}, 250, 0)
        ChangeWeight(${weight_super_sub})
        CorrectDirection()
        Move(0, ${move_y_sub})
        SetWidth(500)
        glyphName = GlyphInfo("Name") # subs フィーチャ追加
        Select(orig[j])
        AddPosSub(lookups[1][0],glyphName)
        j += 1
    endloop

# --------------------------------------------------

# 漢字用フォントで上書きするグリフをクリア
    Print("Remove some glyphs")
 #    Select(0u00bc, 0u00be); Clear() # ¼½¾
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
    ScaleToEm(${em_ascent1024}, ${em_descent1024})
    SetOS2Value("WinAscent",             ${win_ascent1024})
    SetOS2Value("WinDescent",            ${win_descent1024})
    SetOS2Value("TypoAscent",            ${typo_ascent1024})
    SetOS2Value("TypoDescent",          -${typo_descent1024})
    SetOS2Value("TypoLineGap",           ${typo_linegap1024})
    SetOS2Value("HHeadAscent",           ${hhea_ascent1024})
    SetOS2Value("HHeadDescent",         -${hhea_descent1024})
    SetOS2Value("HHeadLineGap",          ${hhea_linegap1024})

# 罫線、ブロックを少し移動 (em値変更でのズレ修正)
    Print("Move box drawing and block")
    Select(0u2500, 0u259f)
    Move(0, ${move_y_em_revise})
    Scale(102, 100, 256, 0) # 横幅を少し拡大
    if ("${loose_flag}" == "true") # Loose 版対応 (とりあえず拡大させておく)
        Scale(113, 100, 256, ${center_height_hankaku})
    endif
    SetWidth(512)

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
dummy_ttf_list      = ["${tmpdir}/${modified_dummy}", \\
                       "${tmpdir}/${modified_dummy}"] # ボールドが無いため
hentai_kana_ttf_list = ["${tmpdir}/${modified_hentai_kana}", \\
                       "${tmpdir}/${modified_hentai_kana}"] # ボールドが無いため
kanzi_sfd_list      = ["${tmpdir}/${modified_kanzi_regular}", \\
                       "${tmpdir}/${modified_kanzi_bold}"]
fontfamily        = "${font_familyname}"
fontfamilysuffix  = "${font_familyname_suffix}"
fontstyle_list    = ["Regular", "Bold"]
fontweight_list   = [400,       700]
panoseweight_list = [5,         8]
if ("${nerd_flag}" == "true") # なぜか後で上書きすると失敗することがあったためここで設定
    copyright     = "${copyright}" \\
                  + "${copyright_nerd_fonts}" \\
                  + "${copyright_license}"
else
    copyright     = "${copyright}" \\
                  + "${copyright_license}"
endif
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
 #    if (fontfamilysuffix != "") # パッチを当てる時にSuffixを追加するので無効化
 #        SetFontNames(fontfamily + fontfamilysuffix + "-" + fontstyle_list[i], \\
 #                     fontfamily + " " + fontfamilysuffix, \\
 #                     fontfamily + " " + fontfamilysuffix + " " + fontstyle_list[i], \\
 #                     fontstyle_list[i], \\
 #                     copyright, version)
 #    else
        SetFontNames(fontfamily + "-" + fontstyle_list[i], \\
                     fontfamily, \\
                     fontfamily + " " + fontstyle_list[i], \\
                     fontstyle_list[i], \\
                     copyright, version)
 #    endif
    SetTTFName(0x409, 2, fontstyle_list[i])
    SetTTFName(0x409, 3, "FontForge ${fontforge_version} : " + "FontTools ${ttx_version} : " + \$fullname + " : " + Strftime("%d-%m-%Y", 0))
    ScaleToEm(${em_ascent1024}, ${em_descent1024})
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
    SetOS2Value("WinAscent",             ${win_ascent1024})
    SetOS2Value("WinDescent",            ${win_descent1024})
    SetOS2Value("TypoAscent",            ${typo_ascent1024})
    SetOS2Value("TypoDescent",          -${typo_descent1024})
    SetOS2Value("TypoLineGap",           ${typo_linegap1024})
    SetOS2Value("HHeadAscent",           ${hhea_ascent1024})
    SetOS2Value("HHeadDescent",         -${hhea_descent1024})
    SetOS2Value("HHeadLineGap",          ${hhea_linegap1024})
    SetPanose([2, 11, panoseweight_list[i], 9, 2, 2, 3, 2, 2, 7])

# Merge fonts
    Print("Merge " + latin_kana_sfd_list[i]:t \\
          + " with " + kanzi_sfd_list[i]:t \\
          + " with " + hentai_kana_ttf_list[i]:t)
    MergeFonts(latin_kana_sfd_list[i])
    MergeFonts(kanzi_sfd_list[i])
    MergeFonts(dummy_ttf_list[i])
    MergeFonts(hentai_kana_ttf_list[i])

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

# 一部を除いた半角文字を拡大 (主に Loose 版対応)
    if (${scale_width_hankaku} != 100 || ${scale_height_hankaku} != 100)
        Print("Edit hankaku aspect ratio")

        Select(0u0021, 0u1fff) # 基本ラテン - ギリシャ文字拡張
        SelectFewer(0u00a0) # ノーブレークスペースを除外
        SelectMore(0u2010, 0u218f) # 一般句読点 - 数字の形
        SelectMore(0u2200, 0u22ff) # 数学記号
        SelectMore(0u27c0, 0u27ef) # その他の数学記号 A
        SelectMore(0u2980, 0u2aff) # その他の数学記号 B - 補助数学記号
        SelectMore(0u2c60, 0u2c7f) # ラテン文字拡張 C
        SelectMore(0u2e00, 0u2e7f) # 補助句読点
        SelectMore(0ua700, 0ua7ff) # 声調装飾文字 - ラテン文字拡張 D
        SelectMore(0ufb00, 0ufb4f) # アルファベット表示形
        foreach
            if (WorthOutputting())
                if (GlyphInfo("Width") <= 700)
                    Scale(${scale_width_hankaku}, ${scale_height_hankaku}, 256, 0)
                    SetWidth(512)
                endif
            endif
        endloop

        Select(0u2190, 0u21ff) # 矢印
        SelectMore(0u2300, 0u231f) # その他の技術用記号 1
        SelectMore(0u2322, 0u239a) # その他の技術用記号 2
        SelectMore(0u23af) # その他の技術用記号 3
        SelectMore(0u23b4, 0u23bd) # その他の技術用記号 4
        SelectMore(0u23cd, 0u23ff) # その他の技術用記号 5
        SelectMore(0u2400, 0u24ff) # 制御機能用記号 - 囲み英数字
        SelectMore(0u25a0, 0u25ff) # 幾何学模様
        SelectMore(0u2600, 0u27bf) # その他の記号 - 装飾記号
        SelectMore(0u27f0, 0u27ff) # 補助矢印 A
        SelectMore(0u2900, 0u297f) # 補助矢印 B
        SelectMore(0u2b00, 0u2bff) # その他の記号および矢印
        SelectMore(0ufffd) # 特殊用途文字
        foreach
            if (WorthOutputting())
                if (GlyphInfo("Width") <= 700)
                    Scale(${scale_width_hankaku}, ${scale_height_hankaku}, 256, 338)
                    SetWidth(512)
                endif
            endif
        endloop

        Select(0u2320, 0u2321) # インテグラル
        SelectMore(0u239b, 0u23ae) # 括弧・インテグラル
        SelectMore(0u23b0, 0u23b3) # 括弧括弧素片・総和記号部分
        SelectMore(0u23be, 0u23cc) # 歯科表記記号
        foreach
            if (WorthOutputting())
                if (GlyphInfo("Width") <= 700)
                    Scale(${scale_width_hankaku}, 100, 256, 338)
                    SetWidth(512)
                endif
            endif
        endloop

        Select(${address_store_mod}, ${address_store_mod} + ${num_mod_glyphs} * 6 - 1) # 保管したDQVZ
        SelectMore(${address_store_zero}, ${address_store_zero} + 5) # 保管したスラッシュ無し0
        SelectMore(${address_store_zero} + 6, ${address_store_zero} + 5 + 6) # 保管したドット0
        SelectMore(${address_store_visi_latin}, ${address_store_visi_latin} + 1) # 保管した ⁄|
        SelectMore(${address_store_visi_kana} + 1) # 保管した –
        Scale(${scale_width_hankaku}, ${scale_height_hankaku}, 256, 0)
        SetWidth(512)
    endif

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
# Open nerd fonts
    Print("Open " + input_list[i])
    Open(input_list[i])
    SelectWorthOutputting()
    UnlinkReference()
    ScaleToEm(${em_ascent1024}, ${em_descent1024})
    SetOS2Value("WinAscent",             ${win_ascent1024})
    SetOS2Value("WinDescent",            ${win_descent1024})
    SetOS2Value("TypoAscent",            ${typo_ascent1024})
    SetOS2Value("TypoDescent",          -${typo_descent1024})
    SetOS2Value("TypoLineGap",           ${typo_linegap1024})
    SetOS2Value("HHeadAscent",           ${hhea_ascent1024})
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

 #    lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups); j = 0
 #    while (j < numlookups)
 #        Print("Remove GSUB_" + lookups[j])
 #        RemoveLookup(lookups[j]); j++
 #    endloop

 #    lookups = GetLookups("GPOS"); numlookups = SizeOf(lookups); j = 0
 #    while (j < numlookups)
 #        Print("Remove GPOS_" + lookups[j])
 #        RemoveLookup(lookups[j]); j++
 #    endloop

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
    SelectWorthOutputting(); Move(0, ${move_y_nerd})

# IEC Power Symbols
    Print("Edit IEC Power Symbols")
    Select(0u23fb, 0u23fe)
    SelectMore(0u2b58)
    Scale(${scale_nerd})
    SetWidth(1024)

# Pomicons
    Print("Edit Pomicons")
    Select(0ue000, 0ue00a)
    Scale(${scale_pomicons})
    SetWidth(1024)

# Powerline Glyphs (Win(HHead)Ascent から Win(HHead)Descent までの長さを基準として大きさと位置を合わせる)
    Print("Edit Powerline Extra Symbols")
    Select(0ue0a0, 0ue0a3)
    SelectMore(0ue0b0, 0ue0c8)
    SelectMore(0ue0ca)
    SelectMore(0ue0cc, 0ue0d2)
    SelectMore(0ue0d4)
    SelectMore(0ue0d6, 0ue0d7)
    Move(0, -${move_y_nerd}) # 元の位置に戻す
    Move(0, ${move_y_em_revise}) # em値変更でのズレ修正
    Select(0ue0a0);         Move(-226, ${move_y_pl}); SetWidth(512)
    Select(0ue0a1, 0ue0a3); Move(-256, ${move_y_pl}); SetWidth(512)
    Select(0ue0b0);         Scale(70,  ${scale_height_pl}, 0,    ${center_height_pl}); Move(9,  ${move_y_pl}); SetWidth(512)
    Select(0ue0b1);         Scale(70,  ${scale_height_pl}, 0,    ${center_height_pl}); Move(0,  ${move_y_pl}); SetWidth(512)
    Select(0ue0b2);         Scale(70,  ${scale_height_pl}, 1024, ${center_height_pl}); Move(-512 - 9,  ${move_y_pl}); SetWidth(512)
    Select(0ue0b3);         Scale(70,  ${scale_height_pl}, 1024, ${center_height_pl}); Move(-512,      ${move_y_pl}); SetWidth(512)
    Select(0ue0b4);         Scale(80,  ${scale_height_pl}, 0,    ${center_height_pl}); Move(18, ${move_y_pl}); SetWidth(512)
    Select(0ue0b5);         Scale(95,  ${scale_height_pl}, 0,    ${center_height_pl}); Move(0,  ${move_y_pl}); SetWidth(512)
    Select(0ue0b6);         Scale(80,  ${scale_height_pl}, 1024, ${center_height_pl}); Move(-512 - 18, ${move_y_pl}); SetWidth(512)
    Select(0ue0b7);         Scale(95,  ${scale_height_pl}, 1024, ${center_height_pl}); Move(-512,      ${move_y_pl}); SetWidth(512)
    Select(0ue0b8);         Scale(50,  ${scale_height_pl}, 0,    ${center_height_pl}); Move(-8,  ${move_y_pl}); SetWidth(512)
    Select(0ue0b9);         Scale(50,  ${scale_height_pl}, 0,    ${center_height_pl}); Move(0,  ${move_y_pl}); SetWidth(512)
    Select(0ue0ba);         Scale(50,  ${scale_height_pl}, 1024, ${center_height_pl}); Move(-512 + 8,  ${move_y_pl}); SetWidth(512)
    Select(0ue0bb);         Scale(50,  ${scale_height_pl}, 1024, ${center_height_pl}); Move(-512,      ${move_y_pl}); SetWidth(512)
    Select(0ue0bc);         Scale(50,  ${scale_height_pl}, 0,    ${center_height_pl}); Move(-8,  ${move_y_pl}); SetWidth(512)
    Select(0ue0bd);         Scale(50,  ${scale_height_pl}, 0,    ${center_height_pl}); Move(0,  ${move_y_pl}); SetWidth(512)
    Select(0ue0be);         Scale(50,  ${scale_height_pl}, 1024, ${center_height_pl}); Move(-512 + 8,  ${move_y_pl}); SetWidth(512)
    Select(0ue0bf);         Scale(50,  ${scale_height_pl}, 1024, ${center_height_pl}); Move(-512,      ${move_y_pl}); SetWidth(512)
    Select(0ue0c0, 0ue0c1); Scale(95,  ${scale_height_pl}, 0,    ${center_height_pl}); Move(0, ${move_y_pl2}); SetWidth(1024)
    Select(0ue0c2, 0ue0c3); Scale(95,  ${scale_height_pl}, 1024, ${center_height_pl}); Move(0, ${move_y_pl2}); SetWidth(1024)
    Select(0ue0c4);         Scale(105, ${scale_height_pl}, 0,    ${center_height_pl}); Move(0, ${move_y_pl}); SetWidth(1024)
    Select(0ue0c5);         Scale(105, ${scale_height_pl}, 1024, ${center_height_pl}); Move(0, ${move_y_pl}); SetWidth(1024)
    Select(0ue0c6);         Scale(105, ${scale_height_pl}, 0,    ${center_height_pl}); Move(0, ${move_y_pl}); SetWidth(1024)
    Select(0ue0c7);         Scale(105, ${scale_height_pl}, 1024, ${center_height_pl}); Move(0, ${move_y_pl}); SetWidth(1024)
    Select(0ue0c8);         Scale(95,  ${scale_height_pl}, 0,    ${center_height_pl}); Move(0, ${move_y_pl}); SetWidth(1024)
    Select(0ue0ca);         Scale(95,  ${scale_height_pl}, 1024, ${center_height_pl}); Move(0, ${move_y_pl}); SetWidth(1024)
    Select(0ue0cc);         Scale(105, ${scale_height_pl}, 0,    ${center_height_pl}); Move(0, ${move_y_pl}); SetWidth(1024)
    Select(0ue0cd);         Scale(105, ${scale_height_pl2}, 0,   ${center_height_pl}); Move(-21, ${move_y_pl}); SetWidth(1024)
    Select(0ue0ce, 0ue0d0); Move(0, ${move_y_pl}); SetWidth(1024)
    Select(0ue0d1);         Scale(105, ${scale_height_pl2}, 0,   ${center_height_pl}); Move(-21, ${move_y_pl}); SetWidth(1024)
    Select(0ue0d2);         Scale(105, ${scale_height_pl}, 0,    ${center_height_pl}); Move(0, ${move_y_pl}); SetWidth(1024)
    Select(0ue0d4);         Scale(105, ${scale_height_pl}, 1024, ${center_height_pl}); Move(0, ${move_y_pl});SetWidth(1024)
    Select(0ue0d6);         Scale(105, ${scale_height_pl}, 0,    ${center_height_pl}); Move( 33, ${move_y_pl}); SetWidth(1024)
    Select(0ue0d7);         Scale(105, ${scale_height_pl}, 1024, ${center_height_pl}); Move(-33, ${move_y_pl});SetWidth(1024)

    # Loose 版対応 (とりあえず移動させておく)
    if ("${loose_flag}" == "true")
        Select(0ue0b0, 0ue0b1)
        SelectMore(0ue0b4)
        SelectMore(0ue0b5)
        SelectMore(0ue0b8, 0ue0b9)
        SelectMore(0ue0bc, 0ue0bd)
        Move(-${move_x_hankaku}, 0)
        SetWidth(512)

        Select(0ue0b2, 0ue0b3)
        SelectMore(0ue0b6)
        SelectMore(0ue0b7)
        SelectMore(0ue0ba, 0ue0bb)
        SelectMore(0ue0be, 0ue0bf)
        Move(${move_x_hankaku}, 0)
        SetWidth(512)
    endif

# Font Awesome Extension
    Print("Edit Font Awesome Extension")
    Select(0ue200, 0ue2a9)
    Scale(${scale_nerd})
    SetWidth(1024)

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
    Scale(${scale_nerd})
    SetWidth(1024)

    Select(0ue300, 0ue3e3)
    SetWidth(1024)

# Seti-UI + Customs
    Print("Edit Seti-UI + Costoms")
    Select(0ue5fa, 0ue6b8)
    Scale(${scale_nerd})
    SetWidth(1024)

# Devicons
    Print("Edit Devicons")
    Select(0ue700, 0ue8ef)
    Scale(${scale_nerd})
    SetWidth(1024)

# Codicons
    Print("Edit Codicons")
    j = 0uea60
    while (j <= 0uec1e)
        Select(j)
        if (WorthOutputting())
            Scale(${scale_nerd})
            SetWidth(1024)
        endif
        j += 1
    endloop

# Font Awesome
    Print("Edit Font Awesome")
    Select(0ued00, 0uedff)
    SelectMore(0uee0c, 0uefce)
    SelectMore(0uf000, 0uf2ff)
    Scale(${scale_nerd})
    SetWidth(1024)

# Font Logos
    Print("Edit Font Logos")
    Select(0uf300, 0uf381)
    Scale(${scale_nerd})
    SetWidth(1024)

# Octicons
    Print("Edit Octicons")
    Select(0u26a1)
    SelectMore(0uf400, 0uf533)
    Scale(${scale_nerd})
    SetWidth(1024)

# Material Design Icons
    Print("Edit Material Design Icons")
 #    Select(0uf500, 0uf8ff); Scale(83); SetWidth(1024) # v2.3.3まで 互換用
    Select(0uf0001, 0uf1af0)
    Scale(${scale_nerd})
    SetWidth(1024)

# Others
    Print("Edit Other glyphs")
    Select(0u2630); Scale(${scale_nerd}); SetWidth(1024)
    Select(0u276c, 0u2771) #; Scale(${scale_nerd}) # 縮小しない
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
copyright     = "${copyright}" \\
              + "${copyright_nerd_fonts}" \\
              + "${copyright_license}"

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
    Scale(100, ${scale_height_block}, 0, ${center_height_pl}) # Powerlineに合わせて縦を縮小
    Move(0, ${move_y_pl})

    Select(0ue0d1); RemoveOverlap(); Copy() # 
    Select(65552); Paste() # Temporary glyph
    if ("${loose_flag}" == "true") # Loose 版対応
        Scale(113, 100, 256, ${center_height_hankaku})
    endif
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

# ベンゼン環
    Select(0uf02d9); Copy() # 󰋙
    Select(0u23e3); Paste() # ⏣
    ChangeWeight(-40)
    CorrectDirection()
    Select(0uf4aa); Copy() # 
    Select(65552); Paste() # Temporary glyph
    Scale(60)
    Copy()
    Select(0u23e3); PasteInto() # ⏣
    Scale(65)
    ChangeWeight(6)
    CorrectDirection()
    Move(-256, 0)
    SetWidth(512)

    Select(65552); Clear() # Temporary glyph

# 八卦
    Print("Edit bagua trigrams")
    Select(0u2630); Copy() # ☰
    Select(0u2631, 0u2637); Paste() # ☱-☷
    # 線を分割するスクリーン
    Select(${address_store_b_diagram} + 2); Copy() # 保管した■
    Select(65552, 65555); Paste() # Temporary glyph
    Scale(150)
    Select(65552)
    Move(0,700)
    Select(0u2630); Copy() # ☰
    Select(65552); PasteInto()
    OverlapIntersect()
    Scale(25, 100)
    Rotate(90)
    VFlip()
    Copy()
    Select(65553); PasteInto()
    Select(65554); PasteWithOffset(0, -330)
    Select(65555); PasteWithOffset(0, -650)
    # 合成
    Select(65553); Copy()
    Select(0u2631); PasteInto(); OverlapIntersect() # ☱
    Select(0u2633); PasteInto(); OverlapIntersect() # ☳
    Select(0u2635); PasteInto(); OverlapIntersect() # ☵
    Select(0u2637); PasteInto(); OverlapIntersect() # ☷
    Select(65554); Copy()
    Select(0u2632); PasteInto(); OverlapIntersect() # ☲
    Select(0u2633); PasteInto(); OverlapIntersect() # ☳
    Select(0u2636); PasteInto(); OverlapIntersect() # ☶
    Select(0u2637); PasteInto(); OverlapIntersect() # ☷
    Select(65555); Copy()
    Select(0u2634); PasteInto(); OverlapIntersect() # ☴
    Select(0u2635); PasteInto(); OverlapIntersect() # ☵
    Select(0u2636); PasteInto(); OverlapIntersect() # ☶
    Select(0u2637); PasteInto(); OverlapIntersect() # ☷
    Select(0u2630, 0u2637); SetWidth(1024)

    Select(65552, 65555); Clear() # Temporary glyph

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

# スペースの width 変更
    Print("Modified space width")

    Select(0u2001) # em quad
    SelectMore(0u2003) # em space
    SetWidth(${width_zenkaku})

    Select(0u2000) # en quad
    SelectMore(0u2002) # en space
    SelectMore(0u2004) # three-per-em space
    SelectMore(0u2005) # four-per-em space
    SelectMore(0u2006) # six-per-em space
    SelectMore(0u2007) # figure space
    SelectMore(0u2008) # punctuation space
    SelectMore(0u2009) # thin space
    SelectMore(0u200a) # hair space
    SelectMore(0u202f) # narrow no-break space
    SelectMore(0u205f) # medium mathematical space
    SetWidth(${width_hankaku})

    Select(0u034f) # combining grapheme joiner
    SelectMore(0u200b) # zero width space
    SelectMore(0u200c) # zero width non-joiner
    SelectMore(0u200d) # zero width joiner
    SelectMore(0u2060) # word joiner
    SelectMore(0ufeff) # zero width no-break space
    SetWidth(0)

# 記号のグリフを加工
    Print("Edit symbols")
# 🄯 (追加、合成前に実行するとエラーが出る)
    Select(0u00a9); Copy() # ©
    Select(0u1f12f); Paste() # 🄯
    HFlip()
    CorrectDirection()
    SetWidth(512)

# ＿ (latin フォントの _ に合わせる)
    Select(0uff3f) # ＿
    Move(0, ${move_y_zenkaku_underbar})
    SetWidth(1024)

# --------------------------------------------------

# 全角形加工 (半角英数記号を全角形にコピーし、下線を追加)
    Print("Copy hankaku to zenkaku and edit")

    # 縦線作成
    Select(${address_store_underline}); Copy() # 保管した全角下線
    Select(${address_store_underline} + 2); Paste() # 保管所 (後で使うために保管)
    Rotate(-90, 512, 315)
    Move(-13, 0)
    SetWidth(1024)

# 半角英数記号を全角形にコピー、加工
    # ! - }
    j = 0
    while (j < 93)
        if (j != 62) # ＿
            if (j == 91)
                Select(${address_store_visi_latin} + 1) # ｜ (全角縦棒を実線にする)
            else
                Select(0u0021 + j)
            endif
            Copy()
            Select(0uff01 + j); Paste()
            Move(251, 0)
        endif
        if (j == 7 || j == 58 || j == 90) # （ ［ ｛
            Move(128, 0)
        elseif (j == 8 || j == 60 || j == 92) # ） ］ ｝
            Move(-118, 0)
        elseif (j == 11 || j == 13) # ， ．
            Move(-226, 0)
        endif
        SetWidth(1024)
        j += 1
    endloop

    # 〜
    Select(0uff5e); Rotate(10) # ～
    SetWidth(1024)

    # ￠ - ￦
    Select(0u00a2);  Copy() # ¢
    Select(0uffe0); Paste() # ￠
    Move(256, 0)
    SetWidth(1024)
    Select(0u00a3);  Copy() # £
    Select(0uffe1); Paste() # ￡
    Move(256, 0)
    SetWidth(1024)
    Select(0u00ac);  Copy() # ¬
    Select(0uffe2); Paste() # ￢
    Move(256, 0)
    SetWidth(1024)
 #    Select(0u00af);  Copy() # ¯
 #    Select(0uffe3); Paste() # ￣
 #    Move(256, 0)
 #    SetWidth(1024)
    Select(0u00a6);  Copy() # ¦
    Select(0uffe4); Paste() # ￤
    Move(256, 0)
    SetWidth(1024)
    Select(0u00a5);  Copy() # ¥
    Select(0uffe5); Paste() # ￥
    Move(256, 0)
    SetWidth(1024)
    Select(0u20a9);  Copy() # ₩
    Select(0uffe6); Paste() # ￦
    Move(256, 0)
    SetWidth(1024)

    # ‼
    Select(0u0021); Copy() # !
    Select(0u203c); Paste() # ‼
    Move(70, 0)
    Select(0u203c); PasteWithOffset(464, 0) # ‼
    SetWidth(1024)

    # ⁇
    Select(0u003F); Copy() # ?
    Select(0u2047); Paste() # ⁇
    Move(32, 0)
    Select(0u2047); PasteWithOffset(462, 0) # ⁇
    SetWidth(1024)

    # ⁈
    Select(0u003F); Copy() # ?
    Select(0u2048); Paste() # ⁈
    Move(32, 0)
    Select(0u0021); Copy() # !
    Select(0u2048); PasteWithOffset(484, 0) # ⁈
    SetWidth(1024)

    # ⁉
    Select(0u0021); Copy() # !
    Select(0u2049); Paste() # ⁉
    Move(50, 0)
    Select(0u003F); Copy() # ?
    Select(0u2049); PasteWithOffset(462, 0) # ⁉
    SetWidth(1024)

# 縦書き形句読点
    hori = [0uff0c, 0u3001, 0u3002] # ，、。
    vert = 0ufe10
    j = 0
    while (j < SizeOf(hori))
        Select(hori[j]); Copy()
        Select(vert + j); Paste()
        if (hori[j] == 0uff0c)
            Move(542, 597)
        else
            Move(594, 546)
        endif
        SetWidth(1024)
        j += 1
    endloop

# CJK互換形下線
    Select(0uff3f); Copy() # ＿
    Select(0ufe33); Paste() # ︳
    Rotate(-90, 512, 315)
    Move(-13, 0)
    SetWidth(1024)

# CJK互換形括弧
    hori = [0u3016, 0u3017] # 〖〗
    vert = 0ufe17 # ︗
    j = 0
    while (j < SizeOf(hori))
        Select(hori[j]); Copy()
        Select(vert + j); Paste()
        Rotate(-90, 512, 315)
        Move(-20, 0)
        SetWidth(1024)
        j += 1
    endloop

    hori = [0uff08, 0uff09, 0uff5b, 0uff5d,\
            0u3014, 0u3015, 0u3010, 0u3011,\
            0u300a, 0u300b, 0u3008, 0u3009,\
            0u300c, 0u300d, 0u300e, 0u300f] # （）｛｝ 〔〕【】 《》〈〉 「」『』
    vert = 0ufe35 # ︵
    j = 0
    while (j < SizeOf(hori))
        Select(hori[j]); Copy()
        Select(vert + j); Paste()
        Rotate(-90, 512, 315)
        if (hori[j] == 0uff08 || hori[j] == 0uff09) # （）
            Move(-9, 0)
        elseif (hori[j] == 0uff5b || hori[j] == 0uff5d) # ｛｝
            Move(3, 0)
        else
            Move(-20, 0)
        endif
        SetWidth(1024)
        j += 1
    endloop

    hori = [0uff3b, 0uff3d] # ［］
    vert = 0ufe47 # ﹇
    j = 0
    while (j < SizeOf(hori))
        Select(hori[j]); Copy()
        Select(vert + j); Paste()
        Rotate(-90, 512, 315)
        Move(2, 0)
        SetWidth(1024)
        j += 1
    endloop

# 縦書き用全角形他 (vertフィーチャ用)
    Print("Edit vert glyphs")
    k = 0
    hori = [0uff08, 0uff09, 0uff0c, 0uff0e,\
            0uff1a, 0uff1d, 0uff3b, 0uff3d,\
            0uff3f, 0uff5b, 0uff5c, 0uff5d,\
            0uff5e, 0uffe3, 0uff0d, 0uff1b,\
            0uff1c, 0uff1e, 0uff5f, 0uff60] # （），． ：＝［］ ＿｛｜｝ ～￣－； ＜＞｟｠
    vert = ${address_vert_start}
    j = 0
    while (j < SizeOf(hori))
        Select(hori[j]); Copy()
        Select(vert + j); Paste()
        if (hori[j] == 0uff0c || hori[j] == 0uff0e) # ， ．
            Move(542, 597)
        else
            Rotate(-90, 512, 315)
            if (hori[j] == 0uff08 || hori[j] == 0uff09) # （）
                Move(-9, 0)
            elseif (hori[j] == 0uff5b || hori[j] == 0uff5d) # ｛｝
                Move(3, 0)
            elseif (hori[j] == 0uff3b || hori[j] == 0uff3d) # ［］
                Move(2, 0)
            elseif (hori[j] == 0uff5f || hori[j] == 0uff60) # ｟｠
                Move(-20, 0)
            elseif (hori[j] == 0uff3f) # ＿
                Move(-13, 0)
            elseif (hori[j] == 0uffe3) # ￣
                Move(13 + 90 - ${move_y_zenkaku_underbar}, 0)
            elseif (hori[j] == 0uff5e) # ～
                Move(13, 0)
            elseif (hori[j] == 0uff1a || hori[j] == 0uff1b) # ：；
                Move(${move_x_vert_colon}, 0)
            elseif (hori[j] == 0uff5c) # ｜
                Move(${move_x_vert_bar}, 0)
            else # ＝－＜＞
                Move(${move_x_vert_math}, 0)
            endif
        endif
        Copy(); Select(${address_store_vert} + k); Paste(); SetWidth(1024) # 保管所にコピー
        Select(${address_store_underline} + 2);  Copy() # 縦線追加
        Select(vert + j); PasteInto()
        SetWidth(1024)
        j += 1
        k += 1
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
        if (hori[j] == 0u309b\
         || hori[j] == 0u309c) # ゛゜
            Move(594, -545)
        elseif (hori[j] == 0uff0f\
             || hori[j] == 0uff3c) # ／＼
            Rotate(-90, 512, 315)
            Move(${move_x_vert_solidus}, 0)
            VFlip()
            CorrectDirection()
        elseif (hori[j] == 0uffe4) # ￤
            Move(0, ${move_y_vert_bbar})
        elseif (hori[j] == 0uff46\
              || hori[j] == 0uff4c) # ｆｌ
            Move(0, ${move_y_vert_1})
        elseif (hori[j] == 0uff42\
              || hori[j] == 0uff44\
              || hori[j] == 0uff48\
              || hori[j] == 0uff4b) # ｂｄｈｋ
            Move(0, ${move_y_vert_2})
        elseif (hori[j] == 0uff49\
              || hori[j] == 0uff54) # ｉｔ
            Move(0, ${move_y_vert_3})
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
            Move(0, ${move_y_vert_4})
        elseif (hori[j] == 0uff4a) # ｊ
            Move(0, ${move_y_vert_5})
        elseif (hori[j] == 0uff50\
              || hori[j] == 0uff51\
              || hori[j] == 0uff59) # ｐｑｙ
            Move(0, ${move_y_vert_6})
        elseif (hori[j] == 0uff47) # ｇ
            Move(0, ${move_y_vert_7})
        endif
        Copy(); Select(${address_store_vert} + k); Paste(); SetWidth(1024) # 保管所にコピー
        Select(${address_store_underline} + 2);  Copy() # 縦線追加
        Select(vert + j); PasteInto()
        SetWidth(1024)
        j += 1
        k += 1
    endloop

    vert += j
    Select(0u2702); Copy() # ✂
    Select(vert); Paste()
    Rotate(-90, 512, 315)
    Move(-16, 0)
    SetWidth(1024)
    j = 1

    hori = [0u2016, 0u3030, 0u30a0] # ‖〰゠
    vert += j
    j = 0
    while (j < SizeOf(hori))
        Select(hori[j]); Copy()
        Select(vert + j); Paste()
        if (j == 0) # ‖
            Rotate(-90, 512, 315)
            Move(-21, -256)
            SetWidth(1024)
        else # 〰゠
            Rotate(-90, 512, 315)
            SetWidth(1024)
        endif
        j += 1
    endloop

# 横書き全角形に下線追加
    j = 0 # ！ - ｠
    while (j < 96)
        Select(0uff01 + j)
        Copy(); Select(${address_store_vert} + k); Paste(); SetWidth(1024) # 保管所にコピー
        Select(${address_store_underline}); Copy() # 下線追加
        Select(0uff01 + j); PasteInto()
        SetWidth(1024)
        j += 1
        k += 1
    endloop

# 保管しているDQVZに下線追加
    j = 0
    while (j < ${num_mod_glyphs})
        Select(${address_store_mod} + j) # 下線無し時の半角
        SetWidth(${width_hankaku})
        Copy()
        Select(${address_store_mod} + ${num_mod_glyphs} * 3 + j); Paste() # 下線付き時の半角 (パッチを当てる時用)
        SetWidth(${width_hankaku})
        Select(${address_store_mod} + ${num_mod_glyphs} + j); Paste() # 下線無し全角横書き
        Move(251, 0)
        SetWidth(1024)
        Copy()
        Select(${address_store_mod} + ${num_mod_glyphs} * 2 + j); Paste() # 下線無し全角縦書き (パッチを当てる時用)
        SetWidth(1024)
        Select(${address_store_mod} + ${num_mod_glyphs} * 4 + j); Paste() # 下線付き全角横書き
        Select(${address_store_mod} + ${num_mod_glyphs} * 5 + j); Paste() # 下線付き全角縦書き
        Select(${address_store_underline}); Copy() # 下線追加
        Select(${address_store_mod} + ${num_mod_glyphs} * 4 + j); PasteInto()
        SetWidth(1024)
        Select(${address_store_underline} + 2); Copy() # 縦線追加
        Select(${address_store_mod} + ${num_mod_glyphs} * 5 + j); PasteInto()
        SetWidth(1024)
        j += 1
    endloop

# 保管しているスラッシュ無し0に下線追加
    Select(${address_store_zero}); Copy() # 下線無し時の半角
    Select(${address_store_zero} + 3); Paste() # 下線無し全角
    Move(251, 0)
    SetWidth(1024)
    Copy()
    Select(${address_store_zero} + 4); Paste() # 下線付き全角横書き
    Select(${address_store_zero} + 5); Paste() # 下線付き全角縦書き
    Select(${address_store_underline}); Copy() # 下線追加
    Select(${address_store_zero} + 4); PasteInto() # 下線付き全角横書き
    SetWidth(1024)
    Select(${address_store_underline} + 2); Copy() # 縦線追加
    Select(${address_store_zero} + 5); PasteInto() # 下線付き全角縦書き
    SetWidth(1024)

# 保管しているドット0に下線追加
    Select(${address_store_zero} + 6); Copy() # 下線無し時の半角
    Select(${address_store_zero} + 3 + 6); Paste() # 下線無し全角
    Move(251, 0)
    SetWidth(1024)
    Copy()
    Select(${address_store_zero} + 4 + 6); Paste() # 下線付き全角横書き
    Select(${address_store_zero} + 5 + 6); Paste() # 下線付き全角縦書き
    Select(${address_store_underline}); Copy() # 下線追加
    Select(${address_store_zero} + 4 + 6); PasteInto() # 下線付き全角横書き
    SetWidth(1024)
    Select(${address_store_underline} + 2); Copy() # 縦線追加
    Select(${address_store_zero} + 5 + 6); PasteInto() # 下線付き全角縦書き
    SetWidth(1024)

# 半角文字に下線を追加
    Print("Edit hankaku")
    j = 0
    while (j < 63)
       Select(0uff61 + j) # ｡-ﾟ
       Copy(); Select(${address_store_vert} + k); Paste(); SetWidth(${width_hankaku}) # 保管所にコピー
       Select(${address_store_underline} + 1); Copy() # 下線追加
       Select(0uff61 + j); PasteInto() # ｡-ﾟ
       SetWidth(512)
        j += 1
        k += 1
    endloop

# 横書き全角形に下線追加 (続き)
    Print("Edit zenkaku")
    j = 0 # ￠ - ￦
    while (j < 7)
        Select(0uffe0 + j)
        Copy(); Select(${address_store_vert} + k); Paste(); SetWidth(1024) # 保管所にコピー
        Select(${address_store_underline}); Copy() # 下線追加
        Select(0uffe0 + j); PasteInto()
        SetWidth(1024)
        j += 1
        k += 1
    endloop

    hori = [0u309b, 0u309c, 0u203c, 0u2047,\
            0u2048, 0u2049] # ゛゜‼⁇ ⁈⁉
    j = 0
    while (j < SizeOf(hori))
        Select(hori[j])
        Copy(); Select(${address_store_vert} + k); Paste(); SetWidth(1024) # 保管所にコピー
        Select(${address_store_underline});  Copy() # 下線追加
        Select(hori[j]); PasteInto()
        SetWidth(1024)
        j += 1
        k += 1
    endloop

# 保管している、改変されたグリフの縦書きを追加
    Select(${address_store_visi_latin} + 1); Copy() # |
    Select(${address_store_vert} + 10); Paste() # 縦書き
    Move(256, 0)
    Rotate(-90, 512, 315)
    Move(${move_x_vert_bar}, 0)
    SetWidth(1024)

 #    Select(${address_store_vert} + 200); Paste() # 全角縦棒を破線にする場合有効にする
 #    Move(256, 0) # ただし ss06 に対応する処理の追加が必要
 #    SetWidth(1024)

    Select(${address_store_visi_kana}); Copy() # ゠
    Select(${address_store_vert} + k); Paste() # 縦書き
    Rotate(-90, 512, 315)
    SetWidth(1024)
    k += 1

# --------------------------------------------------

# 全ての半角の文字を移動して Width 変更 (Loose 版対応)
    if ("${loose_flag}" == "true")
        Print("Change width of hankaku glyphs (it may take a few minutes)")

        SelectWorthOutputting()
        foreach
            if (300 <= GlyphInfo("Width") && GlyphInfo("Width") <= 700)
                Move(${move_x_hankaku}, 0)
                SetWidth(${width_hankaku})
            endif
        endloop
    endif

# --------------------------------------------------

# あいまい文字等を半角に変換 (ss12のグリフと同じにすること)
    if ("${term_flag}" == "true")
        Print("Set neutral and ambiguous characters to hankaku")

        Select(0u2014) # —
        SelectMore(${address_store_visi_kana} + 3) # 保管所
        Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose}, 100, ${width_zenkaku} / 2, 0)
        Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        Copy()
        Move(-6 * ${width_hankaku_loose} / ${width_hankaku}, 0)
        PasteWithOffset(6 * ${width_hankaku_loose} / ${width_hankaku}, 0)
        OverlapIntersect()
        SetWidth(${width_hankaku})

        Select(0u0021); Copy() # !
        Select(0u203c); Paste() # ‼
        Move(-150 * ${width_hankaku_loose} / ${width_hankaku}, 0)
        Select(0u2049); Paste() # ⁉
        Move(-150 * ${width_hankaku_loose} / ${width_hankaku}, 0)

        Select(0u003f); Copy() # ?
        Select(0u2047); Paste() # ⁇
        Move(-150 * ${width_hankaku_loose} / ${width_hankaku}, 0)
        Select(0u2048); Paste() # ⁈
        Move(-150 * ${width_hankaku_loose} / ${width_hankaku}, 0)

        Select(0u0021); Copy() # !
        Select(0u203c); PasteWithOffset(150 * ${width_hankaku_loose} / ${width_hankaku}, 0) # ‼
        Scale(${scale_zenkaku2hankaku}, 100, ${width_hankaku} / 2, 0)
        SetWidth(${width_hankaku})
        Select(0u2048); PasteWithOffset(150 * ${width_hankaku_loose} / ${width_hankaku}, 0) # ⁈
        Scale(${scale_zenkaku2hankaku}, 100, ${width_hankaku} / 2, 0)
        SetWidth(${width_hankaku})

        Select(0u003f); Copy() # ?
        Select(0u2047); PasteWithOffset(150 * ${width_hankaku_loose} / ${width_hankaku}, 0) # ⁇
        Scale(${scale_zenkaku2hankaku}, 100, ${width_hankaku} / 2, 0)
        SetWidth(${width_hankaku})
        Select(0u2049); PasteWithOffset(150 * ${width_hankaku_loose} / ${width_hankaku}, 0) # ⁉
        Scale(${scale_zenkaku2hankaku}, 100, ${width_hankaku} / 2, 0)
        SetWidth(${width_hankaku})

        Select(0u2025) # ‥
        SelectMore(0u2026) # …
        SelectMore(0u22ef) # ⋯
        foreach
            if (WorthOutputting())
                if (600 <= GlyphInfo("Width"))
                    Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose}, 100, ${width_zenkaku} / 2, 0)
                    Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
                    Copy()
                    PasteWithOffset(-10 * ${width_hankaku_loose} / ${width_hankaku}, 0)
                    PasteWithOffset( 10 * ${width_hankaku_loose} / ${width_hankaku}, 0)
                    RemoveOverlap()
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u2042) # ⁂
        SelectMore(0u2103) # ℃
        SelectMore(0u2109) # ℉
        SelectMore(0u226a, 0u226b) # ≪≫
        SelectMore(0u2669, 0u266a) # ♩♪
        SelectMore(0u266b) # ♫
        SelectMore(0u266c, 0u266d) # ♬♭
        SelectMore(0u266e) # ♮
        SelectMore(0u266f) # ♯
        foreach
            if (WorthOutputting())
                if (600 <= GlyphInfo("Width"))
                    Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 1.2, 100, ${width_zenkaku} / 2, 0)
                    Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u2051) # ⁑
        SelectMore(0u22ee) # ⋮
        SelectMore(0u2307) # ⌇
        foreach
            if (WorthOutputting())
                if (600 <= GlyphInfo("Width"))
                    Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u2460, 0u2487) # ①-⒇
        SelectMore(0u249c, 0u24e9) # ⒜-ⓩ
        SelectMore(0u24ea) # ⓪
        SelectMore(0u24eb, 0u24ff) # ⓫-⓿
        SelectMore(0u2776, 0u277f) # ❶-❿
        SelectMore(0u2780, 0u2793) # ➀-➓
        SelectMore(${address_store_visi_kana} + 5, ${address_store_visi_kana} + 24) # 保管所
        foreach
            if (WorthOutputting())
                if (600 <= GlyphInfo("Width"))
                    Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 0.95, 100, ${width_zenkaku} / 2, 0)
                    Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u221d, 0u221e) # ∝∞
        SelectMore(0u223d) # ∽
        SelectMore(0u2660, 0u2661) # ♠♡
        SelectMore(0u2662) # ♢
        SelectMore(0u2663, 0u2665) # ♣♤♥
        SelectMore(0u2666) # ♦
        SelectMore(0u2667) # ♧
        foreach
            if (WorthOutputting())
                if (600 <= GlyphInfo("Width"))
                    Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 1.1, 100, ${width_zenkaku} / 2, 0)
                    Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u25e2) # ◢
        SelectMore(0u25e5) # ◥
        foreach
            if (WorthOutputting())
                if (600 <= GlyphInfo("Width"))
                    Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose}, 100, ${width_zenkaku}, 0)
                    Move(-(${width_zenkaku} - ${width_hankaku}), 0)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u25e3) # ◣
        SelectMore(0u25e4) # ◤
        foreach
            if (WorthOutputting())
                if (600 <= GlyphInfo("Width"))
                    Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose}, 100, 0, 0)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u22a2, 0u22a4) # ⊢-⊤
        SelectMore(0u22a5) # ⊥
        SelectMore(0u232d) # ⌭
        SelectMore(0u2330) # ⌰
        SelectMore(0u23be, 0u23cc) # ⎾-⏌
        foreach
            if (WorthOutputting())
                if (600 <= GlyphInfo("Width"))
                    Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose}, ${width_zenkaku} / 2, 340)
                    Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
                    ChangeWeight(12)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u2190, 0u2194) # ←-↔
        SelectMore(0u2195, 0u2199) # ↕-↙
        SelectMore(0u21a4, 0u21a5) # ↤↥
        SelectMore(0u21a6) # ↦
        SelectMore(0u21a7, 0u21a8) # ↧↨
        SelectMore(0u21a9, 0u21aa) # ↩↪
        SelectMore(0u21b0, 0u21b5) # ↰-↵
        SelectMore(0u21b9) # ↹
        SelectMore(0u21c4, 0u21ca) # ⇄-⇊
        SelectMore(0u21d0, 0u21d1) # ⇐⇑
        SelectMore(0u21d2) # ⇒
        SelectMore(0u21d3) # ⇓
        SelectMore(0u21d4) # ⇔
        SelectMore(0u21d5, 0u21d9) # ⇕-⇙
        SelectMore(0u21de, 0u21df) # ⇞⇟
        SelectMore(0u21e0, 0u21e5) # ⇠-⇥
        SelectMore(0u21e6) # ⇦
        SelectMore(0u21e7) # ⇧
        SelectMore(0u21e8, 0u21ed) # ⇨-⇭
        SelectMore(0u21f5) # ⇵
        SelectMore(0u221f, 0u2220) # ∟∠
        SelectMore(0u22bf) # ⊿
        SelectMore(0u2312) # ⌒
        SelectMore(0u2313) # ⌓
        SelectMore(0u2325) # ⌥
        SelectMore(0u2332, 0u2333) # ⌲⌳
        SelectMore(0u2335) # ⌵
        SelectMore(0u2387) # ⎇
        foreach
            if (WorthOutputting())
                if (600 <= GlyphInfo("Width"))
                    Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 1.1, ${width_zenkaku} / 2, 340)
                    Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
                    ChangeWeight(9)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u23e5) # ⏥
        foreach
            if (WorthOutputting())
                if (600 <= GlyphInfo("Width"))
                    Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 1.1, ${width_zenkaku} / 2, 340)
                    Copy()
                    Scale(98, ${width_zenkaku} / 2, 340)
                    PasteInto()
                    RemoveOverlap()
                    Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u2225) # ∥
        SelectMore(0u2226) # ∦
        SelectMore(0u2300) # ⌀
        SelectMore(0u2302) # ⌂
        SelectMore(0u2303) # ⌃
        SelectMore(0u2324) # ⌤
        SelectMore(0u2334) # ⌴
        SelectMore(0u238b) # ⎋
        SelectMore(0u2425) # ␥
        foreach
            if (WorthOutputting())
                if (600 <= GlyphInfo("Width"))
                    Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 1.2, ${width_zenkaku} / 2, 340)
                    Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
                    ChangeWeight(6)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u23fc) # ⏼
        foreach
            if (WorthOutputting())
                if (600 <= GlyphInfo("Width"))
                    Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 0.9, ${width_zenkaku} / 2, 340)
                    Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u2600) # ☀
        SelectMore(0u263c) # ☼
        foreach
            if (WorthOutputting())
                if (600 <= GlyphInfo("Width"))
                    Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 1.1, ${width_zenkaku} / 2, 340)
                    Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u2316, 0u2318) # ⌖-⌘
        SelectMore(0u2326, 0u2327) # ⌦⌧
        SelectMore(0u232b) # ⌫
        SelectMore(0u2388) # ⎈
        SelectMore(0u23ce, 0u23cf) # ⏎⏏
        foreach
            if (WorthOutputting())
                if (600 <= GlyphInfo("Width"))
                    Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 1.2, ${width_zenkaku} / 2, 340)
                    Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u00bc, 0u00be) # ¼½¾

        SelectMore(0u2000, 0u200a) # スペース
        SelectMore(0u200b, 0u200f) # スペース
        SelectMore(0u2010) # ‐
        SelectMore(0u2011, 0u2012) # ‑‒
        SelectMore(0u2013, 0u2015) # –—―
        SelectMore(0u2016) # ‖
        SelectMore(0u2017) # ‗
        SelectMore(0u2018) # ‘
        SelectMore(0u2019) # ’
        SelectMore(0u201a) # ‚
        SelectMore(0u201b) # ‛
        SelectMore(0u201c) # “
        SelectMore(0u201d) # ”
        SelectMore(0u201e) # „
        SelectMore(0u201f) # ‟
        SelectMore(0u2020, 0u2022) # †‡•
        SelectMore(0u2023) # ‣
        SelectMore(0u2024) # ․
        SelectMore(0u2027) # ‧
        SelectMore(0u202f) # narrow no-break space
        SelectMore(0u2030) # ‰
        SelectMore(0u2031) # ‱
        SelectMore(0u2032, 0u2033) # ′″
        SelectMore(0u2034) # ‴
        SelectMore(0u2035) # ‵
        SelectMore(0u2036, 0u2038) # ‶‷‸
        SelectMore(0u2039) # ‹
        SelectMore(0u203a) # ›
        SelectMore(0u203b) # ※
        SelectMore(0u203d) # ‽
        SelectMore(0u203e) # ‾
        SelectMore(0u203f, 0u2040) # ‿⁀
        SelectMore(0u2041) # ⁁
        SelectMore(0u2043) # ⁃
        SelectMore(0u2044) # ⁄
        SelectMore(0u2045) # ⁅
        SelectMore(0u2046) # ⁆
        SelectMore(0u2050) # ⁐
        SelectMore(0u2052) # ⁒
        SelectMore(0u2053) # ⁓
        SelectMore(0u2054) # ⁔
        SelectMore(0u2055, 0u205e) # ⁕
        SelectMore(0u205f) # medium mathematical space
        SelectMore(0u20a0, 0u20a8) # ₠-₨
        SelectMore(0u20aa, 0u20ab) # ₪₫
        SelectMore(0u20ac) # €
        SelectMore(0u20ad, 0u20c0) # ₭-⃀

        SelectMore(0u2100, 0u2101) # ℀℁
        SelectMore(0u2102) # ℂ
        SelectMore(0u2104) # ℄
        SelectMore(0u2105) # ℅
        SelectMore(0u2106) # ℆
        SelectMore(0u2107) # ℇ
        SelectMore(0u2108) # ℈
        SelectMore(0u210a, 0u2112) # ℊ-ℒ
        SelectMore(0u2113) # ℓ
        SelectMore(0u2114) # ℔
        SelectMore(0u2115) # ℕ
        SelectMore(0u2116) # №
        SelectMore(0u2117) # ℗
        SelectMore(0u2118) # ℘
        SelectMore(0u2119, 0u211d) # ℙ-ℝ
        SelectMore(0u211e, 0u2120) # ℞-℠
        SelectMore(0u2121, 0u2122) # ℡-™
        SelectMore(0u2123) # ℣
        SelectMore(0u2124) # ℤ
        SelectMore(0u2125) # ℥
        SelectMore(0u2126) # Ω
        SelectMore(0u2127) # ℧
        SelectMore(0u2128) # ℨ
        SelectMore(0u2129) # ℩
        SelectMore(0u212a) # K
        SelectMore(0u212b) # Å
        SelectMore(0u212c, 0u212d) # ℬℭ
        SelectMore(0u212e) # ℮
        SelectMore(0u212f, 0u2134) # ℯ
        SelectMore(0u2135, 0u2138) # ℵ-ℸ
        SelectMore(0u2139) # ℹ
        SelectMore(0u213a, 0u213b) # ℺℻
        SelectMore(0u213c, 0u213f) # ℼℿ
        SelectMore(0u2140, 0u2144) # ⅀-⅄
        SelectMore(0u2145, 0u2149) # ⅅ-ⅉ
        SelectMore(0u214a) # ⅊
        SelectMore(0u214b) # ⅋
        SelectMore(0u214c, 0u214d) # ⅌⅍
        SelectMore(0u214e) # ⅎ
        SelectMore(0u214f) # ⅏
        SelectMore(0u2150, 0u2152) # ⅐⅑⅒
        SelectMore(0u2153, 0u2154) # ⅓⅔
        SelectMore(0u2155, 0u215a) # ⅕-⅚
        SelectMore(0u215b, 0u215e) # ⅛-⅞
        SelectMore(0u215f) # ⅟
        SelectMore(0u2160, 0u216b) # Ⅰ-Ⅻ
        SelectMore(0u216c, 0u216f) # Ⅼ-Ⅿ
        SelectMore(0u2170, 0u2179) # ⅰ-ⅹ
        SelectMore(0u217a, 0u2182) # ⅺ-ↂ
        SelectMore(0u2183, 0u2184) # Ↄↄ
        SelectMore(0u2185, 0u2188) # ↅ-ↈ
        SelectMore(0u2189) # ↉
        SelectMore(0u218a, 0u218b) # ↊↋

        SelectMore(0u2200) # ∀
        SelectMore(0u2201) # ∁
        SelectMore(0u2202, 0u2203) # ∂∃
        SelectMore(0u2204, 0u2206) # ∄∅∆
        SelectMore(0u2207, 0u2208) # ∇∈
        SelectMore(0u2209, 0u220a) # ∉∊
        SelectMore(0u220b) # ∋
        SelectMore(0u220c, 0u220e) # ∌∍∎
        SelectMore(0u220f) # ∏
        SelectMore(0u2210) # ∐
        SelectMore(0u2211) # ∑
        SelectMore(0u2212, 0u2214) # −∓∔
        SelectMore(0u2215) # ∕
        SelectMore(0u2216, 0u2219) # ∖-∙
        SelectMore(0u221a) # √
        SelectMore(0u221b, 0u221c) # ∛∜
        SelectMore(0u2223) # ∣
        SelectMore(0u2224) # ∤
        SelectMore(0u2227, 0u222c) # ∧-∬
        SelectMore(0u222d) # ∭
        SelectMore(0u222e) # ∮
        SelectMore(0u222f, 0u2233) # ∯-∳
        SelectMore(0u2234, 0u2237) # ∴-∷
        SelectMore(0u2238, 0u223b) # ∸-∻
        SelectMore(0u223c) # ∼
        SelectMore(0u223e, 0u2247) # ∾-≇
        SelectMore(0u2248) # ≈
        SelectMore(0u2249, 0u224b) # ≉≊≋
        SelectMore(0u224c) # ≌
        SelectMore(0u224d, 0u2251) # ≍-≑
        SelectMore(0u2252) # ≒
        SelectMore(0u2253, 0u225f) # ≓-≟
        SelectMore(0u2260, 0u2261) # ≠≡
        SelectMore(0u2262, 0u2263) # ≢≣
        SelectMore(0u2264, 0u2267) # ≤≧
        SelectMore(0u2268, 0u2269) # ≨≩
        SelectMore(0u226c, 0u226d) # ≬≭
        SelectMore(0u226e, 0u226f) # ≮≯
        SelectMore(0u2270, 0u2281) # ≰-⊁
        SelectMore(0u2282, 0u2283) # ⊂⊃
        SelectMore(0u2284, 0u2285) # ⊄⊅
        SelectMore(0u2286, 0u2287) # ⊆⊇
        SelectMore(0u2288, 0u2294) # ⊈-⊔
        SelectMore(0u22c0, 0u22ed) # ⋀-⋭
        SelectMore(0u22f0, 0u22ff) # ⋰-⋿

        SelectMore(0u2301) # ⌁
        SelectMore(0u2308) # ⌈
        SelectMore(0u2309) # ⌉
        SelectMore(0u230a) # ⌊
        SelectMore(0u230b) # ⌋
        SelectMore(0u230c, 0u2311) # ⌌-⌑
        SelectMore(0u2319) # ⌙
        SelectMore(0u231c, 0u231f) # ⌜-⌟
        SelectMore(0u2320, 0u2321) # ⌠⌡
        SelectMore(0u232f) # ⌯
        SelectMore(0u237c) # ⍼
        SelectMore(0u239b, 0u23b3) # ⎛-⎳
        SelectMore(0u23b4, 0u23bd) # ⎴-⎽
        SelectMore(0u23d0, 0u23db) # ⏐-⏛
        SelectMore(0u23dc, 0u23e1) # ⏜-⏡
        SelectMore(0u23e4) # ⏤

        SelectMore(0u2400, 0u2424) # ␀-␤
        SelectMore(0u2426) # ␦
        SelectMore(0u2440, 0u244a) # ⑀-⑊
        SelectMore(0u2488, 0u249b) # ⒈-⒛

        SelectMore(0u2500, 0u254b) # ─-╋
        SelectMore(0u254c, 0u254f) # ╌╎╏
        SelectMore(0u2550, 0u2573) # ═-╳
        SelectMore(0u2574, 0u257f) # ╴-╿
        SelectMore(0u2580, 0u258f) # ▀-▏
        SelectMore(0u2590, 0u2591) # ▐░
        SelectMore(0u2592, 0u2595) # ▒▕
        SelectMore(0u2596, 0u259f) # ▖-▟

        SelectMore(0u260e, 0u260f) # ☎☏
        SelectMore(0u2613) # ☓
        SelectMore(0u2616, 0u2617) # ☖☗
        SelectMore(0u2620) # ☠
        SelectMore(0u2630, 0u2637) # ☰-☷
        SelectMore(0u2668) # ♨
        SelectMore(0u2672, 0u267b) # ♲-♻
        SelectMore(0u268a, 0u268f) # ⚌-⚏
        SelectMore(0u2690, 0u2691) # ⚐⚑
        SelectMore(0u26a0) # ⚠
        SelectMore(0u26c9, 0u26ca) # ⛉⛊

        SelectMore(0u2756) # ❖
        SelectMore(0u2758, 0u2763) # ❘-❣
        SelectMore(0u2768) # ❨
        SelectMore(0u2769) # ❩
        SelectMore(0u276a) # ❪
        SelectMore(0u276b) # ❫
        SelectMore(0u276c) # ❬
        SelectMore(0u276d) # ❭
        SelectMore(0u276e) # ❮
        SelectMore(0u276f) # ❯
        SelectMore(0u2770) # ❰
        SelectMore(0u2771) # ❱
        SelectMore(0u2772) # ❲
        SelectMore(0u2773) # ❳
        SelectMore(0u2774) # ❴
        SelectMore(0u2775) # ❵
        SelectMore(0u27c0, 0u27c4) # ⟀-⟄
        SelectMore(0u27c5) # ⟅
        SelectMore(0u27c6) # ⟆
        SelectMore(0u27c7, 0u27e5) # ⟇-⟥
        SelectMore(0u27ee) # ⟮
        SelectMore(0u27ef) # ⟯

        SelectMore(0u2800, 0u28ff) # ⠀-⣿

        SelectMore(0u2980, 0u2982) # ⦀⦁⦂
        SelectMore(0u2983) # ⦃
        SelectMore(0u2984) # ⦄
        SelectMore(0u2987) # ⦇
        SelectMore(0u2988) # ⦈
        SelectMore(0u2989) # ⦉
        SelectMore(0u298a) # ⦊
        SelectMore(0u298b) # ⦋
        SelectMore(0u298c) # ⦌
        SelectMore(0u298d) # ⦍
        SelectMore(0u298e) # ⦎
        SelectMore(0u298f) # ⦏
        SelectMore(0u2990) # ⦐
        SelectMore(0u2991) # ⦑
        SelectMore(0u2992) # ⦒
        SelectMore(0u2993) # ⦓
        SelectMore(0u2994) # ⦔
        SelectMore(0u2995) # ⦕
        SelectMore(0u2996) # ⦖
        SelectMore(0u2997) # ⦗
        SelectMore(0u2998) # ⦘
        SelectMore(0u2999, 0u29d7) # ⦙-⧗
        SelectMore(0u29d8) # ⧘
        SelectMore(0u29d9) # ⧙
        SelectMore(0u29da) # ⧚
        SelectMore(0u29db) # ⧛
        SelectMore(0u29dc, 0u29fb) # ⧜-⧻
        SelectMore(0u29fc) # ⧼
        SelectMore(0u29fd) # ⧽
        SelectMore(0u29fe, 0u29ff) # ⧾⧿

        SelectMore(0u2a00, 0u2aff) # ⨀-⫿

        SelectMore(0u1f100) # 🄀

        foreach
            if (WorthOutputting())
                if (600 <= GlyphInfo("Width"))
                    Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose}, 100, ${width_zenkaku} / 2, 0)
                    Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

        Select(0u219a, 0u219b) # ↚↛
        SelectMore(0u219c, 0u219f) # ↜-↟
        SelectMore(0u21a0) # ↠
        SelectMore(0u21a1, 0u21a2) # ↡↢
        SelectMore(0u21a3) # ↣
        SelectMore(0u21ab, 0u21ad) # ↫-↭
        SelectMore(0u21ae) # ↮
        SelectMore(0u21af) # ↯
        SelectMore(0u21b6, 0u21b7) # ↶↷
        SelectMore(0u21b8) # ↸
        SelectMore(0u21ba, 0u21c3) # ↺-⇃
        SelectMore(0u21cb, 0u21cd) # ⇋⇌⇍
        SelectMore(0u21ce, 0u21cf) # ⇎⇏
        SelectMore(0u21da, 0u21dd) # ⇚-⇝
        SelectMore(0u21ee, 0u21f3) # ⇮-⇳
        SelectMore(0u21f4) # ⇴
        SelectMore(0u21f6, 0u21ff) # ⇶-⇿

        SelectMore(0u2295) # ⊕
        SelectMore(0u2296, 0u2298) # ⊖⊗⊘
        SelectMore(0u2299) # ⊙
        SelectMore(0u229a, 0u22a1) # ⊚-⊡
        SelectMore(0u2221, 0u2222) # ∡∢
        SelectMore(0u22a6, 0u22be) # ⊦-⊾

        SelectMore(0u2304, 0u2306) # ⌄-⌆
        SelectMore(0u2314, 0u2315) # ⌔⌕
        SelectMore(0u2322, 0u2323) # ⌢⌣
        SelectMore(0u2328) # ⌨
        SelectMore(0u232c) # ⌬
        SelectMore(0u232e) # ⌮
        SelectMore(0u2331) # ⌱
        SelectMore(0u2336, 0u237a) # ⌶-⍺
        SelectMore(0u237b) # ⍻
        SelectMore(0u237d, 0u2386) # ⍽-⎆
        SelectMore(0u2389, 0u238a) # ⎉⎊
        SelectMore(0u238c, 0u239a) # ⎌-⎚
        SelectMore(0u23cd) # ⏍
        SelectMore(0u23e2, 0u23e3) # ⏢⏣
        SelectMore(0u23e6, 0u23e8) # ⏦⏧⏨
        SelectMore(0u23ed, 0u23ef) # ⏭⏯
        SelectMore(0u23f1, 0u23f2) # ⏱⏲
        SelectMore(0u23f4, 0u23fa) # ⏴-⏺
        SelectMore(0u23fb) # ⏻
        SelectMore(0u23fd, 0u23fe) # ⏽⏾
        SelectMore(0u23ff) # ⏿

        SelectMore(0u25a0, 0u25a1) # ■□
        SelectMore(0u25a2) # ▢
        SelectMore(0u25a3, 0u25a9) # ▣-▩
        SelectMore(0u25aa, 0u25b1) # ▪-▱
        SelectMore(0u25b2, 0u25b3) # ▲△
        SelectMore(0u25b4, 0u25b5) # ▴▵
        SelectMore(0u25b6) # ▶
        SelectMore(0u25b7) # ▷
        SelectMore(0u25b8, 0u25bb) # ▸-▻
        SelectMore(0u25bc, 0u25bd) # ▼▽
        SelectMore(0u25be, 0u25bf) # ▾▿
        SelectMore(0u25c0) # ◀
        SelectMore(0u25c1) # ◁
        SelectMore(0u25c2, 0u25c5) # ◂-◅
        SelectMore(0u25c6, 0u25c8) # ◆◇◈
        SelectMore(0u25c9, 0u25ca) # ◉◊
        SelectMore(0u25cb) # ○
        SelectMore(0u25cc, 0u25cd) # ◌◍
        SelectMore(0u25ce, 0u25d1) # ◎-◑
        SelectMore(0u25d2, 0u25e1) # ◒-◡
        SelectMore(0u25e6, 0u25ee) # ◦-◮
        SelectMore(0u25ef) # ◯
        SelectMore(0u25f0, 0u25f7) # ◰-◷
        SelectMore(0u25f8, 0u25fc) # ◸-◼
        SelectMore(0u25ff) # ◿

        SelectMore(0u2601, 0u2604) # ☁-☄
        SelectMore(0u2605, 0u2606) # ★☆
        SelectMore(0u2607, 0u2608) # ☇☈
        SelectMore(0u2609) # ☉
        SelectMore(0u260a, 0u260d) # ☊-☍
        SelectMore(0u2610, 0u2612) # ☐☑☒
        SelectMore(0u2618, 0u2619) # ☘☙
        SelectMore(0u261a, 0u261b) # ☚☛
        SelectMore(0u261c) # ☜
        SelectMore(0u261d) # ☝
        SelectMore(0u261e) # ☞
        SelectMore(0u261f) # ☟
        SelectMore(0u2621, 0u262f) # ☡-☯
        SelectMore(0u2638, 0u263b) # ☸-☻
        SelectMore(0u263d, 0u263f) # ☽☾☿
        SelectMore(0u2640) # ♀
        SelectMore(0u2641) # ♁
        SelectMore(0u2642) # ♂
        SelectMore(0u2643, 0u2647) # ♃-♇
        SelectMore(0u2654, 0u265f) # ♔-♟
        SelectMore(0u2670, 0u2671) # ♰♱
        SelectMore(0u267c, 0u267e) # ♼♽♾
        SelectMore(0u2680, 0u2689) # ⚀-⚉
        SelectMore(0u2692) # ⚒
        SelectMore(0u2694, 0u269d) # ⚔-⚝
        SelectMore(0u269e, 0u269f) # ⚞⚟
        SelectMore(0u26a2, 0u26a9) # ⚢-⚩
        SelectMore(0u26ac, 0u26bc) # ⚬-⚼
        SelectMore(0u26bf) # ⚿
        SelectMore(0u26c0, 0u26c3) # ⛀-⛃
        SelectMore(0u26c6, 0u26c8) # ⛆⛇⛈
        SelectMore(0u26cb, 0u26cd) # ⛋-⛍
        SelectMore(0u26cf, 0u26d3) # ⛏-⛓
        SelectMore(0u26d5, 0u26e1) # ⛕-⛡
        SelectMore(0u26e2) # ⛢
        SelectMore(0u26e3) # ⛣
        SelectMore(0u26e4, 0u26e7) # ⛤-⛧
        SelectMore(0u26e8, 0u26e9) # ⛨⛩
        SelectMore(0u26eb, 0u26f1) # ⛫-⛱
        SelectMore(0u26f4) # ⛴
        SelectMore(0u26f6, 0u26f9) # ⛶-⛹
        SelectMore(0u26fb, 0u26fc) # ⛻-⛼
        SelectMore(0u26fe, 0u26ff) # ⛾⛿

        SelectMore(0u2700, 0u2704) # ✀-✄
        SelectMore(0u2708, 0u2709) # ✈✉
        SelectMore(0u2706, 0u2707) # ✆✇
        SelectMore(0u270c, 0u2727) # ✌-✧
        SelectMore(0u2729, 0u273c) # ✩-✼
        SelectMore(0u273d) # ✽
        SelectMore(0u273e, 0u274b) # ✾-❋
        SelectMore(0u274d) # ❍
        SelectMore(0u274f, 0u2752) # ❏-❒
        SelectMore(0u2764, 0u2767) # ❤-❧
        SelectMore(0u2794) # ➔
        SelectMore(0u2798, 0u27af) # ➘-➯
        SelectMore(0u27b1, 0u27be) # ➱-➾
        SelectMore(0u27f0, 0u27ff) # ⟰-⟿

        SelectMore(0u2900, 0u297f) # ⤀-⥿
        SelectMore(0u2b00, 0u2b1a) # ⬀-⬚
        SelectMore(0u2b1d, 0u2b2f) # ⬝-⬯
        SelectMore(0u2b30, 0u2b44) # ⬰-⭄
        SelectMore(0u2b45, 0u2b46) # ⭅⭆
        SelectMore(0u2b47, 0u2b4c) # ⭇-⭌
        SelectMore(0u2b4d, 0u2b4f) # ⭍⭎⭏
        SelectMore(0u2b51, 0u2b54) # ⭑-⭔
        SelectMore(0u2b56, 0u2b59) # ⭖-⭙
        SelectMore(0u2b5a, 0u2b73) # ⭚-⭳
        SelectMore(0u2b76, 0u2b95) # ⭶-⮕
        SelectMore(0u2b97, 0u2bff) # ⮗-⯿

        foreach
            if (WorthOutputting())
                if (600 <= GlyphInfo("Width"))
                    Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose}, ${width_zenkaku} / 2, 340)
                    Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
                    SetWidth(${width_hankaku})
                endif
            endif
        endloop

    endif

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

# calt 対応 (変更した時はスロットの追加とパッチ側の変更も忘れないこと)
    Print("Add calt lookups")
    lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups)

    # グリフ変換用 lookup
    lookupName = "単純置換 (中・ラテン文字)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1]) # lookup の最後に追加
    lookupSub0 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub0)

    lookupName = "単純置換 (左・ラテン文字)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)
    k = ${address_calt_AL}
    j = 0
    while (j < 26)
        Select(0u0041 + j); Copy() # A
        glyphName = GlyphInfo("Name")
        Select(k); Paste()
        Move(-${move_x_calt_latin}, 0)
        SetWidth(${width_hankaku})
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
        Move(-${move_x_calt_latin}, 0)
        SetWidth(${width_hankaku})
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
            Move(-${move_x_calt_latin}, 0)
            SetWidth(${width_hankaku})
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
            Move(-${move_x_calt_latin}, 0)
            SetWidth(${width_hankaku})
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
        Move(-${move_x_calt_latin}, 0)
        SetWidth(${width_hankaku})
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
    Move(-${move_x_calt_latin}, 0)
    SetWidth(${width_hankaku})
    AddPosSub(lookupSub0, glyphName) # 左←中
    glyphName = GlyphInfo("Name")
    Select(0u1e9e) # ẞ
    AddPosSub(lookupSub1, glyphName) # 左→中
    k += 1

    lookupName = "単純置換 (右・ラテン文字)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)
    j = 0
    while (j < 26)
        Select(0u0041 + j); Copy() # A
        glyphName = GlyphInfo("Name")
        Select(k); Paste()
        Move(${move_x_calt_latin}, 0)
        SetWidth(${width_hankaku})
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
        Move(${move_x_calt_latin}, 0)
        SetWidth(${width_hankaku})
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
            Move(${move_x_calt_latin}, 0)
            SetWidth(${width_hankaku})
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
            Move(${move_x_calt_latin}, 0)
            SetWidth(${width_hankaku})
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
        Move(${move_x_calt_latin}, 0)
        SetWidth(${width_hankaku})
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
    Move(${move_x_calt_latin}, 0)
    SetWidth(${width_hankaku})
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
        Select(${address_store_b_diagram}); Copy() # 保管した▲
        Select(k); Paste()
        Scale(15, 27)
        Move(${move_x_calt_separate}, ${move_y_calt_separate3})
        Copy(); Select(k + 20); Paste() # 12桁用
        Select(0u0030 + j); Copy() # 0
        glyphName = GlyphInfo("Name")
        Select(k); PasteInto()
        SetWidth(${width_hankaku})
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
        Select(${address_store_b_diagram} + 1); Copy() # 保管した▼
        Select(k); Paste()
        Scale(15, 27)
        Move(${move_x_calt_separate}, ${move_y_calt_separate4})
        Copy(); Select(k + 10); PasteInto() # 12桁用
        Select(0u0030 + j); Copy() # 0
        glyphName = GlyphInfo("Name")
        Select(k); PasteInto()
        SetWidth(${width_hankaku})
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
        SetWidth(${width_hankaku})
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
        Scale(${scale_calt_decimal}, ${scale_calt_decimal}, 256, 0)
        SetWidth(${width_hankaku})
 #        AddPosSub(lookupSub0, glyphName) # ノーマル←小数
        glyphName = GlyphInfo("Name")
        Select(0u0030 + j) # 0
        AddPosSub(lookupSub1, glyphName) # 小数←ノーマル
        k += 1
        j += 1
    endloop

    lookupName = "単純置換 (上下)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)

    Select(0u007c); Copy() # |
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(0, ${move_y_calt_bar})
    SetWidth(${width_hankaku})
 #    AddPosSub(lookupSub0, glyphName) # 移動前←後
    glyphName = GlyphInfo("Name")
    Select(0u007c) # |
    AddPosSub(lookupSub1, glyphName) # 移動前→後
    k += 1

    Select(0u007e); Copy() # ~
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(0, ${move_y_calt_tilde})
    SetWidth(${width_hankaku})
 #    AddPosSub(lookupSub0, glyphName) # 移動前←後
    glyphName = GlyphInfo("Name")
    Select(0u007e) # ~
    AddPosSub(lookupSub1, glyphName) # 移動前→後
    k += 1

    Select(0u003a); Copy() # :
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(${move_x_calt_colon}, ${move_y_calt_colon})
    SetWidth(${width_hankaku})
 #    AddPosSub(lookupSub0, glyphName) # 移動前←後
    glyphName = GlyphInfo("Name")
    Select(0u003a) # :
    AddPosSub(lookupSub1, glyphName) # 移動前→後
    k += 1

    lookupName = "単純置換 (上下 2)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)

    Select(0u002a); Copy() # *
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(0, ${move_y_calt_math})
    SetWidth(${width_hankaku})
 #    AddPosSub(lookupSub0, glyphName) # 移動前←後
    glyphName = GlyphInfo("Name")
    Select(0u002a) # *
    AddPosSub(lookupSub1, glyphName) # 移動前→後
    k += 1

    Select(0u002b); Copy() # +
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(0, ${move_y_calt_math})
    SetWidth(${width_hankaku})
 #    AddPosSub(lookupSub0, glyphName) # 移動前←後
    glyphName = GlyphInfo("Name")
    Select(0u002b) # +
    AddPosSub(lookupSub1, glyphName) # 移動前→後
    k += 1

    Select(0u002d); Copy() # -
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(0, ${move_y_calt_math})
    SetWidth(${width_hankaku})
 #    AddPosSub(lookupSub0, glyphName) # 移動前←後
    glyphName = GlyphInfo("Name")
    Select(0u002d) # -
    AddPosSub(lookupSub1, glyphName) # 移動前→後
    k += 1

    Select(0u003d); Copy() # =
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(0, ${move_y_calt_math})
    SetWidth(${width_hankaku})
 #    AddPosSub(lookupSub0, glyphName) # 移動前←後
    glyphName = GlyphInfo("Name")
    Select(0u003d) # =
    AddPosSub(lookupSub1, glyphName) # 移動前→後
    k += 1

    Select(0u007c); Copy() # |
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(0, ${move_y_calt_bar2})
    SetWidth(${width_hankaku})
 #    AddPosSub(lookupSub0, glyphName) # 移動前←後
    glyphName = GlyphInfo("Name")
    Select(0u007c) # |
    AddPosSub(lookupSub1, glyphName) # 移動前→後
    k += 1

    Select(0u003a); Copy() # :
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    Move(${move_x_calt_colon}, ${move_y_calt_colon2})
    SetWidth(${width_hankaku})
 #    AddPosSub(lookupSub0, glyphName) # 移動前←後
    glyphName = GlyphInfo("Name")
    Select(0u003a) # :
    AddPosSub(lookupSub1, glyphName) # 移動前→後
    k += 1

    lookupName = "単純置換 (左・記号)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)

    symb = [0u002a, 0u002b, 0u002d, 0u003d, 0u005f,\
            0u002f, 0u005c, 0u003c, 0u003e,\
            0u0028, 0u0029, 0u005b, 0u005d,\
            0u007b, 0u007d,\
            0u0021, 0u0022, 0u0027, 0u002c,\
            0u002e, 0u003a, 0u003b, 0u003f,\
            0u0060, 0u007c, 0u0000, 0u0001, 0u0002,\
            0u0003, 0u0004] # *+-=_solidus reverse solidus<>()[]{}!quote apostrophe,.:;?grave|、移動した|~:|:
    j = 0
    while (j < SizeOf(symb))
        if (symb[j] == 0u0000) # 移動した |
            Select(${address_calt_barD})
        elseif (symb[j] == 0u0001) # 移動した ~
            Select(${address_calt_barD} + 1)
        elseif (symb[j] == 0u0002) # 移動した :
            Select(${address_calt_barD} + 2)
        elseif (symb[j] == 0u0003) # 移動した |
            Select(${address_calt_barD} + 7)
        elseif (symb[j] == 0u0004) # 移動した :
            Select(${address_calt_barD} + 8)
        else
            Select(symb[j])
        endif
        Copy()
        glyphName = GlyphInfo("Name")
        Select(k); Paste()
        if (j <= 6) # *+-=_solidus reverse solidus
            Move(-${move_x_calt_latin}, 0)
        else
            Move(-${move_x_calt_symbol}, 0)
        endif
        if (symb[j] == 0u0022) # quote
            Move(${move_x_calt_quote}, 0)
        endif
        SetWidth(${width_hankaku})
        AddPosSub(lookupSub0, glyphName) # 左→中
        glyphName = GlyphInfo("Name")
        if (symb[j] == 0u0000) # 移動した |
            Select(${address_calt_barD})
        elseif (symb[j] == 0u0001) # 移動した ~
            Select(${address_calt_barD} + 1)
        elseif (symb[j] == 0u0002) # 移動した :
            Select(${address_calt_barD} + 2)
        elseif (symb[j] == 0u0003) # 移動した |
            Select(${address_calt_barD} + 7)
        elseif (symb[j] == 0u0004) # 移動した :
            Select(${address_calt_barD} + 8)
        else
            Select(symb[j])
        endif
        AddPosSub(lookupSub1, glyphName) # 左←中
        j += 1
        k += 1
    endloop

    lookupName = "単純置換 (右・記号)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)

    j = 0
    while (j < SizeOf(symb))
        if (symb[j] == 0u0000) # 移動した |
            Select(${address_calt_barD})
        elseif (symb[j] == 0u0001) # 移動した ~
            Select(${address_calt_barD} + 1)
        elseif (symb[j] == 0u0002) # 移動した :
            Select(${address_calt_barD} + 2)
        elseif (symb[j] == 0u0003) # 移動した |
            Select(${address_calt_barD} + 7)
        elseif (symb[j] == 0u0004) # 移動した :
            Select(${address_calt_barD} + 8)
        else
            Select(symb[j])
        endif
        Copy()
        glyphName = GlyphInfo("Name")
        Select(k); Paste()
        if (j <= 6) # *+-=_solidus reverse solidus
            Move(${move_x_calt_latin}, 0)
        else
            Move(${move_x_calt_symbol}, 0)
        endif
        if (symb[j] == 0u0022) # quote
            Move(-${move_x_calt_quote}, 0)
        endif
        SetWidth(${width_hankaku})
        AddPosSub(lookupSub0, glyphName) # 左→中
        glyphName = GlyphInfo("Name")
        if (symb[j] == 0u0000) # 移動した |
            Select(${address_calt_barD})
        elseif (symb[j] == 0u0001) # 移動した ~
            Select(${address_calt_barD} + 1)
        elseif (symb[j] == 0u0002) # 移動した :
            Select(${address_calt_barD} + 2)
        elseif (symb[j] == 0u0003) # 移動した |
            Select(${address_calt_barD} + 7)
        elseif (symb[j] == 0u0004) # 移動した :
            Select(${address_calt_barD} + 8)
        else
            Select(symb[j])
        endif
        AddPosSub(lookupSub1, glyphName) # 左←中
        j += 1
        k += 1
    endloop

    lookupName = "単純置換 (エスケープ文字)"
    AddLookup(lookupName, "gsub_single", 0, [], lookups[numlookups - 1])
    lookupSub1 = lookupName + "サブテーブル"
    AddLookupSubtable(lookupName, lookupSub1)

    Select(0u005c); Copy() # reverse solidus
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    SetWidth(${width_hankaku})
 #    AddPosSub(lookupSub0, glyphName) # 変換前←後
    glyphName = GlyphInfo("Name")
    Select(0u005c) # reverse solidus
    AddPosSub(lookupSub1, glyphName) # 変換前→後
    k += 1

    Select(${address_calt_hyphenL} + 6); Copy() # 左に移動した reverse solidus
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    SetWidth(${width_hankaku})
 #    AddPosSub(lookupSub0, glyphName) # 変換前←後
    glyphName = GlyphInfo("Name")
    Select(${address_calt_hyphenL} + 6) # 左に移動した reverse solidus
    AddPosSub(lookupSub1, glyphName) # 変換前→後
    k += 1

    Select(${address_calt_hyphenR} + 6); Copy() # 右に移動した reverse solidus
    glyphName = GlyphInfo("Name")
    Select(k); Paste()
    SetWidth(${width_hankaku})
 #    AddPosSub(lookupSub0, glyphName) # 変換前←後
    glyphName = GlyphInfo("Name")
    Select(${address_calt_hyphenR} + 6) # 右に移動した reverse solidus
    AddPosSub(lookupSub1, glyphName) # 変換前→後
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
        if (j == 14)
            lookupName = "'ss" + ToString(20) + "' スタイルセット" + ToString(20)
            AddLookup(lookupName, "gsub_single", 0, [["ss" + ToString(20),[["DFLT",["dflt"]]]]], lookups[numlookups - 1])
        elseif (j < 10)
            lookupName = "'ss0" + ToString(j) + "' スタイルセット" + ToString(j)
            AddLookup(lookupName, "gsub_single", 0, [["ss0" + ToString(j),[["DFLT",["dflt"]]]]], lookups[numlookups - 1])
        else
            lookupName = "'ss" + ToString(j) + "' スタイルセット" + ToString(j)
            AddLookup(lookupName, "gsub_single", 0, [["ss" + ToString(j),[["DFLT",["dflt"]]]]], lookups[numlookups - 1])
        endif
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
        SetWidth(1024)
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
        SetWidth(${width_hankaku})
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
        SetWidth(${width_hankaku})
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
        SetWidth(${width_hankaku})
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
            Select(${address_store_mod} + ${num_mod_glyphs} * 2) # 縦書きＤ
        elseif (j == 61)
            Select(${address_store_mod} + ${num_mod_glyphs} * 2 + 1) # 縦書きＱ
        elseif (j == 66)
            Select(${address_store_mod} + ${num_mod_glyphs} * 2 + 2) # 縦書きＶ
        elseif (j == 70)
            Select(${address_store_mod} + ${num_mod_glyphs} * 2 + 3) # 縦書きＺ
        else
            Select(${address_store_vert} + l)
        endif
        Copy()
        Select(k); Paste()
        SetWidth(1024)
        glyphName = GlyphInfo("Name")
        Select(${address_vert_bracket} + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
        l += 1
    endloop

    j = 0
    while (j < 159) # 全角半角横書き
        if (j == 35)
            Select(${address_store_mod} + ${num_mod_glyphs}) # Ｄ
        elseif (j == 48)
            Select(${address_store_mod} + ${num_mod_glyphs} + 1) # Ｑ
        elseif (j == 53)
            Select(${address_store_mod} + ${num_mod_glyphs} + 2) # Ｖ
        elseif (j == 57)
            Select(${address_store_mod} + ${num_mod_glyphs} + 3) # Ｚ
        else
            Select(${address_store_vert} + l)
        endif
        Copy()
        Select(k); Paste()
        if (j < 96)
            SetWidth(1024)
        else
            SetWidth(${width_hankaku})
        endif
        glyphName = GlyphInfo("Name")
        Select(0uff01 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
        l += 1
    endloop

    j = 0
    while (j < 7) # ￠-￦
        Select(${address_store_vert} + l); Copy()
        Select(k); Paste()
        SetWidth(1024)
        glyphName = GlyphInfo("Name")
        Select(0uffe0 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
        l += 1
    endloop

    orig = [0u309b, 0u309c, 0u203c, 0u2047,\
            0u2048, 0u2049] # ゛゜‼⁇ ⁈⁉
    j = 0
    while (j < SizeOf(orig))
        if (2 <= j && "${term_flag}" == "true")
            Select(orig[j]); Copy()
            Select(k); Paste()
            SetWidth(${width_hankaku})
        else
            Select(${address_store_vert} + l); Copy()
            Select(k); Paste()
            SetWidth(1024)
        endif
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
        l += 1
    endloop

    j = 0
    while (j < 256) # 点字
        Select(${address_store_braille} + j); Copy()
        Select(k); Paste()
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(0u2800 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

 #      j = 0 # デフォルトで下線無しにする場合
 #      while (j < 109) # 全角縦書き
 #          if (j == 48)
 #              Select(${address_store_mod} + ${num_mod_glyphs} * 5) # 縦書きＤ
 #          elseif (j == 61)
 #              Select(${address_store_mod} + ${num_mod_glyphs} * 5 + 1) # 縦書きＱ
 #          elseif (j == 66)
 #              Select(${address_store_mod} + ${num_mod_glyphs} * 5 + 2) # 縦書きＶ
 #          elseif (j == 70)
 #              Select(${address_store_mod} + ${num_mod_glyphs} * 5 + 3) # 縦書きＺ
 #          else
 #              Select(${address_vert_bracket} + j)
 #          endif
 #          Copy()
 #          Select(k); Paste()
 #          SetWidth(1024)
 #          glyphName = GlyphInfo("Name")
 #          Select(${address_vert_bracket} + j)
 #          AddPosSub(lookupSub, glyphName)
 #          j += 1
 #          k += 1
 #      endloop
 #
 #    j = 0
 #    while (j < 159) # 全角半角横書き
 #        if (j == 35)
 #            Select(${address_store_mod} + ${num_mod_glyphs} * 4) # Ｄ
 #        elseif (j == 48)
 #            Select(${address_store_mod} + ${num_mod_glyphs} * 4 + 1) # Ｑ
 #        elseif (j == 53)
 #            Select(${address_store_mod} + ${num_mod_glyphs} * 4 + 2) # Ｖ
 #        elseif (j == 57)
 #            Select(${address_store_mod} + ${num_mod_glyphs} * 4 + 3) # Ｚ
 #        else
 #            Select(0uff01 + j)
 #        endif
 #        Copy()
 #        Select(k); Paste()
 #        if (j < 96)
 #            SetWidth(1024)
 #        else
 #            SetWidth(${width_hankaku})
 #        endif
 #        glyphName = GlyphInfo("Name")
 #        Select(0uff01 + j)
 #        AddPosSub(lookupSub, glyphName)
 #        j += 1
 #        k += 1
 #    endloop
 #
 #    j = 0
 #    while (j < 7) # ￠-￦
 #        Select(0uffe0 + j); Copy()
 #        Select(k); Paste()
 #        SetWidth(1024)
 #        glyphName = GlyphInfo("Name")
 #        Select(0uffe0 + j)
 #        AddPosSub(lookupSub, glyphName)
 #        j += 1
 #        k += 1
 #    endloop
 #
 #    orig = [0u309b, 0u309c, 0u203c, 0u2047,\
 #            0u2048, 0u2049] # ゛゜‼⁇ ⁈⁉
 #    j = 0
 #    while (j < SizeOf(orig))
 #        Select(orig[j]); Copy()
 #        Select(k); Paste()
 #        if (2 <= j && "${term_flag}" == "true")
 #            SetWidth(${width_hankaku})
 #        else
 #            SetWidth(1024)
 #        endif
 #        glyphName = GlyphInfo("Name")
 #        Select(orig[j])
 #        AddPosSub(lookupSub, glyphName)
 #        j += 1
 #        k += 1
 #    endloop
 #
 #    j = 0
 #    while (j < 256) # 点字
 #        Select(0u2800 + j); Copy()
 #        Select(k); Paste()
 #        SetWidth(${width_hankaku})
 #        glyphName = GlyphInfo("Name")
 #        Select(0u2800 + j)
 #        AddPosSub(lookupSub, glyphName)
 #        j += 1
 #        k += 1
 #    endloop

    ss += 1
# ss07 破線・ウロコ
    lookupName = "'ss0" + ToString(ss) + "' スタイルセット" + ToString(ss)
    lookupSub = lookupName + "サブテーブル"

    orig = [0u2044, 0u007c,\
            0u30a0, 0u2013, 0ufe32, 0u2014, 0ufe31] # ⁄| ゠–︲—︱
    j = 0
    l = 0
    while (j < SizeOf(orig))
        Select(${address_store_visi_latin} + l); Copy()
        Select(k); Paste()
        if (j <= 1 || j == 3)
            SetWidth(${width_hankaku})
        elseif (j == 5 && "${term_flag}" == "true")
            SetWidth(${width_hankaku})
        else
            SetWidth(1024)
        endif
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
        l += 1
    endloop

    j = 0
    while (j < 20) # ➀-➓
        Select(${address_store_visi_latin} + l); Copy()
        Select(k); Paste()
        if ("${term_flag}" == "true")
            SetWidth(${width_hankaku})
        else
            SetWidth(1024)
        endif
        glyphName = GlyphInfo("Name")
        Select(0u2780 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
        l += 1
    endloop

    orig = [0u3007, 0u4e00, 0u4e8c, 0u4e09,\
            0u5de5, 0u529b, 0u5915, 0u535c,\
            0u53e3, 0u4e8e, 0u4e95, 0u5b50] # 〇一二三 工力夕卜 口于井子
    j = 0
    while (j < SizeOf(orig))
        Select(${address_store_visi_latin} + l); Copy()
        Select(k); Paste()
        SetWidth(1024)
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
        l += 1
    endloop

    Select(${address_store_d_hyphen}); Copy() # 縦書き゠
    Select(k); Paste()
    SetWidth(1024)
    glyphName = GlyphInfo("Name")
    Select(${address_vert_dh})
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(${address_store_visi_latin} + 1); Copy() # 左に移動した |
    Select(k); Paste()
    Move(-${move_x_calt_symbol}, 0)
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_calt_hyphenL} + ${address_calt_barDLR})
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(${address_store_visi_latin} + 1); Copy() # 右に移動した |
    Select(k); Paste()
    Move(${move_x_calt_symbol}, 0)
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_calt_hyphenR} + ${address_calt_barDLR})
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(${address_store_visi_latin} + 1); Copy() # 下に移動した |
    Select(k); Paste()
    Move(0, ${move_y_calt_bar})
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_calt_barD})
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(${address_store_visi_latin} + 1); Copy() # 左下に移動した |
    Select(k); Paste()
    Move(-${move_x_calt_symbol}, ${move_y_calt_bar})
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_calt_hyphenL} + ${address_calt_barDLR} + 1)
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(${address_store_visi_latin} + 1); Copy() # 右下に移動した |
    Select(k); Paste()
    Move(${move_x_calt_symbol}, ${move_y_calt_bar})
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_calt_hyphenR} + ${address_calt_barDLR} + 1)
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(${address_store_visi_latin} + 1); Copy() # 上に移動した | (括弧用)
    Select(k); Paste()
    Move(0, ${move_y_calt_bar2})
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_calt_barD} + 7)
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(${address_store_visi_latin} + 1); Copy() # 左上に移動した | (括弧用)
    Select(k); Paste()
    Move(-${move_x_calt_symbol}, ${move_y_calt_bar2})
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_calt_hyphenL} + ${address_calt_barDLR} + 4)
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(${address_store_visi_latin} + 1); Copy() # 右上に移動した | (括弧用)
    Select(k); Paste()
    Move(${move_x_calt_symbol}, ${move_y_calt_bar2})
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_calt_hyphenR} + ${address_calt_barDLR} + 4)
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(k); Clear(); SetWidth(${width_hankaku}) # ダミー (リガチャ対応フォントとアドレスを合わせるため(最大2個))
    k += 1
    Select(k); Clear(); SetWidth(${width_hankaku}) # ダミー (リガチャ対応フォントとアドレスを合わせるため(最大2個))
    k += 1

    ss += 1
# ss08 DQVZ
    lookupName = "'ss0" + ToString(ss) + "' スタイルセット" + ToString(ss)
    lookupSub = lookupName + "サブテーブル"

    orig = [0u0044, 0u0051, 0u0056, 0u005A] # DQVZ
    num = [3, 16, 21, 25] # 左に移動したAからDQVZまでの数
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(k); Paste()
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < SizeOf(orig)) # 左に移動したDQVZ
        Select(orig[j]); Copy()
        Select(k); Paste()
        Move(-${move_x_calt_latin}, 0)
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(${address_calt_AL} + num[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < SizeOf(orig)) # 右に移動したDQVZ
        Select(orig[j]); Copy()
        Select(k); Paste()
        Move(${move_x_calt_latin}, 0)
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(${address_calt_AR} + num[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

 # (デフォルトで下線無しにする場合はコメントアウトを変更し、glyphName を付加する Select 対象を変える)
    orig = [0uff24, 0uff31, 0uff36, 0uff3a] # 全角横書きDQVZ
    num0 = [35, 48, 53, 57] # 全角横書きDQVZ ！から全角DQVZまでの数
    num1 = [48, 61, 66, 70] # 全角縦書きDQVZ （から全角DQVZまでの数

    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy() # 下線付き横書き
        Select(k); Paste()
        SetWidth(1024)
        glyphName = GlyphInfo("Name")
        Select(orig[j]) # 変換前横書き
 #        Select(${address_ss_zenhan} + num0[j]) # ss変換後横書き
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < SizeOf(orig))
        Select(${address_vert_bracket} + num1[j]); Copy() # 下線付き縦書き
        Select(k); Paste()
        SetWidth(1024)
        glyphName = GlyphInfo("Name")
        Select(${address_vert_bracket} + num1[j]) # vert変換後ss変換前縦書き
 #        Select(${address_ss_vert} + num1[j]) # ss変換後縦書き
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < SizeOf(orig))
        Select(${address_store_vert} + num1[j]); Copy() # 下線無し全角
        Select(k); Paste()
        SetWidth(1024)
        glyphName = GlyphInfo("Name")
        Select(${address_ss_zenhan} + num0[j]) # ss変換後横書き
 #        Select(orig[j]) # 変換前横書き
        AddPosSub(lookupSub, glyphName)
        Select(${address_ss_vert} + num1[j]) # ss変換後縦書き
 #        Select(${address_vert_bracket} + num1[j]) # vert変換後ss変換前縦書き
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    ss += 1
# ss09 罫線
    lookupName = "'ss0" + ToString(ss) + "' スタイルセット" + ToString(ss)
    lookupSub = lookupName + "サブテーブル"

    line = [0u2500, 0u2501, 0u2502, 0u2503, 0u250c, 0u250f,\
            0u2510, 0u2513, 0u2514, 0u2517, 0u2518, 0u251b, 0u251c, 0u251d,\
            0u2520, 0u2523, 0u2524, 0u2525, 0u2528, 0u252b, 0u252c, 0u252f,\
            0u2530, 0u2533, 0u2534, 0u2537, 0u2538, 0u253b, 0u253c, 0u253f,\
            0u2542, 0u254b] # 全角罫線
    j = 0
    while (j < SizeOf(line))
        Select(${address_store_line} + j); Copy()
        Select(k); Paste()
        SetWidth(1024)
        glyphName = GlyphInfo("Name")
        Select(line[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    arrow = [0u2190, 0u2191, 0u2192, 0u2193] # ←↑→↓
    j = 0
    while (j < SizeOf(arrow))
        Select(${address_store_arrow} + j); Copy()
        Select(k); Paste()
        SetWidth(1024)
        glyphName = GlyphInfo("Name")
        Select(arrow[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    ss += 1
# ss10 スラッシュ無し0
    lookupName = "'ss" + ToString(ss) + "' スタイルセット" + ToString(ss)
    lookupSub = lookupName + "サブテーブル"

    zero = [0u0030, 0u2070, 0u2080] # 0⁰₀
    j = 0
    while (j < SizeOf(zero))
        Select(${address_store_zero} + j); Copy()
        Select(k); Paste()
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(zero[j])
        AddPosSub(lookupSub, glyphName)
        if (j == 0)
            Select(${address_calt_figure}) # caltで変換したグリフ (3桁) からの変換
            AddPosSub(lookupSub, glyphName)
            Select(${address_calt_figure} + 10) # caltで変換したグリフ (4桁) からの変換
            AddPosSub(lookupSub, glyphName)
            Select(${address_calt_figure} + 20) # caltで変換したグリフ (12桁) からの変換
            AddPosSub(lookupSub, glyphName)
            Select(${address_calt_figure} + 30) # caltで変換したグリフ (小数) からの変換
            AddPosSub(lookupSub, glyphName)
        endif
        j += 1
        k += 1
    endloop

    # 3桁区切り
    Select(${address_store_b_diagram}); Copy() # 保管した▲
    Select(k); Paste()
    Scale(15, 27)
    Move(${move_x_calt_separate}, ${move_y_calt_separate3})
    Copy(); Select(k + 2); Paste() # 12桁用
    Select(${address_store_zero}); Copy()
    Select(k); PasteInto()
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_ss_figure}) # ssで変換したグリフからの変換
    AddPosSub(lookupSub, glyphName)
    Select(${address_ss_figure} + 40) # ssで変換したグリフ (3桁に偽装した12桁) からの変換
    AddPosSub(lookupSub, glyphName)
    k += 1

    # 4桁区切り
    Select(${address_store_b_diagram} + 1); Copy() # 保管した▼
    Select(k); Paste()
    Scale(15, 27)
    Move(${move_x_calt_separate}, ${move_y_calt_separate4})
    Copy(); Select(k + 1); PasteInto() # 12桁用
    Select(${address_store_zero}); Copy()
    Select(k); PasteInto()
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_ss_figure} + 10) # ssで変換したグリフからの変換
    AddPosSub(lookupSub, glyphName)
    k += 1

    # 12桁区切り
    Select(${address_store_zero}); Copy()
    Select(k); PasteInto()
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_ss_figure} + 20) # ssで変換したグリフからの変換
    AddPosSub(lookupSub, glyphName)
    k += 1

    # 小数
    Select(${address_store_zero}); Copy() # スラッシュ無し0
    Select(k); Paste()
    Scale(${scale_calt_decimal}, ${scale_calt_decimal}, 256, 0)
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_ss_figure} + 30) # ssで変換したグリフからの変換
    AddPosSub(lookupSub, glyphName)
    k += 1

    # 全角
    # (デフォルトで下線無しにする場合はコメントアウトを変更し、glyphName を付加する Select 対象を変える)

    Select(${address_store_zero} + 4); Copy() # 下線付き横書き
    Select(k); Paste()
    SetWidth(1024)
    glyphName = GlyphInfo("Name")
    Select(0uff10) # 変換前横書き
 #    Select(${address_ss_zenhan} + 15) # ss変換後横書き
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(${address_store_zero} + 5); Copy() # 下線付き縦書き
    Select(k); Paste()
    SetWidth(1024)
    glyphName = GlyphInfo("Name")
    Select(${address_vert_bracket} + 33) # vert変換後ss変換前縦書き
 #    Select(${address_ss_vert} + 33) # ss変換後縦書き
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(${address_store_zero} + 3); Copy() # 下線無し全角
    Select(k); Paste()
    SetWidth(1024)
    glyphName = GlyphInfo("Name")
    Select(${address_ss_zenhan} + 15) # ss変換後横書き
 #    Select(0uff10) # 変換前横書き
    AddPosSub(lookupSub, glyphName)
    Select(${address_ss_vert} + 33) # ss変換後縦書き
 #    Select(${address_vert_bracket} + 33) # vert変換後ss変換前縦書き
    AddPosSub(lookupSub, glyphName)
    k += 1

    ss += 1
# ss11 その他のスペース可視化
    lookupName = "'ss" + ToString(ss) + "' スタイルセット" + ToString(ss)
    lookupSub = lookupName + "サブテーブル"

    Select(${address_store_otherspace}); Copy() # その他の全角スペース
    Select(k); Paste()

    spc =[\
    0u2001,\
    0u2003\
    ]
    j = 0
    while (j < SizeOf(spc))
        Select(k)
        glyphName = GlyphInfo("Name")
        Select(spc[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
    endloop
    k += 1

    Select(${address_store_otherspace} + 1); Copy() # その他の半角・幅無しスペース
    Select(k); Paste()

    spc =[\
    0u034f,\
    0u2000,\
    0u2002,\
    0u2004,\
    0u2005,\
    0u2006,\
    0u2007,\
    0u2008,\
    0u2009,\
    0u200a,\
    0u200b,\
    0u200c,\
    0u200d,\
    0u202f,\
    0u205f,\
    0u2060,\
    0ufeff\
    ]
    j = 0
    while (j < SizeOf(spc))
        Select(k)
        glyphName = GlyphInfo("Name")
        Select(spc[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
    endloop
    k += 1

    ss += 1
# ss12 一部のあいまい文字等を半角化
    lookupName = "'ss" + ToString(ss) + "' スタイルセット" + ToString(ss)
    lookupSub = lookupName + "サブテーブル"

    orig = [0u2025, 0u2026] # ‥…
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose}, 100, ${width_zenkaku} / 2, 0)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
            Copy()
            PasteWithOffset(-10 * ${width_hankaku_loose} / ${width_hankaku}, 0)
            PasteWithOffset( 10 * ${width_hankaku_loose} / ${width_hankaku}, 0)
            RemoveOverlap()
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    orig = [0u203b] # ※
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose}, 100, ${width_zenkaku} / 2, 0)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    orig = [0u2103, 0u2109] # ℃℉
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 1.2, 100, ${width_zenkaku} / 2, 0)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < 12)
        Select(0u2160 + j); Copy() # Ⅰ-Ⅻ
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose}, 100, ${width_zenkaku} / 2, 0)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(0u2160 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < 12)
        Select(0u2170 + j); Copy() # ⅰ-ⅻ
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose}, 100, ${width_zenkaku} / 2, 0)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(0u2170 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < 6)
        Select(0u2190 + j); Copy() # ←-↕
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 1.1, ${width_zenkaku} / 2, 340)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
            ChangeWeight(9)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(0u2190 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < 6)
        Select(0u21d0 + j); Copy() # ⇐-⇕
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 1.1, ${width_zenkaku} / 2, 340)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
            ChangeWeight(9)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(0u21d0 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < 20)
        Select(0u2460 + j); Copy() # ①-⑳
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 0.95, 100, ${width_zenkaku} / 2, 0)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(0u2460 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < 11)
        Select(0u24ea + j); Copy() # ⓪-⓴
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 0.95, 100, ${width_zenkaku} / 2, 0)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(0u24ea + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    orig = [0u24ff] # ⓿
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 0.95, 100, ${width_zenkaku} / 2, 0)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    orig = [0u25a0, 0u25a1,\
            0u25b2, 0u25b3,\
            0u25b6, 0u25b7,\
            0u25bc, 0u25bd,\
            0u25c0, 0u25c1,\
            0u25c6, 0u25c7,\
            0u25cb,\
            0u25ce, 0u25cf,\
            0u25ef,\
            0u2605, 0u2606\
            ] # ■□ ▲△ ▶▷ ▼▽ ◀◁ ◆◇ ○ ◎● ◯ ★☆
    j = 0
    while (j < SizeOf(orig))
        Select(orig[j]); Copy()
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose}, ${width_zenkaku} / 2, 340)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < 8)
        Select(0u2660 + j); Copy() # ♠-♧
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 1.1, 100, ${width_zenkaku} / 2, 0)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(0u2660 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < 7)
        Select(0u2669 + j); Copy() # ♩-♯
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 1.2, 100, ${width_zenkaku} / 2, 0)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(0u2669 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    j = 0
    while (j < 10)
        Select(0u2776 + j); Copy() # ❶-❿
        Select(k); Paste()
        if (600 <= GlyphInfo("Width"))
            Scale(${scale_zenkaku2hankaku} * ${width_hankaku} / ${width_hankaku_loose} * 0.95, 100, ${width_zenkaku} / 2, 0)
            Move(-(${width_zenkaku} / 2 - ${width_hankaku} / 2), 0)
        endif
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(0u2776 + j)
        AddPosSub(lookupSub, glyphName)
        j += 1
        k += 1
    endloop

    ss += 1
# ss13 エスケープ文字を細線化
    lookupName = "'ss" + ToString(ss) + "' スタイルセット" + ToString(ss)
    lookupSub = lookupName + "サブテーブル"

    Select(${address_store_escape}); Copy() # 加工した reverse solidus
    Select(k); Paste()
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(0u005c) # reverse solidus
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(${address_store_escape}); Copy() # 加工した reverse solidus
    Select(k); Paste()
    Move(-${move_x_calt_latin}, 0)
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_calt_hyphenL} + 6) # 左に移動した reverse solidus
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(${address_store_escape}); Copy() # 加工した reverse solidus
    Select(k); Paste()
    Move(${move_x_calt_latin}, 0)
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_calt_hyphenR} + 6) # 右に移動した reverse solidus
    AddPosSub(lookupSub, glyphName)
    k += 1

    ss = 20
# ss20 ドット0
    lookupName = "'ss" + ToString(ss) + "' スタイルセット" + ToString(ss)
    lookupSub = lookupName + "サブテーブル"

    zero = [0u0030, 0u2070, 0u2080] # 0⁰₀
    j = 0
    while (j < SizeOf(zero))
        Select(${address_store_zero} + j + 6); Copy()
        Select(k); Paste()
        SetWidth(${width_hankaku})
        glyphName = GlyphInfo("Name")
        Select(zero[j])
        AddPosSub(lookupSub, glyphName)
        if (j == 0)
            Select(${address_calt_figure}) # caltで変換したグリフ (3桁) からの変換
            AddPosSub(lookupSub, glyphName)
            Select(${address_calt_figure} + 10) # caltで変換したグリフ (4桁) からの変換
            AddPosSub(lookupSub, glyphName)
            Select(${address_calt_figure} + 20) # caltで変換したグリフ (12桁) からの変換
            AddPosSub(lookupSub, glyphName)
            Select(${address_calt_figure} + 30) # caltで変換したグリフ (小数) からの変換
            AddPosSub(lookupSub, glyphName)
        endif
        j += 1
        k += 1
    endloop

    # 3桁区切り
    Select(${address_store_b_diagram}); Copy() # 保管した▲
    Select(k); Paste()
    Scale(15, 27)
    Move(${move_x_calt_separate}, ${move_y_calt_separate3})
    Copy(); Select(k + 2); Paste() # 12桁用
    Select(${address_store_zero} + 6); Copy()
    Select(k); PasteInto()
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_ss_figure}) # ssで変換したグリフからの変換
    AddPosSub(lookupSub, glyphName)
    Select(${address_ss_figure} + 40) # ssで変換したグリフ (3桁に偽装した12桁) からの変換
    AddPosSub(lookupSub, glyphName)
    k += 1

    # 4桁区切り
    Select(${address_store_b_diagram} + 1); Copy() # 保管した▼
    Select(k); Paste()
    Scale(15, 27)
    Move(${move_x_calt_separate}, ${move_y_calt_separate4})
    Copy(); Select(k + 1); PasteInto() # 12桁用
    Select(${address_store_zero} + 6); Copy()
    Select(k); PasteInto()
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_ss_figure} + 10) # ssで変換したグリフからの変換
    AddPosSub(lookupSub, glyphName)
    k += 1

    # 12桁区切り
    Select(${address_store_zero} + 6); Copy()
    Select(k); PasteInto()
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_ss_figure} + 20) # ssで変換したグリフからの変換
    AddPosSub(lookupSub, glyphName)
    k += 1

    # 小数
    Select(${address_store_zero} + 6); Copy() # ドット0
    Select(k); Paste()
    Scale(${scale_calt_decimal}, ${scale_calt_decimal}, 256, 0)
    SetWidth(${width_hankaku})
    glyphName = GlyphInfo("Name")
    Select(${address_ss_figure} + 30) # ssで変換したグリフからの変換
    AddPosSub(lookupSub, glyphName)
    k += 1

    # 全角
    # (デフォルトで下線無しにする場合はコメントアウトを変更し、glyphName を付加する Select 対象を変える)

    Select(${address_store_zero} + 4 + 6); Copy() # 下線付き横書き
    Select(k); Paste()
    SetWidth(1024)
    glyphName = GlyphInfo("Name")
    Select(0uff10) # 変換前横書き
 #    Select(${address_ss_zenhan} + 15) # ss変換後横書き
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(${address_store_zero} + 5 + 6); Copy() # 下線付き縦書き
    Select(k); Paste()
    SetWidth(1024)
    glyphName = GlyphInfo("Name")
    Select(${address_vert_bracket} + 33) # vert変換後ss変換前縦書き
 #    Select(${address_ss_vert} + 33) # ss変換後縦書き
    AddPosSub(lookupSub, glyphName)
    k += 1

    Select(${address_store_zero} + 3 + 6); Copy() # 下線無し全角
    Select(k); Paste()
    SetWidth(1024)
    glyphName = GlyphInfo("Name")
    Select(${address_ss_zenhan} + 15) # ss変換後横書き
 #    Select(0uff10) # 変換前横書き
    AddPosSub(lookupSub, glyphName)
    Select(${address_ss_vert} + 33) # ss変換後縦書き
 #    Select(${address_vert_bracket} + 33) # vert変換後ss変換前縦書き
    AddPosSub(lookupSub, glyphName)
    k += 1

# aalt 対応
    Print("Add aalt lookups")
# aalt 1対1
    Select(0u342e) # 㐮
    lookups = GetPosSub("*") # フィーチャを取り出す

 #    Select(0u1b001) # 𛀁
 #    glyphName = GlyphInfo("Name")
 #    Select(0u3048) # え
 #    AddPosSub(lookups[0][0],glyphName) # aaltフィーチャを追加
 #    glyphName = GlyphInfo("Name")
 #    Select(0u1b001) # 𛀁
 #    AddPosSub(lookups[0][0],glyphName) # aaltフィーチャを追加

    Select(0u1b127) # 𛄧
    glyphName = GlyphInfo("Name")
    Select(0u30cd) # ネ
    AddPosSub(lookups[0][0],glyphName) # aaltフィーチャを追加
    glyphName = GlyphInfo("Name")
    Select(0u1b127) # 𛄧
    AddPosSub(lookups[0][0],glyphName) # aaltフィーチャを追加

    Select(0u1b128) # 𛄨
    glyphName = GlyphInfo("Name")
    Select(0u30f0) # ヰ
    AddPosSub(lookups[0][0],glyphName) # aaltフィーチャを追加
    glyphName = GlyphInfo("Name")
    Select(0u1b128) # 𛄨
    AddPosSub(lookups[0][0],glyphName) # aaltフィーチャを追加

   orig = [0u0041, 0u0042, 0u0044, 0u0045,\
            0u0047, 0u0048, 0u0049, 0u004a,\
            0u004b, 0u004c, 0u004d, 0u004e,\
            0u004f, 0u0050, 0u0052, 0u0054,\
            0u0055, 0u0056, 0u0057] # ABDE GHIJ KLMN OPRT UVW
    supb = [0u1d2c, 0u1d2e, 0u1d30, 0u1d31,\
            0u1d33, 0u1d34, 0u1d35, 0u1d36,\
            0u1d37, 0u1d38, 0u1d39, 0u1d3a,\
            0u1d3c, 0u1d3e, 0u1d3f, 0u1d40,\
            0u1d41, 0u2c7d, 0u1d42] # ᴬᴮᴰᴱ ᴳᴴᴵᴶ ᴷᴸᴹᴺ ᴼᴾᴿᵀ ᵁⱽᵂ
    j = 0
    while (j < SizeOf(orig))
        Select(supb[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        j += 1
    endloop

    orig = [0u0062, 0u0063, 0u0064, 0u0066,\
            0u0067, 0u0077, 0u0079, 0u007a] # bcdf gwyz
    supb = [0u1d47, 0u1d9c, 0u1d48, 0u1da0,\
            0u1d4d, 0u02b7, 0u02b8, 0u1dbb] # ᵇᶜᵈᶠ ᵍʷʸᶻ
    j = 0
    while (j < SizeOf(orig))
        Select(supb[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        j += 1
    endloop

    orig = [0u00c6, 0u00f0, 0u018e, 0u014b,\
            0u03b4, 0u03b8, 0u03c1] # ÆðƎŋ δθρ
    supb = [0u1d2d, 0u1d9e, 0u1d32, 0u1d51,\
            0u1d5f, 0u1dbf, 0u1d68] # ᴭᶞᴲᵑ ᵟᶿᵨ

    j = 0
    while (j < SizeOf(orig))
        Select(supb[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        j += 1
    endloop

    orig = [0u0250, 0u0251, 0u0252, 0u0254,\
            0u0255, 0u025b, 0u025c, 0u025f,\
            0u0261, 0u0265, 0u0268, 0u0269,\
            0u026a, 0u026d, 0u026f, 0u0270,\
            0u0271, 0u0272, 0u0273, 0u0274,\
            0u0275, 0u0278, 0u0282, 0u0283,\
            0u0289, 0u028a, 0u028b, 0u028c,\
            0u0290, 0u0291, 0u0292, 0u029d,\
            0u029f, 0u0266, 0u0279, 0u027b,\
            0u0281, 0u0294, 0u0295, 0u0263,\
            0u043d]
            # ɐɑɒɔ ɕɛɜɟ ɡɥɨɩ ɪɭɯɰ ɱɲɳɴ ɵɸʂʃ ʉʊʋʌ ʐʑʒʝ ʟɦɹɻ ʁʔʕɣ н
    supb = [0u1d44, 0u1d45, 0u1d9b, 0u1d53,\
            0u1d9d, 0u1d4b, 0u1d9f, 0u1da1,\
            0u1da2, 0u1da3, 0u1da4, 0u1da5,\
            0u1da6, 0u1da9, 0u1d5a, 0u1dad,\
            0u1dac, 0u1dae, 0u1daf, 0u1db0,\
            0u1db1, 0u1db2, 0u1db3, 0u1db4,\
            0u1db6, 0u1db7, 0u1db9, 0u1dba,\
            0u1dbc, 0u1dbd, 0u1dbe, 0u1da8,\
            0u1dab, 0u02b1, 0u02b4, 0u02b5,\
            0u02b6, 0u02c0, 0u02c1, 0u02e0,\
           0u1d78]
            # ᵄᵅᶛᵓ ᶝᵋᶟᶡ ᶢᶣᶤᶥ ᶦᶩᵚᶭ ᶬᶮᶯᶰ ᶱᶲᶳᶴ ᶶᶷᶹᶺ ᶼᶽᶾᶨ ᶫʱʴʵ ʶˀˁˠ ᵸ
    j = 0
    while (j < SizeOf(orig))
        Select(supb[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        j += 1
    endloop

 #    orig = [0u1d16, 0u1d17, 0u1d1d, 0u1d7b,\
 #            0u1d85, 0u01ab] # ᴖᴗᴝᵻ ᶅƫ
 #    supb = [0u1d54, 0u1d55, 0u1d59, 0u1da7,\
 #            0u1daa, 0u1db5] # ᵔᵕᵙᶧ ᶪᶵ
 #    j = 0
 #    while (j < SizeOf(orig))
 #        Select(supb[j])
 #        glyphName = GlyphInfo("Name")
 #        Select(orig[j])
 #        AddPosSub(lookups[0][0],glyphName)
 #        j += 1
 #    endloop

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

 #    Select(0u32d3) # ㋓
 #    glyphName = GlyphInfo("Name")
 #    Select(0u30a8) # エ
 #    AddPosSub(lookups[0][0],glyphName) # aaltフィーチャを追加
 #    Select(0u1b000) # 𛀀
 #    glyphName = GlyphInfo("Name")
 #    Select(0u30a8) # エ
 #    AddPosSub(lookups[0][0],glyphName) # aaltフィーチャを追加
 #    Select(0u1b121) # 𛄡
 #    glyphName = GlyphInfo("Name")
 #    Select(0u30a8) # エ
 #    AddPosSub(lookups[0][0],glyphName) # aaltフィーチャを追加

 #    Select(0u30a8) # エ
 #    glyphName = GlyphInfo("Name")
 #    Select(0u1b000) # 𛀀
 #    AddPosSub(lookups[0][0],glyphName) # aaltフィーチャを追加

 #    Select(0u30a8) # エ
 #    glyphName = GlyphInfo("Name")
 #    Select(0u1b121) # 𛄡
 #    AddPosSub(lookups[0][0],glyphName) # aaltフィーチャを追加

    orig = [0u0030, 0u0031, 0u0032, 0u0033,\
            0u0034, 0u0035, 0u0036, 0u0037,\
            0u0038, 0u0039,\
            0u002b, 0u002d, 0u003d, 0u0028, 0u0029] # 0-9,+-=()
    sups = [0u2070, 0u00b9, 0u00b2, 0u00b3,\
            0u2074, 0u2075, 0u2076, 0u2077,\
            0u2078, 0u2079,\
            0u207a, 0u207b, 0u207c, 0u207d, 0u207e] # ⁰-⁹,⁺⁻⁼⁽⁾
    subs = [0u2080, 0u2081, 0u2082, 0u2083,\
            0u2084, 0u2085, 0u2086, 0u2087,\
            0u2088, 0u2089,\
            0u208a, 0u208b, 0u208c, 0u208d, 0u208e] # ₀-₉,₊₋₌₍₎
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

    orig = [0u0061, 0u0065, 0u0068, 0u0069,\
            0u006a, 0u006b, 0u006c, 0u006d,\
            0u006e, 0u006f, 0u0070, 0u0072,\
            0u0073, 0u0074, 0u0075, 0u0076,\
            0u0078] # aehi jklm nopr stuv x
    sups = [0u1d43, 0u1d49, 0u02b0, 0u2071,\
            0u02b2, 0u1d4f, 0u02e1, 0u1d50,\
            0u207f, 0u1d52, 0u1d56, 0u02b3,\
            0u02e2, 0u1d57, 0u1d58, 0u1d5b,\
            0u02e3] # ᵃᵉʰⁱ ʲᵏˡᵐ ⁿᵒᵖʳ ˢᵗᵘᵛ ˣ
    subs = [0u2090, 0u2091, 0u2095, 0u1d62,\
            0u2c7c, 0u2096, 0u2097, 0u2098,\
            0u2099, 0u2092, 0u209a, 0u1d63,\
            0u209b, 0u209c, 0u1d64, 0u1d65,\
            0u2093] # ₐₑₕᵢ ⱼₖₗₘ ₙₒₚᵣ ₛₜᵤᵥ ₓ
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

    orig = [0u0061, 0u006f] # ao
    sups = [0u00aa, 0u00ba] # ªº
    j = 0
    while (j < SizeOf(orig))
        Select(sups[j])
        glyphName = GlyphInfo("Name")
        Select(orig[j])
        AddPosSub(lookups[0][0],glyphName)
        j += 1
    endloop

    orig = [0u03b2, 0u03b3, 0u03c6, 0u03c7, 0u0259] # βγφχə
    sups = [0u1d5d, 0u1d5e, 0u1d60, 0u1d61, 0u1d4a] # ᵝᵞᵠᵡᵊ
    subs = [0u1d66, 0u1d67, 0u1d69, 0u1d6a, 0u2094] # ᵦᵧᵩᵪₔ

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

    Select(0u2117) # ℗
    glyphName = GlyphInfo("Name")
    Select(0u0050) # P
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)

    Select(0u00ae) # ®
    glyphName = GlyphInfo("Name")
    Select(0u0052) # R
    AddPosSub(lookups[0][0],glyphName)
    AddPosSub(lookups[1][0],glyphName)

    orig = 0uff21 # Ａ
    circ = 0u24b6 # Ⓐ
    j = 0
    while (j < 26)
        Select(circ + j)
        glyphName = GlyphInfo("Name")
        Select(orig + j)
        AddPosSub(lookups[0][0],glyphName)
        AddPosSub(lookups[1][0],glyphName)
        j += 1
    endloop

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
 #        if (j != 3) # エは𛀀𛄡があるため複数、前のルーチンで処理済 (𛀀𛄡はエの異体字では無いため無効化)
            AddPosSub(lookups[1][0],glyphName)
 #        endif
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

    orig = 0uff11 # １
    circ = 0u2460 # ①
    pare = 0u2474 # ⑴
    peri = 0u2488 # ⒈
    cir2 = 0u24f5 # ⓵
    cirN = 0u2776 # ❶
    cirS = 0u2780 # ➀
    ciSN = 0u278a # ➊
    j = 0
    while (j < 9)
        Select(circ + j)
        glyphName = GlyphInfo("Name")
        Select(orig + j)
        AddPosSub(lookups[0][0],glyphName)
        AddPosSub(lookups[1][0],glyphName)
        Select(pare + j)
        glyphName = GlyphInfo("Name")
        Select(orig + j)
        AddPosSub(lookups[0][0],glyphName)
        AddPosSub(lookups[1][0],glyphName)
        Select(peri + j)
        glyphName = GlyphInfo("Name")
        Select(orig + j)
        AddPosSub(lookups[0][0],glyphName)
        AddPosSub(lookups[1][0],glyphName)
        Select(cir2 + j)
        glyphName = GlyphInfo("Name")
        Select(orig + j)
        AddPosSub(lookups[0][0],glyphName)
        AddPosSub(lookups[1][0],glyphName)
        Select(cirN + j)
        glyphName = GlyphInfo("Name")
        Select(orig + j)
        AddPosSub(lookups[0][0],glyphName)
        AddPosSub(lookups[1][0],glyphName)
        Select(cirS + j)
        glyphName = GlyphInfo("Name")
        Select(orig + j)
        AddPosSub(lookups[0][0],glyphName)
        AddPosSub(lookups[1][0],glyphName)
        Select(ciSN + j)
        glyphName = GlyphInfo("Name")
        Select(orig + j)
        AddPosSub(lookups[0][0],glyphName)
        AddPosSub(lookups[1][0],glyphName)
        j += 1
    endloop

    orig = 0uff41 # ａ
    pare = 0u249c # ⒜
    circ = 0u24d0 # ⓐ
    j = 0
    while (j < 26)
        Select(pare + j)
        glyphName = GlyphInfo("Name")
        Select(orig + j)
        AddPosSub(lookups[0][0],glyphName)
        AddPosSub(lookups[1][0],glyphName)
        Select(circ + j)
        glyphName = GlyphInfo("Name")
        Select(orig + j)
        AddPosSub(lookups[0][0],glyphName)
        AddPosSub(lookups[1][0],glyphName)
        j += 1
    endloop

# .notdef加工
    Print("Edit .notdef")
    Select(1114112)
    Move(86, 0)
    SetWidth(${width_hankaku})

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

# Proccess before saving
    Print("Process before saving")
    SelectWorthOutputting()
    SetGlyphClass("automatic")

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
    Print("Transform glyphs (it may take a few minutes)")
    SelectWorthOutputting()
    SelectFewer(0u0020) # 半角スペース
    SelectFewer(0u00a0) # ノーブレークスペース
# SelectFewer(0u2000, 0u2140) # 文字様記号
    SelectFewer(0u2102) # ℂ
    SelectFewer(0u210d) # ℍ
    SelectFewer(0u2115) # ℕ
    SelectFewer(0u2119) # ℙ
    SelectFewer(0u211a) # ℚ
    SelectFewer(0u211d) # ℝ
    SelectFewer(0u2124) # ℤ
    SelectFewer(0u212e) # ℮
    SelectFewer(0u213c, 0u2140) # ℼℽℾℿ⅀
    SelectFewer(0u2145, 0u2149) # ⅅⅆⅇⅈⅉ
# SelectFewer(0u2190, 0u21ff) # 矢印
    SelectFewer(0u2191) # ↑
    SelectFewer(0u2193) # ↓
    SelectFewer(0u2195, 0u2199) # ↕↖↗↘↙
    SelectFewer(0u219f) # ↟
    SelectFewer(0u21a1) # ↡
    SelectFewer(0u21a5) # ↥
    SelectFewer(0u21a7, 0u21a8) # ↧↨
    SelectFewer(0u21b8) # ↸
    SelectFewer(0u21be, 0u21bf) # ↾↿
    SelectFewer(0u21c2, 0u21c3) # ⇂⇃
    SelectFewer(0u21c5) # ⇅
    SelectFewer(0u21c8) # ⇈
    SelectFewer(0u21ca) # ⇊
    SelectFewer(0u21d1) # ⇑
    SelectFewer(0u21d3) # ⇓
    SelectFewer(0u21d5, 0u21d9) # ⇕⇖⇗⇘⇙
    SelectFewer(0u21de, 0u21df) # ⇞⇟
    SelectFewer(0u21e1) # ⇡
    SelectFewer(0u21e3) # ⇣
    SelectFewer(0u21e7) # ⇧
    SelectFewer(0u21e9, 0u21ef) # ⇩⇪⇫⇬⇭⇮⇯
    SelectFewer(0u21f1, 0u21f3) # ⇱⇲⇳
    SelectFewer(0u21f5) # ⇵
# SelectFewer(0u2200, 0u22ff) # 数学記号
    SelectFewer(0u221f, 0u2222) # ∟∠∡∢
    SelectFewer(0u2225, 0u2226) # ∥∦
 #    SelectFewer(0u2295, 0u22a1) # ⊕ - ⊡
    SelectFewer(0u22a2, 0u22a5) # ⊢ - ⊥
 #    SelectFewer(0u22a6, 0u22af) # ⊦ - ⊯
 #    SelectFewer(0u22b6, 0u22b8) # ⊶ - ⊸
    SelectFewer(0u22be, 0u22bf) # ⊾⊿
 #    SelectFewer(0u22c8, 0u22cc) # ⋈⋉⋊⋋⋌
 #    SelectFewer(0u22ee, 0u22f1) # ⋮⋯⋰⋱
# SelectFewer(0u2300, 0u23ff) # その他の技術用記号
    SelectFewer(0u2300, 0u2307) # ⌀ - ⌇
    SelectFewer(0u230c, 0u230f) # ⌌ - ⌏
    SelectFewer(0u2311, 0u2318) # ⌑ - ⌘
    SelectFewer(0u231c, 0u231f) # ⌜ - ⌟
    SelectFewer(0u231a, 0u231b) # ⌚⌛
    SelectFewer(0u2320, 0u2328) # ⌠ - ⌨
    SelectFewer(0u232b, 0u23ff) # ⌫ - ⏿
# SelectFewer(0u2400, 0u243f) # 制御機能用記号
 #      SelectFewer(0u2423) # ␣
    SelectFewer(0u2425) # ␥
    SelectFewer(0u2440, 0u245f) # 光学的文字認識、OCR
    SelectFewer(0u2500, 0u259f) # 罫線素片・ブロック要素
# SelectFewer(0u25a0, 0u25ff) # 幾何学模様
    SelectFewer(0u25a0, 0u25db) # ■ - ◛
    SelectFewer(0u25dc, 0u25df) # ◜ - ◟
    SelectFewer(0u25e0, 0u25ff) # ◠ - ◿
    SelectFewer(0u2600, 0u26ff) # その他の記号
# SelectFewer(0u2700, 0u27bf) # 装飾記号
    SelectFewer(0u2700, 0u2752) # ✀ - ❒
    SelectFewer(0u2756) # ❖
    SelectFewer(0u2758, 0u275a) # ❘ - ❚
 #    SelectFewer(0u2761, 0u2763) # ❡ - ❣
    SelectFewer(0u2764, 0u2767) # ❤ - ❧
    SelectFewer(0u2795, 0u2798) # ➕ - ➘
    SelectFewer(0u279a) # ➚
    SelectFewer(0u27b0) # ➰
    SelectFewer(0u27b2) # ➲
    SelectFewer(0u27b4) # ➴
    SelectFewer(0u27b6, 0u27b7) # ➶➷
    SelectFewer(0u27b9) # ➹
    SelectFewer(0u27bf) # ➿
# SelectFewer(0u27c0, 0u27ef) # その他の数学記号 A
    SelectFewer(0u27c0) # ⟀
 #    SelectFewer(0u27c1) # ⟁
    SelectFewer(0u27c2) # ⟂
 #    SelectFewer(0u27d3, 0u27e5) # ⟓ - ⟥
# SelectFewer(0u27f0, 0u27ff) # 補助矢印 A
    SelectFewer(0u27f0, 0u27f1) # ⟰⟱
    SelectFewer(0u2800, 0u28ff) # 点字
# SelectFewer(0u2900, 0u2970) # 補助矢印 B
    SelectFewer(0u2908, 0u290b) # ⤈⤉⤊⤋
    SelectFewer(0u2912, 0u2913) # ⤒⤓
    SelectFewer(0u2921, 0u2932) # ⤡ - ⤲
    SelectFewer(0u2949) # ⥉
    SelectFewer(0u294c, 0u294d) # ⥌⥍
    SelectFewer(0u294f) # ⥏
    SelectFewer(0u2951) # ⥑
    SelectFewer(0u2954, 0u2955) # ⥔⥕
    SelectFewer(0u2958, 0u2959) # ⥘⥙
    SelectFewer(0u295c, 0u295d) # ⥜⥝
    SelectFewer(0u2960, 0u2961) # ⥠⥡
    SelectFewer(0u2963) # ⥣
    SelectFewer(0u2965) # ⥥
    SelectFewer(0u296e, 0u296f) # ⥮⥯
    SelectFewer(0u297e, 0u297f) # ⥾⥿
# SelectFewer(0u2980, 0u29ff) # その他の数学記号 B
    SelectFewer(0u299b, 0u29af) # ⦛ - ⦯
 #    SelectFewer(0u29b0, 0u29d7) # ⦰ - ⧗
 #    SelectFewer(0u29df, 0u29f3) # ⧟ - ⧳
# SelectFewer(0u2a00, 0u2aff) # 補助数学記号
 #    SelectFewer(0u2a00, 0u2a02) # ⨀⨁⨂
 #    SelectFewer(0u2a36, 0u2a3b) # ⨶⨷⨸⨹⨺⨻
 #    SelectFewer(0u2ade, 0u2af1) # ⫞ - ⫱
# SelectFewer(0u2b00, 0u2bff) # その他の記号および矢印
    SelectFewer(0u2b00, 0u2b03) # ⬀⬁⬂⬃
    SelectFewer(0u2b06, 0u2b0b) # ⬆⬇⬈⬉⬊⬋
    SelectFewer(0u2b0d) # ⬍
    SelectFewer(0u2b12, 0u2b2f) # ⬒ - ⬯
    SelectFewer(0u2b4e, 0u2b5f) # ⭎ - ⭟
    SelectFewer(0u2b61) # ⭡
    SelectFewer(0u2b63) # ⭣
    SelectFewer(0u2b65, 0u2b69) # ⭥⭦⭧⭨⭩
    SelectFewer(0u2b6b) # ⭫
    SelectFewer(0u2b6d) # ⭭
    SelectFewer(0u2b71) # ⭱
    SelectFewer(0u2b73) # ⭳
    SelectFewer(0u2b76, 0u2b79) # ⭶⭷⭸⭹
    SelectFewer(0u2b7b) # ⭻
    SelectFewer(0u2b7d) # ⭽
    SelectFewer(0u2b7f) # ⭿
    SelectFewer(0u2b81) # ⮁
    SelectFewer(0u2b83) # ⮃
    SelectFewer(0u2b85) # ⮅
    SelectFewer(0u2b87, 0u2b8b) # ⮇⮈⮉⮊⮋
    SelectFewer(0u2b97) # ⮗
    SelectFewer(0u2b99) # ⮙
    SelectFewer(0u2b9b) # ⮛
    SelectFewer(0u2b9d) # ⮝
    SelectFewer(0u2b9f) # ⮟
    SelectFewer(0u2bb8, 0u2bff) # ⮸ - ⯿
    SelectFewer(0u2ff0, 0u2fff) # 漢字構成記述文字
    SelectFewer(0u3000) # 全角スペース
    SelectFewer(0u3004) # 〄
 #    SelectFewer(0u3012) # 〒
    SelectFewer(0u3013) # 〓
    SelectFewer(0u3020) # 〠
 #    SelectFewer(0u3036) # 〶
    SelectFewer(0u31ef) # ㇯
    SelectFewer(0ufe17, 0ufe18) # 縦書き用括弧
    SelectFewer(0ufe19) # ︙
    SelectFewer(0ufe30, 0ufe34) # ︰︱︲︳︴
    SelectFewer(0ufe35, 0ufe44) # 縦書き用括弧
    SelectFewer(0ufe47, 0ufe48) # 縦書き用括弧
 #    SelectFewer(0u1d538, 0u1d56b) # 数学用英数字記号
    SelectFewer(0u1f310) # 🌐
    SelectFewer(0u1f3a4) # 🎤
    SelectFewer("uniFFFD") # Replacement Character
    SelectFewer(".notdef") # notdef
    if ("${nerd_flag}" == "true")
        SelectFewer(0ue000, 0uf8ff) # NerdFonts
        SelectFewer(0uf0001, 0uf1af0) # NerdFonts
    endif

    SelectFewer(${address_store_underline}, ${address_store_underline} + 2) # 保管した下線
    SelectFewer(${address_store_braille}, ${address_store_braille} + 255) # 保管した点字
    SelectFewer(${address_store_line}, ${address_store_line} + 31) # 保管した罫線
    SelectFewer(${address_store_visi_kana} + 2) # 保管した︲
    SelectFewer(${address_store_visi_kana} + 4) # 保管した︱
    SelectFewer(${address_store_arrow}, ${address_store_arrow} + 3) # 保管した矢印
    SelectFewer(${address_store_vert}, ${address_store_vert} + 1) # 保管した縦書きの縦線無し（）
    SelectFewer(${address_store_vert} + 4, ${address_store_vert} + 19) # 保管した縦書きの縦線無し： - ｠
    SelectFewer(${address_store_vert} + 22, ${address_store_vert} + 23) # 保管した縦書きの縦線無し／＼
    SelectFewer(${address_store_vert} + 102) # 保管した縦書きの縦線無し￤
    SelectFewer(${address_store_d_hyphen}) # 保管した縦書きの゠
    SelectFewer(${address_store_otherspace}, ${address_store_otherspace} + 1) # 保管したその他のスペース

    SelectFewer("uni3008.vert", "uni301F.vert") # 縦書きの括弧、〓
    SelectFewer("uni30FC.vert") # 縦書きのー
    SelectFewer("uniFFE4.vert") # 縦書きの￤
    SelectFewer("uni2702.vert", "uni30A0.vert") # 縦書きの✂‖〰゠

    SelectFewer("uni3000.ss01") # ss01の全角スペース

    SelectFewer("space.ss02") # ss02の半角スペース
    SelectFewer("uni00A0.ss02") # ss02のノーブレークスペース

    SelectFewer("uniFF08.vert.ss06", "uniFF09.vert.ss06") # ss06の縦書きの（）
    SelectFewer("uniFF1A.vert.ss06", "uniFF60.vert.ss06") # ss06の縦書きの： - ｠
    SelectFewer("uniFF0F.vert.ss06", "uniFF3C.vert.ss06") # ss06の縦書きの／＼
    SelectFewer("uniFFE4.vert.ss06") # ss06の縦書きの￤
    SelectFewer("uni2800.ss06", "uni28FF.ss06") # ss06の点字

    SelectFewer("uniFE32.ss07") # ss07の︲
    SelectFewer("uniFE31.ss07") # ss07の︱
    SelectFewer("uni30A0.vert.ss07") # ss07の縦書きの゠

    SelectFewer("SF100000.ss09", "arrowdown.ss09") # ss09の罫線、矢印

    SelectFewer("uni2001.ss11") # ss11の全角スペース
    SelectFewer("uni034F.ss11") # ss11の半角スペース

    SelectFewer("arrowup.ss12") # ss12の↑
    SelectFewer("arrowdown.ss12") # ss12の↓
    SelectFewer("arrowupdn.ss12") # ss12の↕
    SelectFewer("arrowdblup.ss12") # ss12の⇑
    SelectFewer("arrowdbldown.ss12") # ss12の⇓
    SelectFewer("uni21D5.ss12") # ss12の⇕
    SelectFewer("filledbox.ss12", "uni266F.ss12") # ss12の■-♯

    Transform(100, 0, ${tan_oblique}, 100, ${move_x_oblique}, 0)
    RemoveOverlap()
    RoundToInt()

# 半角・全角形、縦書き用を作り直し
    Print("Edit hankaku kana, zenkaku eisuu and vert glyphs")

    j = 0
    while (j < ${num_mod_glyphs})
        Select(${address_store_mod} + ${num_mod_glyphs} * 1 + j); Copy() # 保管した横書きのＤＱＶＺ
        Select(${address_store_mod} + ${num_mod_glyphs} * 4 + j); Paste() # 保管した下線ありの横書きのＤＱＶＺ
        Select(${address_store_underline}); Copy() # 下線追加
        Select(${address_store_mod} + ${num_mod_glyphs} * 4 + j); PasteInto() # 保管した下線ありの横書きのＤＱＶＺ
        SetWidth(${width_zenkaku})

        Select(${address_store_mod} + ${num_mod_glyphs} * 2 + j); Copy() # 保管した縦書きのＤＱＶＺ
        Select(${address_store_mod} + ${num_mod_glyphs} * 5 + j); Paste() # 保管した縦線ありの縦書きのＤＱＶＺ
        Select(${address_store_underline} + 2); Copy() # 縦線追加
        Select(${address_store_mod} + ${num_mod_glyphs} * 5 + j); PasteInto() # 保管した縦線ありの縦書きのＤＱＶＺ
        SetWidth(${width_zenkaku})
        j += 1
    endloop

    Select(${address_store_zero} + 3); Copy() # 保管した全角のスラッシュ無し0
    Select(${address_store_zero} + 4); Paste() # 保管した横書きのスラッシュ無し0
    Select(${address_store_underline}); Copy() # 下線追加
    Select(${address_store_zero} + 4); PasteInto() # 保管した横書きのスラッシュ無し0
    SetWidth(${width_zenkaku})

    Select(${address_store_zero} + 3); Copy() # 保管した全角のスラッシュ無し0
    Select(${address_store_zero} + 5); Paste() # 保管した縦書きのスラッシュ無し0
    Select(${address_store_underline} + 2); Copy() # 縦線追加
    Select(${address_store_zero} + 5); PasteInto() # 保管した縦書きのスラッシュ無し0
    SetWidth(${width_zenkaku})

    Select(${address_store_zero} + 3 + 6); Copy() # 保管した全角のドット0
    Select(${address_store_zero} + 4 + 6); Paste() # 保管した横書きのドット0
    Select(${address_store_underline}); Copy() # 下線追加
    Select(${address_store_zero} + 4 + 6); PasteInto() # 保管した横書きのドット0
    SetWidth(${width_zenkaku})

    Select(${address_store_zero} + 3 + 6); Copy() # 保管した全角のドット0
    Select(${address_store_zero} + 5 + 6); Paste() # 保管した縦書きのドット0
    Select(${address_store_underline} + 2); Copy() # 縦線追加
    Select(${address_store_zero} + 5 + 6); PasteInto() # 保管した縦書きのドット0
    SetWidth(${width_zenkaku})

    Select("uniFF08.vert")
    vert = GlyphInfo("Encoding")
    Select("uni2702.vert")
    vert2 = GlyphInfo("Encoding")
    j = 0
    while (j < vert2 - vert)
        Select(${address_store_vert} + j); Copy() # 保管した縦線無し縦書き
        Select(vert + j); Paste() # 縦書き
        Select(${address_store_underline} + 2); Copy() # 縦線追加
        Select(vert + j); PasteInto() # 縦書き
        SetWidth(${width_zenkaku})
        j += 1
    endloop

    Select("uniFF24.ss08")
    ss = GlyphInfo("Encoding")
    st = [35, 48, 53, 57] # 保管した全角半角文字の頭からＤＱＶＺまでの数
    j = 0
    while (j < SizeOf(st))
        Select(${address_store_zenhan} + st[j]); Copy() # 保管した横書きのＤＱＶＺ
        Select(ss + j); Paste() # 横書きのss08用ＤＱＶＺ
        Select(${address_store_underline}); Copy() # 下線追加
        Select(ss + j); PasteInto() # 横書きのss08用ＤＱＶＺ
        SetWidth(${width_zenkaku})
        j += 1
    endloop

    Select("uniFF24.vert.ss08")
    ss = GlyphInfo("Encoding")
    st = [48, 61, 66, 70] # 保管した縦書き文字の頭からＤＱＶＺまでの数
    j = 0
    while (j < SizeOf(st))
        Select(${address_store_vert} + st[j]); Copy() # 保管した縦書きのＤＱＶＺ
        Select(ss + j); Paste() # 縦書きのss08用ＤＱＶＺ
        Select(${address_store_underline} + 2); Copy() # 縦線追加
        Select(ss + j); PasteInto() # 縦書きのss08用ＤＱＶＺ
        SetWidth(${width_zenkaku})
        j += 1
    endloop

    Select(${address_store_zero} + 3); Copy() # 保管した全角のスラッシュ無し0
    Select("uniFF10.ss10"); Paste() # 横書きのスラッシュ無し0
    Select(${address_store_underline}); Copy() # 下線追加
    Select("uniFF10.ss10"); PasteInto() # 横書きのスラッシュ無し0
    SetWidth(${width_zenkaku})

    Select(${address_store_zero} + 3); Copy() # 保管した全角のスラッシュ無し0
    Select("uniFF10.vert.ss10"); Paste() # 縦書きのスラッシュ無し0
    Select(${address_store_underline} + 2); Copy() # 縦線追加
    Select("uniFF10.vert.ss10"); PasteInto() # 縦書きのスラッシュ無し0
    SetWidth(${width_zenkaku})

    Select(${address_store_zero} + 3 + 6); Copy() # 保管した全角のドット0
    Select("uniFF10.ss20"); Paste() # 横書きのドット0
    Select(${address_store_underline}); Copy() # 下線追加
    Select("uniFF10.ss20"); PasteInto() # 横書きのドット0
    SetWidth(${width_zenkaku})

    Select(${address_store_zero} + 3 + 6); Copy() # 保管した全角のドット0
    Select("uniFF10.vert.ss20"); Paste() # 縦書きのドット0
    Select(${address_store_underline} + 2); Copy() # 縦線追加
    Select("uniFF10.vert.ss20"); PasteInto() # 縦書きのドット0
    SetWidth(${width_zenkaku})

    j = 0
    k = 0
    while (k < 96)
        Select(${address_store_zenhan} + k); Copy() # 保管した全角半角文字
        Select(0uff01 + j); Paste() # 全角半角形
        Select(${address_store_underline}); Copy() # 下線追加
        Select(0uff01 + j); PasteInto() # 全角半角形
        SetWidth(${width_zenkaku})
        j += 1
        k += 1
    endloop
    while (k < 159)
        Select(${address_store_zenhan} + k); Copy() # 保管した全角半角文字
        Select(0uff01 + j); Paste() # 全角半角形
        Select(${address_store_underline} + 1); Copy() # 下線追加
        Select(0uff01 + j); PasteInto() # 全角半角形
        SetWidth(${width_hankaku})
        j += 1
        k += 1
    endloop
    j = 0
    while (k < 166)
        Select(${address_store_zenhan} + k); Copy() # 保管した全角半角文字
        Select(0uffe0 + j); Paste() # 全角半角形
        Select(${address_store_underline}); Copy() # 下線追加
        Select(0uffe0 + j); PasteInto() # 全角半角形
        SetWidth(${width_zenkaku})
        j += 1
        k += 1
    endloop
    hori = [0u309b, 0u309c, 0u203c, 0u2047,\
            0u2048, 0u2049] # ゛゜‼⁇ ⁈⁉
    j = 0
    while (k < 172)
        Select(${address_store_zenhan} + k); Copy() # 保管した全角半角文字
        Select(hori[j]); Paste()
        Select(${address_store_underline}); Copy() # 下線追加
        Select(hori[j]); PasteInto()
        SetWidth(${width_zenkaku})
        j += 1
        k += 1
    endloop

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

Print("- Patch the generated fonts -")

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

# 全角スペース消去
    if ("${visible_zenkaku_space_flag}" == "false")
        Print("Option: Disable visible zenkaku space")
        Select(0u3000); Clear(); SetWidth(${width_zenkaku}) # 全角スペース
    endif

# 半角スペース消去
    if ("${visible_hankaku_space_flag}" == "false")
        Print("Option: Disable visible hankaku space")
        Select(0u0020); Clear(); SetWidth(${width_hankaku}) # 半角スペース
        Select(0u00a0); Clear(); SetWidth(${width_hankaku}) # ノーブレークスペース
    endif

# 下線付きの全角・半角形を元に戻す
    if ("${underline_flag}" == "false")
        Print("Option: Disable zenkaku hankaku underline")
        k = 0
        # 全角縦書き
        j = 0
        while (j < 109)
            Select(${address_store_vert} + k); Copy()
            Select(${address_vert_bracket} + j); Paste()
            SetWidth(${width_zenkaku})
            j += 1
            k += 1
        endloop

        # 全角横書き
        j = 0 # ！-｠
        while (j < 96)
            Select(${address_store_vert} + k); Copy()
            Select(0uff01 + j); Paste()
            SetWidth(${width_zenkaku})
            j += 1
            k += 1
        endloop

        # 半角横書き
        j = 0 # ｡-ﾟ
        while (j < 63)
            Select(${address_store_vert} + k); Copy();
            Select(0uff61 + j); Paste()
            SetWidth(${width_hankaku})
            j += 1
            k += 1
        endloop

        # 全角横書き (続き)
        j = 0 # ￠-￦
        while (j < 7)
            Select(${address_store_vert} + k); Copy()
            Select(0uffe0 + j); Paste()
            SetWidth(${width_zenkaku})
            j += 1
            k += 1
        endloop
        orig = [0u309b, 0u309c, 0u203c, 0u2047,\
                0u2048, 0u2049] # ゛゜‼⁇ ⁈⁉
        j = 0
        while (j < SizeOf(orig))
            Select(${address_store_vert} + k); Copy()
            Select(orig[j]); Paste()
            SetWidth(${width_zenkaku})
            j += 1
            k += 1
        endloop

        # 点字
        j = 0
        while (j < 256)
            Select(${address_store_braille} + j); Copy()
            Select(0u2800 + j); Paste()
            SetWidth(${width_hankaku})
            j += 1
        endloop

    endif

# 識別性向上グリフを元に戻す
    if ("${improve_visibility_flag}" == "false")
        Print("Option: Disable glyphs with improved visibility")
        # 破線・ウロコ等
        k = 0
        orig = [0u2044, 0u007c,\
                0u30a0, 0u2013, 0ufe32, 0u2014, 0ufe31] # ⁄| ゠–︲—︱
        j = 0
        while (j < SizeOf(orig))
            Select(${address_store_visi_latin} + k); Copy()
            Select(orig[j]); Paste()
            if (j <= 1 || j == 3)
                SetWidth(${width_hankaku})
            elseif (j == 5 && "${term_flag}" == "true")
                SetWidth(${width_hankaku})
            else
                SetWidth(${width_zenkaku})
            endif
            j += 1
            k += 1
        endloop
        j = 0
        while (j < 20) # ➀-➓
            Select(${address_store_visi_latin} + k); Copy()
            Select(0u2780 + j); Paste()
            if ("${term_flag}" == "true")
                SetWidth(${width_hankaku})
            else
                SetWidth(${width_zenkaku})
            endif
            j += 1
            k += 1
        endloop
        orig = [0u3007, 0u4e00, 0u4e8c, 0u4e09,\
                0u5de5, 0u529b, 0u5915, 0u535c,\
                0u53e3, 0u4e8e, 0u4e95, 0u5b50] # 〇一二三 工力夕卜 口于井子
        j = 0
        while (j < SizeOf(orig))
            Select(${address_store_visi_latin} + k); Copy()
            Select(orig[j]); Paste()
            SetWidth(${width_zenkaku})
            j += 1
            k += 1
        endloop

        Select(${address_store_d_hyphen}); Copy() # 縦書き゠
        Select(${address_vert_dh}); Paste()
        SetWidth(${width_zenkaku})
    endif

# DQVZのクロスバー等消去
    if ("${mod_flag}" == "false")
        Print("Option: Disable modified D,Q,V and Z")
        if ("${underline_flag}" == "false")
            k = 0
        else
            k = ${num_mod_glyphs} * 3
        endif
        j = 0
        orig = [0u0044, 0u0051, 0u0056, 0u005a,\
                0uff24, 0uff31, 0uff36, 0uff3a,\
               "uniFF24.vert", "uniFF31.vert", "uniFF36.vert", "uniFF3A.vert"] # DQVZＤＱＶＺ縦書きＤＱＶＺ
        while (j < SizeOf(orig))
            Select(${address_store_mod} + j + k); Copy()
            Select(orig[j]); Paste()
            if (j <= ${num_mod_glyphs} - 1)
                SetWidth(${width_hankaku})
            else
                SetWidth(${width_zenkaku})
            endif
            j += 1
        endloop
    endif

# スラッシュ無し0
    if ("${zero_mode}" == "0")
        Print("Option: Disable slashed zero")
        # 半角、全角
        zero = [0u0030, 0u2070, 0u2080, 0u0000,\
                0uff10, "uniFF10.vert"] # 0⁰₀０縦書き０ (0u0000はダミー)
        j = 0
        while (j < SizeOf(zero))
            if (j != 3)
                Select(${address_store_zero} + j); Copy()
                Select(zero[j]); Paste()
                if (j < 3)
                    SetWidth(${width_hankaku})
                else
                    SetWidth(${width_zenkaku})
                endif
            endif
            j += 1
        endloop

        # 下線無し
        if ("${underline_flag}" == "false")
            Select(${address_store_zero} + 3); Copy()
            Select(0uff10) # ０
            SelectMore("uniFF10.vert") # 縦書き０
            Paste()
            SetWidth(${width_zenkaku})
        endif

        # 桁区切り
        j = 0
        while (j < 4)
            Select(${address_ss_zero} + 3 + j); Copy()
            Select(${address_calt_figure} + j * 10); Paste()
            SetWidth(${width_hankaku})
            j += 1
        endloop

# ドット0
    elseif ("${zero_mode}" == "2")
        Print("Option: Enable another zero")
        # 半角、全角
        zero = [0u0030, 0u2070, 0u2080, 0u0000,\
                0uff10, "uniFF10.vert"] # 0⁰₀０縦書き０ (0u0000はダミー)
        j = 0
        while (j < SizeOf(zero))
            if (j != 3)
                Select(${address_store_zero} + j + 6); Copy()
                Select(zero[j]); Paste()
                if (j < 3)
                    SetWidth(${width_hankaku})
                else
                    SetWidth(${width_zenkaku})
                endif
            endif
            j += 1
        endloop

        # 下線無し
        if ("${underline_flag}" == "false")
            Select(${address_store_zero} + 3 + 6); Copy()
            Select(0uff10) # ０
            SelectMore("uniFF10.vert") # 縦書き０
            Paste()
            SetWidth(${width_zenkaku})
        endif

        # 桁区切り
        j = 0
        while (j < 4)
            Select(${address_ss_zero2} + 3 + j); Copy()
            Select(${address_calt_figure} + j * 10); Paste()
            SetWidth(${width_hankaku})
            j += 1
        endloop
    endif

# 桁区切りなし・小数を元に戻す
    if ("${separator_flag}" == "false")
        Print("Option: Disable thousands separator")
        j = 0
        while (j < 40)
            Select(0u0030 + j % 10); Copy() # 0-9
            Select(${address_calt_figure} + j); Paste()
            j += 1
        endloop
    endif

# 一部の記号文字を削除 (カラー絵文字フォントとの組み合わせ用)
    if ("${emoji_flag}" == "false")
        Print("Option: Reduce the number of emoji glyphs")

 #        Select(0u0023)             # #
 #        SelectMore(0u002a)         # *
 #        SelectMore(0u0030, 0u0039) # 0 - 9
 #        SelectMore(0u00a9)         # ©
 #        SelectMore(0u00ae)         # ®
        Select(0u203c)             # ‼
        SelectMore(0u2049)         # ⁉
 #        SelectMore(0u2122)         # ™
        SelectMore(0u2139)         # ℹ
        SelectMore(0u2194, 0u2199) # ↔↕↖↗↘↙
        SelectMore(0u21a9, 0u21aa) # ↩↪
        SelectMore(0u231a, 0u231b) # ⌚⌛
        SelectMore(0u2328)         # ⌨
        SelectMore(0u23cf)         # ⏏
        SelectMore(0u23e9, 0u23ec) # ⏩⏪⏫⏫⏬
        SelectMore(0u23ed, 0u23ee) # ⏭⏮
        SelectMore(0u23ef)         # ⏯
        SelectMore(0u23f0)         # ⏰
        SelectMore(0u23f1, 0u23f2) # ⏱⏲
        SelectMore(0u23f3)         # ⏳
        SelectMore(0u23f8, 0u23fa) # ⏸⏹⏺
 #        SelectMore(0u24c2)         # Ⓜ
        SelectMore(0u25aa, 0u25ab) # ▪▫
        SelectMore(0u25b6)         # ▶
        SelectMore(0u25c0)         # ◀
        SelectMore(0u25fb, 0u25fe) # ◻◾
        SelectMore(0u2600, 0u2601) # ☀☁
        SelectMore(0u2602, 0u2603) # ☂☃
        SelectMore(0u2604)         # ☄
        SelectMore(0u260e)         # ☎
        SelectMore(0u2611)         # ☑
        SelectMore(0u2614, 0u2615) # ☔☕
        SelectMore(0u2618)         # ☘
        SelectMore(0u261d)         # ☝
        SelectMore(0u2620)         # ☠
        SelectMore(0u2622, 0u2623) # ☢☣
        SelectMore(0u2626)         # ☦
        SelectMore(0u262a)         # ☪
        SelectMore(0u262e)         # ☮
        SelectMore(0u262f)         # ☯
        SelectMore(0u2638, 0u2639) # ☸☹
        SelectMore(0u263a)         # ☺
        SelectMore(0u2640)         # ♀
        SelectMore(0u2642)         # ♂
        SelectMore(0u2648, 0u2653) # ♈♉♊♋♌♍♎♏♐♑♒♓
        SelectMore(0u265f)         # ♟
        SelectMore(0u2660)         # ♠
        SelectMore(0u2663)         # ♣
        SelectMore(0u2665, 0u2666) # ♥♦
        SelectMore(0u2668)         # ♨
        SelectMore(0u267b)         # ♻
        SelectMore(0u267e)         # ♾
        SelectMore(0u267f)         # ♿
        SelectMore(0u2692)         # ⚒
        SelectMore(0u2693)         # ⚓
        SelectMore(0u2694)         # ⚔
        SelectMore(0u2695)         # ⚕
        SelectMore(0u2696, 0u2697) # ⚖⚗
        SelectMore(0u2699)         # ⚙
        SelectMore(0u269b, 0u269c) # ⚛⚜
        SelectMore(0u26a0, 0u26a1) # ⚠⚡
        SelectMore(0u26a7)         # ⚧
        SelectMore(0u26aa, 0u26ab) # ⚪⚫
        SelectMore(0u26b0, 0u26b1) # ⚰⚱
        SelectMore(0u26bd, 0u26be) # ⚽⚾
        SelectMore(0u26c4, 0u26c5) # ⛄⛅
        SelectMore(0u26c8)         # ⛈
        SelectMore(0u26ce)         # ⛎
        SelectMore(0u26cf)         # ⛏
        SelectMore(0u26d1)         # ⛑
        SelectMore(0u26d3)         # ⛓
        SelectMore(0u26d4)         # ⛔
        SelectMore(0u26e9)         # ⛩
        SelectMore(0u26ea)         # ⛪
        SelectMore(0u26f0, 0u26f1) # ⛰⛱
        SelectMore(0u26f2, 0u26f3) # ⛲⛳
        SelectMore(0u26f4)         # ⛴
        SelectMore(0u26f5)         # ⛵
        SelectMore(0u26f7, 0u26f9) # ⛷⛸⛹
        SelectMore(0u26fa)         # ⛺
        SelectMore(0u26fd)         # ⛽
        SelectMore(0u2702)         # ✂
        SelectMore(0u2705)         # ✅
        SelectMore(0u2708, 0u270c) # ✈✉✊✋✌
        SelectMore(0u270d)         # ✍
        SelectMore(0u270f)         # ✏
        SelectMore(0u2712)         # ✒
        SelectMore(0u2714)         # ✔
        SelectMore(0u2716)         # ✖
        SelectMore(0u271d)         # ✝
        SelectMore(0u2721)         # ✡
        SelectMore(0u2728)         # ✨
        SelectMore(0u2733, 0u2734) # ✳✴
        SelectMore(0u2744)         # ❄
        SelectMore(0u2747)         # ❇
        SelectMore(0u274c)         # ❌
        SelectMore(0u274e)         # ❎
        SelectMore(0u2753, 0u2755) # ❓❔❕
        SelectMore(0u2757)         # ❗
        SelectMore(0u2763)         # ❣
        SelectMore(0u2764)         # ❤
        SelectMore(0u2795, 0u2797) # ➕➖➗
        SelectMore(0u27a1)         # ➡
        SelectMore(0u27b0)         # ➰
        SelectMore(0u27bf)         # ➿
        SelectMore(0u2934, 0u2935) # ⤴⤵
        SelectMore(0u2b05, 0u2b07) # ⬅⬆⬇
        SelectMore(0u2b1b, 0u2b1c) # ⬛⬜
        SelectMore(0u2b50)         # ⭐
        SelectMore(0u2b55)         # ⭕
        SelectMore(0u3030)         # 〰
        SelectMore(0u303d)         # 〽
        SelectMore(0u3297)         # ㊗
        SelectMore(0u3299)         # ㊙

        SelectMore(0u1f310)        # 🌐
        SelectMore(0u1f3a4)        # 🎤
        Clear(); DetachAndRemoveGlyphs()
    endif

# calt用異体字上書き
    if ("${calt_flag}" == "true")
        Print("Overwrite calt glyphs")
        k = ${address_calt_AL}
        j = 0
        while (j < 26)
            Select(0u0041 + j); Copy() # A
            Select(k); Paste()
            Move(-${move_x_calt_latin}, 0)
            SetWidth(${width_hankaku})
            j += 1
            k += 1
        endloop
        j = 0
        while (j < 26)
            Select(0u0061 + j); Copy() # a
            Select(k); Paste()
            Move(-${move_x_calt_latin}, 0)
            SetWidth(${width_hankaku})
            j += 1
            k += 1
        endloop

        k = ${address_calt_AR}
        j = 0
        while (j < 26)
            Select(0u0041 + j); Copy() # A
            Select(k); Paste()
            Move(${move_x_calt_latin}, 0)
            SetWidth(${width_hankaku})
            j += 1
            k += 1
        endloop
        j = 0
        while (j < 26)
            Select(0u0061 + j); Copy() # a
            Select(k); Paste()
            Move(${move_x_calt_latin}, 0)
            SetWidth(${width_hankaku})
            j += 1
            k += 1
        endloop

        Select(0u007c); Copy() # |
        Select(${address_calt_hyphenL} + ${address_calt_barDLR}); Paste() # 左に移動した |
        Move(-${move_x_calt_symbol}, 0)
        SetWidth(${width_hankaku})

        Select(0u007c); Copy() # |
        Select(${address_calt_hyphenR} + ${address_calt_barDLR}); Paste() # 右に移動した |
        Move(${move_x_calt_symbol}, 0)
        SetWidth(${width_hankaku})

        Select(0u007c); Copy() # |
        Select(${address_calt_barD}); Paste() # 下に移動した |
        Move(0, ${move_y_calt_bar})
        SetWidth(${width_hankaku})

        Select(0u007c); Copy() # |
        Select(${address_calt_hyphenL} + ${address_calt_barDLR} + 1); Paste() # 左下に移動した |
        Move(-${move_x_calt_symbol}, ${move_y_calt_bar})
        SetWidth(${width_hankaku})

        Select(0u007c); Copy() # |
        Select(${address_calt_hyphenR} + ${address_calt_barDLR} + 1); Paste() # 右下に移動した |
        Move(${move_x_calt_symbol}, ${move_y_calt_bar})
        SetWidth(${width_hankaku})

        Select(0u007c); Copy() # |
        Select(${address_calt_barD} + 7); Paste() # 上に移動した | (括弧用)
        Move(0, ${move_y_calt_bar2})
        SetWidth(${width_hankaku})

        Select(0u007c); Copy() # |
        Select(${address_calt_hyphenL} + ${address_calt_barDLR} + 4); Paste() # 左上に移動した | (括弧用)
        Move(-${move_x_calt_symbol}, ${move_y_calt_bar2})
        SetWidth(${width_hankaku})

        Select(0u007c); Copy() # |
        Select(${address_calt_hyphenR} + ${address_calt_barDLR} + 4); Paste() # 右上に移動した | (括弧用)
        Move(${move_x_calt_symbol}, ${move_y_calt_bar2})
        SetWidth(${width_hankaku})

    else # calt非対応の場合、ダミーのフィーチャを削除
        Print("Remove calt lookups and glyphs")
        lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups); j = 0
        while (j < numlookups)
            if (${lookupIndex_calt} <= j && j < ${lookupIndex_calt} + ${num_calt_lookups})
                Print("Remove GSUB_" + lookups[j])
                RemoveLookup(lookups[j])
            endif
            j += 1
        endloop

        Select(${address_calt_start}, ${address_calt_end}) # calt非対応の場合、calt用異体字削除
        Clear(); DetachAndRemoveGlyphs()
    endif

# 保管したグリフ消去
    Print("Remove stored glyphs")
    Select(${address_store_start}, ${address_store_end}); Clear() # 保管したグリフを消去

# ss 用異体字消去
    if ("${ss_flag}" == "false")
        Print("Remove ss lookups and glyphs")
        lookups = GetLookups("GSUB"); numlookups = SizeOf(lookups); j = 0
        while (j < numlookups)
            if (${lookupIndex_ss} <= j && j < ${lookupIndex_ss} + ${num_ss_lookups})
                Print("Remove GSUB_" + lookups[j])
                RemoveLookup(lookups[j])
            endif
            j += 1
        endloop

        Select(${address_ss_start}, ${address_ss_end})
        Clear(); DetachAndRemoveGlyphs()
    endif

# --------------------------------------------------

    SetGasp(65535, 15) # Windows のジャギー対策
# Save patched font
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

    # 下書きモード、一時作成ファイルを残す以外で font_generator に変更が無く、すでにパッチ前フォントが作成されていた場合それを呼び出す
    if [ "${draft_flag}" = "false" ] && [ "${leaving_tmp_flag}" = "false" ]; then
        output_data=$(sha256sum font_generator.sh | cut -d ' ' -f 1)
        output_data=${output_data}"_"$(sha256sum "${settings}.txt" | cut -d ' ' -f 1)
        if [ "${nerd_flag}" = "false" ]; then
            nopatchsetdir_name="e"
        fi
        if [ "${oblique_flag}" = "false" ]; then
            nopatchsetdir_name="${nopatchsetdir_name}o"
        fi
        if [ "${loose_flag}" != "false" ]; then
            nopatchsetdir_name="${nopatchsetdir_name}w"
        fi
        if [ "${term_flag}" != "false" ]; then
            nopatchsetdir_name="${nopatchsetdir_name}a"
        fi
        nopatchsetdir_name="${font_familyname}_${nopatchsetdir_name}"
        file_data_txt=$(find "./${nopatchdir_name}/${nopatchsetdir_name}" -maxdepth 1 -name "${fileDataName}.txt" | head -n 1)
        if [ -n "${file_data_txt}" ]; then
            input_data=$(head -n 1 "${nopatchdir_name}/${nopatchsetdir_name}/${fileDataName}.txt")
            if [ "${input_data}" = "${output_data}" ]; then
                echo "font_generator and settings file are unchanged"
                echo "Use saved nopatch fonts"
                cp -f ${nopatchdir_name}/${nopatchsetdir_name}/${font_familyname}-*.nopatch.ttf "."
                compose_flag="false"
                echo
            fi
        fi
    fi

    # 下書きモードかパッチ前フォントが作成されていなかった場合フォントを合成し直す
    if [ "${compose_flag}" = "true" ]; then
        if [ "${draft_flag}" = "false" ] && [ "${leaving_tmp_flag}" = "false" ]; then
            echo "font_generator settings are changed or nopatch fonts not exist"
            echo "Make new nopatch fonts"
            echo
        fi

        # カスタムフォント生成
        $fontforge_command -script ${tmpdir}/${modified_latin_generator} \
            2> $redirection_stderr || exit 4
        $fontforge_command -script ${tmpdir}/${modified_kana_generator} \
            2> $redirection_stderr || exit 4
        $fontforge_command -script ${tmpdir}/${modified_kanzi_generator} \
            2> $redirection_stderr || exit 4
        $fontforge_command -script ${tmpdir}/${modified_dummy_generator} \
            2> $redirection_stderr || exit 4
        $fontforge_command -script ${tmpdir}/${modified_hentai_kana_generator} \
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
        find . -maxdepth 1 -not -name "*.*.ttf" | \
        grep -e "${font_familyname}${font_familyname_suffix}-.*\.ttf$" | while read line
        do
            style_ttf=${line#*-}; style=${style_ttf%%.ttf}
            echo "Rename to ${font_familyname}-${style}.nopatch.ttf"
            mv "${line}" "${font_familyname}-${style}.nopatch.ttf"
            echo
        done

        # 下書きモード、一時作成ファイルを残す以外でフォントを作成した場合、パッチ前フォントと font_generator の情報を保存
        if [ "${draft_flag}" = "false" ] && [ "${leaving_tmp_flag}" = "false" ]; then
            echo "Save nopatch fonts"
            rm -rf "${nopatchdir_name}/${nopatchsetdir_name}"
            mkdir -p "${nopatchdir_name}/${nopatchsetdir_name}"
            printf "${output_data}" > "${nopatchdir_name}/${nopatchsetdir_name}/${fileDataName}.txt"
            cp -f ${font_familyname}-*.nopatch.ttf "${nopatchdir_name}/${nopatchsetdir_name}/."
            echo
        fi
    fi
fi

# パッチ適用
if [ "${patch_flag}" = "true" ]; then
    find . -maxdepth 1 -name "${font_familyname}-*.nopatch.ttf" | while read line
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
