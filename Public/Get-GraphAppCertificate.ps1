<#
.SYNOPSIS
    Gets Graph certificate for use by internal processes
.DESCRIPTION
    James A. Chambers - March 3rd 2026
.EXAMPLE
    Get-GraphAppCertificate
#>
function Get-GraphAppCertificate {
    if ($null -ne $Script:certificate) { return $Script:certificate }

    $TmpDir = [System.IO.Path]::GetTempPath()
    $CertPath = Join-Path $TmpDir "365Explorer.pfx"
    $PasswordStr = 'Abcd#1234!'
    $SecurePassword = ConvertTo-SecureString -String $PasswordStr -Force -AsPlainText

    if (Test-Path -Path "$CertPath") {
        # Fix: Add MachineKeySet and PersistKeySet flags for stable Windows file parsing
        $Script:certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
            $CertPath, 
            $SecurePassword,
            ([System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable -bor 
             [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet)
        )
        return $Script:certificate
    }

    Write-Host -ForegroundColor Cyan "Creating in-memory certificate (Cross-Platform)..."

    $dnsName = "365Explorer"
    $subject = [System.Security.Cryptography.X509Certificates.X500DistinguishedName]::new("CN=$dnsName")
    $rsa = [System.Security.Cryptography.RSA]::Create(2048)

    $request = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new(
        $subject, $rsa,
        [System.Security.Cryptography.HashAlgorithmName]::SHA256,
        [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
    )

    # Inject BOTH Server and Client Auth OIDs so it works on both platforms
    $ekuCollection = [System.Security.Cryptography.OidCollection]::new()
    [void]$ekuCollection.Add([System.Security.Cryptography.Oid]::new("1.3.6.1.5.5.7.3.1")) # Server Auth
    [void]$ekuCollection.Add([System.Security.Cryptography.Oid]::new("1.3.6.1.5.5.7.3.2")) # Client Auth
    
    $ekuExtension = [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]::new($ekuCollection, $false)
    [void]$request.CertificateExtensions.Add($ekuExtension)

    # Key Usage Flags
    $keyUsage = [System.Security.Cryptography.X509Certificates.X509KeyUsageExtension]::new(
        [System.Security.Cryptography.X509Certificates.X509KeyUsageFlags]::DigitalSignature -bor 
        [System.Security.Cryptography.X509Certificates.X509KeyUsageFlags]::KeyEncipherment, $true
    )
    [void]$request.CertificateExtensions.Add($keyUsage)

    # Generate and export safely without touching the Windows Local OS Store
    # Backdated by 1 hour to easily handle any minor local machine time variations
    $cert = $request.CreateSelfSigned([DateTimeOffset]::Now.AddHours(-1), [DateTimeOffset]::Now.AddYears(1))
    $pfxBytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx, $SecurePassword)
    [System.IO.File]::WriteAllBytes($CertPath, $pfxBytes)

    $rsa.Dispose()
    $cert.Dispose()

    $Script:certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
        $CertPath, $SecurePassword,
        ([System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable -bor 
         [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet)
    )

    return $Script:certificate
}
