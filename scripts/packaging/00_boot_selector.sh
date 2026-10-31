#!/system/bin/sh
# ==============================================================================
# 00_boot_selector.sh - Dedicated Hardware Router Kiosk & ADB Root Engine
# Samsung Galaxy M32 5G (MT6853 Dimensity 720)
# ==============================================================================

FLAG_FILE="/data/adb/router_mode.flag"

# 1. ALWAYS Enforce ADB Root on TCP Port 5555 & USB at early boot
setprop service.adb.tcp.port 5555
setprop persist.adb.tcp.port 5555
setprop persist.sys.usb.config mtp,adb
setprop sys.usb.config mtp,adb
start adbd 2>/dev/null

# 2. Check if router mode flag exists (Default to 1 for Dedicated Router Kiosk)
if [ ! -f "$FLAG_FILE" ]; then
    echo "1" > "$FLAG_FILE"
fi

MODE=$(cat "$FLAG_FILE" 2>/dev/null)

# 3. Hardware Key Detection at Early Boot (3-second window)
# Hold Vol+ -> Force Router Mode
# Hold Vol- -> Force Android Mode
if [ -c "/dev/input/event2" ]; then
    TIMEOUT=3
    while [ $TIMEOUT -gt 0 ]; do
        if timeout 1 getevent -c 1 /dev/input/event2 2>/dev/null | grep -q "0073"; then
            MODE="1"
            echo "1" > "$FLAG_FILE"
            break
        elif timeout 1 getevent -c 1 /dev/input/event2 2>/dev/null | grep -q "0072"; then
            MODE="0"
            echo "0" > "$FLAG_FILE"
            break
        fi
        TIMEOUT=$((TIMEOUT - 1))
    done
fi

setprop persist.galaxy.router_mode "$MODE"

# 4. Asynchronous Boot-Completion Actions
(
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        sleep 1
    done

    # Re-verify ADB Port 5555 is listening after boot_completed
    setprop service.adb.tcp.port 5555
    start adbd 2>/dev/null

    if [ "$MODE" = "1" ]; then
        # === DEDICATED HARDWARE ROUTER KIOSK (SCREEN ON, ANDROID LOCKED OUT) ===
        echo "[ROUTER_KIOSK] Initializing Dedicated Hardware Router Kiosk..."

        # Bypass & dismiss Samsung lock screen completely
        locksettings set-disabled true 2>/dev/null
        wm dismiss-keyguard 2>/dev/null
        input keyevent 82 2>/dev/null

        # Keep Display Permanently Awake
        svc power stayon true 2>/dev/null

        # Permanently hide system bars (status bar, navigation bar, notifications)
        settings put global policy_control immersive.full=* 2>/dev/null

        # Suspend Android background bloat (GMS, Bixby, telemetry, phone dialer)
        for pkg in com.google.android.gms com.google.android.gsf com.google.android.apps.messaging com.samsung.android.bixby.agent com.samsung.android.bixby.service com.samsung.android.dialer com.samsung.android.messaging com.sec.android.app.sbrowser com.facebook.katana com.samsung.android.game.gos; do
            pm suspend $pkg 2>/dev/null
        done

        # Start Smart Direct 5G Modem Gateway (v4)
        sh /data/adb/modem_gateway enable 2>/dev/null

        # Ensure Cross-LAN routing and proxy ARP are active
        echo 1 > /proc/sys/net/ipv4/ip_forward 2>/dev/null
        echo 1 > /proc/sys/net/ipv4/conf/all/forwarding 2>/dev/null
        echo 1 > /proc/sys/net/ipv4/conf/all/proxy_arp 2>/dev/null
        echo 1 > /proc/sys/net/ipv4/conf/swlan0/proxy_arp 2>/dev/null
        echo 1 > /proc/sys/net/ipv4/conf/eth0/proxy_arp 2>/dev/null

        # Priority local subnet routing rules
        ip rule del pref 20500 2>/dev/null || true
        ip rule del pref 20501 2>/dev/null || true
        ip rule del pref 20502 2>/dev/null || true
        ip rule add pref 20500 from all to 10.179.108.0/24 lookup main
        ip rule add pref 20501 from all to 10.253.28.0/24 lookup main
        ip rule add pref 20502 from all to 192.168.0.0/16 lookup main

        # Inter-interface forwarding rules
        iptables -C FORWARD -i swlan0 -j ACCEPT 2>/dev/null || iptables -w 2 -I FORWARD 1 -i swlan0 -j ACCEPT 2>/dev/null || true
        iptables -C FORWARD -o swlan0 -j ACCEPT 2>/dev/null || iptables -w 2 -I FORWARD 1 -o swlan0 -j ACCEPT 2>/dev/null || true
        iptables -C FORWARD -i eth0 -j ACCEPT 2>/dev/null || iptables -w 2 -I FORWARD 1 -i eth0 -j ACCEPT 2>/dev/null || true
        iptables -C FORWARD -o eth0 -j ACCEPT 2>/dev/null || iptables -w 2 -I FORWARD 1 -o eth0 -j ACCEPT 2>/dev/null || true

        # Start Universal Cross-LAN Reflector daemon
        if [ -x "/data/adb/universal_lan_reflector" ]; then
            killall -9 universal_lan_reflector 2>/dev/null || true
            nohup /data/adb/universal_lan_reflector > /data/local/tmp/reflector.log 2>&1 &
        fi

        # Ensure ADB Root is listening on 5555 and USB
        setprop service.adb.tcp.port 5555
        start adbd 2>/dev/null

        # Launch Dedicated Router Console Screen in Immersive Fullscreen Kiosk
        sleep 1
        am start -n com.galaxynetmaster/.ui.screens.RouterConsoleActivity --activity-clear-top 2>/dev/null

        # Second dismissal pass to guarantee lockscreen is cleared
        sleep 2
        wm dismiss-keyguard 2>/dev/null
        input keyevent 82 2>/dev/null
        am start -n com.galaxynetmaster/.ui.screens.RouterConsoleActivity --activity-clear-top 2>/dev/null
    else
        # === FULL ANDROID ONE UI MODE ===
        echo "[ROUTER_MODE] Starting Full Android One UI Mode..."
        locksettings set-disabled false 2>/dev/null
        settings put global policy_control null 2>/dev/null
        svc power stayon false 2>/dev/null

        # Unsuspend any suspended packages
        for pkg in com.google.android.gms com.google.android.gsf com.google.android.apps.messaging com.samsung.android.bixby.agent com.samsung.android.bixby.service com.samsung.android.dialer com.samsung.android.messaging com.sec.android.app.sbrowser com.facebook.katana com.samsung.android.game.gos; do
            pm unsuspend $pkg 2>/dev/null
        done

        # Re-check ADB is ready
        setprop service.adb.tcp.port 5555
        start adbd 2>/dev/null
    fi
) &

exit 0
