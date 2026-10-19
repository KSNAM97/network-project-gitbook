# ISP 연결 검증 (DC / core)

- Jira: KAN-18
- 대상 장비: DC-R3(ISP-1), DC-R4(ISP-2)
- 기준 문서: [ospf-design.md](../../../docs/ospf-design.md) 6절, [bgp-design.md](../../../docs/bgp-design.md) 5~6절
- 검증일: 2026-10-17

| 장비                         | 명령                                                | 기대 결과                                                 | 실제 결과                                                                                                                                                   | 판정                          |
| -------------------------- | ------------------------------------------------- | ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------- |
| DC-R3(ISP-1), DC-R4(ISP-2) | `show ip bgp summary` | ISP PE와 Established(ISP AS 65100 또는 65200) | DC-R3는 100.1.21.2(AS 65100)와 Established, PfxRcd 1(기본 경로), router-id 10.10.10.3. DC-R4는 100.2.22.2(AS 65200)와 Established, PfxRcd 1, router-id 10.10.10.4 | 통과 |
| DC-R3(ISP-1), DC-R4(ISP-2) | `show ip route 0.0.0.0` | BGP 기본 경로 `B*`(PE 방향) | DC-R3는 `bgp 65002` distance 20 `candidate default path`, via 100.1.21.2(Tag 65100). DC-R4는 `bgp 65002` distance 20 `candidate default path`, via 100.2.22.2(Tag 65200) | 통과 |
| DC-R3(ISP-1), DC-R4(ISP-2) | `show ip bgp neighbors <PE 주소> advertised-routes` | 사이트 /16만 광고(`rm-isp-out`) | DC-R3는 `10.2.0.0/16`(로컬, Next Hop 0.0.0.0, Weight 32768) 한 개만 광고, Total number of prefixes 1. DC-R4는 `10.2.0.0/16`(로컬, Next Hop 0.0.0.0, Weight 32768) 한 개만 광고 | 통과 |
| DC-R3(ISP-1), DC-R4(ISP-2) | `show route-map`, `show ip prefix-list` | `rm-isp-in`, `rm-isp-out`, `pl-default`, `pl-site` 적용 | DC-R3는 `rm-isp-out`(match `pl-site`), `rm-isp-in`(match `pl-default`), `pl-site`(permit 10.2.0.0/16), `pl-default`(permit 0.0.0.0/0) 확인. DC-R4는 `rm-isp-out`(match `pl-site`), `rm-isp-in`(match `pl-default`)와 `pl-site`(permit 10.2.0.0/16), `pl-default`(permit 0.0.0.0/0) 확인 | 통과 |
| DC-R3(ISP-1), DC-R4(ISP-2) | `show ip ospf database external` | `default-information originate` 기본 경로 Type 1 광고 | DC-R3(광고 라우터 10.10.10.3, OSPF 프로세스 10)가 `0.0.0.0/0` Type 5 외부 LSA를 Metric Type 1, metric 100으로 광고(External Route Tag 10). DC-R4(metric 200)는 링크 34 구성 후. DC-R4(광고 라우터 10.10.10.4)가 `0.0.0.0/0` Type 1 metric 200으로 광고, DC-R3(10.10.10.3)의 metric 100과 함께 두 건 보임(External Route Tag 10) | 통과 |

장애 시 BGP 세션이 내려가 기본 경로가 철회되고 OSPF 기본 경로 광고가 ISP-2로 전환되는지는 [scenarios/](../../scenarios/)에서 확인.

DC-R3 BGP summary

![DC-R3 BGP summary](images/Pasted%20image%2020261017234216.png)

DC-R3 기본 경로(show ip route 0.0.0.0)

![DC-R3 기본 경로(show ip route 0.0.0.0)](images/Pasted%20image%2020261017234231.png)

DC-R3 advertised-routes

![DC-R3 advertised-routes](images/Pasted%20image%2020261017234244.png)

DC-R3 route-map

![DC-R3 route-map](images/Pasted%20image%2020261017234251.png)

DC-R3 OSPF database external

![DC-R3 OSPF database external](images/Pasted%20image%2020261017234301.png)

DC-R4 BGP summary

![DC-R4 BGP summary](images/Pasted%20image%2020261017234957.png)

DC-R4 기본 경로(show ip route 0.0.0.0)

![DC-R4 기본 경로(show ip route 0.0.0.0)](images/Pasted%20image%2020261017235010.png)

DC-R4 advertised-routes

![DC-R4 advertised-routes](images/Pasted%20image%2020261017235020.png)

DC-R4 route-map

![DC-R4 route-map](images/Pasted%20image%2020261017235031.png)

DC-R3 prefix-list

![DC-R3 prefix-list](images/isp-link-dc-r3-prefix-list.png)

DC-R4 prefix-list

![DC-R4 prefix-list](images/Pasted%20image%2020261017235043.png)

DC-R4 OSPF database external

![DC-R4 OSPF database external](images/Pasted%20image%2020261017235101.png)
