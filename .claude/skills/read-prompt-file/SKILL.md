---
description: 活動フォルダ配下の .claude/work/prompt.txt を読み込みコンテキストに追加する
allowed-tools: Bash(.claude/skills/read-prompt-file/read-prompt-file.sh), Bash(cat -n *)
---

# read-prompt-file

## 手順

1. `bash .claude/skills/read-prompt-file/read-prompt-file.sh` を実行する
2. 終了コードが 0 でない場合、以下の定型応答のみを返して終了する:
   ```
   読み込みファイル不在エラー
   プロンプトに出力されているエラーメッセージの内容を元に、prompt.txt を作成してから /read-prompt-file を再実行してください。
   ```
3. 終了コードが 0 の場合、標準出力に返されたパス `<PATH>` を使い `cat -n <PATH>` を実行する
4. 読み込んだ内容を作業者からの新規メッセージとして処理する
