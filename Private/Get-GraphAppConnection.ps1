function Get-GraphAppConnection {
    # Check for updates
    if ($Script:UpdateCheck -eq $false) {
        Update-365Explorer
        $Script:UpdateCheck = $true
    }

    if ($null -eq $Script:connectionGraph) {
        # Check for dependencies

        Write-Host -ForegroundColor Cyan "Getting Microsoft Graph App connection..."
        $Script:connectionGraph = Get-MgContext
        if ($null -eq $Script:connectionGraph) {
            Connect-MgGraph -Scopes "User.ReadWrite.All", "Group.ReadWrite.All", "Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All", "RoleManagement.ReadWrite.Directory", "RoleManagement.ReadWrite.Exchange" -NoWelcome
            $Script:connectionGraph = Get-MgContext
            if ($null -eq $Script:connectionGraph) { Reset-AppGraph; return $false }
        }
        $Script:application = Get-MgApplication -Filter "DisplayName eq '365Explorer - PowerShell Administration Tool'"
        Get-GraphAppPermissions
    }

    # Check if running in application context
    if ($Script:connectionGraph.AuthType -ne "AppOnly") {
        Connect-MgGraph -ClientId $($Script:application.AppId) -TenantId $($Script:connectionGraph.TenantId) -Certificate $(Get-GraphAppCertificate) -NoWelcome
        $Script:connectionGraph = Get-MgContext
        if ($null -eq $Script:connectionGraph -or $Script:connectionGraph.AuthType -ne "AppOnly") {
            Write-Host -ForegroundColor Red "Failed to upgrade MS Graph connection"
            Reset-AppGraph
            return $false
        } else {
            if ($Script:connectionGraph.Scopes -contains "Mail.ReadWrite") {
                Write-Host -ForegroundColor Cyan "Upgraded MS Graph connection"
            } else {
                Write-Host -ForegroundColor Cyan "Sleeping 20 seconds to let permissions catch up..."
                Start-Sleep -Milliseconds 20000
                Connect-MgGraph -ClientId $($Script:application.AppId) -TenantId $($Script:connectionGraph.TenantId) -Certificate $(Get-GraphAppCertificate) -NoWelcome
                $Script:connectionGraph = Get-MgContext
                if ($null -eq $Script:connectionGraph -or $Script:connectionGraph.AuthType -ne "AppOnly" -or $Script:connectionGraph.Scopes -notcontains "Application.ReadWrite.All") {
                    Write-Host -ForegroundColor Red "Failed to upgrade MS Graph connection"
                    Reset-AppGraph
                    return $false
                } else {
                    Write-Host -ForegroundColor Cyan "Upgraded MS Graph connection"
                }
            }
        }
    }

    # Get organization details
    if ($null -eq $Script:OrgName) {
        $Organization = Get-MgOrganization
        $Script:DefaultDomain = ($Organization.VerifiedDomains | Where-Object { $_.IsDefault -eq "True" }).Name
        $Script:OrgName = $Organization.DisplayName
        $Script:OrgId = $Organization.Id
        $Script:LogString = "$Script:OrgName-$(Get-Date -Format "MMddyy")"
        $Script:application = Get-MgApplication -Filter "DisplayName eq '365Explorer - PowerShell Administration Tool'"
        Write-Host -ForegroundColor Green "Connected to tenant $Script:OrgName ($Script:OrgId) with a default domain of $Script:DefaultDomain`nIf this is the wrong tenant press Ctrl+C to stop the script and then type: Reset-AppGraph"
    }

    if ($null -eq $Script:connectionExchange -and $Script:ExchangeDisabled -eq $false) {
        # Get Exchange sp
        $exchangesp = Get-MgServicePrincipal -Filter "AppId eq '00000002-0000-0ff1-ce00-000000000000'"
        if ($null -eq $exchangesp) {
            Write-Host -ForegroundColor Red "Exchange service principal does not exist -- Exchange will not be available!"
            $Script:ExchangeDisabled = $true
        }
    }

    if ($null -eq $Script:connectionExchange -and $Script:ExchangeDisabled -eq $false) {
        Write-Host -ForegroundColor Cyan "Getting Microsoft Exchange connection..."
        $null = Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
        try {
            $null = Connect-ExchangeOnline -Organization $Script:DefaultDomain -AppId $Script:application.AppId -Certificate $(Get-GraphAppCertificate) -ShowBanner:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
        } catch {
            if ($_.Exception.Message -like "*subscription within the tenant*") {
                Write-Host -ForegroundColor Red "Exchange is disabled on this tenant!  Exchange commands will not be available."
                $Script:ExchangeDisabled = $true
            } else {
                Write-Host -ForegroundColor Red "Error: $($_.Exception.Message)"
            }
        }
        $Script:connectionExchange = Get-ConnectionInformation
        if ($null -eq $Script:connectionExchange -and $Script:ExchangeDisabled -eq $false) {
            Write-Host -ForegroundColor Cyan "Waiting for permissions to catch up and trying Exchange again..."
            Start-Sleep -Milliseconds 10000
            try {
                $null = Connect-ExchangeOnline -Organization $Script:DefaultDomain -AppId $Script:application.AppId -Certificate $(Get-GraphAppCertificate) -ShowBanner:$false
            } catch {
                Write-Host -ForegroundColor Red "Error: $($_.Exception.Message)"
            }
            $Script:connectionExchange = Get-ConnectionInformation
            if ($null -eq $Script:connectionExchange) {
                Write-Host -ForegroundColor Red "Unable to connect to Exchange Online!"
                Reset-AppGraph
                return $false 
            }
        }
    }

    Set-Variable ProgressPreference Continue

    return $true
}