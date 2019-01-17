Import-Module BitsTransfer
$uri = "https://help.ubuntu.com/community/Installation/MinimalCD"

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
    Write-Host "Downloading $file_name" 
    Start-BitsTransfer -Source $download_uri -Destination .\$file_Name
    $file_downloaded = Test-Path ".\$file_name"
    if ($file_downloaded -ne "True")
    {
        Write-Host -ForegroundColor red "Problem saving $file_Name"
    }
}

try 
{
    $statuscode = (invoke-webrequest -uri $uri -UseBasicParsing -TimeoutSec 5 -DisableKeepAlive -method Head).statusdescription
}
catch 
{
    $statuscode = "URL DOES NOT EXIST"
}

if ($statuscode -eq "OK") 
{
    $webpage = Invoke-WebRequest -uri $uri

    $P_Elements = $webpage.ParsedHtml.getElementsByTagName("P")
    $innerhtml_elements = $P_Elements | Select-Object -ExpandProperty innerhtml

    foreach ($innerhtml_element in $innerhtml_elements)
    {
        
        # Regex currently looks for http://archive* to retrieve the http link.
        # A better woption would be to look for http(s)://*(amd64|i386).
        $download_uri = $innerhtml_element | ForEach-Object{[regex]::Matches($_,"http:\/\/archive.\/?[\w\.?=%&=\-@\/$,]*") | %{$_.value}} 
        

        if ($download_uri -ne $null)
        {
            # Regex finds all entries starting with "MD5: ".
            $website_md5_hash = $innerhtml_element | ForEach-Object{[regex]::Matches($_,"MD5:\s\w+") | %{$_.value}}
            
            # Trims "MD5 " from the md5 string to give us the actual hash.
            $website_md5_hash = $website_md5_hash -replace "MD5: "

            # Retrieve architecture from URL
            $Architecture = $download_uri | ForEach-Object{[regex]::Matches($_,'\w+\d+') | %{$_.value}}
            
            # Regex finds all Ubuntu names.
            $ubuntu_name = $innerhtml_element | ForEach-Object{[regex]::Matches($_,'Ubuntu\s\d+.\d+\s(\w+\s|)"\w+\s\w+"') | %{$_.value}}
            
            # Replaces all spaces with "." and removes quotes.
            $ubuntu_name = $ubuntu_name -replace ' ','.' -replace '"',''
            
            # Ubuntu 18.04 hasn't been labeled as LTS correctly.
            if ($ubuntu_name -eq "Ubuntu.18.04.Bionic.Beaver")
            {
                $ubuntu_name = "Ubuntu.18.04.LTS.Bionic.Beaver"
            }
            $File_name = "$ubuntu_name.$architecture.mini.iso"

            try 
            {
                $statuscode = (invoke-webrequest -uri $download_uri -UseBasicParsing -TimeoutSec 5 -DisableKeepAlive -method Head).statusdescription
            }
            catch 
            {
                $statuscode = "URL DOES NOT EXIST"
            }
            if ($statuscode -eq "OK") 
            {
                Write-Host " "
                Write-Host -ForegroundColor green "URL for $ubuntu_name exists"
                Write-Host " "

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
                    if ($website_md5_hash -ne $current_file_hash)
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
                if ($website_md5_hash -ne $current_file_hash)
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
			else 
			{ 
				Write-Host " "
				Write-Host -ForegroundColor red "URL for Ubuntu $file_name doesn't exist"
				Write-Host " "
			}
        }
    }
}