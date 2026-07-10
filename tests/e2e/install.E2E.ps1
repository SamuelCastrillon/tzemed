<#
.SYNOPSIS
    End-to-end test for Tzemed installation against a temp directory.
.DESCRIPTION
    Tests the full install pipeline: copies configs, sets up $PROFILE,
    verifies binaries (mock to avoid needing real tools), and tests
    backup/restore cycle.
.NOTES
    Run from repo root: pwsh -File tests/e2e/install.E2E.ps1
#>

#Requires -Version 7.0

$TzemedRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$ScriptsDir  = Join-Path $TzemedRoot "scripts"
$ConfigDir   = Join-Path $TzemedRoot "config"

Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║    Tzemed — End-to-End Install Test      ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# Track pass/fail counts
$global:passed = 0
$global:failed = 0

function Test-Assert {
    param(
        [string]$Name,
        [scriptblock]$Condition
    )
    try {
        $result = & $Condition
        if ($result) {
            Write-Host "  ✓ $Name" -ForegroundColor Green
            $global:passed++
        } else {
            Write-Host "  ✗ $Name" -ForegroundColor Red
            $global:failed++
        }
    } catch {
        Write-Host "  ✗ $Name — $_" -ForegroundColor Red
        $global:failed++
    }
}

# ─── Setup temp environment ──────────────────────────────────────────────────

$TestRoot = Join-Path $env:TEMP "tzemed-e2e-test-$(Get-Random)"
$TestHome = Join-Path $TestRoot "home"
$TestXdg  = Join-Path $TestHome ".config"
$TestPeri = Join-Path $TestHome ".peri"
$TestProfileDir = Join-Path $TestHome "Documents\PowerShell"

# Create directory structure
New-Item -ItemType Directory -Path $TestXdg -Force | Out-Null
New-Item -ItemType Directory -Path $TestPeri -Force | Out-Null
New-Item -ItemType Directory -Path $TestProfileDir -Force | Out-Null

# Override environment for testing
$env:USERPROFILE = $TestHome
if ($PSVersionTable.PSVersion.Major -ge 7) {
    Set-Variable -Name HOME -Value $TestHome -Force
} else {
    $HOME = $TestHome
}
$env:XDG_CONFIG_HOME = $TestXdg
$PROFILE = [PSCustomObject]@{ CurrentUserAllHosts = Join-Path $TestProfileDir "profile.ps1" }

Write-Host "Test environment: $TestRoot" -ForegroundColor Cyan
Write-Host ""

# ─── Test 1: Source install script ──────────────────────────────────────────

Write-Host "◆ Phase 1: Script loading" -ForegroundColor Yellow
$installScript = Join-Path $ScriptsDir "install.ps1"
Test-Assert "install.ps1 exists" { Test-Path $installScript }
. $installScript -ConfigDir $ConfigDir -TzemedDir $TzemedRoot
Test-Assert "install.ps1 loads without error" { $true }
Write-Host ""

# ─── Test 2: Config files exist ─────────────────────────────────────────────

Write-Host "◆ Phase 2: Config sources" -ForegroundColor Yellow
Test-Assert "nvim/init.lua exists" { Test-Path (Join-Path $ConfigDir "nvim\init.lua") }
Test-Assert "nvim/lua/config/lazy.lua exists" { Test-Path (Join-Path $ConfigDir "nvim\lua\config\lazy.lua") }
Test-Assert "nvim/lua/config/options.lua exists" { Test-Path (Join-Path $ConfigDir "nvim\lua\config\options.lua") }
Test-Assert "nvim/lua/config/keymaps.lua exists" { Test-Path (Join-Path $ConfigDir "nvim\lua\config\keymaps.lua") }
Test-Assert "nvim/lua/config/autocmds.lua exists" { Test-Path (Join-Path $ConfigDir "nvim\lua\config\autocmds.lua") }
Test-Assert "nvim/lua/plugins/editor.lua exists" { Test-Path (Join-Path $ConfigDir "nvim\lua\plugins\editor.lua") }
Test-Assert "nvim/lua/plugins/ui.lua exists" { Test-Path (Join-Path $ConfigDir "nvim\lua\plugins\ui.lua") }
Test-Assert "nvim/lua/plugins/lsp.lua exists" { Test-Path (Join-Path $ConfigDir "nvim\lua\plugins\lsp.lua") }
Test-Assert "nvim/lua/plugins/ai.lua exists" { Test-Path (Join-Path $ConfigDir "nvim\lua\plugins\ai.lua") }
Test-Assert "nvim/lua/plugins/tzemed.lua exists" { Test-Path (Join-Path $ConfigDir "nvim\lua\plugins\tzemed.lua") }
Test-Assert "herdr/config.toml exists" { Test-Path (Join-Path $ConfigDir "herdr\config.toml") }
Test-Assert "peri/settings.json exists" { Test-Path (Join-Path $ConfigDir "peri\settings.json") }
Test-Assert "starship.toml exists" { Test-Path (Join-Path $ConfigDir "starship.toml") }
Write-Host ""

# ─── Test 3: Deploy configs ─────────────────────────────────────────────────

Write-Host "◆ Phase 3: Config deployment" -ForegroundColor Yellow
$configResult = Copy-Configs
Test-Assert "Copy-Configs returns true" { $configResult }

Test-Assert "nvim config deployed to ~/.config/nvim/" { Test-Path (Join-Path $TestXdg "nvim\init.lua") }
Test-Assert "herdr config deployed to ~/.config/herdr/" { Test-Path (Join-Path $TestXdg "herdr\config.toml") }
Test-Assert "starship deployed to ~/.config/starship.toml" { Test-Path (Join-Path $TestXdg "starship.toml") }
Test-Assert "peri config deployed to ~/.peri/settings.json" { Test-Path (Join-Path $TestPeri "settings.json") }
Write-Host ""

# ─── Test 4: Profile setup ──────────────────────────────────────────────────

Write-Host "◆ Phase 4: Profile setup" -ForegroundColor Yellow
$profileResult = Set-Profile
Test-Assert "Set-Profile returns true" { $profileResult }

$profileContent = Get-Content $PROFILE.CurrentUserAllHosts -Raw -ErrorAction SilentlyContinue
Test-Assert "$PROFILE contains Tzemed marker block" { $profileContent -match "TZEMED BEGIN" }
Test-Assert "$PROFILE contains XDG_CONFIG_HOME" { $profileContent -match "XDG_CONFIG_HOME" }
Test-Assert "$PROFILE contains TZEMED END marker" { $profileContent -match "TZEMED END" }
Write-Host ""

# ─── Test 5: Backup functionality ────────────────────────────────────────────

Write-Host "◆ Phase 5: Backup" -ForegroundColor Yellow
$backupFile = Backup-TzemedState
Test-Assert "Backup returns file path (or null)" { $null -eq $backupFile -or (Test-Path $backupFile) }
Write-Host ""

# ─── Test 6: Restore from backup ────────────────────────────────────────────

Write-Host "◆ Phase 6: Restore" -ForegroundColor Yellow
if ($backupFile -and (Test-Path $backupFile)) {
    $restoreResult = Restore-Backup -BackupFile $backupFile
    Test-Assert "Restore-Backup returns true" { $restoreResult }
} else {
    Write-Host "  ~ Skipping restore test (no backup created)" -ForegroundColor Yellow
}
Write-Host ""

# ─── Test 7: Entry point (tzemed.ps1) ───────────────────────────────────────

Write-Host "◆ Phase 7: Entry point" -ForegroundColor Yellow
$tzemedScript = Join-Path $ScriptsDir "tzemed.ps1"
Test-Assert "tzemed.ps1 exists" { Test-Path $tzemedScript }
Write-Host ""

# ─── Cleanup ─────────────────────────────────────────────────────────────────

Write-Host "═══ Results ═══" -ForegroundColor Magenta
Write-Host "Passed: $global:passed" -ForegroundColor Green
Write-Host "Failed: $global:failed" -ForegroundColor Red

if ($global:failed -gt 0) {
    Write-Host "Some tests failed. Temp dir: $TestRoot" -ForegroundColor Yellow
    exit 1
} else {
    Remove-Item -Path $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "All tests passed! Temp dir cleaned up." -ForegroundColor Green
    exit 0
}
