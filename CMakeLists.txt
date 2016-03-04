cmake_minimum_required(VERSION 2.8.4)

project(kritashellex)

if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
	if(NOT MSVC)
		message(FATAL_ERROR "kritashellex does not support build environments other than MSVC")
	endif()
else()
	message(FATAL_ERROR "kritashellex does not support non-Windows systems")
endif()

if(CMAKE_CONFIGURATION_TYPES)
	list(REMOVE_ITEM CMAKE_CONFIGURATION_TYPES MinSizeRel)
endif()

set(PREFIX_DEPS "${CMAKE_BINARY_DIR}/deps-install/${CMAKE_CFG_INTDIR}")

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
	set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/install/${CMAKE_CFG_INTDIR}" CACHE PATH "default install path" FORCE )
endif()

add_subdirectory(deps)

add_subdirectory(KritaShellExtension)
