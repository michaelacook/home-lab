<#
Performs a gpupdate on all computers connected to the network specified in the array
Could use a CSV file or specify all computers in an OU for production purposes
This doesn't work on primary DC when trying to use a remote call, fails with an access denied. Something I don't fully understand
here but probably has to do with trying to run remote commands on the primary DC
#>

Write-Host "Updating Group policy on local DC..."
gpupdate /force

$Computers = @(
"DC2",
"FS1",
"HV1",
"HV2",
"BAK1",
"STG1"
)

Foreach ($computer in $Computers) {
  Write-Host "Updating Group Policy on $computer..."
  Invoke-Command -ComputerName $computer -ScriptBlock { gpupdate /force }
}

Write-Host "Done. View output for any potential errors."
Read-Host -Prompt "Press Enter to exit..."