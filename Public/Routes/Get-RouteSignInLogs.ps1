# --- Sign-in logs ---
$GetSignInLogsScript = {
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
    $start = $WebEvent.Query['start']
    $end = $WebEvent.Query['end']

    if (-not $start -or -not $end) {
        Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "Missing 'start', or 'end' query parameters" }
        return
    }

    Write-Host "$(Get-Date) - Get sign in logs for $($user.UserPrincipalName) - Start: $start - End: $end" -ForegroundColor Yellow

    $filter = "userPrincipalName eq '$($user.UserPrincipalName)' and createdDateTime ge $start and createdDateTime lt $end"

    try {
        $signins = Get-MgAuditLogSignIn -Filter $filter -ErrorAction SilentlyContinue |
        Select-Object AppDisplayName, AppId, AppliedConditionalAccessPolicies, ClientAppUsed, ConditionalAccessStatus, CorrelationId, CreatedDateTime, DeviceDetail, IPAddress, Id, IsInteractive, Location, ResourceDisplayName, ResourceId, Status, UserDisplayName, UserId, UserPrincipalName

        if ($signins) {
            $SignInLog = $signins | ForEach-Object {
                [PSCustomObject]@{
                    AppDisplayName            = "$($_.AppDisplayName)"
                    AppId                     = "$($_.AppId)"
                    ConditionalAccessPolicies = $_.AppliedConditionalAccessPolicies.DisplayName -join ","
                    ClientAppUsed             = $_.ClientAppUsed
                    ConditionalAccessStatus   = $_.ConditionalAccessStatus
                    CorrelationId             = $_.CorrelationId
                    CreatedDateTime           = $_.CreatedDateTime
                    DeviceBrowser             = $_.DeviceDetail.Browser
                    DeviceOperatingSystem     = $_.DeviceDetail.OperatingSystem
                    DeviceName                = $_.DeviceDetail.DisplayName
                    DeviceIsCompliant         = $_.DeviceDetail.IsCompliant
                    DeviceIsManaged           = $_.DeviceDetail.IsManaged
                    DeviceId                  = $_.DeviceDetail.DeviceId
                    DeviceTrust               = $_.DeviceDetail.TrustType
                    IPAddress                 = $_.IPAddress
                    Id                        = $_.Id
                    IsInteractive             = $_.IsInteractive
                    UserDisplayName           = $_.UserDisplayName
                    UserId                    = $_.UserId
                    UserPrincipalName         = $_.UserPrincipalName
                    City                      = $_.Location.City
                    State                     = $_.Location.State
                    CountryOrRegion           = $_.Location.CountryOrRegion
                    ResourceDisplayName       = $_.ResourceDisplayName
                    ResourceId                = $_.ResourceId
                    StatusDetail              = $_.Status.AdditionalDetails
                    StatusErrorCode           = $_.Status.ErrorCode
                    StatusFailureReason       = $_.Status.FailureReason
                }
            }
            Write-PodeJsonResponse -Value $SignInLog
        } else {
            Write-PodeJsonResponse -Value @()
        }
    } catch {
        Write-PodeErrorLog -Exception $_.Exception
        Write-PodeJsonResponse -StatusCode 500 -Value @{ error = $_.Exception.Message }
    }
}