# QoS 검증 (DC / core)

- Jira: KAN-25
- 대상 장비: DC-R1~R4
- 기준 문서: [qos-design.md](../../../docs/qos-design.md), [cisco-router.md](../../../docs/config-guide/cisco-router.md) 3.7절
- 검증일: 2026-10-18

| 장비 | 명령 | 기대 결과 | 실제 결과 | 판정 |
|---|---|---|---|---|
| DC-R1~R4 | `show policy-map` | 정책 `pm-lan-out`, `pm-lan-out-child` 정의, 클래스 `cm-control`, `cm-business`, `class-default` | 4대 모두 `pm-lan-out`(class-default `shape average cir 10000000`, `service-policy pm-lan-out-child`)과 `pm-lan-out-child`(`cm-control` bandwidth 10%, `cm-business` bandwidth 30%와 `set dscp af31`, `class-default` fair-queue) 정의 | 통과 |
| DC-R1-R4 | `show policy-map interface gi0/0`, `gi1/0` | `pm-lan-out` 출력 방향 적용, 클래스 3개 표시 | 4대 모두 `gi0/0`, DC-R2-R4는 `gi1/0`도 클래스 3개(`cm-control`, `cm-business`, `class-default`) 카운터가 표시되어 `pm-lan-out` 적용 확인. DC-R1 `gi1/0`도 클래스 3개 카운터가 표시되어 적용 확인 | 통과 |
| 외부 사이트 호스트 | `nslookup dc-r1.lab.local 10.2.50.10` 20회 반복 후 DC-R2 `show policy-map interface gi0/0`, `gi1/0` | `cm-business` 매치 패킷 증가 | DC-R2 `gi0/0`(DC-SW1-L3 방향)에서 `cm-business` 80 packets, 6000 bytes(`Match: access-group name acl-qos-dns` 80 packets), `QoS Set dscp af31` Packets marked 80. 부모 `class-default` 141 packets = `cm-control` 30 + `cm-business` 80 + 자식 `class-default` 31, drop 0. 같은 시점 `gi1/0`(DC-SW2-L3 방향)의 `cm-business`는 0이라 질의는 `gi0/0`으로 들어감(경로: DMVPN, DC-R2 `gi0/0`). 이어서 BR2-PC1에서 같은 시험(20회)을 하자 `cm-business`가 120 packets, `Packets marked 120`으로 +40 증가 HQ-PC1 시험 후에는 160 packets, `Packets marked 160`(+40)으로 BR1(80), BR2(+40), HQ(+40)가 모두 DC-R2 `gi0/0`을 지남. DC-R1 `gi0/0`, DC-R3 `gi0/0`·`gi1/0`, DC-R4 `gi0/0`·`gi1/0`, DC-R2 `gi1/0`의 `cm-business`는 0 | DC-R2 통과 |
| DC-R2 `Gi0/0` ↔ DC-SW1-L3 `Et2` 링크(Wireshark) | BR1-PC1에서 `nslookup` 반복 중 캡처, 필터 `udp.port == 53 && ip.dsfield.dscp == 26` | `cm-business`로 분류된 DNS 패킷이 AF31(DSCP 26)로 표시되어 나감 | 필터에 `10.3.10.217`(BR1-PC1) → `10.2.50.10`의 DNS 질의(`A`, `AAAA`)가 연속으로 매치. Frame 15(75 bytes)의 IP 헤더가 `45 68 ...`으로 TOS `0x68`(DSCP 26, AF31) | 통과 |
| 호스트(BR1-PC1) | 큰 트래픽(`ping -s 1400`) 후 `show policy-map interface` | `class-default`에 drop 발생, `cm-business` 보장 | BR1-PC1에서 `ping -s 1400 -c 2000 -i 0.01 10.10.10.13`을 백그라운드로 보내고(DC-R2 `pm-lan-out`의 `shape average 1000000`으로 병목을 키움) 같은 시간에 `nslookup dc-r1.lab.local 10.2.50.10` 20회 반복. DC-R2 `gi0/0`: 자식 `class-default` drop 578에서 1333(+755), 5분 drop rate 18000 bps. `cm-business` 160에서 232 packets(+72, 재시도 포함 추정), drop 0/0/0, `Packets marked 232`, `cm-control` 296 packets drop 0/0/0. DNS 질의 20회 중 맨 앞 2번은 `connection timed out`(앞단 지연으로 보이며 DC-R2에서 drop은 없음) 이후 `10.10.10.1`로 정상 응답. 시험 후 `shape average 10000000`으로 복구, `shape (average) cir 10000000` 확인 | 통과 |
| DC-R1-R4 | `show policy-map interface gi2/0`(해당 시) | 정책 미적용(제외 대상) | DC-R1-R4 모두 `gi2/0`(DC-R1, R2는 Private-net 방향, DC-R3, R4는 DC-R3↔R4 링크)의 출력이 비어 있어 정책 미적용. DC-R2 `tunnel 0`도 출력이 비어 있어 정책 미적용 | 통과 |

DC-R1 show policy-map
![DC-R1 show policy-map](images/qos-dc-r1-policy-map.png)

DC-R1 show policy-map interface gi0/0
![DC-R1 show policy-map interface gi0/0](images/qos-dc-r1-interface-gi0-0.png)

DC-R2 show policy-map
![DC-R2 show policy-map](images/qos-dc-r2-policy-map.png)

DC-R2 show policy-map interface gi0/0
![DC-R2 show policy-map interface gi0/0](images/qos-dc-r2-interface-gi0-0.png)

DC-R3 show policy-map
![DC-R3 show policy-map](images/qos-dc-r3-policy-map.png)

DC-R3 show policy-map interface gi0/0
![DC-R3 show policy-map interface gi0/0](images/qos-dc-r3-interface-gi0-0.png)

DC-R4 show policy-map
![DC-R4 show policy-map](images/qos-dc-r4-policy-map.png)

DC-R4 show policy-map interface gi0/0
![DC-R4 show policy-map interface gi0/0](images/qos-dc-r4-interface-gi0-0.png)

DC-R2 show policy-map interface gi0/0 (DNS 질의 후)
![DC-R2 show policy-map interface gi0/0](images/qos-dc-r2-gi0-0-dns.png)

DC-R2 show policy-map interface gi1/0 (DNS 질의 후)
![DC-R2 show policy-map interface gi1/0](images/qos-dc-r2-gi1-0.png)

DC-R2 show policy-map interface gi0/0 (BR2 시험 후, cm-business 120)
![DC-R2 show policy-map interface gi0/0 (BR2 시험 후)](images/qos-dc-r2-gi0-0-dns-after-br2.png)

DC-R2 gi0/0 (HQ 시험 후, cm-business 160)
![DC-R2 gi0/0 (HQ 시험 후, cm-business 160)](images/qos-dc-r2-gi0-0-after-hq.png)

DC-R2 gi1/0 (cm-business 0)
![DC-R2 gi1/0 (cm-business 0)](images/qos-dc-r2-gi1-0-after-hq.png)

DC-R1 gi0/0 (cm-business 0)
![DC-R1 gi0/0 (cm-business 0)](images/qos-dc-r1-gi0-0.webp)

DC-R3 gi0/0 (cm-business 0)
![DC-R3 gi0/0 (cm-business 0)](images/qos-dc-r3-gi0-0.webp)

DC-R3 gi1/0 (cm-business 0)
![DC-R3 gi1/0 (cm-business 0)](images/qos-dc-r3-gi1-0.webp)

DC-R4 gi0/0 (cm-business 0)
![DC-R4 gi0/0 (cm-business 0)](images/qos-dc-r4-gi0-0.webp)

DC-R4 gi1/0 (cm-business 0)
![DC-R4 gi1/0 (cm-business 0)](images/qos-dc-r4-gi1-0.webp)

DC-R1 show policy-map interface gi2/0 (정책 미적용)
![DC-R1 show policy-map interface gi2/0 (정책 미적용)](images/qos-dc-r1-gi2-0-excluded.png)

DC-R2 show policy-map interface gi2/0 (정책 미적용)
![DC-R2 show policy-map interface gi2/0 (정책 미적용)](images/qos-dc-r2-gi2-0-excluded.png)

DC-R3 show policy-map interface gi2/0 (정책 미적용)
![DC-R3 show policy-map interface gi2/0 (정책 미적용)](images/qos-dc-r3-gi2-0-excluded.png)

DC-R4 show policy-map interface gi2/0 (정책 미적용)
![DC-R4 show policy-map interface gi2/0 (정책 미적용)](images/qos-dc-r4-gi2-0-excluded.png)

DC-R2 gi0/0 병목 시험 중(class-default drop 578)
![DC-R2 gi0/0 병목 시험 중(class-default drop 578)](images/qos-bottleneck-dc-r2-drop.webp)

BR1-PC1 큰 트래픽 중 nslookup
![BR1-PC1 큰 트래픽 중 nslookup](images/qos-bottleneck-br1-pc1-dns.webp)

DC-R2 gi0/0 병목 시험 후(class-default drop 1333, cm-business drop 0)
![DC-R2 gi0/0 병목 시험 후(class-default drop 1333, cm-business drop 0)](images/qos-bottleneck-dc-r2-after.png)

DC-R2 shape 복구 확인
![DC-R2 shape 복구 확인](images/qos-dc-r2-shape-restored.png)

Wireshark: DC-R2 Gi0/0 → DC-SW1-L3 Et2 링크의 DNS 패킷(DSCP AF31)
![Wireshark DNS 패킷 DSCP AF31](images/qos-wireshark-dscp-af31.webp)

DC-R2 show policy-map interface tunnel 0 (정책 미적용)
![DC-R2 show policy-map interface tunnel 0](images/qos-dc-r2-tunnel0-excluded.png)

DC-R1 show policy-map interface gi1/0
![DC-R1 show policy-map interface gi1/0](images/qos-dc-r1-gi1-0.webp)
