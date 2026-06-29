# 配布計画 — Plugin 配布可否と統合・清書・テストのリポジトリ割当

> [配布可能資産インベントリ](../01.全マシン資産インベントリ/配布可能資産インベントリ.md)を入力に、各資産を **Plugin（層2）で配布できる/できない**に分類し、**どのリポジトリで統合・清書・テストするか**を割り当てる計画。略号は §0 インベントリ準拠（`C-`=cc-workspace／`W-`=workspace／`U-`=ユーザスコープ）。
>
> 根拠: 公式 docs（plugins / plugins-reference / skills、v2.1.195 相当）＋ 内部 v1.2 チャネルマトリクス。

## 1. Plugin が同梱できる/できないコンポーネント（確定）

公式 docs で確認済みの type-level の可否（本計画の前提）。

### Plugin で配布**できる**（層2 コンポーネント）
`skills/`（SKILL.md＋reference/examples/scripts 等のサポートファイル同梱可）／`commands/`（レガシー・新規は skills 推奨）／`agents/`（**`hooks`・`mcpServers`・`permissionMode` フロントマターキーは利用不可**）／`hooks/hooks.json`（参照スクリプトは `${CLAUDE_PLUGIN_ROOT}` で同梱）／`.mcp.json`／`output-styles/`／`.lsp.json`／`monitors/`(v2.1.105+)／`themes/`(experimental)／`bin/`／`settings.json`（**`agent` と `subagentStatusLine` キーのみ**・他は silently ignored）

### Plugin で配布**できない**（→ 層1 Git / 層3 Managed / `--add-dir`）
| 資産 | 理由 | 代替配布手段 |
|---|---|---|
| `CLAUDE.md` / project memory | plugin root の CLAUDE.md は**非ロード**（明示除外） | skill 化して同梱／層1 Git／`--add-dir`+env |
| `rules/*.md`（path-scoped） | plugin コンポーネント未定義 | **skill の `paths:` frontmatter**／層1 Git／managed `CLAUDE.md` 経由 |
| `settings.json` の `permissions`(allow/deny) | 非サポートキー（silently ignored） | **層3 managed settings**／層1 Git（強制力なし） |
| メインセッション `statusLine` スクリプト | plugin は `subagentStatusLine` のみ対応 | 層1 Git／ユーザ・プロジェクト settings |
| standalone な `templates/` | plugin コンポーネント未定義 | **skill のサポートファイルとして同梱**／層1 Git |
| plugin 外ファイル参照 | install 後 cache にコピーされない | plugin ディレクトリ内に内包 |

## 2. 本インベントリ資産の配布チャネル分類

インベントリの各クラスタを当てはめた結果。**汎用共有**（全チームに配る）と**テーマ特化**（特定調査専用・据え置き）を区別する。

### 2-A. Plugin（層2）で配布 — 汎用共有
| 資産 | 正本 | 備考 |
|---|---|---|
| `skills/commit-and-pr` | C-BDC（=多数一致） | そのまま |
| `skills/orchestrate` | C-BDC（=多数一致） | そのまま |
| `skills/request-new-skill` | C-BDC | **依頼書テンプレを skill サポートファイルへ同梱**（standalone templates/ は不可） |
| `skills/review-skill-request` | C-BDC | 同上（`skill-request/` の2テンプレを内包） |
| `skills/5-whys`（+examples/references） | C-CRI/C-RBC/W-RBC（一致） | サポートファイル同梱は plugin 正式対応 |
| `skills/check-model` | C-CRI/C-RBC | そのまま |
| `skills/read-prompt-file`（+README+sh） | C-CRI/C-RBC | スクリプトは plugin 内へ |
| `skills/pre-compact` | **C-CRI(122)** | ⚠️96版でなく122版。`references/decision-flow.md` 同梱 |
| `agents/code-reviewer` | C-BDC（=多数一致） | `hooks`/`mcpServers`/`permissionMode` 不使用＝plugin 可 |
| `output-styles/code-review` | C-BDC（=多数一致） | そのまま |
| `hooks`（SessionStart: git status --short 等） | C-BDC settings | plugin では `hooks/hooks.json` 化（インラインコマンド） |

### 2-B. Plugin（層2）で配布可能だが**テーマ特化** — 別 plugin か据え置き
| 資産 | 所在 | 推奨 |
|---|---|---|
| `skills/generate-llms-txt` | C-CRI | docs テーマ。**C-CRI/C-LLM に据え置き**（汎用 plugin に入れない） |
| `skills/update-official-doc-summary` | **C-LLM(359 正式)** | docs パイプライン。**C-LLM 据え置き** |
| `agents/doc-summary-reviewer` | **C-LLM(94)** | 同上・C-LLM 据え置き |
| `agents/cc-docs-*-expert` ×4 | W-RBC（未追跡） | RAG/governance 専用。**据え置き**（配布対象外の公算大） |

### 2-C. Plugin 不可 — 層1 Git body（C-BDC）/ 層3 Managed へ
| 資産 | 正本 | チャネル |
|---|---|---|
| `CLAUDE.md`（チーム共通） | **C-BDC(50)** | 層1 Git body／`--add-dir`+env |
| `settings.json` の permissions | **C-BDC(39)**(+show/blame 検討) | 層1 Git／（強制は層3 managed） |
| `rules/coding-standards.md` | 全一致 | 層1 Git body |
| `rules/agent-delegation.md` / `git-workflow.md` / `research-source-routing.md` | W-RBC | 層1 Git body（無条件ロード系） |
| `rules/agent-permission-runtime.md` / `cross-review-runtime.md` / `skill-creation-guide.md` | C-CRI/C-RBC/W-RBC | 層1 Git body（path-scoped） |
| `templates/cross-review/` | **W-RBC(v3.0α-r2)** | 層1 Git body（または将来 cross-review skill のサポートファイル化） |
| `templates/inter-claude-communication/` | 一致 | 層1 Git body |
| `statusline`（メインセッション） | **C-RBC(162)+U-USR(145)** | 層1 Git／ユーザ settings（plugin 不可） |

> **重要な含意**: 共有 `.claude` の中身は **2トラックに分かれる**。機能資産（skills/agents/output-styles/hooks）は Plugin 化できるが、ガバナンス資産（CLAUDE.md/rules/settings permissions/templates/statusline）は Plugin 化できず層1 Git（C-BDC body）が主経路。**Plugin だけでは共有 `.claude` を再現できない**——これは v1.2 の「単一手段では配れない／3チャネル併用」結論の再確認。

## 3. 統合・清書・テストのリポジトリ割当

### 3-1. 集約先（統合・清書を行う場所）
- **汎用共有資産は C-BDK（base-dev-kit-for-cc／`<Dev>`）に一元集約**する。C-BDK は既存 dev-flow の開発源（`.claude/` body ＋ `scripts/` 配布運用ツールを保持）。散在する正本（C-CRI/C-RBC/W-RBC 由来の 5-whys・check-model・read-prompt-file・rules・cross-review テンプレ・pre-compact等）を C-BDK へ取り込み・清書する。
- **テーマ特化資産（2-B）は各ホーム据え置き**（C-LLM=docs パイプライン、W-RBC=cc-docs-expert）。汎用配布に混ぜない。

### 3-2. 2トラックの開発→テスト→配布

```
                 ┌─────────────────────────────────────────────┐
                 │   C-BDK  base-dev-kit-for-cc  （<Dev>＝集約・清書）   │
                 │   散在正本を取り込み・清書（汎用共有のみ）            │
                 └───────────────┬─────────────────────┬─────────┘
       層1（ガバナンス資産）         │                     │  層2（機能資産）
   CLAUDE.md/settings/rules/        │                     │  skills/agents/output-styles/hooks
   templates/statusline            │                     │
                                   ▼                     ▼
            ┌──────────────────────────┐   ┌──────────────────────────────┐
            │ テスト（層1 body）            │   │ テスト（層2 plugin）              │
            │ clean-test-env + check-assets│   │ claude --plugin-dir            │
            │ + --add-dir 実機(手順書v1.6) │   │ + claude plugin validate --strict│
            └────────────┬─────────────┘   │ + ローカル marketplace install 検証 │
                         │                  └────────────┬─────────────────┘
                         ▼ publish-share(Sync A)         │ git push
            ┌──────────────────────────┐   ┌──────────────────────────────┐
            │ C-BDC basic_dot_claude       │   │ C-MKT marketplace-for-cc        │
            │ （.claude body・submodule源）  │   │ （marketplace.json で配布）        │
            └────────────┬─────────────┘   └────────────┬─────────────────┘
                         ▼ submodule bump                ▼ /plugin marketplace add + install
            ┌──────────────────────────┐   ┌──────────────────────────────┐
            │ C-BCP basic_cc_project（雛型） │   │ 利用先プロジェクト                  │
            └──────────────────────────┘   └──────────────────────────────┘
```

| トラック | 統合・清書 | テスト | 配布 | 既存資産 |
|---|---|---|---|---|
| **層1 Git body** | C-BDK `.claude/` | clean-test-env / check-assets / `--add-dir` 実機 | publish-share → C-BDC → C-BCP submodule | 手順書 v1.6・scripts 6本（C-BDK） |
| **層2 Plugin** | C-BDK 内に plugin 開発エリア | `--plugin-dir` / `plugin validate --strict` / ローカル marketplace | push → C-MKT marketplace | layer2-plugin テンプレ（reports/03） |

## 4. 判断事項と確定結果（2026-06-29 確定）

| # | 論点 | 確定 |
|---|---|---|
| 1 | 機能資産（skills/agents/output-styles/hooks）のチャネル | **dual** — C-BDC body は完全 standalone を維持（`--add-dir`/コピー展開で plugin 無しでも動く）しつつ、marketplace 派向けに plugin も併発行。v1.2「3チャネル併用」と整合 |
| 2 | Plugin 開発リポジトリのトポロジ | **multi-repo** — C-BDK（`<Dev>`）で開発・validate → C-MKT は marketplace.json で参照する薄い配布リポ |
| 3 | テーマ特化資産（2-B） | **据え置き** — C-LLM(docs)/W-RBC(cc-docs)/C-CRI(generate-llms-txt) に残置。将来必要時に別 plugin 化を再検討 |
| 4 | rules / templates の plugin 化 | **当面 層1 Git body のまま**（`--add-dir`+env 経路あり）。主要 rule の skill `paths:` 化は将来オプション |
| 5 | pre-compact の正本 | **C-CRI 122版**を配布採用（W-RBC 96版・未追跡は破棄） |

> 含意: dual 採用により、機能資産は「C-BDC body（層1）」と「plugin（層2）」の**両方に存在**する。両者の同期は C-BDK を単一集約源とすることで担保する（C-BDK の `.claude/` 正本 → body は publish-share、plugin は同じ正本から組成）。

## 5. 推奨実行順序（次フェーズ）

1. **層1 body の統合・清書**（C-BDK）: rules 群・cross-review テンプレ(W-RBC正本)・CLAUDE.md・settings(+show/blame)・statusline を C-BDK `.claude/` に取り込み清書 → clean-test-env/check-assets → publish-share で C-BDC へ。
2. **層2 plugin の組成**（C-BDK）: layer2-plugin テンプレに汎用 skills（pre-compact=122版・request/review はテンプレ同梱）＋code-reviewer＋code-review＋hooks を実装 → `plugin validate --strict` → C-MKT へ push。
3. **C-MKT marketplace.json 整備**（greenfield からの新規構築）。
4. テーマ特化資産は据え置き（必要時に別 plugin 化を再検討）。

---

## 変更履歴

- 初版（2026-06-29）: Plugin 配布可否（公式docs v2.1.195＋v1.2 マトリクス照合で確定）を本インベントリ資産に適用。汎用共有/テーマ特化を区別し、層1 Git body（C-BDK→C-BDC）と層2 Plugin（C-BDK→C-MKT）の2トラックで統合・清書・テスト・配布のリポジトリを割当。判断点5件と実行順序を提示。
