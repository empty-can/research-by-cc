# Claude Code 公式ドキュメント体系 調査・考察まとめ

## 背景

Claude Code 公式ドキュメントの効率的な参照を目的として、`claude_code_docs_map`・`llms.txt`・`llms-full.txt` の 3 ファイルを調査・比較した結果のまとめ。  
本調査は local RAG for cc プロジェクトの調査活動中（2026-05-09）に実施。

---

## 調査対象ファイルの概要

| ファイル | URL | 形式 | 仕様準拠 |
|---|---|---|---|
| `llms.txt` | `https://code.claude.com/docs/llms.txt` | H1+blockquote+H2リスト（llms.txt 仕様完全準拠） | 完全準拠 |
| `docs_map` | `https://code.claude.com/docs/en/claude_code_docs_map` | ページごとの見出し階層ツリー（Anthropic 独自） | 非準拠 |
| `llms-full.txt` | `https://code.claude.com/docs/llms-full.txt` | 全ページ全文連結（`# タイトル` + `Source: URL` で区切り） | 完全準拠（仕様推奨オプション） |
| 個別 `.md` | `https://code.claude.com/docs/en/{page-name}.md` | 単一ページのクリーンなマークダウン | — |

---

## 全体像: 4 階層構造

```
Layer 1: llms.txt        … 全ページカタログ（URL + 1行説明）
Layer 2: docs_map        … 構造マップ（見出し階層、カバレッジ限定）
Layer 3: llms-full.txt   … 全文連結コーパス
Layer 4: 個別 .md        … 単一ページ全文
```

**ナビゲーション設計**: llms.txt をハブとするスター型。
- 個別 `.md` → llms.txt（各ページ冒頭の callout）
- `docs_map` → llms.txt（冒頭案内）
- `llms-full.txt` → 個別 URL（各セクションの `Source: URL`）

---

## 観点 1: llms.txt はフォーマット仕様か、単なる名称か

**結論: フォーマットルールを持つ emerging standard（事実上の準標準）**

- 提唱者: Jeremy Howard（fast.ai）、2024年9月3日
- GitHub ★2,400+、VitePress/Docusaurus プラグイン等のエコシステムが形成済み
- 公式標準ではなくコミュニティ提案だが、仕様は明確に規定されている

**フォーマットルール**:

| 要素 | 必須／任意 | 内容 |
|---|---|---|
| H1 見出し | **必須** | プロジェクト名 |
| blockquote | 任意 | 短い要約 |
| 本文 | 任意 | 詳細情報 |
| H2 区切りのリスト | 任意 | URL + 説明のリンク群 |

- "Optional" H2 は「スキップ可能コンテンツ」を示す予約語
- 配置場所: サイトルートの `/llms.txt`
- 仕様は `/llms.txt`（短縮版）と `/llms-full.txt`（フルコンテキスト版）の両方提供を推奨
- robots.txt との差別化: robots.txt = クロール時アクセス制御、llms.txt = **推論時**のキュレーション

**Anthropic の実装**: llms.txt 仕様を `/llms.txt` + `/llms-full.txt` 両方含めて完全準拠。さらに各 `.md` ページから llms.txt への callout による循環参照設計 → **「LLM がトップダウンに段階的詳細化できるアーキテクチャを意図的に設計」** と評価できる。

---

## 観点 2: docs_map は llms.txt の一つか、別物か

**結論: llms.txt 仕様とは別物。「中間粒度の構造情報」を埋める補完ファイル**

llms.txt 仕様との非適合点:

| 要件 | llms.txt 仕様 | docs_map |
|---|---|---|
| 配置場所 | サイトルート `/llms.txt` | `/docs/en/claude_code_docs_map` |
| フォーマット | H1+blockquote+H2リスト | ページごとの見出し階層ツリー |
| 1エントリの情報 | URL + 1行説明 | URL + 全見出し構造 |
| サイズ感 | 数百行（コンテキスト収容前提） | 3,109行 / 78KB |

docs_map は llms.txt/llms-full.txt が提供しない「中間粒度」を担う：

| ファイル | 提供粒度 |
|---|---|
| llms.txt | URL + 1行説明（最も粗い） |
| docs_map | ページごとの見出し階層（中間） |
| llms-full.txt / 個別 .md | 全文（最も細かい） |

仕様に「中間粒度」の標準形式がないため、Anthropic が独自実装した補完層（推測）。

> **注**: この粒度分類は「情報の詳細度」軸での 3 段階整理。「取得単位」軸（=全体像の 4 階層構造）では llms-full.txt（全文連結コーパス）と個別 .md（単一ページ取得）は別階層として区別される。両者の本文コンテンツは実質同一（観点 E 参照）。

---

## 観点 3: 両者の掲載情報の差異が意味するもの

### カバレッジの差

| カテゴリ | llms.txt | docs_map | llms-full.txt |
|---|---|---|---|
| Agent SDK（28ページ） | ✓ | ✗ | ✓ ※ |
| リファレンス系 | ✓ | ✗ | ✓ ※ |
| whats-new 週次 changelog | ✓ | ✗ | ✓ ※ |
| ガイド・チュートリアル系 | ✓ | ✓ | ✓ ※ |

> ※ llms-full.txt の掲載ページ数は `Source: URL` 行カウントで 126 件（llms.txt の URL 数と同数）であることを確認済み。個別ページの網羅性は URL カウントから間接確認（1ページ詳細比較は観点 E 参照）。

### 差異が意味するもの

**1. メンテナンスパイプラインの分離（強い推測）**  
docs_map は「GitHub Actions で自動生成（日次）」と明記。llms.txt / llms-full.txt は別パイプラインで生成されている可能性が高い。同一パイプラインならカバレッジは一致するはず → 欠落は単純なバグではなく構造的問題。

**2. docs_map 単体依存時のカバレッジ誤認リスク**  
docs_map のカバレッジを「全体」と誤認した場合、Agent SDK 関連情報が丸ごと抜け落ちる。docs_map の冒頭案内（「llms.txt を先に参照せよ」）の意味が直感的に伝わりにくい点が課題。

---

## 観点 4: 各ファイルは LLM にとって本当に最適な形か

**結論: 各ファイルは「タスクに応じた使い分けが想定された設計」であり、単一最適解ではない**

| ファイル | LLM 最適性の本質 |
|---|---|
| llms.txt | ナビゲーション最適（小サイズ・高被覆・低詳細） |
| docs_map | 構造把握最適（中サイズ・中詳細・カバレッジ限定） |
| llms-full.txt | 全文摂取最適（大サイズ・全詳細・全被覆） |
| 個別 .md | ピンポイント取得最適（任意サイズ・1ページ単位） |

### 各ファイルの LLM 最適性評価

**llms.txt**:
- ✓ サイズが小さくコンテキスト収容可能
- ✓ `.md` URL でクリーンなマークダウン取得可能
- △ 1行説明では類似ページの判別が困難（例: `hooks.md` vs `hooks-guide.md`）
- ✗ カテゴリ分類なしで全ページスキャンが必要
- ✗ ページ間の依存関係が示されない

**docs_map**:
- ✓ 見出し階層でページ内ナビゲーションが精緻化できる
- ✓ セクション分類（Getting started / Agents 等）がある
- ✗ 78KB / 3109行でコンテキストを大きく圧迫（截断リスク）
- ✗ 各ページに説明がなく「なぜそのページか」の判断ができない

**llms-full.txt**:
- ✓ 全文が収録されているため参照漏れがない
- ✓ ページ区切り（`# タイトル` + `Source: URL`）が明確でチャンク化しやすい
- ✗ 推定 MB 級のサイズで直接コンテキスト注入は困難
- ✗ Markdown + HTML/JSX 混在により前処理が必要

---

## 追加観点

### 観点 A: llms.txt をハブとするスター型ナビゲーション

全ファイルが llms.txt（とその指す URL 体系）を参照点としており、どこから入っても llms.txt に誘導される設計。LLM が「現在地」を見失わないための配慮と解釈できる。

### 観点 B: llms-full.txt が「単一ファイル摂取戦略」を成立させる

llms-full.txt の存在により、「フェッチ 1 回で全ドキュメントを取得する」という戦略が現実的選択肢になった。部分取得ミスのリスクがゼロになり、ローカルキャッシュを 1 ファイル管理で完結できる。

### 観点 C: 3 ファイル構造が RAG アーキテクチャと同型

| RAG コンポーネント | Anthropic Docs での対応 |
|---|---|
| Index / Vector store の素材 | `llms.txt`（URL + サマリ） |
| Document corpus | `llms-full.txt`（全文連結） |
| Chunk metadata | `docs_map`（見出し階層） |
| Source documents | 個別 `.md` ページ |

本プロジェクト（local RAG for cc）にとって、**RAG 構築に必要な素材が公式提供のみで完結**することを意味する重要な発見。

### 観点 D: 3 ファイルのパイプライン独立性と相互検証可能性

3 ファイルが独立パイプラインで生成されている可能性が高い（推測）ため、以下の包含関係チェックで Anthropic 側の障害を早期検知できる:
- `llms.txt URL リスト ≈ llms-full.txt セクション URL`
- `docs_map URL リスト ⊂ llms.txt URL リスト`

### 観点 E: llms-full.txt と個別 .md の本文コンテンツは実質同一（確認済み）

overview ページを対象にした直接比較（llms-full.txt の該当セクションを抽出 vs `overview.md` を取得）により、以下を確認:

| 要素 | 個別 .md | llms-full.txt |
|---|---|---|
| Documentation Index callout | あり（サーバー注入） | なし |
| H1 直後の blockquote 説明文 | あり（front matter から注入） | なし |
| 内部リンクのパスプレフィックス | `/en/...` | `/docs/en/...` |
| 本文テキスト・コードサンプル・表 | **同一** | **同一** |

**結論**: 本文コンテンツは実質同一（確認済み）。差異はサーバー注入メタデータ（callout・blockquote）と内部リンクのパスプレフィックスのみ。

この確認により、**llms-full.txt は全 126 ページの個別 .md を結合したものと実質等価** と言える。RAG コーパスとして llms-full.txt を用いれば、個別 .md を 126 回フェッチする手間なく同等の本文コンテンツを取得できる。

---

## 課題・弱点の再評価

| 以前指摘した弱点 | llms-full.txt による緩和度 |
|---|---|
| docs_map のサイズ過大（78KB） | **緩和なし**（docs_map 自体は不変。ただし代替手段が成立） |
| llms.txt の説明精度不足（1行） | **大幅緩和**（llms-full.txt で全文補完可能） |
| docs_map の Agent SDK 欠落 | **大幅緩和**（llms.txt / llms-full.txt 側でカバー済み） |
| HTML/JSX 混在 | **緩和なし**（llms-full.txt も同様の問題を引き継ぐ） |
| 全文サイズの取り扱い | **やや悪化**（llms-full.txt は MB 級、前処理が必要） |

**総括**: 3 大弱点（説明精度・カバレッジ・参照導線）は実質解消。残課題は **(a) llms-full.txt の全文サイズ管理** と **(b) HTML/JSX 混在の前処理** の 2 点に集約される。

---

## 効果的な活用方法

### 活用方法 1: セッション開始時に llms.txt を必須コンテキスト注入

Claude Code 公式機能を調査する前に llms.txt を参照し、候補ページを特定してから個別フェッチする。サイズが小さく（約 130 エントリ）コンテキストコストが低い。F02-001 で発生した「auto-mode-config.md の発見漏れ」を原理的に防止できる。

### 活用方法 2: 候補数に応じた分岐フェッチ

```
Step 1: llms.txt で候補 URL を絞り込む
Step 2: 候補数で分岐
  1〜3 ページ  → 個別 .md を直接フェッチ
  4〜10 ページ → docs_map で構造把握 → 個別 .md
  11+ ページ  → llms-full.txt 一括取得
```

### 活用方法 3: llms-full.txt をローカル RAG コーパスとして活用

- **チャンク分割**: `# ページタイトル` + `Source: URL` でページ単位一次分割 → 大ページのみ H2/H3 で二次分割
- **メタデータ**: `Source: URL` を保持 + llms.txt サマリを結合して補強
- **更新検出**: whats-new セクションの差分検出 → 変更ページのみ再埋め込み
- **構造補強**: docs_map の見出し階層をチャンクのナビゲーション情報として注入

### 活用方法 4: `.md` 直接 URL の積極活用

特定ページの最新版取得は `https://code.claude.com/docs/en/{page-name}.md` を直接構築してフェッチ。クリーンなマークダウンを確実に取得できる。

### 活用方法 5: whats-new で freshness 確認（知識カットオフ補完）

llms.txt の `whats-new/2026-wXX.md` リンクを参照し、モデルの知識カットオフ後の機能変化を確認する。llms-full.txt にも whats-new セクションが同梱されるため、ローカル corpus 内で常に最新 changelog を参照可能。

### 活用方法 6: 用途別ファイル選択マトリクス

| タスク | 推奨ファイル |
|---|---|
| ドキュメント全体の俯瞰 | llms.txt |
| 特定機能の詳細調査 | 個別 .md（llms.txt で URL 特定後） |
| 横断的調査（複数機能比較等） | llms-full.txt |
| ページ内の構造把握 | docs_map |
| ローカル RAG 構築 | llms-full.txt（corpus）+ llms.txt（index） |
| Agent SDK 関連調査 | llms.txt → 個別 .md または llms-full.txt（docs_map では欠落のため不可） |
| changelog / 最新機能確認 | llms-full.txt の whats-new セクション |

### 活用方法 7: 3 ファイルのクロスバリデーション

`llms.txt URL ⊃ docs_map URL` および `llms.txt URL ≈ llms-full.txt セクション URL` を定期チェックし、Anthropic 側のパイプライン障害を早期検知する。

### 活用方法 8: コンテキスト予算別の取得戦略

| 予算規模 | 戦略 |
|---|---|
| 小（数千 token） | llms.txt のみ + 必要時に個別 .md |
| 中（数万 token） | llms.txt + docs_map + 個別 .md 数ページ |
| 大（10 万+ token） | llms-full.txt 一括投入 |
| ローカル RAG 利用時 | corpus は llms-full.txt から構築済み、セッション内では検索結果チャンクのみ注入 |

---

## 結論サマリ

| 認識アップデート | 内容 |
|---|---|
| 仕様準拠度 | **完全準拠**（フル版まで揃えている）と確定 |
| docs_map の役割 | **補完層**（llms.txt の代替ではなく中間粒度を埋める） |
| 3 大弱点の解消 | **実質解消**（説明精度・カバレッジ・参照導線） |
| パイプライン構造 | **独立生成の可能性が高く**、相互検証が成立する |
| 本プロジェクトへの示唆 | **ローカル RAG 構築はスクレイピング不要・公式提供のみで完結可能** |

---

## 変更履歴

- 2026-05-09: 初版作成（調査・考察まとめ）
- 2026-05-09: 検証結果を反映（観点 E 追加・カバレッジ表を確認済みに更新・観点 2 の粒度軸と取得単位軸の差異を注記）
