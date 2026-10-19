📢 [프로젝트] 최종 설계 확정 — HQ/DC/BR1/BR2 + ISP 이중화 + DMVPN

■ 구조
사이트(HQ 65001 / DC 65002 / BR1 65003 / BR2 65004) 내부는 OSPF, 사이트 엣지 라우터만 ISP와 eBGP,
ISP-1(AS 65100) · ISP-2(AS 65200)는 iBGP Route Reflector 구성 (P1/P2 RR, PE-A/PE-B Client, ISP 내부 OSPF, ISP 코어 MPLS L3VPN).
사이트↔ISP는 엣지 eBGP(PE가 기본 경로 전달, 사이트 /16 광고, route-map/prefix-list)+OSPF 기본 경로 광고, DC↔HQ/BR1/BR2는 DMVPN Phase3(mGRE over IPsec)으로
Private Internet(203.0.113.0/24) 경유. Private Internet에는 화이트리스트 ACL 적용.
DC 내부 스위치 6대(L3 4대 + 서버용 L2 2대)는 Arista cEOS, BR1 스위치 3대는 Aruba CX, 나머지는 전부 Cisco.
게이트웨이 이중화는 VRRP, 스패닝 트리는 MSTP로 전 사이트 통일합니다.
DC 서버 VLAN(50)은 DC-DNS-1(주)과 DC-DNS-2(백업) 두 대로 구성합니다 (DHCP는 사이트 게이트웨이에서 제공, DNS는 `DNS` 템플릿의 `dnsmasq`, 주소 10.2.50.10, 10.2.50.11).

■ 역할 분담
- 담당: 남기석 (전 사이트). 작업 영역은 Net-Cloud(DC, HQ, ISP-1, ISP-2, Private Internet, DNS 서버, QoS)와 Policy(BR1, BR2, DMVPN Spoke+IPsec, ACL/컨벤션/문서)로 구분

■ 일정 (3.5주, 10/12~11/4)
- 1주: 설계·환경, VLAN/트렁크/EtherChannel/VRRP/MSTP, 금요일에 사이트 내부 OSPF + 사이트 DHCP
- 주말(10/17~10/18): Private Internet OSPF 선행, ISP MPLS 코어(LDP), PE VRF, vpnv4 선행 작업
- 2주: 월 사이트 엣지 eBGP / 화 PI ACL, DMVPN Hub / 수 DMVPN Spoke / 목 DNS 서버, Phase3 검증 / 금 서버 VLAN ACL, 전 사이트 상호도달
- 3주: 월 VRRP·EtherChannel 장애 실측 / 화 DMVPN Hub 장애 / 수 ISP 내부 iBGP RR / 목 PE 광고, ISP-1 장애 전환 / 금 QoS, 트러블슈팅 로그
- 3.5주: PPT, 리허설
- BGP와 QoS는 후반에 배치하고 OSPF, DHCP는 1주차로 앞당겼습니다. 상세는 docs/schedule.md 참고.

■ 컨벤션
- VLAN: 10=HQ-PUBLIC, 20=HQ-PRIVATE, 50=DC-SERVER(DC-DNS-1, DC-DNS-2), 100=MGMT, 999=NATIVE
  (BR1, BR2도 HQ와 같이 10=BRx-PUBLIC, 20=BRx-PRIVATE)
- 인터페이스/IP 매핑은 docs/network-project-final.md 참고, 실제 케이블링과 반드시 대조
- 브랜치: feature/<역할>-<내용>, PR 후 본인 검토를 거쳐 main에 merge
- 커밋 메시지: <Jira키>: [역할][VLAN태그] 내용
  예) KAN-14: [Network][vlan-dc-server] DC-DNS-1 ACL 추가
  Jira 프로젝트 키는 KAN이고, 커밋 맨 앞에 키를 적으면 이슈에 자동 연결됩니다.
- 컨피그 파일: configs/<사이트>/<계층>/<장비명>.<ios|eos> 로 저장
  변경 전에 장비에서 copy running-config flash:<장비명>-backup-<날짜>.cfg 로 백업

■ 리소스 주의
34대를 한꺼번에 켜면 부팅 순간 메모리가 몰려 GNS3 VM이 프로세스를 종료할 수 있습니다.
BR → HQ → DC 순서로 나눠서 켜고, 작업할 사이트만 기동하는 것을 기본으로 합니다.

■ 목표
3.5주(10/12~11/4), "완주"보다 "각자 결과물 하나씩" 우선. 취업활동으로 잠시 손 놓아도 괜찮습니다.

■ 문서·링크
- GitHub: KSNAM97/network-project
  README.md, docs/README.md(문서 목차), docs/network-project-final.md(전체 설계), docs/schedule.md(일정), verification/(장비 검증 기록)
- Jira: KAN 프로젝트 (티켓 목록은 jira/jira-tickets-3person.csv 기준으로 등록)
#team-net-cloud #team-policy #dev-issues
