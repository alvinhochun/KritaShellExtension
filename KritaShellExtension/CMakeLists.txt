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
	KritaPropertyHandler.cpp
	KritaThumbnailProvider.cpp
	zip_source_IStream.cpp
	KritaShellExtension.rc
	ExportFunctions.def
)

set(KRITASHELLEX_HEADERS
	ClassFactory.h
	dllmain.h
	KritaPropertyHandler.h
	KritaThumbnailProvider.h
	zip_source_IStream.h
)

include_directories(${libzip_INCLUDE_DIRS})
include_directories(${zlib_INCLUDE_DIRS})
include_directories(${tinyxml2_INCLUDE_DIRS})

add_library(kritashellex SHARED ${KRITASHELLEX_SRCS} ${KRITASHELLEX_HEADERS})
target_link_libraries(kritashellex ${libzip_LIBRARY} ${tinyxml2_LIBRARY})
target_link_libraries(kritashellex
	$<$<CONFIG:Debug>:${zlib_LIBRARY_DEBUG}>
	$<$<NOT:$<CONFIG:Debug>>:${zlib_LIBRARY_RELEASE}>
)
