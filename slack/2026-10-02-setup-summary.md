📢 [프로젝트] 사전작업 완료 공유 — GitHub / Jira / Slack 세팅

■ 한 줄 요약
프로젝트를 시작할 수 있도록 저장소, 티켓, 채널을 모두 준비했습니다. 각자 아래 "할 일"만 하면 바로 작업 가능합니다.

■ 1. GitHub
- 저장소: KSNAM97/network-project
- README.md: 구조, 단계, 설계 요약 / docs/: 전체 설계와 일정
- 컨피그 저장: configs/<사이트>/<장비명>.cfg
- 브랜치: feature/<역할>-<내용>, PR 후 본인 검토를 거쳐 main에 merge
- 설계 반영: DC 서버 VLAN(50)은 DC-DNS-1(주)과 DC-DNS-2(백업) 두 대로 구성 (DHCP는 사이트 게이트웨이에서 제공, IP·DNS 소프트웨어는 미확정)

■ 2. Jira
- 프로젝트 키: KAN, 이슈 29개 등록 (KAN-4 ~ KAN-32)
- 제목 앞 [1주]~[3.5주]는 주차, 라벨 net-cloud / policy는 담당 역할입니다.
- 보드 컬럼: 해야 할 일 → 진행 중 → 완료 (시작할 때 진행 중, 끝나면 완료로 옮겨 주세요)
- 번호가 KAN-4부터 시작하는 것은 Jira 특성이며 작업에는 영향이 없습니다.

■ 3. 커밋 규칙
- 형식: KAN-번호: [역할][VLAN태그] 내용
- 예: KAN-14: [Network][vlan-dc-server] DC-DNS-1 ACL 추가
- 맨 앞에 이슈 키를 쓰면 Jira 이슈에 자동 연결됩니다.
- 변경 전에는 장비에서 copy running-config flash:<장비명>-backup-<날짜>.cfg 로 백업해 주세요.

■ 4. Slack
- 채널: #announcements(공지), #team-net-cloud, #team-policy, #dev-issues(장애·이슈 공유)
- Jira 알림: 팀 채널에는 자기 팀 라벨의 이슈만 알림이 옵니다. (생성, 진행 중, 완료로 상태가 바뀔 때)
- #dev-issues는 Jira 알림을 연결하지 않았습니다.

■ 5. 참고: 정리해 둔 것
- DMVPN 참고용 저장소(cisco-dmvpn-ipsec-network)의 컨피그 오류를 수정했습니다.
- 위 문서들은 원본 저장소에 push하면 포트폴리오 사이트에 자동 반영됩니다.

■ 각자 할 일
1. Slack에서 채널 탐색으로 #announcements와 본인 팀 채널에 참여
2. GitHub 초대 수락, Jira 프로젝트 접근 확인
3. 담당 이슈 확인 후 보드에서 상태 변경
4. 모르는 점은 #dev-issues에 남겨 주세요.
