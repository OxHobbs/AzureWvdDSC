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
        [System.String]
        $WorkspaceId
    )

    Write-Verbose "Getting target resource"

    return @{
        WorkspaceId = [System.String]
        WorkspaceKey = [System.String]
    }
    
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $WorkspaceId,

        [Parameter()]
        [System.String]
        $WorkspaceKey
    )

    Write-Verbose "Configuring the config file for sepago monitoring"
    Set-Content -Path $ConfigFile -Value (Get-ConfigFileContent -WorkspaceId $WorkspaceId -WorkspaceKey $WorkspaceKey)

    $schTaskName = 'ITPC-LogAnalyticAgent for RDS and Citrix'
    if (-not (Get-ScheduledTask -TaskName $schTaskName -ErrorAction SilentlyContinue))
    {
        Write-Verbose 'Scheduled tasks not found, running the install command to configure the scheduled task'
        Start-Process -FilePath $ExeFile -ArgumentList "-install"
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $WorkspaceId,

        [Parameter()]
        [System.String]
        $WorkspaceKey
    )

    Write-Verbose "Testing the config file for correct values"
    $ActualContent = Get-Content -Path $ConfigFile

    $WorkspaceIdExists = $ActualContent -match $WorkspaceId
    $WorkspaceKeyExists = $ActualContent -match $WorkspaceKey
    $TaskExists = Get-ScheduledTask -TaskName 'ITPC-LogAnalyticAgent for RDS and Citrix' -ErrorAction SilentlyContinue

    if ($WorkspaceIdExists -and $WorkspaceKeyExists -and $TaskExists) { return $true } 
    return $false
}


function Get-ConfigFileContent
{
    [CmdletBinding()]
    
    param(
        $WorkspaceId,
        $WorkspaceKey
    )

    $ConfigFileContent = @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
    <startup>
    <supportedRuntime version="v4.0" sku=".NETFramework,Version=v4.5.2"/>
    </startup>
    <appSettings>
    <add key="CustomerId" value="$WorkspaceId"/>
    <add key="SharedKey" value="$WorkspaceKey"/>
    <add key="UpdateIntervalInSeconds" value="60"/>
    <add key="SimulateDataSend" value="0"/>
    <add key="UseProxy" value="0"/>
    <add key="ProxyUri" value="127.0.0.1:8088"/>
    <add key="ProxyNeedAuthentication" value="0"/>
    <add key="ProxyUserName" value="ProxyUserName"/>
    <add key="ProxyPassword" value="ProxyUserPassword"/>
    <add key="UseHashesInsteadUserNames" value="0"/>
    </appSettings>
    <system.web>
    <membership defaultProvider="ClientAuthenticationMembershipProvider">
        <providers>
        <add name="ClientAuthenticationMembershipProvider" type="System.Web.ClientServices.Providers.ClientFormsAuthenticationMembershipProvider, System.Web.Extensions, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" serviceUri=""/>
        </providers>
    </membership>
    <roleManager defaultProvider="ClientRoleProvider" enabled="true">
        <providers>
        <add name="ClientRoleProvider" type="System.Web.ClientServices.Providers.ClientRoleProvider, System.Web.Extensions, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" serviceUri="" cacheTimeout="86400"/>
        </providers>
    </roleManager>
    </system.web>
</configuration>
"@

    return $configFileContent
}


Export-ModuleMember -Function *-TargetResource

