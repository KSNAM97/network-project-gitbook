# STP(MST) 검증 (DC / access)

- Jira: KAN-11
- 대상 장비: DC-SW1-L2, DC-SW2-L2
- 기준 문서: [vrrp-mstp-design.md](../../../docs/vrrp-mstp-design.md) 3절
- 검증일: 2026-10-11

| 장비 | 명령 | 기대 결과 | 실제 결과 | 판정 |
|---|---|---|---|---|
| DC-SW1-L2 | `show spanning-tree mst 1` | 기본 priority, 루트는 DC-SW3-L3, Et1 root, Et2 alternate | Bridge 32769, Root `0c06.2ecc.02b8` priority 4097, Et1 root FWD, Et2 alternate discarding, Et12 designated FWD Edge | 통과 |
| DC-SW2-L2 | `show spanning-tree mst 1` | 위와 같음 | Bridge 32769, Root `0c06.2ecc.02b8` priority 4097, Et1 root FWD, Et2 alternate discarding, Et12 designated FWD Edge | 통과 |

DC-SW1-L2 MSTP 확인

![DC-SW1-L2 MSTP 확인](images/Pasted%20image%2020261011232742.png)

DC-SW2-L2 MSTP 확인

![DC-SW2-L2 MSTP 확인](images/Pasted%20image%2020261011232807.png)