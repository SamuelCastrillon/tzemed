#requires -Modules @{ ModuleName = "Pester"; ModuleVersion = "5.0.0" }

<#
.SYNOPSIS
    Unit tests for Tzemed install.ps1 functions.
.DESCRIPTION
    Uses Pester mocks to test file operations, backup/restore, and verification
    without touching the real filesystem.
#>

BeforeAll {
    # Test paths
    $TestRoot = Join-Path $TestDrive "tzemed_test"
    $TestConfigDir = Join-Path $TestRoot "config"
    $TestTzemedDir = Join-Path $TestRoot "scripts"
    $TestHome     = Join-Path $TestRoot "home"

    # Override HOME for testing
    $env:USERPROFILE = $TestHome
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Set-Variable -Name HOME -Value $TestHome -Force
    } else {
        $HOME = $TestHome
    }

    # Source the install script to expose internal functions
    $scriptPath = Join-Path $PSScriptRoot "..\..\scripts\install.ps1"
    . $scriptPath -ConfigDir $TestConfigDir -TzemedDir $TestTzemedDir
}

Describe "Check-Requirements" {
    It "Returns $false when Windows build is below minimum" {
        Mock -CommandName Get-CimInstance -MockWith {
            return @{ BuildNumber = "15000" }
        }

        $result = Check-Requirements
        $result | Should -Be $false
    }

    It "Returns $false when Scoop is not installed" {
        Mock -CommandName Get-Command -MockWith { return $null }
        Mock -CommandName Get-CimInstance -MockWith {
            return @{ BuildNumber = "19045" }
        }

        $result = Check-Requirements
        $result | Should -Be $false
    }

    It "Returns $false when execution policy is Restricted" {
        Mock -CommandName Get-Command -MockWith { return $true }
        Mock -CommandName Get-CimInstance -MockWith {
            return @{ BuildNumber = "19045" }
        }
        Mock -CommandName Get-ExecutionPolicy -MockWith { return "Restricted" }

        $result = Check-Requirements
        $result | Should -Be $false
    }
}

Describe "Backup-TzemedState" {
    It "Creates backup directory if it doesn't exist" {
        $backupRoot = Join-Path $TestHome ".config\tzemed.backup"

        if (Test-Path $backupRoot) { Remove-Item $backupRoot -Recurse -Force }

        Mock -CommandName Get-Date -MockWith { return "20260101-120000" }
        Mock -CommandName Test-Path { return $false } -ParameterFilter { $Path -eq "$TestHome\.config\nvim" }

        $result = Backup-TzemedState

        Test-Path $backupRoot | Should -Be $true
    }

    It "Returns null when no configs exist to back up" {
        Mock -CommandName Test-Path { return $false }

        $result = Backup-TzemedState
        $result | Should -Be $null
    }
}

Describe "Copy-Configs" {
    It "Returns $true when all config sources exist" {
        # Create mock source configs
        New-Item -ItemType Directory -Path "$TestConfigDir\nvim\lua\config" -Force | Out-Null
        New-Item -ItemType Directory -Path "$TestConfigDir\herdr" -Force | Out-Null
        New-Item -ItemType Directory -Path "$TestConfigDir\peri" -Force | Out-Null
        Set-Content -Path "$TestConfigDir\starship.toml" -Value "# test"
        Set-Content -Path "$TestConfigDir\peri\settings.json" -Value "{}"
        Set-Content -Path "$TestConfigDir\nvim\init.lua" -Value "-- test"
        Set-Content -Path "$TestConfigDir\herdr\config.toml" -Value "# test"

        $result = Copy-Configs
        $result | Should -Be $true
    }

    It "Returns $false when nvim config is missing" {
        Mock -CommandName Test-Path { return $false } -ParameterFilter { $Path -like "*nvim*" }

        $result = Copy-Configs
        $result | Should -Be $false
    }

    It "Returns $false when herdr config is missing" {
        Mock -CommandName Test-Path { return $false } -ParameterFilter { $Path -like "*herdr*" }

        $result = Copy-Configs
        $result | Should -Be $false
    }
}

Describe "Set-Profile" {
    It "Adds marker block to empty $PROFILE" {
        $profileDir = Split-Path $PROFILE.CurrentUserAllHosts -Parent
        if (-not (Test-Path $profileDir)) {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }
        if (Test-Path $PROFILE.CurrentUserAllHosts) {
            Remove-Item $PROFILE.CurrentUserAllHosts -Force
        }

        $result = Set-Profile

        $result | Should -Be $true
        $content = Get-Content $PROFILE.CurrentUserAllHosts -Raw
        $content | Should -Match "TZEMED BEGIN"
        $content | Should -Match "TZEMED END"
        $content | Should -Match 'XDG_CONFIG_HOME'
    }

    It "Does not add duplicate marker block" {
        $result = Set-Profile
        $result | Should -Be $true

        $content = Get-Content $PROFILE.CurrentUserAllHosts -Raw
        $matches = [regex]::Matches($content, "TZEMED BEGIN")
        $matches.Count | Should -Be 1
    }
}

Describe "Verify-Binaries" {
    It "Returns $true when all binaries succeed" {
        Mock -CommandName Invoke-Expression { return }
        Mock -CommandName Get-Command {
            return @{ Source = "C:\tools\herdr.exe" }
        }

        # Mock the actual version calls
        $script:mockVersionOutput = @{
            herdr    = "herdr 0.1.0"
            nvim     = "NVIM v0.10.0"
            peri     = "peri 1.0.0"
            starship = "starship 1.20.0"
        }
        Mock -CommandName & {
            param($Command, $Args)
            if ($Command -eq "herdr" -and $Args -contains "--version") { return $script:mockVersionOutput.herdr }
            if ($Command -eq "nvim" -and $Args -contains "--version") { return $script:mockVersionOutput.nvim }
            if ($Command -eq "peri" -and $Args -contains "--version") { return $script:mockVersionOutput.peri }
            if ($Command -eq "starship" -and $Args -contains "--version") { return $script:mockVersionOutput.starship }
            return ""
        }

        $result = Verify-Binaries
        $result | Should -Be $true
    }

    It "Returns $false when a binary fails" {
        Mock -CommandName & {
            param($Command)
            if ($Command -eq "herdr") { throw "not found" }
            return "OK"
        }

        $result = Verify-Binaries
        $result | Should -Be $false
    }
}

Describe "Restore-Backup" {
    It "Returns $false when no backup file exists" {
        $result = Restore-Backup -BackupFile ""
        $result | Should -Be $false
    }

    It "Returns $false when backup file path doesn't exist" {
        $result = Restore-Backup -BackupFile "Z:\nonexistent\backup.zip"
        $result | Should -Be $false
    }
}
