function Get-GraphAppDependencies {
    Write-Host -ForegroundColor Cyan "Checking Graph dependencies..."
    $provider = Get-PackageProvider | Where-Object -Property Name -eq "NuGet"
    $repository = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
    $psget = Get-Module -ListAvailable -Name "PowerShellGet" -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1
    $exchange = Get-Module -ListAvailable -Name "ExchangeOnlineManagement" -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1
    $graph = Get-Module -ListAvailable -Name "Microsoft.Graph" -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1
    if ($null -eq $provider -or $null -eq $repository -or $repository.InstallationPolicy -eq "Untrusted" -or $null -eq $psget -or ($psget.Version -lt [Version]"2.2.5") -or $null -eq $exchange -or ($exchange.Version -lt [Version]"3.6.0") -or $null -eq $graph -or ($graph.Version -lt [Version]"2.28.0")) {
        $null = Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force -Confirm:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        if ($null -eq $provider) { Write-Host -ForegroundColor Cyan "Installing NuGet..."; $null = Install-PackageProvider -Name NuGet -Confirm:$false -Force }
        $repository = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
        if ($null -eq $repository) {
            Write-Host -ForegroundColor Cyan "Registering PSGallery"
            $null = Register-PSRepository -Default -ErrorAction SilentlyContinue
            $repository = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
        }
        if ($repository.InstallationPolicy -eq "Untrusted") {
            Write-Host -ForegroundColor Cyan "Trusting PSGallery"
            $null = Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
        }
        $psget = Get-Module -ListAvailable -Name "PowerShellGet" -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1
        if ($null -eq $psget -or ($psget.Version -lt [Version]"2.2.5")) {
            Write-Host -ForegroundColor Cyan "Upgrading PowerShellGet..."
            Install-Module PowerShellGet -RequiredVersion 2.2.5 -AllowClobber -SkipPublisherCheck -Force -Confirm:$false -Scope CurrentUser
            $null = Remove-Module PackageManagement -Force
            $null = Import-Module PowerShellGet -RequiredVersion 2.2.5 -Force
            $provider = Get-PackageProvider -ListAvailable PowerShellGet | Sort-Object -Property Version -Descending | Select-Object -First 1
            $null = Import-PackageProvider -Name PowerShellGet -Force -RequiredVersion $provider.Version
        }
        if ($null -eq $exchange -or ($exchange.Version -lt [Version]"3.8.0")) {
            Write-Host -ForegroundColor Cyan "Installing ExchangeOnlineManagement..."
            $null = Import-Module PowerShellGet -RequiredVersion 2.2.5 -Force
            Install-Module -Force -AllowPrerelease -SkipPublisherCheck -Confirm:$false ExchangeOnlineManagement -Scope CurrentUser
        }
        if ($null -eq $graph -or ($graph.Version -lt [Version]"2.28.0")) {
            Write-Host -ForegroundColor Cyan "Installing Microsoft.Graph..."
            Install-Module -Force -SkipPublisherCheck -Confirm:$false Microsoft.Graph -Scope CurrentUser
        }
    }
    return $true
}