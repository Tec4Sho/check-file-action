cmake_minimum_required(VERSION 3.19) # Specifies the minimum required CMake version

# ... other project settings ... #
project(MyProject VERSION 1.0 LANGUAGES C)

message(STATUS "Workspace Project Path: $ENV{GITHUB_WORKSPACE}")

set(LLVM_ENABLE_PROJECTS clang;clang-tools-extra)

# .set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2 -Wall -Werror -pedantic")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O2 -Wall -Werror -pedantic")

# .set(CMAKE_EXPORT_COMPILE_COMMANDS ON) # does not produce the json file on wrong cmake version 

set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE INTERNAL "") # works

set(CMAKE_BUILD_TYPE Release)

set(CMAKE_C_STANDARD 90) # Sets the C standard to C90 <C89>

# .set(CMAKE_CXX_STANDARD 17) # Sets the C++ standard to C++17

# .set(CMAKE_CXX_STANDARD_REQUIRED ON) # Ensures the specified C++ standard is strictly enforced

# .set(CMAKE_CXX_EXTENSIONS ON) # Enables compiler-specific extensions for C++

# .set(CMAKE_CXX_COMPILER clang++) # Sets the C++ compiler

set(CMAKE_C_STANDARD 17) # Sets the C standard to C++17

set(CMAKE_C_STANDARD_REQUIRED ON) # Ensures the specified C standard is strictly enforced

set(CMAKE_C_EXTENSIONS ON) # Enables compiler-specific extensions for C

set(CMAKE_C_COMPILER clang) # Sets the C compiler

find_program(CLANG_TIDY_EXE "clang-tidy")
  if(CLANG_TIDY_EXE)
    message(STATUS "clang-tidy found: ${CLANG_TIDY_EXE}")
    # Configure clang-tidy to run with all checks and fix errors
    set(CMAKE_C_CLANG_TIDY "${CLANG_TIDY_EXE};-checks=*; -header-filter=.; -fix")
    # You can also specify specific checks instead of -checks=*
    # set(CMAKE_CXX_CLANG_TIDY "${CLANG_TIDY_EXE};-checks=modernize-loop-convert,readability-identifier-naming;-fix")
  else()
    message(WARNING "clang-tidy not found! Static analysis will be skipped.")
  endif()

# .set(CMAKE_CXX_USE_RESPONSE_FILE_FOR_INCLUDES OFF) 

set(CMAKE_C_USE_RESPONSE_FILE_FOR_INCLUDES OFF) 

file(GLOB_RECURSE SOURCES "*.c")

add_executable(MyProject ${SOURCES}) # Creates an executable target named "MyProject" from sources file

# .file(GLOB_RECURSE INCLUDES LIST_DIRECTORIES true "include")

target_include_directories(MyProject PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

# .include_directories(${INCLUDES})

# .add_executable(MyProject main.cpp) 

# .add_executable(MyExecutable main.cpp my_source.cpp)

# .target_link_libraries(MyExecutable PRIVATE MyLibrary)

# .add_library(MyLibrary STATIC my_library_source.cpp)

# .install(TARGETS MyExecutable DESTINATION bin)

# .install(TARGETS MyLibrary DESTINATION lib)

# .install(FILES my_library.h DESTINATION include)

# .set_target_properties(MyProject PROPERTIES LINKER_LANGUAGE CXX)

# .set_target_properties(MyProject PROPERTIES CXX_STANDARD 17) 

set_target_properties(MyProject PROPERTIES LINKER_LANGUAGE C)

set_target_properties(MyProject PROPERTIES C_STANDARD 90) 

# .enable_language(CUDA)

# .set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/bin)

# .add_subdirectory(src)

# .find_package(PkgConfig REQUIRED)

# .pkg_search_module(LIBCONFIG++ REQUIRED libconfig++)

# .pkg_search_module(LIBCONFIG REQUIRED libconfig)

# .target_include_directories(MyProject PUBLIC ${LIBCONFIG++_INCLUDE_DIRS})

# .target_include_directories(MyProject PUBLIC ${LIBCONFIG_INCLUDE_DIRS})

# .target_link_libraries(MyProject PUBLIC ${LIBCONFIG_LINK_LIBRARES})

execute_process(
    COMMAND ${CMAKE_COMMAND} -E create_symlink
        ${CMAKE_BINARY_DIR}/compile_commands.json
        ${CMAKE_SOURCE_DIR}/compile_commands.json
)
