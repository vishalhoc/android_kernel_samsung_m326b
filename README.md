# Official Samsung Galaxy M32 5G (SM-M326B) Kernel Source with Linux IPC Namespace

[![Kernel](https://img.shields.io/badge/Kernel-4.14.186--27095505-green.svg)](https://kernel.org)
[![Android](https://img.shields.io/badge/Android-13%20|%20One%20UI%205.1-blue.svg)](https://developer.android.com)
[![Device](https://img.shields.io/badge/Device-Samsung%20Galaxy%20M32%205G%20(SM--M326B)-orange.svg)](https://www.samsung.com)
[![SoC](https://img.shields.io/badge/SoC-MediaTek%20MT6853%20Dimensity%20720-red.svg)](https://www.mediatek.com)
[![Droidspaces](https://img.shields.io/badge/Droidspaces-IPC%20Namespace%20Ready-purple.svg)](https://github.com)

Official Linux kernel source code for the **Samsung Galaxy M32 5G (`SM-M326B`)**, based on official Samsung Open Source release (`M326BDDSCCYD1` / SWA / Android 13 One UI 5.1, Binary C), with full **Linux IPC Namespace** (`CONFIG_IPC_NS=y`, `CONFIG_SYSVIPC=y`, `CONFIG_POSIX_MQUEUE=y`) support enabled for running Linux containers, chroot environments, and **Droidspaces v6.6.0**.

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
| **Storage / Encryption** | UFS 2.1, Knox FBE v2 SDP Inode Context |

---

## 🛠️ Features & Enhancements

- **Linux IPC Namespaces**:
  - `CONFIG_SYSVIPC=y`: System V IPC (semaphores, message queues, shared memory).
  - `CONFIG_SYSVIPC_SYSCTL=y`: Sysctl controls for IPC parameters.
  - `CONFIG_POSIX_MQUEUE=y`: POSIX message queues.
  - `CONFIG_POSIX_MQUEUE_SYSCTL=y`: Sysctl controls for POSIX message queues.
  - `CONFIG_IPC_NS=y`: Linux IPC namespaces (`unshare --ipc` functional).
- **Stock Compatibility**:
  - `CONFIG_LOCALVERSION="-27095505"` (exact match to release string).
  - `CONFIG_BLK_DEV_LOOP_MIN_COUNT=48` (prevents loop exhaustion during APEX container mounts).
  - Clean eBPF array map implementation (fixes `bpfloader-failed` critical aborts).
  - Samsung Knox SDP v2 fscrypt context support.

---

## 📦 Toolchain Requirements

To ensure 100% binary compatibility with stock Samsung vendor modules, compile with:
- **Clang**: `clang-r383902` (Android Clang 11.0.1)
- **Cross-Compiler**: `aarch64-linux-android-4.9` (GCC 4.9 toolchain)

---

## 🚀 Build Instructions

### 1. Setup Build Environment (Ubuntu / WSL2)
```bash
sudo apt-get update
sudo apt-get install -y build-essential libncurses5-dev bzip2 libssl-dev bc flex bison libelf-dev
```

### 2. Download Toolchains
Ensure toolchains are placed or symlinked into `toolchain/`:
```bash
toolchain/clang/host/linux-x86/clang-r383902
toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9
```

### 3. Build the Kernel
Run the provided automated build script:
```bash
chmod +x build_kernel.sh
./build_kernel.sh
```

Or build manually:
```bash
export CROSS_COMPILE=$(pwd)/toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
export CC=$(pwd)/toolchain/clang/host/linux-x86/clang-r383902/bin/clang
export CLANG_TRIPLE=aarch64-linux-gnu-
export ARCH=arm64
export ANDROID_MAJOR_VERSION=t
export KCFLAGS=-w
export CONFIG_SECTION_MISMATCH_WARN_ONLY=y

# Configure with stock M32 5G defconfig
make O=out a32x_defconfig

# Build Image.gz
make O=out -j$(nproc) Image.gz
```

Output kernel binary:
`out/arch/arm64/boot/Image.gz`

---

## ⚡ Flashing Instructions

1. Unpack your current working Magisk-rooted boot image:
   ```bash
   magiskboot unpack stock_boot.img
   ```
2. Replace `kernel` with the newly compiled `Image` (or `Image.gz`).
3. Repack:
   ```bash
   magiskboot repack stock_boot.img new_boot.img
   ```
4. Flash via fastboot, recovery, or directly on device:
   ```bash
   su -c "dd if=new_boot.img of=/dev/block/by-name/boot"
   ```

---

## 🔍 Verification

After booting into Android:
```bash
# Check IPC namespace config
zcat /proc/config.gz | grep -E 'CONFIG_(IPC_NS|SYSVIPC|POSIX_MQUEUE)'

# Verify unshare works
unshare --ipc sh -c 'echo IPC_NAMESPACE_SUCCESS'

# Test with Droidspaces
droidspaces check
```

---

## 📜 License
This kernel is released under the GNU General Public License version 2 (GPLv2).
