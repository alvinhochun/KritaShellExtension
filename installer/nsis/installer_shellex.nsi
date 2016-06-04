Unicode true

!define KRITASHELLEX_PRODUCTNAME "Krita Shell Integration"
!define KRITASHELLEX_PUBLISHER "Alvin Wong"

OutFile "kritashellex_setup.exe"
Name "${KRITASHELLEX_PRODUCTNAME}"
XPstyle on

InstallDir ""
ShowInstDetails show
ShowUninstDetails show

!include MUI2.nsh

!define MUI_FINISHPAGE_NOAUTOCLOSE

# Installer Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "license.rtf"
!insertmacro MUI_PAGE_DIRECTORY
Page Custom func_KritaConfigPage_Show
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

# Uninstaller Pages
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

!include LogicLib.nsh
!include x64.nsh
!include WinVer.nsh

!include "include\KritaConfigPage.nsh"
!include "include\FileExists2.nsh"
!include "krita_versions_detect.nsh"
!include "krita_shell_integration.nsh"

VIProductVersion "${KRITASHELLEX_VERSION}"
VIAddVersionKey "CompanyName" "${KRITASHELLEX_PUBLISHER}"
VIAddVersionKey "FileDescription" "${KRITASHELLEX_PRODUCTNAME} Setup"
VIAddVersionKey "FileVersion" "${KRITASHELLEX_VERSION}"
VIAddVersionKey "InternalName" "kritashellex_setup.exe"
VIAddVersionKey "LegalCopyright" "Copyright (C) Alvin Wong 2016"
VIAddVersionKey "OriginalFileName" "kritashellex_setup.exe"
VIAddVersionKey "ProductName" "${KRITASHELLEX_PRODUCTNAME} Setup"
VIAddVersionKey "ProductVersion" "${KRITASHELLEX_VERSION}"

BrandingText "[NSIS ${NSIS_VERSION}]  ${KRITASHELLEX_PRODUCTNAME} ${KRITASHELLEX_VERSION}"

Var KritaExePath
Var KritaMsiProductX86
Var KritaMsiProductX64
Var KritaNsisVersion
Var KritaNsisBitness
Var KritaNsisInstallLocation

Var PrevInstallLocation
Var PrevVersion
Var PrevStandalone
Var PrevKritaExePath

Section "Remove_prev_version"
	${If} ${FileExists} "$PrevInstallLocation\uninstall.exe"
		ExecWait "$PrevInstallLocation\uninstall.exe /S _?=$PrevInstallLocation"
		Delete "$PrevInstallLocation\uninstall.exe"
	${EndIf}
SectionEnd

Section "Thing"
	SetOutPath $INSTDIR
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\KritaShellExtension" \
	                 "DisplayName" "${KRITASHELLEX_PRODUCTNAME}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\KritaShellExtension" \
	                 "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
	WriteUninstaller $INSTDIR\uninstall.exe
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\KritaShellExtension" \
	                 "DisplayVersion" "${KRITASHELLEX_VERSION}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\KritaShellExtension" \
	                 "DisplayIcon" "$\"$INSTDIR\krita.ico$\",0"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\KritaShellExtension" \
	                 "URLInfoAbout" "https://github.com/alvinhochun/KritaShellExtension"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\KritaShellExtension" \
	                 "InstallLocation" "$INSTDIR"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\KritaShellExtension" \
	                 "Publisher" "${KRITASHELLEX_PUBLISHER}"
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\KritaShellExtension" \
	                   "EstimatedSize" 680
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\KritaShellExtension" \
	                   "NoModify" 1
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\KritaShellExtension" \
	                   "NoRepair" 1
	# Registry entries for version recognition
	#   InstallLocation:
	#     Where the shell extension is installed
	#     If installed by Krita installer, this must point to shellex sub-dir
	WriteRegStr HKLM "Software\Krita\ShellExtension" \
	                 "InstallLocation" "$INSTDIR"
	#   Version:
	#     Version of the shell extension
	WriteRegStr HKLM "Software\Krita\ShellExtension" \
	                 "Version" "${KRITASHELLEX_VERSION}"
	#   Standalone:
	#     0 = Installed by Krita installer
	#     1 = Standalone installer
	WriteRegDWORD HKLM "Software\Krita\ShellExtension" \
	                   "Standalone" 1
	#   KritaExePath:
	#     Path to krita.exe as specified by user or by Krita installer
	#     Empty if not specified
	WriteRegStr HKLM "Software\Krita\ShellExtension" \
	                 "KritaExePath" "$KritaExePath"
SectionEnd

Section "Main_associate"
	${Krita_RegisterFileAssociation} $KritaExePath
SectionEnd

Section "ShellEx"
	${If} ${RunningX64}
		${Krita_RegisterComComonents} 64
	${EndIf}
	${Krita_RegisterComComonents} 32

	${Krita_RegisterShellExtension}
SectionEnd

Section "Main_refreshShell"
	${RefreshShell}
SectionEnd

Section "un.ShellEx"
	${Krita_UnregisterShellExtension}

	${If} ${RunningX64}
		${Krita_UnregisterComComonents} 64
	${EndIf}
	${Krita_UnregisterComComonents} 32
SectionEnd

Section "un.Main_associate"
	# TODO: Conditional, use install log
	${Krita_UnregisterFileAssociation}
SectionEnd

Section "un.Thing"
	DeleteRegKey HKLM "Software\Krita\ShellExtension"
	DeleteRegKey /ifempty HKLM "Software\Krita"
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\KritaShellExtension"
	Delete $INSTDIR\uninstall.exe
	RMDir /REBOOTOK $INSTDIR
SectionEnd

Section "un.Main_refreshShell"
	${RefreshShell}
SectionEnd

Function .onInit
	SetShellVarContext all
	${IfNot} ${AtLeastWin7}
		MessageBox MB_OK|MB_ICONSTOP "${KRITASHELLEX_PRODUCTNAME} requires Windows 7 or above."
		Abort
	${EndIf}
	${If} ${RunningX64}
		SetRegView 64
		StrCpy $InstDir "$PROGRAMFILES64\Krita Shell Extension"
	${Else}
		StrCpy $InstDir "$PROGRAMFILES32\Krita Shell Extension"
	${Endif}
	# Detect krita.exe shipped with package
	push $R0
	StrCpy $R0 "$EXEDIR\bin\krita.exe"
	${If} ${FileExists} $R0
		StrCpy $KritaExePath $R0
	${EndIf}
	pop $R0
	# Detect other Krita versions
	${DetectKritaMsi32bit} $KritaMsiProductX86
	${If} ${RunningX64}
		${DetectKritaMsi64bit} $KritaMsiProductX64
		${IfKritaMsi3Alpha} $KritaMsiProductX64
			MessageBox MB_YESNO|MB_ICONQUESTION|MB_DEFBUTTON2 "Krita 3.0 Alpha 1 is installed. It must be removed before ${KRITASHELLEX_PRODUCTNAME} can be installed.$\nDo you wish to remove it now?" \
			           /SD IDYES \
			           IDYES lbl_removeKrita3alpha
			Abort
			lbl_removeKrita3alpha:
			push $R0
			${MsiUninstall} $KritaMsiProductX64 $R0
			${If} $R0 != 0
				MessageBox MB_OK|MB_ICONSTOP "Failed to remove Krita 3.0 Alpha 1."
				Abort
			${EndIf}
			pop $R0
			StrCpy $KritaMsiProductX64 ""
		${ElseIf} $KritaMsiProductX64 != ""
			${If} $KritaMsiProductX86 != ""
				MessageBox MB_YESNO|MB_ICONQUESTION|MB_DEFBUTTON2 "Both 32-bit and 64-bit editions of Krita 2.9 or below are installed.$\nYou are strongly recommended to uninstall both of them.$\nDo you want to remove them now?" \
				           /SD IDYES \
				           IDNO lbl_noremoveKritaBoth
				push $R0
				${MsiUninstall} $KritaMsiProductX86 $R0
				${If} $R0 != 0
					MessageBox MB_OK|MB_ICONSTOP "Failed to remove Krita (32-bit)."
					Abort
				${EndIf}
				${MsiUninstall} $KritaMsiProductX64 $R0
				${If} $R0 != 0
					MessageBox MB_OK|MB_ICONSTOP "Failed to remove Krita (64-bit)."
					Abort
				${EndIf}
				pop $R0
				StrCpy $KritaMsiProductX86 ""
				StrCpy $KritaMsiProductX64 ""
				lbl_noremoveKritaBoth:
			${Else}
				MessageBox MB_YESNO|MB_ICONQUESTION|MB_DEFBUTTON2 "Krita (64-bit) 2.9 or below is installed.$\nYou are strongly recommended to uninstall it.$\nDo you wish to remove it now?" \
				           /SD IDYES \
				           IDNO lbl_noremoveKritaX64
				push $R0
				${MsiUninstall} $KritaMsiProductX64 $R0
				${If} $R0 != 0
					MessageBox MB_OK|MB_ICONSTOP "Failed to remove Krita (64-bit)."
					Abort
				${EndIf}
				pop $R0
				StrCpy $KritaMsiProductX64 ""
				lbl_noremoveKritaX64:
			${EndIf}
		${EndIf}
	${Endif}
	${If} $KritaMsiProductX86 != ""
	${AndIf} $KritaMsiProductX64 == ""
		MessageBox MB_YESNO|MB_ICONQUESTION|MB_DEFBUTTON2 "Krita (32-bit) 2.9 or below is installed.$\nYou are strongly recommended to uninstall it.$\nDo you wish to remove it now?" \
		           /SD IDYES \
		           IDNO lbl_noremoveKritaX86
		push $R0
		${MsiUninstall} $KritaMsiProductX86 $R0
		${If} $R0 != 0
			MessageBox MB_OK|MB_ICONSTOP "Failed to remove Krita (32-bit)."
			Abort
		${EndIf}
		pop $R0
		StrCpy $KritaMsiProductX86 ""
		lbl_noremoveKritaX86:
	${EndIf}

	# TODO: Allow Krita and the shell extension to be installed separately?
	${DetectKritaNsis} $KritaNsisVersion $KritaNsisBitness $KritaNsisInstallLocation
	${If} $KritaNsisVersion != ""
		MessageBox MB_OK|MB_ICONSTOP "Krita $KritaNsisVersion ($KritaNsisBitness-bit) is installed.$\nThis installer will now exit."
		Abort
	${EndIf}

	# Detect other versions of this
	ClearErrors
	ReadRegStr $PrevInstallLocation HKLM "Software\Krita\ShellExtension" "InstallLocation"
	ReadRegStr $PrevVersion HKLM "Software\Krita\ShellExtension" "Version"
	ReadRegDWORD $PrevStandalone HKLM "Software\Krita\ShellExtension" "Standalone"
	ReadRegStr $PrevKritaExePath HKLM "Software\Krita\ShellExtension" "KritaExePath"
	${If} ${Errors}
		# TODO: Assume no previous version installed or what?
	${EndIf}
	${If} $PrevStandalone == 1
		# Shouldn't reach this??? We've already checked for Krita version above
		# Whatever we'll just pass
	${EndIf}
	${If} $KritaExePath == ""
	${AndIf} ${FileExists} $PrevKritaExePath
		StrCpy $KritaExePath $PrevKritaExePath
	${EndIf}
	# TODO: Compare versions?
FunctionEnd

Function un.onInit
	SetShellVarContext all
	${If} ${RunningX64}
		SetRegView 64
	${Endif}
FunctionEnd

# ----[[

Function func_KritaConfigPage_Init
	${NSD_SetText} $hCtl_KritaConfigPage_TextBoxKritaExePath $KritaExePath
	${NSD_SetFocus} $hCtl_KritaConfigPage_TextBoxKritaExePath
	SendMessage $hCtl_KritaConfigPage_TextBoxKritaExePath ${EM_SETSEL} 0 -1
FunctionEnd

Function func_KritaConfigPage_browse
	push $R0
	StrCpy $R0 $KritaExePath
	nsDialogs::SelectFileDialog open $R0 "krita.exe|krita.exe"
	pop $R0
	${NSD_SetText} $hCtl_KritaConfigPage_TextBoxKritaExePath $R0
	pop $R0
FunctionEnd

Function func_KritaConfigPage_text_change
	push $R0
	${NSD_GetText} $hCtl_KritaConfigPage_TextBoxKritaExePath $KritaExePath
	GetDlgItem $R0 $HWNDPARENT 1
	${If} $KritaExePath == ""
	${OrIf} ${FileExists} $KritaExePath
		EnableWindow $R0 1
	${Else}
		EnableWindow $R0 0
	${EndIf}
	pop $R0
FunctionEnd

# ----]]
