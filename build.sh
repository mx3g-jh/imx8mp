#!/bin/bash
#
# i.MX8MP FRDM Manual Build Script
# 自动构建 i.MX8MP FRDM 启动镜像
#

set -e

# ============================================
# 配置
# ============================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}"
SOURCES_DIR="${BUILD_DIR}/sources"
OUTPUT_DIR="${BUILD_DIR}/output"
FIRMWARE_DIR="${BUILD_DIR}/firmware/firmware-imx-8.25-27879f8"

# 交叉编译工具链
export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64
export PATH="${BUILD_DIR}/toolchain/gcc-aarch64-linux-gnu/bin:$PATH"

# 目标板
BOARD="imx8mp"
BOARD_NAME="frdm"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_env() {
    log_info "检查构建环境..."

    # 检查交叉编译工具
    if ! command -v ${CROSS_COMPILE}gcc &> /dev/null; then
        log_error "未找到交叉编译工具链: ${CROSS_COMPILE}gcc"
        log_error "请安装: sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu"
        exit 1
    fi

    # 检查源码目录
    if [ ! -d "${SOURCES_DIR}" ]; then
        log_error "源码目录不存在: ${SOURCES_DIR}"
        exit 1
    fi

    # 检查固件目录
    if [ ! -d "${FIRMWARE_DIR}" ]; then
        log_error "固件目录不存在: ${FIRMWARE_DIR}"
        exit 1
    fi

    log_info "环境检查通过"
}

create_output_dir() {
    log_info "创建输出目录: ${OUTPUT_DIR}"
    mkdir -p "${OUTPUT_DIR}"
}

# ============================================
# Step 1: 编译 ATF
# ============================================
build_atf() {
    log_info "========================================"
    log_info "Step 1: 编译 ATF (BL31)"
    log_info "========================================"

    local atf_dir="${SOURCES_DIR}/imx-atf"
    local build_script="${atf_dir}/build.sh"
    # ATF 编译输出在 build-optee/imx8mp/release/bl31.bin
    local build_dir="${atf_dir}/build-optee/${BOARD}/release"

    if [ -f "${build_dir}/bl31.bin" ]; then
        log_info "ATF 已编译，跳过"
        cp "${build_dir}/bl31.bin" "${OUTPUT_DIR}/"
        return 0
    fi

    # 检查构建脚本是否存在
    if [ -f "${build_script}" ]; then
        log_info "使用构建脚本: ${build_script}"
        cd "${atf_dir}"
        bash "${build_script}" 2>&1 | tee "${OUTPUT_DIR}/atf_build.log"
    else
        log_error "构建脚本不存在: ${build_script}"
        exit 1
    fi

    if [ -f "${build_dir}/bl31.bin" ]; then
        cp "${build_dir}/bl31.bin" "${OUTPUT_DIR}/"
        log_info "ATF 编译完成: ${OUTPUT_DIR}/bl31.bin"
    else
        log_error "ATF 编译失败"
        exit 1
    fi
}

# ============================================
# Step 2: 编译 OP-TEE
# ============================================
build_optee() {
    log_info "========================================"
    log_info "Step 2: 编译 OP-TEE (BL32)"
    log_info "========================================"

    local optee_dir="${SOURCES_DIR}/optee/imx-optee-os"
    local build_script="${optee_dir}/build.sh"
    # OP-TEE 输出在 out/arm-plat-imx/core/tee.bin
    local out_dir="${optee_dir}/out/arm-plat-imx/core"

    if [ -f "${out_dir}/tee.bin" ]; then
        log_info "OP-TEE 已编译，跳过"
        cp "${out_dir}/tee.bin" "${OUTPUT_DIR}/"
        return 0
    fi

    # 检查构建脚本是否存在
    if [ -f "${build_script}" ]; then
        log_info "使用构建脚本: ${build_script}"
        cd "${optee_dir}"
        bash "${build_script}" 2>&1 | tee "${OUTPUT_DIR}/optee_build.log"
    else
        log_error "构建脚本不存在: ${build_script}"
        exit 1
    fi

    if [ -f "${out_dir}/tee.bin" ]; then
        cp "${out_dir}/tee.bin" "${OUTPUT_DIR}/"
        log_info "OP-TEE 编译完成: ${OUTPUT_DIR}/tee.bin"
    else
        log_error "OP-TEE 编译失败"
        exit 1
    fi
}

# ============================================
# Step 3: 编译 U-Boot
# ============================================
build_uboot() {
    log_info "========================================"
    log_info "Step 3: 编译 U-Boot"
    log_info "========================================"

    local uboot_dir="${SOURCES_DIR}/uboot-imx"
    local build_script="${uboot_dir}/build.sh"
    # U-Boot 输出在 build/imx8mp_frdm_defconfig/
    local build_dir="${uboot_dir}/build/imx8mp_frdm_defconfig"

    if [ -f "${build_dir}/u-boot.bin" ]; then
        log_info "U-Boot 已编译，跳过"
        cp "${build_dir}/u-boot.bin" "${OUTPUT_DIR}/"
        [ -f "${build_dir}/SPL" ] && cp "${build_dir}/SPL" "${OUTPUT_DIR}/u-boot-spl.bin"
        return 0
    fi

    # 检查构建脚本是否存在
    if [ -f "${build_script}" ]; then
        log_info "使用构建脚本: ${build_script}"
        cd "${uboot_dir}"
        bash "${build_script}" 2>&1 | tee "${OUTPUT_DIR}/uboot_build.log"
    else
        log_error "构建脚本不存在: ${build_script}"
        exit 1
    fi

    if [ -f "${build_dir}/u-boot.bin" ]; then
        cp "${build_dir}/u-boot.bin" "${OUTPUT_DIR}/"
        [ -f "${build_dir}/SPL" ] && cp "${build_dir}/SPL" "${OUTPUT_DIR}/u-boot-spl.bin"
        log_info "U-Boot 编译完成"
    else
        log_error "U-Boot 编译失败"
        exit 1
    fi
}

# ============================================
# Step 4: 编译 Linux 内核
# ============================================
copy_kernel() {
    log_info "========================================"
    log_info "复制 Linux 内核"
    log_info "========================================"

    local kernel_dir="${SOURCES_DIR}/linux-imx"

    # 从源码目录复制
    if [ -f "${kernel_dir}/arch/arm64/boot/Image" ]; then
        cp "${kernel_dir}/arch/arm64/boot/Image" "${OUTPUT_DIR}/"
        cp "${kernel_dir}/arch/arm64/boot/dts/freescale/imx8mp-frdm"*.dtb "${OUTPUT_DIR}/"
        log_info "内核已从源码目录复制"
        return 0
    fi

    # 从 output 目录跳过
    if [ -f "${OUTPUT_DIR}/Image" ]; then
        log_info "内核已在 output 目录，跳过"
        return 0
    fi

    log_error "未找到内核镜像"
    return 1
}

# ============================================
build_kernel() {
    log_info "========================================"
    log_info "Step 4: 编译 Linux 内核"
    log_info "========================================"

    local kernel_dir="${SOURCES_DIR}/linux-imx"
    local build_script="${kernel_dir}/build.sh"

    # 检查是否已编译
    if [ -f "${kernel_dir}/arch/arm64/boot/Image" ] || [ -f "${OUTPUT_DIR}/Image" ]; then
        log_info "内核已编译，跳过"
        return 0
    fi

    # 检查构建脚本是否存在
    if [ -f "${build_script}" ]; then
        log_info "使用构建脚本: ${build_script}"
        cd "${kernel_dir}"
        bash "${build_script}" 2>&1 | tee "${OUTPUT_DIR}/kernel_build.log"
    else
        log_error "构建脚本不存在: ${build_script}"
        exit 1
    fi

    log_info "内核编译完成"
}

# ============================================
# Step 5: 复制固件
# ============================================
copy_firmware() {
    log_info "========================================"
    log_info "Step 5: 复制固件"
    log_info "========================================"

    local ddr_dir="${FIRMWARE_DIR}/firmware/ddr/synopsys"
    local hdmi_dir="${FIRMWARE_DIR}/firmware/hdmi/cadence"

    # DDR 固件 (LPDDR4 202006)
    log_info "复制 DDR 固件..."
    cp "${ddr_dir}/lpddr4_pmu_train_1d_dmem_202006.bin" "${OUTPUT_DIR}/"
    cp "${ddr_dir}/lpddr4_pmu_train_1d_imem_202006.bin" "${OUTPUT_DIR}/"
    cp "${ddr_dir}/lpddr4_pmu_train_2d_dmem_202006.bin" "${OUTPUT_DIR}/"
    cp "${ddr_dir}/lpddr4_pmu_train_2d_imem_202006.bin" "${OUTPUT_DIR}/"

    # HDMI 固件
    log_info "复制 HDMI 固件..."
    cp "${hdmi_dir}/signed_hdmi_imx8m.bin" "${OUTPUT_DIR}/"
    cp "${hdmi_dir}/signed_dp_imx8m.bin" "${OUTPUT_DIR}/"

    log_info "固件复制完成"
}

# ============================================
# Step 6: 打包合成 flash.bin
# ============================================
build_flash() {
    log_info "========================================"
    log_info "Step 6: 打包合成 flash.bin"
    log_info "========================================"

    local mkimage_dir="${SOURCES_DIR}/imx-mkimage"
    local staging_dir="${mkimage_dir}/iMX8M"

    # 编译 mkimage 工具
    cd "${mkimage_dir}"
    log_info "编译 mkimage..."
    make clean > /dev/null 2>&1 || true
    make -j$(nproc) \
        SOC=iMX8MP \
        CROSS_COMPILE=${CROSS_COMPILE} \
        2>&1 | tee "${OUTPUT_DIR}/mkimage_build.log"

    # 复制所有组件到 staging 目录
    log_info "复制组件到 staging 目录..."

    # DDR 固件
    cp "${OUTPUT_DIR}"/*pmu_train*.bin "${staging_dir}/"

    # HDMI 固件
    cp "${OUTPUT_DIR}"/signed_*imx8m.bin "${staging_dir}/"

    # U-Boot
    cp "${OUTPUT_DIR}/u-boot-spl.bin" "${staging_dir}/"
    cp "${OUTPUT_DIR}/u-boot.bin" "${staging_dir}/u-boot-nodtb.bin"

    # ATF
    cp "${OUTPUT_DIR}/bl31.bin" "${staging_dir}/"

    # OP-TEE
    if [ -f "${OUTPUT_DIR}/tee.bin" ]; then
        cp "${OUTPUT_DIR}/tee.bin" "${staging_dir}/"
    fi

    # 设备树
    cp "${OUTPUT_DIR}"/*.dtb "${staging_dir}/"

    # 打包
    cd "${staging_dir}"
    log_info "打包 flash.bin..."
    make SOC=iMX8M flash 2>&1 | tee "${OUTPUT_DIR}/flash_mkimage.log"

    if [ -f "${staging_dir}/flash.bin" ]; then
        cp "${staging_dir}/flash.bin" "${OUTPUT_DIR}/"
        log_info "flash.bin 构建完成: ${OUTPUT_DIR}/flash.bin"
    else
        log_error "flash.bin 构建失败"
        exit 1
    fi
}

# ============================================
# 显示结果
# ============================================
show_result() {
    log_info "========================================"
    log_info "构建完成!"
    log_info "========================================"

    echo ""
    log_info "输出文件:"
    ls -lh "${OUTPUT_DIR}"

    echo ""
    log_info "烧录命令:"
    echo "  SD卡: sudo dd if=${OUTPUT_DIR}/flash.bin of=/dev/sdX bs=1M status=progress conv=fsync"
    echo "  eMMC: uuu ${OUTPUT_DIR}/flash.bin"
}

# ============================================
# 主函数
# ============================================
main() {
    log_info "i.MX8MP FRDM 手动构建"
    log_info "构建目录: ${BUILD_DIR}"
    log_info "输出目录: ${OUTPUT_DIR}"

    # 检查环境
    check_env

    # 创建输出目录
    create_output_dir

    # 构建各组件
    build_atf
    build_optee
    build_uboot
    build_kernel
    copy_firmware
    build_flash

    # 显示结果
    show_result
}

# 解析参数
case "${1}" in
    atf)
        build_atf
        ;;
    optee)
        build_optee
        ;;
    uboot)
        build_uboot
        ;;
    kernel)
        build_kernel
        ;;
    firmware)
        copy_firmware
        ;;
    flash)
        build_flash
        ;;
    clean)
        rm -rf "${OUTPUT_DIR}"/*
        log_info "清理完成"
        ;;
    copy)
        copy_kernel
        log_info "复制完成"
        ;;
    all|*)
        main
        ;;
esac
