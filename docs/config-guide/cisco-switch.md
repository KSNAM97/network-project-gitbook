# Cisco 스위치 설정 (vIOS L3·L2)

> 설정 가이드 목차: [README.md](./README.md) | [Cisco 라우터](./cisco-router.md) | [Cisco 스위치](./cisco-switch.md) | [Arista 스위치](./arista-switch.md) | [Aruba 스위치](./aruba-switch.md) | [알파인](./alpine.md)

대상: `HQ-SW-*`, `BR2-SW1-L3`, `BR2-SW2-L3`(L3), `BR2-SW3-L2`(L2). 인터페이스 이름은 `gi<슬롯>/<번호>`. BR1 스위치는 Aruba CX라서 [aruba-switch.md](./aruba-switch.md) 참고.

### 4.1 L2 기능

```
spanning-tree mode mst
spanning-tree mst configuration
 name hq
 revision 1
 instance 1 vlan 10,20,100
!
spanning-tree mst 1 priority 4096
vlan 10
 name hq-public
vlan 20
 name hq-private
vlan 100
 name mgmt
vlan 999
 name native
!
int range gi0/0 - 1
 desc to hq-sw-2 po1
 channel-group 1 mode active
int po1
 desc to hq-sw-2 po1
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk native vlan 999
 switchport trunk allowed vlan 10,20,100
int gi3/0
 switchport mode access
 switchport access vlan 10
```

- 채널 번호, 허용 VLAN, 포트는 `docs/vlan-design.md` 4~6절 표 값을 사용. `spanning-tree mst 1 priority`는 루트 장비 4096, Standby 장비 8192, L2 스위치는 기본값. MST 설정(region 이름, revision, instance)은 사이트 안의 모든 스위치에 동일하게 입력.

### 4.2 L3 기능(SVI, VRRP, 라우티드 포트)

```
ip routing
int vlan10
 ip addr 10.1.10.2 255.255.255.0
 vrrp 10 ip 10.1.10.1
 vrrp 10 priority 110
 no sh
int vlan20
 ip addr 10.1.20.2 255.255.255.0
 vrrp 20 ip 10.1.20.1
 vrrp 20 priority 110
 no sh
!
int gi1/0
 no switchport
 ip addr 10.1.0.2 255.255.255.252
```

- 예시는 `HQ-SW-2`(Active). `HQ-SW-3`은 SVI 주소 `.3`, priority 90. VRRP는 `preempt`가 기본 사용이라 별도 입력 없음. 라우티드 포트의 `ip ospf` 설정은 [cisco-router.md](./cisco-router.md) 3.2절과 같은 형식.
- 사용자 VLAN의 SVI는 `passive-interface`로 설정하고 사이트 OSPF Area에 포함. DHCP 풀은 `docs/dhcp-dns-design.md` 3절.
- 이미지(`vios_l2`)에서 `no switchport`와 `ip routing` 동작은 첫 장비에 적용해 확인 후 나머지 장비에 반복.

### 4.3 L2 스위치 예시(BR2-SW3-L2)

- L3 기능 없이 트렁크 2포트(L3 스위치 방향)와 호스트 액세스 2포트만 설정.

```
! cisco
!
hostname br2-sw3-l2
spanning-tree mode mst
spanning-tree mst configuration
 name br2
 revision 1
 instance 1 vlan 10,20,100
!
vlan 10
 name br2-public
vlan 20
 name br2-private
vlan 100
 name mgmt
vlan 999
 name native
!
int gi0/0
 desc to br2-sw1-l3 gi2/0
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk native vlan 999
 switchport trunk allowed vlan 10,20,100
int gi0/1
 desc to br2-sw2-l3 gi2/0
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk native vlan 999
 switchport trunk allowed vlan 10,20,100
int gi3/0
 desc to br2-pc1 eth0
 switchport mode access
 switchport access vlan 10
 spanning-tree portfast
int gi3/1
 desc to br2-pc2 eth0
 switchport mode access
 switchport access vlan 20
 spanning-tree portfast
int vlan100
 ip addr 10.4.100.23 255.255.255.0
```

### 4.4 L3 스위치 OSPF(HQ-SW-2)

```
router ospf 11
 router-id 11.11.11.12
 passive-interface lo0
 passive-interface vlan10
 passive-interface vlan20
!
int lo0
 ip ospf 11 area 1
int vlan10
 ip ospf 11 area 1
int vlan20
 ip ospf 11 area 1
int gi1/0
 ip ospf 11 area 1
 ip ospf network point-to-point
int gi1/1
 ip ospf 11 area 1
 ip ospf network point-to-point
```

- 사용자 VLAN SVI와 `lo0`는 Area에 포함하고 `passive-interface` 처리. 라우티드 포트는 `point-to-point`. MGMT VLAN 100은 OSPF에 포함하지 않음.
- 프로세스, Area, Router ID는 `docs/ospf-design.md` 2~3절의 표 값을 사용.

### 4.5 MGMT SVI

```
int vlan 100
 ip addr 10.1.100.12 255.255.255.0
 no sh
```

- 주소는 `10.<사이트>.100.<장비 번호>`(`docs/vlan-design.md` 1절). 예시는 `HQ-SW-2`(`.12`). 게이트웨이와 OSPF 광고는 없음.
- L2 스위치(`BR2-SW3-L2`)는 4.3절 예시처럼 같은 형식에 장비 번호만 20을 더한 값을 사용.
- Arista L3 전용 스위치(`DC-SW1-L3`, `DC-SW2-L3`)는 VLAN 100에 속한 포트가 없어 SVI가 `down`이 되므로 MGMT SVI를 두지 않음(콘솔로 관리).

### 4.6 DHCP 서버(게이트웨이 스위치)

```
service dhcp
ip dhcp excluded-address 10.1.10.1 10.1.10.99
ip dhcp excluded-address 10.1.10.164 10.1.10.254
!
ip dhcp pool hq-public
 network 10.1.10.0 255.255.255.0
 default-router 10.1.10.1
 dns-server 10.2.50.10 10.2.50.11
 domain-name lab.local
 lease 1
```

- 예시는 `HQ-SW-2`(Active, 풀 `.100` – `.163`). `HQ-SW-3`(Standby)은 제외 구간만 `10.1.10.1 10.1.10.163`, `10.1.10.228 10.1.10.254`로 입력.
- VLAN 20과 BR1, BR2도 같은 형식에서 서브넷과 풀 이름만 변경. 값은 `docs/dhcp-dns-design.md` 3절 표.

### 4.7 STP(MSTP)

- MST 설정(region 이름, revision, instance 매핑)은 사이트 안의 모든 Cisco 스위치(L2 포함)에 동일하게 입력. 하나라도 다르면 별도 region으로 인식.
- `spanning-tree mst 1 priority`는 루트 4096, 보조 루트 8192, 그 외 스위치는 입력하지 않고 기본값(32768) 유지. 루트는 해당 사이트 VRRP Active 장비.

루트(HQ-SW-2):

```
spanning-tree mode mst
spanning-tree mst configuration
 name hq
 revision 1
 instance 1 vlan 10,20,100
!
spanning-tree mst 1 priority 4096
```

보조 루트(HQ-SW-3): 위와 같고 마지막 줄만 `spanning-tree mst 1 priority 8192`.

일반 스위치(HQ-SW-1): 우선순위 줄 없이 MST 설정만 입력.

```
spanning-tree mode mst
spanning-tree mst configuration
 name hq
 revision 1
 instance 1 vlan 10,20,100
!
```

| 사이트 | region 이름 | instance 1 VLAN | 루트 (4096) | 보조 루트 (8192) | 기본값 장비 |
|---|---|---|---|---|---|
| HQ | `hq` | 10,20,100 | HQ-SW-2 | HQ-SW-3 | HQ-SW-1 |
| BR1 | `br1` | 10,20,100 | BR1-SW1-L3 | BR1-SW2-L3 | BR1-SW3-L3 |
| BR2 | `br2` | 10,20,100 | BR2-SW1-L3 | BR2-SW2-L3 | BR2-SW3-L2 |

- `native` VLAN 999는 instance 0에 남기므로 instance 1에 넣지 않음.
- 모드를 바꾸면 STP가 재수렴하므로 사이트의 모든 스위치에 연달아 입력한 뒤 확인.
- 확인: `show spanning-tree mst configuration`(region 이름, revision, instance 일치), `show spanning-tree mst 1`(루트 브리지와 포트 역할), `show spanning-tree summary`(모드 mst).
