# 장비 설정 가이드(목차와 공통 규칙)

`configs/<사이트>/<계층>/<장비명>.<ios|eos>`를 작성할 때의 순서, 공통 규칙, 장비 종류별 설정 틀을 정리한 문서. 값은 각 설계 문서의 표를 그대로 사용하며 아래 예시는 형식 확인용.

## 목차

| 대상 | 문서 | 내용 |
|---|---|---|
| Cisco 라우터(7200) | [cisco-router.md](./cisco-router.md) | 기본, OSPF, 사이트 엣지 eBGP, iBGP RR, MPLS L3VPN, DMVPN, PI ACL, QoS |
| Cisco 스위치(vIOS) | [cisco-switch.md](./cisco-switch.md) | L2·L3 기능, VRRP, MSTP, OSPF, MGMT SVI, DHCP |
| Arista 스위치(vEOS-lab) | [arista-switch.md](./arista-switch.md) | DC L3·L2 스위치, 접속 설정, MLAG |
| Aruba 스위치(CX) | [aruba-switch.md](./aruba-switch.md) | BR1 분배 L3(SW1, SW2)와 액세스(SW3), LAG, MSTP, VRRP, OSPF, DHCP |
| 알파인 노드, DNS 템플릿 | [alpine.md](./alpine.md) | 호스트 DHCP 클라이언트(알파인), DNS 서버(DNS 템플릿) |

## 1. 설계 문서 대응

| 항목 | 문서 |
|---|---|
| 포트·연결 | `docs/port-mapping.md` |
| 인터페이스 IP | `docs/ip-mapping.md` |
| OSPF | `docs/ospf-design.md` |
| BGP(ISP) | `docs/bgp-design.md` |
| MPLS(ISP 코어) | `docs/mpls-design.md` |
| VLAN, VRRP, MSTP, EtherChannel | `docs/vlan-design.md` |
| MLAG(DC) | `docs/mlag-design.md` |
| DMVPN, IPsec | `docs/dmvpn-design.md` |
| DHCP, DNS | `docs/dhcp-dns-design.md` |
| QoS | `docs/qos-design.md` |

## 1-1. 컨피그 표기 규칙

- 컨피그 파일의 모든 문자는 **소문자**(호스트네임, 설명, 이름, 키 포함).
- 확장자는 벤더 기준: Cisco `.ios`, Arista `.eos`(Arista 장비는 `DC-SW*`), Aruba `.aos`(Aruba 장비는 `BR1-SW*`), 알파인 호스트 `.alp`, DNS 서버(Debian 계열) `.sh`(`configs/<사이트>/host/`). 파일 이름은 `<장비명>.<확장자>`.
- IP 주소 표기: Cisco는 마스크(`255.255.255.252`), Arista와 Aruba는 프리픽스 길이(`/30`).
- 첫 줄은 벤더 표기: Cisco는 `! cisco` + `!`, Arista는 `! arista` + `!`, Aruba는 `! aruba` + `!`.
- 폴더는 `configs/<사이트>/<계층>/`로 나눔. 사이트(대분류)는 `hq`, `dc`, `br1`, `br2`, `isp1`, `isp2`, `private-internet`, 계층은 장비 역할 기준 `core`(라우터), `distribution`(L3 스위치, VRRP 게이트웨이), `access`(호스트 연결 스위치).
- 약어 사용:

| 구분 | 약어 |
|---|---|
| 인터페이스 | `et`(Arista Ethernet), `gi`(GigabitEthernet), `te`, `fo`, `fa`, `po`(Port-Channel), `lo`(Loopback), `vlan` |
| 프로토콜 | `bgp`, `ospf`, `eigrp`, `rt`, `rd`, `acl` |
| 일반 속성 | `int`(interface), `desc`(description), `addr`(address; Cisco `ip addr <주소> <마스크>`, Arista `ip add <주소>/<프리픽스>`, Aruba `ip address <주소>/<프리픽스>`), `no sh`(no shutdown), `mgmt`(management) |

| 사이트 | core | distribution | access |
|---|---|---|---|
| hq | HQ-R1, HQ-R2 | HQ-SW-2, HQ-SW-3 | HQ-SW-1 |
| dc | DC-R1 ~ DC-R4 | DC-SW1-L3 ~ DC-SW4-L3 | DC-SW1-L2, DC-SW2-L2 |
| br1 | BR1-R1, BR1-R2 | BR1-SW1-L3, BR1-SW2-L3 | BR1-SW3-L3 |
| br2 | BR2-R1, BR2-R2 | BR2-SW1-L3, BR2-SW2-L3 | BR2-SW3-L2 |
| isp1, isp2, private-internet | 전체 라우터(PE, P, Private-net) | - | - |

- 이 문서의 예시와 `configs/**/*.ios`, `configs/**/*.eos`는 같은 규칙 적용. 문서 본문(표, 설명)의 장비명은 `HQ-R2`처럼 대소문자 표기 유지.

## 2. 작성 순서

| 단계 | 일정 | 대상 | 작업 | 기준 문서 |
|---|---|---|---|---|
| 1 | 1주 월~화 | 전 장비 | 호스트네임, lo0, 인터페이스 설명·IP, 콘솔 설정 | port-mapping, ip-mapping, ospf-design |
| 2 | 1주 수~목 | 스위치 | VLAN, 트렁크, EtherChannel, MSTP, SVI, VRRP | vlan-design |
| 3 | 1주 금 | 사이트 장비 | 사이트 내부 OSPF, 사용자 VLAN DHCP | ospf-design, dhcp-dns-design |
| 3-1 | 주말(10/17) | Private-net, PI 연결 라우터 | 언더레이 OSPF(프로세스 2) | ospf-design 5절, dmvpn-design 5절 |
| 3-2 | 주말(10/17~10/18) | ISP 장비 | MPLS 코어(LDP), PE VRF `corp`, vpnv4(RR) | mpls-design |
| 4 | 2주 월 | 사이트 ISP 연결 라우터, ISP PE | 사이트 엣지 eBGP(route-map, prefix-list), PE 사이트 세션(VRF `corp` 안)과 `default-originate`, OSPF 기본 경로 광고 | bgp-design 5~6절, mpls-design 3절, ospf-design 6절 |
| 5 | 2주 화 | Private-net | PI ACL(언더레이 OSPF는 3-1에서 선행) | ospf-design 5절, dmvpn-design 5절 |
| 6 | 2주 화~수 | DC-R2, HQ-R2, BR1-R1, BR2-R2 | IPsec, Tunnel0, NHRP, 터널 OSPF | dmvpn-design |
| 7 | 2주 목 | DC-DNS-1, DC-DNS-2 | dnsmasq, 레코드 | dhcp-dns-design |
| 8 | 2주 금 | DC-R1 ~ DC-R4 | 서버 VLAN DNS ACL | dhcp-dns-design 5절, [cisco-router.md](./cisco-router.md) 3.8절 |
| 8-1 | 선택(10/19~10/21) | DC-SW3-L3, DC-SW4-L3, DC-SW1-L2, DC-SW2-L2 | MLAG 피어, MLAG 포트채널 | mlag-design, [arista-switch.md](./arista-switch.md) 5.4절 |
| 9 | 3주 수~목 | ISP 장비 | ISP OSPF, iBGP RR, PE `next-hop-self` | bgp-design 1~4절 |
| 10 | 3주 금 | 라우터 | QoS | qos-design, [cisco-router.md](./cisco-router.md) 3.7절 |

## 7. 저장과 백업

- 변경 전 장비에서 `copy running-config flash:<장비명>-backup-<날짜>.cfg`로 백업.
- 변경 후 `copy running-config startup-config`(EOS는 `write`)로 저장하고, 확인한 컨피그를 `configs/<사이트>/<계층>/<장비명>.<ios|eos>`에 반영.
- 실습 환경이므로 접속 비밀번호(`admin1234`)와 DMVPN 키(ISAKMP `dmvpn-hub`, NHRP `nhrpkey1`)를 컨피그와 문서에 그대로 기재.

## 8. 설정 후 확인

| 항목 | Cisco | Arista |
|---|---|---|
| 인터페이스 | `show ip interface brief` | `show ip interface brief` |
| OSPF | `show ip ospf neighbor`, `show ip route ospf` | `show ip ospf neighbor`, `show ip route ospf` |
| BGP | `show ip bgp summary` | - |
| VRRP | `show vrrp brief` | `show vrrp brief` |
| 채널, 트렁크 | `show etherchannel summary`, `show interfaces trunk` | `show port-channel dense`, `show interfaces trunk` |
| MSTP | `show spanning-tree mst`, `show spanning-tree mst configuration` | `show spanning-tree mst`, `show spanning-tree mst configuration` |
| DMVPN | `show dmvpn`, `show ip nhrp`, `show crypto ipsec sa` | - |
| DHCP | `show ip dhcp binding`, `show ip dhcp pool` | - |
| route-map, prefix-list | `show route-map`, `show ip prefix-list` | - |
| MPLS, VRF | `show mpls ldp neighbor`, `show ip vrf`, `show ip bgp vpnv4 all summary` | - |
| ACL | `show ip access-lists` | `show ip access-lists` |
| MLAG | - | `show mlag`, `show mlag detail`, `show port-channel dense` |
| QoS | `show policy-map interface gi0/0` | - |

### 8-1. Arista 설정 필터 (running-config)

- `section`은 파이프 없이, `include`, `grep`은 파이프(`|`) 뒤에 입력(vEOS 4.29에서 `| grep` 동작 확인).
- `| grep -E "a|b"`처럼 큰따옴표 안에 `|`가 들어가는 정규식도 사용 가능하며 따옴표를 반드시 닫음.

| 확인할 것 | 명령 |
|---|---|
| VLAN 정의 | `show running-config section ^vlan` |
| 트렁크 native, 허용 VLAN | `show running-config \| grep -E "native vlan\|allowed vlan"` |
| access 포트 | `show running-config \| grep "access vlan"` |
| 라우티드 포트 | `show running-config \| grep "no switchport"` |
| 인터페이스 블록 | `show running-config section ^interface` |
| 특정 포트, SVI | `show running-config interfaces ethernet7`, `show running-config interfaces vlan 50` |
