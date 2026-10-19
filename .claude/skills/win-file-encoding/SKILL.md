---
name: win-file-encoding
description: >
  CP932 と UTF-8 の一括変換・検査を行う手動ツール。日本語を含む `.bat` を CP932/CRLF へ変換する
  （UTF-8 で保存されてしまった `.bat` の修復を含む）、既存の CP932 ファイル群を UTF-8 へ移行する、
  CP932 でエンコードできない文字が混じっていないか事前検査する、といった一括作業に使う。
  日常の `.bat` 編集では不要（hook が自動処理する）。
---

# win-file-encoding（CP932 ⇄ UTF-8 の一括変換・検査ツール）

> **日常の `.bat` 編集にこの skill は不要**。`.claude/hooks/bat_cp932_guard.py` が原本を隠して UTF-8 の
> 作業コピーを見せ、保存時に CP932 + CRLF へ書き戻す。手順は `.claude/rules/win-file-encoding.md` を見ること。
> 本 skill は**一括変換・移行・事前検査**という、hook では扱えないまとまった作業のための手動ツール。

保存形式の方針（**原則 UTF-8。CP932 は `.bat` だけの例外**。`.ps1` は UTF-8 + BOM + CRLF で、変換不要）は
`.claude/rules/win-file-encoding.md` が正本。本 skill はその方針を**実行する道具**であって、方針を決めない。

## 実行パス（最初に確認）

スクリプトは skill に同梱されている。下のコマンドの先頭は skill 変数 `CLAUDE_SKILL_DIR`（この `SKILL.md` が
あるディレクトリ。Claude Code が skill の読み込み時に本文中で展開する・v2.1.69〜）で指してあるので、skill の
置き場所（プロジェクトの `.claude/skills/`・plugin など）にも CWD にも依存しない:

```
python "${CLAUDE_SKILL_DIR}/scripts/convert_encoding.py" <オプション> "<file>"
```

- 実行コマンドは **`python`**（Windows では `python3` が PATH に無い環境があるため）。変数代入を使わない
  1 行なので、Bash でも PowerShell（Windows では Claude の主シェル）でもそのまま動く。
- skill を経由せず手で実行するとき（変数が展開されない）は、リポジトリのルートを CWD にして
  `.claude/skills/win-file-encoding/scripts/convert_encoding.py` を指す（hook のメッセージもこのパス）。
- マッピング表 `references/cp932-mapping.json` はスクリプトが `__file__` 基準で自動解決する。

## 使いどころ

| 場面 | オプション |
|---|---|
| **事前検査**: CP932 でエンコードできない文字が無いか調べる（**変換しない**） | `--to-win --check "<file>"` |
| **CP932 化**: UTF-8/LF で書いた `.bat` を Windows 形（CP932/CRLF・BOM なし）へ。hook が「UTF-8 で保存されているように見える」として Read を止めた `.bat` の修復もこれ | `--to-win "<file>"` |
| **UTF-8 化**: 既存の CP932 ファイル（`.bat` 以外）を UTF-8/LF へ移行する | `--to-unix "<file>"` |

- **1 回の実行で 1 ファイル**（ディレクトリは渡せない）。一括で処理するときはシェルで回し、失敗したら止める:
  - Bash: `for f in <dir>/*.txt; do python "${CLAUDE_SKILL_DIR}/scripts/convert_encoding.py" --to-unix "$f" || break; done`
  - PowerShell: `foreach ($f in Get-ChildItem <dir> -Filter *.txt) { python "${CLAUDE_SKILL_DIR}/scripts/convert_encoding.py" --to-unix $f.FullName; if ($LASTEXITCODE -ne 0) { break } }`
- `--to-win` は UTF-8→CP932 の正規化（`〜→～` / `—→―` 等・`references/cp932-mapping.json` の `to_win`）と
  LF→CRLF を適用して上書きする。**ASCII 記号（`\` `~` 等）は不変**なのでスクリプト構文を壊さない。
- `--to-win` が CP932 エンコード不可文字を報告したら**放置しない**。`⚠` `✓` のように CP932 に符号位置が無い
  記号は ASCII（`[!]` / `[OK]`）へ置き換える。和字で対応字があるものは `cp932-mapping.json` に追記する。
- `--check` は `--to-win` 専用。`--to-unix` と併用するとファイルに触れずにエラー終了する。
- `--to-unix` に `--restore` を付けると `to_unix` の逆写像も適用する（既定 OFF。全角ハイフン等は正規の和字
  でもあり、無条件の逆変換は誤変換を招くため）。
- **失敗したら（exit 1）ファイルは書き換えない**: CP932 にできない文字がある／`--to-win` の入力が UTF-8 として
  読めない（既に CP932 の可能性）／`--to-unix` の入力が CP932 として読めない、または既に UTF-8 に見える
  （BOM 付き、または UTF-8 として読めて非 ASCII を含む。hook と同じ判定）。`--to-unix` が読むのは CP932 だけで、
  Windows-1252 等の別のレガシー文字コードは CP932 として読めてしまい化けることがあるので、CP932 と分かっている
  ファイルにだけ使う。
- **`.bat` に `--to-win` した後は、その `.bat` の作業コピー（`.claude/.bat-shadow/`）が古くなる**。編集を続ける
  前に原本を Read し直すか `python .claude/hooks/bat_cp932_guard.py sync` を実行する（古い作業コピーを保存しても
  hook が書き戻しを拒否するので、原本は壊れない）。`.bat` をスクリプトで書き換えないという rule の禁止は、
  CP932 + CRLF で書く本スクリプト（と hook の `new`）を例外とする。
- `Edit` / `Write` が **`File is not valid UTF-8`** で拒否したファイル（CP932 の `.txt` 等）は、拒否メッセージの
  とおり**UTF-8 化してよいか利用者に確認してから** `--to-unix` で移行できる。CP932 のまま残すべきもの
  （`.bat`、Win32 プロファイル用途の `.ini` 等）は移行しない。

## ⛔ 適用してはいけないもの

- **`.ps1` / `.psm1` / `.psd1`**: 正解は **UTF-8 + BOM + CRLF**。`--to-win` は CP932・BOM なしで書き出すため、
  PowerShell 7 が UTF-8 として読んで日本語リテラルが壊れる（rule の実測: `'こんにちは'.Length` が 5 → 8）。
  `--to-unix` も BOM を付けないので、移行したら UTF-8 + BOM + CRLF に直さないと Windows PowerShell 5.1 が
  CP932 と誤読する。
- **`.bat` への `--to-unix`**: `.bat` は CP932 が正解。UTF-8 にすると cmd.exe が誤動作し、hook も Read を止める。
  中身を読む・直すには hook の作業コピーを使う。
- **改行だけを直したいファイル**: 本 skill は文字コードも変える。改行は `.gitattributes` が拡張子ごとに固定する
  （判断手順は `git check-attr text eol -- <path>`）ので、改行だけの問題に本 skill を使わない（`.gitattributes` が
  CRLF を指定している `.bat` でも、文字コードの変換は別途必要）。
- **`.csv`**: 正解は UTF-8 + BOM（Excel は BOM を見て UTF-8 と判定する）。`--to-unix` は BOM を付けない。
- **`.reg`**: `permissions.deny` で Claude の R/W を禁止しているスコープ外資産（UTF-16LE + BOM が要求される形式）。
- **`.ini`**: 拡張子だけでは文字コードを決められない（`tox.ini` / `pytest.ini` のように **UTF-8 が正しい `.ini`**
  が広く存在する）。**deny もしていない**。Win32 プロファイル用途の CP932 な `.ini` を変換するときだけ、
  対象を 1 ファイルずつ指定して使うこと。

## 依存・仕様

- `python`（CPython 3.x。`cp932` コーデックは標準同梱。hook と合わせた要件は 3.10 以上 ――
  `.claude/rules/win-file-encoding.md`）。
- 改行は CR/CRLF 混在を一旦 LF に正規化してから目的の改行へ統一する（決定論的）。
- 報告は UTF-8 で出力する（Windows の Python は既定でパイプへ CP932 で書き、シェルツールの出力が化けるため）。
- 背景と化け文字の根拠は `references/mojibake-notes.md`。
