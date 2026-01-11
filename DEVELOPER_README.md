# Developer Guide

## Building AppImage with Docker

If you're building on Ubuntu 18.04+ but want to create an AppImage compatible with CentOS 7+ and Ubuntu 16.04+ (glibc 2.17+), you can use Docker to build in a CentOS 7 environment:

1.  Install Docker: `sudo apt install docker.io` (or use your distribution's package manager)
2.  Build the AppImage using Docker:
    ```bash
    ./scripts/build_AppImage_docker.sh
    ```
3.  The AppImage will be created in the `release/` directory with glibc 2.17 compatibility

This method allows you to build on modern systems (Ubuntu 20.04+, etc.) while ensuring the resulting AppImage works on older systems (CentOS 7+, Ubuntu 16.04+). The Docker container provides an isolated CentOS 7 build environment with glibc 2.17.

**Note:** The regular build script (`scripts/release_AppImage.sh`) will warn you if you're building on a system with glibc > 2.17 and suggest using Docker for better compatibility.

### Supported Distributions

The AppImage built using this Docker method is compatible with:
- CentOS 7+ (glibc 2.17+)
- RHEL 7+ (glibc 2.17+)
- Ubuntu 16.04+ (glibc 2.23+)
- Debian Stretch+ (glibc 2.24+)
- Most modern Linux distributions released after 2014

### Troubleshooting

If you encounter issues building the Docker image:
- Ensure Docker is running: `sudo systemctl start docker` (or equivalent)
- Check Docker permissions: You may need to add your user to the `docker` group or use `sudo`
- Verify the Dockerfile is in the repository root: `Dockerfile.appimage`
- Check available disk space: Docker images and builds can require several GB

If the AppImage build fails inside the container:
- Check that all source files are present in the repository
- Verify that the build script has execute permissions: `chmod +x scripts/release_AppImage.sh`
- Review the build output for specific error messages

## Testing AppImage on CentOS 7

After building the AppImage, you can test it on CentOS 7 to verify it works correctly. The `tests/` directory contains a script to run the AppImage in a CentOS 7 container with GUI support.

### Quick Start

1. **Build the AppImage** (if you haven't already):
   ```bash
   ./scripts/build_AppImage_docker.sh
   ```

2. **Run the AppImage in CentOS 7 container with VNC** (recommended):
   ```bash
   ./tests/run_test_container.sh --vnc
   ```
   Then connect to the VNC server at `localhost:5901` (password: `password`) to see the GUI.

3. **Or use X11 forwarding** (Linux hosts only):
   ```bash
   ./tests/run_test_container.sh --x11
   ```
   The AppImage GUI will appear in your X server window.

The script spins up a CentOS 7 container, mounts your AppImage, and launches it automatically so you can verify it works correctly.

### Detailed Documentation

For complete instructions, troubleshooting, and optional VM-based testing with Vagrant, see [tests/README.md](tests/README.md).

