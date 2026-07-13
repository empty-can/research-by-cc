# Fable 5 クロスレビュー 統合結果（Round 3）― Round 2 指摘への対応検証と再レビュー

> **位置づけ**: PR #1（配布キット grooming）と PR #2（ランチャー）に対する **3 巡目のクロスレビュー**。Round 2 の指摘（CRITICAL 3・IMPORTANT 11・SUGGESTION 4）に対する**対応が正しく行われたか**の検証と、**修正が新たな欠陥を生んでいないか**の探索が対象。メインセッション（Opus）は自らの修正を検証する立場にあり第三者たり得ないため、3 観点を **Fable 5** に委任し、指摘をメインが実ファイル・実行再現で典拠検証して統合した。

## 0. メタ情報

| 項目 | 内容 |
|---|---|
| レビュー対象 | C-BDK `chore/groom-as-share`（PR #1・HEAD `0df64e7`）＋ `feat/launcher-scripts`（PR #2・HEAD `16dba53`）＋ **両者の統合状態** |
| レビューア | Fable 5 × 3 観点（論理整合性 / 実用性 / 作業指示者ペルソナ・いずれも元リポジトリ無変更） |
| 統合・検証 | メインセッション（Opus 4.8・実ファイル / 実行再現） |
| レビュー日 | 2026-07-12（Round 3） |
| 前巡 | `Fableクロスレビュー統合_PR1PR2_Round2_2026-07-12.md` |
| 対応コミット | PR #1: `0df64e7`（CR-b・IM-1/2/3/6/7）／PR #2: `16dba53`（CR-a・CR-c・IM-4/5） |

**件数（統合・検証後）**: CRITICAL **0** / IMPORTANT 10 / SUGGESTION 7 / POSITIVE 6 / 取り下げ 1。

**承認判断**: **条件付き GO**。**Round 2 の CRITICAL 3 件（CR-a / CR-b / CR-c）は 3 観点すべてが独立に実測し、解消を確認した。3 巡目にして初めて「修正が新たな CRITICAL を生まなかった」ラウンドとなった。** マージ操作そのものを止める欠陥は無い（PR #1 → PR #2 の実マージが 2 連続 exit 0・統合ツリーは配布 ready）。ただし **publish 運用を開始する前に塞ぐべき IMPORTANT が 2 件（R3-A / R3-B）** あり、いずれも「ゲートが環境依存で無効化される」クラスであるため、コードが凍結している今のうちに直すのが安い。

## 1. 総括

- **Round 2 の指摘は、対応を主張した 9 件（CR-a/b/c・IM-1〜7）が全件、実体・blob・実行再現のいずれでも解消を確認できた**。誇張や空承認はゼロ。3 観点が独立に同じ結論に達している。
- **今回の新規指摘は「ゲートが環境依存で fail-open する」クラスに集中した**。Round 1・Round 2 の CRITICAL が「片方の OS だけ防御が無い」だったのに対し、Round 3 は **「同じ OS・同じ ref でも、マシンの git 設定やディレクトリ配置で結果が変わる」** という一段深い非決定性である:
  - **R3-A**: `check-assets` の層自動判定が**祖先方向に `.git` を探す**ため、payload の展開先がたまたま git リポジトリ配下だと、**成果物混入も統制ファイル不在も FAIL から WARN へ退化**する（実測: FAIL 5 → FAIL 1）。`publish-share` は payload を `mktemp -d` に展開して検査するので、`TMPDIR` が repo 配下のマシンではゲートが丸ごと fail-open になる。
  - **R3-B**: `git archive` は **publisher のローカル `core.autocrlf` を適用する**ため、同一コミットでも publish するマシン次第で配布 blob が変わる（実測: payload 19 ファイル中 **18 ファイルのハッシュが相違**・CRLF 混入）。Git for Windows の既定は `autocrlf=true` であり、**普通に clone した Windows 開発者が publish すると配布リポの中身が書き換わる**。
- **§8 の再発防止ルールの遵守は「機構は改善・文書は未達」**。①修正後の再検証 ④glob/regex は遵守された。しかし **②両 OS の対称性は診断面で再び片肺**（PS 版パーサだけが不正キーを無警告破棄・R3-C）、**③既存文書を壊していないかは再違反**（README の `check-assets` 説明が修正前の仕様のまま・R3-F）。**「機構は直すが、その機構を説明する文書を置き去りにする」パターンが 3 巡連続で出ている。**
- **マージ後に回した約束が、正本トラッカーに載っていない**（R3-J）。Round 2 が「マージ後・レーンB」へ送った 8 件は、確定書のフェーズ表にも実装計画にも 1 件も計上されていない（機械検索で確認）。**レビュー報告書は「記録」であって「実行トラッカー」ではない。**

## 2. 3 観点が独立到達した核心テーマ

| 統合テーマ | 論理整合性 | 実用性 | 作業指示者 | 私の検証 |
|---|---|---|---|---|
| PR 本文が実体と乖離（旧名 `check-payload`・29 件・虚偽記述の残置） | I6 | R3-4 | U-I1 | **CONFIRMED**（R3-I・**3 観点全到達**） |
| 確定書の「squash 推奨」が現行方針（merge commit・squash 禁止）と矛盾 | I4 | ― | U-I2 | **CONFIRMED**（R3-G） |
| PS 版パーサが不正キーを無警告で破棄（bash は警告） | I3 | R3-5 | ― | **CONFIRMED**（R3-C） |
| 設計書正本に「CR-2 はマージ後に実装」の幻タスク（実体は実装済み） | I5 | ― | U-S2 | **CONFIRMED**（R3-H） |
| symlink 入り payload の可否が OS で分岐 | S-3 注記 | R3-3 | ― | **CONFIRMED**（R3-E） |
| Round 2 積み残しが正本トラッカー未計上 | IM-11 注記 | ― | U-I3 | **CONFIRMED**（R3-J） |

---

## 3. CRITICAL

**該当なし。**

Round 2 の CRITICAL 3 件はすべて解消を実測で確認した。マージ（PR #1 → PR #2・merge commit）を止める欠陥は 3 観点いずれからも検出されなかった。

| Round 2 CRITICAL | 解消の実測典拠 |
|---|---|
| **CR-a**（行パーサの glob/正規表現混同で typo 1 行が bash 起動を殺す） | `setup-environment.sh:59-62` がアンカー付き `[[ =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]` へ。敵対的 `custom.env` 16 種を **bash 5.2 / pwsh 7.4 / Windows PowerShell 5.1** の 3 系統で実行し、typo 行は警告＋読み飛ばしで**起動継続**、1 文字キー `A=1` はロード、機微キーは拒否（実用性観点） |
| **CR-b**（fail-closed が PS 版だけで bash 版に無い） | `publish-share.sh` にパイプライン成否検査＋件数照合を実装。**3 層すべてを個別に実証**（実用性観点）: ①symlink 入り ref → tar exit 2 を検知して中止 ②**「exit 0 なのに 1 ファイル黙って落とす嘘つき tar シム」** → 件数照合「期待 29 / 実際 28」で中止 ③`.claude` 無し ref → 中止。**全ケースで配布先 status 0 行＝無傷** |
| **CR-c**（`.gitattributes` の add/add コンフリクト＋PR の虚偽記述） | 両ブランチの `.gitattributes` blob が**同一 SHA `1e524ba`**。develop → PR#1 → PR#2 の実マージが **2 連続 exit 0**。訂正コメントの時系列も健全（修正コミット 17:59/18:03 JST → 訂正コメント 18:05/18:06 JST＝**今回は修正後に主張している**・作業指示者観点がタイムスタンプで追認） |

---

## 4. IMPORTANT

### R3-A `check-assets` の層自動判定が祖先方向を探索するため、payload 検査の fail-closed が環境依存で退化する（IM-2 対応の残穴）
**統合元**: 論理I1
**私の検証（CONFIRMED・再現済み）**:

`check-assets.sh` / `.ps1` は `git -C <対象> rev-parse --is-inside-work-tree` で「git 層（追跡基準）」か「非 git 層（実体基準）」かを選ぶ。**この判定は祖先方向に `.git` を探索する**ため、**対象自身がリポジトリでなくても「どこかの repo 配下」なら追跡基準に化ける**。

同一 payload（reports 8 件を含む未 groomed な `main`）を 2 か所へ展開して実測:

```
A) 非 git ディレクトリへ展開   → FAIL 5 / exit 1（publish 遮断）
B) git リポジトリ配下へ展開    → FAIL 1 / exit 1
   [WARN] .claude/reports が実在するが未追跡（配布はされない。掃除推奨）      ← 嘘。配布される
   [WARN] .claude/plans   が実在するが未追跡
   [WARN] .claude/.gitignore が無い / [WARN] .claude/.gitattributes が無い
   [FAIL] 共有共通ルール .claude/CLAUDE.md が無い     ← 二層化していないこの 1 件だけが残る
```

B で残る FAIL は**二層化していない `.claude/CLAUDE.md` 検査だけ**である。つまり **`.claude/CLAUDE.md` を持つ ref なら FAIL=0 になり publish が通る**。`chore/groom-as-share` 単独 ref がまさにその条件を満たす（`.claude/CLAUDE.md` を持ち、`.claude/.gitignore` / `.gitattributes` を持たない）ため、**Round 2 IM-7 が「これを publish すると配布先の改行保護だけが黙って消える」と警告した ref が、この環境では実際に素通しされる**。

**発火条件**: `publish-share` は payload を `mktemp -d`（bash）/ `$env:TEMP`（PS）に展開して `check-assets` を呼ぶ。`TMPDIR` / `%TEMP%` が git worktree 配下のマシンで発火する（例: `%USERPROFILE%` を dotfiles リポジトリ化している Windows 利用者は、Git Bash の `/tmp` が home 配下に写像されるため**既定で該当**）。既定環境では発火しないため CRITICAL とはしないが、**「fail-closed を状態・環境に依存させない」という本キット自身の原則（Round 2 P-3）に正面から反する**。
**帰結**: CR-A で塞いだ「内部レポートの公開リポ流出」が、**配布先でも開発リポでもなく publisher のマシン構成という第三の変数から再開通する**。
**修正案**: 呼び出し側は層を知っているのだから自動判定に頼らない。**(1)** `check-assets` に `--payload`（実体基準を強制）を追加し、`publish-share` からは必ず付けて呼ぶ。**(2)** 自動判定側も「repo 配下だが**ルートではない**（`rev-parse --show-prefix` が非空）なら実体基準」に倒す ―― IM-1 で導入した道具をそのまま使える。**両 OS 同時に**。

### R3-B `git archive` が publisher の `core.autocrlf` を適用するため、同一 ref でも publish するマシン次第で配布 blob が変わる
**統合元**: 実用R3-1
**私の検証（CONFIRMED・再現済み）**:

同一リポジトリを 2 通りの設定で clone し、**同一 ref を archive** して展開・ハッシュ比較:

```
pub-lf   (core.autocrlf=false) / pub-crlf (core.autocrlf=true)
payload 総ファイル数: 19 / ハッシュ不一致: 18
  .claude/CLAUDE.md / agents/ / output-styles/ / rules/ / settings.json …
CR バイト数: x-lf=0  x-crlf=50        ← CRLF 化を実測
`-c core.autocrlf=false` を付けた場合: CR バイト数=0   ← 修正案の有効性も実測
```

一致したのは root `.gitattributes` で eol を固定済みのパス（launcher・skills）だけだった。機構: **`git archive` は working-tree 変換（`text`/`eol` 属性＋`core.autocrlf`）を適用する**ため、属性が付いていない全テキストが publisher のローカル設定に従って CRLF 化する。
**帰結**: Round 2 P-1 の「bash / PowerShell で bit 等価」は**同一マシン内でのみ**成立していた。**Git for Windows の既定は `autocrlf=true`** であり、普通に clone した Windows 開発者が publish すると、配布リポ（公開）の**ほぼ全ファイルが CRLF で書き換わる**。以後 publish するマシンが変わるたびに全ファイル diff が発生し、submodule bump の差分レビューが機能しなくなる。配布先 clone 側の `autocrlf` との組み合わせで結果が変わるため、**2 変数の組で非決定**。
**修正案**: **(1)** 両版の archive 呼び出しを `git -c core.autocrlf=false -C "$DEV_ROOT" archive …` に固定する（**bash と PS の両方に**。片肺禁止）。**(2)** 恒久策として配布先ルートに着地する `.claude/.gitattributes` に `* text=auto eol=lf` を先頭行として置き、既存の `.ps1 → crlf` 行を後勝ちで残す（属性で決定化する。**S-4「配布側 `.gitattributes` が skills のスクリプトを対象外にしている」も同時に解決する**）。

### R3-C PS 版パーサが不正キーを無警告で破棄する（bash は警告）― CR-a 修正の診断面が片肺
**統合元**: 論理I3 ／ 実用R3-5
**私の検証（CONFIRMED）**: `setup-environment.sh:59-62` は不正キーを**警告して**読み飛ばす。一方 `setup-environment.ps1:47` は `if ($key -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') { continue }` ―― **無警告で破棄**。実用性観点の実測では、`MAX THINKING TOKENS` / `1BAD` / `FOO-BAR` / `export EXPFOO` / `=nokey` の 5 件に対し bash は警告 5 件、**PS は出力ゼロ**。
**帰結**: 実効 env は両 OS で一致するため機能非対称ではない（CR-a は解消済み）。しかし **CR-a のまさにその筋書き（利用者の typo）に遭遇した Windows 利用者だけが、手掛かりゼロで「設定が効かない」に直面する**。CR-a 修正のコミットメッセージ・PR コメントは「不正名は警告して読み飛ばす」を新しい契約として記載しており、**その契約が片方の OS で履行されていない**。
**修正案**: `setup-environment.ps1:47` を `Write-Warning "custom.env の行を読み飛ばしました（環境変数名として不正）: $key"; continue` に（1 行）。

### R3-D UTF-8 BOM 付きの `custom.env` で先頭キーが bash だけ落ち、しかも警告からは原因が分からない
**統合元**: 実用R3-2
**私の検証（CONFIRMED・再現済み）**: Windows のメモ帳で「UTF-8 (BOM)」保存すると発生する。

```
custom.env 先頭バイト: ef bb bf 46 49 52 53 54 4b 45 59 3d   （BOM + "FIRSTKEY="）
bash : ⚠ custom.env の行を読み飛ばしました（環境変数名として不正）: ﻿FIRSTKEY   ← BOM は不可視
       → FIRSTKEY=[UNSET]  SECOND=[2]
BOM 無し（対照）: → FIRSTKEY=[plainvalue]  SECOND=[2]
PowerShell: Get-Content が BOM を剥がすため FIRSTKEY=[bomvalue]（警告なし）
```

**帰結**: **同じ `custom.env` で先頭の env だけが bash 系で効かない**（CR-a と同じ「OS で結果が違う」クラス。起動は継続するため CRITICAL ではない）。さらに悪いことに、**警告に出るキー名は見た目が正しい**ため、利用者は原因に到達できない。
**修正案**: bash パーサで先頭行の BOM（`$'\xef\xbb\xbf'`）を除去する（1 行）。あわせて `custom.env.template` のヘッダの書式契約に「**BOM なしで保存すること**」を明記する。

### R3-E symlink 入り payload の publish 可否が OS で分岐する（bash は中止・PS は壊れたファイルを配布完了）
**統合元**: 実用R3-3（Round 2 S-3 の昇格）
**検証（CONFIRMED・実用性観点が実測）**: mode 120000 のエントリを持つ ref を publish すると:

```
bash: tar: Cannot create symlink … → ‼ payload を展開できない。publish 中止 / exit 1・配布先無傷
pwsh: → publish 完了（exit 0・push 成功）。配布先の当該ファイルは
      「ターゲットパス文字列（"settings.json" の 13 バイト）を中身とする通常ファイル」
```

**帰結**: CR-b の修正で bash 側が硬く閉じた結果、**同一 ref のリリース可否が実行者の OS に依存する**状態が残った（Round 2 が CR-b で否定した「片方の OS だけ防御が無い」の変種）。PS 経路は zip が symlink を通常ファイル化するため件数照合も通過し、**データが化けたまま公開される**。
**修正案**: Round 2 S-3 の案どおり、**ref に対して** `git ls-tree -r <REF> -- .claude` に mode 120000 が有れば FAIL させる検査を `publish-share` の両版に 1 箇所ずつ追加する（payload 実体でなく ref を見るのが確実）。これで両版の根を断てる。

### R3-F README の `check-assets` 判定説明が IM-2 修正前の仕様のまま（§8③「既存文書を壊さない」の再違反）
**統合元**: 論理I2
**私の検証（CONFIRMED）**: `README.md`（chore・統合後も同一）が今も次のように書いている:

> **セッション成果物**（…）―― **実体があれば FAIL**。追跡状態は見ない。

これは **CR-A 時代の仕様**であり、`0df64e7` が実装を二層基準（working tree: tracked=FAIL / 未追跡実在=WARN、payload: 実体=FAIL）へ変えた後も README は未同期（`0df64e7` の変更ファイルに README は含まれていない）。加えて (a) IM-7 で追加した **2-d 統制ファイル検査**に触れていない、(b) 成果物の列挙が `.claude/agent-memory-local/` を欠く（「正本＝`check-assets` の 2-c 配列」宣言への追随漏れ）。
**帰結**: README の手順を実行した開発者が見る挙動（WARN・exit 0）と、その 10 行下の説明（実体があれば FAIL）が矛盾する。**Round 2 §8 の再発防止③を、当の修正コミットが破っている。**
**修正案**: README の当該節を二層基準の記述へ書き換え、2-d 検査を追記し、列挙は「正本＝`check-assets` の 2-c 配列」への参照に寄せる。

### R3-G 設計確定書に「squash 推奨」が 2 箇所残存 ― 確定済みマージ方針（merge commit・squash 禁止）と正面矛盾
**統合元**: 論理I4 ／ 作業U-I2
**私の検証（CONFIRMED）**: `配布・リリース設計確定_レーンA.md` の 2 箇所:

- L56「PR#1（`chore/groom-as-share` → develop・**推奨 squash merge**）またはその等価 grooming を…前提条件に格上げする」
- §6 フェーズ表 Phase 1「grooming をリリース前提としてマージ（PR#1 chore→develop・**squash 推奨**）」

一方、作業指示者の確定指示は「**squash するとマージ元ブランチの情報が消えるため、マージ時に squash は行わない**」であり、PR コメントにもその旨を記載済み。
**帰結**: 確定書はレーン B が実行時に読む**正本**である。これに従った操作者が squash すると、PR コメント・レビュー報告書が SHA で相互参照している修正コミット群（`ab6436c` / `20bab61` / `0df64e7` / `16dba53` 等）が develop の履歴から辿れなくなる。**Round 2 で自ら問題視した「文書間の片側更新漏れ」と同型。**
**修正案**: 当該 2 箇所を「**merge commit（squash 禁止・履歴保持）**」へ訂正し、変更履歴に方針転換の日時と理由を 1 行残す。

### R3-H 設計書正本に「CR-2 は PR#1 マージ後に実装」という幻タスクが残存（実体は PR#1 で実装済み）
**統合元**: 論理I5 ／ 作業U-S2
**私の検証（CONFIRMED）**: `docs/launcher/launcher-implementation-plan.md` §8-bis に:

> - [ ] **CR-2** publish ゲート強化（`.claude/reports/` 混入で FAIL・`.claude/CLAUDE.md` 不在で FAIL・個人実体で FAIL）。`scripts/` は `chore/groom-as-share` にのみ存在するため、**PR#1 マージ後**に実装する

CR-2 の要求は **PR#1 の `ab6436c` + `0df64e7` で全て実装済み**（未 groomed な payload に対して FAIL が発火することを本レビューで実測）。加えて確定書のフェーズ表 Phase 2 も「check-assets 強化（CR-2）を develop へ」のまま。PR #2 本文の「未実施」節も同様。
**帰結**: マージ後のセッション／レビューアが**存在しないタスクを追う**か、**二重実装する**。設計書を「正本」と規定した（Round 1 IM-8）以上、正本の完了状況が実体とずれるのは正本一元化の趣旨に反する。
**修正案**: 実装計画 §8-bis のチェックボックスを「実装済み（PR#1 `ab6436c` / `0df64e7`）」へ更新。確定書 Phase 2 も同様に消し込む。

### R3-I PR 本文が実体と乖離したまま（Round 2 IM-10 が未対応・**3 観点全到達**）
**統合元**: 論理I6 ／ 実用R3-4 ／ 作業U-I1
**私の検証（CONFIRMED・GitHub API で取得）**:

- **PR #1 本文**: 旧名 **`check-payload` が残存**（`check-assets` へ改名済み＝**本文の検証手順は実行不能**）。「変更」3 点のみだが実体は **15 commits / 51 files**（publish-share・win-file-encoding・pre-compact 等は本文に記載なし）。補足は**コメント 3 件止まり**で本文は未改訂。
- **PR #2 本文**: Round 2 で誤りと判明した「`.claude/reports/` は develop / 本ブランチで **29 件追跡中**」（正: develop **33** 件）と、「PR #1 適用後に本 PR をマージしても**コンフリクトしないことを実測済み**」（Round 2 が虚偽と認定した文）が**無修正で残置**。※後者は `16dba53` による解消で**内容としては真に戻っている**が、本文には訂正の注記が無い。

**帰結**: merge commit 方針では **PR 本文が履歴から辿る第一資料**になる。本文だけを読む将来の読者は「承認されたもの」を誤認し、記載された検証手順の再現にも失敗する。
**修正案**: PR #1 本文に (a) `check-payload` → `check-assets` の訂正、(b)「実体は 15 commits / 51 files。詳細と追認はコメント 3 件を参照」の 1 段落、(c) 検証節の現行化。PR #2 本文の 2 記述に「→ コメントで訂正済み（正: 33 件 / コンフリクトは `16dba53` で解消・再実測済み）」を追記。**いずれも GitHub 上の本文編集のみでブランチ HEAD を動かさない（コード再レビュー不要）。**

### R3-J Round 2 の「マージ後・レーンB」送り 8 件が、正本トラッカーのどこにも計上されていない
**統合元**: 作業U-I3（論理 IM-11 も同旨）
**私の検証（CONFIRMED・機械検索）**: 確定書（`配布・リリース設計確定_レーンA.md`）と実装計画（`docs/launcher/launcher-implementation-plan.md`）の双方に対し、Round 2 のマージ後送り項目のキーワードを検索:

```
  clean-test-env      確定書=0  実装計画=0
  publish-plugin      確定書=0  実装計画=0
  CLAUDE_CONFIG_DIR   確定書=0  実装計画=0
  symlink / 120000    確定書=0  実装計画=0
```

R2 IM-8（`clean-test-env.ps1` の env 復元）・R2 IM-9（`publish-plugin` への横展開）・R2 IM-11（README 群の同期）・S-1〜S-4 は、**いずれの正本にも 1 件も載っていない**。現在の記録は Round 2 報告書 §9 と PR コメントのみ。特に **IM-11 は「確定書のフェーズ表に明記する」ことそのものが修正案だった**のに未実施。
**対照的に、CR-D（root `CLAUDE.md` 書き起こし）と Round 1 IM-3（`CLAUDE.md.example` の C-BCP 移管）は確定書 Phase 3 / Phase 5a に堅牢に記録されており、やればできる形が既にある**（作業指示者観点）。
**帰結**: レビュー報告書は「レビューの記録」であって「実行のトラッカー」ではない。**フェーズ表に無い約束は、レーン B 移管（メモリ非共有と確定書自身が明記）で高確率に消える。** PR 本文だけに書かれた約束も、PR がマージされた瞬間に読まれなくなる。
**修正案**: 確定書のフェーズ表に計上する。最低限 ―― Phase 3 の完了条件に「C-BDK README の launcher 同期（R2 IM-11）＋ R2 IM-8 / R2 IM-9」、Phase 5b の完了条件に「C-BDC / C-BCP README の実態同期＋ S-1〜S-4 の判断」。

---

## 5. SUGGESTION

- **S-1**: `setup-environment.ps1` の `Set-Item` は空値（`EMPTY=`）で**変数を作らない / 削除する**（pwsh 7・5.1 とも実測 `EMPTY=UNSET`）。bash は空文字で set する。存在有無で挙動が変わる env でのみ差が出る。テンプレの書式契約に「空値は不可」を明記するか、PS 側を `[Environment]::SetEnvironmentVariable` 相当へ揃える。
- **S-2**: **Windows PowerShell 5.1 は BOM 無し UTF-8 の `custom.env` を CP932 として誤読する**（実測: `JPVAL=日本語値` → pwsh 7 は `[日本語値]` / 5.1 は `[譌･譛ｬ隱槫､]` を**そのまま export**）。`.ps1` は「5.1 / 7 両対応」を謳っているが、データファイル側は 5.1 で非 ASCII 値が安全でない。「`custom.env` の値は ASCII 推奨（5.1 利用時は必須）」の注記か、対応シェルを pwsh 7+ と明示する。※R3-D（BOM 除去）と**トレードオフの関係にある**点に注意（BOM を付ければ 5.1 は正しく読むが bash が落ちる）。**根本解は R3-D の bash 側 BOM 除去＋「BOM 付き UTF-8 を推奨」に倒す**か、値を ASCII に限る運用。設計判断が要る。
- **S-3**: `docs/launcher/launcher-implementation-plan.md` §6 #2 に「秘匿系は全て `custom.env` でよいか。」という**撤回済み前提の設問**が未注記で残る（#1 / #5 と同様に「→ §6-bis 判定木で確定（分類A は OS env）」の注記を付けて統一する）。
- **S-4**: `check-assets` の 2-d WARN 文言「**この ref を** publish すると…」は working tree 検査時（ref ではない）には不正確。二層基準に合わせ「この状態のまま publish すると」等へ。
- **S-5**: Round 2 IM-9 の修正案にあった「**PR に申し送りを残す**」が未実施（`publish-plugin` の 4 欠陥は PR コメントに記載なし）。R3-I の本文整理時に 1 行併記する。
- **S-6**: **指摘 ID が巡回で衝突している**（「IM-8」が Round 1 では「設計書の正本規定」、Round 2 では「clean-test-env の env 残存」を指す）。トラッカーへ計上する際は `R2-IM-8` のように**巡回接頭辞**を付けないと、レーン B が誤った項目を「完了済み」と誤認し得る（本報告書は `R2 IM-8` 表記で区別している）。
- **S-7**: 配布版 `.claude/CLAUDE.md` の Skills 表が **2 件のまま**（payload は 6 skill を配布）。Round 2 S-1 の残存。R3-B の `.gitattributes` 整備と同じ「配布先にだけ古いものが着地する」クラス。

## 6. POSITIVE

- **P-1 CR-b の fail-closed は 3 層とも本物**: ①パイプライン成否（symlink ref → tar exit 2 → 中止）②件数照合（**「exit 0 なのに 1 ファイルを黙って落とす嘘つき tar シム」を自作して**「期待 29 / 実際 28 → 中止」を独立実証）③check-assets ゲート（`main` payload FAIL → 中止）。**全ケースで配布先は status 0 行＝無傷**（実用性観点）。
- **P-2 IM-1 の根本解（`--show-prefix`）が表記問題を消滅させた**: MSYS の `/tmp` 別名配布先へ publish 成功、スペース入りパス成功、別リポの CWD から実行しても正しい `DEV_ROOT`、**submodule（gitlink）とサブディレクトリは両版 exit 2 で拒否し親リポの `.git` は健在**（過去に `.git` を消す欠陥があった箇所）。
- **P-3 正常系の両 OS parity は blob 単位で完全一致**: 日本語名 3 ファイルを含む ref を bash → 偽配布先 A / PS → 偽配布先 B に publish し、`ls-tree -r` の**ファイル一覧・blob ハッシュとも diff ゼロ**。さらに PS で bash 済み dest へ再 publish すると「変更なし。publish 不要」＝**経路間の決定性**まで裏取り。
- **P-4 IM-2 の二層基準は 4 象限とも設計どおり**: 未追跡実在=WARN / exit 0（README の手順が通る）、`git add -f` で強行追跡=FAIL / exit 1、payload 実体=FAIL / exit 1、統合 payload=exit 0。**「`git add` は `.gitignore` に拒まれ、`-f` で強行して初めて FAIL になる」多層防御が実機で観察できた**。
- **P-5 ランチャーが 3 ランタイムで E2E 成功**: bash 5.2 / pwsh 7.4 / **Windows PowerShell 5.1** で OPTS ＋ 起動時引数が正順で届き、**exit code 42 が 3 系統とも呼び出し元へ伝播**。ガード（`claude` 不在 / launcher 欠落）は exit 1 ＋ 復旧手順を表示。
- **P-6 CR-c の教訓が実践されている**: 今回の「再実測済み」という主張はすべて修正コミット（17:59 / 18:03 JST）**より後**（18:05 / 18:06 JST）に投稿されており、作業指示者観点の独立再実測とも一致した。**「古い検証結果の使い回し」は再発していない。**

## 7. 取り下げ・誤検知

**1 件取り下げ**。

- **論理整合性 S2「CR-b の件数照合により、payload に非 ASCII ファイル名が入った時点で Windows の bash 版 publish は恒久 FAIL になる（bsdtar が取りこぼす）」** → **取り下げ（事実誤認）**。
  - **典拠**: Git Bash の `tar` は `/usr/bin/tar` ＝ **GNU tar 1.35**（実測）であり、UTF-8 のファイル名を正しく扱う。Round 2 で「日本語ファイル名を黙って取りこぼす」と認定したのは **PowerShell 版から呼ばれる `System32\tar.exe`（bsdtar）** であり、**bash 経路とは別の実行体**である。実用性観点は日本語名 3 ファイルを含む ref の bash publish が**成功**することを実測しており（P-3）、論理整合性観点の前提が誤っている。

> なお **S-2（Windows PowerShell 5.1 の CP932 誤読）と R3-D の macOS ケース**は、実機が本環境に無いため**確証済みメカニズムからの外挿**を含む（実用性観点が明示）。

## 8. Round 2 指摘の対応状況（全件）

| ID | 指摘要旨 | 判定 | 典拠 |
|---|---|---|---|
| **CR-a** | 行パーサの glob/正規表現混同 | **解消** | 3 系統で敵対 `custom.env` 実行・起動継続を実測 |
| **CR-b** | fail-closed が PS 版のみ | **解消** | 3 層（パイプライン成否 / 件数照合 / ゲート）を個別実証 |
| **CR-c** | `.gitattributes` add/add ＋虚偽記述 | **解消** | blob 同一（`1e524ba`）・実マージ 2 連続 exit 0・訂正コメントの時系列健全 |
| **IM-1** | ルート一致検査がパス別名で誤拒否 | **解消** | `--show-prefix` 空判定へ。MSYS 別名・gitlink・サブディレクトリを実測 |
| **IM-2** | check-assets が working tree で恒常 FAIL | **解消**（**ただし残穴 → R3-A**） | 4 象限を両版で実測 |
| **IM-3** | `scripts/*.ps1` が BOM 無し | **解消** | 4 blob とも先頭 `ef bb bf` |
| **IM-4** | 撤回済みドクトリンが計画書 3 箇所に残存 | **解消**（残滓 1 → S-3） | `16dba53` が §3(2)・§6#5・§6-bis#5 を訂正 |
| **IM-5** | `.claude/.gitignore` に `/plans/` 無し | **解消** | 三重定義（2-c 配列・root・`.claude`）が全 6 項目一致を機械照合 |
| **IM-6** | win-file-encoding rule の適用除外 | **解消** | 「適用しないケース」＋ `git check-attr` 判断手順＋配布射程の注記 |
| **IM-7** | 統制ファイル不在検査・keep-list 非対称 | **解消**（**ただし R3-A で無効化され得る**） | 2-d 検査を両版に・keep-list に `.gitattributes` |
| **IM-8** | `clean-test-env.ps1` の env 残存 | **未対応（申し送り）→ 記録が R3-J** | 実行後 `CLAUDE_CONFIG_DIR=[削除済みパス]` を実測 |
| **IM-9** | `publish-plugin` への横展開 | **未対応（申し送り）→ 記録が R3-J** | `REF="main"` 既定・CWD 依存・exit code 無検査が現存 |
| **IM-10** | PR #1 本文の乖離 | **未解消 → R3-I** | 本文に `check-payload` 残存・「変更 3 点」のまま |
| **IM-11** | README 群の同期をフェーズ表へ | **未対応 → R3-J** | フェーズ表に該当行なし・統合後 README の launcher 言及 0 件 |
| **S-1** | 配布版 `.claude/CLAUDE.md` の Skills 表 2/6 | 据え置き → S-7 | 表 2 件 vs `skills/` 6 個 |
| **S-2** | `start_claude_code.ps1` の `Write-Error` | 据え置き | exit code は 1 で正しいことを実測（表示のみの問題） |
| **S-3** | symlink payload の検査 | **昇格 → R3-E** | PS 経路が壊れたファイルを publish 完了することを実測 |
| **S-4** | 配布側 `.gitattributes` が skills 非対象 | 据え置き（**R3-B の修正で同時解決可**） | `/launcher/*` のみ |

---

## 9. 次アクションと対応状況

### マージ前（コード）― **全件対応済み**

| ID | 対応 | 対象 | 状態 |
|---|---|---|---|
| **R3-A** | `check-assets` に `--payload` / `-Payload` を追加し `publish-share` から明示指定。自動判定も `--show-prefix` の空判定（対象がリポジトリのルートか）へ | PR #1 | **完了** `debb531` |
| **R3-B** | archive 呼び出しを `-c core.autocrlf=false` へ固定（両版）＋ `.claude/.gitattributes` を「既定 LF ＋ `launcher/*.ps1` だけ CRLF 例外」へ（S-4 も同時解決） | PR #1 ＋ PR #2 | **完了** `debb531` / `c566685` |
| **R3-C** | `setup-environment.ps1` の不正キー破棄に `Write-Warning` を追加 | PR #2 | **完了** `c566685` |
| **R3-D** | bash パーサの BOM 除去＋テンプレの文字コード規定（非 ASCII 値は BOM 付き UTF-8 で保存） | PR #2 | **完了** `c566685` |
| **R3-E** | `publish-share` 両版に「ref に mode 120000 が有れば中止」の検査 | PR #1 | **完了** `debb531` |

### マージ前（文書）

| ID | 対応 | 対象 | 状態 |
|---|---|---|---|
| **R3-F** | README の `check-assets` 判定説明を二層基準へ同期（2-d 検査・成果物クラスの正本を追記） | PR #1 | **完了** `debb531` |
| **R3-G** | 確定書の「squash 推奨」を **merge commit（squash 禁止）** へ訂正（3 箇所） | W-RBC | **完了** |
| **R3-H** | 実装計画 §8-bis / 確定書 Phase 2 の **CR-2 幻タスク**を消し込み | PR #2 ＋ W-RBC | **完了** `c566685` |
| **R3-I** | PR #1 / #2 の**本文**改訂（`check-payload` → `check-assets`・15 commits・33 件・訂正注記） | GitHub | **完了** |
| **R3-J** | Round 2 積み残し 8 件を**確定書のフェーズ表へ計上**（`R1-`/`R2-`/`R3-` 接頭辞を導入） | W-RBC | **完了** |

### 修正後の統合再検証（実測・修正前の結果は使い回さない）

| 検証 | 結果 |
|---|---|
| コンフリクト（chore × feat） | **無し**（exit 0） |
| 実マージ（develop → PR#1 → PR#2・merge commit） | 2 連続 exit 0・作業ツリーの汚れ 0 行 |
| 統合ツリー | reports 追跡 **0 件**・統制ファイル 3 種完備・root `.gitattributes` の scripts 保護 3 行維持 |
| 統合 working tree の check-assets | **exit 0 / FAIL 0 / WARN 0**（誤検知なし） |
| R3-A（payload を git リポジトリ配下で検査） | `--payload` 有無を問わず **FAIL 5 / exit 1**（fail-open が閉じた）。bash / PowerShell が 4 象限で完全一致 |
| R3-B（`autocrlf=true` の clone から archive） | ~~`CLAUDE.md` の CR 50 → **0**、`settings.json` の CR 39 → **0**。`launcher/*.ps1` は **CR 101 のまま**~~ **⚠ この数値は無効**（2026-07-13 判明）。Git Bash の `grep` / `awk` は CR を数えられず、`grep -c $'\r'` は**パターンが空になり全行にマッチして総行数**を返す（50 / 39 / 101 はいずれも行数）。実 CR をパターンにすると今度は grep が入力の CR を剥がして **0** を返すため、**別々の壊れ方どうしが「50 → 0」という“修正が効いた”外見を作っていた**。**結論（`.sh`=LF / `.ps1`=CRLF+BOM ／ `eol=crlf` 属性が勝つ）は `tr -cd '\r' \| wc -c` と `git ls-files --eol` で再測定し正しいことを確認済み**。詳細は確定書 §10 |
| R3-E（symlink 入り ref の publish） | bash / PowerShell とも **exit 1・配布先無傷** |
| 統合 ref の実 publish（`autocrlf=true` の clone から） | 26 ファイル・reports 0・統制ファイル 3 種が着地 |
| ゲートの生存（未 grooming な `main` を publish） | **FAIL 5 / exit 1** で遮断・配布先無傷 |
| 配布先 clone（Windows 既定 `autocrlf=true`）の改行 | `.sh` = **LF**（保護成功）／`.ps1` = **CRLF**（維持）／`CLAUDE.md` = **LF** |

### マージ後・レーンB（確定書のフェーズ表へ計上済み）

- **Phase 3**: R1-IM-9/10（root `CLAUDE.md` の書き起こし＝案X）／**R2-IM-8**（`clean-test-env.ps1` の env 復元）／**R2-IM-9**（`publish-plugin` への横展開）／**R2-IM-11**（C-BDK README の launcher 同期）
- **Phase 5a**: R1-IM-3（`CLAUDE.md.example` → C-BCP `CLAUDE.md.sample` 移管）
- **Phase 5b**: C-BDC / C-BCP README の実態同期／配布版 `.claude/CLAUDE.md` の Skills 表を 6 件へ（R2-S-1 / R3-S-7）
- **任意（SUGGESTION）**: R3-S-1（空値の OS 差）／R3-S-2（PS 5.1 の CP932 誤読 ― テンプレに注記済み・恒久策は設計判断）／R2-S-2（`start_claude_code.ps1` の `Write-Error`）
- 既存の先送り: §6・§7 の Sonnet 動作検証

---

変更履歴: 初版（2026-07-12・Round 3）。Round 2 の指摘への対応を Fable 5 × 3 観点で検証し、メイン（Opus）が実行再現で典拠確認して統合。CRITICAL 0・IMPORTANT 10・SUGGESTION 7・POSITIVE 6・取り下げ 1。**Round 2 の CRITICAL 3 件は全件解消を実測確認し、3 巡目にして初めて「修正が新たな CRITICAL を生まなかった」ラウンドとなった**。新規指摘は「ゲートが環境依存で fail-open する」クラス（R3-A / R3-B）に集中。**「機構は直すが、それを説明する文書を置き去りにする」パターンが 3 巡連続で継続している**（R3-F / R3-H / R3-I / R3-J）。
