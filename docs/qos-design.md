# QoS 설계

사이트 라우터에서 스위치 방향 인터페이스의 출력 트래픽을 클래스별로 나누고 대역을 보장하는 QoS 정책을 정리한 문서. 인터페이스와 링크는 `docs/ip-mapping.md`, `docs/port-mapping.md` 기준이며 명령 예시는 `docs/config-guide/cisco-router.md` 3.7절. 적용 전 설계이며(Jira KAN-25), 장비 확인 결과에 따라 값을 갱신.

## 1. 적용 범위

- 대상: 사이트 라우터 10대의 스위치 방향 인터페이스 `Gi0/0`, `Gi1/0` 20포트, 출력(`service-policy output`) 방향.
- 제외: 라우터 간 링크(`Gi2/0`), ISP 방향(`Gi3/0`), PI 방향(`Gi4/0`, DC-R1·R2는 `Gi2/0`), `Tunnel0`. 스위치 QoS는 적용하지 않음.
- 같은 인터페이스에 DC 라우터의 DNS ACL(`ip access-group dns-only out`, `docs/dhcp-dns-design.md` 5절)이 있어도 정책과 ACL은 함께 사용할 수 있음.

| 사이트 | 장비 | `Gi0/0`(링크 #, 상대) | `Gi1/0`(링크 #, 상대) |
|---|---|---|---|
| HQ | HQ-R1 | 1, HQ-SW-2 | 3, HQ-SW-3 |
| HQ | HQ-R2 | 2, HQ-SW-2 | 4, HQ-SW-3 |
| DC | DC-R1 | 17, DC-SW1-L3 | 18, DC-SW2-L3 |
| DC | DC-R2 | 19, DC-SW1-L3 | 20, DC-SW2-L3 |
| DC | DC-R3 | 26, DC-SW3-L3 | 28, DC-SW4-L3 |
| DC | DC-R4 | 27, DC-SW3-L3 | 29, DC-SW4-L3 |
| BR1 | BR1-R1 | 43, BR1-SW1-L3 | 45, BR1-SW2-L3 |
| BR1 | BR1-R2 | 44, BR1-SW1-L3 | 46, BR1-SW2-L3 |
| BR2 | BR2-R1 | 57, BR2-SW1-L3 | 59, BR2-SW2-L3 |
| BR2 | BR2-R2 | 58, BR2-SW1-L3 | 60, BR2-SW2-L3 |

## 2. 클래스와 대역

| 클래스 | 분류 | 보장 대역 | 비고 |
|---|---|---|---|
| `cm-control` | `match dscp cs6` | 10% | 제어 트래픽 |
| `cm-business` | `match access-group name acl-qos-dns`(UDP/TCP 53, 출발지 또는 목적지 포트) | 30% | 분류된 패킷에 `set dscp af31` 표시 |
| `class-default` | 나머지 | 남은 대역, `fair-queue` | - |

- DNS는 DSCP가 아니라 ACL로 직접 분류. 출력 인터페이스에서 DNS 패킷에 DSCP를 미리 표시하는 지점이 없어서 DSCP 매치로는 분류되지 않음.
- ACL `acl-qos-dns`는 DNS 질의(목적지 포트 53)와 응답(출발지 포트 53)을 모두 포함.

## 3. 정책 구조

- 부모 정책 `pm-lan-out`: `class-default`에 `shape average 10000000`(10Mbps)을 두고 자식 정책 `pm-lan-out-child`를 연결.
- 자식 정책 `pm-lan-out-child`: 위 클래스별 대역(`bandwidth percent`)과 `fair-queue`.
- 부모의 `shape average` 값은 병목을 만들어 클래스별 대역 보장을 확인하기 위한 검증용 값. 실제 포트는 1Gbps라 병목이 없으면 정책이 동작하는 것을 확인하기 어려움. 실측하면서 조정.

## 4. 검증 항목

| 항목 | 명령 | 기대 결과 |
|---|---|---|
| 정책 정의 | `show policy-map` | `pm-lan-out`, `pm-lan-out-child` 정의 |
| 적용 | `show policy-map interface gi0/0`, `gi1/0` | `pm-lan-out` 출력 방향, class `cm-control`, `cm-business`, `class-default` |
| DNS 분류 | 호스트에서 `nslookup` 후 `show policy-map interface` | `cm-business` 매치 패킷 증가 |
| 병목 | 큰 트래픽(예: `ping -s 1400`) 후 `show policy-map interface` | `class-default`에 drop이 생기고 `cm-business`는 보장 |
| 제외 | `show policy-map interface gi2/0`, `tunnel 0` | 정책 미적용 |

## 5. 제약

- 가상 라우터(Cisco 7200)의 처리 성능이 낮아 실제 대역 보장 정밀도는 보장하기 어려움. 클래스별 카운트와 drop 발생 여부로 확인.
- 한 인터페이스에 출력 정책은 하나만 적용 가능.
