<#
.SYNOPSIS
    PowerShell module containing useful work functions
.DESCRIPTION
    James A. Chambers - March 3rd 2026
#>

Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 | ForEach-Object { . $_.FullName }
Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 | ForEach-Object { . $_.FullName }

########## Configuration ##########


########## Other Variables ##########
$Script:MaximumFunctionCount = 10000
$Script:MaximumVariableCount = 10000
$Script:FollowUpActions = New-Object System.Collections.Generic.List[System.Object]
$Script:LogString = $null
$Script:OrgName = $null
$Script:OrgId = $null
$Script:DefaultDomain = $null
$Script:application = $null
$Script:connectionGraph = $null
$Script:connectionExchange = $null
$Script:certificate = Get-GraphAppCertificate
$Script:UpdateCheck = $false
$Script:ExchangeDisabled = $false

if ($PSVersionTable.PSVersion.Major -ge 7) {
    $Script:ParallelEnabled = $true
} else {
    $Script:ParallelEnabled = $false
    Write-Host "WARNING:  You are not running in PowerShell 7 or higher and are unable to run tasks in parallel (things will be slower)!" -ForegroundColor Yellow
}

Write-Host "Run the explorer using Invoke-365Explorer.  To see all commands use: Get-Command -Module 365Explorer" -ForegroundColor Cyan