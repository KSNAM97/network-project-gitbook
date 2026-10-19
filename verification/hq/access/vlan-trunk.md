# VLAN, 트렁크 검증 (HQ / access)

- Jira: KAN-8
- 대상 장비: HQ-SW-1
- 기준 문서: [vlan-design.md](../../../docs/vlan-design.md) 1, 5, 6절
- 검증일: 2026-10-11

| 장비 | 명령 | 기대 결과 | 실제 결과 | 판정 |
|---|---|---|---|---|
| HQ-SW-1 | `show interfaces trunk` | Po1, Po2 trunking, native 999, 허용 10,20,100 | Po1, Po2 802.1q trunking, native 999, 허용·active·STP forwarding 10,20,100 | 통과 |
| HQ-SW-1 | `show vlan brief` | VLAN 10 hq-public, 20 hq-private, 100 mgmt, 999 native, gi3/0 VLAN 10, gi3/1 VLAN 20 | VLAN 10 hq-public(Gi3/0), 20 hq-private(Gi3/1), 100 mgmt, 999 native 모두 active | 통과 |

HQ-SW-1 TRUNK
![HQ-SW-1 TRUNK](images/Pasted%20image%2020261011235502.png)



HQ-SW-1 VLAN
![HQ-SW-1 VLAN](images/Pasted%20image%2020261011235512.png)

