# GitHub 上の自然言語ドキュメントレビュー Skill 調査 — 補足調査報告

| 項目 | 内容 |
|---|---|
| 作成日 | 2026-05-04 |
| 作成者 | Claude (Sonnet 4.6) |
| 関連フェーズ | 02.基礎調査 / 08.オフラインGitHubリポジトリ調査 |
| 位置づけ | 08 の補足調査。RAG リポジトリではなく、**自然言語ドキュメント（計画書・報告書・設計書）のレビューを対象とした Claude Code skill / flow** に絞った GitHub 調査 |

---

## 1. 調査概要

### 1.1 調査目的

Claude Code ベースの **自然言語ドキュメントレビューフロー** の実例を GitHub 上で収集する。対象は以下のドキュメント種別のレビューに関わる skill / flow であり、コードレビューおよびインフラスクリプトレビューは対象外とする。

- 計画書・仕様書・設計書
- 報告書・議事録
- 契約書・法的文書
- ドキュメント品質監査全般

### 1.2 調査方式

1. **再評価**: 前回調査で発見した 4 リポジトリを自然言語ドキュメントレビュー観点で再評価  
2. **新規検索**: 4 本の GitHub 検索クエリを実行し新規候補を発掘  
3. **SKILL.md 取得**: 候補リポジトリから対象ファイルを取得・内容を確認

### 1.3 実行した検索クエリ

| # | クエリ内容 | 目的 |
|---|---|---|
| Q1 | `skill.md "document review" language:markdown` | 汎用ドキュメントレビュー skill 探索 |
| Q2 | `SKILL.md "plan review" OR "spec review" claude` | 計画書・仕様書レビュー skill 探索 |
| Q3 | `claude code skills "legal" OR "contract" review SKILL.md` | 法的文書レビュー skill 探索 |
| Q4 | `SKILL.md "doc-lint" OR "documentation audit" OR "spec-audit"` | ドキュメント品質監査 skill 探索 |

---

## 2. 再評価対象リポジトリ（前回発見済み）

### 2.1 garrytan/gstack

| 項目 | 内容 |
|---|---|
| URL | https://github.com/garrytan/gstack |
| ライセンス | **MIT** (2026 Garry Tan) |
| 対象ドキュメント種別 | 実装計画書・設計書・エンジニアリング計画書・振り返り文書 |
| テンプレート有無 | あり（`SKILL.md.tmpl` が各スキルに存在） |

#### フロー概要

gstack は Claude Code 向けの skill フレームワーク。`plan-eng-review` / `plan-design-review` / `plan-ceo-review` / `retro` の 4 スキルが計画書・設計書レビューに直接対応する。各スキルは `SKILL.md`（本番用・巨大）と `SKILL.md.tmpl`（テンプレート用）の 2 ファイルで構成される。スキルは `.claude/skills/` ではなくリポジトリ直下の独立ディレクトリに配置される構造が特徴的。

**レビューフローの構造（plan-eng-review の例）:**

```
Step 0: スコープチャレンジ（複雑度チェック・既存コード確認・TODO 照合）
  ↓ AskUserQuestion でユーザー確認
Section 1: アーキテクチャレビュー
  ↓ AskUserQuestion（1 課題 = 1 呼び出し）
Section 2: コード品質レビュー
  ↓ AskUserQuestion（1 課題 = 1 呼び出し）
Section 3: テストレビュー（図解生成含む）
  ↓ AskUserQuestion（1 課題 = 1 呼び出し）
Section 4: パフォーマンスレビュー
  ↓ AskUserQuestion
Required Outputs:
  - "NOT in scope" 一覧
  - "What already exists" 一覧
  - TODOS.md 更新提案
  - ASCII ダイアグラム
  - 失敗モード一覧
  - ワークツリー並列化戦略
Completion Summary → Review Log 書き込み
Next Steps: 他スキル（plan-design-review / plan-ceo-review）への連鎖提案
```

**plan-design-review の特徴:**

- 7 つのレビューパス（情報アーキテクチャ / インタラクション状態 / ユーザージャーニー / AI スロップリスク / デザインシステム / レスポンシブ・アクセシビリティ / 未解決決定事項）
- 各パス 0–10 でスコアリング → FIX TO 10 作業 → 再スコア
- ビジュアルモックアップ生成ツール（gstack designer）連携
- 完成度スコア全パス 8+ で合格

**主要な設計特徴:**

- `AskUserQuestion` ツール呼び出しを徹底（1 課題 = 1 呼び出し、複数まとめ禁止）
- コンテキスト圧縮時の優先順位を明示（Step 0 > テスト図 > 意見付き推奨 > その他）
- 「Anti-skip rule」: 全セクション評価を強制（ゼロ発見時は "No issues found" を明示）
- gstack-review-log コマンドで review metadata を `~/.gstack/` に永続化
- `{{PREAMBLE}}`, `{{GBRAIN_CONTEXT_LOAD}}` 等のテンプレート変数で共有ロジックを注入
- 引用文献: Larson (An Elegant Puzzle), McKinley (Choose Boring Technology), Fowler, Skelton/Pais 等

#### 取得推奨ファイル

| ファイル | サイズ | 備考 |
|---|---|---|
| `plan-eng-review/SKILL.md.tmpl` | 27,710 bytes | 取得・解読済み |
| `plan-design-review/SKILL.md.tmpl` | 28,680 bytes | 取得・解読済み |
| `plan-ceo-review/SKILL.md.tmpl` | 63,465 bytes | 大きいため未解読 |
| `retro/SKILL.md.tmpl` | 38,857 bytes | 大きいため未解読 |
| `plan-eng-review/SKILL.md` | 90,571 bytes | 本番用（巨大） |
| `plan-design-review/SKILL.md` | 95,606 bytes | 本番用（巨大） |

#### 評価

自然言語ドキュメント（計画書・設計書）レビューフローの**最も充実した実装例**。インタラクティブな対話型レビュー、スコア付き評価、他スキルへの連鎖（eng → design → CEO）という多層レビューチェーンが特徴。`SKILL.md.tmpl` の構造はそのまま自プロジェクトへの流用が可能なレベル。

---

### 2.2 vlad-ryzhkov/AI-QA-workshop-feb19

| 項目 | 内容 |
|---|---|
| URL | https://github.com/vlad-ryzhkov/AI-QA-workshop-feb19 |
| ライセンス | **Unlicense**（パブリックドメイン相当） |
| 対象ドキュメント種別 | ドキュメント全般の品質監査（Markdown・設計書等） |
| テンプレート有無 | `.claude/qa-antipatterns/` / `.claude/protocols/` に定義集あり |

#### フロー概要

3 つの skill が存在するが、自然言語ドキュメントレビューに直接関係するのは `doc-lint` のみ。

**doc-lint（`.claude/skills/doc-lint/SKILL.md`）**

```
Phase 1: Discovery（対象 MD ファイル全列挙）
Phase 2: Size Analysis（1 ファイル >500 行 = CRITICAL, >200 行 = WARNING）
Phase 3: Structure Analysis（見出し階層 / トップレベル見出し数 / 深さ検証）
Phase 4: Cross-File Duplicate Detection（コンテンツハッシュ比較）
Phase 5: Content Hygiene（TODO 残留 / 空セクション / stale links 等）
Phase 6: Report Generation（audit/doc-lint-report.md 出力）
Phase 7: Safe-Fix Script（自動修正スクリプト生成・実行可否を AskUserQuestion で確認）
```

**スコアリング:**
- CRITICAL: ×15 点, WARNING: ×5 点, INFO: ×0.5 点
- Health Score = MAX(0, 100 − C×15 − W×5 − I×0.5)
- 出力: PASS / FAIL / PARTIAL ベルディクト

**spec-audit（`.claude/skills/spec-audit/SKILL.md`）**: API 仕様書向け QA（ISTQB/BABOC/OWASP 準拠。4 フェーズ・10 チェックポイント）。一般的な自然言語ドキュメントレビューには不向き。

**output-review（`.claude/skills/output-review/SKILL.md`）**: 他 skill の出力をそのチェックリストに照らしてレビューするメタ skill。自然言語ドキュメント直接レビューには不向き。

#### 取得推奨ファイル

| ファイル | 備考 |
|---|---|
| `.claude/skills/doc-lint/SKILL.md` | 取得・解読済み（最重要） |
| `.claude/skills/spec-audit/SKILL.md` | 取得・解読済み（参考程度） |
| `.claude/qa-antipatterns/` 配下 | アンチパターン定義集 |
| `.claude/protocols/` 配下 | プロトコル定義集 |

#### 評価

`doc-lint` は**ドキュメント品質監査の堅実な実装**。SSOT 違反検出・クロスファイル重複検出・自動修正スクリプト生成まで含む 7 フェーズ構成が特徴。Health Score 数値化も実用的。「内容の論理整合性」ではなく「ドキュメント構造・サイズ・重複」の機械的チェックに特化している点に注意。

---

### 2.3 awesome-skills/code-review-skill

**アクセス不可（404）。** リポジトリが削除・非公開化・名称変更された可能性が高い。調査対象から除外。

---

### 2.4 zzhiyuann/claude-code-skills

**アクセス不可（404）。** リポジトリが削除・非公開化・名称変更された可能性が高い。調査対象から除外。

---

## 3. 新規発見リポジトリ

### 3.1 borghei/Claude-Skills

| 項目 | 内容 |
|---|---|
| URL | https://github.com/borghei/Claude-Skills |
| ライセンス | **MIT + Commons Clause**（OSS・個人・社内業務利用は無料。有償製品への組込み・再販売は不可） |
| 対象ドキュメント種別 | 契約書・NDA・法的文書全般 |
| テンプレート有無 | `references/` ディレクトリに clause_analysis_guide.md / negotiation_playbook.md あり |
| 規模 | 245 skill、14 ドメイン、11 AI アシスタント対応、653 Python ツール |

#### フロー概要（legal ドメイン）

**contract-review（`legal/contract-review/SKILL.md`）**

```
Standard Review（6 ステップ）:
  1. 契約書読み込み
  2. プレイブック照合（references/clause_analysis_guide.md）
  3. 条項別 GREEN/YELLOW/RED 分類
  4. リスク分析レポート生成
  5. ネゴシエーション推奨事項作成
  6. レッドライン文書生成

Rapid Risk Triage（迅速リスクトリアージ）:
  - 即座に CRITICAL 問題を 3 点以内で提示

レッドライン優先度:
  - Must-Have: ビジネス上容認不能なリスク
  - Should-Have: 標準的法的保護の不足
  - Nice-to-Have: 有利化のための交渉点

ツール:
  - contract_analyzer.py
  - redline_generator.py
  - references/clause_analysis_guide.md
  - references/negotiation_playbook.md
```

**tabular-document-review（`legal/tabular-document-review/SKILL.md`）**

```
5 ステップパイプライン:
  1. 要件収集（抽出対象フィールド定義）
  2. 対象ドキュメント探索
  3. 並列処理（最大 10 サブエージェント同時起動）
     └── 各エージェント: ドキュメント読込 → フィールド抽出 → 構造化
  4. 結果集約
  5. 比較マトリクス出力（Markdown テーブル）

信頼度スコア: HIGH / MEDIUM / LOW
事前定義カラムセット: 契約書 / NDA / 雇用契約 / リース契約
```

#### 取得推奨ファイル

| ファイル | 備考 |
|---|---|
| `legal/contract-review/SKILL.md` | 取得・解読済み |
| `legal/tabular-document-review/SKILL.md` | 取得・解読済み |
| `legal/nda-review/SKILL.md` | 未取得（NDA レビュー skill） |
| `legal/nda-triage/SKILL.md` | 未取得（NDA トリアージ skill） |
| `legal/legal-red-team/SKILL.md` | 未取得（法的レッドチーム skill） |
| `legal/legal-risk-assessment/SKILL.md` | 未取得（法的リスク評価 skill） |
| `legal/dpia-assessment/SKILL.md` | 未取得（DPIA 評価 skill） |
| `references/clause_analysis_guide.md` | 未取得（条項分析ガイド） |
| `references/negotiation_playbook.md` | 未取得（交渉プレイブック） |

#### 評価

**法的文書レビューの充実した実装例**。GREEN/YELLOW/RED の 3 段階リスク分類・レッドライン生成・交渉プレイブック参照が特徴。`tabular-document-review` の並列エージェント（最大 10 エージェント）による大量文書の比較マトリクス生成は、複数文書を横断的に比較する場面で特に有用。Commons Clause 付き MIT ライセンスのため利用用途に注意が必要。

---

### 3.2 Vera-Solutions-Org/amp-bd-dashboard-demo

| 項目 | 内容 |
|---|---|
| URL | https://github.com/Vera-Solutions-Org/amp-bd-dashboard-demo |
| 対象 | `DESIGN_REVIEW_SKILL.md` |
| 評価 | **対象外**（UI/UX デザインレビュー skill。React/Vue/Angular コンポーネントのビジュアル・アクセシビリティ・レスポンシブデザインレビューが対象であり、自然言語文書レビューではない） |

---

## 4. 横断比較表

| リポジトリ | ドキュメント種別 | レビュー方式 | スコアリング | テンプレート | ライセンス | 推奨度 |
|---|---|---|---|---|---|---|
| garrytan/gstack | 計画書・設計書 | 対話型（AskUserQuestion） | セクション別評価 + Completion Summary | SKILL.md.tmpl あり | MIT | **高** |
| vlad-ryzhkov/AI-QA-workshop-feb19 | Markdown 全般 | 自動監査 | Health Score (0–100) | アンチパターン定義集あり | Unlicense | **高** |
| borghei/Claude-Skills | 契約書・法的文書 | 条項分析 + レッドライン生成 | GREEN/YELLOW/RED | references/ あり | MIT + Commons Clause | **中〜高** |
| awesome-skills/code-review-skill | — | — | — | — | — | 404 (除外) |
| zzhiyuann/claude-code-skills | — | — | — | — | — | 404 (除外) |
| Vera-Solutions-Org/amp-bd-dashboard-demo | UI/UX (対象外) | — | — | — | — | 対象外 |

---

## 5. 取得済み SKILL.md の要約

### 5.1 garrytan/gstack — plan-eng-review/SKILL.md.tmpl

エンジニアリングマネージャー視点での計画書レビュー skill。`AskUserQuestion` 呼び出しを軸にした対話型 4 セクション構成（アーキテクチャ / コード品質 / テスト / パフォーマンス）で、1 課題 = 1 質問の原則を厳守する。「複雑度チェック（8+ ファイル or 2+ 新クラス）」「TODOS.md 照合」「DRY・明示的 > 巧妙」といったエンジニアリング哲学を判断基準に埋め込み、15 の認知パターン（状態診断・ブラスト半径・退屈デフォルト等）を指針として持つ。Completion Summary と Review Log 書き込みで完了を記録し、design-review / CEO-review への連鎖を提案する。

### 5.2 garrytan/gstack — plan-design-review/SKILL.md.tmpl

シニアプロダクトデザイナー視点での計画書デザインレビュー skill。7 パス構成（情報アーキテクチャ / インタラクション状態カバレッジ / ユーザージャーニー / AI スロップリスク / デザインシステム整合性 / レスポンシブ・アクセシビリティ / 未解決デザイン決定事項）で各パスを 0–10 スコアリングし、FIX TO 10 作業を通じて計画書を改善する。gstack designer ツールを使ったビジュアルモックアップ生成を標準フロー（スキップ条件: バックエンド専用 / ツール未セットアップ）とし、"テキスト説明ではなく見せる" を原則とする。Dieter Rams・Don Norman・Nielsen 等のデザイン原則を参照基盤として持つ。

### 5.3 vlad-ryzhkov/AI-QA-workshop-feb19 — .claude/skills/doc-lint/SKILL.md

ドキュメント品質自動監査 skill。7 フェーズ（Discovery / Size Analysis / Structure Analysis / Cross-File Duplicate Detection / Content Hygiene / Report Generation / Safe-Fix Script）で Markdown ドキュメント群を自動検査する。サイズ制限（1 ファイル 500 行以上 = CRITICAL、200 行以上 = WARNING）・構造ルール（H1 の数・見出し深さ）・クロスファイル重複（コンテンツハッシュ比較）・コンテンツ衛生（TODO 残留・空セクション等）をチェックし、Health Score（0–100）と PASS/FAIL/PARTIAL ベルディクトで評価する。最終出力は `audit/doc-lint-report.md` および安全な自動修正スクリプト。

### 5.4 borghei/Claude-Skills — legal/contract-review/SKILL.md

契約書をプレイブック（`references/clause_analysis_guide.md` / `references/negotiation_playbook.md`）と照合してリスク評価する法的文書レビュー skill。条項別に GREEN/YELLOW/RED の 3 段階でリスク分類し、Must-Have / Should-Have / Nice-to-Have の 3 優先度でレッドライン（修正提案）を生成する。Standard Review（6 ステップ）と Rapid Risk Triage（即座に CRITICAL 問題 3 点以内提示）の 2 モードを持ち、`contract_analyzer.py` と `redline_generator.py` の 2 ツールを使用する。

### 5.5 borghei/Claude-Skills — legal/tabular-document-review/SKILL.md

複数の法的文書から構造化データを一斉抽出して比較マトリクスを生成する skill。5 ステップパイプライン（要件収集 → 文書探索 → 並列処理 → 結果集約 → 出力）で、最大 10 サブエージェントを並列起動して各文書を同時処理する。抽出した情報には HIGH / MEDIUM / LOW の信頼度スコアを付与する。契約書・NDA・雇用契約・リース契約向けの事前定義カラムセットを持ち、カスタムカラムにも対応する。

---

## 6. 調査から得られた示唆

### 6.1 レビュー設計パターンの整理

調査で確認できた設計パターンを 3 種に分類する。

| パターン | 代表実装 | 特徴 |
|---|---|---|
| 対話型インクリメンタルレビュー | garrytan/gstack | AskUserQuestion で 1 課題ずつ確認。ユーザーの承認なしに計画を変更しない。対話オーバーヘッドが高いが判断品質が高い |
| 自動批量監査 | vlad-ryzhkov doc-lint | 人間介在なしに一括チェック。スコア化・自動修正スクリプト生成。大量ドキュメントの構造チェックに適する |
| 並列エージェント抽出 | borghei tabular-document-review | 複数文書を同時処理して比較マトリクスを生成。大量の同形式文書を横断比較する場面に適する |

### 6.2 スコアリング手法の比較

| 手法 | 実装例 | 特徴 |
|---|---|---|
| 数値スコア (0–10) | gstack plan-design-review | パス別スコアで「どこが弱いか」が直感的に分かる。before/after 改善が可視化される |
| Health Score (0–100) | doc-lint | 重みづけ加算式（CRITICAL×15 + WARNING×5 + INFO×0.5 を減点）。自動計算可能で客観性が高い |
| GREEN/YELLOW/RED | borghei contract-review | 法的文書に適した 3 段階分類。非エンジニアでも直感的に理解できる |

### 6.3 本プロジェクト（local RAG 向け Claude Code skill）への応用可能性

自然言語ドキュメントレビュー skill は、RAG の出力レポート（調査報告書・設計書）の品質保証に応用できる。特に以下の要素が参考になる。

- **gstack のテンプレート変数方式**（`{{PREAMBLE}}`・`{{GBRAIN_CONTEXT_LOAD}}` 等）: 共通ロジックを複数 skill 間で共有する仕組みは、本プロジェクトの複数フェーズレポートへの品質チェック適用に活用できる
- **doc-lint の Health Score 方式**: 調査報告書の構造・サイズ・重複チェックを自動化し、レビュー前の品質フィルタとして使える
- **borghei の並列エージェント方式**: 複数フェーズ報告書を横断的に比較するクロス分析に応用できる

---

## 変更履歴

| バージョン | 日付 | 内容 |
|---|---|---|
| 1.0 | 2026-05-04 | 初版作成。前回発見 4 リポジトリの再評価 + 新規検索結果をまとめ |
