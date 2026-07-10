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
    Write-Host "████████╗███████╗███████╗███╗   ███╗███████╗██████╗ " -ForegroundColor DarkMagenta
    Write-Host "╚══██╔══╝╚══███╔╝██╔════╝████╗ ████║██╔════╝██╔══██╗" -ForegroundColor DarkMagenta
    Write-Host "   ██║     ███╔╝ █████╗  ██╔████╔██║█████╗  ██║  ██║" -ForegroundColor DarkMagenta
    Write-Host "   ██║    ███╔╝  ██╔══╝  ██║╚██╔╝██║██╔══╝  ██║  ██║" -ForegroundColor DarkMagenta
    Write-Host "   ██║   ███████╗███████╗██║ ╚═╝ ██║███████╗██████╔╝" -ForegroundColor DarkMagenta
    Write-Host "   ╚═╝   ╚══════╝╚══════╝╚═╝     ╚═╝╚══════╝╚═════╝ " -ForegroundColor DarkMagenta
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
            $output = & $comp.Command $comp.Args 2>&1
            $exitCode = $LASTEXITCODE
            $firstLine = $output | Select-Object -First 1
            if ($exitCode -eq 0 -and $firstLine) {
                Write-Pass "$($comp.Name) → $($firstLine.Trim())"
                $results += @{ Component = $comp.Name; Status = "pass"; Version = $firstLine.Trim() }
            } else {
                throw "exit code $exitCode"
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

function Start-HerdrServer {
    <#
    .SYNOPSIS
        Ensures the Herdr headless server is running. Returns $true if server is
        available for API commands within the retry budget.
    #>
    param([string]$Cwd)

    # Resolve Scoop shims
    $scoopShims = "$env:USERPROFILE\scoop\shims"
    $env:PATH = "$scoopShims;$env:PATH"

    if (-not (Get-Command herdr -ErrorAction SilentlyContinue)) {
        Write-Fail "Herdr not found"
        return $false
    }

    $socketPath = "$env:USERPROFILE\.config\herdr\herdr.sock"

    # Check if server is already running
    $null = herdr status server 2>&1
    if ($LASTEXITCODE -eq 0) {
        return $true
    }

    # Try starting the server
    Write-Step "Starting Herdr server (headless)..."
    $herdrExe = (Get-Command herdr).Source
    $null = Start-Process -WindowStyle Hidden -FilePath $herdrExe -ArgumentList "server"

    # Poll for server readiness (up to 3 seconds)
    $maxRetries = 6
    $retryDelay = 500
    for ($i = 0; $i -lt $maxRetries; $i++) {
        Start-Sleep -Milliseconds $retryDelay
        $null = herdr status server 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Pass "Herdr server ready"
            return $true
        }
    }

    Write-Warning "Herdr server did not respond in time — layout will be skipped"
    return $false
}

function Start-TzemedLayout {
    <#
    .SYNOPSIS
        Best-effort layout setup (60/40 split, Peri left, nvim right).
        NEVER blocks the final Herdr attach — layout failures are warnings.
    #>
    param(
        [string]$Cwd,
        [switch]$SkipLayout
    )

    Write-Step "Preparing Herdr Tzemed layout in: $Cwd"

    if (-not (Get-Command herdr -ErrorAction SilentlyContinue)) {
        Write-Fail "Herdr not found — attach only, no layout"
        return $false
    }

    if ($SkipLayout) {
        return $false
    }

    # 1. Ensure server is running
    $serverReady = Start-HerdrServer
    if (-not $serverReady) {
        return $false
    }

    # 2. Create workspace (idempotent if already exists)
    $wsOutput = herdr workspace create --cwd $Cwd --label "Tzemed" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Pass "Workspace created"
    } else {
        Write-Warning "Could not create workspace (exit code: $LASTEXITCODE)"
        Write-Debug "ws output: $wsOutput"
        # Non-fatal — continue to try pane setup
    }

    # 3. Split pane: 60% left, 40% right
    $splitOutput = herdr pane split --direction right --ratio 0.6 --cwd $Cwd 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Pass "Pane split: 60/40 (left 60%, right 40%)"
    } else {
        Write-Warning "Could not split pane (exit code: $LASTEXITCODE)"
        Write-Debug "split output: $splitOutput"
    }

    # 4. Discover panes via pane list
    $paneJson = herdr pane list 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Could not list panes — layout partially applied"
        return $false
    }

    $panes = $paneJson | ConvertFrom-Json -ErrorAction SilentlyContinue
    if (-not $panes -or $panes.Count -lt 2) {
        Write-Warning "Expected at least 2 panes but found $($panes.Count)"
        return $false
    }
    Write-Pass "Detected $($panes.Count) panes (pane[0] = left, pane[1] = right)"

    # 5. Launch Peri in left pane (pane[0] = 60%)
    $null = herdr pane run $panes[0].id "peri" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Pass "Peri launched in left pane"
    } else {
        Write-Warning "Could not launch Peri in left pane"
    }

    # 6. Launch nvim in right pane (pane[1] = 40%)
    $null = herdr pane run $panes[1].id "nvim" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Pass "nvim launched in right pane"
    } else {
        Write-Warning "Could not launch nvim in right pane"
    }

    # 7. Focus left pane (best-effort)
    $null = herdr pane focus --direction left 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Could not focus left pane"
    }

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

        $null = Start-TzemedLayout -Cwd $Cwd

        # Always attach — layout is best-effort
        Write-Host ""
        Write-Pass "Attaching to Herdr..."
        herdr
        exit 0
    } else {
        exit 2
    }
}
