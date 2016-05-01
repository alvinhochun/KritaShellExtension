!macro RefreshShell_Macro
	# SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nullptr, nullptr)
	#   SHCNE_ASSOCCHANGED 0x08000000
	#   SHCNF_IDLIST 0
	System::Call "shell32.dll::SHChangeNotify(i 0x08000000, i 0, i 0, i 0)"
!macroend
!define RefreshShell '!insertmacro RefreshShell_Macro'

# Shell extension constants
!define KRITASHELLEX_VERSION "1.1.0.0"
!getdllversion "kritashellex32.dll" KRITASHELLEX_DLLVER_32_
!define KRITASHELLEX_DLLVER_32 "${KRITASHELLEX_DLLVER_32_1}.${KRITASHELLEX_DLLVER_32_2}.${KRITASHELLEX_DLLVER_32_3}.${KRITASHELLEX_DLLVER_32_4}"
!getdllversion "kritashellex64.dll" KRITASHELLEX_DLLVER_64_
!define KRITASHELLEX_DLLVER_64 "${KRITASHELLEX_DLLVER_64_1}.${KRITASHELLEX_DLLVER_64_2}.${KRITASHELLEX_DLLVER_64_3}.${KRITASHELLEX_DLLVER_64_4}"
!if ${KRITASHELLEX_DLLVER_32} != ${KRITASHELLEX_DLLVER_64}
	!error "kritashellex32.dll (${KRITASHELLEX_DLLVER_32}) and kritashellex64.dll (${KRITASHELLEX_DLLVER_64}) version mismatch. ${KRITASHELLEX_VERSION} is expected."
!endif
!if ${KRITASHELLEX_VERSION} != ${KRITASHELLEX_DLLVER_32}
	!error "Krita shell extension version ${KRITASHELLEX_VERSION} expected, got ${KRITASHELLEX_DLLVER_32} instead."
!endif

!define /ifndef KRITA_SHELLEX_DIR "$INSTDIR"

# CLSIDs of the shell extension classes
!define KRITASHELLEX_CLSID_THUMBNAILPROVIDER "{C6806289-D605-4AFE-A778-BC584303DB9A}"
!define KRITASHELLEX_CLSID_PROPERTYHANDLER "{C8E5509D-6F68-480C-8A41-DB64AECE94C6}"

!macro Krita_RegisterComComonents_Macro Bits
	SetRegView ${Bits}
	File "/oname=${KRITA_SHELLEX_DIR}\kritashellex${Bits}.dll" kritashellex${Bits}.dll
	# Register Thumbnail Provider
	WriteRegStr HKCR "CLSID\${KRITASHELLEX_CLSID_THUMBNAILPROVIDER}" \
	                 "" "Krita Thumbnail Provider"
	WriteRegStr HKCR "CLSID\${KRITASHELLEX_CLSID_THUMBNAILPROVIDER}\InprocServer32" \
	                 "" "${KRITA_SHELLEX_DIR}\kritashellex${Bits}.dll"
	WriteRegStr HKCR "CLSID\${KRITASHELLEX_CLSID_THUMBNAILPROVIDER}\InprocServer32" \
	                 "ThreadingModel" "Apartment"
	# Register Property Handler
	WriteRegStr HKCR "CLSID\${KRITASHELLEX_CLSID_PROPERTYHANDLER}" \
	                 "" "Krita Property Handler"
	WriteRegStr HKCR "CLSID\${KRITASHELLEX_CLSID_PROPERTYHANDLER}\InprocServer32" \
	                 "" "${KRITA_SHELLEX_DIR}\kritashellex${Bits}.dll"
	WriteRegStr HKCR "CLSID\${KRITASHELLEX_CLSID_PROPERTYHANDLER}\InprocServer32" \
	                 "ThreadingModel" "Apartment"
	WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\PropertySystem\PropertyHandlers\.kra" \
	                 "" "${KRITASHELLEX_CLSID_PROPERTYHANDLER}"
	SetRegView lastused
!macroend
!define Krita_RegisterComComonents '!insertmacro Krita_RegisterComComonents_Macro'

!macro Krita_UnregisterComComonents_Macro Bits
	SetRegView ${Bits}
	DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\PropertySystem\PropertyHandlers\.kra"
	DeleteRegKey HKCR "CLSID\${KRITASHELLEX_CLSID_THUMBNAILPROVIDER}"
	DeleteRegKey HKCR "CLSID\${KRITASHELLEX_CLSID_PROPERTYHANDLER}"
	${RefreshShell}
	Sleep 200
	# Try deleting, rename if failed
	ClearErrors
	Delete ${KRITA_SHELLEX_DIR}\kritashellex${Bits}.dll
	${If} ${Errors}
		push $R0
		GetTempFileName $R0 ${KRITA_SHELLEX_DIR}
		SetDetailsPrint none
		Delete $R0
		SetDetailsPrint lastused
		ClearErrors
		Rename ${KRITA_SHELLEX_DIR}\kritashellex${Bits}.dll $R0
		${If} ${Errors}
			Delete /REBOOTOK ${KRITA_SHELLEX_DIR}\kritashellex${Bits}.dll
		${Else}
			Delete /REBOOTOK $R0
		${EndIf}
		pop $R0
	${EndIf}
	SetRegView lastused
!macroend
!define Krita_UnregisterComComonents '!insertmacro Krita_UnregisterComComonents_Macro'

!macro Krita_RegisterFileAssociation_Macro KritaExePath
	File "/oname=${KRITA_SHELLEX_DIR}\kritafile.ico" kritafile.ico
	# Remove existing associations (really though?)
	DeleteRegKey HKCR ".kra"
	DeleteRegKey HKCR "Krita.Document"
	DeleteRegKey HKCR "krafile"
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
	                 "" "$\"${KRITA_SHELLEX_DIR}\kritafile.ico$\",0"
	# Open Command
	${If} ${KritaExePath} != ""
		WriteRegStr HKCR "Krita.Document\shell\open\command" \
						 "" "$\"${KritaExePath}$\" $\"%1$\""
	${EndIf}
	# TODO: .ora
	# TODO: MINE types
!macroend
!define Krita_RegisterFileAssociation '!insertmacro Krita_RegisterFileAssociation_Macro'

!macro Krita_UnregisterFileAssociation_Macro
	Delete ${KRITA_SHELLEX_DIR}\kritafile.ico
	# TODO: Maybe refine these a bit
	DeleteRegKey HKCR ".kra"
	DeleteRegKey HKCR "Krita.Document"
	# TODO: .ora
	# TODO: MINE types
!macroend
!define Krita_UnregisterFileAssociation '!insertmacro Krita_UnregisterFileAssociation_Macro'

!macro Krita_RegisterShellExtension_Macro
	File "/oname=${KRITA_SHELLEX_DIR}\krita.ico" krita.ico
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
	                 "TypeOverlay" "$\"${KRITA_SHELLEX_DIR}\krita.ico$\",0"
!macroend
!define Krita_RegisterShellExtension '!insertmacro Krita_RegisterShellExtension_Macro'

!macro Krita_UnregisterShellExtension_Macro
	DeleteRegKey HKCR ".kra\shellex\{E357FCCD-A995-4576-B01F-234630154E96}"
	DeleteRegKey /ifempty HKCR ".kra\shellex\"
	DeleteRegValue HKCR "Krita.Document" "PreviewDetails"
	DeleteRegValue HKCR "Krita.Document" "InfoTip"
	DeleteRegValue HKCR "Krita.Document" "FullDetails"
	DeleteRegValue HKCR "Krita.Document" "TypeOverlay"
	Delete ${KRITA_SHELLEX_DIR}\krita.ico
!macroend
!define Krita_UnregisterShellExtension '!insertmacro Krita_UnregisterShellExtension_Macro'
