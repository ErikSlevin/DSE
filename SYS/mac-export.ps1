#Requires -Modules ActiveDirectory

<#
.SYNOPSIS
    Sammelt MAC- und IP-Adressen aller Server aus Active Directory
.DESCRIPTION
    Exportiert Netzwerkinformationen aller Server (außer HOST-Systemen) in CSV-Datei
#>

Param(
    [string]$OutputPath = „C:\SOURCEN\MAC_Adress_MGMT.csv“
)

# Server aus AD laden
Write-Host „Lade Server aus Active Directory…“
$servers = (Get-ADComputer -Filter {OperatingSystem -like "*Server*" -and Name -notlike "*HOST"}).Name

Write-Host „$($servers.Count) Server gefunden“

# Datensammlung
$inventory = [System.Collections.Generic.List[PSObject]]::new()

Foreach ($server in $servers) {  
    Try {
       
        # Aktive Netzwerkadapter abrufen
        $adapters = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -ComputerName $server | Where-Object -Property ServiceName -eq "netvsc"
        $PC = (Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $server)
        $ram = ((($PC).TotalPhysicalMemory / 1024)/1024)/1024
        $ram = [Math]::Round($ram,2)
        $FQDN = "$($PC.Name).$($PC.Domain)"
        Foreach ($adapter in $adapters) {
            # Erste IPv4-Adresse verwenden
            $primaryIP = $adapter.IPAddress | Where-Object { $_ -match ‚^\d+\.\d+\.\d+\.\d+$‘ } | Select-Object -First 1
                
            $inventory.Add([PSCustomObject]@{
                ‚Server‘      = $server
                ‚FQDN‘        = $FQDN
                ‚MACAdresse‘  = $adapter.MACAddress
                ‚IPAdresse‘   = $primaryIP
                ‚RAM‘         = $ram.ToString() + "GB"
            })
        }
    } catch {
        Write-Host „ ✗ (Fehler)“ -ForegroundColor Red
    }
}

# CSV Export
If ($inventory.Count -gt 0) {
    # Ausgabeverzeichnis erstellen falls nötig
    $outputDir = Split-Path -Path $OutputPath -Parent
    If (-not (Test-Path $outputDir)) { 
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null 
    }
    
    # Exportieren
    $inventory | Export-Csv -Path $OutputPath -Delimiter „;“ -NoTypeInformation -Encoding UTF8
    
    Write-Host „`n$($inventory.Count) Einträge exportiert nach: $OutputPath“ -ForegroundColor Green
    
    # Vorschau
    $inventory | Format-Table -AutoSize
} else {
    Write-Warning „Keine Daten gefunden!“
}
