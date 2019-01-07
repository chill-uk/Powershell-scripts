# Downloads all available Ubuntu mini isos.
# Written by Christopher Hill 2019/07/01
# Make sure to update $distro and $ubuntu_versions with the latest info.

$distros = @("bionic","cosmic","disco","echo")
$ubuntu_versions = @("18.04.1","18.10","19.04","19.10")
$architectures = @("i386","amd64")

foreach ($distro in $distros) 
{
    $ubuntu_version = $ubuntu_versions[$distros.indexOf($distro)]
    foreach ($architecture in $architectures) 
    {
        $ubuntu_archive = "http://archive.ubuntu.com/ubuntu/dists/$distro/main/installer-$architecture/current/images/netboot/mini.iso"
        $ubuntu_file = $($env:USERPROFILE)+"\Downloads\Ubuntu-mini-$ubuntu_version-$architecture.iso"
        
        try 
        {
            $statuscode = (invoke-webrequest -uri $ubuntu_archive -UseBasicParsing -TimeoutSec 5 -DisableKeepAlive -method Head).statusdescription
        }
        catch 
        {
            $statuscode = "FAIL"
        }
        
        if ($statuscode -eq "OK") 
        {
            Write-Host -ForegroundColor Green "Downloading Ubuntu-mini-$ubuntu_version-$architecture.iso to $env:USERPROFILE\Downloads\"
            Invoke-WebRequest $ubuntu_archive -OutFile $ubuntu_file
            
        }
        else 
        {
            Write-Host -ForegroundColor Red "Ubuntu-mini-$ubuntu_version-$architecture.iso doesn't exist"
        }
    }
}