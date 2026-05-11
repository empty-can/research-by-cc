# read-prompt-file Skill

長文・複数行のメッセージをエディタで作成・保存しておき、それを Claude にコンテキストとして渡すユーティリティ Skill。

## 利用シーン

- プロンプト欄では入力しづらい長文・複数行のやり取りを、使い慣れたエディタで書きたい
- 一度送信したメッセージ内容を後で再確認したい（プロンプト欄の `Ctrl+G` 経由で開いたファイルは閉じた直後に削除されるため不便）

## 利用方法

1. 活動フォルダ配下の `.claude/work/prompt.txt` を、自身の使い慣れたエディタで作成・記述・保存しておく。活動フォルダはルート CLAUDE.md「ブランチ運用ルール」に従い、現ブランチから決定される:
   - 現ブランチが `feature/<X>` またはその派生サブブランチ → `research-for-<X>/.claude/work/prompt.txt`
   - 現ブランチが `main` または非該当 → `./.claude/work/prompt.txt`
2. プロンプトで `/read-prompt-file` を実行する
3. Claude が `prompt.txt` の内容を読み込み、新規メッセージとして処理を開始する

## 注意事項

- `prompt.txt` は `.gitignore` 対象（`.claude/work/` 配下）。コミット対象外
- 本 Skill は `prompt.txt` の自動削除や上書きを行わない。メッセージ送信後に内容を再確認したい場合に備えた仕様
- `prompt.txt` が存在しない状態で実行した場合、Claude は不在エラーの旨を返して処理を終了する。エディタで作成してから再実行する

## ファイル構成

- `SKILL.md` — Claude が読み込む実行手順書（Claude 向け）
- `read-prompt-file.sh` — `prompt.txt` の存在確認とパス返却を行うスクリプト
- `README.md` — 本ファイル（利用者向け）
