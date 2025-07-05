# SYS Tools

Eine Sammlung von PowerShell-Tools für die effiziente Systemverwaltung und Inventarisierung in Windows-Domänenumgebungen.

## Inhaltsverzeichnis

- **[mac-export.ps1](#mac-exportps1)**

---

## mac-export.ps1
> [Link zum Script](mac-export.ps1)\
> Stand: 04.05.2025

### Funktionen
- **Automatische Sammlung** von MAC- und IP-Adressen aller Server aus Active Directory
- **Systeminventarisierung** mit Hostnamen, FQDN und RAM-Informationen
- **Filterung** schließt HOST-Systeme automatisch aus
- **CSV-Export** für weitere Verarbeitung und Dokumentation

### Verwendung
> [!IMPORTANT]  
> Das Script fokussiert sich auf Hyper-V-Netzwerkadapter (`netvsc`). Für physische Server muss der Filter entsprechend angepasst werden.

> [!CAUTION]
> Muss als $\color{red}{\textsf{T0-Administrator}}$ ausgeführt werden

```powershell
# Standard-Ausführung
.\mac-export.ps1

# Angepasster Ausgabepfad
.\mac-export.ps1 -OutputPath "D:\Inventar\Server-MAC-Adressen.csv"

# Mit vollständigem Pfad
.\mac-export.ps1 -OutputPath "C:\Reports\$(Get-Date -Format 'yyyyMMdd')_MAC_Export.csv"
```

### Parameter
- **`-OutputPath`**: Pfad für die CSV-Ausgabedatei (Standard: "C:\SOURCEN\MAC_Adress_MGMT.csv")

### Ausgabe-Struktur (CSV)
Die generierte CSV-Datei enthält folgende Spalten:

| Spalte | Beschreibung |
|--------|--------------|
| **Server** | NetBIOS-Name des Servers |
| **FQDN** | Vollständiger Domänenname (Fully Qualified Domain Name) |
| **MACAdresse** | MAC-Adresse des primären Netzwerkadapters |
| **IPAdresse** | Primäre IPv4-Adresse |
| **RAM** | Installierter Arbeitsspeicher in GB |

### Anwendungsfälle
- **PROD-Domäne-Inventarisierung** für Dokumentation
- **PROD-Domäne-Inventarisierung** für Dokumentation
- **Asset-Management** und Systemübersicht
- **Compliance-Berichte** für IT-Auditierung

### Hinweise

> [!IMPORTANT]  
> Das Script fokussiert sich auf Hyper-V-Netzwerkadapter (`netvsc`). Für physische Server oder andere Virtualisierungsplattformen muss der Filter entsprechend angepasst werden.

> [!NOTE]  
> Bei Servern mit mehreren Netzwerkadaptern wird nur der erste aktive Adapter pro Server erfasst.

### Beispiel-Ausgabe

| Server | FQDN | MACAdresse | IPAdresse | RAM |
|--------|------|------------|-----------|-----|
| VM-PROD-DC-01 | vm-prod-dc-01.domain.local | 00:15:5D:XX:XX:XX | 192.168.1.10 | 8GB |
| VM-PROD-DC-02 | vm-prod-dc-02.domain.local | 00:15:5D:XX:XX:XX | 192.168.1.11 | 8GB |
| VM-PROD-FS-01 | vm-prod-fs-01.domain.local | 00:15:5D:XX:XX:XX | 192.168.1.20 | 16GB |
| VM-PROD-FS-02 | vm-prod-fs-02.domain.local | 00:15:5D:XX:XX:XX | 192.168.1.21 | 16GB |
| VM-PROD-WSUS-01 | vm-prod-wsus-01.domain.local | 00:15:5D:XX:XX:XX | 192.168.1.30 | 12GB |
| VM-PROD-LANCRYPT-01 | vm-prod-lancrypt-01.domain.local | 00:15:5D:XX:XX:XX | 192.168.1.40 | 16GB |
| VM-PROD-MAIL-01 | vm-prod-mail-01.domain.local | 00:15:5D:XX:XX:XX | 192.168.1.50 | 12GB |
| VM-PROD-MAIL-02 | vm-prod-mail-02.domain.local | 00:15:5D:XX:XX:XX | 192.168.1.51 | 12GB |
| VM-PROD-ITWATCH-01 | vm-prod-itwatch-01.domain.local | 00:15:5D:XX:XX:XX | 192.168.1.60 | 8GB |
| VM-PROD-PRINT-01 | vm-prod-print-01.domain.local | 00:15:5D:XX:XX:XX | 192.168.1.70 | 6GB |
| VM-PROD-DHCP-01 | vm-prod-dhcp-01.domain.local | 00:15:5D:XX:XX:XX | 192.168.1.80 | 4GB |
| VM-PROD-WDS-01 | vm-prod-wds-01.domain.local | 00:15:5D:XX:XX:XX | 192.168.1.90 | 8GB |
| VM-PROD-WEB-01 | vm-prod-web-01.domain.local | 00:15:5D:XX:XX:XX | 192.168.1.100 | 8GB |
| VM-PROD-AV-01 | vm-prod-av-01.domain.local | 00:15:5D:XX:XX:XX | 192.168.1.110 | 6GB |