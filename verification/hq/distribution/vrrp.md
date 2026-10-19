# VRRP 검증 (HQ / distribution)

- Jira: KAN-9
- 대상 장비: HQ-SW-2, HQ-SW-3
- 기준 문서: [vrrp-mstp-design.md](../../../docs/vrrp-mstp-design.md) 2절
- 검증일: 2026-10-11

| 장비 | 명령 | 기대 결과 | 실제 결과 | 판정 |
|---|---|---|---|---|
| HQ-SW-2 | `show vrrp brief` | Vl10 그룹 10, Vl20 그룹 20, priority 110, Master | Vl10, Vl20 모두 pri 110, Pre Y, Master, VIP 10.1.10.1, 10.1.20.1 | 통과 |
| HQ-SW-3 | `show vrrp brief` | priority 90, Backup, Master addr은 HQ-SW-2 | Vl10, Vl20 모두 pri 90, Backup, Master addr 10.1.10.2, 10.1.20.2 | 통과 |
| HQ-SW-2, HQ-SW-3 | 장애 전환(SVI shutdown) | Backup이 Master로 전환, 복구 시 Master 복귀 | HQ-SW-2 SVI shutdown 시 HQ-SW-3이 Vl10, Vl20 Master(Master addr 10.1.10.3, 10.1.20.3)로 전환, 복구 후 HQ-SW-3 Backup(Master addr 10.1.10.2, 10.1.20.2)으로 복귀. 중단 시간은 미측정 | 통과 |

HQ-SW-2 VRRP Master
![HQ-SW-2 VRRP Master](images/Pasted%20image%2020261012000253.png)

HQ-SW-3 VRRP Backup
![HQ-SW-3 VRRP Backup](images/Pasted%20image%2020261012000229.png)

HQ-SW-3 VRRP Master 전환 확인(HQ-SW-2 shutdow)
![HQ-SW-3 VRRP Master 전환 확인(HQ-SW-2 shutdow)](images/Pasted%20image%2020261012000408.png)

HQ-SW-3 VRRP Backup 전환 확인(HQ-SW-2 복구 후)
![HQ-SW-3 VRRP Backup 전환 확인(HQ-SW-2 복구 후)](images/Pasted%20image%2020261012000638.png)