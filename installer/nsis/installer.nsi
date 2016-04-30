Unicode true

OutFile "kritashellex_setup.exe"
Name "Krita Shell Integration"
XPstyle on

InstallDir ""
ShowInstDetails show
ShowUninstDetails show

!include MUI2.nsh

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

!include "include\constants.nsh"
!include "include\KritaConfigPage.nsh"
!include "include\FileExists2.nsh"
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

Var KritaExePath

Section "Thing"
	SetOutPath $INSTDIR
	${If} ${RunningX64}
		SetRegView 64
	${EndIf}
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\KritaShellExtension" \
	                 "DisplayName" "Krita Shell Integration"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\KritaShellExtension" \
	                 "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
	WriteUninstaller $INSTDIR\uninstall.exe
	WriteRegStr HKLM "Software\Krita\ShellExtension" \
	                 "InstallDir" "$INSTDIR"
SectionEnd

Section "Main_x64" SEC_x64
	${Krita_RegisterComComonents} 64
SectionEnd

Section "Main_x86"
	${Krita_RegisterComComonents} 32
SectionEnd

Section "Main_associate"
	${Krita_RegisterFileAssociation} $KritaExePath
SectionEnd

Section "Main_common"
	${Krita_RegisterShellExtension}
SectionEnd

Section "main_refreshShell"
	${RefreshShell}
SectionEnd

Section "un.Main_common"
	${Krita_UnregisterShellExtension}
SectionEnd

Section "un.Main_x64" SEC_un_x64
	${Krita_UnregisterComComonents} 64
SectionEnd

Section "un.Main_x86"
	${Krita_UnregisterComComonents} 32
SectionEnd

Section "un.Main_associate"
	# TODO: Conditional, use install log
	${Krita_UnregisterFileAssociation}
SectionEnd

Section "un.Thing"
	${If} ${RunningX64}
		SetRegView 64
	${EndIf}
	DeleteRegKey HKLM "Software\Krita\ShellExtension"
	DeleteRegKey /ifempty HKLM "Software\Krita"
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\KritaShellExtension"
	Delete $INSTDIR\uninstall.exe
SectionEnd

Section "un.main_refreshShell"
	${RefreshShell}
SectionEnd

Function .onInit
	${If} ${RunningX64}
		StrCpy $InstDir "$PROGRAMFILES64\Krita (x64)\shellex"
	${Else}
		StrCpy $InstDir "$PROGRAMFILES32\Krita (x86)\shellex"
		${DeselectSection} ${SEC_x64}
	${Endif}
FunctionEnd

Function un.onInit
	${If} ${RunningX64}
		# Nothing
	${Else}
		${DeselectSection} ${SEC_un_x64}
	${Endif}
FunctionEnd

# ----[[

Function func_KritaConfigPage_Init
	${NSD_SetText} $hCtl_KritaConfigPage_TextBoxKritaExePath $KritaExePath
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
	# TODO: ?
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
