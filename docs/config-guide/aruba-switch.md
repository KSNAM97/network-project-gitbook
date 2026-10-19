# Aruba 스위치(AOS-CX) 설정

> 설정 가이드 목차: [README.md](./README.md) | [Cisco 라우터](./cisco-router.md) | [Cisco 스위치](./cisco-switch.md) | [Arista 스위치](./arista-switch.md) | [Aruba 스위치](./aruba-switch.md) | [알파인](./alpine.md)

대상: `BR1-SW1-L3`, `BR1-SW2-L3`(분배 L3), `BR1-SW3-L3`(액세스). 파일은 `configs/br1/<계층>/<장비명>.aos`. 포트 이름은 `1/1/<번호>`이며 연결은 `docs/port-mapping.md` 기준. 문법은 AOS-CX 10.x 기준이므로 장비에서 `?`로 확인.

## 1. 공통 규칙

- IP 주소는 프리픽스 길이(`10.3.0.2/30`)로 입력(Arista와 같은 방식, Cisco는 마스크 방식).
- 첫 줄은 `! aruba` + `!`. 이름, 약어, 소문자 규칙은 `docs/config-guide/README.md` 1-1절과 같고 들여쓰기는 1칸.
- 모든 포트는 기본이 shutdown이므로 사용하는 포트에 `no shutdown`.
- L3 스위치의 물리 포트는 기본이 routing 포트. L2(트렁크, 액세스)로 쓰는 포트는 `no routing`.
- 계정은 `user admin group administrators password plaintext admin1234`(실습용).
- L3 스위치에서 `ip routing` 설정은 필요 없음.

## 2. 설정 항목별 형식

| 항목 | 형식 |
|---|---|
| VLAN | `vlan 10` 아래 `name br1-public` |
| MSTP | `spanning-tree mode mstp`, `spanning-tree`, `spanning-tree config-name br1`, `spanning-tree config-revision 1`, `spanning-tree instance 1 vlan 10,20,100`, 루트와 보조 루트는 `spanning-tree instance 1 priority 1`(4096) 또는 `2`(8192) |
| LAG | `interface lag 1`에 `description`, `no routing`, `vlan trunk native 999`, `vlan trunk allowed 10,20,100`, `lacp mode active`. 멤버 포트는 `lag 1` |
| 트렁크 포트 | `no routing`, `vlan trunk native 999`, `vlan trunk allowed 10,20,100` |
| 액세스 포트 | `no routing`, `vlan access 10`, `spanning-tree port-type admin-edge` |
| 라우티드 포트 | `ip address 10.3.0.2/30`, `ip ospf 12 area 0.0.0.2`, `ip ospf network point-to-point` |
| Loopback | `interface loopback 0`, `ip address 12.12.12.11/32`, `ip ospf 12 area 0.0.0.2` (loopback은 `ip ospf passive`가 지원되지 않아 생략) |
| SVI | `interface vlan 10`, `ip address 10.3.10.2/24`, `ip ospf 12 area 0.0.0.2`, `ip ospf passive` |
| VRRP | 전역 `router vrrp enable`(필수), SVI 아래 `vrrp 10 address-family ipv4`, `address 10.3.10.1 primary`, `priority 110`, `no shutdown` |
| OSPF | `router ospf 12`, `router-id 12.12.12.11`, `area 0.0.0.2` |
| DHCP | `dhcp-server vrf default` 아래 `pool`, `range`, `default-router`, `dns-server`, `domain-name`, `lease`, `exit`, `enable`(`docs/dhcp-dns-design.md` 3.2절) |

## 3. 예시(BR1-SW1-L3 일부)

```
! aruba
!
hostname br1-sw1-l3
user admin group administrators password plaintext admin1234
!
vlan 10
 name br1-public
!
interface lag 1
 no shutdown
 description to br1-sw2-l3 lag1
 no routing
 vlan trunk native 999
 vlan trunk allowed 10,20,100
 lacp mode active
!
interface 1/1/1
 no shutdown
 description to br1-r1 gi0/0
 ip address 10.3.0.2/30
 ip ospf 12 area 0.0.0.2
 ip ospf network point-to-point
!
interface 1/1/3
 no shutdown
 description to br1-sw2-l3 1/1/3
 lag 1
```

## 4. 확인 명령

| 항목 | Aruba(AOS-CX) |
|---|---|
| VLAN, 트렁크 | `show vlan`, `show vlan port 1/1/5` |
| LAG | `show lacp aggregates`, `show lacp interfaces` |
| MSTP | `show spanning-tree mst`, `show spanning-tree mst-config` |
| VRRP | `show vrrp` |
| OSPF | `show ip ospf neighbors`, `show ip route ospf`, `show ip ospf interface brief` |
| DHCP | `show dhcp-server`, `show dhcp-server leases` |
| 저장 | `write memory` |
