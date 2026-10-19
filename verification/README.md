# 검증 기록

컨피그를 장비에 적용한 뒤 `show` 명령으로 확인한 결과를 보관하는 폴더. 구조는 컨피그 폴더와 같고(사이트 → 계층), 파일은 프로토콜 단위이며 Jira 이슈(KAN)와 연결.

핵심 수치는 [검증 결과 요약](summary.md), 사이트별 토폴로지와 문서 목록은 각 사이트 폴더의 `README.md`에서 확인.

## 1. 구조

```
verification/
├── README.md
├── _template.md                         기록 서식
├── hq/
│   ├── core/            l3-interface, ospf, isp-link, dmvpn, qos
│   ├── distribution/    l3-interface, vlan-trunk, po-channel, vrrp, stp, ospf, dhcp
│   └── access/          l3-interface, vlan-trunk, po-channel, stp
├── dc/
│   ├── core/            ospf, isp-link, dmvpn(Hub), qos, acl
│   ├── distribution/    vlan-trunk, po-channel, vrrp, stp, l3-interface, ospf, mlag
│   ├── access/          vlan-trunk, stp
│   └── host/            dns
├── br1/, br2/
│   ├── core/            ospf, isp-link, dmvpn, qos
│   ├── distribution/    vlan-trunk, po-channel, vrrp, stp, ospf, dhcp
│   └── access/          vlan-trunk, stp
├── isp1/core/, isp2/core/        bgp
├── private-internet/core/        ospf, acl
└── scenarios/                    vrrp-failover, etherchannel-link-down, isp1-failure, dmvpn-hub-failure, qos-verification
```

- 사이트와 계층은 `configs/<사이트>/<계층>/`과 같은 이름이고, 서버·호스트 검증은 `host/`에 기록.
- 파일 이름은 프로토콜: `vlan-trunk`, `po-channel`, `stp`, `vrrp`, `l3-interface`, `ospf`, `isp-link`, `bgp`, `dmvpn`, `dhcp`, `dns`, `qos`, `acl`.
- `scenarios/`는 사이트가 아니라 장애 상황 기준(전환 시간, 복구 동작 측정).
- 새로 만든 파일의 판정은 모두 `미확인`이며 검증하면서 실제 결과와 판정을 채움.

## 1-1. 검증 범위

컨피그 파일(`configs/`)이 작성되어 있으므로 설정 값 자체(IP, `desc`, 계정, 기본 설정)는 파일과 문서 대조로 갈음하고, 장비에서는 **주요 프로토콜의 동작**만 검증.

| 구분 | 항목 | 검증 파일 | 방법 |
|---|---|---|---|
| 주요 프로토콜(장비에서 직접 검증) | VLAN, 트렁크, EtherChannel, MSTP, VRRP | `vlan-trunk`, `po-channel`, `stp`, `vrrp` | `show` 출력과 스크린샷 |
| 주요 프로토콜(장비에서 직접 검증) | OSPF, iBGP RR, MPLS, 사이트 엣지 eBGP, DMVPN | `ospf`, `bgp`, `mpls`, `isp-link`, `dmvpn` | 이웃, 경로, 터널 상태 |
| 장애 시나리오 | VRRP 전환, EtherChannel 멤버 다운, ISP 장애, DMVPN Hub 장애 | `scenarios/` | 전환 시간 측정 |
| 컨피그 대조로 갈음 | 인터페이스 IP, `lo0`, `desc`, 계정, 기본 설정 | `l3-interface` 등(참고용 기록) | 컨피그 파일과 `ip-mapping.md` 대조, 필요 시 `show ip interface brief` |
| 해당 단계에서 판단 | DHCP, DNS, ACL, QoS | `dhcp`, `dns`, `acl`, `qos` | 서비스 구성 후(호스트 포함) |

- hostname, 계정(`username`, password), 접속 설정 같은 기본 설정은 검증 대상에서 제외(`show startup-config` 행은 두지 않음).
- `l3-interface.md`는 이미 기록한 것(HQ 전체, DC)을 유지하되 새로 늘리지 않음.
- 호스트 관련 항목은 DHCP 적용 후 진행.

## 2. 기록 규칙

- 한 파일은 한 프로토콜을 해당 계층의 장비 전체에 대해 기록.
- 표의 열: 장비, 명령, 기대 결과(설계 문서 값), 실제 결과(장비 출력 요약), 판정.
- 판정은 `통과`, `대체 확인`(해당 명령 대신 다른 출력으로 간접 확인), `미확인`(아직 출력 없음), `재확인`(조건이 바뀌어 다시 봐야 함), `불일치`(설계와 다름, 조치 내용을 비고에 기재) 중 하나.
- 명령 출력 스크린샷은 같은 폴더의 `images/`에 두고 표 아래에 `장비 + 명령` 캡션과 `![설명](images/파일)` 형식으로 연결(GitHub에서도 표시됨). 코드 블록으로 붙여도 됨.
- 컨피그를 고치면 같은 파일의 판정과 날짜를 갱신.

## 3. Jira 연결

| Jira | 일정 | 내용 | 검증 파일 | 상태 |
|---|---|---|---|---|
| KAN-7 | 1주 화 | 인터페이스 매핑(HQ 라우터 포함) | `hq/core/l3-interface.md` | 검증 완료 |
| KAN-8 | 1주 목 | HQ VLAN/트렁크 | `hq/*/vlan-trunk.md`, `hq/*/po-channel.md`, `hq/access/l3-interface.md`, `hq/distribution/l3-interface.md` | 검증 완료 |
| KAN-9 | 1주 목 | HQ VRRP + Po1-3 | `hq/distribution/vrrp.md`, `hq/*/stp.md` | 검증 완료 |
| KAN-10 | 1주 수 | DC VLAN/트렁크 | `dc/*/vlan-trunk.md`, `dc/distribution/po-channel.md` | 검증 완료 |
| KAN-11 | 1주 수 | DC VRRP + MSTP 루트 | `dc/distribution/vrrp.md`, `dc/*/stp.md` | 검증 완료 |
| KAN-12 | 1주 수 | BR1 VLAN/트렁크/VRRP | `br1/*/` | 검증 완료 |
| KAN-13 | 1주 목 | BR2 VLAN/트렁크/VRRP | `br2/*/` | 검증 완료 |
| KAN-14 | 1주 금 | 사이트 내부 OSPF + 사이트 DHCP | `*/core/ospf.md`, `*/distribution/ospf.md`, `*/distribution/dhcp.md` | 검증 완료 |
| KAN-36 | 주말(10/18) | BR1 스위치 Aruba CX 교체 | `br1/*/` | 검증 완료 |
| KAN-34 | 주말(10/17~10/18) | ISP MPLS 코어(LDP) | `isp*/core/mpls.md` 1절 | 검증 완료 |
| KAN-35 | 주말(10/17~10/18) | PE VRF corp, vpnv4 | `isp*/core/mpls.md` 2절 | 검증 완료 |
| KAN-18 | 2주 월 | 사이트 엣지 eBGP + route-map | `*/core/isp-link.md`, `isp*/core/bgp.md` 2절 | 검증 완료 |
| KAN-20 | 주말(10/17) | Private Internet OSPF | `private-internet/core/ospf.md` | 검증 완료 |
| KAN-19 | 2주 화 | Private Internet ACL | `private-internet/core/acl.md` | 검증 완료 |
| KAN-21 | 2주 화 | DMVPN Hub | `dc/core/dmvpn.md` | 검증 완료 |
| KAN-22, 23, 33 | 2주 수 | DMVPN Spoke(BR1, BR2, HQ) | `br1/core/dmvpn.md`, `br2/core/dmvpn.md`, `hq/core/dmvpn.md` | 검증 완료 |
| KAN-24 | 2주 목 | DNS 서버, 호스트 DHCP 할당 | `dc/host/dns.md` | 검증 완료 |
| KAN-26 | 2주 금 | DNS 서버 VLAN ACL | `dc/core/acl.md` | 검증 완료 |
| KAN-27 | 3주 월 | VRRP 장애 전환 | `scenarios/vrrp-failover.md` | 검증 완료(벤더별 대표 시험) |
| KAN-28 | 3주 월 | EtherChannel 멤버 다운 | `scenarios/etherchannel-link-down.md` | 검증 완료(벤더별 대표 시험) |
| KAN-37 | 선택(10/19~10/21) | DC MLAG | `dc/distribution/mlag.md` | 검증 완료 |
| KAN-30 | 3주 화 | DMVPN Hub 장애 | `scenarios/dmvpn-hub-failure.md` | 검증 완료 |
| KAN-15, 16 | 3주 수 | ISP 내부 OSPF, iBGP RR | `isp1/core/bgp.md`, `isp2/core/bgp.md` | 검증 완료 |
| KAN-17 | 3주 목 | PE 정책(prefix-list, next-hop-self) | `isp*/core/bgp.md` | 검증 완료 |
| KAN-29 | 3주 목 | ISP-1 장애 시 전환 | `scenarios/isp1-failure.md` | 검증 완료 |
| KAN-25 | 3주 금 | QoS | `*/core/qos.md`, `scenarios/qos-verification.md` | 검증 완료 |
| KAN-31 | 3주 금 | 트러블슈팅 로그 | `troubleshooting-log.md` | 작성 완료 |

## 4. 관련 문서

- 기대 결과의 기준: [docs/README.md](../docs/README.md)의 프로토콜 설계 문서.
- 확인 명령 목록: [docs/config-guide/README.md](../docs/config-guide/README.md) 8절.
