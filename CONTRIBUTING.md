# 기여 가이드

## 브랜치 전략

```
main                  ← 항상 동작 검증된 상태만
feature/network-*
feature/cloud-*
feature/policy-*
```

작업은 각자의 `feature/<역할>-<내용>` 브랜치에서 진행하고, PR을 올려
본인 검토 후 `main`에 merge.

## 브랜치 보호 설정 (레포 관리자가 1회 설정)

```
Settings → Branches → Add rule → main
- Require pull request before merging
- Require approvals (1명 이상)
```

## 커밋 메시지 규칙

```
<Jira키>: [역할][VLAN태그] 내용
```

예시:
```
KAN-14: [Network][vlan-dc-server] DC-DNS-1 ACL 추가
KAN-21: [Cloud][vlan-hq-public] HQ VRRP 설정
KAN-33: [Policy][vlan-br1-public] DMVPN Spoke 구성
```

### VLAN 태그

| VLAN | 태그 |
|---|---|
| 10 (HQ-PUBLIC) | `vlan-hq-public` |
| 20 (HQ-PRIVATE) | `vlan-hq-private` |
| 50 (DC-SERVER) | `vlan-dc-server` |
| 10 (BR1-PUBLIC) | `vlan-br1-public` |
| 20 (BR1-PRIVATE) | `vlan-br1-private` |
| 10 (BR2-PUBLIC) | `vlan-br2-public` |
| 20 (BR2-PRIVATE) | `vlan-br2-private` |
| 100 (MGMT) | `vlan-mgmt` |
| 999 (NATIVE) | `vlan-native` |

### 역할 라벨

1인 체제: 담당자 1명, 라벨 `Net-Cloud` / `Policy`는 작업 영역 구분용.

## Jira 연동

1. Jira 프로젝트 → Apps → **GitHub for Jira** 설치 후 본 레포 연결 (1회 설정)
2. 커밋 메시지 맨 앞에 Jira 이슈 키(`KAN-1` 등)를 정확히 포함해야 자동 연결.
3. CSV Import 후 실제 발급된 이슈 번호를 Jira Board에서 직접 확인하고 공유. Import 순서와 실제 번호가 어긋날 수 있음.
4. PR 제목에도 같은 이슈 키를 포함하면 PR-이슈 연결.

## 컨피그 커밋 규칙

- 변경 전 장비에서 `copy running-config flash:<장비명>-backup-<날짜>.cfg`로 백업 후 진행.
- 위험도 "상" 작업(Trunk/Native VLAN 변경, 라우팅 프로세스 제거, 터널 재구성 등)은
  PR 설명에 영향 범위와 롤백 명령을 함께 기재.
- 컨피그 파일은 `configs/<사이트>/<계층>/<장비명>.<ios|eos>` 형식으로 저장.
