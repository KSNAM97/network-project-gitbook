# EtherChannel 검증 (HQ / access)

- Jira: KAN-8, KAN-9
- 대상 장비: HQ-SW-1
- 기준 문서: [vlan-design.md](../../../docs/vlan-design.md) 4절
- 검증일: 2026-10-11

| 장비 | 명령 | 기대 결과 | 실제 결과 | 판정 |
|---|---|---|---|---|
| HQ-SW-1 | `show etherchannel summary` | Po1(Gi1/0, Gi1/1), Po2(Gi1/2, Gi1/3) LACP, 멤버 `(P)` | Po1(SU) Gi1/0(P) Gi1/1(P), Po2(SU) Gi1/2(P) Gi1/3(P) | 통과 |

HQ-SW-1 EtherChannel

![HQ-SW-1 EtherChannel](images/Pasted%20image%2020261011234834.png)

