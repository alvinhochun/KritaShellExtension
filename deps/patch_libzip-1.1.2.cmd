@echo off
setlocal DisableDelayedExpansion
pushd lib
echo [patch_libzip-1.1.2] Patching...
@del CMakeLists.txt.fail
@del CMakeLists.txt.orig
ren CMakeLists.txt CMakeLists.txt.orig
@del zipint.h.fail
@del zipint.h.orig
ren zipint.h zipint.h.orig
set FOUND1=0
set FOUND2=0
set FOUND3=0
for /f "tokens=*" %%l in ( CMakeLists.txt.orig ) DO (
	echo.%%l>> CMakeLists.txt
	set "LINE=%%l"
	setlocal EnableDelayedExpansion
	rem "ADD_LIBRARY(zip SHARED "
	set SEARCH1=!LINE:~0,23!
	if "!SEARCH1!" == "ADD_LIBRARY(zip SHARED " (
		set LINE1=ADD_LIBRARY(zipstatic STATIC !LINE:~23!
		echo.!LINE1!>> CMakeLists.txt
		rem Escape closing parenthesis
		echo.SET_TARGET_PROPERTIES(zipstatic PROPERTIES COMPILE_FLAGS -DZIP_STATIC^)>> CMakeLists.txt
		echo [patch_libzip-1.1.2] Added zipstatic target.
		set /a FOUND1=!FOUND1!+1
		echo !FOUND1!
	)
	rem "INSTALL(TARGETS zip"
	set SEARCH2=!LINE:~0,19!
	if "!SEARCH2!" == "INSTALL(TARGETS zip" (
		echo.zipstatic>> CMakeLists.txt
		echo [patch_libzip-1.1.2] Added zipstatic to INSTALL directive.
		set /a FOUND2=!FOUND2!+1
	)
	for /f "delims=" %%A in ("!FOUND1!") do for /f "delims=" %%B in ("!FOUND2!") do endlocal & (
		set "FOUND1=%%A"
		set "FOUND2=%%B"
	)
)
if %FOUND1% NEQ 1 (
	echo [patch_libzip-1.1.2] ERROR: zipstatic target added %FOUND1% times>&2
	goto fail
)
if %FOUND2% NEQ 1 (
	echo [patch_libzip-1.1.2] ERROR: zipstatic install target added %FOUND2% times>&2
	goto fail
)
for /f "tokens=*" %%l in ( zipint.h.orig ) DO (
	rem "#define ZIP_EXTERN __declspec(dllexport)"
	if "%%l" == "#define ZIP_EXTERN __declspec(dllexport)" (
		echo.#ifndef ZIP_STATIC>> zipint.h
		echo.%%l>> zipint.h
		echo.#else>> zipint.h
		echo.#define ZIP_EXTERN>> zipint.h
		echo.#endif>> zipint.h
		echo [patch_libzip-1.1.2] Changed %%l to conditional
		setlocal EnableDelayedExpansion
		set /a FOUND3=!FOUND3!+1
		for /f "delims=" %%A in ("!FOUND3!") do endlocal & set FOUND3=%%A
	) else (
		echo.%%l>> zipint.h
	)
)
popd
if %FOUND3% NEQ 1 (
	echo [patch_libzip-1.1.2] ERROR: ZIP_STATIC changed %FOUND3% times>&2
	goto fail
)
popd
echo [patch_libzip-1.1.2] Done.
echo.
goto end

:fail
ren zipint.h zipint.h.fail
ren zipint.h.orig zipint.h
ren CMakeLists.txt CMakeLists.txt.fail
ren CMakeLists.txt.orig CMakeLists.txt
echo [patch_libzip-1.1.2] Fail.
popd
echo.
exit /b 1

:end
