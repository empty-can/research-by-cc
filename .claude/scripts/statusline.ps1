# .claude/scripts/statusline.ps1
# Claude Code statusline - all available elements

$stream = [Console]::OpenStandardInput()
$reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)
$input_json = $reader.ReadToEnd().TrimStart([char]0xFEFF)
try {
    $data = $input_json | ConvertFrom-Json
} catch {
    $data = [PSCustomObject]@{}
}

$parts = [System.Collections.Generic.List[string]]::new()

# ── Vim mode ──────────────────────────────────────────────────────────────────
if ($null -ne $data.vim -and -not [string]::IsNullOrEmpty($data.vim.mode)) {
    $parts.Add("[{0}]" -f $data.vim.mode)
}

# ── Agent ─────────────────────────────────────────────────────────────────────
if ($null -ne $data.agent) {
    $agentLabel = if ($data.agent.name) { $data.agent.name } elseif ($data.agent.type) { $data.agent.type } else { "agent" }
    if ($data.agent.type -and $data.agent.type -ne $agentLabel) {
        $agentLabel = "{0}({1})" -f $agentLabel, $data.agent.type
    }
    $parts.Add("agent:{0}" -f $agentLabel)
}

# ── Model ─────────────────────────────────────────────────────────────────────
$model = $data.model.display_name
if ([string]::IsNullOrEmpty($model)) { $model = $data.model.id }
if (-not [string]::IsNullOrEmpty($model)) {
    $parts.Add("[{0}]" -f $model)
}

# ── Output style ──────────────────────────────────────────────────────────────
if ($null -ne $data.output_style -and -not [string]::IsNullOrEmpty($data.output_style.name) -and $data.output_style.name -ne "default") {
    $parts.Add("style:{0}" -f $data.output_style.name)
}

# ── Thinking / reasoning ──────────────────────────────────────────────────────
if ($null -ne $data.thinking -and $data.thinking.enabled -eq $true) {
    $parts.Add("thinking:on")
}
if ($null -ne $data.effort -and -not [string]::IsNullOrEmpty($data.effort.level)) {
    $parts.Add("effort:{0}" -f $data.effort.level)
}

# ── Git branch ────────────────────────────────────────────────────────────────
try {
    $b = git rev-parse --abbrev-ref HEAD 2>$null
    if ($LASTEXITCODE -eq 0 -and $b) {
        $parts.Add($b)
    }
} catch {}

# ── Workspace / directory / git repo ─────────────────────────────────────────
if ($null -ne $data.workspace) {
    $cwd        = $data.workspace.current_dir
    $projectDir = $data.workspace.project_dir
    $addedDirs  = $data.workspace.added_dirs
    $gitWt      = $data.workspace.git_worktree

    if ($cwd)        { $parts.Add("cwd:{0}" -f $cwd) }
    if ($projectDir -and $projectDir -ne $cwd) { $parts.Add("proj:{0}" -f $projectDir) }
    if ($addedDirs -and $addedDirs.Count -gt 0) { $parts.Add("added:{0}" -f ($addedDirs -join ",")) }
    if ($gitWt)      { $parts.Add("git-wt:{0}" -f $gitWt) }

    $repo = $data.workspace.repo
    if ($null -ne $repo -and $repo.owner -and $repo.name) {
        $repoStr = "{0}/{1}" -f $repo.owner, $repo.name
        if ($repo.host -and $repo.host -ne "github.com") {
            $repoStr = "{0}/{1}" -f $repo.host, $repoStr
        }
        $parts.Add("repo:{0}" -f $repoStr)
    }
}

# ── Worktree session ──────────────────────────────────────────────────────────
if ($null -ne $data.worktree) {
    $wtName   = $data.worktree.name
    $wtBranch = $data.worktree.branch
    $wtLabel  = if ($wtName) { $wtName } elseif ($wtBranch) { $wtBranch } else { "worktree" }
    if ($wtBranch -and $wtBranch -ne $wtName) {
        $wtLabel = "{0}({1})" -f $wtLabel, $wtBranch
    }
    $parts.Add("wt:{0}" -f $wtLabel)
}

# ── Open PR ───────────────────────────────────────────────────────────────────
if ($null -ne $data.pr -and $null -ne $data.pr.number) {
    $prState = if ($data.pr.review_state) { $data.pr.review_state } else { "open" }
    $parts.Add("PR#{0}({1})" -f $data.pr.number, $prState)
}

# ── Context window ────────────────────────────────────────────────────────────
function FmtTokens([int64]$n) {
    if ($n -ge 1000000) {
        return (("{0:F1}" -f ($n / 1000000.0)).TrimEnd('0').TrimEnd('.') + "M")
    }
    return (("{0:F1}" -f ($n / 1000.0)).TrimEnd('0').TrimEnd('.') + "k")
}

if ($null -ne $data.context_window -and $null -ne $data.context_window.used_percentage) {
    $usedPct = [math]::Round($data.context_window.used_percentage)
    $remPct  = if ($null -ne $data.context_window.remaining_percentage) {
                   [math]::Round($data.context_window.remaining_percentage)
               } else { 100 - $usedPct }
    $ctxStr  = "Ctx:{0}%/{1}%" -f $usedPct, $remPct

    $ctxSize  = $data.context_window.context_window_size
    $totalIn  = $data.context_window.total_input_tokens
    $totalOut = $data.context_window.total_output_tokens

    if ($ctxSize)  { $ctxStr += "({0})" -f (FmtTokens ([int64]$ctxSize)) }
    if ($null -ne $totalIn -or $null -ne $totalOut) {
        $inStr  = if ($null -ne $totalIn)  { FmtTokens ([int64]$totalIn) }  else { "0" }
        $outStr = if ($null -ne $totalOut) { FmtTokens ([int64]$totalOut) } else { "0" }
        $ctxStr += " (I/O):{0}/{1}" -f $inStr, $outStr
    }

    $cu = $data.context_window.current_usage
    if ($null -ne $cu) {
        $cacheW = if ($cu.cache_creation_input_tokens) { [int64]$cu.cache_creation_input_tokens } else { 0 }
        $cacheR = if ($cu.cache_read_input_tokens)     { [int64]$cu.cache_read_input_tokens }     else { 0 }
        if ($cacheW -or $cacheR) {
            $ctxStr += " (R/W):{0}/{1}" -f (FmtTokens $cacheR), (FmtTokens $cacheW)
        }
    }

    $parts.Add($ctxStr)
} else {
    $parts.Add("Ctx:--")
}

# ── Rate limits ───────────────────────────────────────────────────────────────
$rateParts = [System.Collections.Generic.List[string]]::new()
if ($null -ne $data.rate_limits) {
    $fiveH = $data.rate_limits.five_hour
    if ($null -ne $fiveH -and $null -ne $fiveH.used_percentage) {
        $label = "5h:{0}%" -f [math]::Floor($fiveH.used_percentage)
        if ($fiveH.resets_at) {
            $dt = [DateTimeOffset]::FromUnixTimeSeconds([int64]$fiveH.resets_at).LocalDateTime
            $label += "(rst:{0})" -f $dt.ToString("HH:mm")
        }
        $rateParts.Add($label)
    }
    $sevenD = $data.rate_limits.seven_day
    if ($null -ne $sevenD -and $null -ne $sevenD.used_percentage) {
        $label = "7d:{0}%" -f [math]::Floor($sevenD.used_percentage)
        if ($sevenD.resets_at) {
            $dt = [DateTimeOffset]::FromUnixTimeSeconds([int64]$sevenD.resets_at).LocalDateTime
            $label += "(rst:{0})" -f $dt.ToString("MM-dd HH:mm")
        }
        $rateParts.Add($label)
    }
}
if ($rateParts.Count -gt 0) {
    $parts.Add("limits:{0}" -f ($rateParts -join " "))
}

# ── App version ───────────────────────────────────────────────────────────────
if (-not [string]::IsNullOrEmpty($data.version)) {
    $parts.Add("v{0}" -f $data.version)
}

Write-Output ($parts -join " | ")
