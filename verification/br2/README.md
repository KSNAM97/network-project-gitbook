# BR2 검증 개요

GNS3 토폴로지(검증 대상 장비와 포트). 상세 결과는 아래 문서 링크에서 확인.

![BR2 토폴로지](images/topology-br2.png)

## 핵심 결과

- DHCP Wireshark DORA(Cisco, 서버 선택 관찰) → [dhcp](distribution/dhcp.md)
- DMVPN Spoke, QoS(DNS 분류) → [dmvpn](core/dmvpn.md), [qos](core/qos.md)

## 계층별 검증 문서

| 계층 | 항목 | Jira | 문서 |
|---|---|---|---|
| access(L2) | STP | KAN-13 | [access/stp.md](access/stp.md) |
| access(L2) | VLAN, 트렁크 검증 | KAN-13 | [access/vlan-trunk.md](access/vlan-trunk.md) |
| core | DMVPN Spoke 검증 | KAN-23 | [core/dmvpn.md](core/dmvpn.md) |
| core | ISP 연결 검증 | KAN-18 | [core/isp-link.md](core/isp-link.md) |
| core | OSPF 검증 | KAN-14 | [core/ospf.md](core/ospf.md) |
| core | QoS 검증 | KAN-25 | [core/qos.md](core/qos.md) |
| distribution | DHCP 검증 | KAN-14 | [distribution/dhcp.md](distribution/dhcp.md) |
| distribution | OSPF 검증 | KAN-14 | [distribution/ospf.md](distribution/ospf.md) |
| distribution | EtherChannel 검증 | KAN-13 | [distribution/po-channel.md](distribution/po-channel.md) |
| distribution | STP | KAN-13 | [distribution/stp.md](distribution/stp.md) |
| distribution | VLAN, 트렁크 검증 | KAN-13 | [distribution/vlan-trunk.md](distribution/vlan-trunk.md) |
| distribution | VRRP 검증 | KAN-13 | [distribution/vrrp.md](distribution/vrrp.md) |

상세 서식과 상태는 [검증 README](../README.md) 참조.
