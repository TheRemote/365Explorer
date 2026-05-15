<#
.SYNOPSIS
    Launches the web server for 365 explorer
.DESCRIPTION
    James A. Chambers - March 9th 2026
.EXAMPLE
    Invoke-365Explorer
#>
function Invoke-365Explorer {
    if (!(Get-GraphAppConnection)) {
        Write-Host -ForegroundColor Red "Failed to connect to Microsoft Graph.  Please check your permissions and try again."
        return
    }

    $pode = Get-Module -ListAvailable -Name "Pode" -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1
    if ($null -eq $pode) {
        Install-Module -Force -SkipPublisherCheck -Confirm:$false Pode -Scope CurrentUser
        Import-Module Pode
    }

    # Import route scripts
    $routePath = "$PSScriptRoot\Routes"
    . "$routePath\Get-RouteUsers.ps1"
    . "$routePath\Get-RouteEmails.ps1"
    . "$routePath\Get-RouteMailRules.ps1"
    . "$routePath\Get-RouteAccount.ps1"
    . "$routePath\Get-RouteMFA.ps1"
    . "$routePath\Get-RouteAuditLogs.ps1"
    . "$routePath\Get-RouteSignInLogs.ps1"
    . "$routePath\Get-RouteOneDrive.ps1"

    # Save config to temp file for Pode to read
    $config = @{
        AppId     = $Script:application.AppId
        OrgId     = $Script:OrgId
        OrgName   = $Script:OrgName
        DefaultDomain = $Script:DefaultDomain
    }
    $configPath = Join-Path "$([System.IO.Path]::GetTempPath())" "pode-config.json"
    $config | ConvertTo-Json -Depth 5 | Set-Content -Path $configPath -Encoding UTF8

    # =============================
    # === Start Pode Server ===
    # =============================

    Start-PodeServer -Threads 4 -Browse {
        Add-PodeEndpoint -Address localhost -Port 8080 -Protocol Https -SelfSigned
        Add-PodeStaticRoute -Path '/' -Source './web'

        Add-PodeRoute -Method GET -Path '/api/users'          -ScriptBlock $GetUsersScript
        Add-PodeRoute -Method GET -Path '/api/emails'         -ScriptBlock $GetEmailsScript
        Add-PodeRoute -Method DELETE -Path '/api/email'       -ScriptBlock $DeleteEmailScript
        Add-PodeRoute -Method GET -Path '/api/attachment'     -ScriptBlock $GetAttachmentScript
        Add-PodeRoute -Method GET -Path '/api/mailrules'      -ScriptBlock $GetMailRulesScript
        Add-PodeRoute -Method DELETE -Path '/api/mailrule'    -ScriptBlock $DeleteMailRuleScript
        Add-PodeRoute -Method GET -Path '/api/disablemailrule' -ScriptBlock $DisableMailRuleScript
        Add-PodeRoute -Method GET -Path '/api/enablemailrule' -ScriptBlock $EnableMailRuleScript
        Add-PodeRoute -Method GET -Path '/api/disableuser'    -ScriptBlock $DisableUserScript
        Add-PodeRoute -Method GET -Path '/api/enableuser'     -ScriptBlock $EnableUserScript
        Add-PodeRoute -Method GET -Path '/api/signOutUser'    -ScriptBlock $SignOutUserScript
        Add-PodeRoute -Method GET -Path '/api/signInLogs'     -ScriptBlock $GetSignInLogsScript
        Add-PodeRoute -Method GET -Path '/api/account'        -ScriptBlock $GetAccountInfoScript
        Add-PodeRoute -Method GET -Path '/api/mfa'            -ScriptBlock $GetMFAMethodsScript
        Add-PodeRoute -Method DELETE -Path '/api/mfa'         -ScriptBlock $DeleteMFAMethodScript
        Add-PodeRoute -Method GET -Path '/api/auditLogs'      -ScriptBlock $GetAuditLogsScript
        Add-PodeRoute -Method GET -Path '/api/onedrive/drives' -ScriptBlock $GetOneDriveDrivesScript
        Add-PodeRoute -Method GET -Path '/api/onedrive/items'  -ScriptBlock $GetOneDriveChildrenScript
        Add-PodeRoute -Method DELETE -Path '/api/onedrive/item' -ScriptBlock $DeleteOneDriveItemScript
        Add-PodeRoute -Method GET -Path '/api/onedrive/download' -ScriptBlock $GetOneDriveFileScript

        $method = New-PodeLoggingMethod -Terminal 
        $method | Enable-PodeRequestLogging
        $method | Enable-PodeErrorLogging
    }
}
