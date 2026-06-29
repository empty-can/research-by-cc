# CLAUDE.md（チーム共有・共通指示）

このリポジトリが配布する**チーム共通の Claude Code 指示**。利用先リポジトリの文脈に
そのまま混ざってよい**汎用ガバナンスルールだけ**を保持する。

> **このファイルに書かないもの**: リポジトリ固有の使い方・MCP ポリシー・拡張オプション・
> ローカル絶対パス。それらは `README.md`（`--add-dir` では非ロード）に置く（README 隔離方式）。

> **層1+2 構成での位置づけ**: 機能資産（skills / subagents / hooks / output-styles）は
> **層2 plugin** から配る（→ リポジトリルート `README.md` と `reports/03` README 参照）。
> 本ファイル（層1）は plugin で運べない**常時ガバナンス**（コーディング規約・Git・セキュリティ）に絞る。
> plugin が提供するコマンドは `/base-dev-kit:<command>` の名前空間で呼ぶ。

## コーディング規約

詳細は `.claude/rules/coding-standards.md`（コードファイル編集時に path-scoped で自動ロード）。主要方針:

- 命名規則は言語慣習に従う
- コメントは「なぜそうするか」を説明する場合のみ記述する
- エラーは握り潰さない
- 外部入力の境界でのみバリデーションする

## Git ワークフロー

- ブランチ命名: `<username>/<feature-description>`（例: `alice/add-auth`）
- コミットプレフィックス: `feat:` / `fix:` / `docs:` / `refactor:` / `test:` / `chore:`
- コミット前にテストを実行する
- `/base-dev-kit:commit-and-pr`（層2 plugin 提供）でコミット → プッシュ → PR 作成を一括実行できる

## 重要な制約

- `.env` ファイルを直接編集しない。環境変数は実行環境から参照する
- API キー・パスワード等の機密情報をコードにハードコードしない
- `secrets/` ディレクトリは `.gitignore` で除外済み
- DB マイグレーション等の破壊的操作は必ず確認を取ってから実行する
