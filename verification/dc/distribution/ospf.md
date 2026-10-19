# OSPF 검증 (DC / distribution)

- Jira: KAN-14
- 대상 장비: DC-SW1-L3-SW4-L3(10.10.10.11-14)
- 기준 문서: [ospf-design.md](../../../docs/ospf-design.md) 2~4절
- 검증일: 2026-10-12

| 장비                               | 명령                             | 기대 결과                                                | 실제 결과 | 판정  |
| -------------------------------- | ------------------------------ | ---------------------------------------------------- | ----- | --- |
| DC-SW1-L3-SW4-L3(10.10.10.11-14) | `show ip ospf neighbor` | 모든 이웃 FULL | DC-SW1-L3, SW2-L3는 DC-R1, R2, 분배 스위치 3대와 5개, DC-SW3-L3, SW4-L3는 분배 스위치 2대와 DC-R3, R4 4개, 모두 FULL | 통과 |
| DC-SW1-L3-SW4-L3(10.10.10.11-14) | `show ip route ospf` | 다른 장비 `lo0`와 반대편 서브넷 학습 | 다른 장비 lo0(10.10.10.1-4, 11-14), 반대편 /30 링크, 서버 VLAN 10.2.50.0/24(SW1, SW2) 학습 | 통과 |
| DC-SW1-L3-SW4-L3(10.10.10.11-14) | `show ip ospf interface brief` | 사용자 VLAN SVI와 `lo0`는 passive, 라우티드 포트 point-to-point | Lo0, Et는 Area 0, Et는 P2P Nbrs 1, DC-SW3-L3, SW4-L3의 Vl50(10.2.50.2, 10.2.50.3)은 Nbrs 0(passive) | 통과 |

프로세스 10, Area 0.

DC-SW1-L3
![DC-SW1-L3](images/Pasted%20image%2020261012192154.png)

![DC-SW1-L3](images/Pasted%20image%2020261012192127.png)

![DC-SW1-L3](images/Pasted%20image%2020261012192138.png)


DC-SW2-L3
![DC-SW2-L3](images/Pasted%20image%2020261012192208.png)

![DC-SW2-L3](images/Pasted%20image%2020261012192225.png)

![DC-SW2-L3](images/Pasted%20image%2020261012192236.png)

DC-SW3-L3
![DC-SW3-L3](images/Pasted%20image%2020261012192256.png)

![DC-SW3-L3](images/Pasted%20image%2020261012192311.png)

![DC-SW3-L3](images/Pasted%20image%2020261012192320.png)

DC-SW4-L3
![DC-SW4-L3](images/Pasted%20image%2020261012192334.png)

![DC-SW4-L3](images/Pasted%20image%2020261012192345.png)

![DC-SW4-L3](images/Pasted%20image%2020261012192402.png)