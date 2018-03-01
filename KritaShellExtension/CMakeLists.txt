# libzip
set(libzip_LIBRARY ${PREFIX_DEPS}/lib/zipstatic.lib)

set(libzip_INCLUDE_DIR ${PREFIX_DEPS}/include)
set(libzip_CONF_INCLUDE_DIR ${PREFIX_DEPS}/lib/libzip/include)
set(libzip_INCLUDE_DIRS ${libzip_INCLUDE_DIR} ${libzip_CONF_INCLUDE_DIR})

# zlib
set(zlib_LIBRARY_DEBUG ${PREFIX_DEPS}/lib/zlibstaticd.lib)
set(zlib_LIBRARY_RELEASE ${PREFIX_DEPS}/lib/zlibstatic.lib)

set(zlib_INCLUDE_DIR ${PREFIX_DEPS}/include)
set(zlib_INCLUDE_DIRS ${zlib_INCLUDE_DIR})

# tinyxml2
set(tinyxml2_LIBRARY ${PREFIX_DEPS}/lib/tinyxml2.lib)

set(tinyxml2_INCLUDE_DIR ${PREFIX_DEPS}/include)
set(tinyxml2_INCLUDE_DIRS ${tinyxml2_INCLUDE_DIR})

# main
add_definitions(
	-DUNICODE
	-D_UNICODE
	-DWIN32
	-D_WINDOWS
	-D_USRDLL
	-DKRITASHELLEXTENSION_EXPORTS
	-DZIP_STATIC
)

set(KRITASHELLEX_SRCS
	ClassFactory.cpp
	dllmain.cpp
	document.cpp
	KritaPropertyHandler.cpp
	KritaThumbnailProvider.cpp
	zip_source_IStream.cpp
	KritaShellExtension.rc
	ExportFunctions.def
)

set(KRITASHELLEX_HEADERS
	ClassFactory.h
	dllmain.h
	document.h
	KritaPropertyHandler.h
	KritaThumbnailProvider.h
	zip_source_IStream.h
)

# https://stackoverflow.com/questions/1618927/cmake-microsoft-visual-studio-and-monolithic-runtimes
if(MSVC)
	foreach(flag_var CMAKE_C_FLAGS_DEBUG CMAKE_CXX_FLAGS_DEBUG CMAKE_C_FLAGS_RELEASE CMAKE_CXX_FLAGS_RELEASE CMAKE_C_FLAGS_MINSIZEREL CMAKE_CXX_FLAGS_MINSIZEREL CMAKE_C_FLAGS_RELWITHDEBINFO CMAKE_CXX_FLAGS_RELWITHDEBINFO)
		string(REGEX REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
		string(REGEX REPLACE "/MDd" "/MTd" ${flag_var} "${${flag_var}}")
	endforeach(flag_var)
	foreach(flag_var CMAKE_C_FLAGS_RELWITHDEBINFO CMAKE_CXX_FLAGS_RELWITHDEBINFO)
		string(REGEX REPLACE "/Ob1" "/Ob2" ${flag_var} "${${flag_var}}")
	endforeach(flag_var)
	SET (CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG}" CACHE STRING "MSVC C Debug MT flags " FORCE)
	SET (CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG}" CACHE STRING "MSVC CXX Debug MT flags " FORCE)
	SET (CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE}" CACHE STRING "MSVC C Release MT flags " FORCE)
	SET (CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE}" CACHE STRING "MSVC CXX Release MT flags " FORCE)
	SET (CMAKE_C_FLAGS_MINSIZEREL "${CMAKE_C_FLAGS_MINSIZEREL}" CACHE STRING "MSVC C Debug MT flags " FORCE)
	SET (CMAKE_CXX_FLAGS_MINSIZEREL "${CMAKE_CXX_FLAGS_MINSIZEREL}" CACHE STRING "MSVC C Release MT flags " FORCE)
	SET (CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO}" CACHE STRING "MSVC CXX Debug MT flags " FORCE)
	SET (CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO}" CACHE STRING "MSVC CXX Release MT flags " FORCE)

	string(REGEX REPLACE "/INCREMENTAL:NO" "" CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO "${CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO}")
	string(REGEX REPLACE "/INCREMENTAL" "" CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO "${CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO}")
	set(CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO "${CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO} /INCREMENTAL:NO /OPT:REF")
endif()

include_directories(${libzip_INCLUDE_DIRS})
include_directories(${zlib_INCLUDE_DIRS})
include_directories(${tinyxml2_INCLUDE_DIRS})

add_library(kritashellex SHARED ${KRITASHELLEX_SRCS} ${KRITASHELLEX_HEADERS})
if (CMAKE_SIZEOF_VOID_P EQUAL 8)
set_target_properties(kritashellex PROPERTIES OUTPUT_NAME "kritashellex64")
else (CMAKE_SIZEOF_VOID_P EQUAL 8)
set_target_properties(kritashellex PROPERTIES OUTPUT_NAME "kritashellex32")
endif (CMAKE_SIZEOF_VOID_P EQUAL 8)
target_link_libraries(kritashellex ${libzip_LIBRARY} ${tinyxml2_LIBRARY})
target_link_libraries(kritashellex
	$<$<CONFIG:Debug>:${zlib_LIBRARY_DEBUG}>
	$<$<NOT:$<CONFIG:Debug>>:${zlib_LIBRARY_RELEASE}>
)
