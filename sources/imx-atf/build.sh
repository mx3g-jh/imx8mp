#!/bin/bash

# ARM Trusted Firmware (ATF) Build Script for i.MX8MP
# This script builds the BL31 (EL3 Runtime Firmware) for i.MX8MP platform

set -e  # Exit on any error

# Configuration
CROSS_COMPILE="aarch64-linux-gnu-"
PLAT="imx8mp"
LD="${CROSS_COMPILE}ld"
CC="${CROSS_COMPILE}gcc"
IMX_BOOT_UART_BASE="0x30890000"
DEBUG="0"
JOBS=$(nproc)  # Use all available CPU cores
TARGET="bl31"

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

    local tools=("$CC" "$LD" "make")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            print_error "Required tool '$tool' not found in PATH"
            print_error "Please ensure the ARM64 cross-compilation toolchain is installed and in PATH"
            exit 1
        fi
    done

    print_info "All required tools found"
}

# Function to clean build artifacts
clean() {
    print_info "Cleaning build artifacts..."
    make clean PLAT="$PLAT" CROSS_COMPILE="$CROSS_COMPILE"
    print_info "Clean completed"
}

# Function to build
build() {
    print_info "Starting ATF build for $PLAT platform..."
    print_info "Target: $TARGET"
    print_info "Cross compiler: $CROSS_COMPILE"
    print_info "Using $JOBS parallel jobs"

    make -j "$JOBS" \
         CROSS_COMPILE="$CROSS_COMPILE" \
         PLAT="$PLAT" \
         LD="$LD" \
         CC="$CC" \
         IMX_BOOT_UART_BASE="$IMX_BOOT_UART_BASE" \
         DEBUG="$DEBUG" \
         "$TARGET"

    if [ $? -eq 0 ]; then
        print_info "Build completed successfully!"
        print_info "Output files can be found in build/ directory"
    else
        print_error "Build failed!"
        exit 1
    fi
}

# Main script logic
case "${1:-build}" in
    "clean")
        check_tools
        clean
        ;;
    "build")
        check_tools
        build
        ;;
    "rebuild")
        check_tools
        clean
        build
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  build    Build ATF (default)"
        echo "  clean    Clean build artifacts"
        echo "  rebuild  Clean and build"
        echo "  help     Show this help message"
        echo ""
        echo "Environment variables:"
        echo "  CROSS_COMPILE    Cross compiler prefix (default: aarch64-linux-gnu-)"
        echo "  PLAT            Platform (default: imx8mp)"
        echo "  JOBS            Number of parallel jobs (default: nproc)"
        ;;
    *)
        print_error "Unknown command: $1"
        print_error "Use '$0 help' for usage information"
        exit 1
        ;;
esac
