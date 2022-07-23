cmake_minimum_required(VERSION 3.14)

project(ApeAmunTest LANGUAGES CXX)

amun_fetch_lib( catch
	GIT_REPOSITORY ../Catch2.git
	GIT_TAG v3.1.0 )

amun_add_test(ape amun
	FEATURES cxx_std_20
	SOURCES main.cpp
	FOLDER unit_tests
	LINKS Catch2::Catch2WithMain
	)