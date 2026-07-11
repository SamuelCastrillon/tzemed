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

Describe "Invoke-TzemedHelp" {
    It "Outputs help content listing all subcommands" {
        $cmd = Get-Command Invoke-TzemedHelp
        $body = $cmd.ScriptBlock.ToString()

        # Should list all subcommands
        $body | Should -Match "help"
        $body | Should -Match "uninstall"
        $body | Should -Match "update"
        $body | Should -Match "fix"

        # Should mention -h, --help, -v options
        $body | Should -Match "-h"
        $body | Should -Match "--help"
        $body | Should -Match "-v"
    }
}

Describe "Invoke-TzemedFix" {
    It "Removes stale marker and calls Initialize-Tzemed + Invoke-BinaryVerification" {
        $marker = Join-Path $env:USERPROFILE ".config\tzemed.init"
        $markerDir = Split-Path $marker
        New-Item -ItemType Directory -Path $markerDir -Force | Out-Null
        Set-Content -Path $marker -Value "stale"
        Test-Path $marker | Should -Be $true

        Mock Initialize-Tzemed { return $true }
        Mock Invoke-BinaryVerification { return $true }

        $result = Invoke-TzemedFix
        $result | Should -Be $true

        # Marker should have been deleted
        Test-Path $marker | Should -Be $false
        Should -Invoke Initialize-Tzemed -Exactly -Times 1
        Should -Invoke Invoke-BinaryVerification -Exactly -Times 1
    }

    It "Returns `$false when verification fails" {
        Mock Initialize-Tzemed { return $true }
        Mock Invoke-BinaryVerification { return $false }

        $result = Invoke-TzemedFix
        $result | Should -Be $false
    }
}

Describe "Invoke-TzemedUpdate" {
    It "Returns `$true when all components update successfully" {
        Mock Invoke-ScoopCli { return @{ Output = @(""); ExitCode = 0 } }

        $result = Invoke-TzemedUpdate
        $result | Should -Be $true
    }

    It "Returns `$false when one component update fails and reports both passes and failures" {
        $callCount = 0
        Mock Invoke-ScoopCli -MockWith {
            $script:callCount++
            if ($script:callCount -eq 3) {
                # nvim update — fail
                return @{ Output = @("ERROR"); ExitCode = 1 }
            }
            return @{ Output = @(""); ExitCode = 0 }
        }

        $result = Invoke-TzemedUpdate
        $result | Should -Be $false
        $script:callCount | Should -BeGreaterThan 2  # scoop update + at least 2 components
    }
}

Describe "Invoke-TzemedUninstall" {
    AfterEach {
        # Clean up any config dirs created during test
        $configDirs = @(
            Join-Path $env:USERPROFILE ".config\nvim",
            Join-Path $env:USERPROFILE ".config\herdr"
        )
        foreach ($d in $configDirs) {
            if (Test-Path $d) { Remove-Item $d -Recurse -Force }
        }
    }

    It "Deletes config directories when -Force is used without prompting" {
        Mock Invoke-ScoopCli { return @{ Output = @(""); ExitCode = 0 } }
        Mock Start-Process { }

        # Create the nvim config dir
        $nvimConfig = Join-Path $env:USERPROFILE ".config\nvim"
        New-Item -ItemType Directory -Path $nvimConfig -Force | Out-Null

        Mock Remove-Item { }
        Mock Confirm-ConfigDeletion { throw "Should not prompt when -Force is used" }

        Invoke-TzemedUninstall -Force

        Should -Invoke Remove-Item -Exactly -Times 1
        Should -Not -Invoke Confirm-ConfigDeletion
    }

    It "Prompts for config deletion when -Force is not set" {
        Mock Invoke-ScoopCli { return @{ Output = @(""); ExitCode = 0 } }
        Mock Start-Process { }

        $nvimConfig = Join-Path $env:USERPROFILE ".config\nvim"
        New-Item -ItemType Directory -Path $nvimConfig -Force | Out-Null

        Mock Remove-Item { }
        Mock Confirm-ConfigDeletion { return $true }

        Invoke-TzemedUninstall

        Should -Invoke Confirm-ConfigDeletion -Exactly -Times 1
        Should -Invoke Remove-Item -Exactly -Times 1
    }

    It "Skips missing Scoop packages with warning and continues with remaining" {
        # Initialize at script scope for mock access
        $script:tzemedScoopCliCount = 0
        Mock Invoke-ScoopCli -MockWith {
            $script:tzemedScoopCliCount++
            # For every component: Invoke-ScoopCli is called with "list"
            # First two calls succeed (packages installed), rest fail (not installed)
            if ($script:tzemedScoopCliCount -gt 2) {
                return @{ Output = @(""); ExitCode = 1 }
            }
            return @{ Output = @(""); ExitCode = 0 }
        }
        Mock Start-Process { }
        Mock Confirm-ConfigDeletion { return $false }  # Skip config prompts

        Invoke-TzemedUninstall

        # Should have called Start-Process only for installed components
        Should -Invoke Start-Process -Exactly -Times 2
    }
}

Describe "Invoke-TzemedRouter" {
    It "Routes 'help' to Invoke-TzemedHelp and returns `$true" {
        Mock Invoke-TzemedHelp { }

        $result = Invoke-TzemedRouter -Directory "help" -RemainingArgs @()
        $result | Should -Be $true
        Should -Invoke Invoke-TzemedHelp -Exactly -Times 1
    }

    It "Does not route -h via RemainingArgs (handled by param switch)" {
        Mock Invoke-TzemedHelp { }

        $result = Invoke-TzemedRouter -Directory "" -RemainingArgs @("-h")
        $result | Should -Be $null
        Should -Invoke Invoke-TzemedHelp -Exactly -Times 0
    }

    It "Does not route --help via RemainingArgs (handled by param switch)" {
        Mock Invoke-TzemedHelp { }

        $result = Invoke-TzemedRouter -Directory "" -RemainingArgs @("--help")
        $result | Should -Be $null
        Should -Invoke Invoke-TzemedHelp -Exactly -Times 0
    }

    It "Routes 'uninstall' to Invoke-TzemedUninstall without force" {
        $forceReceived = $null
        Mock Invoke-TzemedUninstall -MockWith {
            param($Force)
            $script:forceReceived = $Force.IsPresent
            return $true
        }

        $result = Invoke-TzemedRouter -Directory "uninstall" -RemainingArgs @()
        $result | Should -Be $true
        $script:forceReceived | Should -Be $false
        Should -Invoke Invoke-TzemedUninstall -Exactly -Times 1
    }

    It "Passes --force flag to Invoke-TzemedUninstall" {
        $forceReceived = $null
        Mock Invoke-TzemedUninstall -MockWith {
            param($Force)
            $script:forceReceived = $Force.IsPresent
            return $true
        }

        $result = Invoke-TzemedRouter -Directory "uninstall" -RemainingArgs @("--force")
        $result | Should -Be $true
        $script:forceReceived | Should -Be $true
    }

    It "Routes 'update' to Invoke-TzemedUpdate" {
        Mock Invoke-TzemedUpdate { return $true }

        $result = Invoke-TzemedRouter -Directory "update" -RemainingArgs @()
        $result | Should -Be $true
        Should -Invoke Invoke-TzemedUpdate -Exactly -Times 1
    }

    It "Routes 'fix' to Invoke-TzemedFix" {
        Mock Invoke-TzemedFix { return $true }

        $result = Invoke-TzemedRouter -Directory "fix" -RemainingArgs @()
        $result | Should -Be $true
        Should -Invoke Invoke-TzemedFix -Exactly -Times 1
    }

    It "Returns `$null for empty directory (no subcommand)" {
        $result = Invoke-TzemedRouter -Directory "" -RemainingArgs @()
        $result | Should -Be $null
    }

    It "Returns `$null for directory path that is not a subcommand" {
        $result = Invoke-TzemedRouter -Directory "C:\Projects" -RemainingArgs @()
        $result | Should -Be $null
    }

    It "Returns `$null for current-directory shorthand '.'" {
        $result = Invoke-TzemedRouter -Directory "." -RemainingArgs @()
        $result | Should -Be $null
    }

    It "Returns `$false when subcommand function returns `$false" {
        Mock Invoke-TzemedFix { return $false }

        $result = Invoke-TzemedRouter -Directory "fix" -RemainingArgs @()
        $result | Should -Be $false
    }
}
