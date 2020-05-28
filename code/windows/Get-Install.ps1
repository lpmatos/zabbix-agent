################################################################################
## DESCRIPTION: Installation Script.
## NAME: Get-Install.ps1
## AUTHOR: Lucca Pessoa da Silva Matos
## DATE: 27.05.2020
## VERSION: 1.0
## EXEMPLE:
##     PS C:\> .\Get-Install.ps1
################################################################################

# ******************************************************************************
# FUNCTIONS
# ******************************************************************************

Function Write-Header {
  Write-Host ""
  Write-Host "========================================" -ForegroundColor Green
  Write-Host "= Install Script Get Zabbix Agent" -ForegroundColor Green
  Write-Host "= "
  Write-Host "= Author: Lucca Pessoa" -ForegroundColor Yellow
  Write-Host "= Date: 27-05-2020" -ForegroundColor Yellow
  Write-Host "= Version: 1.0" -ForegroundColor Yellow
  Write-Host "========================================" -ForegroundColor Green
  Write-Host "`n"
} #End Write-Header

Function Log($MESSAGE){
  Write-Host
  Write-Host -ForegroundColor Yellow -BackgroundColor Black $MESSAGE
}#End Log

Function Get-Install {
  $SETUP_URL="https://raw.githubusercontent.com/lpmatos/zabbix-agent/master/code/windows/Get-Zabbix-Agent.ps1"
  $PATH = Join-Path C:\ (Split-Path $SETUP_URL -Leaf)
  Log("Install Script...")
  Invoke-WebRequest $SETUP_URL -OutFile $PATH
}#End Get-Install

# ******************************************************************************
# MAIN
# ******************************************************************************

Write-Header

If (!(Test-Path "C:\Get-Zabbix-Agent.ps1")){
  Get-Install
}
Else {
  Log("Get-Zabbix-Agent.ps1 alredy in the system...")
}
