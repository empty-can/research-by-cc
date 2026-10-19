#!/usr/bin/env python3
"""UTF-8/LF（開発・Linux 向け） ⇄ CP932/CRLF（Windows 向け）変換ヘルパー。

Claude Code のネイティブ Read/Edit/Write は UTF-8 前提のため、CP932 ファイルを
直接読み書きすると文字化け・破損する。本スクリプトはその境界を安全に往復する。

使い方（1 回の実行で 1 ファイル）:
  python convert_encoding.py --to-win  <file>   # UTF-8/LF  -> CP932/CRLF
  python convert_encoding.py --to-unix <file>   # CP932/CRLF -> UTF-8/LF

オプション:
  --restore     --to-unix 時に、--to-win の正規化を逆写像で復元する（既定 OFF）。
                全角ハイフン・水平バー等は正規の和字でもあるため、既定では逆変換しない。
                自分で --to-win した直後に完全な round-trip を戻したい時だけ使う。
  --map <path>  マッピング表 JSON のパス（既定: ../references/cp932-mapping.json）。
  --check       変換せず、CP932 でエンコード不可な文字の有無だけ報告する（--to-win 専用。
                --to-unix と併用するとファイルに触れずにエラー終了する）。

設計:
  - --to-win は forward マップ（波ダッシュ→全角チルダ 等）を適用後 cp932 へエンコード。
    cp932 で表現できない文字が残れば「行・文字・コードポイント」を列挙して非ゼロ終了し、
    黙ってデータを失わない（マッピング表に追記して再実行する運用）。
  - 入力が想定の文字コードで読めないときも、書き換えずに非ゼロ終了する。--to-unix は
    既に UTF-8 に見える入力（BOM 付き、または UTF-8 として読めて非 ASCII を含む）を拒否する。
    UTF-8 の日本語は CP932 としても読めてしまうことがあり、通すと黙って化ける
    （判定は hooks/bat_cp932_guard.py の looks_like_utf8 と同じ）。
  - ASCII 記号（\\ ~ 等）はマップに含めない＝不変。スクリプト構文を壊さない。
  - 改行は一旦 LF へ正規化してから目的の改行へ統一する（CR/CRLF 混在を吸収）。
  - 読み書きはバイト単位で行い、OS の改行自動変換に依存しない（決定論的）。
"""
import argparse
import json
import sys
from pathlib import Path

# Windows の Python はパイプへ ANSI コードページ（日本語環境なら cp932）で書くため、
# 呼び出し元（Claude のシェルツール）が UTF-8 として読むと報告が化ける。hooks と同じく UTF-8 に固定する。
for _stream in (sys.stdout, sys.stderr):
    try:
        _stream.reconfigure(encoding="utf-8", errors="backslashreplace")
    except (AttributeError, ValueError):  # pragma: no cover - very old Python
        pass

DEFAULT_MAP = Path(__file__).resolve().parent.parent / "references" / "cp932-mapping.json"
UTF8_BOM = b"\xef\xbb\xbf"


def load_maps(map_path):
    data = json.loads(Path(map_path).read_text(encoding="utf-8"))
    to_win_map = {ord(k): v for k, v in data.get("to_win", {}).items()}
    to_unix_map = {ord(k): v for k, v in data.get("to_unix", {}).items()}
    return to_win_map, to_unix_map


def normalize_newlines(text):
    """CR/CRLF 混在を一旦 LF に揃える。"""
    return text.replace("\r\n", "\n").replace("\r", "\n")


def looks_like_utf8(raw):
    """BOM 付き、または UTF-8 として読めて非 ASCII を含むなら UTF-8 とみなす。"""
    if raw.startswith(UTF8_BOM):
        return True
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        return False
    return any(ord(ch) > 127 for ch in text)


def cmd_to_win(path, to_win_map, check=False):
    raw = Path(path).read_bytes()
    if raw.startswith(UTF8_BOM):  # UTF-8 BOM は除去（CP932 に BOM は無い）
        raw = raw[len(UTF8_BOM):]
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError as exc:
        sys.stderr.write(
            f"[NG] {path}: UTF-8 として読めない（{exc}）。既に CP932 で保存されている可能性がある。"
            f"変換していない\n"
        )
        return 1
    text = normalize_newlines(text)
    text = text.translate(to_win_map)

    bad = []
    for lineno, line in enumerate(text.split("\n"), 1):
        for ch in line:
            try:
                ch.encode("cp932")
            except UnicodeEncodeError:
                bad.append((lineno, ch, f"U+{ord(ch):04X}"))
    if bad:
        sys.stderr.write("[NG] CP932 にエンコードできない文字があります（マッピング表に追加してください）:\n")
        for lineno, ch, cp in bad:
            sys.stderr.write(f"    line {lineno}: {ch!r} {cp}\n")
        return 1
    if check:
        print(f"[OK] {path}: 全文字 CP932 エンコード可能")
        return 0

    out = text.replace("\n", "\r\n").encode("cp932")
    Path(path).write_bytes(out)
    print(f"[to-win] {path} を CP932/CRLF で上書き保存しました")
    return 0


def cmd_to_unix(path, to_unix_map, restore=False):
    raw = Path(path).read_bytes()
    if looks_like_utf8(raw):
        sys.stderr.write(
            f"[NG] {path}: 既に UTF-8 で保存されているように見える（BOM 付き、または UTF-8 として読めて"
            f"非 ASCII を含む）。CP932 として読むと化けるため変換していない\n"
        )
        return 1
    try:
        text = raw.decode("cp932")
    except UnicodeDecodeError as exc:
        sys.stderr.write(f"[NG] {path}: CP932 として読めない（{exc}）。変換していない\n")
        return 1
    text = normalize_newlines(text)
    if restore:
        text = text.translate(to_unix_map)
    Path(path).write_bytes(text.encode("utf-8"))
    note = "（authoring 復元あり）" if restore else ""
    print(f"[to-unix] {path} を UTF-8/LF で上書き保存しました{note}")
    return 0


def main():
    ap = argparse.ArgumentParser(description="UTF-8/LF ⇄ CP932/CRLF 変換ヘルパー")
    grp = ap.add_mutually_exclusive_group(required=True)
    grp.add_argument("--to-win", action="store_true", help="UTF-8/LF -> CP932/CRLF")
    grp.add_argument("--to-unix", action="store_true", help="CP932/CRLF -> UTF-8/LF")
    ap.add_argument("--restore", action="store_true", help="--to-unix 時に逆写像を適用（既定 OFF）")
    ap.add_argument("--check", action="store_true", help="変換せず CP932 エンコード可否のみ報告（--to-win 専用）")
    ap.add_argument("--map", default=str(DEFAULT_MAP), help="マッピング表 JSON のパス")
    ap.add_argument("file", help="対象ファイル（1 つ）")
    args = ap.parse_args()
    # --to-unix に検査専用モードは無い。黙って無視すると「検査のつもりで変換される」ので止める。
    if args.check and not args.to_win:
        ap.error("--check は --to-win と併用する（ファイルには触れていない）")

    to_win_map, to_unix_map = load_maps(args.map)
    if args.to_win:
        return cmd_to_win(args.file, to_win_map, check=args.check)
    return cmd_to_unix(args.file, to_unix_map, restore=args.restore)


if __name__ == "__main__":
    sys.exit(main())
