!macro RefreshShell_Macro
	# SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nullptr, nullptr)
	#   SHCNE_ASSOCCHANGED 0x08000000
	#   SHCNF_IDLIST 0
	System::Call "shell32.dll::SHChangeNotify(i 0x08000000, i 0, i 0, i 0)"
!macroend
!define RefreshShell '!insertmacro RefreshShell_Macro'

# Shell extension constants
!define /ifndef KRITASHELLEX_DLL_SOURCE_DIR ""
!define KRITASHELLEX_VERSION "1.2.4.2"
!getdllversion "${KRITASHELLEX_DLL_SOURCE_DIR}kritashellex32.dll" KRITASHELLEX_DLLVER_32_
!define KRITASHELLEX_DLLVER_32 "${KRITASHELLEX_DLLVER_32_1}.${KRITASHELLEX_DLLVER_32_2}.${KRITASHELLEX_DLLVER_32_3}.${KRITASHELLEX_DLLVER_32_4}"
!getdllversion "${KRITASHELLEX_DLL_SOURCE_DIR}kritashellex64.dll" KRITASHELLEX_DLLVER_64_
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

!macro ForEachGenericImage_Macro _var
	!ifdef ForEachGenericImage_inBlock
		!error "Previous ForEachGenericImage not closed"
	!endif
	!define ForEachGenericImage_inBlock
	Push ""
	Push ".jpg"
	Push ".jpeg"
	Push ".png"
	Push ".gif"
	Push ".tif"
	Push ".tiff"
	Push ".psd"
	Push ".xcf"
	Push ".exr"
	Push ".bmp"
	${Do}
		Pop "${_var}"
		${If} "${_var}" == ""
			${Break}
		${EndIf}
!macroend
!define ForEachGenericImage "!insertmacro ForEachGenericImage_Macro"

!macro EndForEachGenericImage_Macro
	!ifndef ForEachGenericImage_inBlock
		!error "EndForEachGenericImage when not in block"
	!endif
	${Loop}
	!undef ForEachGenericImage_inBlock
	!define /redef /math ForEachGenericImage_counter "${ForEachGenericImage_inBlock}" + 1
!macroend
!define EndForEachGenericImage "!insertmacro EndForEachGenericImage_Macro"

!macro Krita_RegisterComComonents_Macro Bits
	SetRegView ${Bits}
	File "/oname=${KRITA_SHELLEX_DIR}\kritashellex${Bits}.dll" "${KRITASHELLEX_DLL_SOURCE_DIR}kritashellex${Bits}.dll"
	File /nonfatal "/oname=${KRITA_SHELLEX_DIR}\kritashellex${Bits}.pdb" "${KRITASHELLEX_DLL_SOURCE_DIR}kritashellex${Bits}.pdb"
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
	WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\PropertySystem\PropertyHandlers\.ora" \
	                 "" "${KRITASHELLEX_CLSID_PROPERTYHANDLER}"
	SetRegView lastused
!macroend
!define Krita_RegisterComComonents '!insertmacro Krita_RegisterComComonents_Macro'

!macro Krita_UnregisterComComonents_Macro Bits
	SetRegView ${Bits}
	DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\PropertySystem\PropertyHandlers\.kra"
	DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\PropertySystem\PropertyHandlers\.ora"
	DeleteRegKey HKCR "CLSID\${KRITASHELLEX_CLSID_THUMBNAILPROVIDER}"
	DeleteRegKey HKCR "CLSID\${KRITASHELLEX_CLSID_PROPERTYHANDLER}"
	${RefreshShell}
	Sleep 200
	Delete ${KRITA_SHELLEX_DIR}\kritashellex${Bits}.pdb
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
	File "/oname=${KRITA_SHELLEX_DIR}\krita.ico" krita.ico
	# Remove existing associations (really though?)
	#DeleteRegKey HKCR ".kra"
	#DeleteRegKey HKCR ".ora"
	#DeleteRegKey HKCR "Krita.Document"
	#DeleteRegKey HKCR "Krita.OpenRaster"
	# Register .kra
	WriteRegStr HKCR ".kra" \
	                 "" "Krita.Document"
	WriteRegStr HKCR ".kra" \
	                 "Content Type" "application/x-krita"
	# Register .ora
	WriteRegStr HKCR ".ora" \
	                 "" "Krita.OpenRaster"
	WriteRegStr HKCR ".ora" \
	                 "Content Type" "image/openraster"
	# Register ProgId
	WriteRegStr HKCR "Krita.Document" \
	                 "" "Krita Image Document"
	WriteRegStr HKCR "Krita.Document" \
	                 "FriendlyTypeName" "Krita Image Document"
	WriteRegStr HKCR "Krita.Document\DefaultIcon" \
	                 "" "$\"${KRITA_SHELLEX_DIR}\kritafile.ico$\",0"
	WriteRegStr HKCR "Krita.OpenRaster" \
	                 "" "OpenRaster Image Document"
	WriteRegStr HKCR "Krita.OpenRaster" \
	                 "FriendlyTypeName" "OpenRaster Image Document"
	WriteRegStr HKCR "Krita.OpenRaster\DefaultIcon" \
	                 "" "$\"${KRITA_SHELLEX_DIR}\kritafile.ico$\",0"
	WriteRegStr HKCR "Krita.PaintopPreset" \
	                 "" "Krita Brush Preset File"
	WriteRegStr HKCR "Krita.PaintopPreset" \
	                 "FriendlyTypeName" "Krita Brush Preset File"
	WriteRegStr HKCR "Krita.PaintopPreset\DefaultIcon" \
	                 "" "$\"${KRITA_SHELLEX_DIR}\kritafile.ico$\",0"
	WriteRegStr HKCR "Krita.GenericImage" \
	                 "" "Image File"
	WriteRegStr HKCR "Krita.GenericImage" \
	                 "FriendlyTypeName" "Image File"
	WriteRegStr HKCR "Krita.GenericImage\DefaultIcon" \
	                 "" "$\"${KRITA_SHELLEX_DIR}\kritafile.ico$\",0"
	# Set Thumbnail Overlay
	# Do this even if not installing thumbnail handler, since thumbnails
	# will show as long as they exist in the thumbnail cache, and if the
	# associated open command has no icon resources it will show an ugly
	# "unknown filetype" icon.
	WriteRegStr HKCR "Krita.Document" \
	                 "TypeOverlay" "$\"${KRITA_SHELLEX_DIR}\krita.ico$\",0"
	WriteRegStr HKCR "Krita.OpenRaster" \
	                 "TypeOverlay" "$\"${KRITA_SHELLEX_DIR}\krita.ico$\",0"
	WriteRegStr HKCR "Krita.PaintopPreset" \
	                 "TypeOverlay" "$\"${KRITA_SHELLEX_DIR}\krita.ico$\",0"
	WriteRegStr HKCR "Krita.GenericImage" \
	                 "TypeOverlay" "$\"${KRITA_SHELLEX_DIR}\krita.ico$\",0"
	${If} ${KritaExePath} != ""
		# Open Command
		WriteRegStr HKCR "Krita.Document\shell\open\command" \
						 "" "$\"${KritaExePath}$\" $\"%1$\""
		WriteRegStr HKCR "Krita.Document\shell\open" \
						 "FriendlyAppName" "Krita"
		WriteRegStr HKCR "Krita.OpenRaster\shell\open\command" \
						 "" "$\"${KritaExePath}$\" $\"%1$\""
		WriteRegStr HKCR "Krita.OpenRaster\shell\open" \
						 "FriendlyAppName" "Krita"
		WriteRegStr HKCR "Krita.PaintopPreset\shell\open\command" \
						 "" "$\"${KritaExePath}$\" $\"%1$\""
		WriteRegStr HKCR "Krita.PaintopPreset\shell\open" \
						 "FriendlyAppName" "Krita"
		WriteRegStr HKCR "Krita.GenericImage\shell\open\command" \
						 "" "$\"${KritaExePath}$\" $\"%1$\""
		WriteRegStr HKCR "Krita.GenericImage\shell\open" \
						 "FriendlyAppName" "Krita"
		#Register OpenWithProgIds
		WriteRegStr HKCR ".kra\OpenWithProgIds" \
						 "Krita.Document" ""
		WriteRegStr HKCR ".ora\OpenWithProgIds" \
						 "Krita.OpenRaster" ""
		WriteRegStr HKCR ".kpp\OpenWithProgIds" \
						 "Krita.PaintopPreset" ""
		Push $0
		${ForEachGenericImage} $0
			WriteRegStr HKCR "$0\OpenWithProgIds" \
							 "Krita.GenericImage" ""
		${EndForEachGenericImage}
		Pop $0
		# Default Program (Vista+)
		WriteRegStr HKLM "Software\Krita\Capabilities" \
		                 "ApplicationDescription" "The free sketching and painting program."
		#WriteRegStr HKLM "Software\Krita\Capabilities" \
		#                 "ApplicationIcon" "$\"${KRITA_SHELLEX_DIR}\krita.ico$\",0"
		WriteRegStr HKLM "Software\Krita\Capabilities" \
		                 "ApplicationName" "Krita"
		#WriteRegStr HKLM "Software\Krita\Capabilities\DefaultIcon" \
		#                 "" "$\"${KRITA_SHELLEX_DIR}\krita.ico$\",0"
		WriteRegStr HKLM "Software\Krita\Capabilities\FileAssociations" \
		                 ".kra" "Krita.Document"
		WriteRegStr HKLM "Software\Krita\Capabilities\FileAssociations" \
		                 ".ora" "Krita.OpenRaster"
		WriteRegStr HKLM "Software\Krita\Capabilities\MIMEAssociations" \
		                 "application/x-krita" "Krita.Document"
		WriteRegStr HKLM "Software\Krita\Capabilities\MIMEAssociations" \
		                 "image/openraster" "Krita.OpenRaster"
		WriteRegStr HKLM "Software\Krita\Capabilities\FileAssociations" \
		                 ".kpp" "Krita.PaintopPreset"
		Push $0
		${ForEachGenericImage} $0
			WriteRegStr HKLM "Software\Krita\Capabilities\FileAssociations" \
			                 "$0" "Krita.GenericImage"
		${EndForEachGenericImage}
		Pop $0
		WriteRegStr HKLM "Software\Krita\Capabilities\shell\open\command" \
						 "" "$\"${KritaExePath}$\" $\"%1$\""
		WriteRegStr HKLM "Software\Krita\Capabilities\shell\open" \
						 "FriendlyAppName" "Krita"
		WriteRegStr HKLM "Software\RegisteredApplications" \
						 "Krita" "Software\Krita\Capabilities"
		# Registration registry keys
		# This `FriendlyAppName` value is documented but doesn't seem to be used
		WriteRegStr HKCR "Applications\krita.exe" \
						 "FriendlyAppName" "Krita"
		WriteRegStr HKCR "Applications\krita.exe\SupportedTypes" \
						 ".kra" ""
		WriteRegStr HKCR "Applications\krita.exe\SupportedTypes" \
						 ".ora" ""
		WriteRegStr HKCR "Applications\krita.exe\SupportedTypes" \
						 ".kpp" ""
		Push $0
		${ForEachGenericImage} $0
			WriteRegStr HKCR "Applications\krita.exe\SupportedTypes" \
							 "$0" ""
		${EndForEachGenericImage}
		Pop $0
		#WriteRegStr HKCR "Applications\krita.exe\DefaultIcon" \
		#                 "" "$\"${KRITA_SHELLEX_DIR}\krita.ico$\",0"
		WriteRegStr HKCR "Applications\krita.exe\shell\open\command" \
						 "" "$\"${KritaExePath}$\" $\"%1$\""
		# This `FriendlyAppName` value is undocumented but is used in practice
		WriteRegStr HKCR "Applications\krita.exe\shell\open" \
						 "FriendlyAppName" "Krita"
	${EndIf}
!macroend
!define Krita_RegisterFileAssociation '!insertmacro Krita_RegisterFileAssociation_Macro'

!macro Krita_UnregisterFileAssociation_Macro
	Delete ${KRITA_SHELLEX_DIR}\kritafile.ico
	Delete ${KRITA_SHELLEX_DIR}\krita.ico
	DeleteRegValue HKCR "Krita.Document" "TypeOverlay"
	DeleteRegValue HKCR "Krita.OpenRaster" "TypeOverlay"
	DeleteRegValue HKCR "Krita.PaintopPreset" "TypeOverlay"
	DeleteRegValue HKCR "Krita.GenericImage" "TypeOverlay"
	# TODO: Maybe refine these a bit
	DeleteRegValue HKLM "Software\RegisteredApplications" "Krita"
	DeleteRegKey HKLM "Software\Krita\Capabilities"
	DeleteRegKey HKCR "Applications\krita.exe"
	DeleteRegKey HKCR ".kra"
	DeleteRegKey HKCR ".ora"
	DeleteRegValue HKCR ".kpp\OpenWithProgIds" "Krita.PaintopPreset"
	Push $0
	${ForEachGenericImage} $0
		DeleteRegValue HKCR "$0\OpenWithProgIds" "Krita.GenericImage"
		# TODO: Delete only if there are no subkeys and values
		# /ifempty only check for subkeys but ignores all values
		#DeleteRegKey /ifempty HKCR "$0\OpenWithProgIds"
		#DeleteRegKey /ifempty HKCR "$0"
	${EndForEachGenericImage}
	Pop $0
	DeleteRegKey HKCR "Krita.Document"
	DeleteRegKey HKCR "Krita.OpenRaster"
	DeleteRegKey HKCR "Krita.PaintopPreset"
	DeleteRegKey HKCR "Krita.GenericImage"
!macroend
!define Krita_UnregisterFileAssociation '!insertmacro Krita_UnregisterFileAssociation_Macro'

!macro Krita_RegisterShellExtension_Macro
	# Register as IThumbnailProvider
	WriteRegStr HKCR ".kra\shellex\{E357FCCD-A995-4576-B01F-234630154E96}" \
	                 "" "${KRITASHELLEX_CLSID_THUMBNAILPROVIDER}"
	WriteRegStr HKCR ".ora\shellex\{E357FCCD-A995-4576-B01F-234630154E96}" \
	                 "" "${KRITASHELLEX_CLSID_THUMBNAILPROVIDER}"
	# Set PerceivedType
	WriteRegStr HKCR ".kra" \
	                 "PerceivedType" "Image"
	WriteRegStr HKCR ".ora" \
	                 "PerceivedType" "Image"
	# Set Property Lists
	WriteRegStr HKCR "Krita.Document" \
	                 "PreviewDetails" "prop:System.DateModified;System.Size;System.DateCreated;*System.Image.Dimensions;*System.OfflineAvailability;*System.OfflineStatus;*System.SharedWith"
	WriteRegStr HKCR "Krita.Document" \
	                 "InfoTip" "prop:System.ItemTypeText;System.Image.Dimensions;*System.Size;System.DateModified"
	WriteRegStr HKCR "Krita.Document" \
	                 "FullDetails" "prop:System.Image.Dimensions;System.Image.HorizontalSize;System.Image.VerticalSize;System.Image.HorizontalResolution;System.Image.VerticalResolution;System.PropGroup.FileSystem;System.ItemNameDisplay;System.ItemTypeText;System.ItemFolderPathDisplay;System.Size;System.DateCreated;System.DateModified;System.FileAttributes;*System.OfflineAvailability;*System.OfflineStatus;*System.SharedWith;*System.FileOwner;*System.ComputerName"
	WriteRegStr HKCR "Krita.OpenRaster" \
	                 "PreviewDetails" "prop:System.DateModified;System.Size;System.DateCreated;*System.Image.Dimensions;*System.OfflineAvailability;*System.OfflineStatus;*System.SharedWith"
	WriteRegStr HKCR "Krita.OpenRaster" \
	                 "InfoTip" "prop:System.ItemTypeText;System.Image.Dimensions;*System.Size;System.DateModified"
	WriteRegStr HKCR "Krita.OpenRaster" \
	                 "FullDetails" "prop:System.Image.Dimensions;System.Image.HorizontalSize;System.Image.VerticalSize;System.Image.HorizontalResolution;System.Image.VerticalResolution;System.PropGroup.FileSystem;System.ItemNameDisplay;System.ItemTypeText;System.ItemFolderPathDisplay;System.Size;System.DateCreated;System.DateModified;System.FileAttributes;*System.OfflineAvailability;*System.OfflineStatus;*System.SharedWith;*System.FileOwner;*System.ComputerName"
!macroend
!define Krita_RegisterShellExtension '!insertmacro Krita_RegisterShellExtension_Macro'

!macro Krita_UnregisterShellExtension_Macro
	DeleteRegKey HKCR ".kra\shellex\{E357FCCD-A995-4576-B01F-234630154E96}"
	DeleteRegKey /ifempty HKCR ".kra\shellex\"
	DeleteRegKey HKCR ".ora\shellex\{E357FCCD-A995-4576-B01F-234630154E96}"
	DeleteRegKey /ifempty HKCR ".ora\shellex\"
	DeleteRegValue HKCR "Krita.Document" "PreviewDetails"
	DeleteRegValue HKCR "Krita.Document" "InfoTip"
	DeleteRegValue HKCR "Krita.Document" "FullDetails"
	DeleteRegValue HKCR "Krita.OpenRaster" "PreviewDetails"
	DeleteRegValue HKCR "Krita.OpenRaster" "InfoTip"
	DeleteRegValue HKCR "Krita.OpenRaster" "FullDetails"
!macroend
!define Krita_UnregisterShellExtension '!insertmacro Krita_UnregisterShellExtension_Macro'
