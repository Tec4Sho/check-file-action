cmake_minimum_required(VERSION 3.30.0) # Specifies the minimum required CMake version

# ... many examples of user defined project settings for C/C++ ... #

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
    set(CMAKE_C_CLANG_TIDY "${CLANG_TIDY_EXE};-checks=-*,clang-analyzer-*;-header-filter=.*;-fix;-fix-errors;-fix-notes")
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

if(MINGW)
  SET(CMAKE_RC_COMPILE_OBJECT "<CMAKE_RC_COMPILER> -O coff -DwxUSE_DPI_AWARE_MANIFEST=2 -I \"${CMAKE_CURRENT_SOURCE_DIR}/include\" -i <SOURCE> -o <OBJECT>")
endif(MINGW)

set(LLVM_ENABLE_PROJECTS "clang;clang-tools-extra")

# .add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}")

if(DEFINED PROJECT_SRC_DIRS)
  message(STATUS "Project Source: ${PROJECT_SRC_DIRS}")
else()
  message(STATUS "Project Source: $ENV{github_source_dirs}")
endif()

if($ENV{github_absolute_path})
  message(STATUS "Project Paths: Absolute Mode")
  file(GLOB_RECURSE PROJECT_SRC_FILES "*.c")
else()
  message(STATUS "Project Paths: Relative Mode")
  file(GLOB_RECURSE PROJECT_SRC_FILES RELATIVE "*.c")
endif()

list(SORT PROJECT_SRC_FILES)

list(LENGTH PROJECT_SRC_FILES SOURCE_COUNT)

message(STATUS "Source file count: ${SOURCE_COUNT}")

add_executable("${PROJECT_NAME}") # Creates an executable target named "MyProject" from source files

if(DEFINED PROJECT_SRC_FILES)
  message(STATUS "Project Files: cmake added source files")
elseif(DEFINED $ENV{github_source_files})
  message(STATUS "Project Files: cmake found source files")
else()
  message(STATUS "Project Files: cmake added no files")
endif()

if(DEFINED PROJECT_INCLUDE_SRC)
  message(STATUS "Project Auto Includes: true")
  set(INCLUDE_SRC ON CACHE BOOL "${PROJECT_INCLUDE_SRC}")
elseif($ENV{include_source})
  message(STATUS "Project Auto Includes: true")
  set(INCLUDE_SRC ON CACHE BOOL "$ENV{include_source}")
else()
  message(STATUS "Project Auto Includes: false")
  set(INCLUDE_SRC "false")
endif()

# Automatically find all header files recursively
file(GLOB_RECURSE ALL_HEADERS CONFIGURE_DEPENDS "*.h")

# Find all subdirectories that contain at least one header file
file(GLOB_RECURSE include_files LIST_DIRECTORIES true "include/*.h")

set(CHECK_FILE_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/check-file-sources.txt")

# Add the system, project include directory to your target. Comment to disable an add your custom target_include_directories
# .set(PROJECT_AUTO_INCLUDE "true")

if(DEFINED PROJECT_AUTO_INCLUDE)
  target_sources("${PROJECT_NAME}" PRIVATE "${PROJECT_SRC_FILES}")
  if(EXISTS "${CHECK_FILE_SOURCES}" AND INCLUDE_SRC)
    target_include_directories("${PROJECT_NAME}" PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/include/*")
    file(STRINGS "${CHECK_FILE_SOURCES}" FILE_PATHS)
    message(STATUS "Processing auto include source paths: $ENV{include_count}")
    foreach(INCLUDE_PATH IN LISTS FILE_PATHS)
      target_include_directories("${PROJECT_NAME}" PRIVATE "${INCLUDE_PATH}")
    endforeach()
    message(STATUS "Project Includes: cmake added include directories. clang analyzing multiple includes [check 1]")
  elseif($ENV{github_include_dirs})
    target_include_directories("${PROJECT_NAME}" PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/include/linux")
    target_include_directories("${PROJECT_NAME}" PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/include/*/")
    target_include_directories("${PROJECT_NAME}" PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/include")
    target_include_directories("${PROJECT_NAME}" PRIVATE ENV${github_include_dirs})
    target_include_directories("${PROJECT_NAME}" SYSTEM PRIVATE "/usr/include")
    target_include_directories("${PROJECT_NAME}" SYSTEM PRIVATE "/home/runner/.local/lib/python*/site-packages/clang_tidy/data/lib/clang/*/include")
    message(STATUS "Project Includes: cmake added include directories. clang analyzing multiple includes [check 2]")
  elseif(DEFINED PROJECT_INCLUDE_DIRS)
    foreach(PROJECT_INCLUDE_DIR ${PROJECT_INCLUDE_DIRS})
      target_include_directories("${PROJECT_NAME}" PRIVATE "${PROJECT_INCLUDE_DIR}")
    endforeach()
    message(STATUS "Project Includes: cmake added include directories. clang analyzing multiple includes [check 3]")
  elseif(DEFINED include_files)
    set(include_dirs "")
    foreach(file_path ${include_files})
      get_filename_component(dir_path ${file_path} DIRECTORY)
      list(APPEND include_dirs ${dir_path})
    endforeach()
    list(REMOVE_DUPLICATES include_dirs)
    target_include_directories("${PROJECT_NAME}" PRIVATE "${include_dirs}")
    target_include_directories("${PROJECT_NAME}" SYSTEM PUBLIC "/usr/include")
    message(STATUS "Project Includes: cmake added include directories. clang analyzing include directory [check 4]")
  elseif(DEFINED ALL_HEADERS) # Extract the unique directory paths from the list of header files
    set(PROJECT_INCLUDE_DIRS "")
    foreach(_headerFile ${ALL_HEADERS})
      get_filename_component(_dir ${_headerFile} PATH)
      list(APPEND PROJECT_INCLUDE_DIRS ${_dir})
    endforeach()
    list(REMOVE_DUPLICATES PROJECT_INCLUDE_DIRS)
    target_include_directories("${PROJECT_NAME}" PRIVATE "${PROJECT_INCLUDE_DIRS}")
    target_include_directories("${PROJECT_NAME}" SYSTEM PUBLIC "/usr/include")
    message(STATUS "Project Includes: cmake added include directories. clang analyzing all headers [check 5]")
  else()
    target_include_directories("${PROJECT_NAME}" PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/include/*/")
  endif()
else()
# Add your custom includes here after commenting # set(PROJECT_AUTO_INCLUDE "true") above
  set(FILE_COUNT 0)
  message(STATUS "Source File: ${FILE_COUNT}")
  foreach(FILE ${PROJECT_SRC_FILES})
    math(EXPR FILE_COUNT "${FILE_COUNT} + 1")
    set(FILE_CONTENTS "")
    file(READ "${FILE}" FILE_CONTENTS)
    string(REGEX MATCHALL "#include[ \t]+[<\"]([^>\"]+)[>\"]" MATCHES "${FILE_CONTENTS}")
    set(HEADER_LIST "")
    foreach(MATCH ${MATCHES})
      string(REGEX REPLACE "#include[ \t]+[<\"]([^>\"]+)[>\"]" "\\1" HEADER_NAME "${MATCH}")
      list(APPEND HEADER_LIST "${HEADER_NAME}")
    endforeach()
    list(REMOVE_DUPLICATES HEADER_LIST)
    foreach(file_path ${HEADER_LIST})
      file(GLOB_RECURSE PROJECT_INCLUDES RELATIVE LIST_DIRECTORIES true "${file_path}")
      list(APPEND include_dirs ${PROJECT_INCLUDES})
    endforeach()
    list(REMOVE_DUPLICATES include_dirs)
    target_sources("${PROJECT_NAME}" PRIVATE "${FILE}")
    target_include_directories("${PROJECT_NAME}" PRIVATE "${include_dirs}")
    message(STATUS "${CR}Source File: ${FILE_COUNT}")
  endforeach()
  message(STATUS "${CR}Source File: ${FILE_COUNT} - Done")
  message(STATUS "Project Includes: cmake added user defined include directories. clang analyzing includes added [check 6 custom]")
endif()

# .set(CMAKE_CXX_CLANG_TIDY "clang-tidy")

# .set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2 -Wall -Werror -pedantic")

if($ENV{github_build_project})
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O2 -Wall -Werror -Wno-error=unused-command-line-argument -Qunused-arguments -std=c90")
  message(STATUS "Project Build: clang tools analyze test build")
  message(STATUS "CMAKE_C_FLAGS; ${CMAKE_C_FLAGS}")
else()
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O1 -ferror-limit=0 -Wno-error=unused-command-line-argument -Qunused-arguments -std=c90")
  message(STATUS "Project Build: clang tools analyze only")
  message(STATUS "CMAKE_C_FLAGS; ${CMAKE_C_FLAGS}")
endif()

# .set(CMAKE_C_LINK_FLAGS "${CMAKE_C_LINK_FLAGS} -O2 -Wall -Werror -pedantic -std=c99")

# .set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -O2 -Wall -Werror -pedantic -std=c99")

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

set(CMAKE_C_USE_RESPONSE_FILE_FOR_INCLUDES ON) # Useful/Needed for large list of include directories

# .file(GLOB_RECURSE PROJECT_SRC_INCLUDES LIST_DIRECTORIES true "/include/")

# .file(GLOB_RECURSE INCLUDES LIST_DIRECTORIES true 'include')

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