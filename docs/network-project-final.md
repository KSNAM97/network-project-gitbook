# 멀티벤더 하이브리드 네트워크 프로젝트 — 최종 설계

## 1. 전체 구조

```
HQ(65001) ─┬─ ISP-1 ─┐
           └─ ISP-2 ─┤
DC(65002) ─┬─ ISP-1 ─┼─ ISP 내부 iBGP RR, 사이트 엣지 eBGP
           └─ ISP-2 ─┤
BR1        ─┬─ ISP-1 ─┤
           └─ ISP-2 ─┤
BR2        ─┬─ ISP-1 ─┘
           └─ ISP-2 ─┘

DC ←── DMVPN Phase3(mGRE over IPsec, Private Internet 경유) ──→ HQ, BR1, BR2
```

- 사이트(HQ/DC/BR1/BR2) 내부: OSPF(프로세스와 Area는 `docs/ospf-design.md`), 사이트 엣지 라우터만 ISP와 eBGP
- ISP-1/ISP-2: ISP별 단일 AS의 iBGP Route Reflector(P1, P2 RR), ISP 내부 OSPF process 1 Area 0
- ISP 코어: MPLS L3VPN(내부 링크 LDP, PE의 VRF `corp`, vpnv4는 iBGP RR 경유, `docs/mpls-design.md`)
- 사이트 ↔ ISP: 사이트 엣지 eBGP(사이트 AS ↔ ISP AS), PE가 기본 경로 전달, 사이트 /16 광고(route-map, prefix-list), 사이트 OSPF에 기본 경로 광고
- Private Internet(DMVPN 언더레이): 별도 OSPF 프로세스(2), ACL 화이트리스트
- DC 스위치는 Arista vEOS-lab, BR1 스위치는 Aruba AOS-CX, 나머지 전부 Cisco (7200 / IOU)

## 2. 사이트 · AS

| 사이트 | AS | 대역 | 비고 |
|---|---|---|---|
| HQ | 65001 | 10.1.0.0/16 | OSPF 프로세스11 Area1, DMVPN Spoke(HQ-R2) |
| DC | 65002 | 10.2.0.0/16 | OSPF 프로세스10 Area0, DMVPN Hub(DC-R2), 백업 Hub(DC-R1) |
| BR1 | 65003 | 10.3.0.0/16 | OSPF 프로세스12 Area2, DMVPN Spoke(BR1-R1) |
| BR2 | 65004 | 10.4.0.0/16 | OSPF 프로세스13 Area3, DMVPN Spoke(BR2-R2) |
| ISP-1 | 65100 (P1, P2 RR / PE-A, PE-B Client) | 100.1.0.0/16 | iBGP RR + ISP 내부 OSPF |
| ISP-2 | 65200 (P1, P2 RR / PE-A, PE-B Client) | 100.2.0.0/16 | iBGP RR + ISP 내부 OSPF |
| Private Internet | 없음(BGP 미사용) | 203.0.113.0/24 | OSPF 프로세스2 Area100, DMVPN 언더레이 전용 |
| DMVPN 터널 | - | 172.16.0.0/24 | Area0(DC 프로세스10, HQ 프로세스11, BR1 프로세스12, BR2 프로세스13) |

폐기된 AS: 65000, 65006, 65007, 65010, 65020 (설계 변경 과정에서 대체됨)

## 3. VLAN

| 사이트 | VLAN | 이름 | 서브넷 | 게이트웨이 이중화 |
|---|---|---|---|---|
| HQ | 10 | HQ-PUBLIC | 10.1.10.0/24 | VRRP (HQ-SW-2 .2 / HQ-SW-3 .3, VIP .1) |
| HQ | 20 | HQ-PRIVATE | 10.1.20.0/24 | VRRP |
| DC | 50 | SERVER (DC-DNS-1, DC-DNS-2) | 10.2.50.0/24 | VRRP (DC-SW3-L3 .2 / DC-SW4-L3 .3, VIP .1) |
| BR1 | 10 | BR1-PUBLIC | 10.3.10.0/24 | VRRP |
| BR1 | 20 | BR1-PRIVATE | 10.3.20.0/24 | VRRP |
| BR2 | 10 | BR2-PUBLIC | 10.4.10.0/24 | VRRP |
| BR2 | 20 | BR2-PRIVATE | 10.4.20.0/24 | VRRP |
| 전 사이트 | 100 | MGMT | 10.X.100.0/24 | - |
| 전 사이트 | 999 | NATIVE | IP 없음 | 모든 트렁크 native |

## 3-1. GNS3 장비명 대응표

이 문서, 컨피그 파일(`configs/<사이트>/<계층>/<장비명>.<ios|eos>`), 장비 hostname은 GNS3 장비명을 기준으로 사용. 아래 표는 초기 설계에서 쓰던 이름(설계 장비명)과의 대응이며 예전 자료 참조용. 대응 관계는 GNS3 케이블링과 대조하여 확정.

| 사이트 | GNS3 장비명 (기준) | 초기 설계명 | 역할 | 비고 |
|---|---|---|---|---|
| Private Internet | Private-net | PI | DMVPN 언더레이 | |
| HQ | HQ-R1 / HQ-R2 | R11 / R12 | 라우터(R12가 DMVPN Spoke) | |
| HQ | HQ-SW-1 | SW110 | L3 스위치 | |
| HQ | HQ-SW-2 / HQ-SW-3 | SW101 / SW102 | L3 스위치(VRRP) | |
| HQ | HQ-PC1 / HQ-PC2 | - | 호스트(Alpine Linux, docker) | |
| DC | DC-R1 / DC-R2 | R23 / R24 | 라우터(PI 연결) | R24가 DMVPN Hub |
| DC | DC-R3 / DC-R4 | R21 / R22 | 라우터(ISP 연결) | |
| DC | DC-SW1-L3 / DC-SW2-L3 | SW211 / SW212 | L3 스위치(Arista vEOS-lab) | |
| DC | DC-SW3-L3 / DC-SW4-L3 | SW201 / SW202 | L3 스위치(Arista vEOS-lab, VRRP) | |
| DC | DC-SW1-L2 / DC-SW2-L2 | SW-SVR1 / SW-SVR2 | 서버용 L2 스위치(Arista vEOS-lab) | |
| DC | DC-DNS-1 / DC-DNS-2 | DNS1(주) / DNS2(백업) | 서버(VLAN50, DNS 템플릿, docker) | |
| ISP-1 | ISP-1-PE-A / ISP-1-P1 / ISP-1-P2 / ISP-1-PE-B | PE-A / P1 / P2 / PE-B | iBGP RR | |
| ISP-2 | ISP-2-PE-A / ISP-2-P1 / ISP-2-P2 / ISP-2-PE-B | PE-A / P1 / P2 / PE-B | iBGP RR | |
| BR1 | BR1-R1 / BR1-R2 | R1 / R2 | 라우터(R1이 DMVPN Spoke) | |
| BR1 | BR1-SW1-L3 / BR1-SW2-L3 / BR1-SW3-L3 | SW1 / SW2 / SW3 | 스위치(Aruba CX, SW3은 호스트 연결) | |
| BR1 | BR1-PC1 / BR1-PC2 | H1 / H2 | 호스트(Alpine Linux, docker) | |
| BR2 | BR2-R1 / BR2-R2 | R1 / R2 | 라우터(R2가 DMVPN Spoke) | |
| BR2 | BR2-SW1-L3 / BR2-SW2-L3 | SW1 / SW2 | L3 스위치 | |
| BR2 | BR2-SW3-L2 | SW3 | 호스트 연결 L2 스위치 | |
| BR2 | BR2-PC1 / BR2-PC2 | H1 / H2 | 호스트(Alpine Linux, docker) | |

## 4. 인터페이스 · 포트 매핑 (GNS3 연결 대조 완료 — 2026-10-11)

링크 단위 전체 표: [`docs/port-mapping.md`](./port-mapping.md)

### HQ
| A | B | 서브넷/용도 |
|---|---|---|
| HQ-SW-2 Gi1/0 | HQ-R1 Gi0/0 | 10.1.0.0/30 |
| HQ-SW-2 Gi1/1 | HQ-R2 Gi0/0 | 10.1.0.4/30 |
| HQ-SW-3 Gi1/0 | HQ-R1 Gi1/0 | 10.1.0.8/30 |
| HQ-SW-3 Gi1/1 | HQ-R2 Gi1/0 | 10.1.0.12/30 |
| HQ-R1 Gi2/0 | HQ-R2 Gi2/0 | 10.1.0.16/30 |
| HQ-R1 Gi3/0 | ISP-1-PE-A Gi2/0 | 100.1.11.0/30 |
| HQ-R2 Gi3/0 | ISP-2-PE-A Gi2/0 | 100.2.12.0/30 |
| HQ-R2 Gi4/0 | Private-net Gi2/0 | 203.0.113.8/30 (Tunnel0 source, DMVPN Spoke) |
| HQ-SW-1 Gi1/0 | HQ-SW-2 Gi0/0 | Po1 (VLAN10/20/100) |
| HQ-SW-1 Gi1/1 | HQ-SW-2 Gi0/1 | Po1 |
| HQ-SW-1 Gi1/2 | HQ-SW-3 Gi0/0 | Po2 |
| HQ-SW-1 Gi1/3 | HQ-SW-3 Gi0/1 | Po2 |
| HQ-SW-2 Gi0/2 | HQ-SW-3 Gi0/2 | Po3 |
| HQ-SW-2 Gi0/3 | HQ-SW-3 Gi0/3 | Po3 |
| HQ-PC1 eth0 | HQ-SW-1 Gi3/0 | VLAN10 access |
| HQ-PC2 eth0 | HQ-SW-1 Gi3/1 | VLAN20 access |
| **QoS 대상** | HQ-R1 Gi0/0, Gi1/0 / HQ-R2 Gi0/0, Gi1/0 |

### DC
| A | B | 서브넷/용도 |
|---|---|---|
| DC-R1 Gi0/0 | DC-SW1-L3 Et1 | 10.2.0.0/30 |
| DC-R1 Gi1/0 | DC-SW2-L3 Et1 | 10.2.0.4/30 |
| DC-R2 Gi0/0 | DC-SW1-L3 Et2 | 10.2.0.8/30 |
| DC-R2 Gi1/0 | DC-SW2-L3 Et2 | 10.2.0.12/30 |
| DC-SW1-L3 Et3 | DC-SW2-L3 Et3 | 10.2.0.16/30 |
| DC-SW1-L3 Et4 | DC-SW3-L3 Et1 | 10.2.0.20/30 (L3) |
| DC-SW1-L3 Et5 | DC-SW4-L3 Et1 | 10.2.0.24/30 (L3) |
| DC-SW2-L3 Et4 | DC-SW3-L3 Et2 | 10.2.0.28/30 (L3) |
| DC-SW2-L3 Et5 | DC-SW4-L3 Et2 | 10.2.0.32/30 (L3) |
| DC-SW3-L3 Et3 | DC-R3 Gi0/0 | 10.2.0.36/30 (L3) |
| DC-SW3-L3 Et4 | DC-R4 Gi0/0 | 10.2.0.40/30 (L3) |
| DC-SW4-L3 Et3 | DC-R3 Gi1/0 | 10.2.0.44/30 (L3) |
| DC-SW4-L3 Et4 | DC-R4 Gi1/0 | 10.2.0.48/30 (L3) |
| DC-R3 Gi2/0 | DC-R4 Gi2/0 | 10.2.0.52/30 |
| DC-R1 Gi2/0 | Private-net Gi0/0 | 203.0.113.0/30 |
| DC-R2 Gi2/0 | Private-net Gi1/0 | 203.0.113.4/30 (Tunnel0 source) |
| DC-R3 Gi3/0 | ISP-1-PE-A Gi3/0 | 100.1.21.0/30 |
| DC-R4 Gi3/0 | ISP-2-PE-A Gi3/0 | 100.2.22.0/30 |
| DC-SW3-L3 Et5 | DC-SW4-L3 Et5 | Po1 (VLAN50/100) |
| DC-SW3-L3 Et6 | DC-SW4-L3 Et6 | Po1 |
| DC-SW3-L3 Et7 | DC-SW1-L2 Et1 | 트렁크 (연결 확인됨) |
| DC-SW3-L3 Et8 | DC-SW2-L2 Et1 | 트렁크 (연결 확인됨) |
| DC-SW4-L3 Et7 | DC-SW1-L2 Et2 | 트렁크 (연결 확인됨) |
| DC-SW4-L3 Et8 | DC-SW2-L2 Et2 | 트렁크 (연결 확인됨) |
| DC-SW1-L2 Et12 | DC-DNS-1 (VLAN50 access) |
| DC-SW2-L2 Et12 | DC-DNS-2 (VLAN50 access, 백업) |
| **QoS 대상** | DC-R3 Gi0/0,Gi1/0 / DC-R4 Gi0/0,Gi1/0 / DC-R1 Gi0/0,Gi1/0 / DC-R2 Gi0/0,Gi1/0 |

### BR1 (BR2는 10.3→10.4, 장비명 BR2-*, ISP 링크 하단 표 참고)
| A | B | 서브넷/용도 |
|---|---|---|
| BR1-SW1-L3 1/1/1 | BR1-R1 Gi0/0 | 10.3.0.0/30 |
| BR1-SW1-L3 1/1/2 | BR1-R2 Gi0/0 | 10.3.0.4/30 |
| BR1-SW2-L3 1/1/1 | BR1-R1 Gi1/0 | 10.3.0.8/30 |
| BR1-SW2-L3 1/1/2 | BR1-R2 Gi1/0 | 10.3.0.12/30 |
| BR1-R1 Gi2/0 | BR1-R2 Gi2/0 | 10.3.0.16/30 |
| BR1-R1 Gi3/0 | ISP-1-PE-B Gi2/0 | 100.1.31.0/30 |
| BR1-R2 Gi3/0 | ISP-2-PE-B Gi2/0 | 100.2.32.0/30 |
| BR1-R1 Gi4/0 | Private-net Gi3/0 | 203.0.113.12/30 (Tunnel0 source, DMVPN Spoke) |
| BR1-SW1-L3 1/1/3 | BR1-SW2-L3 1/1/3 | LAG 1 (VLAN10/20/100) |
| BR1-SW1-L3 1/1/4 | BR1-SW2-L3 1/1/4 | LAG 1 |
| BR1-SW1-L3 1/1/5 | BR1-SW3-L3 1/1/1 | 트렁크 (연결 확인됨) |
| BR1-SW2-L3 1/1/5 | BR1-SW3-L3 1/1/2 | 트렁크 (연결 확인됨) |
| BR1-PC1 eth0 | BR1-SW3-L3 1/1/6 | VLAN10 access |
| BR1-PC2 eth0 | BR1-SW3-L3 1/1/7 | VLAN20 access |
| **QoS 대상** | BR1-R1 Gi0/0,Gi1/0 / BR1-R2 Gi0/0,Gi1/0 |

### BR2 (BR1과 동일 패턴, 장비명 BR2-*, 스포크는 BR2-R2)
| 링크 | 서브넷 |
|---|---|
| BR2-R1 Gi3/0 ↔ ISP-1-PE-B Gi3/0 | 100.1.41.0/30 |
| BR2-R2 Gi3/0 ↔ ISP-2-PE-B Gi3/0 | 100.2.42.0/30 |
| BR2-R2 Gi4/0 ↔ Private-net Gi4/0 | 203.0.113.16/30 (Tunnel0 source, DMVPN Spoke) |

### ISP-1 (ISP-2는 같은 구조이며 장비명 ISP-2-*, 100.1→100.2, AS +10)
| A | B | 서브넷 |
|---|---|---|
| ISP-1-PE-A Gi0/0 | ISP-1-P1 Gi0/0 | 100.1.0.0/30 |
| ISP-1-PE-A Gi1/0 | ISP-1-P2 Gi0/0 | 100.1.0.4/30 |
| ISP-1-PE-B Gi0/0 | ISP-1-P1 Gi1/0 | 100.1.0.8/30 |
| ISP-1-PE-B Gi1/0 | ISP-1-P2 Gi1/0 | 100.1.0.12/30 |
| ISP-1-P1 Gi2/0 | ISP-1-P2 Gi2/0 | 100.1.0.16/30 |

### DMVPN
| 장비 | Tunnel0 | NBMA(source) | 역할 |
|---|---|---|---|
| DC-R2 | 172.16.0.1/24 | 203.0.113.5 | Hub, priority 255, mGRE over IPsec transport |
| DC-R1 | 172.16.0.2/24 | 203.0.113.1 | 백업 Hub, priority 200(2026-10-19 추가, `docs/dmvpn-design.md` 7절) |
| HQ-R2 | 172.16.0.13/24 | 203.0.113.9 | Spoke, priority 0, shortcut |
| BR1-R1 | 172.16.0.11/24 | 203.0.113.13 | Spoke, priority 0, shortcut |
| BR2-R2 | 172.16.0.12/24 | 203.0.113.17 | Spoke, priority 0, shortcut |

## 5. 정책

### Private Internet ACL (화이트리스트, 5개 링크 전부)
- permit OSPF(224.0.0.5/6), GRE/ESP/UDP500(203.0.113.0/24 간), ICMP(임시)
- deny ip any any log

### QoS (사이트↔스위치 라우터 인터페이스, 총 20포트)
- 위치: HQ-R1/HQ-R2, DC-R1~DC-R4, BR1-R1/BR1-R2, BR2-R1/BR2-R2 — 각 Gi0/0, Gi1/0
- 제외: 라우터간 링크, ISP 방향, PI 방향, Tunnel0
- 클래스: CONTROL(DSCP CS6, 10%) / BUSINESS(DNS 53을 ACL로 분류, AF31 표시, 30%) / class-default(fair-queue). 상세는 `docs/qos-design.md`
- 부모 정책: shape average (병목 검증용 예시값, 실측 시 조정)

### 접근 통제
- DC VLAN50(DC-DNS-1, DC-DNS-2): 각 사이트 → UDP/TCP 53만 허용, 그 외 차단. 적용 위치는 DC-R1~R4의 Gi0/0, Gi1/0 출력 방향(cEOS는 인터페이스 ACL 미지원). DHCP는 각 사이트 게이트웨이에서 제공하므로 서버 VLAN으로 DHCP(UDP 67/68) 허용 없음.

## 6. 빌드 순서 (계획 3.5주, 실제 2주, 1인 체제)

기간: 2026-10-12(월) ~ 2026-11-04(수, 반일). 일별 목표는 `docs/schedule.md` 참고.

| 주차 | 내용 |
|---|---|
| 1주 | AS/IP/VLAN 확정, GNS3 환경 세팅, 이미지별 RAM 실측(cEOS 포함), 노드 배치, 사이트 내부 L2/L3(VLAN, 트렁크, EtherChannel, VRRP, MSTP, 사이트 내부 OSPF, 사이트 DHCP) |
| 2주 | 사이트↔ISP 엣지 eBGP+OSPF 기본 경로 광고, PI ACL, DMVPN(mGRE over IPsec), DNS 서버, 서버 VLAN ACL |
| 3주 | 이중화 장애 실측(VRRP, EtherChannel, DMVPN Hub 장애), ISP 내부 iBGP RR, ISP 장애 실측, QoS 정책, 트러블슈팅 로그 |
| 3.5주 | PPT 제작, 리허설 |

## 7. 비고
- DC 서버 VLAN50: DC-DNS-1(주), DC-DNS-2(백업) 두 대, GNS3 `DNS` 템플릿(Debian 계열) 이미지, `dnsmasq`로 DNS 제공(`docs/dhcp-dns-design.md`). DHCP는 사용자 VLAN 게이트웨이 스위치 두 대가 풀을 나눠 제공.
- QoS는 사이트 스위치와 연결된 라우터 인터페이스 20포트에 적용하며 스위치 QoS는 적용하지 않음.

## 8. 상세 설계 문서

| 영역 | 문서 |
|---|---|
| 포트·IP | `docs/port-mapping.md`, `docs/ip-mapping.md` |
| 라우팅 | `docs/ospf-design.md`, `docs/bgp-design.md` |
| L2·게이트웨이 | `docs/vlan-design.md`, `docs/vrrp-mstp-design.md` |
| 터널·암호화 | `docs/dmvpn-design.md` |
| 서비스 | `docs/dhcp-dns-design.md` |
| 설정 가이드 | `docs/config-guide/README.md`(공통 규칙), 장비별 `docs/config-guide/*.md` |
| 문서 목차 | `docs/README.md` |
