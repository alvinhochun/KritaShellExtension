@echo off
setlocal enabledelayedexpansion

:: Builds the shell extension and installer

set KRITASHELLEX_VERSION_STRING=dev
::set KRITASHELLEX_VERSION_STRING=v1.2.4
set CMAKE_EXE=cmake.exe
set MAKENSIS_EXE=C:\Program Files (x86)\NSIS\makensis.exe
set SEVENZIP_EXE=%ProgramFiles%\7-Zip\7z.exe

:: Do not modify for release builds! You can use "Debug" for debug builds.
set BUILD_CONFIGURATION=Release

mkdir build
mkdir build\x86
mkdir build\x64
mkdir output
mkdir output\krita-nsis
mkdir output\krita-nsis\include

echo Building 32-bit shell extension...
pushd build\x86
"%CMAKE_EXE%" -G "Visual Studio 14 2015" ..\..
"%CMAKE_EXE%" --build . --config %BUILD_CONFIGURATION%
popd

echo Building 64-bit shell extension...
pushd build\x64
"%CMAKE_EXE%" -G "Visual Studio 14 2015 Win64" ..\..
"%CMAKE_EXE%" --build . --config %BUILD_CONFIGURATION%
popd

pushd output
copy /y ..\build\x86\KritaShellExtension\%BUILD_CONFIGURATION%\kritashellex32.dll .
copy /y ..\build\x64\KritaShellExtension\%BUILD_CONFIGURATION%\kritashellex64.dll .
"%MAKENSIS_EXE%" ^
    /DKRITASHELLEX_DLL_SOURCE_DIR=!CD!\ ^
    /DKRITASHELLEX_INSTALLER_OUTPUT=!CD!\KritaShellExtension-!KRITASHELLEX_VERSION_STRING!-setup.exe ^
    /X"SetCompressor /SOLID lzma" ^
    /V4 /P3 ^
    ..\installer\nsis\installer_shellex.nsi
copy /y ..\COPYING.txt .
copy /y ..\COPYING_libzip.txt .
copy /y ..\COPYING_tinyxml2.txt .
copy /y ..\COPYING_zlib.txt .
copy /y ..\README.md README.txt
"%CMAKE_EXE%" -E touch CHANGELOG.TODO

:: Prepare Krita installer package
copy /y kritashellex32.dll .\krita-nsis\
copy /y kritashellex64.dll .\krita-nsis\
type COPYING.txt > .\krita-nsis\COPYING.txt
echo. >> .\krita-nsis\COPYING.txt
echo ## libzip: >> .\krita-nsis\COPYING.txt
type COPYING_libzip.txt >> .\krita-nsis\COPYING.txt
echo. >> .\krita-nsis\COPYING.txt
echo ## tinyxml2: >> .\krita-nsis\COPYING.txt
type COPYING_tinyxml2.txt >> .\krita-nsis\COPYING.txt
echo. >> .\krita-nsis\COPYING.txt
echo ## zlib: >> .\krita-nsis\COPYING.txt
type COPYING_zlib.txt >> .\krita-nsis\COPYING.txt
copy /y ..\installer\nsis\installer_krita.nsi .\krita-nsis\
copy /y ..\installer\nsis\krita_versions_detect.nsh .\krita-nsis\
copy /y ..\installer\nsis\krita_shell_integration.nsh .\krita-nsis\
copy /y ..\installer\nsis\include\FileExists2.nsh .\krita-nsis\include\
copy /y ..\installer\nsis\include\IsFileInUse.nsh .\krita-nsis\include\
copy /y ..\installer\nsis\krita.ico .\krita-nsis\
copy /y ..\installer\nsis\kritafile.ico .\krita-nsis\
copy /y ..\installer\nsis\license.rtf .\krita-nsis\
copy /y ..\installer\nsis\license_gpl-3.0.rtf .\krita-nsis\

del krita-nsis-!KRITASHELLEX_VERSION_STRING!.zip
"%SEVENZIP_EXE%" a -tzip krita-nsis-!KRITASHELLEX_VERSION_STRING!.zip krita-nsis\

echo.
echo Update CHANGELOG file before releasing^!
popd
