cmake_minimum_required(VERSION 3.14)

project(ApeAmunTest LANGUAGES CXX)

amun_fetch_lib( catch
	GIT_REPOSITORY https://github.com/catchorg/Catch2.git
	GIT_TAG v2.13.0 )

add_executable(ape_amun_test main.cpp)
target_compile_features(ape_amun_test PUBLIC cxx_std_17)
target_include_directories(ape_amun_test PUBLIC "${catch_SOURCE_DIR}/single_include")

add_test(NAME run_test COMMAND ape_amun_test )
set_tests_properties(run_test PROPERTIES DEPENDS ape_amun_test)
add_dependencies(check ape_amun_test)
