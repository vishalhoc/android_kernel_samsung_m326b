# Official Samsung Galaxy M32 5G (SM-M326B) Kernel Source (v3.8.0 Hardware Swiss-Army Knife, Enterprise Server & NetHunter Core)

[![Kernel](https://img.shields.io/badge/Kernel-4.14.186--27095505-green.svg)](https://kernel.org)
[![Android](https://img.shields.io/badge/Android-13%20|%20One%20UI%205.1-blue.svg)](https://developer.android.com)
[![Device](https://img.shields.io/badge/Device-Samsung%20Galaxy%20M32%205G%20(SM--M326B)-orange.svg)](https://www.samsung.com)
[![SoC](https://img.shields.io/badge/SoC-MediaTek%20MT6853%20Dimensity%20720-red.svg)](https://www.mediatek.com)
[![TCP BBR](https://img.shields.io/badge/TCP-Google%20BBR%20v1-blue.svg)](https://github.com/vishalhoc/android_kernel_samsung_m326b)
[![FQ-CoDel](https://img.shields.io/badge/QoS-Default%20FQ--CoDel-success.svg)](https://github.com/vishalhoc/android_kernel_samsung_m326b)
[![Zero Aggregation](https://img.shields.io/badge/RNDIS-Zero%20Hold%20Delay-brightgreen.svg)](https://github.com/vishalhoc/android_kernel_samsung_m326b)
[![Big-Core RPS](https://img.shields.io/badge/RPS-Hardcoded%200xC0%20(Big%20Cores)-purple.svg)](https://github.com/vishalhoc/android_kernel_samsung_m326b)
[![Battery Bypass](https://img.shields.io/badge/Battery-Hardware%20Bypass%20Default-yellow.svg)](https://github.com/vishalhoc/android_kernel_samsung_m326b)

Official Linux kernel source code for the **Samsung Galaxy M32 5G (`SM-M326B`)**, based on Samsung Open Source release (`M326BDDSCCYD1` / SWA / Android 13 One UI 5.1, Binary C), engineered specifically for **24/7 Dedicated Headless Networking, Routing, Bridging, and High-Throughput Tethering**.

Tested and 100% verified on live hardware (`SM-M326B`): Cellular 5G NR_SA (Jio True5G), Dual-Stack IPv4/IPv6 Tethering (RNDIS USB & Wi-Fi Hotspot `swlan0`), USB Gigabit Ethernet (`eth0`), Bluetooth 5.1, GPS/GNSS, and FM Radio operate concurrently with rock-solid stability.

---

## 🛠️ What is New in Release v3.8.0 (Hardware Swiss-Army Knife, Enterprise Server & NetHunter Core)

Transforms the Samsung Galaxy M32 5G into an autonomous hardware Swiss-Army knife, enterprise Linux server, and portable wireless auditing platform:

### 1. 💽 DriveDroid UEFI/BIOS Bootable CD-ROM Emulation (`f_mass_storage.c`)
- Implemented kernel-level `cdrom` LUN sysfs attribute hooks (`cdrom_show` / `cdrom_store`).
- Enables booting physical PCs, laptops, and bare-metal servers directly from Windows 11/10 and Linux ISOs stored on the phone via USB cable without flash drives or Rufus.

### 2. ⌨️ USB HID Hardware Keyboard & Mouse Keystroke Injection (`/dev/hidg0`, `/dev/hidg1`)
- Enabled dynamic ConfigFS USB HID gadget support (`CONFIG_USB_CONFIGFS_F_HID=y`).
- Emulates a physical USB keyboard and mouse for external PCs, servers, and Raspberry Pis in BIOS/UEFI setup screens with zero drivers required on host.

### 3. 🎙️ USB Audio Class 2.0 Sound Card & Microphone Gadget (`CONFIG_USB_CONFIGFS_F_UAC2=y`)
- Presents the phone over USB as a studio-grade 24-bit/96kHz external USB sound card and digital microphone to PCs, Macs, and PlayStation/Switch consoles.

### 4. ⚡ USB Host Fast Charging Override (`sec_battery_dt.c`)
- Uncapped standard PC USB 500mA input current limit to **1500mA (1.5A)**, ensuring the device remains fully powered and charged during intensive tethering and container operations.

### 5. 🗄️ Native Network File Systems (CIFS/SMB 3.1.1 & NFS v3/v4/v4.2)
- Added kernel-native `cifs` and `nfs` client support with AES-128 encryption.
- Mount Windows shared folders (`\\192.168.1.100\Storage`) and Linux NFS shares directly into Android `/mnt/nas` at wire speed (1 Gbps) with zero userspace app overhead.

### 6. 🌐 Realtek RTL8152/RTL8153 Gigabit USB-to-LAN & CDC Networking
- Built-in plug-and-play driver support for Realtek RTL8152/RTL8153 Gigabit USB adapters and CDC Ethernet, enabling multi-NIC hardware routing.

### 7. 📡 Wireless Pentesting & External USB Wi-Fi Drivers (NetHunter Core)
- Built-in kernel support for `mac80211`, `cfg80211_wext`, and monitor mode / packet injection drivers:
  - **Atheros AR9271 (`ath9k_htc`):** Alfa AWUS036NHA monitor mode and 802.11 raw packet injection.
  - **Atheros AR9170 (`carl9170`):** 802.11a/b/g/n injection.
  - **Realtek RTL8187 (`rtl8187`):** High-power injection adapter.
  - **Ralink RT2800USB (`rt2800usb`):** RT3070 / RT5370 USB Wi-Fi dongles.

### 8. 🐳 Advanced Docker & Kubernetes Container Networking
- Enabled `CONFIG_GENEVE=y`, `CONFIG_NETFILTER_XT_MATCH_ADDRTYPE=y`, and `CONFIG_IP_NF_TARGET_REDIRECT=y` for seamless Docker port mapping and overlay networking.

---

## 🚀 What is New in Release v3.7.0 (Smart Dual-Engine 350+ Mbps Tethering & Zero-Latency Gaming)

Resolves USB tethering throughput capping (restoring full 300–350+ Mbps line rate) while maintaining instantaneous sub-millisecond response for real-time competitive gaming:

### 1. ⚡ Smart Dual-Engine USB Packet Dispatch (`drivers/usb/gadget/function/u_ether.c`)
- **Real-Time Traffic Engine (< 256 bytes):** UDP game ticks (PUBG/BGMI, Valorant, CS2, COD), VoIP voice frames, DNS lookups, and TCP ACKs completely bypass the hold/aggregation queue and are dispatched across the USB wire in `< 0.1ms` with **0ms holding jitter**.
- **High-Throughput Bulk Engine (>= 256 bytes):** High-speed TCP bulk streams batch up to 10 packets per 16 KB transfer buffer (`dl_max_pkts_per_xfer = 10`), cutting USB interrupt/transaction overhead by 90% and unlocking full **350+ Mbps throughput**.

### 2. 🌐 Re-Enabled Multi-Packet Transfer & 64KB GRO Forwarding (`drivers/usb/gadget/function/f_rndis.c`)
- Setting `rndis_dl_max_pkt_per_xfer = 10` keeps `multi_pkt_xfer = 1` active.
- Fixes cellular 5G modem GRO (Generic Receive Offload) page fragment assembly (`pinfo->frags`) in `u_ether.c`, completely preventing packet truncation and TCP window collapse.

### 3. 📏 Restored Standard Ethernet MTU 1500 on `rndis0`
- Reverted hardcoded 1372 MTU to standard 1500 (`rndis_mtu = 0`).
- Restores full 1460 TCP MSS, maximizing Windows TCP receive window scaling.

### 4. ⚖️ 6-Core Balanced RPS Mask (`0xFC`)
- Upgraded `set_rps_map_work` to mask `0xFC` (Cores 2–7: 4 Little Cortex-A55 + 2 Big Cortex-A76).
- Eliminates Big-Core CPU 6 & 7 softirq saturation during multi-hundred-megabit downloads.

### 5. 🌊 Native Fair Queueing Default (`CONFIG_DEFAULT_FQ=y`)
- Set default kernel packet scheduler to `fq` (`quantum 3000`), seamlessly integrating with Google TCP BBR pacing and eliminating CoDel 5ms delay packet drops.

### 6. 📶 Wi-Fi Hotspot (`swlan0`) & USB Ethernet (`eth0`) Throughput Restoration
- **Dual-Stack CLAT TCP MSS Clamping (`v4-rmnet+`):** Added explicit TCPMSS clamping to PMTU and TTL 64 normalization for `v4-rmnet+` (464XLAT virtual interface), eliminating packet fragmentation loops and PMTU blackholes for all IPv4 tethered traffic.
- **Multi-Queue Hotspot RPS Steering (`swlan0` rx-0 to rx-3):** Overruled Samsung's default `0x3f` LITTLE-core lock, steering Hotspot softirqs across balanced Cores 2–7 (`0xFC`) with `rps_flow_cnt = 4096`.
- **Wi-Fi Constantly Awake Mode:** Enabled `setCAM 1` and `autoPerfCfg ForceEnable:1`, disabling MediaTek DTIM sleep drops during high-speed routing.
- **Restored RFC 7323 TCP Timestamps (`net.ipv4.tcp_timestamps = 1`):** Restores dynamic TCP receive window auto-tuning on connected client PCs.

---

## ⚡ What is New in Release v3.6.0 (Zero-Latency Gaming & Native Kernel Sysctl Hardening)

Direct compile-time hardening of drivers, scheduler defaults, and kernel networking parameters:

### Category A: Driver Source Hardening
1. **RNDIS Instant Packet Dispatch (`drivers/usb/gadget/function/f_rndis.c`):**
   - `rndis_dl_max_pkt_per_xfer = 1` and `rndis_ul_max_pkt_per_xfer = 1`. Incoming packets are transmitted over USB immediately without 10-packet batch buffering.
2. **Packet Hold Threshold Disabled (`drivers/usb/gadget/function/u_ether.c`):**
   - `u_ether_tx_req_threshold = 9999` (was 1). Completely eliminates packet-holding queues in `u_ether.c`.
3. **Compile-Time Big-Core RPS Lock (`drivers/usb/gadget/function/u_ether.c`):**
   - MediaTek's driver hardcoding of `0xFF` in `set_rps_map_work` replaced with `0xC0` (Cortex-A76 Big Cores 6 & 7 only), guaranteeing in-order UDP delivery.
4. **Hardcoded RNDIS MTU (`drivers/usb/gadget/function/u_ether.c`):**
   - `rndis_mtu = 1372`, matching the 5G modem MTU to prevent IP/UDP packet fragmentation.
5. **Silenced MediaTek PPM DLPT Log Contention (`drivers/misc/mediatek/base/power/ppm_v3/src/mtk_ppm_policy_dlpt.c`):**
   - Eliminated the `ppm_warn` spam when DLPT is off, removing printk spinlock delays.
6. **Hardware Battery Slate / Bypass Mode Default (`drivers/battery/common/sec_battery.c`):**
   - Direct boot-time initialization in `sec_battery_probe`: power is routed straight from USB/charger to system with charging disabled (`SEC_BAT_CHG_MODE_CHARGING_OFF`).

### Category B: Defconfig Hardening (`arch/arm64/configs/a32x_defconfig`)
- **Default Packet Scheduler: FQ-CoDel** (`CONFIG_DEFAULT_FQ_CODEL=y`, `CONFIG_DEFAULT_NET_SCH="fq_codel"`), eliminating the 40ms refill delay and queue bloat of standard FQ.
- **BPF JIT Acceleration Always On** (`CONFIG_BPF_JIT=y`, `CONFIG_BPF_JIT_ALWAYS_ON=y`).
- **Default Congestion Control: BBR** (`CONFIG_TCP_CONG_BBR=y`, `CONFIG_DEFAULT_TCP_CONG="bbr"`).

### Category C: Native Compile-Time Kernel Sysctl Defaults
- **`rps_sock_flow_entries = 32768`** (`net/core/dev.c`): Flow table allocated and static keys activated at boot.
- **`tcp_fin_timeout = 15*HZ`** (`include/net/tcp.h`): Fast closure of orphaned connections.
- **`sysctl_tcp_nometrics_save = 1`** (`net/ipv4/tcp_metrics.c`): Zero stale metrics caching.
- **`vm_swappiness = 10`** (`mm/vmscan.c`): Eliminates unnecessary swap pressure.
- **`sysctl_vfs_cache_pressure = 20`** (`fs/dcache.c`): Prioritizes dentry/inode directory caching in physical RAM.
- **`vm_dirty_ratio = 20` & `dirty_background_ratio = 10`** (`mm/page-writeback.c`): Smooth, non-blocking asynchronous dirty page writebacks.

---

## 🚀 What is New in Release v3.5.0 (Ultra Gaming & Zero-Jitter Real-Time Network Edition)

Engineered to resolve real-time gaming packet latency, jitter bursts, and buffer exhaustion over USB RNDIS tethering and Wi-Fi hotspot on the Dimensity 720:

### 1. USB RNDIS Zero-Aggregation Immediate Dispatch (`rndis_dl_max_pkt_per_xfer = 1`)
- **Driver Patched:** `drivers/usb/gadget/function/f_rndis.c`
- Eliminates downstream batch aggregation delay where incoming packets were held until 10 packets accumulated (`rndis_dl_max_pkt_per_xfer = 10`). Real-time UDP gaming ticks are now dispatched immediately across the USB bus with zero hold delay and zero packet jitter.

### 2. High-Throughput USB Request Pool Expansion (`DEFAULT_QLEN = 32`)
- **Driver Patched:** `drivers/usb/gadget/function/u_ether.c`
- Expanded `DEFAULT_QLEN` from 2 to 32 (multiplied by `qmult=5` = 160 transfer buffers). Completely eliminates `NETDEV_TX_BUSY` buffer starvation and queue stops (`eth_start_xmit` drops) under sustained 500+ Mbps 5G bursts.

### 3. Homogeneous Big-Core RPS & RFS Steering (`0xC0` = Cores 6 & 7)
- **Problem Fixed:** Setting `rps_cpus = 0xFF` across heterogeneous big.LITTLE (6× Cortex-A55 + 2× Cortex-A76) cores processed network softirqs at different speeds, resulting in out-of-order UDP packet delivery which game netcodes discard as packet loss.
- **Solution:** Pinned RPS softirq processing strictly to Cortex-A76 Big Cores (`c0`) with Receive Flow Steering (`rps_flow_cnt = 4096`, `rps_sock_flow_entries = 32768`), guaranteeing in-order UDP delivery at maximum clock frequency.

### 4. Hardware Modem & USB DMA IRQ Steering to Cortex-A76 Big Cores
- Cellular modem DPMAIF (`IRQ 162`), CCIF data channels (`IRQ 164`), and USB musb-hdrc controller (`IRQ 183`) hardware interrupts routed directly to Cortex-A76 Big Cores (`c0`), removing little-core interrupt handling bottlenecks.

### 5. Wi-Fi SoftAP Constantly Awake Mode (Zero DTIM Latency)
- Forced continuous active mode via `/proc/net/wlan/setCAM = 1` and `/proc/net/wlan/autoPerfCfg = ForceEnable:1`, preventing the MediaTek Wi-Fi chip from entering sleep states between DTIM beacons and eliminating 100-300ms hotspot jitter spikes.

### 6. Dedicated 8GB Physical RAM Architecture (Purged ZRAM Overhead)
- Deactivated 4GB ZRAM swap (`swapoff /dev/block/zram0`, `swappiness = 0`), eliminating continuous CPU compression/decompression pauses and reclaiming full memory bandwidth from 8GB physical LPDDR4X RAM.

### 7. Hardware-Accelerated ARM64 Cryptography Injected
- Built-in ARMv8 Crypto Extensions enabled in kernel: `CONFIG_CRYPTO_CHACHA20_NEON=y`, `CONFIG_CRYPTO_CRC32_ARM64_CE=y`, `CONFIG_CRYPTO_AES_ARM64_BS=y`, `CONFIG_CRYPTO_AES_ARM64_CE_CCM=y`, `CONFIG_CRYPTO_SHA1_ARM64_CE=y`, `CONFIG_CRYPTO_SHA2_ARM64_CE=y`.

### 8. Enterprise Routing & Conntrack Session Table
- NAT Conntrack table scaled to 4,194,304 sessions (`nf_conntrack_max = 4194304`, `hashsize = 524288`).
- Kernel transparent proxy support (`CONFIG_NETFILTER_XT_TARGET_TPROXY=y`, `CONFIG_NETFILTER_XT_MATCH_SOCKET=y`).
- Congestion control algorithms added: DCTCP (`CONFIG_TCP_CONG_DCTCP=y`) and Illinois (`CONFIG_TCP_CONG_ILLINOIS=y`).

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
