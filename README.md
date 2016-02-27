Krita Shell Extension
=====================

Shell Extension to provide various information about Krita files in
Windows Explorer.

Copyright (c) 2016 Alvin Wong <alvinhochun@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


Acknowledgement
---------------

This software uses the libzip library, which in turn uses the zlib
library.

For the license of libzip, please refer to `COPYING_libzip.txt`.


System Requirements
-------------------

This shell extension requires Windows Vista or above. It does not
work on Windows XP and previous versions of Windows.

The binaries were compiled using Visual Studio 2015, so the Visual
Studio Runtime 2015 would be needed for them to run properly.


Installing
----------

If you would like to install the shell extension manually, please
follow these steps:

1. Place kritashellex32.dll (and also kritashellex64.dll if you are
  running a 64-bit Windows system) in a location that is accessible
  by all users.
2. (Optional:) Set the access rights of the two dll files to be
  read-only by all users.
3. Start a command prompt with administrative rights.
4. Change to the location where the two dll files are located at.
5. Execute `regsvr32 kritashellex32.dll` (without quotes.)
6. (For 64-bit system only:) Execute `regsvr32 kritashellex64.dll`

If you would like to uninstall the shell extension manually, please
follow these steps:

1. Start a command prompt with administrative rights.
2. Change to the location where the two dll files are located at.
3. Execute `regsvr32 /u kritashellex32.dll` (without quotes.)
4. (For 64-bit system only:) Execute `regsvr32 /u kritashellex64.dll`
5. Delete the two dll files.


Using
-----

Once this library is registered on the system, it will automatically
work inside Windows Explorer and other shell components (e.g. File
Dialogs) without needing further actions.


Building From Source
--------------------

The project Has been compiled and tested with Visual Studio 2015,
while statically linked with zlib and libzip. The included prebuilt
zlib (v1.2.8) and libzip (v1.1.2) static libraries were compiled with
the Visual Studio 2015 build tools, so if you don't plan on compiling
zlib and libzip yourself, you should use Visual Studio 2015 to ensure
compatibility.

If you would like to build both libraries from source also, please
refer to the following instructions. Note that you'll need to do the
x86 build and x64 build separately.

I used CMake with the NMake Makefile generator to build both zlib and
libzip. To build the static library of libzip, you may have to add
the target manually by editing `lib\CMakeLists.txt`. Simply copy the
line with:

    ADD_LIBRARY(zip SHARED [...])

and change it to look like this:

    ADD_LIBRARY(zipstatic STATIC [...])

When building both libraries, remember to pass the parameter
`-DCMAKE_BUILD_TYPE=Release` to CMake in order to build the libraries
with release config.

You should build zlib first. After a successful build, gather the
header files `zlib.h` and `zconf.h` in one location (say, `include\`
under the build directory.) They will be used when building libzip.

Now build libzip. It should link against the zlib that you've just
built, therefore you should call CMake with these parameters:

    -DZLIB_LIBRARY=<path_to_zlibstatic.lib>
    -DZLIB_INCLUDE_DIR=<path_to_dir_containing_zlib_headers>

After both libraries are successfully built, gather the following
files and place them as stated:

    \- deps\
	  \- Release-x[86|64]\
		|- zlibstatic.lib  - zlib static lib output
	    |- zipstatic.lib   - libzip static lib output
		\- include\
		  |- zlib.h        - zlib header
		  |- zconf.h       - zlib config header, under build dir
		  |- zip.h         - libzip header, under lib\
		  \- zipconf.h     - libzip config header, under build dir

After that, you can build the main project with MSBuild or within
Visual Studio 2015 directly.

The output would be found inside `output\`, namely
`kritashellex32.dll` and `kritashellex64.dll` respectively.


Additional Information
----------------------

### KritaThumbnailProvider ###

Provides preview thumbnail for .kra files.

### zip_source_IStream ###

Utility allowing libzip to read zip archives directly from the COM
interface IStream without needing to load the content of the entire
stream into memory beforehand, saving some time and reducing memory
usage.
