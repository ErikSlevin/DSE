# Hyper-V Tools

Eine Sammlung von PowerShell-Tools für die effiziente Verwaltung von Hyper-V-Umgebungen und virtuellen Maschinen.

## Inhaltsverzeichnis

- **[Hyper-V-IPsec-On.ps1](#hyper-v-ipsec-onps1)**
- **[Hyper-V-Mount-ISOs.ps1](#hyper-v-mount-isosps1)**

## Hyper-V-IPsec-On.ps1
> [Link zum Script](Hyper-V-IPsec-On.ps1)\
> Stand: 04.05.2025

### Funktionen
- **IPsec-Offload-Konfiguration** für alle Netzwerkadapter von virtuellen Maschinen
- **Automatische Anwendung** auf alle virtuellen PROD-Maschinen
- **Detailliertes Logging** mit Erfolgs- und Fehlermeldungen

### Verwendung

> [!IMPORTANT]  
> PowerShell als Administrator auf einem Hyper-V-Host ausführen

```powershell
# Standard-Ausführung (alle "VM PROD*" VMs)
.\Hyper-V-IPsec-On.ps1

# Spezifischer VM-Filter
.\Hyper-V-IPsec-On.ps1 -VMFilter "VM TEST*"

# Angepasste Sicherheitsassoziationen
.\Hyper-V-IPsec-On.ps1 -VMFilter "VM PROD*" -MaxSecurityAssociation 2
```

### Parameter
- **`-VMFilter`**: Filter für zu bearbeitende VMs (Standard: "VM PROD*")
- **`-MaxSecurityAssociation`**: Maximale Anzahl von Sicherheitsassoziationen (Standard: 1, Range: 0-4096)

## Hyper-V-Mount-ISOs.ps1
> [Link zum Script](Hyper-V-Mount-ISOs.ps1)\
> Stand: 04.05.2025

> [!IMPORTANT]  
> PowerShell als Administrator auf einem Hyper-V-Host ausführen

### Funktionen
- **Automatische ISO-Zuweisung** zu DVD-Laufwerken von virtuellen PROD Maschinen
- **Vordefinierte VM-ISO-Mappings** für verschiedene Serverrollen
- **Flexible Konfiguration** mit anpassbaren Pfaden im Script selber 

---

### Verwendung
PowerShell auf einem Hyper-V-Host ausführen

```powershell
# Standard-Ausführung
.\Hyper-V-Mount-ISOs.ps1

# Angepasster VM-Filter und ISO-Pfad
.\Hyper-V-Mount-ISOs.ps1 -VMFilter "VM TEST*" -ISOBasePath "E:\Test-ISOs"
```

### Parameter
- **`-VMFilter`**: Filter für zu bearbeitende VMs (Standard: "VM PROD*")
- **`-ISOBasePath`**: Basispfad für ISO-Dateien (Standard: "D:\Service-ISOs")

### Vordefinierte ISO-Mappings

| VM-Name | Zugewiesene ISOs |
|---------|------------------|
| VM PROD DC 01/02 | AiO.iso |
| VM PROD FS 01/02 | AiO.iso |
| VM PROD WSUS 01 | AiO.iso |
| VM PROD LANCRYPT 01 | AiO.iso, SQL_SRV_2017_RTM.iso, LANcrypt.iso |
| VM PROD MAIL 01 | AiO.iso |
| VM PROD MAIL 02 | AiO.iso, Domino.iso |
| VM PROD ITWATCH 01 | AiO.iso, itWESS.iso, SQL_SRV_2017_RTM.iso |
| VM PROD PRINT 01 | AiO.iso |
| VM PROD DHCP 01 | AiO.iso |
| VM PROD WDS 01 | AiO.iso, Windows10_22H2.iso |
| VM PROD WEB 01 | AiO.iso |
| VM PROD AV 01 | AiO.iso, SEP_143_RU7.iso, SEP_DefinitionUpdates.iso |
