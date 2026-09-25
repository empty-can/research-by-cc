# CLAUDE.md — research-for-local-mini-otel-infra

## 調査の目的

Claude Code（以下 cc）の OpenTelemetry テレメトリを、**Windows ローカルで完結する最小構成**で受信・蓄積・可視化する仕組みを構築する。

## 背景

cc の費用対効果を最大化したい。そのために、ステータスラインで見られるモデル・コンテキストサイズ・総トークン量だけでなく、次の情報をテレメトリとして収集・分析できるようにする:

- effort 値
- **作業の内容・性質の分類ごと**の送受信トークン（思考トークンを含む）
- 上記を切り分けるためのタグ

分析で得たいもの:

1. トークンを消費しやすい作業の特定
2. 作業の性質に対する推奨モデル・推奨 effort の導出

分析結果は、ルート `CLAUDE.md` の「モデル選定原則」と `check-model` skill の判定基準へフィードバックする（**これが本活動の最終的な効用**。分析そのものを目的化しない）。

## 前提・制約

- **Docker 不使用**。Windows 11 ローカルで完結して動作すること
- OTel 受信サーバ・データシンク等は、**ローカル起動できる OSS を積極活用してよい**
- 分析 UI は、デザイン・レイアウトを度々変えたくなる見込みがあるため、**Node.js 上の自作ダッシュボード**を有力候補とする（OSS 製品との比較は Phase 1 で行う）
- 環境基線（2026-09-25 時点）: Claude Code **2.1.282** / Node.js **v24.14.0**
- OTel の属性は v2.1.2xx 台で頻繁に追加・変更されている。**仕様は cc のバージョンに依存する**前提で扱う

### ブランチに関する未決事項

`feature/local-mini-otel-infra` は main ではなく cve-triage 系列（`9fe51fa`、2026-07-29 時点）から分岐しており、main 未取り込みの cve-triage 関連コミット 65 件を含む。main から作り直すかは**未判断**（作業指示者判断待ち）。

## スコープ

### 含む

- cc が出力する OTel シグナル（metrics / logs(events) / traces(beta)）の受信・保存
- 思考トークンを含むトークン内訳の取得（OTel 外の補完データソースを含む。後述）
- 作業分類タグの付与方式の設計・実装
- 分析用ダッシュボード
- 分析結果に基づく推奨モデル×effort 表の作成と、ルート資産への反映提案

### 含まない

- チーム・組織単位の集中収集（本活動は個人ローカル用）
- クラウド／SaaS の監視基盤（Datadog 等）への送信
- Docker・WSL 前提の構成

## 公式仕様から判明している重要事実（2026-09-25 / cc 2.1.282 時点）

出典: `C:\cc-workspace\LLMs\official-llms-txts\code.claude.com\docs\llms-full.txt`（Monitoring 節、env-vars 節、statusline 節）。詳細と計画上の扱いは `reports/00.活動計画/活動計画書.md` の §2 を参照。

- `claude_code.token.usage` / `cost.usage` と `api_request` イベントには `model` / `effort` / `query_source` / `skill.name` / `agent.name` などの属性が付く
- **思考トークンは OTel では分離されない**（output_tokens に含まれる）。ただし transcript（`~/.claude/projects/*/*.jsonl`）の `message.usage.output_tokens_details.thinking_tokens` には記録されており、同じエントリに `requestId` もある（いずれも実測で確認）。OTel の `api_request` とは `request_id` で突合できる見込み。`api_response_body` イベントの usage から取る経路もある（未実測）
- ユーザ定義 agent 名は `agent.name="custom"` に丸められる。ユーザ定義 skill 名はそのまま出る
- `OTEL_RESOURCE_ATTRIBUTES` は起動時に固定され、セッション途中では変えられない
- OTel 変数はユーザ settings の `env` で設定できる（`OTEL_LOG_RAW_API_BODIES` 等の一部は project / local settings では無視される）

## 参照リソース

| 資料 | 場所 |
|---|---|
| cc 公式 docs（最新） | `C:\cc-workspace\LLMs\official-llms-txts\code.claude.com\docs\llms-full.txt` の `# Monitoring` 節（Monitoring usage）。ルート CLAUDE.md の暫定ルールが指す repo 内 references/ は 2026-05-24 で止まっているため使わない |
| cc transcript | `~/.claude/projects/*/*.jsonl`（2026-09-25 時点で 21 プロジェクト / 約 217MB） |
| ステータスライン実装 | `~/.claude/statusline-command.sh`（本 repo の管理外） |

## 成果物の配置

- 報告書類: `reports/<タスク>/<フェーズ>/`（ルート CLAUDE.md の規約に従う）
- 実装コード: `app/`（Phase 3 以降に作成予定。配置の確定は Phase 2）
- **収集データ（プロンプト本文等を含み得る）はコミットしない**。保存先は Phase 2 で repo 外に決める

## タスク進行状況

- [x] Phase 0: 活動計画の策定
  - [x] 活動フォルダ・CLAUDE.md 作成
  - [x] 活動計画書 `reports/00.活動計画/活動計画書.md` の作業指示者承認（2026-09-25）
- [ ] Phase 1: 基礎調査・フィジビリティ確認
- [ ] Phase 2: 設計
- [ ] Phase 3: PoC（エンドツーエンド疎通）
- [ ] Phase 4: 収集基盤の実装
- [ ] Phase 5: ダッシュボードの実装
- [ ] Phase 6: 運用・分析とフィードバック

各 Phase の中身は活動計画書を正本とする。

## 変更履歴

| 日付 | 内容 |
|---|---|
| 2026-09-25 | 新規作成（Phase 0 着手） |
