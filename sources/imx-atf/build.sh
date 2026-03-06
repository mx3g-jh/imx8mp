#!/bin/bash
#
# i.MX ATF (ARM Trusted Firmware) Build Script
#

set -e

# 工具链配置
export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

# 构建参数
PLAT="imx8mp"
BUILD_BASE="build-optee"
SPD="opteed"
DEBUG=0
IMX_BOOT_UART_BASE=0x30890000

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

# 清理旧构建
echo "Cleaning old build..."
make -j$(nproc) \
    CROSS_COMPILE=${CROSS_COMPILE} \
    PLAT=${PLAT} \
    LD=aarch64-linux-gnu-ld \
    CC=aarch64-linux-gnu-gcc \
    IMX_BOOT_UART_BASE=${IMX_BOOT_UART_BASE} \
    DEBUG=${DEBUG} \
    clean \
    BUILD_BASE=${BUILD_BASE} \
    > /dev/null 2>&1 || true

# 编译 ATF (BL31)
echo "Building ATF (BL31) for ${PLAT}..."
make -j$(nproc) \
    CROSS_COMPILE=${CROSS_COMPILE} \
    PLAT=${PLAT} \
    LD=aarch64-linux-gnu-ld \
    CC=aarch64-linux-gnu-gcc \
    IMX_BOOT_UART_BASE=${IMX_BOOT_UART_BASE} \
    DEBUG=${DEBUG} \
    BUILD_BASE=${BUILD_BASE} \
    SPD=${SPD} \
    bl31

# 检查输出 (i.MX ATF 输出路径)
BUILD_DIR="${BUILD_BASE}/${PLAT}/release"
if [ -f "${BUILD_DIR}/bl31.bin" ]; then
    echo "ATF build completed: ${BUILD_DIR}/bl31.bin"
else
    echo "ERROR: ATF build failed, output not found at ${BUILD_DIR}/bl31.bin"
    exit 1
fi
