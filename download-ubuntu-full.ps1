# Checks and downloads your Ubuntu isos (full versions).
# attaches hash to each file via alternative data streams
# Written by Christopher Hill 2019/07/01

Import-Module BitsTransfer
$ubuntu_versions = @("18.04.1","18.10","19.04")
#$progressPreference = 'silentlyContinue'


function generate_hash 
{
    $file_downloaded = Test-Path ".\$file_name"
    if ($file_downloaded -eq "True")
    {
        Write-Host -ForegroundColor yellow "Generating hash"
        $current_file_hash = Get-FileHash .\$file_Name -Algorithm MD5
        $current_file_hash = $current_file_hash.hash
        Add-Content -path .\$file_Name -Value $current_file_hash -Stream FileHash
    }
    else
    {
        Write-Host -ForegroundColor red "$file_Name not found"        
    }
    return $current_file_hash
}

function download_iso
{
    Write-Host "Downloading $ubuntu_url$file_Name" 
    Start-BitsTransfer -Source $ubuntu_url$file_Name -Destination .\$file_Name
    $file_downloaded = Test-Path ".\$file_name"
    if ($file_downloaded -ne "True")
    {
        Write-Host -ForegroundColor red "Problem saving $file_Name"
    }
}

foreach ($ubuntu_version in $ubuntu_versions) 
{
    $ubuntu_url = "http://releases.ubuntu.com/$ubuntu_version/"
    $ubuntu_archive = $ubuntu_url + "MD5SUMS"
    $md5_file_name = $ubuntu_version + ".MD5SUMS"

    try 
    {
        $statuscode = (invoke-webrequest -uri $ubuntu_archive -UseBasicParsing -TimeoutSec 5 -DisableKeepAlive -method Head).statusdescription
    }
    catch 
    {
        $statuscode = "URL DOES NOT EXIST"
    }

    if ($statuscode -eq "OK") 
    {
        Write-Host " "
        Write-Host -ForegroundColor green "URL for $ubuntu_version exists"
        Write-Host " "
    
        Invoke-WebRequest -uri $ubuntu_archive -OutFile .\$md5_file_name
        $file_downloaded = Test-Path ".\$md5_file_name"
        if ($file_downloaded -eq "True")
        {
            $remote_file_hashes = Get-Content -Path .\$md5_file_name

            foreach ($Data in $remote_file_hashes) 
            {
                $Data = $Data -split(' ')
                $hash = $Data[0]
                $file_name = $Data[1].Trim("*")
    
                $file_downloaded = Test-Path ".\$file_name"

                if ($file_downloaded -eq "True")
                {
                    Write-Host "$file_Name is already downloaded."
                    Write-Host -ForegroundColor yellow "Checking for hash."
            
                    $ErrorActionPreference = "silentlyContinue"
                    $current_file_hash = Get-Content ".\$file_name" -Stream FileHash
                    $ErrorActionPreference = "Continue"
                    if ($null -eq $current_file_hash)
                    {
                        Write-Host -ForegroundColor yellow "Hash not found."
                        $current_file_hash = generate_hash
                    }
                    if ($hash -ne $current_file_hash)
                    {
                        Write-Host -ForegroundColor red "Hash is different, downloading new version"
                        download_iso
                        $current_file_hash = generate_hash
                    }
                }
                else
                {
                    Write-Host -ForegroundColor yellow "$file_name not found locally."
                    download_iso
                    $current_file_hash = generate_hash
                }
                if ($hash -ne $current_file_hash)
                {
                    Write-Host -ForegroundColor red "$file_name verification failed."
                    Write-Host -ForegroundColor red "Either your iso is corrupt, or Ubuntu's MD5 hashes are out of date"
                }
                else
                {
                    Write-Host -ForegroundColor green "Verification successfull. You have the latest version"
                    Write-Host ""
                }
            }
        }
        else
        {
            Write-Host -ForegroundColor red "Problem saving $md5_file_Name"
        }
    }
    else 
    { 
        Write-Host " "
        Write-Host -ForegroundColor red "URL for Ubuntu $ubuntu_version doesn't exist"
        Write-Host " "
    }
}
