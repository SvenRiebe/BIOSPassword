#########################################
# Name: Powershell Script for BIOS AdminPW random delete on Dell Devices
#
# Description: Powershell using Dell Command | Monitor for deleting AdminPW on the machine. The script checking if any PW is exist and can delete known PW on the machine.
#
# Author: Sven Riebe Twitter: @SvenRiebe
# Version: 1.0.1
# Status: Test

<#
1.0.1   reset RegKey Update to date to day

#>

#Variable not for change
$PWset = Get-CimInstance -Namespace root\dcim\sysman -ClassName dcim_BIOSPassword -Filter "AttributeName='AdminPwd'" | select -ExpandProperty isSet
$BIOSVersion = Get-CimInstance -ClassName win32_bios | select -ExpandProperty SMBIOSBIOSVersion
$PWstatus = ""
$DeviceName = Get-CimInstance -ClassName win32_computersystem | select -ExpandProperty Name
$serviceTag = Get-CimInstance -ClassName win32_bios | select -ExpandProperty SerialNumber
$AdminPw = "$serviceTag$PWKey"
$Date = Get-Date
$RegKeyexist = Test-Path 'HKLM:\SOFTWARE\Dell\BIOS'
$PWKeyOld = ""
$serviceTagOld = ""
$AdminPwOld = ""

#Logging device data
Write-Output $env:COMPUTERNAME | out-file "c:\temp\BIOS_Profile.txt" -Append
Write-Output "ServiceTag:         $serviceTag" | out-file "c:\temp\BIOS_Profile.txt" -Append
Write-Output "Profile install at: $Date" | out-file "c:\temp\BIOS_Profile.txt" -Append

#Generate exiting PW from Registry
$AdminPwOld = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Dell\BIOS\' -Name Hash | select -ExpandProperty Hash


#Checking AdminPW is not set on the machine

If ($PWset -eq $false)
    {
    Write-Output "No password is set on machine"  | out-file "c:\temp\BIOS_Profile.txt" -Append
    }
else
    {
    $PWstatus = Get-CimInstance -Namespace root\dcim\sysman -ClassName DCIM_BIOSService | Invoke-CimMethod -MethodName SetBIOSAttributes -Arguments @{AttributeName=@("AdminPwd");AttributeValue=@("");AuthorizationToken=$AdminPwOld} | select -ExpandProperty Setresult
        
#Checking if change was successful

        If($PWstatus -eq 0)
            {
            Write-Output "Password is delete from the machine" | out-file "c:\temp\BIOS_Profile.txt" -Append

            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "BIOS" -value $BIOSVersion -type string -Force
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "ServiceTag" -value $serviceTag -type string -Force
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Date" -value $Date -type string -Force
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Hash" -value "" -type string -Force
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Status" -value "Delete" -type string -Force
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Update" -value (Get-Date -Format yyyy-MM-dd) -type string -Force
            }

#Checking if change was unsuccessful. Most reason is there is a AdminPW is set by user or admin before the profile is enrolled

        else
            {
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Date" -value $Date -type string -Force
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Status" -value "Unknown" -type string -Force
            Write-Output "Unknown password on machine. This need to delete first" | out-file "c:\temp\BIOS_Profile.txt" -Append
            }
        }
