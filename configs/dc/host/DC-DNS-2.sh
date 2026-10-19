# debian (GNS3 DNS 템플릿)
#
# hostname
echo dc-dns-2 > /etc/hostname
hostname -F /etc/hostname
#
# interfaces (고정 주소, 재시작 후에도 유지)
echo 'auto eth0' > /etc/network/interfaces
echo 'iface eth0 inet static' >> /etc/network/interfaces
echo '    address 10.2.50.11' >> /etc/network/interfaces
echo '    netmask 255.255.255.0' >> /etc/network/interfaces
echo '    gateway 10.2.50.1' >> /etc/network/interfaces
#
# 주소 즉시 적용
ifconfig eth0 10.2.50.11 netmask 255.255.255.0 up
route add default gw 10.2.50.1
#
# dnsmasq.conf (기본 파일은 .orig로 보관)
cp -n /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
echo 'port=53' > /etc/dnsmasq.conf
echo 'listen-address=10.2.50.11' >> /etc/dnsmasq.conf
echo 'bind-interfaces' >> /etc/dnsmasq.conf
echo 'no-resolv' >> /etc/dnsmasq.conf
echo 'no-hosts' >> /etc/dnsmasq.conf
echo 'domain=lab.local' >> /etc/dnsmasq.conf
echo 'local=/lab.local/' >> /etc/dnsmasq.conf
echo 'expand-hosts' >> /etc/dnsmasq.conf
echo 'addn-hosts=/etc/hosts.lab' >> /etc/dnsmasq.conf
echo 'log-queries' >> /etc/dnsmasq.conf
echo 'log-facility=/var/log/dnsmasq.log' >> /etc/dnsmasq.conf
#
# hosts.lab (레코드 31개)
echo '11.11.11.1 hq-r1.lab.local hq-r1' > /etc/hosts.lab
echo '11.11.11.2 hq-r2.lab.local hq-r2' >> /etc/hosts.lab
echo '11.11.11.12 hq-sw-2.lab.local hq-sw-2' >> /etc/hosts.lab
echo '11.11.11.13 hq-sw-3.lab.local hq-sw-3' >> /etc/hosts.lab
echo '10.10.10.1 dc-r1.lab.local dc-r1' >> /etc/hosts.lab
echo '10.10.10.2 dc-r2.lab.local dc-r2' >> /etc/hosts.lab
echo '10.10.10.3 dc-r3.lab.local dc-r3' >> /etc/hosts.lab
echo '10.10.10.4 dc-r4.lab.local dc-r4' >> /etc/hosts.lab
echo '10.10.10.11 dc-sw1-l3.lab.local dc-sw1-l3' >> /etc/hosts.lab
echo '10.10.10.12 dc-sw2-l3.lab.local dc-sw2-l3' >> /etc/hosts.lab
echo '10.10.10.13 dc-sw3-l3.lab.local dc-sw3-l3' >> /etc/hosts.lab
echo '10.10.10.14 dc-sw4-l3.lab.local dc-sw4-l3' >> /etc/hosts.lab
echo '12.12.12.1 br1-r1.lab.local br1-r1' >> /etc/hosts.lab
echo '12.12.12.2 br1-r2.lab.local br1-r2' >> /etc/hosts.lab
echo '12.12.12.11 br1-sw1-l3.lab.local br1-sw1-l3' >> /etc/hosts.lab
echo '12.12.12.12 br1-sw2-l3.lab.local br1-sw2-l3' >> /etc/hosts.lab
echo '13.13.13.1 br2-r1.lab.local br2-r1' >> /etc/hosts.lab
echo '13.13.13.2 br2-r2.lab.local br2-r2' >> /etc/hosts.lab
echo '13.13.13.11 br2-sw1-l3.lab.local br2-sw1-l3' >> /etc/hosts.lab
echo '13.13.13.12 br2-sw2-l3.lab.local br2-sw2-l3' >> /etc/hosts.lab
echo '2.2.2.2 private-net.lab.local private-net' >> /etc/hosts.lab
echo '100.100.100.1 isp-1-pe-a.lab.local isp-1-pe-a' >> /etc/hosts.lab
echo '100.100.100.2 isp-1-p1.lab.local isp-1-p1' >> /etc/hosts.lab
echo '100.100.100.3 isp-1-p2.lab.local isp-1-p2' >> /etc/hosts.lab
echo '100.100.100.4 isp-1-pe-b.lab.local isp-1-pe-b' >> /etc/hosts.lab
echo '200.200.200.1 isp-2-pe-a.lab.local isp-2-pe-a' >> /etc/hosts.lab
echo '200.200.200.2 isp-2-p1.lab.local isp-2-p1' >> /etc/hosts.lab
echo '200.200.200.3 isp-2-p2.lab.local isp-2-p2' >> /etc/hosts.lab
echo '200.200.200.4 isp-2-pe-b.lab.local isp-2-pe-b' >> /etc/hosts.lab
echo '10.2.50.10 dc-dns-1.lab.local dc-dns-1' >> /etc/hosts.lab
echo '10.2.50.11 dc-dns-2.lab.local dc-dns-2' >> /etc/hosts.lab
#
# dnsmasq 재시작
service dnsmasq restart < /dev/null
sleep 2
#
# 검증
cat /etc/hostname
cat /etc/network/interfaces
ifconfig eth0
route -n
cat /etc/dnsmasq.conf
cat /etc/hosts.lab
service dnsmasq status
netstat -lun | grep :53
nslookup dc-r1.lab.local 10.2.50.11
tail -n 10 /var/log/dnsmasq.log
