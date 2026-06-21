<#
.SYNOPSIS
  check-payload.ps1 — 配布する共有ペイロード <Share> を公開前に機械チェックする（手順書 §6）

.DESCRIPTION
  「6. 落とし穴チェックリスト」のうちスクリプトで検査可能な項目を自動判定する。
  対話 TUI が必要な項目（trust 承認・/memory・/status の確認など）は対象外（手順書 §6 を手で確認）。
  FAIL が1件以上で終了コード 1、なければ 0（CI 利用可）。

.EXAMPLE
  .\check-payload.ps1 -Share C:\path\to\share
#>
param(
  [Parameter(Mandatory = $true)][string]$Share
)

if (-not (Test-Path -PathType Container $Share)) { Write-Error "ディレクトリが見つかりません: $Share"; exit 2 }
$Share = (Resolve-Path $Share).Path

$script:fail = 0
function Pass($m) { Write-Host "  [PASS] $m" }
function Bad($m)  { Write-Host "  [FAIL] $m" -ForegroundColor Red;    $script:fail = 1 }
function Warn($m) { Write-Host "  [WARN] $m" -ForegroundColor Yellow }

Write-Host "[check-payload] 対象: $Share"

# 1. 個人ファイル CLAUDE.local.md を共有ペイロードに含めない
if ((Test-Path (Join-Path $Share 'CLAUDE.local.md')) -or (Test-Path (Join-Path $Share '.claude\CLAUDE.local.md'))) {
  Bad "CLAUDE.local.md が <Share> にある（個人ファイル・--add-dir+env で参照側へ漏れる）。削除する"
} else {
  Pass "CLAUDE.local.md なし"
}

# 2. settings.local.json を共有ペイロードに含めない
if (Test-Path (Join-Path $Share '.claude\settings.local.json')) {
  Bad ".claude\settings.local.json が <Share> にある（個人・非共有）。共有設定は settings.json へ"
} else {
  Pass "settings.local.json なし"
}

# 3. settings.json の JSON 構文 ＋ project/local で無視される security キーの検出
$settings = Join-Path $Share '.claude\settings.json'
if (Test-Path $settings) {
  $json = $null
  try { $json = Get-Content $settings -Raw | ConvertFrom-Json } catch { $json = $null }
  if ($null -eq $json) {
    Bad "settings.json が不正な JSON（/doctor でも検出される）"
  } else {
    Pass "settings.json は valid JSON"
    $hits = @()
    if ($json.defaultMode -eq 'auto')                       { $hits += 'defaultMode:auto' }
    if ($null -ne $json.skipDangerousModePermissionPrompt)  { $hits += 'skipDangerousModePermissionPrompt' }
    if ($null -ne $json.autoMode)                           { $hits += 'autoMode' }
    if ($null -ne $json.useAutoModeDuringPlan)              { $hits += 'useAutoModeDuringPlan' }
    if ($hits.Count -gt 0) {
      Warn ("project/local では無視される可能性のあるキー: " + ($hits -join ', ') + "（効かせるなら ~/.claude/settings.json へ）")
    } else {
      Pass "project/local 無視キーなし（settings.json）"
    }
  }
} else {
  Warn "settings.json が無い（settings を共有しない構成なら問題なし）"
}

# 4. 共通ルール CLAUDE.md の存在（情報）
if ((Test-Path (Join-Path $Share 'CLAUDE.md')) -or (Test-Path (Join-Path $Share '.claude\CLAUDE.md'))) {
  Pass "共通ルール CLAUDE.md あり"
} else {
  Warn "CLAUDE.md（共通ルール）が無い（rules/ や skills のみ配る構成なら問題なし）"
}

if ($script:fail -eq 0) {
  Write-Host "[check-payload] 結果: 重大な問題なし（FAIL=0）"
} else {
  Write-Host "[check-payload] 結果: FAIL あり。上記を修正してください"
}
exit $script:fail
