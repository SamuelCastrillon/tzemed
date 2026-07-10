<#
.SYNOPSIS
    Run Neovim :checkhealth using Tzemed config.
.DESCRIPTION
    Launches nvim --headless with Tzemed config and runs :checkhealth.
    Reports pass/fail for each health check section.
.NOTES
    Requires Neovim and the Tzemed config to be deployed.
    Config path: ~/.config/nvim/ (via XDG_CONFIG_HOME or default).
#>

#Requires -Version 7.0

Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║     Tzemed — Nvim Health Check            ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# Check if nvim is available
if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) {
    Write-Host "✗ nvim not found. Install it via 'scoop install neovim'" -ForegroundColor Red
    exit 1
}

Write-Host "➜ Running: nvim --headless -c 'checkhealth' -c 'qall'" -ForegroundColor Cyan
Write-Host ""

# Run checkhealth and capture output
try {
    $output = nvim --headless +"checkhealth" +"qall" 2>&1
    $exitCode = $LASTEXITCODE
} catch {
    Write-Host "✗ Failed to run nvim: $_" -ForegroundColor Red
    exit 1
}

# Process output
$allOk = $true
$currentPlugin = ""
$errorCount = 0
$warningCount = 0

foreach ($line in $output) {
    $line = $line.ToString()

    if ($line -match "^## (.+)") {
        $currentPlugin = $matches[1].Trim()
        Write-Host "`n◆ $currentPlugin" -ForegroundColor Yellow
    }
    elseif ($line -match "^\s*✓") {
        Write-Host "  $line" -ForegroundColor Green
    }
    elseif ($line -match "^\s*✗|^\s*ERROR") {
        Write-Host "  $line" -ForegroundColor Red
        $errorCount++
        $allOk = $false
    }
    elseif ($line -match "^\s*~|^\s*WARNING") {
        Write-Host "  $line" -ForegroundColor Yellow
        $warningCount++
    }
}

Write-Host ""
Write-Host "═══ Health Summary ═══" -ForegroundColor Magenta
if ($allOk) {
    Write-Host "✔ All health checks passed!" -ForegroundColor Green
} else {
    Write-Host "✗ $errorCount errors, $warningCount warnings found" -ForegroundColor Yellow
}

exit $(if ($allOk) { 0 } else { 1 })
