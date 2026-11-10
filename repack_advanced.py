import os
import subprocess
import sys

workdir = "/build/repack_final"
os.makedirs(workdir, exist_ok=True)
os.chdir(workdir)

# Clean
for f in os.listdir(workdir):
    p = os.path.join(workdir, f)
    if os.path.isfile(p):
        os.remove(p)

print("=== 1. Unpacking stock_boot.img ===")
subprocess.run(["magiskboot", "unpack", "/mnt/i/Kernel_Project/stock_boot.img"], check=True)

print("=== 2. Replacing kernel Image ===")
subprocess.run(["cp", "/build/kernel_out/arch/arm64/boot/Image", "./kernel"], check=True)

print("=== 3. Inverting and setting boot-level ADB properties ===")
build_prop = """ro.product.bootimage.brand=samsung
ro.product.bootimage.device=a32x
ro.product.bootimage.manufacturer=samsung
ro.product.bootimage.model=SM-M326B
ro.product.bootimage.name=a32xins
ro.bootimage.build.date=Thu Apr 17 20:18:34 KST 2025
ro.bootimage.build.date.utc=1744888714
ro.bootimage.build.fingerprint=samsung/a32xins/a32x:13/TP1A.220624.014/M326BDDSCCYD1:user/release-keys
ro.bootimage.build.id=TP1A.220624.014
ro.bootimage.build.tags=release-keys
ro.bootimage.build.type=user
ro.bootimage.build.version.incremental=M326BDDSCCYD1
ro.bootimage.build.version.release=13
ro.bootimage.build.version.release_or_codename=13
ro.bootimage.build.version.sdk=33
persist.sys.usb.config=mtp,adb
ro.debuggable=1
ro.adb.secure=0
ro.secure=0
service.adb.tcp.port=5555
persist.adb.tcp.port=5555
persist.service.adb.enable=1
persist.service.debuggable=1
"""
with open("build.prop.mod", "w") as f:
    f.write(build_prop)

init_rc = """on early-init
    setprop ro.debuggable 1
    setprop ro.adb.secure 0
    setprop ro.secure 0
    setprop persist.adb.tcp.port 5555
    setprop service.adb.tcp.port 5555

on init
    setprop ro.debuggable 1
    setprop ro.adb.secure 0
    setprop persist.sys.usb.config mtp,adb
    setprop sys.usb.config mtp,adb
    setprop persist.adb.tcp.port 5555
    setprop service.adb.tcp.port 5555

on post-fs-data
    setprop persist.sys.usb.config mtp,adb
    setprop persist.service.adb.enable 1
    setprop persist.service.debuggable 1
    setprop persist.adb.tcp.port 5555
    setprop service.adb.tcp.port 5555
    start adbd

    # Kernel & IPC Subsystem Inotify Limits
    write /proc/sys/fs/inotify/max_user_watches 1048576
    write /proc/sys/fs/inotify/max_user_instances 1024

    # IPv6 SLAAC & RA Acceptance Guarantee (CRITICAL: Overrule router mode so 5G WAN connects!)
    write /proc/sys/net/ipv6/conf/all/accept_ra 2
    write /proc/sys/net/ipv6/conf/default/accept_ra 2

    # Hardware Battery Bypass Slate Mode World-Writable (0666)
    chmod 0666 /sys/class/power_supply/battery/batt_slate_mode
    chmod 0666 /sys/class/power_supply/battery/batt_full_capacity

on boot
    setprop persist.sys.usb.config mtp,adb
    setprop sys.usb.config mtp,adb
    setprop persist.adb.tcp.port 5555
    setprop service.adb.tcp.port 5555
    start adbd

# ==============================================================================
# Seamless Multi-Interface ADB Auto-Start Engine (Hotspot, Ethernet, Wi-Fi & USB)
# ==============================================================================

# 1. Wi-Fi SoftAP / Hotspot Auto-Start Triggers
on property:sys.wifi.tethering=1
    setprop persist.adb.tcp.port 5555
    setprop service.adb.tcp.port 5555
    start adbd

on property:wifi.tethering=1
    setprop persist.adb.tcp.port 5555
    setprop service.adb.tcp.port 5555
    start adbd

on property:net.swlan0.state=up
    setprop persist.adb.tcp.port 5555
    setprop service.adb.tcp.port 5555
    start adbd

on property:init.svc.hostapd=running
    setprop persist.adb.tcp.port 5555
    setprop service.adb.tcp.port 5555
    start adbd

# 2. Gigabit USB Ethernet (RTL8152/8153, AX88179, CDC) Auto-Start Triggers
on property:net.eth0.state=up
    setprop persist.adb.tcp.port 5555
    setprop service.adb.tcp.port 5555
    start adbd

on property:net.eth1.state=up
    setprop persist.adb.tcp.port 5555
    setprop service.adb.tcp.port 5555
    start adbd

on property:dhcp.eth0.result=ok
    setprop persist.adb.tcp.port 5555
    setprop service.adb.tcp.port 5555
    start adbd

on property:dhcp.eth1.result=ok
    setprop persist.adb.tcp.port 5555
    setprop service.adb.tcp.port 5555
    start adbd

# 3. Wi-Fi Client (WLAN STA) Auto-Start Triggers
on property:wlan.driver.status=ok
    setprop persist.adb.tcp.port 5555
    setprop service.adb.tcp.port 5555
    start adbd

on property:net.wlan0.state=up
    setprop persist.adb.tcp.port 5555
    setprop service.adb.tcp.port 5555
    start adbd

# 4. USB Disconnect & Host Mode Shield (Preserve ADB when USB cable is unplugged)
on property:sys.usb.config=none
    setprop persist.adb.tcp.port 5555
    setprop service.adb.tcp.port 5555
    start adbd

on property:sys.usb.state=none
    setprop persist.adb.tcp.port 5555
    setprop service.adb.tcp.port 5555
    start adbd

# 5. Continuous Auto-Revive Trigger (Never allow adbd to stay stopped)
on property:init.svc.adbd=stopped
    setprop persist.adb.tcp.port 5555
    setprop service.adb.tcp.port 5555
    start adbd

# 6. Service definition for 24/7 ADB Network Watchdog
service adb_watchdog /system/bin/sh /overlay.d/adb_watchdog.sh
    disabled
    user root
    group root
    seclabel u:r:magisk:s0
    oneshot

    # Linux Container & IPC Auto-Mount Subsystem
    mkdir /dev/shm 0777 root root
    mount tmpfs tmpfs /dev/shm nodev nosuid mode=1777,size=512M
    mkdir /dev/mqueue 0777 root root
    mount mqueue none /dev/mqueue
    mkdir /sys/fs/cgroup/devices 0755 root root
    mount cgroup none /sys/fs/cgroup/devices devices
    mkdir /sys/fs/cgroup/freezer 0755 root root
    mount cgroup none /sys/fs/cgroup/freezer freezer

    # Network Queue Pacing & Congestion Control
    write /proc/sys/net/ipv4/tcp_congestion_control bbr
    write /proc/sys/net/core/default_qdisc fq
    write /proc/sys/net/ipv4/ip_default_ttl 64

    # 8GB Dedicated Network & Internet Router Memory Pools (Massive Buffers)
    write /proc/sys/net/core/rmem_max 67108864
    write /proc/sys/net/core/wmem_max 67108864
    write /proc/sys/net/core/rmem_default 2097152
    write /proc/sys/net/core/wmem_default 2097152
    write /proc/sys/net/core/optmem_max 2097152
    write /proc/sys/net/ipv4/tcp_rmem "4096 87380 67108864"
    write /proc/sys/net/ipv4/tcp_wmem "4096 65536 67108864"
    write /proc/sys/net/core/netdev_max_backlog 65536
    write /proc/sys/net/core/somaxconn 8192
    write /proc/sys/net/ipv4/tcp_max_syn_backlog 8192
    write /proc/sys/net/ipv4/tcp_max_tw_buckets 2000000
    write /proc/sys/net/netfilter/nf_conntrack_max 1048576
    write /proc/sys/net/netfilter/nf_conntrack_tcp_timeout_established 7200
    write /proc/sys/net/ipv4/tcp_fin_timeout 15
    write /proc/sys/net/ipv4/tcp_no_metrics_save 1

    # Dedicated 8GB RAM Pool Tuning (Zero ZRAM Swap Stalls)
    write /proc/sys/vm/swappiness 10
    write /proc/sys/vm/vfs_cache_pressure 20
    write /proc/sys/vm/dirty_ratio 20
    write /proc/sys/vm/dirty_background_ratio 10
    write /proc/sys/vm/dirty_expire_centisecs 3000
    write /proc/sys/vm/dirty_writeback_centisecs 500

    # Ultra-Low Latency & 0-RTT Connection Parameters
    write /proc/sys/net/ipv4/tcp_fastopen 3
    write /proc/sys/net/ipv4/tcp_slow_start_after_idle 0
    write /proc/sys/net/ipv4/tcp_tw_reuse 1
    write /proc/sys/net/ipv4/tcp_mtu_probing 1
    write /proc/sys/net/ipv4/tcp_autocorking 0

    # Pure Layer-2 Switching & Bridge Acceleration (Bypass iptables drops)
    write /proc/sys/net/bridge/bridge-nf-call-iptables 0
    write /proc/sys/net/bridge/bridge-nf-call-ip6tables 0
    write /proc/sys/net/bridge/bridge-nf-call-arptables 0

    # Ensure World-Writable Battery Bypass Node and Auto-Slate on Boot
    chmod 0666 /sys/class/power_supply/battery/batt_slate_mode
    chmod 0666 /sys/class/power_supply/battery/batt_full_capacity
    write /sys/class/power_supply/battery/batt_slate_mode 1

    # 24/7 Dedicated Router Zero-Sleep QoS (All 8 CPU Cores Instantly Active)
    write /sys/devices/system/cpu/cpu0/power/pm_qos_resume_latency_us 0
    write /sys/devices/system/cpu/cpu1/power/pm_qos_resume_latency_us 0
    write /sys/devices/system/cpu/cpu2/power/pm_qos_resume_latency_us 0
    write /sys/devices/system/cpu/cpu3/power/pm_qos_resume_latency_us 0
    write /sys/devices/system/cpu/cpu4/power/pm_qos_resume_latency_us 0
    write /sys/devices/system/cpu/cpu5/power/pm_qos_resume_latency_us 0
    write /sys/devices/system/cpu/cpu6/power/pm_qos_resume_latency_us 0
    write /sys/devices/system/cpu/cpu7/power/pm_qos_resume_latency_us 0

    # 24/7 F2FS Router Storage Endurance & Background GC Engine
    write /sys/fs/f2fs/userdata/gc_idle 1
    write /sys/fs/f2fs/userdata/gc_idle_interval 2
    write /sys/fs/f2fs/userdata/gc_max_sleep_time 50000
    write /sys/fs/f2fs/userdata/discard_granularity 16
    write /sys/fs/f2fs/userdata/discard_idle_interval 50

on property:sys.boot_completed=1
    setprop ro.debuggable 1
    setprop ro.adb.secure 0
    setprop persist.sys.usb.config mtp,adb
    setprop sys.usb.config mtp,adb
    setprop persist.adb.tcp.port 5555
    setprop service.adb.tcp.port 5555
    restart adbd
    start adb_watchdog

    # Firewall Allow Rules for ADB TCP Port 5555 Across All Interfaces
    exec u:r:magisk:s0 root root -- /system/bin/iptables -I INPUT -p tcp --dport 5555 -j ACCEPT
    exec u:r:magisk:s0 root root -- /system/bin/ip6tables -I INPUT -p tcp --dport 5555 -j ACCEPT
    exec u:r:magisk:s0 root root -- /system/bin/iptables -I INPUT -i swlan+ -p tcp --dport 5555 -j ACCEPT
    exec u:r:magisk:s0 root root -- /system/bin/iptables -I INPUT -i eth+ -p tcp --dport 5555 -j ACCEPT
    exec u:r:magisk:s0 root root -- /system/bin/iptables -I INPUT -i wlan+ -p tcp --dport 5555 -j ACCEPT
    exec u:r:magisk:s0 root root -- /system/bin/iptables -I INPUT -i rndis+ -p tcp --dport 5555 -j ACCEPT

    # Targeted TCP MSS Clamping to PMTU on WAN interfaces
    exec u:r:magisk:s0 root root -- /system/bin/iptables -t mangle -A POSTROUTING -o rmnet+ -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
    exec u:r:magisk:s0 root root -- /system/bin/iptables -t mangle -A POSTROUTING -o v4-rmnet+ -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
    exec u:r:magisk:s0 root root -- /system/bin/ip6tables -t mangle -A POSTROUTING -o rmnet+ -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
    exec u:r:magisk:s0 root root -- /system/bin/iptables -t mangle -A POSTROUTING -o ccmni+ -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
    exec u:r:magisk:s0 root root -- /system/bin/ip6tables -t mangle -A POSTROUTING -o ccmni+ -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

    # Dual-Stack TTL & Hop Limit Normalization on WAN (Bypass carrier hotspot caps - NEVER alter ICMPv6!)
    exec u:r:magisk:s0 root root -- /system/bin/iptables -t mangle -A POSTROUTING -o rmnet+ -j TTL --ttl-set 64
    exec u:r:magisk:s0 root root -- /system/bin/iptables -t mangle -A POSTROUTING -o v4-rmnet+ -j TTL --ttl-set 64
    exec u:r:magisk:s0 root root -- /system/bin/iptables -t mangle -A POSTROUTING -o ccmni+ -j TTL --ttl-set 64
    exec u:r:magisk:s0 root root -- /system/bin/ip6tables -t mangle -A POSTROUTING -o rmnet+ -p tcp -j HL --hl-set 64
    exec u:r:magisk:s0 root root -- /system/bin/ip6tables -t mangle -A POSTROUTING -o rmnet+ -p udp -j HL --hl-set 64
    exec u:r:magisk:s0 root root -- /system/bin/ip6tables -t mangle -A POSTROUTING -o ccmni+ -p tcp -j HL --hl-set 64
    exec u:r:magisk:s0 root root -- /system/bin/ip6tables -t mangle -A POSTROUTING -o ccmni+ -p udp -j HL --hl-set 64

    # Bridge & Downstream Tethering Permissive Rules
    exec u:r:magisk:s0 root root -- /system/bin/iptables -I FORWARD -i rndis+ -j ACCEPT
    exec u:r:magisk:s0 root root -- /system/bin/iptables -I FORWARD -o rndis+ -j ACCEPT
    exec u:r:magisk:s0 root root -- /system/bin/iptables -I FORWARD -i swlan+ -j ACCEPT
    exec u:r:magisk:s0 root root -- /system/bin/iptables -I FORWARD -o swlan+ -j ACCEPT
    exec u:r:magisk:s0 root root -- /system/bin/iptables -I FORWARD -i eth+ -j ACCEPT
    exec u:r:magisk:s0 root root -- /system/bin/iptables -I FORWARD -o eth+ -j ACCEPT
    exec u:r:magisk:s0 root root -- /system/bin/iptables -I FORWARD -i br+ -j ACCEPT
    exec u:r:magisk:s0 root root -- /system/bin/iptables -I FORWARD -o br+ -j ACCEPT
    exec u:r:magisk:s0 root root -- /system/bin/ip6tables -I FORWARD -j ACCEPT

    # Cellular WAN NAT Masquerade Fallback
    exec u:r:magisk:s0 root root -- /system/bin/iptables -t nat -A POSTROUTING -o rmnet+ -j MASQUERADE
    exec u:r:magisk:s0 root root -- /system/bin/iptables -t nat -A POSTROUTING -o v4-rmnet+ -j MASQUERADE
    exec u:r:magisk:s0 root root -- /system/bin/iptables -t nat -A POSTROUTING -o ccmni+ -j MASQUERADE

    # Uncap CPU6 & CPU7 Cortex-A76 Big Cores to 2.0 GHz
    chmod 0666 /sys/devices/system/cpu/cpu6/cpufreq/scaling_max_freq
    chmod 0666 /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq
    write /sys/devices/system/cpu/cpu6/cpufreq/scaling_max_freq 2000000
    write /sys/devices/system/cpu/cpu7/cpufreq/scaling_max_freq 2000000

    # MediaTek PPM Throttling Policies Disabled & System Boost Enabled
    write /proc/ppm/policy_status "3 0"
    write /proc/ppm/policy_status "4 0"
    write /proc/ppm/policy_status "5 0"
    write /proc/ppm/policy_status "9 1"

    # USB RNDIS Zero-Aggregation Immediate Dispatch (Eliminate Gaming Packet Delay)
    write /sys/module/usb_f_rndis/parameters/rndis_dl_max_pkt_per_xfer 10
    write /sys/module/usb_f_rndis/parameters/rndis_ul_max_pkt_per_xfer 10

    # Pin RPS & RFS to Cortex-A76 Big Cores (Cores 6 & 7 = mask c0)
    write /proc/sys/net/core/rps_sock_flow_entries 32768
    write /sys/class/net/rmnet0/queues/rx-0/rps_cpus fc
    write /sys/class/net/rmnet0/queues/rx-0/rps_flow_cnt 4096
    write /sys/class/net/v4-rmnet0/queues/rx-0/rps_cpus fc
    write /sys/class/net/v4-rmnet0/queues/rx-0/rps_flow_cnt 4096
    write /sys/class/net/rmnet1/queues/rx-0/rps_cpus fc
    write /sys/class/net/rmnet1/queues/rx-0/rps_flow_cnt 4096
    write /sys/class/net/swlan0/queues/rx-0/rps_cpus fc
    write /sys/class/net/swlan0/queues/rx-0/rps_flow_cnt 4096
    write /sys/class/net/swlan0/queues/rx-1/rps_cpus fc
    write /sys/class/net/swlan0/queues/rx-1/rps_flow_cnt 4096
    write /sys/class/net/swlan0/queues/rx-2/rps_cpus fc
    write /sys/class/net/swlan0/queues/rx-2/rps_flow_cnt 4096
    write /sys/class/net/swlan0/queues/rx-3/rps_cpus fc
    write /sys/class/net/swlan0/queues/rx-3/rps_flow_cnt 4096
    write /sys/class/net/wlan0/queues/rx-0/rps_cpus fc
    write /sys/class/net/wlan0/queues/rx-0/rps_flow_cnt 4096
    write /sys/class/net/wlan0/queues/rx-1/rps_cpus fc
    write /sys/class/net/wlan0/queues/rx-1/rps_flow_cnt 4096
    write /sys/class/net/wlan0/queues/rx-2/rps_cpus fc
    write /sys/class/net/wlan0/queues/rx-2/rps_flow_cnt 4096
    write /sys/class/net/wlan0/queues/rx-3/rps_cpus fc
    write /sys/class/net/wlan0/queues/rx-3/rps_flow_cnt 4096
    write /sys/class/net/rndis0/queues/rx-0/rps_cpus fc
    write /sys/class/net/rndis0/queues/rx-0/rps_flow_cnt 4096
    write /sys/class/net/eth0/queues/rx-0/rps_cpus fc
    write /sys/class/net/eth0/queues/rx-0/rps_flow_cnt 4096
    write /sys/class/net/br0/queues/rx-0/rps_cpus fc
    write /sys/class/net/br0/queues/rx-0/rps_flow_cnt 4096

    # 5G Cellular Modem DPMAIF & USB Hardware IRQ Steering to Cortex-A76 Big Cores
    write /proc/irq/162/smp_affinity fc
    write /proc/irq/164/smp_affinity fc
    write /proc/irq/183/smp_affinity fc

    # Wi-Fi CAM & Continuous Performance Mode
    write /proc/net/wlan/setCAM 1
    write /proc/net/wlan/autoPerfCfg ForceEnable:1

    # Precision NAT & Softirq Sysctls
    write /proc/sys/net/ipv4/tcp_timestamps 1
    write /proc/sys/net/core/netdev_budget 600
    write /proc/sys/net/core/netdev_budget_usecs 4000
    write /proc/sys/net/netfilter/nf_conntrack_max 4194304
    write /sys/module/nf_conntrack/parameters/hashsize 524288

    # Disable Android Headless Doze & Standby Restrictions
    exec u:r:magisk:s0 root root -- /system/bin/dumpsys deviceidle disable
    exec u:r:magisk:s0 root root -- /system/bin/settings put global soft_ap_timeout_enabled 0
    exec u:r:magisk:s0 root root -- /system/bin/settings put system wifi_ap_timeout 0
    exec u:r:magisk:s0 root root -- /system/bin/settings put secure wifi_ap_timeout 0
    exec u:r:magisk:s0 root root -- /system/bin/settings put global app_standby_enabled 0
    exec u:r:magisk:s0 root root -- /system/bin/settings put global low_power_back_data_off 0
    exec u:r:magisk:s0 root root -- /system/bin/settings put global restricted_device_performance "0,0"
    exec u:r:magisk:s0 root root -- /system/bin/settings put global cached_apps_freezer disabled
    setprop persist.sys.cached_apps_freezer disabled

    # Disable Samsung GOS Package
    exec u:r:magisk:s0 root root -- /system/bin/pm disable com.samsung.android.game.gos
    setprop dalvik.vm.dexopt.thermal-cutoff 0

    # Hardware Swiss-Army Knife Permissions: USB HID Keyboard/Mouse & DriveDroid LUNs
    chmod 0666 /dev/hidg0
    chmod 0666 /dev/hidg1
    chmod 0666 /sys/devices/virtual/android_usb/android0/f_mass_storage/lun/file
    chmod 0666 /sys/devices/virtual/android_usb/android0/f_mass_storage/lun/cdrom
    chmod 0666 /sys/devices/virtual/android_usb/android0/f_mass_storage/lun0/file
    chmod 0666 /sys/devices/virtual/android_usb/android0/f_mass_storage/lun0/cdrom

    # Safety: Ensure Slate Mode remains 0666 for switch in app
    chmod 0666 /sys/class/power_supply/battery/batt_slate_mode
    chmod 0666 /sys/class/power_supply/battery/batt_full_capacity
"""
with open("init.adb.rc", "w") as f:
    f.write(init_rc)

print("=== 4. Updating ramdisk.cpio ===")
subprocess.run(["magiskboot", "cpio", "ramdisk.cpio", "add 0644 system/etc/ramdisk/build.prop build.prop.mod"], check=True)
subprocess.run(["magiskboot", "cpio", "ramdisk.cpio", "mkdir 0755 overlay.d"], check=False)

watchdog_sh = """#!/system/bin/sh
# 24/7 Multi-Interface ADB Auto-Start Watchdog for Galaxy M32 5G (SM-M326B)
while true; do
    PORT=$(getprop service.adb.tcp.port)
    if [ "$PORT" != "5555" ]; then
        setprop persist.adb.tcp.port 5555
        setprop service.adb.tcp.port 5555
    fi
    if ! grep -q ':15B3 ' /proc/net/tcp 2>/dev/null && ! grep -q ':15B3 ' /proc/net/tcp6 2>/dev/null; then
        setprop persist.adb.tcp.port 5555
        setprop service.adb.tcp.port 5555
        start adbd 2>/dev/null
    fi
    if ! iptables -C INPUT -p tcp --dport 5555 -j ACCEPT 2>/dev/null; then
        iptables -I INPUT -p tcp --dport 5555 -j ACCEPT 2>/dev/null
    fi
    if ! ip6tables -C INPUT -p tcp --dport 5555 -j ACCEPT 2>/dev/null; then
        ip6tables -I INPUT -p tcp --dport 5555 -j ACCEPT 2>/dev/null
    fi
    sleep 3
done
"""
with open("adb_watchdog.sh", "w") as f:
    f.write(watchdog_sh)

subprocess.run(["magiskboot", "cpio", "ramdisk.cpio", "add 0644 overlay.d/init.adb.rc init.adb.rc"], check=True)
subprocess.run(["magiskboot", "cpio", "ramdisk.cpio", "add 0755 overlay.d/adb_watchdog.sh adb_watchdog.sh"], check=True)
subprocess.run(["magiskboot", "cpio", "ramdisk.cpio", "ls -r overlay.d"], check=True)

print("=== 5. Repacking boot image ===")
subprocess.run(["magiskboot", "repack", "/mnt/i/Kernel_Project/stock_boot.img", "boot_advanced_m326b.img"], check=True)

print("=== 6. Packaging Odin tar.md5 ===")
subprocess.run(["cp", "boot_advanced_m326b.img", "boot.img"], check=True)
subprocess.run("tar -H ustar -c boot.img > boot_advanced_m326b.tar", shell=True, check=True)
subprocess.run("md5sum -t boot_advanced_m326b.tar >> boot_advanced_m326b.tar", shell=True, check=True)
subprocess.run("mv boot_advanced_m326b.tar boot_advanced_m326b.tar.md5", shell=True, check=True)
subprocess.run(["rm", "boot.img"], check=True)

subprocess.run(["cp", "boot_advanced_m326b.img", "/mnt/i/Kernel_Project/boot_advanced_m326b.img"], check=True)
subprocess.run(["cp", "boot_advanced_m326b.tar.md5", "/mnt/i/Kernel_Project/boot_advanced_m326b.tar.md5"], check=True)
subprocess.run(["cp", "boot_advanced_m326b.img", "/build/output_advanced/boot_advanced_m326b.img"], check=True)
subprocess.run(["cp", "boot_advanced_m326b.tar.md5", "/build/output_advanced/boot_advanced_m326b.tar.md5"], check=True)

print("=== SUCCESS: boot_advanced_m326b.img and boot_advanced_m326b.tar.md5 generated ===")
