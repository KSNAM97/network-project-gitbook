# QoS 동작 검증 시나리오

- Jira: KAN-25
- 대상 장비: DC-R1~R4(스위치 방향 `Gi0/0`, `Gi1/0`), 시험 호스트 BR1-PC1(또는 HQ-PC1), DC-DNS-1
- 기준 문서: [qos-design.md](../../docs/qos-design.md), [cisco-router.md](../../docs/config-guide/cisco-router.md) 3.7절
- 검증일: 2026-10-18

정책 정의와 `Gi0/0` 적용은 사이트별 `*/core/qos.md`에서 확인함. 이 시나리오는 실제 트래픽으로 클래스 분류와 대역 보장이 동작하는지 확인.

## 1. 시험 경로

- 외부 사이트 호스트에서 DC로 들어오는 트래픽은 DC 라우터(DMVPN이면 `DC-R2`, ISP 경유면 `DC-R3`, `DC-R4`)의 `Gi0/0` 또는 `Gi1/0` 출력으로 스위치 방향에 나감. 이 인터페이스가 정책(10Mbps shaping)이 걸린 지점.
- DNS 서버(`10.2.50.10`, `10.2.50.11`)에는 DC 라우터의 DNS ACL(`dns-only`)이 DNS 외 트래픽을 차단하므로, 대량 트래픽은 서버 VLAN이 아니라 `DC-SW3-L3` Loopback0(`10.10.10.13`)으로 보냄.
- 어느 라우터와 인터페이스를 지나는지는 각 단계 후 DC-R1~R4의 `show policy-map interface gi0/0`, `gi1/0`으로 확인(카운트가 오른 곳이 경로).

## 2. 시나리오

| 순서 | 동작 | 기대 결과 | 측정값 | 판정 |
|---|---|---|---|---|
| 1 | 시험 전 기준값 캡처: 확인할 라우터에서 `show policy-map interface gi0/0`, `gi1/0`(이 IOS는 `clear policy-map interface`를 지원하지 않고 `clear counters`로는 정책 카운터가 비워졌는지 불확실하므로 전후 비교로 판단) | `cm-business` 0, `cm-control`은 제어 트래픽 소량 | 모든 사이트 라우터와 DC-R1~R4에서 시험 전후 값을 비교(이 IOS는 `clear policy-map interface` 미지원). 시험 전 `cm-business` 0, `cm-control`은 제어 트래픽 소량 | 통과 |
| 2 | 호스트에서 `nslookup dc-r1.lab.local 10.2.50.10`을 반복(예: 20회) | 응답 정상(`10.10.10.1`), 경로상 DC 라우터의 `cm-business` 매치 패킷과 `Packets marked`(af31) 증가 | BR1-PC1, BR2-PC1, HQ-PC1 각각 `nslookup` 20회(모두 `10.10.10.1` 응답). BR1-R1 `gi1/0` 68→80 packets, BR2-R2 `gi0/0` 40 packets, HQ-R2 `gi1/0` 40 packets(각각 `Packets marked` 동일, af31). DC-R2 `gi0/0`은 80→120→160(+40씩)으로 세 사이트 질의가 모두 지남 | 통과 |
| 3 | 호스트에서 대량 트래픽 `ping -s 1400 -c 2000 -i 0.01 10.10.10.13` | 응답 정상, 경로상 라우터의 `class-default` 패킷 증가 | BR1-PC1에서 `ping -s 1400 -c 2000 -i 0.01 10.10.10.13`(백그라운드) 후 DC-R2 `gi0/0`의 자식 `class-default` 패킷과 drop 증가 확인(drop 0에서 578) | 통과 |
| 4 | 대량 트래픽과 DNS 질의를 동시에 실행(두 호스트 또는 두 세션) | DNS 질의는 계속 성공(손실 0), `class-default`에 drop 발생, `cm-business`에는 drop 없음 | 큰 트래픽과 `nslookup` 20회 동시. DC-R2 `gi0/0`: `class-default` drop 578→1333(+755), `cm-business` 160→232 packets drop 0/0/0, `cm-control` 296 packets drop 0/0/0. DNS 질의 20회 중 맨 앞 2번은 `connection timed out`(앞단 지연으로 보이며 DC-R2에서 drop 없음), 이후 정상 응답 | 통과 |
| 5 | 정책에 영향을 주기 위해 병목을 키움: 경로상 라우터에서 `policy-map pm-lan-out` / `class class-default` / `shape average 1000000`으로 낮추고 3~4 반복 | 병목이 작을수록 `class-default` drop이 뚜렷하고 DNS는 보장 대역(30%) 안에서 유지 | DC-R2 `pm-lan-out`의 `shape average 1000000`으로 병목을 키워 3~4를 수행(offered 74000 bps, drop 18000 bps) | 통과 |
| 6 | `shape average 10000000`으로 복구, `show policy-map interface gi0/0`, `gi1/0` | 정책이 원래 값으로 복구, 양쪽 포트 모두 정책 적용 | `shape average 10000000`으로 복구, DC-R2 `show policy-map interface gi0/0 \| include shape`에서 `shape (average) cir 10000000, bc 40000, be 40000` 확인. 사이트 라우터의 `gi0/0`, `gi1/0` 적용은 각 사이트 문서에서 확인 | 통과 |
| 7 | `show policy-map interface gi2/0`, `tunnel 0` | 제외 포트는 정책 미적용 | BR1-R1, BR1-R2, BR2-R1, BR2-R2, HQ-R1, HQ-R2, DC-R1~R4의 `show policy-map interface gi2/0` 출력이 비어 있어 정책 미적용. DC-R2 `tunnel 0`도 출력이 비어 있어 정책 미적용 | 통과 |

## 3. 측정 방법

- DNS 성공률: `for i in $(seq 1 20); do nslookup dc-r1.lab.local 10.2.50.10 | grep -c Address; done` 또는 호스트의 `nslookup` 반복 결과를 캡처.
- 대량 트래픽 중 DNS 응답 시간은 `time nslookup dc-r1.lab.local 10.2.50.10`으로 확인(정책이 없을 때와 비교하면 효과가 보임).
- 클래스별 변화는 같은 시점의 `show policy-map interface gi0/0`, `gi1/0` 전후를 비교. 응답이 나가는 포트는 호스트가 붙은 스위치에 따라 `gi0/0` 또는 `gi1/0`이므로 두 포트를 모두 확인(BR1-PC1은 BR1-R1의 `gi1/0`).

## 4. 제약과 주의

- 가상 라우터(Cisco 7200)와 호스트 CPU 때문에 호스트가 10Mbps 이상을 만들지 못할 수 있음. 이 경우 5단계처럼 `shape` 값을 낮춰 병목을 만들고, 시험 후 반드시 `shape average 10000000`으로 복구.
- 정책은 출력 방향이라 외부에서 DC로 들어오는 방향(스위치 방향 출력)만 확인됨. 반대 방향은 사이트 라우터의 `Gi0/0`, `Gi1/0`(각 사이트 문서) 출력에서 확인.
- 시험 중에는 ISP 장비 등 시험과 무관한 장비를 끄면 호스트 부하를 줄일 수 있음.

- 사이트별 상세 결과와 캡처는 `*/core/qos.md`(`dc/core/qos.md`에 병목 시험)를 참조.
