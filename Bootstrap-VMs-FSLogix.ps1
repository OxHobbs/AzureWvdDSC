[CmdletBinding()]
param(
    $resourceGroupName = 'wvd-lab',
    $storageAccountName = 'wvdoxhobbs',
    $ProfileShare = "\\userProvided\Share",
    $VMNames = @()
)



# comment this out and pull a list of VMs dynamically if preferred
# $VMNames = @(
#     'wvd-personal-0'
#     'wvd-personal-1'
# )

if (-not $VMNames)
{
    $VMs_dynamic = (Get-AzVM -ResourceGroupName $resourceGroupName |  Where Name -notmatch 'dc').Name
}

# =====================================================================================================================
function Install-RequiredModules
{
    [CmdletBinding()]
    param ()

    $mods = @(
        @{
            Name = 'AzureWvdDsc'
            Version = '0.1.0'
        }
    )

    function Verify-PackageProvider
    {
        if (-not (Get-PackageProvider -Name 'Nuget' -ErrorAction SilentlyContinue))
        {
            Write-Verbose "Installing nuget package provider"
            $null = Install-PackageProvider -Name 'Nuget' -Force
        }
    
    }
    Verify-PackageProvider

    foreach ($mod in $mods)
    {
        if (Get-Module -ListAvailable -Name $mod.Name -ErrorAction SilentlyContinue | ? Version -eq $mod.Version)
        {  
            Write-Verbose "Module already installed, $($mod.name) versioned $($mod.Version)"
            continue
        }

        try
        {
            Install-Module -Name $mod.Name -RequiredVersion $mod.Version -Confirm:$false -Force -ErrorAction Stop
            Write-Verbose "Installed module, $($mod.Name), version: $($mod.Version)"
        }
        catch
        {
            Write-Error $error[0].Exception.ToString()
            break
        }
    }
}

Install-RequiredModules

$tempScr = Join-Path $env:Temp "tempScr.ps1"
"Set-ExecutionPolicy Unrestricted -Force" | Out-File $tempScr

$params = @{
    ConfigurationPath = ".\AzureWvdDsc\Examples\SetupFSLogix.ps1"
    ResourceGroupName = $resourceGroupName
    StorageAccountName = $storageAccountName
}
Publish-AzVMDscConfiguration -Force @params

foreach ($vm in $VMNames)
{
    $vmParams = @{
        ResourceGroupName = $resourceGroupName
        VMName = $vm
        Version = '2.76'
        ArchiveStorageAccountName = $storageAccountName
        ArchiveBlobName = 'SetupFSLogix.ps1.zip'
        ConfigurationName = 'SetupFSLogix'
        ConfigurationArgument = @{ProfileShare = $ProfileShare}
    }

    Write-Verbose "Running command"
    Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -VMName $vm -CommandId RunPowerShellScript -ScriptPath $tempScr
    Write-Verbose "Command completed"

    if ($null -ne (Get-AzVMExtension -ResourceGroupName $resourceGroupName -VMName $vm -Name 'dscextension' -ErrorAction SilentlyContinue))
    {
        Write-Verbose "Must remove existing dsc extension to apply new one"
        Remove-AzVMExtension -ResourceGroupName $resourceGroupName -VMName $vm -Name dscextension -Force
    }

    Write-Verbose "Beginning DSC extension"
    Set-AzVMDscExtension -Force @vmParams
    Write-Verbose "$vm - complete"

}


# =======================================================================
