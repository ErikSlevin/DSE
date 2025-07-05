#Requires -Version 5.1
#Requires -RunAsAdministrator

$productsToDecline = @(
    # ===== VERALTETE WINDOWS-BETRIEBSSYSTEME =====
    "Windows 2000",                                                              # End-of-Life seit 2010
    "Windows XP",                                                                # End-of-Life seit 2014
    "Windows XP 64-Bit Edition Version 2003",                                    # End-of-Life seit 2015
    "Windows Vista",                                                             # End-of-Life seit 2017
    "Windows 7",                                                                 # End-of-Life seit 2020
    "Windows 8",                                                                 # End-of-Life seit 2016
    "Windows 8.1",                                                               # End-of-Life seit 2023
    "Windows 8.1 Drivers",                                                       # Treiber für nicht mehr unterstützte Version
    "Windows RT",                                                                # Tablet-Version, nicht mehr entwickelt
    "Windows RT 8.1",                                                            # Tablet-Version, nicht mehr entwickelt
    "Windows Embedded",                                                          # Embedded-Versionen nicht in Umgebung
    "Windows Embedded Standard 7",                                               # Embedded-Version, End-of-Life
    "Windows 8 Embedded",                                                        # Embedded-Version, End-of-Life
    "Windows 10 LTSB",                                                           # Long Term Servicing Branch - spezielle Edition
    "Windows Insider Pre-Release",                                               # Preview-Builds für Testzwecke
    
    # Windows 10 S Edition (Education, nicht Business)
    "Windows 10 S and Later Servicing Drivers",                                 # Windows 10 S - Education Edition
    "Windows 10 S Version 1709 and Later Servicing Drivers for testing",        # Windows 10 S - Test-Treiber
    "Windows 10 S Version 1709 and Later Upgrade & Servicing Drivers for testing", # Windows 10 S - Test-Upgrade-Treiber
    "Windows 10 S Version 1803 and Later Servicing Drivers",                    # Windows 10 S - Servicing-Treiber
    "Windows 10 S Version 1803 and Later Upgrade & Servicing Drivers",          # Windows 10 S - Upgrade-Treiber
    "Windows 10 S, version 1809 and later, Servicing Drivers",                  # Windows 10 S - 1809 Servicing
    "Windows 10 S, version 1809 and later, Upgrade & Servicing Drivers",        # Windows 10 S - 1809 Upgrade
    "Windows 10 S, version 1903 and later, Servicing Drivers",                  # Windows 10 S - 1903 Servicing
    "Windows 10 S, version 1903 and later, Upgrade & Servicing Drivers",        # Windows 10 S - 1903 Upgrade
    "Windows 10 S, Vibranium and later, Servicing Drivers",                     # Windows 10 S - Vibranium Servicing
    "Windows 10 S, Vibranium and later, Upgrade & Servicing Drivers",           # Windows 10 S - Vibranium Upgrade
    "Windows - Client S, version 21H2 and later, Servicing Drivers",            # Windows 10 S - 21H2 Servicing
    "Windows - Client S, version 21H2 and later, Upgrade & Servicing Drivers",  # Windows 10 S - 21H2 Upgrade

    # ===== VERALTETE/NICHT VERWENDETE WINDOWS SERVER-VERSIONEN =====
    "Server 2003",                                                              # End-of-Life seit 2015
    "Windows Server 2008",                                                      # End-of-Life seit 2020
    "Windows Server 2008 R2",                                                   # End-of-Life seit 2020
    "Windows Server 2012",                                                      # End-of-Life Januar 2023
    "Windows Server 2012 R2",                                                   # End-of-Life Oktober 2023
    "Windows Server 2012 R2 Drivers",                                           # Treiber für nicht mehr unterstützte Version
    "Windows Server 2022",                                                      # Neuere Version, nicht in Umgebung
    "Windows Server 2025",                                                      # Zukünftige Version, nicht in Umgebung
    "Windows Server Drivers",                                                   # Allgemeine alte Server-Treiber
    "Windows Server, version 1903 and later",                                   # Semi-Annual Channel (nicht LTSC)
    "Windows Server Manager – WSUS Dynamic Installer",                          # Spezielle Installer-Komponente
    "Microsoft Server operating system-21H2",                                   # Semi-Annual Channel Version
    "Server 2022 Hotpatch Category",                                            # Hotpatch für Server 2022 (nicht in Umgebung)
    "Windows Server Technical Preview Language Packs",                          # Preview-Version Sprachpakete
    
    # Business Server-Editionen
    "Small Business Server",                                                    # End-of-Life seit 2020
    "Small Business Server 2011",                                               # End-of-Life seit 2020
    "Business Server 2015",                                                     # End-of-Life
    "Windows Essential Business Server 2008",                                   # End-of-Life
    "Windows Essential Business Server 2008 Setup Updates",                     # End-of-Life Setup-Updates
    "Windows Essential Business Server Preinstallation Tools",                  # End-of-Life Preinstallation-Tools
    "Windows Server Solutions Best Practices Analyzer 1.0",                     # Veraltetes Analyse-Tool

    # ===== SHAREPOINT SERVER =====
    "SharePoint Server",                                                        # Alle SharePoint Server-Versionen
    "SharePoint Server 2016",                                                   # SharePoint Server 2016
    "SharePoint Server 2019",                                                   # SharePoint Server 2019
    "SharePoint Server 2019/Office Online Server",                              # SharePoint 2019 mit Office Online

    # ===== EXCHANGE SERVER =====
    "Exchange 2000 Server",                                                     # End-of-Life seit 2009
    "Exchange Server 2000",                                                     # End-of-Life seit 2009
    "Exchange Server 2007",                                                     # End-of-Life seit 2017
    "Exchange Server 2010",                                                     # End-of-Life seit 2020
    "Exchange Server 2013",                                                     # End-of-Life seit 2023
    "Exchange Server 2016",                                                     # Nicht in Umgebung
    "Exchange Server 2019",                                                     # Nicht in Umgebung
    "Antigen for Exchange/SMTP",                                                # Veraltete Exchange-Sicherheitssoftware

    # ===== SQL SERVER =====
    "SQL Server 2000",                                                          # End-of-Life seit 2013
    "SQL Server 2005",                                                          # End-of-Life seit 2016
    "SQL Server 2008",                                                          # End-of-Life seit 2019
    "SQL Server 2012",                                                          # End-of-Life seit 2022
    "SQL Server 2014",                                                          # End-of-Life Oktober 2024
    "Microsoft SQL Server 2016",                                                # Nicht in Umgebung
    "SQL Server 2017",                                                          # Nicht in Umgebung
    "Microsoft SQL Server 2017",                                                # Nicht in Umgebung
    "Microsoft SQL Server 2019",                                                # Nicht in Umgebung
    "Microsoft SQL Server Management Studio v17",                               # Spezifische SSMS-Version
    "SQL Server Feature Pack",                                                  # SQL Server Feature Pack (alle Versionen)

    # ===== OFFICE-PRODUKTE UND KOMPONENTEN =====
    "Office XP",                                                                # End-of-Life seit 2008
    "Office 2002/XP",                                                           # End-of-Life seit 2008
    "Office 2003",                                                              # End-of-Life seit 2014
    "Office 2007",                                                              # End-of-Life seit 2017
    "Office 2010",                                                              # End-of-Life seit 2020
    "Office 2013",                                                              # End-of-Life seit 2023
    "Office 365",                                                               # Alte Bezeichnung, jetzt Microsoft 365
    "Microsoft 365",                                                            # Cloud-Version, separat verwaltet
    "Microsoft 365 Apps/Office 2019/Office LTSC",                               # Neuere Versionen, separat verwaltet
    "Office Live Add-in",                                                       # Veraltetes Online-Add-in
    
    # Einzelne Office-Anwendungen (alte Versionen)
    "Access",                                                                   # Allgemeine Access-Updates (alle Versionen)
    "Access 2002",                                                              # End-of-Life
    "Excel",                                                                    # Allgemeine Excel-Updates (alle Versionen)
    "Excel 2002",                                                               # End-of-Life
    "Outlook",                                                                  # Allgemeine Outlook-Updates (alle Versionen)
    "Outlook 2002",                                                             # End-of-Life
    "Word",                                                                     # Allgemeine Word-Updates (alle Versionen)
    "Word 2002",                                                                # End-of-Life
    
    # Publisher-Versionen
    "Publisher",                                                                # Allgemeine Publisher-Updates (alle Versionen)
    "Publisher 2000",                                                           # End-of-Life
    "Publisher 2002",                                                           # End-of-Life
    "Publisher 2003",                                                           # End-of-Life
    "Publisher 2007",                                                           # End-of-Life
    "Publisher 2010",                                                           # End-of-Life
    "Publisher 2013",                                                           # End-of-Life
    
    # Visio-Versionen
    "Visio",                                                                    # Allgemeine Visio-Updates (alle Versionen)
    "Visio 2000",                                                               # End-of-Life
    "Visio 2002",                                                               # End-of-Life
    "Visio 2003",                                                               # End-of-Life
    "Visio 2007",                                                               # End-of-Life
    "Visio 2010",                                                               # End-of-Life
    "Visio 2013",                                                               # End-of-Life
    
    # Project-Versionen
    "Project",                                                                  # Allgemeine Project-Updates (alle Versionen)
    "Project 2000",                                                             # End-of-Life
    "Project 2002",                                                             # End-of-Life
    "Project 2003",                                                             # End-of-Life
    "Project 2007",                                                             # End-of-Life
    "Project 2010",                                                             # End-of-Life
    "Project 2013",                                                             # End-of-Life

    # ===== VISUAL STUDIO =====
    "Visual Studio 2005",                                                       # End-of-Life seit 2016
    "Visual Studio 2008",                                                       # End-of-Life seit 2018
    "Visual Studio 2010",                                                       # End-of-Life seit 2020
    "Visual Studio 2012",                                                       # End-of-Life seit 2023
    "Visual Studio 2013",                                                       # End-of-Life seit 2024
    "Visual Studio 2015",                                                       # End-of-Life April 2025

    # ===== SYSTEM CENTER =====
    "System Center",                                                            # Allgemeine System Center-Updates
    "System Center 2019 - Operations Manager",                                  # SCOM 2019, nicht in Umgebung
    "System Center 2019 - Orchestrator",                                        # System Center Orchestrator 2019
    "System Center 2019 - Virtual Machine Manager",                             # SCVMM 2019, nicht in Umgebung
    "System Center 2019 Data Protection Manager",                               # SCDPM 2019, nicht in Umgebung
    "Microsoft Monitoring Agent",                                               # System Center Monitoring Agent

    # ===== KOMMUNIKATIONS-SERVER =====
    "Microsoft Lync 2010",                                                      # End-of-Life seit 2020
    "Microsoft Lync 2013",                                                      # End-of-Life seit 2023
    "Microsoft Lync Server",                                                    # Allgemeine Lync Server-Updates
    "Microsoft Lync Server 2010",                                               # End-of-Life seit 2020
    "Office Communicator 2007 R2",                                              # End-of-Life
    "Office Communicator Server",                                               # End-of-Life
    "Office Communicator Server 2007",                                          # End-of-Life
    "Office Communications Server",                                             # End-of-Life
    "Office Communications Server 2007",                                        # End-of-Life
    "Skype for Business",                                                       # Allgemeine Skype for Business-Updates
    "Skype for Business 2015",                                                  # Skype for Business 2015
    "Skype for Business Server 2015, SmartSetup",                               # Skype for Business Server 2015
    "Skype for Business Server 2019, SmartSetup",                               # Skype for Business Server 2019

    # ===== BIZTALK SERVER =====
    "BizTalk Server 2002",                                                      # End-of-Life
    "BizTalk Server 2006R2",                                                    # End-of-Life
    "BizTalk Server 2009",                                                      # End-of-Life
    "BizTalk Server 2013",                                                      # End-of-Life

    # ===== HOST INTEGRATION SERVER =====
    "Host Integration Server 2000",                                             # End-of-Life
    "Host Integration Server 2004",                                             # End-of-Life
    "Host Integration Server 2006",                                             # End-of-Life
    "Host Integration Server 2009",                                             # End-of-Life
    "Host Integration Server 2010",                                             # End-of-Life

    # ===== BROWSER UND WEB-TECHNOLOGIEN =====
    "Internet Explorer",                                                        # End-of-Life Juni 2022
    "Microsoft Edge Legacy",                                                    # Alte Edge-Version (EdgeHTML)
    "Silverlight",                                                              # End-of-Life Oktober 2021
    "Bing Bar",                                                                 # Veraltete Browser-Toolbar
    "Search Enhancement Pack",                                                  # Veraltetes Such-Add-on

    # ===== SICHERHEITS- UND MANAGEMENT-TOOLS =====
    "Forefront Client Security",                                                # End-of-Life, ersetzt durch Windows Defender
    "Forefront Endpoint Protection 2010",                                       # End-of-Life, ersetzt durch Windows Defender
    "Forefront Identity Manager",                                               # End-of-Life
    "Forefront Identity Manager 2010",                                          # End-of-Life
    "Forefront Identity Manager 2010 R2",                                       # End-of-Life
    "Forefront Protection Category",                                            # Forefront Protection-Updates
    "Forefront Server Security Category",                                       # Forefront Server Security-Updates
    "Forefront Threat Management Gateway, Definition Updates for HTTP Malware Inspection", # TMG Malware-Definition-Updates
    "Forefront TMG",                                                            # Threat Management Gateway
    "Forefront TMG MBE",                                                        # TMG Medium Business Edition
    "Security Essentials",                                                      # Microsoft Security Essentials (ersetzt durch Windows Defender)
    "Microsoft Advanced Threat Analytics",                                      # ATA, ersetzt durch Microsoft Defender for Identity
    "Microsoft BitLocker Administration and Monitoring v1",                     # MBAM v1, veraltete Version
    "OneCare Family Safety Installation",                                       # Veraltete Familienschutz-Software
    
    # ISA Server
    "Firewall Client for ISA Server",                                           # ISA Server Firewall Client
    "Internet Security and Acceleration Server 2004",                           # ISA Server 2004
    "Internet Security and Acceleration Server 2006",                           # ISA Server 2006
    
    # TMG (Threat Management Gateway)
    "Threat Management Gateway Definition Updates for Network Inspection System", # TMG Definition-Updates
    "TMG Firewall Client",                                                      # TMG Firewall Client

    # ===== VIRTUALISIERUNG =====
    "Virtual PC",                                                               # End-of-Life, ersetzt durch Hyper-V
    "Virtual Server",                                                           # End-of-Life, ersetzt durch Hyper-V
    "Microsoft Application Virtualization 4.5",                                 # App-V 4.5, veraltete Version
    "Microsoft Application Virtualization 4.6",                                 # App-V 4.6, veraltete Version
    "Microsoft Application Virtualization 5.0",                                 # App-V 5.0, veraltete Version

    # ===== .NET FRAMEWORK =====
    ".NET 5.0",                                                                 # .NET 5.0, End-of-Life
    "NET Core 2.1",                                                             # .NET Core 2.1, End-of-Life
    ".NET Core 3.1",                                                            # .NET Core 3.1, End-of-Life

    # ===== EXPRESSION-SUITE (WEBDESIGN-TOOLS) =====
    "Expression Design 1",                                                      # End-of-Life
    "Expression Design 2",                                                      # End-of-Life
    "Expression Design 3",                                                      # End-of-Life
    "Expression Design 4",                                                      # End-of-Life
    "Expression Media 2",                                                       # End-of-Life
    "Expression Media V1",                                                      # End-of-Life
    "Expression Web 3",                                                         # End-of-Life
    "Expression Web 4",                                                         # End-of-Life

    # ===== MICROSOFT WORKS =====
    "Microsoft Works 8",                                                        # End-of-Life
    "Microsoft Works 9",                                                        # End-of-Life
    "Works 6-9 Converter",                                                      # Konverter für Microsoft Works

    # ===== MICROSOFT DYNAMICS CRM =====
    "Microsoft Dynamics CRM 2011",                                              # End-of-Life
    "Microsoft Dynamics CRM 2011 SHS",                                          # Dynamics CRM 2011 SHS
    "Microsoft Dynamics CRM 2013",                                              # End-of-Life
    "Microsoft Dynamics CRM 2015",                                              # End-of-Life
    "Microsoft Dynamics CRM 2016",                                              # End-of-Life
    "Microsoft Dynamics CRM 2016 SHS",                                          # Dynamics CRM 2016 SHS

    # ===== WINDOWS LIVE =====
    "Windows Live",                                                             # End-of-Life
    "Windows Live Toolbar",                                                     # End-of-Life Browser-Toolbar

    # ===== WINDOWS AZURE PACK =====
    "Windows Azure Pack: Admin API",                                            # Azure Pack Admin API
    "Windows Azure Pack: Admin Authentication Site",                            # Azure Pack Admin Authentication
    "Windows Azure Pack: Admin Site",                                           # Azure Pack Admin Site
    "Windows Azure Pack: Configuration Site",                                   # Azure Pack Configuration Site
    "Windows Azure Pack: Microsoft Best Practice Analyzer",                     # Azure Pack Best Practice Analyzer
    "Windows Azure Pack: Monitoring Extension",                                 # Azure Pack Monitoring Extension
    "Windows Azure Pack: MySQL Extension",                                      # Azure Pack MySQL Extension
    "Windows Azure Pack: PowerShell API",                                       # Azure Pack PowerShell API
    "Windows Azure Pack: SQL Server Extension",                                 # Azure Pack SQL Server Extension
    "Windows Azure Pack: Tenant API",                                           # Azure Pack Tenant API
    "Windows Azure Pack: Tenant Authentication Site",                           # Azure Pack Tenant Authentication
    "Windows Azure Pack: Tenant Public API",                                    # Azure Pack Tenant Public API
    "Windows Azure Pack: Tenant Site",                                          # Azure Pack Tenant Site
    "Windows Azure Pack: Usage Extension",                                      # Azure Pack Usage Extension
    "Windows Azure Pack: Web App Gallery Extension",                            # Azure Pack Web App Gallery
    "Windows Azure Pack: Web Sites",                                            # Azure Pack Web Sites

    # ===== AZURE-KOMPONENTEN =====
    "Microsoft Azure Backup Server V3 - Data Protection Manager",               # Azure Backup Server V3
    "Microsoft Azure Edge Appliance",                                           # Azure Edge Appliance
    "Microsoft Azure Site Recovery Provider",                                   # Azure Site Recovery Provider
    "Azure IoT Edge for Linux on Windows Category",                             # Azure IoT Edge für Linux on Windows
    "Azure Stack HCI",                                                          # Azure Stack HCI, nicht in Umgebung

    # ===== ENTWICKLER- UND REPORTING-TOOLS =====
    "ASP.NET Web Frameworks",                                                   # ASP.NET Web Frameworks (allgemein)
    "Report Viewer 2005",                                                       # SQL Server Report Viewer 2005
    "Report Viewer 2008",                                                       # SQL Server Report Viewer 2008
    "Report Viewer 2010",                                                       # SQL Server Report Viewer 2010
    "Microsoft StreamInsight V1.0",                                             # StreamInsight V1.0, End-of-Life

    # ===== MONITORING- UND MANAGEMENT-TOOLS =====
    "Data Protection Manager 2006",                                             # System Center DPM 2006
    "HPC Pack 2008",                                                            # High Performance Computing Pack 2008
    "Network Monitor 3",                                                        # Microsoft Network Monitor 3
    "Service Bus for Windows Server 1.1",                                       # Service Bus für Windows Server

    # ===== GESUNDHEITS- UND MULTIMEDIA-TOOLS =====
    "HealthVault Connection Center",                                            # Microsoft HealthVault Connection Center
    "HealthVault Connection Center Upgrades",                                   # HealthVault Connection Center Upgrades
    "Microsoft Research AutoCollage 2008",                                      # AutoCollage 2008
    "Photo Gallery Installation and Upgrades",                                  # Windows Live Photo Gallery

    # ===== WINDOWS-EXTRAS UND SPIELE =====
    "DreamScene",                                                               # Windows DreamScene (Vista Ultimate)
    "Pokerspiel",                                                               # Windows Pokerspiel
    'Pokerspiel "Hold Em"',                                                     # Windows Hold'Em Pokerspiel
    "Tinker",                                                                   # Windows Tinker-Spiel
    "Windows Ultimate Extras",                                                  # Windows Vista Ultimate Extras
    "Writer Installation and Upgrades",                                         # Windows Live Writer

    # ===== HARDWARE-SPEZIFISCHE TREIBER =====
    "Surface Hub 2S drivers",                                                   # Surface Hub 2S Treiber
    "Driver",                                                                   # Allgemeine Treiber-Updates

    # ===== POWERSHELL =====
    "PowerShell Preview - x64",                                                 # PowerShell Preview-Versionen

    # ===== VERSCHIEDENE LEGACY-TOOLS =====
    "Active Directory Rights Management Services Client 2.0",                   # AD RMS Client 2.0
    "CAPICOM",                                                                  # Cryptographic API Component Object Model
    "Compute Cluster Pack",                                                     # Windows Compute Cluster Pack
    "Device Health",                                                            # Device Health-Updates
    "Dictionary Updates for Microsoft IMEs",                                    # Wörterbuch-Updates für Input Method Editors
    "New Dictionaries for Microsoft IMEs",                                      # Neue Wörterbücher für IMEs
    "Windows Dictionary Updates",                                               # Windows Wörterbuch-Updates
    "Windows Safe OS Dynamic Update",                                           # Windows Safe OS Dynamic Updates
    "Microsoft Online Services Sign-In Assistant",                              # Online Services Sign-In Assistant
    
    # ===== DYNAMIC UPDATE-KATEGORIEN =====
    # WICHTIG: Dynamic Updates (DU) und GDR-Dynamic Updates (GDR-DU) sind spezielle Update-Kategorien, die Microsoft für In-Place-Upgrades und Feature-Updates verwendet.
    # Diese sollten in WSUS NICHT genehmigt werden, da sie:
    #    1. Automatisch während Windows-Upgrades heruntergeladen werden (nicht über WSUS)
    #    2. Können Upgrade-Probleme verursachen wenn über WSUS bereitgestellt
    #    3. Sind für Zero-Day-Patches während Upgrades gedacht, nicht für laufende Systeme
    #    4. Können zu unerwarteten System-Neustarts und Installationen führen
    #    5. Umgehen normale Change-Management-Prozesse
    
    "Windows 10 and later GDR-DU",                                             # GDR Dynamic Updates - automatisch während Upgrades
    "Windows 10 and later Dynamic Update",                                     # Dynamic Updates - automatisch während Feature-Updates
    "Windows 10 GDR-DU FOD",                                                   # GDR-DU Features on Demand - automatisch installiert
    "Windows 10 GDR-DU LP",                                                    # GDR-DU Language Packs - automatisch während Upgrades
    "Windows 11 Dynamic Update / GDR-DU",                                      # Windows 11 Dynamic Updates - automatisch verwaltet
    "Windows GDR-Dynamic Update"                                               # GDR Dynamic Updates - bypassen WSUS-Kontrolle
)

function Format-TitleShort {
    param(
        [string]$title,
        [string[]]$kbArticles,
        [int]$maxLen = 160
    )

    # Titel als String sicherstellen
    $title = [string]$title

    # KB-Nummer extrahieren aus $kbArticles
    $kb = ""
    if ($kbArticles -and $kbArticles.Count -gt 0) {
        $kb = "KB" + $kbArticles[0]
    }

    # KB-Nummer (inkl. Klammern) aus dem Titel entfernen (alle Vorkommen)
    if ($kb) {
        # Entfernt alle Vorkommen von (KBxxxxxxx) oder KBxxxxxxx im Titel
        $title = $title -replace '\(?KB\d+\)?', ''
        $title = $title.Trim()
    }

    # Titel kürzen, falls zu lang
    if ($title.Length -gt $maxLen) {
        $title = $title.Substring(0, $maxLen).TrimEnd() + "..."
    }

    return @{ Title = $title; KB = $kb }
}

function Write-Color {
    param(
        [string]$text,
        [ConsoleColor]$color
    )
    $origColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $color
    Write-Host -NoNewline $text
    $Host.UI.RawUI.ForegroundColor = $origColor
}


# Verbindung zu WSUS (lokal, kein SSL, Port 8530)
[void][reflection.assembly]::LoadWithPartialName('Microsoft.UpdateServices.Administration')
$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($env:COMPUTERNAME, $false, 8530)

# [void][reflection.assembly]::LoadWithPartialName('Microsoft.UpdateServices.Administration')
# $wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($env:COMPUTERNAME.$env:USERDNSDOMAIN,$true, 8531)

# Funktion: Bestimme den Grund für Ablehnung
# Funktion: Bestimme den Grund für Ablehnung (KORRIGIERTE VERSION)
function Get-DeclineReason {
    param($update)
    
    # Frühe Prüfungen
    if ($update.IsBeta) { return "Beta" }
    if ($update.IsSuperseded) { return "Superseded" }
    
    # Prüfe Produkttitel auf Ablehnungsgründe
    if (Get-Variable -Name "productsToDecline" -Scope Global -ErrorAction SilentlyContinue) {
        foreach ($pt in $update.ProductTitles) {
            foreach ($prod in $productsToDecline) {
                if ($pt.IndexOf($prod, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    return $prod
                }
            }
        }
    }
    
    # Sprachprüfung - kombinierter Text
    $allText = $update.Title + " " + $update.Description + " " + ($update.ProductTitles -join " ")
    
    # Erlaubte Sprachen (Codes und Begriffe)
    $allowedPatterns = @(
        'de-de', 'en-us', 'en-gb',           # Sprachcodes
        '\bGerman\b', '\bEnglish\b', '\bDeutsch\b'  # Sprachbegriffe
    )
    
    # Verbotene Sprachen
    $forbiddenPatterns = @(
        'French', 'Spanish', 'Italian', 'Portuguese', 'Dutch', 'Polish',
        'Russian', 'Chinese', 'Japanese', 'Korean', 'Arabic', 'Hebrew',
        'Czech', 'Hungarian', 'Swedish', 'Norwegian', 'Danish', 'Finnish',
        'Turkish', 'Greek'
    )
    
    # Prüfe auf Sprachen (nur wenn Sprachbezug erkannt wird)
    if ($allText -match '(?i)(Language|Sprachpaket|\b[a-zA-Z]{2}-[a-zA-Z]{2}\b|German|English|French|Spanish|Italian)') {
        
        # Suche erlaubte Sprachen
        $hasAllowedLanguage = $false
        foreach ($pattern in $allowedPatterns) {
            if ($allText -match "(?i)$pattern") {
                $hasAllowedLanguage = $true
                break
            }
        }
        
        # Wenn keine erlaubte Sprache gefunden → prüfe auf verbotene
        if (-not $hasAllowedLanguage) {
            foreach ($pattern in $forbiddenPatterns) {
                if ($allText -match "(?i)\b$pattern\b") {
                    return "Nicht erlaubte Sprache ($pattern)"
                }
            }
        }
    }
    
    # Kein Ablehnungsgrund gefunden
    return $null
}

function Get-SimplifiedReasonForCSV {
    param($reason)
    
    if ($reason -eq "Beta") { return "Beta" }
    if ($reason -eq "Superseded") { return "Abgeloest" }
    if ($reason -match "^Nicht erlaubte Sprache") { return "Sprache" }
    
    # Produktablehnungen
    if ($reason -ne "Beta" -and $reason -ne "Superseded" -and $reason -notmatch "^Nicht erlaubte Sprache") {
        return "Unerwuenschtes_Produkt"
    }
    
    return "Sonstige"
}

function Get-SafeFileName {
    param($fileName)
    # Ersetze ungültige Zeichen durch Unterstriche
    $invalidChars = [IO.Path]::GetInvalidFileNameChars() + [IO.Path]::GetInvalidPathChars()
    $safeFileName = $fileName
    foreach ($char in $invalidChars) {
        $safeFileName = $safeFileName -replace [regex]::Escape($char), '_'
    }
    return $safeFileName
}

# Timer-Schleife starten
while ($true) {
    Write-Host "=== Durchlauf um $(Get-Date -Format 'HH:mm:ss') ===" -ForegroundColor Green

    # Updates laden
    Write-Host "Updates werden geladen..."
    $scope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
    $scope.ExcludedInstallationStates = [Microsoft.UpdateServices.Administration.UpdateInstallationStates]::NotApplicable
    $updates = $wsus.GetUpdates($scope) | Where-Object { -not $_.IsDeclined }
    Write-Host "$($updates.Count) Updates gefunden.`n"
    
    # Gruppierung vorbereiten: Dictionary mit Listen je Ablehnungsgrund
    $groupedUpdates = @{}
    foreach ($update in $updates) {
        $reason = Get-DeclineReason -update $update
        if ($reason) {
            if (-not $groupedUpdates.ContainsKey($reason)) {
                $groupedUpdates[$reason] = @()
            }
            $groupedUpdates[$reason] += $update
        }
    }
    
    # Log-Verzeichnis erstellen
    $logBasePath = "G:\WSUS\logs"
    if (-not (Test-Path $logBasePath)) {
        New-Item -Path $logBasePath -ItemType Directory -Force | Out-Null
    }
    $dateString = Get-Date -Format "yyyyMMdd"
    
    # Gruppenweise Ablehnen und Ausgabe mit Farbe + Logging
    $totalDeclined = 0
    $totalFailed = 0
    
    foreach ($group in $groupedUpdates.Keys) {
        Write-Host -ForegroundColor Cyan "`n=== $group ====================================================================================================="
        
        # Log-Ordner für diese Gruppe erstellen (mit vereinfachtem Namen für CSV)
        $simplifiedReason = Get-SimplifiedReasonForCSV -reason $group
        $safeGroupName = Get-SafeFileName -fileName $simplifiedReason
        $groupLogPath = Join-Path $logBasePath $safeGroupName
        if (-not (Test-Path $groupLogPath)) {
            New-Item -Path $groupLogPath -ItemType Directory -Force | Out-Null
        }
        
        # CSV-Datei für heute
        $csvFileName = "${dateString}_${safeGroupName}.csv"
        $csvFilePath = Join-Path $groupLogPath $csvFileName
        
        # CSV-Header erstellen falls Datei nicht existiert
        if (-not (Test-Path $csvFilePath)) {
            "Zeitstempel,Titel,KB-Artikel,Beschreibung,Produkttitel,Größe" | Out-File -FilePath $csvFilePath -Encoding UTF8
        }
        
        foreach ($update in $groupedUpdates[$group]) {
            try {
                $update.Decline()
                
                # Formatieren für Ausgabe
                $formatResult = Format-TitleShort -title $update.Title -kbArticles $update.KnowledgebaseArticles
                $shortTitle = $formatResult.Title
                $kb = $formatResult.KB
                
                # CSV-Daten vorbereiten (Anführungszeichen und Kommas escapen)
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $csvTitle = $update.Title -replace '"', '""'
                $csvDescription = ""
                if ($update.Description) {
                    $csvDescription = ($update.Description -replace '"', '""' -replace "`r`n", " " -replace "`n", " ")
                    if ($csvDescription.Length -gt 200) {
                        $csvDescription = $csvDescription.Substring(0, 200)
                    }
                }
                $csvProductTitles = ($update.ProductTitles -join "; ") -replace '"', '""'
                $csvKB = ($update.KnowledgebaseArticles -join "; ")
                $csvSize = $update.Size
                
                # In CSV schreiben
                $csvLine = "`"$timestamp`",`"$csvTitle`",`"$csvKB`",`"$csvDescription`",`"$csvProductTitles`",`"$csvSize`""
                Add-Content -Path $csvFilePath -Value $csvLine -Encoding UTF8
                
                # Konsolen-Ausgabe (unverändert)
                Write-Host "[x] " -Foregroundcolor Red -NoNewline
                Write-Host "[$($group)]" -Foregroundcolor Cyan -NoNewline
                if ($kb) {
                    Write-Host -NoNewline " $shortTitle "
                    Write-Host "($kb)" -Foregroundcolor Yellow
                } else {
                    Write-Host " $shortTitle "
                }
                $totalDeclined++
            }
            catch {
                Write-Host "  FEHLER bei '$($update.Title)'" -ForegroundColor Red
                
                # Auch Fehler loggen
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $errorLine = "`"$timestamp`",`"FEHLER: $($update.Title -replace '"', '""')`",`"`",`"$($_.Exception.Message -replace '"', '""')`",`"`",`"`""
                Add-Content -Path $csvFilePath -Value $errorLine -Encoding UTF8
                
                $totalFailed++
            }
        }
        Write-Host ""
    }
    
    # Abschluss
    Write-Host "Fertig."
    Write-Host "Abgelehnt: $totalDeclined"
    if ($totalFailed -gt 0) {
        Write-Host "Fehler: $totalFailed"
    }
    
    Write-Host "Warte 60 Sekunden..." -ForegroundColor Yellow
    Start-Sleep -Seconds 60
}
