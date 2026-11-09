import os
import sys
import hashlib
import subprocess

ADB = r"C:\Users\visha\AppData\Local\Android\Sdk\platform-tools\adb.exe"
IMG_PATH = r"I:\Kernel_Project\boot_advanced_m326b.img"
REMOTE_PATH = "/data/local/tmp/boot_advanced_m326b.img"

def calc_sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()

def run_adb(args, check=True):
    cmd = [ADB] + args
    res = subprocess.run(cmd, capture_output=True, text=True)
    if check and res.returncode != 0:
        print(f"Error running {' '.join(cmd)}: {res.stderr}")
        sys.exit(res.returncode)
    return res.stdout.strip()

print("=== 1. Checking boot image ===")
if not os.path.exists(IMG_PATH):
    print(f"Error: {IMG_PATH} not found!")
    sys.exit(1)

size = os.path.getsize(IMG_PATH)
local_sha = calc_sha256(IMG_PATH)
print(f"Local Image: {IMG_PATH}")
print(f"Size: {size} bytes ({size / 1024 / 1024:.2f} MB)")
print(f"Local SHA256: {local_sha}")

print("\n=== 2. Checking connected ADB devices ===")
devices_out = run_adb(["devices"])
lines = [l for l in devices_out.splitlines() if l.strip() and not l.startswith("List")]
if not lines:
    print("Error: No ADB devices found connected!")
    sys.exit(1)

target_dev = lines[0].split()[0]
print(f"Target Device: {target_dev}")

print("\n=== 3. Pushing image to device ===")
run_adb(["-s", target_dev, "push", IMG_PATH, REMOTE_PATH])
print("Image pushed successfully.")

print("\n=== 4. Verifying SHA256 on device ===")
dev_out = run_adb(["-s", target_dev, "shell", f"su -c 'sha256sum {REMOTE_PATH}'"])
dev_sha = dev_out.split()[0] if dev_out else ""
print(f"Device SHA256: {dev_sha}")

if local_sha.lower() != dev_sha.lower():
    print("FATAL ERROR: SHA256 checksum mismatch! Aborting flash for safety.")
    sys.exit(1)

print("Checksum verification PASSED!")

print("\n=== 5. Flashing to /dev/block/by-name/boot ===")
dd_out = run_adb(["-s", target_dev, "shell", f"su -c 'dd if={REMOTE_PATH} of=/dev/block/by-name/boot bs=4096 && sync'"])
print(dd_out)

print("\n=== 6. Cleaning up temporary image ===")
run_adb(["-s", target_dev, "shell", f"su -c 'rm -f {REMOTE_PATH}'"])

print("\n=== 7. Rebooting device with new custom kernel ===")
run_adb(["-s", target_dev, "shell", "su -c 'reboot'"], check=False)
print("Device reboot initiated successfully! The new custom kernel is now flashing and booting.")
