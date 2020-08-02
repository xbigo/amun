if(NOT CMAKE_VERSION VERSION_LESS 3.10)
  include_guard()
endif()

set (AMUN_INCLUDED TRUE)

if(WIN32)
  set(CMAKE_INSTALL_PREFIX "C:/Ape" CACHE PATH "Installation path prefix, prepended to installation directories" FORCE)
endif()

include(FetchContent)

# amun_message(
#   [FATAL_ERROR|SEND_ERROR|WARNING|AUTHOR_WARNING|DEPRECATION|NOTICE|STATUS
#     |VERBOSE|DEBUG]
#   messages...)

function(amun_message type)
  if(type STREQUAL "VERBOSE")
    if(Ape_VERBOSE OR Ape_DEBUG)
      set(type STATUS)
    elseif(CMAKE_VERSION VERSION_LESS 3.15)
      return()
    endif()
  endif()

  if(type STREQUAL "DEBUG")
    if(Ape_DEBUG)
      set(type STATUS)
    elseif(CMAKE_VERSION VERSION_LESS 3.15)
      return()
    endif()
  endif()

  if(type STREQUAL "NOTICE" AND CMAKE_VERSION VERSION_LESS 3.15)
    set(type "")
  endif()

  set(m "")
  math(EXPR last "${ARGC}-1")

  foreach(i RANGE 1 ${last})
    string(APPEND m "${ARGV${i}}")
  endforeach()

  message(${type} "${m}")
endfunction()

function(amun_disable_build_in_source)
	if (CMAKE_BINARY_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
		message(FATAL_ERROR 
			"Building in-source is not supported! Create a build dir and remove ${CMAKE_SOURCE_DIR}/CMakeCache.txt.\n"
			"Consider: cmake [options] -S <path-to-source> -B <path-to-build>"
			)
	endif()
endfunction()

function(amun_get_cmake_install_dir variable)
	if (WIN32)
		set(_prefix "" )
	else()
		set(_prefix lib/cmake/ )
	endif()
	if (DEFINED APE_SUPERPROJECT)
		set(${variable} ${_prefix}${APE_SUPERPROJECT}-${APE_SUPERPROJECT_VERSION} PARENT_SCOPE)
	else()
		set(${variable} ${_prefix}${PROJECT_NAME}-${PROJECT_VERSION} PARENT_SCOPE)
	endif()
endfunction()

function(amun_install_targets target_install_dir)
	install(TARGETS ${ARGN} EXPORT ${PROJECT_NAME}Targets)
	install(EXPORT ${PROJECT_NAME}Targets DESTINATION ${target_install_dir} NAMESPACE Ape:: FILE ${PROJECT_NAME}Config.cmake)

endfunction()

function(amun_install_config_version target_install_dir)
	set(options NOARCH ARCH)
	cmake_parse_arguments(_local "${options}" "" "" ${ARGN})
	include(CMakePackageConfigHelpers)

	if (_local_NOARCH)
		set(OLD_CMAKE_SIZEOF_VOID_P ${CMAKE_SIZEOF_VOID_P})
		unset(CMAKE_SIZEOF_VOID_P)
	endif()
		write_basic_package_version_file("${PROJECT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake" COMPATIBILITY AnyNewerVersion)
	if (_local_NOARCH)
		set(CMAKE_SIZEOF_VOID_P ${OLD_CMAKE_SIZEOF_VOID_P})
	endif()

	install(FILES "${PROJECT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake" DESTINATION ${target_install_dir})
endfunction()

function (amun_check_build prefix normal install test)
	set(${prefix}_${normal} TRUE PARENT_SCOPE)

	if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR OR 
			CMAKE_SOURCE_DIR STREQUAL APE_SUPERPROJECT_SOURCE_DIR )
		set(${prefix}_${install} TRUE PARENT_SCOPE)
	else()
		set(${prefix}_${install} FALSE PARENT_SCOPE)
	endif()

	if((CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR OR APE_BUILD_TESTING) AND BUILD_TESTING)
		set(${prefix}_${test} TRUE PARENT_SCOPE)
	else()
		set(${prefix}_${test} FALSE PARENT_SCOPE)
	endif()

endfunction()

macro (amun_enable_testing)
	if (NOT AMUN_TESTING_ENABLED)
		include (CTest)
		enable_testing()
		add_custom_target(check COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure -C $<CONFIG>)
		set(AMUN_TESTING_ENABLED TRUE)
	endif()
endmacro()

macro (amun_fetch_lib)
	FetchContent_Declare(${ARGN})
	FetchContent_GetProperties(${ARGV0})
	if(NOT ${ARGV0}_POPULATED)
		FetchContent_Populate(${ARGV0})
	endif()
	#FetchContent_MakeAvailable(${ARGV0})  # this function will call add_directory implicit unexpectedly
endmacro()
