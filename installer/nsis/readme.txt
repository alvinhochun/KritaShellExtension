Place `kritashellex32.dll` and `kritashellex64.dll` in this directory.

---

To build the shell extension installer:

"C:\Program Files (x86)\NSIS\makensis.exe" ^
	installer_shellex.nsi

---

To build the 64-bit Krita installer:

"C:\Program Files (x86)\NSIS\makensis.exe" ^
	/DKRITA_INSTALLER_64 ^
	/DKRITA_VERSION=2.99.90.1 ^
	/DKRITA_VERSION_DISPLAY="Beta 1 dev" ^
	/DKRITA_INSTALLER_OUTPUT_DIR="" ^
	/DKRITA_INSTALLER_OUTPUT_NAME="krita-3.0-Beta-master-4a58260-x64_setup.exe" ^
	/DKRITA_PACKAGE_ROOT="F:\dev\krita\krita-3.0-Beta-master-4a58260-x64" ^
	/X"SetCompressor /SOLID lzma" ^
	installer_krita.nsi

Replace the values as needed.

---

To build the 32-bit Krita installer:

"C:\Program Files (x86)\NSIS\makensis.exe" ^
	/DKRITA_INSTALLER_32 ^
	/DKRITA_VERSION=2.99.90.1 ^
	/DKRITA_VERSION_DISPLAY="Beta 1 dev" ^
	/DKRITA_INSTALLER_OUTPUT_DIR="" ^
	/DKRITA_INSTALLER_OUTPUT_NAME="krita-3.0-Beta-master-4a58260-x86_setup.exe" ^
	/DKRITA_PACKAGE_ROOT="F:\dev\krita\krita-3.0-Beta-master-4a58260-x86" ^
	/X"SetCompressor /SOLID lzma" ^
	installer_krita.nsi

Replace the values as needed.
