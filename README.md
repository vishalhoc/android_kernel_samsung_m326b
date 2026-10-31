# Official Samsung Galaxy M32 5G (SM-M326B) Kernel Source (v2.0 Advanced Router & Performance Engine)

[![Kernel](https://img.shields.io/badge/Kernel-4.14.186--27095505-green.svg)](https://kernel.org)
[![Android](https://img.shields.io/badge/Android-13%20|%20One%20UI%205.1-blue.svg)](https://developer.android.com)
[![Device](https://img.shields.io/badge/Device-Samsung%20Galaxy%20M32%205G%20(SM--M326B)-orange.svg)](https://www.samsung.com)
[![SoC](https://img.shields.io/badge/SoC-MediaTek%20MT6853%20Dimensity%20720-red.svg)](https://www.mediatek.com)
[![TCP BBR](https://img.shields.io/badge/TCP-Google%20BBR%20v1%20%2B%20FQ-blue.svg)](https://github.com/vishalhoc/android_kernel_samsung_m326b)
[![CAKE Bufferbloat](https://img.shields.io/badge/QoS-CAKE%20%26%20FQ--CoDel-success.svg)](https://github.com/vishalhoc/android_kernel_samsung_m326b)
[![IPC Namespace](https://img.shields.io/badge/IPC%20Namespaces-Active%20%26%20Verified-brightgreen.svg)](https://kernel.org)
[![DLKM Modules](https://img.shields.io/badge/DLKM%20Bypass-CRC%20Mismatch%20Override-orange.svg)](https://github.com/vishalhoc/android_kernel_samsung_m326b)

Official Linux kernel source code for the **Samsung Galaxy M32 5G (`SM-M326B`)**, based on Samsung Open Source release (`M326BDDSCCYD1` / SWA / Android 13 One UI 5.1, Binary C), with full **High-Speed Router Networking**, **Google BBR**, **CAKE & FQ Bufferbloat Mitigation**, **Linux Bridge & MACVLAN**, **BFQ Storage Scheduling**, **DLKM CRC Mismatch Bypass**, and **Linux IPC Namespace** support.

Tested and 100% verified on live hardware (`SM-M326B`): Cellular 5G NR_SA, Wi-Fi 5GHz (802.11ac 433Mbps), USB Gigabit Ethernet (`eth0`), Bluetooth 5.1, GPS/GNSS, and FM Radio operate concurrently with rock-solid stability.

---

## 📱 Device Specifications

| Feature | Value |
|---|---|
| **Device Model** | Samsung Galaxy M32 5G (`SM-M326B`) |
| **Board / Platform** | MediaTek MT6853 (`k6853v1_64_titan`) / Dimensity 720 5G |
| **Kernel Version** | Linux `4.14.186-27095505` |
| **Android Version** | Android 13 (`Tiramisu`) / One UI 5.1 |
| **Stock Build Fingerprint** | `samsung/m32xins/m32x:13/TP1A.220624.014/M326BDDSCCYD1:user/release-keys` |
| **Bootloader Revision** | Binary C (Rev 12) |
| **GPU Driver** | ARM Mali Valhall `r32p1` (`CONFIG_MTK_GPU_VERSION="mali valhall r32p1"`) |
| **Sensor Subsystem** | Samsung SHUB (`CONFIG_SHUB=y`, `CONFIG_SHUB_MTK=y`) |
| **Connectivity Hardware** | MT6631 / MT6635 (Wi-Fi 802.11ac, Bluetooth 5.1, GPS/GNSS, FM) |

---

## 🚀 Features & Enhancements in v2.0

### 1. High-Performance Networking Engine
- **Google BBR TCP Congestion Control**:
  - `CONFIG_TCP_CONG_BBR=y`, `CONFIG_DEFAULT_TCP_CONG="bbr"`
  - Maximizes throughput and minimizes latency on cellular (5G/4G) and tethered interfaces.
- **Bufferbloat Elimination (CAKE, FQ, FQ-CoDel)**:
  - `CONFIG_NET_SCH_CAKE=y`: In-tree Common Applications Kept Enhanced qdisc backported to 4.14.
  - `CONFIG_NET_SCH_FQ=y`, `CONFIG_NET_SCH_FQ_CODEL=y`, `CONFIG_NET_SCH_CODEL=y`.
- **Bridge & Virtual Interfaces**:
  - `CONFIG_BRIDGE=y`, `CONFIG_BRIDGE_IGMP_SNOOPING=y`, `CONFIG_BRIDGE_NETFILTER=m`.
  - `CONFIG_MACVLAN=y`, `CONFIG_IPVLAN=y` for multi-WAN and virtual tethering topologies.
- **USB ConfigFS High-Speed Gadgets**:
  - `CONFIG_USB_CONFIGFS_NCM=y`, `CONFIG_USB_CONFIGFS_ECM=y`, `CONFIG_USB_CONFIGFS_EEM=y`.

### 2. DLKM Architecture & Driver Compatibility
- **In-Kernel CRC Mismatch Bypass (`kernel/module.c`)**:
  - Overrides symbol CRC check rejections (`[FORCE_ALLOW] ignores CRC mismatch`) to guarantee out-of-tree vendor modules load seamlessly without module layout panics.
- **MediaTek EMI MPU MD Register Clear Fix (`drivers/memory/mediatek/emimpu.c`)**:
  - Fixes modem register clear sequence during reboot/reset cycles.
- **Vendored In-Tree Subsystems**:
  - `net/wireguard`: In-tree WireGuard VPN protocol accelerator.
  - `drivers/kernelsu`: In-tree KernelSU hook infrastructure.

### 3. Core Linux Capabilities
- **Full IPC Namespaces**:
  - `CONFIG_SYSVIPC=y`, `CONFIG_SYSVIPC_SYSCTL=y`, `CONFIG_POSIX_MQUEUE=y`, `CONFIG_IPC_NS=y`.
  - Enables unprivileged Linux containers, Droidspaces, and chroot/proot environments.
- **BFQ Storage I/O Scheduling**:
  - `CONFIG_IOSCHED_BFQ=y`, `CONFIG_DEFAULT_IOSCHED="noop"`.

---

## 🛠️ Build Instructions

### Toolchain Setup
Prerequisites: Google Clang `r383902` and GCC `4.9` aarch64 cross-compiler.
```bash
export ARCH=arm64
export SUBARCH=arm64
export ANDROID_MAJOR_VERSION=t
export CLANG_PATH=/build/toolchains/clang-r383902/bin
export GCC_PATH=/build/toolchains/gcc-4.9/bin
export PATH="${CLANG_PATH}:${GCC_PATH}:${PATH}"
```

### 1. Building the Kernel
```bash
chmod +x build_kernel_advanced.sh
./build_kernel_advanced.sh
```
Outputs `Image.gz` and `Module.symvers` with exact matching localversion `-27095505`.

### 2. Building Out-of-Tree MediaTek DLKM Modules
```bash
chmod +x build_all_modules_advanced.sh
./build_all_modules_advanced.sh
```
Compiles all 8 MediaTek vendor drivers: `wmt_drv.ko`, `connfem.ko`, `wmt_chrdev_wifi.ko`, `wlan_drv_gen4m.ko`, `bt_drv_connac1x.ko`, `gps_drv.ko`, `fmradio_drv_mt6631_6635.ko`, `met.ko`.

---

## ⚡ Deployment & Flashing

### Option A: Odin Flashing (PC)
1. Boot phone into **Download Mode** (`Vol Up + Vol Down` while plugging in USB-C connected to PC).
2. Open Odin and place `boot_advanced_m326b.tar.md5` into the **AP** slot.
3. Click **Start** to flash.

### Option B: Rooted ADB / Magisk Flashing
```bash
# Flash custom boot image directly
adb push boot_advanced_m326b.img /data/local/tmp/
adb shell su -c "dd if=/data/local/tmp/boot_advanced_m326b.img of=/dev/block/by-name/boot"

# Install matching DLKM module pack
adb push m326b_advanced_modules_v2.0.zip /data/local/tmp/
adb shell su -c "magisk --install-module /data/local/tmp/m326b_advanced_modules_v2.0.zip"

adb reboot
```

---

## 🔍 Verification Commands

```bash
# Verify kernel and localversion
uname -a
# Expected: Linux localhost 4.14.186-27095505 ... aarch64

# Verify Google BBR
cat /proc/sys/net/ipv4/tcp_congestion_control
# Expected: bbr

# Verify loaded vendor modules
lsmod

# Verify IPC namespaces
unshare -i echo IPC_NAMESPACES_OK
```

---

## 📜 License
This kernel is released under the GNU General Public License version 2 (GPLv2).
MediaTek vendor drivers are provided under their respective licenses from official Samsung Open Source release packages.
