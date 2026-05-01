---
name: commit-and-pr
description: 現在のステージ済み・未ステージ変更を適切なメッセージでコミットし、プッシュして Pull Request を作成する。変更が完成して共有可能な状態になったら使用する。
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Bash(git branch:*), Bash(git push:*), Bash(gh pr create:*)
---

## 前提条件

- `gh` CLI がインストールされていること
  - 未インストールの場合: PR 作成手順を説明するので手動で実施してください
- GitHub にリモートリポジトリが存在すること

## コンテキスト

- 現在の変更: !`git status --short`
- 現在のブランチ: !`git branch --show-current`
- 差分サマリ: !`git diff --stat HEAD`

## 実行手順

以下を **1 メッセージで連続して** 実行してください：

1. **ブランチ確認**: `main` または `master` の場合は `git checkout -b <username>/<feature>` で新ブランチを作成
2. **コミット**: 変更を単一コミットにまとめる
   - コミットメッセージのプレフィックス: `feat:` / `fix:` / `docs:` / `refactor:` / `test:`
   - メッセージは変更内容を端的に表現（50 文字以内）
3. **プッシュ**: `git push -u origin <branch>`
4. **PR 作成**: `gh pr create --title "<title>" --body "<body>"`
   - `gh` が使えない場合は PR 用 URL と本文を出力して手動作成を案内

## 注意事項

- `.env` や `secrets/` 内のファイルは絶対にコミットしない
- 意図しない変更が含まれていないか `git diff --stat` で確認してからコミット
