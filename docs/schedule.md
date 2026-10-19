# 일정 — 1인 체제, 3.5주

기간: 2026-10-12(월) ~ 2026-11-04(수, 반일). 평일 17.5일이며 6주(30일) 계획을 압축한 일정.

## 역할 분담

담당자: 남기석(전 사이트). 작업 영역은 `Net-Cloud`(DC, HQ, ISP-1, ISP-2, Private Internet, DNS, QoS)와 `Policy`(BR1, BR2, DMVPN, 접근통제 ACL)로 구분하며 Jira 라벨도 동일하게 사용. 일별 표의 `/` 앞은 Net-Cloud, 뒤는 Policy 영역 작업.

⚠️ 2인 일정을 1인이 수행하도록 통합한 일정으로 하루 작업량이 두 배. 지연 시 대응은 아래 "리스크"의 컷 순서 참조.

## VLAN 태그

| VLAN | 태그 |
|---|---|
| 10 | `vlan-hq-public` |
| 20 | `vlan-hq-private` |
| 50 | `vlan-dc-server` |
| BR1 10 | `vlan-br1-public` |
| BR1 20 | `vlan-br1-private` |
| BR2 10 | `vlan-br2-public` |
| BR2 20 | `vlan-br2-private` |
| 100 | `vlan-mgmt` |
| 999 | `vlan-native` |

## 일별 목표

| 주 | 일 | 작업 |
|---|---|---|
| 1주 (10/12-10/16) | 월 | AS/IP/VLAN 표 리뷰, GNS3/Jira/Slack/Git 세팅 |
|  | 화 | 7200/cEOS/IOU RAM 실측, 노드 배치, 기본 링크 up/up / BR1+BR2 노드 배치, 기본 링크 up/up |
|  | 수 | DC VLAN/트렁크(Arista), DC VRRP / BR1 VLAN/트렁크, VRRP |
|  | 목 | HQ VLAN/트렁크, VRRP, Po1-3 / BR2 VLAN/트렁크, VRRP |
|  | 금 | 사이트 내부 OSPF, 사이트 DHCP(HQ), DC/HQ 내부통신 검증 / 사이트 내부 OSPF, 사이트 DHCP(BR1, BR2), BR1/BR2 내부통신 검증 |
| 주말 (10/17-10/18) | 토-일 | Private Internet 기본 연결+OSPF(프로세스2) 선행, ISP MPLS 코어(LDP), PE VRF `corp`, MP-BGP vpnv4(사이트 CE 없이 `show` 확인), QoS 정책 사전 작업, BR1 스위치 Aruba CX 교체(컨피그 전환, 재검증) |
| 2주 (10/19-10/23) | 월 | DC/HQ↔ISP 사이트 엣지 eBGP(PE VRF 안)+OSPF 기본 경로 광고 / BR1/BR2↔ISP 사이트 엣지 eBGP |
|  | 화 | PI ACL 화이트리스트, DMVPN Hub(DC-R2) crypto / DMVPN Spoke 사전 준비 |
|  | 수 | DMVPN Spoke(HQ) / DMVPN Spoke(BR1, BR2) |
|  | 목 | DC-DNS-1·DC-DNS-2(DNS 템플릿) 배치+검증, 호스트 DHCP 할당 확인 / Phase3 shortcut 검증 |
|  | 금 | DNS 서버 VLAN ACL, 전 사이트 상호도달 확인 / 통합 테스트 |
| 3주 (10/26-10/30) | 월 | VRRP 장애 전환, EtherChannel 멤버 다운 실측 |
|  | 화 | DMVPN Hub 장애 실측 |
|  | 수 | ISP-1, ISP-2 내부 OSPF, iBGP RR 10세션 |
|  | 목 | PE 정책(prefix-list, next-hop-self), 사이트 간 ISP 경유 도달, ISP-1 장애→ISP-2/DMVPN 전환 실측 |
|  | 금 | QoS 20포트(DC/HQ 12대, BR 8대), 트러블슈팅 로그 정리 |
| 3.5주 (11/2-11/4) | 월 | PPT(DC/HQ/ISP/이중화) / PPT(BR/DMVPN) |
|  | 화 | PPT 마무리, 리허설 |
|  | 수(반일) | 예비 |

## 실제 진행(Jira 완료 처리일 기준, 2026-10-19)

Jira `해결` 일시(완료 처리한 날) 기준 실제 진행. 계획과 달리 1주 이슈 다수는 10/11 - 10/12에 먼저 완료 처리했고, 2주와 3주 이슈는 10/17 - 10/18에 앞당겨 완료. 이슈별 계획일, 현재 Jira 기한, 근거 커밋은 [`jira/jira-actual-due-dates.csv`](../jira/jira-actual-due-dates.csv)에 기재.

| 완료 처리일 | 이슈 | 이슈 수 |
|---|---|---|
| 10/11(일) | KAN-4, KAN-5, KAN-6, KAN-7, KAN-8, KAN-9, KAN-10, KAN-11 | 8 |
| 10/12(월) | KAN-12, KAN-13 | 2 |
| 10/13(화) | KAN-14 | 1 |
| 10/14(수) | KAN-24 | 1 |
| 10/17(토) | KAN-15, KAN-16, KAN-20, KAN-34, KAN-35, KAN-36 | 6 |
| 10/18(일) | KAN-17, KAN-18, KAN-19, KAN-21, KAN-22, KAN-23, KAN-25, KAN-26, KAN-27, KAN-28, KAN-29, KAN-30, KAN-31, KAN-33, KAN-37 | 15 |
| 진행 중 | KAN-32(PPT 슬라이드 작성과 리허설, 기한 10/23로 조정) | 1 |

- 34개 이슈 중 33개 완료. 10/12 - 10/18 구간에 계획의 1주 - 3주 작업을 모두 마무리.
- 10/19 이후는 보강 검증(Wireshark 캡처, 벤더별 재시험), 문서, PPT 작업.

## Jira 이슈 표기(2026-10-19 조정)

Jira 이슈 제목 앞의 `[1주]`, `[2주]`, `[3주]`는 실제 진행 기준 주차. 계획(3.5주)보다 앞서 10/18에 구성과 검증을 마쳐, 주차를 실제 진행에 맞춰 다시 붙임. PPT 이슈(KAN-32)는 이번 주 완료를 목표로 기한을 11/4에서 10/23으로 앞당김(예비 기간은 11/4까지 유지).

| 이슈 표기 | 기간 | 내용 | 이슈 수 |
|---|---|---|---|
| [1주] | 10/12 - 10/16 | 설계, 환경, VLAN, VRRP, 사이트 OSPF, DHCP, DNS | 12 |
| [2주] | 10/17 - 10/18 | ISP 코어, PE VRF, eBGP, DMVPN, ACL, QoS, 장애 실측, 트러블슈팅, MLAG | 21 |
| [3주] | 10/19 - 10/23 | 보강 시험(Hub 이중화, Wireshark), PPT 작성과 리허설(KAN-32, 목표 10/23) | 1 |

기존 계획의 주차 표(위 "일별 목표")는 최초 계획으로 남김. 일정표에는 있으나 별도 이슈가 없는 작업(전 사이트 상호도달 확인, 통합 테스트)은 관련 이슈 설명에 포함.

## 리스크
- 2인용 일정을 1인이 수행하여 병렬 작업이 직렬로 전환되고, 하루 작업량이 두 배가 되어 예비일이 사실상 없음.
- 위험 구간: 2주(PI·DMVPN), 3주 수-금(BGP, QoS). BGP와 QoS는 일정 후반에 배치하여 앞 단계(OSPF, DHCP, DMVPN)를 먼저 확보.
- 주말(10/17-10/18)에는 Private Internet OSPF(KAN-20)를 먼저 구성하고 이어서 MPLS(LDP, VRF, vpnv4)를 선행. MPLS는 2주 월 이후 사이트 eBGP가 VRF 안으로 이어짐. 지연 시 MPLS를 생략하고 PE의 전역 eBGP(`docs/bgp-design.md` 5-6절)로 되돌릴 수 있음.
- 지연 발생 시 컷 순서(앞에서부터 생략): ① QoS 스위치 검증 생략(라우터만) ② BR2 구성은 BR1과 같은 패턴을 복제만 하고 장애 실측 생략 ③ ISP-2 생략, ISP-1+DMVPN만 ④ DC-DNS-2(백업) 서버 구축 생략, DC-DNS-1만 운영
- 일정 연장이 가능하면 위 컷 순서의 생략 항목을 줄이는 방향으로 조정.
