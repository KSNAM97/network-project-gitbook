# VRRP, MSTP 설계

게이트웨이 이중화(VRRP)와 스패닝 트리(MSTP)의 값과 설정을 정리한 문서. VLAN, 서브넷, 트렁크는 `docs/vlan-design.md`, 포트는 `docs/port-mapping.md`, 주소는 `docs/ip-mapping.md` 기준.

## 1. 적용 기준

- 게이트웨이 이중화는 전 사이트 **VRRP**(RFC 5798), 스패닝 트리는 전 사이트 **MSTP**(IEEE 802.1s)로 통일.
- 두 프로토콜 모두 표준이라 Cisco(IOS), Arista(EOS), Aruba(AOS-CX) 장비에서 같은 개념으로 동작. 한 벤더 전용인 HSRP, VARP, PVST는 사용하지 않음.
- 한 VRRP 그룹과 한 MST region 안에는 같은 벤더 장비만 배치(HQ와 BR2는 Cisco, DC는 Arista, BR1은 Aruba).
- 문서의 Active, Standby는 VRRP의 Master, Backup, MST의 루트, 보조 루트와 같은 장비를 가리킴.

## 2. VRRP

### 2.1 그룹

- 그룹 번호는 VLAN 번호와 동일, VIP는 서브넷의 `.1`, 장비 SVI 주소는 `.2`(Active)와 `.3`(Standby).
- 우선순위는 Active 110, Standby 90. `preempt`는 기본 사용이라 별도 설정 없음.
- 광고 주기와 타이머는 기본값 사용.

| 사이트 | VLAN            | 그룹  | Active (110)           | Standby (90)           | VIP       |
| --- | --------------- | --- | ---------------------- | ---------------------- | --------- |
| HQ  | 10 (HQ-PUBLIC)  | 10  | HQ-SW-2 `10.1.10.2`    | HQ-SW-3 `10.1.10.3`    | 10.1.10.1 |
| HQ  | 20 (HQ-PRIVATE) | 20  | HQ-SW-2 `10.1.20.2`    | HQ-SW-3 `10.1.20.3`    | 10.1.20.1 |
| DC  | 50 (SERVER)     | 50  | DC-SW3-L3 `10.2.50.2`  | DC-SW4-L3 `10.2.50.3`  | 10.2.50.1 |
| BR1 | 10 (BR1-PUBLIC) | 10 | BR1-SW1-L3 `10.3.10.2` | BR1-SW2-L3 `10.3.10.3` | 10.3.10.1 |
| BR1 | 20 (BR1-PRIVATE) | 20 | BR1-SW1-L3 `10.3.20.2` | BR1-SW2-L3 `10.3.20.3` | 10.3.20.1 |
| BR2 | 10 (BR2-PUBLIC) | 10 | BR2-SW1-L3 `10.4.10.2` | BR2-SW2-L3 `10.4.10.3` | 10.4.10.1 |
| BR2 | 20 (BR2-PRIVATE) | 20 | BR2-SW1-L3 `10.4.20.2` | BR2-SW2-L3 `10.4.20.3` | 10.4.20.1 |

- VRRP는 사용자 VLAN의 SVI에서만 동작. Loopback은 그룹 구성에 사용할 수 없음(Router ID, 관리용).
- MGMT VLAN 100은 게이트웨이를 두지 않으므로 VRRP 그룹 없음.

### 2.2 명령 비교

| 항목 | Cisco(vIOS) | Arista(vEOS-lab) |
|---|---|---|
| VIP | `vrrp 10 ip 10.1.10.1` | `vrrp 50 ipv4 10.2.50.1` |
| 우선순위 | `vrrp 10 priority 110` | `vrrp 50 priority-level 110` |
| 위치 | SVI(`int vlan10`) | SVI(`int vlan50`) |
| 확인 | `show vrrp brief` | `show vrrp brief` |

- Arista의 `vrrp 50 ?` 출력에서 `ipv4`, `priority-level`, `preempt`, `timers`, `bfd`가 제공됨을 확인.

### 2.3 Aruba(AOS-CX) 명령

| 항목 | Aruba(AOS-CX) |
|---|---|
| VIP | 전역 `router vrrp enable` 필수(없으면 `VRRP is not enabled`, 상태 INIT). SVI 아래 `vrrp 10 address-family ipv4`, `address 10.3.10.1 primary` |
| 우선순위 | `priority 110` |
| 활성화 | VRRP 설정 안에서 `no shutdown` |
| 위치 | SVI(`interface vlan 10`) |
| 확인 | `show vrrp` |

## 3. MSTP

### 3.1 region과 instance

- 사이트마다 region 하나. 사이트 간 L2 연결이 없으므로 region 이름은 사이트 이름(소문자), revision은 1.
- instance 1에 사용자(또는 서버) VLAN과 MGMT VLAN 100을 매핑. native VLAN 999는 기본 instance 0.
- 사이트 안의 모든 스위치(L2 포함)에 같은 MST 설정(이름, revision, instance 매핑)을 입력. 하나라도 다르면 별도 region으로 인식.

| 사이트 | region 이름 | revision | instance 1 VLAN |
|---|---|---|---|
| HQ | `hq` | 1 | 10,20,100 |
| DC | `dc` | 1 | 50,100 |
| BR1 | `br1` | 1 | 10,20,100 |
| BR2 | `br2` | 1 | 10,20,100 |

### 3.2 루트와 우선순위

- 루트 브리지는 해당 사이트 VRRP Active 장비로 고정해 L2 경로와 게이트웨이를 일치시킴.
- `spanning-tree mst 1 priority`는 루트 4096, 보조 루트 8192. 그 외 스위치는 기본값(32768) 유지.

| 사이트 | 루트 (4096) | 보조 루트 (8192) | 기본값 장비 |
|---|---|---|---|
| HQ | HQ-SW-2 | HQ-SW-3 | HQ-SW-1 |
| DC | DC-SW3-L3 | DC-SW4-L3 | DC-SW1-L2, DC-SW2-L2 |

- DC는 MLAG 적용(`docs/mlag-design.md`)으로 `DC-SW1-L2`, `DC-SW2-L2` 업링크가 MLAG 포트채널이라 STP 차단 링크가 없음. 루트(`DC-SW3-L3`)와 VRRP Active는 그대로 유지.
| BR1 | BR1-SW1-L3 | BR1-SW2-L3 | BR1-SW3-L3 |
| BR2 | BR2-SW1-L3 | BR2-SW2-L3 | BR2-SW3-L2 |

### 3.3 모드 명령

| 항목 | Cisco | Arista |
|---|---|---|
| 모드 | `spanning-tree mode mst` | `spanning-tree mode mstp` |
| region 설정 | `spanning-tree mst configuration` 아래 `name`, `revision`, `instance` | 같은 형식(1칸 들여쓰기) |
| 우선순위 | `spanning-tree mst 1 priority 4096` | `spanning-tree mst 1 priority 4096` |
| 확인 | `show spanning-tree mst` | `show spanning-tree mst` |

### 3.4 Aruba(AOS-CX) 모드 명령

| 항목 | Aruba(AOS-CX) |
|---|---|
| 모드 | `spanning-tree mode mstp`, `spanning-tree` |
| region 설정 | `spanning-tree config-name br1`, `spanning-tree config-revision 1`, `spanning-tree instance 1 vlan 10,20,100` |
| 우선순위 | `spanning-tree instance 1 priority 1`(4096 단위, `1` = 4096, `2` = 8192) |
| 확인 | `show spanning-tree mst`, `show spanning-tree mst-config` |

## 4. 설정 예시

### 4.1 Cisco 루트(HQ-SW-2)

```
spanning-tree mode mst
spanning-tree mst configuration
 name hq
 revision 1
 instance 1 vlan 10,20,100
!
spanning-tree mst 1 priority 4096
!
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
```

- `HQ-SW-3`은 SVI 주소 `.3`, `vrrp ... priority 90`, `spanning-tree mst 1 priority 8192`.
- `HQ-SW-1`은 MST 설정만 같게 입력하고 priority와 VRRP는 없음.

### 4.2 Arista 루트(DC-SW3-L3)

```
spanning-tree mode mstp
spanning-tree mst configuration
 name dc
 revision 1
 instance 1 vlan 50,100
!
spanning-tree mst 1 priority 4096
!
int vlan50
 ip add 10.2.50.2/24
 vrrp 50 ipv4 10.2.50.1
 vrrp 50 priority-level 110
```

- `DC-SW4-L3`은 SVI 주소 `.3`, `vrrp 50 priority-level 90`, `spanning-tree mst 1 priority 8192`.
- `DC-SW1-L2`, `DC-SW2-L2`는 MST 설정만 같게 입력.

### 4.3 Aruba 루트(BR1-SW1-L3)

```
spanning-tree mode mstp
spanning-tree
spanning-tree config-name br1
spanning-tree config-revision 1
spanning-tree instance 1 vlan 10,20,100
spanning-tree instance 1 priority 1
!
router vrrp enable
!
interface vlan 10
 ip address 10.3.10.2/24
 vrrp 10 address-family ipv4
  address 10.3.10.1 primary
  priority 110
  no shutdown
```

- `BR1-SW2-L3`은 SVI 주소 `.3`, `priority 90`, `spanning-tree instance 1 priority 2`. `BR1-SW3-L3`은 MST 설정만 같게 입력하고 priority와 VRRP는 없음.
- VLAN 20은 `interface vlan 20`, 주소 `10.3.20.2`(SW2는 `.3`), 그룹 `20`.

## 5. 검증

| 항목 | 방법 | 기대 결과 |
|---|---|---|
| VRRP 상태 | `show vrrp brief` | Active는 Master, Standby는 Backup |
| MST 일치 | `show spanning-tree mst` | 사이트 내 스위치의 region 이름, revision, instance 동일 |
| 루트 | `show spanning-tree mst 1` | 루트 브리지가 사이트의 Active 장비 |
| 호스트 게이트웨이 | 호스트에서 VIP로 `ping` | 응답 |
| 전환 | Active 장비 SVI `shutdown` 후 호스트 `ping` | Standby가 Master로 전환, 중단 시간 측정(KAN-27) |
| 복귀 | Active 장비 SVI `no sh` | `preempt`로 Master 복귀 |
