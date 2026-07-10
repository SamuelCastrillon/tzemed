<#
.SYNOPSIS
    Tzemed entry point — initialize and verify the development stack.
.DESCRIPTION
    Runs post-install initialization and per-component binary verification.
    Idempotent — safe to run multiple times.
    Uses ~/.config/tzemed.init marker file to skip re-initialization.
.EXAMPLE
    tzemed
#>

#Requires -Version 7.0

$XDG_CONFIG_HOME = Join-Path $HOME ".config"
$MARKER_FILE     = Join-Path $XDG_CONFIG_HOME "tzemed.init"

# ─── Helpers ─────────────────────────────────────────────────────────────────

function Write-Header {
    Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           Tzemed — Dev Stack             ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Message)
    Write-Host "  ➜ $Message" -ForegroundColor Cyan
}

function Write-Pass {
    param([string]$Message)
    Write-Host "    ✓ $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "    ✗ $Message" -ForegroundColor Red
}

# ─── Initialization ──────────────────────────────────────────────────────────

function Initialize-Tzemed {
    Write-Step "Checking initialization status..."

    if (Test-Path $MARKER_FILE) {
        Write-Pass "Already initialized (marker found: $MARKER_FILE)"
        $initStatus = Get-Content $MARKER_FILE -Raw -ErrorAction SilentlyContinue
        if ($initStatus) {
            Write-Pass "Init: $initStatus"
        }
        return $true
    }

    Write-Step "First-time initialization..."

    # Source $PROFILE to pick up XDG_CONFIG_HOME if recently set
    $profilePath = $PROFILE.CurrentUserAllHosts
    if (Test-Path $profilePath) {
        . $profilePath
    }

    # Create marker file
    $initDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Set-Content -Path $MARKER_FILE -Value "Initialized on $initDate"
    Write-Pass "Marker created: $MARKER_FILE"
    return $true
}

# ─── Verification ────────────────────────────────────────────────────────────

function Invoke-BinaryVerification {
    Write-Step "Verifying stack components..."

    $allPassed = $true
    $results = @()

    $components = @(
        @{ Name = "Herdr";    Command = "herdr";    Args = @("--version") }
        @{ Name = "Neovim";   Command = "nvim";     Args = @("--version") }
        @{ Name = "Peri";     Command = "peri";     Args = @("--version") }
        @{ Name = "Starship"; Command = "starship"; Args = @("--version") }
    )

    foreach ($comp in $components) {
        try {
            $output = & $comp.Command $comp.Args 2>&1 | Select-Object -First 1
            if ($LASTEXITCODE -eq 0 -and $output) {
                Write-Pass "$($comp.Name) → $($output.Trim())"
                $results += @{ Component = $comp.Name; Status = "pass"; Version = $output.Trim() }
            } else {
                throw "exit code $LASTEXITCODE"
            }
        } catch {
            Write-Fail "$($comp.Name) — not found or failed"
            $results += @{ Component = $comp.Name; Status = "fail"; Version = $null }
            $allPassed = $false
        }
    }

    Write-Host ""

    if ($allPassed) {
        Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║   All components ready!                  ║" -ForegroundColor Green
        Write-Host "║                                          ║" -ForegroundColor Green
        Write-Host "║   Next: run 'herdr' to start coding     ║" -ForegroundColor Green
        Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Green
    } else {
        Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Red
        Write-Host "║   Some components are missing.           ║" -ForegroundColor Red
        Write-Host "║   Run 'scoop update tzemed' to reinstall ║" -ForegroundColor Red
        Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Red
    }

    return $allPassed
}

# ─── Main ────────────────────────────────────────────────────────────────────

Write-Header
Initialize-Tzemed
Write-Host ""
$success = Invoke-BinaryVerification

if (-not $success) {
    exit 2
}

exit 0
