Unicode true

OutFile "kritashellex_setup.exe"
Name "Krita Shell Integration"
XPstyle on

InstallDir ""

!include MUI2.nsh

# Installer Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
Page Custom func_KritaConfigPage_Show
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

# Uninstaller Pages
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

!include x64.nsh

!include "include\constants.nsh"
!include "include\KritaConfigPage.nsh"
!include "include\FileExists2.nsh"

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

# ----[[

!macro RefreshShell_Macro
	# SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nullptr, nullptr)
	#   SHCNE_ASSOCCHANGED 0x08000000
	#   SHCNF_IDLIST 0
	System::Call "shell32.dll::SHChangeNotify(i 0x08000000, i 0, i 0, i 0)"
!macroend
!define RefreshShell '!insertmacro RefreshShell_Macro'

# ----]]

Var KritaExePath

Section "Thing"
	MessageBox MB_OK "Thing"
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

!macro Section_Main_Contents Bits
	SetRegView ${Bits}
	File kritashellex${Bits}.dll
	# Register Thumbnail Provider
	WriteRegStr HKCR "CLSID\${KRITASHELLEX_CLSID_THUMBNAILPROVIDER}" \
	                 "" "Krita Thumbnail Provider"
	WriteRegStr HKCR "CLSID\${KRITASHELLEX_CLSID_THUMBNAILPROVIDER}\InprocServer32" \
	                 "" "$INSTDIR\kritashellex${Bits}.dll"
	WriteRegStr HKCR "CLSID\${KRITASHELLEX_CLSID_THUMBNAILPROVIDER}\InprocServer32" \
	                 "ThreadingModel" "Apartment"
	# Register Property Handler
	WriteRegStr HKCR "CLSID\${KRITASHELLEX_CLSID_PROPERTYHANDLER}" \
	                 "" "Krita Property Handler"
	WriteRegStr HKCR "CLSID\${KRITASHELLEX_CLSID_PROPERTYHANDLER}\InprocServer32" \
	                 "" "$INSTDIR\kritashellex${Bits}.dll"
	WriteRegStr HKCR "CLSID\${KRITASHELLEX_CLSID_PROPERTYHANDLER}\InprocServer32" \
	                 "ThreadingModel" "Apartment"
	WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\PropertySystem\PropertyHandlers\.kra" \
	                 "" "${KRITASHELLEX_CLSID_PROPERTYHANDLER}"
!macroend

Section "Main_x64" SEC_x64
	MessageBox MB_OK "x64"
	!insertmacro Section_Main_Contents 64
SectionEnd

Section "Main_x86"
	MessageBox MB_OK "x86"
	!insertmacro Section_Main_Contents 32
SectionEnd

Section "Main_associate"
	# TODO: Conditional, check existing association
	# TODO: Write install log
	# TODO
	MessageBox MB_OK "associate"
	File kritafile.ico
	# Register .kra
	WriteRegStr HKCR ".kra" \
	                 "" "Krita.Document"
	WriteRegStr HKCR ".kra" \
	                 "Content Type" "application/x-krita"
	# Register ProgId
	WriteRegStr HKCR "Krita.Document" \
	                 "" "Krita Image File"
	WriteRegStr HKCR "Krita.Document" \
	                 "FriendlyTypeName" "Krita Image File"
	WriteRegStr HKCR "Krita.Document\DefaultIcon" \
	                 "" "$\"$INSTDIR\kritafile.ico$\",0"
	# Open Command
	${If} $KritaExePath != ""
		WriteRegStr HKCR "Krita.Document\shell\open\command" \
						 "" "$\"$KritaExePath$\" $\"%1$\""
	${EndIf}
SectionEnd

Section "Main_common"
	MessageBox MB_OK "common"
	File krita.ico
	# Register as IThumbnailProvider
	WriteRegStr HKCR ".kra\shellex\{E357FCCD-A995-4576-B01F-234630154E96}" \
	                 "" "${KRITASHELLEX_CLSID_THUMBNAILPROVIDER}"
	# Set PerceivedType
	WriteRegStr HKCR ".kra" \
	                 "PerceivedType" "Image"
	# Set Property Lists
	WriteRegStr HKCR "Krita.Document" \
	                 "PreviewDetails" "prop:System.DateModified;System.Size;System.DateCreated;*System.Image.Dimensions;*System.OfflineAvailability;*System.OfflineStatus;*System.SharedWith"
	WriteRegStr HKCR "Krita.Document" \
	                 "InfoTip" "prop:System.ItemTypeText;System.Image.Dimensions;*System.Size;System.DateModified"
	WriteRegStr HKCR "Krita.Document" \
	                 "FullDetails" "prop:System.Image.Dimensions;System.Image.HorizontalSize;System.Image.VerticalSize;System.Image.HorizontalResolution;System.Image.VerticalResolution;System.PropGroup.FileSystem;System.ItemNameDisplay;System.ItemTypeText;System.ItemFolderPathDisplay;System.Size;System.DateCreated;System.DateModified;System.FileAttributes;*System.OfflineAvailability;*System.OfflineStatus;*System.SharedWith;*System.FileOwner;*System.ComputerName"
	# Set Thumbnail Overlay
	WriteRegStr HKCR "Krita.Document" \
	                 "TypeOverlay" "$\"$INSTDIR\krita.ico$\",0"
SectionEnd

Section "main_refreshShell"
	${RefreshShell}
SectionEnd

Section "un.Main_common"
	MessageBox MB_OK "common"
	DeleteRegKey HKCR ".kra\shellex\{E357FCCD-A995-4576-B01F-234630154E96}"
	DeleteRegValue HKCR "Krita.Document" "PreviewDetails"
	DeleteRegValue HKCR "Krita.Document" "InfoTip"
	DeleteRegValue HKCR "Krita.Document" "FullDetails"
	DeleteRegValue HKCR "Krita.Document" "TypeOverlay"
	Delete $INSTDIR\krita.ico
SectionEnd

!macro UnSection_Main_Contents Bits
	SetRegView ${Bits}
	DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\PropertySystem\PropertyHandlers\.kra"
	DeleteRegKey HKCR "CLSID\${KRITASHELLEX_CLSID_THUMBNAILPROVIDER}"
	DeleteRegKey HKCR "CLSID\${KRITASHELLEX_CLSID_PROPERTYHANDLER}"
	${RefreshShell}
	Sleep 200
	# Try deleting, rename if failed
	Delete $INSTDIR\kritashellex${Bits}.dll
	${If} ${Errors}
		push $R0
		GetTempFileName $R0 $INSTDIR
		SetDetailsPrint none
		Delete $R0
		SetDetailsPrint lastused
		Rename $INSTDIR\kritashellex${Bits}.dll $R0
		${If} ${Errors}
			Delete /REBOOTOK $INSTDIR\kritashellex${Bits}.dll
		${Else}
			Delete /REBOOTOK $R0
		${EndIf}
		pop $R0
	${EndIf}
!macroend

Section "un.Main_x64" SEC_un_x64
	MessageBox MB_OK "x64"
	!insertmacro UnSection_Main_Contents 64
SectionEnd

Section "un.Main_x86"
	MessageBox MB_OK "x86"
	!insertmacro UnSection_Main_Contents 32
SectionEnd

Section "un.Main_associate"
	MessageBox MB_OK "associate"
	# TODO: Conditional, use install log
	Delete $INSTDIR\kritafile.ico
	# TODO: Refine these a bit
	DeleteRegKey HKCR ".kra"
	DeleteRegKey HKCR "Krita.Document"
SectionEnd

Section "un.Thing"
	MessageBox MB_OK "Thing"
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
	push $KritaExePath
	pop $R0
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
