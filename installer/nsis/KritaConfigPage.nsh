; handle variables
Var hCtl_KritaConfigPage
Var hCtl_KritaConfigPage_Label
;Var hCtl_KritaConfigPage_CheckBoxAssociate
Var hCtl_KritaConfigPage_GroupBox
Var hCtl_KritaConfigPage_TextBoxKritaExePath
Var hCtl_KritaConfigPage_ButtonBrowseKritaExe
;Var hCtl_KritaConfigPage_ButtonSearchExistingInstall

; dialog create function
Function func_KritaConfigPage_Create

	; === KritaConfigPage (type: Dialog) ===
	nsDialogs::Create 1018
	Pop $hCtl_KritaConfigPage
	${If} $hCtl_KritaConfigPage == error
		Abort
	${EndIf}
	!insertmacro MUI_HEADER_TEXT "Configure File Association" "Configure existing Krita installation for file association."

	; === Label (type: Label) ===
	${NSD_CreateLabel} 0u 0u 300u 50u "Setup can associate .kra and .ora file types to be opened by a specified version of Krita, typically a portable install that is extracted from the zip packages manually. To skip the association of file types, leave the below text box blank.$\r$\n$\r$\n$_CLICK"
	Pop $hCtl_KritaConfigPage_Label

	; === CheckBoxAssociate (type: Checkbox) ===
	;${NSD_CreateCheckbox} 0u 60u 300u 10u "Associate files to existing Krita installation"
	;Pop $hCtl_KritaConfigPage_CheckBoxAssociate

	; === GroupBox (type: GroupBox) ===
	${NSD_CreateGroupBox} 0u 60u 300u 35u "Path to krita.exe"
	Pop $hCtl_KritaConfigPage_GroupBox

	; === TextBoxKritaExePath (type: Text) ===
	${NSD_CreateText} 10u 75u 210u 12u ""
	Pop $hCtl_KritaConfigPage_TextBoxKritaExePath
	${NSD_AddStyle} $hCtl_KritaConfigPage_TextBoxKritaExePath ${WS_TABSTOP}|${WS_CHILD}
	${NSD_OnChange} $hCtl_KritaConfigPage_TextBoxKritaExePath func_KritaConfigPage_text_change

	; === ButtonBrowseKritaExe (type: Button) ===
	${NSD_CreateButton} 228u 73u 60u 15u "B&rowse..."
	Pop $hCtl_KritaConfigPage_ButtonBrowseKritaExe
	${NSD_OnClick} $hCtl_KritaConfigPage_ButtonBrowseKritaExe func_KritaConfigPage_browse

	; === ButtonBrowseKritaExe (type: Button) ===
	;${NSD_CreateButton} 20u 105u 260u 15u "Search for existing Krita installation"
	;Pop $hCtl_KritaConfigPage_ButtonSearchExistingInstall
	;${NSD_OnClick} $hCtl_KritaConfigPage_ButtonSearchExistingInstall func_browse_krita_exe

FunctionEnd

; dialog show function
Function func_KritaConfigPage_Show
	Call func_KritaConfigPage_Create
	Call func_KritaConfigPage_Init
	nsDialogs::Show
FunctionEnd
