#region LAPS Password Tool
<#
.SYNOPSIS
    LAPS-Passwort Computer Auswahl Tool
    
.DESCRIPTION
    Dieses Script zeigt alle Computer aus dem Active Directory an und ermöglicht
    die Auswahl eines Computers zur Anzeige des LAPS-Passworts.
    
.NOTES
    Version: 2.0
    Aufruf: laps
    
.REQUIREMENTS
    - Active Directory PowerShell Module
    - LAPS PowerShell Module
    - Berechtigung zum Lesen von LAPS-Passwörtern
#>

<#
.SYNOPSIS
    Ermittelt die Funktion eines Computers basierend auf seinem Namen
#>
function Get-ComputerFunction {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )
    
    # Prüfung auf PAW-Computer (Pattern: PAW + 2 Ziffern)
    if ($ComputerName -match "PAW\d{2}") {
        return "PAW"
    }
    
    # Prüfung auf Standardnamen mit 15 Zeichen
    if ($ComputerName.Length -eq 15) {
        $functionCode = $ComputerName.Substring(7, 2)
        
        # Mapping der Funktionscodes zu Funktionsnamen
        $functionMapping = @{
            "DC" = "DC"
            "SF" = "File"
            "SU" = "WSUS"
            "LC" = "LanCrypt"
            "SP" = "Print"
            "SI" = "DHCP"
            "ID" = "WDS"
            "SW" = "WEB"
            "IW" = "ITWatch"
            "SV" = "Antivir"
        }
        
        if ($functionMapping.ContainsKey($functionCode)) {
            return $functionMapping[$functionCode]
        }
    }
    
    return "Unbekannt"
}

<#
.SYNOPSIS
    Ermittelt den Tier/LocalAdmin-Bereich eines Computers
#>
function Get-ComputerTier {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )
    
    # PAW-Computer erhalten eigenen Tier
    if ($ComputerName -match "PAW\d{2}") {
        return "LA_PAW_MGMNT"
    }
    
    # Standardnamen mit 15 Zeichen
    if ($ComputerName.Length -eq 15) {
        $functionCode = $ComputerName.Substring(7, 2)
        
        # Tier-Zuordnung basierend auf Funktionscode
        switch ($functionCode) {
            "DC" { 
                return "LA_T0_MGMNT" 
            }
            { $_ -in "SF", "SU", "LC", "SP", "SI", "ID", "SW", "IW", "SV" } { 
                return "LA_T1_MGMNT" 
            }
        }
    }
    
    return "------------"
}

<#
.SYNOPSIS
    Erstellt ein Computer-Objekt mit allen relevanten Eigenschaften
#>
function New-ComputerObject {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,
        
        [Parameter(Mandatory = $true)]
        [int]$Index
    )
    
    return [PSCustomObject]@{
        Nr = $Index + 1  # Benutzerfreundliche Nummerierung (1-basiert)
        Name = $ComputerName
        Funktion = Get-ComputerFunction -ComputerName $ComputerName
        LocalAdmin = Get-ComputerTier -ComputerName $ComputerName
    }
}

<#
.SYNOPSIS
    Lädt alle Computer aus dem Active Directory und erstellt Computer-Objekte
#>
function Get-AllComputerObjects {
    Write-Verbose "Lade Computer aus Active Directory..."
    
    try {
        # Alle Computer aus AD laden (nur Namen)
        $computerNames = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name
        
        $computerObjects = @()
        
        # Computer-Objekte erstellen
        for ($i = 0; $i -lt $computerNames.Count; $i++) {
            $computerObjects += New-ComputerObject -ComputerName $computerNames[$i] -Index $i
        }
        
        # Nach Nummer sortiert zurückgeben
        return $computerObjects | Sort-Object -Property Nr
    }
    catch {
        Write-Error "Fehler beim Laden der Computer: $($_.Exception.Message)"
        return $null
    }
}

<#
.SYNOPSIS
    Zeigt die Computer-Liste in tabellarischer Form an
#>
function Show-ComputerSelection {
    param(
        [Parameter(Mandatory = $true)]
        [Array]$ComputerObjects
    )
    
    Write-Host -ForegroundColor Yellow "`n`nLAPS-Passwort Computer Auswahl"
    $ComputerObjects | Format-Table -Property Nr, Name, LocalAdmin, Funktion -AutoSize
}

<#
.SYNOPSIS
    Holt die Benutzerauswahl und validiert sie
#>
function Get-UserSelection {
    param(
        [Parameter(Mandatory = $true)]
        [Array]$ComputerObjects
    )
    
    do {
        $selection = Read-Host "Auswahl"
        
        # Eingabe validieren
        if ([int]::TryParse($selection, [ref]$null)) {
            $selectionInt = [int]$selection
            if ($selectionInt -ge 1 -and $selectionInt -le $ComputerObjects.Count) {
                return $ComputerObjects[$selectionInt - 1]  # Array ist 0-basiert
            }
        }
        
        Write-Warning "Ungültige Auswahl. Bitte wählen Sie eine Nummer zwischen 1 und $($ComputerObjects.Count)."
    } while ($true)
}

<#
.SYNOPSIS
    Zeigt die LAPS-Informationen für den ausgewählten Computer an
#>
function Show-LapsInformation {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$SelectedComputer
    )
    
    try {
        Write-Verbose "Lade LAPS-Passwort für Computer: $($SelectedComputer.Name)"
        
        # LAPS-Passwort abrufen
        $lapsPassword = (Get-LapsADPassword $SelectedComputer.Name -AsPlainText).Password
        
        # Formatierte Ausgabe
        Write-Host "`n    Computer: $($SelectedComputer.Name)"
        Write-Host "    Funktion: $($SelectedComputer.Funktion)"
        Write-Host "        User: " -NoNewLine
        Write-Host -ForegroundColor Yellow -BackgroundColor Black "    $($SelectedComputer.LocalAdmin)    "
        Write-Host "    Passwort: " -NoNewLine
        Write-Host -ForegroundColor Yellow -BackgroundColor Black "    $($lapsPassword)    `n`n"
    }
    catch {
        Write-Error "Fehler beim Abrufen des LAPS-Passworts für '$($SelectedComputer.Name)': $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Hauptfunktion des LAPS Password Tools
#>
function Invoke-LapsPasswordSelection {
    try {
        # Bildschirm leeren
        Clear-Host
        
        # Computer aus AD laden
        $computerObjects = Get-AllComputerObjects
        
        if ($null -eq $computerObjects -or $computerObjects.Count -eq 0) {
            Write-Warning "Keine Computer gefunden oder Fehler beim Laden."
            return
        }
        
        # Computer-Auswahl anzeigen
        Show-ComputerSelection -ComputerObjects $computerObjects
        
        # Benutzerauswahl einholen
        $selectedComputer = Get-UserSelection -ComputerObjects $computerObjects
        
        # LAPS-Informationen anzeigen
        Show-LapsInformation -SelectedComputer $selectedComputer
    }
    catch {
        Write-Error "Unerwarteter Fehler: $($_.Exception.Message)"
    }
}

# Alias für einfachen Aufruf erstellen
Set-Alias -Name "laps" -Value "Invoke-LapsPasswordSelection" -Description "LAPS Password Selection Tool"
Set-Alias -Name "LAPS" -Value "Invoke-LapsPasswordSelection" -Description "LAPS Password Selection Tool"

#endregion