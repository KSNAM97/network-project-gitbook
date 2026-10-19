# VLAN, 트렁크 검증 (BR1 / access)

- Jira: KAN-12
- 대상 장비: BR1-SW3-L3
- 기준 문서: [vlan-design.md](../../../docs/vlan-design.md) 1, 4~6절
- 검증일: 2026-10-17
- Aruba CX 교체: BR1 스위치를 Aruba CX(ArubaOS-CX Virtual 10.07)로 교체하고 AOS-CX 명령 기준으로 재검증

| 장비 | 명령 | 기대 결과 | 실제 결과 | 판정 |
|---|---|---|---|---|
| BR1-SW3-L3 | `show interface trunk` | `1/1/1`, `1/1/2` 트렁크, 허용 10,20,100(native 999는 허용 목록에 없음) | 1/1/1, 1/1/2 Trunk VLANs 10,20,100. Native VLAN은 None으로 표시(999는 허용 목록 밖, 멤버 포트 없음) | 통과 |
| BR1-SW3-L3 | `show vlan` | VLAN 10 br1-public(1/1/6, BR1-PC1), VLAN 20 br1-private(1/1/7, BR1-PC2) | VLAN 10 br1-public up(1/1/1-1/1/2, 1/1/6), VLAN 20 br1-private up(1/1/1-1/1/2, 1/1/7), VLAN 100 mgmt up(1/1/1-1/1/2), 999 native와 1 DEFAULT_VLAN_1은 down(no_member_port) | 통과 |

BR1-SW3-L3 TRUNK

![BR1-SW3-L3 TRUNK](images/Pasted%20image%2020261017184531.png)

BR1-SW3-L3 VLAN

![BR1-SW3-L3 VLAN](images/Pasted%20image%2020261017184540.png)