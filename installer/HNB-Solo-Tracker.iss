; Inno Setup script for HNB Solo Tracker (Flutter).
; Build the app first: flutter build windows
; Then: iscc /DAppVersion=1.1.0 installer\HNB-Solo-Tracker.iss
; Output: dist\HNB-Solo-Tracker-Setup-1.1.0.exe

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

#define AppName "HNB Solo Tracker"
#define AppExe "hnb_solo_tracker.exe"
#define AppPublisher "Axcel Blade"
#define AppUrl "https://github.com/axcel-blade/HNB-Solo-Tracker"
#define ReleaseDir "..\build\windows\x64\runner\Release"

[Setup]
; Same AppId as the 0.1.0 installer so a per-user upgrade replaces that copy.
AppId={{6E1B7C52-3F4A-4E8B-9C2D-5A7F1E0B9D31}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppUrl}
AppSupportURL={#AppUrl}/issues
AppUpdatesURL={#AppUrl}/releases
PrivilegesRequired=lowest
DefaultDirName={localappdata}\Programs\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
LicenseFile=..\LICENSE.md
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName}
OutputDir=..\dist
OutputBaseFilename=HNB-Solo-Tracker-Setup-{#AppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[InstallDelete]
; The 0.1.0 desktop app used a different file name in this folder.
Type: files; Name: "{app}\hnb-solo-tracker.exe"

[Files]
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"; IconFilename: "{app}\{#AppExe}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; IconFilename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

; solo_collection.sqlite lives in the user's Documents folder and is left in place on uninstall.
