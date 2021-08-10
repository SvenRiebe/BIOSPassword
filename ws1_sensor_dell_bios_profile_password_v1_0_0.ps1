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
# Version 1.0.0
#
# Date: 08-06-2021

$PWKey = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Dell\BIOS\' -Name BIOS | select -ExpandProperty BIOS
$serviceTag = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Dell\BIOS\' -Name ServiceTag | select -ExpandProperty ServiceTag
$AdminPw = "$serviceTag$PWKey"


Write-Output $AdminPw
