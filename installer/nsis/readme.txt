Place `kritashellex32.dll` and `kritashellex64.dll` in this directory.

---

To build the shell extension installer:

"C:\Program Files (x86)\NSIS\makensis.exe" ^
	/X"SetCompressor /SOLID lzma" ^
	installer_shellex.nsi

The contents are actually not that huge so it's not actually necessary to use solid lzma

---

To build the 64-bit Krita installer:

"C:\Program Files (x86)\NSIS\makensis.exe" ^
	/DKRITA_INSTALLER_64 ^
	/DKRITA_VERSION=3.0.0.0 ^
	/DKRITA_VERSION_DISPLAY="3.0" ^
	/DKRITA_INSTALLER_OUTPUT_DIR="" ^
	/DKRITA_INSTALLER_OUTPUT_NAME="krita-3.0-x64-setup.exe" ^
	/DKRITA_PACKAGE_ROOT="F:\dev\krita\3.0\krita-3.0-x64" ^
	/X"SetCompressor /SOLID lzma" ^
	installer_krita.nsi

Replace the values as needed.

---

To build the 32-bit Krita installer:

"C:\Program Files (x86)\NSIS\makensis.exe" ^
	/DKRITA_INSTALLER_32 ^
	/DKRITA_VERSION=3.0.0.0 ^
	/DKRITA_VERSION_DISPLAY="3.0" ^
	/DKRITA_INSTALLER_OUTPUT_DIR="" ^
	/DKRITA_INSTALLER_OUTPUT_NAME="krita-3.0-x86-setup.exe" ^
	/DKRITA_PACKAGE_ROOT="F:\dev\krita\3.0\krita-3.0-x86" ^
	/X"SetCompressor /SOLID lzma" ^
	installer_krita.nsi

Replace the values as needed.
