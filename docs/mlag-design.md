# MLAG 설계 (DC)

DC 게이트웨이 스위치 한 쌍을 MLAG로 묶어 L2 스위치 업링크를 하나의 포트채널로 쓰는 구성을 정리한 문서. 2026-10-18 DC에 적용하고 검증 완료(Jira KAN-37, `verification/dc/distribution/mlag.md`). VLAN, 트렁크, 포트는 `docs/vlan-design.md`, `docs/port-mapping.md` 기준.

## 1. 구성 개요

- 대상: `DC-SW3-L3`, `DC-SW4-L3`(Arista vEOS-lab)가 MLAG 피어, `DC-SW1-L2`, `DC-SW2-L2`가 MLAG 포트채널의 반대편.
- 목적: L2 스위치가 SW3, SW4로 올리는 업링크 2개(현재 트렁크 각 1개, MSTP가 한쪽을 차단)를 하나의 LACP 포트채널로 묶어 두 링크를 모두 사용하고, 링크나 스위치 한 대 장애 시에도 끊김 없이 전환.
- VRRP(그룹 50)와 MSTP(루트 `DC-SW3-L3`)는 그대로 유지(`docs/vrrp-mstp-design.md`). MLAG는 L2 이중화만 바꾸고 게이트웨이 구조는 바꾸지 않음.
- VXLAN은 적용하지 않음.
- 범위: DC 한 사이트. 다른 사이트 구성에는 영향 없음.

## 2. 피어 구성

| 항목 | 값 |
|---|---|
| MLAG 도메인 | `dc-mlag` |
| 피어 링크 | 기존 `Po1`(`DC-SW3-L3` Et5, Et6 ↔ `DC-SW4-L3` Et5, Et6) 재사용 |
| 피어 VLAN | VLAN 4094(`trunk group MLAGPEER`, STP 제외) |
| 피어 SVI | `vlan4094` `10.2.254.0/30`(`DC-SW3-L3` `.1`, `DC-SW4-L3` `.2`), `no autostate` |
| 피어 링크 허용 VLAN | 50, 100, 4094 |

- `Po1`은 이미 두 스위치 사이에서 VLAN 50, 100 트렁크로 사용 중. peer-link 역할을 겸하므로 VLAN 4094와 `trunk group MLAGPEER`만 추가.
- 피어 주소 대역 `10.2.254.0/30`은 `docs/ip-mapping.md`의 다른 서브넷과 겹치지 않음.

## 3. MLAG 포트채널

- 포트채널 번호와 MLAG ID는 같은 값을 사용. 멤버 포트는 LACP(`channel-group <번호> mode active`).
- 허용 VLAN은 50, 100, native 999(기존 트렁크와 동일).

| MLAG ID | L2 스위치 | L2 쪽 멤버 | `DC-SW3-L3` 멤버 | `DC-SW4-L3` 멤버 | 링크 # |
|---|---|---|---|---|---|
| 10 | DC-SW1-L2 | Et1, Et2 | Et7 | Et7 | 37, 39 |
| 20 | DC-SW2-L2 | Et1, Et2 | Et8 | Et8 | 38, 40 |

- L2 쪽 `Po10`(`DC-SW1-L2`), `Po20`(`DC-SW2-L2`)은 로컬 번호이며 SW3, SW4 쪽 MLAG ID와 짝만 맞으면 됨.

## 4. 적용 순서

1. SW3, SW4에 VLAN 4094, `Po1` 변경, `mlag configuration`을 입력하고 `show mlag`로 피어 활성 확인(vEOS-lab 지원 여부 확인 단계).
2. `DC-SW1-L2` 한 대씩: SW3, SW4의 해당 포트를 MLAG 포트채널로 바꾸고 L2 스위치의 Et1, Et2를 포트채널로 묶음. 완료 후 `DC-SW2-L2`.
3. 각 단계마다 `write memory`.

- 되돌릴 지점: `git tag before-dc-mlag`.
- 같은 L2 스위치의 두 업링크를 한꺼번에 바꾸지 않으면 루프나 단절이 생길 수 있으므로 위 순서를 지킴.

## 5. 검증 항목

| 항목 | 명령 | 기대 결과 |
|---|---|---|
| 피어 상태 | `show mlag` | State Active, Negotiation Connected, peer-link Up(`Po1`) |
| 설정 일치 | `show mlag detail` | Config sanity consistent |
| 포트채널 | `show port-channel dense` | `Po10`, `Po20`이 SW3, SW4, L2 모두 Up |
| LACP | `show lacp peer` | 멤버 포트가 파트너와 정상 협상 |
| 서비스 | DC DNS 서버(`10.2.50.10`)에서 게이트웨이 `10.2.50.1` 응답 | 유지 |
| 장애(실측) | SW3 멤버 포트 또는 SW3 전체 다운 | `Po10`, `Po20`으로 트래픽 유지, 복구 후 재전환 |

## 6. 제약과 확인 필요 사항

- vEOS-lab는 일부 기능을 지원하지 않음(인터페이스 ACL `ip access-group`이 `Unavailable command`로 거부된 선례가 있음, `docs/dhcp-dns-design.md` 5절). MLAG 지원 여부는 구성 첫 단계의 `show mlag`로 확인하고, 미지원이면 이 문서에 한계로 기록.
- VRRP는 MLAG 구조에서 active/active 라우팅이 가능하나, 이 구성에서는 단순성을 위해 기존 Master/Backup 구조를 유지.

## 7. 적용 후 갱신한 문서

| 문서 | 내용 |
|---|---|
| `docs/port-mapping.md` | 링크 37 ~ 40을 MLAG 포트채널 멤버로 표시, 피어 링크(35, 36) 설명 |
| `docs/vlan-design.md` | 4절 EtherChannel 표에 `Po10`, `Po20`(MLAG)과 5절 트렁크 표 변경 |
| `docs/vrrp-mstp-design.md` | MLAG 적용 후 STP 차단 링크 변화 |
| `docs/config-guide/arista-switch.md` | MLAG 구성 예시 |
| `docs/ip-mapping.md` | `vlan4094` 주소 |
| 검증 | `verification/dc/distribution/mlag.md` |
