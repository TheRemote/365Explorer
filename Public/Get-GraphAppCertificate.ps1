<#
.SYNOPSIS
    Gets Graph certificate for use by internal processes
.DESCRIPTION
    James A. Chambers - March 3rd 2026
.EXAMPLE
    Get-GraphAppCertificate
#>
function Get-GraphAppCertificate {
    # Check certificate
    if ($null -eq $Script:certificate) {
        $TmpDir = [System.IO.Path]::GetTempPath()
        $CertPath = Join-Path $TmpDir "365Explorer.pfx"
        if (Test-Path -Path "$CertPath") {
            $Script:certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("$CertPath", (ConvertTo-SecureString -String 'Abcd#1234!' -Force -AsPlainText))
            return $Script:certificate
        }
        else {
            Write-Host -ForegroundColor Cyan "Creating certificate..."
            
            $password = ConvertTo-SecureString 'Abcd#1234!' -AsPlainText -Force
            $dnsName = "localhost"

            # Build Distinguished Name
            $subject = [System.Security.Cryptography.X509Certificates.X500DistinguishedName]::new(
                "CN=$dnsName"
            )

            # Create RSA key
            $rsa = [System.Security.Cryptography.RSA]::Create(2048)

            # Create certificate request
            $request = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new(
                $subject,
                $rsa,
                [System.Security.Cryptography.HashAlgorithmName]::SHA256,
                [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
            )

            # Enhanced Key Usage (Server Authentication)
            $ekuCollection = [System.Security.Cryptography.OidCollection]::new()

            [void]$ekuCollection.Add(
                [System.Security.Cryptography.Oid]::new("1.3.6.1.5.5.7.3.1")
            )

            $ekuExtension = [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]::new(
                $ekuCollection,
                $false
            )

            [void]$request.CertificateExtensions.Add($ekuExtension)

            # Subject Alternative Name
            $sanBuilder = [System.Security.Cryptography.X509Certificates.SubjectAlternativeNameBuilder]::new()
            $sanBuilder.AddDnsName($dnsName)

            [void]$request.CertificateExtensions.Add($sanBuilder.Build())

            # Create self-signed cert
            $cert = $request.CreateSelfSigned(
                [DateTimeOffset]::Now,
                [DateTimeOffset]::Now.AddYears(1)
            )

            # Export PFX
            $pfxBytes = $cert.Export(
                [System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx,
                $password
            )

            # Save to disk
            [System.IO.File]::WriteAllBytes($CertPath, $pfxBytes)

            # Cleanup
            $rsa.Dispose()
            $cert.Dispose()

            # Re-import certificate
            $Script:certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
                $CertPath,
                $password,
                [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
            )

            return $Script:certificate
        }
    }
    else {
        return $Script:certificate
    }
}