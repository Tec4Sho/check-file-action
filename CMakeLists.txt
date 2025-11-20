cmake_minimum_required(VERSION 3.10) # Specifies the minimum required CMake version

# ... other project settings ... #
project(MyProject VERSION 1.0 LANGUAGES C)

set(LLVM_ENABLE_PROJECTS clang;clang-tools-extra)

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

file(GLOB_RECURSE SOURCES "main.c")

add_executable(MyProject ${SOURCES}) # Creates an executable target named "MyProject" from sources file

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
