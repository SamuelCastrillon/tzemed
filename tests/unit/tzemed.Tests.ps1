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

Describe "Write-Header" {
    It "Outputs 6 ANSI Shadow lines via Write-Host DarkMagenta plus a blank line" {
        $cmd = Get-Command Write-Header
        $body = $cmd.ScriptBlock.ToString()

        # Count Write-Host calls with ANSI Shadow block chars
        $matches = [regex]::Matches($body, 'Write-Host "')

        # 6 logo lines using Write-Host with DarkMagenta, plus 1 blank Write-Host
        $matches.Count | Should -Be 7

        # Verify DarkMagenta is used
        $body | Should -Match "DarkMagenta"

        # Verify ANSI Shadow block chars are present (first line approximation)
        $body | Should -Match "████"

        # Verify blank line at end
        $body | Should -Match 'Write-Host ""'
    }
}

Describe "Start-TzemedLayout" {
    It "Uses --ratio 0.6 in pane split command and queries pane list" {
        Mock -CommandName Get-Command { return $true } -ParameterFilter { $Name -eq "herdr" }

        $global:LASTEXITCODE = 0
        $splitArgs = $null
        $paneListCalled = $false
        Mock -CommandName herdr {
            if ($args[0] -eq "pane" -and $args[1] -eq "split") {
                $script:splitArgs = $args
                $global:LASTEXITCODE = 0
                return ""
            }
            if ($args[0] -eq "workspace" -and $args[1] -eq "create") {
                $global:LASTEXITCODE = 0
                return ""
            }
            if ($args[0] -eq "pane" -and $args[1] -eq "list") {
                $script:paneListCalled = $true
                $global:LASTEXITCODE = 0
                return '[{"id":"pane-left","label":"left"},{"id":"pane-right","label":"right"}]'
            }
            if ($args[0] -eq "pane" -and $args[1] -eq "run") {
                $global:LASTEXITCODE = 0
                return ""
            }
            if ($args[0] -eq "pane" -and $args[1] -eq "focus") {
                $global:LASTEXITCODE = 0
                return ""
            }
            $global:LASTEXITCODE = 0
            return ""
        }

        Start-TzemedLayout -Cwd $TestDrive

        # Verify --ratio 0.6
        $script:splitArgs -contains "--ratio" | Should -Be $true
        $ratioIdx = [array]::IndexOf($script:splitArgs, "--ratio")
        $script:splitArgs[$ratioIdx + 1] | Should -Be "0.6"

        # Verify pane list was used instead of pane current
        $script:paneListCalled | Should -Be $true
    }

    It "Launches Peri in pane[0] and nvim in pane[1] using pane list" {
        Mock -CommandName Get-Command { return $true } -ParameterFilter { $Name -eq "herdr" }

        $runCalls = @()
        Mock -CommandName herdr {
            if ($args[0] -eq "pane" -and $args[1] -eq "run") {
                $script:runCalls += ,@($args[2], $args[3])
            }
            if ($args[0] -eq "pane" -and $args[1] -eq "list") {
                return '[{"id":"pane-left","label":"left"},{"id":"pane-right","label":"right"}]'
            }
            $global:LASTEXITCODE = 0
            return ""
        }

        Start-TzemedLayout -Cwd $TestDrive

        # First pane run: pane[0] should get "peri"
        $script:runCalls[0][1] | Should -Be "peri"
        # Second pane run: pane[1] should get "nvim"
        $script:runCalls[1][1] | Should -Be "nvim"
    }
}
