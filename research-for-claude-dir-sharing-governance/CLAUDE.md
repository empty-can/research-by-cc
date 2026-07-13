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
| 層2 配布物の開発・テスト 調査結果 | `reports/02.配布物の開発・テスト/01.Plugin・Marketplace編/Plugin・Marketplace配布物の開発・テスト_調査結果.md` |
| Plugin 開発・テスト手順書 | `reports/02.配布物の開発・テスト/01.Plugin・Marketplace編/Plugin開発・テスト_手順書.md` |
| Marketplace 外資産の開発・テスト 調査結果 | `reports/02.配布物の開発・テスト/02.Marketplace外資産編/Marketplace外資産の開発・テスト_調査結果.md` |
| Marketplace 外資産 開発・テスト手順書 | `reports/02.配布物の開発・テスト/02.Marketplace外資産編/Marketplace外資産_開発・テスト_手順書.md` |
| 開発・テスト補助スクリプト（clean-test-env / check-assets / publish-share・bash+PowerShell） | `reports/02.配布物の開発・テスト/02.Marketplace外資産編/scripts/` |
| 実装テンプレート（層1+2・3チャネル構成の雛形） | `reports/03.実装テンプレート（層1+2）/`（README ＋ `layer1-repo-template/` ＋ `layer2-plugin/`） |
| ランチャースクリプト構成設計・実装計画 | `reports/04.資産インベントリ・統合/04.ランチャースクリプト実装/`（**実体スクリプトおよび設計書2点は C-BDK `docs/launcher/` が正本**。本フォルダの2点は 2026-07-05 時点の**凍結スナップショット**。⚠ スナップショット本文の「秘匿は custom.env」は撤回済み） |
| **配布・リリース設計確定（レーンA）** ＝ **リリース工程の正本** | 同上 `配布・リリース設計確定_レーンA.md`（CR-1 搬送方式／CR-2 リリース前提条件／案X／**フェーズ表 Phase 0〜5b**。マージ方式は **merge commit・squash 禁止**） |
| クロスレビュー報告書（Round 1〜3 ＋ マージ前セルフレビュー） | 同上 `レビュー/`（`Fableクロスレビュー統合_2026-07-07.md`＝PR#2 初回／`_PR1配布キット_`＝PR#1 初回／`_PR1PR2_Round2_`／`_PR1PR2_Round3_`／`横断セルフレビュー_マージ前_`） |
| 公開 README（GitHub 閲覧者向け・CLAUDE.md 派生） | `README.md` |

> 各成果物の版は各ファイル末尾の変更履歴を参照（索引には版番号を持たせない）。

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
- [x] 02.Marketplace外資産編 の Sonnet 動作検証（2026-06-22・実機）→ **重大検出: subagents×`--add-dir` は v2.1.178 版依存**（v2.1.165=非ロード／v2.1.178+=ロード）。現行✅＋版境界注記へ v1.2 errata 再訂正・出典 [75] 追加（225dda9）。対話実機で **#1 `/memory`＝`<Share>/.claude/CLAUDE.md` ロード確認（案1 生命線）／#2 `/agents`＝`--add-dir` 経由 subagent ロードを一意プローブで立証**。check-assets を案1（Git 追跡基準）へ改修も併施（75cc12d）。実 `<Share>`＝`base-dev-kit-for-cc` を grooming（PR #1）
- [x] item3 残検証 **C7/C10/C12 を実機確認**（2026-06-22・`--debug-file` の設定ロードログ＝非対話の権威ある証跡）。C7=クリーン隔離で個人/project/local 排除・managed 残存・auth 非継承を実証／C10=`--settings` は `flagSettings`（command-line 層）として各スコープと別 destination で併存／C12=project の `defaultMode:"auto"` 無視を WARN で実観測＋付与可能スコープ＝policy/user/flag を判明。調査結果 v1.3・手順書 v1.3 に反映。item3 完全クローズ
- [x] 実装スコープ決定（**層1+2＝テスト可能なコア**を採用・作業指示者選択）と 3 チャネル構成のテンプレート雛形作成 → `reports/03.実装テンプレート（層1+2）/`（2026-06-22）。base-dev-kit 資産を層1（ガバナンス＋起動装置）／層2（plugin: skills/agent/output-style/hook）へ振り分け。`claude plugin validate`（`--strict`）・marketplace validate ともにパス。**層3 は通常マシンで実機検証不可のため雛形は作らずレポート §解決案 層3系・付録A の記述に委譲**
- [x] 公開 `README.md` 作成（CLAUDE.md からの派生・GitHub 閲覧者向け・コミット済 d3c766d）
- [x] 成果物群の公式 docs 最新版（v2.1.195・2026-06-28）照合と横断整合性レビュー（2026-06-29・各5観点 SubAgent 並列）→ テンプレ/手順書/調査結果/v1.2/索引の陳腐化・不整合を修正（settings.local.json 2キー例外の伝播・subagents 版境界の統一・`<D>`→`<Share>`・`sub-agents`→`subagents`・MCP ポリシー一本化・テンプレ誤誘導の是正 等）
- [x] `--add-dir` 例外ロード表の**正本一元化**（J1・2026-06-29）→ v1.2 付録B に「`--add-dir` 例外ロード一覧（正本）」を新設（anchor `adddir-exceptions`）。01編§4・02編§2・02手順書§3 の早見表は本表を正本とする参照注記へ寄せ、版依存事実の片側更新漏れ（F1/F2 で顕在化）を構造的に抑止
- [x] 全マシン横断の配布可能資産インベントリ・Plugin配布可否分類・リポジトリ割当計画・全ブランチ横断資産マップ（2026-06-30、tmp/asset-inventory ブランチ）→ `reports/04.資産インベントリ・統合/`
- [x] ランチャースクリプト実装（env・起動オプションの4分類判定木、sh/ps1両対応・UTF-8 BOM+CRLF、exhaustive オプションテンプレ）→ `reports/04.資産インベントリ・統合/04.ランチャースクリプト実装/`（2026-07-05）。実体スクリプトは C-BDK（`base-dev-kit-for-cc`）が正本、PR #2（base=develop）で提出
- [x] レーンA（設計確定）→ `配布・リリース設計確定_レーンA.md`（2026-07-07）。CR-1（配布先の統制ファイルを payload に同乗）／**CR-2＝PR #1（grooming）をリリースの前提条件に格上げ**（未 grooming な ref を publish すると内部レポートが公開リポへ流出し、配布先の CLAUDE.md が消える）／案X（root `CLAUDE.md` は開発リポ専用に純化）／リリースフェーズ計画 Phase 0〜5b
- [x] レーンB（実装）→ C-BDK の 2 本の PR に反映。**PR #1 `chore/groom-as-share`**（配布キットの grooming ＋ `scripts/` の配布ゲート）と **PR #2 `feat/launcher-scripts`**（ランチャー）。**両者は相互依存**（PR#1 の publish-share が PR#2 の CR-1 を有効化し、PR#1 の check-assets が PR#2 の資産を検査する）ため、統合状態で評価する
- [x] クロスレビュー 3 巡（いずれも **Fable 5 × 3 観点**へ委任。メインは実装者ゆえ第三者たり得ない）→ `レビュー/`。**Round 1**: CRITICAL 4（publish ゲートが機能せず**内部レポートが公開リポへ流出する状態**だった 等）／**Round 2**: CRITICAL 3（**すべて Round 1 の修正が生んだ欠陥**。glob と正規表現の混同・fail-closed の片肺実装・自分の変更で無効になった検証結果の使い回し）／**Round 3**: CRITICAL 0（Round 2 の指摘は全件解消を実測確認。新規は「ゲートが環境依存で fail-open する」クラス）
- [x] マージ前の資材横断セルフレビュー（2026-07-12）→ `レビュー/横断セルフレビュー_マージ前_2026-07-12.md`。PR 差分でなく**統合後ツリー全量**（46 ファイル / payload 26）を対象。CRITICAL 0 / IMPORTANT 8 / SUGGESTION 4 / 取り下げ 1。**差分に現れない資材が 3 巡の死角だった**（公開配布物へのマシン固有パス混入・誤配置ガードの非対称・README のコピーリスト欠落 等）。全件修正済み
- [x] **PR #1 → PR #2 のマージ**（2026-07-13・**merge commit**。`400c904`＝PR#1 / `9458ed3`＝PR#2。squash していないため両ブランチの個別コミットを辿れる）。統合後 `develop` を実測 ―― reports 追跡 0 件／check-assets が作業ツリー・payload とも **exit 0 / FAIL 0**／payload 26 ファイル／`CLAUDE.md`・`.sh`＝LF・`.ps1`＝CRLF+BOM
- [x] **Phase 3 実装 → PR#3（`feat/phase3-win-file-policy` → develop）を提出**（2026-07-13・**作業指示者のレビュー／マージ待ち**）。Windows ファイル方針の確定（**一律 UTF-8・CP932 は `.bat` だけの例外**。一律 CP932 は PS7 が CP932 を読めず成立しない）／`.bat` の CP932 ガード（**原本は常に CP932・Claude には UTF-8 の影を見せる**・fail-closed 書き戻し・`permissions.deny` を硬いガードに）／`.gitattributes` の拡張子ベース化／`.ps1` の BOM+CRLF 検査 hook（**Write ツールは BOM も CRLF も保持しない**ことを実測）／root `CLAUDE.md` 書き起こし（案X）／R2-IM-8（`clean-test-env.ps1` の env 復元）／R2-IM-9（`publish-plugin` は防御 7 点を**すべて**欠いていた）／改行検証の数値訂正。R2-IM-11 は PR#1 のセルフレビューで完了済みだった
- [ ] Phase 4（develop→main ＋ tag）→ Phase 5a（C-BCP へ起動装置・雛型を移管）→ Phase 5b（publish 実行・受入検証）

> ⚠ **Round 3 の改行検証で使った計測手段が壊れていた**（2026-07-13 発覚・訂正済み）。Git Bash（MSYS）の `grep` / `awk` は CR を数えられず、**間違い方が 2 通りあってどちらも“それらしい値”を返す** ―― `grep -c $'\r'` は**パターンが空になり全行にマッチして総行数**を返し、実 CR をパターンにすると今度は grep が**入力の CR を剥がして常に 0** を返す（`awk '/\r$/'` も同様に 0）。**「大きい数」と「0」の両方が誤りになりうる**ため、before/after を別の書き方で測ると**壊れた計測どうしが「修正が効いた」ように見える**（Round 3 の「CR 50 → 0」がまさにそれ）。**正しいのは `tr -cd '\r' | wc -c` または `git ls-files --eol`**（`grep -U` でも可）。結論（`.sh`=LF / `.ps1`=CRLF+BOM）は再測定で追認済み。詳細は確定書 §10。
