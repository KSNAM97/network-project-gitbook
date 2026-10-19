# MPLS 검증 (ISP1 / core)

- Jira: KAN-34(LDP), KAN-35(VRF, vpnv4)
- 대상 장비: ISP-1-PE-A, P1, P2, PE-B
- 기준 문서: [mpls-design.md](../../../docs/mpls-design.md) 2~4절, 6절
- 검증일: 2026-10-17

## 1. LDP (KAN-34)

| 장비 | 명령 | 기대 결과 | 실제 결과 | 판정 |
|---|---|---|---|---|
| ISP-1-PE-A, PE-B | `show mpls ldp neighbor` | P1, P2와 LDP 이웃 2개 Oper | PE-A, PE-B 모두 P1(100.100.100.2, Gi0/0)과 P2(100.100.100.3, Gi1/0) 이웃 2개 Oper. Local LDP Ident는 Loopback0(PE-A 100.100.100.1, PE-B 100.100.100.4) | 통과 |
| ISP-1-P1, P2 | `show mpls ldp neighbor` | PE-A, PE-B, 상대 P와 LDP 이웃 3개 Oper | P1은 100.100.100.1(PE-A, Gi0/0), .3(P2, Gi2/0), .4(PE-B, Gi1/0), P2는 .1(PE-A, Gi0/0), .2(P1, Gi2/0), .4(PE-B, Gi1/0) 각 3개 Oper. Local LDP Ident는 Loopback0(P1 100.100.100.2, P2 100.100.100.3) | 통과 |
| ISP-1-PE-A, PE-B, P1, P2 | `show mpls interface` | 내부 링크만 LDP 활성(PE의 사이트 방향 포트는 제외) | PE-A, PE-B는 Gi0/0, Gi1/0, P1, P2는 Gi0/0, Gi1/0, Gi2/0이 `Yes (ldp)`, Operational Yes. PE의 사이트 방향 Gi2/0, Gi3/0은 목록에 없음 | 통과 |
| ISP-1-PE-A, PE-B, P1, P2 | `show mpls forwarding-table` | 상대 장비 Loopback0 `/32` 3개에 레이블 | 각 장비가 Loopback0 `/32` 3개에 레이블 보유(장비별 구간 값). PE-A 11003(.2), 11004(.3), 11005(.4), P1 12002(.1), 12003(.3), 12004(.4), P2 13002(.1), 13003(.2), 13004(.4), PE-B 14009(.1), 14010(.2), 14011(.3). 이웃으로 가는 경로는 Pop Label(PHP), PE-A와 PE-B 사이는 P1, P2 경유 이중 경로(예: 11005에서 12004, 13004) | 통과 |

ISP-1-PE-A LDP neighbor
![ISP-1-PE-A LDP neighbor](images/Pasted%20image%2020261017211443.png)

ISP-1-PE-B LDP neighbor
![ISP-1-PE-B LDP neighbor](images/Pasted%20image%2020261017211500.png)

ISP-1-P1 LDP neighbor
![ISP-1-P1 LDP neighbor](images/Pasted%20image%2020261017211358.png)

ISP-1-P2 LDP neighbor
![ISP-1-P2 LDP neighbor](images/Pasted%20image%2020261017211424.png)

ISP-1-P1 MPLS interface
![ISP-1-P1 MPLS interface](images/Pasted%20image%2020261017211538.png)

ISP-1-PE-A MPLS interface
![ISP-1-PE-A MPLS interface](images/Pasted%20image%2020261017211549.png)

ISP-1-PE-B MPLS interface
![ISP-1-PE-B MPLS interface](images/Pasted%20image%2020261017211559.png)

ISP-1-P2 MPLS interface
![ISP-1-P2 MPLS interface](images/Pasted%20image%2020261017211608.png)

ISP-1-P1 MPLS forwarding-table
![ISP-1-P1 MPLS forwarding-table](images/Pasted%20image%2020261017211632.png)

ISP-1-PE-A MPLS forwarding-table
![ISP-1-PE-A MPLS forwarding-table](images/Pasted%20image%2020261017211641.png)

ISP-1-PE-B MPLS forwarding-table
![ISP-1-PE-B MPLS forwarding-table](images/Pasted%20image%2020261017211649.png)

ISP-1-P2 MPLS forwarding-table
![ISP-1-P2 MPLS forwarding-table](images/Pasted%20image%2020261017211659.png)

## 2. VRF와 vpnv4 (KAN-35)

| 장비               | 명령                              | 기대 결과                                     | 실제 결과                                                                                                                 | 판정  |
| ---------------- | ------------------------------- | ----------------------------------------- | --------------------------------------------------------------------------------------------------------------------- | --- |
| ISP-1-PE-A, PE-B | `show ip vrf`                   | `corp`, RD 65100:1                        | PE-A, PE-B 모두 VRF `corp`, Default RD 65100:1                                                                          | 통과  |
| ISP-1-PE-A, PE-B | `show ip vrf interfaces`        | 사이트 방향 포트 Gi2/0, Gi3/0이 `corp` 소속         | PE-A는 Gi2/0(100.1.11.2), Gi3/0(100.1.21.2), PE-B는 Gi2/0(100.1.31.2), Gi3/0(100.1.41.2)이 `corp` 소속, Protocol up, IP 유지 | 통과  |
| ISP-1-P1, P2 | `show ip bgp vpnv4 all summary` | PE-A, PE-B, 상대 RR과 vpnv4 Established(3세션) | P1(router-id 100.100.100.2)은 PE-A(100.100.100.1), P2(100.100.100.3), PE-B(100.100.100.4), P2(router-id 100.100.100.3)는 PE-A(.1), P1(.2), PE-B(.4) 각 3개 vpnv4 이웃이 Established(AS 65100, State/PfxRcd 0). Up/Down이 4~27초로 vpnv4 추가 직후 재수립된 상태 | 통과 |
| ISP-1-PE-A, PE-B | `show ip bgp vpnv4 all summary` | P1, P2와 vpnv4 Established(2세션) | PE-A(router-id 100.100.100.1)와 PE-B(100.100.100.4) 모두 P1(100.100.100.2), P2(100.100.100.3) 2개 vpnv4 이웃 Established(State/PfxRcd 0, 사이트 경로는 KAN-18 이후) | 통과 |

ISP-1-PE-A VRF
![ISP-1-PE-A VRF](images/Pasted%20image%2020261017213929.png)

ISP-1-PE-B VRF
![ISP-1-PE-B VRF](images/Pasted%20image%2020261017213922.png)

ISP-1-P1 VPNv4 summary
![ISP-1-P1 VPNv4 summary](images/Pasted%20image%2020261017214815.png)

ISP-1-P2 VPNv4 summary
![ISP-1-P2 VPNv4 summary](images/Pasted%20image%2020261017214828.png)

ISP-1-PE-A VPNv4 summary
![ISP-1-PE-A VPNv4 summary](images/Pasted%20image%2020261017214846.png)

ISP-1-PE-B VPNv4 summary
![ISP-1-PE-B VPNv4 summary](images/Pasted%20image%2020261017214857.png)

## 3. 사이트 경로와 레이블 경로 (사이트 eBGP 이후)

| 장비 | 명령 | 기대 결과 | 실제 결과 | 판정 |
|---|---|---|---|---|
| ISP-1-PE-A, PE-B | `show ip route vrf corp` | 사이트 /16(CE에서 eBGP, 상대 PE에서 vpnv4) | PE-A: `10.1.0.0`(via 100.1.11.1)와 `10.2.0.0`(via 100.1.21.1)은 `B [20/0]`(eBGP, 사이트 링크 주소), `10.3.0.0`, `10.4.0.0`은 `B [200/0]`(iBGP, via 100.100.100.4=PE-B Loopback0). PE-B: `10.3.0.0`(via 100.1.31.1)와 `10.4.0.0`(via 100.1.41.1)은 `B [20/0]`, `10.1.0.0`, `10.2.0.0`은 `B [200/0]`(via 100.100.100.1=PE-A Loopback0). 연결 경로 `C`는 사이트 링크 2개 | 통과 |
| ISP-1-PE-B | `show ip cef vrf corp 10.1.0.0`, `traceroute mpls ipv4 100.100.100.1 255.255.255.255` | 사이트 경로가 LDP 레이블과 VPN 레이블 2개로 전달되고, 코어 LSP가 PE-A까지 이어짐(일반 `traceroute vrf corp`는 코어 홉 응답이 돌아오지 않아 `* * *`로 표시되며, 출발 주소가 VRF 밖이라 응답 경로가 없는 것으로 추정) | `show ip cef vrf corp 10.1.0.0`: next-hop `100.1.0.9 Gi0/0 label 12001 11006`(P1 경유)와 `100.1.0.13 Gi1/0 label 13002 11006`(P2 경유). 바깥 LDP 레이블(12001, 13002)과 안쪽 VPN 레이블 11006(PE-A가 광고한 값)의 2단 스택. `traceroute mpls ipv4 100.100.100.1/32`: `0 100.1.0.10 [Labels: 12001]` → `L 1 100.1.0.9 [Labels: implicit-null] 40ms` → `! 2 100.1.0.1 52ms`로 PE-B에서 P를 거쳐 PE-A까지 LSP 성공(P에서 PHP) | 통과 |

ISP-1-PE-A show ip route vrf corp
![ISP-1-PE-A show ip route vrf corp](images/mpls-vrf-route-pe-a.webp)

ISP-1-PE-B show ip route vrf corp
![ISP-1-PE-B show ip route vrf corp](images/mpls-vrf-route-pe-b.webp)

ISP-1-PE-B show ip cef vrf corp 10.1.0.0
![ISP-1-PE-B show ip cef vrf corp 10.1.0.0](images/mpls-label-stack-cef.png)

ISP-1-PE-B traceroute mpls ipv4 100.100.100.1
![ISP-1-PE-B traceroute mpls ipv4 100.100.100.1](images/mpls-label-stack-lsp-traceroute.webp)

## Wireshark 확인(LDP 세션 수립)

- 검증일: 2026-10-19
- 캡처 링크: `ISP-1-PE-A Gi0/0 ↔ ISP-1-P1 Gi0/0`(링크 71), 필터 `ldp`
- 트리거: `clear mpls ldp neighbor *`

| 시각(초) | 패킷 | 내용 |
|---|---|---|
| 1.41 ~ 24.96 | Hello(76바이트) | UDP 646, 목적지 `224.0.0.2`. PE-A(`100.1.0.1`)와 P1(`100.1.0.2`)이 각각 약 5초 간격으로 전송 |
| 29.84 | Initialization(90바이트) | TCP 세션. P1(`100.100.100.2`) → PE-A(`100.100.100.1`), LDP ID가 큰 쪽이 먼저 시작 |
| 29.88 | Initialization + KeepAlive(98바이트) | PE-A 응답 |
| 29.91 | Keep Alive(72바이트) | 세션 확립 |
| 29.91, 29.96 | Address Message + Label Mapping Message(346, 368바이트) | 양쪽이 주소와 레이블 매핑 교환 |

- Hello 이후 TCP 세션 수립과 레이블 매핑 교환까지 한 화면에서 확인.
- 이웃 상태는 `show mpls ldp neighbor`(1절)와 같음. 매핑된 레이블 값(예: PE-B Loopback `12004`)은 이 화면에서 펼치지 않았음.

Wireshark(`ldp`): Hello, Initialization, Label Mapping
![LDP 세션 수립](images/mpls-wireshark-ldp-session.webp)

### LDP Label Mapping 패킷 바이트 해석(프레임 83, P1 → PE-A)

Address Message와 Label Mapping Message 여러 개가 한 TCP 세그먼트에 들어 있고, 패킷 바이트에서 직접 해석한 값.

| 항목 | 해석한 내용 |
|---|---|
| Address Message | P1에 바인딩된 주소 `100.1.0.2`, `100.100.100.2`, `100.1.0.9`, `100.1.0.17`(`show mpls ldp neighbor`의 "Addresses bound to peer LDP Ident"와 일치) |
| 직결·자기 prefix | `100.1.0.0/30`, `100.1.0.8/30`, `100.1.0.16/30`, `100.100.100.2/32`는 레이블 3(implicit-null, PHP) |
| 다른 prefix | `100.100.100.3/32` → 12000, `100.100.100.1/32` → 12001, `100.1.0.12/30` → 12002, `100.1.0.4/30` → 12003, **`100.100.100.4/32`(PE-B Loopback) → 12004** |

- P1이 PE-B Loopback에 대해 광고한 레이블 12004는 PE-A 전달 테이블의 `100.100.100.4/32` 나가는 레이블 12004(Gi0/0)와 일치하고, MPLS 시나리오에서 캡처한 바깥 레이블 12004의 출처임([mpls-label-path](../../scenarios/mpls-label-path.md)).
- 레이블 값은 바이트(`2e e4` = 12004)에서 읽은 값.

Wireshark 패킷 바이트(프레임 83): LDP Address, Label Mapping
![LDP Label Mapping 패킷 바이트](images/mpls-wireshark-ldp-mapping-bytes.webp)

### LDP 메시지 펼침(프레임 30, 122, 316)

같은 링크(링크 71)에서 메시지별로 펼친 화면. 앞 절의 표(Hello, Initialization, Keep Alive, Label Mapping)에 대응.

| 프레임 | 시각(초) | 메시지 | 확인한 값 |
|---|---|---|---|
| 30 | 16.33 | Hello | UDP 646 → 646, 목적지 `224.0.0.2`, LSR ID `100.100.100.1`(PE-A), Hold Time 15, Link Hello, IPv4 Transport Address `100.100.100.1` |
| 122 | 58.53 | Keep Alive | `100.100.100.1` → `100.100.100.2`, TCP 646 → 22428, Keep Alive Message(0x201) |
| 316 | 136.62 | Address Message + Label Mapping 9개 | P1(`100.100.100.2`) → PE-A. 주소 `100.1.0.2`, `100.100.100.2`, `100.1.0.9`, `100.1.0.17`. 아홉 번째 Label Mapping(Message ID 0x43)의 Generic Label **12004**(0x02ee4) |

- 12004는 앞 절의 패킷 바이트 해석(`100.100.100.4/32` → 12004)과 같은 값. 이 화면에서는 `FEC Element 1`을 펼치지 않아 prefix는 보이지 않고, 바이트(`2e e4`)로 일치를 확인.

Wireshark(프레임 30): LDP Hello
![LDP Hello](images/mpls-wireshark-ldp-hello.webp)

Wireshark(프레임 122): LDP Keep Alive
![LDP Keep Alive](images/mpls-wireshark-ldp-keepalive.webp)

Wireshark(프레임 316): Address Message 펼침
![LDP Address Message](images/mpls-wireshark-ldp-address.webp)

Wireshark(프레임 316): Label Mapping Message 9개
![LDP Label Mapping 목록](images/mpls-wireshark-ldp-mapping-list.webp)

Wireshark(프레임 316): 아홉 번째 Label Mapping, Generic Label 12004
![LDP Label Mapping 12004](images/mpls-wireshark-ldp-mapping-expanded.webp)

