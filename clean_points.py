#!/usr/bin/env python3
"""
Font points cleaner

Copyright (c) 2026 omonomo

※ このスクリプトは製作に生成 AI を使用しています。


説明:
TrueType（static）フォントのグリフから無駄なポイントを除去するスクリプト。

  1. 重複点（長さゼロの線分）の除去
  2. 直線上の中間点の除去（許容誤差 --tol、既定 0 = 完全に一直線のみ）
  3. 暗黙オンカーブ点の除去（オフカーブ2点の厳密な中点にあるオンカーブ点）

使い方:
  python clean_points.py in.ttf out.ttf [--tol 0] [--allow-half] [--spikes] [--fix-cracks] [--force] [-v] [--report FILE]

注意:
デフォルト設定（--tol 0、--allow-half なし）では描画結果は完全に同じになります。

スパイク除去(後述)以外でbboxが変化した場合、ポイント削除は実行しません。

ヒンティング命令は破棄されます。

ポイント番号で配置された複合グリフの参照先は処理対象から外します。

--spikes 指定でウェイト変更時などに発生したヒゲ状のゴミを除去しまが、輪郭が変わります。
具体的には、幅ほぼゼロの「行って戻る」突起と、面積ほぼゼロの輪郭を削除します。

--fix-cracks 指定時で、わずかにずれた辺で接している輪郭（亀裂）を、点を吸着させてから
合体させます（skia-pathops が必要）。合体させたグリフは --spikes と同じ削除処理も行います。

GPOS の AnchorFormat2、GDEF の CaretValue Format2（点番号指定）があれば中断するします。
--force を付けると強制的に実行します。

-v / --verbose を付けると、グリフごとの結果（Spike removed、Bounding box changed
within tolerance、Skipped (bounding box would change)、LSB adjusted）を1行ずつ表示します。
付けない場合は最後のまとめ（件数）だけを表示します。

--report FILE を付けると、亀裂を修正したグリフとスパイクを除去したグリフを
文字として並べたテキストファイル（UTF-8）を書き出します。出力フォントで開けば
修正結果を目視で確認できます。コードポイントのないグリフや、空白・制御文字のように
表示できない文字はグリフ名で列挙します。

カレントディレクトリに除外リスト（exclusions.txt）があった場合、
記載されたコードポイントのグリフは処理しません。

exclusions.txtの書式:
行頭が # か空行は無視。
コードポイントのみ(XXXX)で単独指定。
XXXX..XXXXで範囲指定。
"""
import argparse
import copy
import math
import os
import sys
import unicodedata

# 除外リストのファイル名（カレントディレクトリから探す）。
# 記載されたコードポイントのグリフは処理しない。ファイルがなければ何も除外しない。
EXCLUDE_LIST_FILE = "exclusions.txt"

try:
    import pathops  # --fix-cracks でのみ使用（pip install skia-pathops）
except ImportError:
    pathops = None
from fontTools.pens.recordingPen import RecordingPen, replayRecording
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont
from array import array

from fontTools.ttLib.tables._g_l_y_f import (
    GlyphCoordinates,
    flagOnCurve,
    flagOverlapSimple as OVERLAP_SIMPLE,
    dropImpliedOnCurvePoints,
)


# --help に表示する説明
DESCRIPTION = """\
Remove redundant points from glyphs in a static TrueType font.

  1. duplicate points (zero-length segments)
  2. collinear intermediate points (tolerance: --tol, default 0)
  3. implied on-curve points (exact midpoint of two off-curve points)

With the defaults (--tol 0, no --allow-half) the outlines are unchanged.
Hinting instructions are discarded.

--spikes additionally removes zero-width spikes (the outline goes out and
comes back along the same line) and contours with almost no area.

--fix-cracks merges contours whose edges almost coincide (hairline cracks left
by overlap removal on fractional coordinates, e.g. after ChangeWeight). This changes the bounding box, and the
hmtx left side bearing is updated accordingly."""


# ---------- 暗黙オンカーブ点の除去 ----------

def drop_exact_implied(g):
    """前後がオフカーブで、座標が厳密に中点（2p == a + b）のオンカーブ点だけを削除。
    中点が x.5 になる点は残すので、描画は完全に同一になる。"""
    coords, flags = g.coordinates, g.flags
    drop, start = set(), 0
    for end in g.endPtsOfContours:
        n = end - start + 1
        if n >= 3:
            for i in range(start, end + 1):
                if not flags[i] & flagOnCurve:
                    continue
                pi = start + (i - start - 1) % n
                ni = start + (i - start + 1) % n
                if flags[pi] & flagOnCurve or flags[ni] & flagOnCurve:
                    continue
                (ax, ay), (px, py), (bx, by) = coords[pi], coords[i], coords[ni]
                if 2 * px == ax + bx and 2 * py == ay + by:
                    drop.add(i)
        start = end + 1
    if not drop:
        return
    keep = [i for i in range(len(coords)) if i not in drop]
    ends, start = [], 0
    for end in g.endPtsOfContours:
        ends.append(end - sum(1 for d in drop if d <= end))
    g.coordinates = GlyphCoordinates([coords[i] for i in keep])
    g.flags = array("B", [flags[i] for i in keep])
    g.endPtsOfContours = ends


# ---------- スパイク（行って戻る突起）の除去 ----------

MIN_REACH = 8.0    # 突起の長さの下限
MERGE_DIST = 1.0   # これ以下なら出発点と戻り点を1点にまとめる

def _expand(coords, flags):
    """輪郭を (x, y, on, 元の点番号) のリストに展開。暗黙オンカーブ点は番号 None で補う"""
    pts = [(coords[i][0], coords[i][1], bool(flags[i] & flagOnCurve), i)
           for i in range(len(coords))]
    out, n = [], len(pts)
    for k in range(n):
        p, q = pts[k], pts[(k + 1) % n]
        out.append(p)
        if not p[2] and not q[2]:
            out.append(((p[0] + q[0]) / 2, (p[1] + q[1]) / 2, True, None))
    return out


def _subpath_metrics(ex, a, b):
    """a から b までの部分経路を弦 b→a で閉じた領域の面積と、部分経路の長さ"""
    m = len(ex)
    area2 = length = 0.0
    k = a
    while k != b:
        p, q = ex[k], ex[(k + 1) % m]
        if q[2]:  # 直線
            area2 += p[0] * q[1] - q[0] * p[1]
            length += math.dist(p[:2], q[:2])
            k = (k + 1) % m
        else:     # 2次曲線（暗黙点を補ってあるので次の次は必ずオンカーブ）
            r = ex[(k + 2) % m]
            area2 += p[0] * r[1] - r[0] * p[1]
            # 曲線と弦に挟まれた面積は、制御三角形の面積の 2/3
            area2 += (2 / 3) * ((q[0] - p[0]) * (r[1] - p[1])
                                - (q[1] - p[1]) * (r[0] - p[0]))
            length += (math.dist(p[:2], r[:2]) + math.dist(p[:2], q[:2])
                       + math.dist(q[:2], r[:2])) / 2
            k = (k + 2) % m
    p, q = ex[b], ex[a]
    area2 += p[0] * q[1] - q[0] * p[1]
    return abs(area2) / 2, length


def _unit(p, q):
    dx, dy = q[0] - p[0], q[1] - p[1]
    d = math.hypot(dx, dy)
    return (dx / d, dy / d) if d else None


def _hairpin(p, q, r):
    """p→q→r で向きがほぼ反転する（約 155° 以上曲がる）か"""
    u, v = _unit(p, q), _unit(q, r)
    return u is not None and v is not None and u[0] * v[0] + u[1] * v[1] < -0.9


def _leaves_hairpin(ex, a, b):
    """a と b の間を削除して a→b でつないだとき、a か b で折り返しが残るか"""
    m = len(ex)
    prev, nxt = ex[(a - 1) % m][:2], ex[(b + 1) % m][:2]
    pa, pb = ex[a][:2], ex[b][:2]
    if math.dist(pa, pb) <= MERGE_DIST:
        return _hairpin(prev, pa, nxt)
    return _hairpin(prev, pa, pb) or _hairpin(pa, pb, nxt)


def _contour_metrics(ex):
    """輪郭全体の面積と周長"""
    s = next((k for k, p in enumerate(ex) if p[2]), None)
    if s is None:
        return 0.0, 0.0
    ring = ex[s:] + ex[:s] + [ex[s]]
    return _subpath_metrics(ring, 0, len(ring) - 1)



# ---------- 行きと帰りの経路が重なっているかの判定 ----------
# 面積（符号付き）だけで判定すると、オーバーラップした輪郭で8の字に交差する経路の
# 面積が打ち消し合い、本物の形状を「幅ゼロ」と誤判定する。
# そのため、行きの経路の全点が帰りの経路の近く（tol 以内）にあり、
# その逆も成り立つことを確かめる。

LEG_STEPS = 8  # 曲線を折れ線に分割する数


def _bezier_pt(ctrl, t):
    """任意次数のベジェ曲線上の点（de Casteljau）"""
    pts = list(ctrl)
    while len(pts) > 1:
        pts = [((1 - t) * p[0] + t * q[0], (1 - t) * p[1] + t * q[1])
               for p, q in zip(pts, pts[1:])]
    return pts[0]


def _subpath_poly(ex, a, b):
    """a から b までの部分経路を折れ線にする"""
    m = len(ex)
    poly = [ex[a][:2]]
    k = a
    while True:
        seg = [ex[k][:2]]
        j = (k + 1) % m
        while not ex[j][2]:
            seg.append(ex[j][:2])
            j = (j + 1) % m
        seg.append(ex[j][:2])
        if len(seg) == 2:
            poly.append(seg[1])
        else:
            poly += [_bezier_pt(seg, s / LEG_STEPS) for s in range(1, LEG_STEPS + 1)]
        k = j
        if k == b:
            return poly


def _seg_dist(p, a, b):
    """点 p と線分 ab の距離"""
    dx, dy = b[0] - a[0], b[1] - a[1]
    L = dx * dx + dy * dy
    if L == 0:
        return math.dist(p, a)
    t = max(0.0, min(1.0, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / L))
    return math.hypot(p[0] - a[0] - t * dx, p[1] - a[1] - t * dy)


def _densify(poly, step):
    """折れ線の各辺を step 以下の間隔で分割した点列"""
    out = [poly[0]]
    for p, q in zip(poly, poly[1:]):
        n = int(math.dist(p, q) / step)
        for i in range(1, n + 1):
            t = i / (n + 1)
            out.append((p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t))
        out.append(q)
    return out


def _leg_dists(samples, ref, max_tol):
    """samples の各点から折れ線 ref までの距離のリスト。
    max_tol を超える点が1つでもあれば None（その時点で打ち切る）"""
    segs = list(zip(ref, ref[1:])) or [(ref[0], ref[0])]
    out = []
    for p in samples:
        d = min(_seg_dist(p, s, e) for s, e in segs)
        if d > max_tol:
            return None
        out.append(d)
    return out


def _legs_coincide(poly, mean_tol, max_tol):
    """折れ線 poly（始点 a、終点 b）が先端で折り返し、行きと帰りが重なっているか。
    行きと帰りの経路の距離が、平均で mean_tol 以下、最大で max_tol 以下であること。
    a と b の間は弦 a–b で補う"""
    a, b = poly[0], poly[-1]
    t = max(range(len(poly)), key=lambda i: _seg_dist(poly[i], a, b))  # 先端
    if t == 0 or t == len(poly) - 1:
        return False
    out_leg, back_leg = poly[:t + 1], poly[t:]
    step = max(min(mean_tol, max_tol) / 2, 0.25)
    d1 = _leg_dists(_densify(out_leg, step), back_leg + [a], max_tol)
    if d1 is None:
        return False
    d2 = _leg_dists(_densify(back_leg, step), [b] + out_leg, max_tol)
    if d2 is None:
        return False
    d = d1 + d2
    return sum(d) / len(d) <= mean_tol


def _is_degenerate_ex(ex, mean_tol, max_tol):
    """輪郭全体が自分自身の上に折り重なっている（面積がない）か"""
    pts = [p[:2] for p in ex]
    if not pts:
        return False
    xs, ys = [p[0] for p in pts], [p[1] for p in pts]
    if math.hypot(max(xs) - min(xs), max(ys) - min(ys)) <= mean_tol:
        return True  # 点が1か所に集まっているだけ
    ons = [k for k, p in enumerate(ex) if p[2]]
    if not ons:
        return False
    # 前判定: 符号付き面積が大きい輪郭は折り重なっていない（重い判定を省く）
    area, perim = _contour_metrics(ex)
    if perim > 0 and 2 * area / perim > max_tol:
        return False
    cx, cy = sum(xs) / len(xs), sum(ys) / len(ys)
    s = max(ons, key=lambda k: math.hypot(ex[k][0] - cx, ex[k][1] - cy))  # 端の点
    ring = ex[s:] + ex[:s] + [ex[s]]
    return _legs_coincide(_subpath_poly(ring, 0, len(ring) - 1), mean_tol, max_tol)


def _seg_metrics(ex, k):
    """オンカーブ点 ex[k] から次のオンカーブ点までの区間について、
    (面積計算用の外積の寄与, 長さ) を返す"""
    m = len(ex)
    p, q = ex[k], ex[(k + 1) % m]
    if q[2]:  # 直線
        return p[0] * q[1] - q[0] * p[1], math.dist(p[:2], q[:2])
    r = ex[(k + 2) % m]  # 2次曲線（暗黙点を補ってあるので次の次は必ずオンカーブ）
    # 曲線と弦に挟まれた面積は、制御三角形の面積の 2/3
    a2 = (p[0] * r[1] - r[0] * p[1]
          + (2 / 3) * ((q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])))
    ln = (math.dist(p[:2], r[:2]) + math.dist(p[:2], q[:2]) + math.dist(q[:2], r[:2])) / 2
    return a2, ln


def _find_spike(ex, join_tol, mean_tol, max_tol):
    """オンカーブ点 a から外へ出て、同じ線をたどって b に戻ってくる部分を探す。
    条件: |ab| <= join_tol、経路長 >= 3|ab|、
          行きと帰りの経路の距離が平均 mean_tol 以下・最大 max_tol 以下、
          突起の長さ（経路長の半分）>= MIN_REACH かつ >= 平均幅の 5 倍（細長い）
    点の多い輪郭でも速く動くよう、区間ごとの面積・長さを累積和にしておき、
    候補の組は格子で近傍だけを探す。"""
    m = len(ex)
    ons = [k for k in range(m) if ex[k][2]]  # 暗黙点を含むオンカーブ点
    L = len(ons)
    if L < 2:
        return None
    pos = {k: i for i, k in enumerate(ons)}
    # 累積和（周回に対応するため 2 周分）
    segs = [_seg_metrics(ex, k) for k in ons]
    A, S = [0.0], [0.0]
    for t in range(2 * L):
        a2, ln = segs[t % L]
        A.append(A[-1] + a2)
        S.append(S[-1] + ln)
    # 近傍探索用の格子（実在するオンカーブ点だけ）
    cell = max(join_tol, 1.0)
    real = [k for k in ons if ex[k][3] is not None]
    grid = {}
    for k in real:
        grid.setdefault((math.floor(ex[k][0] / cell), math.floor(ex[k][1] / cell)), []).append(k)

    best = None
    for a in real:
        pa = ex[a]
        gx, gy = math.floor(pa[0] / cell), math.floor(pa[1] / cell)
        ia = pos[a]
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                for b in grid.get((gx + dx, gy + dy), ()):
                    span = (b - a) % m
                    if span < 2 or m - span < 3:
                        continue
                    if best is not None and span >= best[2]:
                        continue  # 間の点がより少ない候補がすでにある
                    pb = ex[b]
                    chord = math.dist(pa[:2], pb[:2])
                    if chord > join_tol:
                        continue
                    ib = pos[b]
                    jb = ib if ib > ia else ib + L
                    length = S[jb] - S[ia]
                    if length <= 0 or length < 3 * chord:
                        continue  # 行って戻る形ではない
                    area = abs(A[jb] - A[ia] + pb[0] * pa[1] - pa[0] * pb[1]) / 2
                    width = 2 * area / length
                    if width > max_tol:
                        continue  # 前判定: 面積から見て幅がある（本物の形状）
                    reach = length / 2
                    if reach < MIN_REACH or reach < 5 * width:
                        continue  # 細長くない（小さな凹凸は残す）
                    if all(ex[(a + k) % m][3] is None for k in range(1, span)):
                        continue  # 間に削除できる点がない
                    if _leaves_hairpin(ex, a, b):
                        continue  # つないだ後に折り返しが残る（もっと外側の点を使うべき）
                    if not _legs_coincide(_subpath_poly(ex, a, b), mean_tol, max_tol):
                        continue  # 行きと帰りが重なっていない（本物の形状）
                    best = (a, b, span)
    return best


def remove_spikes(g, join_tol, mean_tol, max_tol):
    """単純グリフからスパイクと、面積がほぼゼロの輪郭を取り除く。削除した点の数を返す"""
    coords, flags = list(g.coordinates), list(g.flags)
    kept = []  # (座標, フラグ) の輪郭ごとのリスト
    removed, start = 0, 0
    for end in g.endPtsOfContours:
        c, f = coords[start:end + 1], flags[start:end + 1]
        start = end + 1
        while len(c) >= 3:
            ex = _expand(c, f)
            sp = _find_spike(ex, join_tol, mean_tol, max_tol)
            if sp is None:
                break
            a, b, span = sp
            m = len(ex)
            # a と b の間の点を削除し、a→b を直線でつなぐ（a, b は残す）
            drop = {ex[(a + k) % m][3] for k in range(1, span)} - {None}
            if math.dist(ex[a][:2], ex[b][:2]) <= MERGE_DIST:
                drop.add(ex[b][3])  # a と b がほぼ同じ位置なら b も削除
            c = [pt for i, pt in enumerate(c) if i not in drop]
            f = [fl for i, fl in enumerate(f) if i not in drop]
            removed += len(drop)
        kept.append((c, f))

    # 自分自身の上に折り重なった（面積のない）輪郭を削除。1点だけの輪郭は残す
    def degenerate(cf):
        c, f = cf
        return len(c) >= 2 and _is_degenerate_ex(_expand(c, f), mean_tol, max_tol)
    rest = [cf for cf in kept if not degenerate(cf)]
    if rest and len(rest) < len(kept):  # すべて消える場合は何もしない
        removed += sum(len(c) for c, _ in kept) - sum(len(c) for c, _ in rest)
        kept = rest

    if removed:
        new_c, new_f, new_e = [], [], []
        for c, f in kept:
            new_c += c
            new_f += f
            new_e.append(len(new_c) - 1)
        g.coordinates = GlyphCoordinates(new_c)
        g.flags = array("B", new_f)
        g.endPtsOfContours = new_e
        g.numberOfContours = len(new_e)
    return removed


# ---------- 亀裂（ほぼ重なった辺の隙間）の修正 ----------
# ChangeWeight などで座標が小数になった後にオーバーラップ除去がかかると、
# 同じ画や懐を構成する2つの輪郭が、わずかにずれた辺（0.1〜0.5 ユニット程度）で接したまま
# 残る。その隙間が白い亀裂や、懐の中の黒い細い線として見える。
# 別の輪郭の辺から snap 以内にある点をその辺の上に移してから輪郭を合体させると、
# 辺が一致するので境目が消える。

def _snap_points(g, glyf, snap):
    """別の輪郭の辺（制御多角形の線分）から snap 以内にある点を、その辺の上に移す。
    移した点があれば新しい座標のリスト、なければ None を返す"""
    co, ends, _ = g.getCoordinates(glyf)
    pts = [(float(x), float(y)) for x, y in co]
    contours, s = [], 0
    for e in ends:
        contours.append(list(range(s, e + 1)))
        s = e + 1
    if len(contours) < 2:
        return None
    # 線分を格子に登録（近くの線分だけを調べるため）
    cell = max(snap * 16, 16.0)
    grid = {}
    for ci, C in enumerate(contours):
        for k in range(len(C)):
            a, b = pts[C[k]], pts[C[(k + 1) % len(C)]]
            n = int(math.dist(a, b) / cell) + 1
            cells = {(math.floor((a[0] + (b[0] - a[0]) * t / n) / cell),
                      math.floor((a[1] + (b[1] - a[1]) * t / n) / cell))
                     for t in range(n + 1)}
            for c in cells:
                grid.setdefault(c, []).append((ci, a, b))
    new, moved = list(pts), 0
    for ci, C in enumerate(contours):
        for i in C:
            p = pts[i]
            gx, gy = math.floor(p[0] / cell), math.floor(p[1] / cell)
            best = None
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    for cj, a, b in grid.get((gx + dx, gy + dy), ()):
                        if cj == ci:
                            continue
                        vx, vy = b[0] - a[0], b[1] - a[1]
                        L = vx * vx + vy * vy
                        t = 0.0 if L == 0 else max(0.0, min(1.0, ((p[0] - a[0]) * vx + (p[1] - a[1]) * vy) / L))
                        q = (a[0] + t * vx, a[1] + t * vy)
                        d = math.dist(p, q)
                        if best is None or d < best[0]:
                            best = (d, q)
            if best is not None and 0 < best[0] <= snap:
                new[i] = best[1]
                moved += 1
    return new if moved else None


def fix_cracks(g, glyf, snap):
    """点を吸着させてから輪郭を合体させた新しいグリフを返す。対象外・失敗時は None"""
    new_pts = _snap_points(g, glyf, snap)
    if new_pts is None:
        return None
    h = copy.deepcopy(g)
    h.coordinates = GlyphCoordinates(new_pts)
    path = pathops.Path()
    h.draw(path.getPen(), glyf)
    try:
        res = pathops.simplify(path, clockwise=path.clockwise)
    except pathops.PathOpsError:
        # 小数座標で失敗する skia-pathops の既知の問題への対処: 整数に丸めて再試行
        rp = pathops.Path()
        for verb, pts in path:
            rp.add(verb, *((round(x), round(y)) for x, y in pts))
        try:
            res = pathops.simplify(rp, clockwise=rp.clockwise)
        except pathops.PathOpsError:
            return None
    pen = TTGlyphPen(None)
    res.draw(pen)
    out = pen.glyph()
    out.recalcBounds(glyf)
    return out if out.numberOfContours > 0 else None


# ---------- 直線上・重複点の除去 ----------

def is_redundant(a, p, c, tol):
    """a→p→c が一直線（距離 tol 以内）で、p が a と c の間にあるか"""
    ax, ay = p[0] - a[0], p[1] - a[1]
    cx, cy = c[0] - p[0], c[1] - p[1]
    length = math.hypot(c[0] - a[0], c[1] - a[1])
    if length == 0:
        return False
    cross = abs(ax * cy - ay * cx)  # = 直線 a-c からの距離 × length
    return cross <= tol * length and (ax * cx + ay * cy) >= 0


def clean_contour(contour, tol):
    move, end, segs = contour[0], contour[-1], list(contour[1:-1])
    start = move[1][0]
    closed = end[0] == "closePath"

    # 長さゼロの lineTo を削除
    cur, tmp = start, []
    for op, args in segs:
        if op == "lineTo" and math.dist(cur, args[0]) <= tol:
            continue
        tmp.append((op, args))
        cur = args[-1]
    segs = tmp

    # 直線上の中間点を削除（変化がなくなるまで）
    changed = True
    while changed:
        changed = False
        prev = start
        for k, (op, args) in enumerate(segs):
            if op != "lineTo":
                prev = args[-1]
                continue
            p = args[0]
            if k + 1 < len(segs):
                nop, nargs = segs[k + 1]
                if nop != "lineTo":
                    prev = p
                    continue
                nxt = nargs[0]
            elif closed:
                nxt = start  # 閉じる線分の行き先は始点
            else:
                break
            if is_redundant(prev, p, nxt, tol):
                del segs[k]
                changed = True
                break
            prev = p
    return [move] + segs + [end]


def clean_recording(value, tol):
    out, contour = [], []
    for op, args in value:
        if op == "addComponent":
            out.append((op, args))
            continue
        contour.append((op, args))
        if op in ("closePath", "endPath"):
            out.extend(clean_contour(contour, tol))
            contour = []
    out.extend(contour)
    return out


# ---------- 点番号参照のチェック ----------

def point_matched_glyphs(glyf):
    """点番号で配置された複合グリフが参照するグリフ名の集合"""
    protected = set()
    for name in glyf.keys():
        g = glyf[name]
        if not g.isComposite():
            continue
        if any(not hasattr(c, "x") for c in g.components):
            protected.update(c.glyphName for c in g.components)
    return protected


def has_point_anchors(font):
    """GPOS の AnchorFormat2、または GDEF の CaretValue Format2 が含まれるか"""
    for tag, cls in (("GPOS", "Anchor"), ("GDEF", "CaretValue")):
        if tag not in font:
            continue
        seen, stack = set(), [font[tag].table]
        while stack:
            obj = stack.pop()
            if id(obj) in seen:
                continue
            seen.add(id(obj))
            if isinstance(obj, (list, tuple)):
                stack.extend(obj)
            elif hasattr(obj, "__dict__"):
                if type(obj).__name__ == cls and getattr(obj, "Format", None) == 2:
                    return True
                stack.extend(v for v in vars(obj).values()
                             if isinstance(v, (list, tuple)) or hasattr(v, "__dict__"))
    return False


# ---------- 除外リスト ----------

def load_exclude_list(path):
    """除外リストを読み、コードポイントの集合を返す。
    書式: 1行に1項目。"0020"（単独）または "0021..0023"（範囲、両端を含む）。16進数。
    行頭が # の行と空行は無視する。"""
    codes = set()
    with open(path, encoding="utf-8-sig") as f:
        for lineno, raw in enumerate(f, 1):
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            try:
                if ".." in line:
                    lo, hi = (int(v, 16) for v in line.split("..", 1))
                    if lo > hi:
                        raise ValueError
                    codes.update(range(lo, hi + 1))
                else:
                    codes.add(int(line, 16))
            except ValueError:
                sys.exit(f"error: {path} line {lineno}: invalid entry: {line}")
    return codes


def excluded_glyphs(font, codes):
    """除外するコードポイントに割り当てられたグリフ名の集合"""
    names = set()
    for table in font["cmap"].tables:
        if table.isUnicode():
            names.update(g for cp, g in table.cmap.items() if cp in codes)
    return names


# ---------- 修正したグリフの一覧（--report） ----------

REPORT_PER_LINE = 40  # 1行に並べる文字数

# 表示しても見えない（または改行などになる）文字の一般カテゴリ
_INVISIBLE = {"Cc", "Cf", "Cs", "Zs", "Zl", "Zp"}


def write_report(font, path, sections):
    """sections: [(見出し, グリフ名の集合)]。各グリフを文字として並べたテキストを書き出す"""
    rev = {}  # グリフ名 → 割り当てられた最小のコードポイント
    for cp, name in (font.getBestCmap() or {}).items():
        if name not in rev or cp < rev[name]:
            rev[name] = cp
    lines = []
    for title, names in sections:
        lines.append(f"# {title}: {len(names)} glyphs")
        chars, others = [], []
        for cp, name in sorted((rev[n], n) for n in names if n in rev):
            cat = unicodedata.category(chr(cp))
            if cat in _INVISIBLE:
                others.append(f"U+{cp:04X} {name}")
            elif cat.startswith("M"):
                chars.append(" " + chr(cp))  # 結合文字は NBSP に乗せて表示
            else:
                chars.append(chr(cp))
        others += sorted(n for n in names if n not in rev)
        for i in range(0, len(chars), REPORT_PER_LINE):
            lines.append("".join(chars[i:i + REPORT_PER_LINE]))
        if others:
            lines.append("## Not displayable / no code point:")
            lines += others
        lines.append("")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))


# ---------- メイン ----------

def main():
    ap = argparse.ArgumentParser(description=DESCRIPTION,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("input")
    ap.add_argument("output")
    ap.add_argument("--tol", type=float, default=0.0,
                    help="tolerance for collinearity in font units "
                         "(0 = outlines stay identical; > 0 also allows the "
                         "bounding box to shrink by up to ceil(TOL) per side)")
    ap.add_argument("--allow-half", action="store_true",
                    help="also drop on-curve points whose implied midpoint is "
                         "at x.5 (fontTools default behavior; allows up to "
                         "0.5 unit deviation)")
    ap.add_argument("--spikes", action="store_true",
                    help="remove zero-width spikes and zero-area contours "
                         "(changes the outline)")
    ap.add_argument("--spike-width", type=float, default=1.0,
                    help="max AVERAGE distance between the outgoing and returning "
                         "sides of a spike, in font units (default 1)")
    ap.add_argument("--spike-max-width", type=float, default=3.0,
                    help="max distance at any point between the outgoing and "
                         "returning sides of a spike, in font units (default 3)")
    ap.add_argument("--spike-join", type=float, default=32.0,
                    help="max distance between the point where a spike leaves "
                         "the outline and the point where it returns (default 32)")
    ap.add_argument("--fix-cracks", action="store_true",
                    help="merge contours whose edges almost coincide, removing "
                         "hairline cracks (requires skia-pathops; also removes "
                         "spikes in the merged glyphs)")
    ap.add_argument("--crack-snap", type=float, default=1.0,
                    help="max distance in font units for snapping a point onto "
                         "an edge of another contour (default 1)")
    ap.add_argument("--force", action="store_true",
                    help="continue even if GPOS/GDEF reference point numbers")
    ap.add_argument("-v", "--verbose", action="store_true",
                    help="print the result for each glyph")
    ap.add_argument("--report", metavar="FILE",
                    help="write a UTF-8 text file listing the glyphs whose "
                         "cracks were fixed or spikes were removed, as characters")
    args = ap.parse_args()

    font = TTFont(args.input)
    if "glyf" not in font:
        sys.exit("error: not a TrueType (glyf) font")
    if "fvar" in font:
        sys.exit("error: variable fonts are not supported")
    if has_point_anchors(font) and not args.force:
        sys.exit("error: GPOS/GDEF reference point numbers (AnchorFormat2 or "
                 "CaretValue Format2); "
                 "removing points would break them (use --force to continue)")

    glyf = font["glyf"]

    # 処理前に glyf に記録されている xMin（描画位置は「xMin − LSB」で決まるため、
    # 保存時に fontTools が bbox を計算し直して xMin が変わったら LSB も合わせる）
    stored_xmin = {n: glyf[n].xMin for n in font.getGlyphOrder()
                   if glyf[n].numberOfContours != 0}
    gs = font.getGlyphSet()
    protected = point_matched_glyphs(glyf)

    excluded = set()
    if os.path.exists(EXCLUDE_LIST_FILE):
        codes = load_exclude_list(EXCLUDE_LIST_FILE)
        excluded = excluded_glyphs(font, codes)
        print(f"Exclude list: {EXCLUDE_LIST_FILE} "
              f"({len(codes)} code points, {len(excluded)} glyphs)", flush=True)

    # 亀裂の修正（--fix-cracks）: 他の処理の前に、対象グリフの輪郭を合体させておく
    merged, skipped_crack = set(), []
    if args.fix_cracks:
        if pathops is None:
            sys.exit("error: --fix-cracks requires skia-pathops "
                     "(pip install skia-pathops)")
        pad = math.ceil(args.crack_snap)
        for name in font.getGlyphOrder():
            g = glyf[name]
            if g.isComposite() or g.numberOfContours < 2 or name in protected \
                    or name in excluded:
                continue
            out = fix_cracks(g, glyf, args.crack_snap)
            if out is None:
                continue
            ref = copy.deepcopy(g)
            ref.recalcBounds(glyf)
            # 吸着で動くのは最大 crack_snap なので、bbox がそれ以上変わる場合は元のまま残す
            if not (ref.xMin - pad <= out.xMin and ref.yMin - pad <= out.yMin
                    and out.xMax <= ref.xMax + pad and out.yMax <= ref.yMax + pad):
                skipped_crack.append(name)
                if args.verbose:
                    print(f"Skipped (cracks, bounding box would change): {name} "
                          f"{(ref.xMin, ref.yMin, ref.xMax, ref.yMax)} -> "
                          f"{(out.xMin, out.yMin, out.xMax, out.yMax)}", flush=True)
                continue
            if args.verbose:
                print(f"Cracks fixed: {name} (contours {g.numberOfContours} -> "
                      f"{out.numberOfContours})", flush=True)
            glyf[name] = out
            merged.add(name)
        gs = font.getGlyphSet()  # 置き換えたグリフを反映

    total_before = total_after = 0
    n_line = n_implied = n_spike = n_tol_bbox = 0
    spiked = []
    skipped_bbox = []

    for name in font.getGlyphOrder():
        g = glyf[name]
        if g.isComposite() or g.numberOfContours <= 0 or name in protected \
                or name in excluded:
            continue

        coords, _, _ = g.getCoordinates(glyf)
        before = len(coords)
        # 比較の基準は、記録値ではなく点の座標から計算し直した bbox
        # （記録値が点の座標と食い違っているフォントがあるため）
        ref = copy.deepcopy(g)
        ref.recalcBounds(glyf)
        bbox = (ref.xMin, ref.yMin, ref.xMax, ref.yMax)
        overlap = bool(g.flags[0] & OVERLAP_SIMPLE) if g.flags else False

        # 0: スパイク（--spikes 指定時のみ）
        src, ns = g, 0
        if args.spikes or name in merged:  # 合体させたグリフは細い切れ端も取り除く
            src = copy.deepcopy(g)
            ns = remove_spikes(src, args.spike_join, args.spike_width,
                               args.spike_max_width)

        # 1 + 2: 重複点・直線上の点
        rec = RecordingPen()
        if ns:
            src.draw(rec, glyf)
        else:
            gs[name].draw(rec)
        pen = TTGlyphPen(None)
        replayRecording(clean_recording(rec.value, args.tol), pen)
        new = pen.glyph()
        mid = len(new.getCoordinates(glyf)[0])

        # 3: 暗黙オンカーブ点
        if args.allow_half:
            dropImpliedOnCurvePoints(new)
        else:
            drop_exact_implied(new)
        new.recalcBounds(glyf)
        after = len(new.getCoordinates(glyf)[0])

        # 安全確認: バウンディングボックスが変わったら元に戻す
        # （スパイクを削除した場合は、元の bbox の内側に縮むことだけを許す。
        #   --tol > 0 の場合は、各辺が許容値以内で内側に縮むことだけを許す）
        nb = (new.xMin, new.yMin, new.xMax, new.yMax)
        shrink = (nb[0] - bbox[0], nb[1] - bbox[1], bbox[2] - nb[2], bbox[3] - nb[3])
        inside = all(d >= 0 for d in shrink)
        within_tol = False
        if ns:
            bad = not inside
        elif nb == bbox:
            bad = False
        else:
            # 1点だけの輪郭などが消えて輪郭の数が減った場合は、許容値に関係なく除外する
            within_tol = (args.tol > 0 and inside
                          and new.numberOfContours == g.numberOfContours
                          and max(shrink) <= math.ceil(args.tol))
            bad = not within_tol
        if within_tol:
            n_tol_bbox += 1
            if args.verbose:
                print(f"Bounding box changed within tolerance: {name} "
                      f"{bbox} -> {nb}", flush=True)
        if bad:
            skipped_bbox.append(name)
            # 除外した時点で1グリフずつ表示する（--verbose 指定時）
            if args.verbose:
                print(f"Skipped (bounding box would change): {name} "
                      f"{bbox} -> {nb}", flush=True)
            continue

        if overlap and new.flags:
            new.flags[0] |= OVERLAP_SIMPLE

        glyf[name] = new
        if ns:
            n_spike += ns
            spiked.append(name)
            # 除去を確定した時点で1グリフずつ表示する（--verbose 指定時）
            if args.verbose:
                print(f"Spike removed: {name} ({ns} points)", flush=True)
        n_line += before - ns - mid
        n_implied += mid - after
        total_before += before
        total_after += after

    # 保存時に計算し直される xMin に合わせて LSB を補正する（送り幅はそのまま）。
    # 処理したグリフだけでなく、記録された bbox が点の座標と食い違っていたグリフや、
    # 部品が変わった複合グリフも対象になる。
    n_lsb = 0
    for name, old in stored_xmin.items():
        g = copy.deepcopy(glyf[name])
        g.recalcBounds(glyf)
        if g.numberOfContours != 0 and g.xMin != old:
            adv, lsb = font["hmtx"][name]
            font["hmtx"][name] = (adv, lsb + g.xMin - old)
            n_lsb += 1
            if args.verbose:
                print(f"LSB adjusted: {name} {lsb} -> {lsb + g.xMin - old} "
                      f"(xMin {old} -> {g.xMin})", flush=True)

    font.save(args.output)

    if args.report:
        sections = []
        if args.fix_cracks:
            sections.append(("Cracks fixed", merged))
        if args.spikes or spiked:
            sections.append(("Spikes removed", set(spiked)))
        if args.fix_cracks or args.spikes:
            sections.append(("All (cracks or spikes)", merged | set(spiked)))
        write_report(font, args.report, sections)

    if args.fix_cracks:
        print(f"Cracks fixed (contours merged): {len(merged)} glyphs")
        if skipped_crack:
            print(f"Skipped (cracks, bounding box would change): "
                  f"{len(skipped_crack)} glyphs")
    if args.spikes:
        print(f"Spike points removed:               {n_spike} "
              f"({len(spiked)} glyphs)")
    print(f"Collinear/duplicate points removed: {n_line}")
    print(f"Implied on-curve points removed:    {n_implied}")
    if total_before:
        print(f"Total points: {total_before} -> {total_after} "
              f"({(total_before - total_after) / total_before:.1%} reduction)")
    if excluded:
        print(f"Skipped (exclude list): {len(excluded)} glyphs")
    if protected:
        print(f"Skipped (referenced by point-matched components): "
              f"{len(protected)} glyphs")
    if n_tol_bbox:
        print(f"Bounding box changed within tolerance: {n_tol_bbox} glyphs")
    if skipped_bbox:
        print(f"Skipped (bounding box would change): {len(skipped_bbox)} glyphs")
    if n_lsb:
        print(f"LSB adjusted: {n_lsb} glyphs")
    print(f"Saved: {args.output}")
    if args.report:
        print(f"Report: {args.report}")


if __name__ == "__main__":
    main()
