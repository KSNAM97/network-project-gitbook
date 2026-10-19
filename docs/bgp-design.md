# BGP 설계

ISP-1, ISP-2 내부의 iBGP Route Reflector와 사이트 엣지 eBGP(사이트 라우터 ↔ ISP PE) 구성을 정리한 문서. ISP 쪽은 MPLS L3VPN으로 확장되어 PE가 VRF `corp` 안에서 사이트와 eBGP를 맺고 사이트 경로를 vpnv4로 전달(`docs/mpls-design.md`). Private Internet은 BGP 미사용. ISP-1과 ISP-2는 서로 연결되지 않으며 둘 사이 BGP 세션 없음. 링크 IP는 `docs/ip-mapping.md`, 포트는 `docs/port-mapping.md` 기준.

## 1. AS 구성

- ISP 내부는 ISP마다 단일 AS의 iBGP. P1, P2가 Route Reflector(RR), PE-A, PE-B가 RR Client.
- P1, P2는 같은 `bgp cluster-id`를 사용하는 이중 RR. Client가 P1, P2 양쪽과 세션을 맺어 RR 한 대 장애 시에도 경로 유지, 같은 cluster-id로 중복 반사 경로 억제.
- 사이트 엣지는 사이트 라우터(사이트 AS)와 ISP PE(ISP AS) 사이 eBGP. 사이트는 ISP-1과 ISP-2에 서로 다른 라우터로 각각 연결.
- 사이트끼리는 BGP 세션 없음. 사이트 내부는 OSPF(`docs/ospf-design.md`).

| ISP | AS | 대역 | RR (P1, P2) | RR Client | cluster-id |
|---|---|---|---|---|---|
| ISP-1 | 65100 | 100.1.0.0/16 | ISP-1-P1, ISP-1-P2 | ISP-1-PE-A, ISP-1-PE-B | 1.1.1.1 |
| ISP-2 | 65200 | 100.2.0.0/16 | ISP-2-P1, ISP-2-P2 | ISP-2-PE-A, ISP-2-PE-B | 2.2.2.2 |

| 사이트 | AS | 사이트 prefix | 엣지 라우터(ISP-1 연결, ISP-2 연결) |
|---|---|---|---|
| HQ | 65001 | 10.1.0.0/16 | HQ-R1, HQ-R2 |
| DC | 65002 | 10.2.0.0/16 | DC-R3, DC-R4 |
| BR1 | 65003 | 10.3.0.0/16 | BR1-R1, BR1-R2 |
| BR2 | 65004 | 10.4.0.0/16 | BR2-R1, BR2-R2 |

## 2. Router ID (Loopback0)

- ISP 장비: ISP-1 `100.100.100.<n>`, ISP-2 `200.200.200.<n>`. 번호는 PE-A 1, P1 2, P2 3, PE-B 4. Loopback0 `/32`와 `bgp router-id`에 같은 값 사용.
- ISP 장비의 Loopback0은 iBGP 세션 주소와 `update-source`로 사용하며, ISP 내부 OSPF로 서로 도달.
- 사이트 엣지 라우터는 OSPF와 같은 Loopback0 값(`docs/ospf-design.md` 2절)을 `bgp router-id`로 사용.

| 장비 | 역할 | Router ID / Loopback0 |
|---|---|---|
| ISP-1-PE-A | RR Client | 100.100.100.1/32 |
| ISP-1-P1 | RR | 100.100.100.2/32 |
| ISP-1-P2 | RR | 100.100.100.3/32 |
| ISP-1-PE-B | RR Client | 100.100.100.4/32 |
| ISP-2-PE-A | RR Client | 200.200.200.1/32 |
| ISP-2-P1 | RR | 200.200.200.2/32 |
| ISP-2-P2 | RR | 200.200.200.3/32 |
| ISP-2-PE-B | RR Client | 200.200.200.4/32 |
| HQ-R1, HQ-R2 | 사이트 엣지 | 11.11.11.1, 11.11.11.2 |
| DC-R3, DC-R4 | 사이트 엣지 | 10.10.10.3, 10.10.10.4 |
| BR1-R1, BR1-R2 | 사이트 엣지 | 12.12.12.1, 12.12.12.2 |
| BR2-R1, BR2-R2 | 사이트 엣지 | 13.13.13.1, 13.13.13.2 |

## 3. ISP 내부 OSPF (iBGP 도달성)

- ISP 내부 링크와 Loopback0 도달성 확보용. process 1, Area 0, router-id는 Loopback0 값. 인터페이스 소속과 네트워크 타입(point-to-point)은 `docs/ospf-design.md` 1~3절 표 기준.
- 대상: ISP 내부 링크(링크 # 71-75, 76-80)와 Loopback0. 사이트 방향 링크(PE–사이트)는 포함하지 않음(eBGP 세션 주소로만 사용).
- 사이트 방향 인터페이스에는 OSPF를 켜지 않으며, Loopback0는 `ip ospf 1 area 0`으로 광고.

## 4. iBGP 세션

- ISP당 5세션, 합계 10세션. Loopback0 주소로 세션을 맺고 `neighbor <peer-lo0> update-source lo0` 적용.
- P1–P2는 RR끼리 일반 iBGP(non-client) 피어. PE는 RR 두 대와만 세션을 맺으며 PE끼리는 세션 없음.
- RR 쪽 설정: `neighbor <PE-lo0> route-reflector-client`.
- vpnv4: 위 10세션에 `address-family vpnv4`를 추가(`docs/mpls-design.md` 4절).
- PE 쪽 설정: RR와의 세션에 `neighbor <RR-lo0> next-hop-self`. 사이트 eBGP로 배운 경로의 next-hop이 사이트 방향 링크 주소라 ISP 내부에서 도달할 수 없으므로 PE Loopback0으로 바꿔서 전달. MPLS L3VPN에서는 사이트 경로가 vpnv4로 전달되고 next-hop이 PE Loopback0이라 필수는 아니지만 그대로 유지.

| # | 링크 # | RR 장비 | RR Loopback0 | 상대 장비 | 상대 Loopback0 | 관계 |
|---|---|---|---|---|---|---|
| 1 | 71 | ISP-1-P1 | 100.100.100.2 | ISP-1-PE-A | 100.100.100.1 | Client |
| 2 | 72 | ISP-1-P2 | 100.100.100.3 | ISP-1-PE-A | 100.100.100.1 | Client |
| 3 | 73 | ISP-1-P1 | 100.100.100.2 | ISP-1-PE-B | 100.100.100.4 | Client |
| 4 | 74 | ISP-1-P2 | 100.100.100.3 | ISP-1-PE-B | 100.100.100.4 | Client |
| 5 | 75 | ISP-1-P1 | 100.100.100.2 | ISP-1-P2 | 100.100.100.3 | RR 간 피어 |
| 6 | 76 | ISP-2-P1 | 200.200.200.2 | ISP-2-PE-A | 200.200.200.1 | Client |
| 7 | 77 | ISP-2-P2 | 200.200.200.3 | ISP-2-PE-A | 200.200.200.1 | Client |
| 8 | 78 | ISP-2-P1 | 200.200.200.2 | ISP-2-PE-B | 200.200.200.4 | Client |
| 9 | 79 | ISP-2-P2 | 200.200.200.3 | ISP-2-PE-B | 200.200.200.4 | Client |
| 10 | 80 | ISP-2-P1 | 200.200.200.2 | ISP-2-P2 | 200.200.200.3 | RR 간 피어 |

## 5. 사이트 엣지 eBGP 세션

- 사이트 라우터와 ISP PE 사이 8세션. 직접 연결 링크의 인터페이스 주소로 세션을 맺으므로 `ebgp-multihop`, `update-source` 불필요. ISP PE 쪽 이웃은 VRF `corp` 안(`address-family ipv4 vrf corp`)에서 구성(`docs/mpls-design.md` 3절).
- 사이트마다 ISP-1 연결 라우터(R1 계열)와 ISP-2 연결 라우터(R2 계열)가 각각 한 세션.

| #   | 링크 # | 사이트 장비 | 사이트 IP     | 사이트 AS | ISP 장비     | ISP IP     | ISP AS |
| --- | ---- | ------ | ---------- | ------ | ---------- | ---------- | ------ |
| 1   | 6    | HQ-R1  | 100.1.11.1 | 65001  | ISP-1-PE-A | 100.1.11.2 | 65100  |
| 2   | 7    | HQ-R2  | 100.2.12.1 | 65001  | ISP-2-PE-A | 100.2.12.2 | 65200  |
| 3   | 33   | DC-R3  | 100.1.21.1 | 65002  | ISP-1-PE-A | 100.1.21.2 | 65100  |
| 4   | 34   | DC-R4  | 100.2.22.1 | 65002  | ISP-2-PE-A | 100.2.22.2 | 65200  |
| 5   | 48   | BR1-R1 | 100.1.31.1 | 65003  | ISP-1-PE-B | 100.1.31.2 | 65100  |
| 6   | 49   | BR1-R2 | 100.2.32.1 | 65003  | ISP-2-PE-B | 100.2.32.2 | 65200  |
| 7   | 62   | BR2-R1 | 100.1.41.1 | 65004  | ISP-1-PE-B | 100.1.41.2 | 65100  |
| 8   | 63   | BR2-R2 | 100.2.42.1 | 65004  | ISP-2-PE-B | 100.2.42.2 | 65200  |

## 6. 광고 prefix와 정책

- 사이트 → ISP: 사이트 /16만 광고. 사이트 엣지 라우터에 `ip route <사이트 /16> null0`을 두고 `network <사이트 /16> mask 255.255.0.0`으로 광고(사이트 내부 상세 경로는 광고하지 않음). 출력 방향 `route-map rm-isp-out`(`pl-site`: 사이트 /16만 허용).
- ISP → 사이트: 기본 경로만 전달. PE에서 `neighbor <사이트 라우터> default-originate`를 설정하고 출력 방향 `prefix-list pl-deny-all`(모든 prefix 차단, default-originate 경로는 별도 전송). 사이트 엣지 라우터는 입력 방향 `route-map rm-isp-in`(`pl-default`: `0.0.0.0/0`만 허용).
- PE 입력 방향: 사이트별 `prefix-list pl-<사이트>-in`으로 해당 사이트 /16만 허용. 이 설정과 `default-originate`는 PE의 VRF 주소군 안에서 적용하고, 사이트 /16은 PE의 VRF에서 vpnv4로 상대 PE에 전달.
- RR(P1, P2)은 prefix를 광고하지 않고 반사만 수행. 반사된 경로의 next-hop은 광고한 PE의 Loopback0.
- 사이트 간 통신은 기본 경로로 ISP에 전달되어, ISP 내부 iBGP로 배운 목적지 사이트 /16을 따라 상대 사이트의 엣지 라우터로 전달.

| 사이트 | 사이트 prefix | 사이트 prefix-list | 사이트 route-map | PE 입력 prefix-list |
|---|---|---|---|---|
| HQ | 10.1.0.0/16 | `pl-site`, `pl-default` | `rm-isp-out`, `rm-isp-in` | `pl-hq-in` |
| DC | 10.2.0.0/16 | `pl-site`, `pl-default` | `rm-isp-out`, `rm-isp-in` | `pl-dc-in` |
| BR1 | 10.3.0.0/16 | `pl-site`, `pl-default` | `rm-isp-out`, `rm-isp-in` | `pl-br1-in` |
| BR2 | 10.4.0.0/16 | `pl-site`, `pl-default` | `rm-isp-out`, `rm-isp-in` | `pl-br2-in` |

## 7. 타이머와 공통 설정

- 모든 세션(eBGP 8, iBGP 10)에 `timers bgp 3 9`(keepalive 3초, hold-time 9초). 사이트 엣지 세션은 ISP 장애 시 기본 경로 철회와 ISP-2 전환의 수렴 시간을 좌우하는 값.
- `bgp log-neighbor-changes`, `no auto-summary`, `no synchronization`(해당 시) 적용.
- 인증은 적용하지 않음(실습 환경).

## 8. 경로 선택과 이중화

- 사이트의 두 엣지 라우터(ISP-1 연결, ISP-2 연결)는 각각 PE에서 기본 경로를 BGP로 받아 사이트 OSPF에 `default-information originate metric <값> metric-type 1`로 광고. ISP-1 연결 라우터 metric 100, ISP-2 연결 라우터 metric 200으로 주/보조 경로 구분(`docs/ospf-design.md` 6절).
- ISP-1 장애 시 사이트 엣지 라우터와 PE의 eBGP 세션이 hold-time 9초 후 내려가고 기본 경로가 라우팅 테이블에서 사라져 OSPF 기본 경로 광고가 철회되며 ISP-2 쪽(metric 200)으로 전환. IP SLA와 track은 사용하지 않음.
- ISP 내부는 RR 이중화로 P1 또는 P2 한 대가 내려가도 나머지 RR을 통해 경로 유지.
- DMVPN 터널(Private Internet 경유)은 ISP와 독립된 경로이며 `docs/dmvpn-design.md` 참조.
