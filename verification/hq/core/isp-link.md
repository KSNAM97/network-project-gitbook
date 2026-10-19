# ISP 연결 검증 (HQ / core)

- Jira: KAN-18
- 대상 장비: HQ-R1(ISP-1, metric 100), HQ-R2(ISP-2, metric 200)
- 기준 문서: [ospf-design.md](../../../docs/ospf-design.md) 6절, [bgp-design.md](../../../docs/bgp-design.md) 5~6절
- 검증일: 2026-10-17

| 장비                                                 | 명령                                                | 기대 결과                                                 | 실제 결과                                                                                                                                     | 판정  |
| -------------------------------------------------- | ------------------------------------------------- | ----------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | --- |
| HQ-R1(ISP-1, metric 100), HQ-R2(ISP-2, metric 200) | `show ip bgp summary`                             | ISP PE와 Established(ISP AS 65100 또는 65200)            | HQ-R1은 100.1.11.2(AS 65100), HQ-R2는 100.2.12.2(AS 65200)와 Established, PfxRcd 1(기본 경로). HQ-R1 Up/Down 00:08:20, HQ-R2 00:01:51            | 통과  |
| HQ-R1(ISP-1, metric 100), HQ-R2(ISP-2, metric 200) | `show ip route 0.0.0.0`                           | BGP 기본 경로 `B*`(PE 방향)                                 | 두 라우터 모두 `bgp 65001` distance 20 `candidate default path`. HQ-R1은 via 100.1.11.2(Tag 65100), HQ-R2는 via 100.2.12.2(Tag 65200)             | 통과  |
| HQ-R1(ISP-1, metric 100), HQ-R2(ISP-2, metric 200) | `show ip bgp neighbors <PE 주소> advertised-routes` | 사이트 /16만 광고(`rm-isp-out`)                             | 두 라우터 모두 `10.1.0.0/16`(로컬, Next Hop 0.0.0.0, Weight 32768) 한 개만 광고, Total number of prefixes 1                                            | 통과  |
| HQ-R1(ISP-1, metric 100), HQ-R2(ISP-2, metric 200) | `show route-map`, `show ip prefix-list`           | `rm-isp-in`, `rm-isp-out`, `pl-default`, `pl-site` 적용 | 두 라우터 모두 `rm-isp-out`(match `pl-site`), `rm-isp-in`(match `pl-default`) 정의, `pl-site`는 permit 10.1.0.0/16, `pl-default`는 permit 0.0.0.0/0 | 통과  |
| HQ-R1(ISP-1, metric 100), HQ-R2(ISP-2, metric 200) | `show ip ospf database external`                  | `default-information originate` 기본 경로 Type 1 광고       | `0.0.0.0/0` Type 5 외부 LSA 2건, Metric Type 1: 광고 라우터 11.11.11.1(HQ-R1) metric 100, 11.11.11.2(HQ-R2) metric 200, External Route Tag 11     | 통과  |

장애 시 BGP 세션이 내려가 기본 경로가 철회되고 OSPF 기본 경로 광고가 ISP-2로 전환되는지는 [scenarios/](../../scenarios/)에서 확인.

HQ-R1 BGP summary
![HQ-R1 BGP summary](images/Pasted%20image%2020261017232622.png)

HQ-R1 기본 경로(show ip route 0.0.0.0)
![HQ-R1 기본 경로(show ip route 0.0.0.0)](images/Pasted%20image%2020261017232640.png)

HQ-R1 advertised-routes
![HQ-R1 advertised-routes](images/Pasted%20image%2020261017232820.png)

HQ-R1 route-map
![HQ-R1 route-map](images/Pasted%20image%2020261017232904.png)

HQ-R1 prefix-list
![HQ-R1 prefix-list](images/Pasted%20image%2020261017232912.png)

HQ-R1 OSPF database external
![HQ-R1 OSPF database external](images/Pasted%20image%2020261017232944.png)

HQ-R2 BGP summary
![HQ-R2 BGP summary](images/Pasted%20image%2020261017233004.png)

HQ-R2 기본 경로(show ip route 0.0.0.0)
![HQ-R2 기본 경로(show ip route 0.0.0.0)](images/Pasted%20image%2020261017233011.png)

HQ-R2 advertised-routes
![HQ-R2 advertised-routes](images/Pasted%20image%2020261017233045.png)

HQ-R2 route-map
![HQ-R2 route-map](images/Pasted%20image%2020261017233114.png)

HQ-R2 prefix-list
![HQ-R2 prefix-list](images/Pasted%20image%2020261017233121.png)

HQ-R2 OSPF database external
![HQ-R2 OSPF database external](images/Pasted%20image%2020261017233141.png)
