# 実装テンプレート（層1+2）— 3チャネル構成の雛形

> 方針レポート（`reports/01.配布・統制方針調査/結論・構成案_…_v1.2.md`）の **§推奨** を、
> コピーして使える**ディレクトリ骨格**へ落とした実装雛形。スコープは作業指示者判断により
> **層1+2（テスト可能なコア）**。層3（Managed settings）は通常マシンで実機検証できないため
> 本雛形には含めず、レポート本文 **§解決案 層3系・案D** の記述に委ねる。

## この雛形の位置づけ

- **層1＝Git commit テンプレート**（`layer1-repo-template/`）: 利用先リポジトリの直下へ
  コピー／commit する最小骨格。**層2 で運べないガバナンス資産**（`CLAUDE.md` / `rules` /
  `permissions`）と、**層2 を起動するための装置**（`settings.json` の
  `extraKnownMarketplaces` / `enabledPlugins`）に絞る。
- **層2＝Plugin / Marketplace**（`layer2-plugin/`）: skills / subagents / hooks /
  output-styles などの**機能資産**を一元更新可能な plugin に集約する骨格。

実装の起点は既存の `<Share>` リポジトリ **`base-dev-kit-for-cc`**
（`empty-can/base-dev-kit-for-cc`・案1/README 隔離）。本雛形はその資産を層1+2 へ
振り分けた姿を示す（base-dev-kit は層1 単独の `<Share>` 実装、本雛形はそれを層2 集約へ進めた形）。

## レポート §推奨 との対応：base-dev-kit 資産の振り分け

| base-dev-kit の資産 | 寄せる先 | 雛形での所在 | 根拠（レポート） |
|---|---|---|---|
| skills（commit-and-pr / orchestrate / request-new-skill / review-skill-request） | **層2** | `layer2-plugin/plugins/base-dev-kit/skills/`（形式雛形 `example-skill/` のみ同梱・実 skill は配布時に追加） | 一元更新・版管理（マトリクス①） |
| `code-reviewer` sub-agent | **層2** | `layer2-plugin/plugins/base-dev-kit/agents/` | plugin 経由可（hooks/mcpServers/permissionMode 不使用＝①△に非該当） |
| `code-review` output-style | **層2** | `layer2-plugin/plugins/base-dev-kit/output-styles/` | 機能資産（マトリクス①） |
| SessionStart hook（`git status --short`） | **層2** | `layer2-plugin/plugins/base-dev-kit/hooks/hooks.json` | hooks は plugin で自己完結（①）。本例はインラインコマンドのみで同梱スクリプト不要。スクリプトを同梱する hook は `${CLAUDE_PLUGIN_ROOT}/...` で参照する |
| `CLAUDE.md`（共通ガバナンス） | **層1** | `layer1-repo-template/.claude/CLAUDE.md` | plugin で運べない（マトリクス②） |
| `rules/coding-standards.md` | **層1** | `layer1-repo-template/.claude/rules/` | 常時 rule は skill 化でも代替不可（②） |
| `permissions`（deny/allow） | **層1** | `layer1-repo-template/.claude/settings.json` | plugin で運べない（②） |
| **層2 起動装置**（extraKnownMarketplaces / enabledPlugins） | **層1** | `layer1-repo-template/.claude/settings.json` | 層2 有効化の前提・project commit（②） |
| README（リポ固有情報） | 層1（隔離先） | `layer1-repo-template/README.md.example` | README 隔離方式（README は memory ファイルでなく `--add-dir`+env でも非ロード） |

> **△回避の注記**: `hooks` / `mcpServers` / `permissionMode` を使う sub-agent は plugin 経由だと
> 当該設定が無視される（マトリクス①△）。そうした sub-agent は層1 commit か層3 managed へ。
> 本雛形の `code-reviewer` はこれらを使わないため層2 で問題ない。

## 起動装置が「のり」

層1 と層2 を繋ぐのは、層1 に commit する `settings.json` の 2 キー:

- `extraKnownMarketplaces` — plugin を取得する Marketplace を宣言（project スコープでチーム配布）
- `enabledPlugins` — どの plugin を有効化するかを宣言

これらを project（`.claude/settings.json`）に commit することで、clone したメンバー全員に
層2 plugin が誘導される。**user スコープ（`~/.claude/`）はチーム配布にならない**点に注意。
ただし「clone だけで即利用可」ではなく、trust 時のインストールプロンプト、fresh machine での
`claude plugin install` が必要になりうる（レポート §解決案 層2系の注意事項）。

> **コピー後の置換（必須）**: 雛形のプレースホルダを自組織の実値へ置換する——`.claude/settings.json` の `your-org/base-dev-kit-marketplace`（→ 実 Marketplace リポジトリ）、`marketplace.json`・`plugin.json` の `Your Team`・`team@example.com`（→ 実チーム名・連絡先）。未置換のままだと存在しない repo を参照し層2 が起動しない。

## ディレクトリ構成

```
03.実装テンプレート（層1+2）/
├── README.md                          # 本ファイル
├── layer1-repo-template/              # 層1: 利用先リポへ commit する骨格
│   ├── .claude/
│   │   ├── CLAUDE.md                  # 共通ガバナンス（README 隔離・--add-dir+env でロード）
│   │   ├── rules/coding-standards.md  # path-scoped 規約
│   │   ├── settings.json             # permissions ＋ 層2 起動装置 ★のり
│   │   └── settings.local.json.example
│   ├── .mcp.json
│   ├── .env.example
│   ├── .gitignore
│   ├── CLAUDE.md.example             # 方法A コピー展開用のリポ固有 CLAUDE.md 雛形
│   └── README.md.example             # リポ固有情報の隔離先 雛形
└── layer2-plugin/                     # 層2: plugin + marketplace 骨格
    ├── marketplace/
    │   └── .claude-plugin/
    │       └── marketplace.json      # Marketplace 定義（plugin の所在を列挙）
    └── plugins/
        └── base-dev-kit/
            ├── .claude-plugin/
            │   └── plugin.json       # plugin メタデータ
            ├── skills/example-skill/SKILL.md
            ├── agents/code-reviewer.md
            ├── output-styles/code-review.md
            └── hooks/hooks.json      # SessionStart（インライン git status --short）
```

> Marketplace と plugin は本雛形では 1 リポジトリ内に併置しているが、実運用では
> Marketplace を独立リポジトリにして複数 plugin を集約する構成も採れる
> （レポート §解決案 層2系・案B/B'）。

## テスト手順への導線

本雛形の開発・テスト手順は既存の成果物に詳述済み。重複させず参照する:

- **層2（plugin）の開発・テスト**: `reports/02.配布物の開発・テスト/01.Plugin・Marketplace編/`
  - ローカルテスト = `claude --plugin-dir layer2-plugin/plugins/base-dev-kit`
  - 構造検証 = `claude plugin validate layer2-plugin/plugins/base-dev-kit`
- **層1（Marketplace 外資産）の開発・テスト**: `reports/02.配布物の開発・テスト/02.Marketplace外資産編/`
  - ネイティブ起動スモーク（方法A）／`--add-dir` + env + `--settings` 結合検証（方法B）
  - 公開前ゲート = `check-payload`（衛生）＋ `/security-review`（脆弱性）
  - 検証コマンド = `/memory`・`/context`・`/status`・`/doctor`・`/skills`・`/agents`・`/plugin`

## スコープ外（層3）

層3（Managed settings）はガバナンス資産の**強制**チャネルだが、server-managed は
Claude for Teams/Enterprise 契約、endpoint-managed は MDM／OS 管理者権限が前提で、
通常の開発マシンでは雛形を実機検証できない。設定キー・配置パス・選択軸（server-managed vs
endpoint-managed）はレポート **§解決案 層3系・案D** と **付録A** に整理済み。本雛形では扱わない。
