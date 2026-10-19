# OSPF 검증 (HQ / distribution)

- Jira: KAN-14
- 대상 장비: HQ-SW-2(11.11.11.12), HQ-SW-3(11.11.11.13)
- 기준 문서: [ospf-design.md](../../../docs/ospf-design.md) 2~4절
- 검증일: 2026-10-12

| 장비                                         | 명령                             | 기대 결과                                                | 실제 결과 | 판정  |
| ------------------------------------------ | ------------------------------ | ---------------------------------------------------- | ----- | --- |
| HQ-SW-2(11.11.11.12), HQ-SW-3(11.11.11.13) | `show ip ospf neighbor` | 모든 이웃 FULL | HQ-SW-2, SW-3 각 2개(HQ-R1, HQ-R2) 모두 FULL, 스위치 간 이웃 없음(Po 링크는 L2) | 통과 |
| HQ-SW-2(11.11.11.12), HQ-SW-3(11.11.11.13) | `show ip route ospf` | 다른 장비 `lo0`와 반대편 서브넷 학습 | HQ 내부 /30 링크, 라우터·상대 스위치 lo0(11.11.11.1, 11.11.11.2, 상대 스위치) 학습, 13개 서브넷. DMVPN 전이라 타 사이트 경로 없음 | 통과 |
| HQ-SW-2(11.11.11.12), HQ-SW-3(11.11.11.13) | `show ip ospf interface brief` | 사용자 VLAN SVI와 `lo0`는 passive, 라우티드 포트 point-to-point | Lo0 LOOP, Vl10, Vl20 DR Nbrs 0/0(passive), Gi1/0, Gi1/1 P2P 1/1, 전체 Area 1 | 통과 |

프로세스 11, Area 1.

HQ-SW-2 OSPF

![HQ-SW-2 OSPF](images/Pasted%20image%2020261012194052.png)

HQ-SW-3 OSPF

![HQ-SW-3 OSPF](images/Pasted%20image%2020261012194157.png)