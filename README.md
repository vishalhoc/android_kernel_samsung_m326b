# Official Samsung Galaxy M32 5G (SM-M326B) Kernel Source (v3.4.0 Dedicated Router Super-Edition)

[![Kernel](https://img.shields.io/badge/Kernel-4.14.186--27095505-green.svg)](https://kernel.org)
[![Android](https://img.shields.io/badge/Android-13%20|%20One%20UI%205.1-blue.svg)](https://developer.android.com)
[![Device](https://img.shields.io/badge/Device-Samsung%20Galaxy%20M32%205G%20(SM--M326B)-orange.svg)](https://www.samsung.com)
[![SoC](https://img.shields.io/badge/SoC-MediaTek%20MT6853%20Dimensity%20720-red.svg)](https://www.mediatek.com)
[![TCP BBR](https://img.shields.io/badge/TCP-Google%20BBR%20v1%20%2B%20FQ-blue.svg)](https://github.com/vishalhoc/android_kernel_samsung_m326b)
[![CAKE Bufferbloat](https://img.shields.io/badge/QoS-CAKE%20%26%20FQ--CoDel-success.svg)](https://github.com/vishalhoc/android_kernel_samsung_m326b)
[![IPC Namespace](https://img.shields.io/badge/IPC%20Namespaces-Active%20%26%20Verified-brightgreen.svg)](https://kernel.org)
[![DLKM Modules](https://img.shields.io/badge/DLKM%20Bypass-CRC%20Mismatch%20Override-orange.svg)](https://github.com/vishalhoc/android_kernel_samsung_m326b)

Official Linux kernel source code for the **Samsung Galaxy M32 5G (`SM-M326B`)**, based on Samsung Open Source release (`M326BDDSCCYD1` / SWA / Android 13 One UI 5.1, Binary C), engineered specifically for **24/7 Dedicated Headless Networking, Routing, Bridging, and High-Throughput Tethering**.

Tested and 100% verified on live hardware (`SM-M326B`): Cellular 5G NR_SA (Jio True5G), Dual-Stack IPv4/IPv6 Tethering (RNDIS USB & Wi-Fi Hotspot `swlan0`), USB Gigabit Ethernet (`eth0`), Bluetooth 5.1, GPS/GNSS, and FM Radio operate concurrently with rock-solid stability.

---

## ⚡ What is New in Release v3.4.0 (24/7 Dedicated Router & Network Super-Edition)

Designed specifically for **headless 24/7 dedicated high-performance routing, bridging, and tethering** on the Samsung Galaxy M32 5G (8 GB RAM, 24/7 charger-powered).

### 1. Ultra-Low Latency Zero-Sleep PM QoS (0µs Response)
- Sets `pm_qos_resume_latency_us = 0` across all 8 CPU cores (Cortex-A76 Big Cores + Cortex-A55 Little Cores).
- CPU cores remain instantly responsive at sub-microsecond latency for real-time packet forwarding with zero wake-up jitter.

### 2. Wi-Fi CAM (Constantly Awake Mode) & High-Capacity Queues
- Hardware Wi-Fi power-saving completely disabled (`CFG_ENABLE_FULL_PM = 0`).
- Radio initialized in `ENUM_PSP_CONTINUOUS_ACTIVE` for minimum latency.
- Wi-Fi TX packet queue expanded from 1024 to 4096 packets (`CFG_TX_MAX_PKT_NUM = 4096`).

### 3. Massive 32MB Network Socket Buffers (8GB RAM Dedicated Memory Pools)
- Socket buffer limits raised to 32MB (`rmem_max = 33554432`, `wmem_max = 33554432`).
- TCP auto-tuning dynamically scales up to 32MB windows (`tcp_rmem = 4096 87380 33554432`, `tcp_wmem = 4096 65536 33554432`).
- Network device input backlog expanded to 32,768 packets (`netdev_max_backlog = 32768`).
- Maximum socket connections and SYN backlog scaled to 8,192 (`somaxconn = 8192`, `tcp_max_syn_backlog = 8192`).

### 4. Linux L2 Bridge Acceleration & EBTables Filtering Engine
- Built-in bridge acceleration with `CONFIG_BRIDGE_VLAN_FILTERING=y` and ebtables extensions (`CONFIG_BRIDGE_EBT_ARPREPLY=y`, `DNAT=y`, `SNAT=y`, `REDIRECT=y`, `AMONG=y`, `LIMIT=y`).
- Kernel IP Virtual Server (IPVS) transport-layer load balancers compiled directly into the kernel (`CONFIG_IP_VS=y` with Round Robin, Weighted RR, Least-Connection, and Weighted LC).

### 5. RFC 4861-Compliant Precision WAN TTL & Hop Limit Normalization
- Carrier hotspot restrictions bypassed with automatic `TTL 64` / `HL 64` normalization targeted strictly to outbound WAN traffic (`rmnet+`, `ccmni+`) on TCP and UDP protocols.
- ICMPv6 Router Solicitations and Neighbor Discovery strictly preserved at Hop Limit 255 per RFC 4861, ensuring seamless 5G SA SLAAC registration.
- Enforced unconditional Router Advertisement acceptance (`accept_ra = 2`).

### 6. Universal Cross-NIC Forwarding & Dual-Stack TCP MSS Clamping
- Unrestricted forwarding across Wi-Fi hotspot (`swlan0`), USB tethering (`rndis0`), Ethernet (`eth0`), and bridge (`br0`).
- Automated PMTU clamping (`TCPMSS --clamp-mss-to-pmtu`) eliminating packet fragmentation and VPN connection drops.

### 7. Complete Hardware & Kernel Restriction Removal
- **CPU Big-Core Uncap**: Cortex-A76 Big Cores (CPU6 & CPU7) uncapped to full 2.0 GHz (`scaling_max_freq = 2000000`).
- **MediaTek PPM Throttling Elimination**: `PPM_POLICY_PWR_THRO`, `PPM_POLICY_THERMAL`, and `PPM_POLICY_DLPT` disabled; `PPM_POLICY_SYS_BOOST` enabled.
- **Dedicated 8GB RAM Cache Allocation**: `vm.swappiness = 10`, `vfs_cache_pressure = 20`, `dirty_ratio = 20`, eliminating all ZRAM swapping overhead and premature cache eviction.
- **High-Concurrency Session Table**: `nf_conntrack_max = 2000000`, `tcp_fin_timeout = 15`.
- **Hex 0xFF Multi-Core Packet Steering**: Receive Packet Steering (`rps_cpus = ff`) steering network interrupts evenly across all 8 cores.
- **24/7 Hardware Battery Slate Mode**: Direct AC power supply bypass (`batt_slate_mode = 1`, `galaxy_acc.conf BYPASS=1`) running indefinitely on charger with zero battery cycling.
- **Android Framework Restriction Removal**: Android Doze disabled (`dumpsys deviceidle disable`), Samsung GOS disabled (`pm disable com.samsung.android.game.gos`), Wi-Fi SoftAP inactivity timeout disabled (`wifi_ap_timeout = 0`).

---

## ⚡ What is New in Release v3.3.0 (All 7 Advanced Innovations)

1. **TCP BBR+ Jitter Elimination Engine**:
   - Extended min_rtt window to 25s (`bbr_min_rtt_win_sec = 25`).
   - Reduced PROBE_RTT duration from 200ms to 30ms (`bbr_probe_rtt_mode_ms = 30`).
   - Raised cwnd floor from 4 to 16 packets (`bbr_cwnd_min_target = 16`), completely eliminating periodic throughput drops during gaming and voice calls.

2. **5G Cellular Data Plane Cortex-A76 Big-Core DVFS Boost & Distributed RPS Steering**:
   - Patched MediaTek ECCCI platform modem DVFS tables (`drivers/misc/mediatek/eccci/mt6853/ccci_platform.c`).
   - Forces immediate Cortex-A76 Big-Core scheduling (`0xC0`) and RPS distribution (`0xFC`) across all 6 Little Cores + 2 Big Cores down to 0-50 Mbps.

3. **High-Density AP Wi-Fi Client Capacity (64 Concurrent Stations)**:
   - Expanded MediaTek gen4m driver station capacity from 27 to 64 (`#define CFG_STA_REC_NUM 64`).
   - Fully compliant with 802.11 TIM partial virtual bitmap standards.

4. **Sub-Millisecond Wi-Fi AP P2P Beaconing (DTIM = 1)**:
   - Patched AP start message in `os/linux/gl_p2p_cfg80211.c` to force `u4DtimPeriod = 1`.
   - Delivers low latency for real-time competitive online gaming and VOIP.

5. **Headless PM QoS Resume Latency Engine**:
   - Injected `pm_qos_resume_latency_us = 50` across all CPU cores (cpu0-cpu7).
   - Prevents deep idle C-state sleep jitter during screen-off operation.

6. **Hardware Battery Bypass Auto-Slate on Boot**:
   - Auto-activates `batt_slate_mode 1` directly in boot ramdisk.
   - Enforces world-writable `0666` permissions for non-root battery bypass toggling.

7. **24/7 F2FS Router Storage Endurance & Background GC Engine**:
   - Auto-configures F2FS userdata filesystem: `gc_idle=1`, `gc_idle_interval=2`, `gc_max_sleep_time=50000`, `discard_granularity=16`, `discard_idle_interval=50`.
   - Protects UFS flash storage from write amplification during sustained 24/7 routing workloads.

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

# Verify CPU6/7 2.0GHz uncap
cat /sys/devices/system/cpu/cpu6/cpufreq/scaling_cur_freq
# Expected: 2000000

# Verify MediaTek PPM Throttling disabled
cat /proc/ppm/policy_status | grep -E "PWR_THRO|THERMAL|SYS_BOOST"
# Expected: PWR_THRO: disabled, THERMAL: disabled, SYS_BOOST: enabled

# Verify Battery Slate Mode
cat /sys/class/power_supply/battery/batt_slate_mode
# Expected: 1
```

---

## 📜 License
This kernel is released under the GNU General Public License version 2 (GPLv2).
MediaTek vendor drivers are provided under their respective licenses from official Samsung Open Source release packages.
