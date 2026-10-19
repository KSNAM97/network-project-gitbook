# OSPF 설계

사이트별 OSPF 프로세스와 Area, Router ID, 인터페이스 소속을 정리한 문서(ISP 내부 OSPF 포함). 인터페이스와 IP는 `docs/ip-mapping.md`, 포트는 `docs/port-mapping.md` 기준.

## 1. 프로세스와 Area

| 사이트 | 프로세스 | Area | 비고 |
|---|---|---|---|
| DC | 10 | 0 | DC 전체(라우터 4대, L3 스위치 4대)와 DMVPN 터널(Hub `DC-R2`)이 Area 0 |
| HQ | 11 | 1 | 터널(Area 0) 연결 라우터 `HQ-R2`가 ABR |
| BR1 | 12 | 2 | 터널(Area 0) 연결 라우터 `BR1-R1`이 ABR |
| BR2 | 13 | 3 | 터널(Area 0) 연결 라우터 `BR2-R2`가 ABR |
| Private Internet(DMVPN 언더레이) | 2 | 100 | `Private-net`과 사이트의 PI 연결 라우터 |
| ISP-1, ISP-2 내부 | 1 | 0 | 각 ISP가 독립된 OSPF 도메인(ISP끼리 연결되지 않음). iBGP Loopback0 도달성 용도이며 사이트와는 OSPF로 연결하지 않음(eBGP) |

- 프로세스 번호는 장비 로컬 값이며 IOS와 EOS 모두 1 ~ 65535만 허용. 사이트 번호(DC 0, HQ 1, BR1 2, BR2 3)에 10을 더해 사용하고, 언더레이 프로세스 2와 겹치지 않도록 구성. ISP 내부는 프로세스 1.
- Area 0은 DC와 DMVPN 터널. HQ(Area 1), BR1(Area 2), BR2(Area 3)는 터널을 통해 Area 0에 연결.
- ISP-1, ISP-2는 ISP 내부에서만 OSPF process 1 Area 0 사용(iBGP Loopback0 도달성, `docs/bgp-design.md` 3절). 사이트↔ISP 구간은 OSPF를 쓰지 않고 eBGP 사용(`docs/bgp-design.md` 5절). ISP 내부 링크에는 이 OSPF 위에서 LDP(MPLS)가 동작(`docs/mpls-design.md` 2절).

## 2. Router ID (Loopback0)

- 형식: `<프로세스>.<프로세스>.<프로세스>.<장비 번호>/32`. DC `10.10.10.x`, HQ `11.11.11.x`, BR1 `12.12.12.x`, BR2 `13.13.13.x`. 끝자리는 라우터가 이름의 번호(`R1` → `.1`), L3 스위치가 이름의 번호에 10을 더한 값(`SW1` → `.11`).
- 같은 OSPF 도메인 안에서 Router ID는 장비마다 고유해야 하므로 사이트 내 장비는 끝자리로 구분.
- Loopback0은 해당 사이트 Area에 포함하고 `passive-interface` 처리. 이 값을 `router-id`로 사용.
- `Private-net`의 Router ID는 `2.2.2.2`(Loopback0, `/32`).
- 사이트 라우터의 PI 프로세스(2)는 사이트 프로세스와 같은 Router ID를 쓸 수 없음. 같은 장비의 다른 OSPF 프로세스가 쓰는 값은 `OSPF: router-id <값> in use by ospf process <번호>`로 거부됨. 그래서 프로세스 2의 Router ID는 PI 연결 인터페이스 주소(`DC-R1` `203.0.113.1`, `DC-R2` `203.0.113.5`, `HQ-R2` `203.0.113.9`, `BR1-R1` `203.0.113.13`, `BR2-R2` `203.0.113.17`)를 명시해서 사용.
- ISP 장비의 Router ID는 `bgp router-id`와 같은 Loopback0 값(ISP-1 `100.100.100.<n>`, ISP-2 `200.200.200.<n>`, PE-A 1, P1 2, P2 3, PE-B 4). Loopback0은 Area 0에 포함하고 `passive-interface` 처리.

| 장비          | Loopback0      | 프로세스 | Area |
| ----------- | -------------- | ---- | ---- |
| HQ-R1       | 11.11.11.1/32  | 11   | 1    |
| HQ-R2       | 11.11.11.2/32  | 11   | 1    |
| HQ-SW-2     | 11.11.11.12/32 | 11   | 1    |
| HQ-SW-3     | 11.11.11.13/32 | 11   | 1    |
| DC-R1       | 10.10.10.1/32  | 10   | 0    |
| DC-R2       | 10.10.10.2/32  | 10   | 0    |
| DC-R3       | 10.10.10.3/32  | 10   | 0    |
| DC-R4       | 10.10.10.4/32  | 10   | 0    |
| DC-SW1-L3   | 10.10.10.11/32 | 10   | 0    |
| DC-SW2-L3   | 10.10.10.12/32 | 10   | 0    |
| DC-SW3-L3   | 10.10.10.13/32 | 10   | 0    |
| DC-SW4-L3   | 10.10.10.14/32 | 10   | 0    |
| BR1-R1      | 12.12.12.1/32  | 12   | 2    |
| BR1-R2      | 12.12.12.2/32  | 12   | 2    |
| BR1-SW1-L3  | 12.12.12.11/32 | 12   | 2    |
| BR1-SW2-L3  | 12.12.12.12/32 | 12   | 2    |
| BR2-R1      | 13.13.13.1/32  | 13   | 3    |
| BR2-R2      | 13.13.13.2/32  | 13   | 3    |
| BR2-SW1-L3  | 13.13.13.11/32 | 13   | 3    |
| BR2-SW2-L3  | 13.13.13.12/32 | 13   | 3    |
| Private-net | 2.2.2.2/32     | 2    | 100  |
| ISP-1-PE-A | 100.100.100.1/32 | 1 | 0 |
| ISP-1-P1 | 100.100.100.2/32 | 1 | 0 |
| ISP-1-P2 | 100.100.100.3/32 | 1 | 0 |
| ISP-1-PE-B | 100.100.100.4/32 | 1 | 0 |
| ISP-2-PE-A | 200.200.200.1/32 | 1 | 0 |
| ISP-2-P1 | 200.200.200.2/32 | 1 | 0 |
| ISP-2-P2 | 200.200.200.3/32 | 1 | 0 |
| ISP-2-PE-B | 200.200.200.4/32 | 1 | 0 |

## 3. 인터페이스별 OSPF 소속

- 모든 /30 링크는 `ip ospf network point-to-point`로 DR 선출 없이 구성.
- 사용자 VLAN과 서버 VLAN(`10.2.50.0/24`)의 SVI는 해당 사이트 Area에 포함하고 `passive-interface` 처리.
- 타이머는 기본값, 인증은 미적용(실습 환경).
- BR1 스위치(Aruba CX)는 Area를 `0.0.0.2` 형식으로 선언하고(`router ospf 12`에 `router-id`와 `area 0.0.0.2`), passive는 `passive-interface default` 대신 SVI 인터페이스에 `ip ospf passive`로 설정(Loopback0은 `ip ospf passive`가 지원되지 않아 설정하지 않음).

| 장비          | 인터페이스   | IP              | 프로세스 | Area | 네트워크 타입                      | 링크 # |
| ----------- | ------- | --------------- | ---- | ---- | ---------------------------- | ---- |
| HQ-R1       | Gi0/0   | 10.1.0.1/30     | 11   | 1    | point-to-point               | 1    |
| HQ-R1       | Gi1/0   | 10.1.0.9/30     | 11   | 1    | point-to-point               | 3    |
| HQ-R1       | Gi2/0   | 10.1.0.17/30    | 11   | 1    | point-to-point               | 5    |
| HQ-R2       | Gi0/0   | 10.1.0.5/30     | 11   | 1    | point-to-point               | 2    |
| HQ-R2       | Gi1/0   | 10.1.0.13/30    | 11   | 1    | point-to-point               | 4    |
| HQ-R2       | Gi2/0   | 10.1.0.18/30    | 11   | 1    | point-to-point               | 5    |
| HQ-R2       | Gi4/0   | 203.0.113.9/30  | 2    | 100  | point-to-point               | 8    |
| HQ-R2       | Tunnel0 | 172.16.0.13/24  | 11   | 0    | broadcast, priority 0        | -    |
| HQ-SW-2     | Gi1/0   | 10.1.0.2/30     | 11   | 1    | point-to-point               | 1    |
| HQ-SW-2     | Gi1/1   | 10.1.0.6/30     | 11   | 1    | point-to-point               | 2    |
| HQ-SW-3     | Gi1/0   | 10.1.0.10/30    | 11   | 1    | point-to-point               | 3    |
| HQ-SW-3     | Gi1/1   | 10.1.0.14/30    | 11   | 1    | point-to-point               | 4    |
| DC-R1       | Gi0/0   | 10.2.0.1/30     | 10   | 0    | point-to-point               | 17   |
| DC-R1       | Gi1/0   | 10.2.0.5/30     | 10   | 0    | point-to-point               | 18   |
| DC-R1       | Gi2/0   | 203.0.113.1/30  | 2    | 100  | point-to-point               | 31   |
| DC-R2       | Gi0/0   | 10.2.0.10/30    | 10   | 0    | point-to-point               | 19   |
| DC-R2       | Gi1/0   | 10.2.0.13/30    | 10   | 0    | point-to-point               | 20   |
| DC-R2       | Gi2/0   | 203.0.113.5/30  | 2    | 100  | point-to-point               | 32   |
| DC-R2       | Tunnel0 | 172.16.0.1/24   | 10   | 0    | broadcast, priority 255 (DR) | -    |
| DC-R3       | Gi0/0   | 10.2.0.37/30    | 10   | 0    | point-to-point               | 26   |
| DC-R3       | Gi1/0   | 10.2.0.45/30    | 10   | 0    | point-to-point               | 28   |
| DC-R3       | Gi2/0   | 10.2.0.53/30    | 10   | 0    | point-to-point               | 30   |
| DC-R4       | Gi0/0   | 10.2.0.42/30    | 10   | 0    | point-to-point               | 27   |
| DC-R4       | Gi1/0   | 10.2.0.49/30    | 10   | 0    | point-to-point               | 29   |
| DC-R4       | Gi2/0   | 10.2.0.54/30    | 10   | 0    | point-to-point               | 30   |
| DC-SW1-L3   | Et1     | 10.2.0.2/30     | 10   | 0    | point-to-point               | 17   |
| DC-SW1-L3   | Et2     | 10.2.0.9/30     | 10   | 0    | point-to-point               | 19   |
| DC-SW1-L3   | Et3     | 10.2.0.17/30    | 10   | 0    | point-to-point               | 21   |
| DC-SW1-L3   | Et4     | 10.2.0.21/30    | 10   | 0    | point-to-point               | 22   |
| DC-SW1-L3   | Et5     | 10.2.0.25/30    | 10   | 0    | point-to-point               | 23   |
| DC-SW2-L3   | Et1     | 10.2.0.6/30     | 10   | 0    | point-to-point               | 18   |
| DC-SW2-L3   | Et2     | 10.2.0.14/30    | 10   | 0    | point-to-point               | 20   |
| DC-SW2-L3   | Et3     | 10.2.0.18/30    | 10   | 0    | point-to-point               | 21   |
| DC-SW2-L3   | Et4     | 10.2.0.29/30    | 10   | 0    | point-to-point               | 24   |
| DC-SW2-L3   | Et5     | 10.2.0.33/30    | 10   | 0    | point-to-point               | 25   |
| DC-SW3-L3   | Et1     | 10.2.0.22/30    | 10   | 0    | point-to-point               | 22   |
| DC-SW3-L3   | Et2     | 10.2.0.30/30    | 10   | 0    | point-to-point               | 24   |
| DC-SW3-L3   | Et3     | 10.2.0.38/30    | 10   | 0    | point-to-point               | 26   |
| DC-SW3-L3   | Et4     | 10.2.0.41/30    | 10   | 0    | point-to-point               | 27   |
| DC-SW4-L3   | Et1     | 10.2.0.26/30    | 10   | 0    | point-to-point               | 23   |
| DC-SW4-L3   | Et2     | 10.2.0.34/30    | 10   | 0    | point-to-point               | 25   |
| DC-SW4-L3   | Et3     | 10.2.0.46/30    | 10   | 0    | point-to-point               | 28   |
| DC-SW4-L3   | Et4     | 10.2.0.50/30    | 10   | 0    | point-to-point               | 29   |
| BR1-R1      | Gi0/0   | 10.3.0.1/30     | 12   | 2    | point-to-point               | 43   |
| BR1-R1      | Gi1/0   | 10.3.0.9/30     | 12   | 2    | point-to-point               | 45   |
| BR1-R1      | Gi2/0   | 10.3.0.17/30    | 12   | 2    | point-to-point               | 47   |
| BR1-R1      | Gi4/0   | 203.0.113.13/30 | 2    | 100  | point-to-point               | 50   |
| BR1-R1      | Tunnel0 | 172.16.0.11/24  | 12   | 0    | broadcast, priority 0        | -    |
| BR1-R2      | Gi0/0   | 10.3.0.6/30     | 12   | 2    | point-to-point               | 44   |
| BR1-R2      | Gi1/0   | 10.3.0.13/30    | 12   | 2    | point-to-point               | 46   |
| BR1-R2      | Gi2/0   | 10.3.0.18/30    | 12   | 2    | point-to-point               | 47   |
| BR1-SW1-L3  | 1/1/1   | 10.3.0.2/30     | 12   | 2    | point-to-point               | 43   |
| BR1-SW1-L3  | 1/1/2   | 10.3.0.5/30     | 12   | 2    | point-to-point               | 44   |
| BR1-SW2-L3  | 1/1/1   | 10.3.0.10/30    | 12   | 2    | point-to-point               | 45   |
| BR1-SW2-L3  | 1/1/2   | 10.3.0.14/30    | 12   | 2    | point-to-point               | 46   |
| BR2-R1      | Gi0/0   | 10.4.0.1/30     | 13   | 3    | point-to-point               | 57   |
| BR2-R1      | Gi1/0   | 10.4.0.9/30     | 13   | 3    | point-to-point               | 59   |
| BR2-R1      | Gi2/0   | 10.4.0.17/30    | 13   | 3    | point-to-point               | 61   |
| BR2-R2      | Gi0/0   | 10.4.0.6/30     | 13   | 3    | point-to-point               | 58   |
| BR2-R2      | Gi1/0   | 10.4.0.13/30    | 13   | 3    | point-to-point               | 60   |
| BR2-R2      | Gi2/0   | 10.4.0.18/30    | 13   | 3    | point-to-point               | 61   |
| BR2-R2      | Gi4/0   | 203.0.113.17/30 | 2    | 100  | point-to-point               | 64   |
| BR2-R2      | Tunnel0 | 172.16.0.12/24  | 13   | 0    | broadcast, priority 0        | -    |
| BR2-SW1-L3  | Gi0/0   | 10.4.0.2/30     | 13   | 3    | point-to-point               | 57   |
| BR2-SW1-L3  | Gi0/1   | 10.4.0.5/30     | 13   | 3    | point-to-point               | 58   |
| BR2-SW2-L3  | Gi0/0   | 10.4.0.10/30    | 13   | 3    | point-to-point               | 59   |
| BR2-SW2-L3  | Gi0/1   | 10.4.0.14/30    | 13   | 3    | point-to-point               | 60   |
| Private-net | Gi0/0   | 203.0.113.2/30  | 2    | 100  | point-to-point               | 31   |
| Private-net | Gi1/0   | 203.0.113.6/30  | 2    | 100  | point-to-point               | 32   |
| Private-net | Gi2/0   | 203.0.113.10/30 | 2    | 100  | point-to-point               | 8    |
| Private-net | Gi3/0   | 203.0.113.14/30 | 2    | 100  | point-to-point               | 50   |
| Private-net | Gi4/0   | 203.0.113.18/30 | 2    | 100  | point-to-point               | 64   |
| ISP-1-PE-A | Gi0/0 | 100.1.0.1/30 | 1 | 0 | point-to-point | 71 |
| ISP-1-PE-A | Gi1/0 | 100.1.0.5/30 | 1 | 0 | point-to-point | 72 |
| ISP-1-P1 | Gi0/0 | 100.1.0.2/30 | 1 | 0 | point-to-point | 71 |
| ISP-1-P1 | Gi1/0 | 100.1.0.9/30 | 1 | 0 | point-to-point | 73 |
| ISP-1-P1 | Gi2/0 | 100.1.0.17/30 | 1 | 0 | point-to-point | 75 |
| ISP-1-P2 | Gi0/0 | 100.1.0.6/30 | 1 | 0 | point-to-point | 72 |
| ISP-1-P2 | Gi1/0 | 100.1.0.13/30 | 1 | 0 | point-to-point | 74 |
| ISP-1-P2 | Gi2/0 | 100.1.0.18/30 | 1 | 0 | point-to-point | 75 |
| ISP-1-PE-B | Gi0/0 | 100.1.0.10/30 | 1 | 0 | point-to-point | 73 |
| ISP-1-PE-B | Gi1/0 | 100.1.0.14/30 | 1 | 0 | point-to-point | 74 |
| ISP-2-PE-A | Gi0/0 | 100.2.0.1/30 | 1 | 0 | point-to-point | 76 |
| ISP-2-PE-A | Gi1/0 | 100.2.0.5/30 | 1 | 0 | point-to-point | 77 |
| ISP-2-P1 | Gi0/0 | 100.2.0.2/30 | 1 | 0 | point-to-point | 76 |
| ISP-2-P1 | Gi1/0 | 100.2.0.9/30 | 1 | 0 | point-to-point | 78 |
| ISP-2-P1 | Gi2/0 | 100.2.0.17/30 | 1 | 0 | point-to-point | 80 |
| ISP-2-P2 | Gi0/0 | 100.2.0.6/30 | 1 | 0 | point-to-point | 77 |
| ISP-2-P2 | Gi1/0 | 100.2.0.13/30 | 1 | 0 | point-to-point | 79 |
| ISP-2-P2 | Gi2/0 | 100.2.0.18/30 | 1 | 0 | point-to-point | 80 |
| ISP-2-PE-B | Gi0/0 | 100.2.0.10/30 | 1 | 0 | point-to-point | 78 |
| ISP-2-PE-B | Gi1/0 | 100.2.0.14/30 | 1 | 0 | point-to-point | 79 |

## 4. DMVPN 터널(Tunnel0)

- 터널 `172.16.0.0/24`는 Area 0. Hub `DC-R2`(`172.16.0.1`)는 DC 프로세스 10, Spoke `HQ-R2`(`172.16.0.13`)는 프로세스 11, `BR1-R1`(`172.16.0.11`)은 프로세스 12, `BR2-R2`(`172.16.0.12`)는 프로세스 13에 속하며 프로세스 번호는 장비 로컬 값이라 인접 관계에 영향 없음.
- 네트워크 타입은 `broadcast`. Hub는 `ip ospf priority 255`(DR), Spoke는 `ip ospf priority 0`.
- `HQ-R2`는 터널(Area 0)과 HQ 내부(Area 1), `BR1-R1`은 터널(Area 0)과 BR1 내부(Area 2), `BR2-R2`는 터널(Area 0)과 BR2 내부(Area 3)를 가져 ABR 역할. `DC-R2`는 DC 전체가 Area 0이므로 ABR 아님.
- 사이트당 Spoke 라우터 한 대만 터널을 가지므로 `HQ-R1`, `BR1-R2`, `BR2-R1`은 Area 내부 라우터.

## 5. Private Internet 언더레이(프로세스 2, Area 100)

- 대상: `Private-net`(5포트)과 PI 연결 사이트 라우터(`DC-R1`, `DC-R2`, `HQ-R2`, `BR1-R1`, `BR2-R2`)의 PI 연결 인터페이스.
- 사이트 내부 OSPF와 별도 프로세스이며 Area 100만 사용. ACL 화이트리스트가 OSPF(224.0.0.5/6)를 허용.

## 6. 사이트 엣지 eBGP와 OSPF 기본 경로 광고

- 사이트↔ISP 구간은 OSPF를 사용하지 않음. 사이트 엣지 라우터와 ISP PE가 eBGP로 연결되며(`docs/bgp-design.md` 5절) PE가 `default-originate`로 기본 경로를 전달.
- 사이트 엣지 라우터는 BGP로 받은 기본 경로를 사이트 OSPF 프로세스에 `default-information originate metric <값> metric-type 1`(`always` 없음)로 광고. ISP-1 연결 라우터 metric 100, ISP-2 연결 라우터 metric 200으로 ISP-1을 우선 경로로 사용.
- ISP 도달성 상실 시 BGP 세션이 hold-time 9초 후 내려가 기본 경로가 라우팅 테이블에서 사라지고 OSPF 기본 경로 광고가 철회되어 ISP-2 경로로 전환. IP SLA와 track은 사용하지 않음.
- 사이트 prefix는 사이트 엣지 라우터가 eBGP로 ISP에 광고하고 ISP 내부 iBGP(Route Reflector)로 전달(`docs/bgp-design.md`). 경로 요약(`area range`)은 적용하지 않음.

| 링크 # | 사이트 장비 | 포트 | IP | ISP 장비 | 포트 | IP | 프로세스 | 광고 metric |
|---|---|---|---|---|---|---|---|---|
| 6 | HQ-R1 | Gi3/0 | 100.1.11.1/30 | ISP-1-PE-A | Gi2/0 | 100.1.11.2/30 | 11 | 100 |
| 7 | HQ-R2 | Gi3/0 | 100.2.12.1/30 | ISP-2-PE-A | Gi2/0 | 100.2.12.2/30 | 11 | 200 |
| 33 | DC-R3 | Gi3/0 | 100.1.21.1/30 | ISP-1-PE-A | Gi3/0 | 100.1.21.2/30 | 10 | 100 |
| 34 | DC-R4 | Gi3/0 | 100.2.22.1/30 | ISP-2-PE-A | Gi3/0 | 100.2.22.2/30 | 10 | 200 |
| 48 | BR1-R1 | Gi3/0 | 100.1.31.1/30 | ISP-1-PE-B | Gi2/0 | 100.1.31.2/30 | 12 | 100 |
| 49 | BR1-R2 | Gi3/0 | 100.2.32.1/30 | ISP-2-PE-B | Gi2/0 | 100.2.32.2/30 | 12 | 200 |
| 62 | BR2-R1 | Gi3/0 | 100.1.41.1/30 | ISP-1-PE-B | Gi3/0 | 100.1.41.2/30 | 13 | 100 |
| 63 | BR2-R2 | Gi3/0 | 100.2.42.1/30 | ISP-2-PE-B | Gi3/0 | 100.2.42.2/30 | 13 | 200 |

