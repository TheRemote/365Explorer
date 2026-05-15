<#
.SYNOPSIS
    Disconnects from Microsoft Graph and clears module variables
.DESCRIPTION
    James A. Chambers - March 3rd 2026
.EXAMPLE
    Reset-Graph
#>
function Reset-AppGraph {
    try {
        $null = Disconnect-MgGraph -ErrorAction SilentlyContinue
    } catch {}

    try {
        $null = Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
    } catch {}
    
    $Script:OrgName = $null
    $Script:connectionGraph = $null
    $Script:connectionExchange = $null
    $Script:ExchangeDisabled = $false
    Write-Host -ForegroundColor Cyan "Graph connection has been reset and disconnected!"
}