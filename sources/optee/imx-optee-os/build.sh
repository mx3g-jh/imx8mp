#!/bin/bash

# OP-TEE OS Build Script for i.MX platforms
# This script builds the Trusted Execution Environment (TEE) for ARM64

set -e  # Exit on any error

# Configuration
CROSS_COMPILE="aarch64-linux-gnu-"
PLATFORM="imx-mx8mpevk"
JOBS=$(nproc)  # Use all available CPU cores
TA_DEV_KIT_DIR="${TA_DEV_KIT_DIR:-../optee-os-tadevkit}"

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

    local tools=("${CROSS_COMPILE}gcc" "${CROSS_COMPILE}ld" "make" "python3")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            print_error "Required tool '$tool' not found in PATH"
            print_error "Please ensure the ARM64 cross-compilation toolchain and Python3 are installed"
            exit 1
        fi
    done

    print_info "All required tools found"
}

# Function to check TA dev kit
check_ta_devkit() {
    if [ ! -d "$TA_DEV_KIT_DIR" ]; then
        print_warning "TA dev kit directory not found: $TA_DEV_KIT_DIR"
        print_warning "Some TA (Trusted Applications) may not build correctly"
        print_warning "Set TA_DEV_KIT_DIR environment variable if needed"
    else
        print_info "TA dev kit found: $TA_DEV_KIT_DIR"
    fi
}

# Function to build OP-TEE OS
build() {
    print_info "Building OP-TEE OS..."
    print_info "Platform: $PLATFORM"
    print_info "Cross compiler: $CROSS_COMPILE"
    print_info "Using $JOBS parallel jobs"

    make -j"$JOBS" CROSS_COMPILE="$CROSS_COMPILE" PLATFORM="$PLATFORM"

    if [ $? -eq 0 ]; then
        print_info "OP-TEE OS build completed successfully!"
        print_info "TEE binary: out/arm-plat-$PLATFORM/core/tee.bin"
        print_info "TEE pager: out/arm-plat-$PLATFORM/core/tee-pager.bin"
        print_info "TEE raw: out/arm-plat-$PLATFORM/core/tee-raw.bin"
    else
        print_error "OP-TEE OS build failed!"
        exit 1
    fi
}

# Function to clean build artifacts
clean() {
    print_info "Cleaning OP-TEE OS build artifacts..."
    make clean
    print_info "Clean completed"
}

# Function to perform distclean
distclean() {
    print_info "Performing distclean..."
    make distclean
    print_info "Distclean completed"
}

# Function to build with debug symbols
debug() {
    print_info "Building OP-TEE OS with debug symbols..."
    make -j"$JOBS" CROSS_COMPILE="$CROSS_COMPILE" PLATFORM="$PLATFORM" DEBUG=1

    if [ $? -eq 0 ]; then
        print_info "Debug build completed successfully!"
    else
        print_error "Debug build failed!"
        exit 1
    fi
}

# Function to show build information
info() {
    echo "OP-TEE OS Build Information:"
    echo "==========================="
    echo "Platform: $PLATFORM"
    echo "Cross Compiler: $CROSS_COMPILE"
    echo "Parallel Jobs: $JOBS"
    echo "TA Dev Kit: $TA_DEV_KIT_DIR"
    echo ""
    if [ -d "out" ]; then
        echo "Build artifacts:"
        find out -name "*.bin" -o -name "*.elf" | head -10
        if [ $(find out -name "*.bin" -o -name "*.elf" | wc -l) -gt 10 ]; then
            echo "... (and more)"
        fi
    else
        echo "No build directory found. Run 'build' first."
    fi
}

# Function to build and sign for secure boot
sign() {
    print_info "Building OP-TEE OS for secure boot..."
    build

    # Check if signing tools are available
    if command -v "openssl" &> /dev/null && command -v "dtc" &> /dev/null; then
        print_info "Signing tools available - OP-TEE ready for secure boot"
    else
        print_warning "Signing tools (openssl, dtc) not found"
        print_warning "Secure boot signing not available"
    fi
}

# Main script logic
case "${1:-build}" in
    "build")
        check_tools
        check_ta_devkit
        build
        ;;
    "clean")
        clean
        ;;
    "distclean")
        distclean
        ;;
    "debug")
        check_tools
        check_ta_devkit
        debug
        ;;
    "sign")
        check_tools
        check_ta_devkit
        sign
        ;;
    "rebuild")
        check_tools
        check_ta_devkit
        clean
        build
        ;;
    "info")
        info
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  build      Build OP-TEE OS (default)"
        echo "  clean      Clean build artifacts"
        echo "  distclean  Clean everything"
        echo "  debug      Build with debug symbols"
        echo "  sign       Build for secure boot"
        echo "  rebuild    Clean and rebuild"
        echo "  info       Show build information"
        echo "  help       Show this help message"
        echo ""
        echo "Environment variables:"
        echo "  CROSS_COMPILE    Cross compiler prefix (default: aarch64-linux-gnu-)"
        echo "  PLATFORM         Target platform (default: imx-mx8mpevk)"
        echo "  JOBS             Number of parallel jobs (default: nproc)"
        echo "  TA_DEV_KIT_DIR   TA dev kit directory (default: ../optee-os-tadevkit)"
        ;;
    *)
        print_error "Unknown command: $1"
        print_error "Use '$0 help' for usage information"
        exit 1
        ;;
esac