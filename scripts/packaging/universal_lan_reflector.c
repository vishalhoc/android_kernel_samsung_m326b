#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <netinet/udp.h>
#include <arpa/inet.h>
#include <time.h>

#define MAX_IFACES 8
#define BUF_SIZE 8192

// Targeted discovery ports
static const int DISCOVERY_PORTS[] = {1716, 5353, 1900, 137, 138};
#define NUM_PORTS (sizeof(DISCOVERY_PORTS) / sizeof(DISCOVERY_PORTS[0]))

typedef struct {
    char name[IFNAMSIZ];
    int ifindex;
    struct in_addr ip;
    struct in_addr bcast;
    int is_up;
} IfaceEntry;

static IfaceEntry g_ifaces[MAX_IFACES];
static int g_num_ifaces = 0;
static int g_raw_sock = -1;

// Ring buffer cache to prevent reflection loops
#define HASH_CACHE_SIZE 256
typedef struct {
    uint32_t hash;
    time_t seen;
} HashEntry;
static HashEntry g_hash_cache[HASH_CACHE_SIZE];
static int g_hash_idx = 0;

static uint32_t calc_pkt_hash(uint32_t src_ip, uint16_t src_port, const uint8_t *data, size_t len) {
    uint32_t h = 2166136261u;
    h = (h ^ src_ip) * 16777619u;
    h = (h ^ src_port) * 16777619u;
    for (size_t i = 0; i < len && i < 64; i++) {
        h = (h ^ data[i]) * 16777619u;
    }
    return h;
}

static int is_duplicate(uint32_t hash) {
    time_t now = time(NULL);
    for (int i = 0; i < HASH_CACHE_SIZE; i++) {
        if (g_hash_cache[i].hash == hash && (now - g_hash_cache[i].seen) < 3) {
            return 1; // Duplicate packet within 3 seconds
        }
    }
    g_hash_cache[g_hash_idx].hash = hash;
    g_hash_cache[g_hash_idx].seen = now;
    g_hash_idx = (g_hash_idx + 1) % HASH_CACHE_SIZE;
    return 0;
}

// Pseudo header for UDP checksum calculation
struct pseudo_hdr {
    uint32_t src;
    uint32_t dst;
    uint8_t zero;
    uint8_t proto;
    uint16_t len;
};

static uint16_t in_cksum(const void *data, size_t len) {
    const uint16_t *p = (const uint16_t *)data;
    uint32_t sum = 0;
    while (len > 1) {
        sum += *p++;
        len -= 2;
    }
    if (len == 1) {
        sum += *(const uint8_t *)p;
    }
    while (sum >> 16) {
        sum = (sum & 0xFFFF) + (sum >> 16);
    }
    return (uint16_t)(~sum);
}

static uint16_t udp_checksum(struct iphdr *ip, struct udphdr *udp, const uint8_t *payload, size_t payload_len) {
    size_t udp_len = sizeof(struct udphdr) + payload_len;
    size_t total_len = sizeof(struct pseudo_hdr) + udp_len;
    uint8_t *buf = (uint8_t *)malloc(total_len);
    if (!buf) return 0;

    struct pseudo_hdr *phdr = (struct pseudo_hdr *)buf;
    phdr->src = ip->saddr;
    phdr->dst = ip->daddr;
    phdr->zero = 0;
    phdr->proto = IPPROTO_UDP;
    phdr->len = htons(udp_len);

    memcpy(buf + sizeof(struct pseudo_hdr), udp, sizeof(struct udphdr));
    memcpy(buf + sizeof(struct pseudo_hdr) + sizeof(struct udphdr), payload, payload_len);

    uint16_t ck = in_cksum(buf, total_len);
    free(buf);
    return ck == 0 ? 0xFFFF : ck;
}

static void refresh_interfaces() {
    const char *candidates[] = {"eth0", "swlan0", "ap0", "rndis0", "usb0", "bt-pan"};
    int n_cands = sizeof(candidates) / sizeof(candidates[0]);
    int s = socket(AF_INET, SOCK_DGRAM, 0);
    if (s < 0) return;

    g_num_ifaces = 0;
    for (int i = 0; i < n_cands && g_num_ifaces < MAX_IFACES; i++) {
        struct ifreq ifr;
        memset(&ifr, 0, sizeof(ifr));
        strncpy(ifr.ifr_name, candidates[i], IFNAMSIZ - 1);

        if (ioctl(s, SIOCGIFFLAGS, &ifr) < 0) continue;
        if (!(ifr.ifr_flags & IFF_UP)) continue;

        struct ifreq req_addr;
        memset(&req_addr, 0, sizeof(req_addr));
        strncpy(req_addr.ifr_name, candidates[i], IFNAMSIZ - 1);
        if (ioctl(s, SIOCGIFADDR, &req_addr) < 0) continue;

        struct ifreq req_bcast;
        memset(&req_bcast, 0, sizeof(req_bcast));
        strncpy(req_bcast.ifr_name, candidates[i], IFNAMSIZ - 1);
        if (ioctl(s, SIOCGIFBRDADDR, &req_bcast) < 0) {
            // Default to /24 broadcast
            struct sockaddr_in *sin = (struct sockaddr_in *)&req_addr.ifr_addr;
            uint32_t ip_h = ntohl(sin->sin_addr.s_addr);
            struct in_addr bcast;
            bcast.s_addr = htonl((ip_h & 0xFFFFFF00) | 0xFF);
            g_ifaces[g_num_ifaces].bcast = bcast;
        } else {
            g_ifaces[g_num_ifaces].bcast = ((struct sockaddr_in *)&req_bcast.ifr_broadaddr)->sin_addr;
        }

        strncpy(g_ifaces[g_num_ifaces].name, candidates[i], IFNAMSIZ - 1);
        g_ifaces[g_num_ifaces].ip = ((struct sockaddr_in *)&req_addr.ifr_addr)->sin_addr;
        g_ifaces[g_num_ifaces].ifindex = if_nametoindex(candidates[i]);
        g_ifaces[g_num_ifaces].is_up = 1;

        printf("[IFACE] Active %s: ip=%s bcast=%s idx=%d\n",
               g_ifaces[g_num_ifaces].name,
               inet_ntoa(g_ifaces[g_num_ifaces].ip),
               inet_ntoa(g_ifaces[g_num_ifaces].bcast),
               g_ifaces[g_num_ifaces].ifindex);
        fflush(stdout);

        g_num_ifaces++;
    }
    close(s);
}

// Forward a received UDP packet preserving source IP to all other interfaces
static void reflect_packet(int in_ifindex, struct in_addr orig_src, uint16_t orig_port,
                           uint16_t dst_port, const uint8_t *payload, size_t payload_len) {
    if (g_raw_sock < 0) return;

    for (int i = 0; i < g_num_ifaces; i++) {
        if (g_ifaces[i].ifindex == in_ifindex) continue; // Don't echo back to originating interface
        if (!g_ifaces[i].is_up) continue;

        // Skip if sender was this interface's own IP
        if (orig_src.s_addr == g_ifaces[i].ip.s_addr) continue;

        // Construct Raw IP Packet: [IPv4 Header] + [UDP Header] + [Payload]
        size_t total_pkt_len = sizeof(struct iphdr) + sizeof(struct udphdr) + payload_len;
        uint8_t *pkt = (uint8_t *)malloc(total_pkt_len);
        if (!pkt) continue;

        struct iphdr *ip = (struct iphdr *)pkt;
        struct udphdr *udp = (struct udphdr *)(pkt + sizeof(struct iphdr));
        uint8_t *data = pkt + sizeof(struct iphdr) + sizeof(struct udphdr);

        // Fill IP Header
        ip->version = 4;
        ip->ihl = 5;
        ip->tos = 0;
        ip->tot_len = htons(total_pkt_len);
        ip->id = htons((uint16_t)rand());
        ip->frag_off = 0;
        ip->ttl = 64;
        ip->protocol = IPPROTO_UDP;
        ip->check = 0;
        ip->saddr = orig_src.s_addr; // ORIGINAL SENDER IP PRESERVED!
        ip->daddr = g_ifaces[i].bcast.s_addr; // Targeted Subnet Broadcast
        ip->check = in_cksum(ip, sizeof(struct iphdr));

        // Fill UDP Header
        udp->source = orig_port;
        udp->dest = htons(dst_port);
        udp->len = htons(sizeof(struct udphdr) + payload_len);
        udp->check = 0;
        memcpy(data, payload, payload_len);
        udp->check = udp_checksum(ip, udp, payload, payload_len);

        // Bind raw socket to target interface
        setsockopt(g_raw_sock, SOL_SOCKET, SO_BINDTODEVICE, g_ifaces[i].name, strlen(g_ifaces[i].name));

        struct sockaddr_in sin;
        memset(&sin, 0, sizeof(sin));
        sin.sin_family = AF_INET;
        sin.sin_addr = g_ifaces[i].bcast;
        sin.sin_port = htons(dst_port);

        sendto(g_raw_sock, pkt, total_pkt_len, 0, (struct sockaddr *)&sin, sizeof(sin));

        // Also send to 255.255.255.255
        ip->daddr = htonl(INADDR_BROADCAST);
        ip->check = 0;
        ip->check = in_cksum(ip, sizeof(struct iphdr));
        udp->check = 0;
        udp->check = udp_checksum(ip, udp, payload, payload_len);
        sin.sin_addr.s_addr = htonl(INADDR_BROADCAST);
        sendto(g_raw_sock, pkt, total_pkt_len, 0, (struct sockaddr *)&sin, sizeof(sin));

        // Also send unicast directly to known clients on this interface to defeat client sleep/broadcast filters
        FILE *farp = fopen("/proc/net/arp", "r");
        if (farp) {
            char line[256];
            while (fgets(line, sizeof(line), farp)) {
                char ip_str[32], dev_str[32], mac_str[32];
                int type, flags;
                if (sscanf(line, "%31s 0x%x 0x%x %31s %*s %31s", ip_str, &type, &flags, mac_str, dev_str) == 5) {
                    if (strcmp(dev_str, g_ifaces[i].name) == 0 && flags != 0 && strcmp(mac_str, "00:00:00:00:00:00") != 0) {
                        struct in_addr client_addr;
                        if (inet_aton(ip_str, &client_addr) != 0 && client_addr.s_addr != orig_src.s_addr) {
                            ip->daddr = client_addr.s_addr;
                            ip->check = 0;
                            ip->check = in_cksum(ip, sizeof(struct iphdr));
                            udp->check = 0;
                            udp->check = udp_checksum(ip, udp, payload, payload_len);
                            sin.sin_addr = client_addr;
                            sendto(g_raw_sock, pkt, total_pkt_len, 0, (struct sockaddr *)&sin, sizeof(sin));
                        }
                    }
                }
            }
            fclose(farp);
        }

        setsockopt(g_raw_sock, SOL_SOCKET, SO_BINDTODEVICE, "", 0);
        free(pkt);
    }
}

int main() {
    // Daemonize
    signal(SIGPIPE, SIG_IGN);

    // Create raw injection socket
    g_raw_sock = socket(AF_INET, SOCK_RAW, IPPROTO_RAW);
    if (g_raw_sock < 0) {
        perror("socket raw");
        return 1;
    }
    int one = 1;
    setsockopt(g_raw_sock, IPPROTO_IP, IP_HDRINCL, &one, sizeof(one));
    setsockopt(g_raw_sock, SOL_SOCKET, SO_BROADCAST, &one, sizeof(one));

    // Create listening sockets for all discovery ports
    int port_socks[NUM_PORTS];
    int max_fd = g_raw_sock;

    for (size_t p = 0; p < NUM_PORTS; p++) {
        int s = socket(AF_INET, SOCK_DGRAM, 0);
        if (s < 0) continue;
        setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &one, sizeof(one));
        setsockopt(s, SOL_SOCKET, SO_BROADCAST, &one, sizeof(one));
        setsockopt(s, IPPROTO_IP, IP_PKTINFO, &one, sizeof(one));

        struct sockaddr_in baddr;
        memset(&baddr, 0, sizeof(baddr));
        baddr.sin_family = AF_INET;
        baddr.sin_port = htons(DISCOVERY_PORTS[p]);
        baddr.sin_addr.s_addr = htonl(INADDR_ANY);

        if (bind(s, (struct sockaddr *)&baddr, sizeof(baddr)) < 0) {
            close(s);
            port_socks[p] = -1;
            continue;
        }

        // If multicast (mDNS 5353, SSDP 1900), join multicast groups
        if (DISCOVERY_PORTS[p] == 5353) {
            struct ip_mreq mreq;
            mreq.imr_multiaddr.s_addr = inet_addr("224.0.0.251");
            mreq.imr_interface.s_addr = htonl(INADDR_ANY);
            setsockopt(s, IPPROTO_IP, IP_ADD_MEMBERSHIP, &mreq, sizeof(mreq));
        } else if (DISCOVERY_PORTS[p] == 1900) {
            struct ip_mreq mreq;
            mreq.imr_multiaddr.s_addr = inet_addr("239.255.255.250");
            mreq.imr_interface.s_addr = htonl(INADDR_ANY);
            setsockopt(s, IPPROTO_IP, IP_ADD_MEMBERSHIP, &mreq, sizeof(mreq));
        }

        port_socks[p] = s;
        if (s > max_fd) max_fd = s;
    }

    refresh_interfaces();
    printf("Universal LAN Reflector running (PORTS: 1716, 5353, 1900, 137, 138)...\n");
    fflush(stdout);

    uint8_t buffer[BUF_SIZE];
    uint8_t cmsg_buf[256];
    int refresh_counter = 0;

    while (1) {
        if (++refresh_counter % 20 == 0) {
            refresh_interfaces();
        }

        fd_set fds;
        FD_ZERO(&fds);
        for (size_t p = 0; p < NUM_PORTS; p++) {
            if (port_socks[p] >= 0) FD_SET(port_socks[p], &fds);
        }

        struct timeval tv = {2, 0};
        int sel = select(max_fd + 1, &fds, NULL, NULL, &tv);
        if (sel <= 0) continue;

        for (size_t p = 0; p < NUM_PORTS; p++) {
            int s = port_socks[p];
            if (s < 0 || !FD_ISSET(s, &fds)) continue;

            struct sockaddr_in src_addr;
            struct iovec iov = {buffer, sizeof(buffer)};
            struct msghdr msg;
            memset(&msg, 0, sizeof(msg));
            msg.msg_name = &src_addr;
            msg.msg_namelen = sizeof(src_addr);
            msg.msg_iov = &iov;
            msg.msg_iovlen = 1;
            msg.msg_control = cmsg_buf;
            msg.msg_controllen = sizeof(cmsg_buf);

            ssize_t n = recvmsg(s, &msg, 0);
            if (n <= 0) continue;

            int in_ifindex = 0;
            for (struct cmsghdr *cmsg = CMSG_FIRSTHDR(&msg); cmsg; cmsg = CMSG_NXTHDR(&msg, cmsg)) {
                if (cmsg->cmsg_level == IPPROTO_IP && cmsg->cmsg_type == IP_PKTINFO) {
                    struct in_pktinfo *pi = (struct in_pktinfo *)CMSG_DATA(cmsg);
                    in_ifindex = pi->ipi_ifindex;
                    break;
                }
            }

            // Ignore packets sent by the router itself
            int is_local_router = 0;
            for (int i = 0; i < g_num_ifaces; i++) {
                if (src_addr.sin_addr.s_addr == g_ifaces[i].ip.s_addr) {
                    is_local_router = 1;
                    break;
                }
            }
            if (is_local_router) continue;

            // Check loop prevention hash cache
            uint32_t pkt_hash = calc_pkt_hash(src_addr.sin_addr.s_addr, src_addr.sin_port, buffer, (size_t)n);
            if (is_duplicate(pkt_hash)) continue;

            printf("[REFLECT] Port %d from %s:%d (len %zd, ifindex %d)\n",
                   DISCOVERY_PORTS[p], inet_ntoa(src_addr.sin_addr), ntohs(src_addr.sin_port), n, in_ifindex);
            fflush(stdout);

            reflect_packet(in_ifindex, src_addr.sin_addr, src_addr.sin_port,
                           DISCOVERY_PORTS[p], buffer, (size_t)n);
        }
    }

    close(g_raw_sock);
    return 0;
}
