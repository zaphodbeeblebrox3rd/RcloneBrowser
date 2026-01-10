#!/bin/bash

set -e

# x86_64 build
  # For AppImage compatibility with glibc 2.17+ (CentOS 7+ and Ubuntu 16.04+), build on CentOS 7
  # Building on newer systems (Ubuntu 18.04+, glibc 2.27+) will limit compatibility
  # newer cmake may be required depending on distribution
  # download from http://www.cmake.org/download
  # sudo mkdir /opt/cmake
  # sudo sh cmake-$version.$build-Linux-x86_64.sh --prefix=/opt/cmake

  if [ $(arch) = "x86_64" ]; then
    # Use custom cmake if available, otherwise use system cmake
    if [ -f "/opt/cmake/bin/cmake" ]; then
      CMAKE="/opt/cmake/bin/cmake"
    else
      CMAKE="cmake"
    fi
  fi

# i686 build on Ubuntu 16.04 LTS (glibc 2.23, GCC 5.4 - supports C++14)

# armv7l build on raspbian stretch (glibc 2.24, GCC 6.3 - supports C++14)

# Qt path and flags set in env e.g.:
# export PATH="/opt/Qt/5.14.0/bin/:$PATH"
# export CPPFLAGS="-I/opt/Qt/5.14.0/bin/include/"
# export LDFLAGS="-L/opt/Qt/5.14.0/bin/lib/"
# export LD_LIBRARY_PATH="/opt/Qt/5.14.0/bin/lib/:$LD_LIBRARY_PATH"

# for x86_64 and i686 platform
# Qt 5.14.0 uses openssl 1.1 and some older distros still use 1.0
# we build openssl 1.1.1d from source using following setup:
# ./config shared --prefix=/opt/openssl-1.1.1/ && make --jobs=`nproc --all` && sudo make install
# and add to build env
# export LD_LIBRARY_PATH="/opt/openssl-1.1.1/lib/:$LD_LIBRARY_PATH"

if [ "$1" = "SIGN" ]; then
  export SIGN="1"
fi

# check gcc version (C++14 requires GCC 5.1+)
currentver="$(gcc -dumpversion | cut -d. -f1)"
minorver="$(gcc -dumpversion | cut -d. -f2)"
if [ "$currentver" -lt "5" ] || ([ "$currentver" -eq "5" ] && [ "$minorver" -lt "1" ]); then
  echo "Error: GCC 5.1 or newer required for C++14 support"
  echo "Current GCC version: $(gcc -dumpversion)"
  exit 1
fi

# check glibc version for AppImage compatibility
# AppImages built on systems with newer glibc won't run on older systems
# For maximum compatibility, build on CentOS 7 (glibc 2.17)
if [ $(arch) = "x86_64" ] || [ $(arch) = "i686" ]; then
  if command -v ldd >/dev/null 2>&1; then
    # Extract glibc version from ldd output (format varies: "ldd (Ubuntu GLIBC 2.35) 2.35" or "ldd (GNU libc) 2.27")
    GLIBC_VERSION=$(ldd --version 2>&1 | head -n1 | grep -oE '[0-9]+\.[0-9]+' | head -n1)
    if [ -n "$GLIBC_VERSION" ]; then
      GLIBC_MAJOR=$(echo "$GLIBC_VERSION" | cut -d. -f1)
      GLIBC_MINOR=$(echo "$GLIBC_VERSION" | cut -d. -f2)
      
      # Warn if glibc is newer than 2.17 (CentOS 7)
      # Check if major > 2, or (major == 2 and minor > 17)
      if [ "$GLIBC_MAJOR" -gt "2" ] || ([ "$GLIBC_MAJOR" -eq "2" ] && [ -n "$GLIBC_MINOR" ] && [ "$GLIBC_MINOR" -gt "17" ]); then
        echo "==================================================================="
        echo "Warning: Building on system with glibc $GLIBC_VERSION"
        echo "         This AppImage may not run on systems with glibc < $GLIBC_VERSION"
        echo ""
        echo "For maximum compatibility (glibc 2.17+, CentOS 7+ and Ubuntu 16.04+), you can:"
        echo "  1. Build on CentOS 7 directly"
        echo "  2. Use Docker: ./scripts/build_AppImage_docker.sh"
        echo ""
        echo "Press Ctrl+C to cancel, or wait 5 seconds to continue with current build..."
        echo "==================================================================="
        sleep 5
      fi
    fi
  fi
fi

# building AppImage in temporary directory to keep system clean
# use RAM disk if possible (as in: not building on CI system like Travis, and RAM disk is available)
if [ "$CI" == "" ] && [ -d /dev/shm ]; then
  TEMP_BASE=/dev/shm
else
  TEMP_BASE=/tmp
fi

# we run it from our project scripts folder
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/..
VERSION=$(cat "$ROOT"/VERSION)-$(git rev-parse --short HEAD)
# linuxdeploy uses $VERSION env variable for AppImage name
export VERSION=$VERSION
BUILD="$ROOT"/build
TARGET=rclone-browser-$VERSION.AppImage

# clean AppImage temporary folder
if [ -d "$TEMP_BASE/$TARGET" ]; then
  rm -rf "$TEMP_BASE/$TARGET"
fi
mkdir "$TEMP_BASE/$TARGET"

# clean build folder
if [ -d "$BUILD" ]; then
  rm -rf "$BUILD"
fi
mkdir "$BUILD"

# create release folder if does not exist
mkdir -p "$ROOT"/release

# clean current version previous build
if [ $(arch) = "armv7l" ] && [ -f "$ROOT"/release/rclone-browser-"$VERSION"-armhf.AppImage ]; then
  rm "$ROOT"/release/rclone-browser-"$VERSION"-raspberrypi-armhf.AppImage
fi

if [ $(arch) = "i686" ] && [ -f "$ROOT"/release/rclone-browser-"$VERSION"-i386.AppImage ]; then
  rm "$ROOT"/release/rclone-browser-"$VERSION"-linux-i386.AppImage
fi

if [ $(arch) = "x86_64" ] && [ -f "$ROOT"/release/rclone-browser-"$VERSION"-x86_64.AppImage ]; then
  rm "$ROOT"/release/rclone-browser-"$VERSION"-linux-x86_64.AppImage
fi

# build and install to temporary AppDir folder
cd "$BUILD"

if [ $(arch) = "armv7l" ]; then
  # more threads need swap on 1GB RAM RPi
  cmake .. -DCMAKE_INSTALL_PREFIX=/usr
  make -j 2
fi

if [ $(arch) = "x86_64" ]; then
  "$CMAKE" .. -DCMAKE_INSTALL_PREFIX=/usr
  make --jobs=$(nproc --all)
fi

if [ $(arch) = "i686" ]; then
  cmake .. -DCMAKE_INSTALL_PREFIX=/usr
  make --jobs=$(nproc --all)
fi

make install DESTDIR="$TEMP_BASE"/"$TARGET"/AppDir

# prepare AppImage
cd "$TEMP_BASE/$TARGET"

# metainfo file
#mkdir $TEMP_BASE/$TARGET/AppDir/usr/share/metainfo
#cp $ROOT/assets/rclone-browser.appdata.xml $TEMP_BASE/$TARGET/AppDir/usr/share/metainfo/

# copy info files to AppImage
cp "$ROOT"/README.md "$TEMP_BASE"/"$TARGET"/AppDir/Readme.md
cp "$ROOT"/CHANGELOG.md "$TEMP_BASE"/"$TARGET"/AppDir/Changelog.md
cp "$ROOT"/LICENSE "$TEMP_BASE"/"$TARGET"/AppDir/License.txt

# https://github.com/linuxdeploy/linuxdeploy
# https://github.com/linuxdeploy/linuxdeploy-plugin-qt
# Set Qt environment variables to help linuxdeploy-qt find Qt modules
if command -v qmake >/dev/null 2>&1; then
  export QTDIR=$(qmake -query QT_INSTALL_PREFIX 2>/dev/null || echo "/usr/lib/x86_64-linux-gnu/qt5")
  export PATH="$QTDIR/bin:$PATH"
  export QT_PLUGIN_PATH="${QT_PLUGIN_PATH:-/usr/lib/x86_64-linux-gnu/qt5/plugins}"
fi

# Deploy dependencies first, then Qt plugin
# The app uses Qt5::Widgets and Qt5::Network (see src/CMakeLists.txt line 137)
linuxdeploy --appdir AppDir \
  --executable AppDir/usr/bin/rclone-browser \
  --desktop-file=AppDir/usr/share/applications/rclone-browser.desktop

# Deploy Qt libraries - manually specify the libraries the app needs
# The app links against Qt5::Widgets and Qt5::Network, which also require Qt5::Core and Qt5::Gui
echo "Deploying Qt libraries manually..."
QT_LIB_DIR="/usr/lib/x86_64-linux-gnu"
for lib in libQt5Widgets.so.5 libQt5Network.so.5 libQt5Core.so.5 libQt5Gui.so.5; do
  if [ -f "$QT_LIB_DIR/$lib" ]; then
    # Deploy library (strip failures are non-fatal, libraries are still copied)
    linuxdeploy --appdir AppDir --library "$QT_LIB_DIR/$lib" 2>&1 | grep -v "ERROR: Strip call failed" || true
  fi
done

# Deploy Qt plugins using the qt plugin (this will handle platform plugins, etc.)
# The plugin might fail but that's okay if libraries are already deployed
linuxdeploy-plugin-qt --appdir AppDir 2>&1 | grep -v "ERROR: Could not find Qt modules" || echo "Note: Qt libraries deployed manually, plugin may have failed"

if [ $(arch) != "armv7l" ]
then
  # we add openssl 1.1.1 libs needed for distros still using openssl 1.0
  # Qt 5.x uses OpenSSL 1.1.x, and bundling 1.1.1 ensures compatibility with older systems
  if [ -f "/opt/openssl-1.1.1/lib/libssl.so.1.1" ] && [ -f "/opt/openssl-1.1.1/lib/libcrypto.so.1.1" ]; then
    cp /opt/openssl-1.1.1/lib/libssl.so.1.1 ./AppDir/usr/bin/
    cp /opt/openssl-1.1.1/lib/libcrypto.so.1.1 ./AppDir/usr/bin/
    echo "Bundled OpenSSL 1.1.1 libraries for compatibility with distros using OpenSSL 1.0"
  else
    echo "Warning: OpenSSL 1.1.1 libraries not found at /opt/openssl-1.1.1/ - AppImage will use system OpenSSL"
    echo "This may cause issues on older distros that still use OpenSSL 1.0 (e.g., Ubuntu 16.04, Debian Stretch)"
  fi
fi

# https://github.com/linuxdeploy/linuxdeploy-plugin-appimage
linuxdeploy-plugin-appimage --appdir=AppDir

# raspberry pi build
if [ $(arch) = "armv7l" ]; then
  rename 's/armhf/raspberrypi-armhf/' Rclone_Browser*
  rename 's/Rclone_Browser/rclone-browser/' Rclone_Browser*
fi

# x86 build
if [ $(arch) = "i686" ]; then
  rename 's/i386/linux-i386/' Rclone_Browser*
  rename 's/Rclone_Browser/rclone-browser/' Rclone_Browser*
fi

# x86_64 build
if [ $(arch) = "x86_64" ]; then
  rename x86_64 linux-x86_64 Rclone_Browser*
  rename Rclone_Browser rclone-browser Rclone_Browser*
fi

cp ./*AppImage "$ROOT"/release/

# clean AppImage temporary folder
cd ..
rm -rf "$TARGET"
