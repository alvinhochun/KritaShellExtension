Krita Shell Extension
=====================

Shell Extension to provide various information about Krita files in
Windows Explorer.


License
-------

The MIT License

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

This software uses the following libraries:

- libzip - BSD-like license - http://www.nih.at/libzip/
- zlib - zlib license - http://www.zlib.net/
- TinyXML-2 - zlib license https://github.com/leethomason/tinyxml2

For the license information on these libraries, you can either refer
to the URLs shown above, or refer to the corresponding `COPYING` files
included in the source tree and/or binary release package.


System Requirements
-------------------

This shell extension requires Windows Vista or above. It does not
work on Windows XP and previous versions of Windows.

The binaries were compiled using Visual Studio 2015, so the Visual
C++ Runtime Libraries 2015 would be needed for this to run properly.


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

*TODO*: Registry changes for properties from the property handler


Using
-----

Once this library is registered on the system, it will automatically
work inside Windows Explorer and other shell components (e.g. File
Dialogs) without needing further actions.


Building From Source
--------------------

The project has been compiled and tested with CMake 3.4.3 using both
NMake Makefile and Visual Studio 2015.

External libraries should be automatically downloaded and compiled by
the build system. You can also choose to download their sources
manually by replacing `deps/CMakeLists.txt` with
`deps/CMakeLists_uselocal.txt`. Note that you may need to change the
CMakeLists.txt of libzip manually to add the static library target.

You have to build the 32-bit and 64-bot versions separately. Using an
out-of-source build location is recommended.

Example build commands:

- Visual Studio 2015 64-bit build:

	cmake -G "Visual Studio 14 2015 Win64" <path_to_source>
	cmake --build . --config RelWithDebInfo

- NMake (within Visual Studio command prompt):

	cmake -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=RelWithDebInfo <path_to_source>
	cmake --build .

Currently, the project does not include an install target. You will
have to copy the output manually or using an external script. The
output DLL is located at

	`<build_dir>\KritaShellExtension\<config>\kritashellex.dll`

or

	`<build_dir>\KritaShellExtension\kritashellex.dll`

depending on the generator you use.

You may want to rename the output files into `kritashellex32.dll` and
`kritashellex64.dll` to avoid confusion.


Additional Information
----------------------

### KritaThumbnailProvider ###

Provides preview thumbnail for .kra files.

### KritaPropertyHandler ###

Provides image file properties for .kra files. Additional registry
changes are needed for it to work the best.

### zip_source_IStream ###

Utility allowing libzip to read zip archives directly from the COM
interface IStream without needing to load the content of the entire
stream into memory beforehand, saving some time and reducing memory
usage.
