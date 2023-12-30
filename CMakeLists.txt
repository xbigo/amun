cmake_minimum_required(VERSION 3.14)

project(ApeAmun 
	VERSION "0.4.2"
	DESCRIPTION "CMake and other scripts for build"
	LANGUAGES CXX)

if (NOT DEFINED APE_SUPERPROJECT)
	if(AMUN_INCLUDED)
		message(FATAL_ERROR "Amun was not included from self project. Might mixed using installed Amun and Amun project?")
	else()
		include(lib/amun/amun.cmake)
	endif()
endif()

amun_disable_build_in_source()
amun_check_build(AMUN NORMAL INSTALL TEST)

if(${AMUN_NORMAL})
	add_library(ape_amun INTERFACE)
	add_library(Ape::amun ALIAS ape_amun )

	add_custom_target(ape_amun_ SOURCES  lib/amun/amun.cmake lib/amun/ApeAmunConfig-include.cmake)
	set_target_properties(ape_amun_ PROPERTIES FOLDER Libs)
endif()

if(${AMUN_INSTALL})
	amun_get_cmake_install_dir(AMUN_INSTALL_DIR)

	if (NOT DEFINED APE_SUPERPROJECT)
		amun_install_targets(${AMUN_INSTALL_DIR} ape_amun)
		amun_install_config_version(${AMUN_INSTALL_DIR} NOARCH)
		install(FILES lib/amun/ApeAmunConfig-include.cmake DESTINATION ${AMUN_INSTALL_DIR})
	endif()
	install(FILES lib/amun/amun.cmake DESTINATION ${AMUN_INSTALL_DIR})
endif()

if(${AMUN_TEST})
	amun_enable_testing()
	add_subdirectory(test)
endif()
