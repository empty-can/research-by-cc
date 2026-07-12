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
> よって `.claude/.gitignore` には「配布先で必要な除外の全量」を持たせる必要がある（**ここに無い行は publish のたびに消える**）。実装では既存4行を保持し、launcher 個人実体3行と作業一時物（`/work/` `/workspace/` `/agent-memory-local/`）を追加した。
> `/reports/` は CR-2・PR#1 の担当領域のため本ファイルには入れていない（既追跡の29件に影響を与えないため）。
> 検証: 旧 `.gitignore` の全パターンが新 `.gitignore` に包含されることを差分照合で確認済み（回帰ゼロ）。

**`.claude/.gitattributes`（新規）**:
```gitattributes
# ランチャー資産の改行コード固定（配布先 C-BDC の clone で core.autocrlf に破壊されないため）
/launcher/*.sh                text eol=lf
/launcher/*.sh.template       text eol=lf
/launcher/custom.env.template text eol=lf
/launcher/*.ps1               text eol=crlf
/launcher/*.ps1.template      text eol=crlf
```

- publish-share L51-54 は keep-list（`.git`/`.gitignore`/`README.md`/`LICENSE`）を残し他を rm→`cp -R`。`.claude/.gitignore` は cp で C-BDC ルート `.gitignore` を payload 版へ**収束**（keep-list の既存を上書き）。`.claude/.gitattributes` は keep-list 外だが cp で新規着地。→ 以後 C-BDC の両ファイル正本は C-BDK payload に一元化。
- C-BDK ルートの既存 `.gitignore`/`.gitattributes`（launcher 行）は**二重防御として残置可**（C-BDK リポ内でも有効）。
- **ルート直下物（`start_claude_code.{sh,ps1}`）の eol** は payload に乗らないため、C-BCP ルートへ直コミットする `.gitattributes`（`/start_claude_code.sh text eol=lf`・`/start_claude_code.ps1 text eol=crlf`）で担保（§6 Phase 5a）。

---

## 2. CR-2: リリース前提条件【確定】

**確定事項**: **PR#1（chore/groom-as-share → develop・推奨 squash merge）またはその等価 grooming を、リリース（Phase 4 以降）の前提条件に格上げする**。

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
| **0** | PR#2（launcher・feat/launcher-scripts→develop）のレビュー対応。レーンB 機械的修正（IM-1〜7,12,13）を反映 | 作業指示者レビュー完了・機械的修正コミット済み | B（C-BDK） |
| **1** | grooming をリリース前提としてマージ（PR#1 chore→develop・squash 推奨） | develop に「reports 0 件・`.claude/CLAUDE.md` 有・`.gitignore` の reports 行復活」が載る | 計画=A／実行=B |
| **2** | CR-1 実装（`.claude/.gitignore`・`.claude/.gitattributes` 追加）＋ check-assets 強化（CR-2）を develop へ | 配布先統制ファイルが payload に乗る・check-assets が reports/CLAUDE.md/個人実体を FAIL 判定 | B |
| **3** | IM-9/10 反映（root CLAUDE.md 役割確定・§ディレクトリ構造改訂・`.env` 記述是正） | root CLAUDE.md が §5 決定どおり・配布共通指示正本が明記 | 設計=A／実行=B |
| **4** | develop → main 統合 ＋ 版 tag | main が配布 ready（reports 0・CLAUDE.md 有・統制ファイル有）・tag 付与 | B |
| **5a** | C-BCP ルート配布レール整備（`start_claude_code.{sh,ps1}` ＋ ルート `.gitattributes` を C-BCP 直コミット）＋ **雛型役の移管**（C-BDK `CLAUDE.md.example` → C-BCP `CLAUDE.md.sample`・C-BDK 側は削除） | C-BCP に起動装置・改行属性・雛型 CLAUDE.md が着地・README mode A コピーリスト更新 | B |
| **5b** | 公開: `/security-review` ゲート → publish-share（tag 付き main ref）で C-BDC 反映 → C-BCP submodule bump → **受入検証**（fresh clone `--recurse-submodules` で Git Bash/PowerShell 両起動スモーク・**autocrlf=true マシン**で CR-1 検収） | 3リポ公開・スモーク pass・reports/CLAUDE.md/改行の実配布確認 | B |

- **PR#1・PR#2 の順序**: reports 除去（PR#1）と launcher（PR#2）は独立でコンフリクト最小。どちらを先に develop へ入れてもよいが、**publish は両方＋CR-1/IM-9 が develop→main に揃うまで不可**。
- 会話ベースだった旧5手順を本表で置換・ファイル化（IM-2 の「計画をファイル化」を満たす）。

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

変更履歴: 初版（2026-07-07）。Fable クロスレビュー統合の §9 レーンA を受け、CR-1 搬送方式・CR-2 前提条件・IM-8 正本・IM-9 §ディレクトリ構造・リリースフェーズ計画を確定。IM-10（root CLAUDE.md 役割）は案X（開発リポ専用に純化）で作業指示者確定（同日）。／**2026-07-12（レーンB 着手時の補正）**: 実装・実測により本書の 2 点を補正 ―― (1) §1 CR-1 の `.claude/.gitignore` は 3 行では不足（publish の `cp -R` が C-BDC の既存 `.gitignore` を上書きするため、既存4行を含む全量を持たせないと個人設定の除外が配布のたびに失われる）。(2) §5 案X の実装には「C-BDK `CLAUDE.md.example` → C-BCP `CLAUDE.md.sample` の移管」工程が必要（chore は既に root CLAUDE.md を .example 化済み・C-BCP に雛型が未整備）＝ Phase 5a に追加。Phase 0（機械的修正 IM-1〜7/11〜13・S-1〜5 ＋ CR-1）は C-BDK `feat/launcher-scripts` にて実装完了。
