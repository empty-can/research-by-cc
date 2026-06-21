<#
.SYNOPSIS
  clean-test-env.ps1 — クリーン隔離テスト環境を作って Claude Code を起動する（手順書 §5）

.DESCRIPTION
  自分の ~/.claude / project 設定を切り離し、配布する <Share> の共有資産だけを検証する。
  空の CLAUDE_CONFIG_DIR と、.claude / CLAUDE.md / .mcp.json を持たない空の作業ディレクトリを作り、
  <Share> を --add-dir / 環境変数 / --settings で結合して起動する。

  注意:
    - managed settings は system パスにあるためクリーンセッションでも適用され続ける。
    - Windows では認証情報が config dir 配下のため再ログインを求められることがある。

.PARAMETER Share
  配布する共有ペイロード <Share> のパス。省略時は結合なしの素のクリーンセッション。

.PARAMETER Keep
  指定すると終了後に一時ディレクトリを残す（既定は削除）。

.EXAMPLE
  .\clean-test-env.ps1 -Share C:\path\to\share
#>
param(
  [string]$Share = "",
  [switch]$Keep
)

$cfg  = Join-Path $env:TEMP ("cc-clean-cfg-"  + [System.IO.Path]::GetRandomFileName())
$work = Join-Path $env:TEMP ("cc-clean-work-" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Force -Path $cfg, $work | Out-Null
Write-Host "[clean-test-env] CLAUDE_CONFIG_DIR = $cfg"
Write-Host "[clean-test-env] 作業ディレクトリ   = $work"

$env:CLAUDE_CONFIG_DIR = $cfg
$cli = @()

if ($Share -ne "") {
  if (-not (Test-Path -PathType Container $Share)) { Write-Error "<Share> が見つかりません: $Share"; exit 1 }
  $shareAbs = (Resolve-Path $Share).Path
  $cli += @("--add-dir", $shareAbs)
  $env:CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD = "1"   # CLAUDE.md / rules も結合
  Write-Host "[clean-test-env] 結合: --add-dir $shareAbs（+ CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1）"
  $settings = Join-Path $shareAbs ".claude\settings.json"
  if (Test-Path $settings) {
    $cli += @("--settings", $settings)   # settings.json は --add-dir で来ないので明示
    Write-Host "[clean-test-env] 結合: --settings $settings"
  }
}

try {
  Write-Host "[clean-test-env] 起動中... (起動後は /memory /context /status /doctor /skills /agents で検証)"
  Push-Location $work
  & claude @cli
}
finally {
  Pop-Location
  if ($Keep) {
    Write-Host "[clean-test-env] 一時ディレクトリを残しました: $cfg  $work"
  } else {
    Remove-Item -Recurse -Force $cfg, $work -ErrorAction SilentlyContinue
    Write-Host "[clean-test-env] 一時ディレクトリを削除しました（残すには -Keep）"
  }
}
