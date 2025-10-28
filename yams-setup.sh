#!/bin/bash

# YAMS Installation Script for Ubuntu 22.04 Server
# This script checks requirements and installs YAMS dependencies

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "YAMS Installation Script"
echo "=========================================="
echo ""

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run this script as root or with sudo"
    exit 1
fi

print_status "Running as root/sudo"

# Update system
echo ""
echo "Step 1: Updating system packages..."
apt-get update
apt-get upgrade -y
print_status "System updated"

# Check Ubuntu version
echo ""
echo "Step 2: Checking Ubuntu version..."
UBUNTU_VERSION=$(lsb_release -rs)
echo "Ubuntu version: $UBUNTU_VERSION"
if [[ "$UBUNTU_VERSION" == "22.04" ]]; then
    print_status "Ubuntu 22.04 confirmed"
else
    print_warning "Expected Ubuntu 22.04, found $UBUNTU_VERSION"
fi

# Install required packages
echo ""
echo "Step 3: Installing required packages..."
apt-get install -y curl git wget ca-certificates gnupg lsb-release

# Install Docker
echo ""
echo "Step 4: Installing Docker..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    print_status "Docker already installed: $DOCKER_VERSION"
else
    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    DOCKER_VERSION=$(docker --version)
    print_status "Docker installed: $DOCKER_VERSION"
fi

# Check Docker Compose
echo ""
echo "Step 5: Checking Docker Compose..."
if docker compose version &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version)
    print_status "Docker Compose available: $COMPOSE_VERSION"
else
    print_error "Docker Compose not available"
    exit 1
fi

# Add current user to docker group (if not root)
if [ -n "$SUDO_USER" ]; then
    echo ""
    echo "Step 6: Adding $SUDO_USER to docker group..."
    usermod -aG docker "$SUDO_USER"
    print_status "User $SUDO_USER added to docker group (logout/login required)"
fi

# Install YAMS
echo ""
echo "Step 7: Installing YAMS..."
echo "Creating YAMS installation directory..."

# Determine home directory
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    INSTALL_DIR="$USER_HOME/yams"
else
    INSTALL_DIR="/opt/yams"
fi

echo "Installation directory: $INSTALL_DIR"

# Download and run YAMS installer
cd /tmp
curl -fsSL https://yams.media/install.sh -o yams-install.sh
chmod +x yams-install.sh

print_status "YAMS installer downloaded"
echo ""
echo "=========================================="
echo "Prerequisites installed successfully!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. If you're not root, logout and login again for docker group changes to take effect"
echo "2. Run the YAMS installer: bash /tmp/yams-install.sh"
echo ""
echo "The installer will guide you through:"
echo "  - Choosing installation directory"
echo "  - Configuring media paths"
echo "  - Setting up VPN (optional)"
echo "  - Configuring services"
echo ""
print_warning "Would you like to run the YAMS installer now? (y/n)"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo ""
    print_status "Starting YAMS installer..."
    bash /tmp/yams-install.sh
else
    echo ""
    print_status "You can run the installer later with: bash /tmp/yams-install.sh"
fi

echo ""
echo "=========================================="
echo "Installation complete!"
echo "=========================================="
