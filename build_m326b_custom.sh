#!/bin/bash
set -e

# ==============================================================================
# Samsung Galaxy M32 5G (SM-M326B) Custom Kernel & DLKM Modules Build Script
# Architecture: ARM64 (MediaTek MT6853 Dimensity 720)
# Target: Android 13 / One UI 5.1 (Build M326BDDSCCYD1)
# Features: CONFIG_IPC_NS=y, CONFIG_SYSVIPC=y, CONFIG_POSIX_MQUEUE=y
# ==============================================================================

export ARCH=arm64
export SUBARCH=arm64
export ANDROID_MAJOR_VERSION=r

# Toolchain setup
TOOLCHAIN_DIR=/root/toolchain/android11-release/bin
export PATH="${TOOLCHAIN_DIR}:${PATH}"
export CROSS_COMPILE=aarch64-linux-android-
export CROSS_COMPILE_ARM32=arm-linux-androideabi-
export CC=clang
export CLANG_TRIPLE=aarch64-linux-gnu-

KERNEL_SRC=/root/fresh_kernel_m326b
KERNEL_OUT=${KERNEL_SRC}/out
MODULES_SRC=/root/mtk_modules
OUTPUT_DIR=/root/build_output

mkdir -p "${KERNEL_OUT}" "${OUTPUT_DIR}"

echo "=== [1/4] Configuring Kernel with IPC Namespaces ==="
cd "${KERNEL_SRC}"
make -C $(pwd) O="${KERNEL_OUT}" KCFLAGS=-w CONFIG_SECTION_MISMATCH_WARN_ONLY=y a32x_defconfig

# Inject IPC Namespace configs and matching localversion
sed -i 's/# CONFIG_SYSVIPC is not set/CONFIG_SYSVIPC=y/' "${KERNEL_OUT}/.config"
sed -i 's/# CONFIG_POSIX_MQUEUE is not set/CONFIG_POSIX_MQUEUE=y/' "${KERNEL_OUT}/.config"
sed -i 's/# CONFIG_IPC_NS is not set/CONFIG_IPC_NS=y/' "${KERNEL_OUT}/.config"
grep -q "CONFIG_LOCALVERSION=" "${KERNEL_OUT}/.config" && \
  sed -i 's/CONFIG_LOCALVERSION=".*"/CONFIG_LOCALVERSION="-27095505"/' "${KERNEL_OUT}/.config" || \
  echo 'CONFIG_LOCALVERSION="-27095505"' >> "${KERNEL_OUT}/.config"

echo "=== [2/4] Building Kernel (Image.gz and Module.symvers) ==="
make -C $(pwd) O="${KERNEL_OUT}" KCFLAGS=-w CONFIG_SECTION_MISMATCH_WARN_ONLY=y -j$(nproc) Image.gz modules

cp "${KERNEL_OUT}/arch/arm64/boot/Image.gz" "${OUTPUT_DIR}/Image.gz"
echo "Kernel compiled successfully: ${OUTPUT_DIR}/Image.gz"

echo "=== [3/4] Building Out-Of-Tree DLKM Vendor Modules ==="
export KDIR="${KERNEL_OUT}"
export TOP=/root/android_top

# 1. connfem.ko
echo "--> Compiling connfem.ko..."
make -C "${KDIR}" M="${MODULES_SRC}/connectivity/connfem" modules KCFLAGS=-w -j$(nproc)
cp "${MODULES_SRC}/connectivity/connfem/connfem.ko" "${OUTPUT_DIR}/"

# 2. wmt_drv.ko
echo "--> Compiling wmt_drv.ko..."
make -C "${KDIR}" M="${MODULES_SRC}/connectivity/common" modules KCFLAGS=-w -j$(nproc)
cp "${MODULES_SRC}/connectivity/common/wmt_drv.ko" "${OUTPUT_DIR}/"

# 3. wmt_chrdev_wifi.ko
echo "--> Compiling wmt_chrdev_wifi.ko..."
make -C "${KDIR}" M="${MODULES_SRC}/connectivity/wlan/adaptor" modules KCFLAGS=-w -j$(nproc)
cp "${MODULES_SRC}/connectivity/wlan/adaptor/wmt_chrdev_wifi.ko" "${OUTPUT_DIR}/"

# 4. wlan_drv_gen4m.ko
echo "--> Compiling wlan_drv_gen4m.ko..."
make -C "${KDIR}" M="${MODULES_SRC}/connectivity/wlan/core/gen4m" modules KCFLAGS=-w -j$(nproc) \
  MODULE_NAME=wlan_drv_gen4m CONFIG_MTK_COMBO_WIFI_HIF=axi MTK_COMBO_CHIP=SOC2_2X2 WLAN_CHIP_ID=6853 \
  MTK_ANDROID_WMT=y WIFI_IP_SET=3 MTK_ANDROID_EMI=y MTK_WLAN_SERVICE=yes MTK_WLAN_SERVICE_PATH=wlan_service/ TOP="${TOP}"
cp "${MODULES_SRC}/connectivity/wlan/core/gen4m/wlan_drv_gen4m.ko" "${OUTPUT_DIR}/"

# 5. bt_drv_connac1x.ko
echo "--> Compiling bt_drv_connac1x.ko..."
make -C "${KDIR}" M="${MODULES_SRC}/connectivity/bt/mt66xx/wmt" modules KCFLAGS=-w -j$(nproc)
cp "${MODULES_SRC}/connectivity/bt/mt66xx/wmt/bt_drv_connac1x.ko" "${OUTPUT_DIR}/"

# 6. gps_drv.ko
echo "--> Compiling gps_drv.ko..."
make -C "${KDIR}" M="${MODULES_SRC}/connectivity/gps" modules KCFLAGS=-w -j$(nproc)
cp "${MODULES_SRC}/connectivity/gps/gps_drv.ko" "${OUTPUT_DIR}/"

# 7. fmradio_drv_mt6631_6635.ko
echo "--> Compiling fmradio_drv_mt6631_6635.ko..."
make -C "${KDIR}" M="${MODULES_SRC}/connectivity/fmradio" modules KCFLAGS=-w -j$(nproc)
cp "${MODULES_SRC}/connectivity/fmradio/fmradio_drv_mt6631_6635.ko" "${OUTPUT_DIR}/"

# 8. met.ko
echo "--> Compiling met.ko..."
make -C "${KDIR}" M="${MODULES_SRC}/met_drv/4.14/mt6853" modules KCFLAGS=-w -j$(nproc)
cp "${MODULES_SRC}/met_drv/4.14/mt6853/met.ko" "${OUTPUT_DIR}/"

echo "=== [4/4] Build Complete! ==="
ls -lh "${OUTPUT_DIR}"
