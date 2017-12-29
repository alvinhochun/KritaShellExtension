@echo off
setlocal enabledelayedexpansion

:: Builds the shell extension and installer

set KRITASHELLEX_VERSION_STRING=dev
::set KRITASHELLEX_VERSION_STRING=v1.2.4
set CMAKE_EXE=cmake.exe
set MAKENSIS_EXE=C:\Program Files (x86)\NSIS\makensis.exe

:: Do not modify for release builds! You can use "Debug" for debug builds.
set BUILD_CONFIGURATION=Release

mkdir build
mkdir build\x86
mkdir build\x64
mkdir output

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
popd
