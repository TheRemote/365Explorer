function Get-GraphAppPermissions {
    $Script:GraphPermissions = @(
        "741f803b-c850-494e-b5df-cde7c675a1ca", # User RW All
        "50483e42-d915-4231-9639-7fdb7fd190e5", # User Authentication RW
        "77f3a031-c388-4f99-b373-dc68676a979e", # User Revoke All Sessions
        "62a82d76-70ea-41e2-9197-370581804d09", # Group RW
        "e2a3a72e-5f79-4c64-b1b1-878b674786c9", # Mail RW
        "fef87b92-8391-4589-9da7-eb93dab7dc8a", # Mailbox RW
        "6931bccd-447a-43d1-b442-00a195474933", # Mailbox Settings RW
        "294ce7c9-31ba-490a-ad7d-97a7d075e4ed", # Chat RW
        "ef54d2bf-783f-4e0f-bca1-3210c0444d99", # Calendar RW
        "6918b873-d17a-4dc1-b314-35f528134491", # Contacts RW
        "1138cb37-bd11-4084-a2b7-9f71582aeddb", # Device RW
        "7e05723c-0bb0-42da-be95-ae9f08a6e53c", # Domain RW
        "b2620db1-3bf7-4c5b-9cb9-576d29eac736", # eDiscovery RW
        "75359482-378d-4052-8f01-80520e7db3cd", # Files RW
        "c22a92cc-79bf-4bb1-8b6c-e0a05d3d80ce", # On-Prem RW
        "246dd0d5-5bd0-4def-940b-0421030a5b68", # Policy R
        "292d869f-3427-49a8-9dab-8c70152b74e9", # Organization RW
        "9e3f62cf-ca93-4989-b6ce-bf83c28f9fe8", # Role Management Directory RW
        "025d3225-3f02-4882-b4c0-cd5b541a4e80", # Role Management Exchange RW
        "b0afded3-3588-46d8-8b3d-9842eff778da", # Audit Log R
        "5e1e9171-754d-478c-812c-f1755a9a4c2d", # Audit Log Query R
        "a88eef72-fed0-4bf7-a2a9-f19df33f8b83", # Authentication Context R
        "9f1b81a7-0223-4428-bfa4-0bcb5535f27d", # Consent Requests RW
        "90db2b9a-d928-4d33-a4dd-8442ae3d41e4", # Identity Provider RW
        "db06fb33-1953-4b7b-a2ac-f1e2c854f7ae", # Identity Risk Event RW
        "607c7344-0eed-41e5-823a-9695ebe1b7b0", # Identity Risky SP RW
        "656f6061-f9fe-4807-9708-6a2e0934df76", # Identity Risky User RW
        "1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9", # Application RW
        "06b708a9-e830-4db3-a914-8e69da51d44f", # App Role Assignment RW
        "230c1aed-a721-4c5d-9cb4-a90514e508ef", # Reports R
        "2a60023f-3219-47ad-baa4-40e17cd02a1d", # Report Settings RW
        "01c0a623-fc9b-48e9-b794-0756f8e8f067", # Conditional Access RW
        "a82116e5-55eb-4c41-a434-62fe8a61c773", # Sites FullControl
        "9b50c33d-700f-43b1-b2eb-87e89b703581", # Synchronization RW
        "bdd80a03-d9bc-451d-b7c4-ce7c63fe3c8f", # TeamsSettings RW
        "a402ca1c-2696-4531-972d-6e5ee4aa11ea", # PermissionGrant RW
        "8e8e4742-1d95-4f68-9d56-6ee75648c72a", # Delegated PermisionGrant RW
        "57f1cf28-c0c4-4ec3-9a30-19a2eaaf2f6e", # Bitlocker R
        "6b22000a-1228-42ec-88db-b8c00399aecb", # Bookings Manage All
        "9769393e-5a9f-4302-9e3d-7e018ecb64a7" # Bookings Appointments RW All
    )

    # Initialize Graph resource access objects
    $requiredGrants = New-Object -TypeName System.Collections.Generic.List[Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess]
    $GraphResourceAccess = New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess
    $GraphResourceAccess.ResourceAppId = "00000003-0000-0000-c000-000000000000"
    $Script:GraphPermissions | ForEach-Object {
        $scope = @{ Id = $_; Type = "Role" }
        $GraphResourceAccess.ResourceAccess += $scope
    }
    $requiredGrants.Add($GraphResourceAccess)
    $GraphResourceAccess = New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess
    $GraphResourceAccess.ResourceAppId = "00000002-0000-0ff1-ce00-000000000000" # Exchange
    $GraphResourceAccess.ResourceAccess += @{ Id = "dc50a0fb-09a3-484d-be87-e023b12c6440"; Type = "Role" }
    $requiredGrants.Add($GraphResourceAccess)
    $GraphResourceAccess = New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess
    $GraphResourceAccess.ResourceAppId = "00000003-0000-0ff1-ce00-000000000000" # SharePoint
    $GraphResourceAccess.ResourceAccess += @{ Id = "678536fe-1083-478a-9c59-b99265e6b0d3"; Type = "Role" }
    $requiredGrants.Add($GraphResourceAccess)
    # Check application registration
    $Script:application = Get-MgApplication -Filter "DisplayName eq '365Explorer - PowerShell Administration Tool'"
    if ($null -ne $Script:application) {
        Write-Host -ForegroundColor Cyan "Registration is present."
        # Check application certificate
        Write-Host -ForegroundColor Cyan "Checking application certificate..."

        $certMatch = $false
        $certIndex = 0

        # Local certificate info (normalized to UTC)
        $localSubject = $Script:certificate[0].Subject
        $localStart = $Script:certificate[0].NotBefore.ToUniversalTime()
        $localEnd = $Script:certificate[0].NotAfter.ToUniversalTime()

        Write-Host ""
        Write-Host -ForegroundColor Yellow "LOCAL CERTIFICATE"
        Write-Host "Subject : $localSubject"
        Write-Host "Start   : $localStart"
        Write-Host "End     : $localEnd"
        Write-Host ""

        foreach ($keyCred in $Script:application.KeyCredentials) {

            $certIndex++

            Write-Host -ForegroundColor Cyan "APP CERTIFICATE #$certIndex"

            $appSubject = $keyCred.DisplayName
            $appStart = ([datetimeoffset]$keyCred.StartDateTime).UtcDateTime
            $appEnd = ([datetimeoffset]$keyCred.EndDateTime).UtcDateTime

            Write-Host "DisplayName : $appSubject"
            Write-Host "Start       : $appStart"
            Write-Host "End         : $appEnd"

            $sameSubject = ($appSubject -eq $localSubject)
            $sameStart = ($appStart -eq $localStart)
            $sameEnd = ($appEnd -eq $localEnd)

            Write-Host ""
            Write-Host "Subject Match : $sameSubject"
            Write-Host "Start Match   : $sameStart"
            Write-Host "End Match     : $sameEnd"

            if ($sameSubject -and $sameStart -and $sameEnd) {

                Write-Host -ForegroundColor Green "MATCH FOUND"
                $certMatch = $true
                break
            }

            Write-Host ""
        }

        if ($certMatch) {
            Write-Host -ForegroundColor Green "Certificate already exists in application registration."
        } else {
            Write-Host -ForegroundColor Cyan "Registration has a different certificate attached.  Reregistering application..."
            Remove-365Explorer
            $appRegistration = New-MgApplication -DisplayName "365Explorer - PowerShell Administration Tool" -SignInAudience "AzureADMyOrg" -Web @{ RedirectUris = "http://localhost"; } `
                -RequiredResourceAccess $requiredGrants -AdditionalProperties @{} -KeyCredentials @(@{ Type = "AsymmetricX509Cert"; Usage = "Verify"; Key = $Script:certificate[0].RawData })
            Write-Host -ForegroundColor Cyan "App registration created with app ID" $appRegistration.AppId
            New-MgServicePrincipal -AppId $appRegistration.AppId -AdditionalProperties @{} | Out-Null
            Write-Host -ForegroundColor Cyan "Service principal created"
            Start-Sleep -Milliseconds 5000
            $Script:application = Get-MgApplication -Filter "DisplayName eq '365Explorer - PowerShell Administration Tool'"
        }
    } else {
        Write-Host -ForegroundColor Cyan "Registration does not exist.  Registering application..."
        $appRegistration = New-MgApplication -DisplayName "365Explorer - PowerShell Administration Tool" -SignInAudience "AzureADMyOrg" -Web @{ RedirectUris = "http://localhost"; } `
            -RequiredResourceAccess $requiredGrants -AdditionalProperties @{} -KeyCredentials @(@{ Type = "AsymmetricX509Cert"; Usage = "Verify"; Key = $Script:certificate[0].RawData })
        Write-Host -ForegroundColor Cyan "App registration created with app ID" $appRegistration.AppId
        New-MgServicePrincipal -AppId $appRegistration.AppId -AdditionalProperties @{} | Out-Null
        Write-Host -ForegroundColor Cyan "Service principal created"
        Start-Sleep -Milliseconds 5000
        $Script:application = Get-MgApplication -Filter "DisplayName eq '365Explorer - PowerShell Administration Tool'"
    }
    # Check service principal
    Write-Host -ForegroundColor Cyan "Checking service principal..."
    $sp = Get-MgServicePrincipal -Filter "AppId eq '$($Script:application.AppId)'"
    if ($null -ne $sp) {
        Write-Host -ForegroundColor Cyan "Service principal is present."
    } else {
        Write-Host -ForegroundColor Cyan "Service principal does not exist.  Creating service principal..."
        New-MgServicePrincipal -AppId $Script:application.AppId -AdditionalProperties @{} | Out-Null
        $sp = Get-MgServicePrincipal -Filter "AppId eq '$($Script:application.AppId)'"
    }
    Write-Host -ForegroundColor Cyan "Checking required resource access..."
    $PermissionsObject = $Script:application.RequiredResourceAccess | Where-Object { $_.ResourceAppId -like "00000003-0000-0000-c000-000000000000" }
    $MissingPermissions = $Script:GraphPermissions | ForEach-Object {
        if ($PermissionsObject.ResourceAccess.Id -notcontains $_) {
            Write-Host -ForegroundColor Cyan "Missing permissions entry for $($_)"
            $_
        }
    }
    $PermissionsExchange = $Script:application.RequiredResourceAccess | Where-Object { $_.ResourceAppId -like "00000002-0000-0ff1-ce00-000000000000" }
    $PermissionsSharePoint = $Script:application.RequiredResourceAccess | Where-Object { $_.ResourceAppId -like "00000003-0000-0ff1-ce00-000000000000" }
    if ($null -ne $MissingPermissions -or $null -eq $PermissionsExchange -or $null -eq $PermissionsSharePoint) {
        Write-Host -ForegroundColor Cyan "Updating application required permissions..."
        Update-MgApplication -ApplicationId $Script:application.Id -RequiredResourceAccess $requiredGrants
        Start-Sleep -Milliseconds 8000
        $Script:application = Get-MgApplication -Filter "DisplayName eq '365Explorer - PowerShell Administration Tool'"
    }
    
    $graphsp = Get-MgServicePrincipal -Filter "AppId eq '00000003-0000-0000-c000-000000000000'"
    $exchangesp = Get-MgServicePrincipal -Filter "AppId eq '00000002-0000-0ff1-ce00-000000000000'"
    $sharepointsp = Get-MgServicePrincipal -Filter "AppId eq '00000003-0000-0ff1-ce00-000000000000'"
    $assignedRoles = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId "$($sp.Id)" # Check assigned roles
    $Script:GraphPermissions | ForEach-Object {
        if ($assignedRoles.AppRoleId -notcontains $_) {
            Write-Host -ForegroundColor Cyan "Giving admin consent for $_"
            New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId "$($sp.Id)" -PrincipalId "$($sp.Id)" -ResourceId "$($graphsp.Id)" -AppRoleId "$_" | Out-Null
        }
    }
    if ($assignedRoles.AppRoleId -notcontains "dc50a0fb-09a3-484d-be87-e023b12c6440") {
        if ($null -ne $exchangesp) {
            Write-Host -ForegroundColor Cyan "Giving admin consent for Exchange"
            New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId "$($sp.Id)" -PrincipalId "$($sp.Id)" -ResourceId "$($exchangesp.Id)" -AppRoleId "dc50a0fb-09a3-484d-be87-e023b12c6440" | Out-Null    
        } else {
            Write-Host -ForegroundColor Red "Exchange service principal does not exist -- Exchange will not be available!"
            $Script:ExchangeDisabled = $true
        }
    }
    if ($null -ne $sharepointsp -and $assignedRoles.AppRoleId -notcontains "678536fe-1083-478a-9c59-b99265e6b0d3") {
        Write-Host -ForegroundColor Cyan "Giving admin consent for SharePoint"
        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId "$($sp.Id)" -PrincipalId "$($sp.Id)" -ResourceId "$($sharepointsp.Id)" -AppRoleId "678536fe-1083-478a-9c59-b99265e6b0d3" | Out-Null
    }
    $entraRoles = Get-MgRoleManagementDirectoryRoleAssignment -All | Where-Object { $_.PrincipalId -eq $sp.Id } # Check Entra roles
    if ($entraRoles.RoleDefinitionId -notcontains "29232cdf-9323-42fd-ade2-1d097af3e4de") {
        Write-Host -ForegroundColor Cyan "Adding Exchange Administrator role"
        New-MgRoleManagementDirectoryRoleAssignment -PrincipalId $sp.Id -RoleDefinitionId "29232cdf-9323-42fd-ade2-1d097af3e4de" -DirectoryScopeId / | Out-Null
    }
    if ($entraRoles.RoleDefinitionId -notcontains "f28a1f50-f6e7-4571-818b-6a12f2af6b6c") {
        Write-Host -ForegroundColor Cyan "Adding SharePoint Administrator role"
        New-MgRoleManagementDirectoryRoleAssignment -PrincipalId $sp.Id -RoleDefinitionId "f28a1f50-f6e7-4571-818b-6a12f2af6b6c" -DirectoryScopeId / | Out-Null
    }
    if ($entraRoles.RoleDefinitionId -notcontains "62e90394-69f5-4237-9190-012177145e10") {
        Write-Host -ForegroundColor Cyan "Adding Global Administrator role"
        New-MgRoleManagementDirectoryRoleAssignment -PrincipalId $sp.Id -RoleDefinitionId "62e90394-69f5-4237-9190-012177145e10" -DirectoryScopeId / | Out-Null
        Write-Host -ForegroundColor Cyan "Sleeping for 20 seconds to let permissions catch up..."
        Start-Sleep -Milliseconds 20000
    }
}