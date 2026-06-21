<#
.SYNOPSIS
  check-payload.ps1 — 配布する共有ペイロード <Share> を公開前に機械チェックする（手順書 §6）

.DESCRIPTION
  「6. 落とし穴チェックリスト」のうちスクリプトで検査可能な項目を自動判定する。
  対話 TUI が必要な項目（trust 承認・/memory・/status の確認など）は対象外（手順書 §6 を手で確認）。

  判定基準（README 隔離方式 / 案1 対応）:
    <Share> が git リポジトリなら「Git 追跡されているか」で配布可否を判定する。
      - 個人ファイルが tracked        → FAIL（clone に含まれ参照側へ漏れる）
      - 個人ファイルが untracked で実在 → WARN（gitignore 済みで配布はされないが掃除推奨）
      - 不在                          → PASS
    git リポジトリでない（コピー展開した素のディレクトリ）なら、実在＝FAIL にフォールバックする。

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

# git リポジトリか判定
$isGit = $false
try { git -C $Share rev-parse --is-inside-work-tree 2>$null | Out-Null; if ($LASTEXITCODE -eq 0) { $isGit = $true } } catch { $isGit = $false }

function Test-Tracked($rel) {
  git -C $Share ls-files --error-unmatch $rel 2>$null | Out-Null
  return ($LASTEXITCODE -eq 0)
}

# 個人ファイル（tracked=FAIL / untracked実在=WARN / 不在=PASS、非gitは実在=FAIL）を判定
function Check-Personal($rel, $label) {
  $abs = Join-Path $Share $rel
  if ($isGit) {
    if (Test-Tracked $rel) {
      Bad "$label が Git 追跡されている（clone に含まれ参照側へ漏れる）。git rm --cached して .gitignore へ"
    } elseif (Test-Path $abs) {
      Warn "$label が実在するが未追跡（配布はされない。掃除推奨）"
    } else {
      Pass "$label なし"
    }
  } else {
    if (Test-Path $abs) {
      Bad "$label がある（非 git のためコピー展開でそのまま配布される）。削除する"
    } else {
      Pass "$label なし"
    }
  }
}

Write-Host ("[check-payload] 対象: $Share（" + $(if ($isGit) { 'git リポジトリ: 追跡基準' } else { '非 git: 実在基準' }) + "）")

# 1. 個人ファイル CLAUDE.local.md
Check-Personal 'CLAUDE.local.md'         'CLAUDE.local.md'
Check-Personal '.claude\CLAUDE.local.md' '.claude\CLAUDE.local.md'

# 2. settings.local.json
Check-Personal '.claude\settings.local.json' '.claude\settings.local.json'

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

# 4. 共有共通ルールの所在（案1 では .claude\CLAUDE.md。ルート CLAUDE.md は README 隔離の対象）
if (Test-Path (Join-Path $Share '.claude\CLAUDE.md')) {
  Pass "共有共通ルール .claude\CLAUDE.md あり（案1 構成）"
} elseif (Test-Path (Join-Path $Share 'CLAUDE.md')) {
  Warn "共有ルールがルート CLAUDE.md にある。案1（README 隔離）では .claude\CLAUDE.md へ移し、リポ固有情報は README.md へ"
} else {
  Warn "共有共通ルール（.claude\CLAUDE.md）が無い（rules/ や skills のみ配る構成なら問題なし）"
}

# 5. （案1 情報）ルート CLAUDE.md が tracked なら --add-dir+env で参照側へ漏れる旨を通知
if ($isGit -and (Test-Tracked 'CLAUDE.md')) {
  Warn "ルート CLAUDE.md が Git 追跡されている。--add-dir + CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1 で参照側にロードされる点に注意（リポ固有情報を含めない）"
}

if ($script:fail -eq 0) {
  Write-Host "[check-payload] 結果: 重大な問題なし（FAIL=0）"
} else {
  Write-Host "[check-payload] 結果: FAIL あり。上記を修正してください"
}
exit $script:fail
