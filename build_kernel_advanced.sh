#!/bin/bash
set -e

# ==============================================================================
# Advanced Kernel Compilation for Samsung Galaxy M32 5G (SM-M326B)
# Kernel: 4.14.186-27095505 (MT6853 Dimensity 720)
# Features:
#   - Google BBR TCP Congestion Control (CONFIG_TCP_CONG_BBR=y, default=bbr)
#   - FQ & FQ-CoDel Pacing / Bufferbloat Elimination (CONFIG_NET_SCH_FQ=y)
#   - MACVLAN & IPVLAN Multi-WAN / Virtual Ethernet (CONFIG_MACVLAN=y)
#   - BFQ I/O Scheduler & Default NOOP Flash Scheduler (CONFIG_IOSCHED_BFQ=y)
#   - Linux IPC Namespaces (CONFIG_IPC_NS=y, CONFIG_SYSVIPC=y, CONFIG_POSIX_MQUEUE=y)
#   - USB ConfigFS NCM/ECM/EEM Gadgets
#   - Exact Stock Localversion: -27095505
# ==============================================================================

export ARCH=arm64
export SUBARCH=arm64
export ANDROID_MAJOR_VERSION=t

export CLANG_PATH=/build/toolchains/clang-r383902/bin
export GCC_PATH=/build/toolchains/gcc-4.9/bin
export PATH="${CLANG_PATH}:${GCC_PATH}:${PATH}"

export CC=${CLANG_PATH}/clang
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=${GCC_PATH}/aarch64-linux-android-

export KCFLAGS="-w"
export CONFIG_SECTION_MISMATCH_WARN_ONLY=y

KERNEL_DIR="$(pwd)"
OUT_DIR=/build/kernel_out
OUTPUT_DIR=/build/output_advanced

mkdir -p "${OUT_DIR}" "${OUTPUT_DIR}"
cd "${KERNEL_DIR}"

touch .scmversion

echo "=== [1/4] make mrproper and a32x_defconfig ==="
make -C "${KERNEL_DIR}" O="${OUT_DIR}" mrproper
make -C "${KERNEL_DIR}" O="${OUT_DIR}" a32x_defconfig

echo "=== [2/4] Applying Advanced Feature Configurations ==="
# 1. IPC Namespaces
sed -i 's/# CONFIG_SYSVIPC is not set/CONFIG_SYSVIPC=y/' "${OUT_DIR}/.config"
sed -i 's/# CONFIG_POSIX_MQUEUE is not set/CONFIG_POSIX_MQUEUE=y/' "${OUT_DIR}/.config"
sed -i 's/# CONFIG_IPC_NS is not set/CONFIG_IPC_NS=y/' "${OUT_DIR}/.config"

# 2. Google BBR and FQ Pacing
sed -i 's/# CONFIG_TCP_CONG_BBR is not set/CONFIG_TCP_CONG_BBR=y/' "${OUT_DIR}/.config"
sed -i 's/CONFIG_DEFAULT_TCP_CONG="bic"/CONFIG_DEFAULT_TCP_CONG="bbr"/' "${OUT_DIR}/.config"
sed -i 's/# CONFIG_NET_SCH_FQ is not set/CONFIG_NET_SCH_FQ=y/' "${OUT_DIR}/.config"
sed -i 's/# CONFIG_NET_SCH_FQ_CODEL is not set/CONFIG_NET_SCH_FQ_CODEL=y/' "${OUT_DIR}/.config"
sed -i 's/# CONFIG_NET_SCH_CODEL is not set/CONFIG_NET_SCH_CODEL=y/' "${OUT_DIR}/.config"

# 3. Virtual Interfaces (MACVLAN / IPVLAN)
sed -i 's/# CONFIG_MACVLAN is not set/CONFIG_MACVLAN=y/' "${OUT_DIR}/.config"
sed -i 's/# CONFIG_IPVLAN is not set/CONFIG_IPVLAN=y/' "${OUT_DIR}/.config"

# 4. Storage Schedulers (BFQ + NOOP Default)
sed -i 's/# CONFIG_IOSCHED_BFQ is not set/CONFIG_IOSCHED_BFQ=y/' "${OUT_DIR}/.config"
sed -i 's/CONFIG_DEFAULT_IOSCHED="cfq"/CONFIG_DEFAULT_IOSCHED="noop"/' "${OUT_DIR}/.config"

# 5. USB ConfigFS Gadgets
sed -i 's/# CONFIG_USB_CONFIGFS_NCM is not set/CONFIG_USB_CONFIGFS_NCM=y/' "${OUT_DIR}/.config"
sed -i 's/# CONFIG_USB_CONFIGFS_ECM is not set/CONFIG_USB_CONFIGFS_ECM=y/' "${OUT_DIR}/.config"
sed -i 's/# CONFIG_USB_CONFIGFS_EEM is not set/CONFIG_USB_CONFIGFS_EEM=y/' "${OUT_DIR}/.config"

# 6. Localversion align
sed -i 's/CONFIG_LOCALVERSION=""/CONFIG_LOCALVERSION="-27095505"/' "${OUT_DIR}/.config"
grep -q "CONFIG_LOCALVERSION=" "${OUT_DIR}/.config" || echo 'CONFIG_LOCALVERSION="-27095505"' >> "${OUT_DIR}/.config"

# Resolve dependencies cleanly
make -C "${KERNEL_DIR}" O="${OUT_DIR}" olddefconfig

echo "=== Verified Advanced Properties in .config ==="
grep -E 'CONFIG_(TCP_CONG_BBR|DEFAULT_TCP_CONG|NET_SCH_FQ|NET_SCH_FQ_CODEL|MACVLAN|IPVLAN|IOSCHED_BFQ|DEFAULT_IOSCHED|IPC_NS|SYSVIPC|POSIX_MQUEUE|USB_CONFIGFS_NCM|LOCALVERSION)=' "${OUT_DIR}/.config"

NPROC=$(nproc 2>/dev/null || echo 8)
echo "=== [3/4] Compiling Kernel Image.gz and modules (-j${NPROC}) ==="
make -C "${KERNEL_DIR}" O="${OUT_DIR}" -j${NPROC} Image.gz modules

echo "=== [4/4] Copying Kernel Artifacts ==="
cp "${OUT_DIR}/arch/arm64/boot/Image.gz" "${OUTPUT_DIR}/Image.gz"
cp "${OUT_DIR}/Module.symvers" "${OUTPUT_DIR}/Module.symvers"
cat "${OUT_DIR}/include/config/kernel.release" > "${OUTPUT_DIR}/kernel.release"

echo "Kernel compilation completed successfully! Artifacts in ${OUTPUT_DIR}/"
ls -lh "${OUTPUT_DIR}"
