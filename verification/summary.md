# 검증 결과 요약

장애 시험과 주요 프로토콜 검증의 핵심 수치를 한 곳에 모은 문서. 상세 증거는 각 문서 링크에서 확인. 사이트별 토폴로지와 문서 목록은 [HQ](hq/README.md), [DC](dc/README.md), [BR1](br1/README.md), [BR2](br2/README.md), [ISP-1](isp1/README.md), [ISP-2](isp2/README.md), [Private Internet](private-internet/README.md).

## 이중화 장애 시험

| 시험 | 대상 | 핵심 결과 | 문서 |
|---|---|---|---|
| VRRP 전환 | HQ(Cisco) | 장비 로그 기준 약 0.19초(Master → Init 00:13:56.227, Backup → Master 00:13:56.415), `ping` 손실 1개. 두 장비 시계 일치는 미확인 | [vrrp-failover](scenarios/vrrp-failover.md) |
| VRRP 전환 | DC(Arista) | Wireshark 광고 공백 약 3.2초, `ping` 손실 5개 | [vrrp-failover](scenarios/vrrp-failover.md) |
| VRRP 전환 | BR1(Aruba) | Wireshark 광고 공백 약 4.0초(1차 3.97초, 2차 4.00초로 재현, `ping` 손실은 복구 구간 포함 값이라 제외) | [vrrp-failover](scenarios/vrrp-failover.md) |
| EtherChannel 링크 다운 | HQ Po1 | 손실 1개 | [etherchannel-link-down](scenarios/etherchannel-link-down.md) |
| EtherChannel 링크 다운 | BR1 LAG 1(Aruba) | 손실 5개, 최대 응답 5015 ms | [etherchannel-link-down](scenarios/etherchannel-link-down.md) |
| MLAG 링크 다운 | DC | 손실 1개, 복구 후 Active-full 2 | [etherchannel-link-down](scenarios/etherchannel-link-down.md), [mlag](dc/distribution/mlag.md) |
| ISP-1 장애 | HQ-R1 ↔ ISP-1-PE-A | BGP hold-time 9초, 마지막 Keepalive 후 약 9.7초에 `NOTIFICATION`. 기본 경로는 ISP-2 쪽 OSPF E1 metric 201로 전환, 복구 후 세션 수립 약 1.6초 | [isp1-failure](scenarios/isp1-failure.md) |
| DMVPN Hub 장애 | DC-R2 `tunnel 0` | Hub 중단 약 105초. shortcut ESP는 약 44초 유지 뒤 ISP(MPLS) 경로로 우회(TTL 60 → 57). `ping` 294개 모두 응답 | [dmvpn-hub-failure](scenarios/dmvpn-hub-failure.md) |
| DMVPN Hub 이중화(DC-R1 백업 Hub) | DC-R2 `tunnel 0` | 평상시 `172.16.0.1` 경유, shutdown 후 `172.16.0.2`(DC-R1) 경유로 전환(HQ-PC1 → `10.10.10.13`, 5홉 유지). `ping` 44개 중 38개 응답(손실 6개), 복구 후 `172.16.0.1` 복귀 | [dmvpn-hub-failure](scenarios/dmvpn-hub-failure.md) |

## 서비스 품질과 서비스 동작

| 시험 | 핵심 결과 | 문서 |
|---|---|---|
| QoS | DNS를 ACL로 분류해 `cm-business`에 af31 표시. 병목 시 `class-default`만 drop(578 → 1333), `cm-business` drop 0 | [qos-verification](scenarios/qos-verification.md) |
| DHCP(HQ·BR2 Cisco, BR1 Aruba) | DORA 4단계 확인. 두 서버가 모두 Offer를 보내고 먼저 도착한 Offer로 임대(HQ, BR1은 SW-1, BR2는 SW-2). BR1(Aruba)은 VIP 출발지 Offer까지 3개 관찰. lease 86400 | [HQ](hq/distribution/dhcp.md), [BR1](br1/distribution/dhcp.md), [BR2](br2/distribution/dhcp.md) |
| DNS(BR1-PC1 → DC-DNS-1) | DHCP로 받은 주소로 질의, A 질의에 `dc-r1.lab.local` → `10.10.10.1` 응답(첫 질의 약 30ms, 반복 질의 0.19 ~ 0.53ms) | [dns](dc/host/dns.md) |
| MPLS 레이블 | Hub 장애로 ISP 경유 시 `12004`(LDP) + `14007`(VPN) 두 레이블, PHP로 마지막 홉 전 바깥 레이블 제거 | [mpls-label-path](scenarios/mpls-label-path.md) |

## 프로토콜 패킷 캡처(Wireshark)

| 프로토콜 | 확인한 것 | 문서 |
|---|---|---|
| OSPF | Hello 10초, Dead 40초, point-to-point(DR 없음). HQ Area `0.0.0.1`, DC Area `0.0.0.0`. 이웃 수립(Hello, DBD, LSR, LSU, LSAck) | [HQ](hq/core/ospf.md), [DC](dc/core/ospf.md) |
| eBGP | OPEN(사이트 AS 65001, ISP AS 65100, Hold 9), 광고 UPDATE(`10.1.0.0/16`, `0.0.0.0/0`), 철회 UPDATE, Keepalive 3초 | [bgp](isp1/core/bgp.md) |
| iBGP vpnv4, LDP | vpnv4 UPDATE(RD 65100:1, VPN 레이블 11007, 11006), LDP Label Mapping(PE-B Loopback 12004) | [bgp](isp1/core/bgp.md), [mpls](isp1/core/mpls.md) |
| LACP | DC MLAG 두 스위치가 같은 Actor System ID `0e:06:2e:cc:02:b8`로 광고, BR1 LAG Active | [mlag](dc/distribution/mlag.md), [po-channel](br1/distribution/po-channel.md) |
| MLAG 피어링 | VLAN 4094, TCP·UDP 4432, DSCP CS7 | [mlag](dc/distribution/mlag.md) |
| VLAN, STP | 802.1Q 태그(HQ 10, DC 50, BR1 10·20), MST 이름·digest(hq, dc, br1), 인스턴스 1 루트 우선순위 4096 | [HQ](hq/distribution/stp.md), [DC](dc/distribution/stp.md), [BR1](br1/distribution/stp.md) |
| IKE, ESP | Hub 장애 시 ESP 중단과 IKE 재협상 | [dmvpn-hub-failure](scenarios/dmvpn-hub-failure.md) |

## 트러블슈팅

구성과 검증 중 설계와 달랐던 10건(vEOS-lab ACL 미지원, router-id 충돌, QoS 분류, BR1 L2 루프 등)의 증상, 원인, 조치는 [troubleshooting-log](troubleshooting-log.md) 참조.
