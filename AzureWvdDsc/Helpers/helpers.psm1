function Test-FSLogixInstalled
{
    $IsInstalled = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object DisplayName -match 'FSLogix'

    if ($IsInstalled) { return $true }
    return $false
}