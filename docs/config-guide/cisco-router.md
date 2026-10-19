# Cisco 라우터 설정 (7200)

> 설정 가이드 목차: [README.md](./README.md) | [Cisco 라우터](./cisco-router.md) | [Cisco 스위치](./cisco-switch.md) | [Arista 스위치](./arista-switch.md) | [Aruba 스위치](./aruba-switch.md) | [알파인](./alpine.md)

대상: `HQ-R*`, `DC-R*`, `BR*-R*`, `ISP-*`, `Private-net`. 인터페이스 이름은 `gi<슬롯>/0`.

### 3.1 기본

```
! cisco
!
hostname hq-r2
enable secret admin1234
no ip domain-lookup
service timestamps debug datetime msec
service timestamps log datetime msec
!
line con 0
 logging synchronous
 exec-timeout 0 0
line vty 0 4
 password admin1234
 login
!
int lo0
 ip addr 11.11.11.2 255.255.255.255
!
int gi0/0
 desc to hq-sw-2 gi1/0
 ip addr 10.1.0.5 255.255.255.252
 no sh
```

- 콘솔에서 `enable`, `configure terminal`로 설정 모드에 진입한 뒤 위 내용을 붙여 넣음(진입 명령은 파일에 기재하지 않음).
- 접속 설정(`enable secret`, `line vty`)은 모든 Cisco 장비에 같은 형식으로 적용. Arista는 `username admin secret admin1234`.
- 실습 환경이므로 접속 비밀번호는 `admin1234`로 통일하고 컨피그와 문서에 그대로 기재([README.md](./README.md) 7절).
- 물리 포트와 `po`(연결 상대와 포트)에는 `desc`를 입력하고 Cisco는 `no sh`를 명시. Arista는 포트가 기본 활성이므로 `no sh`를 입력하지 않음(EOS에서 `no sh`는 모호한 명령으로 거절됨). 가상 인터페이스(`lo0`)와 MGMT SVI(`vlan 100`, VLAN `name`으로 구분)는 `desc` 생략. 단, EtherChannel 멤버 포트는 `int range`로 묶어 범위에 `desc to <상대 장비> po<번호>`를 한 번만 입력(포트별 `desc`는 생략).

### 3.2 OSPF(사이트 프로세스)

```
router ospf 11
 router-id 11.11.11.2
 passive-interface lo0
!
int lo0
 ip ospf 11 area 1
int gi0/0
 ip ospf 11 area 1
 ip ospf network point-to-point
```

- 프로세스, Area, Router ID는 `docs/ospf-design.md` 2~3절의 표 값을 사용. 터널 인터페이스는 3.5절 참조.

### 3.3 사이트 엣지 eBGP(ISP 연결, 기본 경로 광고)

```
ip route 10.1.0.0 255.255.0.0 null0
ip prefix-list pl-site seq 5 permit 10.1.0.0/16
ip prefix-list pl-default seq 5 permit 0.0.0.0/0
route-map rm-isp-out permit 10
 match ip address prefix-list pl-site
route-map rm-isp-in permit 10
 match ip address prefix-list pl-default
!
router bgp 65001
 bgp router-id 11.11.11.2
 bgp log-neighbor-changes
 no auto-summary
 no synchronization
 neighbor 100.2.12.2 remote-as 65200
 neighbor 100.2.12.2 timers 3 9
 neighbor 100.2.12.2 route-map rm-isp-in in
 neighbor 100.2.12.2 route-map rm-isp-out out
 network 10.1.0.0 mask 255.255.0.0
!
router ospf 11
 default-information originate metric 200 metric-type 1
```

- 예시는 `HQ-R2`(ISP-2 연결). ISP-1 연결 라우터는 metric 100. 세션, AS, prefix-list는 `docs/bgp-design.md` 5~6절, metric은 `docs/ospf-design.md` 6절 표 값을 사용. `default-information originate`에 `always`를 붙이지 않아 BGP 기본 경로가 사라지면 광고도 철회됨.

### 3.4 ISP 라우터 OSPF, iBGP Route Reflector

```
! isp-1-pe-a (RR Client)
router ospf 1
 router-id 100.100.100.1
 passive-interface default
 no passive-interface gi0/0
 no passive-interface gi1/0
int lo0
 ip ospf 1 area 0
int gi0/0
 ip ospf 1 area 0
 ip ospf network point-to-point
int gi1/0
 ip ospf 1 area 0
 ip ospf network point-to-point
!
router bgp 65100
 bgp router-id 100.100.100.1
 bgp log-neighbor-changes
 no auto-summary
 no synchronization
 neighbor 100.100.100.2 remote-as 65100
 neighbor 100.100.100.2 update-source lo0
 neighbor 100.100.100.2 next-hop-self
 neighbor 100.100.100.2 timers 3 9
 neighbor 100.100.100.3 remote-as 65100
 neighbor 100.100.100.3 update-source lo0
 neighbor 100.100.100.3 next-hop-self
 neighbor 100.100.100.3 timers 3 9
```

```
! isp-1-p1 (Route Reflector)
router bgp 65100
 bgp router-id 100.100.100.2
 bgp cluster-id 1.1.1.1
 bgp log-neighbor-changes
 no auto-summary
 no synchronization
 neighbor 100.100.100.1 remote-as 65100
 neighbor 100.100.100.1 update-source lo0
 neighbor 100.100.100.1 route-reflector-client
 neighbor 100.100.100.1 timers 3 9
 neighbor 100.100.100.4 remote-as 65100
 neighbor 100.100.100.4 update-source lo0
 neighbor 100.100.100.4 route-reflector-client
 neighbor 100.100.100.4 timers 3 9
 neighbor 100.100.100.3 remote-as 65100
 neighbor 100.100.100.3 update-source lo0
 neighbor 100.100.100.3 timers 3 9
```

- 예시는 `ISP-1-PE-A`와 `ISP-1-P1`. AS, Loopback0, 세션, prefix-list는 `docs/bgp-design.md` 1~6절 표 값을 사용. P1, P2는 사이트 방향 링크가 없어 사이트 eBGP, `network` 구문 없음. 사이트 eBGP(PE)와 MPLS, VRF는 3.4-1절. PE의 OSPF 대상은 ISP 내부 링크(Gi0/0, Gi1/0)와 Loopback0이며 사이트 방향 링크는 제외. 7200은 포트마다 슬롯이 달라 `int range` 대신 포트별로 입력.

### 3.4-1 ISP MPLS L3VPN(LDP, VRF, vpnv4, PE 사이트 eBGP)

```
! isp-1-pe-a (PE)
ip prefix-list pl-hq-in seq 5 permit 10.1.0.0/16
ip prefix-list pl-dc-in seq 5 permit 10.2.0.0/16
ip prefix-list pl-deny-all seq 5 deny 0.0.0.0/0 le 32
!
ip vrf corp
 rd 65100:1
 route-target export 65100:1
 route-target import 65100:1
!
mpls label protocol ldp
mpls ldp router-id lo0 force
mpls label range 11000 11999
int gi0/0
 mpls ip
int gi1/0
 mpls ip
int gi2/0
 ip vrf forwarding corp
 ip addr 100.1.11.2 255.255.255.252
int gi3/0
 ip vrf forwarding corp
 ip addr 100.1.21.2 255.255.255.252
!
router bgp 65100
 address-family vpnv4
  neighbor 100.100.100.2 activate
  neighbor 100.100.100.2 send-community extended
  neighbor 100.100.100.3 activate
  neighbor 100.100.100.3 send-community extended
 exit-address-family
 address-family ipv4 vrf corp
  neighbor 100.1.11.1 remote-as 65001
  neighbor 100.1.11.1 activate
  neighbor 100.1.11.1 timers 3 9
  neighbor 100.1.11.1 prefix-list pl-hq-in in
  neighbor 100.1.11.1 prefix-list pl-deny-all out
  neighbor 100.1.11.1 default-originate
  neighbor 100.1.21.1 remote-as 65002
  neighbor 100.1.21.1 activate
  neighbor 100.1.21.1 timers 3 9
  neighbor 100.1.21.1 prefix-list pl-dc-in in
  neighbor 100.1.21.1 prefix-list pl-deny-all out
  neighbor 100.1.21.1 default-originate
 exit-address-family
```

```
! isp-1-p1 (P + RR)
mpls label protocol ldp
mpls ldp router-id lo0 force
mpls label range 12000 12999
int gi0/0
 mpls ip
int gi1/0
 mpls ip
int gi2/0
 mpls ip
!
router bgp 65100
 address-family vpnv4
  neighbor 100.100.100.1 activate
  neighbor 100.100.100.1 send-community extended
  neighbor 100.100.100.1 route-reflector-client
  neighbor 100.100.100.4 activate
  neighbor 100.100.100.4 send-community extended
  neighbor 100.100.100.4 route-reflector-client
  neighbor 100.100.100.3 activate
  neighbor 100.100.100.3 send-community extended
 exit-address-family
```

- 예시는 `ISP-1-PE-A`와 `ISP-1-P1`. VRF, RD/RT, 인터페이스는 `docs/mpls-design.md` 2~4절, 사이트 이웃과 prefix-list는 `docs/bgp-design.md` 5~6절 표 값을 사용. `ip vrf forwarding`을 입력하면 해당 포트의 IP가 지워지므로 `ip addr`를 다시 입력. `mpls label range`는 장비마다 `docs/mpls-design.md` 2절 표의 구간으로 입력(예시는 ISP-1-PE-A 11000 11999, ISP-1-P1 12000 12999). 설정 후 `clear ip bgp *`가 필요할 수 있음.

### 3.5 DMVPN(Hub와 Spoke)

```
crypto isakmp policy 10
 encryption aes 256
 hash sha
 authentication pre-share
 group 5
 lifetime 86400
crypto isakmp key dmvpn-hub address 0.0.0.0 0.0.0.0
crypto isakmp keepalive 10 3
crypto ipsec transform-set ts-aes256 esp-aes 256 esp-sha-hmac
 mode tunnel
crypto ipsec profile dmvpn-profile
 set transform-set ts-aes256
 set pfs group5
 set security-association lifetime seconds 3600
!
int tunnel0
 ip addr 172.16.0.13 255.255.255.0
 ip mtu 1400
 ip tcp adjust-mss 1360
 tunnel source gi4/0
 tunnel mode gre multipoint
 tunnel key 100
 ip nhrp network-id 100
 ip nhrp holdtime 600
 ip nhrp authentication nhrpkey1
 ip nhrp nhs 172.16.0.1
 ip nhrp map 172.16.0.1 203.0.113.5
 ip nhrp map multicast 203.0.113.5
 ip nhrp shortcut
 ip ospf 11 area 0
 ip ospf network broadcast
 ip ospf priority 0
 tunnel protection ipsec profile dmvpn-profile shared
```

- 예시는 Spoke `HQ-R2`. Hub(`DC-R2`)는 `ip nhrp map multicast dynamic`, `ip nhrp redirect`, `ip ospf priority 255`를 사용하고 NHS·map·shortcut 줄 제외.

### 3.6 Private Internet 언더레이와 ACL

```
router ospf 2
 router-id 203.0.113.9
int gi4/0
 ip ospf 2 area 100
 ip ospf network point-to-point
!
ip access-list extended pi-whitelist
 permit ospf any host 224.0.0.5
 permit ospf any host 224.0.0.6
 permit gre 203.0.113.0 0.0.0.255 203.0.113.0 0.0.0.255
 permit esp 203.0.113.0 0.0.0.255 203.0.113.0 0.0.0.255
 permit udp 203.0.113.0 0.0.0.255 203.0.113.0 0.0.0.255 eq isakmp
 permit icmp any any
 deny ip any any log
```

- ACL은 `Private-net`의 5개 링크 인터페이스에 적용(`ip access-group pi-whitelist in`). `ICMP` 허용 줄은 임시이며 검증 후 제거.
- 사이트 라우터의 프로세스 2 Router ID는 PI 연결 인터페이스 주소를 명시(예시는 `HQ-R2`의 `203.0.113.9`). 사이트 프로세스와 같은 값(Loopback0)을 쓰면 `router-id in use by ospf process`로 거부됨. `Private-net`의 Router ID는 `2.2.2.2`.

### 3.7 QoS

```
ip access-list extended acl-qos-dns
 permit udp any any eq 53
 permit udp any eq 53 any
 permit tcp any any eq 53
 permit tcp any eq 53 any
!
class-map match-any cm-control
 match dscp cs6
class-map match-any cm-business
 match access-group name acl-qos-dns
!
policy-map pm-lan-out-child
 class cm-control
  bandwidth percent 10
 class cm-business
  bandwidth percent 30
  set dscp af31
 class class-default
  fair-queue
policy-map pm-lan-out
 class class-default
  shape average 10000000
  service-policy pm-lan-out-child
!
int gi0/0
 service-policy output pm-lan-out
int gi1/0
 service-policy output pm-lan-out
```

- 적용 대상은 사이트 스위치와 연결된 라우터 인터페이스(`Gi0/0`, `Gi1/0`) 20포트(`docs/qos-design.md` 1절). 제외: 라우터 간 링크, ISP 방향, PI 방향, Tunnel0.
- DNS(53) 트래픽은 DSCP가 아니라 `match access-group`으로 `cm-business`에 분류하고 `set dscp af31`로 표시. `shape average` 값은 병목 검증용. 스위치 QoS는 적용하지 않음.

### 3.8 DC 서버 VLAN DNS ACL(DC-R1 ~ DC-R4)

```
ip access-list extended dns-only
 permit udp any host 10.2.50.10 eq 53
 permit tcp any host 10.2.50.10 eq 53
 permit udp any host 10.2.50.11 eq 53
 permit tcp any host 10.2.50.11 eq 53
 deny ip any 10.2.50.0 0.0.0.255 log
 permit ip any any
!
int gi0/0
 ip access-group dns-only out
int gi1/0
 ip access-group dns-only out
```

- 서버 VLAN(`10.2.50.0/24`)으로는 DNS(UDP/TCP 53)만 허용하고 나머지 트래픽은 통과(`permit ip any any`). 순서와 값은 `docs/dhcp-dns-design.md` 5절 표.
- 라우터가 직접 만드는 OSPF 등 제어 트래픽은 출력 ACL의 영향을 받지 않음. 스위치(vEOS-lab)가 ACL을 지원하지 않아 이 위치에 적용([arista-switch.md](./arista-switch.md) 5.3절).
