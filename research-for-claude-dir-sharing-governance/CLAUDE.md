# CLAUDE.md — ポータブルな `.claude` チーム共有・統制の調査

> 本フォルダは「ゼロから作ったリポジトリでも使えるポータブルな最小 `.claude/` を、Marketplace のようにチーム共有・統制する仕組み」を調査する個別調査フォルダ。ルート `CLAUDE.md` の規約（成果物配置・命名・Git 運用・Agent 活用・公式ドキュメント調査手順）に従う。

## 調査の目的・背景

- **問い**:
  1. `<Prjルート>\.claude` を Marketplace の仕組みで配布できるか。
  2. 特定リポジトリ向けにチューニングされていない、ゼロから作ったリポジトリでも使える **最低限の資産だけのシンプルな `.claude/`** を、Marketplace のように Skill 等を配布する形でチーム共有するベストプラクティスは存在するか。無ければ最適な仕組みを設計せよ。
- **想定読者**: Claude Code を活用するチームのガバナンス担当者。
- **核心結論**: `.claude/` 全体を単一手段で配る方法は無く、**3 配布チャネル**（層1 Git commit／層2 Plugin・Marketplace／層3 Managed settings）の組み合わせで設計する。`--add-dir` は補助参照。資産×配布チャネル マトリクスが報告書の中核。

## 成果物

| 成果物 | 所在 |
|---|---|
| 結論・構成案（**確定版 v1.2**） | `reports/01.配布・統制方針調査/結論・構成案_ポータブルな.claude共有_v1.2.md` |
| クロスレビュー報告書（3観点・各1.0版） | `reports/01.配布・統制方針調査/レビュー/`（論理整合性／実用性＋出典照合／作業指示者＋人間読み手） |
| 層2 配布物の開発・テスト 調査結果（v1.0） | `reports/02.配布物の開発・テスト/01.Plugin・Marketplace編/Plugin・Marketplace配布物の開発・テスト_調査結果.md` |
| Plugin 開発・テスト手順書（v1.0） | `reports/02.配布物の開発・テスト/01.Plugin・Marketplace編/Plugin開発・テスト_手順書.md` |
| Marketplace 外資産の開発・テスト 調査結果（v1.0） | `reports/02.配布物の開発・テスト/02.Marketplace外資産編/Marketplace外資産の開発・テスト_調査結果.md` |
| Marketplace 外資産 開発・テスト手順書（v1.0） | `reports/02.配布物の開発・テスト/02.Marketplace外資産編/Marketplace外資産_開発・テスト_手順書.md` |
| 開発・テスト補助スクリプト（clean-test-env / check-payload・bash+PowerShell） | `reports/02.配布物の開発・テスト/02.Marketplace外資産編/scripts/` |
| 実装テンプレート（層1+2・3チャネル構成の雛形） | `reports/03.実装テンプレート（層1+2）/`（README ＋ `layer1-repo-template/` ＋ `layer2-plugin/`） |

## 参照リソース

- **本文の根拠**: Claude Code 公式ドキュメント `cc-relative-info\LLMs\official-llms-txts\code.claude.com\docs\llms-full.txt`（CLI v2.1.165 相当。報告書の出典一覧の行番号はこのファイルの絶対行番号）。
- **精読の根拠**（中間成果物・workspace 保管）: `.claude/workspace/portable-claude-dir-sharing/intermediate-reports/01〜07-*.md`（7 Agent によるページ別精読結果）。
- **改訂経緯の凍結スナップショット**（workspace 保管）: `.claude/workspace/portable-claude-dir-sharing/結論・構成案_…_v2.0〜v2.6.md`（reports/ 昇格前の版。Git 履歴と併せて経緯を追える）。

## 版管理運用（本フォルダ固有）

- reports/ 配下の確定版は **単一ファイル＋ファイル内変更履歴** で版を表現（ルート `CLAUDE.md` 原則に準拠）。
- reports/ 昇格時に workspace の **v2.6 を v1.0 として再採番**した。workspace の版数（v1.0〜v2.6）は調査過程の試行錯誤の記録であり、reports/ では新たな成果物ライフサイクルとして **v1.0 から開始**する。
- 詳細な改訂経緯は **Git 履歴**へ委譲し、確定版の変更履歴は要点のみ保持する（v2.0〜v2.6 の逐次経緯は workspace 凍結版を参照）。

## タスク進行状況

- [x] 公式ドキュメント精読（7 Agent ページ別）→ 結論・構成案 初版〜v2.6（workspace）
- [x] 3 観点クロスレビュー（論理整合性 Opus／実用性＋出典照合 Sonnet／作業指示者ペルソナ Opus）→ v2.6 反映・アンカー検証パス（REFS=DEFS=72）
- [x] reports/ 昇格・**v1.0 再採番**（2026-06-07）
- [x] 層2（Plugin/Marketplace）配布物の開発・テスト調査 → 調査結果 v1.0 ＋ 手順書 v1.0（2026-06-21・タスク02）
- [x] 層2 成果物の Sonnet 動作検証（実機 `claude plugin validate` v2.1.185・2026-06-21）→ 指摘反映（7df3c0b）。副産物で v1.2 マトリクスの `--add-dir`×agents 誤記を発見・訂正（5063ded）。※後続の実機検証で**本訂正自体が v2.1.178 版依存**と判明し再訂正（225dda9・下記参照）
- [x] Marketplace 外資産（CLAUDE.md/rules/settings 等）の開発・テスト調査 → 調査結果 v1.0 ＋ 手順書 v1.0（2026-06-21・タスク02 第2フェーズ `02.Marketplace外資産編`）
- [x] 02.Marketplace外資産編 の Sonnet 動作検証（2026-06-22・実機）→ **重大検出: subagents×`--add-dir` は v2.1.178 版依存**（v2.1.165=非ロード／v2.1.178+=ロード）。現行✅＋版境界注記へ v1.2 errata 再訂正・出典 [75] 追加（225dda9）。対話実機で **#1 `/memory`＝`<Share>/.claude/CLAUDE.md` ロード確認（案1 生命線）／#2 `/agents`＝`--add-dir` 経由 subagent ロードを一意プローブで立証**。check-payload を案1（Git 追跡基準）へ改修も併施（75cc12d）。実 `<Share>`＝`base-dev-kit-for-cc` を grooming（PR #1）
- [x] 実装スコープ決定（**層1+2＝テスト可能なコア**を採用・作業指示者選択）と 3 チャネル構成のテンプレート雛形作成 → `reports/03.実装テンプレート（層1+2）/`（2026-06-22）。base-dev-kit 資産を層1（ガバナンス＋起動装置）／層2（plugin: skills/agent/output-style/hook）へ振り分け。`claude plugin validate`（`--strict`）・marketplace validate ともにパス。**層3 は通常マシンで実機検証不可のため雛形は作らずレポート §解決案 層3系・付録A の記述に委譲**
- [ ] （任意）公開 `README.md` 作成（CLAUDE.md からの派生・GitHub 閲覧者向け）
