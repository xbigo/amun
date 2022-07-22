cmake_minimum_required(VERSION 3.14)

project(ApeAmunTest LANGUAGES CXX)

amun_fetch_lib( catch
	GIT_REPOSITORY ../Catch2.git
	GIT_TAG v2.13.0 )

amun_add_test(ape amun
	FEATURES cxx_std_20
	SOURCES main.cpp
	INCLUDES "${catch_SOURCE_DIR}/single_include"
	FOLDER unit_tests
	)