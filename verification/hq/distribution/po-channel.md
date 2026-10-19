# EtherChannel 검증 (HQ / distribution)

- Jira: KAN-8, KAN-9
- 대상 장비: HQ-SW-2, HQ-SW-3
- 기준 문서: [vlan-design.md](../../../docs/vlan-design.md) 4절
- 검증일: 2026-10-11

| 장비 | 명령 | 기대 결과 | 실제 결과 | 판정 |
|---|---|---|---|---|
| HQ-SW-2 | `show etherchannel summary` | Po1(Gi0/0, Gi0/1), Po3(Gi0/2, Gi0/3) LACP, `(P)` | Po1(SU) Gi0/0(P) Gi0/1(P), Po3(SU) Gi0/2(P) Gi0/3(P) | 통과 |
| HQ-SW-3 | `show etherchannel summary` | Po2(Gi0/0, Gi0/1), Po3(Gi0/2, Gi0/3) LACP, `(P)` | Po2(SU) Gi0/0(P) Gi0/1(P), Po3(SU) Gi0/2(P) Gi0/3(P) | 통과 |

HQ-SW-2 EtherChannel

![HQ-SW-2 EtherChannel](images/Pasted%20image%2020261011235246.png)

HQ-SW-3 EtherChannel

![HQ-SW-3 EtherChannel](images/Pasted%20image%2020261011235303.png)