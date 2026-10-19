# VRRP 검증 (BR1 / distribution)

- Jira: KAN-12
- 대상 장비: BR1-SW1-L3, BR1-SW2-L3
- 기준 문서: [vrrp-mstp-design.md](../../../docs/vrrp-mstp-design.md) 2절
- 검증일: 2026-10-17
- Aruba CX 교체: BR1 스위치를 Aruba CX(ArubaOS-CX Virtual 10.07)로 교체하고 AOS-CX 명령 기준으로 재검증

| 장비 | 명령 | 기대 결과 | 실제 결과 | 판정 |
|---|---|---|---|---|
| BR1-SW1-L3 | `show vrrp` | vlan10 그룹 10, vlan20 그룹 20, priority 110, Master, VIP 10.3.10.1, 10.3.20.1 | VRRP enabled. vlan10, vlan20 MASTER, Priority 110, VIP 10.3.10.1, 10.3.20.1, Virtual MAC 00:00:5E:00:01:0A, ...:14, Preemption enabled, Master Router 자기 자신(local) | 통과 |
| BR1-SW2-L3 | `show vrrp` | vlan10, vlan20 priority 90, Backup, Master addr 10.3.10.2, 10.3.20.2 | vlan10, vlan20 BACKUP, Priority 90, Master Router 10.3.10.2, 10.3.20.2 | 통과 |
| BR1-SW1-L3, BR1-SW2-L3 | 장애 전환(BR1-SW1-L3 vlan10 shutdown) | Backup이 Master로 전환, 복구 시 Backup 복귀 | BR1-SW1-L3 vlan10 shutdown 시 BR1-SW2-L3 vlan10이 MASTER(Priority 90, Master Router 10.3.10.3 local)로 전환, vlan20은 BACKUP 유지. SVI 복구 후 vlan10이 BACKUP으로 복귀(Master Router 10.3.10.2). 전환 시간은 미측정 | 통과 |

BR1-SW1-L3 VRRP MASTER
![BR1-SW1-L3 VRRP MASTER](images/Pasted%20image%2020261017185553.png)

BR1-SW2-L3 VRRP BACKUP
![BR1-SW2-L3 VRRP BACKUP](images/Pasted%20image%2020261017185605.png)

BR1-SW2-L3 VRRP MASTER 전환 확인(BR1-SW1-L3 SHUTDOWN)
![BR1-SW2-L3 VRRP MASTER 전환 확인(BR1-SW1-L3 SHUTDOWN)](images/Pasted%20image%2020261017185758.png)

BR1-SW2-L3 VRRP BACKUP 전환 확인(BR1-SW1-L3 복구)
![BR1-SW2-L3 VRRP BACKUP 전환 확인(BR1-SW1-L3 복구)](images/Pasted%20image%2020261017185831.png)