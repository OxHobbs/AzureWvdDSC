# v0.2.0
[CmdletBinding()]
param(
    $resourceGroupName = 'wvd-lab',
    $storageAccountName = 'wvdoxhobbs',
    $ProfileShare = "\\userProvided\Share",
    [Parameter(Mandatory)]
    $WorkspaceId,
    [Parameter(Mandatory)]
    $WorkspaceKey,
    $VMNames = @()
)


if (-not $VMNames)
{
    $VMNames = (Get-AzVM -ResourceGroupName $resourceGroupName |  Where Name -notmatch 'dc').Name
}

# =====================================================================================================================
function Install-RequiredModules
{
    [CmdletBinding()]
    param ()

    $mods = @(
        @{
            Name = 'AzureWvdDsc'
            Version = '0.3.0'
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
    ConfigurationPath = ".\AzureWvdDsc\Examples\SetupFSLogixSepago.ps1"
    ResourceGroupName = $resourceGroupName
    StorageAccountName = $storageAccountName
}

Write-Host "Publishing artifacts to storage account $storageAccountName" -NoNewline
try
{
    $null = Publish-AzVMDscConfiguration -Force @params
    Write-Host " .. OK" -ForegroundColor Green
}
catch
{
    Write-Host " .. failed" -ForegroundColor Red
    Write-Error $_
    break
}

foreach ($vm in $VMNames)
{
    $vmParams = @{
        ResourceGroupName = $resourceGroupName
        VMName = $vm
        Version = '2.76'
        ArchiveStorageAccountName = $storageAccountName
        ArchiveBlobName = 'SetupFSLogixSepago.ps1.zip'
        ConfigurationName = 'SetupFSLogixSepago'
        ConfigurationArgument = @{ProfileShare = $ProfileShare; WorkspaceId = $WorkspaceId; WorkspaceKey = $WorkspaceKey}
    }

    Write-Host "`nProcessing VM: $vm"

    try
    {
        Write-Verbose "Running command"
        Write-Host "-- Running pre-requisites" -NoNewline
        $null = Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -VMName $vm -CommandId RunPowerShellScript -ScriptPath $tempScr -ErrorAction Stop
        Write-Host " .. OK" -ForegroundColor Green
        Write-Verbose "Command completed"

        if ($null -ne (Get-AzVMExtension -ResourceGroupName $resourceGroupName -VMName $vm -Name 'dscextension' -ErrorAction SilentlyContinue))
        {
            Write-Host "-- Must remove existing DSC extension" -NoNewline
            Write-Verbose "Must remove existing dsc extension to apply new one"
            $null = Remove-AzVMExtension -ResourceGroupName $resourceGroupName -VMName $vm -Name dscextension -Force -ErrorAction Stop
            Write-Host " .. OK" -ForegroundColor Green
        }

        Write-Host "-- Processing DSC extension" -NoNewline
        Write-Verbose "Beginning DSC extension"
        $null = Set-AzVMDscExtension -ErrorAction Stop -Force @vmParams
        Write-Verbose "$vm - complete"        
        Write-Host " .. OK" -ForegroundColor Green
    }
    catch
    {
        Write-Host " .. Failed" -ForegroundColor Red
        Write-Error $_
        continue
    }


}
