#!/bin/sh


# URL of the plugin .tar.gz file
PLUGIN_URL="https://github.com/ismail9875/SatelliteManager/raw/refs/heads/main/SatelliteManager.tar.gz"

# Temp directory
TEMP_DIR="/tmp/satmanager_install"

# Plugin path
PLUGIN_PATH="/usr/lib/enigma2/python/Plugins/Extensions/SatelliteManager"

# Log file
LOG_FILE="/tmp/satmanager_install.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to print status
print_status() {
    echo -e "${BLUE}[*]${NC} $1"
    log "$1"
}

# Function to print success
print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
    log "SUCCESS: $1"
}

# Function to print error
print_error() {
    echo -e "${RED}[✗]${NC} $1"
    log "ERROR: $1"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
    log "WARNING: $1"
}

# Clear screen
clear

echo "====================================================="
echo "     SatelliteManager Plugin Installation (Auto)"
echo "====================================================="
echo ""
print_status "Starting automatic installation..."

# Check if running as root
print_status "Checking root permissions..."
if [ "$(id -u)" != "0" ]; then
    print_error "This script must be run as root"
    exit 1
fi
print_success "Root permissions confirmed"

# Check internet connection
print_status "Checking internet connection..."
if ping -c 1 -W 2 github.com > /dev/null 2>&1; then
    print_success "Internet connection OK"
else
    print_warning "Cannot reach github.com, but continuing..."
fi

# Check for required commands
print_status "Checking required commands..."

if command -v wget >/dev/null 2>&1; then
    DOWNLOAD_CMD="wget --no-check-certificate -q -O"
    print_success "wget found"
elif command -v curl >/dev/null 2>&1; then
    DOWNLOAD_CMD="curl -k -L -s -o"
    print_success "curl found"
else
    print_error "Neither wget nor curl is installed"
    exit 1
fi

if command -v tar >/dev/null 2>&1; then
    print_success "tar found"
else
    print_error "tar command not found"
    exit 1
fi

# Create temporary directory
print_status "Creating temporary directory..."
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"
if [ $? -ne 0 ]; then
    print_error "Cannot create temporary directory"
    exit 1
fi
print_success "Temporary directory created: $TEMP_DIR"

# Download the plugin archive
print_status "Downloading plugin from GitHub..."
cd "$TEMP_DIR"
$DOWNLOAD_CMD SatelliteManager.tar.gz "$PLUGIN_URL"

# Check download result
if [ ! -f "SatelliteManager.tar.gz" ]; then
    print_error "Failed to download the plugin archive"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Check file size
FILE_SIZE=$(stat -c%s "SatelliteManager.tar.gz" 2>/dev/null || stat -f%z "SatelliteManager.tar.gz" 2>/dev/null)
if [ "$FILE_SIZE" -lt 1000 ]; then
    print_error "Downloaded file is too small (may be an error page)"
    rm -rf "$TEMP_DIR"
    exit 1
fi
print_success "Downloaded successfully ($FILE_SIZE bytes)"

# Extract the archive directly to root
print_status "Extracting archive to root..."
tar -xzf SatelliteManager.tar.gz -C /
if [ $? -ne 0 ]; then
    print_error "Failed to extract archive"
    rm -rf "$TEMP_DIR"
    exit 1
fi
print_success "Extraction completed"

# Set correct permissions
if [ -d "$PLUGIN_PATH" ]; then
    print_status "Setting file permissions for plugin..."
    find "$PLUGIN_PATH" -type d -exec chmod 755 {} \;
    find "$PLUGIN_PATH" -type f -exec chmod 644 {} \;
    print_success "Permissions set successfully"
else
    print_warning "Plugin directory not found at $PLUGIN_PATH"
    print_status "Searching for plugin files..."
    find /usr/lib/enigma2 -name "SatelliteManager" -type d 2>/dev/null
fi

# Clean up temporary directory
print_status "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"
print_success "Cleanup completed"

echo ""
echo "====================================================="
print_success "Installation completed successfully!"
echo "====================================================="
echo ""
print_status "Files installed to: $PLUGIN_PATH"
echo ""

# Automatic restart without asking
print_status "Restarting Enigma2 GUI in 3 seconds..."
sleep 3
print_status "Restarting now..."
init 4 && sleep 2 && init 3 &

exit 0