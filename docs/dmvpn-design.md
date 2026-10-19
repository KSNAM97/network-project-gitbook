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

## 7. 백업 Hub 구성(DC-R1)

현재 Hub는 `DC-R2` 한 대이고, `DC-R1`은 Private Internet 언더레이에만 참여함(Gi2/0 `203.0.113.1/30`, OSPF 프로세스 2, Area 100). 아래는 `DC-R1`에 Tunnel0을 추가해 두 번째 Hub로 쓰는 구성안이며 2026-10-19에 적용했음. 적용 후 Hub 장애 시험 결과는 `verification/scenarios/dmvpn-hub-failure.md`의 "백업 Hub(DC-R1) 전환 시험"에 기록.

### 7.1 근거(적용 전 확인)

- BR1-R1 NBMA 주소(`203.0.113.13`)에서 `ping 203.0.113.1 source gigabitEthernet 4/0`이 5/5 응답(60/88/100ms). 언더레이 도달성은 추가 구성 없이 확보된 상태.
- Private-net `pi-whitelist`는 GRE, ESP, UDP 500(isakmp), OSPF를 이미 허용하므로 ACL 변경은 필요 없음.

### 7.2 DC-R1 추가 설정

```text
crypto isakmp policy 10
 encryption aes 256
 hash sha
 authentication pre-share
 group 5
 lifetime 86400
crypto isakmp key dmvpn-hub address 0.0.0.0 0.0.0.0
crypto isakmp keepalive 10 3
crypto ipsec transform-set ts-aes256 esp-aes 256 esp-sha-hmac
 mode tunnel
crypto ipsec profile dmvpn-profile
 set transform-set ts-aes256
 set pfs group5
 set security-association lifetime seconds 3600
!
int tunnel 0
 desc dmvpn hub backup
 ip addr 172.16.0.2 255.255.255.0
 ip mtu 1400
 ip tcp adjust-mss 1360
 tunnel source gi2/0
 tunnel mode gre multipoint
 tunnel key 100
 ip nhrp network-id 100
 ip nhrp holdtime 600
 ip nhrp authentication nhrpkey1
 ip nhrp map multicast dynamic
 ip nhrp redirect
 ip nhrp nhs 172.16.0.1
 ip nhrp map 172.16.0.1 203.0.113.5
 ip nhrp map multicast 203.0.113.5
 ip ospf network broadcast
 ip ospf priority 200
 ip ospf 10 area 0
 tunnel protection ipsec profile dmvpn-profile shared
 no sh
!
router ospf 10
 no passive-interface tunnel 0
```

- 값은 `DC-R2`와 같고 터널 주소 `172.16.0.2`, OSPF priority 200만 다름. DC-R2를 NHS로 등록해 두 Hub가 서로 이웃(OSPF, NHRP)이 되게 함.
- 평상시에 Spoke가 DC-R2를 우선하도록 `DC-R1`의 DC 내부 링크에 `ip ospf cost 100`을 둠(`gi0/0`, `gi1/0`). 터널 인터페이스에 비용을 두면 Spoke 경로 비용에 반영되지 않음(첫 시험에서 DC-R1이 평상시에도 선택됨).

### 7.3 Spoke 추가 설정(HQ-R2, BR1-R1, BR2-R2 공통)

```text
int tunnel0
 ip nhrp nhs 172.16.0.2
 ip nhrp map 172.16.0.2 203.0.113.1
 ip nhrp map multicast 203.0.113.1
```

- Spoke의 기존 NHS(`172.16.0.1`, 매핑 `203.0.113.5`)는 그대로 둠.

### 7.4 검증 항목

| 항목 | 명령 | 기대 결과 |
|---|---|---|
| 두 Hub 등록 | `show dmvpn`(Spoke) | NHS `172.16.0.1`, `172.16.0.2` 모두 UP |
| OSPF | `show ip ospf neighbor`(DC-R1, DC-R2) | Spoke 3대와 FULL, DC-R2 DR, DC-R1 BDR |
| 평상시 경로 | Spoke에서 `show ip route 10.10.10.13` | DC-R2(`172.16.0.1`) 경유 |
| Hub 장애 | DC-R2 `tunnel 0` shutdown 후 HQ-PC1에서 `traceroute 10.10.10.13` | DC-R1(`172.16.0.2`) 경유로 전환, ISP 경유(8홉)와 구분 |

