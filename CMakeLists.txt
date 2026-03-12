cmake_minimum_required(VERSION 4.1.0) # Specifies the minimum required CMake version

set(CMAKE_CONFIGURATION_TYPES "Debug" CACHE STRING "" FORCE)

string(ASCII 13 CR)

	if(DEFINED GITHUB_PROJECT_NAME)
	  set(PROJECT_NAME "${GITHUB_PROJECT_NAME}")
	else()
	  set(PROJECT_NAME "$ENV{github_repository}")
	endif()
	
	if($ENV{github_build_project})
	  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O2 -Wall -Werror -Wno-error=unused-command-line-argument -Qunused-arguments -std=c90")
	  message(STATUS "Project Build: clang tools analyze test build")
	  message(STATUS "CMAKE_C_FLAGS: ${CMAKE_C_FLAGS}")
	else()
	  add_compile_options(
	    "-Wall" "-Wpedantic" "-Wextra" "-fexceptions" "-std=c90"
	    "$<$<CONFIG:DEBUG>:-O0;-ferror-limit=0;-Wno-error=unused-command-line-argument;-Qunused-arguments>"
	  )
	  set(C_FLAGS "${C_FLAGS} -O1 -ferror-limit=0 -Wno-error=unused-command-line-argument -Qunused-arguments -std=c90")
	  message(STATUS "Project Build: clang tools analyze only")
	  message(STATUS "C_FLAGS: ${C_FLAGS}")
	endif()
	
# For arm 32 an 64 bit builds using inputs.arch=arm

# ... many examples of user defined project settings for C/C++ ... #

project("${PROJECT_NAME}" VERSION 1.0 LANGUAGES C)

message(STATUS "Project Owner: $ENV{GITHUB_REPOSITORY_OWNER}")

message(STATUS "Project Name: ${PROJECT_NAME}")

message(STATUS "Workspace Path: $ENV{GITHUB_WORKSPACE}")

if($ENV{rsp})
  set(CMAKE_C_USE_RESPONSE_FILE_FOR_INCLUDES ON) # Compile command json for small list of include directories, needed for cppcheck only
else()
  set(CMAKE_C_USE_RESPONSE_FILE_FOR_INCLUDES OFF) # Useful/Needed for large list of include directories, is not used by cppcheck only
endif()

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

# 1. Find the file
# file(GLOB CHECK_FILE_PATH "build-source-files.txt")
# set(CHECK_FILE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/build-source-files.txt")

# 2. Start the logic if file is found
# 1. Anchor strictly to the Workspace Root
set(G_ROOT "$ENV{GITHUB_WORKSPACE}")
set(CHECK_FILE_NAME "build-source-files.txt")

# 2. Find the artifact in the current dir (where you copied it)
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${CHECK_FILE_NAME}")
  file(STRINGS "${CMAKE_CURRENT_SOURCE_DIR}/${CHECK_FILE_NAME}" PROJECT_SRC_FILES)
  # Create the Target
  add_executable("${PROJECT_NAME}")
  set(FILE_COUNT 0)
  message(CHECK_START "Generating portable database for ${PROJECT_NAME}")
  foreach(REL_FILE IN LISTS PROJECT_SRC_FILES)
    # 3. Use Workspace + Relative path to verify it exists on the runner
    set(LIVE_FILE "${G_ROOT}/${REL_FILE}")
    if(EXISTS "${LIVE_FILE}")
      math(EXPR FILE_COUNT "${FILE_COUNT} + 1") 
      # Add to target using the Workspace-anchored path
      # This ensures compile_commands.json is valid for the Clang scan step
      target_sources("${PROJECT_NAME}" PRIVATE "${LIVE_FILE}") 
      message(STATUS "Added [${FILE_COUNT}]: ${REL_FILE}")
    else()
      math(EXPR FILE_COUNT "${FILE_COUNT} + 1") 
      file(GLOB_RECURSE FILE_PATH "${REL_FILE}")
      target_sources("${PROJECT_NAME}" PRIVATE "${FILE_PATH}") 
      message(STATUS "Added [${FILE_COUNT}]: ${REL_FILE}")
    endif()
  endforeach()
  # 4. Add ONLY the Standard Kernel Include Tree (No Scanning)
  # This provides the base headers without the risk of 'missing' local folders
  target_include_directories("${PROJECT_NAME}" PRIVATE 
    "${G_ROOT}/include"
    "${G_ROOT}/include/uapi"
    "${G_ROOT}/arch/$ENV{arch}/include"
    "${G_ROOT}/arch/$ENV{arch}/include/uapi"
  )
  set_target_properties("${PROJECT_NAME}" PROPERTIES 
    C_STANDARD 90
    C_STANDARD_REQUIRED ON
    EXCLUDE_FROM_ALL TRUE
    WORKING_DIRECTORY "${GITHUB_WORKSPACE}" 
  )
  set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
  set(CMAKE_C_USE_RESPONSE_FILE_FOR_INCLUDES OFF)
  option(PROJECT_AUTO_INCLUDE "Automatically include projects" OFF)
  message(CHECK_PASS "Done: ${FILE_COUNT} files anchored to ${G_ROOT}")
  # Fallback logic for Absolute/Relative/Missing modes
elseif($ENV{github_absolute_path})
  option(PROJECT_AUTO_INCLUDE "Automatically include projects" ON)
  message(STATUS "Project Paths: Absolute Mode")
  file(GLOB_RECURSE PROJECT_SRC_FILES "*.$ENV{filetype}")
  list(SORT PROJECT_SRC_FILES)
  list(LENGTH PROJECT_SRC_FILES SOURCE_COUNT)
  message(STATUS "Source file count: ${SOURCE_COUNT}")
else()
  option(PROJECT_AUTO_INCLUDE "Automatically include projects" ON)
  message(STATUS "Project Paths: Relative Mode")
  file(GLOB_RECURSE PROJECT_SRC_FILES RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "*.$ENV{filetype}")
  list(SORT PROJECT_SRC_FILES)
  list(LENGTH PROJECT_SRC_FILES SOURCE_COUNT)
  message(STATUS "Source file count: ${SOURCE_COUNT}")
endif()

if(DEFINED PROJECT_SRC_FILES)
  message(STATUS "Project Files: cmake added project source files")
elseif($ENV{github_source_files})
  message(STATUS "Project Files: cmake found project source files")
elseif(CHECK_FILE_PATH)
  message(STATUS "Project Files: cmake found build source files")
else()
  message(STATUS "Project Files: cmake added no files")
endif()

if($ENV{include_source})
  message(STATUS "Project Auto Includes 1: true")
  set(INCLUDE_SRC ON CACHE BOOL "$ENV{include_source}")
elseif($ENV{sources})
  message(STATUS "Project Auto Sources 2: true")
  set(INCLUDE_SRC "$ENV{sources}")
elseif(DEFINED PROJECT_INCLUDE_SRC)
  message(STATUS "Project Auto Includes 3: true")
  set(INCLUDE_SRC ON CACHE BOOL "${PROJECT_INCLUDE_SRC}")
else()
  message(STATUS "Project Auto Includes 4: false")
  set(INCLUDE_SRC ON CACHE BOOL "false")
endif()

# Automatically find all header files recursively
file(GLOB_RECURSE ALL_HEADERS CONFIGURE_DEPENDS "*.h")

# Find all subdirectories that contain at least one header file
file(GLOB_RECURSE include_files LIST_DIRECTORIES true "include/*.h")

set(CHECK_FILE_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/check-file-sources.txt")

set(CHECK_FILE_COMPILE "${CMAKE_CURRENT_SOURCE_DIR}/check-file-compile.txt")

# Add the system, project include directory to your target. Comment to disable an add custom target_source & target_include_directories

get_filename_component(compile_file ${CHECK_FILE_COMPILE} NAME)

if(EXISTS "${CHECK_FILE_COMPILE}" AND IS_READABLE "${CHECK_FILE_COMPILE}")
  set(FILE_COUNT 0)
  file(STRINGS "${CHECK_FILE_COMPILE}" FILE_CONTENT)
  file(READ "${CHECK_FILE_COMPILE}" content_of_file)
  if(NOT "${content_of_file}" STREQUAL "")
    message(CHECK_START "Sources ${compile_file} found. Proceeding...")
    foreach(ITEM IN LISTS FILE_CONTENT)
      get_filename_component(file ${ITEM} NAME)
      if(NOT IS_ABSOLUTE "${ITEM}")
        set(FULL_PATH "${CMAKE_CURRENT_SOURCE_DIR}/${ITEM}")
      else()
        set(FULL_PATH "${ITEM}")
      endif()
      if(IS_DIRECTORY "${FULL_PATH}" AND "${FULL_PATH}" MATCHES "^/home/runner/work/")
        message(STATUS "User Include: ${FULL_PATH}")
        target_include_directories("${PROJECT_NAME}_${FILE_COUNT}" PRIVATE "${FULL_PATH}")
      elseif(IS_DIRECTORY "${FULL_PATH}")
        message(STATUS "System Include: ${FULL_PATH}")
        target_include_directories("${PROJECT_NAME}_${FILE_COUNT}" SYSTEM PRIVATE "${FULL_PATH}")
      elseif(EXISTS "${FULL_PATH}")
        math(EXPR FILE_COUNT "${FILE_COUNT} + 1")
        message(STATUS "Processing File: ${file}  ${FILE_COUNT}/${SOURCE_COUNT}")
        message(STATUS "Target Name: ${PROJECT_NAME}_${FILE_COUNT}")
        message(STATUS "Source File: ${FULL_PATH}")
        add_library("${PROJECT_NAME}_${FILE_COUNT}" OBJECT "${FULL_PATH}")
        set_target_properties("${PROJECT_NAME}_${FILE_COUNT}" PROPERTIES 
          C_STANDARD 90
          C_STANDARD_REQUIRED ON
          EXCLUDE_FROM_ALL TRUE
        )
      else()
        message(STATUS "Path does not exist: ${FULL_PATH}")
      endif()
    endforeach()    
    message(CHECK_PASS "Source Files & Include Directories: ${FILE_COUNT}/${SOURCE_COUNT} - Done")
  else()
    message(STATUS "${CHECK_FILE_COMPILE} exists but is empty!")
    add_executable("${PROJECT_NAME}")
    target_sources("${PROJECT_NAME}" PRIVATE "${PROJECT_SRC_FILES}")
    file(GLOB_RECURSE INCLUDE_FILES "${CMAKE_CURRENT_SOURCE_DIR}/include/*.h" "${CMAKE_CURRENT_SOURCE_DIR}/include/*.hh" "${CMAKE_CURRENT_SOURCE_DIR}/include/*.hpp")
    set(INCLUDE_DIRS "")
    foreach(FILE ${INCLUDE_FILES})
      get_filename_component(DIR ${FILE} DIRECTORY)
      list(APPEND INCLUDE_DIRS ${DIR})
    endforeach()
    list(REMOVE_DUPLICATES INCLUDE_DIRS)
    target_include_directories("${PROJECT_NAME}" PRIVATE ${INCLUDE_DIRS})
  endif()
    set(CMAKE_C_USE_RESPONSE_FILE_FOR_INCLUDES ON) # Useful/Needed for large list of include directories
    message(STATUS "Project Includes: cmake added include directories. clang analyzing multiple includes [check 1]")
elseif(PROJECT_AUTO_INCLUDE)
  add_executable("${PROJECT_NAME}") # Creates an executable target named "MyProject" from source files
  target_sources("${PROJECT_NAME}" PRIVATE "${PROJECT_SRC_FILES}")
  if(IS_READABLE "${CHECK_FILE_SOURCES}" AND INCLUDE_SRC)
    target_include_directories("${PROJECT_NAME}" PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/include/*")
    file(STRINGS "${CHECK_FILE_SOURCES}" FILE_PATHS)
    message(STATUS "Processing auto include source paths: $ENV{include_count}")
    foreach(INCLUDE_PATH IN LISTS FILE_PATHS)
      target_include_directories("${PROJECT_NAME}" PRIVATE "${INCLUDE_PATH}")
    endforeach()
    message(STATUS "Project Includes: cmake added include directories. clang analyzing multiple includes [check 2]")
  elseif($ENV{github_include_dirs})
    target_include_directories("${PROJECT_NAME}" PRIVATE ENV${github_include_dirs})
    target_include_directories("${PROJECT_NAME}" SYSTEM PRIVATE "/home/runner/.local/lib/python*/site-packages/clang_tidy/data/lib/clang/*/include")
    message(STATUS "Project Includes: cmake added include directories. clang analyzing multiple includes [check 3]")
  elseif(DEFINED PROJECT_INCLUDE_DIRS)
    foreach(PROJECT_INCLUDE_DIR ${PROJECT_INCLUDE_DIRS})
      target_include_directories("${PROJECT_NAME}" PRIVATE "${PROJECT_INCLUDE_DIR}")
    endforeach()
    message(STATUS "Project Includes: cmake added include directories. clang analyzing multiple includes [check 4]")
  elseif(DEFINED include_files)
    set(include_dirs "")
    foreach(file_path ${include_files})
      get_filename_component(dir_path ${file_path} DIRECTORY)
      list(APPEND include_dirs ${dir_path})
    endforeach()
    list(REMOVE_DUPLICATES include_dirs)
    target_include_directories("${PROJECT_NAME}" PRIVATE "${include_dirs}")
    message(STATUS "Project Includes: cmake added include directories. clang analyzing include directory [check 5]")
  elseif(DEFINED ALL_HEADERS) # Extract the unique directory paths from the list of header files
    set(PROJECT_INCLUDE_DIRS "")
    foreach(_headerFile ${ALL_HEADERS})
      get_filename_component(_dir ${_headerFile} PATH)
      list(APPEND PROJECT_INCLUDE_DIRS ${_dir})
    endforeach()
    list(REMOVE_DUPLICATES PROJECT_INCLUDE_DIRS)
    target_include_directories("${PROJECT_NAME}" PRIVATE "${PROJECT_INCLUDE_DIRS}")
    target_include_directories("${PROJECT_NAME}" SYSTEM PUBLIC "/usr/include;/usr/src")
    message(STATUS "Project Includes: cmake added include directories. clang analyzing all headers [check 6]")
  else()
    target_sources("${PROJECT_NAME}" PRIVATE "${PROJECT_SRC_FILES}")
    target_include_directories("${PROJECT_NAME}" PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/include/*/")
    message(STATUS "Project Includes: cmake added include directories. clang analyzing sources [check 7 default]")
  endif()
  set_target_properties("${PROJECT_NAME}" PROPERTIES LINKER_LANGUAGE C)
  message(STATUS "Project Builder: cmake added source files an include directories. build-source-files.txt scan complete [check 8 custom build]")
endif()

if($ENV{linux})
	if($ENV{arch} STREQUAL "arm")
	# These MUST come before the project() call
	  set(CMAKE_SYSTEM_NAME Linux)
	  set(CMAKE_SYSTEM_PROCESSOR arm)
	  set(ARM_TRIPLE arm-linux-gnueabihf)
	  set(ARM_SYSROOT /usr/${ARM_TRIPLE})
	# Set the flags for the compilers
	  set(CMAKE_C_FLAGS "--target=${ARM_TRIPLE} -mcpu=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard --sysroot=${ARM_SYSROOT}" CACHE STRING "" FORCE)
	  set(CMAKE_CXX_FLAGS "--target=${ARM_TRIPLE} -mcpu=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard --sysroot=${ARM_SYSROOT}" CACHE STRING "" FORCE)
	# Set the flags for the linker
	  set(CMAKE_EXE_LINKER_FLAGS "--target=${ARM_TRIPLE} --sysroot=${ARM_SYSROOT}" CACHE STRING "" FORCE)
	  set(CMAKE_C_COMPILER_FORCED TRUE)
	  set(CMAKE_CXX_COMPILER_FORCED TRUE)
	  set(CMAKE_C_COMPILER clang)
	  set(CMAKE_CXX_COMPILER clang++)
	  set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")
	  message(STATUS "Project Arch: $ENV{arch}")
	endif()
	if($ENV{arch} STREQUAL "arm64")
	# These MUST come before the project() call
	  set(CMAKE_SYSTEM_NAME Linux)
	  set(CMAKE_SYSTEM_PROCESSOR arm64)
	  set(ARM_TRIPLE aarch64-unknown-linux-gnu)
	  set(ARM_SYSROOT /usr/${ARM_TRIPLE})
	# Set the flags for the compilers
	  set(CMAKE_C_FLAGS "--target=${ARM_TRIPLE} -mcpu=cortex-a53 -mfpu=neon-vfpv4 -mfloat-abi=hard --sysroot=${ARM_SYSROOT}" CACHE STRING "" FORCE)
	  set(CMAKE_CXX_FLAGS "--target=${ARM_TRIPLE} -mcpu=cortex-a53 -mfpu=neon-vfpv4 -mfloat-abi=hard --sysroot=${ARM_SYSROOT}" CACHE STRING "" FORCE)
	# Set the flags for the linker
	  set(CMAKE_EXE_LINKER_FLAGS "--target=${ARM_TRIPLE} --sysroot=${ARM_SYSROOT}" CACHE STRING "" FORCE)
	  set(CMAKE_C_COMPILER_FORCED TRUE)
	  set(CMAKE_CXX_COMPILER_FORCED TRUE)
	  set(CMAKE_C_COMPILER clang)
	  set(CMAKE_CXX_COMPILER clang++)
	  set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")
	  message(STATUS "Project Arch: $ENV{arch}")
	endif()
	target_compile_definitions("${PROJECT_NAME}" PRIVATE 
	    __KERNEL__ 
	    LINUX 
	    MODULE 
	    KBUILD_MODNAME="${PROJECT_NAME}"
	    ARCH_$ENV{arch}
	)
	target_compile_options("${PROJECT_NAME}" PRIVATE
	    -ffreestanding
	    -fno-builtin
	    -fno-stack-protector
	    -mno-red-zone
	    -O2 # Kernels typically require at least -O1 for inline functions to work
	)
else()
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fno-pic")
	if($ENV{arch} STREQUAL "arm")
	# These MUST come before the project() call
	  set(CMAKE_SYSTEM_NAME Linux)
	  set(CMAKE_SYSTEM_PROCESSOR arm)
	  set(ARM_TRIPLE arm-linux-android)
	  set(ARM_SYSROOT ${GITHUB_WORKSPACE}/workspace/prebuilts/${ARM_TRIPLE})
	# Set the flags for the compilers
	  set(CMAKE_C_FLAGS "--target=${ARM_TRIPLE} -mcpu=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard --sysroot=${ARM_SYSROOT}" CACHE STRING "" FORCE)
	  set(CMAKE_CXX_FLAGS "--target=${ARM_TRIPLE} -mcpu=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard --sysroot=${ARM_SYSROOT}" CACHE STRING "" FORCE)
	# Set the flags for the linker
	  set(CMAKE_EXE_LINKER_FLAGS "--target=${ARM_TRIPLE} --sysroot=${ARM_SYSROOT}" CACHE STRING "" FORCE)
	  set(CMAKE_C_COMPILER_FORCED TRUE)
	  set(CMAKE_CXX_COMPILER_FORCED TRUE)
	  set(CMAKE_C_COMPILER clang)
	  set(CMAKE_CXX_COMPILER clang++)
	  set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")
	  target_compile_options("${PROJECT_NAME}" PRIVATE
	    -ffreestanding
	    -fno-stack-protector
	    -fstack-protector-strong
	    -fsanitize=shadow-call-stack
	    -ftrivial-auto-var-init=pattern
	    --target=arm-linux-android
	  )
	  message(STATUS "Project Arch: $ENV{arch}")
	endif()
	if($ENV{arch} STREQUAL "arm64")
	# These MUST come before the project() call
	  set(CMAKE_SYSTEM_NAME Linux)
	  set(CMAKE_SYSTEM_PROCESSOR arm64)
	  set(ARM_TRIPLE aarch64-linux-android)
	  set(ARM_SYSROOT ${GITHUB_WORKSPACE}/workspace/prebuilts/${ARM_TRIPLE})
	# Set the flags for the compilers
	  set(CMAKE_C_FLAGS "--target=${ARM_TRIPLE} -mcpu=cortex-a53 -mfpu=neon-vfpv4 -mfloat-abi=hard --sysroot=${ARM_SYSROOT}" CACHE STRING "" FORCE)
	  set(CMAKE_CXX_FLAGS "--target=${ARM_TRIPLE} -mcpu=cortex-a53 -mfpu=neon-vfpv4 -mfloat-abi=hard --sysroot=${ARM_SYSROOT}" CACHE STRING "" FORCE)
	# Set the flags for the linker
	  set(CMAKE_EXE_LINKER_FLAGS "--target=${ARM_TRIPLE} --sysroot=${ARM_SYSROOT}" CACHE STRING "" FORCE)
	  set(CMAKE_C_COMPILER_FORCED TRUE)
	  set(CMAKE_CXX_COMPILER_FORCED TRUE)
	  set(CMAKE_C_COMPILER clang)
	  set(CMAKE_CXX_COMPILER clang++)
	  set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")
	  target_compile_options("${PROJECT_NAME}" PRIVATE
	    -ffreestanding
	    -fno-stack-protector
	    -fstack-protector-strong
	    -fsanitize=shadow-call-stack
	    -ftrivial-auto-var-init=pattern
	    --target=aarch64-linux-android
	  )
	  message(STATUS "Project Arch: $ENV{arch}")
	endif()
	target_compile_definitions("${PROJECT_NAME}" PRIVATE 
	    __KERNEL__ 
	    LINUX 
	    CONFIG_ANDROID
	    KBUILD_MODNAME="${PROJECT_NAME}"
	)
endif()

# .set(CMAKE_CXX_CLANG_TIDY "clang-tidy")

# .set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2 -Wall -Werror -pedantic")

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
      message(STATUS "Project include directories written to: ${src_dir}")
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
      message(STATUS "Project source files written to: ${src_file}")
    endif()
  endfunction()

output_src_includes()

output_src_files()

# .Place build artifacts in ${CMAKE_BINARY_DIR}/{bin,lib}
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin CACHE PATH "")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib CACHE PATH "")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib CACHE PATH "")