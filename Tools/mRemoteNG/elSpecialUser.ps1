Clear-Host
Import-Module ActiveDirectory
$domain = (Get-ADDomain).DNSRoot
Write-Host "Domäne: $domain"
$user = Read-Host "Username (T0-Admin)"
$aduser = "$domain\$user"
$password = Read-Host "Password für $user eingeben" -AsSecureString
$mRemoteNG = "C:\SOURCEN\RemoteNG\mRemoteNG.exe"
$credentials = New-Object System.Management.Automation.PSCredential($aduser, $password)
Start-Process -FilePath $mRemoteNG -Credential $credentials -WorkingDirectory(Split-Path $mRemoteNG) -NoNewWindow
