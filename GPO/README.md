# GPO Tools

Eine Sammlung von PowerShell-Tools für das effiziente Exportieren und Importieren von Group Policy Objects (GPOs) in Windows-Domänenumgebungen.


## Inhaltsverzeichnis

- **[GPO-Export.ps1](#gpo-exportps1)**
  - [Verwendung](#verwendung)
- **[GPO-Import.ps1](#gpo-importps1)**
  - [Verwendung](#verwendung-1)

 ## GPO-Export.ps1
> Stand: 30.06.2025

### Funktionen
- **Export** von GPOs aus der aktuellen Domäne in ein Backup-Verzeichnis
- **Mehrfach-Auswahl von GPOs** (z.B. `1-6, 9, 10, 14-22`) für effiziente Massenbearbeitung
- **Strukturierte Backups** mit detailliertem Logging und Metadaten
- **Parameter-Support** für automatisierte Ausführung in Cronjobs 

### Verwendung
Powershell auf einer PROD/MGMT-PAW ausführen

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


> [!CAUTION]
> Muss als $\color{red}{\textsf{T0-Administrator}}$ ausgeführt werden

### Funktionen
- **Import in Domänenfremder GPOs** aus einem Backupverzeichniss 
  - Prod-Domain `->` MGMT Domain 
  - Prod-Domain-Übung-1 `->` Prod-Domain-Einsatz-1
- **Analyse von Backup-Verzeichnissen** mit automatischer Metadaten-Extraktion
- **Interaktive Auswahl** der zu importierenden GPOs
- **Mehrfach-Auswahl von GPOs** (z.B. `1-6, 9, 10, 14-22`) für effiziente Massenbearbeitung
- **Parameter-Support** für automatisierte Ausführung in Cronjobs 

### Verwendung

Powershell als **T0-Admin** ausführen auf einer PROD/MGMT-PAW

```powershell
# Komplett interaktiver Modus
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