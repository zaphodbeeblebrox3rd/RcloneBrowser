<img src="https://github.com/zaphodbeeblebrox3rd/RcloneBrowser/wiki/images/RcloneBrowserLongLogo1.png" width="80%" />

[![Travis CI Build Status][img1]][1] [![AppVeyor Build Status][img2]][2] [![Downloads][img3]][3] [![Release][img4]][4] <img src="https://img.shields.io/badge/Qt-cmake-green.svg"> [![License][img5]][5]

Rclone browser
==============
Simple cross platform GUI for [rclone](https://rclone.org/) command line tool.

Supports macOS, GNU/Linux, BSD family and Windows.

Table of contents
-------------------
*   [Features](https://github.com/zaphodbeeblebrox3rd/RcloneBrowser#features)
*   [Sample screenshots](https://github.com/zaphodbeeblebrox3rd/RcloneBrowser#sample-screenshots)
*   [How to get it](https://github.com/zaphodbeeblebrox3rd/RcloneBrowser#how-to-get-it)
*   [Why AppImage only for Linux](https://github.com/zaphodbeeblebrox3rd/RcloneBrowser#why-appimage-only-for-linux)
*   [Build instructions](https://github.com/zaphodbeeblebrox3rd/RcloneBrowser#build-instructions)
    *   [Linux](https://github.com/zaphodbeeblebrox3rd/RcloneBrowser#linux)
    *   [FreeBSD](https://github.com/zaphodbeeblebrox3rd/RcloneBrowser#freebsd)
    *   [OpenBSD](https://github.com/zaphodbeeblebrox3rd/RcloneBrowser#openbsd)
    *   [NetBSD](https://github.com/zaphodbeeblebrox3rd/RcloneBrowser#netbsd)
    *   [macOS](https://github.com/zaphodbeeblebrox3rd/RcloneBrowser#macos)
    *   [Windows](https://github.com/zaphodbeeblebrox3rd/RcloneBrowser#windows)
*   [Portable vs standard mode](https://github.com/zaphodbeeblebrox3rd/RcloneBrowser#portable-vs-standard-mode)
*   [History](https://github.com/zaphodbeeblebrox3rd/RcloneBrowser#history)

Features
--------
*   Allows to browse and modify any rclone remote, including encrypted ones
*   Uses same configuration file as rclone, no extra configuration required
*   Supports custom location and encryption for rclone.conf configuration file
*   Simultaneously navigate multiple repositories in separate tabs
*   Lists files hierarchically with file name, size and modify date
*   All rclone commands are executed asynchronously, no freezing GUI
*   File hierarchy is lazily cached in memory, for faster traversal of folders
*   Allows to upload, download, create new folders, rename or delete files and folders
*   Allows to calculate size of folder, export list of files and copy rclone command to clipboard
*   Can process multiple upload or download jobs in background
*   Drag & drop support for dragging files from local file explorer for uploading
*   Streaming media files for playback in player like [vlc][6] or similar
*   Mount and unmount folders on macOS, GNU/Linux and Windows (for Windows requires [winfsp](http://www.secfs.net/winfsp/) and for mac [fuse for macOS](https://osxfuse.github.io/))
*   Optionally minimizes to tray, with notifications when upload/download finishes
*   Supports portable mode (create .ini file next to executable with same name), rclone and rclone.conf path now can be relative to executable
*   Supports drive-shared-with-me (Google Drive specific)
*   For remotes supporting public link sharing has an option (right-click menu) to fetch it
*   Supports tasks. Created jobs can be saved and run or edited later.
*   Configurable dark mode for all systems

Sample screenshots
-------------------
**macOS**
<p align="center">
<img src="https://github.com/zaphodbeeblebrox3rd/RcloneBrowser/wiki/images/screenshot24.png" width="100%" />
<img src="https://github.com/zaphodbeeblebrox3rd/RcloneBrowser/wiki/images/screenshot23.png" width="75%" />
</p>

**Linux**
<p align="center">
<img src="https://github.com/zaphodbeeblebrox3rd/RcloneBrowser/wiki/images/screenshot21.png" width="65%" />
</p>
&nbsp;
<p align="center">
<img src="https://github.com/zaphodbeeblebrox3rd/RcloneBrowser/wiki/images/screenshot22.png" width="65%" />
</p>

&nbsp;
**Windows**
<p align="center">
<img src="https://github.com/zaphodbeeblebrox3rd/RcloneBrowser/wiki/images/screenshot25.PNG" width="100%" />
</p>
&nbsp;
<p align="center">
<img src="https://github.com/zaphodbeeblebrox3rd/RcloneBrowser/wiki/images/screenshot26.PNG" width="65%" />
</p>

&nbsp;

How to get it
--------------
Get binaries for Windows, macOS and Linux on [releases][3]' page.

Windows installers (64-bit and 32-bit) are compatible with all x86 based Windows OS starting with Windows 7. If for whatever reason somebody would prefer not to run installer all files can be extracted using [innoextract](https://constexpr.org/innoextract/).

Mac version is compiled to run on all versions of macOS starting with 10.9.

Situation with Linux is a bit fuzzier...
Linux binary ([AppImage](https://appimage.org/)) for armhf architecture runs on any Raspberry Pi hardware using Raspbian based on Stretch or Buster.

Linux binaries (AppImage) for x86_64 and i386 architectures should run on systems using distributions released in the last few years. x86_64 one is built on CentOS 7 (glibc 2.17) and i386 on Ubuntu 16.04 LTS (released in 2016, glibc 2.23). Building on CentOS 7 ensures the AppImage is compatible with systems running glibc 2.17 and newer (CentOS 7+, RHEL 7+, Ubuntu 16.04+, Debian Stretch+, etc.).

The whole idea with AppImage is to build it on the oldest still supported LTS distro – and it should work on all newer OS releases. AppImage contains an aplication and all the files the app needs to run. In other words, each AppImage has no dependencies other than what is included in the base operating system.

In practical terms it means that for example for Ubuntu Rclone Browser AppImage works on all versions starting with 16.04 LTS (glibc 2.23+) and for Debian starting with Stretch (glibc 2.24+). The AppImage also works on CentOS 7+ and RHEL 7+ (glibc 2.17+). With other distributions YMMV but I test major ones like Suse or Fedora. This is Linux. 10000 different distributions… with changes and customizations often only their authors are aware of. I would be happy to hear what distribution it does not work for.

To make life easier when using AppImages on Linux, you can use [AppImageLauncher](https://github.com/TheAssassin/AppImageLauncher) which monitors your system for downloaded AppImages and provides several useful benefits including:

*   **AppImage desktop integration** - AppImageLauncher allows you to integrate AppImages you download into your application menu or launcher to make it easier for you to launch them. It also takes care of moving them into a central location, where you can find them later if you need access to them again.

*   **Update management** - AppImageLauncher provides a simple to use update mechanism. After desktop integration, the context menu of the AppImage's entry in the application launcher will have an entry for updating that launches a little helper tool that uses AppImageUpdate internally. Just click the entry and have the tool search and apply updates.

*   **Easy removal of AppImages from system** - Removing integrated AppImages is pretty simple, too. Similar to updating AppImages, you will find an entry in the context menu in the application launcher that triggers a removal tool. You will be asked to confirm the removal. If you choose to do so, the desktop integration is undone, and the file is removed from your system.

More and more operating systems include Rclone Browser in their offical distribution channels. You can check availibility [here](https://repology.org/project/rclone-browser/packages).

ArchLinux users can install latest release from AUR repository: [rclone-browser][7].

Fedora package is now available from [Fedora packages](https://apps.fedoraproject.org/packages/rclone-browser) - simply run `sudo dnf install rclone-browser`

FreeBSD has its version available from [freshports](https://www.freshports.org/net/rclone-browser) website.

And if you would like to run it directly on your NAS (e.g. Synology or QNAP) there is docker version provided by @romancin - https://github.com/romancin/rclonebrowser-docker

### Compatibility Table for AppImage with x86_64

| Distribution | Unsupported Versions | Supported Versions |
|--------------|---------------------|-------------------|
| **Debian/Ubuntu** | Ubuntu 14.04 and earlier, Debian 8 (Jessie) and earlier | Ubuntu 16.04+, Debian 9 (Stretch)+ |
| **Suse/OpenSuse** | OpenSUSE 13.2 and earlier | OpenSUSE Leap 42.1+, Tumbleweed |
| **RHEL/CentOS** | RHEL 6 and earlier, CentOS 6 and earlier | RHEL 7+, CentOS 7+ |
| **Fedora** | Fedora 21 and earlier | Fedora 22+ |
| **Arch/Manjaro** | N/A (rolling release) | All current versions |
| **FreeBSD** | FreeBSD 10 and earlier | FreeBSD 11+ |
| **OpenBSD** | OpenBSD 5.8 and earlier | OpenBSD 6.0+ |
| **NetBSD** | NetBSD 7 and earlier | NetBSD 8+ |
| **macOS** | macOS 10.8 and earlier | macOS 10.9+ |
| **Windows** | Windows 7 and earlier (without Visual Studio 2015+) | Windows 8+ with Visual Studio 2015+ or Windows 10+ |

Why AppImage only for Linux
----------------------------
Starting with version 1.7.0 Linux binaries are only available in [AppImage](https://appimage.org/) format. Some explanation on this... 

Binaries for Linux desktop applications is a major f*ing pain in the ass... as Linus Torvalds said - [DebConf 14_ QA](https://www.youtube.com/watch?v=5PmHRSeA2c8) at 05:40:

> I'm talking about actual application writers that want to make a package of their application for Linux. And I've seen this firsthand with the other project I've been involved with, which is my divelog application.
> We make binaries for Windows and OS X. 

He is talking about [Subsurface](https://subsurface-divelog.org). His small side project.

> We basically don't make binaries for Linux. Why? Because binaries for Linux desktop applications is a major f*ing pain in the ass. Right. You don't make binaries for Linux. You make binaries for Fedora 19, Fedora 20, maybe there's even like RHEL 5 from ten years ago, you make binaries for debian stable.
> Or actually you don't make binaries for debian stable because debian stable has libraries that are so old that anything that was built in the last century doesn't work. But you might make binaries for debian... whatever the codename is for unstable. And even that is a major pain because (...) debian has those rules that you are supposed to use shared libraries. Right.
>
> And if you don't use shared libraries, getting your package in, like, is just painful. 
> But using shared libraries is not an option when the libraries are experimental and the libraries are used by two people and one of them is crazy, so every other day some ABI breaks. 
> So you actually want to just compile one binary and have it work. Preferably forever. And preferably across all Linux distributions. 
> And I actually think distributions have done a horribly, horribly bad job.
>
> One of the things that I do on the kernel - and I have to fight this every single release and I think it's sad - we have one rule in the kernel, one rule: we don't break userspace. (...) People break userspace, I get really, really angry. (...) 
> And then all the distributions come in and they screw it all up. Because they break binary compatibility left and right. 
> They update glibc and everything breaks. (...) 
> So that's my rant. And that's what I really fundamentally think needs to change for Linux to work on the desktop because you can't have applications writers to do fifteen billion different versions.

And I totally agree with above. I want to provide binary which works across as many Linux distributions as possible and I dont have time to fight with all mess with different dependencies etc. There are other similar ditribution formats e.g. flatpak but I had to choose one and I decided that AppImage is my best choice. I am not saying that AppImage is the best one but it nicely fits my objectives. You can see comparison of different solutions [here](https://github.com/AppImage/AppImageKit/wiki/Similar-projects#comparison).

If for whatever reason you are not happy or your system is not covered with provided binaries you can easily build Rclone Browser for yourself. Especially on Unix-like systems it is very easy. Please see below step by step instructions for major operating systems. I have tested all of them and you can have your own Linux distribution Rclone Browser running in no time  - it takes 8 min on Raspberry Pi 3B+, on modern desktop it can be less than a minute.

Build instructions
------------------

**System Requirements:** This project requires C++14 support (GCC 5.1+ or equivalent) and Qt5. The source code can be built on Ubuntu 18.04 LTS through 25.10 and equivalent distributions. The following table shows supported and unsupported major versions for each distribution:

**Note for AppImage Builds:** While the source code builds on Ubuntu 18.04-25.10, AppImages should be built on **CentOS 7** (glibc 2.17) to ensure compatibility with systems running glibc 2.17 and newer (CentOS 7+, RHEL 7+, Ubuntu 16.04+, etc.). Building AppImages on newer systems will limit compatibility to systems with matching or newer glibc versions.

**Building AppImages on Newer Systems:** If you're building on Ubuntu 18.04+ but want to maintain compatibility with CentOS 7+, RHEL 7+, and Ubuntu 16.04+, you can use Docker to build in a CentOS 7 environment. See the [Developer Guide](DEVELOPER_README.md#building-appimage-with-docker) for instructions.


### Linux
> Compiling, rather than using the AppImage will yield you a build with modern OpenSSL implementations.  The AppImage is built with OpenSSL 1.1.  It might or might not be a real-life security concern in this context in the way it is used.  
1.  Install dependencies for your particular distribution:
    *   **Debian/Ubuntu and derivatives**: `sudo apt update && sudo apt -y install git g++ cmake make qtdeclarative5-dev` 
    *   **Suse/OpenSuse**: `sudo zypper ref && sudo zypper --non-interactive install git cmake make gcc-c++ libQt5Core-devel libQt5Widgets-devel libQt5Network-devel`
    *   **RHEL**: `sudo yum -y install git gcc-c++ cmake make qt5-qtdeclarative`
    *   **Fedora**: `sudo dnf -y install git g++ cmake make qt5-qtdeclarative-devel`
    *   **Arch/Manjaro**: `sudo pacman -Sy --noconfirm --needed git gcc cmake make qt5-declarative`
2.  Clone source code from this repo `git clone https://github.com/zaphodbeeblebrox3rd/RcloneBrowser.git`
3.  Go to source folder `cd RcloneBrowser`
4.  Create new build folder - `mkdir build && cd build`
5.  Run `cmake ..` from build folder to create makefile
6.  Run `make` from build folder to create binary
7.  Install `sudo make install`

**For Docker-based AppImage builds:** See the [Developer Guide](DEVELOPER_README.md#building-appimage-with-docker) for instructions on building AppImages using Docker for maximum compatibility.

### FreeBSD
1.  Install dependencies `sudo pkg install git cmake qt5-buildtools qt5-declarative qt5-qmake`
2.  Clone source code from this repo `git clone https://github.com/zaphodbeeblebrox3rd/RcloneBrowser.git`
3.  Go to source folder `cd RcloneBrowser`
4.  Create new build folder - `mkdir build && cd build`
5.  Run `cmake ..` from build folder to create makefile
6.  Run `make` from build folder to create binary
7.  Install `sudo make install`

*Note: For rclone remotes mount to work please see this forum [thread](https://forum.rclone.org/t/failed-to-mount-fuse-fs-freebsd/7723/9). For me it was enough to run `sudo sysctl vfs.usermount=1`*

### OpenBSD
1.  Install dependencies `sudo pkg_add git cmake qt5`
2.  Clone source code from this repo `git clone https://github.com/zaphodbeeblebrox3rd/RcloneBrowser.git`
3.  Go to source folder `cd RcloneBrowser`
4.  Create new build folder - `mkdir build && cd build`
5.  Run `cmake .. -DCMAKE_PREFIX_PATH:PATH=/usr/local/lib/qt5/cmake` from build folder to create makefile
6.  Run `make` from build folder to create binary
7.  Install `sudo make install`

*Note: rclone for openBSD does not support `mount` hence this feature is disabled in Rclone Browser. cgofuse guys did not manage to implement it: [#18][billziss-gh_cgofuse_i18]*

### NetBSD
1.  Install dependencies `sudo pkgin install git cmake qt5-qtdeclarative`
2.  Clone source code from this repo `git clone https://github.com/zaphodbeeblebrox3rd/RcloneBrowser.git`
3.  Go to source folder `cd RcloneBrowser`
4.  Create new build folder - `mkdir build && cd build`
5.  Run `cmake .. -DCMAKE_PREFIX_PATH:PATH=/usr/pkg/qt5` from build folder to create makefile
6.  Run `make` from build folder to create binary
7.  Install `sudo make install`

*Note: rclone for NetBSD does not support `mount` hence this feature is disabled in Rclone Browser. cgofuse guys did not manage to implement it: [#18][billziss-gh_cgofuse_i18]*

### macOS
1.  If you don't have [Homebrew](https://brew.sh/) yet install it `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`
2.  You might be asked to install xcode command line tools - do it. This is actuall macOS SDK, headers, and build tools. You don't need full xcode IDE.
3.  Install dependencies `brew install git cmake qt5`
4.  Clone source code from this repo `git clone https://github.com/zaphodbeeblebrox3rd/RcloneBrowser.git`
5.  Go to source folder `cd RcloneBrowser`
6.  Create new build folder - `mkdir build && cd build`
7.  Run `cmake .. -DCMAKE_PREFIX_PATH:PATH=/usr/local/opt/qt` from build folder to create makefile
8.  Run `make` from build folder to create binary
9.  Go to yet another newly created build folder `cd build`. Your binary should be here
10. `cp -r rclone-browser.app /Applications/`

> MacOS Optional - for mounting of remotes.  
> - Install macFuse `brew install --cask macfuse`.  
> - Make sure that rclone is **not** be Brew-installed (brew uninstall if necessary).
> - Install rclone from the rclone website or this command: `sudo -v ; curl https://rclone.org/install.sh | sudo bash`
> - Attempt to mount a remote, see there will be an error.  
> - Attempt to enable the system extensions in System Settings -> Privacy and Security.  Follow the prompts to shut down your machine and enable Kernel extensions.

### Windows
1.  Get [Visual Studio 2019][8] - you need "Desktop development with C++" module only
2.  Install [CMake][9]
3.  Install latest Qt v5 (64-bit) from [Qt website][10]. You only need "Qt 5.13.2 Prebuilt Components for MSVC 2017 64-bit" (MSVC 2017 64-bit). Later steps assume you install it in c:\Qt
4.  Get rclone-browser source code. You either need to install git and clone it or download zip file from [releases][3]
5.  Go to source folder `cd RcloneBrowser`
6.  From cmd create new build folder  - `mkdir build` and then `cd build`
7.  run `cmake -G "Visual Studio 16 2019" -A x64 -DCMAKE_CONFIGURATION_TYPES="Release" -DCMAKE_PREFIX_PATH=c:\Qt\5.13.2\msvc2017_64 .. && cmake --build . --config Release`
8.  run `c:\Qt\5.13.2\msvc2017_64\bin\windeployqt.exe --no-translations --no-angle --no-compiler-runtime --no-svg ".\build\Release\RcloneBrowser.exe"`
9.  build\Release folder contains now RcloneBrowser.exe binary and all other files required to run it
10. If your system does not have required MSVC runtime you can install one from Microsoft [website](https://support.microsoft.com/en-gb/help/2977003/the-latest-supported-visual-c-downloads).

Portable vs standard mode
-----------------------

In standard operations mode all configurations files are stored in the following locations:

*   macOS:
    *   preferences: ~/Library/Preferences/com.rclone-browser.rclone-browser.plist
    *   tasks file:  ~/Library/Application Support/rclone-browser/rclone-browser/tasks.bin
    *   lock file:   in $TMPDIR assigned by OS

*   Linux/BSD:
    *   preferences: ~/.config/rclone-browser/rclone-browser.conf
    *   tasks file:  ~/.local/share/rclone-browser/rclone-browser/tasks.bin
    *   lock file:   in $TMPDIR or /tmp if $TMPDIR is not defined

*   Windows:
    *   preferences: in registry Computer\HKEY_CURRENT_USER\Software\rclone-browser\rclone-browser
    *   tasks file:  %HOMEPATH%\AppData\Local\rclone-browser\rclone-browser\tasks.bin
    *   lock file:   %HOMEPATH%\AppData\Local\Temp\

Starting with version 1.7.0 of Rclone Browser portable mode is supported on all operating systems. To enable it you have to create .ini file (for Windows and macOS) next to executable with same name - e.g. if application name is `RcloneBrowser.exe` or `RcloneBrowser.app` create `RcloneBrowser.ini`. For Linux create a directory (not a file) with the same name as the AppImage plus the ".config" extension in the same directory as the AppImage file - e.g. if application name is `rclone-browser.AppImage` create folder `rclone-browser.AppImage.config` next to it. This is solution supported by [AppImage specification](https://docs.appimage.org/user-guide/portable-mode.html).

In portable mode all configuration files will be stored in the same folder as application (in .config folder on Linux) and rclone and rclone.conf path can be relative to executable - so if in preferences in `rclone location` you put `rclone.exe` browser with look for it in folder where application resides. It means that you can put all required stuff including rclone binary itself and its config on e.g. memory stick and everything will be stored there.

History
--------
I have been using rclone-browser for long time and being annoyed by small not working bits and pieces I decided for DYI approach and this is how this repo was created. Original mmozeiko’s [repository](https://github.com/mmozeiko/RcloneBrowser) was abandoned and in the meantime rclone changed few things breaking rclone-browser functionality.

I looked around but could not find anything fully working. Some github users made progress in fixing and adding stuff so I built upon it.

I used DinCahill's [fork](https://github.com/DinCahill/RcloneBrowser) as a base for my version.

I fixed whatever I found not working and added various tweaks enhancing functionality. I recompiled and repackaged everything using latest Qt (5.13.1) and latest platforms' compilers. This on its own fixed some issues and added new features like support for dark mode in macOS. Then followed with more fixes and more features. Rclone Browser was great again:) and is getting better.

Acknowledgments
---------------

This project uses various external tools and libraries during development and packaging. See [ACKNOWLEDGMENTS.md](ACKNOWLEDGMENTS.md) for a complete list and recognition of their creators and maintainers.

Special Thanks
--------------

Special recognition goes to **kapitainsky** for his major contributions to this project over the years. His significant work in maintaining, fixing, and enhancing Rclone Browser has been invaluable to the community.

If you'd like to support kapitainsky's efforts to obtain code-signing certificates for Windows and macOS releases (which would eliminate security warnings and improve user experience), you can contribute via [PayPal](https://www.paypal.me/kapitainsky).


[1]: https://travis-ci.org/zaphodbeeblebrox3rd/RcloneBrowser
[2]: https://ci.appveyor.com/project/zaphodbeeblebrox3rd/RcloneBrowser
[3]: https://github.com/zaphodbeeblebrox3rd/RcloneBrowser/releases
[4]: https://github.com/zaphodbeeblebrox3rd/RcloneBrowser/releases/latest
[5]: https://github.com/zaphodbeeblebrox3rd/RcloneBrowser/blob/master/LICENSE
[6]: https://www.videolan.org
[7]: https://aur.archlinux.org/packages/rclone-browser
[8]: https://docs.microsoft.com/en-us/visualstudio/releases/2019/release-notes
[9]: http://www.cmake.org/
[10]: https://www.qt.io/download-open-source/
[img1]: https://api.travis-ci.org/zaphodbeeblebrox3rd/RcloneBrowser.svg?branch=master
[img2]: https://ci.appveyor.com/api/projects/status/cclx7jc48t4u4x9u?svg=true
[img3]: https://img.shields.io/github/downloads/zaphodbeeblebrox3rd/RcloneBrowser/total.svg?maxAge=3600
[img4]: https://img.shields.io/github/release/zaphodbeeblebrox3rd/RcloneBrowser.svg?maxAge=3600
[img5]: https://img.shields.io/github/license/zaphodbeeblebrox3rd/RcloneBrowser.svg?maxAge=3600
[billziss-gh_cgofuse_i18]: https://github.com/billziss-gh/cgofuse/issues/18
