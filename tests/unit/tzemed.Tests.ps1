#requires -Modules @{ ModuleName = "Pester"; ModuleVersion = "5.0.0" }

<#
.SYNOPSIS
    Unit tests for Tzemed tzemed.ps1 functions — layout, pre-install, init.
.DESCRIPTION
    Uses Pester mocks to test Initialize-Tzemed return value,
    Start-PluginPreInstall process launch, and Start-TzemedLayout
    ratio/Peri launch without invoking real commands.
#>

BeforeAll {
    $TestHome = Join-Path $TestDrive "home"
    $env:USERPROFILE = $TestHome
    # Override $HOME to match USERPROFILE for the test session
    Set-Variable -Name HOME -Value $TestHome -Force

    # Source the tzemed script to expose internal functions
    $scriptPath = Join-Path $PSScriptRoot "..\..\scripts\tzemed.ps1"
    . $scriptPath
}

Describe "Initialize-Tzemed" {
    AfterEach {
        $marker = Join-Path $env:USERPROFILE ".config\tzemed.init"
        if (Test-Path $marker) { Remove-Item $marker -Force }
    }

    It "Returns `$true when marker file does not exist (first-time init)" {
        $result = Initialize-Tzemed
        $result | Should -Be $true
    }

    It "Returns `$false when marker file already exists (already initialized)" {
        $markerDir = Join-Path $env:USERPROFILE ".config"
        New-Item -ItemType Directory -Path $markerDir -Force | Out-Null
        $marker = Join-Path $markerDir "tzemed.init"
        Set-Content -Path $marker -Value "test"

        $result = Initialize-Tzemed
        $result | Should -Be $false
    }
}

Describe "Start-PluginPreInstall" {
    It "Launches pwsh with Lazy sync and MasonInstall commands" {
        $invokedArgs = $null
        Mock -CommandName Start-Process -MockWith {
            param($FilePath, $ArgumentList)
            $script:invokedArgs = @{ FilePath = $FilePath; ArgumentList = $ArgumentList }
        }

        Start-PluginPreInstall
        Should -Invoke -CommandName Start-Process -Exactly -Times 1
        $script:invokedArgs.FilePath | Should -Be "pwsh"
        $argString = $script:invokedArgs.ArgumentList -join " "
        $argString | Should -Match "Lazy sync"
        $argString | Should -Match "MasonInstall"
    }
}

Describe "Start-TzemedLayout" {
    It "Uses --ratio 0.5 in pane split command" {
        Mock -CommandName Get-Command { return $true } -ParameterFilter { $Name -eq "herdr" }

        $global:LASTEXITCODE = 0
        $splitArgs = $null
        Mock -CommandName herdr {
            if ($args[0] -eq "pane" -and $args[1] -eq "split") {
                $script:splitArgs = $args
            }
            $global:LASTEXITCODE = 0
            if ($args[0] -eq "workspace" -and $args[1] -eq "create") {
                return ""; $global:LASTEXITCODE = 0
            }
            if ($args[0] -eq "pane" -and $args[1] -eq "current") {
                return '{"id":"pane-r","label":"right-pane"}'
            }
            return ""
        }

        Start-TzemedLayout -Cwd $TestDrive

        $script:splitArgs -contains "--ratio" | Should -Be $true
        $ratioIdx = [array]::IndexOf($script:splitArgs, "--ratio")
        $script:splitArgs[$ratioIdx + 1] | Should -Be "0.5"
    }

    It "Attempts to launch Peri in left pane after nvim launch" {
        Mock -CommandName Get-Command { return $true } -ParameterFilter { $Name -eq "herdr" }

        $periLaunched = $false
        Mock -CommandName herdr {
            if ($args[0] -eq "pane" -and $args[1] -eq "run" -and $args[3] -eq "peri") {
                $script:periLaunched = $true
            }
            # Return a mock pane for `herdr pane current` calls
            if ($args[0] -eq "pane" -and $args[1] -eq "current") {
                return '{"id":"pane-r","label":"current"}'
            }
            $global:LASTEXITCODE = 0
            return ""
        }

        Start-TzemedLayout -Cwd $TestDrive

        $script:periLaunched | Should -Be $true
    }
}
