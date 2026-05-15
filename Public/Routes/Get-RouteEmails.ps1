$GetEmailsScript = {
    $userid = $WebEvent.Query['user']
    if (-not $userid) {
        Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "Missing 'user' query parameter" }
        return
    }

    $mailcount = [int]($WebEvent.Query['mailcount'] ?? 10)
    $subjectSearch = $WebEvent.Query['subject']
    $startDate = $WebEvent.Query['start']
    $endDate = $WebEvent.Query['end']

    Write-Host "$(Get-Date) - Get emails - Subject: $($subjectSearch) - Start: $startDate - End: $endDate" -ForegroundColor Yellow

    # Build Graph filter query
    $filters = @()
    if ($subjectSearch) {
        $filters += "contains(subject,'$subjectSearch')"
    }
    if ($startDate) {
        $filters += "sentDateTime ge $startDate"
    }
    if ($endDate) {
        $filters += "sentDateTime le $endDate"
    }
    $filterQuery = if ($filters.Count -gt 0) { $filters -join ' and ' } else { $null }

    # Fetch message list
    $emails = Get-MgUserMessage -UserId $userid -Top $mailcount -Property Id, Subject, Body, BodyPreview, From, ToRecipients, ReplyTo, SentDateTime, HasAttachments, ParentFolderId, InternetMessageHeaders -Filter $filterQuery

    $emails = $emails | ForEach-Object {
        $email = $_
        $folderName = ''
        try {
            $folder = Get-MgUserMailFolder -UserId $userid -MailFolderId $email.ParentFolderId -ErrorAction Stop
            $folderName = $folder.DisplayName
        } catch { $folderName = '(Unknown)' }

        $attachments = @()
        if ($email.HasAttachments -eq $true) {
            try {
                $atts = Get-MgUserMessageAttachment -UserId $userid -MessageId $email.Id -ErrorAction Stop
                $attachments = $atts | ForEach-Object {
                    [PSCustomObject]@{
                        Name        = $_.Name
                        Size        = $_.Size
                        ContentType = $_.ContentType
                        WebLink     = "/api/attachment?user=$userid&messageId=$($email.Id)&attachmentId=$($_.Id)"
                    }
                }
            } catch {
                Write-Warning "Failed to fetch attachments for message $($email.Id): $_"
            }
        }

        [PSCustomObject]@{
            Id                     = $email.Id
            Folder                 = $folderName
            Subject                = $email.Subject
            BodyPreview            = $email.BodyPreview
            From                   = $email.From.EmailAddress.Address
            To                     = ($email.ToRecipients | ForEach-Object { $_.EmailAddress.Address }) -join ', '
            ReplyTo                = ($email.ReplyTo | ForEach-Object { $_.EmailAddress.Address }) -join ', '
            SentDateTime           = $email.SentDateTime
            HasAttachments         = $email.HasAttachments
            Attachments            = $attachments
            Body                   = $email.Body.Content
            InternetMessageHeaders = $email.InternetMessageHeaders
        }
    }

    Write-PodeJsonResponse -Value $emails -Depth 5
}

$DeleteEmailScript = {
    $user = $WebEvent.Query['user']
    $id = $WebEvent.Query['id']

    if (-not $user -or -not $id) {
        Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "Missing parameters" }
        return
    }

    Write-Host "$(Get-Date) - Delete email" -ForegroundColor Yellow

    try {
        Remove-MgUserMessage -UserId $user -MessageId $id -Confirm:$false -ErrorAction Stop
        Write-PodeJsonResponse -Value @{ success = $true }
    } catch {
        Write-PodeErrorLog -Exception $_.Exception
        Write-PodeJsonResponse -StatusCode 500 -Value @{ error = $_.Exception.Message }
    }
}


# --- Download attachment route ---
$GetAttachmentScript = {
    $user = $WebEvent.Query['user']
    $messageId = $WebEvent.Query['messageId']
    $attachmentId = $WebEvent.Query['attachmentId']

    if (-not $user -or -not $messageId -or -not $attachmentId) {
        Write-PodeJsonResponse -StatusCode 400 -Value @{ error = "Missing required parameters" }
        return
    }

    Write-Host "$(Get-Date) - Retrieve attachment - MessageId: $messageId" -ForegroundColor Yellow

    try {
        # Fetch the attachment metadata and content from Microsoft Graph
        $attachment = Get-MgUserMessageAttachment -UserId $user -MessageId $messageId -AttachmentId $attachmentId -ErrorAction Stop

        # For file attachments, the content bytes are stored in $attachment.ContentBytes (Base64)
        if ($attachment.ContentType -and $attachment.AdditionalProperties.contentBytes) {
            $bytes = [System.Convert]::FromBase64String($attachment.AdditionalProperties.contentBytes)
            $path = "$([System.IO.Path]::GetTempPath())$($attachment.Name)"
            [System.IO.File]::WriteAllBytes($path, $bytes)

            # Set the correct content headers and send file
            Add-PodeHeader -Name "Content-Disposition" -Value "attachment; filename=`"$($attachment.Name)`""
            Write-PodeFileResponse -ContentType $attachment.ContentType -Path "$path"
        } else {
            Write-PodeJsonResponse -StatusCode 404 -Value @{ error = "Attachment not found or not a file type" }
        }
    } catch {
        Write-PodeErrorLog -Exception $_.Exception
        Write-PodeJsonResponse -StatusCode 500 -Value @{ error = $_.Exception.Message }
    }
}