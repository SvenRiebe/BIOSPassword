# Description
# Return Type: String
# Execution Context: System
##################################################################
#
# Name: Sensor Dell status change date AdminPW by BIOS Profile
#
# Author: Sven Riebe
#
# Status: test
#
# Version 1.0.0
#
# Date: 08-06-2021

$BiosProfilDate = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Dell\BIOS\' -Name Date | select -ExpandProperty Date
Write-Output $BiosProfilDate
