# VLAN 설계

VLAN, 게이트웨이 이중화, EtherChannel, 트렁크, STP(MSTP), DHCP 배치를 정리한 문서. 포트는 `docs/port-mapping.md`, 서브넷과 DHCP 풀은 `docs/ip-mapping.md` 기준.

## 1. VLAN 정의

| 사이트 | VLAN | 이름 | 서브넷 | 태그 | 게이트웨이 이중화 |
|---|---|---|---|---|---|
| HQ | 10 | HQ-PUBLIC | 10.1.10.0/24 | `vlan-hq-public` | VRRP |
| HQ | 20 | HQ-PRIVATE | 10.1.20.0/24 | `vlan-hq-private` | VRRP |
| DC | 50 | SERVER | 10.2.50.0/24 | `vlan-dc-server` | VRRP |
| BR1 | 10 | BR1-PUBLIC | 10.3.10.0/24 | `vlan-br1-public` | VRRP |
| BR1 | 20 | BR1-PRIVATE | 10.3.20.0/24 | `vlan-br1-private` | VRRP |
| BR2 | 10 | BR2-PUBLIC | 10.4.10.0/24 | `vlan-br2-public` | VRRP |
| BR2 | 20 | BR2-PRIVATE | 10.4.20.0/24 | `vlan-br2-private` | VRRP |
| 전 사이트 | 100 | MGMT | 10.<사이트>.100.0/24 | `vlan-mgmt` | - |
| 전 사이트 | 999 | NATIVE | 없음 | `vlan-native` | - |

- 모든 트렁크의 native VLAN은 999.
- BR1 스위치는 Aruba CX(AOS-CX). 트렁크는 `vlan trunk native 999`, `vlan trunk allowed 10,20,100`, 액세스 포트는 `vlan access <번호>`, EtherChannel은 LAG(`interface lag 1`, `lacp mode active`)로 설정(`docs/config-guide/aruba-switch.md`).
- MGMT VLAN 100은 스위치마다 SVI를 두며 주소는 `10.<사이트>.100.<장비 번호>/24`. 장비 번호는 이름 끝이 `-L2`인 스위치는 이름의 번호에 20을 더한 값, 그 외 스위치는 10을 더한 값(예: `HQ-SW-2` → `10.1.100.12`, `DC-SW3-L3` → `10.2.100.13`, `DC-SW1-L2` → `10.2.100.21`). 단, L2 구간이 없는 L3 전용 스위치(`DC-SW1-L3`, `DC-SW2-L3`)는 MGMT SVI를 두지 않고 콘솔로 관리.
- MGMT VLAN 100은 사이트 내부 관리용이며 게이트웨이와 OSPF 광고를 두지 않음.

## 2. 게이트웨이 이중화

- 전 사이트 VRRP(표준, 멀티벤더 호환)로 통일. 그룹 번호는 VLAN 번호와 동일, `preempt`는 기본 사용. 우선순위는 Active 110, Standby 90(문서의 Active/Standby는 VRRP Master/Backup).
- DC 서버 VLAN도 VRRP 사용(Arista `vrrp 50 ipv4 10.2.50.1`). VARP와 HSRP는 사용하지 않음.

| 사이트 | VLAN | 방식 | Active / 1번 장비 | Standby / 2번 장비 | VIP | 서브넷 |
|---|---|---|---|---|---|---|
| HQ | 10 | VRRP | HQ-SW-2 `10.1.10.2` (110) | HQ-SW-3 `10.1.10.3` (90) | 10.1.10.1 | 10.1.10.0/24 |
| HQ | 20 | VRRP | HQ-SW-2 `10.1.20.2` (110) | HQ-SW-3 `10.1.20.3` (90) | 10.1.20.1 | 10.1.20.0/24 |
| DC | 50 | VRRP | DC-SW3-L3 `10.2.50.2` (110) | DC-SW4-L3 `10.2.50.3` (90) | 10.2.50.1 | 10.2.50.0/24 |
| BR1 | 10 | VRRP | BR1-SW1-L3 `10.3.10.2` (110) | BR1-SW2-L3 `10.3.10.3` (90) | 10.3.10.1 | 10.3.10.0/24 |
| BR1 | 20 | VRRP | BR1-SW1-L3 `10.3.20.2` (110) | BR1-SW2-L3 `10.3.20.3` (90) | 10.3.20.1 | 10.3.20.0/24 |
| BR2 | 10 | VRRP | BR2-SW1-L3 `10.4.10.2` (110) | BR2-SW2-L3 `10.4.10.3` (90) | 10.4.10.1 | 10.4.10.0/24 |
| BR2 | 20 | VRRP | BR2-SW1-L3 `10.4.20.2` (110) | BR2-SW2-L3 `10.4.20.3` (90) | 10.4.20.1 | 10.4.20.0/24 |

## 3. STP(MSTP)

- 전 사이트 MSTP(IEEE 802.1s)로 통일: Cisco `spanning-tree mode mst`, Arista `spanning-tree mode mstp`, Aruba `spanning-tree mode mstp`.
- 사이트마다 region 하나를 두며 region 이름은 사이트 이름(소문자), revision은 1. 사용자 또는 서버 VLAN과 MGMT VLAN 100은 instance 1에 매핑하고 native VLAN 999는 기본 instance 0에 둠. 사이트 안의 모든 스위치(L2 포함)는 같은 MST 설정 사용.
- 루트 브리지는 게이트웨이 Active 장비로 고정(`spanning-tree mst 1 priority 4096`, Standby는 8192).

| 사이트 | 루트 | 보조 루트 |
|---|---|---|
| HQ | HQ-SW-2 | HQ-SW-3 |
| DC | DC-SW3-L3 | DC-SW4-L3 |
| BR1 | BR1-SW1-L3 | BR1-SW2-L3 |
| BR2 | BR2-SW1-L3 | BR2-SW2-L3 |

| 사이트 | region 이름 | instance 1 VLAN |
|---|---|---|
| HQ | `hq` | 10,20,100 |
| DC | `dc` | 50,100 |
| BR1 | `br1` | 10,20,100 |
| BR2 | `br2` | 10,20,100 |

## 4. EtherChannel

- 모든 채널은 LACP(`channel-group <번호> mode active`) 사용.
- DC는 `DC-SW3-L3`, `DC-SW4-L3`를 MLAG 피어로 묶고 `DC-SW1-L2`, `DC-SW2-L2` 업링크를 MLAG 포트채널(`Po10`, `Po20`)로 사용(`docs/mlag-design.md`). 그래서 5절 트렁크 표에서 DC 구간은 제외.

| 사이트 | Po | 장비 A | A 포트 | 장비 B | B 포트 | 허용 VLAN |
|---|---|---|---|---|---|---|
| HQ | Po1 | HQ-SW-1 | Gi1/0, Gi1/1 | HQ-SW-2 | Gi0/0, Gi0/1 | 10,20,100 |
| HQ | Po2 | HQ-SW-1 | Gi1/2, Gi1/3 | HQ-SW-3 | Gi0/0, Gi0/1 | 10,20,100 |
| HQ | Po3 | HQ-SW-2 | Gi0/2, Gi0/3 | HQ-SW-3 | Gi0/2, Gi0/3 | 10,20,100 |
| DC | Po1 (MLAG peer-link) | DC-SW3-L3 | Et5, Et6 | DC-SW4-L3 | Et5, Et6 | 50,100,4094 |
| DC | Po10 (MLAG 10) | DC-SW1-L2 | Et1, Et2 | DC-SW3-L3 / DC-SW4-L3 | Et7 / Et7 | 50,100 |
| DC | Po20 (MLAG 20) | DC-SW2-L2 | Et1, Et2 | DC-SW3-L3 / DC-SW4-L3 | Et8 / Et8 | 50,100 |
| BR1 | LAG 1 | BR1-SW1-L3 | 1/1/3, 1/1/4 | BR1-SW2-L3 | 1/1/3, 1/1/4 | 10,20,100 |
| BR2 | Po1 | BR2-SW1-L3 | Gi1/0, Gi1/1 | BR2-SW2-L3 | Gi1/0, Gi1/1 | 10,20,100 |

## 5. 트렁크

- 허용 VLAN은 사이트별 값(HQ 10, 20, 100 / DC 50, 100 / BR1·BR2 10, 20, 100)만 통과, native 999.

| 사이트 | 장비 A | A 포트 | 장비 B | B 포트 | 허용 VLAN |
|---|---|---|---|---|---|
| BR1 | BR1-SW1-L3 | 1/1/5 | BR1-SW3-L3 | 1/1/1 | 10,20,100 |
| BR1 | BR1-SW2-L3 | 1/1/5 | BR1-SW3-L3 | 1/1/2 | 10,20,100 |
| BR2 | BR2-SW1-L3 | Gi2/0 | BR2-SW3-L2 | Gi0/0 | 10,20,100 |
| BR2 | BR2-SW2-L3 | Gi2/0 | BR2-SW3-L2 | Gi0/1 | 10,20,100 |

## 6. 액세스 포트

| 장비 A | A 포트 | 호스트 장비 | 포트 | VLAN |
|---|---|---|---|---|
| HQ-SW-1 | Gi3/0 | HQ-PC1 | eth0 | 10 |
| HQ-SW-1 | Gi3/1 | HQ-PC2 | eth0 | 20 |
| DC-SW1-L2 | Et12 | DC-DNS-1 | eth0 | 50 |
| DC-SW2-L2 | Et12 | DC-DNS-2 | eth0 | 50 |
| BR1-SW3-L3 | 1/1/6 | BR1-PC1 | eth0 | 10 |
| BR1-SW3-L3 | 1/1/7 | BR1-PC2 | eth0 | 20 |
| BR2-SW3-L2 | Gi3/0 | BR2-PC1 | eth0 | 10 |
| BR2-SW3-L2 | Gi3/1 | BR2-PC2 | eth0 | 20 |

## 7. DHCP 배치

- DHCP는 사용자 VLAN의 게이트웨이 장비 두 대가 함께 제공하고, 풀 범위를 나눠 중복 할당을 방지. 서버 VLAN은 DHCP 없이 고정 주소 사용.
- 풀 전체는 `.100` – `.227`(128개). Active 장비가 앞 64개, Standby 장비가 뒤 64개 담당. `default-router`는 VIP, DNS는 `10.2.50.10`, `10.2.50.11`.

| 사이트 | VLAN | Active 장비 풀 | Standby 장비 풀 |
|---|---|---|---|
| HQ | 10 | HQ-SW-2 `10.1.10.100` – `10.1.10.163` | HQ-SW-3 `10.1.10.164` – `10.1.10.227` |
| HQ | 20 | HQ-SW-2 `10.1.20.100` – `10.1.20.163` | HQ-SW-3 `10.1.20.164` – `10.1.20.227` |
| BR1 | 10 | BR1-SW1-L3 `10.3.10.100` – `10.3.10.163` | BR1-SW2-L3 `10.3.10.164` – `10.3.10.227` |
| BR1 | 20 | BR1-SW1-L3 `10.3.20.100` – `10.3.20.163` | BR1-SW2-L3 `10.3.20.164` – `10.3.20.227` |
| BR2 | 10 | BR2-SW1-L3 `10.4.10.100` – `10.4.10.163` | BR2-SW2-L3 `10.4.10.164` – `10.4.10.227` |
| BR2 | 20 | BR2-SW1-L3 `10.4.20.100` – `10.4.20.163` | BR2-SW2-L3 `10.4.20.164` – `10.4.20.227` |

