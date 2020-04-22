$InstallPath = Join-Path $env:ProgramW6432 'ITPC-LogAnalyticsAgent'
$ConfigFile = Join-path $InstallPath 'ITPC-LogAnalyticsAgent.exe.config'
$ExeFile = Join-Path $InstallPath 'ITPC-LogAnalyticsAgent.exe'


function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    Write-Verbose "Getting target resource"
    return @{Ensure = $Ensure}
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    try
    {
        $tempInstallerPath = Join-Path $env:Temp 'ITPC-LogAnalyticsAgent.zip'
        $downloadUri = 'http://loganalytics.sepago.com/downloads/ITPC-LogAnalyticsAgent.zip'
        Invoke-WebRequest -Uri $downloadUri -OutFile $tempInstallerPath
        Expand-Archive -Path $tempInstallerPath $InstallPath
        Get-ChildItem -Path (Join-Path $InstallPath 'Azure Monitor for WVD') | Move-Item -Destination $InstallPath
        Remove-Item (Join-Path $InstallPath 'Azure Monitor for WVD')
    }
    catch
    {
        Write-Verbose "There was an error thrown when attempting to install sepago agent"
        Write-Error $_
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    return (Test-Path $ExeFile)
}


Export-ModuleMember -Function *-TargetResource

