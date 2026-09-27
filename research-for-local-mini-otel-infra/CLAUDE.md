# CLAUDE.md — research-for-local-mini-otel-infra

## 調査の目的

Claude Code（以下 cc）の OpenTelemetry テレメトリを、**Windows ローカルで完結する最小構成**で受信・蓄積・可視化する仕組みを構築する。

背景・ゴール・問い①〜③・前提・スコープ・フェーズ構成は `reports/00.活動計画/活動計画書.md`（以下「計画書」）を正本とする。最終的な効用は、分析結果をルート資産（「モデル選定原則」、`check-model` skill 等）へ還流させることであり、**分析そのものを目的化しない**（計画書 §1）。

## 作業時の制約

- **Windows ネイティブ・Docker 不要**で動く構成にする。WSL + Docker 前提の構成は本活動では作らない（第二のゴールとして次の活動で扱う）
- 仕組みは本環境と職場環境（社内 LLM ゲートウェイ + Amazon Bedrock）の両方で動かす前提で設計する。**Claude Code は職場環境で検証しない**（確認手順書を用意し、作業指示者が実施する。計画書 Phase 3）
- 収集データを外部の SaaS・クラウドへ送らない。**収集データ（プロンプト本文等を含み得る）はコミットしない**
- 仕様は cc のバージョンに依存する。基線（cc と docs の版）は計画書 §2 冒頭

## 作業時の注意

- OTel の仕様に関わる作業の前に `reports/00.活動計画/【別紙】公式仕様の調査結果.md`（仕様別紙）を読む。「見込み」とある項目は事実として扱わない
- OTel の変数はユーザ settings（`~/.claude/settings.json`）の `env` に設定する。project / local settings では、有効化・送信先・内容記録の変数が無視される
- transcript（`~/.claude/projects/*/*.jsonl`）は cc が既定 30 日で削除する。取込の仕組みができるまでは、分析に使う transcript が残っていることを前提にしない

## ブランチ

- 作業ブランチ: Phase 0 は `phase/local-mini-otel-infra/00_activity-plan`（`feature/local-mini-otel-infra` から作成）
- `feature/local-mini-otel-infra` は develop から派生している（2026-09-27 のブランチ再編で、cve-triage 系列から切り離して本活動固有のコミットだけを載せ直した。計画書 §7 #1）。取り込み先は develop（ルート CLAUDE.md「ブランチ運用ルール」）

## 参照リソース

| 資料 | 場所 |
|---|---|
| cc 公式 docs | `C:\cc-workspace\LLMs\official-llms-txts\code.claude.com\docs\llms-full.txt`（`# Monitoring` 節）。ルート CLAUDE.md の暫定ルールが指す repo 内 references/ は古いため使わない |
| 仕様別紙 | `reports/00.活動計画/【別紙】公式仕様の調査結果.md` |
| 引継ぎ資料 v2.1 | `reports/00.活動計画/handover-report_by_chat-claude/claude-code-otel-telemetry-design-brief-v2.1.md`。検証項目（V-ID）とリスク（R-ID）は後続フェーズでも参照する。取り込み状況は `reports/00.活動計画/【別紙】引継ぎ資料v2.1取り込み対応表.md` |
| クロスレビュー報告書 | `reports/00.活動計画/レビュー/` |
| cc transcript | `~/.claude/projects/*/*.jsonl` |
| ステータスライン実装 | `~/.claude/statusline-command.sh`（本 repo の管理外） |

## 成果物の配置

- 報告書類: `reports/<タスク>/<フェーズ>/`（ルート CLAUDE.md の規約に従う）
- 実装コード: `app/`（Phase 3 以降に作成予定。配置の確定は Phase 2）
- 収集データの保存先: repo 外（Phase 2 で決める）

## タスク進行状況

- [x] Phase 0: 活動計画の策定
  - [x] 活動フォルダ・CLAUDE.md 作成
  - [x] 計画書初版（v0.1）の作業指示者承認（2026-09-25）
  - [x] 引継ぎ資料のクロスレビュー・v2.1 化
  - [x] 計画書 v1.0 改訂・作業指示者の正式レビュー完了（2026-09-27）
- [ ] Phase 1: 基礎調査・フィジビリティ確認
- [ ] Phase 2: 設計
- [ ] Phase 3: PoC（エンドツーエンド疎通）
- [ ] Phase 4: 収集基盤の実装
- [ ] Phase 5: ダッシュボードの実装
- [ ] Phase 6: 運用・分析とフィードバック

各 Phase の中身は計画書を正本とする。

## 変更履歴

| 日付 | 内容 |
|---|---|
| 2026-09-25 | 新規作成（Phase 0 着手） |
| 2026-09-27 | 計画書 v1.0 に合わせて再構成。背景・前提・スコープは計画書 §1、仕様上の事実は仕様別紙へ移し、本書は作業時の制約・注意・参照先に絞った |
| 2026-09-27 | 計画書 v1.0 の正式レビュー完了を受け、Phase 0 を完了にした |
| 2026-09-27 | ブランチ再編の結果に合わせてブランチ節を更新（計画書 v1.2） |
