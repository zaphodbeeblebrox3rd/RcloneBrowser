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
# Use the GCC from PATH (which should be devtoolset-7's GCC 7.3 in CentOS 7 Docker)
GCC_CMD="gcc"
if [ -f "/opt/rh/devtoolset-7/root/usr/bin/gcc" ]; then
  GCC_CMD="/opt/rh/devtoolset-7/root/usr/bin/gcc"
fi
currentver="$($GCC_CMD -dumpversion | cut -d. -f1)"
minorver="$($GCC_CMD -dumpversion | cut -d. -f2)"
if [ "$currentver" -lt "5" ] || ([ "$currentver" -eq "5" ] && [ "$minorver" -lt "1" ]); then
  echo "Error: GCC 5.1 or newer required for C++14 support"
  echo "Current GCC version: $($GCC_CMD -dumpversion)"
  echo "GCC path: $GCC_CMD"
  exit 1
fi
echo "Using GCC $($GCC_CMD -dumpversion) from: $GCC_CMD"

# check glibc version for AppImage compatibility
# AppImages built on systems with newer glibc won't run on older systems
# For maximum compatibility, build on CentOS 7 (glibc 2.17)
# Skip this check if running in Docker (Docker build script handles compatibility)
if [ -z "$CI" ] && [ ! -f /.dockerenv ] && [ $(arch) = "x86_64" ] || [ $(arch) = "i686" ]; then
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
elif [ -f /.dockerenv ]; then
  # Running in Docker - verify we're on CentOS 7 (glibc 2.17)
  if command -v ldd >/dev/null 2>&1; then
    GLIBC_VERSION=$(ldd --version 2>&1 | head -n1 | grep -oE '[0-9]+\.[0-9]+' | head -n1)
    echo "Building in Docker container with glibc $GLIBC_VERSION (target: glibc 2.17 for CentOS 7 compatibility)"
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

# On CentOS 7 with devtoolset, ensure we link against system libstdc++ (glibc 2.17)
# not devtoolset's libstdc++ (glibc 2.18). 
# Set library path and linker flags to prioritize system libs.
if [ -d "/opt/rh/devtoolset-7" ] && [ -f "/usr/lib64/libstdc++.so.6" ]; then
  export LD_LIBRARY_PATH="/usr/lib64:/usr/lib:${LD_LIBRARY_PATH}"
  # Explicitly tell linker to use system libstdc++ instead of devtoolset's
  export LDFLAGS="-L/usr/lib64 -Wl,-rpath,/usr/lib64 ${LDFLAGS}"
  export CPPFLAGS="-I/usr/include ${CPPFLAGS}"
  echo "Using system libstdc++ for glibc 2.17 compatibility (avoiding devtoolset version)"
  echo "LDFLAGS set to: $LDFLAGS"
fi

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
# Detect Qt installation path (varies by distro)
if command -v qmake >/dev/null 2>&1; then
  export QTDIR=$(qmake -query QT_INSTALL_PREFIX 2>/dev/null || echo "/usr/lib64/qt5")
  export PATH="$QTDIR/bin:$PATH"
  # Find Qt plugin path (CentOS uses /usr/lib64/qt5/plugins, Ubuntu uses /usr/lib/x86_64-linux-gnu/qt5/plugins)
  if [ -d "/usr/lib64/qt5/plugins" ]; then
    export QT_PLUGIN_PATH="/usr/lib64/qt5/plugins"
  elif [ -d "/usr/lib/x86_64-linux-gnu/qt5/plugins" ]; then
    export QT_PLUGIN_PATH="/usr/lib/x86_64-linux-gnu/qt5/plugins"
  else
    export QT_PLUGIN_PATH="${QT_PLUGIN_PATH:-/usr/lib64/qt5/plugins}"
  fi
  echo "Qt installation: QTDIR=$QTDIR, QT_PLUGIN_PATH=$QT_PLUGIN_PATH"
fi

# Deploy dependencies first, then Qt plugin
# The app uses Qt5::Widgets and Qt5::Network (see src/CMakeLists.txt line 137)
linuxdeploy --appdir AppDir \
  --executable AppDir/usr/bin/rclone-browser \
  --desktop-file=AppDir/usr/share/applications/rclone-browser.desktop

# Deploy Qt libraries - manually specify the libraries the app needs
# The app links against Qt5::Widgets and Qt5::Network, which also require Qt5::Core and Qt5::Gui
echo "Deploying Qt libraries manually..."
# Find Qt library directory (varies by distro: /usr/lib64 for CentOS/RHEL, /usr/lib/x86_64-linux-gnu for Ubuntu/Debian)
if [ -d "/usr/lib64/qt5" ] && [ -f "/usr/lib64/libQt5Widgets.so.5" ]; then
  QT_LIB_DIR="/usr/lib64"
elif [ -d "/usr/lib/x86_64-linux-gnu/qt5" ] && [ -f "/usr/lib/x86_64-linux-gnu/libQt5Widgets.so.5" ]; then
  QT_LIB_DIR="/usr/lib/x86_64-linux-gnu"
else
  # Try to find Qt libraries
  QT_LIB_DIR=$(find /usr/lib* -name "libQt5Widgets.so.5" 2>/dev/null | head -1 | xargs dirname 2>/dev/null || echo "/usr/lib64")
fi

echo "Using Qt library directory: $QT_LIB_DIR"
for lib in libQt5Widgets.so.5 libQt5Network.so.5 libQt5Core.so.5 libQt5Gui.so.5; do
  if [ -f "$QT_LIB_DIR/$lib" ]; then
    echo "Deploying $lib from $QT_LIB_DIR..."
    # Deploy library (strip failures are non-fatal, libraries are still copied)
    linuxdeploy --appdir AppDir --library "$QT_LIB_DIR/$lib" 2>&1 | grep -v "ERROR: Strip call failed" || true
  else
    echo "Warning: $lib not found in $QT_LIB_DIR"
  fi
done

# Deploy Qt plugins using the qt plugin (this will handle platform plugins, etc.)
# The plugin might fail but that's okay if libraries are already deployed
linuxdeploy-plugin-qt --appdir AppDir 2>&1 | grep -v "ERROR: Could not find Qt modules" || true

# Always manually deploy Qt platform plugins to ensure they're present
# This is critical for GUI applications - without platform plugins, Qt apps won't start
echo "Deploying Qt platform plugins..."
PLATFORM_PLUGIN_DIR=""
if [ -d "/usr/lib64/qt5/plugins/platforms" ]; then
  PLATFORM_PLUGIN_DIR="/usr/lib64/qt5/plugins/platforms"
elif [ -d "/usr/lib/x86_64-linux-gnu/qt5/plugins/platforms" ]; then
  PLATFORM_PLUGIN_DIR="/usr/lib/x86_64-linux-gnu/qt5/plugins/platforms"
fi

if [ -n "$PLATFORM_PLUGIN_DIR" ] && [ -d "$PLATFORM_PLUGIN_DIR" ]; then
  mkdir -p ./AppDir/usr/plugins/platforms
  # First, deploy libqxcb.so using linuxdeploy to pull in all its dependencies
  if [ -f "$PLATFORM_PLUGIN_DIR/libqxcb.so" ]; then
    echo "Deploying libqxcb.so and its dependencies..."
    linuxdeploy --appdir AppDir --library "$PLATFORM_PLUGIN_DIR/libqxcb.so" 2>&1 | grep -v "ERROR: Strip call failed" || true
    # Move it to the correct location (linuxdeploy puts it in usr/lib, we need it in usr/plugins/platforms)
    if [ -f "./AppDir/usr/lib/libqxcb.so" ]; then
      mkdir -p ./AppDir/usr/plugins/platforms
      mv ./AppDir/usr/lib/libqxcb.so ./AppDir/usr/plugins/platforms/ 2>/dev/null || cp ./AppDir/usr/lib/libqxcb.so ./AppDir/usr/plugins/platforms/ 2>/dev/null || true
    fi
  fi
  # Copy all other platform plugins
  cp "$PLATFORM_PLUGIN_DIR"/libq*.so ./AppDir/usr/plugins/platforms/ 2>/dev/null || true
  if [ -f "./AppDir/usr/plugins/platforms/libqxcb.so" ]; then
    echo "Successfully deployed Qt platform plugins from $PLATFORM_PLUGIN_DIR (including libqxcb.so for X11)"
    echo "Qt platform plugins deployed to: ./AppDir/usr/plugins/platforms/"
    ls -la ./AppDir/usr/plugins/platforms/ | head -10 || echo "Warning: Could not list platform plugins"
  else
    echo "Error: libqxcb.so deployment failed!"
    echo "Attempted to copy from: $PLATFORM_PLUGIN_DIR"
    ls -la "$PLATFORM_PLUGIN_DIR" || true
    exit 1
  fi
else
  echo "Error: Qt platform plugins directory not found"
  exit 1
fi

# Ensure Qt can find the plugins by updating the hook script
# CRITICAL: The AppRun script sets $this_dir but NOT $APPDIR
# The hook needs to export APPDIR so QT_PLUGIN_PATH works correctly
mkdir -p ./AppDir/apprun-hooks

echo "Creating/updating Qt plugin path hook..."
# Always recreate the hook to ensure it's correct
cat > ./AppDir/apprun-hooks/linuxdeploy-plugin-qt-hook.sh << 'HOOKEOF'
#!/bin/bash
# Qt plugin hook for AppImage
# This must define APPDIR since AppRun only sets $this_dir

# Set APPDIR from the script location (AppRun sources this from $this_dir)
export APPDIR="${APPDIR:-"$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.."}"

# Set Qt plugin path so Qt can find platform plugins
export QT_PLUGIN_PATH="${APPDIR}/usr/plugins:${QT_PLUGIN_PATH}"

# Also set LD_LIBRARY_PATH to find Qt libraries
export LD_LIBRARY_PATH="${APPDIR}/usr/lib:${LD_LIBRARY_PATH}"

# Try to make Qt apps more "native looking" on Gtk-based desktops
case "${XDG_CURRENT_DESKTOP}" in
    *GNOME*|*gnome*|*XFCE*)
        export QT_QPA_PLATFORMTHEME=gtk2
        ;;
esac
HOOKEOF
chmod +x ./AppDir/apprun-hooks/linuxdeploy-plugin-qt-hook.sh
echo "Created Qt plugin path hook with APPDIR definition"

# Bundle libstdc++ for compatibility across different distributions
# IMPORTANT: Use the system libstdc++ (compatible with glibc 2.17), not devtoolset's
# On CentOS 7, devtoolset-7's libstdc++ requires glibc 2.18, but system libstdc++ only needs 2.17
# Find system libstdc++ location (prioritize system paths, avoid devtoolset paths)
if [ -f "/usr/lib64/libstdc++.so.6" ] && ! readlink -f /usr/lib64/libstdc++.so.6 | grep -q devtoolset; then
    # CentOS 7 system libstdc++ (glibc 2.17 compatible)
    STDCPP_LIB="/usr/lib64/libstdc++.so.6"
elif [ -f "/usr/lib/x86_64-linux-gnu/libstdc++.so.6" ] && ! readlink -f /usr/lib/x86_64-linux-gnu/libstdc++.so.6 | grep -q devtoolset; then
    # Ubuntu/Debian system libstdc++
    STDCPP_LIB="/usr/lib/x86_64-linux-gnu/libstdc++.so.6"
elif [ -f "/usr/lib/libstdc++.so.6" ] && ! readlink -f /usr/lib/libstdc++.so.6 | grep -q devtoolset; then
    # Generic system libstdc++
    STDCPP_LIB="/usr/lib/libstdc++.so.6"
fi

if [ -n "$STDCPP_LIB" ] && [ -f "$STDCPP_LIB" ]; then
    echo "Bundling system libstdc++ for compatibility (glibc 2.17+)..."
    cp "$STDCPP_LIB" ./AppDir/usr/lib/ 2>/dev/null || true
    # Also try to find and bundle system libgcc_s (avoid devtoolset)
    if [ -f "/usr/lib64/libgcc_s.so.1" ] && ! readlink -f /usr/lib64/libgcc_s.so.1 2>/dev/null | grep -q devtoolset; then
        cp /usr/lib64/libgcc_s.so.1 ./AppDir/usr/lib/ 2>/dev/null || true
    elif [ -f "/usr/lib/x86_64-linux-gnu/libgcc_s.so.1" ] && ! readlink -f /usr/lib/x86_64-linux-gnu/libgcc_s.so.1 2>/dev/null | grep -q devtoolset; then
        cp /usr/lib/x86_64-linux-gnu/libgcc_s.so.1 ./AppDir/usr/lib/ 2>/dev/null || true
    fi
else
    echo "Warning: Could not find system libstdc++ (avoiding devtoolset version)"
    echo "AppImage may have compatibility issues on older systems"
fi

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
  for file in Rclone_Browser*; do
    [ -f "$file" ] || continue
    newname=$(echo "$file" | sed 's/armhf/raspberrypi-armhf/; s/Rclone_Browser/rclone-browser/')
    [ "$file" != "$newname" ] && mv "$file" "$newname"
  done
fi

# x86 build
if [ $(arch) = "i686" ]; then
  for file in Rclone_Browser*; do
    [ -f "$file" ] || continue
    newname=$(echo "$file" | sed 's/i386/linux-i386/; s/Rclone_Browser/rclone-browser/')
    [ "$file" != "$newname" ] && mv "$file" "$newname"
  done
fi

# x86_64 build
if [ $(arch) = "x86_64" ]; then
  for file in Rclone_Browser*; do
    [ -f "$file" ] || continue
    newname=$(echo "$file" | sed 's/x86_64/linux-x86_64/; s/Rclone_Browser/rclone-browser/')
    [ "$file" != "$newname" ] && mv "$file" "$newname"
  done
fi

cp ./*AppImage "$ROOT"/release/

# clean AppImage temporary folder
cd ..
rm -rf "$TARGET"
