if(NOT CMAKE_VERSION VERSION_LESS 3.10)
  include_guard()
endif()

set (AMUN_INCLUDED TRUE)

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

function(amun_get_install_dir variable)
	if (DEFINED APE_PROJECT_NAME)
		set(${variable} lib/cmake/${APE_PROJECT_NAME}-${APE_PROJECT_VERSION} PARENT_SCOPE)
	else()
		set(${variable} lib/cmake/${PROJECT_NAME}-${PROJECT_VERSION} PARENT_SCOPE)
	endif()
endfunction()

function(amun_install_targets target_install_dir)
	install(TARGETS ape_amun EXPORT ${PROJECT_NAME}Targets)
	install(EXPORT ${PROJECT_NAME}Targets DESTINATION ${target_install_dir} NAMESPACE Ape:: FILE ${PROJECT_NAME}Config.cmake)

endfunction()

function(amun_install_config_version target_install_dir)
	set(options NOARCH ARCH)
	cmake_parse_arguments(_local "${options}" "" "" ${ARGN})

	if (_local_NOARCH)
		include(CMakePackageConfigHelpers)
		set(OLD_CMAKE_SIZEOF_VOID_P ${CMAKE_SIZEOF_VOID_P})
		unset(CMAKE_SIZEOF_VOID_P)
		write_basic_package_version_file("${PROJECT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake" COMPATIBILITY AnyNewerVersion)
		set(CMAKE_SIZEOF_VOID_P ${OLD_CMAKE_SIZEOF_VOID_P})
	endif()

	install(FILES "${PROJECT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake" DESTINATION ${target_install_dir})
endfunction()

function (amun_check_build prefix normal install test)
	set(${prefix}_${normal} TRUE PARENT_SCOPE)

	if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR OR APE_SUPER_PROJECT)
		set(${prefix}_${install} TRUE PARENT_SCOPE)
	else()
		set(${prefix}_${install} FALSE PARENT_SCOPE)
	endif()

	if((CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR OR APE_AMUN_BUILD_TESTING) AND BUILD_TESTING)
		set(${prefix}_${test} TRUE PARENT_SCOPE)
	else()
		set(${prefix}_${test} FALSE PARENT_SCOPE)
	endif()

endfunction()

macro (amun_enable_testing)
	enable_testing()
	add_custom_target(check COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure -C $<CONFIG>)
endmacro()

macro (amun_fetch_lib)
	FetchContent_Declare(${ARGN})
	FetchContent_MakeAvailable(${ARGV0})
endmacro()
