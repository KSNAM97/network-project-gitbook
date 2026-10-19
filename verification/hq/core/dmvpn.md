# DMVPN Spoke 검증 (HQ / core)

- Jira: KAN-33
- 대상 장비: HQ-R2
- 기준 문서: [dmvpn-design.md](../../../docs/dmvpn-design.md) 1~4절
- 검증일: 2026-10-18

| 장비 | 명령 | 기대 결과 | 실제 결과 | 판정 |
|---|---|---|---|---|
| HQ-R2 | `show dmvpn` | Hub(172.16.0.1) Up, Tunnel0 172.16.0.13, NBMA 203.0.113.9 | Tunnel0 Type:Spoke, NHRP Peers 1. Hub 203.0.113.5(172.16.0.1) State UP, Attrb S(Static) | 통과 |
| HQ-R2 | `show ip ospf neighbor` | Tunnel0에서 DC-R2와 FULL(Spoke priority 0) | Tunnel0에서 10.10.10.2(172.16.0.1) FULL/DR(Pri 255). Gi4/0에서 Private-net 203.0.113.10(Private-net 2.2.2.2) FULL. 사이트 내부 이웃 11.11.11.1(10.1.0.17, Gi2/0), 11.11.11.13(10.1.0.14, Gi1/0), 11.11.11.12(10.1.0.6, Gi0/0) | 통과 |
| HQ-R2 | `show ip ospf interface tunnel 0` | Spoke priority 0, Hub(DR)와 인접 | Tunnel0 up/up, 172.16.0.13/24, Area 0, 프로세스 11, Router ID 11.11.11.2, BROADCAST, State DROTHER, Priority 0, DR는 10.10.10.2(172.16.0.1), BDR 없음. Neighbor Count 1, Adjacent neighbor 1(10.10.10.2, DR) | 통과 |
| HQ-R2 | `show crypto isakmp sa` | Hub와 QM_IDLE | dst 203.0.113.5, src 203.0.113.9 QM_IDLE ACTIVE(conn-id 1002). 이전 시도의 MM_NO_STATE(deleted) 항목이 함께 표시됨 | 통과 |
| HQ-R2 | `show ip nhrp` | Hub(172.16.0.1) static 항목, NBMA 203.0.113.5 | 172.16.0.1/32 via 172.16.0.1, Type static, Flags used, NBMA 203.0.113.5, never expire | 통과 |
| HQ-R2 | `show crypto ipsec sa` | Hub와 SA, 암호화 카운트 증가 | Tunnel0, profile dmvpn-profile-head-1, local 203.0.113.9, 상대 203.0.113.5(GRE/47). encaps 25, decaps 23, recv errors 0, send errors 86(SA 수립 전 시도분), PFS Y, DH group5 | 통과 |
| HQ-R2 | `ping 12.12.12.1 source lo0 repeat 10` 후 `traceroute`, `show dmvpn`, `show ip nhrp`, `show crypto isakmp sa` (BR1-R1 대상) | Phase 3 shortcut 생성, `show ip nhrp`에 Spoke 간 dynamic 항목, `traceroute`가 Hub를 거치지 않음 | ping 10/10 성공(60/113/176ms). `traceroute 12.12.12.1 source lo0`은 1홉 `172.16.0.11`(BR1-R1)로 직행해 Hub(172.16.0.1)를 거치지 않음. `show dmvpn`에 `203.0.113.13`(172.16.0.11)이 Dynamic(D)으로 추가(Peers 2), `show ip nhrp`에 `172.16.0.11/32`(NBMA 203.0.113.13)와 `12.12.12.1/32 via 172.16.0.11` dynamic 항목, `show crypto isakmp sa`에 203.0.113.9와 203.0.113.13 사이 QM_IDLE 2건(conn-id 1002, 1003). | 통과 |
| HQ-R2 | `ping 13.13.13.2 source lo0 repeat 10` 후 `traceroute`, `show dmvpn`, `show ip nhrp`, `show crypto isakmp sa` (BR2-R2 대상) | Phase 3 shortcut 생성, `show ip nhrp`에 Spoke 간 dynamic 항목, `traceroute`가 Hub를 거치지 않음 | ping 9/10 성공(52/111/172ms, 1개 손실). `traceroute 13.13.13.2 source lo0`은 1홉 `172.16.0.12`(BR2-R2)로 직행. `show dmvpn`에 `203.0.113.17`(172.16.0.12)이 Dynamic(D)으로 추가, `show ip nhrp`에 `172.16.0.12/32`(NBMA 203.0.113.17)와 `13.13.13.2/32 via 172.16.0.12` dynamic 항목, `show crypto isakmp sa`에 203.0.113.9와 203.0.113.17 사이 QM_IDLE 2건(conn-id 1006, 1007). `MM_NO_STATE (deleted)` 항목은 `clear crypto isakmp`로 지운 이전 SA의 잔재 | 통과 |

Phase 3 shortcut 검증은 2026-10-18에 HQ-R2에서 BR1-R1, BR2-R2 대상으로 수행(BR1-R1 ↔ BR2-R2는 `verification/br1/core/dmvpn.md`).

HQ-R2 show ip ospf interface tunnel 0
![HQ-R2 OSPF interface tunnel 0](images/dmvpn-hq-r2-ospf-interface.webp)

HQ-R2 dmvpn
![HQ-R2 dmvpn](images/dmvpn-hq-r2-dmvpn.webp)

HQ-R2 nhrp
![HQ-R2 nhrp](images/dmvpn-hq-r2-nhrp.png)

HQ-R2 isakmp
![HQ-R2 isakmp](images/dmvpn-hq-r2-isakmp.webp)

HQ-R2 ipsec
![HQ-R2 ipsec](images/dmvpn-hq-r2-ipsec.webp)

HQ-R2 ospf-neighbor
![HQ-R2 ospf-neighbor](images/dmvpn-hq-r2-ospf-neighbor.webp)

HQ-R2 ping 12.12.12.1
![HQ-R2 ping 12.12.12.1](images/dmvpn-hq-r2-shortcut-ping.webp)

HQ-R2 traceroute 12.12.12.1
![HQ-R2 traceroute 12.12.12.1](images/dmvpn-hq-r2-shortcut-traceroute.png)

HQ-R2 show dmvpn(shortcut 후)
![HQ-R2 show dmvpn(shortcut 후)](images/dmvpn-hq-r2-shortcut-dmvpn.webp)

HQ-R2 show ip nhrp(shortcut 후)
![HQ-R2 show ip nhrp(shortcut 후)](images/dmvpn-hq-r2-shortcut-nhrp.png)

HQ-R2 show crypto isakmp sa(shortcut 후)
![HQ-R2 show crypto isakmp sa(shortcut 후)](images/dmvpn-hq-r2-shortcut-isakmp.png)

HQ-R2 ping 13.13.13.2
![HQ-R2 ping 13.13.13.2](images/dmvpn-hq-r2-shortcut-br2-ping.webp)

HQ-R2 traceroute 13.13.13.2
![HQ-R2 traceroute 13.13.13.2](images/dmvpn-hq-r2-shortcut-br2-traceroute.png)

HQ-R2 show dmvpn(BR2 shortcut 후)
![HQ-R2 show dmvpn(BR2 shortcut 후)](images/dmvpn-hq-r2-shortcut-br2-dmvpn.webp)

HQ-R2 show ip nhrp(BR2 shortcut 후)
![HQ-R2 show ip nhrp(BR2 shortcut 후)](images/dmvpn-hq-r2-shortcut-br2-nhrp.png)

HQ-R2 show crypto isakmp sa(BR2 shortcut 후)
![HQ-R2 show crypto isakmp sa(BR2 shortcut 후)](images/dmvpn-hq-r2-shortcut-br2-isakmp.webp)
