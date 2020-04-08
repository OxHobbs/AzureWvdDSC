function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Version
    )

    return @{Version = 'latest'}
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet("Absent","Present")]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Version,

        [Parameter()]
        [System.String]
        $PayloadUri = 'https://aka.ms/fslogix_download'
    )

    $fsLogixArchiveZip = "fslogix_$(get-date -Format yyddMMhhmmss).zip"
    $fslogixArchivePath = Join-Path $env:Temp $fsLogixArchiveZip

    Get-FSLogixPayload -PayloadUri $PayloadUri -OutFilePath $fslogixArchivePath

    $fsLogixDir = Join-Path $env:Temp $fsLogixArchiveZip.replace('.zip', '')
    Expand-Archive -Path $fslogixArchivePath -DestinationPath $fsLogixDir


    $fsLogixInstaller = Join-Path $fsLogixDir "x64\Release\FSLogixAppsSetup.exe"
    $fsLogixInstallLog = Join-Path $env:Temp $fsLogixArchiveZip.Replace(".zip", ".log")

    Write-Verbose "Installing FSLogix"
    Install-FSLogix -InstallerPath $fsLogixInstaller -LogFilePath $fsLogixInstallLog
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateSet("Absent","Present")]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Version,

        [Parameter()]
        [System.String]
        $PayloadUri
    )

    Write-Verbose "Checking to see if FSLogix is installed already"
    
    $IsInstalled = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object DisplayName -match 'FSLogix'

    if ($IsInstalled) { return $true }
    return $false
}


function Get-FSLogixPayload
{
    param(
        $PayloadUri,
        $OutFilePath
    )

    Invoke-WebRequest -Uri $PayloadUri -OutFile $OutFilePath
}

function Install-FSLogix
{
    param(
        $InstallerPath,
        $LogFilePath
    )

    Write-Verbose "Install-FSLogix - installing fslogix silently"
    Start-Process -Wait -FilePath $InstallerPath -ArgumentList "/install /quiet /norestart /log $LogFilePath"

}

Export-ModuleMember -Function *-TargetResource

