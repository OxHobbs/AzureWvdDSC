# Azure WVD FSLogix Bootstrap Script

## Description

This script and DSC resource module will hopefully ease some pains when needing to install and configure FSLogix on Azure WVD session hosts.

## Script

The script to kick off the bootstrap process is in the root of the repo, `Bootstrap-VMs-FSLogix.ps1`.

This script can take four optional parameters:

* `ResourceGroupName`:The resource group in which the storage account and session hosts reside
* `StorageAccountName`: The name of the storage account where the DSC artifacts will be staged
* `ProfileShare`: The UNC Path where your FSLogix profile VHDs will be stored
* `VMNames`: Provide a list of VMs that need to be configured.  If this value is ommitted then the script will    dynamically pull a list of VMs from the provided resource group

## Examples

![](img/example1.jpg)

```
.\Bootstrap-VMs-FSLogix.ps1 -ResourceGroupName 'wvd-lab' -StorageAccountName 'wvdlabdalsjf' -ProfileShare \\myUnc\Share -VMNames 'wvd-personal-1', 'wvd-personal-2' -Verbose
```

```
.\Bootstrap-VMs-FSLogix.ps1 -ResourceGroupName 'wvd-lab' -StorageAccountName 'wvdlabdljf' -ProfileShare \\myUnc\Share -Verbose
```

## DSC Resource Module - AzureWvdDsc

The `AzureWvdDsc` module contains two DSC resources:

* `FSLogixInstall` - Installs FSLogix (x64)
* `ConfigureFSLogix` - Configures the necessary registry settings for FSLogix to use a file share for user profile VHDs
* `SepagoAgentInstall` - Installs the log analytics agent for sepago
* `SepagoAgentConfig` - Configured the sepago agent configuration file and scheduled task

## ChangeLog

v0.3.0
* Added `SepagoAgentConfig` and `SepagoAgentInstall` DSC resources