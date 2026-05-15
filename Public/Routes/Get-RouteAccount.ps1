
# --- Account info ---
$GetAccountInfoScript = {
    $userid = $WebEvent.Query['user']
    if (-not $userid) {
        Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "Missing 'user' query parameter" }
        return
    }
    $user = Get-MgUser -UserId $userid -Property Id, accountEnabled, displayName, mail, userPrincipalName, assignedLicenses, assignedPlans, createdDateTime, lastPasswordChangeDateTime, jobTitle, department, officeLocation, userType, usageLocation, preferredLanguage, proxyAddresses, onPremisesSyncEnabled, onPremisesDomainName, passwordPolicies, signInSessionsValidFromDateTime
    if (-not $user) {
        Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "User not found" }
        return
    }

    Write-Host "$(Get-Date) - Get account info for $($user.UserPrincipalName)" -ForegroundColor Yellow

    $configPath = Join-Path "$([System.IO.Path]::GetTempPath())" "pode-config.json"
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    Write-Host "$(Get-Date) - Getting Exchange connection..." -ForegroundColor Cyan
    Write-Host $config
    $null = Connect-ExchangeOnline -Organization $config.DefaultDomain -AppId $config.AppId -Certificate (Get-GraphAppCertificate) -ShowBanner:$false
    Write-Host "$(Get-Date) - Exchange connection completed" -ForegroundColor Cyan
        
    try {
        $signin = Get-MgUser -UserId $userid -Property signInActivity -ErrorAction SilentlyContinue
    } catch {}

    # === Exchange Mailbox Data ===
    try {
        $mailbox = Get-Mailbox -Identity $user.UserPrincipalName -ErrorAction SilentlyContinue

        $stats = Get-MailboxStatistics -Identity $user.UserPrincipalName
        $archiveStats = Get-MailboxStatistics -Identity $user.UserPrincipalName -Archive -ErrorAction SilentlyContinue
        $quota = $mailbox | Select-Object IssueWarningQuota, ProhibitSendQuota, ProhibitSendReceiveQuota
        $archiveQuota = $mailbox.ArchiveQuota

        function Convert-ToMB($sizeString) {
            if (-not $sizeString) { return 0 }
            if ($sizeString -match "([\d\.]+)\s*(\w+)") {
                $number = [double]$matches[1]
                $unit = $matches[2].ToUpper()
                switch ($unit) {
                    "KB" { return [math]::Round($number / 1024, 2) }
                    "MB" { return [math]::Round($number, 2) }
                    "GB" { return [math]::Round($number * 1024, 2) }
                    default { return 0 }
                }
            } else { return 0 }
        }

        # === Size calculations ===
        $mailboxSizeMB = Convert-ToMB $stats.TotalItemSize.Value
        $archiveSizeMB = if ($archiveStats) { Convert-ToMB $archiveStats.TotalItemSize.Value } else { 0 }
        $maxMailboxMB = Convert-ToMB $quota.ProhibitSendQuota.Value
        $maxArchiveMB = if ($archiveQuota) { Convert-ToMB $archiveQuota.Value } else { 0 }
    } catch {
        Write-PodeErrorLog -Exception $_.Exception
        $mailboxSizeMB = "N/A"
        $archiveSizeMB = "N/A"
        $maxMailboxMB = "N/A"
        $maxArchiveMB = "N/A"
    }

    try {
        # === License Resolution ===
        $skus = Get-MgSubscribedSku
        $Licenses = $user.AssignedLicenses | ForEach-Object {
            $lic = $_
            $sku = $skus | Where-Object { $_.SkuId -eq $lic.SkuId }
            if ($sku) { $sku.SkuPartNumber } else { $lic.SkuId }
        }

        # === Assigned Plan Details (flattened string output) ===
        if ($user.AssignedPlans) {
            $AssignedPlans = $user.AssignedPlans | ForEach-Object {
                $_.Service
            }
            $AssignedPlans = $AssignedPlans | Sort-Object -Unique
            $AssignedPlansString = $AssignedPlans -join ", "
        } else {
            $AssignedPlansString = ""
        }

        # === Combine all info ===
        $result = [PSCustomObject]@{
            # --- Basic Identity ---
            DisplayName              = $user.DisplayName
            UserPrincipalName        = $user.UserPrincipalName
            Mail                     = $user.Mail
            UserId                   = $userid
            UserType                 = $user.UserType
            Department               = $user.Department
            JobTitle                 = $user.JobTitle
            OfficeLocation           = $user.OfficeLocation
            CompanyDomain            = $user.OnPremisesDomainName
            UsageLocation            = $user.UsageLocation
            PreferredLanguage        = $user.PreferredLanguage
            ProxyAddresses           = $user.ProxyAddresses -join ", "

            # --- Account State ---
            Enabled                  = $user.AccountEnabled
            PasswordPolicies         = $user.PasswordPolicies
            PasswordChanged          = $user.LastPasswordChangeDateTime
            SignInSessionsValidFrom  = $user.SignInSessionsValidFromDateTime
            CreatedDateTime          = $user.CreatedDateTime
            LastSignInDate           = if ($signin) { $user.SignInActivity.LastSignInDateTime } else { "Missing P1" }
            LastNonInteractiveSignIn = if ($signin) { $user.SignInActivity.LastNonInteractiveSignInDateTime } else { "Missing P1" }
            OnPremisesSyncEnabled    = if ($user.OnPremisesSyncEnabled) { $user.OnPremisesSyncEnabled } else { "false" }

            # --- Licensing ---
            IsLicensed               = ($user.AssignedLicenses.Count -gt 0)
            LicenseCount             = $Licenses.Count
            Licensing                = $Licenses
            AssignedPlans            = $AssignedPlansString

            # --- Mailbox Info ---
            PrimarySmtpAddress       = if ($mailbox) { $mailbox.PrimarySmtpAddress } else { "N/A" }
            MailboxType              = if ($mailbox) { $mailbox.RecipientTypeDetails } else { "N/A" }
            HiddenFromGAL            = if ($mailbox) { $mailbox.HiddenFromAddressListsEnabled } else { "N/A" }
            ArchiveStatus            = if ($mailbox) { $mailbox.ArchiveStatus } else { "N/A" }
            RetentionPolicy          = if ($mailbox) { $mailbox.RetentionPolicy } else { "N/A" }
            LitigationHoldEnabled    = if ($mailbox) { $mailbox.LitigationHoldEnabled } else { "N/A" }
            ForwardingAddress        = if ($mailbox) { $mailbox.ForwardingSmtpAddress } else { "N/A" }

            # --- Mailbox Usage ---
            MailboxSizeMB            = $mailboxSizeMB
            MailboxQuotaMB           = $maxMailboxMB
            ItemCount                = if ($stats) { $stats.ItemCount } else { "N/A" }
            DeletedItemCount         = if ($stats) { $stats.DeletedItemCount } else { "N/A" }
            ArchiveSizeMB            = $archiveSizeMB
            ArchiveQuotaMB           = $maxArchiveMB
            ArchiveItemCount         = if ($archiveStats) { $archiveStats.ItemCount } else { "N/A" }
        }

        Write-PodeJsonResponse -Value $result
    } catch {
        Write-PodeErrorLog -Exception $_.Exception
        Write-PodeJsonResponse -StatusCode 500 -Value @{ error = $_.Exception.Message }
    }
}