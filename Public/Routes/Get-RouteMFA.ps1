
# --- Get MFA methods ---
$GetMFAMethodsScript = {
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

    Write-Host "$(Get-Date) - Retrieve MFA methods for $($user.UserPrincipalName)" -ForegroundColor Yellow

    try {
        # Retrieve authentication methods
        $methods = Get-MgUserAuthenticationMethod -UserId $user.Id -ErrorAction SilentlyContinue

        if ($null -eq $methods -or $methods.Count -eq 0) {
            Write-PodeJsonResponse -Value @()
            return
        }

        $MFAData = $methods | ForEach-Object {
            $type = $_.AdditionalProperties.'@odata.type'
            $method = $_.AdditionalProperties
            $id = $_.Id
            switch -Regex ($type) {
                '#microsoft.graph.passwordAuthenticationMethod' {
                    [PSCustomObject]@{
                        Id      = $id
                        Type    = 'Password'
                        RawType = 'microsoft.graph.passwordAuthenticationMethod'
                        Detail  = "Last Changed: $($method.createdDateTime)"
                    }
                }
                '#microsoft.graph.fido2AuthenticationMethod' {
                    [PSCustomObject]@{
                        Id      = $id
                        Type    = 'FIDO2 Security Key'
                        RawType = 'microsoft.graph.fido2AuthenticationMethod'
                        Detail  = $method.model
                    }
                }
                '#microsoft.graph.microsoftAuthenticatorAuthenticationMethod' {
                    [PSCustomObject]@{
                        Id      = $id
                        Type    = 'Microsoft Authenticator App'
                        RawType = 'microsoft.graph.microsoftAuthenticatorAuthenticationMethod'
                        Detail  = "Device: $($method.displayName) - Tag: $($method.deviceTag) - Version: $($method.phoneAppVersion)"
                    }
                }
                '#microsoft.graph.windowsHelloForBusinessAuthenticationMethod' {
                    [PSCustomObject]@{
                        Id      = $id
                        Type    = 'Windows Hello for Business'
                        RawType = 'microsoft.graph.windowsHelloForBusinessAuthenticationMethod'
                        Detail  = "Device: $($method.displayName) - Created: $($method.createdDateTime) - KeyStrength: $($method.keyStrength)"
                    }
                }
                '#microsoft.graph.phoneAuthenticationMethod' {
                    [PSCustomObject]@{
                        Id      = $id
                        Type    = 'Phone'
                        RawType = 'microsoft.graph.phoneAuthenticationMethod'
                        Detail  = "$($method.phoneType): $($method.phoneNumber)"
                    }
                }
                '#microsoft.graph.emailAuthenticationMethod' {
                    [PSCustomObject]@{
                        Id      = $id
                        Type    = 'Email'
                        RawType = 'microsoft.graph.emailAuthenticationMethod'
                        Detail  = $($method.emailAddress)
                    }
                }
                '#microsoft.graph.softwareOathAuthenticationMethod' {
                    [PSCustomObject]@{
                        Id      = $id
                        Type    = 'Software OATH Token'
                        RawType = 'microsoft.graph.softwareOathAuthenticationMethod'
                        Detail  = ''
                    }
                }
                '#microsoft.graph.tempAccessPassAuthenticationMethod' {
                    [PSCustomObject]@{
                        Id      = $id
                        Type    = 'Temporary Access Pass'
                        RawType = 'microsoft.graph.tempAccessPassAuthenticationMethod'
                        Detail  = "Date Created: $($method.createdDateTime)"
                    }
                }
                default {
                    [PSCustomObject]@{
                        Id      = $id
                        Type    = $type
                        RawType = $type
                        Detail  = "(Unknown type)"
                    }
                }
            }
        }

        Write-PodeJsonResponse -Value $MFAData
    } catch {
        Write-PodeErrorLog -Exception $_.Exception
        Write-PodeJsonResponse -StatusCode 500 -Value @{ error = $_.Exception.Message }
    }
}

$DeleteMFAMethodScript = {
    $userid = $WebEvent.Query['user']
    if (-not $userid) {
        Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "Missing 'user' query parameter" }
        return
    }

    $MethodId = $WebEvent.Query['id']
    $Type = $WebEvent.Query['type']

    Write-Host "$(Get-Date) - Delete MFA method $($Type)" -ForegroundColor Yellow

    if (-not $Type) {
        Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "Missing 'type' query parameter" }
        return
    }

    try {
        $success = $false

        switch ($Type.ToLower()) {
            'microsoft.graph.microsoftauthenticatorauthenticationmethod' {
                Remove-MgUserAuthenticationMicrosoftAuthenticatorMethod -UserId $userId -MicrosoftAuthenticatorAuthenticationMethodId $MethodId -Confirm:$false -ErrorAction Stop
                $success = $true
            }
            'microsoft.graph.phoneauthenticationmethod' {
                Remove-MgUserAuthenticationPhoneMethod -UserId $userId -PhoneAuthenticationMethodId $MethodId -Confirm:$false -ErrorAction Stop
                $success = $true
            }
            'microsoft.graph.emailauthenticationmethod' {
                Remove-MgUserAuthenticationEmailMethod -UserId $userId -EmailAuthenticationMethodId $MethodId -Confirm:$false -ErrorAction Stop
                $success = $true
            }
            'microsoft.graph.fido2authenticationmethod' {
                Remove-MgUserAuthenticationFido2Method -UserId $userId -Fido2AuthenticationMethodId $MethodId -Confirm:$false -ErrorAction Stop
                $success = $true
            }
            'microsoft.graph.softwareoathauthenticationmethod' {
                Remove-MgUserAuthenticationSoftwareOathMethod -UserId $userId -SoftwareOathAuthenticationMethodId $MethodId -Confirm:$false -ErrorAction Stop
                $success = $true
            }
            'microsoft.graph.temporaryaccesspassauthenticationmethod' {
                Remove-MgUserAuthenticationTemporaryAccessPassMethod -UserId $userId -TemporaryAccessPassAuthenticationMethodId $MethodId -Confirm:$false -ErrorAction Stop
                $success = $true
            }
            'microsoft.graph.windowshelloforbusinessauthenticationmethod' {
                Remove-MgUserAuthenticationWindowsHelloForBusinessMethod -UserId $userId -WindowsHelloForBusinessAuthenticationMethodId $MethodId -Confirm:$false -ErrorAction Stop
                $success = $true
            }
            default {
                Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "Unsupported MFA type: $Type" }
                return
            }
        }

        if ($success) {
            Write-PodeJsonResponse -Value @{ success = $true }
        }
    } catch {
        Write-PodeErrorLog -Exception $_.Exception
        Write-PodeJsonResponse -StatusCode 500 -Value @{ error = $_.Exception.Message }
    }
}