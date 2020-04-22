Configuration SetupFSLogixSepago {

    param(
        $ProfileShare = "\\defaultTest\Share",
        $WorkspaceId,
        $WorkspaceKey
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

        SepagoAgentInstall InstallSepago {
            Ensure = 'Present'
        }

        SepagoAgentConfig ConfigSepago {
            WorkspaceKey = $WorkspaceKey
            WorkspaceId = $WorkspaceId
        }
    }
}