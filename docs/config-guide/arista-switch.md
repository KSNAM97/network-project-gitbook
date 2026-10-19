# Arista 스위치 설정 (vEOS-lab)

> 설정 가이드 목차: [README.md](./README.md) | [Cisco 라우터](./cisco-router.md) | [Cisco 스위치](./cisco-switch.md) | [Arista 스위치](./arista-switch.md) | [Aruba 스위치](./aruba-switch.md) | [알파인](./alpine.md)

대상: `DC-SW1-L3` ~ `DC-SW4-L3`, `DC-SW1-L2`, `DC-SW2-L2`. 인터페이스 이름은 `et<번호>`(범위는 `int range et 5-6`), 주소는 `ip add`. 하위 명령 들여쓰기는 Cisco와 같은 1칸.

```
! arista
!
hostname dc-sw3-l3
spanning-tree mode mstp
spanning-tree mst configuration
 name dc
 revision 1
 instance 1 vlan 50,100
!
spanning-tree mst 1 priority 4096
ip routing
!
vlan 50
 name server
vlan 100
 name mgmt
vlan 999
 name native
!
int range et 5-6
 channel-group 1 mode active
int po1
 switchport mode trunk
 switchport trunk native vlan 999
 switchport trunk allowed vlan 50,100
int vlan50
 ip add 10.2.50.2/24
 vrrp 50 ipv4 10.2.50.1
 vrrp 50 priority-level 110
int et3
 no switchport
 ip add 10.2.0.38/30
 ip ospf network point-to-point
!
router ospf 10
 router-id 10.10.10.13
 passive-interface vlan50
 network 10.2.0.36/30 area 0.0.0.0
 network 10.2.50.0/24 area 0.0.0.0
```

- 예시는 `DC-SW3-L3`. `DC-SW4-L3`은 SVI 주소 `.3`, `vrrp 50 priority-level 90`, `spanning-tree mst 1 priority 8192`. `DC-SW1-L3`, `DC-SW2-L3`은 VLAN 설정 없이 라우티드 포트와 OSPF만 사용.
### 5.1 DC L2 스위치(DC-SW1-L2, DC-SW2-L2)

- `ip routing`, OSPF 없이 트렁크(Et1, Et2)와 서버 액세스(Et12, VLAN 50)만 설정. EOS의 포트는 기본이 스위치포트이므로 `no switchport` 불필요.

```
! arista
!
hostname dc-sw1-l2
spanning-tree mode mstp
spanning-tree mst configuration
 name dc
 revision 1
 instance 1 vlan 50,100
!
!
vlan 50
 name server
vlan 100
 name mgmt
vlan 999
 name native
!
int et1
 desc to dc-sw3-l3 et7
 switchport mode trunk
 switchport trunk native vlan 999
 switchport trunk allowed vlan 50,100
int et2
 desc to dc-sw4-l3 et7
 switchport mode trunk
 switchport trunk native vlan 999
 switchport trunk allowed vlan 50,100
int et12
 desc to dc-dns-1 eth0
 switchport mode access
 switchport access vlan 50
 spanning-tree portfast
int vlan100
 ip add 10.2.100.21/24
```

- `DC-SW2-L2`는 호스트네임 `dc-sw2-l2`, 업링크 설명 `desc to dc-sw3-l3 et8`(et1), `desc to dc-sw4-l3 et8`(et2), 서버 포트 설명 `desc to dc-dns-2 eth0`, MGMT 주소 `ip add 10.2.100.22/24`로 변경.

### 5.2 접속 설정

```
username admin privilege 15 role network-admin secret admin1234
```

- Cisco의 `enable secret`, `line vty`에 해당. 호스트네임과 접속 계정은 모든 Arista 장비에 같은 형식으로 적용.

### 5.3 서버 VLAN ACL

- vEOS-lab는 인터페이스 ACL(`ip access-group`)을 지원하지 않음. SVI 출력, 라우티드 포트 입력 모두 `% Unavailable command (not supported on this hardware platform)`로 거부되어 `DC-SW3-L3`, `DC-SW4-L3`에는 적용하지 않음.
- 서버 VLAN DNS ACL은 DC 라우터에 적용([cisco-router.md](./cisco-router.md) 3.8절, `docs/dhcp-dns-design.md` 5절).

### 5.4 MLAG(DC-SW3-L3, DC-SW4-L3, DC-SW1-L2, DC-SW2-L2)

`DC-SW3-L3` 예시. `DC-SW4-L3`은 `vlan4094` 주소와 `peer-address`만 반대로 입력(아래 설명).

```
vlan 4094
 name mlag-peer
 trunk group MLAGPEER
no spanning-tree vlan-id 4094
!
int po1
 switchport trunk allowed vlan 50,100,4094
 switchport trunk group MLAGPEER
!
int vlan4094
 desc mlag peer
 ip add 10.2.254.1/30
 no autostate
!
mlag configuration
 domain-id dc-mlag
 local-interface vlan4094
 peer-address 10.2.254.2
 peer-link port-channel 1
!
default int et7
default int et8
int et7
 desc to dc-sw1-l2 et1
 channel-group 10 mode active
int et8
 desc to dc-sw2-l2 et1
 channel-group 20 mode active
!
int po10
 desc to dc-sw1-l2 po10
 switchport mode trunk
 switchport trunk native vlan 999
 switchport trunk allowed vlan 50,100
 mlag 10
int po20
 desc to dc-sw2-l2 po20
 switchport mode trunk
 switchport trunk native vlan 999
 switchport trunk allowed vlan 50,100
 mlag 20
```

L2 스위치 쪽(`DC-SW1-L2` 예시, `DC-SW2-L2`는 `po20`):

```
default int et1
default int et2
int range et1-2
 channel-group 10 mode active
int po10
 desc to dc-sw3-l3, dc-sw4-l3 mlag
 switchport mode trunk
 switchport trunk native vlan 999
 switchport trunk allowed vlan 50,100
```

- `DC-SW4-L3`: `int vlan4094`의 주소는 `10.2.254.2/30`, `peer-address`는 `10.2.254.1`, `et7`, `et8`의 `desc`는 `to dc-sw1-l2 et2`, `to dc-sw2-l2 et2`.
- 피어 링크는 기존 `Po1`(Et5, Et6)을 재사용하고 VLAN 4094(`trunk group MLAGPEER`)만 추가. 값과 적용 순서는 `docs/mlag-design.md`.
- 한 L2 스위치씩 순서대로 전환하고 단계마다 `write memory`. vEOS-lab의 MLAG 지원 여부는 `show mlag`로 먼저 확인.
