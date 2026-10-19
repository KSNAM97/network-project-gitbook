# EtherChannel 검증 (DC / distribution)

- Jira: KAN-10
- 대상 장비: DC-SW3-L3, DC-SW4-L3
- 기준 문서: [vlan-design.md](../../../docs/vlan-design.md) 4절
- 검증일: 2026-10-11

| 장비 | 명령 | 기대 결과 | 실제 결과 | 판정 |
|---|---|---|---|---|
| DC-SW3-L3 | `show port-channel dense` | Po1(Et5, Et6) LACP, 멤버 활성 | Po1(U) LACP(a) Et5(PG+) Et6(PG+), 사용 채널 1개 | 통과 |
| DC-SW4-L3 | `show port-channel dense` | Po1(Et5, Et6) LACP, 멤버 활성 | Po1(U) LACP(a) Et5(PG+) Et6(PG+), 사용 채널 1개 | 통과 |

DC-SW3-L3 Po1

![DC-SW3-L3 Po1](images/Pasted%20image%2020261011233546.png)

DC-SW4-L3 Po1

![DC-SW4-L3 Po1](images/Pasted%20image%2020261011233604.png)