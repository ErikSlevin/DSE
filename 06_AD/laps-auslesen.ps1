function laps {
    Clear-Host
    Write-Host -ForegroundColor yellow "`n`nLAPS-Passwort Computer Auswahl" 
    $computers = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name
    $computersObjects = @()
    
    for ($i = 0; $i -lt $computers.Count; $i++) {
        
        $funktion = "Unbekannt"
        $tier = "------------"
        
        if (($computers[$i]).Length -eq 15) {
            $char = $computers[$i].Substring(7,2)
            switch ($char) {
                "DC" {$funktion = "DC"}
                "SF" {$funktion = "File"}
                "SU" {$funktion = "WSUS"}
                "LC" {$funktion = "LanCrypt"}
                "SP" {$funktion = "Print"}
                "SI" {$funktion = "DHCP"}
                "ID" {$funktion = "WDS"}
                "SW" {$funktion = "WEB"}
                "IW" {$funktion = "ITWatch"}
                "SV" {$funktion = "Antivir"}
            }
            
            # Tier-Zuweisung basierend auf dem gleichen $char
            switch ($char) {
                {$_ -in "SF","SU","LC","SP","SI","ID","SW","IW","SV"} { $tier = "LA_T1_MGMNT"}
                "DC" { $tier = "LA_T0_MGMNT"}
            }
        } elseif ($computers[$i] -match "PAW\d{2}") {
            $funktion = "PAW"
            $tier = "LA_PAW_MGMNT"  # PAW-Computer bekommen eigenen Tier
        }
        
        $computersObjects += New-Object PSObject -Property @{
            Nr = $i + 1  # +1 f?r benutzerfreundliche Nummerierung
            Funktion = $funktion
            Name = $computers[$i]
            LocalAdmin = $tier
        }
    }
    
    # Sortieren und anzeigen
    $computersObjects = $computersObjects | Sort-Object -Property Nr
    $computersObjects | Format-Table -Property Nr, Name, LocalAdmin, Funktion -AutoSize
    
    $auswahl = Read-Host "Auswahl"
    $selectedcomputer = $computersObjects[[int]$auswahl - 1]  # -1 wegen Array-Index
    
    $pw = (Get-LapsADPassword $selectedcomputer.Name -AsPlainText).Password
    Write-Host "`n    Computer: $($selectedcomputer.Name)"
    Write-Host "    Funktion: $($selectedcomputer.Funktion)"
    Write-Host "        User: " -NoNewLine
    Write-Host -ForegroundColor yellow -BackgroundColor Black "    $($selectedcomputer.LocalAdmin)    "
    Write-Host "    Passwort: " -NoNewLine
    Write-Host -ForegroundColor yellow -BackgroundColor Black "    $($pw)    `n`n"
}
