#Requires -Version 5.1
#Requires -Modules Hyper-V
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Konfiguriert IPsec-Offload für Netzwerkadapter von virtuellen Maschinen.

.DESCRIPTION
    Dieses Skript aktiviert die IPsec-Offload-Funktion für alle Netzwerkadapter
    der angegebenen virtuellen Maschinen durch Setzen des Parameters
    IPsecOffloadMaximumSecurityAssociation.

.PARAMETER VMFilter
    Filter für die zu bearbeitenden virtuellen Maschinen. Standard ist "VM PROD*".

.PARAMETER MaxSecurityAssociation
    Die maximale Anzahl von Sicherheitsassoziationen für IPsec-Offload. Standard ist 1.

.EXAMPLE
    .\Set-VMIPsecOffload.ps1 -VMFilter "VM TEST*" -MaxSecurityAssociation 2

.NOTES
    Autor: ErikSlevin
    Datum: 04.055.2025
    Version: 0.2
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$VMFilter = "VM PROD*",
    
    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 4096)]
    [int]$MaxSecurityAssociation = 1
)

# Initialisiere Logging
# $LogFile = Join-Path -Path $PSScriptRoot -ChildPath "IPSec-Config_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
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

# Funktion zur Konfiguration der IPsec-Offload-Einstellungen
function Set-VMIPsecOffloadSetting {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Microsoft.HyperV.PowerShell.VirtualMachine]$VirtualMachine,
        
        [Parameter(Mandatory = $false)]
        [int]$SecurityAssociation = $MaxSecurityAssociation
    )
    
    try {
        # Alle Netzwerkadapter der VM abrufen
        $networkAdapters = Get-VMNetworkAdapter -VM $VirtualMachine -ErrorAction Stop
        
        if (-not $networkAdapters -or $networkAdapters.Count -eq 0) {
            Write-Log "Keine Netzwerkadapter für VM '$($VirtualMachine.Name)' gefunden" -Level WARNING
            return $false
        }

        $successCount = 0
        foreach ($adapter in $networkAdapters) {
            try {
                # Netzwerkadapter konfigurieren
                Set-VMNetworkAdapter -VMNetworkAdapter $adapter -IPsecOffloadMaximumSecurityAssociation $SecurityAssociation -ErrorAction Stop
                $successCount++
                Write-Log "Netzwerkadapter '$($adapter.Name)' bei VM '$($VirtualMachine.Name)' erfolgreich konfiguriert (IPsec SA: $SecurityAssociation)" -Level SUCCESS
            }
            catch {
                Write-Log "Fehler bei der Konfiguration des Netzwerkadapters '$($adapter.Name)' bei VM '$($VirtualMachine.Name)': $_" -Level ERROR
            }
        }
        
        return ($successCount -gt 0)
    }
    catch {
        Write-Log "Fehler beim Abrufen der Netzwerkadapter für VM '$($VirtualMachine.Name)': $_" -Level ERROR
        return $false
    }
}

# Hauptlogik
Write-Log "Skript gestartet - IPsec-Offload-Konfiguration wird durchgeführt" -Level INFO
Write-Log "Filter für virtuelle Maschinen: $VMFilter, Maximale Sicherheitsassoziationen: $MaxSecurityAssociation" -Level INFO

try {
    # Alle VMs abrufen, die dem Filter entsprechen
    $vms = Get-VM | Where-Object { $_.Name -like $VMFilter } -ErrorAction Stop
    
    if (-not $vms -or $vms.Count -eq 0) {
        Write-Log "Keine virtuellen Maschinen gefunden, die dem Filter '$VMFilter' entsprechen" -Level WARNING
        exit
    }
    
    Write-Log "Gefundene virtuelle Maschinen: $($vms.Count)" -Level INFO
    
    # Statistik initialisieren
    $totalVMs = $vms.Count
    $successVMs = 0
    $failedVMs = 0
    
    # Jede VM bearbeiten
    foreach ($vm in $vms) {
        Write-Log "Bearbeite VM: $($vm.Name)" -Level INFO
        
        # Status der VM prüfen
        if ($vm.State -ne 'off') {
            Write-Log "VM '$($vm.Name)' ist nicht im Zustand 'Running' (Aktueller Zustand: $($vm.State)). Überspringe..." -Level WARNING
            $failedVMs++
            continue
        }
        
        # IPsec-Offload konfigurieren
        $result = Set-VMIPsecOffloadSetting -VirtualMachine $vm
        
        if ($result) {
            $successVMs++
        } else {
            $failedVMs++
        }
    }
    
    # Zusammenfassung ausgeben
    Write-Log "Zusammenfassung: $successVMs von $totalVMs VMs erfolgreich konfiguriert, $failedVMs fehlgeschlagen" -Level INFO
}
catch {
    Write-Log "Unerwarteter Fehler: $_" -Level ERROR
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level ERROR
}
finally {
    Write-Log "Skript beendet" -Level INFO
}
