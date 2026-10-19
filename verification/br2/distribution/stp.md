# STP(MST) 검증 (BR2 / distribution)

- Jira: KAN-13
- 대상 장비: BR2-SW1-L3, BR2-SW2-L3
- 기준 문서: [vrrp-mstp-design.md](../../../docs/vrrp-mstp-design.md) 3절
- 검증일: 2026-10-13

| 장비         | 명령                         | 기대 결과                                                    | 실제 결과 | 판정  |
| ---------- | -------------------------- | -------------------------------------------------------- | ----- | --- |
| BR2-SW1-L3 | `show spanning-tree mst 1` | 루트(priority 4096), region br2, instance 1 VLAN 10,20,100 | MST1 VLAN 10,20,100, priority 4097(4096 sysid 1), Root this switch for MST1, Gi2/0과 Po1 Desg FWD. region 이름은 이 출력에 없음(show spanning-tree mst configuration 필요) | 통과 |
| BR2-SW2-L3 | `show spanning-tree mst 1` | 보조 루트(8192), 루트는 SW1 | priority 8193(8192 sysid 1), 루트 4097(BR2-SW1-L3), Po1 Root FWD, Gi2/0 Desg FWD | 통과 |

BR2-SW1-L3 STP

![BR2-SW1-L3 STP](images/Pasted%20image%2020261013185140.png)

BR2-SW2-L3 STP

![BR2-SW2-L3 STP](images/Pasted%20image%2020261013185200.png)