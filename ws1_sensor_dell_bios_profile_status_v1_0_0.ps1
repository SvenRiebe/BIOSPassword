# Description
# Return Type: String
# Execution Context: System
##################################################################
#
# Name: Sensor Dell status AdminPW by BIOS Profile
#
# Author: Sven Riebe
#
# Status: test
#
# Version 1.0.0
#
# Date: 08-06-2021

$BiosProfilStatus = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Dell\BIOS\' -Name Status | select -ExpandProperty Status
Write-Output $BiosProfilStatus
