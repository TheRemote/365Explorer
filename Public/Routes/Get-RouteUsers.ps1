# --- Get users ---
$GetUsersScript = {
    Write-Host "$(Get-Date) - Get users" -ForegroundColor Yellow

    $users = Get-MgUser -All -Property DisplayName, UserPrincipalName, UserType, Mail, Id |
    Where-Object { $_.Mail -and $_.UserType -ne 'guest' } |
    Select-Object DisplayName, UserPrincipalName, Id
    Write-PodeJsonResponse -Value $users
}

$EnableUserScript = {
    $userid = $WebEvent.Query['user']
    if (-not $userid) {
        Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "Missing 'user' query parameter" }
        return
    }

    Write-Host "$(Get-Date) - Enable / allow sign in for user" -ForegroundColor Yellow

    Set-MgUser -UserId $userid -AccountEnabled:$true -Confirm:$false
    Write-PodeJsonResponse -Value ""
}

$DisableUserScript = {
    $userid = $WebEvent.Query['user']
    if (-not $userid) {
        Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "Missing 'user' query parameter" }
        return
    }

    Write-Host "$(Get-Date) - Disable / block sign in for user" -ForegroundColor Yellow

    Set-MgUser -UserId $userid -AccountEnabled:$false -Confirm:$false
    Write-PodeJsonResponse -Value ""
}

$SignOutUserScript = {
    $userid = $WebEvent.Query['user']
    if (-not $userid) {
        Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "Missing 'user' query parameter" }
        return
    }

    Write-Host "$(Get-Date) - Sign out all sessions for user" -ForegroundColor Yellow

    Revoke-MgUserSignInSession -UserId $userid -Confirm:$false
    Write-PodeJsonResponse -Value ""
}
