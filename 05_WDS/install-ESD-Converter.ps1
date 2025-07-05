#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Extrahiert Windows-Images aus einer ESD-Datei als separate WIM-Dateien.

.DESCRIPTION
    Dieses Skript identifiziert alle Image-Indizes in einer ESD-Datei und extrahiert
    jedes Image als separate WIM-Datei mit maximaler Kompression. Es eignet sich besonders
    für die Vorbereitung von Images für Windows Deployment Services (WDS).

.PARAMETER ESDPath
    Pfad zur Quell-ESD-Datei. Standard ist "D:\RemoteInstall\ISOCopy\install.esd".

.PARAMETER DestinationFolder
    Zielordner für die extrahierten WIM-Dateien. Standard ist "D:\RemoteInstall\ISOCopy\ExtractedWIMs".

.PARAMETER CompressionMethod
    Komprimierungsmethode für die WIM-Dateien. Mögliche Werte sind "None", "Fast", "Maximum".
    Standard ist "Maximum".

.EXAMPLE
    .\Extract-ESDToWIM.ps1 -ESDPath "E:\Sources\install.esd" -DestinationFolder "E:\WIMs" -CompressionMethod "Fast"

.NOTES
    Autor:ErikSlevin
    Datum: 04.05.2025
    Version: 0.1
    
    Abhängigkeiten: DISM (Deployment Image Servicing and Management)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$ESDPath = "D:\RemoteInstall\ISOCopy\install.esd",
    
    [Parameter(Mandatory = $false)]
    [string]$DestinationFolder = "D:\RemoteInstall\ISOCopy\ExtractedWIMs",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("None", "Fast", "Maximum")]
    [string]$CompressionMethod = "Maximum"
)

# Mapping für DISM-Kompressionsparameter
$compressionMapping = @{
    "None" = "None"
    "Fast" = "Fast"
    "Maximum" = "Max"
}

# Initialisiere Logging
$LogFolder = Join-Path -Path $PSScriptRoot -ChildPath "Logs"
if (-not (Test-Path -Path $LogFolder)) {
    New-Item -ItemType Directory -Path $LogFolder -Force | Out-Null
}

$LogFile = Join-Path -Path $LogFolder -ChildPath "ESD-Extract_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$TranscriptFile = Join-Path -Path $LogFolder -ChildPath "ESD-Extract_Transcript_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

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
    Add-Content -Path $LogFile -Value $LogMessage
    
    # Farbige Konsolenausgabe
    switch ($Level) {
        'INFO'    { Write-Host $LogMessage -ForegroundColor Cyan }
        'WARNING' { Write-Host $LogMessage -ForegroundColor Yellow }
        'ERROR'   { Write-Host $LogMessage -ForegroundColor Red }
        'SUCCESS' { Write-Host $LogMessage -ForegroundColor Green }
    }
}

function Get-WimIndexInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$WimFile
    )
    
    try {
        Write-Log "Ermittle Image-Informationen für $WimFile" -Level INFO
        
        # DISM-Befehl ausführen und Ausgabe erfassen
        $dismOutput = & dism /Get-WimInfo /WimFile:"$WimFile" 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "DISM-Fehler beim Abrufen der WIM-Informationen: $dismOutput" -Level ERROR
            return $null
        }
        
        # Extrahiere Index, Name und Edition
        $indexInfo = @()
        $currentIndex = $null
        $currentName = $null
        $currentDesc = $null
        
        foreach ($line in $dismOutput) {
            $line = $line.ToString().Trim()
            
            if ($line -match "^Index\s*:\s*(\d+)$") {
                # Speichere vorherigen Index-Eintrag, falls vorhanden
                if ($currentIndex) {
                    $indexInfo += [PSCustomObject]@{
                        Index = $currentIndex
                        Name = $currentName
                        Description = $currentDesc
                    }
                }
                
                # Starte neuen Index-Eintrag
                $currentIndex = $matches[1]
                $currentName = $null
                $currentDesc = $null
            }
            elseif ($line -match "^Name\s*:\s*(.+)$") {
                $currentName = $matches[1]
            }
            elseif ($line -match "^Description\s*:\s*(.+)$") {
                $currentDesc = $matches[1]
            }
        }
        
        # Letzten Eintrag hinzufügen
        if ($currentIndex) {
            $indexInfo += [PSCustomObject]@{
                Index = $currentIndex
                Name = $currentName
                Description = $currentDesc
            }
        }
        
        return $indexInfo
    }
    catch {
        Write-Log "Fehler beim Ermitteln der WIM-Indexinformationen: $_" -Level ERROR
        return $null
    }
}

function Export-WimImage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceFile,
        
        [Parameter(Mandatory = $true)]
        [int]$SourceIndex,
        
        [Parameter(Mandatory = $true)]
        [string]$DestinationFile,
        
        [Parameter(Mandatory = $false)]
        [string]$ImageName,
        
        [Parameter(Mandatory = $false)]
        [string]$Compression = "Max"
    )
    
    try {
        $startTime = Get-Date
        
        # Zeitmessung starten
        Write-Log "Beginne Export von Index $SourceIndex $(if($ImageName){"($ImageName)"}) nach $DestinationFile" -Level INFO
        
        # Prüfe, ob die Zieldatei bereits existiert
        if (Test-Path -Path $DestinationFile) {
            Write-Log "Zieldatei existiert bereits. Wird überschrieben: $DestinationFile" -Level WARNING
            Remove-Item -Path $DestinationFile -Force
        }
        
        # Stelle sicher, dass der Zielordner existiert
        $destinationFolder = Split-Path -Path $DestinationFile -Parent
        if (-not (Test-Path -Path $destinationFolder)) {
            New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null
            Write-Log "Zielordner erstellt: $destinationFolder" -Level INFO
        }
        
        # DISM-Befehl ausführen
        $dismArgs = @(
            "/Export-Image"
            "/SourceImageFile:`"$SourceFile`""
            "/SourceIndex:$SourceIndex"
            "/DestinationImageFile:`"$DestinationFile`""
            "/Compress:$Compression"
            "/CheckIntegrity"
        )
        
        # Führe DISM-Befehl aus
        $process = Start-Process -FilePath "dism.exe" -ArgumentList $dismArgs -NoNewWindow -PassThru -Wait
        
        if ($process.ExitCode -ne 0) {
            Write-Log "DISM-Export fehlgeschlagen mit Exit-Code $($process.ExitCode)" -Level ERROR
            return $false
        }
        
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        # Überprüfe, ob die Datei erfolgreich erstellt wurde
        if (Test-Path -Path $DestinationFile) {
            $fileInfo = Get-Item -Path $DestinationFile
            $fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
            
            Write-Log "Export erfolgreich: Index $SourceIndex $(if($ImageName){"($ImageName)"}) (Größe: $fileSizeMB MB, Dauer: $($duration.ToString('hh\:mm\:ss')))" -Level SUCCESS
            return $true
        }
        else {
            Write-Log "Export fehlgeschlagen: Zieldatei wurde nicht erstellt" -Level ERROR
            return $false
        }
    }
    catch {
        Write-Log "Fehler beim Exportieren des WIM-Image: $_" -Level ERROR
        Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level ERROR
        return $false
    }
}

# Hauptfunktion
function Start-ESDExtraction {
    [CmdletBinding()]
    param()
    
    try {
        # Startzeit für Gesamtdauer
        $totalStartTime = Get-Date
        
        # Einleitung
        Write-Log "===== ESD-zu-WIM Extraktionsprozess gestartet =====" -Level INFO
        Write-Log "Quell-ESD: $ESDPath" -Level INFO
        Write-Log "Zielordner: $DestinationFolder" -Level INFO
        Write-Log "Komprimierungsmethode: $CompressionMethod (DISM: $($compressionMapping[$CompressionMethod]))" -Level INFO
        
        # Prüfen, ob die ESD-Datei existiert
        if (-not (Test-Path -Path $ESDPath)) {
            Write-Log "Die angegebene ESD-Datei existiert nicht: $ESDPath" -Level ERROR
            return
        }
        
        # Zielordner erstellen oder überprüfen
        if (-not (Test-Path -Path $DestinationFolder)) {
            New-Item -ItemType Directory -Path $DestinationFolder -Force | Out-Null
            Write-Log "Zielordner wurde erstellt: $DestinationFolder" -Level INFO
        }
        
        # WIM-Index-Informationen abrufen
        $indexInfo = Get-WimIndexInfo -WimFile $ESDPath
        
        if (-not $indexInfo -or $indexInfo.Count -eq 0) {
            Write-Log "Keine gültigen Indizes in der ESD-Datei gefunden" -Level ERROR
            return
        }
        
        # Zusammenfassung der gefundenen Images
        Write-Log "Es wurden $($indexInfo.Count) Windows-Images in der ESD-Datei gefunden:" -Level INFO
        foreach ($image in $indexInfo) {
            Write-Log "  Index $($image.Index): $($image.Name) - $($image.Description)" -Level INFO
        }
        
        # Für jeden Index eine WIM-Datei erstellen
        $successCount = 0
        $failCount = 0
        
        foreach ($image in $indexInfo) {
            # Bereinige den Namen für die Datei
            $safeName = if ($image.Name) {
                $image.Name -replace '[\\\/\:\*\?\"\<\>\|]', '_' 
            } else { 
                "Unknown" 
            }
            
            $destinationFile = Join-Path -Path $DestinationFolder -ChildPath "install_$($image.Index)_$safeName.wim"
            
            # Exportiere das Image
            $result = Export-WimImage -SourceFile $ESDPath -SourceIndex $image.Index -DestinationFile $destinationFile -ImageName $image.Name -Compression $compressionMapping[$CompressionMethod]
            
            if ($result) {
                $successCount++
            } else {
                $failCount++
            }
        }
        
        # Gesamtergebnis
        $totalEndTime = Get-Date
        $totalDuration = $totalEndTime - $totalStartTime
        
        Write-Log "===== Extraktion abgeschlossen =====" -Level INFO
        Write-Log "Erfolgreich exportierte Images: $successCount" -Level INFO
        Write-Log "Fehlgeschlagene Exporte: $failCount" -Level INFO
        Write-Log "Gesamtdauer: $($totalDuration.ToString('hh\:mm\:ss'))" -Level INFO
        
        if ($successCount -eq $indexInfo.Count) {
            Write-Log "Alle Windows-Images wurden erfolgreich extrahiert!" -Level SUCCESS
        } else {
            Write-Log "Einige Images konnten nicht extrahiert werden. Bitte prüfen Sie die Protokolle." -Level WARNING
        }
    }
    catch {
        Write-Log "Unerwarteter Fehler: $_" -Level ERROR
        Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level ERROR
    }
    finally {
        Write-Log "Skript beendet" -Level INFO
    }
}

# Starte Protokollierung und führe Hauptfunktion aus
try {
    Start-Transcript -Path $TranscriptFile | Out-Null
    Write-Log "Transkript wird aufgezeichnet in: $TranscriptFile" -Level INFO
    
    # Freier Speicherplatz prüfen
    $drive = Split-Path -Path $DestinationFolder -Qualifier
    $freeSpace = (Get-PSDrive -Name $drive.TrimEnd(':')) | Select-Object -ExpandProperty Free
    $freeSpaceGB = [math]::Round($freeSpace / 1GB, 2)
    
    Write-Log "Verfügbarer Speicherplatz auf Laufwerk $drive`: $freeSpaceGB GB" -Level INFO
    
    if ($freeSpaceGB -lt 10) {
        Write-Log "Warnung: Wenig freier Speicherplatz verfügbar. Mindestens 10 GB empfohlen." -Level WARNING
    }
    
    # Hauptfunktion ausführen
    Start-ESDExtraction
}
catch {
    Write-Log "Kritischer Fehler beim Ausführen des Skripts: $_" -Level ERROR
}
finally {
    Stop-Transcript | Out-Null
}
