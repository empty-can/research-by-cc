---
description: 活動フォルダ配下の .claude/work/prompt.txt を読み込みコンテキストに追加する
allowed-tools: Bash(.claude/skills/read-prompt-file/read-prompt-file.sh), Bash(cat -n *)
---

# read-prompt-file

長文・複数行のメッセージをエディタで作成・保存しておき、それを Claude にコンテキストとして渡すユーティリティ Skill。

## 前提

作業者は本 Skill を実行する前に、活動フォルダ配下の `.claude/work/prompt.txt` を **自身の使い慣れたエディタで作成・記述・保存** しておく。活動フォルダはルート CLAUDE.md「ブランチ運用ルール」に従い、現ブランチから決定する:

- 現ブランチが `feature/<X>` またはその派生サブブランチ → `research-for-<X>/.claude/work/prompt.txt`
- 現ブランチが `main` または非該当 → `./.claude/work/prompt.txt`

## 動作

1. Bash で以下を実行し、prompt.txt の存在確認とパス取得を行う:
   ```
   bash .claude/skills/read-prompt-file/read-prompt-file.sh
   ```
   - **存在する場合**: 標準出力にリポジトリルートからの相対パスが返る
   - **存在しない場合**: 標準エラーに作成を促すメッセージが出力され、非ゼロ終了する。Claude はそのメッセージをそのまま作業者に伝え、本 Skill の処理を一旦終了する

2. パスが取得できた場合、続けて以下で内容を読み込む:
   ```
   cat -n <取得したパス>
   ```

3. 内容に基づいて作業を開始する

## 注意

- prompt.txt は `.gitignore` 対象（`.claude/work/` 配下）。コミット対象外
- 作業者がメッセージ送信後に内容を再確認したい場合に備え、本 Skill はファイルの自動削除や上書きを行わない
