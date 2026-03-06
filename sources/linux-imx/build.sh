#!/bin/bash
#
# i.MX Linux Kernel Build Script
#

set -e

# 工具链配置
export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

# 构建参数
BOARD="imx8mp"
DEFCONFIG="imx_v8_defconfig"

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

# 清理旧构建 (可选)
if [ "$1" = "clean" ]; then
    echo "Cleaning kernel build..."
    make distclean
    exit 0
fi

# 清理旧的构建产物
rm -rf build

# 配置内核 - 使用 imx_v8_defconfig
echo "Configuring kernel with ${DEFCONFIG}..."
make ${DEFCONFIG}

# 编译内核 Image
echo "Building kernel Image..."
make -j$(nproc) Image

# 编译设备树
echo "Building device trees..."
make -j$(nproc) dtbs

# 检查输出
if [ -f "arch/arm64/boot/Image" ]; then
    echo "Kernel build completed: arch/arm64/boot/Image"
    ls -lh "arch/arm64/boot/Image"
else
    echo "ERROR: Kernel build failed"
    exit 1
fi
