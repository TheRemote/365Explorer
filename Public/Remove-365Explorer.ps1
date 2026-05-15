<#
.SYNOPSIS
    Removes the application entry for 365Explorer if it exists
.DESCRIPTION
    James A. Chambers - March 3rd 2026
.EXAMPLE
    Remove-365Explorer
#>
function Remove-365Explorer {
    $Script:application = Get-MgApplication -Filter "DisplayName eq '365Explorer - PowerShell Administration Tool'"
    if ($Script:application) {
        Write-Host "Removing application from tenant" -ForegroundColor Green
        Remove-MgApplication -ApplicationId $($Script:application.Id) -Confirm:$false
    } else {
        Write-Host "No application found in tenant to remove" -ForegroundColor Yellow
    }
}