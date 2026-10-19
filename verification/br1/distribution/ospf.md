# OSPF 검증 (BR1 / distribution)

- Jira: KAN-14
- 대상 장비: BR1-SW1-L3(12.12.12.11), BR1-SW2-L3(12.12.12.12)
- 기준 문서: [ospf-design.md](../../../docs/ospf-design.md) 2~4절
- 검증일: 2026-10-17
- Aruba CX 교체: BR1 스위치를 Aruba CX(ArubaOS-CX Virtual 10.07)로 교체하고 AOS-CX 명령 기준으로 재검증

| 장비 | 명령 | 기대 결과 | 실제 결과 | 판정 |
|---|---|---|---|---|
| BR1-SW1-L3(12.12.12.11) | `show ip ospf neighbors` | 모든 이웃 FULL | 이웃 2개 모두 FULL: 12.12.12.1(BR1-R1, 10.3.0.1, 1/1/1), 12.12.12.2(BR1-R2, 10.3.0.6, 1/1/2). 스위치 간 이웃 없음(lag1은 L2) | 통과 |
| BR1-SW2-L3(12.12.12.12) | `show ip ospf neighbors` | 모든 이웃 FULL | 이웃 2개 모두 FULL: 12.12.12.1(BR1-R1, 10.3.0.9, 1/1/1), 12.12.12.2(BR1-R2, 10.3.0.13, 1/1/2). 스위치 간 이웃 없음 | 통과 |
| BR1-SW1-L3(12.12.12.11) | `show ip route ospf` | 다른 장비 `lo0`와 반대편 서브넷 학습 | 6개: 10.3.0.8/30, 10.3.0.12/30, 10.3.0.16/30, 12.12.12.1/32, 12.12.12.2/32, 12.12.12.12/32(R1, R2 경유 2경로), 전부 [110/101]. 타 사이트 경로 없음 | 통과 |
| BR1-SW2-L3(12.12.12.12) | `show ip route ospf` | 다른 장비 `lo0`와 반대편 서브넷 학습 | 6개: 10.3.0.0/30, 10.3.0.4/30, 10.3.0.16/30, 12.12.12.1/32, 12.12.12.2/32, 12.12.12.11/32(R1, R2 경유 2경로), 전부 [110/101]. 타 사이트 경로 없음 | 통과 |
| BR1-SW1-L3, BR1-SW2-L3 | `show ip ospf interface brief` | 라우티드 포트 point-to-point, `lo0`와 SVI 포함, 전체 Area 0.0.0.2 | Interfaces 5개 모두 up, Area 0.0.0.2: 1/1/1, 1/1/2 Point-to-point cost 100, loopback0 Loopback cost 0, vlan10과 vlan20 DR-other cost 100(이웃 없음). passive 여부는 이 출력에서 구분되지 않음 | 통과 |

프로세스 12, Area 0.0.0.2(Area 2).

BR1-SW1-L3 OSPF

![BR1-SW1-L3 OSPF](images/Pasted%20image%2020261017185252.png)

BR1-SW2-L3 OSPF

![BR1-SW2-L3 OSPF](images/Pasted%20image%2020261017185313.png)