# CMake 3.5 is required for compatibility with modern CMake versions (4.0+)
# which removed support for projects requiring < 3.5. CMake 3.5 was released
# in 2016 and should be available on all supported platforms via package
# managers (Homebrew, etc.) or direct download.
# Note: This does NOT affect the minimum macOS version the app can run on
# (controlled by CMAKE_OSX_DEPLOYMENT_TARGET in src/CMakeLists.txt).

# Check CMake version and provide helpful error message if too old
if(CMAKE_VERSION VERSION_LESS "3.5")
    message(FATAL_ERROR "\n"
        "CMake 3.5 or higher is required to build this project.\n"
        "Your current CMake version is: ${CMAKE_VERSION}\n\n"
        "To install CMake 3.5+ on your system:\n"
        "  macOS (Homebrew):     brew install cmake\n"
        "  macOS (MacPorts):     sudo port install cmake\n"
        "  Linux (Ubuntu/Debian): sudo apt-get install cmake\n"
        "  Linux (Fedora/RHEL):   sudo dnf install cmake\n"
        "  Linux (Arch):          sudo pacman -S cmake\n"
        "  Windows:               Download from https://cmake.org/download/\n"
        "  Or build from source:  https://cmake.org/download/\n\n"
        "After installing, make sure the new CMake is in your PATH.\n"
        "You can verify with: cmake --version\n"
    )
endif()

cmake_minimum_required(VERSION 3.5)

project(rclone-browser)

if(WIN32)
  # link automatically to qtmain.lib on Windows
  cmake_policy(SET CMP0020 NEW)
endif()

find_package(Qt5Widgets REQUIRED)
if(WIN32)
  find_package(Qt5WinExtras REQUIRED)
elseif(APPLE)
  find_package(Qt5MacExtras REQUIRED)
  find_library(COCOA_LIB Cocoa REQUIRED)
endif()

if(WIN32)
  set_property(GLOBAL PROPERTY USE_FOLDERS OFF)

  add_definitions("-D_UNICODE -DUNICODE -D_SCL_SECURE_NO_DEPRECATE -D_CRT_SECURE_NO_DEPRECATE")

  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /MP")
  set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS} /GF /Gy /GS- /GR- /GL")

  set(CMAKE_EXE_LINKER_FLAGS "/INCREMENTAL:NO")
  set(CMAKE_EXE_LINKER_FLAGS_DEBUG "/DEBUG")
  set(CMAKE_EXE_LINKER_FLAGS_RELEASE "/LTCG /OPT:ICF /OPT:REF")

  macro(use_pch HEADER SOURCE FILES)
    foreach(FILE ${FILES})
      set_source_files_properties(${FILE} PROPERTIES COMPILE_FLAGS "/Yu${HEADER} /FI${HEADER}")
    endforeach()
    set_source_files_properties(${SOURCE} PROPERTIES COMPILE_FLAGS "/Yc${HEADER}")
  endmacro(use_pch)

else()

  macro(use_pch TARGET HEADER SOURCE)
    # TODO
  endmacro(use_pch)

endif()

file(READ "VERSION" RCLONE_BROWSER_VERSION)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${rclone-browser_BINARY_DIR}/build")

add_subdirectory(src)
