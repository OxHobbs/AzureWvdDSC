Configuration SetupFSLogix {

    param(
        $ProfileShare = "\\defaultTest\Share"
    )

    Import-DscResource -ModuleName AzureWvdDSC

    node "localhost" {
        FSLogixInstall InstallFSLogix {
            Ensure = 'Present'
            Version = 'latest'
        }

        ConfigureFSLogix configFSLogix {
            ProfileShare = $ProfileShare
        }
    }
}