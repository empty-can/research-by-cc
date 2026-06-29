# Plugin・Marketplace 配布物の開発・テスト — 調査結果（v1.0）

> - **想定読者**: 層2（Plugin / Marketplace）で資産を配布するチームの開発担当者。「配布専用リポジトリに載せる plugin / skill を、どこで・どうやって開発しテストするのが Claude Code の標準/推奨なのか」を知りたい読み手。
> - **位置づけ**: 「ポータブルな `.claude/` のチーム共有・統制」調査（[結論・構成案 v1.2](../../01.配布・統制方針調査/結論・構成案_ポータブルな.claude共有_v1.2.md)）の **層2（Plugin / Marketplace）実務続編**。v1.2 が「**何を**どのチャネルで配れるか（資産×チャネル マトリクス）」を確定したのに対し、本書は「層2 で配ると決めた資産を **どこで・どう開発しテストするか**」を扱う。
> - **作成日**: 2026-06-21
> - **根拠ドキュメント**: Claude Code 公式ドキュメント（ローカル DL 版 `llms-full.txt`）。担当ページは `docs/plugins` / `docs/plugin-marketplaces` / `docs/plugins-reference` / `docs/skills`。本書の出典は**ページ名＋セクション**を主アンカーとする（行番号は snapshot 依存のため [§出典](#sources) に参考値として併記）。原文照合は `cc-docs-plugins-marketplace-expert`（公式 docs 原文忠実 agent）による。

---

<a id="summary"></a>

## エグゼクティブサマリ（結論の先出し）

**問い**: Marketplace（配布専用リポジトリ）で配る plugin / skill を、どこで・どのように開発・テストするのが Claude Code の標準/推奨パターンか。

**結論**: 公式は **一本道のフロー**を推奨している。

> **「まず `.claude/` のスタンドアロン設定で素早くイテレーションし、共有準備ができたらプラグイン化する」**（`docs/plugins`）

ポイントは、**開発・テストの主戦場はローカルであり、Marketplace への登録は配布段階で初めて行う**こと。開発中はマーケットプレイス登録すらせず、`--plugin-dir` フラグで plugin を直接ロードして検証する。すなわち **「開発・テスト環境」と「配布専用リポジトリ（Marketplace）」は役割が別物**であり、両者を分離するのが公式フローの前提になっている。

- **開発の主手段** = `claude --plugin-dir ./my-plugin`（marketplace 登録・install 不要でプラグインを直接ロード）
- **イテレーション** = `/reload-plugins`（再起動なし反映）／skill の `SKILL.md` はライブ変更検出
- **配布形態の検証** = ローカルディレクトリを `claude plugin marketplace add ./local-mp` で「ローカル marketplace」化し、install〜uninstall を実地確認
- **公開前ゲート** = `claude plugin validate`（提出前必須・レビューパイプラインが同じ検査を回す）

本書冒頭で確認した制約 ——「plugin が運べるのはプラグインディレクトリ単位で、`CLAUDE.md` / `rules/` / `settings.json` 等のリポジトリ統制設定そのものは plugin 配布の対象外」—— は、**層2 を選んだ時点での当然の帰結**であり（v1.2 [§マトリクス](../../01.配布・統制方針調査/結論・構成案_ポータブルな.claude共有_v1.2.md) ②と整合）、Marketplace 開発手順のスコープでは問題にならない。これらの「Marketplace で配れない資産」の開発・テストは**別調査**（本タスクの後続フェーズ）で扱う。

---

## 問い・スコープ

- **問い**: 配布専用リポジトリ（Marketplace）で配布する plugin / skill を、どこで・どのように開発・テストするのが一般的か。Claude Code としての標準・推奨パターンは存在するか。
- **スコープ内**: 層2 で配布できる資産（plugin、plugin 同梱の skills / commands / agents / hooks / MCP / LSP / bin 等、および skill 単体）の開発・テストのワークフロー・コマンド・起動オプション・検証手段。
- **スコープ外**: 層2 で配れない資産（`CLAUDE.md` / `rules/` / `settings.json` 等のガバナンス資産）の開発・テスト → 本タスクの後続フェーズで扱う。各資産がどのチャネルで配れるかの判断は v1.2 マトリクスに委譲。

---

<a id="flow"></a>

## 1. 公式が示す開発・テストフロー（全体像）

公式ドキュメントは、配布物の作成を以下の段階で説明している（`docs/plugins`）。

```
① standalone .claude/ で素早くイテレーション
        │   （まだ plugin 化しない。最速で試行錯誤する段階）
        ▼
② 共有準備ができたら plugin 化（plugin.json を付与）
        │
        ▼
③ ローカルで開発テスト
        │   主: claude --plugin-dir ./my-plugin   （marketplace 登録なしで直接ロード）
        │   副: claude plugin marketplace add ./local-mp → /plugin install   （配布形態の検証）
        │   反映: /reload-plugins ／ skill は SKILL.md ライブ検出
        ▼
④ 公開前バリデーション
        │   claude plugin validate .   （提出前必須。レビューパイプラインも同じ検査）
        ▼
⑤ 配布専用リポジトリ（Marketplace）へ push
            利用者: /plugin marketplace add <repo> → /plugin install
```

**設計上の含意**: ③ の開発テストは**ローカルで完結**し、Marketplace（⑤）は配布の器でしかない。したがって「開発・テストリポジトリ（ローカル）」と「配布専用リポジトリ（公開）」を分けるのが自然な構成になる。公式は両者の分離を明示的に強制も否定もしていないが、フロー全体がこの分離を前提に組まれている。

---

<a id="means"></a>

## 2. 開発・テストの具体手段（主 → 副）

公式が「主たる開発手段」として説明しているのは **`--plugin-dir` フラグ**であり、ローカル marketplace 登録はその次（配布形態まで含めた検証）に位置づけられる。

| 手段 | 何をするか | 主な特性 | 出典ページ |
|---|---|---|---|
| **`claude --plugin-dir ./my-plugin`**（主） | marketplace 登録・install なしでプラグインを直接ロードしてテスト | `.zip` アーカイブも可（v2.1.128+）／フラグ反復で複数 plugin 同時ロード／`--plugin-url` で CI ビルド成果物 URL からもロード可 | `docs/plugins` |
| **`claude plugin init my-tool`** | `~/.claude/skills/my-tool/` を生成し、次セッションで `my-tool@skills-dir` として自動ロード | install / marketplace 不要。`--plugin-dir` と違い毎回のフラグ指定も不要 | `docs/plugins` |
| **`claude plugin marketplace add ./local-mp`**（副） | ローカルディレクトリを marketplace として登録し、配布形態ごと検証 | `marketplace.json` 込みで install→uninstall→reinstall の実地確認に使う。`/plugin marketplace add ./...` のセッション内コマンドも等価 | `docs/plugin-marketplaces` |

### イテレーション（編集 → 反映 → 確認）

| 機構 | 反映対象 | 反映トリガ | 出典ページ |
|---|---|---|---|
| **`/reload-plugins`** | plugin・skills・agents・hooks・plugin MCP / LSP サーバ | コマンド実行（再起動不要） | `docs/plugins` |
| **skill のライブ変更検出** | `SKILL.md` の追加・編集・削除 | セッション内で**即時**（`~/.claude/skills/`・project `.claude/skills/`・`--add-dir` 配下の `.claude/skills/`） | `docs/skills` |
| （上の例外） | skill が plugin でもある場合の `hooks/`・`.mcp.json`・`agents/`・`output-styles/` 変更 | `/reload-plugins` が必要 | `docs/skills` |

### `--plugin-dir` の優先度（インストール済み plugin の上書きテスト）

同名のインストール済み marketplace plugin がある場合、**`--plugin-dir` のローカルコピーがそのセッションで優先**される。アンインストールせずに、配布中の plugin への変更をテストできる（`docs/plugins`）。
※ ただし managed settings で force-enable / force-disable された plugin はこの方法で上書きできない。

---

<a id="repo-relation"></a>

## 3. 配布専用リポジトリと開発・テスト環境の関係

### (1) standalone → plugin への昇格

公式の昇格判断（`docs/plugins`／v1.2 とも整合）:

- **standalone `.claude/`** … イテレーションが速い。試行錯誤段階・単一リポジトリ内利用に最適。
- **plugin 化** … versioned / shareable / marketplace 配布が必要になった段階で行う。

つまり「開発・テストリポジトリ（ローカル・standalone `.claude/` ベース）」で機能を作り込み、固まったら plugin 化して「配布専用リポジトリ（Marketplace）」へ載せる、という二段構えが公式の想定線。

### (2) キャッシュコピー挙動（配布時の最重要制約）

> 利用者が plugin をインストールすると、Claude Code は plugin ディレクトリを**キャッシュ場所（`~/.claude/plugins/cache`）へコピー**して使う（in-place では使わない）。（`docs/plugin-marketplaces` / `docs/plugins-reference`）

この挙動から導かれる制約:

- **配布可能な単位は「プラグインディレクトリ単位」**。plugin ディレクトリの外にあるファイル（例: `../shared-utils`）への相対参照は、コピーされないため**配布後に壊れる**。
- 従って `.claude/settings.json` / `CLAUDE.md` / `rules/` 等の**プロジェクト設定全体は plugin 配布の対象外**。
  → これは v1.2 [§マトリクス](../../01.配布・統制方針調査/結論・構成案_ポータブルな.claude共有_v1.2.md) ②（ガバナンス資産は層2 で運べない）の**裏付け**であり、Marketplace 開発手順のスコープでは制約ではなく**前提**。

### (3) monorepo / multi-repo と source 参照

- `marketplace.json` の `source: "./plugins/..."` のような**相対パス参照は git 経由配布でのみ機能**（URL-based marketplace では不可）。
- `source` フィールドは**外部リポジトリ参照**も取れるため、薄い「配布専用 marketplace リポジトリ」が、別々のプラグイン開発リポを指す **multi-repo 構成**も可能。
- 反対に全 plugin を 1 リポにまとめる **monorepo** も可。ドメイン混在・保守責任の曖昧化というトレードオフがある（公式は monorepo 向けに `git-subdir` ソース / `--sparse` 取得を用意。v1.2 案B 補足参照）。

---

<a id="skill-only"></a>

## 4. スキル単体（plugin に包まない `.claude/skills/`）の開発・テストとの差異

skill は plugin に同梱せず `.claude/skills/` 単体でも配布できる（v1.2 マトリクス①）。開発・テストの観点で plugin 同梱版と異なる点:

| 観点 | スキル単体（`.claude/skills/`） | plugin 同梱スキル |
|---|---|---|
| 開発時のロード | project / `~/.claude/` / `--add-dir` 配下に置けば自動ロード | `--plugin-dir` またはローカル marketplace install |
| ライブ変更検出 | あり（`SKILL.md` の編集は**即時反映**） | `/reload-plugins` が必要 |
| 呼び出し名 | `/hello`（短いコマンド名） | `/plugin-name:hello`（名前空間付き） |
| hooks / MCP の同梱 | 不可 | 可能 |
| 配布チャネル | バージョン管理へ commit（層1） | Marketplace 経由（層2） |

### skill 開発を支援する純正ツール

- **`skill-creator` プラグイン**（純正）… skill の eval ループを自動化（テストケース `evals/evals.json` 蓄積／テストケース毎に subagent を spawn する隔離実行／アサーション照合の採点 `grading.json`／skill 有無の pass 率・時間・token を比較する `benchmark.json`／2 版の blind A/B＝version comparison／description tuning／HTML の review viewer）。`/plugin install skill-creator@claude-plugins-official`（`docs/skills`）。
  - 公開リソース（英語・日本語版未確認）: 本体 `https://github.com/anthropics/claude-plugins-official/tree/main/plugins/skill-creator`／README `https://github.com/anthropics/claude-plugins-official/blob/main/plugins/skill-creator/README.md`／eval 形式 `https://agentskills.io/skill-creation/evaluating-skills`／公式ブログ `https://claude.com/blog/improving-skill-creator-test-measure-and-refine-agent-skills`
- **`claude plugin init <name>`** … `~/.claude/skills/<name>/` を scaffold（雛形生成。`.claude-plugin/plugin.json` ＋ starter `SKILL.md` を生成、次セッションで `<name>@skills-dir` ロード）。

### `--add-dir` と skill の関係（テスト時に有用）

`--add-dir` / `/add-dir` は本来「ファイルアクセス権の付与」であり設定の自動探索はしないが、**いくつかの構成要素は例外として `<dir>/.claude/` から自動ロードされる**（`docs/permissions` の表）:

| 構成 | `--add-dir` から自動ロード |
|---|---|
| skills（`.claude/skills/`） | ✅ live reload |
| **subagents（`.claude/agents/`）** | ✅（v2.1.178+。v2.1.165 までは非ロード） |
| `settings.json` の `enabledPlugins` / `extraKnownMarketplaces` | ✅（この2キーのみ） |
| `CLAUDE.md` / `.claude/rules/` / `CLAUDE.local.md` | △ `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` を付けた時のみ |
| `settings.json` のそれ以外（permissions/hooks 等）・commands・output-styles | ❌ |

※ これら例外は **`--add-dir` フラグ／`/add-dir` コマンド限定**。`permissions.additionalDirectories` 設定経由では一切ロードされず、ファイルアクセス付与のみ。
→ 開発・テストリポジトリ（ローカル）と作業リポジトリを**結合してテスト**する際、**skill と subagent** はこの `--add-dir` 例外で結合できる。`CLAUDE.md` / `rules` は環境変数併用、`settings.json` の大半は別経路（v1.2 案C）。

---

<a id="validate"></a>

## 5. 検証・デバッグ（公式の注意点）

| 手段 | 用途 | 検出内容 | 出典ページ |
|---|---|---|---|
| **`claude plugin validate .`**（`/plugin validate .`） | 公開前バリデーション（**公開審査のある Marketplace への提出時は必須／private な独自 Marketplace では推奨**） | marketplace ディレクトリ対象時: `marketplace.json` の schema・重複 plugin 名・source のパストラバーサル・各 `plugin.json` とのバージョン不整合／plugin ディレクトリ対象時: skill・agent・command・hook の frontmatter、`hooks/hooks.json` の JSON 構文 | `docs/plugins` / `docs/plugin-marketplaces` |
| **`claude --debug`** | 汎用デバッグログ（**ロード時専用ではない**） | plugin の場合はロード詳細（どの plugin がロードされたか・manifest エラー・skill/agent/hook 登録・MCP 初期化）。加えて `--debug hooks`（hook 評価をツール実行ごとにライブ記録）・`--debug mcp`（MCP サーバの stderr）など**ロード後の実行時イベント**も対象。出力先は **`~/.claude/debug/<session-id>.txt`**（セッション単位のファイル） | `docs/plugins-reference` ほか |
| **`/plugin` の Errors タブ** | ロードエラーの確認 | LSP サーバのパスエラー等 | `docs/plugins-reference` |

> **validate の必須/推奨の別**: 公開審査のある Marketplace（本家 `claude-plugins-official` / コミュニティ）では、レビューパイプラインが提出ごとに `claude plugin validate` と同じ検査＋自動セーフティスクリーニングを回す（`docs/plugins`）ため、ローカルで通しておくことが提出の前提＝**実質必須**。一方 **private な独自 Marketplace（チーム内に閉じる）には審査パイプラインが無いため必須ではない**が、schema・構造・バージョン不整合をローカル/CI で弾けるので**推奨**。
>
> **`--strict` オプション（実機確認）**: `claude plugin validate <path> --strict` は警告をエラー扱いにし（未承認フィールド・メタデータ欠落等で exit 1）、CI に組み込む用途に向く。
>
> **実機で確認した manifest の必須事項（写経で詰まりやすい点）**: `plugin.json` の `author` は**オブジェクト型**必須（`{"name": ...}`。文字列だと `expected object, received string` で失敗）。`marketplace.json` の `owner` は**必須・オブジェクト型**（欠けると `expected object, received undefined` で失敗）。

---

<a id="plugin-dev"></a>

## 6. 純正の plugin 開発支援ツールキット: `plugin-dev`

公式マーケットプレイスリポジトリ `anthropics/claude-plugins-official` に **`plugin-dev`（"Plugin Development Toolkit"）** が同梱されている。manifest（`plugin.json`）の author は **Anthropic**（README の author 表記は Daisy Hollman〔Anthropic〕、README 記載 version 0.1.0。manifest に version フィールドは無い）。**公式 docs にはカタログ掲載レベルの言及はある**——`discover-plugins` ページの "Development workflows" に「**plugin-dev**: Toolkit for creating your own plugins」と1行、`plugins-reference` に名前空間の例 `plugin-dev:agent-creator`。**ただし機能の詳細を解説したページは docs に無く、以下の内容の出所は plugin 同梱の README とコマンド/agent 定義ファイル**（`https://github.com/anthropics/claude-plugins-official/tree/main/plugins/plugin-dev`）である。

**位置づけ**: hooks / MCP 統合 / plugin 構造 / marketplace 公開のベストプラクティスを与える**純正の plugin 開発支援ツールキット**。前回「未裏取り」としたコミュニティ説（"plugin-development"）の実体。

**構成（実ファイルで確認）**: `commands/create-plugin.md`（8 フェーズ workflow 本体）／`agents/`（`agent-creator`・`plugin-validator`・`skill-reviewer` の3本）／`skills/`（7本）。

**7つの専門 skill**（関連する質問をすると自動ロード＝progressive disclosure）: `plugin-structure`（構造・manifest・auto-discovery）／`skill-development`（skill 作成・skill-creator 方法論を適応）／`agent-development`（AI 支援生成）／`hook-development`（全 hook イベント・prompt/command hook）／`mcp-integration`（stdio/SSE/HTTP/WebSocket・認証）／`plugin-settings`（`.claude/<plugin-name>.local.md` での設定保存）／`command-development`（**レガシー `commands/` 形式専用**）。

**ガイド付きワークフローコマンド `/plugin-dev:create-plugin [説明]`** — plugin をゼロから作る **8 フェーズ**の対話型。主要な意思決定点でユーザー確認を待つ（`allowed-tools`: Read/Write/Grep/Glob/Bash/TodoWrite/AskUserQuestion/Skill/Task）:

| # | フェーズ | 要点 |
|---|---|---|
| 1 | Discovery | plugin の目的・対象・課題を確定 |
| 2 | Component Planning | 必要コンポーネントを表で提示し承認（`plugin-structure` をロード） |
| 3 | Detailed Design & 質問 | 各コンポーネント詳細設計（**CRITICAL・省略禁止**） |
| 4 | Structure Creation | 名前・配置場所決定、`plugin.json`/README/`.gitignore`/git init 作成 |
| 5 | Component Implementation | コンポーネント別 skill をロードして実装（`agent-creator` で agent 生成） |
| 6 | Validation & Quality | `plugin-validator`／`skill-reviewer` agent ＋検証スクリプトで検査 |
| 7 | Testing & Verification | **`cc --plugin-dir <path>` で導入**し、skill 発火・`/plugin-name:skill`・agent・hook（`claude --debug`）・MCP（`/mcp`）を確認 |
| 8 | Documentation & Next Steps | README 完成度確認、（公開時）`marketplace.json` エントリ追加、サマリ |

**検証 agent（3本）**: `agent-creator`（identifier・whenToUse 例・systemPrompt を生成）／`plugin-validator`（manifest・構造・命名・コンポーネント・セキュリティを検査）／`skill-reviewer`（description 品質・progressive disclosure・writing style を検査）。
**検証スクリプト（6本）**: `validate-hook-schema.sh` / `test-hook.sh` / `hook-linter.sh` / `validate-settings.sh` / `parse-frontmatter.sh` / `validate-agent.sh`。

**install / 開発**: README は `/plugin install plugin-dev@claude-code-marketplace`、開発時は `cc --plugin-dir /path/to/plugin-dev`。**※ marketplace 名は公式 docs（skill-creator）の `claude-plugins-official` と README の `claude-code-marketplace` で表記差があり、install 時に要確認**（docs のカタログ文脈は `claude-plugins-official`）。

**重要な副次知見（`commands/` のレガシー化）**: `create-plugin` の Phase 2/5 は明示的に「**`commands/` ディレクトリはレガシー形式。新規のユーザー起動スラッシュコマンドは `skills/<name>/SKILL.md` で作るべき**（両者はロード挙動が同一でファイルレイアウトのみ差。`commands/` は既存 plugin 保守時の許容レガシー）」と述べる。v1.2 の「新規は skills 推奨」を純正ツールが裏付ける。

**本書フローへの含意**: plugin-dev は**本書 §1 の開発・テストフローを置換しない**。`create-plugin` の Phase 7 自身が「ローカルテストは `cc --plugin-dir`」「hook は `claude --debug`」「MCP は `/mcp`」と案内しており、`--plugin-dir` / `--debug` / `validate` という本書の中核手段を**前提に、その上に AI 支援のスキャフォールドとベストプラクティス指南・対話的 questioning を載せる accelerator**である。標準フローは §1 のままで、plugin-dev は「より速く・型に沿って・抜け漏れなく作る」任意の上位ツール。

> **`skill-creator` との棲み分け**: `skill-creator` = **skill 単体**の eval・測定（test / measure / refine）。`plugin-dev` = **plugin 全体**の作成支援（hooks / MCP / 構造 / command / agent / skill を横断）。両者は補完関係。

---

<a id="cache-constraints"></a>

## 7. plugin 配布時のパス解決・可変状態・同梱物アクセス（実装制約）

> 本節は §3(2) のキャッシュコピー挙動を **skill 同梱の補助ファイル（references/・templates/・scripts/・README）** へ敷衍し、**「フォルダごと配布可」でも構成要素ごとに cache 先で使えない／書けない／ユーザに見えない制約がある**ことを原文照合で確定する。実 skill の plugin 化テストで顕在化した論点で、[手順書 §6](./Plugin開発・テスト_手順書.md) の根拠。出典はページ名＋セクション主体（行番号は現行 snapshot の参考値・[§出典](#sources) S16〜S20）。

### (1) パス解決 — `${CLAUDE_SKILL_DIR}` / `${CLAUDE_PLUGIN_ROOT}`

- 公式は **3 つのパス変数 `${CLAUDE_PLUGIN_ROOT}` / `${CLAUDE_SKILL_DIR}` / `${CLAUDE_PLUGIN_DATA}`** を提供し、**skill 本文・agent 本文・hook command・monitor command・MCP/LSP config のいずれでもインライン置換**され、さらに **hook プロセス・MCP/LSP サーバ subprocess には環境変数として export** される（`docs/plugins-reference`「path variables」）。
- **skill 同梱ファイル（references/・templates/・scripts/）の参照は `${CLAUDE_SKILL_DIR}` が公式推奨**。SKILL.md のあるディレクトリ（plugin skill では plugin root でなく skill サブディレクトリ）に解決され、**personal / project / plugin のどこに置かれても正しく解決**される。SKILL.md 本文に `python3 ${CLAUDE_SKILL_DIR}/scripts/foo.py` と書けば実行前に絶対パスへ置換される（`docs/skills`「Available string substitutions」／codebase-visualizer 例）。
- **スクリプト内部から env で読めるのは hook / MCP / LSP 起動プロセスに限る**（上記 export 対象）。**skill 手順で Claude が Bash ツール実行**するスクリプトは env 注入が保証されないため、SKILL.md 側の `${CLAUDE_SKILL_DIR}` 置換で絶対パスを引数に渡すか、スクリプトが自身位置（`__file__` 等）から相対解決する。※この env は **子プロセスの OS 環境変数**であり `settings.json` の `env` 要素ではない（`env` は OS 環境変数でも settings.json でも設定可・前者が唯一の採用元ではない）。
- plugin root 外への `../` 参照は cache にコピーされず壊れる（`docs/plugins-reference`「Path traversal limitations」。§3(2) と整合）。

### (2) 書き込み・可変状態 — cache は ephemeral、`${CLAUDE_PLUGIN_DATA}` を使う

- **`${CLAUDE_PLUGIN_ROOT}` 配下（cache）に state を書いてはならない**。更新でパスが変わり、旧バージョン dir は約7日後に削除（orphaned 化し Glob/Grep 対象からも除外）。公式が "treat it as ephemeral … do not write state here" と明記（`docs/plugins-reference`「Plugin caching and file resolution」）。
- 永続させる可変データ（ナレッジ蓄積・生成物・venv/node_modules・キャッシュ）は **`${CLAUDE_PLUGIN_DATA}`（`~/.claude/plugins/data/{id}/`・更新をまたいで残る・初回参照時に自動作成・最終スコープからの uninstall 時に削除〔`--keep-data` で保持〕）**かプロジェクト側に置く。
- 含意: skill が「同梱 references/ に追記してナレッジ蓄積」する設計は cache では成立しない。**同梱 references/ は読み取り専用の初期データ**とし、可変分は分離する。

### (3) 同梱ドキュメント（README・references）のユーザアクセス

- plugin 同梱の `README.md`・references/ は cache にコピーされるが、**`/plugin`・`claude plugin` 系から本文を閲覧する公式 UI は無い**。`claude plugin details` はコンポーネント一覧とトークンコスト表示、Discover タブの詳細ペインも "commands and skills it provides" の一覧で、本文ではなく **homepage URL の参照を案内**する（`docs/discover-plugins`）。README は同梱を推奨されるが（`docs/plugins`）、**閲覧導線は plugin の `homepage`/`repository` フィールド（配布元リポジトリ）**が公式想定。
- 含意: ユーザが読む README は配布元リポジトリ（`homepage`/`repository` で提示）に置く。skill が処理中に使う references/ は Claude がオンデマンドロードするのでユーザ手動アクセスは原則不要。**ユーザが読む／編集するファイルは plugin 同梱（読み取り専用 cache）に不向き**で、プロジェクト側（層1）か `${CLAUDE_PLUGIN_DATA}` へ寄せる。

### (4) `skills/<name>/` 構成要素別の配布挙動

plugin ディレクトリ全体が cache にコピーされるため、`skills/<name>/` 配下のサブフォルダ（references/・templates/・scripts/）や `README.md` はコピーされ実行時に参照可能。ただし構成要素で扱いが異なる:

| 構成要素 | cache コピー | 制約 |
|---|:---:|---|
| `SKILL.md` | ○（ロード） | パスは `${CLAUDE_SKILL_DIR}` で記述 |
| `references/`・`templates/` | ○ | 参照のみ（読み取り）。追記先に使わない（(2)） |
| `scripts/*` | ○ | cwd 非依存で実装、書き込みは `${CLAUDE_PLUGIN_DATA}`／プロジェクト |
| `README.md` | ○ | UI 閲覧不可。ユーザ向けは `homepage`/repo（(3)） |
| plugin root `CLAUDE.md` | ○ | **コンテキスト自動ロードされない**（`docs/plugins-reference`）。指示は skill 化 |

> **v1.2 マトリクスへの含意**: [§マトリクス](../../01.配布・統制方針調査/結論・構成案_ポータブルな.claude共有_v1.2.md) ① の「`skills/` ✅ 層2」は**フォルダが配布される**ことを示すが、**中身が cache 先でそのまま機能する保証ではない**。本節の制約を v1.2 側にも脚注として反映済み。

---

<a id="implications"></a>

## 8. v1.2（層2）との接続・含意

- 本書のフロー（standalone で開発 → 固まったら plugin 化 → ローカル `--plugin-dir` でテスト → validate → Marketplace へ push）は、v1.2 が「層2 へ寄せる」と判断した**機能・拡張資産**の実装・配布ライフサイクルそのものに対応する。v1.2 案B〜B'''（marketplace 型／インライン宣言型／`@skills-dir` 型／seed 焼き込み型）の**どれを選ぶかに依らず、開発・テスト段階は共通してローカル `--plugin-dir` / ローカル marketplace で回す**。
- **最大の制約 = 配布単位はプラグインディレクトリ単位**で、`CLAUDE.md` / `rules/` / `settings.json` 等のリポジトリ統制設定は plugin 配布外、という点は v1.2 マトリクス②の裏付けであり、Marketplace 開発スコープでは前提。これら「Marketplace で配れない資産」の開発・テストは、本タスクの**後続フェーズ（`02.Marketplace外資産編` 想定）**で扱う。
- 後続フェーズの**作業仮説**（本書の知見からの推測・要検証）: 「公開の配布用リポジトリと開発・テストリポジトリは別（後者はローカル）」「テストは `--add-dir` 等で配布用リポと開発・テストリポを結合して実施」という構図は、**skill と subagent については本書で裏付け済み**（`--add-dir` 配下の `.claude/skills/`・`.claude/agents/` は自動ロード）。一方 `CLAUDE.md` / `rules/` / `settings.json`（の大半）は `--add-dir` 単体では結合されず、別経路（環境変数 / `--settings` / clone 後の物理配置）になる（v1.2 案A パターン2・案C）。後続フェーズはこの差を軸に整理する。

---

<a id="sources"></a>

## 出典

根拠は Claude Code 公式ドキュメントのローカル DL 版 `llms-full.txt`（`docs/` 配下を 1 ファイルに連結したもの。実体パスは `CLAUDE.local.md` 参照）。本書は**ページ名＋セクション**を主アンカーとし、行番号は snapshot 依存のため参考値として併記する（v1.2 の出典一覧とは snapshot/行番号が一致しない可能性があるため、ページ名で照合すること）。原文照合は `cc-docs-plugins-marketplace-expert` agent による。

| # | 主張 | ページ | 参考行 |
|---|---|---|---|
| S1 | `--plugin-dir` で marketplace 登録なし直接ロード／`.zip`（v2.1.128+）／複数指定／`--plugin-url` | `docs/plugins` | 27839・27845・27867 |
| S2 | `claude plugin init` → `~/.claude/skills/<name>/` 生成 → `<name>@skills-dir` 自動ロード | `docs/plugins` | 27708 付近 |
| S3 | `claude plugin marketplace add ./local-mp`／ローカル marketplace の事前テスト | `docs/plugin-marketplaces` | 26991 付近・13669 付近 |
| S4 | `/reload-plugins` の反映対象（plugin/skill/agent/hook/MCP/LSP） | `docs/plugins` | 27853 付近 |
| S5 | skill の `SKILL.md` ライブ変更検出と、plugin 同梱時の例外（`/reload-plugins` 要） | `docs/skills` | 32741・32744 |
| S6 | `--plugin-dir` の優先度（インストール済み同名 plugin の上書きテスト・managed は不可） | `docs/plugins` | 27851 付近 |
| S7 | 「standalone `.claude/` で素早く反復、共有準備で plugin 化」 | `docs/plugins` | 27567 付近 |
| S8 | install 時に plugin を `~/.claude/plugins/cache` へコピー／`../` 外部参照不可 | `docs/plugin-marketplaces` / `docs/plugins-reference` | 26557・63470 付近 |
| S9 | `source: "./..."` 相対参照は git 経由のみ（URL-based 不可） | `docs/plugin-marketplaces` | 26710 付近 |
| S10 | skill の配布スコープ（project commit / plugin / managed） | `docs/skills` | 33231 付近 |
| S11 | `skill-creator` プラグイン（eval ループ自動化） | `docs/skills` | 33208 付近 |
| S12 | `--add-dir` 配下の `.claude/skills/` は自動ロード（`additionalDirectories` 設定は対象外） | `docs/skills` | 32771 付近 |
| S13 | `claude plugin validate`（提出前必須・検査内容・レビューパイプライン） | `docs/plugins` / `docs/plugin-marketplaces` | 27914・27423・27425 |
| S14 | `claude --debug` / `/plugin` Errors タブ | `docs/plugins-reference` | 63864・63017 付近 |
| S15 | `plugin-dev` の docs カタログ掲載（"Development workflows"）＋名前空間例 | `docs/discover-plugins`（13524 付近）／`docs/plugins-reference`（13210 付近） | — |
| S16 | パス変数3種（`CLAUDE_PLUGIN_ROOT`/`CLAUDE_SKILL_DIR`/`CLAUDE_PLUGIN_DATA`）は skill/agent 本文・hook/monitor command・MCP/LSP config でインライン置換＋hook/MCP/LSP subprocess へ env export | `docs/plugins-reference`（path variables） | 63695 付近 |
| S17 | `${CLAUDE_SKILL_DIR}` で skill 同梱スクリプト/ファイルを参照（personal/project/plugin で解決） | `docs/skills`（Available string substitutions / codebase-visualizer 例） | 32800・33163・33181 付近 |
| S18 | cache は ephemeral・"do not write state here"・旧版は約7日後に削除・Glob/Grep 除外／`../` 外部参照不可 | `docs/plugins-reference`（Plugin caching and file resolution / Path traversal limitations） | 63695-63697・63776・63778・63784 付近 |
| S19 | `${CLAUDE_PLUGIN_DATA}` = `~/.claude/plugins/data/{id}/`・更新をまたいで永続・初回参照で自動作成・最終スコープ uninstall で削除（`--keep-data` で保持） | `docs/plugins-reference`（persistent data directory） | 63701・63724 付近 |
| S20 | README 同梱は推奨だが UI 閲覧導線なし→`homepage`/Discover で案内／`claude plugin details` はコンポーネント一覧表示／plugin root の `CLAUDE.md` は非ロード | `docs/plugins`・`docs/discover-plugins`・`docs/plugins-reference` | 27807・13706・64098・63855 付近 |

> **`plugin-dev` の機能詳細の出所**: 上記 S15 は docs 側の「言及」のみ。7 skill・`/plugin-dev:create-plugin` の 8 フェーズ・3 agent・6 検証スクリプトといった機能詳細は docs に無く、根拠は plugin 同梱の `README.md` および `commands/create-plugin.md` / `agents/*.md` / `.claude-plugin/plugin.json`（`anthropics/claude-plugins-official` の `plugins/plugin-dev/`、GitHub MCP で取得・精読）。

> **`plugin-dev` の裏取り（完了）**: web discovery 段階で観測したコミュニティ説 "plugin-development" は、**公式リポジトリの純正プラグイン `plugin-dev` が実体**であることを README 精読で確定した（[§6](#plugin-dev)）。ただしコミュニティ説の具体（`/plugin-development:init` / `:validate` でスラッシュコマンド／dev marketplace 生成）は**不正確**で、実際の主コマンドは **`/plugin-dev:create-plugin`（8 フェーズのガイド付き作成ワークフロー）**であり、専用の "dev marketplace" を生成する機能は README に記載が無い（テストは `--plugin-dir` / `claude --debug`）。公式 docs には `discover-plugins` の1行カタログ掲載と `plugins-reference` の名前空間例としての言及はあるが、**機能の詳細解説は無く、知見の出所は plugin-dev の README** である点に留意。

## 変更履歴

- **v1.2（2026-06-29）**: 横断整合性レビュー反映。§4 表の subagents×`--add-dir` を **「✅（v2.1.178+。v2.1.165 までは非ロード）」** と版境界付きに統一（v1.2 報告書 errata [75]・Marketplace外資産編 C9 と整合）。従来は本編のみ無条件 ✅ で版境界が欠落し、版を跨ぐ読者に「常時ロード」と誤読される恐れがあった。
- **v1.1（2026-06-25）**: §7「plugin 配布時のパス解決・可変状態・同梱物アクセス（実装制約）」を新設（実 skill の plugin 化テストで顕在化）。`${CLAUDE_SKILL_DIR}`／`${CLAUDE_PLUGIN_ROOT}` の置換範囲と env export、cache の ephemeral 性（書込禁止・約7日 orphan）と `${CLAUDE_PLUGIN_DATA}` への可変状態退避、README/references のユーザアクセス制約（UI 非閲覧→`homepage`）、`skills/<name>/` 構成要素別挙動を原文照合で確定。§出典に S16〜S20 を追加。[手順書 v1.1 §6](./Plugin開発・テスト_手順書.md) の根拠。旧§7「v1.2との接続・含意」は §8 へ繰り下げ。原文照合は `cc-docs-plugins-marketplace-expert` agent。
- **v1.0（2026-06-21）**: 初版。公式 docs（plugins / plugin-marketplaces / plugins-reference / skills）の原文照合に基づき、層2 配布物の開発・テストフロー・手段・制約・検証を整理。レビュー指摘反映として `--debug` の実行時カバー範囲、`validate` の必須/推奨条件、`skill-creator` の機能詳細・公開 URL を補強。純正 `plugin-dev` を README＋`create-plugin.md`／agent 定義／manifest の精読で裏取りし [§6](#plugin-dev) を追加（8 フェーズ詳細・3 agent・6 スクリプト・`commands/` レガシー指針・docs カタログ掲載の確認を含む）。**Sonnet 動作検証（実機 `claude plugin validate` v2.1.185）の反映**: `plugin.json` の `author` ＝オブジェクト型・`marketplace.json` の `owner` ＝必須、`--add-dir` は skills だけでなく **subagents（`.claude/agents/`）も自動ロード**（§4 訂正）、`--debug` 出力先 `~/.claude/debug/<session-id>.txt`、`validate --strict`。
