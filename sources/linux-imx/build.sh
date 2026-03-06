#!/bin/bash

# Linux Kernel Build Script for i.MX platforms
# This script builds the Linux kernel for ARM64 architecture

set -e  # Exit on any error

# Configuration
ARCH="arm64"
CROSS_COMPILE="aarch64-linux-gnu-"
CONFIG="imx_v8_defconfig"
TARGET="Image"
JOBS=$(nproc)  # Use all available CPU cores

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if required tools are available
check_tools() {
    print_info "Checking required tools..."

    local tools=("${CROSS_COMPILE}gcc" "${CROSS_COMPILE}ld" "make" "bc")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            print_error "Required tool '$tool' not found in PATH"
            print_error "Please ensure the ARM64 cross-compilation toolchain is installed and in PATH"
            exit 1
        fi
    done

    print_info "All required tools found"
}

# Function to configure kernel
configure() {
    print_info "Configuring kernel with $CONFIG..."
    make ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" "$CONFIG"
    print_info "Configuration completed"
}

# Function to build kernel
build() {
    print_info "Building Linux kernel..."
    print_info "Architecture: $ARCH"
    print_info "Cross compiler: $CROSS_COMPILE"
    print_info "Target: $TARGET"
    print_info "Using $JOBS parallel jobs"

    make ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" -j"$JOBS" "$TARGET"

    if [ $? -eq 0 ]; then
        print_info "Kernel build completed successfully!"
        print_info "Kernel image: arch/$ARCH/boot/$TARGET"
    else
        print_error "Kernel build failed!"
        exit 1
    fi
}

# Function to clean build artifacts
clean() {
    print_info "Cleaning kernel build artifacts..."
    make ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" clean
    print_info "Clean completed"
}

# Function to perform distclean
distclean() {
    print_info "Performing distclean..."
    make ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" distclean
    print_info "Distclean completed"
}

# Function to build modules
modules() {
    print_info "Building kernel modules..."
    make ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" -j"$JOBS" modules
    print_info "Modules build completed"
}

# Function to install modules
modules_install() {
    local install_path="${1:-/tmp/modules}"
    print_info "Installing kernel modules to $install_path..."
    make ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" INSTALL_MOD_PATH="$install_path" modules_install
    print_info "Modules installation completed"
}

# Main script logic
case "${1:-build}" in
    "config")
        check_tools
        configure
        ;;
    "build")
        check_tools
        configure
        build
        ;;
    "clean")
        clean
        ;;
    "distclean")
        distclean
        ;;
    "modules")
        check_tools
        configure
        modules
        ;;
    "modules_install")
        check_tools
        configure
        modules
        modules_install "$2"
        ;;
    "rebuild")
        check_tools
        clean
        configure
        build
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command] [options]"
        echo ""
        echo "Commands:"
        echo "  config          Configure kernel (imx_v8_defconfig)"
        echo "  build           Configure and build kernel (default)"
        echo "  clean           Clean build artifacts"
        echo "  distclean       Clean everything including config"
        echo "  modules         Build kernel modules"
        echo "  modules_install Install modules to path (default: /tmp/modules)"
        echo "  rebuild         Clean, configure and build"
        echo "  help            Show this help message"
        echo ""
        echo "Environment variables:"
        echo "  ARCH            Architecture (default: arm64)"
        echo "  CROSS_COMPILE   Cross compiler prefix (default: aarch64-linux-gnu-)"
        echo "  CONFIG          Kernel config (default: imx_v8_defconfig)"
        echo "  JOBS            Number of parallel jobs (default: nproc)"
        ;;
    *)
        print_error "Unknown command: $1"
        print_error "Use '$0 help' for usage information"
        exit 1
        ;;
esac