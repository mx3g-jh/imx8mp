# i.MX8MP FRDM 手动构建目录

本目录用于手动构建 i.MX8MP FRDM 开发板的启动镜像，替代 Yocto 构建。

---

## 目录结构

```
manual-build/
├── firmware/                      # 固件目录
│   ├── firmware-imx-8.25-27879f8.bin    # NXP i.MX 8.25 固件安装包
│   ├── firmware-imx-8.25-27879f8/       # 解压后的固件目录
│   │   └── firmware/
│   │       ├── ddr/synopsys/   # DDR 内存训练固件
│   │       ├── hdmi/cadence/   # HDMI 固件
│   │       ├── sdma/           # SDMA 固件
│   │       └── xuvi/           # VPU 固件
│   └── linux-firmware-20240312.tar.xz   # Linux 通用无线固件 (WiFi/BT)
│
├── sources/                      # 源码目录
│   ├── linux-imx/               # NXP Linux 内核 (分支: lf-6.6.y)
│   ├── uboot-imx/              # NXP U-Boot (分支: lf_v2024.04)
│   ├── imx-atf/                # ARM Trusted Firmware (ATF)
│   ├── imx-mkimage/            # i.MX 镜像生成工具
│   └── optee/                  # OP-TEE 安全框架
│       ├── imx-optee-os/       # OP-TEE OS (分支: lf-6.6.36_2.1.0)
│       ├── imx-optee-client/    # OP-TEE 客户端库
│       └── imx-optee-test/     # OP-TEE 测试工具
│
└── output/                      # 构建输出目录
    └── (最终生成的镜像文件)
```

---

## 固件说明

### DDR 固件 (i.MX8MP LPDDR4)

FRDM-iMX8MP 使用 **LPDDR4** 内存，版本 `202006`：

| 文件名 | 用途 |
|--------|------|
| `lpddr4_pmu_train_1d_dmem_202006.bin` | 1D 训练数据内存 |
| `lpddr4_pmu_train_1d_imem_202006.bin` | 1D 训练指令内存 |
| `lpddr4_pmu_train_2d_dmem_202006.bin` | 2D 训练数据内存 |
| `lpddr4_pmu_train_2d_imem_202006.bin` | 2D 训练指令内存 |

位置: `firmware/firmware-imx-8.25-27879f8/firmware/ddr/synopsys/`

### HDMI 固件 (i.MX8MP)

| 文件名 | 用途 |
|--------|------|
| `hdmitxfw.bin` | HDMI TX 固件 |
| `hdmirxfw.bin` | HDMI RX 固件 |
| `dpfw.bin` | DisplayPort 固件 |
| `signed_hdmi_imx8m.bin` | HDMI 签名固件 (i.MX8M) |
| `signed_dp_imx8m.bin` | DP 签名固件 (i.MX8M) |

### 其他固件

- **SDMA**: `firmware/sdma/` - Smart DMA 固件
- **VPU**: `firmware/xuvi/` - Video Processing Unit 固件

---

## 源码版本

| 组件 | 仓库 | 分支 | 备注 |
|------|------|------|------|
| Linux Kernel | `github.com/nxp-imx/linux-imx` | `lf-6.6.y` | 对应 Linux 6.6.36 |
| U-Boot | `github.com/nxp-imx/uboot-imx` | `lf_v2024.04` | |
| ATF | `github.com/nxp-imx/imx-atf` | `lf_v2.10` | |
| mkimage | `github.com/nxp-imx/imx-mkimage` | `lf-6.6.36_2.1.0` | |
| OP-TEE OS | `github.com/nxp-imx/imx-optee-os` | `lf-6.6.36_2.1.0` | |
| OP-TEE Client | `github.com/nxp-imx/imx-optee-client` | `lf-6.6.36_2.1.0` | |
| OP-TEE Test | `github.com/nxp-imx/imx-optee-test` | `lf-6.6.36_2.1.0` | 可选 |

---

## 构建流程概述

1. **Linux 内核**: 配置并编译 `arch/arm64/boot/Image` 和设备树
2. **U-Boot**: 编译生成 `u-boot.bin` 和 `u-boot-spl.bin`
3. **ATF (BL31)**: 编译生成 `bl31.bin`
4. **OP-TEE (BL32)**: 编译生成 `tee.bin`
5. **DDR 固件**: 从 firmware-imx 包中复制
6. **HDMI 固件**: 从 firmware-imx 包中复制
7. **mkimage**: 打包合成最终启动镜像

---

## 源码获取 (参考)

如需重新克隆源码:

```bash
# Linux Kernel (NXP)
git clone https://github.com/nxp-imx/linux-imx.git -b lf-6.6.y --depth 1

# U-Boot
git clone https://github.com/nxp-imx/uboot-imx.git -b lf_v2024.04 --depth 1

# ATF
git clone https://github.com/nxp-imx/imx-atf.git -b lf_v2.10 --depth 1

# mkimage
git clone https://github.com/nxp-imx/imx-mkimage.git -b lf-6.6.36_2.1.0 --depth 1

# OP-TEE
git clone https://github.com/nxp-imx/imx-optee-os.git -b lf-6.6.36_2.1.0 --depth 1
git clone https://github.com/nxp-imx/imx-optee-client.git -b lf-6.6.36_2.1.0 --depth 1
```

---

## 输出文件

构建完成后，`output/` 目录将包含:

| 文件 | 描述 |
|------|------|
| `flash.bin` | 完整启动镜像 (SD卡/eMMC烧录) |
| `bl31.bin` | ATF BL31 镜像 |
| `tee.bin` | OP-TEE 镜像 |
| `u-boot.bin` | U-Boot 镜像 |
| `u-boot-spl.bin` | U-Boot SPL |
| `Image` | Linux 内核镜像 |
| `*.dtb` | 设备树 Blob |

---

## 相关文档

- [NXP i.MX Linux Release Notes](https://www.nxp.com/docs/en/release-note/IMX_LINUX_RELEASE_NOTES.pdf)
- [i.MX 8M Plus Reference Manual](https://www.nxp.com/docs/en/reference-manual/IMX8MPRM.pdf)
- [FRDM-iMX8MP 官方页面](https://www.nxp.com/design/development-boards/freedom-development-platforms/mcuxpresso-development-platforms/evaluation-and-development-platforms/i-mx-8m-plus-evaluation-kit:IMX8MPLUS-EVK)
