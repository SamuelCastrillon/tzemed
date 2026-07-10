<#
.SYNOPSIS
    Tzemed installer — deploys configs, sets up $PROFILE, validates binaries.
.DESCRIPTION
    This script is called as Scoop's post_install from tzemed.json.
    It performs the full Tzemed installation pipeline:

    Check-Requirements → Backup-TzemedState → Copy-Configs → Set-Profile → Verify-Binaries

    On any Verify-Binaries failure, Restore-Backup is triggered automatically.
.PARAMETER ConfigDir
    Path to the config/ directory within the Scoop install.
.PARAMETER TzemedDir
    Path to the Tzemed installation root (Scoop dir).
.EXAMPLE
    .\scripts\install.ps1 -ConfigDir "C:\Users\me\scoop\apps\tzemed\1.0.0\config"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigDir,

    [Parameter(Mandatory = $true)]
    [string]$TzemedDir
)

#Requires -Version 7.0

# ─── Configuration ───────────────────────────────────────────────────────────
$XDG_CONFIG_HOME = Join-Path $HOME ".config"
$PERI_CONFIG_DIR = Join-Path $HOME ".peri"
$BACKUP_ROOT     = Join-Path $XDG_CONFIG_HOME "tzemed.backup"
$MARKER_FILE     = Join-Path $XDG_CONFIG_HOME "tzemed.init"
$BACKUP_PREFIX   = "tzemed-backup"
$REQUIRED_OS_BUILD = 17763  # Windows 10 1809

# ─── Helper Functions ────────────────────────────────────────────────────────

function Write-Step {
    param([string]$Message)
    Write-Host "➜ $Message" -ForegroundColor Cyan
}

function Write-Pass {
    param([string]$Message)
    Write-Host "  ✓ $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "  ✗ $Message" -ForegroundColor Red
}

# ─── Task 1.2: Check-Requirements ───────────────────────────────────────────

function Check-Requirements {
    Write-Step "Checking system requirements..."

    # Check Windows version
    $os = Get-CimInstance Win32_OperatingSystem
    $build = $os.BuildNumber -as [int]
    if ($build -lt $REQUIRED_OS_BUILD) {
        Write-Fail "Windows build $build is below minimum $REQUIRED_OS_BUILD (Windows 10 1809)."
        return $false
    }
    Write-Pass "Windows build $build ≥ $REQUIRED_OS_BUILD"

    # Check Scoop
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-Fail "Scoop is not installed. Install it from https://scoop.sh first."
        return $false
    }
    Write-Pass "Scoop found"

    # Check PowerShell execution policy
    $execPolicy = Get-ExecutionPolicy -Scope CurrentUser
    if ($execPolicy -eq "Restricted") {
        Write-Fail "Execution policy is Restricted. Run: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser"
        return $false
    }
    Write-Pass "Execution policy: $execPolicy"

    # Check Scoop apps are installed
    $requiredApps = @("herdr", "neovim", "peri", "starship")
    $installedApps = (scoop list) | ForEach-Object {
        if ($_ -match 'Name=(\S[^;]*)') { $matches[1] }
    }
    $missing = $requiredApps | Where-Object { $_ -notin $installedApps }
    if ($missing.Count -gt 0) {
        Write-Fail "Missing Scoop dependencies: $($missing -join ', ')"
        return $false
    }
    Write-Pass "All Scoop dependencies installed"

    return $true
}

# ─── Task 2.1: Backup-TzemedState ───────────────────────────────────────────

function Backup-TzemedState {
    Write-Step "Backing up existing configs..."

    if (-not (Test-Path $BACKUP_ROOT)) {
        New-Item -ItemType Directory -Path $BACKUP_ROOT -Force | Out-Null
    }

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupFile = Join-Path $BACKUP_ROOT "$BACKUP_PREFIX-$timestamp.zip"

    $pathsToBackup = @()

    # Check each config path and add if it exists
    $configPaths = @(
        (Join-Path $XDG_CONFIG_HOME "nvim"),
        (Join-Path $XDG_CONFIG_HOME "herdr"),
        (Join-Path $XDG_CONFIG_HOME "starship.toml"),
        $PERI_CONFIG_DIR
    )

    foreach ($path in $configPaths) {
        if (Test-Path $path) {
            $pathsToBackup += $path
            Write-Pass "Queued for backup: $path"
        }
    }

    if ($pathsToBackup.Count -eq 0) {
        Write-Pass "No existing configs to back up"
        return $null
    }

    try {
        Compress-Archive -Path $pathsToBackup -DestinationPath $backupFile -Force
        Write-Pass "Backup created: $backupFile"
        return $backupFile
    } catch {
        Write-Fail "Failed to create backup: $_"
        throw
    }
}

# ─── Task 2.2: Copy-Configs ──────────────────────────────────────────────────

function Copy-Configs {
    Write-Step "Deploying Tzemed configs..."

    # Source paths (within the Scoop package)
    $nvimSource   = Join-Path $ConfigDir "nvim"
    $herdrSource  = Join-Path $ConfigDir "herdr"
    $periSource   = Join-Path $ConfigDir "peri"
    $starshipSource = Join-Path $ConfigDir "starship.toml"

    # Destination paths
    $nvimDest     = Join-Path $XDG_CONFIG_HOME "nvim"
    $herdrDest    = Join-Path $XDG_CONFIG_HOME "herdr"
    $starshipDest = Join-Path $XDG_CONFIG_HOME "starship.toml"
    $periDestDir  = $PERI_CONFIG_DIR
    $periDest     = Join-Path $PERI_CONFIG_DIR "settings.json"

    # Ensure destination directories exist
    foreach ($dir in @($nvimDest, $herdrDest, $periDestDir)) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }

    # Copy nvim config
    if (Test-Path $nvimSource) {
        Copy-Item -Path "$nvimSource\*" -Destination $nvimDest -Recurse -Force
        Write-Pass "Nvim config deployed to $nvimDest"
    } else {
        Write-Fail "Nvim config source not found: $nvimSource"
        return $false
    }

    # Copy herdr config
    if (Test-Path $herdrSource) {
        Copy-Item -Path "$herdrSource\*" -Destination $herdrDest -Recurse -Force
        Write-Pass "Herdr config deployed to $herdrDest"
    } else {
        Write-Fail "Herdr config source not found: $herdrSource"
        return $false
    }

    # Copy Peri settings.json (NOT to ~/.config/peri/ — Peri uses ~/.peri/)
    $periSourceFile = Join-Path $periSource "settings.json"
    if (Test-Path $periSourceFile) {
        Copy-Item -Path $periSourceFile -Destination $periDest -Force
        Write-Pass "Peri config deployed to $periDest"
    } else {
        Write-Fail "Peri config source not found: $periSourceFile"
        return $false
    }

    # Copy starship.toml
    if (Test-Path $starshipSource) {
        Copy-Item -Path $starshipSource -Destination $starshipDest -Force
        Write-Pass "Starship config deployed to $starshipDest"
    } else {
        Write-Fail "Starship config source not found: $starshipSource"
        return $false
    }

    return $true
}

# ─── Task 2.3: Set-Profile ──────────────────────────────────────────────────

function Set-Profile {
    Write-Step "Configuring PowerShell profile..."

    $profilePath = $PROFILE.CurrentUserAllHosts
    $profileDir = Split-Path $profilePath -Parent

    # Ensure profile directory exists
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }

    # Ensure profile file exists
    if (-not (Test-Path $profilePath)) {
        New-Item -ItemType File -Path $profilePath -Force | Out-Null
    }

    $profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue

    # Check if marker block already exists
    if ($profileContent -match '# === TZEMED BEGIN ===') {
        Write-Pass "Tzemed marker block already present in $PROFILE"
        return $true
    }

    # Check if XDG_CONFIG_HOME is already set externally
    if ([Environment]::GetEnvironmentVariable("XDG_CONFIG_HOME", "User") -or $env:XDG_CONFIG_HOME) {
        Write-Pass "XDG_CONFIG_HOME already set — skipping profile update"
        return $true
    }

    $markerBlock = @"

# === TZEMED BEGIN ===
# Managed by Tzemed — do not edit between markers
`$env:XDG_CONFIG_HOME = "`$HOME\.config"
# === TZEMED END ===
"@

    Add-Content -Path $profilePath -Value $markerBlock
    Write-Pass "Added Tzemed marker block to $PROFILE"
    return $true
}

# ─── Task 2.4: Verify-Binaries ──────────────────────────────────────────────

function Verify-Binaries {
    Write-Step "Verifying installed binaries..."
    $allPassed = $true
    $results = @{}

    $binaries = @{
        "herdr"    = "herdr"
        "nvim"     = "nvim"
        "peri"     = "peri"
        "starship" = "starship"
    }

    foreach ($name in $binaries.Keys) {
        $cmd = $binaries[$name]
        try {
            $version = & $cmd --version 2>&1 | Select-Object -First 1
            if ($LASTEXITCODE -eq 0 -and $version) {
                Write-Pass "$name → $($version.Trim())"
                $results[$name] = "pass"
            } else {
                throw "exit code $LASTEXITCODE"
            }
        } catch {
            Write-Fail "$name — binary not found or failed: $_"
            $results[$name] = "fail"
            $allPassed = $false
        }
    }

    if ($allPassed) {
        Write-Host "`n✔ All binaries verified successfully!" -ForegroundColor Green
    } else {
        Write-Host "`n✗ Some binaries are missing. Restoring backup..." -ForegroundColor Yellow
    }

    return $allPassed
}

# ─── Task 2.4: Restore-Backup ───────────────────────────────────────────────

function Restore-Backup {
    param([string]$BackupFile)

    Write-Step "Restoring backup..."

    if (-not $BackupFile -or -not (Test-Path $BackupFile)) {
        Write-Fail "No backup file found to restore"
        return $false
    }

    # Remove deployed configs
    $configPaths = @(
        (Join-Path $XDG_CONFIG_HOME "nvim"),
        (Join-Path $XDG_CONFIG_HOME "herdr"),
        (Join-Path $XDG_CONFIG_HOME "starship.toml"),
        $PERI_CONFIG_DIR
    )

    foreach ($path in $configPaths) {
        if (Test-Path $path) {
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # Extract backup
    try {
        Expand-Archive -Path $BackupFile -DestinationPath $HOME -Force
        Write-Pass "Backup restored from $BackupFile"

        # Remove marker to force re-init
        if (Test-Path $MARKER_FILE) {
            Remove-Item -Path $MARKER_FILE -Force
        }

        Write-Host "`n⚠  Rollback complete. Pre-install configs have been restored." -ForegroundColor Yellow
        Write-Host "   Run 'tzemed' to retry initialization." -ForegroundColor Yellow
        return $true
    } catch {
        Write-Fail "Failed to restore backup: $_"
        return $false
    }
}

# ─── Main Pipeline ───────────────────────────────────────────────────────────

function Invoke-TzemedInstall {
    Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║        Tzemed — Install Pipeline         ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    # Step 1: Check requirements
    if (-not (Check-Requirements)) {
        Write-Fail "System requirements not met. Aborting installation."
        exit 1
    }
    Write-Host ""

    # Step 2: Backup existing configs
    $backupFile = Backup-TzemedState
    Write-Host ""

    # Step 3: Copy new configs
    if (-not (Copy-Configs)) {
        Write-Fail "Config deployment failed."
        if ($backupFile) {
            Restore-Backup -BackupFile $backupFile
        }
        exit 1
    }
    Write-Host ""

    # Step 4: Set up $PROFILE
    Set-Profile
    Write-Host ""

    # Step 5: Verify binaries
    $verified = Verify-Binaries
    Write-Host ""

    if (-not $verified) {
        if ($backupFile) {
            Restore-Backup -BackupFile $backupFile
        }
        Write-Host ""
        Write-Fail "Installation failed. Review errors above and try again."
        exit 2
    }

    Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║   Tzemed installed successfully!         ║" -ForegroundColor Green
    Write-Host "║                                          ║" -ForegroundColor Green
    Write-Host "║   Run 'tzemed' to initialize your stack  ║" -ForegroundColor Green
    Write-Host "║   Then run 'herdr' to start coding       ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Green
}

# ─── Entry Point ─────────────────────────────────────────────────────────────

Invoke-TzemedInstall
