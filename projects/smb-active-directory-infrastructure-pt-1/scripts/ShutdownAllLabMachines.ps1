<#
This script should never be used in production!
The intention is to easily shutdown all my lab machines without manually remoting 
or accessing the desktop for each device separately, which I got tired of doing

This script doesn't work well. BAK1 and STG1 don't shut off. Troubleshoot this (RPC doesn't appear to be enabled/allowed through firewall)
Update: this has been fixed with Group Policy that enables all inbound WMI rules^
#>

$computers = @(
    "DC2",
    "FS1",
    "BAK1",
    "STG1",
    "HV1",
    "HV2",
    "CLOUDSYNC1"
)

Stop-Computer -ComputerName $computers -Force