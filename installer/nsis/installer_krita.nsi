!ifndef KRITA_INSTALLER_32 & KRITA_INSTALLER_64
	!error "Either one of KRITA_INSTALLER_32 or KRITA_INSTALLER_64 must be defined."
!endif

!ifndef KRITA_PACKAGE_ROOT
	!error "KRITA_PACKAGE_ROOT should be defined and point to the root of the package files."
!endif

Unicode true

!ifdef KRITA_INSTALLER_64
	OutFile "krita_x64_setup.exe"
	Name "Krita (x64)"
	InstallDir "$PROGRAMFILES64\Krita (x64)"
!else
	OutFile "krita_x86_setup.exe"
	Name "Krita (x86)"
	InstallDir "$PROGRAMFILES64\Krita (x86)"
!endif
XPstyle on

ShowInstDetails show
ShowUninstDetails show

!include MUI2.nsh

!define MUI_FINISHPAGE_NOAUTOCLOSE

# Installer Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "license_krita.rtf"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
#!insertmacro MUI_PAGE_LICENSE "license.rtf"
#Page Custom func_KritaConfigPage_Show
# TODO: More options?
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

# Uninstaller Pages
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

!include LogicLib.nsh
!include x64.nsh

!ifdef KRITA_INSTALLER_64
	!define UNINSTALL_REGKEY "Krita_x64"
	!define UNINSTALL_PRODUCT "Krita (x64)"
!else
	!define UNINSTALL_REGKEY "Krita_x86"
	!define UNINSTALL_PRODUCT "Krita (x86)"
!endif
!define KRITA_SHELLEX_DIR "$INSTDIR\shellex"

!include "include\constants.nsh"
#!include "include\KritaConfigPage.nsh"
#!include "include\FileExists2.nsh"
!include "krita_versions_detect.nsh"
!include "krita_shell_integration.nsh"

# ----[[

!macro SelectSection_Macro SecId
	Push $R0
	SectionGetFlags ${SecId} $R0
	IntOp $R0 $R0 | ${SF_SELECTED}
	SectionSetFlags ${SecId} $R0
	Pop $R0
!macroend
!define SelectSection '!insertmacro SelectSection_Macro'

!macro DeselectSection_Macro SecId
	Push $R0
	SectionGetFlags ${SecId} $R0
	IntOp $R0 $R0 ^ ${SF_SELECTED}
	SectionSetFlags ${SecId} $R0
	Pop $R0
!macroend
!define DeselectSection '!insertmacro DeselectSection_Macro'

# ----]]

Var KritaMsiProductX86
Var KritaMsiProductX64
Var KritaNsisVersion
Var KritaNsisBitness
Var KritaNsisInstallLocation

Var PrevShellExInstallLocation
Var PrevShellExStandalone

Section "Remove_shellex"
	${If} ${FileExists} "$PrevShellExInstallLocation\uninstall.exe"
		ExecWait "$PrevShellExInstallLocation\uninstall.exe /S _?=$PrevShellExInstallLocation"
		Delete "$PrevShellExInstallLocation\uninstall.exe"
	${EndIf}
SectionEnd

#Section "Remove_prev_version"
#	${If} ${FileExists} "$KritaNsisInstallLocation\uninstall.exe"
#		ExecWait "$KritaNsisInstallLocation\uninstall.exe /S _?=$KritaNsisInstallLocation"
#		Delete "$KritaNsisInstallLocation\uninstall.exe"
#	${EndIf}
#SectionEnd

Section "Thing"
	SetOutPath $INSTDIR
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTALL_REGKEY}" \
	                 "DisplayName" "${UNINSTALL_PRODUCT}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTALL_REGKEY}" \
	                 "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
	WriteUninstaller $INSTDIR\uninstall.exe
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTALL_REGKEY}" \
	                 "DisplayVersion" "2.99.90.0"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTALL_REGKEY}" \
	                 "DisplayIcon" "$\"$INSTDIR\shellex\krita.ico$\",0"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTALL_REGKEY}" \
	                 "URLInfoAbout" "https://krita.org/"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTALL_REGKEY}" \
	                 "InstallLocation" "$INSTDIR"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTALL_REGKEY}" \
	                 "Publisher" "Krita Foundation"
	#WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTALL_REGKEY}" \
	#                   "EstimatedSize" 250000
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTALL_REGKEY}" \
	                   "NoModify" 1
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTALL_REGKEY}" \
	                   "NoRepair" 1
	# Registry entries for version recognition
	#   InstallLocation:
	#     Where krita is installed
	WriteRegStr HKLM "Software\Krita" \
	                 "InstallLocation" "$INSTDIR"
	#   Version:
	#     Version of Krita
	WriteRegStr HKLM "Software\Krita" \
	                 "Version" "2.99.90.0"
	#   x64:
	#     Set to 1 for 64-bit Krita, can be missing for 32-bit Krita
!ifdef KRITA_INSTALLER_64
	WriteRegDWORD HKLM "Software\Krita" \
	                   "x64" 1
!else
	DeleteRegValue HKLM "Software\Krita" "x64"
!endif

	#   ShellExtension\InstallLocation:
	#     Where the shell extension is installed
	#     If installed by Krita installer, this must point to shellex sub-dir
	WriteRegStr HKLM "Software\Krita\ShellExtension" \
	                 "InstallLocation" "$INSTDIR\shellex"
	#   ShellExtension\Version:
	#     Version of the shell extension
	WriteRegStr HKLM "Software\Krita\ShellExtension" \
	                 "Version" "1.1.0.0"
	#   ShellExtension\Standalone:
	#     0 = Installed by Krita installer
	#     1 = Standalone installer
	WriteRegDWORD HKLM "Software\Krita\ShellExtension" \
	                   "Standalone" 0
	#   ShellExtension\KritaExePath:
	#     Path to krita.exe as specified by user or by Krita installer
	#     Empty if not specified
	WriteRegStr HKLM "Software\Krita\ShellExtension" \
	                 "KritaExePath" "$INSTDIR\bin\krita.exe"
SectionEnd

Section "Main_Krita"
	# TODO: Maybe switch to explicit file list?
	File /r ${KRITA_PACKAGE_ROOT}\bin
	File /r ${KRITA_PACKAGE_ROOT}\lib
	File /r ${KRITA_PACKAGE_ROOT}\share
SectionEnd

!ifdef KRITA_INSTALLER_64
Section "ShellEx_x64" SEC_shellex_x64
	${Krita_RegisterComComonents} 64
SectionEnd
!endif

Section "ShellEx_x86"
	${Krita_RegisterComComonents} 32
SectionEnd

Section "Main_associate"
	${Krita_RegisterFileAssociation} "$INSTDIR\bin\krita.exe"
SectionEnd

Section "ShellEx_common"
	${Krita_RegisterShellExtension}
SectionEnd

Section "Main_refreshShell"
	${RefreshShell}
SectionEnd

Section "un.ShellEx_common"
	${Krita_UnregisterShellExtension}
SectionEnd

!ifdef KRITA_INSTALLER_64
Section "un.ShellExn_x64" SEC_un_shellex_x64
	${Krita_UnregisterComComonents} 64
SectionEnd
!endif

Section "un.ShellEx_x86"
	${Krita_UnregisterComComonents} 32
SectionEnd

Section "un.Main_associate"
	# TODO: Conditional, use install log
	SetOutPath $INSTDIR\shellex
	${Krita_UnregisterFileAssociation}
SectionEnd

Section "un.Main_Krita"
	# TODO: Maybe switch to explicit file list or some sort of install log?
	RMDir /r $INSTDIR\bin
	RMDir /r $INSTDIR\lib
	RMDir /r $INSTDIR\share
SectionEnd

Section "un.Thing"
	DeleteRegKey HKLM "Software\Krita"
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${UNINSTALL_REGKEY}"
	Delete $INSTDIR\uninstall.exe
SectionEnd

Section "un.Main_refreshShell"
	${RefreshShell}
SectionEnd

Function .onInit
	MessageBox MB_OK|MB_ICONEXCLAMATION "This installer is experimental. Use only for testing."
!ifdef KRITA_INSTALLER_64
	${If} ${RunningX64}
		SetRegView 64
	${Else}
		MessageBox MB_OK|MB_ICONSTOP "You are running 32-bit Windows, but this installer installs Krita 64-bit which can only be installed on 64-bit Windows. Please download the 32-bit version on https://krita.org/"
		Abort
	${Endif}
!else
	${If} ${RunningX64}
		SetRegView 64
		MessageBox MB_OK|MB_ICONEXCLAMATION "You are running 64-bit Windows. You are strongly recommended to install the 64-bit version of Krita instead since it offers better performance."
	${Endif}
!endif
	# Detect other Krita versions
	${DetectKritaMsi32bit} $KritaMsiProductX86
	${If} ${RunningX64}
		${DetectKritaMsi64bit} $KritaMsiProductX64
		${IfKritaMsi3Alpha} $KritaMsiProductX64
			MessageBox MB_OK|MB_ICONSTOP "Krita 3.0 Alpha 1 is installed.$\nPlease uninstall it before running this installer."
			Abort
		${ElseIf} $KritaMsiProductX64 != ""
			${If} $KritaMsiProductX86 != ""
				MessageBox MB_OK|MB_ICONSTOP "Both 32-bit and 64-bit editions of Krita 2.9 or below are installed.$\nPlease uninstall both of them before running this installer."
				Abort
			${Else}
				MessageBox MB_OK|MB_ICONSTOP "Krita (64-bit) 2.9 or below is installed.$\nPlease uninstall it before running this installer."
				Abort
			${EndIf}
		${EndIf}
	${Endif}
	${If} $KritaMsiProductX86 != ""
		MessageBox MB_OK|MB_ICONSTOP "Krita (32-bit) 2.9 or below is installed.$\nPlease uninstall it before running this installer."
		Abort
	${EndIf}
	# TODO: Offer to uninstall these old versions?

	# TODO: Detect and abort on newer versions, and uninstall old versions without aborting (unless a version of different bitness is installed)
	${DetectKritaNsis} $KritaNsisVersion $KritaNsisBitness $KritaNsisInstallLocation
	${If} $KritaNsisVersion != ""
		#MessageBox MB_OK|MB_ICONEXCLAMATION "Krita $KritaNsisVersion ($KritaNsisBitness-bit) is installed. It will be uninstalled before this version is installed."
		MessageBox MB_OK|MB_ICONSTOP "Krita $KritaNsisVersion ($KritaNsisBitness-bit) is installed.$\nPlease uninstall it before running this installer."
		Abort
	${EndIf}

	# Detect standalone shell extension
	# TODO: Allow Krita and the shell extension to be installed separately?
	ClearErrors
	ReadRegStr $PrevShellExInstallLocation HKLM "Software\Krita\ShellExtension" "InstallLocation"
	#ReadRegStr $PrevShellExVersion HKLM "Software\Krita\ShellExtension" "Version"
	ReadRegDWORD $PrevShellExStandalone HKLM "Software\Krita\ShellExtension" "Standalone"
	#ReadRegStr $PrevShellExKritaExePath HKLM "Software\Krita\ShellExtension" "KritaExePath"
	${If} ${Errors}
		# TODO: Assume no previous version installed or what?
	${EndIf}
	${If} $PrevShellExStandalone == 1
		MessageBox MB_YESNO|MB_ICONQUESTION "Krita Shell Integration is already installed separately. It will be uninstalled automatically when installing Krita.$\nDo you want to continue?" \
		           /SD IDYES \
		           IDYES lbl_allowremoveshellex
		Abort
		lbl_allowremoveshellex:
	${EndIf}
FunctionEnd

Function un.onInit
!ifdef KRITA_INSTALLER_64
	${If} ${RunningX64}
		SetRegView 64
	${Else}
		Abort
	${Endif}
!else
	${If} ${RunningX64}
		SetRegView 64
	${Endif}
!endif
FunctionEnd
