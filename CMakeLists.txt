cmake_minimum_required(VERSION 3.14)

project(ApeAmun 
	VERSION "0.1.0"
	DESCRIPTION "CMake and other scripts for build"
	LANGUAGES CXX)

if (AMUN_INCLUDED)
	message(FATAL "Amun was not from it self")
endif()

include(lib/amun/amun.cmake)
amun_disable_build_in_source()
amun_check_build(AMUN NORMAL INSTALL TEST)

if(${AMUN_NORMAL})
	add_library(ape_amun INTERFACE)
	add_library(Ape::amun ALIAS ape_amun )
endif()

if(${AMUN_INSTALL})
	amun_get_cmake_install_dir(AMUN_INSTALL_DIR)

	amun_install_targets(${AMUN_INSTALL_DIR})
	amun_install_config_version(${AMUN_INSTALL_DIR} NOARCH)
	install(DIRECTORY lib/amun DESTINATION ${AMUN_INSTALL_DIR})

endif()

if(${AMUN_TEST})
	amun_enable_testing()
	add_subdirectory(test)
endif()
