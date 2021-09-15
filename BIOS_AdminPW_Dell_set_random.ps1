#########################################
# Name: Powershell Script for BIOS AdminPW setting on Dell Devices
#
# Description: Powershell using Dell Command | Monitor for setting AdminPW with random PW on the machine. The script checking if any PW is exist and can setup new and change PW.
#
# Author: Sven Riebe Twitter: @SvenRiebe
# Version: 1.0.3
# Status: Test

<#
1.0.1   add check folder c:\temp if not there new-item for $Path
        log path is now a variable $Path
1.0.2   move request for AdminPwold from line 104 to 168
        additional setting RegKey "Hash" at unsuccessfull to be secure that Hash is not empty if AdminPWOld asking for
1.0.3   checking if password older than 180 days before a new PW will deployed
        New Function Test-RegistryValue
        Adjust special char to use only Char are same keyboard position on DE / US Keyboard to make it easier for manuel typing later
#>


#Variable you can change

## Days a password need exist before it will be change
$PWTime = "180"

## Logging Path
$PATH = "C:\Temp\"

## length of your BIOS Password max 32 char. The BIOS supporting only a max 0f 32 Characters. Recommand to set 12.
$PWLength = 12



function New-Password {
  
    [CmdletBinding()]
    [OutputType([String])]
    param (
        # The length of the password which should be created.
        [Parameter(ValueFromPipeline)]        
        [ValidateRange(8, 255)]
        [Int32]$Length = 10,

        # The character sets the password may contain. A password will contain at least one of each of the characters.
        [String[]]$CharacterSet = ('abcdefghijklmnopqrstuvwxyz',
                                   'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                                   '0123456789',
                                   '!$%'),
<#
For Dell 7th Generation and newer client products, you should use the following guidelines:
BIOS passwords can include:

The following special characters (ASCII 0x21 – 0x2f):
! " # $ % & ' ( ) * + , - . /

A number (ASCII 0x30 – 0x39):
0 1 2 3 4 5 6 7 8 9

One of the following special characters (ASCII 0x3a – 0x40):
: ; < = > ? @

A capital English letter (ASCII 0x41 – 0x5a):
A - Z

One of the following special characters (ASCII 0x5b – 0x60):
[ \ ] ^ _ `

A lower case English letter (ASCII 0x61 – 0x7a):
a - z

One of the following special characters (ASCII 0x7b – 0x7e):
{ | } ~
#>
        # The number of characters to select from each character set.
        [Int32[]]$CharacterSetCount = (@(1) * $CharacterSet.Count)
    )

    begin {
        $bytes = [Byte[]]::new(4)
        $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        $rng.GetBytes($bytes)

        $seed = [System.BitConverter]::ToInt32($bytes, 0)
        $rnd = [Random]::new($seed)

        if ($CharacterSet.Count -ne $CharacterSetCount.Count) {
            throw "The number of items in -CharacterSet needs to match the number of items in -CharacterSetCount"
        }

        $allCharacterSets = [String]::Concat($CharacterSet)
    }

    process {
        try {
            $requiredCharLength = 0
            foreach ($i in $CharacterSetCount) {
                $requiredCharLength += $i
            }

            if ($requiredCharLength -gt $Length) {
                throw "The sum of characters specified by CharacterSetCount is higher than the desired password length"
            }

            $password = [Char[]]::new($Length)
            $index = 0
        
            for ($i = 0; $i -lt $CharacterSet.Count; $i++) {
                for ($j = 0; $j -lt $CharacterSetCount[$i]; $j++) {
                    $password[$index++] = $CharacterSet[$i][$rnd.Next($CharacterSet[$i].Length)]
                }
            }

            for ($i = $index; $i -lt $Length; $i++) {
                $password[$index++] = $allCharacterSets[$rnd.Next($allCharacterSets.Length)]
            }

            # Fisher-Yates shuffle
            for ($i = $Length; $i -gt 0; $i--) {
                $n = $i - 1
                $m = $rnd.Next($i)
                $j = $password[$m]
                $password[$m] = $password[$n]
                $password[$n] = $j
            }

            [String]::new($password)
        } catch {
            Write-Error -ErrorRecord $_
        }
    }
}

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



#Variable not for change
$PWset = Get-CimInstance -Namespace root\dcim\sysman -ClassName dcim_BIOSPassword -Filter "AttributeName='AdminPwd'" | select -ExpandProperty isSet
$PWstatus = ""
$DeviceName = Get-CimInstance -ClassName win32_computersystem | select -ExpandProperty Name
$serviceTag = Get-CimInstance -ClassName win32_bios | select -ExpandProperty SerialNumber
$AdminPw = ""
$Date = Get-Date -Format yyyy-MM-dd
$DateExpire = ""
$RegKeyexist = Test-Path 'HKLM:\SOFTWARE\Dell\BIOS'
$PWKeyOld = ""
$serviceTagOld = ""
$AdminPwOld = ""
$DateTransfer = (Get-Date).AddDays($PWTime)
$BIOSVersion = Get-CimInstance -ClassName win32_bios | select -ExpandProperty SMBIOSBIOSVersion


#check if c:\temp exist
if (!(Test-Path $PATH)) {New-Item -Path $PATH -ItemType Directory}

#Logging device data
Write-Output $env:COMPUTERNAME | out-file "$Path\BIOS_Profile.txt" -Append
Write-Output "ServiceTag:         $serviceTag" | out-file "$Path\BIOS_Profile.txt" -Append
Write-Output "Profile install at: $Date" | out-file "$Path\BIOS_Profile.txt" -Append


#Checking RegistryKey availbility

if ($RegKeyexist -eq "True")
    {
    Write-Output "RegKey exist"  | out-file "$Path\BIOS_Profile.txt" -Append

    $RegKeyCheckUpdate = Test-RegistryValue -Path HKLM:\SOFTWARE\Dell\BIOS -Value Update

    
    If ($RegKeyCheckUpdate -eq $false)
        {
        New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Update" -value $Date -type string -Force
        Write-Output "RegKey Update generated" | out-file "$Path\BIOS_Profile.txt" -Append
        }
    else
        {
        Write-Output "Field Update exist" | out-file "$Path\BIOS_Profile.txt" -Append
        }

        
    }
Else
    {
    New-Item -path "hklm:\software\Dell\BIOS" -Force
    New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "BIOS" -value $BIOSVersion -type string -Force
    New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "ServiceTag" -value "" -type string -Force
    New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Date" -value "" -type string -Force
    New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Status" -value "" -type string -Force
    New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Hash" -value "" -type string -Force
    New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Update" -value $Date -type string -Force
    
    Write-Output "RegKey is set"  | out-file "$Path\BIOS_Profile.txt" -Append
    }

#check if BIOS password older that 180 days

$DateExpire = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Dell\BIOS\' -Name Update | select -ExpandProperty Update


if ((Get-Date -Format yyyyMMdd) -ge (Get-Date $DateExpire -Format yyyyMMdd))
    {

    $AdminPw = New-Password -Length $PWLength 
    
    # only for security need to delete if script is working stable
    Write-Output "Password: $AdminPW" | out-file "$Path\BIOS_Profile.txt" -Append

    #Checking AdminPW is not set on the machine    
    If ($PWset -eq $false)
        {
        $PWstatus = Get-CimInstance -Namespace root\dcim\sysman -ClassName DCIM_BIOSService | Invoke-CimMethod -MethodName SetBIOSAttributes -Arguments @{AttributeName=@("AdminPwd");AttributeValue=@($AdminPw)} | select -ExpandProperty Setresult
    
    #Setting of AdminPW was successful

        If ($PWstatus -eq 0)
            {
            
            #$DateTransfer = (Get-Date).AddDays($PWTime)
                         
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "BIOS" -value $BIOSVersion -type string -Force
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "ServiceTag" -value $serviceTag -type string -Force
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Date" -value $Date -type string -Force
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Status" -value "Ready" -type string -Force
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Hash" -value $AdminPw -type string -Force
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Update" -value (Get-Date $DateTransfer -Format yyyy-MM-dd) -type string -Force

            Write-Output "Password is set successful for first time"  | out-file "$Path\BIOS_Profile.txt" -Append
            }

    #Setting of AdminPW was unsuccessful

        else
            {
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Status" -value "Error" -type string -Force
            New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Hash" -value $AdminPw -type string -Force
            Write-Output "Error Passwort could not set" | out-file "$Path\BIOS_Profile.txt" -Append
            }
        }


    #Checking AdminPW is exsting on the machine

    else
        {
    
    #Compare old and new AdminPW are equal
    $AdminPwOld = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Dell\BIOS\' -Name Hash | select -ExpandProperty Hash
    
        If ($AdminPw -eq $AdminPwOld)
            {
            Write-Output "Password no change" | out-file "$Path\BIOS_Profile.txt" -Append
    
            }

    #Old and new AdminPW are different make AdminPW change
        else
            {
            $PWstatus = Get-CimInstance -Namespace root\dcim\sysman -ClassName DCIM_BIOSService | Invoke-CimMethod -MethodName SetBIOSAttributes -Arguments @{AttributeName=@("AdminPwd");AttributeValue=@($AdminPw);AuthorizationToken=$AdminPwOld} | select -ExpandProperty Setresult
        
    #Checking if change was successful

            If($PWstatus -eq 0)
                {
                New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Status" -value "Ready" -type string -Force
                New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "BIOS" -value $BIOSVersion -type string -Force
                New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Hash" -value $AdminPw -type string -Force
                New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Date" -value $Date -type string -Force
                New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Update" -value (Get-Date $DateTransfer -Format yyyy-MM-dd) -type string -Force

                Write-Output "Password is change successful" | out-file "$Path\BIOS_Profile.txt" -Append
                }

    #Checking if change was unsuccessful. Most reason is there is a AdminPW is set by user or admin before the profile is enrolled

            else
                {
                New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Status" -value "Unknown" -type string -Force
                New-Itemproperty -path "hklm:\software\Dell\BIOS" -name "Date" -value $Date -type string -Force
                
                Write-Output "Unknown password on machine. This need to delete first" | out-file "$Path\BIOS_Profile.txt" -Append
                }
            }
     }
    }
else
    {
    Write-Output "Password is not older than 180 Days. No Password Change" | out-file "$Path\BIOS_Profile.txt" -Append
    }
