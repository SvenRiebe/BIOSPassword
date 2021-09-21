#########################################
# Name: Powershell Script for BIOS AdminPW setting on Dell Devices
#
# Description: Powershell using Dell Command | Monitor for setting AdminPW on the machine. The script checking if any PW is exist and can setup new and change PW.
#
# Author: Sven Riebe Twitter: @SvenRiebe
# Version: 1.2.2
# Status: Test

<#
1.2.2   add check folder c:\temp if not there new-item for $Path
        log path is now a variable $Path
#>

#Variable for change
$PWKey = "Your Static Key"

#Variable not for change

# Check if BIOS Admin PW is set
$PWset = Get-CimInstance -Namespace root\dcim\sysman -ClassName dcim_BIOSPassword -Filter "AttributeName='AdminPwd'" | select -ExpandProperty isSet

# Return code form Dell Command | Monitor for setting Admin PW - Value 0 = OK rest issue is happen
$PWstatus = ""

# Computername of system
$DeviceName = Get-CimInstance -ClassName win32_computersystem | select -ExpandProperty Name

# OEM Serial number of device
$serviceTag = Get-CimInstance -ClassName win32_bios | select -ExpandProperty SerialNumber

# will be used as BIOS Admin PW build from $ServiceTag and $PWKey
$AdminPw = "$serviceTag$PWKey"

# actual system date
$Date = Get-Date

# Check if registry path is availible
$RegKeyexist = Test-Path 'HKLM:\SOFTWARE\Dell\BIOS'

# Value HKLM:\SOFTWARE\Dell\BIOS BIOS use value from registry
$PWKeyOld = ""

# Value HKLM:\SOFTWARE\Dell\BIOS ServiceTag use value from registry
$serviceTagOld = ""

# Old Admin PW generate by registry later
$AdminPwOld = ""

# Path for logging
$PATH = "C:\Temp\"

#check if c:\temp exist
if (!(Test-Path $PATH)) {New-Item -Path $PATH -ItemType Directory}

#Logging device data
Write-Output $env:COMPUTERNAME | out-file "$PATH\BIOS_Profile.txt" -Append
Write-Output "ServiceTag:         $serviceTag" | out-file "$PATH\BIOS_Profile.txt" -Append
Write-Output "Profile install at: $Date" | out-file "$PATH\BIOS_Profile.txt" -Append


#Checking RegistryKey availbility

if ($RegKeyexist -eq "True")
    {
    $PWKeyOld = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Dell\BIOS\' -Name BIOS | select -ExpandProperty BIOS
    $serviceTagOld = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Dell\BIOS\' -Name ServiceTag | select -ExpandProperty ServiceTag
    $AdminPwOld = "$serviceTagOld$PWKeyOld"
    Write-Output "RegKey exist"  | out-file "$PATH\BIOS_Profile.txt" -Append
    }
Else
    {
    New-Item -path "hklm:\software\Dell\BIOS" -Force
    New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "BIOS" -value "" -type string -Force
    New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "ServiceTag" -value "" -type string -Force
    New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Date" -value "" -type string -Force
    New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Status" -value "" -type string -Force
    Write-Output "RegKey is set"  | out-file "$PATH\BIOS_Profile.txt" -Append
    }

#Checking AdminPW is not set on the machine

If ($PWset -eq $false)
    {
    $PWstatus = Get-CimInstance -Namespace root\dcim\sysman -ClassName DCIM_BIOSService | Invoke-CimMethod -MethodName SetBIOSAttributes -Arguments @{AttributeName=@("AdminPwd");AttributeValue=@($AdminPw)} | select -ExpandProperty Setresult
    
#Setting of AdminPW was successful

    If ($PWstatus -eq 0)
        {
        New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "BIOS" -value $PWKey -type string -Force
        New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "ServiceTag" -value $serviceTag -type string -Force
        New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Date" -value $Date -type string -Force
        New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Status" -value "Ready" -type string -Force

        Write-Output "Password is set successful for first time"  | out-file "$PATH\BIOS_Profile.txt" -Append
        }

#Setting of AdminPW was unsuccessful

    else
        {
        New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Status" -value "Error" -type string -Force
        Write-Output "Error Passwort could not set" | out-file "$PATH\BIOS_Profile.txt" -Append
        }
    }


#Checking AdminPW is exsting on the machine

else
    {
    
#Compare old and new AdminPW are equal

    If ($AdminPw -eq $AdminPwOld)
        {
        Write-Output "Password no change" | out-file "$PATH\BIOS_Profile.txt" -Append

        }

#Old and new AdminPW are different make AdminPW change

    else
        {
        $PWstatus = Get-CimInstance -Namespace root\dcim\sysman -ClassName DCIM_BIOSService | Invoke-CimMethod -MethodName SetBIOSAttributes -Arguments @{AttributeName=@("AdminPwd");AttributeValue=@($AdminPw);AuthorizationToken=$AdminPwOld} | select -ExpandProperty Setresult
        
#Checking if change was successful

        If($PWstatus -eq 0)
            {
            Write-Output "Password is change successful" | out-file "$PATH\BIOS_Profile.txt" -Append
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Status" -value "Ready" -type string -Force
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "BIOS" -value $PWKey -type string -Force
            }

#Checking if change was unsuccessful. Most reason is there is a AdminPW is set by user or admin before the profile is enrolled

        else
            {
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Status" -value "Unknown" -type string -Force
            Write-Output "Unknown password on machine. This need to delete first" | out-file "$PATH\BIOS_Profile.txt" -Append
            }
        }
    }
