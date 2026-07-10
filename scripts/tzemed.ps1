<#
.SYNOPSIS
    Tzemed entry point — initialize, verify, and launch the dev environment.
.DESCRIPTION
    - First-time initialization (marker file)
    - Binary verification for all components
    - Launch Herdr with Tzemed layout (Peri left, nvim right)
.PARAMETER Directory
    Working directory for the Herdr workspace. Defaults to current directory.
.EXAMPLE
    tzemed
    tzemed .
    tzemed C:\projects\my-app
#>

#Requires -Version 7.0

param(
    [Parameter(Position = 0)]
    [string]$Directory = ""
)

# ─── Resolve working directory ───────────────────────────────────────────────
if ([string]::IsNullOrWhiteSpace($Directory)) {
    $Cwd = (Get-Location).Path
} else {
    $resolved = Resolve-Path -Path $Directory -ErrorAction SilentlyContinue
    if (-not $resolved) {
        Write-Host "✗ Directory not found: $Directory" -ForegroundColor Red
        exit 1
    }
    $Cwd = $resolved.Path
}

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
        return $false
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

    # Resolve Scoop shims in case PATH hasn't been refreshed
    $scoopShims = "$env:USERPROFILE\scoop\shims"
    $env:PATH = "$scoopShims;$env:PATH"

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
        Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Green
    } else {
        Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Red
        Write-Host "║   Some components are missing.           ║" -ForegroundColor Red
        Write-Host "║   Run 'scoop update tzemed' to reinstall ║" -ForegroundColor Red
        Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Red
    }

    return $allPassed
}

# ─── Plugin Pre-Install (background) ──────────────────────────────────────────

function Start-PluginPreInstall {
    Write-Step "Pre-installing plugins & LSP servers (background)..."

    $script = @'
nvim --headless "+Lazy sync" +qa
if ($LASTEXITCODE -eq 0) {
    nvim --headless "+MasonInstall lua-language-server typescript-language-server pyright" +qa
}
'@

    Start-Process -NoNewWindow -FilePath "pwsh" `
        -ArgumentList "-NoProfile", "-Command", $script
    Write-Pass "Plugin pre-install launched (background)"
}

# ─── Herdr Layout ────────────────────────────────────────────────────────────

function Start-TzemedLayout {
    param(
        [string]$Cwd,
        [switch]$SkipLayout
    )

    Write-Step "Preparing Herdr Tzemed layout in: $Cwd"

    # Resolve Scoop shims
    $scoopShims = "$env:USERPROFILE\scoop\shims"
    if ($env:PATH -notlike "*$scoopShims*") {
        $env:PATH = "$scoopShims;$env:PATH"
    }

    if (-not (Get-Command herdr -ErrorAction SilentlyContinue)) {
        Write-Fail "Herdr not found — layout cannot start"
        return $false
    }

    # Attempt to create the Tzemed workspace layout via herdr CLI
    # These commands work in a real PowerShell terminal (the broken pipe
    # only occurs in non-interactive tool contexts).
    if (-not $SkipLayout) {
        $layoutOk = $false

        # 1. Create workspace with focus
        $wsOut = herdr workspace create --cwd $Cwd --label "Tzemed" --focus 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Pass "Workspace created"

            # 2. Split pane: 50% left (Peri), 50% right (nvim)
            $splitOut = herdr pane split --direction right --ratio 0.5 --cwd $Cwd 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Pass "Pane split: Peri left, nvim right (50/50)"

                # 3. Try to auto-launch nvim in the right pane
                #    After split, the new pane (right) gets focus.
                $foundNvim = $false
                try {
                    $paneCurrent = herdr pane current 2>$null
                    if ($paneCurrent) {
                        $pane = $paneCurrent | ConvertFrom-Json -ErrorAction SilentlyContinue
                        if ($pane -and $pane.id) {
                            herdr pane run $pane.id "nvim" 2>$null
                            herdr pane focus --direction left 2>$null
                            $foundNvim = $true
                        }
                    }
                } catch {
                    # fallback
                }

                # 4. Auto-launch Peri in the left pane
                if ($foundNvim) {
                    try {
                        $leftPane = herdr pane current 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue
                        if ($leftPane -and $leftPane.id) {
                            herdr pane run $leftPane.id "peri" 2>$null
                            Write-Pass "Peri launched in left pane"
                        }
                    } catch {
                        # Peri launch is non-critical
                    }
                }

                if (-not $foundNvim) {
                    # Fallback: try pane list
                    try {
                        $panes = herdr pane list 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue
                        if ($panes -and $panes.Count -ge 2) {
                        herdr pane run $panes[-1].id "nvim" 2>$null
                        herdr pane focus --direction left 2>$null
                        herdr pane run $panes[0].id "peri" 2>$null
                    }
                } catch {
                        Write-Warning "Could not auto-launch nvim (run it manually after attaching)"
                    }
                }

                $layoutOk = $true
            }
        } else {
            Write-Warning "Herdr CLI unavailable (server may not be running)"
        }

        if (-not $layoutOk) {
            Write-Host "    ℹ Layout will be created manually on attach:" -ForegroundColor Yellow
            Write-Host "      1. Press $([char]0x1b)[36mCtrl+B, V$([char]0x1b)[0m to split vertical" -ForegroundColor Yellow
            Write-Host "      2. Press $([char]0x1b)[36mCtrl+B, ←$([char]0x1b)[0m to focus left pane" -ForegroundColor Yellow
            Write-Host "      3. Run $([char]0x1b)[36mperi$([char]0x1b)[0m in the left pane" -ForegroundColor Yellow
            Write-Host "      4. Press $([char]0x1b)[36mCtrl+B, →$([char]0x1b)[0m to focus right pane" -ForegroundColor Yellow
            Write-Host "      5. Run $([char]0x1b)[36mnvim$([char]0x1b)[0m in the right pane" -ForegroundColor Yellow
        }
    }

    # Attach to herdr
    Write-Host ""
    Write-Pass "Attaching to Herdr..."
    herdr

    return $true
}

# ─── Main ────────────────────────────────────────────────────────────────────

# Guard: when dot-sourced by Pester BeforeAll, only load functions and variables
if ($MyInvocation.InvocationName -ne '.') {
    Write-Header
    $isFirstInit = Initialize-Tzemed
    Write-Host ""
    $success = Invoke-BinaryVerification
    Write-Host ""

    if ($success) {
        $dirName = Split-Path $Cwd -Leaf
        Write-Pass "Workspace directory: $dirName ($Cwd)"
        Write-Host ""

        if ($isFirstInit) {
            Start-PluginPreInstall
        }

        Start-TzemedLayout -Cwd $Cwd
        exit 0
    } else {
        exit 2
    }
}
