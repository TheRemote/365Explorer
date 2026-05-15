
# --- Unified Audit Logs ---
$GetAuditLogsScript = {
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
        Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "Missing 'start' or 'end' query parameters" }
        return
    }

    try {
        $startDate = [datetime]$start
        $endDate = [datetime]$end

        Write-Host "$(Get-Date) - Get audit logs for $($user.UserPrincipalName) - Start: $startDate - End: $endDate" -ForegroundColor Yellow
        
        $configPath = Join-Path "$([System.IO.Path]::GetTempPath())" "pode-config.json"
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        Write-Host "$(Get-Date) - Getting Exchange connection..." -ForegroundColor Cyan
        $null = Connect-ExchangeOnline -Organization $config.DefaultDomain -AppId $config.AppId -Certificate (Get-GraphAppCertificate) -ShowBanner:$false
        Write-Host "$(Get-Date) - Exchange connection completed" -ForegroundColor Cyan

        # Make sure logging is enabled
        $LogSettings = Get-AdminAuditLogConfig
        if ($LogSettings.UnifiedAuditLogIngestionEnabled -eq $false) {
            Write-Host -ForegroundColor Cyan "Enabling organization customization..."
            $null = Enable-OrganizationCustomization -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 3000
            Write-Host -ForegroundColor Cyan "Enabling unified audit logging..."
            $null = Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true
        
            $LogSettings = Get-AdminAuditLogConfig
            if ($LogSettings.AdminAuditLogEnabled -eq $false) { 
                Write-Host -ForegroundColor Green "Unified audit logging is disabled.  It was attempted to be enabled but likely enabling organization customization is delaying being able to turn it on.  Please try again later or enable it manually with`nSet-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled `$true"
            }
            else {
                Write-Host -ForegroundColor Cyan "Unified audit logging was disabled but has been successfully enabled.  Unified audit log data will not be available for a period of time."
            }
        }
        else {
            Write-Host -ForegroundColor Green "Unified audit log is enabled!"
        }

        # Retrieve unified audit log entries for that date range
        $logs = Search-UnifiedAuditLog -StartDate $startDate -EndDate $endDate -UserIds $user.UserPrincipalName -ResultSize 1000 -ErrorAction SilentlyContinue |
        Select-Object CreationDate, UserIds, Operations, Workload, ClientIP, UserAgent, ResultStatus, RecordType, Id, AuditData

        if (-not $logs -or $logs.Count -eq 0) {
            Write-PodeJsonResponse -Value @()
            return
        }

        # Helper: Flatten nested AuditData
        function Update-JsonObject($obj, $prefix = "") {
            $result = @{}
            foreach ($prop in $obj.PSObject.Properties) {
                $key = if ($prefix) { "$prefix.$($prop.Name)" } else { $prop.Name }
                $value = $prop.Value

                if ($value -is [PSCustomObject]) {
                    $nested = Update-JsonObject -obj $value -prefix $key
                    foreach ($k in $nested.Keys) {
                        $result[$k] = $nested[$k]
                    }
                }
                elseif ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
                    $result[$key] = ($value | ConvertTo-Json -Depth 5 -Compress)
                }
                else {
                    $result[$key] = $value
                }
            }
            return $result
        }

        $expandedLogs = foreach ($log in $logs) {
            $data = $null
            try { $data = ($log.AuditData | ConvertFrom-Json) } catch {}

            $flat = [ordered]@{
                CreationDate = $log.CreationDate
                UserId       = ($log.UserIds -join ",")
                Operation    = $log.Operations
                Workload     = $log.Workload
                ClientIP     = $log.ClientIP
                UserAgent    = $log.UserAgent
                ResultStatus = $log.ResultStatus
                RecordType   = $log.RecordType
                Id           = $log.Id
            }

            if ($data) {
                $flatData = Update-JsonObject $data
                foreach ($key in $flatData.Keys) {
                    $flat[$key] = $flatData[$key]
                }
            }

            [PSCustomObject]$flat
        }

        Write-PodeJsonResponse -Value $expandedLogs
    }
    catch {
        Write-PodeErrorLog -Exception $_.Exception
        Write-PodeJsonResponse -StatusCode 500 -Value @{ error = $_.Exception.Message }
    }
}
