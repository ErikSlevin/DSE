#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
WSUS-Management Hauptskript - All-in-One
    
.DESCRIPTION
Hauptskript für WSUS-Verwaltungsaufgaben mit integrierten Funktionen:
- Verbindung zum WSUS-Server
- Konsolen-Logging
- Datei-Logging
- Ablehnung veralteter Updates
- Ablehnung von Beta/Preview-Updates
- Ablehnung ersetzter Updates

.NOTES
Version:        1.2.0
Autor:          Erik Slevin
Datum:          2025-07-01
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("LOCAL", "DOMAIN")]
    [string]$Mode = "LOCAL",
    
    [Parameter(Mandatory = $false)]
    [string]$ServerName,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableFileLogging
)

#region Integrierte Funktionen

function Write-WSUSLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Message,
        
        [ValidateSet("INFO", "SUBINFO", "SUCCESS", "WARNING", "ERROR", "DEBUG", "INLINE_GREEN", "INLINE_RED")]
        [string]$Status = "INFO",
        
        [ConsoleColor]$MessageColor,
        
        [switch]$NoNewLine
    )
    
    begin {
        $StatusColors = @{
            SUCCESS      = "Green"
            ERROR        = "Red"
            WARNING      = "Yellow"
            INFO         = "White"
            SUBINFO      = "DarkGray"
            DEBUG        = "Magenta"
            INLINE_GREEN = "Green"
            INLINE_RED   = "Red"
        }
        
        $InlineStatus = @("INLINE_GREEN", "INLINE_RED")
    }
    
    process {
        if ([string]::IsNullOrEmpty($Message)) {
            Write-Host ""
            return
        }
        
        $Color = if ($MessageColor) { $MessageColor } else { $StatusColors[$Status] }
        
        if ($Status -in $InlineStatus) {
            Write-Host $Message -NoNewline:$NoNewLine -ForegroundColor $Color
            return
        }
        
        $TimeStamp = Get-Date -Format "HH:mm:ss"
        
        Write-Host "[" -NoNewline -ForegroundColor White
        Write-Host $TimeStamp -NoNewline
        Write-Host "] " -NoNewline -ForegroundColor White
        Write-Host $Message -NoNewline:$NoNewLine -ForegroundColor $Color
    }
}

function Write-WSUSLogFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [switch]$PassThru,
        
        [Parameter(Mandatory = $false)]
        [string]$LogPath = "D:\WSUS-DATEN\logfiles\",
        
        [Parameter(Mandatory = $false)]
        [string]$FileName,
        
        [Parameter(Mandatory = $false)]
        [bool]$Append = $true
    )
    
    begin {
        $CurrentDate = Get-Date
        $DateString = $CurrentDate.ToString("yyyy-MM-dd")
        $TimeString = $CurrentDate.ToString("HH:mm:ss")
        
        if (-not $FileName) {
            $FileName = "$DateString-WSUS-Script.log"
        }
        
        $FullLogPath = Join-Path -Path $LogPath -ChildPath $FileName
        
        $LogDirectory = Split-Path -Path $FullLogPath -Parent
        if (-not (Test-Path -Path $LogDirectory)) {
            try {
                New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
                Write-WSUSLog "Log-Verzeichnis erstellt: $LogDirectory" -Status SUCCESS
            }
            catch {
                Write-WSUSLog "Fehler beim Erstellen des Log-Verzeichnisses: $($_.Exception.Message)" -Status ERROR
                throw
            }
        }
    }
    
    process {
        try {
            $LogEntry = "$DateString`t$TimeString`t$Message"
            
            if ($Append) {
                Add-Content -Path $FullLogPath -Value $LogEntry -Encoding UTF8
            } else {
                Set-Content -Path $FullLogPath -Value $LogEntry -Encoding UTF8
            }
            
            if ($PSBoundParameters.ContainsKey('Debug') -or $VerbosePreference -eq 'Continue') {
                Write-WSUSLog "Log geschrieben: $FileName" -Status DEBUG
            }
            
            if ($PSBoundParameters.ContainsKey('PassThru') -and $PassThru) {
                return $FullLogPath
            }
            
        }
        catch {
            Write-WSUSLog "Fehler beim Schreiben der Logdatei: $($_.Exception.Message)" -Status ERROR
            Write-WSUSLog "Pfad: $FullLogPath" -Status ERROR
            throw
        }
    }
}

function Connect-WSUSServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("LOCAL", "DOMAIN")]
        [string]$Mode = "LOCAL",
        
        [Parameter(Mandatory = $false)]
        [string]$ServerName,
        
        [Parameter(Mandatory = $false)]
        [int]$Port,
        
        [Parameter(Mandatory = $false)]
        [bool]$UseSSL
    )
    
    begin {
        try {
            Add-Type -Path "${env:ProgramFiles}\Update Services\Api\Microsoft.UpdateServices.Administration.dll" -ErrorAction Stop
        }
        catch {
            Write-WSUSLog "Fehler beim Laden der WSUS-Assembly: $($_.Exception.Message)" -Status ERROR
            throw "WSUS-Assembly konnte nicht geladen werden. Ist WSUS installiert?"
        }
    }
    
    process {
        try {
            switch ($Mode.ToUpper()) {
                "LOCAL" {
                    $ComputedServerName = if ($ServerName) { $ServerName } else { $env:COMPUTERNAME }
                    $ComputedUseSSL = if ($PSBoundParameters.ContainsKey('UseSSL')) { $UseSSL } else { $false }
                    $ComputedPort = if ($Port) { $Port } else { 8530 }
                }
                
                "DOMAIN" {
                    if ($ServerName) {
                        $ComputedServerName = $ServerName
                    } else {
                        if (-not $env:USERDNSDOMAIN) {
                            throw "Domäne konnte nicht ermittelt werden. Bitte ServerName-Parameter verwenden."
                        }
                        $ComputedServerName = "$($env:COMPUTERNAME).$($env:USERDNSDOMAIN)"
                    }
                    
                    $ComputedUseSSL = if ($PSBoundParameters.ContainsKey('UseSSL')) { $UseSSL } else { $true }
                    $ComputedPort = if ($Port) { $Port } else { 8531 }
                }
            }
            
            $WSUSServer = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer(
                $ComputedServerName,
                $ComputedUseSSL,
                $ComputedPort
            )
            
            Write-WSUSLog "WSUS-Verbindung erfolgreich hergestellt" -Status SUCCESS
            
            return $WSUSServer

        }
        catch {
            Write-WSUSLog "Fehler bei WSUS-Verbindung: $($_.Exception.Message)" -Status ERROR
            Write-WSUSLog "Server: $ComputedServerName | SSL: $ComputedUseSSL | Port: $ComputedPort" -Status ERROR
        }
    }
}

function Invoke-DeclineUpdatesFromConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.UpdateServices.Administration.IUpdateServer]$WSUSServer,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$JsonContent,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableFileLogging
    )
    
    begin {
        Write-WSUSLog "Starte Ablehnung ALLER veralteten Updates..." -Status INFO
        
        if ($EnableFileLogging) {
            Write-WSUSLogFile "Starte Ablehnung veralteter Updates basierend auf JSON-Konfiguration"
        }
        
        $TotalDeclined = 0
        $TotalProcessed = 0
        $ErrorCount = 0
    }
    
    process {
        try {
            Write-WSUSLog "Lade verfügbare Produkte vom WSUS-Server..." -Status INFO
            $AllProducts = $WSUSServer.GetUpdateCategories()
            
            Write-WSUSLog "Gefundene Produkte: $($AllProducts.Count)" -Status SUBINFO
            
            foreach ($category in $JsonContent.declined_updates) {
                Write-WSUSLog "Verarbeite Kategorie: $($category.name)" -Status INFO
                
                if ($EnableFileLogging) {
                    Write-WSUSLogFile "Verarbeite Kategorie: $($category.name) | Priorität: $($category.priority)"
                }
                
                $CategoryDeclined = 0
                
                foreach ($productName in $category.products) {
                    Write-WSUSLog "  Suche Produkt: $productName" -Status SUBINFO
                    
                    $MatchingProducts = $AllProducts | Where-Object { 
                        $_.Title -eq $productName -or 
                        $_.Title -like "*$productName*" 
                    }
                    
                    if ($MatchingProducts) {
                        foreach ($product in $MatchingProducts) {
                            Write-WSUSLog "  Verarbeite Produkt: $($product.Title)" -Status SUBINFO
                            
                            $UpdateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
                            $UpdateScope.Categories.Add($product)
                            
                            try {
                                $Updates = $WSUSServer.GetUpdates($UpdateScope)
                                $ProductDeclined = 0
                                
                                foreach ($update in $Updates) {
                                    if (-not $update.IsDeclined) {
                                        $TotalProcessed++
                                        
                                        $update.Decline()
                                        Write-WSUSLog "    Abgelehnt: $($update.Title)" -Status SUCCESS
                                        $ProductDeclined++
                                        $CategoryDeclined++
                                        $TotalDeclined++
                                        
                                        if ($EnableFileLogging) {
                                            Write-WSUSLogFile "Update abgelehnt: $($update.Title) | Produkt: $($product.Title) | Kategorie: $($category.name)"
                                        }
                                    }
                                }
                                
                                Write-WSUSLog "  Updates für '$($product.Title)' verarbeitet: $ProductDeclined abgelehnt" -Status INFO
                                
                            } catch {
                                Write-WSUSLog "  Fehler beim Abrufen der Updates für '$($product.Title)': $($_.Exception.Message)" -Status ERROR
                                $ErrorCount++
                                
                                if ($EnableFileLogging) {
                                    Write-WSUSLogFile "FEHLER beim Verarbeiten von Produkt '$($product.Title)': $($_.Exception.Message)"
                                }
                            }
                        }
                    } else {
                        Write-WSUSLog "  Produkt nicht gefunden: $productName" -Status WARNING
                        
                        if ($EnableFileLogging) {
                            Write-WSUSLogFile "WARNUNG: Produkt nicht gefunden: $productName"
                        }
                    }
                }
                
                Write-WSUSLog "Kategorie '$($category.name)' abgeschlossen: $CategoryDeclined Updates abgelehnt" -Status SUCCESS
            }
            
        } catch {
            Write-WSUSLog "Kritischer Fehler beim Verarbeiten der Updates: $($_.Exception.Message)" -Status ERROR
            $ErrorCount++
            
            if ($EnableFileLogging) {
                Write-WSUSLogFile "KRITISCHER FEHLER: $($_.Exception.Message)"
            }
        }
    }
    
    end {
        Write-WSUSLog "========================================" -Status INFO
        Write-WSUSLog "ZUSAMMENFASSUNG VERALTETE UPDATES" -Status INFO
        Write-WSUSLog "========================================" -Status INFO
        Write-WSUSLog "Verarbeitete Updates: $TotalProcessed" -Status INFO
        Write-WSUSLog "Abgelehnte Updates: $TotalDeclined" -Status SUCCESS
        Write-WSUSLog "Fehler aufgetreten: $ErrorCount" -Status $(if ($ErrorCount -gt 0) { "ERROR" } else { "SUCCESS" })
        Write-WSUSLog "========================================" -Status INFO
        
        if ($EnableFileLogging) {
            Write-WSUSLogFile "ZUSAMMENFASSUNG veraltete Updates - Verarbeitet: $TotalProcessed | Abgelehnt: $TotalDeclined | Fehler: $ErrorCount"
        }
    }
}

function Invoke-DeclineBetaPreviewUpdates {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.UpdateServices.Administration.IUpdateServer]$WSUSServer,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableFileLogging
    )
    
    begin {
        Write-WSUSLog "Starte Ablehnung ALLER Beta/Preview/Insider-Updates..." -Status INFO
        
        if ($EnableFileLogging) {
            Write-WSUSLogFile "Starte Ablehnung von Beta/Preview/Insider-Updates"
        }
        
        $BetaKeywords = @(
            "Beta", "beta", "BETA",
            "Preview", "preview", "PREVIEW", 
            "Insider", "insider", "INSIDER",
            "Pre-Release", "pre-release", "PRE-RELEASE",
            "Release Candidate", "RC", "rc",
            "Alpha", "alpha", "ALPHA",
            "Development", "development", "DEV", "dev",
            "Test", "TEST", "Testing",
            "Experimental", "experimental",
            "Canary", "canary", "CANARY",
            "Nightly", "nightly", "NIGHTLY"
        )
        
        $TotalDeclined = 0
        $TotalProcessed = 0
        $ErrorCount = 0
        $BetaUpdates = @()
    }
    
    process {
        try {
            Write-WSUSLog "Lade alle verfügbaren Updates vom WSUS-Server..." -Status INFO
            
            $UpdateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
            $AllUpdates = $WSUSServer.GetUpdates($UpdateScope)
            
            Write-WSUSLog "Gefundene Updates gesamt: $($AllUpdates.Count)" -Status SUBINFO
            
            foreach ($update in $AllUpdates) {
                $TotalProcessed++
                
                $ContainsBetaKeyword = $false
                
                foreach ($keyword in $BetaKeywords) {
                    if ($update.Title -like "*$keyword*" -or 
                        $update.Description -like "*$keyword*") {
                        $ContainsBetaKeyword = $true
                        break
                    }
                }
                
                if ($ContainsBetaKeyword) {
                    $BetaUpdates += $update
                }
                
                if ($TotalProcessed % 1000 -eq 0) {
                    Write-WSUSLog "Fortschritt: $TotalProcessed Updates geprüft..." -Status SUBINFO
                }
            }
            
            Write-WSUSLog "Beta/Preview/Insider Updates gefunden: $($BetaUpdates.Count)" -Status INFO
            
            foreach ($update in $BetaUpdates) {
                if (-not $update.IsDeclined) {
                    try {
                        $update.Decline()
                        Write-WSUSLog "  Abgelehnt: $($update.Title)" -Status SUCCESS
                        $TotalDeclined++
                        
                        if ($EnableFileLogging) {
                            Write-WSUSLogFile "Beta/Preview-Update abgelehnt: $($update.Title)"
                        }
                    } catch {
                        Write-WSUSLog "  Fehler beim Ablehnen: $($update.Title) - $($_.Exception.Message)" -Status ERROR
                        $ErrorCount++
                        
                        if ($EnableFileLogging) {
                            Write-WSUSLogFile "FEHLER beim Ablehnen von Beta-Update '$($update.Title)': $($_.Exception.Message)"
                        }
                    }
                }
            }
            
        } catch {
            Write-WSUSLog "Kritischer Fehler beim Verarbeiten der Beta/Preview-Updates: $($_.Exception.Message)" -Status ERROR
            $ErrorCount++
            
            if ($EnableFileLogging) {
                Write-WSUSLogFile "KRITISCHER FEHLER bei Beta/Preview-Updates: $($_.Exception.Message)"
            }
        }
    }
    
    end {
        Write-WSUSLog "========================================" -Status INFO
        Write-WSUSLog "ZUSAMMENFASSUNG BETA/PREVIEW-UPDATES" -Status INFO
        Write-WSUSLog "========================================" -Status INFO
        Write-WSUSLog "Geprüfte Updates: $TotalProcessed" -Status INFO
        Write-WSUSLog "Gefundene Beta/Preview-Updates: $($BetaUpdates.Count)" -Status INFO
        Write-WSUSLog "Abgelehnte Updates: $TotalDeclined" -Status SUCCESS
        Write-WSUSLog "Fehler aufgetreten: $ErrorCount" -Status $(if ($ErrorCount -gt 0) { "ERROR" } else { "SUCCESS" })
        Write-WSUSLog "========================================" -Status INFO
        
        if ($EnableFileLogging) {
            Write-WSUSLogFile "ZUSAMMENFASSUNG Beta/Preview-Updates - Geprüft: $TotalProcessed | Gefunden: $($BetaUpdates.Count) | Abgelehnt: $TotalDeclined | Fehler: $ErrorCount"
        }
    }
}

function Invoke-DeclineSupersededUpdates {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.UpdateServices.Administration.IUpdateServer]$WSUSServer,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableFileLogging
    )
    
    begin {
        Write-WSUSLog "Starte Ablehnung ALLER ersetzten/abgelösten Updates..." -Status INFO
        
        if ($EnableFileLogging) {
            Write-WSUSLogFile "Starte Ablehnung von ersetzten/abgelösten (superseded) Updates"
        }
        
        $TotalDeclined = 0
        $TotalProcessed = 0
        $ErrorCount = 0
        $SupersededUpdates = @()
    }
    
    process {
        try {
            Write-WSUSLog "Lade alle verfügbaren Updates vom WSUS-Server..." -Status INFO
            
            $UpdateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
            $AllUpdates = $WSUSServer.GetUpdates($UpdateScope)
            
            Write-WSUSLog "Gefundene Updates gesamt: $($AllUpdates.Count)" -Status SUBINFO
            
            foreach ($update in $AllUpdates) {
                $TotalProcessed++
                
                if ($update.IsSuperseded) {
                    $SupersededUpdates += $update
                }
                
                if ($TotalProcessed % 1000 -eq 0) {
                    Write-WSUSLog "Fortschritt: $TotalProcessed Updates geprüft..." -Status SUBINFO
                }
            }
            
            Write-WSUSLog "Ersetzte/abgelöste Updates gefunden: $($SupersededUpdates.Count)" -Status INFO
            
            foreach ($update in $SupersededUpdates) {
                if (-not $update.IsDeclined) {
                    try {
                        $update.Decline()
                        Write-WSUSLog "  Abgelehnt: $($update.Title)" -Status SUCCESS
                        $TotalDeclined++
                        
                        if ($EnableFileLogging) {
                            Write-WSUSLogFile "Ersetztes Update abgelehnt: $($update.Title)"
                        }
                    } catch {
                        Write-WSUSLog "  Fehler beim Ablehnen: $($update.Title) - $($_.Exception.Message)" -Status ERROR
                        $ErrorCount++
                        
                        if ($EnableFileLogging) {
                            Write-WSUSLogFile "FEHLER beim Ablehnen von ersetztem Update '$($update.Title)': $($_.Exception.Message)"
                        }
                    }
                } else {
                    Write-WSUSLog "  Bereits abgelehnt: $($update.Title)" -Status SUBINFO
                }
            }
            
        } catch {
            Write-WSUSLog "Kritischer Fehler beim Verarbeiten der ersetzten Updates: $($_.Exception.Message)" -Status ERROR
            $ErrorCount++
            
            if ($EnableFileLogging) {
                Write-WSUSLogFile "KRITISCHER FEHLER bei ersetzten Updates: $($_.Exception.Message)"
            }
        }
    }
    
    end {
        Write-WSUSLog "========================================" -Status INFO
        Write-WSUSLog "ZUSAMMENFASSUNG ERSETZTE UPDATES" -Status INFO
        Write-WSUSLog "========================================" -Status INFO
        Write-WSUSLog "Geprüfte Updates: $TotalProcessed" -Status INFO
        Write-WSUSLog "Gefundene ersetzte Updates: $($SupersededUpdates.Count)" -Status INFO
        Write-WSUSLog "Abgelehnte Updates: $TotalDeclined" -Status SUCCESS
        Write-WSUSLog "Fehler aufgetreten: $ErrorCount" -Status $(if ($ErrorCount -gt 0) { "ERROR" } else { "SUCCESS" })
        Write-WSUSLog "========================================" -Status INFO
        
        if ($EnableFileLogging) {
            Write-WSUSLogFile "ZUSAMMENFASSUNG ersetzte Updates - Geprüft: $TotalProcessed | Gefunden: $($SupersededUpdates.Count) | Abgelehnt: $TotalDeclined | Fehler: $ErrorCount"
        }
    }
}

#endregion

#region Script-Konfiguration
$script:StartTime = Get-Date
$script:WSUSServer = $null
#endregion

#region Hauptprogramm
try {
    Write-WSUSLog "========================================" -Status INFO
    Write-WSUSLog "WSUS-Management Script gestartet" -Status SUCCESS
    Write-WSUSLog "========================================" -Status INFO
    Write-WSUSLog "Modus: $Mode" -Status INFO
    
    if ($EnableFileLogging) {
        Write-WSUSLogFile "WSUS-Management Script gestartet - Modus: $Mode"
        Write-WSUSLog "Datei-Logging aktiviert" -Status SUCCESS
    }
    
    Write-WSUSLog "Stelle Verbindung zum WSUS-Server her..." -Status INFO
    
    $ConnectionParams = @{
        Mode = $Mode
    }
    
    if ($ServerName) {
        $ConnectionParams.ServerName = $ServerName
        Write-WSUSLog "Verwende benutzerdefinierten Server: $ServerName" -Status INFO
    }
    
    $script:WSUSServer = Connect-WSUSServer @ConnectionParams
    
    if ($null -eq $script:WSUSServer) {
        throw "WSUS-Server-Verbindung konnte nicht hergestellt werden"
    }
    
    Write-WSUSLog "========================================" -Status INFO
    Write-WSUSLog "WSUS-Server Informationen:" -Status INFO
    Write-WSUSLog "Name: $($script:WSUSServer.Name)" -Status SUBINFO
    Write-WSUSLog "Port: $($script:WSUSServer.PortNumber)" -Status SUBINFO
    Write-WSUSLog "SSL: $($script:WSUSServer.UseSecureConnection)" -Status SUBINFO
    Write-WSUSLog "Version: $($script:WSUSServer.Version)" -Status SUBINFO
    Write-WSUSLog "========================================" -Status INFO
    
    if ($EnableFileLogging) {
        Write-WSUSLogFile "WSUS-Server verbunden: $($script:WSUSServer.Name) | Port: $($script:WSUSServer.PortNumber) | SSL: $($script:WSUSServer.UseSecureConnection)"
    }
    
    $JsonPath = Join-Path -Path $PSScriptRoot -ChildPath "abzulehnende_produkte.json"
    
    if (-not (Test-Path -Path $JsonPath)) {
        throw "JSON-Datei nicht gefunden: $JsonPath"
    }
    
    Write-WSUSLog "Lade Konfigurationsdatei..." -Status INFO
    
    try {
        $JsonContent = Get-Content -Path $JsonPath -Raw | ConvertFrom-Json
        Write-WSUSLog "Konfiguration erfolgreich geladen" -Status SUCCESS
        Write-WSUSLog "Version: $($JsonContent.metadata.version)" -Status SUBINFO
        Write-WSUSLog "Letzte Aktualisierung: $($JsonContent.metadata.lastUpdated)" -Status SUBINFO
    }
    catch {
        throw "Fehler beim Laden der JSON-Datei: $($_.Exception.Message)"
    }
    
    do {
        Write-Host "`n" -ForegroundColor White
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "         WSUS PRODUKTVERWALTUNG         " -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1. Abzulehnende Produkte anzeigen" -ForegroundColor White
        Write-Host "2. Erlaubte Produkte anzeigen" -ForegroundColor White
        Write-Host "3. Statistiken anzeigen" -ForegroundColor White
        Write-Host "4. Alle veralteten Updates ablehnen" -ForegroundColor Red
        Write-Host "5. Alle Preview/Beta/Insider Updates ablehnen" -ForegroundColor Yellow
        Write-Host "6. Alle ersetzten/abgelösten Updates ablehnen" -ForegroundColor Magenta
        Write-Host ""
        Write-Host "9. KOMPLETT-BEREINIGUNG (Alle oben genannten)" -ForegroundColor DarkRed
        Write-Host ""
        Write-Host "0. Beenden" -ForegroundColor Gray
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        
        $UserChoice = Read-Host "Bitte wählen Sie eine Option"
        
        switch ($UserChoice) {
            "1" {
                Clear-Host
                Write-Host "`n========================================" -ForegroundColor Cyan
                Write-Host "  ABZULEHNENDE PRODUKTE" -ForegroundColor Cyan
                Write-Host "  Konfiguration gem.  $JsonPath" -Foregroundcolor Gray
                Write-Host "========================================`n" -ForegroundColor Cyan
                
                foreach ($category in $JsonContent.declined_updates) {
                    Write-Host "  $($category.name) - Anzahl Produkte: $($category.products.Count)" -ForegroundColor White
                    Write-Host "  - Beschreibung: $($category.description)" -ForegroundColor Gray
                    Write-Host "  - Grund: $($category.reason)" -ForegroundColor Gray
                    Write-Host ""
                    
                    if ($EnableFileLogging) {
                        Write-WSUSLogFile "Anzeige abzulehnende Kategorie: $($category.name) | Produkte: $($category.products.Count)"
                    }
                }
                
                $TotalDeclinedProducts = ($JsonContent.declined_updates | ForEach-Object { $_.products.Count } | Measure-Object -Sum).Sum
                Write-Host ""
                Write-Host "Gesamt abzulehnende Kategorien: $($JsonContent.declined_updates.Count)" -ForegroundColor red
                Write-Host "Gesamt abzulehnende Produkte: $TotalDeclinedProducts" -ForegroundColor red
                
                Write-Host "`nDrücken Sie Enter um fortzufahren..." -ForegroundColor Gray
                Read-Host
            }
            
            "2" {
                Clear-Host
                Write-Host "`n========================================" -ForegroundColor Cyan
                Write-Host "  ERLAUBTE PRODUKTE" -ForegroundColor Cyan
                Write-Host "  Konfiguration gem.  $JsonPath" -Foregroundcolor Gray
                Write-Host "========================================`n" -ForegroundColor Cyan
                
                foreach ($category in $JsonContent.approved_updates) {
                    Write-Host "  $($category.name) - Anzahl Produkte: $($category.products.Count)" -ForegroundColor White
                    Write-Host "  - Beschreibung: $($category.description)" -ForegroundColor Gray
                    Write-Host "  - Grund: $($category.reason)" -ForegroundColor Gray
                    Write-Host ""
                    
                    if ($EnableFileLogging) {
                        Write-WSUSLogFile "Anzeige erlaubte Kategorie: $($category.name) | Produkte: $($category.products.Count)"
                    }
                }
                
                $TotalApprovedProducts = ($JsonContent.approved_updates | ForEach-Object { $_.products.Count } | Measure-Object -Sum).Sum
                Write-Host ""
                Write-Host "Gesamt erlaubte Kategorien: $($JsonContent.approved_updates.Count)" -ForegroundColor Green
                Write-Host "Gesamt erlaubte Produkte: $TotalApprovedProducts" -ForegroundColor Green
                
                Write-Host "`nDrücken Sie Enter um fortzufahren..." -ForegroundColor Gray
                Read-Host
            }

            "3" {
                Clear-Host
                Write-Host "`n========================================" -ForegroundColor Cyan
                Write-Host "  STATISTIKEN" -ForegroundColor Cyan
                Write-Host "  Konfiguration gem.  $JsonPath" -Foregroundcolor Gray
                Write-Host "========================================`n" -ForegroundColor Cyan
                
                $TotalDeclinedCategories = $JsonContent.declined_updates.Count
                $TotalApprovedCategories = $JsonContent.approved_updates.Count
                $TotalDeclinedProducts = ($JsonContent.declined_updates | ForEach-Object { $_.products.Count } | Measure-Object -Sum).Sum
                $TotalApprovedProducts = ($JsonContent.approved_updates | ForEach-Object { $_.products.Count } | Measure-Object -Sum).Sum
                
                Write-Host "  KONFIGURATIONSÜBERSICHT" -ForegroundColor White
                Write-Host "  * Version: $($JsonContent.metadata.version)" -ForegroundColor Gray
                Write-Host "  * Letzte Aktualisierung: $($JsonContent.metadata.lastUpdated)" -ForegroundColor Gray
                Write-Host "  * Autor: $($JsonContent.metadata.author)`n" -ForegroundColor Gray
                
                Write-Host "  KATEGORIEN" -ForegroundColor White
                Write-Host "  * Abzulehnende Kategorien: $TotalDeclinedCategories" -ForegroundColor Gray
                Write-Host "  * Erlaubte Kategorien: $TotalApprovedCategories`n" -ForegroundColor Gray
                
                Write-Host "  PRODUKTE" -ForegroundColor White
                Write-Host "  * Abzulehnende Produkte: $TotalDeclinedProducts" -ForegroundColor Gray
                Write-Host "  * Erlaubte Produkte: $TotalApprovedProducts" -ForegroundColor Gray
                Write-Host "  * Gesamt definierte Produkte: $($TotalDeclinedProducts + $TotalApprovedProducts)" -ForegroundColor Gray
                
                Write-Host "  `nDrücken Sie Enter um fortzufahren..." -ForegroundColor Gray
                Read-Host
            }
            
            "4" {
                Clear-Host
                Write-Host "`n========================================" -ForegroundColor Red
                Write-Host "  VERALTETE UPDATES ABLEHNEN" -ForegroundColor Red
                Write-Host "========================================`n" -ForegroundColor Red
                
                Write-Host "WARNUNG: Diese Aktion lehnt ALLE Updates für die in der" -ForegroundColor Yellow
                Write-Host "JSON-Konfiguration definierten veralteten Produkte ab!" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "Es werden SOFORT alle gefundenen Updates abgelehnt!" -ForegroundColor Red
                Write-Host ""
                
                $Confirmation = Read-Host "Möchten Sie ALLE veralteten Updates ablehnen? (J/N)"
                
                if ($Confirmation -eq "J" -or $Confirmation -eq "j" -or $Confirmation -eq "Y" -or $Confirmation -eq "y") {
                    Write-Host ""
                    Write-Host "Starte Ablehnung ALLER veralteten Updates..." -ForegroundColor Yellow
                    
                    if ($EnableFileLogging) {
                        Write-WSUSLogFile "BENUTZERAKTION: Start Ablehnung ALLER veralteten Updates"
                    }
                    
                    try {
                        Invoke-DeclineUpdatesFromConfig -WSUSServer $script:WSUSServer -JsonContent $JsonContent -EnableFileLogging:$EnableFileLogging
                        Write-Host "`nALLE veralteten Updates erfolgreich abgelehnt!" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "`nFehler beim Ablehnen der Updates: $($_.Exception.Message)" -ForegroundColor Red
                        
                        if ($EnableFileLogging) {
                            Write-WSUSLogFile "FEHLER beim Ablehnen veralteter Updates: $($_.Exception.Message)"
                        }
                    }
                } else {
                    Write-Host "Vorgang abgebrochen." -ForegroundColor Yellow
                    
                    if ($EnableFileLogging) {
                        Write-WSUSLogFile "BENUTZERAKTION: Ablehnung veralteter Updates abgebrochen"
                    }
                }
                
                Write-Host "`nDrücken Sie Enter um fortzufahren..." -ForegroundColor Gray
                Read-Host
            }
            
            "5" {
                Clear-Host
                Write-Host "`n========================================" -ForegroundColor Yellow
                Write-Host "  PREVIEW/BETA/INSIDER UPDATES ABLEHNEN" -ForegroundColor Yellow
                Write-Host "========================================`n" -ForegroundColor Yellow
                
                Write-Host "WARNUNG: Diese Aktion sucht nach ALLEN Updates die" -ForegroundColor Yellow
                Write-Host "Beta-, Preview-, Insider- oder ähnliche Begriffe enthalten" -ForegroundColor Yellow
                Write-Host "und lehnt diese SOFORT ab!" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "Suchbegriffe:" -ForegroundColor White
                Write-Host "  - Beta, Preview, Insider, Pre-Release" -ForegroundColor Gray
                Write-Host "  - Release Candidate (RC), Alpha, Development" -ForegroundColor Gray
                Write-Host "  - Test, Experimental, Canary, Nightly" -ForegroundColor Gray
                Write-Host ""
                Write-Host "Diese Updates sind nicht für Produktionsumgebungen geeignet!" -ForegroundColor Red
                Write-Host ""
                
                $Confirmation = Read-Host "Möchten Sie ALLE Preview/Beta/Insider-Updates ablehnen? (J/N)"
                
                if ($Confirmation -eq "J" -or $Confirmation -eq "j" -or $Confirmation -eq "Y" -or $Confirmation -eq "y") {
                    Write-Host ""
                    Write-Host "Starte Suche und Ablehnung ALLER Preview/Beta/Insider-Updates..." -ForegroundColor Yellow
                    Write-Host "HINWEIS: Dies kann einige Minuten dauern..." -ForegroundColor Gray
                    
                    if ($EnableFileLogging) {
                        Write-WSUSLogFile "BENUTZERAKTION: Start Ablehnung ALLER Preview/Beta/Insider-Updates"
                    }
                    
                    try {
                        Invoke-DeclineBetaPreviewUpdates -WSUSServer $script:WSUSServer -EnableFileLogging:$EnableFileLogging
                        Write-Host "`nALLE Preview/Beta/Insider-Updates erfolgreich abgelehnt!" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "`nFehler beim Ablehnen der Updates: $($_.Exception.Message)" -ForegroundColor Red
                        
                        if ($EnableFileLogging) {
                            Write-WSUSLogFile "FEHLER beim Ablehnen von Preview/Beta/Insider-Updates: $($_.Exception.Message)"
                        }
                    }
                } else {
                    Write-Host "Vorgang abgebrochen." -ForegroundColor Yellow
                    
                    if ($EnableFileLogging) {
                        Write-WSUSLogFile "BENUTZERAKTION: Ablehnung Preview/Beta/Insider-Updates abgebrochen"
                    }
                }
                
                Write-Host "`nDrücken Sie Enter um fortzufahren..." -ForegroundColor Gray
                Read-Host
            }
            
            "6" {
                Clear-Host
                Write-Host "`n========================================" -ForegroundColor Magenta
                Write-Host "  ERSETZTE/ABGELÖSTE UPDATES ABLEHNEN" -ForegroundColor Magenta
                Write-Host "========================================`n" -ForegroundColor Magenta
                
                Write-Host "Diese Aktion sucht nach ALLEN Updates die durch neuere" -ForegroundColor Yellow
                Write-Host "Versionen ersetzt/abgelöst (superseded) wurden und lehnt" -ForegroundColor Yellow
                Write-Host "diese SOFORT ab!" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "Vorteile:" -ForegroundColor White
                Write-Host "  - Verbesserte WSUS-Performance" -ForegroundColor Gray
                Write-Host "  - Reduzierter Speicherbedarf" -ForegroundColor Gray
                Write-Host "  - Aufräumen veralteter Updates" -ForegroundColor Gray
                Write-Host ""
                Write-Host "Ersetzte Updates sind sicher zu entfernen!" -ForegroundColor Green
                Write-Host ""
                
                $Confirmation = Read-Host "Möchten Sie ALLE ersetzten/abgelösten Updates ablehnen? (J/N)"
                
                if ($Confirmation -eq "J" -or $Confirmation -eq "j" -or $Confirmation -eq "Y" -or $Confirmation -eq "y") {
                    Write-Host ""
                    Write-Host "Starte Suche und Ablehnung ALLER ersetzten/abgelösten Updates..." -ForegroundColor Yellow
                    Write-Host "HINWEIS: Dies kann einige Minuten dauern..." -ForegroundColor Gray
                    
                    if ($EnableFileLogging) {
                        Write-WSUSLogFile "BENUTZERAKTION: Start Ablehnung ALLER ersetzten/abgelösten Updates"
                    }
                    
                    try {
                        Invoke-DeclineSupersededUpdates -WSUSServer $script:WSUSServer -EnableFileLogging:$EnableFileLogging
                        Write-Host "`nALLE ersetzten/abgelösten Updates erfolgreich abgelehnt!" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "`nFehler beim Ablehnen der Updates: $($_.Exception.Message)" -ForegroundColor Red
                        
                        if ($EnableFileLogging) {
                            Write-WSUSLogFile "FEHLER beim Ablehnen von ersetzten Updates: $($_.Exception.Message)"
                        }
                    }
                } else {
                    Write-Host "Vorgang abgebrochen." -ForegroundColor Yellow
                    
                    if ($EnableFileLogging) {
                        Write-WSUSLogFile "BENUTZERAKTION: Ablehnung ersetzter Updates abgebrochen"
                    }
                }
                
                Write-Host "`nDrücken Sie Enter um fortzufahren..." -ForegroundColor Gray
                Read-Host
            }

            "9" {
                Clear-Host
                Write-Host "`n========================================" -ForegroundColor DarkRed
                Write-Host "       KOMPLETT-BEREINIGUNG" -ForegroundColor DarkRed
                Write-Host "========================================`n" -ForegroundColor DarkRed
                
                Write-Host "WARNUNG: Diese Aktion führt ALLE Bereinigungsschritte" -ForegroundColor Red
                Write-Host "nacheinander aus:" -ForegroundColor Red
                Write-Host ""
                Write-Host "1. Veraltete Updates (aus JSON-Konfiguration)" -ForegroundColor Yellow
                Write-Host "2. Preview/Beta/Insider Updates" -ForegroundColor Yellow
                Write-Host "3. Ersetzte/abgelöste Updates" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "Dies ist die umfassendste WSUS-Bereinigung!" -ForegroundColor Red
                Write-Host ""
                
                $Confirmation = Read-Host "Möchten Sie die KOMPLETT-BEREINIGUNG starten? (J/N)"
                
                if ($Confirmation -eq "J" -or $Confirmation -eq "j" -or $Confirmation -eq "Y" -or $Confirmation -eq "y") {
                    Write-Host ""
                    Write-Host "Starte KOMPLETT-BEREINIGUNG..." -ForegroundColor Red
                    Write-Host "HINWEIS: Dies kann längere Zeit dauern..." -ForegroundColor Gray
                    
                    if ($EnableFileLogging) {
                        Write-WSUSLogFile "BENUTZERAKTION: Start KOMPLETT-BEREINIGUNG"
                    }
                    
                    $TotalErrors = 0
                    
                    Write-Host "`n=== SCHRITT 1: VERALTETE UPDATES ===" -ForegroundColor Yellow
                    try {
                        Invoke-DeclineUpdatesFromConfig -WSUSServer $script:WSUSServer -JsonContent $JsonContent -EnableFileLogging:$EnableFileLogging
                        Write-Host "Schritt 1 abgeschlossen!" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "FEHLER in Schritt 1: $($_.Exception.Message)" -ForegroundColor Red
                        $TotalErrors++
                        
                        if ($EnableFileLogging) {
                            Write-WSUSLogFile "FEHLER Schritt 1 (veraltete Updates): $($_.Exception.Message)"
                        }
                    }
                    
                    Write-Host "`n=== SCHRITT 2: BETA/PREVIEW UPDATES ===" -ForegroundColor Yellow
                    try {
                        Invoke-DeclineBetaPreviewUpdates -WSUSServer $script:WSUSServer -EnableFileLogging:$EnableFileLogging
                        Write-Host "Schritt 2 abgeschlossen!" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "FEHLER in Schritt 2: $($_.Exception.Message)" -ForegroundColor Red
                        $TotalErrors++
                        
                        if ($EnableFileLogging) {
                            Write-WSUSLogFile "FEHLER Schritt 2 (Beta/Preview): $($_.Exception.Message)"
                        }
                    }
                    
                    Write-Host "`n=== SCHRITT 3: ERSETZTE UPDATES ===" -ForegroundColor Yellow
                    try {
                        Invoke-DeclineSupersededUpdates -WSUSServer $script:WSUSServer -EnableFileLogging:$EnableFileLogging
                        Write-Host "Schritt 3 abgeschlossen!" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "FEHLER in Schritt 3: $($_.Exception.Message)" -ForegroundColor Red
                        $TotalErrors++
                        
                        if ($EnableFileLogging) {
                            Write-WSUSLogFile "FEHLER Schritt 3 (ersetzte Updates): $($_.Exception.Message)"
                        }
                    }
                    
                    Write-Host "`n========================================" -ForegroundColor DarkRed
                    Write-Host "KOMPLETT-BEREINIGUNG ABGESCHLOSSEN" -ForegroundColor DarkRed
                    Write-Host "========================================" -ForegroundColor DarkRed
                    
                    if ($TotalErrors -eq 0) {
                        Write-Host "ALLE Schritte erfolgreich abgeschlossen!" -ForegroundColor Green
                    } else {
                        Write-Host "Abgeschlossen mit $TotalErrors Fehlern!" -ForegroundColor Red
                    }
                    
                    if ($EnableFileLogging) {
                        Write-WSUSLogFile "KOMPLETT-BEREINIGUNG abgeschlossen - Fehler: $TotalErrors"
                    }
                    
                } else {
                    Write-Host "KOMPLETT-BEREINIGUNG abgebrochen." -ForegroundColor Yellow
                    
                    if ($EnableFileLogging) {
                        Write-WSUSLogFile "BENUTZERAKTION: KOMPLETT-BEREINIGUNG abgebrochen"
                    }
                }
                
                Write-Host "`nDrücken Sie Enter um fortzufahren..." -ForegroundColor Gray
                Read-Host
            }
            
            "0" {
                Write-Host "`nProgramm wird beendet..." -ForegroundColor Yellow
                Write-WSUSLog "Benutzer hat das Programm beendet" -Status INFO
            }
            
            default {
                Write-Host "`nUngültige Auswahl. Bitte versuchen Sie es erneut." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
        
    } while ($UserChoice -ne "0")
    
}
catch {
    Write-WSUSLog "Kritischer Fehler: $($_.Exception.Message)" -Status ERROR
    
    if ($EnableFileLogging) {
        Write-WSUSLogFile "FEHLER: $($_.Exception.Message)"
    }
    
    Write-WSUSLog "Stacktrace:" -Status ERROR
    Write-WSUSLog $_.ScriptStackTrace -Status ERROR
    
    exit 1
}
finally {
    $EndTime = Get-Date
    $Duration = $EndTime - $script:StartTime
    
    Write-WSUSLog "Script beendet" -Status INFO
    Write-WSUSLog "Laufzeit: $($Duration.ToString('hh\:mm\:ss'))" -Status INFO

    if ($EnableFileLogging) {
        Write-WSUSLogFile "Script beendet - Laufzeit: $($Duration.ToString('hh\:mm\:ss'))"
    }
}
#endregion
