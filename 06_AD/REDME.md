# AD Tools

Eine Sammlung von PowerShell-Tools für die effiziente Verwaltung von Active Directory und LAPS (Local Administrator Password Solution).

## Inhaltsverzeichnis

- **[laps-auslesen.ps1](#laps-auslesenps1)**

---

## laps-auslesen.ps1
> [Link zum Script](laps-auslesen.ps1)\
> Stand: 05.07.2025

### Funktionen
- **Interaktive Computer-Auswahl** aus Active Directory
- **Automatische Funktionserkennung** basierend auf Namenskonvention
- **Tier-Zuweisung** für Local Admin-Gruppen
- **LAPS-Passwort-Ausgabe** im Klartext
- **Strukturierte Darstellung** mit Tabelle und farbiger Ausgabe

### Verwendung

> [!IMPORTANT]  
> Muss als Benutzer mit LAPS-Leserechten ausgeführt werden

```powershell
# Script laden und Funktion aufrufen
. .\laps-auslesen.ps1
laps
```

### Unterstützte Computer-Kategorien

#### Server (15-Zeichen Format)
| Code | Funktion | Local Admin Gruppe |
|------|----------|-------------------|
| DC | Domain Controller | LA_T0_MGMNT |
| SF | File Server | LA_T1_MGMNT |
| SU | WSUS Server | LA_T1_MGMNT |
| LC | LanCrypt Server | LA_T1_MGMNT |
| SP | Print Server | LA_T1_MGMNT |
| SI | DHCP Server | LA_T1_MGMNT |
| ID | WDS Server | LA_T1_MGMNT |
| SW | Web Server | LA_T1_MGMNT |
| IW | ITWatch Server | LA_T1_MGMNT |
| SV | Antivirus Server | LA_T1_MGMNT |

#### PAW-Computer
| Format | Funktion | Local Admin Gruppe |
|--------|----------|-------------------|
| PAW01, PAW02, etc. | Privileged Access Workstation | LA_PAW_MGMNT |

## Ausgabe-Beispiel

```
Nr Name            LocalAdmin    Funktion
-- ----            ----------    --------
1  VM-PROD-DC-01   LA_T0_MGMNT   DC
2  VM-PROD-SF-01   LA_T1_MGMNT   File
3  PAW01           LA_PAW_MGMNT  PAW
```

Nach der Auswahl:
```
    Computer: VM-PROD-DC-01
    Funktion: DC
        User:     LA_T0_MGMNT    
    Passwort:     Zx9!mK8pQ2@nR5    
```

### Voraussetzungen
- **Active Directory PowerShell-Modul**
- **LAPS PowerShell-Modul** (`Get-LapsADPassword`)
- **Leserechte** auf LAPS-Passwörter in Active Directory
- **Domain-Mitgliedschaft** des ausführenden Systems

### Sicherheitshinweise

> [!CAUTION]
> Das Script zeigt LAPS-Passwörter im Klartext an. Verwenden Sie es nur in sicheren Umgebungen und stellen Sie sicher, dass der Bildschirm nicht einsehbar ist.

> [!NOTE]
> Die Tier-Zuweisung basiert auf einem spezifischen Schema. Bei abweichenden Namenskonventionen muss das Script entsprechend angepasst werden.