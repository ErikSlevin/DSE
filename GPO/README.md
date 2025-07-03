# GPO Tools

Eine Sammlung von PowerShell-Tools für das effiziente Exportieren und Importieren von Group Policy Objects (GPOs) in Windows-Domänenumgebungen.

 ## GPO-Export.ps1
> Stand: 30.06.2025

### Funktionen
- **Export** von GPOs aus der aktuellen Domäne
- **Mehrfach-Auswahl von GPOs** (z.B. `1-6, 9, 10, 14-22`) für effiziente Massenbearbeitung
- **Strukturierte Backups** mit detailliertem Logging und Metadaten
- **Parameter-Support** für automatisierte Ausführung in Cronjobs 

### Verwendung
``` Powershell 
# Interaktiver Modus
.\GPO-Export.ps1

# Export mit Parametern
.\GPO-Export.ps1 -GpoNames "Default Domain Policy,Custom Policy" -BackupPath "C:\GPO-Backups"

# Stiller Export
.\GPO-Export.ps1 -GpoNames "Policy1,Policy2" -BackupPath "C:\Backups" -Mode Silent
```

### Parameter
- **`-GpoNames`**: Kommaseparierte Liste der zu exportierenden GPO-Namen
- **`-BackupPath`**: Zielpfad für die GPO-Backups
- **`-Mode`**: Ausführungsmodus (`Interactive` oder `Silent`)

## Ausgabe-Struktur

``` 
| Backup-Verzeichnis/
├── {GUID}/
│   ├── Backup.xml
│   ├── DomainSysvol/
│   └── gpreport.xml
├── GPO-Export-Metadata.log
└── GPO-Import-Log.log
```

--- 

# GPO-Import.ps1
> _Stand: 30.06.2025_

> [!IMPORTANT]  
> Muss als T0-Administrator ausgeführt werden

### Funktionen
- **Import in Domänenfremder GPOs** aus einem Backupverzeichniss 
  - Prod-Domain `->` MGMT Domain 
  - Prod-Domain-Übung-1 `->` Prod-Domain-Einsatz-1
- **Analyse von Backup-Verzeichnissen** mit automatischer Metadaten-Extraktion
- **Interaktive Auswahl** der zu importierenden GPOs
- **Mehrfach-Auswahl von GPOs** (z.B. `1-6, 9, 10, 14-22`) für effiziente Massenbearbeitung
- **Parameter-Support** für automatisierte Ausführung in Cronjobs 
- 
### Verwendung

#### Komplett interaktiver Modus
```powershell
.\GPO-Import.ps1

# Import mit Pfad-Vorgabe
.\GPO-Import.ps1 -ImportPath "C:\GPO-Backups"

# Import mit spezifischen GPOs
.\GPO-Import.ps1 -ImportPath "C:\GPO-Backups" -GpoNames "Policy1,Policy2" -TargetDomain "domain.local"
```

### Parameter
- **`-ImportPath`**: Pfad zu den GPO-Backup-Verzeichnissen
- **`-GpoNames`**: Kommaseparierte Liste der zu importierenden GPO-Namen
- **`-Mode`**: Ausführungsmodus (`Interactive` oder `Silent`)
- **`-TargetDomain`**: Zieldomäne für den Import