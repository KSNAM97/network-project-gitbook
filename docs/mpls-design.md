# MPLS 설계

ISP-1, ISP-2 코어에 MPLS L3VPN을 적용하는 구성을 정리한 문서. ISP 내부 OSPF(`docs/ospf-design.md`)와 iBGP Route Reflector(`docs/bgp-design.md`) 위에 LDP, VRF, MP-BGP(vpnv4)를 추가. 사이트 라우터의 설정(eBGP, route-map, OSPF 기본 경로 광고)은 바뀌지 않고 ISP PE만 달라짐. 링크 IP는 `docs/ip-mapping.md`, 포트는 `docs/port-mapping.md` 기준.

## 1. 구성 개요

- 각 ISP는 독립된 MPLS 도메인(ISP-1과 ISP-2는 서로 연결되지 않음). PE-A, PE-B가 PE, P1, P2가 P 라우터이면서 BGP RR.
- 데이터 경로: 사이트 → 기본 경로 → PE(VRF 조회) → vpnv4 경로의 next-hop(상대 PE Loopback0)까지 레이블 스위칭(P 라우터는 레이블만 조회) → 상대 PE(VRF 조회) → 사이트.
- 사이트 라우터는 PE에서 기본 경로만 받음(`docs/bgp-design.md` 6절). 사이트 /16은 PE의 VRF에서 vpnv4로 상대 PE에 전달.

## 2. LDP (MPLS 코어)

- ISP 내부 링크(링크 # 71-75, 76-80)에서만 MPLS 활성화. 사이트 방향 링크는 VRF 인터페이스이므로 `mpls ip` 사용 안 함.
- LDP Router ID는 Loopback0(`mpls ldp router-id lo0 force`). Loopback0 `/32`는 ISP 내부 OSPF로 도달(`docs/ospf-design.md`).
- `force`는 LDP가 이미 다른 Router ID로 동작 중일 때 즉시 바꾸는 옵션(세션이 재시작됨). 구성 순서를 `mpls ldp router-id` 먼저, 인터페이스 `mpls ip` 나중으로 하면 필요 없고, 이미 `mpls ip`를 켠 뒤 Loopback0으로 바꿔야 할 때만 사용.
- `mpls label protocol ldp`(표준 LDP), `mpls label range <시작> <끝>`(장비마다 레이블 구간을 나눔), 인터페이스에 `mpls ip`. 타이머와 인증은 기본값.

| 장비 | `mpls ip` 인터페이스 | 링크 # (ISP-1 / ISP-2) |
|---|---|---|
| PE-A | Gi0/0, Gi1/0 | 71, 72 / 76, 77 |
| P1 | Gi0/0, Gi1/0, Gi2/0 | 71, 73, 75 / 76, 78, 80 |
| P2 | Gi0/0, Gi1/0, Gi2/0 | 72, 74, 75 / 77, 79, 80 |
| PE-B | Gi0/0, Gi1/0 | 73, 74 / 78, 79 |

레이블 구간(`mpls label range <시작> <끝>`). 첫째 자리는 ISP, 둘째 자리는 장비 순서(PE-A 1, P1 2, P2 3, PE-B 4, Loopback0 마지막 자리와 같음)이며 구간이 겹치지 않아 `show mpls forwarding-table`의 레이블 숫자로 붙인 장비를 알 수 있음. 레이블 16 미만은 예약.

| 장비 | ISP-1 | ISP-2 |
|---|---|---|
| PE-A | 11000 11999 | 21000 21999 |
| P1 | 12000 12999 | 22000 22999 |
| P2 | 13000 13999 | 23000 23999 |
| PE-B | 14000 14999 | 24000 24999 |

## 3. VRF

- ISP마다 VRF 하나(`corp`)로 네 사이트를 같은 VPN에 연결. VRF는 PE-A, PE-B에만 존재하고 P1, P2에는 없음.
- RD와 RT는 ISP의 AS 번호 기준. RT export와 import를 같은 값으로 두어 사이트끼리 전부 도달.

| ISP   | VRF  | RD      | route-target export / import |
| ----- | ---- | ------- | ---------------------------- |
| ISP-1 | corp | 65100:1 | 65100:1 / 65100:1            |
| ISP-2 | corp | 65200:1 | 65200:1 / 65200:1            |

- 사이트 방향 포트를 VRF 인터페이스로 지정(`ip vrf forwarding corp`). 이 명령을 넣으면 기존 IP가 지워지므로 `ip addr`를 다시 입력.

| PE 장비 | 포트 | 링크 # | 사이트 장비(CE) |
|---|---|---|---|
| ISP-1-PE-A | Gi2/0 | 6 | HQ-R1 |
| ISP-1-PE-A | Gi3/0 | 33 | DC-R3 |
| ISP-1-PE-B | Gi2/0 | 48 | BR1-R1 |
| ISP-1-PE-B | Gi3/0 | 62 | BR2-R1 |
| ISP-2-PE-A | Gi2/0 | 7 | HQ-R2 |
| ISP-2-PE-A | Gi3/0 | 34 | DC-R4 |
| ISP-2-PE-B | Gi2/0 | 49 | BR1-R2 |
| ISP-2-PE-B | Gi3/0 | 63 | BR2-R2 |

## 4. MP-BGP (vpnv4)

- 기존 iBGP 세션(10세션, Loopback0 주소)에 `address-family vpnv4`를 추가. PE는 RR(P1, P2) 두 대와, RR은 PE 두 대와 P1–P2 세션에서 vpnv4를 활성화.
- RR 쪽: `neighbor <PE-lo0> route-reflector-client`를 vpnv4 주소군에도 적용, `send-community extended`. PE 쪽: `send-community extended`.
- vpnv4 경로의 next-hop은 PE Loopback0이며 LDP 레이블로 도달. 그래서 IPv4 유니캐스트 세션의 `next-hop-self`는 이 구성에서 사용되지 않으나 그대로 유지.
- 사이트 엣지 eBGP는 PE의 `address-family ipv4 vrf corp` 안에서 구성(세션 주소, prefix-list, `default-originate`, `timers 3 9`는 `docs/bgp-design.md` 5~6절 값 그대로).

## 5. MTU

- 레이블 1개당 4바이트 증가. vpnv4 경로는 레이블 2개(전송 레이블, VPN 레이블)가 붙어 8바이트 증가.
- 기본 크기의 `ping`, `traceroute`는 영향이 없으며 큰 패킷 시험이 필요할 때만 ISP 내부 링크의 `mtu`를 1520으로 조정.

## 6. 검증 항목

| 항목 | 명령 | 기대 결과 |
|---|---|---|
| LDP 이웃 | `show mpls ldp neighbor` | 내부 링크마다 이웃 Oper, 레이블 교환 |
| 레이블 테이블 | `show mpls forwarding-table` | 상대 장비 Loopback0 `/32`에 대한 레이블 |
| VRF | `show ip vrf`, `show ip vrf interfaces` | `corp`, 사이트 방향 포트 소속 |
| vpnv4 세션 | `show ip bgp vpnv4 all summary` | RR 3세션, PE 2세션 Established |
| VRF 경로 | `show ip route vrf corp` | 사이트 /16(CE에서 eBGP, 상대 PE에서 vpnv4) |
| 경로 확인 | `traceroute`(사이트 호스트에서 다른 사이트로) | ISP 구간에 `[MPLS: Label ...]` 표시 |

## 7. 일정

- 주말(10/17~10/18): LDP, VRF, vpnv4 선행 구성(사이트 CE 없이 `show` 확인 가능).
- 2주 월(10/19): 사이트 엣지 eBGP를 VRF 안에서 구성(KAN-18).
