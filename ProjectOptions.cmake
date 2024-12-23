include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(cppweekly_rpg_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(cppweekly_rpg_setup_options)
  option(cppweekly_rpg_ENABLE_HARDENING "Enable hardening" ON)
  option(cppweekly_rpg_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    cppweekly_rpg_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    cppweekly_rpg_ENABLE_HARDENING
    OFF)

  cppweekly_rpg_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR cppweekly_rpg_PACKAGING_MAINTAINER_MODE)
    option(cppweekly_rpg_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(cppweekly_rpg_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(cppweekly_rpg_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(cppweekly_rpg_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(cppweekly_rpg_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(cppweekly_rpg_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(cppweekly_rpg_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(cppweekly_rpg_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(cppweekly_rpg_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(cppweekly_rpg_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(cppweekly_rpg_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(cppweekly_rpg_ENABLE_PCH "Enable precompiled headers" OFF)
    option(cppweekly_rpg_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(cppweekly_rpg_ENABLE_IPO "Enable IPO/LTO" ON)
    option(cppweekly_rpg_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(cppweekly_rpg_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(cppweekly_rpg_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(cppweekly_rpg_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(cppweekly_rpg_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(cppweekly_rpg_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(cppweekly_rpg_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(cppweekly_rpg_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(cppweekly_rpg_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(cppweekly_rpg_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(cppweekly_rpg_ENABLE_PCH "Enable precompiled headers" OFF)
    option(cppweekly_rpg_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      cppweekly_rpg_ENABLE_IPO
      cppweekly_rpg_WARNINGS_AS_ERRORS
      cppweekly_rpg_ENABLE_USER_LINKER
      cppweekly_rpg_ENABLE_SANITIZER_ADDRESS
      cppweekly_rpg_ENABLE_SANITIZER_LEAK
      cppweekly_rpg_ENABLE_SANITIZER_UNDEFINED
      cppweekly_rpg_ENABLE_SANITIZER_THREAD
      cppweekly_rpg_ENABLE_SANITIZER_MEMORY
      cppweekly_rpg_ENABLE_UNITY_BUILD
      cppweekly_rpg_ENABLE_CLANG_TIDY
      cppweekly_rpg_ENABLE_CPPCHECK
      cppweekly_rpg_ENABLE_COVERAGE
      cppweekly_rpg_ENABLE_PCH
      cppweekly_rpg_ENABLE_CACHE)
  endif()

  cppweekly_rpg_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (cppweekly_rpg_ENABLE_SANITIZER_ADDRESS OR cppweekly_rpg_ENABLE_SANITIZER_THREAD OR cppweekly_rpg_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(cppweekly_rpg_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(cppweekly_rpg_global_options)
  if(cppweekly_rpg_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    cppweekly_rpg_enable_ipo()
  endif()

  cppweekly_rpg_supports_sanitizers()

  if(cppweekly_rpg_ENABLE_HARDENING AND cppweekly_rpg_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR cppweekly_rpg_ENABLE_SANITIZER_UNDEFINED
       OR cppweekly_rpg_ENABLE_SANITIZER_ADDRESS
       OR cppweekly_rpg_ENABLE_SANITIZER_THREAD
       OR cppweekly_rpg_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${cppweekly_rpg_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${cppweekly_rpg_ENABLE_SANITIZER_UNDEFINED}")
    cppweekly_rpg_enable_hardening(cppweekly_rpg_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(cppweekly_rpg_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(cppweekly_rpg_warnings INTERFACE)
  add_library(cppweekly_rpg_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  cppweekly_rpg_set_project_warnings(
    cppweekly_rpg_warnings
    ${cppweekly_rpg_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(cppweekly_rpg_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    cppweekly_rpg_configure_linker(cppweekly_rpg_options)
  endif()

  include(cmake/Sanitizers.cmake)
  cppweekly_rpg_enable_sanitizers(
    cppweekly_rpg_options
    ${cppweekly_rpg_ENABLE_SANITIZER_ADDRESS}
    ${cppweekly_rpg_ENABLE_SANITIZER_LEAK}
    ${cppweekly_rpg_ENABLE_SANITIZER_UNDEFINED}
    ${cppweekly_rpg_ENABLE_SANITIZER_THREAD}
    ${cppweekly_rpg_ENABLE_SANITIZER_MEMORY})

  set_target_properties(cppweekly_rpg_options PROPERTIES UNITY_BUILD ${cppweekly_rpg_ENABLE_UNITY_BUILD})

  if(cppweekly_rpg_ENABLE_PCH)
    target_precompile_headers(
      cppweekly_rpg_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(cppweekly_rpg_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    cppweekly_rpg_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(cppweekly_rpg_ENABLE_CLANG_TIDY)
    cppweekly_rpg_enable_clang_tidy(cppweekly_rpg_options ${cppweekly_rpg_WARNINGS_AS_ERRORS})
  endif()

  if(cppweekly_rpg_ENABLE_CPPCHECK)
    cppweekly_rpg_enable_cppcheck(${cppweekly_rpg_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(cppweekly_rpg_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    cppweekly_rpg_enable_coverage(cppweekly_rpg_options)
  endif()

  if(cppweekly_rpg_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(cppweekly_rpg_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(cppweekly_rpg_ENABLE_HARDENING AND NOT cppweekly_rpg_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR cppweekly_rpg_ENABLE_SANITIZER_UNDEFINED
       OR cppweekly_rpg_ENABLE_SANITIZER_ADDRESS
       OR cppweekly_rpg_ENABLE_SANITIZER_THREAD
       OR cppweekly_rpg_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    cppweekly_rpg_enable_hardening(cppweekly_rpg_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
