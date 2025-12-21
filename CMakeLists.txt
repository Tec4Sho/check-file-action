cmake_minimum_required(VERSION 3.30) # Specifies the minimum required CMake version

# ... many examples of user defined project settings ... #

if(DEFINED GITHUB_PROJECT_NAME)
  set(PROJECT_NAME "${GITHUB_PROJECT_NAME}")
else()
  set(PROJECT_NAME "$ENV{github_repository}")
endif()

project("${PROJECT_NAME}" VERSION 1.0 LANGUAGES C)

message(STATUS "Project Owner: $ENV{GITHUB_REPOSITORY_OWNER}")

message(STATUS "Project Name: ${PROJECT_NAME}")

message(STATUS "Workspace Path: $ENV{GITHUB_WORKSPACE}")

find_program(CLANG_TIDY_EXE "clang-tidy")
  if(CLANG_TIDY_EXE)
    message(STATUS "clang-tidy found: ${CLANG_TIDY_EXE}")
    # Configure clang-tidy to run with all checks and fix errors
    # .set(CMAKE_C_CLANG_TIDY "${CLANG_TIDY_EXE};-checks=*;-header-filter=.;-fix")
    set(CMAKE_C_CLANG_TIDY "${CLANG_TIDY_EXE};-checks=-*,modernize-loop-convert,readability-identifier-naming,clang-analyzer-*;-fix")
    # You can also specify specific checks instead of -checks=*
    # .set(CMAKE_CXX_CLANG_TIDY "${CLANG_TIDY_EXE};-checks=modernize-loop-convert,readability-identifier-naming,clang-analyzer-cplusplus;-fix")
  else()
    message(WARNING "clang-tidy not found! Static analysis will be skipped.")
  endif()

find_package(Git REQUIRED)
  if(GIT_FOUND AND EXISTS "${PROJECT_SOURCE_DIR}/.git")
    message(STATUS "Populating Git submodule.")
    execute_process(COMMAND "${GIT_EXECUTABLE}" submodule update --init --recursive WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}" RESULT_VARIABLE GIT_SUBMOD_RESULT)
    if(NOT GIT_SUBMOD_RESULT EQUAL "0")
        message(FATAL_ERROR "git submodule update --init --recursive failed with ${GIT_SUBMOD_RESULT}.")
    endif()
  endif()

# .set(_saved_CMAKE_MESSAGE_LOG_LEVEL "${CMAKE_MESSAGE_LOG_LEVEL}")

# .set(CMAKE_MESSAGE_LOG_LEVEL WARNING)

set(CMAKE_C_CLANG_TIDY "clang-tidy")

set(LLVM_ENABLE_PROJECTS "clang;clang-tools-extra")

# .add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}")

if(DEFINED PROJECT_SRC_DIRS)
  message(STATUS "Project Source: ${PROJECT_SRC_DIRS}")
else()
  message(STATUS "Project Source: $ENV{github_source_dirs}")
endif()

file(GLOB_RECURSE PROJECT_SRC_FILES "*.c")

add_executable("${PROJECT_NAME}" "${PROJECT_SRC_FILES}") # Creates an executable target named "MyProject" from source files

target_sources("${PROJECT_NAME}" PUBLIC "${PROJECT_SRC_FILES}") 

if(DEFINED PROJECT_SRC_FILES)
  message(STATUS "Project Files: cmake added source files")
elif($ENV{github_source_files})
  message(STATUS "Project Files: cmake found source files")
else()
  message(STATUS "Project Files: cmake added no files")
endif()

if(DEFINED PROJECT_SRC_INCLUDES)
  target_include_directories("${PROJECT_NAME}" PRIVATE "${PROJECT_SRC_INCLUDES}")
  message(STATUS "Project Includes: cmake added include directories. clang analyzer")
else()
# .file(GLOB_RECURSE PROJECT_SRC_INCLUDES LIST_DIRECTORIES true "/include/")
  target_include_directories("${PROJECT_NAME}" PRIVATE "ENV${target_include_dirs}")
  message(STATUS "Project Includes: cmake added include directories. codechecker analyzer")
endif()

# Automatically find all header files recursively
file(GLOB_RECURSE ALL_HEADERS CONFIGURE_DEPENDS "*.h")

# Extract the unique directory paths from the list of header files
set(PROJECT_INCLUDE_DIRS "")
  foreach(_headerFile ${ALL_HEADERS})
    get_filename_component(_dir ${_headerFile} PATH)
    list(APPEND PROJECT_INCLUDE_DIRS ${_dir})
  endforeach()
list(REMOVE_DUPLICATES PROJECT_INCLUDE_DIRS)

# Add the unique, collected directories to your target
target_include_directories("${PROJECT_NAME}" SYSTEM PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")

# .set(CMAKE_CXX_CLANG_TIDY "clang-tidy")

# .set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2 -Wall -Werror -pedantic")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O2 -Wall -Werror -std=c90")

# .set(CMAKE_C_LINK_FLAGS "${CMAKE_C_LINK_FLAGS} -O2 -Wall -Werror -pedantic -std=c99")

# .set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -O2 -Wall -Werror -pedantic -std=c99")

message(STATUS "CMAKE_C_FLAGS=${CMAKE_C_FLAGS}")

# .set(CMAKE_C_FLAGS_DEBUG "put your flags") set(CMAKE_C_FLAGS_MINSIZEREL "put your flags") set(CMAKE_C_FLAGS_RELWITHDEBINFO "put your flags") set(CMAKE_C_FLAGS_RELEASE "put your flags")

# .set(CMAKE_CXX_FLAGS_DEBUG "put your flags") set(CMAKE_CXX_FLAGS_MINSIZEREL "put your flags") set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "put your flags") set(CMAKE_CXX_FLAGS_RELEASE "put your 

# .set(CMAKE_EXPORT_COMPILE_COMMANDS ON) # does not produce the json file on wrong cmake version 

set(CLANG_TIDY_ENABLE_STATIC_ANALYZER ON)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE INTERNAL "") # works

set(CMAKE_BUILD_TYPE Release)

# .set(CMAKE_CXX_STANDARD 17) # Sets the C++ standard to C++17

# .set(CMAKE_CXX_STANDARD_REQUIRED ON) # Ensures the specified C++ standard is strictly enforced

# .set(CMAKE_CXX_EXTENSIONS ON) # Enables compiler-specific extensions for C++

# .set(CMAKE_CXX_COMPILER clang++) # Sets the C++ compiler

set(CMAKE_C_STANDARD 90) # Sets the C standard to C90 <C89>

set(CMAKE_C_STANDARD_REQUIRED ON) # Ensures the specified C standard is strictly enforced

set(CMAKE_C_EXTENSIONS ON) # Enables compiler-specific extensions for C

set(CMAKE_C_COMPILER clang) # Sets the C compiler

# .set(CMAKE_CXX_USE_RESPONSE_FILE_FOR_INCLUDES OFF) 

set(CMAKE_C_USE_RESPONSE_FILE_FOR_INCLUDES ON)

# .file(GLOB_RECURSE INCLUDES LIST_DIRECTORIES true 'include')

# .include_directories(${INCLUDES})

# .set(CMAKE_MESSAGE_LOG_LEVEL "${_saved_CMAKE_MESSAGE_LOG_LEVEL}")

# .target_include_directories(MyProject PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

# .add_executable(MyProject main.cpp) 

# .add_executable(MyExecutable main.cpp my_source.cpp)

# .target_link_libraries(MyExecutable PRIVATE MyLibrary)

# .add_library(MyLibrary STATIC my_library_source.cpp)

# .install(TARGETS MyExecutable DESTINATION bin)

# .install(TARGETS MyLibrary DESTINATION lib)

# .install(FILES my_library.h DESTINATION include)

# .set_target_properties(MyProject PROPERTIES LINKER_LANGUAGE CXX)

# .set_target_properties(MyProject PROPERTIES CXX_STANDARD 17) 

# .enable_language(CUDA)

# .set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/bin)

# .add_subdirectory(src)

# .find_package(PkgConfig REQUIRED)

# .pkg_search_module(LIBCONFIG++ REQUIRED libconfig++)

# .pkg_search_module(LIBCONFIG REQUIRED libconfig)

# .target_include_directories(MyProject PUBLIC ${LIBCONFIG++_INCLUDE_DIRS})

# .target_include_directories(MyProject PUBLIC ${LIBCONFIG_INCLUDE_DIRS})

# .target_link_libraries(MyProject PUBLIC ${LIBCONFIG_LINK_LIBRARES})

# .GET_DIRECTORY_PROPERTY(output INCLUDE_DIRECTORIES) 

# .get_property(INCLUDE DIRECTORY ${CMAKE_SOURCE_DIR} PROPERTY INCLUDE_DIRECTORIES)

# .message(WARNING ${output}) # This will print all -I dirs like: /usr/local/include/

set_target_properties("${PROJECT_NAME}" PROPERTIES LINKER_LANGUAGE C)

set_target_properties("${PROJECT_NAME}" PROPERTIES C_STANDARD 90) 

execute_process(
    COMMAND "${CMAKE_COMMAND}" -E create_symlink
        "${CMAKE_BINARY_DIR}/compile_commands.json"
        "${CMAKE_SOURCE_DIR}/compile_commands.json"
)

function(output_src_includes)
    set(src_dir_str "")
    if(DEFINED PROJECT_INCLUDE_DIRS)
      foreach(DIR "${PROJECT_INCLUDE_DIRS}")
        set(src_dir_str "${DIR}\n")
      endforeach()
      set(src_dir "${CMAKE_BINARY_DIR}/cmake-include-dirs.txt")
      file(WRITE "${src_dir}" "${src_dir_str}")
      message(STATUS "${PROJECT_NAME} header file directories written to: ${src_dir}")
    endif()
endfunction()

function(output_src_files)
    set(src_files_str "")
    if(DEFINED PROJECT_SRC_FILES)
      foreach(FILE "${PROJECT_SRC_FILES}")
        set(src_files_str "${FILE}\n")
      endforeach()
      set(src_file "${CMAKE_BINARY_DIR}/cmake-source-files.txt")
      file(WRITE "${src_file}" "${src_files_str}")
      message(STATUS "${PROJECT_NAME} source files written to: ${src_file}")
    endif()
endfunction()

output_src_includes()

output_src_files()

# .Place build artifacts in ${CMAKE_BINARY_DIR}/{bin,lib}
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin CACHE PATH "")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib CACHE PATH "")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib CACHE PATH "")

