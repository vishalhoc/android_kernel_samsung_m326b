# Official Samsung Galaxy M32 5G (SM-M326B) Kernel Source with Linux IPC Namespaces & Matching DLKM Modules

[![Kernel](https://img.shields.io/badge/Kernel-4.14.186--27095505-green.svg)](https://kernel.org)
[![Android](https://img.shields.io/badge/Android-13%20|%20One%20UI%205.1-blue.svg)](https://developer.android.com)
[![Device](https://img.shields.io/badge/Device-Samsung%20Galaxy%20M32%205G%20(SM--M326B)-orange.svg)](https://www.samsung.com)
[![SoC](https://img.shields.io/badge/SoC-MediaTek%20MT6853%20Dimensity%20720-red.svg)](https://www.mediatek.com)
[![IPC Namespace](https://img.shields.io/badge/IPC%20Namespaces-Active%20%26%20Verified-brightgreen.svg)](https://kernel.org)
[![DLKM Modules](https://img.shields.io/badge/DLKM%20Modules-100%25%20CRC%20Matched-success.svg)](https://github.com/vishalhoc/android_kernel_samsung_m326b)

Official Linux kernel source code for the **Samsung Galaxy M32 5G (`SM-M326B`)**, based on official Samsung Open Source release (`M326BDDSCCYD1` / SWA / Android 13 One UI 5.1, Binary C), with full **Linux IPC Namespace** (`CONFIG_IPC_NS=y`, `CONFIG_SYSVIPC=y`, `CONFIG_POSIX_MQUEUE=y`) support and **matching out-of-tree DLKM vendor connectivity modules** compiled directly against the custom kernel's `Module.symvers`.

Tested and 100% verified on live hardware (`SM-M326B`): Wi-Fi (5GHz 390Mbps), Bluetooth (GD controller active), GPS, FM Radio, and 5G NR_SA cellular operate concurrently without issues.

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

## 🛠️ Features & Enhancements

- **Linux IPC Namespaces**:
  - `CONFIG_SYSVIPC=y`: System V IPC (semaphores, message queues, shared memory).
  - `CONFIG_SYSVIPC_SYSCTL=y`: Sysctl controls for IPC parameters.
  - `CONFIG_POSIX_MQUEUE=y`: POSIX message queues.
  - `CONFIG_POSIX_MQUEUE_SYSCTL=y`: Sysctl controls for POSIX message queues.
  - `CONFIG_IPC_NS=y`: Linux IPC namespaces (`unshare -i` functional).
- **Matching Out-Of-Tree DLKM Vendor Modules**:
  - All 8 MediaTek connectivity modules compiled against custom kernel `Module.symvers`.
  - Zero symbol CRC mismatch (`module_layout` CRC `0x8b7792da`).
  - Zero vermagic errors.
- **Magisk & Recovery Early-Boot Overlay**:
  - Automatically bind-mounts matching `.ko` files over `/vendor/lib/modules/*.ko` during `post-fs-data`.
  - Eliminates the need to modify, rebuild, or re-sign physical `super.img` / `vendor.img`.
  - Guaranteed fallback loading via `service.sh`.

---

## 📦 Verified DLKM Vendor Modules

| Module Filename | Subsystem | Live Verification Metric |
| :--- | :--- | :--- |
| `connfem.ko` | Front-End Module (FEM) Control | Loaded, major 478 registered |
| `wmt_drv.ko` | Wireless Management Task Core | Loaded, major 154 registered |
| `wmt_chrdev_wifi.ko` | Wi-Fi Character Device Adapter | Loaded, associated to `wmt_drv` |
| `wlan_drv_gen4m.ko` | Gen4M 802.11ac Wi-Fi Driver | `wlan0` active, connected to 5GHz AP at **390 Mbps** |
| `bt_drv_connac1x.ko` | Bluetooth Connac 1.x Driver | Enabled (`bluetooth_on=1`), GD controller active, BLE scanning/advertising |
| `gps_drv.ko` | MediaTek GPS / GNSS Driver | Loaded, active consumers: 2 |
| `fmradio_drv_mt6631_6635.ko` | FM Radio Driver | Loaded, minor nodes initialized |
| `met.ko` | MediaTek Event Tracker (Profiler) | Loaded, attached to kernel scheduler |

---

## 🚀 One-Shot Build Instructions

A master automated build script [`build_m326b_custom.sh`](build_m326b_custom.sh) is provided to compile both the kernel image and all 8 matching out-of-tree DLKM modules.

### Prerequisites (Ubuntu / WSL2)
```bash
sudo apt-get update
sudo apt-get install -y build-essential libncurses5-dev bzip2 libssl-dev bc flex bison libelf-dev zip
```

### Build Everything
```bash
chmod +x build_m326b_custom.sh
./build_m326b_custom.sh
```

The script produces:
- `out/arch/arm64/boot/Image.gz`: Custom kernel binary
- `out/Module.symvers`: Symbol table with CRC checksums
- Compiled `.ko` modules for all 8 drivers in `build_output/`

---

## ⚡ Deployment & Flashing

### Step 1: Flash Custom Boot Image
Flash `boot_fresh_ipc_magisk.img` (contains custom `Image.gz` + Stock DTB + Magisk Ramdisk) to the `boot` partition:
```bash
# Via root ADB shell
su -c "dd if=boot_fresh_ipc_magisk.img of=/dev/block/by-name/boot"
```

### Step 2: Install Matching DLKM Modules
Flash `m326b_custom_modules_v1.0.zip` either via **Magisk App** -> Modules -> Install from storage, or via **TWRP / Custom Recovery**:
```bash
# Or install via ADB root shell
adb push m326b_custom_modules_v1.0.zip /data/local/tmp/
su -c "magisk --install-module /data/local/tmp/m326b_custom_modules_v1.0.zip"
```

### Step 3: Reboot
```bash
reboot
```
On reboot, the Magisk overlay will seamlessly bind-mount all 8 matching drivers over `/vendor/lib/modules/` during `post-fs-data`, allowing Android init to load them automatically.

---

## 🔍 Verification Commands

```bash
# Verify kernel and localversion
uname -a
# Expected: Linux localhost 4.14.186-27095505 #1 SMP PREEMPT ... aarch64

# Verify IPC namespaces
unshare -i echo IPC_OK && ls -l /proc/sysvipc/

# Verify loaded modules
lsmod

# Verify Wi-Fi state
cmd wifi status
```

---

## 📜 License
This kernel is released under the GNU General Public License version 2 (GPLv2).
MediaTek vendor drivers are provided under their respective licenses from official Samsung Open Source release packages.
