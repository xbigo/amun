# Useful CMake code snippets

1. Grep version string from file

    ```cmake
    file(STRINGS include/ape/config/version.hpp _define_version_ REGEX "APE_CONFIG_VERSION")
    string(REGEX MATCH "([0-9\\.]+)" _version_str_ "${_define_version_}")
    ```

2. Check top level cmake or embeded

    Check the container dir of current CMakeLists.txt or top level CMakeLists.txt:

    ```cmake
    if (CMAKE_BINARY_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
        message(FATAL_ERROR "Building in-source is not supported! Create a build dir and remove ${CMAKE_SOURCE_DIR}/CMakeCache.txt")
    endif()
    ```

    Or check the project name:

    ```cmake
    if(CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME)
    # Top project, enable testing and add 3rd parties
        enable_testing()
    endif()
    ```

3. END
