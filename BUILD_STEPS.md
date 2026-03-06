# i.MX8MP FRDM 手动构建步骤

本文档详细说明手动构建 i.MX8MP FRDM 启动镜像的完整流程。

---

## 构建流程概览

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         i.MX8MP 启动镜像构建流程                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. 编译 ATF (BL31)                                                         │
│     └── sources/imx-atf ──────────────► bl31.bin                            │
│                                                                             │
│  2. 编译 OP-TEE (BL32)                                                      │
│     └── sources/optee/imx-optee-os ──► tee.bin                             │
│                                                                             │
│  3. 编译 U-Boot                                                             │
│     └── sources/uboot-imx ──────────► u-boot.bin + u-boot-spl.bin         │
│                                                                             │
│  4. 编译 Linux 内核                                                         │
│     └── sources/linux-imx ──────────► Image + *.dtb                        │
│                                                                             │
│  5. 准备固件                                                                │
│     ├── DDR 固件 (from firmware-imx)                                        │
│     ├── HDMI 固件 (from firmware-imx)                                       │
│     └── (可选) WiFi/BT 固件                                                 │
│                                                                             │
│  6. 打包合成镜像                                                            │
│     └── imx-mkimage ─────────────────► flash.bin (最终镜像)                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 各步骤详细说明

### Step 1: 编译 ATF (ARM Trusted Firmware)

**作用**: ATF 是 ARM 架构的可信固件，运行在 EL3 (Exception Level 3)，负责初始化安全世界和切换到 BL32 (OP-TEE)。

**源码位置**: `sources/imx-atf/`

**编译命令**:

```bash
cd sources/imx-atf

make CROSS_COMPILE=aarch64-linux-gnu- PLAT=imx8mp \
    IMX_ATF_PLAT=imx8mp \
    ARCH=aarch64 \
    1>&2 | tee build.log

# 输出文件
# build/imx8mp/release/bl31/bin/bl31.bin
```

**生成文件**:
| 文件 | 说明 |
|------|------|
| `bl31.bin` | ATF BL31 镜像，固定加载地址 `0x00910000` |

**Yocto 等价**: `imx-atf` recipe

---

### Step 2: 编译 OP-TEE OS

**作用**: OP-TEE 是基于 ARM TrustZone 的安全操作系统，运行在安全世界 (Secure World)，提供 TEE (Trusted Execution Environment)。

**源码位置**: `sources/optee/imx-optee-os/`

**编译命令**:

```bash
cd sources/optee/imx-optee-os

make CROSS_COMPILE=aarch64-linux-gnu- \
    TA_DEV_KIT_DIR=$(pwd)/../optee_client/out/export/usr \
    1>&2 | tee build.log

# 或者使用 build.py
python3 scripts/imx-optee-os/build.py --board imx8mp-frdm
```

**生成文件**:
| 文件 | 说明 |
|------|------|
| `out/core/tee.bin` | OP-TEE 镜像 |
| `out/core/tee-pager.bin` | OP-TEE 分页模式镜像 |

**Yocto 等价**: `optee-os` recipe

---

### Step 3: 编译 U-Boot

**作用**: U-Boot 是第一阶段 bootloader，负责初始化 DDR、加载内核、启动系统。

**源码位置**: `sources/uboot-imx/`

**编译命令**:

```bash
cd sources/uboot-imx

# 配置
make CROSS_COMPILE=aarch64-linux-gnu- \
    imx8mp_frdm_defconfig

# 编译
make CROSS_COMPILE=aarch64-linux-gnu- \
    CONFIG_NXP_ESDHC_ADDR=0x30b50000 \
    1>&2 | tee build.log
```

**生成文件**:
| 文件 | 说明 |
|------|------|
| `u-boot.bin` | U-Boot 主镜像 |
| `u-boot-spl.bin` | U-Boot SPL (Secondary Program Loader)，先于 U-Boot 运行 |
| `u-boot-nodtb.bin` | 不含设备树的 U-Boot |
| `*.dtb` | 设备树 Blob |

**Yocto 等价**: `u-boot-imx` recipe

---

### Step 4: 编译 Linux 内核

**作用**: Linux 系统内核。

**源码位置**: `sources/linux-imx/`

**编译命令**:

```bash
cd sources/linux-imx

# 配置
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- \
    imx8mp_frdm_defconfig

# 编译内核
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- \
    Image -j$(nproc)

# 编译设备树
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- \
    dtbs -j$(nproc)
```

**生成文件**:
| 文件 | 说明 |
|------|------|
| `arch/arm64/boot/Image` | Linux 内核镜像 |
| `arch/arm64/boot/dts/freescale/imx8mp-frdm*.dtb` | 设备树 |

**Yocto 等价**: `linux-imx` recipe

---

### Step 5: 准备固件

#### 5.1 DDR 固件

**作用**: DDR 内存初始化和训练固件，在 ATF/U-Boot 启动阶段加载到内存控制器。

**来源**: `firmware/firmware-imx-8.25-27879f8/firmware/ddr/synopsys/`

**所需文件** (i.MX8MP LPDDR4):

```bash
# 复制 DDR 固件到构建目录
cp firmware/firmware-imx-8.25-27879f8/firmware/ddr/synopsys/lpddr4_pmu_train_1d_dmem_202006.bin output/
cp firmware/firmware-imx-8.25-27879f8/firmware/ddr/synopsys/lpddr4_pmu_train_1d_imem_202006.bin output/
cp firmware/firmware-imx-8.25-27879f8/firmware/ddr/synopsys/lpddr4_pmu_train_2d_dmem_202006.bin output/
cp firmware/firmware-imx-8.25-27879f8/firmware/ddr/synopsys/lpddr4_pmu_train_2d_imem_202006.bin output/
```

**文件名说明**:
| 文件 | 说明 |
|------|------|
| `lpddr4_pmu_train_1d_dmem_202006.bin` | 1D 训练数据内存 |
| `lpddr4_pmu_train_1d_imem_202006.bin` | 1D 训练指令内存 |
| `lpddr4_pmu_train_2d_dmem_202006.bin` | 2D 训练数据内存 |
| `lpddr4_pmu_train_2d_imem_202006.bin` | 2D 训练指令内存 |

#### 5.2 HDMI 固件

**作用**: HDMI/DisplayPort 显示接口固件。

**来源**: `firmware/firmware-imx-8.25-27879f8/firmware/hdmi/cadence/`

```bash
cp firmware/firmware-imx-8.25-27879f8/firmware/hdmi/cadence/signed_hdmi_imx8m.bin output/
cp firmware/firmware-imx-8.25-27879f8/firmware/hdmi/cadence/signed_dp_imx8m.bin output/
```

---

### Step 6: 编译 mkimage 并打包合成

**作用**: `imx-mkimage` 是 NXP 的镜像打包工具，将所有组件合成一个可启动的 `flash.bin`。

**源码位置**: `sources/imx-mkimage/`

**编译**:

```bash
cd sources/imx-mkimage

make CROSS_COMPILE=aarch64-linux-gnu- SOC=iMX8MP clean
make CROSS_COMPILE=aarch64-linux-gnu- SOC=iMX8MP
```

**打包合成** (iMX8M 目录):

```bash
cd sources/imx-mkimage/iMX8M

# 复制所有组件
cp /path/to/output/lpddr4_pmu_train_1d_dmem_202006.bin ./
cp /path/to/output/lpddr4_pmu_train_1d_imem_202006.bin ./
cp /path/to/output/lpddr4_pmu_train_2d_dmem_202006.bin ./
cp /path/to/output/lpddr4_pmu_train_2d_imem_202006.bin ./
cp /path/to/output/signed_hdmi_imx8m.bin ./
cp /path/to/output/signed_dp_imx8m.bin ./
cp /path/to/output/u-boot-spl.bin ./
cp /path/to/output/u-boot-nodtb.bin ./
cp /path/to/output/u-boot.bin ./
cp /path/to/output/bl31.bin ./bl31.bin
cp /path/to/output/tee.bin ./
cp /path/to/output/*.dtb ./

# 打包
make SOC=iMX8MP flash_linux_m4
```

**生成文件**:
| 文件 | 说明 |
|------|------|
| `flash.bin` | 最终可启动镜像，可直接烧录到 SD/eMMC |

---

## 完整构建命令汇总

```bash
# ============================================
# 1. 编译 ATF
# ============================================
cd sources/imx-atf
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=imx8mp IMX_ATF_PLAT=imx8mp ARCH=aarch64
cp build/imx8mp/release/bl31/bin/bl31.bin ../../output/

# ============================================
# 2. 编译 OP-TEE
# ============================================
cd ../optee/imx-optee-os
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=imx8mp ARCH=arm64
cp out/core/tee.bin ../../../output/

# ============================================
# 3. 编译 U-Boot
# ============================================
cd ../../uboot-imx
make CROSS_COMPILE=aarch64-linux-gnu- imx8mp_frdm_defconfig
make CROSS_COMPILE=aarch64-linux-gnu-
cp u-boot.bin ../output/
cp u-boot-spl.bin ../output/
cp arch/arm/dts/imx8mp-frdm.dtb ../output/

# ============================================
# 4. 编译 Linux 内核
# ============================================
cd ../linux-imx
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- imx8mp_frdm_defconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image -j$(nproc)
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- dtbs
cp arch/arm64/boot/Image ../output/
cp arch/arm64/boot/dts/freescale/imx8mp-frdm*.dtb ../output/

# ============================================
# 5. 复制固件
# ============================================
DDR_DIR=../../firmware/firmware-imx-8.25-27879f8/firmware/ddr/synopsys
cp $DDR_DIR/lpddr4_pmu_train_1d_dmem_202006.bin ../../output/
cp $DDR_DIR/lpddr4_pmu_train_1d_imem_202006.bin ../../output/
cp $DDR_DIR/lpddr4_pmu_train_2d_dmem_202006.bin ../../output/
cp $DDR_DIR/lpddr4_pmu_train_2d_imem_202006.bin ../../output/

HDMI_DIR=../../firmware/firmware-imx-8.25-27879f8/firmware/hdmi/cadence
cp $HDMI_DIR/signed_hdmi_imx8m.bin ../../output/
cp $HDMI_DIR/signed_dp_imx8m.bin ../../output/

# ============================================
# 6. 打包合成 flash.bin
# ============================================
cd ../../imx-mkimage/iMX8M
# 复制所有文件到当前目录，然后执行 make
make SOC=iMX8MP flash_linux_m4
cp flash.bin ../../output/
```

---

## 输出文件说明

| 文件 | 来源 | 用途 |
|------|------|------|
| `flash.bin` | mkimage | **最终镜像**，烧录到 SD/eMMC |
| `bl31.bin` | ATF | ARM Trusted Firmware |
| `tee.bin` | OP-TEE | Trusted Execution Environment |
| `u-boot.bin` | U-Boot | Bootloader 主镜像 |
| `u-boot-spl.bin` | U-Boot | 初始加载程序 |
| `Image` | Linux Kernel | Linux 内核 |
| `imx8mp-frdm.dtb` | Linux Kernel | 设备树 |

---

## 烧录

```bash
# 烧录到 SD 卡
sudo dd if=output/flash.bin of=/dev/sdX bs=1M status=progress conv=fsync

# 烧录到 eMMC (通过 UUU 工具)
uuu output/flash.bin
```

---

## 验证构建 (与 Yocto 对比)

| 组件 | Yocto 输出 | 手动构建应生成 |
|------|------------|----------------|
| ATF | `bl31-imx8mp.bin` | `bl31.bin` |
| OP-TEE | (含在 bl31 中或单独 tee.bin) | `tee.bin` |
| U-Boot | `u-boot.bin` | `u-boot.bin`, `u-boot-spl.bin` |
| 内核 | `Image` | `Image` |
| 设备树 | `imx8mp-frdm.dtb` | `imx8mp-frdm.dtb` |
| 最终镜像 | `imx-boot` | `flash.bin` |
