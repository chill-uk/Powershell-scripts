$certificate_location = "cert:\LocalMachine\My"
$Certificate = $null

$computer_name = Read-Host -Prompt "What is the hostname of the platform you want to generate a self-signed certificate?"

function generate_new_certificate {
    New-SelfSignedCertificate -DnsName $computer_name -CertStoreLocation $certificate_location
} 

# function export_certificae {
#     # request user for password
#     $certificate_export_password = Read-Host -Prompt "Would you like to generate a self-signed cert for $($computer_name)? (y/n) [y]" -AsSecureString
#     #change secure-input to secure-string
#     $pwd = ConvertTo-SecureString -String "Pa$$w0rd" -Force -AsPlainText

#     # Export the certificate
#     $Export_location = Read-Host "Where would you like to store the certiifcate?"
#     Test-Path $Export_location
#     if Test-Path = bad{
#         Write-host "Path does not exist or you do not have the correct permissions"
#         Write-Host "Please enter a new destnation"
#         export_certificae
#     }
#     if Test-Path = good {
#         Export-PfxCertificate -cert $Certificate.Thumbprint -FilePath e:\temp\cert.pfx -Password $pwd
#     }
# }

$Certificate = Get-ChildItem -Path Cert:\localMachine\My -DnsName $computer_name

if ($null -eq $Certificate) {
    Write-Host -ForegroundColor Yellow "No certificate found found Local Computer\personal\Certificates"
    Write-Host
    $generate_certificate_y_n = Read-Host -Prompt "Would you like to generate a self-signed cert for $($computer_name)? (y/n) [y]"
    # $prompt = Read-Host "Press enter to accept the default [$($defaultValue)]"
    if ($generate_certificate_y_n -eq "y") {
        generate_new_certificate
    }
    else {
        Write-Host -ForegroundColor Red "No certificate generated"
    }
}
else {
    Write-Host -ForegroundColor Red "Certificate for $($computer_name) already exists"
    $Certificate
    # $overwrite_certificate_y_n = Read-Host -Prompt "Would you like to overwrite $($computer_name) with a new Certificate (y/n)"
}

# generates a secure string to apply to the export certificate process
# 

# Next stage is to export the certificate we set earlier.
# 