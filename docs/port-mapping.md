# 장비 포트 매핑표 (GNS3 장비명 기준)

`docs/network-project-final.md` 4절의 링크 정보를 GNS3 장비명 기준으로 링크 한 줄씩 정리한 표. 케이블링과 컨피그 작성의 기준으로 사용.

- 장비명: GNS3 노드 이름.
- 인터페이스 이름: GNS3에서 확인한 실제 이름(L2 스위치도 동일한 이름 규칙).

| 장비 종류 | GNS3 인터페이스 | 사용 가능 포트 |
|---|---|---|
| Cisco 7200 라우터 (`HQ-R*`, `DC-R*`, `BR*-R*`, `ISP-*`, `Private-net`) | `GigabitEthernet0/0` – `6/0` (`GiX/0`) | 7포트 |
| Cisco IOU 스위치 L3·L2 (`HQ-SW-*`, `BR*-SW*-L3`, `BR2-SW3-L2`) | `Gi0/0` – `Gi3/3` | 16포트 |
| Arista vEOS-lab 스위치 L3·L2 (`DC-SW*-L3`, `DC-SW*-L2`) | `Management1`, `Ethernet1` – `Ethernet12` (`Et1` – `Et12`) | 12포트 + 관리 |

- 이 표는 2026-10-11 저장된 GNS3 프로젝트의 연결과 대조 완료(연결 80개). `연결 확인됨`은 GNS3에 실제 연결된 값이며, 서브넷과 IP는 컨피그 작업 전이라 장비에 미적용.

- 서브넷이 `-`인 링크: L2 링크(트렁크, EtherChannel, access).
- ISP-1과 ISP-2는 동일 구조이며 `100.1.x.x`, `100.2.x.x`로 구분. 번호 `#`는 문서 내 링크 번호.

## 1. 링크 표

### HQ

| # | A 장비 | A 포트 | B 장비 | B 포트 | 서브넷 | 비고 |
|---|---|---|---|---|---|---|
| 1 | HQ-SW-2 | Gi1/0 | HQ-R1 | Gi0/0 | 10.1.0.0/30 | - |
| 2 | HQ-SW-2 | Gi1/1 | HQ-R2 | Gi0/0 | 10.1.0.4/30 | - |
| 3 | HQ-SW-3 | Gi1/0 | HQ-R1 | Gi1/0 | 10.1.0.8/30 | - |
| 4 | HQ-SW-3 | Gi1/1 | HQ-R2 | Gi1/0 | 10.1.0.12/30 | - |
| 5 | HQ-R1 | Gi2/0 | HQ-R2 | Gi2/0 | 10.1.0.16/30 | - |
| 6 | HQ-R1 | Gi3/0 | ISP-1-PE-A | Gi2/0 | 100.1.11.0/30 | ISP-1 연결 |
| 7 | HQ-R2 | Gi3/0 | ISP-2-PE-A | Gi2/0 | 100.2.12.0/30 | ISP-2 연결 |
| 8 | HQ-R2 | Gi4/0 | Private-net | Gi2/0 | 203.0.113.8/30 | PI 연결, DMVPN Spoke Tunnel0 source |
| 9 | HQ-SW-1 | Gi1/0 | HQ-SW-2 | Gi0/0 | - | Po1 (VLAN 10/20/100) |
| 10 | HQ-SW-1 | Gi1/1 | HQ-SW-2 | Gi0/1 | - | Po1 |
| 11 | HQ-SW-1 | Gi1/2 | HQ-SW-3 | Gi0/0 | - | Po2 |
| 12 | HQ-SW-1 | Gi1/3 | HQ-SW-3 | Gi0/1 | - | Po2 |
| 13 | HQ-SW-2 | Gi0/2 | HQ-SW-3 | Gi0/2 | - | Po3 |
| 14 | HQ-SW-2 | Gi0/3 | HQ-SW-3 | Gi0/3 | - | Po3 |
| 15 | HQ-PC1 | eth0 | HQ-SW-1 | Gi3/0 | - | VLAN 10 access, HQ-PUBLIC (Alpine Linux, 연결 확인됨) |
| 16 | HQ-PC2 | eth0 | HQ-SW-1 | Gi3/1 | - | VLAN 20 access, HQ-PRIVATE (Alpine Linux, 연결 확인됨) |

### DC

| # | A 장비 | A 포트 | B 장비 | B 포트 | 서브넷 | 비고 |
|---|---|---|---|---|---|---|
| 17 | DC-R1 | Gi0/0 | DC-SW1-L3 | Et1 | 10.2.0.0/30 | - |
| 18 | DC-R1 | Gi1/0 | DC-SW2-L3 | Et1 | 10.2.0.4/30 | - |
| 19 | DC-R2 | Gi0/0 | DC-SW1-L3 | Et2 | 10.2.0.8/30 | - |
| 20 | DC-R2 | Gi1/0 | DC-SW2-L3 | Et2 | 10.2.0.12/30 | - |
| 21 | DC-SW1-L3 | Et3 | DC-SW2-L3 | Et3 | 10.2.0.16/30 | - |
| 22 | DC-SW1-L3 | Et4 | DC-SW3-L3 | Et1 | 10.2.0.20/30 | L3 링크 |
| 23 | DC-SW1-L3 | Et5 | DC-SW4-L3 | Et1 | 10.2.0.24/30 | L3 링크 |
| 24 | DC-SW2-L3 | Et4 | DC-SW3-L3 | Et2 | 10.2.0.28/30 | L3 링크 |
| 25 | DC-SW2-L3 | Et5 | DC-SW4-L3 | Et2 | 10.2.0.32/30 | L3 링크 |
| 26 | DC-SW3-L3 | Et3 | DC-R3 | Gi0/0 | 10.2.0.36/30 | L3 링크 |
| 27 | DC-SW3-L3 | Et4 | DC-R4 | Gi0/0 | 10.2.0.40/30 | L3 링크 |
| 28 | DC-SW4-L3 | Et3 | DC-R3 | Gi1/0 | 10.2.0.44/30 | L3 링크 |
| 29 | DC-SW4-L3 | Et4 | DC-R4 | Gi1/0 | 10.2.0.48/30 | L3 링크 |
| 30 | DC-R3 | Gi2/0 | DC-R4 | Gi2/0 | 10.2.0.52/30 | - |
| 31 | DC-R1 | Gi2/0 | Private-net | Gi0/0 | 203.0.113.0/30 | PI 연결 |
| 32 | DC-R2 | Gi2/0 | Private-net | Gi1/0 | 203.0.113.4/30 | PI 연결, DMVPN Hub Tunnel0 source |
| 33 | DC-R3 | Gi3/0 | ISP-1-PE-A | Gi3/0 | 100.1.21.0/30 | ISP-1 연결 |
| 34 | DC-R4 | Gi3/0 | ISP-2-PE-A | Gi3/0 | 100.2.22.0/30 | ISP-2 연결 |
| 35 | DC-SW3-L3 | Et5 | DC-SW4-L3 | Et5 | - | Po1 (VLAN 50/100, MLAG peer-link) |
| 36 | DC-SW3-L3 | Et6 | DC-SW4-L3 | Et6 | - | Po1 (MLAG peer-link) |
| 37 | DC-SW3-L3 | Et7 | DC-SW1-L2 | Et1 | - | MLAG 포트채널 Po10(mlag 10) 멤버 |
| 38 | DC-SW3-L3 | Et8 | DC-SW2-L2 | Et1 | - | MLAG 포트채널 Po20(mlag 20) 멤버 |
| 39 | DC-SW4-L3 | Et7 | DC-SW1-L2 | Et2 | - | MLAG 포트채널 Po10(mlag 10) 멤버 |
| 40 | DC-SW4-L3 | Et8 | DC-SW2-L2 | Et2 | - | MLAG 포트채널 Po20(mlag 20) 멤버 |
| 41 | DC-SW1-L2 | Et12 | DC-DNS-1 | eth0 | - | VLAN 50 access (주 DNS, DNS 템플릿, 연결 확인됨) |
| 42 | DC-SW2-L2 | Et12 | DC-DNS-2 | eth0 | - | VLAN 50 access (백업 DNS, DNS 템플릿, 연결 확인됨) |

### BR1

| # | A 장비 | A 포트 | B 장비 | B 포트 | 서브넷 | 비고 |
|---|---|---|---|---|---|---|
| 43 | BR1-SW1-L3 | 1/1/1 | BR1-R1 | Gi0/0 | 10.3.0.0/30 | L3 링크 |
| 44 | BR1-SW1-L3 | 1/1/2 | BR1-R2 | Gi0/0 | 10.3.0.4/30 | L3 링크 |
| 45 | BR1-SW2-L3 | 1/1/1 | BR1-R1 | Gi1/0 | 10.3.0.8/30 | L3 링크 |
| 46 | BR1-SW2-L3 | 1/1/2 | BR1-R2 | Gi1/0 | 10.3.0.12/30 | L3 링크 |
| 47 | BR1-R1 | Gi2/0 | BR1-R2 | Gi2/0 | 10.3.0.16/30 | - |
| 48 | BR1-R1 | Gi3/0 | ISP-1-PE-B | Gi2/0 | 100.1.31.0/30 | ISP-1 연결 |
| 49 | BR1-R2 | Gi3/0 | ISP-2-PE-B | Gi2/0 | 100.2.32.0/30 | ISP-2 연결 |
| 50 | BR1-R1 | Gi4/0 | Private-net | Gi3/0 | 203.0.113.12/30 | PI 연결, DMVPN Spoke Tunnel0 source |
| 51 | BR1-SW1-L3 | 1/1/3 | BR1-SW2-L3 | 1/1/3 | - | LAG 1 (VLAN 10/20/100) |
| 52 | BR1-SW1-L3 | 1/1/4 | BR1-SW2-L3 | 1/1/4 | - | LAG 1 |
| 53 | BR1-SW1-L3 | 1/1/5 | BR1-SW3-L3 | 1/1/1 | - | 트렁크 (연결 확인됨) |
| 54 | BR1-SW2-L3 | 1/1/5 | BR1-SW3-L3 | 1/1/2 | - | 트렁크 (연결 확인됨) |
| 55 | BR1-PC1 | eth0 | BR1-SW3-L3 | 1/1/6 | - | VLAN 10 access, BR1-PUBLIC (Alpine Linux, 연결 확인됨) |
| 56 | BR1-PC2 | eth0 | BR1-SW3-L3 | 1/1/7 | - | VLAN 20 access, BR1-PRIVATE (Alpine Linux, 연결 확인됨) |

### BR2 (BR1과 같은 패턴)

| # | A 장비 | A 포트 | B 장비 | B 포트 | 서브넷 | 비고 |
|---|---|---|---|---|---|---|
| 57 | BR2-SW1-L3 | Gi0/0 | BR2-R1 | Gi0/0 | 10.4.0.0/30 | L3 링크 |
| 58 | BR2-SW1-L3 | Gi0/1 | BR2-R2 | Gi0/0 | 10.4.0.4/30 | L3 링크 |
| 59 | BR2-SW2-L3 | Gi0/0 | BR2-R1 | Gi1/0 | 10.4.0.8/30 | L3 링크 |
| 60 | BR2-SW2-L3 | Gi0/1 | BR2-R2 | Gi1/0 | 10.4.0.12/30 | L3 링크 |
| 61 | BR2-R1 | Gi2/0 | BR2-R2 | Gi2/0 | 10.4.0.16/30 | - |
| 62 | BR2-R1 | Gi3/0 | ISP-1-PE-B | Gi3/0 | 100.1.41.0/30 | ISP-1 연결 |
| 63 | BR2-R2 | Gi3/0 | ISP-2-PE-B | Gi3/0 | 100.2.42.0/30 | ISP-2 연결 |
| 64 | BR2-R2 | Gi4/0 | Private-net | Gi4/0 | 203.0.113.16/30 | PI 연결, DMVPN Spoke Tunnel0 source |
| 65 | BR2-SW1-L3 | Gi1/0 | BR2-SW2-L3 | Gi1/0 | - | Po1 (VLAN 10/20/100) |
| 66 | BR2-SW1-L3 | Gi1/1 | BR2-SW2-L3 | Gi1/1 | - | Po1 |
| 67 | BR2-SW1-L3 | Gi2/0 | BR2-SW3-L2 | Gi0/0 | - | 트렁크 (연결 확인됨) |
| 68 | BR2-SW2-L3 | Gi2/0 | BR2-SW3-L2 | Gi0/1 | - | 트렁크 (연결 확인됨) |
| 69 | BR2-PC1 | eth0 | BR2-SW3-L2 | Gi3/0 | - | VLAN 10 access, BR2-PUBLIC (Alpine Linux, 연결 확인됨) |
| 70 | BR2-PC2 | eth0 | BR2-SW3-L2 | Gi3/1 | - | VLAN 20 access, BR2-PRIVATE (Alpine Linux, 연결 확인됨) |

### ISP-1

| # | A 장비 | A 포트 | B 장비 | B 포트 | 서브넷 | 비고 |
|---|---|---|---|---|---|---|
| 71 | ISP-1-PE-A | Gi0/0 | ISP-1-P1 | Gi0/0 | 100.1.0.0/30 | - |
| 72 | ISP-1-PE-A | Gi1/0 | ISP-1-P2 | Gi0/0 | 100.1.0.4/30 | - |
| 73 | ISP-1-PE-B | Gi0/0 | ISP-1-P1 | Gi1/0 | 100.1.0.8/30 | - |
| 74 | ISP-1-PE-B | Gi1/0 | ISP-1-P2 | Gi1/0 | 100.1.0.12/30 | - |
| 75 | ISP-1-P1 | Gi2/0 | ISP-1-P2 | Gi2/0 | 100.1.0.16/30 | - |

### ISP-2

| # | A 장비 | A 포트 | B 장비 | B 포트 | 서브넷 | 비고 |
|---|---|---|---|---|---|---|
| 76 | ISP-2-PE-A | Gi0/0 | ISP-2-P1 | Gi0/0 | 100.2.0.0/30 | - |
| 77 | ISP-2-PE-A | Gi1/0 | ISP-2-P2 | Gi0/0 | 100.2.0.4/30 | - |
| 78 | ISP-2-PE-B | Gi0/0 | ISP-2-P1 | Gi1/0 | 100.2.0.8/30 | - |
| 79 | ISP-2-PE-B | Gi1/0 | ISP-2-P2 | Gi1/0 | 100.2.0.12/30 | - |
| 80 | ISP-2-P1 | Gi2/0 | ISP-2-P2 | Gi2/0 | 100.2.0.16/30 | - |

## 2. 장비별 사용 포트

| 장비 | 사용 포트 | 개수 |
|---|---|---|
| Private-net | Gi0/0, Gi1/0, Gi2/0, Gi3/0, Gi4/0 | 5 |
| BR1-R1 | Gi0/0, Gi1/0, Gi2/0, Gi3/0, Gi4/0 | 5 |
| BR1-R2 | Gi0/0, Gi1/0, Gi2/0, Gi3/0 | 4 |
| BR1-SW1-L3 | 1/1/1, 1/1/2, 1/1/3, 1/1/4, 1/1/5 | 5 |
| BR1-SW2-L3 | 1/1/1, 1/1/2, 1/1/3, 1/1/4, 1/1/5 | 5 |
| BR1-SW3-L3 | 1/1/1, 1/1/2, 1/1/6, 1/1/7 | 4 |
| BR2-R1 | Gi0/0, Gi1/0, Gi2/0, Gi3/0 | 4 |
| BR2-R2 | Gi0/0, Gi1/0, Gi2/0, Gi3/0, Gi4/0 | 5 |
| BR2-SW1-L3 | Gi0/0, Gi0/1, Gi1/0, Gi1/1, Gi2/0 | 5 |
| BR2-SW2-L3 | Gi0/0, Gi0/1, Gi1/0, Gi1/1, Gi2/0 | 5 |
| BR2-SW3-L2 | Gi0/0, Gi0/1, Gi3/0, Gi3/1 | 4 |
| DC-R1 | Gi0/0, Gi1/0, Gi2/0 | 3 |
| DC-R2 | Gi0/0, Gi1/0, Gi2/0 | 3 |
| DC-R3 | Gi0/0, Gi1/0, Gi2/0, Gi3/0 | 4 |
| DC-R4 | Gi0/0, Gi1/0, Gi2/0, Gi3/0 | 4 |
| DC-SW1-L2 | Et1, Et2, Et12 | 3 |
| DC-SW1-L3 | Et1, Et2, Et3, Et4, Et5 | 5 |
| DC-SW2-L2 | Et1, Et2, Et12 | 3 |
| DC-SW2-L3 | Et1, Et2, Et3, Et4, Et5 | 5 |
| DC-SW3-L3 | Et1, Et2, Et3, Et4, Et5, Et6, Et7, Et8 | 8 |
| DC-SW4-L3 | Et1, Et2, Et3, Et4, Et5, Et6, Et7, Et8 | 8 |
| HQ-R1 | Gi0/0, Gi1/0, Gi2/0, Gi3/0 | 4 |
| HQ-R2 | Gi0/0, Gi1/0, Gi2/0, Gi3/0, Gi4/0 | 5 |
| HQ-SW-1 | Gi1/0, Gi1/1, Gi1/2, Gi1/3, Gi3/0, Gi3/1 | 6 |
| HQ-SW-2 | Gi0/0, Gi0/1, Gi0/2, Gi0/3, Gi1/0, Gi1/1 | 6 |
| HQ-SW-3 | Gi0/0, Gi0/1, Gi0/2, Gi0/3, Gi1/0, Gi1/1 | 6 |
| ISP-1-P1 | Gi0/0, Gi1/0, Gi2/0 | 3 |
| ISP-1-P2 | Gi0/0, Gi1/0, Gi2/0 | 3 |
| ISP-1-PE-A | Gi0/0, Gi1/0, Gi2/0, Gi3/0 | 4 |
| ISP-1-PE-B | Gi0/0, Gi1/0, Gi2/0, Gi3/0 | 4 |
| ISP-2-P1 | Gi0/0, Gi1/0, Gi2/0 | 3 |
| ISP-2-P2 | Gi0/0, Gi1/0, Gi2/0 | 3 |
| ISP-2-PE-A | Gi0/0, Gi1/0, Gi2/0, Gi3/0 | 4 |
| ISP-2-PE-B | Gi0/0, Gi1/0, Gi2/0, Gi3/0 | 4 |

## 3. 비고

- BR1·BR2 스위치↔라우터 L3 링크 4개씩의 서브넷: `10.3.0.0/30` – `10.3.0.12/30`, `10.4.0.0/30` – `10.4.0.12/30`(HQ 패턴).
- HQ 호스트의 VLAN: `HQ-PC1` VLAN 10(HQ-PUBLIC), `HQ-PC2` VLAN 20(HQ-PRIVATE). 두 호스트 모두 DHCP로 주소를 받음.
- BR1·BR2 호스트의 VLAN: `BR1-PC1`, `BR2-PC1` VLAN 10(PUBLIC), `BR1-PC2`, `BR2-PC2` VLAN 20(PRIVATE). 두 호스트 모두 DHCP로 주소를 받음.
- 서버 IP는 고정(`docs/ip-mapping.md`), 호스트 IP는 DHCP(`docs/dhcp-dns-design.md`).
