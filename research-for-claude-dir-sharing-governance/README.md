# ポータブルな `.claude/` のチーム共有・統制

> ゼロから作ったリポジトリでも使える**ポータブルな最小 `.claude/`** を、Marketplace のように
> チーム共有・統制する仕組みを調査・設計した research フォルダ。
> **本質的な情報の出所は [`CLAUDE.md`](CLAUDE.md)** であり、本 README はその派生（GitHub 閲覧者向けの俯瞰）。
> 詳細・前提・進捗は `CLAUDE.md` と各成果物を参照。

## 調査の問い

1. `<Prjルート>/.claude` を Marketplace の仕組みで配布できるか。
2. 特定リポジトリにチューニングされていない、ゼロから作ったリポジトリでも使える
   **最低限の資産だけのシンプルな `.claude/`** を、Marketplace のように Skill 等を配布する形で
   チーム共有するベストプラクティスは存在するか。無ければ最適な仕組みを設計せよ。

想定読者: Claude Code を活用するチームのガバナンス担当者。

## 核心結論

`.claude/` 全体を**単一手段で配る方法は存在しない**。**3 つの配布チャネルの組み合わせ**で設計する。
資産 × 配布チャネルの**マトリクス**が報告書の中核。

| チャネル | 配布手段 | 運べる資産 | コスト | 強制力 | 更新性 |
|---|---|---|---|---|---|
| **層1** | Git commit / テンプレート | ガバナンス（CLAUDE.md/rules/permissions）＋層2 起動装置＋層1専用（workflows 等） | 低 | なし | 手動 |
| **層2** | Plugin / Marketplace | 機能資産（skills/commands/hooks/MCP/output-styles/△以外の subagents） | 中 | 弱 | 一元更新 |
| **層3** | Managed settings | ガバナンス資産の**強制**配布（claudeMd/permissions/MCP/subagents/skills/version） | server-managed＝極低／endpoint-managed＝中〜高 | 最高（上書き不可） | 中央 push |

- **`--add-dir`** は主配布チャネルではなく、層2 で運べない CLAUDE.md/rules を共有ディレクトリから参照する**補助**。
- **推奨**: 機能資産は層2 へ集約し、層1（ガバナンス＋起動装置）・層3（強制）・`--add-dir`（補助）で役割分担する。

## 成果物

| フェーズ | 内容 | 所在 |
|---|---|---|
| 01. 配布・統制方針調査 | 結論・構成案（確定版 v1.2）＋ 3 観点クロスレビュー報告書 | [`reports/01.配布・統制方針調査/`](reports/01.配布・統制方針調査/) |
| 02. 配布物の開発・テスト | 層2（Plugin/Marketplace）と Marketplace 外資産の開発・テスト調査＋手順書＋補助スクリプト | [`reports/02.配布物の開発・テスト/`](reports/02.配布物の開発・テスト/) |
| 03. 実装テンプレート（層1+2） | 方針を落とし込んだコピー可能な雛形（層1 リポ骨格＋層2 plugin/marketplace 骨格） | [`reports/03.実装テンプレート（層1+2）/`](reports/03.実装テンプレート（層1+2）/) |

実装の起点となる `<Share>` リポジトリの実体は別リポジトリ
[`empty-can/base-dev-kit-for-cc`](https://github.com/empty-can/base-dev-kit-for-cc)（案1/README 隔離方式）。

## 進捗

主要フェーズ（方針調査 → クロスレビュー → reports/ 昇格 → 配布物の開発・テスト → Sonnet 動作検証 →
実装テンプレート 層1+2）は完了済み。最新の進行状況・残タスク（任意）は [`CLAUDE.md`](CLAUDE.md) のタスク進行状況を参照。

## 参照リソース

- 根拠ドキュメント: Claude Code 公式ドキュメント（`llms-full.txt`。出典行番号の基準は CLI v2.1.165 版、一部 v2.1.178+ 版）
- 調査経路・版管理運用などの詳細は [`CLAUDE.md`](CLAUDE.md) を参照
