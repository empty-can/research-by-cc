# Phase 2: セキュリティ Issue 調査結果
作成日: 2026-06-21 / 担当: Sonnet Agent

## 調査方法

各 repo について GitHub MCP（`search_issues` / `list_issues` / `get_issue` / `get_issue_comments`）で以下を実施:

1. セキュリティ関連キーワード（security / vulnerability / CVE / RCE / injection / exploit / SSRF / path traversal / arbitrary code / authentication / sandbox escape）でタイトル・本文をスキャン（open/closed 両方、最大50件/repo）。
2. ヒットした Issue のうち、誤検出（本文に "authentication" 等が文脈的に含まれるだけの dependabot PR・機能要望等）を除外し、真にセキュリティ起因の Issue を特定。
3. 該当 Issue について番号 / タイトル / 状態 / 日付 / メンテナ応答 / 概要を記録し、放置判定を実施。

**注**: GitHub の `search_issues` をキーワード AND で実行した際は全 repo 0 件だった（GitHub 検索のトークン化挙動による）。そのため `list_issues` で全件取得し Python でローカルスキャンする方式に切り替えた。各 repo の全 Issue 件数は最大取得上限の 50 件（一部は実数）。

---

## サマリ表

| 候補 | 分類(P/S) | セキュリティIssue件数(open/closed) | 放置判定 | 特記 |
|---|---|---|---|---|
| blackwell-systems/agent-lsp | P | 0 / 1 | 放置なし | #1 は SafeSkill バッジ営業 PR（closed）。実害脆弱性報告なし |
| oraios/serena | P | 0 / 2 | 放置なし | #1585・#1569 command injection 報告。両方メンテナ即時応答→設計上の trust boundary として却下クローズ |
| bug-ops/mcpls | P | 1 / 0 | 軽微（堅牢性バグ） | #150 URI予約文字でサーバ panic。DoS寄りだが攻撃Issueではない。open・未応答約44日 |
| stephanj/LSP4J-MCP | P | 0 / 0 | セキュリティIssue報告なし | Issue/PRは3件全てdependabot/機能PR。#1にCVE-2026-24400(依存assertj)言及あるが本体脆弱性ではない |
| DeusData/codebase-memory-mcp | P | 0 / 0 | セキュリティIssue報告なし | #540は監査営業ボットIssue。脆弱性報告なし |
| sunix/jdtls-mcp | S | 0 / 0 | セキュリティIssue報告なし | 誤検出のみ（本文キーワードヒット） |
| isaacphi/mcp-language-server | S | 1 / 0 | 要注意（自動スキャン営業・未応答） | #130 MCPSafeスキャン結果(85/100,Crit0/High0/Med15)。open・コメント0・約40日未応答だが実害脆弱性ではない |
| johnhuang316/code-index-mcp | S | 0 / 1 | 放置なし | #84 ReDoS(DoS)。詳細PoC付き正当な報告→18日で対応完了クローズ |
| ProfessioneIT/lsp-mcp-server | S | 0 / 0 | セキュリティIssue報告なし | Issue/PRは3件のみ全てバグ修正PR・機能。脆弱性報告なし |
| aimasteracc/tree-sitter-analyzer | S | 0 / 0 | セキュリティIssue報告なし | 誤検出のみ（コード品質・複雑度Issue） |

凡例: P=Primary, S=Secondary

---

## 各候補の詳細

### blackwell-systems/agent-lsp (Primary)

- 全 Issue/PR: 10件。真のセキュリティ脆弱性報告: **なし**。
- **#1「Add SafeSkill security badge (30/100 — Blocked)」** closed / 作成 2026-04-22 / クローズ 2026-04-22（同日, by メンテナ blackwell-systems）
  - 概要: SafeSkill による自動スキャン結果のバッジ営業 PR。「Tool/shell abuse instruction」「Context boundary escape」等を検出と主張するが、対象はドキュメント/SKILL.md 内の記述パターンであり、コード脆弱性ではない。メンテナが同日クローズ。
  - URL: https://github.com/blackwell-systems/agent-lsp/pull/1
- 判定: **放置なし**（実害脆弱性 Issue は皆無、営業 Issue は即日処理済み）。

### oraios/serena (Primary)

最も活発でセキュリティ Issue 報告も複数。いずれもメンテナが即時対応している。

- **#1585「Security: COMMAND_INJECTION in agent.py:1222 (subprocess shell=True)」** closed (not_planned) / 作成 2026-06-16 / クローズ 2026-06-16（同日, by メンテナ opcode81）/ コメント8件・メンテナ複数応答
  - 概要: `subprocess.Popen(cmd, shell=True)` で `jetbrains_launch_command` が外部設定ファイル由来のため任意コマンド実行が可能と報告（自動スキャナ aina-vibeguard 由来）。メンテナは「当該設定はユーザのグローバル設定（ホームディレクトリ）にあり、trusted と仮定する設計」とセキュリティドキュメント（070_security.html）を提示して却下。報告者も納得しクローズ。`invalid` ラベル付与。
  - URL: https://github.com/oraios/serena/issues/1585
- **#1569「Security: subprocess.Popen with shell=True accepts unsanitized input」** closed (not_planned) / 作成 2026-06-11 / クローズ 2026-06-11（同日, by メンテナ opcode81）/ コメント1件
  - 概要: mcp-redteam スキャナによる静的解析報告（shell=True + ユーザ入力）。メンテナは「shell=True は意図的、実行引数はユーザ入力由来ではない」と即時応答してクローズ。`invalid` ラベル付与。
  - URL: https://github.com/oraios/serena/issues/1569
- 判定: **放置なし**（2件とも同日にメンテナが応答・クローズ。trust boundary の設計判断として明示的に対応済み）。

### bug-ops/mcpls (Primary)

- 全 Issue: 50件取得。大半は dependabot PR。真の脆弱性寄り Issue は堅牢性バグ系3件。
- **#150「get_diagnostics can abort stdio server for file paths containing URI-reserved chars」** open / 作成 2026-05-08 / 更新 2026-05-08 / コメント0・メンテナ応答なし
  - 概要: ファイルパスに URI 予約文字（`[` `]` 等、例 `routes/api/[...].ts`）が含まれると `path_to_uri` が `file://{path}` を直接整形するため `lsp_types::Uri::from_str` が panic し、stdio サーバが異常終了する。報告者はローカルで修正パッチ（`Url::from_file_path` + percent-encode）まで検証済み。DoS（サーバabort）寄りだが、攻撃を意図した脆弱性報告ではなく堅牢性バグ。**open のまま約44日メンテナ未応答**。
  - URL: https://github.com/bug-ops/mcpls/issues/150
- 関連バグ（同根のURIエスケープ不備、いずれもメンテナ自身 bug-ops 起票・open）: #167（path_to_uri が bare `file://{}` を使用）、#168（encode_rfc3986_path_chars が `{` `}` backtick を欠く）。メンテナ自身が認識しトラッキングしている。
  - URL: https://github.com/bug-ops/mcpls/issues/167 , https://github.com/bug-ops/mcpls/issues/168
- 判定: **軽微（堅牢性バグ）**。#150 は60日未満だが約44日未応答。ただしセキュリティ脆弱性というより panic/DoS 系堅牢性バグであり、同根の問題をメンテナ自身が #167/#168 で認識・トラッキング中。

### stephanj/LSP4J-MCP (Primary)

- 全 Issue/PR: 3件（PR #1, #2, #3）。すべて dependabot 依存更新 or 機能拡張 PR。セキュリティ脆弱性報告 Issue は**なし**。
- 補足: dependabot PR #1（assertj-core 3.26.3→3.27.7, closed/merged 2026-06-10）の本文に依存ライブラリ側の **CVE-2026-24400（assertj の XXE 脆弱性修正）** への言及があるが、これは LSP4J-MCP 本体の脆弱性ではなく依存更新による解消。本体に対するセキュリティ Issue は提起されていない。
  - URL: https://github.com/stephanj/LSP4J-MCP/pull/1
- 判定: **セキュリティ Issue 報告なし**。

### DeusData/codebase-memory-mcp (Primary)

- 全 Issue: 50件取得。活発（多数の機能PR・バグ報告）。真のセキュリティ脆弱性報告は**なし**。
- **#540「Free MCP Server Audit - Protocol Compliance & Cross-Platform Testing」** open / 作成 2026-06-20 / 投稿者 scotia1973-bot
  - 概要: ボットによる無料監査営業 Issue。具体的な脆弱性指摘ではなく監査サービス勧誘。実害報告ではない。
  - URL: https://github.com/DeusData/codebase-memory-mcp/issues/540
- 補足: #511（非UTF-8ソースの raw bytes が MCP レスポンスに出力されMCPクライアントがハングする, open）、#541/#526（UTF-8 サニタイズ修正PR）等は堅牢性バグ・修正であり、攻撃を意図した脆弱性報告ではない。
- 判定: **セキュリティ Issue 報告なし**（営業ボット Issue・堅牢性バグのみ）。

### sunix/jdtls-mcp (Secondary)

- 全 Issue/PR: 15件。キーワードヒット8件はすべて本文中の誤検出（README整理・ライセンス追加・MCPツール追加等のPR、投稿者は sunix / Copilot）。タイトルにセキュリティキーワードを含むものは皆無。
- 判定: **セキュリティ Issue 報告なし**。

### isaacphi/mcp-language-server (Secondary)

- 全 Issue/PR: 50件取得。真の脆弱性報告 Issue は**なし**だが、自動スキャン営業 Issue が1件 open で未応答。
- **#130「Security scan results for mcp-language-server — MCPSafe AIVSS 85/100 (Grade B)」** open / 作成 2026-05-12 / 更新 2026-05-12 / コメント0・メンテナ応答なし
  - 概要: MCPSafe（MCPサーバ向け自動スキャナ）によるスキャン結果報告 + バッジ営業。**Critical 0 / High 0 / Medium 15 / Low 0**。Medium 15件は「language server ツールスキーマと code analysis 権限まわり」と概括されるのみで、Issue 本文に個別の脆弱性詳細・再現手順はなし（詳細は外部サイト mcpsafe.io へのリンク）。**open のまま約40日メンテナ未応答（コメント0）**。
  - URL: https://github.com/isaacphi/mcp-language-server/issues/130
- 補足: #128 / #134（GitHub Actions の SHA ピン留め＝サプライチェーン対策, 投稿者 KooshaPari）はいずれも closed（対応済み）。dependabot による golang.org/x/text 等の依存更新 PR が多数（脆弱性修正を含みうる定期更新）。
- 判定: **要注意（放置気味だが実害脆弱性ではない）**。#130 は約40日 open・未応答で60日基準には未達。内容は自動スキャナによるバッジ営業で Critical/High ゼロ、個別脆弱性の実証なし。「セキュリティ脆弱性の放置」と断定はできないが、自動スキャン Issue が放置されている状態。

### johnhuang316/code-index-mcp (Secondary)

- 全 Issue/PR: 50件取得。正当なセキュリティ脆弱性報告が1件あり、適切に対応済み。
- **#84「[Bug]: Unvalidated patterns may lead to ReDoS attacks」** closed (completed) / 作成 2026-03-03 / クローズ 2026-03-21（by メンテナ johnhuang316）/ コメント4件
  - 概要: `search_code_advanced` ツールの `BasicSearchStrategy`（ripgrep等が無い場合のフォールバック）で、ユーザ入力 regex の安全性チェック `is_safe_regex_pattern()` が3つの固定文字列しか見ておらず、`(a+)+$` 等のネスト量化子で容易にバイパス可能。catastrophic backtracking により CPU 枯渇 → サーバハング（DoS）。詳細な PoC・脆弱コード行・再現手順付きの質の高い報告。認証不要で悪用可能と明記。**約18日で対応完了クローズ**（state_reason: completed）。
  - URL: https://github.com/johnhuang316/code-index-mcp/issues/84
- 判定: **放置なし**（正当な脆弱性報告に対し18日で修正完了クローズ）。

### ProfessioneIT/lsp-mcp-server (Secondary)

- 全 Issue/PR: 3件のみ。#3（spawn cwd 修正PR, open）、#2（Windows非対応の不具合報告, open）、#1（monorepo workspace root 修正PR, closed）。いずれもセキュリティ脆弱性とは無関係のバグ修正・機能。
- 判定: **セキュリティ Issue 報告なし**。

### aimasteracc/tree-sitter-analyzer (Secondary)

- 全 Issue/PR: 50件取得。キーワードヒット11件はすべて本文中の誤検出で、内容はコード品質・API設計・cyclomatic complexity 実装の不整合に関するもの（投稿者は主に aimasteracc 本人）。タイトルにセキュリティキーワード（CVE/RCE/SSRF/injection/exploit 等）を含む Issue は0件。
- 判定: **セキュリティ Issue 報告なし**。

---

## 総括

### 放置ありと判定した候補

**該当なし**（60日超でメンテナ未応答・未対応の明確なセキュリティ脆弱性 Issue は、全10候補で確認されなかった）。

ただし以下は準・要注意:

- **isaacphi/mcp-language-server #130**: MCPSafe 自動スキャン営業 Issue が約40日 open・コメント0で放置気味。ただし Critical/High ゼロ・個別脆弱性の実証なしで、「実害脆弱性の放置」とは言い切れない。
- **bug-ops/mcpls #150**: URI 予約文字でサーバが panic する堅牢性/DoS 寄りバグが約44日 open・未応答。ただし同根の問題をメンテナ自身が #167/#168 で認識・トラッキング中。

### セキュリティ Issue（脆弱性報告）が提起された候補

- **oraios/serena**: command injection 2件（#1585, #1569）。いずれもメンテナが**即日応答**し、trust boundary の設計判断として明示的に却下クローズ。対応姿勢は良好。
- **johnhuang316/code-index-mcp**: ReDoS/DoS 1件（#84, 詳細PoC付き）。**18日で修正完了**。対応姿勢は良好。
- 上記以外（agent-lsp, mcp-language-server）の「セキュリティ」Issue はすべて自動スキャナ/バッジ営業系で、実害脆弱性の実証を伴わない。

### 全体所見

- 10候補中、**正当な脆弱性報告（実証付き）が存在し、かつメンテナが適切に対応している**のは oraios/serena と johnhuang316/code-index-mcp の2つ。いずれもセキュリティ対応姿勢は良好（即日〜18日でクローズ、設計ドキュメント整備あり）。
- 残り8候補は、セキュリティ脆弱性 Issue 自体が報告されていない（誤検出のみ、または自動スキャナ営業 Issue のみ）。
- 自動セキュリティスキャナ（MCPSafe / SafeSkill / aina-vibeguard / mcp-redteam）由来の営業・スキャン結果 Issue が複数候補に投稿されている点が特徴的。これらは個別脆弱性の実証を欠くものが多く、メンテナの対応（即時クローズ vs 放置）は候補によって分かれる。
- **本タスクは Issue 調査のみ**。依存関係 CVE スキャン（dependabot PR で言及された CVE-2026-24400 等を含む）は別担当のスコープ。
