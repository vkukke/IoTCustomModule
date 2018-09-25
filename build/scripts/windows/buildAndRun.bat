Powershell.exe -executionpolicy remotesigned -File  Install-Prereqs.ps1
Powershell.exe -executionpolicy remotesigned -File  Build-Branch.ps1
Powershell.exe -executionpolicy remotesigned -File  Run-Tests.ps1