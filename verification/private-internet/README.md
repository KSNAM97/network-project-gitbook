# Private Internet 검증 개요

GNS3 토폴로지(검증 대상 장비와 포트). 상세 결과는 아래 문서 링크에서 확인.

![Private Internet 토폴로지](images/topology-private-internet.png)

## 핵심 결과

- DMVPN 언더레이: Hub 장애에도 PI 구간과 이웃(`2.2.2.2`) 유지 → [dmvpn-hub-failure](../scenarios/dmvpn-hub-failure.md)
- PI ACL(pi-whitelist), OSPF → [acl](core/acl.md), [ospf](core/ospf.md)

## 계층별 검증 문서

| 계층 | 항목 | Jira | 문서 |
|---|---|---|---|
| core | Private Internet ACL 검증 | KAN-19 | [core/acl.md](core/acl.md) |
| core | Private Internet OSPF 검증 | KAN-20 | [core/ospf.md](core/ospf.md) |

상세 서식과 상태는 [검증 README](../README.md) 참조.
