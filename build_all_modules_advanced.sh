#!/bin/bash
set -e

export ARCH=arm64
export SUBARCH=arm64
export ANDROID_MAJOR_VERSION=t
export CLANG_OTH=/build/toolchains/clang-r383902/bin
export GCC_OTH=/build/toolchains/gcc-4.9/bin
export PATH="${CLANG_OTH}:${GCC_OTH}:${PATH}"
export CC="${CLANG_OTH}/clang"
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE="${GCC_OTH}/aarch64-linux-android-"
export KCFLAGS="-w"

KERNEL_DIR="$(pwd)"
OUT_DIR=/build/kernel_out
PLATFORM_BASE=/build/platform
PLATFORM_MODS=/build/platform/vendor/mediatek/kernel_modules
MODULE_DEST=/build/output_advanced/modules_compiled

mkdir -p "${MODULE_DEST}"

echo "=== 1. Building wmt_drv ==="
make -C "${KERNEL_DIR}" O="${OUT_DIR}" M="${PLATFORM_MODS}/connectivity/common" KERNEL_OUT="${OUT_DIR}" TOP="${PLATFORM_BASE}" modules -j8
WMT_SYM="$(find ${PLATFORM_MODS}/connectivity/common -name Module.symvers)"
WMT_KO="$(find ${PLATFORM_MODS}/connectivity/common -name wmt_drv.ko)"
cp "${WMT_KO}" "${MODULE_DEST}/"
echo "wmt_drv.ko built OK -> ${WMT_KO}"

echo "=== 2. Building connfem ==="
make -C "${KERNEL_DIR}" O="${OUT_DIR}" M="${PLATFORM_MODS}/connectivity/connfem" KERNEL_OUT="${OUT_DIR}" TOP="${PLATFORM_BASE}" modules -j8
CONNFEM_SYM="$(find ${PLATFORM_MODS}/connectivity/connfem -name Module.symvers)"
CONNFEM_KO="$(find ${PLATFORM_MODS}/connectivity/connfem -name connfem.ko)"
cp "${CONNFEM_KO}" "${MODULE_DEST}/"
echo "connfem.ko built OK -> ${CONNFEM_KO}"

echo "=== 3. Building wmt_chrdev_wifi ==="
make -C "${KERNEL_DIR}" O="${OUT_DIR}" M="${PLATFORM_MODS}/connectivity/wlan/adaptor" MODULE_NAME=wmt_chrdev_wifi KERNEL_OUT="${OUT_DIR}" TOP="${PLATFORM_BASE}" KBUILD_EXTRA_SYMBOLS="${WMT_SYM}" modules -j8
CHRDEV_SYM="$(find ${PLATFORM_MODS}/connectivity/wlan/adaptor -name Module.symvers)"
CHRDEV_KO="$(find ${PLATFORM_MODS}/connectivity/wlan/adaptor -name wmt_chrdev_wifi.ko)"
cp "${CHRDEV_KO}" "${MODULE_DEST}/"
echo "wmt_chrdev_wifi.ko built OK -> ${CHRDEV_KO}"

echo "=== 4. Building wlan_drv_gen4m ==="
make -C "${KERNEL_DIR}" O="${OUT_DIR}" M="${PLATFORM_MODS}/connectivity/wlan/core/gen4m" \
  MODULE_NAME=wlan_drv_gen4m CONFIG_MTK_COMBO_WIFI_HIF=axi MTK_COMBO_CHIP=SOC2_2X2 WLAN_CHIP_ID=6853 \
  MTK_ANDROID_WMT=y WIFI_IP_SET=3 MTK_ANDROID_EMI=y MTK_WLAN_SERVICE=yes MTK_WLAN_SERVICE_PATH=wlan_service/ \
  KERNEL_OUT="${OUT_DIR}" TOP="${PLATFORM_BASE}" KBUILD_EXTRA_SYMBOLS="${WMT_SYM} ${CONNFEM_SYM} ${CHRDEV_SYM}" modules -j8
WLAN_SYM="$(find ${PLATFORM_MODS}/connectivity/wlan/core/gen4m -name Module.symvers)"
WLAN_KO="$(find ${PLATFORM_MODS}/connectivity/wlan/core/gen4m -name wlan_drv_gen4m.ko)"
cp "${WLAN_KO}" "${MODULE_DEST}/"
echo "wlan_drv_gen4m.ko built OK -> ${WLAN_KO}"

echo "=== 5. Building bt_drv_connac1x ==="
make -C "${KERNEL_DIR}" O="${OUT_DIR}" M="${PLATFORM_MODS}/connectivity/bt/mt66xx/wmt" MODULE_NAME=bt_drv_connac1x BT_PLATFORM=connac1x KERNEL_OUT="${OUT_DIR}" TOP="${PLATFORM_BASE}" KBUILD_EXTRA_SYMBOLS="${WMT_SYM}" modules -j8
BT_KO="$(find ${PLATFORM_MODS}/connectivity/bt/mt66xx/wmt -name bt_drv_connac1x.ko)"
cp "${BT_KO}" "${MODULE_DEST}/"
echo "bt_drv_connac1x.ko built OK -> ${BT_KO}"

echo "=== 6. Building gps_drv ==="
make -C "${KERNEL_DIR}" O="${OUT_DIR}" M="${PLATFORM_MODS}/connectivity/gps" MODULE_NAME=gps_drv KERNEL_OUT="${OUT_DIR}" TOP="${PLATFORM_BASE}" KBUILD_EXTRA_SYMBOLS="${WMT_SYM}" modules -j8
GPS_KO="$(find ${PLATFORM_MODS}/connectivity/gps -name gps_drv.ko)"
cp "${GPS_KO}" "${MODULE_DEST}/"
echo "gps_drv.ko built OK -> ${GPS_KO}"

echo "=== 7. Building fmradio_drv_mt6631_6635 ==="
make -C "${KERNEL_DIR}" O="${OUT_DIR}" M="${PLATFORM_MODS}/connectivity/fmradio" MODULE_NAME=fmradio_drv_mt6631_6635 KERNEL_OUT="${OUT_DIR}" TOP="${PLATFORM_BASE}" KBUILD_EXTRA_SYMBOLS="${WMT_SYM}" modules -j8
FM_KO="$(find ${PLATFORM_MODS}/connectivity/fmradio -name 'fmradio*.ko')"
cp "${FM_KO}" "${MODULE_DEST}/"
echo "fmradio built OK -> ${FM_KO}"

echo "=== 8. Building met ==="
make -C "${KERNEL_DIR}" O="${OUT_DIR}" M="${PLATFORM_MODS}/met_drv/4.14" KERNEL_OUT="${OUT_DIR}" TOP="${PLATFORM_BASE}" modules -j8
MET_KO="$(find ${PLATFORM_MODS}/met_drv/4.14 -name met.ko)"
cp "${MET_KO}" "${MODULE_DEST}/"
echo "met.ko built OK -> ${MET_KO}"

echo "=== ALL 8 MODULES BUILT SUCCESSFULLY ==="
ls -lh "${MODULE_DEST}"
