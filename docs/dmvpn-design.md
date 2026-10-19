# DMVPN 설계

DMVPN Phase 3(mGRE over IPsec) 구성을 정리한 문서. 값은 참고 저장소 `cisco-dmvpn-ipsec-network`의 구성(AES-256, DH 그룹 5, MTU 1400)을 기준으로 단일 Hub 구조로 적용. 언더레이는 Private Internet, 라우팅은 `docs/ospf-design.md` 참조.

## 1. 구성

- Hub 1대(`DC-R2`)와 Spoke 3대(`HQ-R2`, `BR1-R1`, `BR2-R2`)로 구성. Hub 이중화 없음(Hub 장애 실측 대상).
- Spoke 간 직접 통신은 Phase 3 방식(NHRP redirect/shortcut)으로 수립.
- 터널 대역 `172.16.0.0/24`, 터널 인터페이스 `Tunnel0`.

| 장비 | 역할 | Tunnel0 | NBMA(source 인터페이스) | NBMA IP | OSPF 프로세스 / Area | OSPF priority |
|---|---|---|---|---|---|---|
| DC-R2 | Hub | 172.16.0.1/24 | Gi2/0 | 203.0.113.5 | 10 / 0 | 255 |
| HQ-R2 | Spoke | 172.16.0.13/24 | Gi4/0 | 203.0.113.9 | 11 / 0 | 0 |
| BR1-R1 | Spoke | 172.16.0.11/24 | Gi4/0 | 203.0.113.13 | 12 / 0 | 0 |
| BR2-R2 | Spoke | 172.16.0.12/24 | Gi4/0 | 203.0.113.17 | 13 / 0 | 0 |

## 2. IPsec

| 항목 | 값 |
|---|---|
| ISAKMP 정책 | `crypto isakmp policy 10`, encryption aes 256, hash sha, authentication pre-share, group 5, lifetime 86400 |
| ISAKMP keepalive | `crypto isakmp keepalive 10 3` |
| Transform set | `ts-aes256`: esp-aes 256 esp-sha-hmac, mode tunnel |
| IPsec profile | `dmvpn-profile`: transform-set `ts-aes256`, pfs group5, SA lifetime 3600초 |
| 터널 보호 | `tunnel protection ipsec profile dmvpn-profile shared` |
| 사전 공유 키 | `crypto isakmp key dmvpn-hub address 0.0.0.0 0.0.0.0` |

## 3. Tunnel0 공통 설정

| 항목 | 값 |
|---|---|
| 모드 | `tunnel mode gre multipoint` |
| 터널 key | 100 |
| MTU, MSS | `ip mtu 1400`, `ip tcp adjust-mss 1360` |
| NHRP | `ip nhrp network-id 100`, `ip nhrp holdtime 600`, `ip nhrp authentication nhrpkey1` |
| OSPF | 네트워크 타입 broadcast, Hub priority 255, Spoke priority 0 |

## 4. 역할별 NHRP 설정

| 장비 | 설정 |
|---|---|
| Hub `DC-R2` | `ip nhrp map multicast dynamic`, `ip nhrp redirect` |
| Spoke `HQ-R2` | `ip nhrp nhs 172.16.0.1`, `ip nhrp map 172.16.0.1 203.0.113.5`, `ip nhrp map multicast 203.0.113.5`, `ip nhrp shortcut` |
| Spoke `BR1-R1` | 동일(NHS `172.16.0.1`, NBMA `203.0.113.5`) |
| Spoke `BR2-R2` | 동일(NHS `172.16.0.1`, NBMA `203.0.113.5`) |

## 5. 언더레이(Private Internet)

- NBMA 주소는 Private Internet 링크의 사이트 측 IP. 언더레이는 OSPF 프로세스 2 Area 100으로 상호 도달.
- Private Internet ACL은 OSPF(224.0.0.5/6), GRE, ESP, UDP 500(203.0.113.0/24 간)과 ICMP(임시)만 허용.

| 링크 # | 사이트 장비 | 포트 | IP | Private-net 포트 | IP |
|---|---|---|---|---|---|
| 8 | HQ-R2 | Gi4/0 | 203.0.113.9/30 | Gi2/0 | 203.0.113.10/30 |
| 31 | DC-R1 | Gi2/0 | 203.0.113.1/30 | Gi0/0 | 203.0.113.2/30 |
| 32 | DC-R2 | Gi2/0 | 203.0.113.5/30 | Gi1/0 | 203.0.113.6/30 |
| 50 | BR1-R1 | Gi4/0 | 203.0.113.13/30 | Gi3/0 | 203.0.113.14/30 |
| 64 | BR2-R2 | Gi4/0 | 203.0.113.17/30 | Gi4/0 | 203.0.113.18/30 |

- 사이트 라우터 중 `DC-R1`은 언더레이에만 참여하고 터널은 가지지 않음.

## 6. 검증 항목

| 항목 | 명령 | 기대 결과 |
|---|---|---|
| NHRP 등록 | `show ip nhrp`, `show dmvpn` | Spoke 3대가 Hub에 Dynamic 등록 |
| IPsec SA | `show crypto isakmp sa`, `show crypto ipsec sa` | Hub–Spoke SA 수립, 암호화 카운터 증가 |
| OSPF | `show ip ospf neighbor` | Hub와 Spoke 간 FULL, Hub가 DR |
| Phase 3 shortcut | Spoke 간 ping 후 `traceroute`, `show dmvpn` | 첫 패킷 이후 Spoke 간 직접 터널 수립 |
| Hub 장애 | Hub 인터페이스 shutdown | 터널 경로 단절 확인(실측 항목) |

