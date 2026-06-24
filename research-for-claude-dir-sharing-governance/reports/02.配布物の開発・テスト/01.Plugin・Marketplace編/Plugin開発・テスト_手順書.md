# Plugin 開発・テスト手順書（v1.0）

> - **目的**: Claude Code で Marketplace 配布する plugin / skill を開発・テストする際の **全体フロー・起動オプション・コマンド例**を、手を動かす順に把握できる実務手順書。
> - **位置づけ**: [調査結果報告書](./Plugin・Marketplace配布物の開発・テスト_調査結果.md) の派生（実務オペレーション版）。**根拠・出典・制約の理由は報告書側**にあり、本書は手順に絞る（二重管理を避ける）。
> - **前提環境**: Claude Code CLI（`--plugin-dir` の `.zip` 対応は v2.1.128 以降）。コマンドは PowerShell / bash いずれでも同形。
> - **作成日**: 2026-06-21

---

## 0. 全体フロー（地図）

### 登場するローカルリポジトリ（手元に置くもの）

| 記号 | リポジトリ | 役割 |
|---|---|---|
| **(A)** | **開発・テストリポジトリ** | plugin の中身を作り込み、ローカルでテストする場所（standalone `.claude/` → plugin 化）。**②の plugin 化はここで行う** |
| **(B)** | **配布専用リポジトリ（Marketplace）のローカルクローン** | 公開先。完成品を `git push` で受け取るだけで、**ここでは開発しない** |
| **(C)** | **ローカル marketplace（任意・"見なし公開"）** | 配布形態（install 挙動）を手元で検証するための `marketplace.json` 入りディレクトリ。(A) を兼ねてもよいし、検証用に別ディレクトリを作ってもよい |

> **(A) と (B) の関係はリポジトリ構成で変わる**:
> - **monorepo** … 1 リポジトリが開発・テストも配布も兼ねる。**(A) = (B)**（同一リポのローカル作業コピーと remote の関係）。ローカルではそれを `--plugin-dir` / `marketplace add .` でテストし、`git push` で公開。
> - **multi-repo** … plugin 開発リポ (A)（複数可）と、薄い marketplace リポ (B)（external source で各 plugin を参照）を分離。開発・テストは各 (A) でローカルに行い、(B) は参照を束ねるだけ。

### フロー

```
[(A) 開発・テストリポジトリ]
  ① standalone .claude/ で試作＋動作検証
        │  （plugin 化前の試行錯誤。skills/ commands/ agents/ hooks/ を直接置き、
        │    編集→即時反映で「共有できるレベル」まで動作確認する段）
        ▼
  ② plugin 化（.claude-plugin/plugin.json を付与）   ← (A) の中で行う
        │
        ▼
  ③ ローカルでテスト
        │   主:  claude --plugin-dir ./my-plugin            （marketplace 不要）
        │   副:  (C) を用意し claude plugin marketplace add ./my-mp → /plugin install
        │        （配布形態＝install 挙動の検証）
        │   反映: /reload-plugins（skill は SKILL.md 即時）
        ▼
  ④ claude plugin validate .
        │   ← 公開審査のある Marketplace（本家/コミュニティ）では必須
        │     private な独自 Marketplace では審査が無いので必須ではない（推奨）
        │
        ▼ git push
[(B) 配布専用リポジトリ＝Marketplace]
  ⑤ marketplace.json を公開
        利用者: /plugin marketplace add <repo>
                /plugin install <name>@<mp>
```

**原則**: 開発・テストは**ローカル (A) で完結**させる。Marketplace (B) は配布の器であり、開発の場ではない。よって**「開発・テストリポジトリ」と「配布専用リポジトリ」は役割で分ける**（monorepo では同一リポの作業コピー／remote、multi-repo では別リポ）。

---

## 1. ステップ別手順

### ① standalone `.claude/` で試作＋動作検証

> ここでの **「standalone」は「plugin にしていない素の構成」という状態の呼称**（公式語 "standalone configuration in `.claude/`"）。`.claude/` は**任意のローカル開発リポジトリ (A) の直下**に置くフォルダを指す。

plugin 化する前に、まず通常の `.claude/` 配下に資産を置いて動かし、素早く試行錯誤する。**この段の「試行錯誤」には、plugin 化前の動作検証（編集→実行→確認の反復で「共有・配布できるレベル」に仕上げるテスト）が含まれる**。skill であれば後述の `skill-creator` で eval を回すのもこの段。

```
my-tool/                     # 手元の開発リポジトリ（=作業ディレクトリ）
└── .claude/
    ├── skills/hello/SKILL.md
    ├── commands/foo.md
    └── agents/bar.md
```

この段階では `claude` を `my-tool/` で起動すれば資産はそのまま有効。skill は `SKILL.md` を編集すると**セッション内で即時反映**される。

### ② plugin 化

共有・配布する段になったら、plugin のマニフェストを付与して plugin ディレクトリ化する。**この作業は開発・テストリポジトリ (A) の中で行う**（配布専用リポのクローン (B) で開発しない。(B) は完成品を push で受け取るだけ）。

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json          # name / version / description / author などのメタdata
├── skills/my-skill/
│   ├── SKILL.md             # ユーザー起動コマンドも新規はここ（skills/）に作る
│   ├── README.md            # 利用者向け説明（※cache 内は UI から閲覧不可 → §6.3）
│   ├── references/          # skill が処理中に参照するナレッジ（読み取り専用前提 → §6.2）
│   ├── templates/           # skill が生成する成果物のひな型
│   └── scripts/*.py         # skill が呼ぶスクリプト（パスは ${CLAUDE_SKILL_DIR} 解決 → §6.1）
├── agents/bar.md
└── hooks/hooks.json         # 必要なら（スクリプト本体は ${CLAUDE_PLUGIN_ROOT} 参照で同梱）
```

`plugin.json` の最小例（**`author` はオブジェクト型**で書く点に注意。文字列だと `claude plugin validate` が `expected object, received string` で失敗する）:

```json
{
  "name": "my-plugin",
  "version": "0.1.0",
  "description": "...",
  "author": { "name": "チーム名" }
}
```

> ⚠️ **plugin ディレクトリの外を参照しない**こと。install 時に plugin ディレクトリだけがキャッシュへコピーされるため、`../shared/...` のような外部参照は配布後に壊れる。共有したいファイルは plugin 内に収める。
>
> 📌 **`commands/` はレガシー形式**: 公式の `plugin-dev` は「新規のユーザー起動スラッシュコマンドは `commands/*.md` ではなく `skills/<name>/SKILL.md` で作る」ことを推奨する（両者はロード挙動が同一で、差はファイルレイアウトのみ。`commands/` は既存 plugin 保守時の許容レガシー）。新規 plugin では `skills/` に寄せる。

> 🧩 **配布前提のスクリプト・同梱ファイル（references/ templates/ scripts/ README）には実装規約がある**: plugin 化すると実行場所が `<repo>\.claude` でなく cache（`~/.claude/plugins/cache/…`）になり、パス解決・書き込み先・README 提示に制約がつく（cwd 依存の相対パスは壊れる）。**新規に skill＋スクリプトを作る前に §6 を必読**。

skill 単体を scaffold したい場合は次が速い:

```bash
claude plugin init my-tool
# → ~/.claude/skills/my-tool/ に plugin.json + starter SKILL.md を生成
#   次セッションで my-tool@skills-dir として自動ロード（install 不要）
```

### ③ ローカルでテスト

#### 主: `--plugin-dir`（marketplace 登録なしで直接ロード）

```bash
# 単体
claude --plugin-dir ./my-plugin

# 複数同時
claude --plugin-dir ./plugin-one --plugin-dir ./plugin-two

# .zip アーカイブ（v2.1.128+）
claude --plugin-dir ./my-plugin.zip

# CI ビルド成果物などの URL から
claude --plugin-url https://example.com/builds/my-plugin.zip
```

- インストール済みの同名 plugin があっても、**`--plugin-dir` のローカルコピーがそのセッションで優先**される（アンインストール不要で変更をテストできる）。
- 起動後、`/plugin-name:skill-name` や `/agents` で動作確認する。

#### 副: ローカル marketplace（配布形態ごと検証）

配布したときの install 挙動まで確認したい場合は、ローカルディレクトリを marketplace 化する。

```
my-mp/                       # ローカル marketplace
├── .claude-plugin/
│   └── marketplace.json     # name + owner(必須) + plugins
└── plugins/
    └── my-plugin/ …
```

`marketplace.json` の最小例（**`owner` は必須・オブジェクト型**。欠けると `claude plugin validate` が `owner: expected object, received undefined` で失敗する）:

```json
{
  "name": "my-mp",
  "owner": { "name": "チーム名" },
  "plugins": [{ "name": "my-plugin", "source": "./plugins/my-plugin" }]
}
```

```bash
# CLI から
claude plugin marketplace add ./my-mp
claude plugin install my-plugin@my-mp

# もしくはセッション内コマンド
/plugin marketplace add ./my-mp
/plugin install my-plugin@my-mp
```

> `source: "./..."` の相対参照は **git 経由配布でのみ**機能する（URL-based marketplace では不可）。ローカルテストでは効くが、公開時の source 種別に注意。

#### 反映（編集 → 確認のループ）

| 変更した対象 | 反映方法 |
|---|---|
| skill の `SKILL.md` | **即時**（操作不要） |
| plugin の hooks / `.mcp.json` / agents / output-styles | `/reload-plugins` |
| plugin / skill / agent / hook / MCP / LSP 全般 | `/reload-plugins`（再起動不要で全再読込） |

### ④ 公開前バリデーション

```bash
# plugin 単体を検証（plugin.json + skill/agent/command/hook の frontmatter・hooks.json 構文）
claude plugin validate ./my-plugin

# marketplace を検証（marketplace.json の schema・重複名・source パストラバーサル・バージョン不整合）
claude plugin validate ./my-mp

# CI 用: 警告もエラー扱い（未承認フィールド・メタデータ欠落等で exit 1）
claude plugin validate ./my-plugin --strict
```

- **公開審査のある Marketplace（本家 `claude-plugins-official` / コミュニティ）へ提出する場合は必須**。レビューパイプラインが提出ごとに同じ検査＋自動セーフティスクリーニングを回すため、ローカルで通しておくのが提出の前提。
- **private な独自 Marketplace（チーム内に閉じる）では審査パイプラインが無いので必須ではない**。ただし schema・構造・バージョン不整合をローカルで弾けるので**実行を推奨**（CI に組み込むと安全）。
- ロードがうまくいかない時のデバッグ:

```bash
claude --debug            # デバッグログ（ファイル出力）。plugin のロード詳細・manifest エラーに加え、
                          # ロード後の実行時イベントも対象（後述の早見表参照）。
                          # 出力先は ~/.claude/debug/<session-id>.txt（セッション単位のファイル）
claude --debug mcp        # MCP サーバの stderr を確認したい時
claude --debug hooks      # hook の評価をツール実行ごとにライブ記録したい時
# /plugin の Errors タブでも LSP パスエラー等を確認できる
```

### ⑤ 配布専用リポジトリ（Marketplace）へ公開

検証を通したら、配布専用リポジトリへ push する。利用者側:

```bash
/plugin marketplace add <github-repo-or-git-url>
/plugin install <name>@<marketplace>
```

---

## 2. 起動オプション・コマンド早見表

### 起動オプション（CLI フラグ）

| フラグ | 用途 |
|---|---|
| `--plugin-dir <path>` | plugin を marketplace 登録なしで直接ロード（**開発の主手段**）。`.zip` 可・反復指定で複数 |
| `--plugin-url <url>` | URL（CI 成果物等）から plugin をロード |
| `--add-dir <dir>` | 追加ディレクトリのファイルアクセスを付与。**`<dir>/.claude/skills/` は自動ロードされる**（skill テストの結合に有用） |
| `--debug` | **汎用デバッグログ（`~/.claude/debug/<session-id>.txt` にセッション単位で出力）**。plugin の場合はロード詳細・manifest エラーを見られるが、**ロード時専用ではない**——`--debug hooks`（hook 評価をツール実行ごとにライブ記録）・`--debug mcp`（MCP サーバの stderr）のように**ロード後の実行時イベントも対象**。サブチャネル（`hooks`/`mcp`）で対象を絞れる（旧 `--mcp-debug` は非推奨・`--debug mcp` を使う） |

> `--add-dir` で渡すのは「`.claude/` を内包する親フォルダ」。フォルダ名自体を `.claude` にすると `<dir>/.claude/.claude/` を探して読まれないので注意。
> **`--add-dir`（フラグ／`/add-dir`）で `<dir>/.claude/` から自動ロードされる設定**（公式 `docs/permissions` の表）: **skills（`.claude/skills/`・live reload）と subagents（`.claude/agents/`）**、および `settings.json` のうち **`enabledPlugins` / `extraKnownMarketplaces` のみ**。`CLAUDE.md` / `rules` / `CLAUDE.local.md` は環境変数 `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` を付けた時だけ読まれる。`settings.json` のそれ以外のキー（permissions/hooks 等）・commands・output-styles は読まれない。
> ⚠️ `permissions.additionalDirectories` 設定経由ではこれら例外は**一切**読まれず、ファイルアクセス付与のみ（自動ロードは `--add-dir` フラグ／`/add-dir` 限定）。

### セッション内 / CLI コマンド対応

| 操作 | セッション内 | CLI |
|---|---|---|
| marketplace 追加 | `/plugin marketplace add <source>` | `claude plugin marketplace add <source>` |
| marketplace 一覧 | `/plugin marketplace list` | `claude plugin marketplace list` |
| plugin インストール | `/plugin install <name>@<mp>` | `claude plugin install <name>@<mp>` |
| バリデーション | `/plugin validate <path>` | `claude plugin validate <path>` |
| 変更の再読込 | `/reload-plugins` | —（セッション内専用） |
| skill の雛形生成（scaffold） | — | `claude plugin init <name>` |

> **「scaffold（スキャフォールド）」= 雛形生成**。`claude plugin init <name>` は `~/.claude/skills/<name>/` に `.claude-plugin/plugin.json` と starter `SKILL.md`（土台一式）を自動生成し、次セッションで `<name>@skills-dir` として自動ロードする。ゼロからファイルを手書きせず、編集すればよい状態の雛形を作る操作。
>
> **`claude plugin validate` が具体的にチェックする内容**（出典は[調査結果報告書 §5](./Plugin・Marketplace配布物の開発・テスト_調査結果.md)）:
> - **marketplace ディレクトリ対象**: `marketplace.json` の schema、plugin 名の重複、`source` のパストラバーサル、各 `plugin.json` とのバージョン不整合
> - **plugin ディレクトリ対象**: skill / agent / command の YAML frontmatter、`hooks/hooks.json` の JSON 構文

---

## 3. skill 単体を開発・テストする場合（plugin に包まない）

> **位置づけ**: 本セクションは2つの面を持つ。(1) plugin 化せず `.claude/skills/` 単体で skill を作り込む作業は、**全体フロー①「standalone での試作＋動作検証」に相当**する（ここで skill を仕上げ、plugin に同梱するなら②以降へ進む）。(2) 同時に、skill 単体は **plugin 化せず層1 commit でそのまま配る独立ルート**でもあり、その場合は②以降（plugin 化・Marketplace）に進まない。

plugin 化せず `.claude/skills/` 単体で配る skill は、開発がさらに軽い。

- **配置**: project `.claude/skills/` ／ `~/.claude/skills/` ／ `--add-dir` 配下の `.claude/skills/` のいずれかに置けば自動ロード。
- **反映**: `SKILL.md` の編集は**即時**（`/reload-plugins` 不要）。
- **呼び出し**: `/skill-name`（plugin 同梱だと `/plugin-name:skill-name` と名前空間が付く）。
- **動作確認の考え方**: skill が「発火した」ことと「意図どおり動いた」ことは別。**skill 有り／無効化の 2 セッションで同じ現実的プロンプトを流して baseline 比較**するのが公式の検証法。

### 支援ツール: `skill-creator` プラグイン（純正）

skill の eval ループを Claude Code 内で自動化する純正プラグイン。

```bash
/plugin install skill-creator@claude-plugins-official
/reload-plugins
# 例: 「evaluate my summarize-changes skill with skill-creator」と依頼すると eval ループが走る
```

公式 docs（`docs/skills`）が挙げる具体機能:

| 機能 | 内容 | 生成物 |
|---|---|---|
| Test cases | プロンプト・入力ファイル・期待挙動を蓄積 | skill ディレクトリ内 `evals/evals.json` |
| Isolated runs | テストケースごとに subagent を spawn（クリーンな context で実行）、token 数・所要時間を記録 | — |
| Grading | 各アサーションを出力と照合し pass/fail を根拠付きで記録 | `grading.json` |
| Benchmark | skill 有り／無しの pass 率・時間・token を集計（改善幅とオーバーヘッドを比較） | `benchmark.json` |
| Version comparison | 2 バージョンを blind A/B し、編集が改善かをコミット前に確認 | — |
| Description tuning | should-trigger / should-not-trigger プロンプトを生成し発火率を測定、description 修正案を提示 | — |
| Review viewer | 各出力を確認し定性フィードバックを記録する HTML レポート | — |

**公開リソース（いずれも英語。日本語版は確認できず）**:
- プラグイン本体（公式リポ）: `https://github.com/anthropics/claude-plugins-official/tree/main/plugins/skill-creator`
- README: `https://github.com/anthropics/claude-plugins-official/blob/main/plugins/skill-creator/README.md`
- eval ファイル形式・反復ワークフロー: `https://agentskills.io/skill-creation/evaluating-skills`
- ベンチ／比較モードの背景（公式ブログ）: `https://claude.com/blog/improving-skill-creator-test-measure-and-refine-agent-skills`

> skill 単体は hooks / MCP を同梱できない。これらが必要なら plugin 化する。

---

## 4. （推奨・任意）純正ツールキット `plugin-dev` で開発を加速

純正の **`plugin-dev`（"Plugin Development Toolkit"・author=Anthropic・README 記載 v0.1.0）** は、本手順書 §0〜§3 のフローを **AI 支援＋ベストプラクティス指南つき**で進める公式ツールキット。**本手順書のフローを置換するものではなく、その上に乗る accelerator**——`plugin-dev` 自身が最終フェーズで「テストは `cc --plugin-dir` / `claude --debug` / `/mcp` で」と案内しており、§2〜§3 の中核手段を**公式が裏打ち**している。

```bash
# 利用（marketplace から）
/plugin install plugin-dev@claude-plugins-official
# ※ README 上の表記は plugin-dev@claude-code-marketplace。marketplace エイリアスに表記差があるため
#   install 時に実際の marketplace 名を確認する（公式 docs カタログ文脈では claude-plugins-official）
/reload-plugins

# 開発時に直接ロード（plugin-dev 自体を試す/改変する場合）
cc --plugin-dir /path/to/plugin-dev
```

### 4.1 ガイド付き作成コマンド `/plugin-dev:create-plugin [説明]`

ゼロから plugin を作る **8 フェーズ**のワークフロー。各フェーズで確認質問を行い、必要な skill を自動ロードし、専用 agent と検証スクリプトを使う。**主要な意思決定点でユーザーの確認を待って進む**対話型。

| # | フェーズ | 何をするか | 自動ロード skill / agent |
|---|---|---|---|
| 1 | Discovery | plugin の目的・対象ユーザー・解く課題を確定（曖昧なら質問） | — |
| 2 | Component Planning | 必要コンポーネント（skills/agents/hooks/MCP/settings）を決め、表で提示し承認を得る | `plugin-structure` |
| 3 | Detailed Design & 質問 | 各コンポーネントを詳細設計し曖昧点を解消（**CRITICAL・省略禁止**） | — |
| 4 | Structure Creation | 名前（kebab-case）・配置場所を決め、ディレクトリ・`plugin.json`・README・`.gitignore`・git init を作成 | — |
| 5 | Component Implementation | 各コンポーネントをベストプラクティスで実装 | `skill-development` / `agent-development` / `hook-development` / `mcp-integration` / `plugin-settings`（必要分）＋ `agent-creator` |
| 6 | Validation & Quality | `plugin-validator` agent で manifest/構造/命名/コンポーネント/セキュリティを検査、`skill-reviewer` で skill 検査、検証スクリプト実行 | `plugin-validator` / `skill-reviewer` |
| 7 | Testing & Verification | `cc --plugin-dir <path>` で導入し、skill 発火・`/plugin-name:skill` 実行・agent 発火・hook（`claude --debug`）・MCP（`/mcp`）を確認 | — |
| 8 | Documentation & Next Steps | README 完成度確認、（公開時）`marketplace.json` エントリ追加、サマリ作成 | — |

> このコマンドの `allowed-tools` は Read / Write / Grep / Glob / Bash / TodoWrite / AskUserQuestion / Skill / Task。

### 4.2 提供される skill（7本・質問に応じて自動ロード）

| skill | 役割 |
|---|---|
| `plugin-structure` | plugin ディレクトリ構造・`plugin.json` manifest・auto-discovery |
| `skill-development` | skill 作成（progressive disclosure・強いトリガー記述）。`skill-creator` 方法論を plugin 向けに適応 |
| `agent-development` | subagent 作成（YAML frontmatter＋system prompt・AI 支援生成） |
| `hook-development` | 全 hook イベント・prompt/command hook・`${CLAUDE_PLUGIN_ROOT}` |
| `mcp-integration` | MCP サーバ統合（stdio/SSE/HTTP/WebSocket・認証） |
| `plugin-settings` | `.claude/<plugin-name>.local.md` でのプロジェクト別設定保存 |
| `command-development` | スラッシュコマンド作成（**レガシー `commands/` 形式専用**。新規は `skill-development` を使う） |

### 4.3 検証 agent（3本）と検証スクリプト（6本）

- **agent（3本）**: `agent-creator`（AI 支援で agent を生成＝identifier・whenToUse 例・systemPrompt）／`plugin-validator`（plugin 全体の検査）／`skill-reviewer`（skill の記述品質・progressive disclosure 検査）。
- **検証スクリプト（6本）**: `validate-hook-schema.sh` / `test-hook.sh` / `hook-linter.sh` / `validate-settings.sh` / `parse-frontmatter.sh` / `validate-agent.sh`。

### 4.4 使いどころ・棲み分け

- **使いどころ**: 「型に沿って・抜け漏れなく・対話で確認しながら」plugin を新規作成したい時。手で §1〜§3 を回すより、設計の questioning と検証の自動化が効く。
- **棲み分け**: `skill-creator` = **skill 単体**の eval・測定（test/measure/refine）／`plugin-dev` = **plugin 全体**の作成支援。詳細は[調査結果報告書 §6](./Plugin・Marketplace配布物の開発・テスト_調査結果.md)。

---

## 5. 公開前チェックリスト

- [ ] plugin ディレクトリ外への参照（`../...`）が無い（キャッシュコピーで壊れる）
- [ ] `plugin.json` の `author` がオブジェクト型／marketplace 配布なら `marketplace.json` に `owner`（オブジェクト・必須）がある
- [ ] `claude plugin validate ./my-plugin` がパスする（CI では `--strict` も）
- [ ] marketplace 配布なら `claude plugin validate ./my-mp` もパスする（schema・重複名・source・バージョン整合）
- [ ] `--plugin-dir` で起動し、skill / command / agent / hook が期待どおり動く
- [ ] 配布形態（ローカル marketplace install → uninstall → reinstall）で挙動を確認した
- [ ] `source` の種別（git / URL）と相対パス参照の整合を確認した
- [ ] `--debug` でロードエラーが出ていない
- [ ] スクリプト/SKILL.md のパス参照が `${CLAUDE_SKILL_DIR}` / `${CLAUDE_PLUGIN_ROOT}` 解決（cwd 依存・絶対パス・`../` 不使用）（§6.1）
- [ ] 書き込み・蓄積先が `${CLAUDE_PLUGIN_DATA}` かプロジェクト側（cache=`${CLAUDE_PLUGIN_ROOT}` 配下に書いていない）（§6.2）
- [ ] ユーザが読む README は `homepage`/repo で参照可能（cache 内 README に依存しない）（§6.3）
- [ ] plugin root の `CLAUDE.md` に依存していない（自動ロードされない）（§6.4）

---

## 6. plugin 配布前提のスクリプト・同梱ファイル実装規約（重要）

> **なぜ重要か**: skills/ のように「フォルダごと配布可」とされる資産でも、**plugin 化して Marketplace 配布すると実行場所が `<repo>\.claude` ではなく cache（`~/.claude/plugins/cache/<mp>/<plugin>/<version>/`）になる**。`*.md` のようにパスがファイル固定の資産と違い、フォルダ配布資産は**構成要素ごとに「配布されても cache 先で使えない／書けない／ユーザに見えない」制約**を持つ。standalone（層1 直置き）では cwd＝`<repo>` 前提の相対パスが偶然動くが、plugin 化で必ず壊れる。配布前提のスクリプト・同梱ファイルは最初からこの規約で作る。（出典: 公式 plugins-reference / skills。根拠詳細は調査結果報告書へ別途追補）

### 6.1 パス解決（読み取り）— cwd 非依存で書く

- **skill 同梱ファイル（references/・templates/・scripts/）の参照は `${CLAUDE_SKILL_DIR}` を使う**。SKILL.md のあるディレクトリ（plugin の場合は plugin root でなく skill サブディレクトリ）に解決され、**personal / project / plugin のどこに置かれても正しく解決される**公式推奨変数。SKILL.md 本文に `python3 ${CLAUDE_SKILL_DIR}/scripts/foo.py` と書けば**実行前に絶対パスへインライン置換**される。
- **plugin root 相対（複数 skill 横断・hook・MCP/LSP）の参照は `${CLAUDE_PLUGIN_ROOT}`**。`${CLAUDE_PLUGIN_ROOT}` / `${CLAUDE_SKILL_DIR}` / `${CLAUDE_PLUGIN_DATA}` は **skill 本文・agent 本文・hook command・monitor command・MCP/LSP config のいずれでもインライン置換**される。
- **スクリプト内部から env 変数で読めるか**は起動経路で異なる（**ここでの env は「起動された子プロセスの OS 環境変数」であり、settings.json の `env` 要素ではない**。これらの変数は Claude Code が実行時に注入する）:
  - **hook / MCP / LSP から起動**されたプロセス → `CLAUDE_PLUGIN_ROOT` 等が環境変数として export され `os.environ` / `process.env` で読める。
  - **skill の手順で Claude が Bash ツール実行**するスクリプト → env 注入は保証されない。**SKILL.md 側で `${CLAUDE_SKILL_DIR}` を置換させ引数で絶対パスを渡す**か、スクリプトが**自身位置から相対解決**（Python `Path(__file__).resolve().parent`／bash `cd "$(dirname "${BASH_SOURCE[0]}")" && pwd`）する。
- **禁止**: cwd 依存の相対パス（`./scripts/...`）／ハードコード絶対パス／plugin root 外への `../` 参照（cache にコピーされず壊れる）。

### 6.2 書き込み・蓄積先 — cache に書かない

- **`${CLAUDE_PLUGIN_ROOT}` 配下（cache）へ state を書いてはならない**。更新のたびにパスが変わり、旧バージョン dir は**約7日後に削除**（orphaned 化し Glob/Grep 対象からも除外）。公式も "treat it as ephemeral … do not write state here" と明記。
- **永続させる書き込み（ナレッジ蓄積・生成物・venv/node_modules・キャッシュ）は `${CLAUDE_PLUGIN_DATA}`**（`~/.claude/plugins/data/{id}/`・**更新をまたいで残る**・初回参照時に自動作成・最終スコープからの uninstall 時に削除〔`--keep-data` で保持〕）かプロジェクト側に置く。
- 「references/ のファイルに追記してナレッジ蓄積」は cache 配下では不可。**同梱 references/ は読み取り専用の初期データ**として扱い、可変分は `${CLAUDE_PLUGIN_DATA}`／プロジェクトへ分離する。

### 6.3 README・references のユーザアクセス — cache 内ファイルに依存しない

- plugin 同梱の `README.md`・references/ は cache にコピーされるが、**`/plugin`・`claude plugin` 系から内容を閲覧する公式 UI は無い**（`claude plugin details`／Discover タブはコンポーネント一覧とトークンコスト表示で、本文表示ではない）。普段開かない cache パスを辿らせる運用は非現実的。
- **対応案**:
  1. **ユーザが読む README は配布元リポジトリに置き、`plugin.json` / `marketplace.json` の `homepage` / `repository` で URL を提示**する（公式想定経路・GitHub 上で閲覧）。← 推奨
  2. **skill が処理中に参照する references/ は、ユーザの手動アクセス前提にしない**。SKILL.md から参照され Claude がオンデマンドにロードする。
  3. **ユーザが読む／編集するファイル**は plugin 同梱（読み取り専用 cache）に不向き。プロジェクト側（層1）か `${CLAUDE_PLUGIN_DATA}` に置く設計へ寄せる。

### 6.4 フォルダ配布資産（skills/<name>/）の構成要素別チェック

| 構成要素 | cache へコピー | plugin 配布時の制約・実装規約 |
|---|:---:|---|
| `SKILL.md` | ○（ロード） | 本文のパスは `${CLAUDE_SKILL_DIR}` で書く（§6.1） |
| `references/`（読み取り） | ○ | 参照は `${CLAUDE_SKILL_DIR}` 経由。**追記先に使わない**（§6.2） |
| `templates/` | ○ | 読み取りは同上。生成物の出力先は cache でなくプロジェクト／PLUGIN_DATA |
| `scripts/*.py` 等 | ○ | cwd 非依存で実装（§6.1）、書き込みは §6.2 |
| `README.md` | ○ | **UI 閲覧不可**。ユーザ向けは `homepage`/repo で提示（§6.3） |
| plugin root `CLAUDE.md` | ○ | **コンテキストに自動ロードされない**。指示を載せるなら skill 化 |

> **要点**: 「skills/ は層2 配布可（v1.2 マトリクス §核心 ①）」は**フォルダが配布される**ことを意味するが、**中身が cache 先でそのまま機能する保証ではない**。配布前提の skill は本 §6 の規約で実装する。

---

## 変更履歴

- **v1.1（2026-06-25）**: §6「plugin 配布前提のスクリプト・同梱ファイル実装規約」を新設（実 skill の plugin 化テストで判明したパス解決・書き込み先・README アクセスの制約を反映）。パス解決は `${CLAUDE_SKILL_DIR}`／`${CLAUDE_PLUGIN_ROOT}` のインライン置換と起動経路別の env 注入、書き込みは cache 禁止・`${CLAUDE_PLUGIN_DATA}` 利用、README は UI 非閲覧で `homepage` 提示を明記。§②のディレクトリ例を references/templates/scripts/README 付きの実構成へ拡張し §6 への必読ポインタを追加、§5 チェックリストに 4 項目追加。（出典の行番号付き根拠は調査結果報告書へ別途追補予定）
- **v1.0（2026-06-21）**: 初版。[調査結果報告書 v1.0](./Plugin・Marketplace配布物の開発・テスト_調査結果.md) を実務手順に落とし込み。レビュー反映として全体フロー図のローカルリポ明示（A/B/C）、standalone の語義・①の動作検証・②の実施リポ・④ validate の必須/推奨条件・`--debug` の実行時範囲・scaffold の語義・`skill-creator` の機能/URL を補強。`commands/` レガシー指針（§1②）を追記し、純正 `plugin-dev` の節（§4）を `create-plugin` 8 フェーズ表・7 skill・3 agent・6 検証スクリプトまで踏まえて拡充。**Sonnet 動作検証（実機 `claude plugin validate` v2.1.185）反映**: `plugin.json` の `author`＝オブジェクト・`marketplace.json` の `owner`＝必須の最小例追加、`--add-dir` 注記を skills＋subagents に訂正、`--debug` 出力先 `~/.claude/debug/<session-id>.txt` 明記、`validate --strict` 追加。
