#Requires -Version 5.1
#Requires -Modules Hyper-V

<#
.SYNOPSIS
    Weist ISO-Dateien den DVD-Laufwerken von virtuellen Maschinen zu.

.DESCRIPTION
    Dieses Skript verwaltet die Zuweisung von ISO-Dateien zu den DVD-Laufwerken von
    virtuellen Maschinen basierend auf einer vordefinierten Konfiguration.

.PARAMETER VMFilter
    Filter für die zu bearbeitenden virtuellen Maschinen. Standard ist "VM PROD*".

.PARAMETER ISOBasePath
    Basispfad für die ISO-Dateien. Standard ist "D:\Service-ISOs".

.EXAMPLE
    .\Set-VMISOMapping.ps1 -VMFilter "VM TEST*" -ISOBasePath "E:\Test-ISOs"

.NOTES
    Autor: ErikSlevin
    Datum: 04.05.2025
    Version: 0.1
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$VMFilter = "VM PROD*",
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$ISOBasePath = "D:\Service-ISOs"
)

# Starte Protokollierung
# $LogFile = Join-Path -Path $PSScriptRoot -ChildPath "ISO-Mapping_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )
    
    $TimeStamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "[$TimeStamp] [$Level] $Message"
    
    # In Datei und Konsole schreiben
    # Add-Content -Path $LogFile -Value $LogMessage
    
    # Farbige Konsolenausgabe
    switch ($Level) {
        'INFO'    { Write-Host $LogMessage -ForegroundColor Cyan }
        'WARNING' { Write-Host $LogMessage -ForegroundColor Yellow }
        'ERROR'   { Write-Host $LogMessage -ForegroundColor Red }
        'SUCCESS' { Write-Host $LogMessage -ForegroundColor Green }
    }
}

Write-Log "Skript gestartet - ISO-Zuweisungen werden vorbereitet" -Level INFO

# ISO-Pfade definieren
$isoPaths = @{
    "AiO.iso"                     = Join-Path -Path $ISOBasePath -ChildPath "AiO.iso"
    "SQL_SRV_2017_RTM.iso"        = Join-Path -Path $ISOBasePath -ChildPath "SQL_SRV_2017_RTM.iso"
    "LANcrypt.iso"                = Join-Path -Path $ISOBasePath -ChildPath "LANcrypt.iso"
    "Domino.iso"                  = Join-Path -Path $ISOBasePath -ChildPath "Domino.iso"
    "itWESS.iso"                  = Join-Path -Path $ISOBasePath -ChildPath "itWESS.iso"
    "Windows10_22H2.iso"          = Join-Path -Path $ISOBasePath -ChildPath "Windows10_22H2.iso"
    "SEP_143_RU7.iso"             = Join-Path -Path $ISOBasePath -ChildPath "SEP_143_RU7.iso"
    "SEP_DefinitionUpdates.iso"   = Join-Path -Path $ISOBasePath -ChildPath "SEP_DefinitionUpdates.iso"
}

# Überprüfe, ob die ISO-Dateien existieren
foreach ($isoKey in $isoPaths.Keys) {
    $isoPath = $isoPaths[$isoKey]
    if (-not (Test-Path -Path $isoPath)) {
        Write-Log "ISO-Datei nicht gefunden: $isoPath" -Level WARNING
    }
}

# VM-ISO-Zuordnungen
$vmIsoMapping = @{
    "VM PROD DC 01"           = @("AiO.iso")
    "VM PROD DC 02"           = @("AiO.iso")
    "VM PROD FS 01"           = @("AiO.iso")
    "VM PROD FS 02"           = @("AiO.iso")
    "VM PROD WSUS 01"         = @("AiO.iso")
    "VM PROD LANCRYPT 01"     = @("AiO.iso", "SQL_SRV_2017_RTM.iso", "LANcrypt.iso")
    "VM PROD MAIL 01"         = @("AiO.iso")
    "VM PROD MAIL 02"         = @("AiO.iso", "Domino.iso")
    "VM PROD ITWATCH 01"      = @("AiO.iso", "itWESS.iso", "SQL_SRV_2017_RTM.iso")
    "VM PROD PRINT 01"          = @("AiO.iso")
    "VM PROD DHCP 01"         = @("AiO.iso")
    "VM PROD WDS 01"          = @("AiO.iso", "Windows10_22H2.iso")
    "VM PROD WEB 01"          = @("AiO.iso")
    "VM PROD AV 01"           = @("AiO.iso", "SEP_143_RU7.iso", "SEP_DefinitionUpdates.iso")
}

function Set-VDDrives {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$VMName,
        
        [Parameter(Mandatory = $true)]
        [array]$ISOFiles,
        
        [Parameter(Mandatory = $true)]
        [array]$DVDDrives
    )
    
    for ($i = 0; $i -lt $ISOFiles.Count; $i++) {
        if ($i -lt $DVDDrives.Count) {
            $dvdDrive = $DVDDrives[$i]
            $isoPath = $isoPaths[$ISOFiles[$i]]
            
            if (-not $isoPath) {
                Write-Log "ISO-Datei '$($ISOFiles[$i])' nicht in der Konfiguration gefunden für VM $VMName" -Level ERROR
                continue
            }
            
            if (-not (Test-Path -Path $isoPath)) {
                Write-Log "ISO-Datei nicht gefunden: $isoPath für VM $VMName" -Level ERROR
                continue
            }
            
            try {
                Set-VMDVDDrive -VMName $VMName `
                               -ControllerNumber $dvdDrive.ControllerNumber `
                               -ControllerLocation $dvdDrive.ControllerLocation `
                               -Path $isoPath
                
                Write-Log "ISO '$($ISOFiles[$i])' erfolgreich in $VMName eingebunden" -Level SUCCESS
            }
            catch {
                Write-Log "Fehler beim Einbinden von '$($ISOFiles[$i])' in $VMName: $_" -Level ERROR
            }
        }
        else {
            Write-Log "Nicht genug DVD-Laufwerke für VM $VMName. Benötigt: $($ISOFiles.Count), Vorhanden: $($DVDDrives.Count)" -Level WARNING
            break
        }
    }
}

# Hauptlogik
Write-Log "Suche nach virtuellen Maschinen mit Filter: $VMFilter" -Level INFO

try {
    $vms = Get-VM | Where-Object { $_.Name -like $VMFilter }
    
    if (-not $vms) {
        Write-Log "Keine VMs gefunden, die dem Filter '$VMFilter' entsprechen" -Level WARNING
        exit
    }
    
    Write-Log "Gefundene VMs: $($vms.Count)" -Level INFO
    
    foreach ($vm in $vms) {
        Write-Log "Verarbeite VM: $($vm.Name)" -Level INFO
        
        # Prüfe ob VM-Name in der Konfiguration vorhanden ist
        if (-not $vmIsoMapping.ContainsKey($vm.Name)) {
            Write-Log "Keine ISO-Konfiguration für VM $($vm.Name) gefunden" -Level WARNING
            continue
        }
        
        $dvdDrives = Get-VMDVDDrive -VMName $vm.Name
        $isoNames = $vmIsoMapping[$vm.Name]
        
        if (-not $dvdDrives) {
            Write-Log "Keine DVD-Laufwerke in VM $($vm.Name) gefunden" -Level ERROR
            continue
        }
        
        if (-not $isoNames) {
            Write-Log "Keine ISOs für VM $($vm.Name) definiert" -Level WARNING
            continue
        }
        
        # ISO-Dateien zuweisen
        Set-VDDrives -VMName $vm.Name -ISOFiles $isoNames -DVDDrives $dvdDrives
        
        # Zusammenfassung ausgeben
        Write-Log "VM $($vm.Name): $($isoNames -join ", ") erfolgreich konfiguriert" -Level SUCCESS
    }
}
catch {
    Write-Log "Unerwarteter Fehler: $_" -Level ERROR
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level ERROR
}
finally {
    Write-Log "Skript beendet" -Level INFO
}
