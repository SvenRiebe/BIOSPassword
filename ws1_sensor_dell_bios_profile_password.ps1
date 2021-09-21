# Description
# Return Type: String
# Execution Context: System
##################################################################
#
# Name: Sensor Dell actual AdminPW on the Device by BIOS Profile
#
# Author: Sven Riebe
#
# Status: test
#
# Version 1.0.1
#
# Date: 09-14-2021


<#
1.0.1   cover Static and Random PW

#>


#Variables
$HashKeyCheck = ""
$PWKey = ""
$serviceTag = ""
$AdminPw = ""

# this function is from https://stackoverflow.com/questions/5648931/test-if-registry-value-exists
function Test-RegistryValue {

param (

 [parameter(Mandatory=$true)]
 [ValidateNotNullOrEmpty()]$Path,

[parameter(Mandatory=$true)]
 [ValidateNotNullOrEmpty()]$Value
)

try {

Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop | Out-Null
 return $true
 }

catch {

return $false

}

}

$HashKeyCheck = Test-RegistryValue -Path HKLM:\SOFTWARE\Dell\BIOS -Value Hash

If ($HashKeyCheck -match "false")
    {
    $PWKey = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Dell\BIOS\' -Name BIOS | select -ExpandProperty BIOS
    $serviceTag = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Dell\BIOS\' -Name ServiceTag | select -ExpandProperty ServiceTag
    $AdminPw = "$serviceTag$PWKey"
    }
else
    {
    $AdminPw = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Dell\BIOS\' -Name Hash | select -ExpandProperty Hash
    }


Write-Output $AdminPw
