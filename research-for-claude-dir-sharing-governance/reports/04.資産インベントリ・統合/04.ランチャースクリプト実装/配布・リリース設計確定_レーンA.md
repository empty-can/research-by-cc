# ランチャー配布・リリース設計 確定書（レーンA）

> Fable クロスレビュー統合（`レビュー/Fableクロスレビュー統合_2026-07-07.md` §3 CRITICAL・§9 レーンA）を受けた**設計判断・計画の確定**。実装（レーンB）は C-BDK セッションへ移管する際の指示書となる。判断規則: 設計論は本 W-RBC セッションで確定／機械的修正は C-BDK 移管。

## 0. 前提: 3リポの CLAUDE.md / 統制ファイル 役割分担（実測に基づく現状）

| 資産 | C-BDK（`<Dev>` base-dev-kit-for-cc） | C-BDC（`<Share.claude>` basic_dot_claude） | C-BCP（`<Share>` basic_cc_project） |
|---|---|---|---|
| **root `CLAUDE.md`** | 有（**雛型宣言と開発リポ固有情報が混線**＝要是正） | ―（ルート＝`.claude` 中身） | **無**（雛型段階では置かず、利用者がコピー先で作成 / `CLAUDE.md.sample`） |
| **`.claude/CLAUDE.md`（配布共通指示）** | **chore/groom-as-share にのみ有**（develop/main に無） | 有（＝chore 由来の複製・完成度高） | （C-BDC submodule 経由で保持） |
| **`.gitignore`（ランチャー個人実体除外）** | ルートに有（F1・`.claude/` 外＝**配布されない**） | **無**（4行・個人実体除外なし＝CR-1） | ― |
| **`.gitattributes`（改行固定）** | ルートに有（launcher パス限定・`.claude/` 外＝**配布されない**） | **無**（CR-1） | 無 |

**含意**: 配布共通指示（`.claude/CLAUDE.md`）とリポ固有情報（README）の分離は **C-BDC/C-BCP 側で既に正しく確立**。是正が必要なのは (a) C-BDK root CLAUDE.md の混線（§5）、(b) 統制ファイルが `.claude/` 外にあり配布されない（§2）、(c) 配布共通指示が develop/main に無い（§3）。

---

## 1. CR-1: 配布先セーフティネットの搬送方式【確定】

**方針**: 統制ファイルを `.claude/` 配下に置き **publish-share の payload に自動同乗**させる（`.claude/` 相対パスなので C-BDC ルートでそのまま機能する）。ルート直下物は C-BCP 直コミットの別レール。

### 追加ファイル（C-BDK・レーンB 実装）

**`.claude/.gitignore`（新規）**:
```gitignore
# ランチャーの個人実体（テンプレから作成・コミットしない）。配布先 C-BDC でも有効化するため .claude/ 配下に置く
/option-settings.sh
/option-settings.ps1
/custom.env
```

> **【レーンB 実装時の補正・2026-07-12】上記3行だけでは配布先で回帰が出るため拡張した。**
> publish-share は keep-list で C-BDC の既存 `.gitignore` を残すが、**その直後の `cp -R "$tmp/.claude/." "$SHARE_BODY/"` が payload 版で上書きする**。C-BDC の現行 `.gitignore` は `settings.local.json` / `CLAUDE.local.md`（＋ `**/` 版）の4行を持っており、上記3行だけを置くと**配布のたびに個人設定の除外が失われる**。
> よって `.claude/.gitignore` には「配布先で必要な除外の全量」を持たせる必要がある（**ここに無い行は publish のたびに消える**）。実装では既存4行を保持し、launcher 個人実体3行と成果物クラスを追加した。
> 検証: 旧 `.gitignore` の全パターンが新 `.gitignore` に包含されることを差分照合で確認済み（回帰ゼロ）。

> **【Round 2 / Round 3 での更新・2026-07-12】**
> - **`/reports/` と `/plans/` も本ファイルに入れた**（R2-IM-6 / R2-IM-5）。当初「`/reports/` は CR-2・PR#1 の担当領域だから入れない」としたのは**判断の誤り**。C-BDC は submodule として**利用先の `.claude/`** になるため、**利用者が配布先で作った** reports / plans が `git add -A` 一発で public リポへ混入する経路が残っていた。「開発リポの成果物を配らない（追跡解除）」と「配布先で生まれる成果物を公開しない（gitignore）」は**独立した問題**である。
> - 現在の内容は **成果物クラス 6 種**（`/reports/` `/plans/` `/work/` `/workspace/` `/agent-memory-local/` `work_instructions.txt`）＋ 個人設定 4 行 ＋ launcher 個人実体 3 行。**正本は `check-assets` の 2-c 配列**であり、root と `.claude/` 双方の `.gitignore` はこれに追随させる（三者一致を機械照合で確認済み）。
> - なお grooming 対象の reports は **33 件**（develop 基準）。旧記述の「29 件」は feat ブランチ時点の数で**誤り**。

**`.claude/.gitattributes`（新規）**:
```gitattributes
# 既定を「全ファイル LF」に倒し、CRLF が要る launcher/*.ps1 だけを後勝ちで例外にする
* text=auto eol=lf

/launcher/*.ps1               text eol=crlf
/launcher/*.ps1.template      text eol=crlf
/launcher/*.sh                text eol=lf
/launcher/*.sh.template       text eol=lf
/launcher/custom.env.template text eol=lf
```

> **【Round 3 での更新・2026-07-12】** 先頭の `* text=auto eol=lf` は **R3-B で追加**した。当初のパス列挙方式（`/launcher/*` だけを指定）では、**skills 同梱の `.sh` のように後から増えた配布物が保護対象から漏れ**、配布先の Windows clone で CRLF 化して壊れる（CR-1 と同じ故障クラスが「指定漏れ」という形で再発芽する）。`text=auto` なのでバイナリは Git が検出して変換しない。R2-S-4 も同時に解決した。

- publish-share のミラーは keep-list（`.git` / `.gitignore` / **`.gitattributes`** / `README.md` / `LICENSE`）を削除から守り、他を rm → `cp -R` する。keep-list は「**削除から守る**」意味であって「payload より優先する」意味ではなく、**直後の cp が payload 版で上書きする**。→ 以後 C-BDC の両ファイルの正本は C-BDK payload に一元化される。
  （`.gitattributes` の keep-list 追加は R2-IM-7。「payload に無いと配布先から消える」クラスの二重化。）
- **⚠ `.gitattributes` は「二重防御」にならない**（Round 3 セルフレビュー F1）。`.gitattributes` は**深い階層が勝つ**ため、`.claude/.gitattributes` が存在する限り **C-BDK ルートの `/.claude/**` 行は効かない**（加算ではなく**上書き**）。launcher / skills の改行方針を変えるときは **`.claude/.gitattributes` を直す**こと。ルート側の `/.claude/**` 行は「`.claude/.gitattributes` を持たない ref」のための保険として残す。
  一方 **`.gitignore` は加算的**なので二重防御が実際に成立する（`.claude/.gitignore` を消しても root だけで個人実体・成果物が守られることを実測確認済み）。**この 2 つは挙動が違う**。
- **ルート直下物（`start_claude_code.{sh,ps1}`）の eol** は payload に乗らないため、C-BCP ルートへ直コミットする `.gitattributes`（`/start_claude_code.sh text eol=lf`・`/start_claude_code.ps1 text eol=crlf`）で担保（§6 Phase 5a）。

---

## 2. CR-2: リリース前提条件【確定】

**確定事項**: **PR#1（chore/groom-as-share → develop・merge commit）またはその等価 grooming を、リリース（Phase 4 以降）の前提条件に格上げする**。

> **マージ方式は merge commit（squash 禁止）**。squash するとマージ元ブランチの履歴が消え、レビュー報告書・PR コメントが SHA で参照している修正コミット群（`ab6436c` / `20bab61` / `0df64e7` / `debb531` / `16dba53` / `c566685` 等）を develop の履歴から辿れなくなる。初版は「squash 推奨」と記載していたが、作業指示者の確定指示により**撤回**した（2026-07-12）。

**根拠（実測）**: chore/groom-as-share **だけ**が配布 ready ―― (a) `.claude/reports/` が **0 件**（develop/feat は 29 件追跡）、(b) `.claude/CLAUDE.md`（配布共通指示）を**保有**（develop/main/feat は不保有）。この状態を develop に載せずに publish すると:
- reports 群が C-BDC へ配布される（check-assets は reports を検査せず PASS）。
- C-BDC の `.claude/CLAUDE.md` が削除される（keep-list に CLAUDE.md 無し・check-assets は WARN 止まりで publish 続行）。

**check-assets 強化（レーンB 実装・W-RBC scripts 正本 → C-BDK 配布分）**:
- `.claude/reports/` が payload に実在 → **FAIL**（現状: 検査なし）
- `.claude/CLAUDE.md` 不在 → **FAIL**（現状: WARN。配る構成を採用済みのため格上げ）
- `custom.env` / `option-settings.{sh,ps1}` が payload に実在 → **FAIL**
- publish ref は「リリースタグ済みの groomed ref のみ」を手順書に明文化。

---

## 3. IM-8: 設計書の正本【確定】

- **正本 = C-BDK `docs/launcher/`**（実装と同一 PR で共進化する側）。
- W-RBC `reports/04/…/{構成設計,実装計画}.md` の冒頭に「**正本は C-BDK `docs/launcher/`。本書は 2026-07-05 時点スナップショット（調査ジャーナル）・以後更新しない**」バナーを付す。
- W-RBC `research-for-claude-dir-sharing-governance/CLAUDE.md` 成果物表の「実体スクリプトは C-BDK が正本」を「**実体スクリプトおよび設計書2点は C-BDK が正本**」へ拡張。
- 今回検出の §8 差分（grep vs check-ignore 等）は正本側で事実確定。

---

## 4. IM-1/2/9: 実装計画・CLAUDE.md の訂正方針【確定】

- **IM-1**（撤回済み「custom.env=秘匿格納」残存）: 実装計画 §1/§5 の該当箇所を判定木準拠に書換 or 「→§6-bis で撤回」注記。安全ドクトリンに関わるため PR 前必須。
- **IM-2**（publish 経路誤記）: §1/§6-bis#1/§8 の「publish-share で `start_claude_code.*`→C-BCP」を「`.claude/launcher/*`→publish-share（C-BDC）／`start_claude_code.*`→C-BCP 直コミット別レール（Phase 5a）」へ訂正。
- **IM-9**（C-BDK root CLAUDE.md §ディレクトリ構造の陳腐化・`.env` 記述の分類A衝突）: §5 の役割確定後に「配布対象/開発専用」軸で改訂（下記）。

### §ディレクトリ構造 改訂案（C-BDK root CLAUDE.md）

| 区分 | 資産 | 配布経路 | Git 追跡 |
|---|---|---|---|
| **配布対象（payload）** | `.claude/`（settings/rules/skills/agents/output-styles/templates/**launcher** の追跡ファイル・**`.claude/CLAUDE.md`**・`.claude/.gitignore`・`.claude/.gitattributes`） | publish-share → C-BDC | 追跡 |
| **配布対象（ルート別レール）** | `start_claude_code.{sh,ps1}`・C-BCP 用 `.gitattributes` | C-BCP 直コミット | 追跡 |
| **開発専用（非配布・追跡）** | `docs/`（恒久設計文書）・`scripts/`（配布/保守ツール）・root `CLAUDE.md`・`CLAUDE.local.md.example`・`.env.example`・`.mcp.json`・ルート `.gitattributes`/`.gitignore` | ― | 追跡 |
| **開発専用（非配布・非追跡）** | `.claude/reports/`（セッション成果物）・`.claude/work/`・`.claude/workspace/`・個人実体（`custom.env`/`option-settings.*`/`settings.local.json`/`CLAUDE.local.md`） | ― | .gitignore |

- `.env`＝「機密情報の置き場」の旧記述は**削除**し、分類A整合（「機微は OS 環境変数。ランチャーファイルにも `.env` にも書かない」）へ差替。
- 「ランチャーの使い方」節（テンプレ→実体コピー手順＋foreground/background 注意）を追加。

---

## 5. IM-10: root CLAUDE.md の役割【確定: 案X＝開発リポ専用に純化（2026-07-07）】

**確定している部分**:
- **配布共通指示の正本 = C-BDK `.claude/CLAUDE.md`**（現状 chore のみ→ PR#1 で develop/main へ）。C-BDC はその複製。この設計は既に良質で維持。
- 雛型ルートの CLAUDE.md は **C-BCP** が担う（`CLAUDE.md.sample` / コピー先新規作成）。

**判断が要る点**: C-BDK **root** `CLAUDE.md` は現状「新規プロジェクトにコピーして使う雛型」を名乗りつつ、マシン固有パス（`C:\workspace\claude-doc-repositories`）・C-BDK 固有 MCP ポリシーを含み混線している。どちらに純化するか:

- **案X（推奨）: C-BDK root CLAUDE.md を「C-BDK 開発リポ専用文書」に純化**。雛型宣言を撤去し、§ディレクトリ構造・配布対象/開発専用・開発フロー・固有 MCP ポリシーに徹する。エンドユーザ向け雛型は C-BCP に一本化。
  - 長所: 役割が3リポで一意に定まり二重管理が消える。C-BDC/C-BCP の既存設計と完全整合。
  - 短所: 「base-dev-kit を直接コピーして使う」旧ルートを C-BCP 利用へ寄せる方針転換になる。
- **案Y: root CLAUDE.md に雛型性を残し、開発リポ固有情報だけ別セクション/別ファイルへ隔離**。
  - 長所: C-BDK 直接コピー運用を温存。
  - 短所: 「雛型としての root CLAUDE.md」が C-BCP と二重に存在し続ける（IM-10 が懸念した二重管理の火種が残る）。

**確定（2026-07-07・作業指示者判断）: 案X を採用**。C-BDK root `CLAUDE.md` は「開発リポ専用文書」に純化する ―― 「新規プロジェクトにコピーして使う」雛型宣言を撤去し、§ディレクトリ構造・配布対象/開発専用・開発フロー・C-BDK 固有情報（マシン固有パス・固有 MCP ポリシー）に徹する。エンドユーザ向け雛型役は **C-BCP に一本化**。§4 の §ディレクトリ構造改訂は本方針で確定（Phase 3・レーンB 実装）。

> **【レーンB 着手時の実測・2026-07-12】案X の実装には工程が 1 つ足りない。**
> - **chore/groom-as-share は既に root `CLAUDE.md` を `CLAUDE.md.example`（コピー展開用テンプレート）へリネーム済み**。つまり PR#1 をマージすると develop から root `CLAUDE.md` が消え、雛型役の `CLAUDE.md.example` が残る。§0 の表「root CLAUDE.md: 有」は develop/feat の実態であり、chore では既に別の姿になっている。
> - 一方 **C-BCP には `CLAUDE.md.sample` が存在しない**（tracked は `.claude`(submodule) / `.gitmodules` / `README.md` の 3 つのみ。README は「`CLAUDE.md.sample` を用意してあれば」と条件付きで書いており未整備）。
> - よって案X「雛型役は C-BCP に一本化」を成立させるには、**C-BDK の `CLAUDE.md.example` を C-BCP へ `CLAUDE.md.sample` として移管**し、C-BDK 側では削除した上で root `CLAUDE.md` を開発リポ専用文書として書き直す必要がある。移管は Phase 5a（C-BCP ルート直コミットレール）に同梱するのが自然。
> - **順序制約**: この事情により IM-9/IM-10 は **PR#1 マージ後**でなければ着手できない（先に feat 側で root `CLAUDE.md` を改訂すると、PR#1 のリネーム／削除と衝突する）。Phase 表の「Phase 1 → Phase 3」の順序は正しく、レーンB では Phase 0（機械的修正＋CR-1）までを先行実施した。

> ※この判断は §4 の §ディレクトリ構造 改訂の書き方にのみ影響し、CR-1/CR-2/IM-8 とは独立。

---

## 6. リリースフェーズ計画【確定版】

| Phase | 内容 | 完了条件 | レーン |
|---|---|---|---|
| **0** | PR#2（launcher・feat/launcher-scripts→develop）のレビュー対応。レーンB 機械的修正（R1-IM-1〜7,12,13）を反映 | 作業指示者レビュー完了・機械的修正コミット済み | B（C-BDK） |
| **0-bis** | **Round 2 / Round 3 クロスレビュー指摘の反映**（両 PR・完了済み） | R2 CR-a/b/c ＋ R3-A〜J のコード・文書修正が両 PR にコミット済み。統合状態を実測再検証済み | B |
| **1** | ~~grooming をリリース前提としてマージ~~ → **完了（2026-07-13）**。**PR#1（`400c904`）→ PR#2（`9458ed3`）の順・いずれも merge commit**。統合後 develop を実測: reports 追跡 0／check-assets が作業ツリー・payload とも exit 0・FAIL 0／payload 26 ファイル／`CLAUDE.md`・`.sh`=LF・`.ps1`=CRLF+BOM | 達成済み | 計画=A／実行=B（完了） |
| **2** | ~~CR-1 実装 ＋ check-assets 強化（CR-2）を develop へ~~ → **両 PR で実装済み**（CR-1＝PR#2 の `.claude/.gitignore`・`.claude/.gitattributes`／CR-2＝PR#1 の check-assets 強化）。本 Phase はマージで自動達成 | 配布先統制ファイルが payload に乗る・check-assets が reports/CLAUDE.md/個人実体/統制ファイル不在を FAIL 判定（**実測確認済み**） | B（完了） |
| **3** | R1-IM-9/10 反映（root CLAUDE.md 役割確定・§ディレクトリ構造改訂・`.env` 記述是正）＋ **C-BDK README の launcher 同期（R2-IM-11）** ＋ **R2-IM-8**（`clean-test-env.ps1` が呼び出し元セッションに削除済み `CLAUDE_CONFIG_DIR` を残す）＋ **R2-IM-9**（`publish-plugin` へ publish-share の修正 4 点を横展開）＋ **Windows ファイル方針の確定反映（§9）** ＋ **改行検証の数値訂正（§10）** | root CLAUDE.md が §5 決定どおり・配布共通指示正本が明記・README に launcher/`start_claude_code.*`/`docs/` が載る・`clean-test-env.ps1` が env を復元・`publish-plugin` が publish-share と対称・§9/§10 の完了条件を満たす | 設計=A／実行=B |
| **3 の実施状況** | **PR#3（`feat/phase3-win-file-policy` → develop）として提出済み（2026-07-13）**。`5cddd0c`＝Windows ファイル方針＋`.bat` の CP932 ガード（§9）／`6783cea`＝root CLAUDE.md 新設・R2-IM-8・R2-IM-9・`.ps1` 保存形式の検査 hook／`fadd537`＝CR 計測の壊れ方を明記（§10）。R2-IM-11（README の launcher 同期）は PR#1 のセルフレビューで既に完了していた | **作業指示者のレビュー・マージ待ち** | B |
| **4** | develop → main 統合 ＋ 版 tag | main が配布 ready（reports 0・CLAUDE.md 有・統制ファイル有）・tag 付与 | B |
| **5a** | C-BCP ルート配布レール整備（`start_claude_code.{sh,ps1}` ＋ ルート `.gitattributes` を C-BCP 直コミット）＋ **雛型役の移管**（C-BDK `CLAUDE.md.example` → C-BCP `CLAUDE.md.sample`・C-BDK 側は削除） | C-BCP に起動装置・改行属性・雛型 CLAUDE.md が着地・README mode A コピーリスト更新 | B |
| **5b** | 公開: `/security-review` ゲート → publish-share（tag 付き main ref）で C-BDC 反映 → C-BCP submodule bump → **受入検証**（fresh clone `--recurse-submodules` で Git Bash/PowerShell 両起動スモーク・**autocrlf=true マシン**で CR-1 検収）。あわせて **C-BDC / C-BCP README の実態同期**（直コミット。C-BDC README は publish-share の keep-list で保護されるため C-BDK からは更新できない＝R2-IM-11 の後段）と **配布版 `.claude/CLAUDE.md` の Skills 表を 6 件へ同期**（R2-S-1 / R3-S-7） | 3リポ公開・スモーク pass・reports/CLAUDE.md/改行の実配布確認・README が実態と一致 | B |

- **PR#1・PR#2 の順序**: **PR#1 → PR#2 の順、いずれも merge commit（squash 禁止）**。この順・この方式でコンフリクトが発生しないこと、統合ツリーが配布 ready であることは Round 3 レビューで実測済み。**publish は両方が develop→main に揃うまで不可**。
- 会話ベースだった旧5手順を本表で置換・ファイル化（R1-IM-2 の「計画をファイル化」を満たす）。
- **積み残しの残り（SUGGESTION 級・Phase 3 以降の任意）**: R3-S-1（`custom.env` の空値が PowerShell では変数を作らない）／R3-S-2（Windows PowerShell 5.1 の CP932 誤読 ―― テンプレに注記済み・恒久策は設計判断）／R2-S-2（`start_claude_code.ps1` の `Write-Error` 自家撞着）。
- **指摘 ID は巡回ごとに振り直されている**（例: 「IM-8」は Round 1 では「設計書の正本規定」、Round 2 では「clean-test-env の env 残存」）。本表では `R1-` / `R2-` / `R3-` の巡回接頭辞を付けて区別する。

---

## 7. レーンB（C-BDK 移管）指示サマリ

Phase 0/2/3/5 の実装項目。C-BDK セッション（primary=C-BDK）で実施:
1. 機械的修正: IM-1（旧記述訂正）/IM-2（publish 経路）/IM-3（コピー先誤記）/IM-4（CRLF・書式契約）/IM-5（bash 版数ガード）/IM-6（bypassPermissions 隔離）/IM-7（add-dir 注記）/IM-12（TEAM_OPTS 文言）/IM-13（submodule ガード・README 同期）/S-2〜S-6。
2. CR-1 実装: `.claude/.gitignore`・`.claude/.gitattributes` 追加。
3. CR-2 実装: check-assets 強化（W-RBC scripts 正本を改修 → C-BDK 配布分へ反映）。
4. IM-9 実装: §ディレクトリ構造改訂（§5 判断反映後）。
5. IM-8: 設計書正本の差分取込。

> C-BDK は auto-memory 名前空間が別（本 W-RBC セッションのメモリは移らない）。移管時は本確定書 ＋ 統合レビュー報告書を参照素材として渡す。

---

## 9. Windows 向けファイルの保存形式【確定・2026-07-13】

配布 rule `.claude/rules/win-file-encoding.md` は **payload に同乗して全利用先へ配布される**ため射程が広い。現行は `.ps1` / `.bat` / `.cmd` / `.reg` / `.ini` の 5 拡張子を**ひとまとめ**にして「CP932/CRLF へ変換せよ」と指示しているが、**保存形式の正解は拡張子ごとに違う**ことが実測で判明した。以下を確定方針とする。

### 9-1. 原則: 一律 UTF-8。CP932 は `.bat` だけの例外

| 拡張子 | 読み手 | 保存形式 | 根拠（実測） |
|---|---|---|---|
| `.ps1` / `.psm1` / `.psd1` | PowerShell | **UTF-8 + BOM + CRLF** | PS 5.1 は BOM 無しを ANSI（CP932）として読む。**PS 7 は既定 UTF-8** なので CP932 ファイルの日本語リテラルが壊れる（`'こんにちは'` の長さが 5 → 8 に化けることを実測）。**5.1 と 7 の両方で正しく読める唯一の形式が UTF-8 + BOM** |
| `.bat` | cmd.exe | **CP932 + CRLF・BOM なし** | cmd.exe は BOM を読み飛ばさず 1 行目を壊す。`chcp 65001` を先頭に置く回避策は**コンソール表示品質を損なう**ため作業指示者が忌避 → CP932 以外に実用解が無い |
| `.cmd` | cmd.exe | **使用禁止**（`.bat` に一本化） | `.bat` との差は一部組み込みコマンドの ERRORLEVEL 挙動のみ。一本化して失うものがなく、例外を 1 つに絞れる |
| `.reg` / `.ini` | regedit / Win32 API | **スコープ外**（Claude に R/W 権限を与えない） | `.env` と同格の扱い。`settings.json` の `permissions.deny` に追加する |
| `.csv` | Excel | UTF-8 + BOM | Excel は BOM を見て UTF-8 と判定する（参考。キットには現存しない） |

**`.bat` の本文は CP932 で表現できる文字だけに限る**。`⚠`（U+26A0）/ `‼`（U+203C）/ `✓`（U+2713）/ `✗`（U+2717）/ `—`（U+2014）は **CP932 に符号位置が無く**、変換で救えない（既存 `.ps1` 7 本すべてがこれらを含むことを実測）。メッセージ記号は `[!]` / `[OK]` 等の ASCII を使う。

### 9-2. `.bat` の R/W 機構: 原本は常に CP932。Claude には UTF-8 の影を見せる

「操作の前後で原本を変換する」方式は採らない。Grep は対象が事前に確定せず、Bash は何に触るか原理的に不明なため、**リポジトリが「本来 CP932 のはずのファイルが UTF-8 になっている」状態を持つ時間帯**ができ、その最中の `git add` / hook 失敗 / ユーザ中断で**壊れたバイト列がコミットされる**（＝ Round 1〜3 で潰し続けた「ゲートが環境依存で fail-open する」クラスの再発）。

代わりに**読みはディスクを書き換えない**という非対称性を使う:

| 経路 | 設計 |
|---|---|
| `Read` | PreToolUse で `file_path` を **UTF-8 に変換した一時コピー**へ差し替える（`hookSpecificOutput.updatedInput`）。**原本は不変** |
| `Edit` / `Write` | 同じく一時コピー上で編集させ、PostToolUse で **CP932 + CRLF へ書き戻す**。原本が変わるのはこの 1 ステップだけ |
| `Grep` | 変換しない。UTF-8 で標準出力へ流すヘルパー `bat-grep` を用意し rule で誘導（ディスクを触らないので無害） |
| `Bash` | 変換しない。rule で「`.bat` を `sed -i` / リダイレクトで書き換えない・読むなら `bat-cat`」と規定 |

- **コーデックは `cp932` を指定する**（`shift_jis` ではない）。`shift_jis` だと 0x5C が U+00A5〈¥〉に写るが、`cp932` は 0x5C ↔ U+005C〈バックスラッシュ〉で正しく往復する。プロンプト上で `¥` に見えるのはフォントの表示であってエンコーディングではない。
- **書き戻しは fail-closed**。CP932 に写せない文字が 1 つでもあれば書き戻しを中止し、原本を保全したまま PostToolUse の `decision: "block"` ＋ `reason` で Claude へ差し戻す（`?` 置換で黙って通すと壊れたファイルが配布される）。
- **実装前に実測する分岐**: PreToolUse の `updatedInput` で `Read` の `file_path` を差し替えられるかは公式 docs に明記が無く**未確認**。効かない場合は「`.bat` に対する Read/Edit/Write を rule で禁止し、専用ヘルパー（`bat-read` / `bat-edit`）へ一本化する」設計に切り替える。

### 9-3. 併せて実施

- **`.gitattributes` を拡張子ベースへ一般化**する（現行はパス個別指定のため、将来増えるファイルが保護から漏れる）。`*.ps1` / `*.bat` を明示登録。
- **`.ps1` の BOM + CRLF 保全を検査する PostToolUse hook** を入れる。公式 changelog に **v2.1.77「Write tool が CRLF ファイルを上書きする際に黙って改行コードを変換していた」／ v2.1.89「Edit/Write tool が Windows で CRLF を二重化していた」**の修正記録があり、**改行の保全は仕様として保証されておらず回帰しうる**（ファイル操作ツールの改行・文字コードの扱いを規定した記述は公式 docs に一切ない）。検査を機械化して回帰を検知する。

## 10. 改行検証の計測手段の誤り【2026-07-13 発覚・要訂正】

**Round 3 の改行検証で使った計測コマンドが壊れていた**。Git Bash（MSYS）の `grep` / `awk` は CR を数えられず、
しかも**間違い方が 2 通りあって、どちらも“それらしい値”を返す**。真値 CR=2・3 行のファイルで実測:

| 書き方 | 返る値 | 何が起きているか |
|---|---|---|
| `grep -c $'\r' <file>` | **3**（＝総行数） | パターンが空になり**全行にマッチ**する |
| `grep -c "$(printf '\r')" <file>` | **0** | grep がテキストモードで**入力の CR を剥がす**ため一致しない |
| `awk '/\r$/' <file>` | **0** | awk も CR を剥がす |
| `grep -c -U "$(printf '\r')" <file>` | **2** ✅ | `-U`（バイナリ扱い）なら CR が見える |
| `tr -cd '\r' < <file> \| wc -c` | **2** ✅ | 正解 |

**これが最も危険な点**: 「大きい数」と「0」の**両方が誤りになりうる**ため、`before → after` を別の書き方で測ると
**壊れた計測どうしが「修正が効いた」ように見える**。Round 3 の「`CLAUDE.md` の **CR 50 → 0**」がまさにそれで、
before は「空パターンで**行数 50**」、after は「CR を剥がされて **0**」という**別々の壊れ方**だった
（`.claude/CLAUDE.md` はちょうど 50 行）。同様に「`settings.json` の CR 39 → 0」「`launcher/*.ps1` は CR 101 のまま」も
**行数であって CR 数ではない**。

**結論そのもの（`.sh`=LF / `.ps1`=CRLF+BOM）は 2026-07-13 に `tr -cd '\r' | wc -c` と `git ls-files --eol` で
独立に再測定し、正しいことを確認済み**（`git ls-files --eol` が `i/lf w/crlf attr/text eol=crlf` を返す）。

**Phase 3 での対応**: (1) 上記数値を訂正する（Round 3 報告書・本書・マージ済み PR#1/#2 の本文）。
(2) 「Git Bash の `grep` / `awk` で CR を数えてはならない」を配布 rule（`win-file-encoding.md`）と
C-BDK root `CLAUDE.md` に明記する。

> **教訓**: 「機構は直すが、それを説明する文書を置き去りにする」（Round 3 の教訓）の親戚で、型としては
> **「結論は合っていたが、根拠として掲げた測り方が壊れていた」**。しかも**壊れた計測が before/after の
> 形をとると、修正の成功を偽証する**。検証の道具そのものを検証していなかった。

---

変更履歴: 初版（2026-07-07）。Fable クロスレビュー統合の §9 レーンA を受け、CR-1 搬送方式・CR-2 前提条件・IM-8 正本・IM-9 §ディレクトリ構造・リリースフェーズ計画を確定。IM-10（root CLAUDE.md 役割）は案X（開発リポ専用に純化）で作業指示者確定（同日）。／**2026-07-12（レーンB 着手時の補正）**: 実装・実測により本書の 2 点を補正 ―― (1) §1 CR-1 の `.claude/.gitignore` は 3 行では不足（publish の `cp -R` が C-BDC の既存 `.gitignore` を上書きするため、既存4行を含む全量を持たせないと個人設定の除外が配布のたびに失われる）。(2) §5 案X の実装には「C-BDK `CLAUDE.md.example` → C-BCP `CLAUDE.md.sample` の移管」工程が必要（chore は既に root CLAUDE.md を .example 化済み・C-BCP に雛型が未整備）＝ Phase 5a に追加。Phase 0（機械的修正 IM-1〜7/11〜13・S-1〜5 ＋ CR-1）は C-BDK `feat/launcher-scripts` にて実装完了。／**2026-07-12（Round 3 レビュー反映）**: (1) **マージ方式を「squash 推奨」から「merge commit（squash 禁止）」へ訂正**（§2・§6 Phase 1・§6 注記の 3 箇所）。squash はマージ元ブランチの履歴を消し、レビュー報告書・PR コメントが SHA で参照する修正コミット群を辿れなくするため、作業指示者の確定指示により撤回した（R3-G）。(2) **Phase 2 の CR-1/CR-2 は両 PR で実装済み**のため完了扱いに変更（R3-H）。(3) **Round 2 の「マージ後・レーンB」送り 8 件を本フェーズ表へ計上**（R2-IM-8/9/11・R2-S-1 を Phase 3 / 5b へ。R3-J＝「フェーズ表に無い約束はレーンB 移管で消える」）。(4) 指摘 ID に巡回接頭辞（`R1-` / `R2-` / `R3-`）を導入（巡回ごとに ID が振り直され「IM-8」が別物を指していたため）。／**2026-07-13（マージ実施・Windows ファイル方針の確定）**: (1) **Phase 1 完了** ―― PR#1（`400c904`）→ PR#2（`9458ed3`）を merge commit でマージし、統合後 develop を実測（reports 0・両層の check-assets が exit 0/FAIL 0・payload 26 ファイル・`.sh`=LF/`.ps1`=CRLF+BOM）。(2) **§9 を新設** ―― Windows 向けファイルの保存形式を「一律 UTF-8、CP932 は `.bat` だけの例外（`.cmd` は使用禁止・`.reg`/`.ini` はスコープ外）」で確定し、`.bat` の R/W 機構を「原本は常に CP932。Claude には UTF-8 の影を見せる（読みはディスクを触らない）」で確定。(3) **§10 を新設** ―― Round 3 の改行検証で使った `grep -c $'\r'` が Git Bash で機能しておらず（全行マッチ＝総行数を返す）、報告書と PR 本文の CR 数値が無効であることを記録。結論は再測定で追認。
