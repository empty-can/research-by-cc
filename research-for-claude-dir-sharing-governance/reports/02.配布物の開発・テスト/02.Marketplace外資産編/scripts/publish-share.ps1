<#
  publish-share.ps1 — <Dev> の指定 ref の .claude を共有本体 <Share.claude> へ publish（パターンB・Sync A・手動ゲート）

  session 開始時の自動同期（refresh / pull --ff-only）とは別物。release-ready な .claude を
  共有本体へ反映する意図的な公開操作で、publish はここでしか push しない。
  publish 対象は -Ref で指定（既定 main＝公開基準）。checkout 不要で任意 ref を publish できる。

  使い方:
    .\scripts\publish-share.ps1 -ShareBody <Share.claude のローカルパス> [-Ref <ref>]
  例:
    .\scripts\publish-share.ps1 -ShareBody C:\path\to\share-claude                # main を publish
    .\scripts\publish-share.ps1 -ShareBody C:\path\to\share-claude -Ref develop    # 指定ブランチを publish
#>
param(
  [Parameter(Mandatory = $true)][string]$ShareBody,
  [string]$Ref = 'main'
)
$ErrorActionPreference = 'Stop'

$DevRoot = (git rev-parse --show-toplevel).Trim()
$Here    = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Test-Path (Join-Path $ShareBody '.git'))) { Write-Error "共有本体（<Share.claude> のクローン）が見つからない: $ShareBody"; exit 2 }
git -C $DevRoot rev-parse --verify "$Ref^{commit}" *> $null
if ($LASTEXITCODE -ne 0) { Write-Error "ref が存在しない: $Ref"; exit 2 }

$tmp = Join-Path $env:TEMP ('pubshare_' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
  # 1. 追跡ファイルのみを ref から取り出し（checkout 不要・個人/未追跡は構造的に除外）
  git -C $DevRoot archive $Ref .claude -o (Join-Path $tmp 'a.tar')
  if ($LASTEXITCODE -ne 0) { Write-Error "$Ref から .claude を取り出せない（.claude が無い?）"; exit 1 }
  tar -xf (Join-Path $tmp 'a.tar') -C $tmp                       # → $tmp\.claude\
  $src = Join-Path $tmp '.claude'

  # 2. 安全弁: 取り出した .claude が空なら中止
  if (-not (Test-Path $src) -or -not (Get-ChildItem -Force $src)) {
    Write-Error "$Ref の .claude が空。publish 中止（共有本体を空で上書きしない）"; exit 1
  }

  # 3. 衛生ゲート: 取り出した実体に対して check-assets
  & (Join-Path $Here 'check-assets.ps1') -Share $tmp
  if ($LASTEXITCODE -ne 0) { Write-Error 'check-assets FAIL。publish 中止'; exit 1 }

  # 4. /security-review は対話のため手動確認
  $ok = Read-Host "→ $Ref の内容について /security-review を実行済みなら y で続行"
  if ($ok -ne 'y') { Write-Host '中止'; exit 1 }

  # 5. 共有本体へミラー（メタ .git/README/LICENSE/.gitignore を除外して総入れ替え）
  robocopy $src $ShareBody /MIR /XD .git /XF README.md LICENSE .gitignore | Out-Null
  if ($LASTEXITCODE -ge 8) { Write-Error "robocopy 失敗 (code=$LASTEXITCODE)"; exit 1 }
  $global:LASTEXITCODE = 0
} finally { Remove-Item -Recurse -Force $tmp }

# 6. 共有本体を commit & push
git -C $ShareBody add -A
git -C $ShareBody diff --cached --quiet
if ($LASTEXITCODE -eq 0) { Write-Host '変更なし。publish 不要'; exit 0 }
$short = (git -C $DevRoot rev-parse --short $Ref).Trim()
git -C $ShareBody commit -m "publish: sync .claude from <Dev>@$short (ref: $Ref)"
git -C $ShareBody push

Write-Host "✓ publish 完了（ref: $Ref）。雛型リポジトリ <Share> で submodule を bump してください:"
Write-Host '    git -C <Share> submodule update --remote .claude'
Write-Host "    git -C <Share> add .claude && git -C <Share> commit -m 'chore: bump .claude' && git -C <Share> push"
