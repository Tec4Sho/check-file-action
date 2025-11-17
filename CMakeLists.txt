cmake_minimum_required(VERSION 3.10) # Or a newer version
# ... other project settings ... #
project(MyProject VERSION 1.0 LANGUAGES CXX)

#add_executable(MyExecutable main.cpp my_source.cpp)

#target_link_libraries(MyExecutable PRIVATE MyLibrary)

#add_library(MyLibrary STATIC my_library_source.cpp)

#install(TARGETS MyExecutable DESTINATION bin)
#install(TARGETS MyLibrary DESTINATION lib)
#install(FILES my_library.h DESTINATION include)

    find_program(CLANG_TIDY_EXE "clang-tidy")
    if(CLANG_TIDY_EXE)
        message(STATUS "clang-tidy found: ${CLANG_TIDY_EXE}")
        # Configure clang-tidy to run with all checks and fix errors
        set(CMAKE_CXX_CLANG_TIDY "${CLANG_TIDY_EXE};-checks=*; -header-filter=.; -fix")
        # You can also specify specific checks instead of -checks=*
        # set(CMAKE_CXX_CLANG_TIDY "${CLANG_TIDY_EXE};-checks=modernize-loop-convert,readability-identifier-naming;-fix")
    else()
        message(WARNING "clang-tidy not found! Static analysis will be skipped.")
    endif()

