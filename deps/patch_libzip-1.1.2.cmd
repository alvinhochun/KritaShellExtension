@echo off
setlocal EnableDelayedExpansion
pushd lib
echo [patch_libzip-1.1.2] Patching...
@del CMakeLists.txt.orig
set FOUND1=0
set FOUND2=0
ren CMakeLists.txt CMakeLists.txt.orig
for /f "tokens=*" %%l in ( CMakeLists.txt.orig ) DO (
	set LINE=%%l
	echo.!LINE!>> CMakeLists.txt
	rem "ADD_LIBRARY(zip SHARED "
	set SEARCH1=!LINE:~0,23!
	if "!SEARCH1!" == "ADD_LIBRARY(zip SHARED " (
		set LINE1=ADD_LIBRARY(zipstatic STATIC !LINE:~23!
		echo.!LINE1!>> CMakeLists.txt
		echo [patch_libzip-1.1.2] Added zipstatic target.
		set /a FOUND1=!FOUND1!+1
	)
	rem "INSTALL(TARGETS zip"
	set SEARCH2=!LINE:~0,19!
	if "!SEARCH2!" == "INSTALL(TARGETS zip" (
		echo.zipstatic>> CMakeLists.txt
		echo [patch_libzip-1.1.2] Added zipstatic to INSTALL directive.
		set /a FOUND2=!FOUND2!+1
	)
)
popd
if %FOUND1% NEQ 1 (
	echo [patch_libzip-1.1.2] ERROR: zipstatic target added %FOUND1% times>&2
	goto fail
)
if %FOUND2% NEQ 1 (
	echo [patch_libzip-1.1.2] ERROR: zipstatic install target added %FOUND2% times>&2
	goto fail
)
echo [patch_libzip-1.1.2] Done.
echo.
endlocal
goto end

:fail
echo [patch_libzip-1.1.2] Fail.
@del CMakeLists.txt
ren CMakeLists.txt.orig CMakeLists.txt
echo.
endlocal
exit /b 1

:end
