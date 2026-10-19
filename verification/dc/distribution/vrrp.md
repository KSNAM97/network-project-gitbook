# VRRP 검증 (DC / distribution)

- Jira: KAN-11
- 대상 장비: DC-SW3-L3, DC-SW4-L3
- 기준 문서: [vrrp-mstp-design.md](../../../docs/vrrp-mstp-design.md) 2절
- 검증일: 2026-10-11

| 장비 | 명령 | 기대 결과 | 실제 결과 | 판정 |
|---|---|---|---|---|
| DC-SW3-L3 | `show vrrp brief` | Vl50 그룹 50, priority 110, Master, VIP 10.2.50.1 | Vl50 ID 50 Ver 2 Pri 110 Master, VR IP 10.2.50.1 | 통과 |
| DC-SW4-L3 | `show vrrp brief` | Vl50 그룹 50, priority 90, Backup | Vl50 ID 50 Ver 2 Pri 90 Backup, VR IP 10.2.50.1 | 통과 |
| DC-SW3-L3, DC-SW4-L3 | 장애 전환(SVI shutdown) | Backup이 Master로 전환, 복구 시 Master 복귀 | DC-SW3-L3 shutdown 시 DC-SW4-L3이 Master(Pri 90)로 전환, 복구 후 Backup으로 복귀. 중단 시간은 미측정 | 통과 |

DC-SW3-L3 VRRP Master
![DC-SW3-L3 VRRP Master](images/Pasted%20image%2020261011234432.png)

DC-SW4-L3 VRRP Backup
![DC-SW4-L3 VRRP Backup](images/Pasted%20image%2020261011234442.png)

DC-SW4-L3 VRRP Master 전환 확인(DC-SW3-L3 shutdown)
![DC-SW4-L3 VRRP Master 전환 확인(DC-SW3-L3 shutdown)](images/Pasted%20image%2020261011234548.png)

DC-SW4-L3 VRRP Backup 전환 확인(DC-SW3-L3 복구 후)
![DC-SW4-L3 VRRP Backup 전환 확인(DC-SW3-L3 복구 후)](images/Pasted%20image%2020261011234933.png)