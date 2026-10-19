---
paths:
  - "**/*.ps1"
  - "**/*.ps1.template"
  - "**/*.psm1"
  - "**/*.psd1"
  - "**/*.bat"
  - "**/*.cmd"
  - ".claude/.bat-shadow/**"
---

# Windows 向けファイルの文字コード・改行規約

**原則は一律 UTF-8。CP932 は `.bat` だけの例外**。「Windows 向けは一律 CP932」は成立しない ―― PowerShell 7 は
既定が UTF-8 で、CP932 の `.ps1` は日本語リテラルが壊れる（実測: `'こんにちは'.Length` が 5 → 8）。
保存形式を決める権利は書き手ではなく**読み手（処理系）**にあり、読み手ごとに正解が違う。

| 拡張子 | 読み手 | 保存形式 | 理由 |
|---|---|---|---|
| `.ps1` / `.psm1` / `.psd1` | PowerShell | **UTF-8 + BOM + CRLF** | 5.1 は BOM 無しを CP932 と誤読、7 は CP932 を読めない。**両対応はこの形式だけ**。Claude のツールでそのまま読み書きしてよい |
| `.bat` | cmd.exe | **CP932 + CRLF・BOM なし** | cmd.exe は BOM を読み飛ばさず **1 行目を壊す**。`chcp 65001` を先頭に置く回避策はコンソール表示品質を損なうため採らない |
| `.cmd` | cmd.exe | **使用禁止**（`.bat` に一本化） | `.bat` との差は一部組み込みの ERRORLEVEL 挙動のみ。例外を 1 つに絞るため。`.bat` と同じく `permissions.deny` で編集を拒否している |
| `.reg` | regedit | **スコープ外**（`permissions.deny` で R/W を禁止） | UTF-16LE + BOM が要求される形式で、`.env` と同格に扱う |
| `.ini` | Win32 `GetPrivateProfile*` | **規定しない**（deny も**していない**） | `tox.ini` / `pytest.ini` / `mypy.ini` のように **UTF-8 が正しい `.ini` が広く存在する**ため、拡張子で一律に扱えない。**Win32 プロファイル用途の CP932 な `.ini` を扱うときは、その都度 `file` やバイト列で文字コードを確かめること**（機構による保護は無い） |
| `.csv` | Excel | UTF-8 + BOM | Excel は BOM を見て UTF-8 と判定する |

改行は `.gitattributes` が拡張子ベースで固定する。ただし**その保護が届く範囲は、`.gitattributes` が置かれた
ディレクトリ以下だけ**である点に注意する:

- **`.claude/.gitattributes` が守るのは `.claude/` 以下だけ**。**`.claude/` の外**（リポジトリのルート直下や
  `scripts/` 等）は、そのディレクトリか親のディレクトリに `.gitattributes` が無ければ**無防備**。
- 迷ったら `git check-attr text eol -- <path>` で確かめる。属性が付いていない `.sh` は
  `core.autocrlf=true`（Git for Windows 既定）の clone で CRLF 化し、`set -euo pipefail` 下で `$'\r'` により落ちる。

## `.ps1` は普通に編集してよい（ただし新規作成は必ず壊れる）

UTF-8 + BOM なので Claude のツールがそのまま扱える。**変換は不要**。ただし **`Write` ツールは CRLF を保持せず、
新規作成では BOM も付かない**（実測: `Write` で作った `.ps1` は BOM 無し・LF になる。`Edit` は BOM も CRLF も保持する）。
既存ファイルを `Write` で**上書き**したときの BOM は、changelog 2.1.299 が「BOM を落とす Write を修正（now refused）」と
しているが、docs（tools-reference）には記載が無い。**v2.1.302 での実測**（hook と deny が反応しないよう `.txt` で測定）:
UTF-8 + BOM + CRLF のファイルを `Write` で上書きすると、拒否されず **BOM は保持され、改行は LF になった**（渡した
内容の改行のまま書かれ、元の CRLF は残らない）。上書きでも CRLF は壊れる。加えて Claude Code は
過去に **CRLF を二重化する不具合（v2.1.89 修正）／CRLF ファイルの改行を黙って変換する不具合（v2.1.77 修正）**
を出しており、**改行と BOM の保全は仕様として保証されていない**（公式 docs にファイル操作ツールの改行・
文字コードの規定は無い）。

そのため **`.claude/hooks/ps1_bom_crlf_check.py` が編集後に自動検査し、BOM 欠落・LF 化を検出すると差し戻す**
（PostToolUse。直し方のコマンドも一緒に返す）。手で確認するなら:

```bash
# CR バイト数（0 でなければ CRLF）と先頭 3 バイト（efbbbf なら BOM 付き）
tr -cd '\r' < <file> | wc -c
head -c 3 <file> | od -An -tx1
```

⚠ **Git Bash（MSYS）の `grep` / `awk` で CR を数えてはならない。しかも間違い方が 2 通りあり、どちらも
“それらしい値”を返す**（真値 CR=2・3 行のファイルで実測）:

| 書き方 | 返る値 | 何が起きているか |
|---|---|---|
| `grep -c "$(printf '\r')" <file>` | **0** | grep がテキストモードで**入力の CR を剥がす**ため、一致し得ない |
| `grep -c $'\r' <file>` | **0 または総行数（3）** | **呼び出し文脈で変わる**。パターンが CR として届けば 0、空文字列に落ちれば**全行にマッチして総行数**（実測: コマンド文字列に直接書くと 0、スクリプトファイル内では 3） |
| `awk '/\r$/' <file>` | **0** | awk も CR を剥がす |
| `grep -c -U "$(printf '\r')" <file>` | **2** ✅ | `-U`（バイナリ扱い）なら CR が見える |
| `tr -cd '\r' < <file> \| wc -c` | **2** ✅ | 正解。バイト単位で数える |

**「0」と「総行数」の両方が誤りになりうる**のが厄介で、`before → after` を別の書き方で測ると
**壊れた計測どうしが「修正が効いた」ように見える**（実際に起きた: `CR 50 → 0` は「空パターンで行数 50」→
「CR を剥がされて 0」という**別々の壊れ方**の組み合わせだった）。**`tr` か `git ls-files --eol` を使う**。

## `.bat` は原本に触らない（hook が自動処理する）

`.bat` は CP932 なので、Claude のツールで直接読むと文字化けする。書く側は、`Edit` が非 UTF-8 ファイルへの変更を
拒否する（v2.1.296〜。tools-reference「Non-UTF-8 files」）が、**ASCII だけの `.bat` は UTF-8 としても有効なので
`Edit` が通り、日本語を足すと UTF-8 で保存されて壊れる**。`Write` は docs では「UTF-8 で上書きし元の文字コードは
失われる」、changelog 2.1.299 では「Shift-JIS 等を黙って UTF-8 化する Write は拒否」とされ、食い違っている。
**v2.1.302 での実測**（`.txt` で測定）は changelog のとおりで、日本語を含む CP932 のファイルへの `Write` は
`File is not valid UTF-8` で拒否され、バイト列は変わらなかった。ただし **ASCII だけのファイルは `Write` も通り**、
日本語を書くと UTF-8・LF で保存された（`Edit` と同じ穴）。
そのため **`.claude/hooks/bat_cp932_guard.py` が原本を隠し、UTF-8 の作業コピー（影）を見せる**。
**Claude は以下に従うだけでよく、文字コードを意識する必要はない**。

| やること | 方法 |
|---|---|
| **読む** | 普通に `Read <path>.bat` する。hook が UTF-8 の作業コピーへ差し替えるので**正しい日本語が読める**（原本は不変） |
| **編集する** | 原本ではなく**作業コピー `.claude/.bat-shadow/<相対パス>.bat.utf8.txt` を `Edit` する**。保存すると hook が **CP932 + CRLF で原本へ書き戻す**。作業コピーのパスは Read した直後に hook が教える |
| **新規作成する** | `python .claude/hooks/bat_cp932_guard.py new <path>.bat` で空の `.bat` と作業コピーを作り、作業コピーを編集する（`Write` は拒否される） |
| **中身を検索する** | `python .claude/hooks/bat_cp932_guard.py sync` で全作業コピーを更新してから、`Grep` の対象を `.claude/.bat-shadow/` にする（CP932 のままでは Grep は日本語にヒットしない） |

- **原本への `Edit` / `Write` は `permissions.deny` で拒否される**。hook は Python が無い環境では起動に失敗し、
  既定ではそのまま操作が素通りする。`.bat` の Read ガード（PreToolUse）には `"onFailure": "block"`（v2.1.295〜）を
  付けてあるので、起動失敗・タイムアウト・想定外の終了コードでは **Read 自体が止まる**（PostToolUse 側の書き戻し・
  `.ps1` 検査には付けていない。対応する最低版は v2.1.295 で、それ未満は対象外）。それでも
  **ハードなガードは permission 側が担い、hook は利便性を担う**という二層構造は変わらない。
  **hook には Python 3.10 以上が `python` として PATH に必要**（無い場合、`.bat` は読めないが原本は壊れない）。
  hook の `if` 条件は **Claude Code v2.1.176 以上**でないと正しくマッチしない（それ以前は起動しない）。
  最低版の v2.1.295 はこれを包含する。
- **CP932 に存在しない文字は書き戻し時に拒否される**（原本は書き換わらない）。`⚠` `‼` `✓` `✗` は CP932 に
  符号位置が無いので、`.bat` のメッセージ記号は **ASCII（`[!]` / `[OK]` 等）**を使う。
  `〜` `—` `−` のような和字は `.claude/skills/win-file-encoding/references/cp932-mapping.json` の表で
  CP932 の対応字へ自動正規化されるため、拒否されない。
- **`.bat` を `sed -i`・リダイレクト・PowerShell の `Set-Content` / `Add-Content` / `Out-File` / `>`・スクリプト
  （Python 等）で書き換えない**（シェルやスクリプト経由の書き込みは hook が守れない。`permissions.deny` の
  `Edit(...)` が止めるのも Bash のリダイレクト先と `sed` / `tee` 等までで、PowerShell やスクリプトには保証が無い）。
  非 UTF-8 のファイルに対する `Edit` / `Write` の拒否メッセージは「文字コードを保つシェルコマンドで直す」を勧め、
  `Write` のもの（v2.1.302 で実測）はさらに iconv や PowerShell の `Set-Content -Encoding`、「消してから `Write`
  する」まで挙げるが、`.bat` には従わない。
  **例外は CP932 + CRLF で書く、この規約に同梱の 2 つだけ**: `bat_cp932_guard.py new`（新規作成）と、`win-file-encoding`
  skill の `convert_encoding.py --to-win`（UTF-8 で保存されてしまった `.bat` の修復・一括変換。hook が Read を止めた
  ときに案内する。実行後は作業コピーが古くなるので、原本を Read し直してから編集する）。

> 一括変換・検査を手動で行いたい場合は `win-file-encoding` skill の `convert_encoding.py` を使う
> （`--to-win --check` で CP932 エンコード可否だけを検査できる）。日常の `.bat` 編集で skill を呼ぶ必要はない。
