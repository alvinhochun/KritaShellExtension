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
to the above URLs, or refer to the corresponding `COPYING` files
included in the source tree and/or binary release package.


System Requirements
-------------------

This shell extension requires Windows Vista or above. It does not
work on Windows XP and previous versions of Windows.

The released installer checks for Windows 7 or above, so it can not
be used directly on Windows Vista.

The binaries were compiled using Visual Studio 2015. They are linked
statically against the C++ runtime, so no extra runtime libraries are
needed for this to work.


Installing
----------

Executing the installer should work without any trouble.

Installing the shell extensions by `regsvr32` is *not* supported.


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
		cmake --build . --config Release

- NMake (within Visual Studio command prompt):

		cmake -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release <path_to_source>
		cmake --build .

Currently, the project does not include an install target. You will
have to copy the output manually or using an external script. The
output DLL is located at

	<build_dir>\KritaShellExtension\<config>\kritashellex.dll

or

	<build_dir>\KritaShellExtension\kritashellex.dll

depending on the generator you use.

To build the NSIS installer, refer to the readme file under
`installer/nsis`.


Additional Information
----------------------

### KritaThumbnailProvider ###

Provides preview thumbnail for .kra and .ora files.

### KritaPropertyHandler ###

Provides image file properties for .kra and .ora files. Additional
registry changes are needed for it to work the best.

### zip_source_IStream ###

Utility allowing libzip to read zip archives directly from the COM
interface IStream without needing to load the content of the entire
stream into memory beforehand, saving some time and reducing memory
usage.
