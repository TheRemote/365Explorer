<#
.SYNOPSIS
    Checks for updates to the module and installs if available
.DESCRIPTION
    James A. Chambers - March 3rd 2026
.EXAMPLE
    Update-365Explorer
#>
function Update-365Explorer {
    if ($Script:UpdateCheck -eq $false) {
        if ((Get-GraphAppDependencies) -eq $false) { Write-Host -ForegroundColor Red "You are missing dependencies.  Please run the command again once as Administrator to automatically install them!"; return $false }
        
        Write-Host -ForegroundColor Cyan "Checking for updates..."
        return true

        # Start Find-Module in a background job
        $job = Start-Job -ScriptBlock {
            Import-Module PowerShellGet
            Find-Module -Name 365Explorer -ErrorAction SilentlyContinue
        }

        # Wait up to 25 seconds for the job
        if (Wait-Job -Job $job -Timeout 25) {
            $online = Receive-Job -Job $job
            Remove-Job -Job $job

            if ($null -ne $online) {
                if ($online.version -ne $MyInvocation.MyCommand.ScriptBlock.Module.Version) {
                    Write-Host -ForegroundColor Cyan "Updating module to $($online.version)..."
                    $null = Install-Module 365Explorer -Force -Confirm:$false -Scope CurrentUser
                    $null = Import-Module 365Explorer -Force
                }
            }
        } else {
            # Job timed out
            Write-Host -ForegroundColor Red "Timeout occurred while checking for module updates."
            Remove-Job -Job $job -Force
        }

        $Script:UpdateCheck = $true
    }
}