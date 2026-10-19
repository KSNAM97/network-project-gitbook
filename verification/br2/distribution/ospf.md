# OSPF 검증 (BR2 / distribution)

- Jira: KAN-14
- 대상 장비: BR2-SW1-L3(13.13.13.11), BR2-SW2-L3(13.13.13.12)
- 기준 문서: [ospf-design.md](../../../docs/ospf-design.md) 2~4절
- 검증일: 2026-10-12

| 장비                                               | 명령                             | 기대 결과                                                | 실제 결과 | 판정  |
| ------------------------------------------------ | ------------------------------ | ---------------------------------------------------- | ----- | --- |
| BR2-SW1-L3(13.13.13.11), BR2-SW2-L3(13.13.13.12) | `show ip ospf neighbor` | 모든 이웃 FULL | BR2-SW1-L3, SW2-L3 각 2개(BR2-R1, BR2-R2) 모두 FULL, 스위치 간 이웃 없음(Po1은 L2) | 통과 |
| BR2-SW1-L3(13.13.13.11), BR2-SW2-L3(13.13.13.12) | `show ip route ospf` | 다른 장비 `lo0`와 반대편 서브넷 학습 | 내부 /30 링크, 라우터·상대 스위치 lo0(13.13.13.1, .2, 상대 스위치) 학습, 13개 서브넷. 타 사이트 경로 없음 | 통과 |
| BR2-SW1-L3(13.13.13.11), BR2-SW2-L3(13.13.13.12) | `show ip ospf interface brief` | 사용자 VLAN SVI와 `lo0`는 passive, 라우티드 포트 point-to-point | Lo0 LOOP, Vl10, Vl20 DR Nbrs 0/0(passive), Gi0/0, Gi0/1 P2P 1/1, 전체 PID 13, Area 3 | 통과 |

프로세스 13, Area 3.
BR2-SW1-L3 OSPF

![BR2-SW1-L3 OSPF](images/Pasted%20image%2020261012205237.png)

BR2-SW2-L3 OSPF

![BR2-SW2-L3 OSPF](images/Pasted%20image%2020261012205249.png)