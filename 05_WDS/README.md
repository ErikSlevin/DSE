# WDS Tools

Eine Sammlung von PowerShell-Tools für die effiziente Verwaltung von Windows Deployment Services (WDS) und Image-Konvertierung.

## Inhaltsverzeichnis

- **[install-ESD-Converter.ps1](#install-esd-converterps1)**

---

## install-ESD-Converter.ps1
> [Link zum Script](install-ESD-Converter.ps1)\
> Stand: 04.05.2025

### Funktionen
- **Automatische Konvertierung** von ESD-Dateien zu WIM-Dateien
- **Mehrfach-Image-Extraktion** - alle Indizes werden als separate WIM-Dateien extrahiert
- **Maximale Komprimierung** für optimale Speicherplatznutzung
- **Detaillierte Metadaten-Extraktion** aus ESD-Dateien
- **Strukturierte Protokollierung** mit Zeitstempel und Fortschrittsanzeige
- **Validierung** der Quell- und Zieldateien

### Verwendung
PowerShell **als Administrator** auf einem WDS-Server oder System mit DISM ausführen

```powershell
# Standard-Ausführung
.\install-ESD-Converter.ps1

# Angepasste Pfade
.\install-ESD-Converter.ps1 -ESDPath "E:\Sources\install.esd" -DestinationFolder "E:\WIMs"

# Andere Komprimierungsmethode
.\install-ESD-Converter.ps1 -ESDPath "D:\ISO\install.esd" -DestinationFolder "D:\WIMs" -CompressionMethod "Fast"
```

### Parameter
- **`-ESDPath`**: Pfad zur Quell-ESD-Datei (Standard: "D:\RemoteInstall\ISOCopy\install.esd")
- **`-DestinationFolder`**: Zielordner für extrahierte WIM-Dateien (Standard: "D:\RemoteInstall\ISOCopy\ExtractedWIMs")
- **`-CompressionMethod`**: Komprimierungsmethode - "None", "Fast", "Maximum" (Standard: "Maximum")

### Hintergrund: ESD vs. WIM

> [!IMPORTANT]  
> **Moderne Windows-ISOs** (Windows 10/11) verwenden das **ESD-Format** (Electronic Software Distribution), welches nicht direkt mit **Windows Deployment Services (WDS)** kompatibel ist.


### Ausgabe-Struktur
```
ExtractedWIMs/
├── install_1_Windows_10_Home.wim
├── install_2_Windows_10_Pro.wim
├── install_3_Windows_10_Enterprise.wim
└── install_4_Windows_10_Education.wim
```

### Voraussetzungen
- **Administrator-Rechte**
- **DISM** (Deployment Image Servicing and Management)
- **Ausreichend Speicherplatz** (mindestens 10 GB empfohlen)

### Anwendungsfälle
- **WDS-Vorbereitung** - Konvertierung für Windows Deployment Services
- **Image-Verwaltung** - Separation verschiedener Windows-Editionen
- **Legacy-Kompatibilität** - Nutzung moderner ISOs mit klassischen Tools

### Protokollierung
Das Script erstellt automatisch Logs im `Logs/`-Unterverzeichnis:
- **ESD-Extract_YYYYMMDD_HHMMSS.log** - Detaillierte Ausführungsprotokolle
- **ESD-Extract_Transcript_YYYYMMDD_HHMMSS.txt** - Vollständige PowerShell-Transkription

### Hinweise

> [!NOTE]  
> Die Konvertierung kann je nach Anzahl der Images und Systemleistung **mehrere Stunden** dauern.

> [!WARNING]  
> Stellen Sie sicher, dass **genügend freier Speicherplatz** verfügbar ist. Jede WIM-Datei kann zwischen 3-6 GB groß sein.

### Beispiel-Ausgabe

| Index | Windows-Edition | Ausgabe-Datei | Größe |
|-------|-----------------|---------------|-------|
| 1 | Windows 10 Home | install_1_Windows_10_Home.wim | 4.2 GB |
| 2 | Windows 10 Pro | install_2_Windows_10_Pro.wim | 4.5 GB |
| 3 | Windows 10 Enterprise | install_3_Windows_10_Enterprise.wim | 4.8 GB |
| 4 | Windows 10 Education | install_4_Windows_10_Education.wim | 4.6 GB |


### Integration mit WDS
Nach der Konvertierung können die WIM-Dateien direkt in WDS importiert werden: