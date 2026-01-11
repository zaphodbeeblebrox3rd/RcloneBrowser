#!/bin/bash

# Script to run the AppImage in a CentOS 7 container with GUI support
# This spins up a container with the freshly built AppImage and presents it to the developer

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DOCKERFILE="$SCRIPT_DIR/Dockerfile.test"
IMAGE_NAME="rclone-browser-test-centos7"
CONTAINER_NAME="rclone-browser-test"

# Default mode - prefer X11 to avoid VNC dialog issues
# Check if X11 is available (check for any X socket, not just X0)
if [ -n "$DISPLAY" ] && ls /tmp/.X11-unix/X* >/dev/null 2>&1; then
    MODE="x11"
else
    # If X11 not available, warn user about VNC dialog issues
    MODE="vnc"
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --x11)
            MODE="x11"
            shift
            ;;
        --vnc)
            MODE="vnc"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--x11|--vnc]"
            echo ""
            echo "Spins up a CentOS 7 container with the AppImage and presents the GUI."
            echo ""
            echo "Options:"
            echo "  --x11    Use X11 forwarding (Linux hosts only, recommended - no dialogs!)"
            echo "  --vnc    Use VNC server (works on all platforms, but may have dialog issues)"
            echo "  --help   Show this help message"
            echo ""
            echo "Note: X11 mode is recommended on Linux as it avoids VNC viewer dialog issues."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check if Docker is available
if ! command -v docker >/dev/null 2>&1; then
    echo "Error: Docker is not installed or not in PATH"
    echo "Please install Docker to use this script"
    exit 1
fi

# Check if we can run Docker (might need sudo)
DOCKER_CMD="docker"
if ! docker info >/dev/null 2>&1; then
    if sudo docker info >/dev/null 2>&1; then
        DOCKER_CMD="sudo docker"
        echo "Note: Using sudo for Docker commands"
    else
        echo "Error: Cannot access Docker. Please ensure Docker is running and you have permissions"
        exit 1
    fi
fi

# Check if AppImage exists
APPIMAGE=$(find "$ROOT_DIR/release" -name "*.AppImage" -type f 2>/dev/null | head -n 1)
if [ -z "$APPIMAGE" ]; then
    echo "Error: No AppImage found in $ROOT_DIR/release/"
    echo "Please build the AppImage first using: ./scripts/build_AppImage_docker.sh"
    exit 1
fi

echo "Found AppImage: $(basename "$APPIMAGE")"

# Build Docker image
echo "Building test container image..."
$DOCKER_CMD build -f "$DOCKERFILE" -t "$IMAGE_NAME" "$SCRIPT_DIR" >/dev/null 2>&1 || {
    echo "Building test container image (this may take a few minutes)..."
    $DOCKER_CMD build -f "$DOCKERFILE" -t "$IMAGE_NAME" "$SCRIPT_DIR"
}

# Stop and remove existing container if it exists
if $DOCKER_CMD ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Removing existing container..."
    $DOCKER_CMD rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
fi

# Prepare Docker run command
DOCKER_RUN_ARGS=(
    --rm
    --name "$CONTAINER_NAME"
    --cap-add SYS_ADMIN
    --device /dev/fuse
    -v "$APPIMAGE:/test/$(basename "$APPIMAGE"):ro"
)

# Mount rclone config from host if it exists
HOST_RCLONE_CONFIG="${HOME}/.config/rclone"
if [ -d "$HOST_RCLONE_CONFIG" ] || [ -f "$HOST_RCLONE_CONFIG/rclone.conf" ]; then
    # Mount the entire rclone config directory so the config file and any cached tokens are available
    DOCKER_RUN_ARGS+=(-v "$HOST_RCLONE_CONFIG:/root/.config/rclone:ro")
    echo "Mounting rclone config from host: $HOST_RCLONE_CONFIG"
else
    echo "Note: No rclone config found at $HOST_RCLONE_CONFIG (you can configure rclone in the GUI)"
fi

# AppImage name for use in container
APPIMAGE_NAME=$(basename "$APPIMAGE")

if [ "$MODE" = "x11" ]; then
    # X11 forwarding mode
    if [ -z "$DISPLAY" ] || ! ls /tmp/.X11-unix/X* >/dev/null 2>&1; then
        echo "Error: X11 not available"
        echo "X11 forwarding requires an X server to be running and DISPLAY to be set"
        echo "Try using --vnc mode instead, or start an X server"
        exit 1
    fi
    
    # Extract display number from DISPLAY (e.g., :1 -> X1, :0 -> X0)
    DISPLAY_NUM=$(echo "$DISPLAY" | sed 's/.*:\([0-9]*\).*/\1/')
    X_SOCKET="/tmp/.X11-unix/X${DISPLAY_NUM}"
    
    if [ ! -S "$X_SOCKET" ]; then
        echo "Warning: X11 socket $X_SOCKET not found, but will try anyway"
    fi
    
    # Allow X11 connections from Docker
    xhost +local:docker 2>/dev/null || echo "Warning: Could not run 'xhost +local:docker'. You may need to run this manually."
    
    DOCKER_RUN_ARGS+=(
        -e DISPLAY="$DISPLAY"
        -v /tmp/.X11-unix:/tmp/.X11-unix:rw
    )
    
    echo ""
    echo "=== Starting container with X11 forwarding ==="
    echo "The AppImage GUI should appear in your X server window"
    echo ""
    
    # Run container with X11 forwarding
    $DOCKER_CMD run -it "${DOCKER_RUN_ARGS[@]}" \
        "$IMAGE_NAME" \
        /bin/bash -c "
            export DISPLAY=$DISPLAY
            cd /test
            # Copy AppImage to writable location and make it executable
            cp '$APPIMAGE_NAME' appimage_copy
            chmod +x appimage_copy
            echo 'Starting AppImage...'
            ./appimage_copy &
            echo ''
            echo 'AppImage started in background.'
            echo 'You can also run it manually: ./appimage_copy'
            echo 'Press Ctrl+C to exit the container'
            /bin/bash
        "
    
    # Restore X11 access control
    xhost -local:docker 2>/dev/null || true
    
elif [ "$MODE" = "vnc" ]; then
    # VNC mode
    VNC_PORT=5901
    
    # Check if X11 is available and recommend it
    if [ -n "$DISPLAY" ] && ls /tmp/.X11-unix/X* >/dev/null 2>&1; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  ⚠️  RECOMMENDATION: Use X11 forwarding instead!"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  X11 forwarding avoids VNC viewer dialog issues."
        echo "  To use X11 mode, stop this and run:"
        echo "    $0 --x11"
        echo ""
        echo "  Continuing with VNC mode (you may encounter dialog issues)..."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        sleep 2
    fi
    
    DOCKER_RUN_ARGS+=(
        -p "$VNC_PORT:5901"
        -e DISPLAY=:1
    )
    
    echo ""
    echo "=== Starting container with VNC server ==="
    echo ""
    
    # Run container with VNC
    $DOCKER_CMD run -d "${DOCKER_RUN_ARGS[@]}" \
        "$IMAGE_NAME" \
        /bin/bash -c "
            # Start VNC server
            vncserver :1 -geometry 1024x768 -depth 24
            sleep 5
            
            # Wait for Xfce to fully start
            export DISPLAY=:1
            for i in {1..30}; do
                if xdpyinfo >/dev/null 2>&1; then
                    break
                fi
                sleep 1
            done
            
            # Copy AppImage to writable location and make it executable
            cd /test
            cp '$(basename "$APPIMAGE")' appimage_copy
            chmod +x appimage_copy
            
            # Start AppImage in the VNC session
            sleep 2
            ./appimage_copy >/tmp/appimage.log 2>&1 &
            
            echo 'AppImage started in VNC session'
            echo ''
            echo '=== VNC Server Running ==='
            echo 'Connect with: vncviewer localhost:$VNC_PORT'
            echo 'Password: password'
            echo ''
            echo 'Container is running in background.'
            echo 'To stop: docker stop $CONTAINER_NAME'
            echo 'To view logs: docker logs -f $CONTAINER_NAME'
            echo 'To get a shell: docker exec -it $CONTAINER_NAME /bin/bash'
            
            # Keep container running
            tail -f /dev/null
        " >/dev/null
    
    echo "Container started!"
    echo ""
    
    # Wait a moment for VNC server to be ready
    sleep 3
    
    # Show connection info and try to auto-launch Remmina
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  VNC Connection Ready"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Address: localhost:$VNC_PORT"
    echo "  Password: password"
    echo ""
    
    # Try to auto-launch Remmina if available
    if command -v remmina >/dev/null 2>&1; then
        echo "  Auto-launching Remmina..."
        remmina -c vnc://:password@localhost:$VNC_PORT >/dev/null 2>&1 &
        sleep 2
        echo "  Remmina launched (if it didn't open, try manually)"
        echo ""
    fi
    
    echo "  Connect using one of these methods:"
    echo ""
    
    # Detect available viewers and show appropriate command
    if command -v vncviewer >/dev/null 2>&1; then
        echo "  Option 1:"
        echo "    vncviewer localhost:$VNC_PORT"
        echo ""
    fi
    
    if command -v tigervnc-viewer >/dev/null 2>&1; then
        echo "  Option 2:"
        echo "    tigervnc-viewer localhost:$VNC_PORT"
        echo ""
    fi
    
    if [ -d "/Applications" ]; then
        echo "  Option 3 (macOS):"
        echo "    open vnc://localhost:$VNC_PORT"
        echo ""
    fi
    
    echo "  Or use any VNC viewer and connect to: localhost:$VNC_PORT"
    echo ""
    echo "  After connecting, you should see the Xfce desktop with the AppImage running."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    echo "Container management:"
    echo "  Stop:    $DOCKER_CMD stop $CONTAINER_NAME"
    echo "  Logs:    $DOCKER_CMD logs -f $CONTAINER_NAME"
    echo "  Shell:   $DOCKER_CMD exec -it $CONTAINER_NAME /bin/bash"
    echo ""
    echo "Press Ctrl+C to stop the container when done."
    
    # Keep script running so container stays alive
    # Wait for container to stop or user interrupt
    trap "echo ''; echo 'Stopping container...'; $DOCKER_CMD stop $CONTAINER_NAME >/dev/null 2>&1; exit 0" INT TERM
    $DOCKER_CMD wait $CONTAINER_NAME >/dev/null 2>&1 || wait
fi
