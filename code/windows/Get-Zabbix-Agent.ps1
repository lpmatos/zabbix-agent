################################################################################
## DESCRIPTION: Script to Install Zabbix Agent in a Windows Machine.
## NAME: Get-Zabbix-Agent.ps1
## AUTHOR: Lucca Pessoa da Silva Matos
## DATE: 27.05.2020
## VERSION: 1.0
## EXEMPLE:
##     PS C:\> .\Get-Zabbis-Agent.ps1
################################################################################

[CmdletBinding()]
Param(
  [Parameter(HelpMessage="Install Zabbix Agent - Setup CLI commands.")]
  [ValidateSet("install", "help")]
  [string]$Setup="install"
)

# ******************************************************************************
# GLOBAL
# ******************************************************************************

$Version        = "5.0.0"
$Title          = "Zabbix"
$ServiceName    = "Zabbix Agent"
$URL            = "https://www.zabbix.com/downloads/$Version/zabbix_agent-$Version-windows-i386-openssl.zip"
$URL64          = "https://www.zabbix.com/downloads/$Version/zabbix_agent-$Version-windows-amd64-openssl.zip"

$InstallDir     = Join-Path C:\ $Title
$BinDir         = Join-Path $InstallDir "bin"
$ConfigDir      = Join-Path $InstallDir "conf/zabbix_agentd.conf"

$TempDir        = Join-Path $env:TEMP "zabbix"
$TempBinDir         = Join-Path $TempDir "bin"
$TempConfigDir         = Join-Path $TempDir "conf"

$Is64bit = (Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture) -match "64"
$Service = Get-WmiObject -Class Win32_Service -Filter "Name=`'$ServiceName`'"

$ZabbixHost="woopi-bastion"
$ZabbixServer="172.168.32.3"

# ******************************************************************************
# FUNCTIONS
# ******************************************************************************

Function Write-Header {
  Write-Host ""
  Write-Host "========================================" -ForegroundColor Green
  Write-Host "= Install Zabbix Agent" -ForegroundColor Green
  Write-Host "= Windows Setup to Zabbix Agent" -ForegroundColor Green
  Write-Host "= "
  Write-Host "= Author: Lucca Pessoa" -ForegroundColor Yellow
  Write-Host "= Date: 27-05-2020" -ForegroundColor Yellow
  Write-Host "= Version: 1.0" -ForegroundColor Yellow
  Write-Host "========================================" -ForegroundColor Green
} #End Write-Header

Function Log($MESSAGE){
  Write-Host
  Write-Host -ForegroundColor Yellow -BackgroundColor Black $MESSAGE
}#End Log

Function Get-Admin-Execution {
  # Test-Admin is not available yet, so use...
  If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell -ArgumentList "-noprofile -NoExit -file `"$PSCommandPath`"" -Verb RunAs
    Exit
  }
  # From a Administrator PowerShell, if Get-ExecutionPolicy returns Restricted, run:
  If ((Get-ExecutionPolicy) -eq "Restricted") {
    Set-ExecutionPolicy Unrestricted -Force
  }
} #End Get-Admin-Execution

Function Test-Zabbix-Agent-Information {
  # Checking if variables Zabbix Host and Zabbix Server exist.
  If ($ZabbixHost -and $ZabbixServer){
    Log("Everything is Okay!")
  } Else {
    Write-Error "Error - Zabbix Agent Information not been defined. Bye Bye :)"
    Exit
  }
} #Test-Zabbix-Agent-Information

Function Test-Directory-Exist {
  # Test if Install Directory exist in Windows System.
  If (!(Test-Path $InstallDir)) {
    Log("Make Install Directory...")
    New-Item $InstallDir -type directory
  } Else {
    Log("Install Directory Alredy Exist in Windows System...")
  }
  # Test if Temp Directory exist in Windows System.
  If (!(Test-Path $TempDir)) {
    Log("Make Temp Directory...")
    New-Item $TempDir -type directory
  } Else {
    Log("Temp Directory Alredy Exist in Windows System...")
    Remove-Item -Recurse -Force $TempDir
  }
} #Test-Directory-Exist

Function Move-Temp-Files {
  # Just Move Temp Files to Install Directory.
  Log("Moving Temp Bin/Config Directory to Install Directory...")
  If (!(Test-Path $BinDir)) {
    Move-Item $TempBinDir $InstallDir -Force
  } Else {
    Log("Zabbix Agent Bin Directory Alredy Exist")
  }
  If (!(Test-Path $ConfigDir)) {
    Move-Item $TempConfigDir $InstallDir -Force
  }Else {
    Log("Zabbix Agent Config Directory Alredy Exist")
  }
} #Move-Temp-Files

Function Test-Install-Directory-Files {
  # Checking if Install Directory is Empty.
  If((Get-ChildItem $InstallDir -force | Select-Object -First 1 | Measure-Object).Count -eq 0){
    Log("Install Directory Is Empty... Move Temp Files...")
    Move-Temp-Files
  }
} #Test-Install-Directory-Files

Function Get-Install-Zabbix-Agent-ZipFile($ZipFile, $URL) {
  # Call Invoke WebRequest and Get Zabbix Agent ZipFile, Extract Zip and Move.
  If (!(Test-Path $ZipFile)){
    Log("Install Zabbix Agent ZipFile...")
    Invoke-WebRequest $URL -OutFile $ZipFile
    Log("Extract content from ZipFile...")
    Expand-Archive $ZipFile -DestinationPath $TempDir
    Move-Temp-Files
  } Else {
    Log("Zabbix Zip File Alredy Exist...")
    Test-Install-Directory-Files
  }
} #Get-Install-Zabbix-Agent-ZipFile

Function Get-Zabbix-Agent-ZipFile {
  # Check if Windows is 64 and get Zabbix Agent ZipFile
  If ($Is64bit) {
    $ZipFile = Join-Path $TempDir "zabbix_agent-$Version-windows-amd64-openssl.zip"
    Get-Install-Zabbix-Agent-ZipFile $ZipFile $URL64
  } Else {
    $ZipFile = Join-Path $TempDir "zabbix_agent-$Version-windows-i386-openssl.zip"
    Get-Install-Zabbix-Agent-ZipFile $ZipFile $URL
  }
} #Get-Zabbix-Agent-ZipFile

Function Get-Install {
  # Testing somethings, Get Zabbix Agent Installation and Remove Caches.
  try {
    If ($Service) {
      $Service.StopService()
    }
    Test-Directory-Exist
    Get-Zabbix-Agent-ZipFile
    Remove-Item -Recurse -Force $TempDir
    $ZabbixAgentExe = Join-Path $BinDir "zabbix_agentd.exe"
    $Arguments = "-i -c $ConfigDir"
    If (!($service)) {
      Log("Starting Process...")
      Start-Process $ZabbixAgentExe $Arguments
    }
    Log("Starting Service...")
    Start-Service -Name $Title
  } catch {
    Write-Error "Error when we install Zabbix Agent... Bye Bye :)"
    Exit
  }
} #Get-Install

Function Get-Sed-Zabbix-Agent-Config {
  Test-Zabbix-Agent-Information
  ((Get-Content -path $ConfigDir -Raw) -replace "Hostname=Windows host","Hostname=$ZabbixHost") | Set-Content -Path $ConfigDir
  ((Get-Content -path $ConfigDir -Raw) -replace "Server=127.0.0.1","Server=$ZabbixServer") | Set-Content -Path $ConfigDir
  ((Get-Content -path $ConfigDir -Raw) -replace "ServerActive=127.0.0.1","ServerActive=$ZabbixServer") | Set-Content -Path $ConfigDir
} #Get-Sed-Information-Zabbix-Agent-Config

# ******************************************************************************
# MAIN
# ******************************************************************************

Write-Header

Get-Admin-Execution

switch ($Setup) {
  install {
    Get-Install
    Get-Sed-Zabbix-Agent-Config
  }

  help {
		Log("usage: install|help")
	}

  default {
		Log("usage: install|help")
  }
}
