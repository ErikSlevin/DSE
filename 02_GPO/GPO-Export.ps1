#Requires -Version 5.1
#Requires -Modules GroupPolicy

<#
.SYNOPSIS
    Exportiert ausgewaehlte Group Policy Objects (GPOs) als Backup-Dateien.

.DESCRIPTION
    Dieses Tool ermoelicht den Export von GPOs entweder interaktiv oder ueber Parameter.
    Es erstellt strukturierte Backups mit detailliertem Logging und Metadaten.
    Unterstuetzt Range-Eingaben wie "1-6,9,10,14-22" fuer effiziente Auswahl.

.PARAMETER GpoNames
    Kommaseparierte Liste der zu exportierenden GPO-Namen.
    Wenn nicht angegeben, erfolgt eine interaktive Auswahl.

.PARAMETER BackupPath
    Zielpfad fuer die GPO-Backups. Muss ein gueltiger Verzeichnispfad sein oder erstellt werden koennen.

.PARAMETER Mode
    Ausfuehrungsmodus: 'Interactive' fuer Benutzerinteraktion oder 'Silent' fuer automatische Ausfuehrung.

.EXAMPLE
    .\GPO-Export-Compatible.ps1
    Startet das Tool im interaktiven Modus.

.EXAMPLE
    .\GPO-Export-Compatible.ps1 -GpoNames "Default Domain Policy" -BackupPath "C:\GPO-Backups"
    Exportiert eine spezifische GPO in den angegebenen Pfad.

.EXAMPLE
    .\GPO-Export-Compatible.ps1 -GpoNames "Policy1,Policy2" -BackupPath "C:\GPO-Backups" -Mode Silent
    Exportiert mehrere GPOs ohne Benutzerinteraktion.

.NOTES
    Version: 2.1
    Autor: Erik Slevin
    Erstellt: 30.06.2025
    Erweitert: Range-Support fuer Benutzerauswahl, PowerShell 5 Kompatibilitaet
    Benoetigt: PowerShell 5.1+, GroupPolicy-Modul, Domain-Zugriff
#>

[CmdletBinding()]
param(
    [Parameter(
        Position = 0,
        HelpMessage = "Kommaseparierte Liste der GPO-Namen zum Export"
    )]
    [ValidateNotNullOrEmpty()]
    [string]$GpoNames,

    [Parameter(
        Position = 1,
        HelpMessage = "Zielpfad fuer GPO-Backups"
    )]
    [ValidateScript({
        # Pruefung ob Pfad existiert oder erstellt werden kann
        if (Test-Path $_ -PathType Container) {
            return $true
        }
        # Versuche Elternverzeichnis zu finden
        $parentPath = Split-Path $_ -Parent
        if ([string]::IsNullOrEmpty($parentPath) -or (Test-Path $parentPath -PathType Container)) {
            return $true
        }
        throw "Der Pfad '$_' ist ungueltig oder das Elternverzeichnis existiert nicht."
    })]
    [string]$BackupPath,

    [Parameter(
        HelpMessage = "Ausfuehrungsmodus: Interactive oder Silent"
    )]
    [ValidateSet('Interactive', 'Silent')]
    [string]$Mode = 'Interactive'
)

#region Konstanten und Konfiguration
$Script:Config = @{
    LogFileName = 'GPO-Export-Metadata.log'
    DateTimeFormat = 'yyyy-MM-dd_HH-mm-ss'
    Encoding = 'UTF8'
    ConfirmationPattern = '^[JjYy]'
}

$Script:Messages = @{
    Title = "`nGPO EXPORT TOOL`n---------------------`nExportiert GPO´s aus der aktuellen Domaene`n"
    GpoCountFound = "Gefundene GPOs in der Domaene: {0}"
    ExportStarting = "`n=== Export wird gestartet ==="
    ExportCompleted = "`n=== Export abgeschlossen ==="
    CreatedDirectory = "Verzeichnis wurde erstellt: {0}"
    ExportingGpo = "Exportiere GPO: {0}..."
    ExportSuccess = "  [OK] Erfolgreich exportiert (Backup-ID: {0})"
    ExportError = "  [FEHLER] Export fehlgeschlagen: {0}"
    ValidationError = "FEHLER: {0}"
    UserCancelled = "Vorgang wurde vom Benutzer abgebrochen."
}
#endregion

#region Range-Parser Hilfsfunktion
function Expand-NumberRanges {
    <#
    .SYNOPSIS
        Erweitert Zahlenbereichs-Eingaben zu einer Liste von Einzelnummern.
    
    .DESCRIPTION
        Parst Eingaben wie "1-6,9,10,14-22" und gibt eine Liste aller enthaltenen Nummern zurueck.
        Unterstuetzt sowohl Einzelnummern als auch Bereiche (mit Bindestrich getrennt).
    
    .PARAMETER InputString
        Die zu parsende Eingabezeichenkette mit Nummern und Bereichen.
    
    .PARAMETER MaxValue
        Der maximale gueltige Wert (fuer Validierung).
    
    .PARAMETER MinValue
        Der minimale gueltige Wert (fuer Validierung).
    
    .EXAMPLE
        Expand-NumberRanges -InputString "1-6,9,10,14-22" -MaxValue 25
        Gibt zurueck: 1,2,3,4,5,6,9,10,14,15,16,17,18,19,20,21,22
    
    .OUTPUTS
        [int[]] Array mit allen expandierten Nummern, sortiert und ohne Duplikate.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$InputString,
        
        [Parameter(Mandatory)]
        [int]$MaxValue,
        
        [int]$MinValue = 1
    )
    
    try {
        # Eingabe bereinigen (Leerzeichen entfernen)
        $cleanInput = $InputString -replace '\s+', ''
        
        if ([string]::IsNullOrEmpty($cleanInput)) {
            throw "Eingabe ist leer"
        }
        
        # Aufteilen nach Kommas
        $segments = $cleanInput.Split(',', [StringSplitOptions]::RemoveEmptyEntries)
        
        if ($segments.Count -eq 0) {
            throw "Keine gueltigen Segmente gefunden"
        }
        
        $expandedNumbers = @()
        
        foreach ($segment in $segments) {
            if ([string]::IsNullOrEmpty($segment)) {
                continue
            }
            
            # Pruefen ob es sich um einen Bereich handelt (enthaelt Bindestrich)
            if ($segment.Contains('-')) {
                # Range verarbeiten
                $rangeParts = $segment.Split('-', [StringSplitOptions]::RemoveEmptyEntries)
                
                if ($rangeParts.Count -ne 2) {
                    throw "Ungueltiger Bereich: '$segment'. Format sollte sein: 'Start-Ende'"
                }
                
                # Start- und Endwerte parsen
                [int]$rangeStart = 0
                [int]$rangeEnd = 0
                
                if (-not [int]::TryParse($rangeParts[0], [ref]$rangeStart)) {
                    throw "Ungueltiger Startwert in Bereich '$segment': '$($rangeParts[0])'"
                }
                
                if (-not [int]::TryParse($rangeParts[1], [ref]$rangeEnd)) {
                    throw "Ungueltiger Endwert in Bereich '$segment': '$($rangeParts[1])'"
                }
                
                # Validierung der Reihenfolge
                if ($rangeStart -gt $rangeEnd) {
                    throw "Ungueltiger Bereich '$segment': Startwert ($rangeStart) ist groesser als Endwert ($rangeEnd)"
                }
                
                # Validierung der Grenzen
                if ($rangeStart -lt $MinValue -or $rangeStart -gt $MaxValue) {
                    throw "Startwert '$rangeStart' in Bereich '$segment' ist ausserhalb des gueltigen Bereichs ($MinValue-$MaxValue)"
                }
                
                if ($rangeEnd -lt $MinValue -or $rangeEnd -gt $MaxValue) {
                    throw "Endwert '$rangeEnd' in Bereich '$segment' ist ausserhalb des gueltigen Bereichs ($MinValue-$MaxValue)"
                }
                
                # Bereich expandieren
                for ($i = $rangeStart; $i -le $rangeEnd; $i++) {
                    $expandedNumbers += $i
                }
            }
            else {
                # Einzelne Nummer verarbeiten
                [int]$singleNumber = 0
                
                if (-not [int]::TryParse($segment, [ref]$singleNumber)) {
                    throw "Ungueltige Nummer: '$segment'"
                }
                
                # Validierung der Grenzen
                if ($singleNumber -lt $MinValue -or $singleNumber -gt $MaxValue) {
                    throw "Nummer '$singleNumber' ist ausserhalb des gueltigen Bereichs ($MinValue-$MaxValue)"
                }
                
                $expandedNumbers += $singleNumber
            }
        }
        
        if ($expandedNumbers.Count -eq 0) {
            throw "Keine gueltigen Nummern gefunden"
        }
        
        # Duplikate entfernen und sortieren
        $uniqueNumbers = $expandedNumbers | Sort-Object -Unique
        
        return $uniqueNumbers
    }
    catch {
        throw "Fehler beim Parsen der Eingabe '$InputString': $($_.Exception.Message)"
    }
}
#endregion

#region Hilfsfunktionen fuer Praesentation
function Write-ToolHeader {
    <#
    .SYNOPSIS
        Zeigt den Tool-Header an.
    #>
    Clear-Host
    Write-Host $Script:Messages.Title -ForegroundColor Green
}

function Write-StatusMessage {
    <#
    .SYNOPSIS
        Zeigt formatierte Statusmeldungen an.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Type = 'Info'
    )
    
    $colorMap = @{
        'Info' = 'Cyan'
        'Success' = 'Green'
        'Warning' = 'Yellow'
        'Error' = 'Red'
    }
    
    Write-Host $Message -ForegroundColor $colorMap[$Type]
}

function Write-GpoList {
    <#
    .SYNOPSIS
        Zeigt eine nummerierte Liste von GPOs an.
    #>
    param(
        [Parameter(Mandatory)]
        [System.Object[]]$GpoList,
        
        [string]$Title = "Verfuegbare GPOs"
    )
    
    Write-StatusMessage "`n=== $Title ===" -Type Info
    
    for ($i = 0; $i -lt $GpoList.Count; $i++) {
        Write-Host "$($i + 1). $($GpoList[$i].DisplayName)" -ForegroundColor White
    }
    
    # Beispiele fuer Range-Eingaben anzeigen
    if ($Title -eq "Verfuegbare GPOs") {
        Write-Host "`nEingabebeispiele:" -ForegroundColor Yellow
        Write-Host "  Einzeln:      1,3,5" -ForegroundColor Gray
        Write-Host "  Bereiche:     1-6,9,12-15" -ForegroundColor Gray
        Write-Host "  Kombiniert:   1-3,7,10-12,15" -ForegroundColor Gray
    }
}

function Write-ExportSummary {
    <#
    .SYNOPSIS
        Zeigt die Zusammenfassung des Exports an.
    #>
    param(
        [Parameter(Mandatory)]
        [int]$SuccessCount,
        
        [Parameter(Mandatory)]
        [int]$ErrorCount,
        
        [Parameter(Mandatory)]
        [string]$ExportPath
    )
    
    Write-StatusMessage $Script:Messages.ExportCompleted -Type Success
    Write-StatusMessage "Erfolgreich exportiert: $SuccessCount" -Type Success
    
    if ($ErrorCount -gt 0) {
        Write-StatusMessage "Fehlgeschlagen: $ErrorCount" -Type Error
    }
    
    Write-StatusMessage "Exportpfad: $ExportPath" -Type Info
}
#endregion

#region Kernlogik-Funktionen
function Get-AllDomainGpos {
    <#
    .SYNOPSIS
        Laedt alle GPOs aus der aktuellen Domaene.
    #>
    try {
        Import-Module GroupPolicy -ErrorAction Stop
        $allGpos = Get-GPO -All | Sort-Object DisplayName
        
        Write-StatusMessage ($Script:Messages.GpoCountFound -f $allGpos.Count) -Type Success
        return $allGpos
    }
    catch {
        Write-StatusMessage ($Script:Messages.ValidationError -f "GroupPolicy-Modul konnte nicht geladen werden: $($_.Exception.Message)") -Type Error
        throw
    }
}

function Get-UserSelectedGpos {
    <#
    .SYNOPSIS
        Ermoelicht die interaktive Auswahl von GPOs durch den Benutzer mit Range-Unterstuetzung.
    #>
    param(
        [Parameter(Mandatory)]
        [System.Object[]]$AllGpos
    )
    
    Write-GpoList -GpoList $AllGpos
    
    do {
        $userInput = Read-Host "`nNummer(n) der zu exportierenden GPOs (z.B. 1,3,5 oder 1-6,9,12-15)"
        
        try {
            $selectedNumbers = Expand-NumberRanges -InputString $userInput -MaxValue $AllGpos.Count -MinValue 1
            $validInput = $true
            
            Write-StatusMessage "Erweiterte Auswahl: $($selectedNumbers -join ',')" -Type Info
        }
        catch {
            Write-StatusMessage "Ungueltige Eingabe: $($_.Exception.Message)" -Type Warning
            Write-StatusMessage "Bitte verwenden Sie das Format: 1,3,5 oder 1-6,9,12-15" -Type Info
            $validInput = $false
        }
    } while (-not $validInput)
    
    Clear-Host
    Write-Host ""

    # Ausgewaehlte GPOs zurueckgeben
    $selectedGpos = $selectedNumbers | ForEach-Object { $AllGpos[$_ - 1] }
    
    # Auswahl bestaetigen
    Write-GpoList -GpoList $selectedGpos -Title "Ausgewaehlte GPOs fuer Export"
    
    $confirmation = Read-Host "`nExport starten? (J/N)"
    if ($confirmation -notmatch $Script:Config.ConfirmationPattern) {
        Write-StatusMessage $Script:Messages.UserCancelled -Type Warning
        return $null
    }
    
    return $selectedGpos
}

function Get-GposByNames {
    <#
    .SYNOPSIS
        Sucht GPOs anhand ihrer Namen.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$GpoNameList,
        
        [Parameter(Mandatory)]
        [System.Object[]]$AllGpos
    )
    
    $requestedNames = $GpoNameList.Split(',') | ForEach-Object { $_.Trim() }
    $foundGpos = @()
    $notFoundNames = @()
    
    foreach ($name in $requestedNames) {
        $matchingGpo = $AllGpos | Where-Object { $_.DisplayName -eq $name }
        if ($matchingGpo) {
            $foundGpos += $matchingGpo
        } else {
            $notFoundNames += $name
        }
    }
    
    # Fehlende GPOs melden
    if ($notFoundNames.Count -gt 0) {
        foreach ($name in $notFoundNames) {
            Write-StatusMessage "GPO nicht gefunden: $name" -Type Warning
        }
    }
    
    if ($foundGpos.Count -eq 0) {
        throw "Keine der angegebenen GPOs wurde gefunden."
    }
    
    return $foundGpos
}

function Initialize-BackupDirectory {
    <#
    .SYNOPSIS
        Erstellt das Backup-Verzeichnis falls es nicht existiert.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    if (-not (Test-Path $Path -PathType Container)) {
        try {
            New-Item -Path $Path -ItemType Directory -Force | Out-Null
            Write-StatusMessage ($Script:Messages.CreatedDirectory -f $Path) -Type Success
        }
        catch {
            throw "Konnte Backup-Verzeichnis nicht erstellen: $($_.Exception.Message)"
        }
    }
    
    return (Resolve-Path $Path).Path
}

function Export-GpoBackups {
    <#
    .SYNOPSIS
        Fuehrt den eigentlichen Export der ausgewaehlten GPOs durch.
    #>
    param(
        [Parameter(Mandatory)]
        [System.Object[]]$GposToExport,
        
        [Parameter(Mandatory)]
        [string]$TargetPath
    )
    
    Write-StatusMessage $Script:Messages.ExportStarting -Type Info
    
    $timestamp = Get-Date -Format $Script:Config.DateTimeFormat
    $logFilePath = Join-Path $TargetPath $Script:Config.LogFileName
    $logEntries = @()
    $successCount = 0
    $errorCount = 0
    
    foreach ($gpo in $GposToExport) {
        Write-StatusMessage ($Script:Messages.ExportingGpo -f $gpo.DisplayName) -Type Info
        
        try {
            $backupResult = Backup-GPO -Name $gpo.DisplayName -Path $TargetPath -Comment "Export von '$($gpo.DisplayName)' am $timestamp"
            
            # Erfolgreichen Export protokollieren
            $logEntry = "$timestamp - ERFOLG - GPO-ID: $($gpo.Id) - Name: $($gpo.DisplayName) - Backup-ID: $($backupResult.Id)"
            $logEntries += $logEntry
            
            Write-StatusMessage ($Script:Messages.ExportSuccess -f $backupResult.Id) -Type Success
            $successCount++
        }
        catch {
            # Fehlgeschlagenen Export protokollieren
            $errorMessage = $_.Exception.Message
            $logEntry = "$timestamp - FEHLER - GPO-ID: $($gpo.Id) - Name: $($gpo.DisplayName) - Fehler: $errorMessage"
            $logEntries += $logEntry
            
            Write-StatusMessage ($Script:Messages.ExportError -f $errorMessage) -Type Error
            $errorCount++
        }
    }
    
    # Log-Datei schreiben
    if ($logEntries.Count -gt 0) {
        try {
            if (Test-Path $logFilePath) {
                $logEntries | Add-Content -Path $logFilePath -Encoding $Script:Config.Encoding
            } else {
                $logEntries | Out-File -FilePath $logFilePath -Encoding $Script:Config.Encoding
            }
        }
        catch {
            Write-StatusMessage "Warnung: Log-Datei konnte nicht geschrieben werden: $($_.Exception.Message)" -Type Warning
        }
    }
    
    return @{
        SuccessCount = $successCount
        ErrorCount = $errorCount
    }
}

function Get-InteractiveBackupPath {
    <#
    .SYNOPSIS
        Fragt den Benutzer nach dem Backup-Pfad.
    #>
    do {
        $path = Read-Host "Pfad fuer GPO-Export eingeben"
        if ([string]::IsNullOrWhiteSpace($path)) {
            Write-StatusMessage "Ungueltiger Pfad. Bitte einen gueltigen Pfad eingeben." -Type Warning
            $validPath = $false
        } else {
            $validPath = $true
        }
    } while (-not $validPath)
    
    return $path
}
#endregion

#region Hauptprogramm
function Start-GpoExportProcess {
    <#
    .SYNOPSIS
        Hauptfunktion zur Koordination des Export-Prozesses.
    #>
    try {
        Write-ToolHeader
        
        # Parametervalidierung
        if (($GpoNames -and -not $BackupPath) -or (-not $GpoNames -and $BackupPath)) {
            Write-StatusMessage "FEHLER: Wenn GPO-Namen angegeben werden, muss auch der Backup-Pfad angegeben werden!" -Type Error
            Write-StatusMessage "`nVerwendung:" -Type Info
            Write-StatusMessage "  Interaktiv:  .\GPO-Export-Compatible.ps1" -Type Info
            Write-StatusMessage "  Parameter:   .\GPO-Export-Compatible.ps1 -GpoNames `"Name1,Name2`" -BackupPath `"C:\Pfad`"" -Type Info
            exit 1
        }
        
        # Alle GPOs aus der Domaene laden
        $allGpos = Get-AllDomainGpos
        
        # GPOs fuer Export auswaehlen
        if ($GpoNames) {
            # Parameter-Modus: GPOs nach Namen suchen
            $selectedGpos = Get-GposByNames -GpoNameList $GpoNames -AllGpos $allGpos
        } else {
            # Interaktiver Modus: Benutzerauswahl
            $selectedGpos = Get-UserSelectedGpos -AllGpos $allGpos
            if ($null -eq $selectedGpos) {
                exit 0
            }
        }
        
        # Backup-Pfad bestimmen
        if (-not $BackupPath) {
            $BackupPath = Get-InteractiveBackupPath
        }
        
        # Backup-Verzeichnis vorbereiten
        $resolvedBackupPath = Initialize-BackupDirectory -Path $BackupPath
        
        # Export durchfuehren
        $exportResult = Export-GpoBackups -GposToExport $selectedGpos -TargetPath $resolvedBackupPath
        
        # Zusammenfassung anzeigen
        Write-ExportSummary -SuccessCount $exportResult.SuccessCount -ErrorCount $exportResult.ErrorCount -ExportPath $resolvedBackupPath
        
        # Bei interaktivem Modus auf Eingabe warten
        if ($Mode -eq 'Interactive') {
            Read-Host "`nDruecken Sie Enter zum Beenden"
        }
        
        exit 0
    }
    catch {
        Write-StatusMessage "Kritischer Fehler: $($_.Exception.Message)" -Type Error
        if ($Mode -eq 'Interactive') {
            Read-Host "`nDruecken Sie Enter zum Beenden"
        }
        exit 1
    }
}

# Hauptprogramm ausfuehren
Start-GpoExportProcess
#endregion
