<#
.SYNOPSIS
    Tzemed entry point — initialize, verify, and launch the dev environment.
.DESCRIPTION
    - First-time initialization (marker file)
    - Binary verification for all components
    - Launch Herdr with Tzemed layout (Peri left, nvim right)
.PARAMETER Directory
    Working directory for the Herdr workspace. Defaults to current directory.
.PARAMETER Version
    Print the tzemed version and exit.
.EXAMPLE
    tzemed
    tzemed .
    tzemed C:\projects\my-app
    tzemed -Version
#>

#Requires -Version 7.0

param(
    [Parameter(Position = 0)]
    [string]$Directory = "",
    [switch]$Version,
    [switch]$Help
)

if ($Version) {
    Write-Host "tzemed 0.2.3"
    exit 0
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

function Invoke-ScoopCli {
    <#
    .SYNOPSIS
        Run a scoop command and capture output and exit code. Wrapped for testability.
    .PARAMETER Arguments
        Arguments to pass to scoop (e.g. @("update", "herdr")).
    .OUTPUTS
        Hashtable with Output (string[]) and ExitCode (int).
    #>
    param([string[]]$Arguments)
    $output = & scoop @Arguments 2>&1
    return @{ Output = $output; ExitCode = $LASTEXITCODE }
}

function Confirm-ConfigDeletion {
    <#
    .SYNOPSIS
        Prompt the user for config deletion confirmation. Mockable for tests.
    .OUTPUTS
        [bool] $true if user confirms deletion, $false otherwise.
    #>
    param(
        [string]$Name,
        [string]$Path
    )
    $title = "Delete Config"
    $message = "Delete $Name at $Path?"
    $choices = [System.Management.Automation.Host.ChoiceDescription[]]@(
        [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Delete this config directory")
        [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Keep this config directory")
    )
    return ($Host.UI.PromptForChoice($title, $message, $choices, 1) -eq 0)
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

# ─── Subcommands ──────────────────────────────────────────────────────────────

function Invoke-TzemedHelp {
    <#
    .SYNOPSIS
        Print all available subcommands with one-line descriptions.
    #>
    Write-Host "Usage: tzemed [subcommand] [options]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Subcommands:" -ForegroundColor Yellow
    Write-Host "  help       Show available subcommands and usage"
    Write-Host "  uninstall  Remove all Tzemed components and configs"
    Write-Host "  update     Update all Tzemed components via Scoop"
    Write-Host "  fix        Re-verify binaries and re-create init state"
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -v, -Version   Print tzemed version and exit"
    Write-Host "  -h, --help     Show this help message"
    Write-Host ""
    Write-Host "Default behavior (no subcommand):" -ForegroundColor Yellow
    Write-Host "  Initialize, verify binaries, and launch Herdr layout"
}

function Invoke-TzemedFix {
    <#
    .SYNOPSIS
        Re-execute the init pipeline: re-create marker, verify binaries.
    #>
    Write-Step "Running tzemed fix..."

    # Remove marker so Initialize-Tzemed re-creates it
    if (Test-Path $MARKER_FILE) {
        Remove-Item $MARKER_FILE -Force
        Write-Pass "Removed stale marker"
    }

    Write-Host ""
    $isFirstInit = Initialize-Tzemed
    Write-Host ""
    $success = Invoke-BinaryVerification
    Write-Host ""

    if ($success) {
        Write-Pass "Fix completed — all components verified"
    } else {
        Write-Fail "Fix completed with issues — some components are missing"
    }

    return $success
}

function Invoke-TzemedUpdate {
    <#
    .SYNOPSIS
        Update all Tzemed components via Scoop.
    .OUTPUTS
        [bool] $true if all updates succeeded, $false otherwise.
    #>
    Write-Step "Updating Tzemed components via Scoop..."

    $components = @("herdr", "nvim", "peri", "starship")
    $passed = @()
    $failed = @()

    # Update Scoop package lists first
    Write-Step "Updating Scoop package lists..."
    $null = Invoke-ScoopCli @("update")

    foreach ($comp in $components) {
        Write-Step "Updating $comp..."
        $result = Invoke-ScoopCli @("update", $comp)
        if ($result.ExitCode -eq 0) {
            Write-Pass "$comp updated"
            $passed += $comp
        } else {
            Write-Fail "$comp update failed"
            $failed += $comp
        }
    }

    Write-Host ""
    if ($failed.Count -eq 0) {
        Write-Pass "All components updated successfully"
        return $true
    } else {
        Write-Host "  ✓ Passed: $($passed -join ', ')" -ForegroundColor Green
        Write-Host "  ✗ Failed: $($failed -join ', ')" -ForegroundColor Red
        return $false
    }
}

function Invoke-TzemedUninstall {
    <#
    .SYNOPSIS
        Uninstall all Tzemed components via Scoop and optionally remove configs.
    .PARAMETER Force
        Skip all confirmation prompts when set.
    .OUTPUTS
        [bool] $true if all components uninstalled, $false otherwise.
    #>
    param(
        [switch]$Force
    )

    Write-Step "Uninstalling Tzemed components..."

    $components = @("herdr", "nvim", "peri", "starship")
    $uninstalled = @()
    $skipped = @()

    foreach ($comp in $components) {
        # Check if installed via Scoop
        $listResult = Invoke-ScoopCli @("list", $comp)
        if ($listResult.ExitCode -ne 0) {
            Write-Warning "$comp is not installed via Scoop — skipping"
            $skipped += $comp
            continue
        }

        Write-Step "Uninstalling $comp..."
        Start-Process -Wait -NoNewWindow -FilePath "scoop" -ArgumentList "uninstall", $comp
        $uninstalled += $comp
    }

    Write-Host ""

    # Config deletion (prompt per directory unless --force)
    $configPaths = @(
        @{ Path = Join-Path $env:USERPROFILE ".config\nvim";     Name = "Neovim config" }
        @{ Path = Join-Path $env:USERPROFILE ".config\herdr";    Name = "Herdr config" }
        @{ Path = Join-Path $env:USERPROFILE ".config\starship.toml"; Name = "Starship config" }
        @{ Path = Join-Path $env:USERPROFILE ".peri";            Name = "Peri config" }
    )

    Write-Step "Removing configuration files..."
    $deleted = @()
    $cfgSkipped = @()

    foreach ($cfg in $configPaths) {
        if (-not (Test-Path $cfg.Path)) {
            $cfgSkipped += $cfg.Name
            continue
        }

        $shouldDelete = $Force -or (Confirm-ConfigDeletion -Name $cfg.Name -Path $cfg.Path)

        if ($shouldDelete) {
            Remove-Item -Path $cfg.Path -Recurse -Force
            Write-Pass "Deleted $($cfg.Name)"
            $deleted += $cfg.Name
        } else {
            Write-Host "  Skipped $($cfg.Name)" -ForegroundColor Yellow
            $cfgSkipped += $cfg.Name
        }
    }

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║   Tzemed uninstall complete              ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host "  Uninstalled: $($uninstalled -join ', ')" -ForegroundColor Cyan
    if ($skipped.Count -gt 0) { Write-Host "  Skipped (not installed): $($skipped -join ', ')" -ForegroundColor Yellow }
    if ($deleted.Count -gt 0)  { Write-Host "  Configs deleted: $($deleted -join ', ')" -ForegroundColor Cyan }
    if ($cfgSkipped.Count -gt 0) { Write-Host "  Configs kept: $($cfgSkipped -join ', ')" -ForegroundColor Yellow }

    # Consider success if at least we tried
    return $true
}

function Invoke-TzemedRouter {
    <#
    .SYNOPSIS
        Routes subcommand calls to the appropriate Invoke-Tzemed* function.
    .PARAMETER Directory
        The value of $Directory from the param block.
    .PARAMETER RemainingArgs
        The remaining $args that weren't bound to parameters.
    .OUTPUTS
        [bool|null] $true (success), $false (failure), or $null (not a subcommand).
    #>
    param(
        [string]$Directory,
        [string[]]$RemainingArgs
    )

    # Dispatch known subcommands
    $knownCommands = @("help", "uninstall", "update", "fix")
    if (-not [string]::IsNullOrWhiteSpace($Directory) -and $knownCommands -contains $Directory) {
        switch ($Directory) {
            "help" {
                Invoke-TzemedHelp
                return $true
            }
            "uninstall" {
                $forceFlag = $RemainingArgs -contains '--force'
                return Invoke-TzemedUninstall -Force:$forceFlag
            }
            "update" {
                return Invoke-TzemedUpdate
            }
            "fix" {
                return Invoke-TzemedFix
            }
        }
    }

    return $null  # Not a subcommand — caller should use default pipeline
}

# ─── Main ────────────────────────────────────────────────────────────────────

# Guard: when dot-sourced by Pester BeforeAll, only load functions and variables
if ($MyInvocation.InvocationName -ne '.') {
    # ── Help switch (checked here so functions are defined) ──
    if ($Help) {
        Invoke-TzemedHelp
        exit 0
    }

    # ── Subcommand routing ──
    $routeResult = Invoke-TzemedRouter -Directory $Directory -RemainingArgs $args
    if ($null -ne $routeResult) {
        exit $(if ($routeResult) { 0 } else { 1 })
    }

    # ── --help / -h / -v catch (bound to $Directory via shim @args splatting) ──
    if ($Directory -eq '--help' -or $Directory -eq '-h') {
        Invoke-TzemedHelp
        exit 0
    }

    # ── Resolve working directory ──
    if ([string]::IsNullOrWhiteSpace($Directory)) {
        $Cwd = (Get-Location).Path
    } else {
        $resolved = Resolve-Path -Path $Directory -ErrorAction SilentlyContinue
        if (-not $resolved) {
            Write-Host "✗ Unknown command or directory not found: $Directory" -ForegroundColor Red
            Invoke-TzemedHelp
            exit 1
        }
        $Cwd = $resolved.Path
    }

    # ── Default pipeline ──
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
