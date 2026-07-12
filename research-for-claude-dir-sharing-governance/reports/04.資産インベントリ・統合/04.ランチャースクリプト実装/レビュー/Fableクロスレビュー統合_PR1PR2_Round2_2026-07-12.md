# Fable 5 クロスレビュー 統合結果（Round 2）― PR #1 / PR #2 の対応検証と再レビュー

> **位置づけ**: PR #1（配布キット grooming）と PR #2（ランチャー）に対する **2 巡目のクロスレビュー**。1 巡目の指摘に対する**対応が正しく行われたか**の検証（Round 2）と、**新規指摘**の両方が対象。メインセッション（Opus）は自らの修正を検証する立場にあり第三者たり得ないため、3 観点を **Fable 5** に委任し、指摘をメインが実ファイル・実行結果で典拠検証して統合した。

## 0. メタ情報

| 項目 | 内容 |
|---|---|
| レビュー対象 | C-BDK `chore/groom-as-share`（PR #1）＋ `feat/launcher-scripts`（PR #2）＋ **両者の統合状態** |
| レビューア | Fable 5 × 3 観点（論理整合性 / 実用性 / 作業指示者ペルソナ・読み取り専用） |
| 統合・検証 | メインセッション（Opus 4.8・実ファイル / 実行再現） |
| レビュー日 | 2026-07-12（Round 2） |
| 1 巡目 | `Fableクロスレビュー統合_PR1配布キット_2026-07-12.md`（PR #1）／`Fableクロスレビュー統合_2026-07-07.md`（PR #2） |
| 対応コミット | PR #1: `ab6436c` / `6271172` / `20bab61`　PR #2: `0a39c88` / `0563abd` |

**件数（統合・検証後）**: CRITICAL 3 / IMPORTANT 11 / SUGGESTION 4 / POSITIVE 4。

**承認判断**: **条件付き GO**。1 巡目の CRITICAL（CR-A/B/C・CR-1/CR-2）は**実測で解消を確認**した。しかし **新規 CRITICAL 3 件が検出され、うち 2 件はメイン（Opus）の実装バグ、1 件はメイン自身の変更が作り込んだコンフリクト**である。**これらを塞ぐまでマージすべきでない**。

## 1. 総括

- **1 巡目の指摘への対応は総じて高品質**。publish ゲート（CR-A）は 3 観点すべてが独立に実測し「未 groomed ref → FAIL exit 1／groomed ref → PASS」を再現。CR-C の修正により **bash 版と PowerShell 版の配布結果が tracked 一覧・blob ハッシュまで完全一致**することも実証された（実用性観点が偽リポジトリへの実 publish で確認）。
- **しかし、修正そのものに新たな欠陥が入った**。3 件の CRITICAL はすべて **1 巡目の修正に起因**する:
  - **CR-a**: ランチャーの行パーサ（IM-4 対応で導入）が、**利用者の typo 1 行で bash 系の起動を不能にする**。glob を正規表現と混同した実装ミス。
  - **CR-b**: publish-share の fail-closed 化（zip 件数照合）を **PowerShell 版だけに実装し bash 版に入れなかった**。bash 経路では展開失敗が素通しされ、**配布先からファイルが黙って消える**。
  - **CR-c**: IM-2 対応で root `.gitattributes` を新設した結果、**PR #2 の同名ファイルと add/add コンフリクト**が発生。さらに**メインは「コンフリクトしない」と PR に記載したまま**（自らの変更が前提を覆したことに気づかず、古い検証結果を再掲載した）。
- **教訓**: 1 巡目で「実装者は実装の外側に盲点ができる」と総括したが、**2 巡目では「修正それ自体が新たな欠陥を生む」ことが実証された**。修正は必ず**修正後の状態で再検証**し、**片方の OS だけ直していないか**を機械的に確認する必要がある。

## 2. 3 観点が独立到達した核心テーマ

| 統合テーマ | 論理整合性 | 実用性 | 作業指示者 | 私の検証 |
|---|---|---|---|---|
| root `.gitattributes` の add/add コンフリクト | I1 | I3 | U-C1 | **CONFIRMED**（CR-c・3 観点全到達） |
| check-assets が working tree で恒常 FAIL | I4 | I2 | ― | **CONFIRMED**（IM-2） |
| `.claude/.gitignore` に `/plans/` が無い | I2 | ― | U-S1 | **CONFIRMED**（IM-5） |
| win-file-encoding rule の適用除外が未対応 | I3 | ― | U-I3 | **CONFIRMED**（IM-6） |
| 配布先の統制ファイルの存在を誰も検査しない | S2 | S1 | ― | **CONFIRMED**（IM-7） |
| 配布版 `.claude/CLAUDE.md` の Skills 表が 2/6 | S4 | S2 | U-S2 | **CONFIRMED**（S-1） |

---

## 3. CRITICAL（新規・すべてメインの修正に起因）

### CR-a ランチャーの行パーサが不正なキー 1 行で bash 系の起動を不能にする（PowerShell 版は正常＝OS 非対称）
**統合元**: 実用C1（実行再現）
**私の検証（CONFIRMED・再現済み）**:

`setup-environment.sh` の環境変数名バリデーションを **glob と正規表現を混同して実装した**（メインの実装ミス）:

```bash
case "${_key}" in
  [A-Za-z_][A-Za-z0-9_]*) ;;   # ← glob。末尾の * は「空白を含む任意文字列」にマッチする
  *) continue ;;
esac
```

- **`MAX THINKING TOKENS=32000`**（利用者がアンダースコアを忘れた typo）→ `M`・`A` が先頭 2 文字にマッチし、残り `X THINKING TOKENS` が `*` に吸われて**検査を通過** → `export` が `not a valid identifier` で失敗 → **`set -euo pipefail` 下で source が中断し、claude が起動しない**（実測: 「起動成功」メッセージが出ない）。
- **`A=1`**（1 文字キー）→ glob は 2 文字目を**必須**とするため**不マッチ → 無言で破棄**。PowerShell 版（正規表現 `^[A-Za-z_][A-Za-z0-9_]*$`）は正しくロードする＝**同じ custom.env が OS で異なる結果になる**。

**帰結**: 個人ファイルの typo 1 行で、**bash 系利用者（macOS / Git Bash）がランチャーから起動できなくなる**。コメントに書いた「不正名の export で落とさない」という目的が達成されていない。
**修正案**: `case` を bash の正規表現マッチに置換する（bash 4.4+ 前提なので使用可）:
```bash
[[ "${_key}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
```
これで空白キーの拒否と 1 文字キーの受理が PowerShell 版と揃う。

---

### CR-b bash 版 publish-share が payload の展開失敗を検知せず、部分 payload のまま publish して配布先からファイルを消す
**統合元**: 実用C2（実行再現）
**私の検証（CONFIRMED）**:

1 巡目で「Windows の tar が日本語ファイル名を取りこぼす」問題に対し **zip 化＋展開ファイル数の照合（fail-closed）を PowerShell 版だけに実装し、bash 版には入れなかった**（メインの対応漏れ）。

- `publish-share.sh` L68: `git archive "$REF" .claude | tar -x -C "$tmp"` ―― **パイプラインの成否を検査していない**（`set -uo pipefail` に `-e` は無い）。かつ **PS 版 2-b 相当の件数照合が無い**。
- 実用性観点の実測: payload に symlink エントリ（mode 120000）を含む ref を publish すると、`tar: Cannot create symlink... Exiting with failure status` とエラーが出たまま **check-assets PASS → publish 続行 → exit 0**。該当ファイルは配布先に存在しない。
- **ミラー処理は「payload に無い」ファイルを配布先から削除する**ため、展開に失敗したファイルは**配布先で消失する**。

**帰結**: `ab6436c` が「fail-closed」を謳って塞いだはずの故障クラスが、**bash 経路には開いたまま**。コミットメッセージにも「PS 版限定」とは書いていない。
**修正案**: (1) パイプラインの成否を検査（`pipefail` 有効なので戻り値で拾える）。(2) PowerShell 版と同じ件数照合（`git ls-tree -r --name-only $REF -- .claude | wc -l` と `find "$tmp/.claude" -type f | wc -l` の一致）を追加。(3) 併せて check-assets に「payload ref に mode 120000（symlink）が有れば FAIL」を足すと、両版の根を断てる。

---

### CR-c root `.gitattributes` が PR #1 × PR #2 で add/add コンフリクトし、かつ PR の「コンフリクトしない・実測済み」記述が虚偽になっている
**統合元**: 論理I1 ／ 実用I3 ／ 作業U-C1（**3 観点全到達**）
**私の検証（CONFIRMED）**:

- `git merge-tree --write-tree <PR#1適用後> feat/launcher-scripts` → **`CONFLICT (add/add): Merge conflict in .gitattributes`・exit 1**（実測）。
- 原因: develop に `.gitattributes` は無く、**chore（`6271172`＝メインの IM-2 対応）と feat（既存）が独立に新設**した。内容が異なるため自動マージできない。
- **1 巡目の修正前は「コンフリクトなし」だった**。**メイン自身の修正がコンフリクトを作った**。
- **さらに問題**: メインは PR #1 コメント（17:17 JST）と PR #2 本文に「**PR #2 とのコンフリクトは発生しないことを `git merge-tree` で実測済み**」と記載している。しかし `.gitattributes` を追加した `6271172` は **16:38 JST** ―― **既にコンフリクトする状態になった後に、古い検証結果を「実測済み」として再掲載した**（作業指示者観点がタイムスタンプまで追って指摘）。
- **これは CR-A で問題視した「機械的裏付けのない安全宣言」と同型の過ち**である。

**帰結**: マージ操作者が記述を信じて自動マージを期待 → 実際にはコンフリクト → その場の判断で **feat 版を採用すると `scripts/*.sh text eol=lf` が失われ、IM-2（autocrlf=true の Windows clone で publish パイプラインが CRLF 死する）が無言で回帰する**。
**内容の包含関係（3 観点が逐条確認）**: **chore 版は feat 版の厳密な上位集合**（feat の全行＋`/scripts/*.{sh,ps1,py}`・`/.claude/skills/**` の 5 行）。重複パスの eol 指定は完全一致。
**修正案**: **feat 側の `.gitattributes` を chore 版と同一内容に揃えて、コンフリクト自体を消す**（add/add は内容が完全一致すれば自動解決される）。手順書で「chore 版を採れ」と指示するより、**機構で衝突を消す方が確実**（本プロジェクトの「運用規律でなく物理境界で防ぐ」原則に沿う）。あわせて **PR の虚偽記述を訂正する**。

---

## 4. IMPORTANT

### IM-1 ルート一致検査（`20bab61`）がパス別名を跨ぐと正しい配布先を今も誤拒否する ― メインの修正が不完全
**統合元**: 実用I1（実行再現）
**私の検証（CONFIRMED・再現済み）**:

`20bab61` は「Git Bash では `rev-parse --show-toplevel` が `C:/...` を返すが `pwd` は `/c/...` を返す」というバグを修正したが、**MSYS のマウント別名までは解決していない**:

```
指定パス cd+pwd    : /c/Users/empty/AppData/Local/Temp/claude/.../aliastest
toplevel を cd+pwd : /tmp/claude/.../aliastest          ← MSYS が /tmp へ正規化
→ 不一致 → exit 2（正しい配布先なのに拒否）
```

**macOS でも同型で必ず再現する**（`/tmp` → `/private/tmp` の symlink）。「一時ディレクトリで検証 run する」という運用が**最初に踏む**。
**帰結**: fail-closed なので壊しはしないが、正当な配布先で publish 不能。
**修正案（根本解）**: **パス文字列の比較をやめる**。`git -C "$SHARE_BODY" rev-parse --show-prefix` が**空文字を返すか**で判定する（空＝リポジトリのルート）。実測で `[]`（空）を確認済み。パス形式問題が消滅し、bash / PowerShell 両版を同じ 1 行にできる。

### IM-2 check-assets の成果物検査が working tree に対して恒常 FAIL する ― CR-A 対応の副作用
**統合元**: 論理I4 ／ 実用I2
**私の検証（CONFIRMED・再現済み）**:

CR-A 対応で成果物検査を**実体基準**にしたが、**README が案内する「working tree に対して実行する手順」と衝突する**:

```
README L90: bash scripts/check-assets.sh .   # 機械チェック（CI 可）
→ [FAIL] .claude/work が配布ペイロードに含まれている → exit 1
```

`.claude/work` は **gitignored で payload には乗らない**。FAIL メッセージ「配布ペイロードに含まれている」は working tree に対しては**事実に反する**。キット自身の運用が `work/` を作るため、**開発者の日常状態でほぼ常時 FAIL する**。
**帰結**: 「常に赤いゲート」は "FAIL 慣れ" を誘発し、**本当の混入時に無視される**（ゲートのオオカミ少年化）。
**修正案**: 成果物検査を**個人ファイル検査と同じ二層基準**に揃える。既存の `check_personal` が既にこの構造を持っている:
- **git リポジトリ**（= working tree 検査）→ tracked なら **FAIL** / untracked で実在なら **WARN** / 不在なら PASS
- **非 git**（= publish 時に取り出した payload 実体）→ 実在なら **FAIL**（現行どおり。CR-A の要求を温存）

これで publish 経路の fail-closed 性を保ったまま、日常の誤検知が消える。

### IM-3 `scripts/*.ps1` が BOM 無し ― 自ら宣言した「PowerShell は UTF-8 BOM + CRLF」方針と不一致
**統合元**: 実用I4
**私の検証（CONFIRMED）**: `scripts/publish-share.ps1` / `check-assets.ps1` 等の blob 先頭は `3c 23`（**BOM 無し**）。一方 `.claude/launcher/*.ps1` は `ef bb bf`（BOM 有り）。メインが新設した root `.gitattributes` のヘッダは「PowerShell: UTF-8 BOM + CRLF（Windows PowerShell 5.1 での日本語コメント文字化けを避ける）」と**宣言している**。
**帰結**: Windows PowerShell 5.1 では BOM 無し UTF-8 が ANSI と誤解釈され、日本語コメント・メッセージが化ける（後続バイトが引用符を食えば構文エラーにもなり得る）。宣言と実体の乖離は IM-6（win-file-encoding rule）の混乱も再誘発する。
**修正案**: `scripts/*.ps1`（4 本）に BOM を付与し launcher と方針を統一する。pwsh 7 専用と割り切るなら、`.gitattributes` の宣言と README を「scripts/ は PowerShell 7+ 専用」に改める。

### IM-4 撤回済みドクトリンが `launcher-implementation-plan.md` の 3 箇所に残存 ― メインの IM-1 対応が不完全
**統合元**: 作業U-I1
**私の検証（CONFIRMED）**: メインは §1/§5 を訂正したが、**L47 / L85 / L95** を見落とした:

- L47「秘匿値はハードコードしない（固定 env は非秘匿のものだけ。**秘匿は custom.env 経由**）」
- L85 / L95「認証は **custom.env のトークン供給に一本化**、で確定」

これらは**同一文書の L26 / L68 / L74 の撤回宣言**（「custom.env は機微情報の格納先ではない」「読み込まずに警告する」）と**正面矛盾**する。**正本と規定した設計書（IM-8）の「確定事項」節が、実装が拒否する運用を「確定」と記載している**。
**帰結**: 機構ガード（分類A キーの読み込み拒否）があるため実害は水際で止まるが、1 巡目 IM-1 で「PR 前必須」とされた同一クラスの欠陥の取り残し。
**修正案**: L47 / L85 / L95 を判定木準拠（分類A は OS env）へ訂正、または「→ §6-bis で撤回」注記を付す。

### IM-5 配布先セーフティネット `.claude/.gitignore` に `/plans/` が無い ― IM-6 と同型の取り残し
**統合元**: 論理I2 ／ 作業U-S1
**私の検証（CONFIRMED）**: メインは `0563abd` で `/reports/` を追加したが、**`/plans/` を入れなかった**。一方:
- 開発リポの root `.gitignore` は `.claude/plans/` を持つ
- `check-assets` の 2-c は `.claude/plans` を FAIL 検査する
- **配布先セーフティネット（`.claude/.gitignore`）だけが `/plans/` を持たない**

**帰結**: 利用者が submodule 内 `.claude/plans/` に作った計画ファイルが `git add -A` 一発で public な C-BDC へ混入する経路が残る（IM-6 が塞いだのと**同じ穴の隣**）。
**修正案**: `.claude/.gitignore` に `/plans/` を追加。あわせて「**成果物クラスの正本リストは check-assets の 2-c 配列とし、root / `.claude` 両 `.gitignore` はそれに追随する**」旨をコメントで明記し、三重定義の追随漏れを構造的に抑止する。

### IM-6 win-file-encoding rule の適用除外が未対応 ― 先送り分類が不当。かつ rule は payload で全利用先に配布される
**統合元**: 論理I3 ／ 作業U-I3
**私の検証（CONFIRMED）**:
- rule の frontmatter は `paths: ["**/*.ps1", ...]` ＝ `.ps1` を編集すれば**必ずロードされる**。本文は「既存編集: 最後に `--to-win` で **CP932/CRLF へ戻す**」と指示する。
- 本キットの `.ps1` は **UTF-8 BOM + CRLF が確定方針**。converter は **BOM を除去する**ため正面衝突する。
- **1 巡目はこれを「レーンB（案X 実装時）」に先送りしたが、案X と依存関係が無い機械的修正**であり、束ねる論理的根拠が無い（論理整合性観点の指摘）。
- **さらに射程が広い**: この rule は `.claude/rules/` 配下＝**payload に同乗して全利用先に配布される**。publish 後は**利用者のセッションでも** UTF-8 な `.ps1` に CP932 化を誘導する。1 巡目は開発リポ内の危険としてのみ評価しており、**配布による射程拡大を見落としていた**。
**修正案**: rule の「適用しないケース」に「**本キットの `scripts/` / `.claude/launcher/`（UTF-8 (BOM) + 改行は `.gitattributes` で管理）**」を追記する。**publish 前（Phase 5b 前）の必須項目**としてフェーズ表に載せる。

### IM-7 配布先の統制ファイルの「存在」を誰も検査しておらず、keep-list も非対称
**統合元**: 実用S1 ／ 論理S2
**私の検証（CONFIRMED）**:
- `check-assets` は payload に `.claude/.gitignore` / `.claude/.gitattributes` が**有るか**を検査しない（`.claude/CLAUDE.md` だけ不在 FAIL）。
- publish-share のミラー keep-list は `.git` / `.gitignore` / `README.md` / `LICENSE` ―― **`.gitattributes` を守らない**。
**帰結**: 将来これらを欠いた ref（例: chore 単独時点の tag）を publish すると、**配布先の改行保護だけが黙って消える**（CR-1 の逆行）。「payload に無いと配布先から消える」というクラスの検査が `.claude/CLAUDE.md` にしか適用されていない。
**修正案**: check-assets に「`.claude/.gitignore` / `.claude/.gitattributes` 不在 → FAIL」を追加し、keep-list にも `.gitattributes` を足して二重化する。

### IM-8 `clean-test-env.ps1` が呼び出し元セッションに削除済みの `CLAUDE_CONFIG_DIR` を残す（bash 版には無い副作用）
**統合元**: 実用I5（実行再現）
**検証（CONFIRMED・実用性観点が実測）**: `clean-test-env.ps1` は `$env:CLAUDE_CONFIG_DIR = $cfg` を設定するが、**終了時に復元しない**。同一 pwsh セッションで実行すると、テスト終了後も**削除済みパスを指したまま残存**する（`exists=False` を実測）。bash 版は子プロセスなので無害。
**帰結**: テスト後、同じウィンドウで素の `claude` を起動すると**本人の設定・認証を見失う**。原因が見えにくい。
**修正案**: `finally` で元値へ復元するか、子プロセスで隔離実行する。

### IM-9 `publish-plugin.sh` に publish-share で塞いだ欠陥がそのまま残存
**統合元**: 実用I6
**検証（CONFIRMED）**: `REF="main"`（既定 main を維持＝CR-A 未適用）／`DEV_ROOT="$(git rev-parse --show-toplevel)"`（CWD 依存＝IM-8 未適用）／`git add -A / commit / push` の exit code 無検査（IM-7 未適用）／`.git` のルート一致検査なし（CR-B 未適用）。
**帰結**: 現状は README で「ドラフト・未運用」と明記され、既定の `plugin/` ディレクトリも不在のため**実害は保留**。だが「`scripts/` に置かれた実行可能なドラフト」が publish-share の修正意図と非対称なまま残る。
**修正案**: publish-share と同じ 4 点を機械的に移植する（運用開始前でよいが、PR に申し送りを残す）。

### IM-10 PR #1 本文が実体と乖離したまま（1 巡目 IM-5 の対応がコメント止まり）
**統合元**: 作業U-I2
**検証（CONFIRMED）**: PR #1 本文は「変更」3 点＋「検証: `check-payload` で FAIL=0」のみ。実体は **14 commits / 51 files** で、`check-payload` は改名済み（**本文の検証手順は実行不能**）。説明外変更はコメント 2 件で追認したが、**本文は未改訂**。
**帰結**: merge commit 方針のため、履歴から辿る第一資料は PR 本文。コメントまで読まないと「承認したもの」を誤認する。
**修正案**: 本文に「実体は 14 commits。詳細と追認はコメント 2 件を参照」の 1 段落と `check-payload` → `check-assets` の訂正を入れる。

### IM-11 README 群の同期がフェーズ表に計上されていない（統合後の姿を誰も書いていない）
**統合元**: 論理I5 ／ 作業U-I4
**検証（CONFIRMED）**:
- C-BDK README は PR #1 で全面改訂されたが、**launcher（PR #2 の資産）への言及がゼロ**。構成ツリーにも `start_claude_code.*` / `.claude/launcher/` / `docs/` が無い。**どちらの PR も統合後の姿に同期していない**。
- **C-BDC README は「初期スキャフォールド（各フォルダは空）」のまま**（実態は `781747b` で 6 skills 等を配布済み）。しかも **publish-share の keep-list で保護されるため C-BDK からは構造的に更新できない**（1 巡目 IM-13 は「C-BDK 移管」と割り当てたが、**その割当自体が実行不能**）。
**修正案**: 確定書のフェーズ表に「Phase 3: C-BDK README の launcher 同期」「Phase 5b: C-BDC / C-BCP README の実態同期（直コミット）」を完了条件として明記する。

---

## 5. SUGGESTION

- **S-1**: 配布版 `.claude/CLAUDE.md` の Skills 表が **2 件のまま**（payload は 6 skill を配布）。README 側は同期済みで、**利用先にロードされる側だけが古い**（3 観点が到達）。
- **S-2**: `start_claude_code.ps1` のガードが `Write-Error` × `$ErrorActionPreference='Stop'` ―― **publish-share.ps1 自身のコメントが禁止したパターン**で自家撞着（機能は満たすが表示が例外スタック調に崩れる）。`Write-Host` + `exit` へ統一を。
- **S-3**: symlink 混入 payload の挙動差 ―― bash は tar 失敗→無言欠落（CR-b）、PowerShell は「ターゲットパス文字列を中身とする通常ファイル」として配布（データ化け）。check-assets に「`git ls-tree -r <ref>` に mode 120000 が有れば FAIL」を足すと**両版の根を断てる**。
- **S-4**: 配布側 `.claude/.gitattributes` が **skills 同梱スクリプトを対象外**にしている（`/launcher/*` のみ）。skills に `.sh` が入った時点で CR-1 / IM-3 と同じ故障クラスが配布側で再発芽する。

## 6. POSITIVE

- **P-1 両 OS の配布結果が bit 等価**: bash（tar 経路）と PowerShell（zip 経路）で同じ ref を別々の偽配布先へ publish し、**tracked ファイル一覧と blob ハッシュが完全一致**（日本語ファイル名 3 件を含む）。CR-C の「セマンティクス統一」は言葉どおり実現されている。
- **P-2 ゲートの exit code 連鎖が全経路で正しい**: check-assets FAIL → publish exit 1 → **配布先無傷**、push 失敗 → exit 1 ＋ 回復手順の案内 ＋ ローカルコミット温存 ―― を bash / PowerShell 双方で実測確認。CR-A の多段ゲートは設計どおり機能する。
- **P-3 実体基準への転換は論理的に正しい**: 「追跡解除したから大丈夫、は ref を取り違えた瞬間に崩れる。実体で検査する」は CR-A の根本原因（状態依存の防御）を機構で殺す設計。**ただし working tree への適用は誤り**（IM-2）であり、二層基準への修正が必要。
- **P-4 CR-C 対応が指摘の要求を超えた**: robocopy のセマンティクス修正に留まらず、**Windows の tar が UTF-8 日本語ファイル名を黙って取りこぼす欠陥**（放置すると配布先で削除事故）を自主的に発見し zip 化 + fail-closed で封じた。**ただし bash 版に入れ忘れた**（CR-b）のが痛い。

## 7. 取り下げ・誤検知

**該当なし**。3 観点の事実系指摘はすべて典拠検証を通過した。

> ただし **IM-3（PS 5.1 の文字化け）と IM-1 の macOS ケース**は、実機が本環境に無いため**確証済みメカニズムからの外挿**（実用性観点が明示）。実装時に実機確認できるとなお良い。

## 8. メイン（Opus）の過ちの総括 ― 2 巡目で判明したこと

1 巡目の教訓は「**実装者は実装の外側（別 OS の実行経路・配布先で起きること）に盲点ができる**」だった。2 巡目では**さらに厳しい事実**が判明した:

| # | 過ち | 性質 |
|---|---|---|
| 1 | **glob を正規表現と混同**（CR-a） | 単純な実装ミス。だが**利用者の typo 1 行で起動不能**という致命的な帰結 |
| 2 | **fail-closed を PowerShell 版だけに実装**（CR-b） | **片肺修正の再発**。1 巡目で CR-1 が片肺だったことを反省したのに、同じ過ちを繰り返した |
| 3 | **自分の変更がコンフリクトを作ったことに気づかず「コンフリクトしない・実測済み」と PR に再掲載**（CR-c） | **検証の前提が自分の変更で覆ったのに、古い結論を使い回した**。CR-A で問題視した「機械的裏付けのない安全宣言」と同型 |
| 4 | **ルート一致検査の修正が不完全**（IM-1） | 「直した」と報告した箇所が**まだ壊れている**。パス比較という筋の悪い方法に固執し、`--show-prefix` という根本解に気づかなかった |
| 5 | **CR-A 対応の副作用を検証しなかった**（IM-2） | 実体基準化が **README の公式手順を壊す**ことに気づかなかった |
| 6 | **IM-1 対応の見落とし**（IM-4）・**`/plans/` の漏れ**（IM-5） | 網羅性の欠如。逆引き照合をしていれば防げた |

**再発防止**:
- **修正後の状態で再検証する**（修正前の検証結果を使い回さない）。特に「コンフリクトしない」等の**構造的な主張は、自分の変更のたびに再実行する**。
- **片方の OS だけ直していないか**を機械的に確認する（bash / PowerShell の対称性チェックをリスト化する）。
- **修正が既存の手順・文書を壊さないか**を確認する（今回は README の check-assets 手順）。
- **正規表現と glob を混同しない**（bash の `case` は glob。正規表現は `[[ =~ ]]`）。

---

## 9. 次アクション

### マージ前に必須（CRITICAL）

| ID | 対応 | 対象 |
|---|---|---|
| **CR-a** | `setup-environment.sh` の `case` glob を `[[ =~ ]]` の正規表現へ | PR #2（feat） |
| **CR-b** | `publish-share.sh` に展開成否の検査＋件数照合を追加（PS 版と対称化） | PR #1（chore） |
| **CR-c** | feat 側の `.gitattributes` を chore 版と同一内容に揃えてコンフリクトを消す＋**PR の虚偽記述を訂正** | PR #2（feat）＋ GitHub |

### マージ前が望ましい（IMPORTANT）

| ID | 対応 | 対象 |
|---|---|---|
| **IM-1** | ルート一致検査を `rev-parse --show-prefix` の空判定へ（両版・根本解） | PR #1 |
| **IM-2** | check-assets の成果物検査を二層基準へ（git=tracked 基準 / 非 git=実体基準） | PR #1 |
| **IM-5** | `.claude/.gitignore` に `/plans/` を追加 | PR #2 |
| **IM-4** | `launcher-implementation-plan.md` L47/L85/L95 の撤回済みドクトリンを訂正 | PR #2 |
| **IM-6** | win-file-encoding rule に適用除外を追記（**publish 前必須**） | PR #1 |
| **IM-7** | check-assets に統制ファイルの不在 FAIL ＋ keep-list に `.gitattributes` | PR #1 |
| **IM-3** | `scripts/*.ps1` に BOM 付与（方針統一） | PR #1 |
| **IM-10** | PR #1 本文の改訂 | GitHub |

### マージ後・レーンB

- **IM-8**（clean-test-env.ps1 の env 復元）／**IM-9**（publish-plugin.sh への横展開）／**IM-11**（README 群の同期をフェーズ表へ）／SUGGESTION 各件
- 既存の先送り: **CR-D**（root `CLAUDE.md` の書き起こし）／**IM-3 1 巡目**（`CLAUDE.md.example` の C-BCP 移管）

---

変更履歴: 初版（2026-07-12・Round 2）。PR #1 / PR #2 の 1 巡目指摘への対応を Fable 5 × 3 観点で検証し、メイン（Opus）が実行再現で典拠確認して統合。CRITICAL 3・IMPORTANT 11・SUGGESTION 4・POSITIVE 4・取り下げ 0。**新規 CRITICAL 3 件はすべてメインの修正に起因**（実装バグ 2・自ら作り込んだコンフリクト 1）。§8 に過ちの総括と再発防止を記録。
