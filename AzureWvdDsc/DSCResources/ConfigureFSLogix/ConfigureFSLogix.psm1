function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ProfileShare
    )

    return @{ProfileShare = $ProfileShare}
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ProfileShare,

        [Parameter()]
        [System.Boolean]
        $Enabled = $true
    )

    Write-Verbose "Calling for creation of profile key"
    New-FSLogixProfileKey

    New-FSLogixEnabledProperty -Enabled $Enabled
    
    New-FSLogixVHDLocationsProperty -SharePath $ProfileShare

}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ProfileShare,

        [Parameter()]
        [System.Boolean]
        $Enabled = $true
    )

    $DwordValue = if ($Enabled) { "1" } else { "0" }
    if (-not (Test-Path 'HKLM:\SOFTWARE\FSLogix\Profiles')) { return $false }
    if ((Get-EnabledProperty).Enabled -ne $DwordValue) { return $false }
    if ((Get-VHDLocationsProperty).VHDLocations -ne $ProfileShare) { return $false }

    return $true
}

function New-FSLogixProfileKey
{
    [CmdletBinding()]
    param()

    if (-not (Test-Path 'HKLM:\SOFTWARE\FSLogix\Profiles'))
    {
        Write-Verbose "Creating the Profiles key in the FSLogix registry tree"
        $null = New-Item -Path 'HKLM:\SOFTWARE\FSLogix' -Name 'Profiles'
    }
    else
    {
        Write-Verbose "FSLogix profile key already exists"
    }
}

function New-FSLogixEnabledProperty
{
    [CmdletBinding()]
    param(
        $Enabled
    )

    $DwordValue = if ($Enabled) { '1' } else { '0' }

    $currentValue = Get-EnabledProperty
    if (-not $currentValue)
    {
        Write-Verbose "Creating new property Enabled with value $DwordValue"
        $null = New-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'Enabled' -PropertyType DWord -Value $DwordValue
        return
    }
    else
    {
        if ($currentValue.Enabled -eq $DwordValue)
        {
            Write-Verbose "Enabled property is already set to $DwordValue"
            return
        }

        Write-Verbose "Updating Enabled property value to $DwordValue"
        $null = Set-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'Enabled' -Value $DwordValue
        return
    }
}

function New-FSLogixVHDLocationsProperty
{
    [CmdletBinding()]
    param(
        $SharePath
    )

    $CurrentValue = Get-VHDLocationsProperty

    if ($CurrentValue)
    {
        Write-Verbose "VHDLocations property already exists, will update if needed"

        if ($CurrentValue.VHDLocations -ne $SharePath)
        {
            Write-Verbose "Updating VHDLocations with path $SharePath"
            $null = Set-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'VHDLocations' -Value $SharePath 
            return
        }
        Write-Verbose "VHDLocations is already set to $SharePath"
        return
    }
    else
    {
        Write-Verbose "Creating VHDProfiles property with value $SharePath"
        $null = New-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'VHDLocations' -Value $SharePath -PropertyType MultiString
    }
    return
}

function Get-EnabledProperty
{
    return (Get-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'Enabled' -ErrorAction SilentlyContinue)
}

function Get-VHDLocationsProperty
{
    return (Get-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'VHDLocations' -ErrorAction SilentlyContinue)
}


Export-ModuleMember -Function *-TargetResource

