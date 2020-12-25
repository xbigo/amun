if(NOT CMAKE_VERSION VERSION_LESS 3.10)
  include_guard()
endif()

set (AMUN_INCLUDED TRUE)

find_package(Git)
if (NOT Git_FOUND)
	message(FATAL_ERROR "Git not found")
endif()

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

function(amun_git_url output url )
	string(REGEX MATCH "^https?://[^/]+/|^git@[^/]+:" site ${url} )
	if (site)
		set(${output} ${url} PARENT_SCOPE)
		return()
	endif()

	execute_process(
		COMMAND ${GIT_EXECUTABLE} ls-remote --get-url
		WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
		RESULT_VARIABLE result
		OUTPUT_VARIABLE git_url)

	if (NOT result EQUAL "0")
		message(FATAL_ERROR "Failed to get git remote url at ${CMAKE_CURRENT_LIST_DIR}")
	endif()

	string(REGEX MATCH "(^https?://[^/]+/|^git@[^/]+:)(.*$)" site ${git_url})
	if (NOT site)
		message(FATAL_ERROR "Unsupported git url format: ${git_url} ${site}")
	endif()
	set(site ${CMAKE_MATCH_1})
	set(path ${CMAKE_MATCH_2})

	if (NOT ${url} MATCHES "^\\.\\./")
		set(${output} ${site}${url} PARENT_SCOPE)
		return()
	endif()

	while (url MATCHES "^\\.\\./")
		get_filename_component(path ${path} DIRECTORY)
		string(SUBSTRING ${url} 3 -1 url)
	endwhile()
	if (path)
		set(path ${path}/${url})
	else()
		set(path ${url})
	endif()

	set(${output} ${site}${path} PARENT_SCOPE)

endfunction()

macro (amun_fetch_lib)
	
	set(args "${ARGN}")
	cmake_parse_arguments(_amun_fetch_lib "" "GIT_REPOSITORY" "" ${args})
	if (_amun_fetch_lib_GIT_REPOSITORY)
		amun_git_url(_amun_url ${_amun_fetch_lib_GIT_REPOSITORY})
		list(FIND args "GIT_REPOSITORY" idx)
		math(EXPR idx "${idx} + 1")
		list(REMOVE_AT args ${idx})
		list(INSERT args ${idx} ${_amun_url})
	endif()

	FetchContent_Declare(${args})
	FetchContent_GetProperties(${ARGV0})
	if(NOT ${ARGV0}_POPULATED)
		FetchContent_Populate(${ARGV0})
	endif()
	unset(_amun_url)
	unset(_amun_fetch_lib_GIT_REPOSITORY)
endmacro()

function(amun_enable_features name)
	set(multiValues FEATURES)
	cmake_parse_arguments(_local "" "" "${multiValues}" ${ARGN})

	if (_local_FEATURES)
		target_compile_features(${name} ${_local_FEATURES})
	endif()

	if (MSVC)
		get_target_property(_type ${name} TYPE)
		set(_local_type PUBLIC)
		
		if ("${_type}" STREQUAL "INTERFACE_LIBRARY")
			set(_local_type INTERFACE)
		endif()

		target_compile_options(${name} ${_local_type} "/Zc:__cplusplus")
	endif()
endfunction()

function(amun_add_test prefix name )
	set(oneValue FOLDER WORKING_DIRECTORY)
	set(multiValues FEATURES SOURCES INCLUDES LINKS DEFINES)
	cmake_parse_arguments(_local "" "${oneValue}" "${multiValues}" ${ARGN})

	set(_target_name ${prefix}_${name}_test)

	add_executable(${_target_name} main.cpp)
	if (MSVC)
		target_compile_options(${_target_name} PUBLIC "/Zc:__cplusplus")
	endif()
	if (_local_DEFINES)
		target_compile_definitions(ape_thread_test ${_local_DEFINES}) 
	endif()
	if (_local_FEATURES)
		target_compile_features(${_target_name} PUBLIC ${_local_FEATURES})
	endif()
	if (_local_INCLUDES)
		target_include_directories(${_target_name} PUBLIC "${_local_INCLUDES}")
	endif()
	if (_local_LINKS)
		target_link_libraries(${_target_name} ${_local_LINKS})
	endif()
	if (_local_WORKING_DIRECTORY)
		add_test(NAME ${name}_test COMMAND ${_target_name} WORKING_DIRECTORY "${_local_WORKING_DIRECTORY}" )
	else()
		add_test(NAME ${name}_test COMMAND ${_target_name} )
	endif()
	set_tests_properties(${name}_test PROPERTIES DEPENDS ${_target_name})
	add_dependencies(check ${_target_name})

	if (_local_FOLDER)
		set_target_properties(${_target_name} PROPERTIES FOLDER ${_local_FOLDER})
	endif()
endfunction()

function(amun_fake_project name )
	set(oneValue FOLDER)
	set(multiValues SOURCES INCLUDES)
	cmake_parse_arguments(_local "" "${oneValue}" "${multiValues}" ${ARGN})
	
	add_library(${name} OBJECT EXCLUDE_FROM_ALL ${_local_SOURCES})
	amun_enable_features(${name} FEATURES INTERFACE cxx_std_17)
	target_compile_options(${name} PUBLIC "/Zc:__cplusplus")

	if (_local_FOLDER)
		set_target_properties(${name} PROPERTIES FOLDER ${_local_FOLDER})
	endif()
	if (_local_INCLUDES)
		target_include_directories(${name} PUBLIC "${_local_INCLUDES}")
	endif()
endfunction()

