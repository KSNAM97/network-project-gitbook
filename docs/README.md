# 문서 목차

무엇을 하려는지에 따라 아래 표에서 문서를 고름. 모든 값의 기준은 설계 문서이며 컨피그(`configs/`)와 설정 가이드는 그 값을 따름.

## 1. 하려는 일별로 찾기

| 하려는 일 | 먼저 볼 문서 | 함께 볼 문서 |
|---|---|---|
| 프로젝트 전체 구조 파악 | [network-project-final.md](./network-project-final.md) | - |
| 일정, 오늘 할 일 확인 | [schedule.md](./schedule.md) | Jira(KAN) |
| Jira, Slack 운영과 진행 현황 | [project-management.md](./project-management.md) | Jira(KAN), Slack |
| 장비 포트와 연결 확인 | [port-mapping.md](./port-mapping.md) | - |
| 장비 IP, DHCP 풀 확인 | [ip-mapping.md](./ip-mapping.md) | - |
| 컨피그 작성 방법 | [config-guide/README.md](./config-guide/README.md) | 아래 3절의 장비별 가이드 |
| 파일 위치, 이름, 약어 규칙 | [config-guide/README.md](./config-guide/README.md) 1-1절 | - |
| 장비 확인 결과 기록 | [../verification/README.md](../verification/README.md) | Jira(KAN) |

## 2. 프로토콜 설계 (값의 기준)

| 영역 | 문서 | 내용 |
|---|---|---|
| 사이트 내부 라우팅 | [ospf-design.md](./ospf-design.md) | 프로세스, Area, Router ID, 인터페이스별 소속, 기본 경로 광고 |
| ISP 라우팅 | [bgp-design.md](./bgp-design.md) | AS, Router ID, RR 구조, iBGP·eBGP 세션, 광고 prefix와 정책 |
| ISP 코어 MPLS | [mpls-design.md](./mpls-design.md) | LDP, VRF(corp), MP-BGP vpnv4, MTU, 검증 항목 |
| VLAN, 채널, 트렁크 | [vlan-design.md](./vlan-design.md) | VLAN 정의, EtherChannel, 트렁크, 액세스 포트, DHCP 배치 |
| 게이트웨이 이중화, STP | [vrrp-mstp-design.md](./vrrp-mstp-design.md) | VRRP 그룹과 우선순위, MST region과 루트 |
| DC L2 이중화 | [mlag-design.md](./mlag-design.md) | DC MLAG 피어, MLAG 포트채널, 적용 순서, 검증 항목 |
| 사이트 간 터널 | [dmvpn-design.md](./dmvpn-design.md) | DMVPN Phase 3, IPsec, NHRP, PI 언더레이 |
| DHCP, DNS | [dhcp-dns-design.md](./dhcp-dns-design.md) | 풀, DNS 서버, 접근 통제 |
| QoS | [qos-design.md](./qos-design.md) | 적용 대상 20포트, 클래스와 대역, 정책 구조, 검증 항목 |

## 3. 장비별 설정 가이드

| 대상 | 문서 |
|---|---|
| 공통 규칙, 작성 순서, 저장, 확인 명령 | [config-guide/README.md](./config-guide/README.md) |
| Cisco 라우터(7200) | [config-guide/cisco-router.md](./config-guide/cisco-router.md) |
| Cisco 스위치(vIOS) | [config-guide/cisco-switch.md](./config-guide/cisco-switch.md) |
| Arista 스위치(vEOS-lab) | [config-guide/arista-switch.md](./config-guide/arista-switch.md) |
| Aruba 스위치(CX, BR1) | [config-guide/aruba-switch.md](./config-guide/aruba-switch.md) |
| 알파인 노드 | [config-guide/alpine.md](./config-guide/alpine.md) |

## 4. 컨피그 작성 흐름

1. [port-mapping.md](./port-mapping.md)와 [ip-mapping.md](./ip-mapping.md)에서 장비의 포트, 상대 장비, IP를 확인.
2. 프로토콜 설계 문서(2절)에서 필요한 값(VLAN, 우선순위, Area 등)을 확인.
3. 장비별 설정 가이드(3절)의 예시를 틀로 `configs/<사이트>/<계층>/<장비명>.<ios|eos>`를 작성.
4. 장비에 입력하고 저장한 뒤 확인 명령([config-guide/README.md](./config-guide/README.md) 8절)으로 검증.

## 5. 보관 문서

| 문서 | 내용 |
|---|---|
| [archive/schedule-2person.md](./archive/schedule-2person.md) | 2인 체제 일정(보관) |
| [archive/schedule-3person.md](./archive/schedule-3person.md) | 3인 체제 일정(보관) |
