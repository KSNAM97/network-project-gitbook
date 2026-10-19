# STP(MST) 검증 (BR1 / access)

- Jira: KAN-12
- 대상 장비: BR1-SW3-L3
- 기준 문서: [vrrp-mstp-design.md](../../../docs/vrrp-mstp-design.md) 3절
- 검증일: 2026-10-17
- Aruba CX 교체: BR1 스위치를 Aruba CX(ArubaOS-CX Virtual 10.07)로 교체하고 AOS-CX 명령 기준으로 재검증

| 장비 | 명령 | 기대 결과 | 실제 결과 | 판정 |
|---|---|---|---|---|
| BR1-SW3-L3 | `show spanning-tree mst` | 기본 priority, 루트는 SW1, 호스트 포트 Designated Forwarding | MST1 VLAN 10,20,100, 루트 08:00:09:48:bf:8f(BR1-SW1-L3, priority 4096), 자기 priority 32768(기본). 1/1/1 Root FWD, 1/1/2 Alternate BLK, 1/1/6과 1/1/7 Designated FWD(MST0도 루트 SW1) | 통과 |

BR1-SW3-L3 MSTP

![BR1-SW3-L3 MSTP](images/Pasted%20image%2020261017184609.png)