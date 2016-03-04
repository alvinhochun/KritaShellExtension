project(kritashellex-deps)

if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
	if(NOT MSVC)
		message(FATAL_ERROR "kritashellex does not support build environments other than MSVC")
	endif()
else()
	message(FATAL_ERROR "kritashellex does not support non-Windows systems")
endif()

include(ExternalProject)

ExternalProject_Add(dep_zlib
	URL http://zlib.net/zlib-1.2.8.tar.gz
	URL_MD5 44d667c142d7cda120332623eab69f40
	CMAKE_ARGS
		-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
		-DCMAKE_INSTALL_PREFIX=${PREFIX_DEPS}
)
# Removes the INSTALL_*_DIR variables to force it to regenerate the install paths
ExternalProject_Add_Step(dep_zlib dep_zlib_refresh_install_cache
	WORKING_DIRECTORY <BINARY_DIR>
	COMMAND ${CMAKE_COMMAND}
		-UINSTALL_*_DIR
		<BINARY_DIR>
	DEPENDEES configure
	DEPENDERS build
)

ExternalProject_Add(dep_libzip
	URL http://www.nih.at/libzip/libzip-1.1.2.tar.xz
	URL_MD5 d79c12d2405366cd954dd8e2144efbf7
	PATCH_COMMAND "${CMAKE_CURRENT_LIST_DIR}/patch_libzip-1.1.2.cmd"
	DEPENDS dep_zlib
	CMAKE_ARGS
		-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
		-DCMAKE_INSTALL_PREFIX=${PREFIX_DEPS}
)

ExternalProject_Add(dep_tinyxml2
	GIT_REPOSITORY https://github.com/leethomason/tinyxml2.git
	GIT_TAG d175e9de0be0d4db75d0a8cf065599a435a87eb6
	CMAKE_ARGS
		-DBUILD_SHARED_LIBS=OFF
		-DBUILD_STATIC_LIBS=ON
		-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
		-DCMAKE_INSTALL_PREFIX=${PREFIX_DEPS}
)
