import os
import re

kernel_src = "/build/kernel/samsung/m326b"
kernel_out = "/build/kernel_out"

print("=== 1. Backup .config ===")
cfg_path = os.path.join(kernel_out, ".config")
bak_path = os.path.join(kernel_out, ".config.bak_before_feature_pack")
with open(cfg_path, "r", encoding="utf-8") as f:
    orig_cfg = f.read()
with open(bak_path, "w", encoding="utf-8") as f:
    f.write(orig_cfg)
print(f"Backed up .config to {bak_path}")

print("=== 2. Updating cpufreq_schedutil.c down_rate_limit_us to 4000 ===")
sched_path = os.path.join(kernel_src, "kernel/sched/cpufreq_schedutil.c")
with open(sched_path, "r", encoding="utf-8") as f:
    sched_c = f.read()

target_down = "tunables->down_rate_limit_us = cpufreq_policy_transition_delay_us(policy);"
replacement_down = "tunables->down_rate_limit_us = 4000; /* GalaxyNetMaster 4ms Down Throttle */"
if target_down in sched_c:
    sched_c = sched_c.replace(target_down, replacement_down)
    with open(sched_path, "w", encoding="utf-8") as f:
        f.write(sched_c)
    print("Updated schedutil down_rate_limit_us to 4000!")
else:
    print("down_rate_limit_us already updated or target not matched")

print("=== 3. Updating syslimiter.c default disable to 1 ===")
syslim_path = os.path.join(kernel_src, "drivers/misc/mediatek/performance/syslimiter/syslimiter.c")
with open(syslim_path, "r", encoding="utf-8") as f:
    syslim_c = f.read()

target_syslim = "static int syslimiter_disable;"
replacement_syslim = "static int syslimiter_disable = 1; /* Disabled by default for unthrottled router mode */"
if target_syslim in syslim_c:
    syslim_c = syslim_c.replace(target_syslim, replacement_syslim)
    with open(syslim_path, "w", encoding="utf-8") as f:
        f.write(syslim_c)
    print("Updated syslimiter_disable default to 1!")
else:
    print("syslimiter_disable already updated or target not matched")

print("=== 4. Updating .config Feature Set ===")
feature_updates = {
    # 1. Carrier Tethering & Hotspot Quota Bypass
    "CONFIG_NETFILTER_XT_TARGET_HL": "y",
    "CONFIG_IP_NF_TARGET_TTL": "y",
    "CONFIG_IP6_NF_TARGET_HL": "y",
    "CONFIG_IP_NF_MATCH_TTL": "y",
    "CONFIG_IP6_NF_MATCH_HL": "y",

    # 2. Bridge & Ethernet Layer-2 Capabilities
    "CONFIG_BRIDGE": "y",
    "CONFIG_BRIDGE_NETFILTER": "y",
    "CONFIG_NETFILTER_XT_MATCH_PHYSDEV": "y",
    "CONFIG_NETFILTER_XT_TARGET_CHECKSUM": "y",
    "CONFIG_BRIDGE_NF_EBTABLES": "y",
    "CONFIG_BRIDGE_EBT_BROUTE": "y",
    "CONFIG_BRIDGE_EBT_T_FILTER": "y",
    "CONFIG_BRIDGE_EBT_T_NAT": "y",
    "CONFIG_BRIDGE_EBT_ARP": "y",
    "CONFIG_BRIDGE_EBT_IP": "y",
    "CONFIG_BRIDGE_EBT_IP6": "y",
    "CONFIG_BRIDGE_EBT_VLAN": "y",
    "CONFIG_BRIDGE_EBT_MARK": "y",
    "CONFIG_BRIDGE_EBT_MARK_T": "y",

    # 3. Advanced Routing, Multi-WAN, Multicast & Match Sets
    "CONFIG_IP_ROUTE_MULTIPATH": "y",
    "CONFIG_IP_MROUTE": "y",
    "CONFIG_IP_MROUTE_MULTIPLE_TABLES": "y",
    "CONFIG_IPV6_MROUTE": "y",
    "CONFIG_IPV6_MROUTE_MULTIPLE_TABLES": "y",
    "CONFIG_IP_SET": "y",
    "CONFIG_IP_SET_MAX": "256",
    "CONFIG_IP_SET_BITMAP_IP": "y",
    "CONFIG_IP_SET_BITMAP_IPMAC": "y",
    "CONFIG_IP_SET_BITMAP_PORT": "y",
    "CONFIG_IP_SET_HASH_IP": "y",
    "CONFIG_IP_SET_HASH_IPMARK": "y",
    "CONFIG_IP_SET_HASH_IPPORT": "y",
    "CONFIG_IP_SET_HASH_IPPORTIP": "y",
    "CONFIG_IP_SET_HASH_IPPORTNET": "y",
    "CONFIG_IP_SET_HASH_IPMAC": "y",
    "CONFIG_IP_SET_HASH_MAC": "y",
    "CONFIG_IP_SET_HASH_NETPORTNET": "y",
    "CONFIG_IP_SET_HASH_NET": "y",
    "CONFIG_IP_SET_HASH_NETNET": "y",
    "CONFIG_IP_SET_HASH_NETPORT": "y",
    "CONFIG_IP_SET_HASH_NETIFACE": "y",
    "CONFIG_IP_SET_LIST_SET": "y",
    "CONFIG_NETFILTER_XT_SET": "y",
    "CONFIG_NETFILTER_XT_TARGET_TEE": "y",
    "CONFIG_NETFILTER_XT_TARGET_DSCP": "y",
    "CONFIG_NETFILTER_XT_MATCH_DSCP": "y",
    "CONFIG_NETFILTER_XT_MATCH_STRING": "y",
    "CONFIG_NETFILTER_XT_MATCH_ADDRTYPE": "y",
    "CONFIG_NETFILTER_XT_MATCH_IPRANGE": "y",
    "CONFIG_IPVLAN": "y",
    "CONFIG_VXLAN": "y",
    "CONFIG_NET_IPGRE": "y",
    "CONFIG_NET_IPIP": "y",

    # 4. Universal USB Network Adapters & Dongles
    "CONFIG_USB_NET_RNDIS_HOST": "y",
    "CONFIG_USB_NET_CDC_MBIM": "y",
    "CONFIG_USB_NET_QMI_WWAN": "y",
    "CONFIG_USB_NET_DM9601": "y",
    "CONFIG_USB_NET_SR9700": "y",
    "CONFIG_USB_NET_SMSC75XX": "y",
    "CONFIG_USB_NET_LAN78XX": "y",
    "CONFIG_USB_NET_IPHETH": "y",
    "CONFIG_USB_NET_MCS7830": "y",
    "CONFIG_USB_NET_CDC_EEM": "y",

    # 5. TCP Congestion & Bufferbloat
    "CONFIG_TCP_CONG_WESTWOOD": "y",
    "CONFIG_TCP_CONG_HYBLA": "y",

    # 6. Containers, Namespaces & DroidSpaces
    "CONFIG_USER_NS": "y",
    "CONFIG_CGROUP_DEVICE": "y",
    "CONFIG_CGROUP_PIDS": "y",
    "CONFIG_CGROUP_FREEZER": "y",
    "CONFIG_MEMCG": "y",
    "CONFIG_MEMCG_SWAP": "y",
    "CONFIG_CFS_BANDWIDTH": "y",

    # 7. Network File Systems & Storage (24/7 NAS Mode)
    "CONFIG_CIFS": "y",
    "CONFIG_CIFS_SMB2": "y",
    "CONFIG_CIFS_SMB3": "y",
    "CONFIG_NFS_FS": "y",
    "CONFIG_NFS_V3": "y",
    "CONFIG_NFS_V4": "y",
    "CONFIG_NTFS_RW": "y",
}

lines = orig_cfg.splitlines()
new_lines = []
updated_keys = set()

for line in lines:
    matched = False
    for k in feature_updates:
        if line.startswith(k + "=") or line.startswith("# " + k + " "):
            val = feature_updates[k]
            if val.startswith('"') or val.isdigit() or val in ["y", "m"]:
                new_lines.append(f"{k}={val}")
            else:
                new_lines.append(f"{k}={val}")
            updated_keys.add(k)
            matched = True
            break
    if not matched:
        new_lines.append(line)

for k, val in feature_updates.items():
    if k not in updated_keys:
        new_lines.append(f"{k}={val}")
        print(f"Appended new config: {k}={val}")

with open(cfg_path, "w", encoding="utf-8") as f:
    f.write("\n".join(new_lines) + "\n")

print(f"Updated {len(feature_updates)} config symbols in {cfg_path}")
