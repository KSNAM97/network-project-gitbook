# STP(MST) 검증 (BR2 / access)

- Jira: KAN-13
- 대상 장비: BR2-SW3-L2
- 기준 문서: [vrrp-mstp-design.md](../../../docs/vrrp-mstp-design.md) 3절
- 검증일: 2026-10-13

| 장비         | 명령                         | 기대 결과                                      | 실제 결과 | 판정  |
| ---------- | -------------------------- | ------------------------------------------ | ----- | --- |
| BR2-SW3-L2 | `show spanning-tree mst 1` | 기본 priority, 루트는 SW1, 호스트 포트 Desg FWD Edge | 루트 BR2-SW1-L3(0cc6.38db, priority 4097), 자기 priority 32769(기본), Gi0/0 Root FWD, Gi0/1 Altn BLK, Gi3/0과 Gi3/1 Desg FWD P2p Edge | 통과 |

BR2-SW3-L2 STP
![BR2-SW3-L2 STP](images/Pasted%20image%2020261013185003.png)
