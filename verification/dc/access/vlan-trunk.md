# VLAN, 트렁크 검증 (DC / access)

- Jira: KAN-10
- 대상 장비: DC-SW1-L2, DC-SW2-L2
- 기준 문서: [vlan-design.md](../../../docs/vlan-design.md) 1, 5, 6절
- 검증일: 2026-10-11

| 장비 | 명령 | 기대 결과 | 실제 결과 | 판정 |
|---|---|---|---|---|
| DC-SW1-L2 | `show interfaces trunk` | Et1, Et2 trunking, native 999, 허용 50,100 | Et1, Et2 trunking, native 999, 허용·active 50,100 | 통과 |
| DC-SW1-L2 | `show vlan` | VLAN 50(Et1, Et2, Et12), 100(Et1, Et2), 999 | VLAN 50 Et1 Et2 Et12, VLAN 100 Cpu Et1 Et2, 999 active | 통과 |
| DC-SW1-L2 | `show ip interface brief` | Vlan100 10.2.100.21/24 up | Vlan100 10.2.100.21/24 up/up | 통과 |
| DC-SW2-L2 | `show interfaces trunk` | Et1, Et2 trunking, native 999, 허용 50,100 | Et1, Et2 trunking, native 999, 허용·active 50,100 | 통과 |
| DC-SW2-L2 | `show vlan` | VLAN 50(Et1, Et2, Et12), 100(Et1, Et2), 999 | VLAN 50 Et1 Et2 Et12, VLAN 100 Cpu Et1 Et2, 999 active | 통과 |
| DC-SW2-L2 | `show ip interface brief` | Vlan100 10.2.100.22/24 up | Vlan100 10.2.100.22/24 up/up | 통과 |

DC-SW1-L2 TRUNK
![DC-SW1-L2 TRUNK](images/Pasted%20image%2020261011232918.png)

DC-SW1-L2 VLAN
![DC-SW1-L2 VLAN](images/Pasted%20image%2020261011233005.png)

DC-SW1-L2 INTERFACE
![DC-SW1-L2 INTERFACE](images/Pasted%20image%2020261011233048.png)

DC-SW2-L2 TRUNK
![DC-SW2-L2 TRUNK](images/Pasted%20image%2020261011233201.png)

DC-SW2-L2 VLAN
![DC-SW2-L2 VLAN](images/Pasted%20image%2020261011233214.png)

DC-SW2-L2 INTERFACE
![DC-SW2-L2 INTERFACE](images/Pasted%20image%2020261011233223.png)