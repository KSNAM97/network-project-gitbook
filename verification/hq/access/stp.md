# STP(MST) 검증 (HQ / access)

- Jira: KAN-9
- 대상 장비: HQ-SW-1
- 기준 문서: [vrrp-mstp-design.md](../../../docs/vrrp-mstp-design.md) 3절
- 검증일: 2026-10-11

| 장비 | 명령 | 기대 결과 | 실제 결과 | 판정 |
|---|---|---|---|---|
| HQ-SW-1 | `show spanning-tree mst 1` | 기본 priority(32768), 루트는 HQ-SW-2 | Bridge 32769, Root `0c65.58a4` priority 4097(HQ-SW-2), Po1 Root FWD, Po2 Altn BLK, Gi3/0 Gi3/1 Desg FWD Edge | 통과 |

HQ-SW-1 MSTP

![HQ-SW-1 MSTP](images/Pasted%20image%2020261011235142.png)

