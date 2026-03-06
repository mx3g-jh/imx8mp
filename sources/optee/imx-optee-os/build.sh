#!/bin/bash
#
# i.MX OP-TEE Build Script
#

set -e

# 工具链配置
export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

# 构建参数
PLATFORM="imx-mx8mpevk"
OUT_DIR="out"

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

# 清理旧构建 (可选)
if [ "$1" = "clean" ]; then
    echo "Cleaning OP-TEE build..."
    make clean O=${OUT_DIR}
    rm -rf ${OUT_DIR}
    exit 0
fi

# 编译 OP-TEE
echo "Building OP-TEE for ${PLATFORM}..."
make -j$(nproc) \
    PLATFORM=${PLATFORM} \
    ARCH=${ARCH} \
    CROSS_COMPILE64=${CROSS_COMPILE} \
    O=${OUT_DIR}

# 检查输出
if [ -f "${OUT_DIR}/core/tee.bin" ]; then
    echo "OP-TEE build completed: ${OUT_DIR}/core/tee.bin"
else
    echo "ERROR: OP-TEE build failed"
    exit 1
fi
