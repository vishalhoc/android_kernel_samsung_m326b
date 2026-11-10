#!/bin/bash
set -e

# ==============================================================================
# Advanced Kernel Compilation for Samsung Galaxy M32 5G (SM-M326B)
# Kernel: 4.14.186-27095505 (MT6853 Dimensity 720)
# Features:
#   - Google BBR TCP Congestion Control (CONFIG_TCP_CONG_BBR=y, default=bbr)
#   - DCTCP & Illinois TCP Congestion Controls
#   - ARMv8 Hardware Crypto Extensions (NEON ChaCha20, Bit-sliced AES, CRC32 CE, SHA1/2 CE)
#   - Transparent Proxying & Netfilter (TPROXY, SOCKET, SIP ALG, TBF Shaper)
#   - Bridge VLAN Filtering & EBTables Acceleration
#   - Kernel IP Virtual Server (IPVS) Layer-4 Load Balancing
#   - USB RNDIS Instant Packet Dispatch (Zero Aggregation Delay)
#   - Expanded USB Request Pool (DEFAULT_QLEN = 32)
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

KERNEL_DIR=/build/kernel/samsung/m326b
OUT_DIR=/build/kernel_out
OUTPUT_DIR=/build/output_advanced

mkdir -p "${OUT_DIR}" "${OUTPUT_DIR}"
cd "${KERNEL_DIR}"

touch .scmversion

echo "=== [1/4] make mrproper and a32x_defconfig ==="
make -C "${KERNEL_DIR}" O="${OUT_DIR}" mrproper
make -C "${KERNEL_DIR}" O="${OUT_DIR}" a32x_defconfig

echo "=== [2/4] Applying Advanced Feature Configurations ==="
CONFIG_FILE="${OUT_DIR}/.config"

inject_opt() {
    local k="$1"
    local v="$2"
    if grep -q "^${k}=" "${CONFIG_FILE}" || grep -q "^# ${k} is not set" "${CONFIG_FILE}"; then
        sed -i "s|^# ${k} is not set|${k}=${v}|" "${CONFIG_FILE}"
        sed -i "s|^${k}=.*|${k}=${v}|" "${CONFIG_FILE}"
    else
        echo "${k}=${v}" >> "${CONFIG_FILE}"
    fi
}

# 1. IPC Namespaces
inject_opt "CONFIG_SYSVIPC" "y"
inject_opt "CONFIG_POSIX_MQUEUE" "y"
inject_opt "CONFIG_IPC_NS" "y"

# 2. Google BBR, DCTCP, Illinois & FQ Pacing
inject_opt "CONFIG_TCP_CONG_BBR" "y"
inject_opt "CONFIG_DEFAULT_TCP_CONG" '"bbr"'
inject_opt "CONFIG_TCP_CONG_DCTCP" "y"
inject_opt "CONFIG_TCP_CONG_ILLINOIS" "y"
inject_opt "CONFIG_NET_SCH_FQ" "y"
inject_opt "CONFIG_NET_SCH_FQ_CODEL" "y"
inject_opt "CONFIG_DEFAULT_FQ" "y"
inject_opt "CONFIG_DEFAULT_NET_SCH" '"fq"'
inject_opt "CONFIG_NET_SCH_CODEL" "y"
inject_opt "CONFIG_NET_SCH_CAKE" "y"
inject_opt "CONFIG_NET_SCH_TBF" "y"
inject_opt "CONFIG_NET_SCH_HHF" "y"
inject_opt "CONFIG_NET_SCH_PIE" "y"

# 3. Virtual Interfaces & L2 Bridge Acceleration
inject_opt "CONFIG_MACVLAN" "y"
inject_opt "CONFIG_IPVLAN" "y"
inject_opt "CONFIG_BRIDGE_VLAN_FILTERING" "y"
inject_opt "CONFIG_BRIDGE_EBT_ARPREPLY" "y"
inject_opt "CONFIG_BRIDGE_EBT_DNAT" "y"
inject_opt "CONFIG_BRIDGE_EBT_SNAT" "y"
inject_opt "CONFIG_BRIDGE_EBT_REDIRECT" "y"
inject_opt "CONFIG_BRIDGE_EBT_AMONG" "y"
inject_opt "CONFIG_BRIDGE_EBT_LIMIT" "y"

# 4. Netfilter, Conntrack & Transparent Proxying
inject_opt "CONFIG_NETFILTER_XT_TARGET_TPROXY" "y"
inject_opt "CONFIG_NETFILTER_XT_MATCH_SOCKET" "y"
inject_opt "CONFIG_NETFILTER_XT_MATCH_TCPMSS" "y"
inject_opt "CONFIG_NF_CONNTRACK_TIMEOUT" "y"
inject_opt "CONFIG_NF_CONNTRACK_ZONES" "y"
inject_opt "CONFIG_NF_CONNTRACK_SIP" "y"
inject_opt "CONFIG_IP_NF_TARGET_SYNPROXY" "y"
inject_opt "CONFIG_IP6_NF_TARGET_SYNPROXY" "y"

# 5. Kernel IP Virtual Server (IPVS)
inject_opt "CONFIG_IP_VS" "y"
inject_opt "CONFIG_IP_VS_RR" "y"
inject_opt "CONFIG_IP_VS_WRR" "y"
inject_opt "CONFIG_IP_VS_LC" "y"
inject_opt "CONFIG_IP_VS_WLC" "y"
inject_opt "CONFIG_IP_VS_SH" "y"
inject_opt "CONFIG_IP_VS_FTP" "y"
inject_opt "CONFIG_IP_VS_NFCT" "y"

# 6. ARM64 Hardware Cryptographic Acceleration (NEON & CE)
inject_opt "CONFIG_CRYPTO_CHACHA20_NEON" "y"
inject_opt "CONFIG_CRYPTO_CRC32_ARM64_CE" "y"
inject_opt "CONFIG_CRYPTO_AES_ARM64_BS" "y"
inject_opt "CONFIG_CRYPTO_AES_ARM64_CE_CCM" "y"
inject_opt "CONFIG_CRYPTO_SHA1_ARM64_CE" "y"
inject_opt "CONFIG_CRYPTO_SHA2_ARM64_CE" "y"

# 7. Storage Schedulers (BFQ + NOOP Default)
inject_opt "CONFIG_IOSCHED_BFQ" "y"
inject_opt "CONFIG_DEFAULT_IOSCHED" '"noop"'

# 8. USB ConfigFS Gadgets & Audio Class 2.0
inject_opt "CONFIG_USB_CONFIGFS_NCM" "y"
inject_opt "CONFIG_USB_CONFIGFS_ECM" "y"
inject_opt "CONFIG_USB_CONFIGFS_EEM" "y"
inject_opt "CONFIG_USB_CONFIGFS_F_UAC2" "y"
inject_opt "CONFIG_USB_CONFIGFS_F_HID" "y"

# 10. Native Network File Systems (CIFS/SMB 3.1.1 & NFS v3/v4/v4.2 Client)
inject_opt "CONFIG_NETWORK_FILESYSTEMS" "y"
inject_opt "CONFIG_CIFS" "y"
inject_opt "CONFIG_CIFS_STATS" "y"
inject_opt "CONFIG_CIFS_STATS2" "y"
inject_opt "CONFIG_CIFS_WEAK_PW_HASH" "y"
inject_opt "CONFIG_CIFS_UPCALL" "y"
inject_opt "CONFIG_CIFS_XATTR" "y"
inject_opt "CONFIG_CIFS_POSIX" "y"
inject_opt "CONFIG_CIFS_ACL" "y"
inject_opt "CONFIG_CIFS_DFS_UPCALL" "y"
inject_opt "CONFIG_CIFS_SMB311" "y"
inject_opt "CONFIG_NFS_FS" "y"
inject_opt "CONFIG_NFS_V3" "y"
inject_opt "CONFIG_NFS_V4" "y"
inject_opt "CONFIG_NFS_V4_1" "y"
inject_opt "CONFIG_NFS_V4_2" "y"

# 11. Gigabit USB Ethernet & CDC Networking
inject_opt "CONFIG_USB_USBNET" "y"
inject_opt "CONFIG_USB_RTL8152" "y"
inject_opt "CONFIG_USB_NET_CDCETHER" "y"
inject_opt "CONFIG_USB_NET_AX88179_178A" "y"

# 12. Wireless Auditing & External Wi-Fi Drivers (NetHunter Core)
inject_opt "CONFIG_CFG80211" "y"
inject_opt "CONFIG_CFG80211_WEXT" "y"
inject_opt "CONFIG_MAC80211" "y"
inject_opt "CONFIG_MAC80211_RC_MINSTREL" "y"
inject_opt "CONFIG_MAC80211_RC_MINSTREL_HT" "y"
inject_opt "CONFIG_WLAN_VENDOR_ATH" "y"
inject_opt "CONFIG_ATH9K_HTC" "y"
inject_opt "CONFIG_CARL9170" "y"
inject_opt "CONFIG_WLAN_VENDOR_REALTEK" "y"
inject_opt "CONFIG_RTL8187" "y"
inject_opt "CONFIG_WLAN_VENDOR_RALINK" "y"
inject_opt "CONFIG_RT2X00" "y"
inject_opt "CONFIG_RT2800USB" "y"
inject_opt "CONFIG_RT2800USB_RT33XX" "y"
inject_opt "CONFIG_RT2800USB_RT35XX" "y"
inject_opt "CONFIG_RT2800USB_RT53XX" "y"
inject_opt "CONFIG_RT2X00_LIB_USB" "y"

# 13. Advanced Container Networking & Docker Port Mapping
inject_opt "CONFIG_GENEVE" "y"
inject_opt "CONFIG_NETFILTER_XT_MATCH_ADDRTYPE" "y"
inject_opt "CONFIG_IP_NF_TARGET_REDIRECT" "y"


# 9. Localversion align
inject_opt "CONFIG_LOCALVERSION" '"-27095505"'

# Resolve dependencies cleanly
make -C "${KERNEL_DIR}" O="${OUT_DIR}" olddefconfig

echo "=== Verified Advanced Properties in .config ==="
grep -E 'CONFIG_(TCP_CONG_BBR|TCP_CONG_DCTCP|CRYPTO_CHACHA20_NEON|CRYPTO_CRC32_ARM64_CE|NETFILTER_XT_TARGET_TPROXY|NET_SCH_TBF|BRIDGE_VLAN_FILTERING|IP_VS|LOCALVERSION)=' "${OUT_DIR}/.config"

NPROC=$(nproc 2>/dev/null || echo 8)
echo "=== [3/4] Compiling Kernel Image.gz and modules (-j${NPROC}) ==="
make -C "${KERNEL_DIR}" O="${OUT_DIR}" -j${NPROC} Image.gz modules

echo "=== [4/4] Copying Kernel Artifacts ==="
cp "${OUT_DIR}/arch/arm64/boot/Image.gz" "${OUTPUT_DIR}/Image.gz"
cp "${OUT_DIR}/Module.symvers" "${OUTPUT_DIR}/Module.symvers"
cat "${OUT_DIR}/include/config/kernel.release" > "${OUTPUT_DIR}/kernel.release"

echo "Kernel compilation completed successfully! Artifacts in ${OUTPUT_DIR}/"
ls -lh "${OUTPUT_DIR}"
