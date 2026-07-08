#!/bin/bash

# CSVファイル名
CSV_FILE="download_list.csv"

# ヘッダ行をスキップして読み込み
tail -n +2 "$CSV_FILE" | while IFS=',' read -r url filename folder overwrite_flag
do
    # 空行スキップ
    [ -z "$url" ] && continue

    echo "----------------------------------------"
    echo "Downloading: $url"

    # 保存先フォルダ作成
    mkdir -p "$folder"

    # 保存先ファイルパス
    filepath="$folder/$filename"

    # 上書きフラグを小文字化
    flag=$(echo "$overwrite_flag" | tr '[:upper:]' '[:lower:]')

    # TRUE または 1 の場合
    if [[ "$flag" == "true" || "$flag" == "1" ]]; then

        echo "Overwrite mode: ENABLED"

        # 強制上書きダウンロード
        curl -L -f "$url" -o "$filepath"

    else

        echo "Overwrite mode: DISABLED"

        # 既存ファイルが存在する場合
        if [ -e "$filepath" ]; then

            # archive フォルダ作成
            archive_dir="$folder/archive"
            mkdir -p "$archive_dir"

            # タイムスタンプ生成
            timestamp=$(date +"%Y%m%d_%H%M")

            # ファイル名と拡張子分離
            base="${filename%.*}"
            ext="${filename##*.}"

            # 拡張子なし対応
            if [ "$base" = "$ext" ]; then
                archive_name="${base}_${timestamp}"
            else
                archive_name="${base}_${timestamp}.${ext}"
            fi

            archive_path="$archive_dir/$archive_name"

            echo "Existing file found."
            echo "Move to archive:"
            echo "  $filepath"
            echo "  -> $archive_path"

            # archiveへ移動
            mv "$filepath" "$archive_path"
        fi

        # ダウンロード
        curl -L -f "$url" -o "$filepath"

    fi

    # 実行結果確認
    if [ $? -eq 0 ]; then
        echo "Success: $filepath"
    else
        echo "Failed: $url"
    fi

done