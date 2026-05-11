# .claude/scripts/statusline.ps1
# Claude Code statusline script for OWX project
#
# Display: [Model] branch | Ctx: XX% | $X.XX | +N -N

$input_json = [Console]::In.ReadToEnd()
$data = $input_json | ConvertFrom-Json

# 1. Model name
$model = $data.model.display_name

# 2. Git branch
$branch = ""
try {
    $b = git rev-parse --abbrev-ref HEAD 2>$null
    if ($LASTEXITCODE -eq 0 -and $b) {
        $branch = " $b"
    }
} catch {}

# 3. Context usage percentage
$ctx = 0
if ($null -ne $data.context_window -and $null -ne $data.context_window.used_percentage) {
    $ctx = [math]::Floor($data.context_window.used_percentage)
}

# 4. Session cost
$cost = 0.0
if ($null -ne $data.cost -and $null -ne $data.cost.total_cost_usd) {
    $cost = $data.cost.total_cost_usd
}
$costFmt = '$' + ('{0:F2}' -f $cost)

# 5. Lines added / removed
$added = 0
$removed = 0
if ($null -ne $data.cost) {
    if ($null -ne $data.cost.total_lines_added)   { $added   = $data.cost.total_lines_added }
    if ($null -ne $data.cost.total_lines_removed)  { $removed = $data.cost.total_lines_removed }
}
$lines = "+${added} -${removed}"

# Build output
Write-Output "[$model]$branch | Ctx: ${ctx}% | $costFmt | $lines"
