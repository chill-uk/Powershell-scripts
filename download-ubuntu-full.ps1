# Checks and downloads your Ubuntu isos (full versions).
# Written by Christopher Hill 2019/07/01

$ubuntu_versions = @("18.04.1","18.10","19.04")

foreach ($ubuntu_version in $ubuntu_versions) 
{
    $ubuntu_archive = "http://releases.ubuntu.com/$ubuntu_version/MD5SUMS"
    $md5_file_name = $ubuntu_version + ".MD5SUMS"

    try 
    {
    $statuscode = (invoke-webrequest -uri $ubuntu_archive -UseBasicParsing -TimeoutSec 5 -DisableKeepAlive -method Head).statusdescription
    }
    Catch 
    {
    $statuscode = "FAIL"
    }

    if ($statuscode -eq "OK") 
    {
        Write-Host " "
	Write-Host -ForegroundColor green "URL for $ubuntu_version exists"
        Write-Host " "
        
        Invoke-WebRequest -uri $ubuntu_archive -OutFile .\$md5_file_name
        $remote_file_hashes = Get-Content -Path .\$md5_file_name

        foreach ($Data in $remote_file_hashes) 
        {
            $Data = $Data -split(' ')
            $hash = $Data[0]
            $file_name = $Data[1].Trim("*")

            $file_already_downloaded = Test-Path ".\$file_name"

            if ($file_already_downloaded -eq "True") 
            {
                Write-Host "$file_Name is already downloaded. Checking hash."

                $current_file_hash = Get-FileHash ".\$file_name" -Algorithm MD5

                if (Compare-Object -ReferenceObject $hash -DifferenceObject $current_file_hash.hash)
                {
                    Write-Host -ForegroundColor red "Hash is different. Downloading current version."
                    Invoke-WebRequest -Uri http://releases.ubuntu.com/$ubuntu_version/$file_Name -OutFile .\$file_Name
                }
                else 
                {
                    Write-Host -ForegroundColor green "Hash is correct. You already have the latest version."
                }
            }
            else 
            { 
                Write-Host -ForegroundColor yellow "$file_name downloading for the first time"
		Invoke-WebRequest -Uri http://releases.ubuntu.com/$ubuntu_version/$file_Name -OutFile .\$file_Name
            }
        }
    }
    else 
    { 
        Write-Host " "
	Write-Host -ForegroundColor red "URL for Ubuntu $ubuntu_version doesn't exist"
	Write-Host " "
    }
}
