---
description: 活動フォルダ配下の .claude/work/clip.txt を読み込みコンテキストに追加する
allowed-tools: Bash(.claude/skills/read-prompt-file/read-prompt-file.sh), Bash(cat -n *)
---

# read-prompt-file

長文・複数行のメッセージをエディタで作成・編集してから Claude にコンテキストとして渡すユーティリティ Skill。

## 動作

1. 活動フォルダ（ルート CLAUDE.md「ブランチ運用ルール」で決定）配下に `.claude/work/clip.txt` を準備する
   - 存在しなければ空ファイルとして作成
   - その後 Windows の既定アプリ（エディタ）で開く
2. 作業者がエディタで内容を記述・保存する
3. Claude がファイル内容を読み込みコンテキストに取り込む

## 実行手順

以下を Bash で順に実行:

1. ファイル準備とエディタ起動:
   ```
   bash .claude/skills/read-prompt-file/read-prompt-file.sh
   ```
   標準出力には clip.txt のリポジトリルートからの相対パスが返る（例: `research-for-MCP-Srv-Sec-Inspection/.claude/work/clip.txt`）

2. 作業者がエディタで保存完了したことを確認したら、上記パスの内容を読み込み:
   ```
   cat -n <上記で得たパス>
   ```

3. 内容に基づいて作業を開始する

## 注意

- エディタは作業者が手動で閉じるまで開いたまま。送信後にもファイルは残るため、再確認したい場合に有用
- clip.txt は `.gitignore` 対象（`.claude/work/` 配下）。コミット対象外
