# --- Get mail rules ---
$GetMailRulesScript = {
    $userid = $WebEvent.Query['user']
    if (-not $userid) {
        Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "Missing 'user' query parameter" }
        return
    }
    $user = Get-MgUser -UserId $userid
    if (-not $user) {
        Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "User not found" }
        return
    }

    Write-Host "$(Get-Date) - Get mail rules for $($user.UserPrincipalName)" -ForegroundColor Yellow
    
    $configPath = Join-Path "$([System.IO.Path]::GetTempPath())" "pode-config.json"
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    Write-Host "$(Get-Date) - Getting Exchange connection..." -ForegroundColor Cyan
    $null = Connect-ExchangeOnline -Organization $config.DefaultDomain -AppId $config.AppId -Certificate (Get-GraphAppCertificate) -ShowBanner:$false
    Write-Host "$(Get-Date) - Exchange connection completed" -ForegroundColor Cyan

    $rules = Get-InboxRule -Mailbox $user.UserPrincipalName -IncludeHidden | 
    Select-Object -Property MailboxOwnerID, Name,
    @{Name = 'Identity'; Expression = { [string]$_.Identity } },
    @{Name = 'RuleIdentity'; Expression = { [string]$_.RuleIdentity } },
    Enabled, From, Description, RedirectTo, ForwardTo
    Write-PodeJsonResponse -Value $rules
}

# --- Delete mail rule ---
$DeleteMailRuleScript = {
    $userid = $WebEvent.Query['user']
    if (-not $userid) {
        Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "Missing 'user' query parameter" }
        return
    }
    $user = Get-MgUser -UserId $userid
    if (-not $user) {
        Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "User not found" }
        return
    }
    $ruleId = $WebEvent.Query['ruleid']
    if (-not $ruleId) {
        Write-PodeJsonResponse -Value @{ error = "Missing ruleid" } -StatusCode 400
        return
    }

    Write-Host "$(Get-Date) - Delete mail rule for $($user.UserPrincipalName)" -ForegroundColor Yellow
    
    $configPath = Join-Path "$([System.IO.Path]::GetTempPath())" "pode-config.json"
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    Write-Host "$(Get-Date) - Getting Exchange connection..." -ForegroundColor Cyan
    $null = Connect-ExchangeOnline -Organization $config.DefaultDomain -AppId $config.AppId -Certificate (Get-GraphAppCertificate) -ShowBanner:$false
    Write-Host "$(Get-Date) - Exchange connection completed" -ForegroundColor Cyan

    try {
        Remove-InboxRule -Mailbox "$($user.UserPrincipalName)" -Identity "$ruleId" -Confirm:$false
        Write-PodeJsonResponse -Value @{ success = $true }
    } catch {
        Write-PodeJsonResponse -Value @{ error = $_.Exception.Message } -StatusCode 500
    }
}

# --- Disable mail rule ---
$DisableMailRuleScript = {
    $userid = $WebEvent.Query['user']
    if (-not $userid) {
        Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "Missing 'user' query parameter" }
        return
    }
    $user = Get-MgUser -UserId $userid
    if (-not $user) {
        Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "User not found" }
        return
    }
    $ruleId = $WebEvent.Query['ruleid']
    if (-not $ruleId) {
        Write-PodeJsonResponse -Value @{ error = "Missing ruleid" } -StatusCode 400
        return
    }

    Write-Host "$(Get-Date) - Disable mail rule for $($user.UserPrincipalName)" -ForegroundColor Yellow
    
    $configPath = Join-Path "$([System.IO.Path]::GetTempPath())" "pode-config.json"
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    Write-Host "$(Get-Date) - Getting Exchange connection..." -ForegroundColor Cyan
    $null = Connect-ExchangeOnline -Organization $config.DefaultDomain -AppId $config.AppId -Certificate (Get-GraphAppCertificate) -ShowBanner:$false
    Write-Host "$(Get-Date) - Exchange connection completed" -ForegroundColor Cyan

    try {
        Disable-InboxRule -Mailbox "$($user.UserPrincipalName)" -Identity "$ruleId" -Confirm:$false
        Write-PodeJsonResponse -Value @{ success = $true }
    } catch {
        Write-PodeJsonResponse -Value @{ error = $_.Exception.Message } -StatusCode 500
    }
}

# --- Enable mail rule ---
$EnableMailRuleScript = {
    $userid = $WebEvent.Query['user']
    if (-not $userid) {
        Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "Missing 'user' query parameter" }
        return
    }
    $user = Get-MgUser -UserId $userid
    if (-not $user) {
        Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "User not found" }
        return
    }
    $ruleId = $WebEvent.Query['ruleid']
    if (-not $ruleId) {
        Write-PodeJsonResponse -Value @{ error = "Missing ruleid" } -StatusCode 400
        return
    }

    Write-Host "$(Get-Date) - Enable mail rule for $($user.UserPrincipalName)" -ForegroundColor Yellow
    
    $configPath = Join-Path "$([System.IO.Path]::GetTempPath())" "pode-config.json"
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    Write-Host "$(Get-Date) - Getting Exchange connection..." -ForegroundColor Cyan
    $null = Connect-ExchangeOnline -Organization $config.DefaultDomain -AppId $config.AppId -Certificate (Get-GraphAppCertificate) -ShowBanner:$false
    Write-Host "$(Get-Date) - Exchange connection completed" -ForegroundColor Cyan

    try {
        Enable-InboxRule -Mailbox "$($user.UserPrincipalName)" -Identity "$ruleId" -Confirm:$false
        Write-PodeJsonResponse -Value @{ success = $true }
    } catch {
        Write-PodeJsonResponse -Value @{ error = $_.Exception.Message } -StatusCode 500
    }
}
