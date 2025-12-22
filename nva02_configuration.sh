# nva02 config
apt-get update
apt-get install bird -y
sed -ir 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sysctl -p
ip link add vxlan-blue type vxlan id 100 local 10.2.0.200 remote 10.1.0.200 dstport 4789 dev eth0
ip link set vxlan-blue up
ip route add 172.16.0.0/24 dev vxlan-blue
ip addr add 172.16.0.21/24 dev vxlan-blue

cat > "/etc/bird/bird.conf" <<EOL
# This is a minimal configuration file, which allows the bird daemon to start
# but will not cause anything else to happen.
#
# Please refer to the documentation in the bird-doc package or BIRD User's
# Guide on http://bird.network.cz/ for more information on configuring BIRD and
# adding routing protocols.

# Change this into your BIRD router ID. It's a world-wide unique identification
# of your router, usually one of router's IPv4 addresses.
router id 10.2.0.4;

# The Kernel protocol is not a real routing protocol. Instead of communicating
# with other routers in the network, it performs synchronization of BIRD's
# routing tables with the OS kernel.
protocol kernel {
        scan time 60;
        import none;
        export all;   # Actually insert routes into the kernel routing table
}

# The Device protocol is not a real routing protocol. It doesn't generate any
# routes and it only serves as a module for getting information about network
# interfaces from the kernel.
protocol device {
        scan time 60;
}

protocol direct {
        interface "eth0";
        interface "vxlan-blue";
}

protocol static {
        route 10.2.0.132/32 via 10.2.0.1;
        route 10.2.0.133/32 via 10.2.0.1;
}

filter default_export {
        if net ~ [
            10.2.0.132/32,
            10.2.0.133/32,
            172.16.0.0/24
        ] then reject;
        if bgp_path ~ [ 65515 ] then
            bgp_path.delete(65515);
        accept;
}

protocol bgp azurerouteserverinstanceprimary {
      router id 10.2.0.4;
      local 10.2.0.4 as 65502;
      neighbor 10.2.0.133 as 65515;
      multihop;
      next hop self;
      keepalive time 60;
      hold time 180;
      import filter {
         if net = 10.2.0.0/24 then reject;
         else accept;
      };
      export filter default_export;
      enable route refresh on;
}

protocol bgp azurerouteserverinstancesecondary {
      router id 10.2.0.4;
      local 10.2.0.4 as 65502;
      neighbor 10.2.0.132 as 65515;
      multihop;
      next hop self;
      keepalive time 60;
      hold time 180;
      import filter {
         if net = 10.2.0.0/24 then reject;
         else accept;
      };
      export filter default_export;
      enable route refresh on;
}

protocol bgp vxlanpeer {
      router id 10.2.0.4;
      local 172.16.0.21 as 65502;
      neighbor 172.16.0.11 as 65501;
      multihop;
      next hop self;
      keepalive time 60;
      hold time 180;
      import all;
      export filter default_export;
      enable route refresh on;
}
EOL

systemctl restart bird




# # vxlan02 delete config
# ip route del 172.16.0.0/24
# ip addr del 172.16.0.21/24 dev vxlan-blue
# ip link del vxlan-blue