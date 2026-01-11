# Testing AppImage on CentOS 7

This directory contains a script to run the AppImage in a CentOS 7 container with GUI support, allowing you to verify it works correctly on CentOS 7.

## Prerequisites

- Docker installed and running
- For X11 forwarding mode: X server running on Linux host
- For VNC mode: VNC viewer client (for GUI access)

## Quick Start

1. **Build the AppImage first:**
   ```bash
   ./scripts/build_AppImage_docker.sh
   ```

2. **Run the AppImage in CentOS 7 container with VNC (recommended):**
   ```bash
   ./tests/run_test_container.sh --vnc
   ```

3. **Connect to the GUI:**
   ```bash
   vncviewer localhost:5901
   ```
   Password: `password`

4. **Or use X11 forwarding (Linux hosts only):**
   ```bash
   ./tests/run_test_container.sh --x11
   ```
   The AppImage GUI will appear in your X server window.

## Usage Modes

### VNC Mode (Default)

VNC mode works on all platforms. It starts a VNC server inside the container that you can connect to from your host machine.

**Usage:**
```bash
./tests/run_test_container.sh --vnc
```

**Connecting to the GUI:**
1. Install a VNC viewer if you don't have one:
   - **Linux:** `sudo apt install tigervnc-viewer` or `sudo apt install remmina`
   - **macOS:** Download from [RealVNC](https://www.realvnc.com/download/viewer/) or use built-in Screen Sharing
   - **Windows:** Download [TigerVNC](https://tigervnc.org/) or [RealVNC Viewer](https://www.realvnc.com/download/viewer/)

2. Connect to `localhost:5901`
   - Password: `password`

3. Or use command line:
   ```bash
   vncviewer localhost:5901
   ```

**Container Management:**
- View logs: `docker logs -f rclone-browser-test`
- Get a shell: `docker exec -it rclone-browser-test /bin/bash`
- Stop container: `docker stop rclone-browser-test`

### X11 Forwarding Mode

X11 forwarding allows the AppImage GUI to appear directly in your X server window. This only works on Linux hosts with an X server running.

**Usage:**
```bash
./tests/run_test_container.sh --x11
```

**Requirements:**
- X server running on host (most Linux desktop environments have this)
- X11 socket accessible at `/tmp/.X11-unix/X0`
- The script will automatically run `xhost +local:docker` to allow Docker access

**Note:** If you get permission errors, you may need to run:
```bash
xhost +local:docker
```

## What It Does

The script:
1. Finds your freshly built AppImage in the `release/` directory
2. Builds a CentOS 7 Docker image with desktop environment (Xfce) and VNC server
3. Starts a container with the AppImage mounted
4. Launches the AppImage automatically
5. Provides you with connection instructions to see the GUI

The AppImage runs in a CentOS 7 environment (glibc 2.17), so you can verify it works correctly on CentOS 7+ and Ubuntu 16.04+ systems.

## Troubleshooting

### "No AppImage found" error
- Make sure you've built the AppImage first: `./scripts/build_AppImage_docker.sh`
- Check that the AppImage exists in `release/` directory

### VNC connection refused
- Make sure the container is still running: `docker ps`
- Check if port 5901 is already in use: `netstat -an | grep 5901`
- Try a different port by modifying the script

### X11 forwarding not working
- Verify X server is running: `echo $DISPLAY`
- Check X11 socket exists: `ls -l /tmp/.X11-unix/X0`
- Try VNC mode instead, which is more reliable

### Container permissions issues
- You may need to use `sudo` with Docker commands
- Or add your user to the `docker` group: `sudo usermod -aG docker $USER` (requires logout/login)

## Files

- `Dockerfile.test` - Docker image definition for CentOS 7 test environment
- `run_test_container.sh` - Script to build and run the container with GUI support
- `Vagrantfile` - Optional Vagrant setup for VM-based testing (see below)

## Optional: VM Testing with Vagrant

For more comprehensive testing, you can use Vagrant to spin up a full CentOS 7 VM:

1. Install Vagrant: https://www.vagrantup.com/downloads
2. Start the VM:
   ```bash
   cd tests
   vagrant up
   ```
3. Connect via VNC or SSH
4. Copy AppImage to VM and test

See `Vagrantfile` for details.
