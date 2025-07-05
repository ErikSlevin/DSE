# DSE - Domain Systems & Enterprise Tools

Eine umfassende Sammlung von PowerShell-Tools für die effiziente Verwaltung von Windows-Domänenumgebungen und Enterprise-Systemen.

> **Letztes Update:** 05.07.2025
> **Gesamtanzahl Scripts:** 8
> **Kategorien:** 5

## Inhaltsverzeichnis

| Kategorie | Beschreibung | Scripts | Dokumentation |
|-----------|--------------|---------|---------------|
| **[01_HYPER-V](01_HYPER-V/)** | Eine Sammlung von PowerShell-Tools für die effiziente Verwaltung von Hyper-V-Umgebungen und virtuellen Maschinen. | 2 | [README](01_HYPER-V/README.md) |
| **[02_GPO](02_GPO/)** | Eine Sammlung von PowerShell-Tools für das effiziente Exportieren und Importieren von Group Policy Objects (GPOs) in Windows-Domänenumgebungen. | 2 | [README](02_GPO/README.md) |
| **[03_SYS](03_SYS/)** | Eine Sammlung von PowerShell-Tools für die effiziente Systemverwaltung und Inventarisierung in Windows-Domänenumgebungen. | 1 | [README](03_SYS/README.md) |
| **[04_WSUS](04_WSUS/)** | Keine Beschreibung verfügbar | 2 | Keine |
| **[05_WDS](05_WDS/)** | Eine Sammlung von PowerShell-Tools für die effiziente Verwaltung von Windows Deployment Services (WDS) und Image-Konvertierung. | 1 | [README](05_WDS/README.md) |

## Schnellstart

### Voraussetzungen
- PowerShell 5.1 oder höher
- Entsprechende Administratorrechte je nach Tool
- Windows-Domänenumgebung (für die meisten Tools)

### Verwendung
1. Repository klonen oder einzelne Scripts herunterladen
2. PowerShell als Administrator öffnen
3. Zum gewünschten Verzeichnis navigieren
4. Script mit entsprechenden Parametern ausführen

## Kategorien im Detail

### 01_HYPER-V
**[Zur vollständigen Dokumentation](01_HYPER-V/README.md)**

Eine Sammlung von PowerShell-Tools für die effiziente Verwaltung von Hyper-V-Umgebungen und virtuellen Maschinen.

- **Anzahl Scripts:** 2
- **Verfügbare Scripts:**
  - `Hyper-V-IPsec-On.ps1`
  - `Hyper-V-Mount-ISOs.ps1`

### 02_GPO
**[Zur vollständigen Dokumentation](02_GPO/README.md)**

Eine Sammlung von PowerShell-Tools für das effiziente Exportieren und Importieren von Group Policy Objects (GPOs) in Windows-Domänenumgebungen.

- **Anzahl Scripts:** 2
- **Verfügbare Scripts:**
  - `GPO-Export.ps1`
  - `GPO-Import.ps1`

### 03_SYS
**[Zur vollständigen Dokumentation](03_SYS/README.md)**

Eine Sammlung von PowerShell-Tools für die effiziente Systemverwaltung und Inventarisierung in Windows-Domänenumgebungen.

- **Anzahl Scripts:** 1
- **Verfügbare Scripts:**
  - `mac-export.ps1`

### 04_WSUS
Keine Beschreibung verfügbar

- **Anzahl Scripts:** 2
- **Verfügbare Scripts:**
  - `Updates_ablehnen.ps1`
  - `WSUS-Updates-Ablehnen_OLD.ps1`

### 05_WDS
**[Zur vollständigen Dokumentation](05_WDS/README.md)**

Eine Sammlung von PowerShell-Tools für die effiziente Verwaltung von Windows Deployment Services (WDS) und Image-Konvertierung.

- **Anzahl Scripts:** 1
- **Verfügbare Scripts:**
  - `install-ESD-Converter.ps1`

## Entwicklung & Beitrag

### Repository-Struktur
```
DSE/
├── 01_HYPER-V/                     # 01_HYPER-V Tools
├── 02_GPO/                     # 02_GPO Tools
├── 03_SYS/                     # 03_SYS Tools
├── 04_WSUS/                     # 04_WSUS Tools
└── 05_WDS/                     # 05_WDS Tools
```

### Beitrag leisten
1. Fork des Repositories erstellen
2. Feature-Branch erstellen (`git checkout -b feature/neue-funktion`)
3. Änderungen committen (`git commit -am 'Neue Funktion hinzufügen'`)
4. Branch pushen (`git push origin feature/neue-funktion`)
5. Pull Request erstellen

### Coding-Standards
- PowerShell-Scripts sollten `#Requires` Statements enthalten
- Umfassende Kommentierung und Help-Dokumentation
- Fehlerbehandlung implementieren
- Parameter-Validierung verwenden

> Automatisch generiert am 05.07.2025 um 00:02:57 UTC