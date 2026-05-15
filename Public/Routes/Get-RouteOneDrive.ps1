# --- List Drives for a User ---
$GetOneDriveDrivesScript = {
    $userid = $WebEvent.Query['user']
    if (-not $userid) {
        Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "Missing 'user' query parameter" }
        return
    }

    try {
        Write-Host "$(Get-Date) - Listing OneDrive drives for $userid" -ForegroundColor Yellow

        $drives = Get-MgUserDrive -UserId $userid -ErrorAction SilentlyContinue |
        Select-Object Id, Name, DriveType, WebUrl

        Write-PodeJsonResponse -Value $drives
    } catch {
        Write-PodeErrorLog -Exception $_.Exception
        Write-PodeJsonResponse -StatusCode 500 -Value @{ error = $_.Exception.Message }
    }
}

# --- List Children in a Folder ---
$GetOneDriveChildrenScript = {
    $userid = $WebEvent.Query['user']
    $driveId = $WebEvent.Query['drive']
    $itemId = $WebEvent.Query['item']

    if (-not $userid -or -not $driveId) {
        Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "Missing required parameters" }
        return
    }

    Write-Host "$(Get-Date) - Listing OneDrive items for drive $driveId (user: $userid)" -ForegroundColor Yellow

    try {
        if ($itemId) {
            $children = Get-MgDriveItemChild -DriveId $driveId -DriveItemId $itemId -ErrorAction SilentlyContinue
        } else {
            $children = Get-MgDriveRootChild -DriveId $driveId -ErrorAction SilentlyContinue
        }

        $items = $children | Select-Object Name, Id, @{N = 'Type'; E = { if ($_.Folder.ChildCount -ge 0) { 'Folder' } else { 'File' } } },
        @{N = 'SizeKB'; E = { [math]::Round($_.Size / 1KB, 2) } },
        @{N = 'LastModified'; E = { $_.LastModifiedDateTime } },
        @{N = 'WebUrl'; E = { $_.WebUrl } }

        Write-PodeJsonResponse -Value $items
    } catch {
        Write-PodeErrorLog -Exception $_.Exception
        Write-PodeJsonResponse -StatusCode 500 -Value @{ error = $_.Exception.Message }
    }
}

# --- OneDrive file download route ---
$GetOneDriveFileScript = {
    $user = $WebEvent.Query['user']
    $driveId = $WebEvent.Query['driveId']
    $itemId = $WebEvent.Query['itemId']

    if (-not $user -or -not $driveId -or -not $itemId) {
        Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "Missing required parameters" }
        return
    }

    Write-Host "$(Get-Date) - Retrieve OneDrive file - Drive: $driveId - Item: $itemId" -ForegroundColor Yellow

    try {
        # Get item metadata from Graph
        $item = Get-MgUserDriveItem -UserId $user -DriveId $driveId -DriveItemId $itemId -ErrorAction Stop

        # Extract authorized download URL (from AdditionalProperties)
        $downloadUrl = $item.AdditionalProperties.'@microsoft.graph.downloadUrl'

        if (-not $downloadUrl) {
            Write-PodeJsonResponse -StatusCode 404 -Value @{ error = "Download URL not found" }
            return
        }

        # Download file to temp
        $path = Join-Path $([System.IO.Path]::GetTempPath()) $item.Name
        Invoke-WebRequest -Uri $downloadUrl -OutFile $path -ErrorAction Stop

        Add-PodeHeader -Name "Content-Disposition" -Value "attachment; filename=`"$($item.Name)`""
        Write-PodeFileResponse -ContentType "application/octet-stream" -Path $path
    } catch {
        Write-PodeErrorLog -Exception $_.Exception
        Write-PodeJsonResponse -StatusCode 500 -Value @{ error = $_.Exception.Message }
    }
}

# --- Delete OneDrive Item ---
$DeleteOneDriveItemScript = {
    $user = $WebEvent.Query['user']
    $driveId = $WebEvent.Query['driveId']
    $itemId = $WebEvent.Query['itemId']

    if (-not $user -or -not $driveId -or -not $itemId) {
        Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "Missing required parameters" }
        return
    }

    try {
        Write-Host "$(Get-Date) - Deleting OneDrive item $itemId (drive $driveId, user $user)" -ForegroundColor Red

        # DELETE item from OneDrive
        Remove-MgDriveItem -DriveId $driveId -DriveItemId $itemId -ErrorAction Stop

        Write-PodeJsonResponse -Value @{ success = $true }
    }
    catch {
        Write-PodeErrorLog -Exception $_.Exception
        Write-PodeJsonResponse -StatusCode 500 -Value @{ error = $_.Exception.Message }
    }
}