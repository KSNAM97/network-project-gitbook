# DHCP·DNS 설계

호스트 주소 할당(DHCP)과 이름 해석(DNS) 구성 및 설정 가이드. 서버 주소와 VLAN은 `docs/ip-mapping.md`, `docs/vlan-design.md` 기준.

## 1. 구성 개요

- DNS: DC 서버 VLAN 50의 GNS3 `DNS` 템플릿(Debian 계열, `dnsmasq` 사전 설치) 노드 2대(`DC-DNS-1` 주, `DC-DNS-2` 백업)가 `dnsmasq`로 DNS만 제공(DHCP 기능 비활성).
- DHCP: 사용자 VLAN의 게이트웨이 스위치 두 대(Cisco IOS DHCP 서버)가 풀을 나눠 제공. 서버 VLAN은 고정 주소.
- 호스트(`HQ-PC*`, `BR*-PC*`, 알파인 docker)는 DHCP로 주소, 기본 게이트웨이(VRRP VIP), DNS 서버 두 대를 수신.

## 2. DNS 서버

| 장비 | 역할 | IP | 게이트웨이 | 스위치 포트 | 소프트웨어 |
|---|---|---|---|---|---|
| DC-DNS-1 | 주 DNS | 10.2.50.10/24 | 10.2.50.1 | DC-SW1-L2 Et12 | dnsmasq |
| DC-DNS-2 | 백업 DNS | 10.2.50.11/24 | 10.2.50.1 | DC-SW2-L2 Et12 | dnsmasq |

- 도메인은 `lab.local`. 두 서버는 같은 레코드 파일을 사용하며, 클라이언트는 주 서버를 먼저 조회하고 응답이 없으면 백업 서버를 조회.
- 외부 DNS 연결이 없으므로 상위 서버 미사용(`no-resolv`).
- 레코드는 장비 Router ID(Loopback0) 기준의 A 레코드. 이름은 장비 이름을 소문자로 표기(예: `dc-r1.lab.local`).

### 2.1 서버 설정 파일

`/etc/network/interfaces`(`DC-DNS-2`는 주소 `10.2.50.11`):

```
auto eth0
iface eth0 inet static
    address 10.2.50.10
    netmask 255.255.255.0
    gateway 10.2.50.1
```

`/etc/dnsmasq.conf`(`DC-DNS-2`는 `listen-address=10.2.50.11`):

```
port=53
listen-address=10.2.50.10
bind-interfaces
no-resolv
no-hosts
domain=lab.local
local=/lab.local/
expand-hosts
addn-hosts=/etc/hosts.lab
log-queries
log-facility=/var/log/dnsmasq.log
```

- `/etc/hosts.lab` 형식은 `<IP> <이름>` 한 줄씩(아래 2.2절 표 기준). `log-queries`는 조회 확인용이며 `log-facility`로 질의 기록을 `/var/log/dnsmasq.log`에 저장(이미지에 syslog 데몬이 없어 파일로 직접 기록, 확인은 `tail /var/log/dnsmasq.log`).
- `dnsmasq`는 GNS3 `DNS` 템플릿 이미지에 설치되어 있고 부팅 시 자동 시작. `dnsmasq.conf`와 `hosts.lab` 반영은 `service dnsmasq restart`. 확인은 `service dnsmasq status`, `ss -lun | grep :53`, `nslookup`.

### 2.2 DNS 레코드

- 총 31개. Router ID는 `docs/ospf-design.md` 2절(사이트 장비, `Private-net`)과 `docs/bgp-design.md` 2절(ISP 장비) 기준.

| 이름                    | IP            |
| --------------------- | ------------- |
| hq-r1.lab.local       | 11.11.11.1    |
| hq-r2.lab.local       | 11.11.11.2    |
| hq-sw-2.lab.local     | 11.11.11.12   |
| hq-sw-3.lab.local     | 11.11.11.13   |
| dc-r1.lab.local       | 10.10.10.1    |
| dc-r2.lab.local       | 10.10.10.2    |
| dc-r3.lab.local       | 10.10.10.3    |
| dc-r4.lab.local       | 10.10.10.4    |
| dc-sw1-l3.lab.local   | 10.10.10.11   |
| dc-sw2-l3.lab.local   | 10.10.10.12   |
| dc-sw3-l3.lab.local   | 10.10.10.13   |
| dc-sw4-l3.lab.local   | 10.10.10.14   |
| br1-r1.lab.local      | 12.12.12.1    |
| br1-r2.lab.local      | 12.12.12.2    |
| br1-sw1-l3.lab.local  | 12.12.12.11   |
| br1-sw2-l3.lab.local  | 12.12.12.12   |
| br2-r1.lab.local      | 13.13.13.1    |
| br2-r2.lab.local      | 13.13.13.2    |
| br2-sw1-l3.lab.local  | 13.13.13.11   |
| br2-sw2-l3.lab.local  | 13.13.13.12   |
| private-net.lab.local | 2.2.2.2       |
| isp-1-pe-a.lab.local  | 100.100.100.1 |
| isp-1-p1.lab.local    | 100.100.100.2 |
| isp-1-p2.lab.local    | 100.100.100.3 |
| isp-1-pe-b.lab.local  | 100.100.100.4 |
| isp-2-pe-a.lab.local  | 200.200.200.1 |
| isp-2-p1.lab.local    | 200.200.200.2 |
| isp-2-p2.lab.local    | 200.200.200.3 |
| isp-2-pe-b.lab.local  | 200.200.200.4 |
| dc-dns-1.lab.local    | 10.2.50.10    |
| dc-dns-2.lab.local    | 10.2.50.11    |

## 3. DHCP 서버

- 게이트웨이 스위치 두 대가 같은 서브넷에 같은 풀을 두되 서로 다른 절반만 할당(주소 중복 방지). 풀은 `.100` – `.227`(128개).
- Active(우선순위 110) 장비는 `.100` – `.163`, Standby(우선순위 90) 장비는 `.164` – `.227` 담당. 제외 구간(`excluded-address`)으로 범위를 구분.
- 옵션: `default-router` VRRP VIP(`.1`), `dns-server` `10.2.50.10` `10.2.50.11`, `domain-name` `lab.local`, 임대 시간 1일.

| 사이트 | VLAN | 풀 이름        | 서브넷          | 장비         | 역할      | 할당 범위                     | 제외 구간                                              |
| --- | ---- | ----------- | ------------ | ---------- | ------- | ------------------------- | -------------------------------------------------- |
| HQ  | 10   | hq-public   | 10.1.10.0/24 | HQ-SW-2    | Active  | 10.1.10.100 – 10.1.10.163 | 10.1.10.1 – 10.1.10.99, 10.1.10.164 – 10.1.10.254  |
| HQ  | 10   | hq-public   | 10.1.10.0/24 | HQ-SW-3    | Standby | 10.1.10.164 – 10.1.10.227 | 10.1.10.1 – 10.1.10.163, 10.1.10.228 – 10.1.10.254 |
| HQ  | 20   | hq-private  | 10.1.20.0/24 | HQ-SW-2    | Active  | 10.1.20.100 – 10.1.20.163 | 10.1.20.1 – 10.1.20.99, 10.1.20.164 – 10.1.20.254  |
| HQ  | 20   | hq-private  | 10.1.20.0/24 | HQ-SW-3    | Standby | 10.1.20.164 – 10.1.20.227 | 10.1.20.1 – 10.1.20.163, 10.1.20.228 – 10.1.20.254 |
| BR1 | 10   | br1-public  | 10.3.10.0/24 | BR1-SW1-L3 | Active  | 10.3.10.100 – 10.3.10.163 | 10.3.10.1 – 10.3.10.99, 10.3.10.164 – 10.3.10.254  |
| BR1 | 20   | br1-private | 10.3.20.0/24 | BR1-SW1-L3 | Active  | 10.3.20.100 – 10.3.20.163 | 10.3.20.1 – 10.3.20.99, 10.3.20.164 – 10.3.20.254  |
| BR1 | 10   | br1-public  | 10.3.10.0/24 | BR1-SW2-L3 | Standby | 10.3.10.164 – 10.3.10.227 | 10.3.10.1 – 10.3.10.163, 10.3.10.228 – 10.3.10.254 |
| BR1 | 20   | br1-private | 10.3.20.0/24 | BR1-SW2-L3 | Standby | 10.3.20.164 – 10.3.20.227 | 10.3.20.1 – 10.3.20.163, 10.3.20.228 – 10.3.20.254 |
| BR2 | 10   | br2-public  | 10.4.10.0/24 | BR2-SW1-L3 | Active  | 10.4.10.100 – 10.4.10.163 | 10.4.10.1 – 10.4.10.99, 10.4.10.164 – 10.4.10.254  |
| BR2 | 20   | br2-private | 10.4.20.0/24 | BR2-SW1-L3 | Active  | 10.4.20.100 – 10.4.20.163 | 10.4.20.1 – 10.4.20.99, 10.4.20.164 – 10.4.20.254  |
| BR2 | 10   | br2-public  | 10.4.10.0/24 | BR2-SW2-L3 | Standby | 10.4.10.164 – 10.4.10.227 | 10.4.10.1 – 10.4.10.163, 10.4.10.228 – 10.4.10.254 |
| BR2 | 20   | br2-private | 10.4.20.0/24 | BR2-SW2-L3 | Standby | 10.4.20.164 – 10.4.20.227 | 10.4.20.1 – 10.4.20.163, 10.4.20.228 – 10.4.20.254 |

### 3.1 설정 예시(HQ-SW-2, VLAN 10)

```
service dhcp
ip dhcp excluded-address 10.1.10.1 10.1.10.99
ip dhcp excluded-address 10.1.10.164 10.1.10.254
!
ip dhcp pool hq-public
 network 10.1.10.0 255.255.255.0
 default-router 10.1.10.1
 dns-server 10.2.50.10 10.2.50.11
 domain-name lab.local
 lease 1
```

- Standby 장비(`HQ-SW-3`)는 풀 설정이 같고 제외 구간만 `10.1.10.1 10.1.10.163`, `10.1.10.228 10.1.10.254`로 설정.
- 다른 VLAN(HQ VLAN 20, BR1·BR2 VLAN 10과 20)도 같은 형식으로 서브넷과 풀 이름만 변경.

### 3.2 설정 예시(BR1-SW1-L3, Aruba CX)

```
dhcp-server vrf default
 pool br1-public
  range 10.3.10.100 10.3.10.163 prefix-len 24
  default-router 10.3.10.1
  dns-server 10.2.50.10 10.2.50.11
  domain-name lab.local
  lease 01:00:00
 exit
 pool br1-private
  range 10.3.20.100 10.3.20.163 prefix-len 24
  default-router 10.3.20.1
  dns-server 10.2.50.10 10.2.50.11
  domain-name lab.local
  lease 01:00:00
 exit
 enable
```

- Aruba(AOS-CX)는 제외 구간 대신 `range`로 할당 범위를 직접 지정. Active `BR1-SW1-L3`은 `.100` – `.163`, Standby `BR1-SW2-L3`은 `.164` – `.227`.
- 풀 이름, 옵션 값은 3절 표와 같고 명령 문법은 AOS-CX 10.07 가상 장비에서 확인함. 풀 사이에 `exit` 필요, `enable`은 풀 밖(`dhcp-server` 레벨)에서 입력. `lease`는 `DD:HH:MM` 두 자리 형식(`01:00:00` = 1일, 기본값은 `00:01:00`)이며 서버가 켜진 상태에서는 변경 불가(`disable` 후 변경, 다시 `enable`).

## 4. 클라이언트(알파인 호스트)

- 주소 설정: `/etc/network/interfaces`에 `iface eth0 inet dhcp`, 또는 수동 실행 `udhcpc -i eth0`.
- DNS 설정: DHCP 응답의 DNS 옵션이 `/etc/resolv.conf`에 반영(`nameserver 10.2.50.10`, `nameserver 10.2.50.11`).

## 5. 접근 통제

- 외부(각 사이트, ISP)에서 서버 VLAN(`10.2.50.0/24`)으로 들어오는 트래픽은 UDP/TCP 53만 허용하고 그 외 차단. 서버 VLAN은 DHCP를 사용하지 않으므로 UDP 67/68은 허용 대상이 아님.
- 적용 위치: DC 라우터(`DC-R1` ~ `DC-R4`)의 스위치 방향 인터페이스(`Gi0/0`, `Gi1/0`) 출력 방향. DC 외부에서 서버 VLAN으로 가는 트래픽은 모두 이 라우터들을 거침. 서버가 보내는 응답 트래픽은 필터링하지 않음.
- Arista vEOS-lab는 인터페이스 ACL을 지원하지 않아 스위치(`DC-SW3-L3`, `DC-SW4-L3`)에는 적용하지 않음. `ip access-group`이 SVI 출력, 라우티드 포트 입력 모두 `Unavailable command (not supported on this hardware platform)`로 거부됨(`verification/dc/core/acl.md`).
- 한계: DC 내부 VLAN 간 라우팅(예: VLAN 100에서 VLAN 50)은 스위치 안에서 처리되어 이 ACL을 거치지 않음.
- ICMP는 허용 대상이 아니므로 ACL 적용 후 서버 응답 확인은 `ping`이 아니라 `nslookup` 또는 `dig` 사용.

| 순서 | 동작 | 프로토콜 | 목적지 | 포트 |
|---|---|---|---|---|
| 10 | permit | udp | host 10.2.50.10 | 53 |
| 20 | permit | tcp | host 10.2.50.10 | 53 |
| 30 | permit | udp | host 10.2.50.11 | 53 |
| 40 | permit | tcp | host 10.2.50.11 | 53 |
| 50 | deny | ip | 10.2.50.0/24 | - (로그) |
| 60 | permit | ip | any | - (서버 VLAN 외 트래픽은 통과) |

## 6. 검증 항목

| 항목 | 명령 | 기대 결과 |
|---|---|---|
| DHCP 할당 | 호스트에서 `udhcpc -i eth0`, `ip addr` | 풀 범위 주소(`.100` – `.227`), 게이트웨이 VIP |
| DHCP 서버 | 스위치에서 `show ip dhcp binding`, `show ip dhcp pool` | 임대 목록, 풀 사용량 |
| 풀 분할 | 두 스위치 모두 응답 시 각자 범위 내 주소 | 앞 64개 또는 뒤 64개 |
| DNS 조회 | `nslookup dc-r1.lab.local 10.2.50.10` | `10.10.10.1` |
| DNS 백업 | 주 서버 중지 후 `nslookup dc-r1.lab.local 10.2.50.11` | 동일 응답 |
| 접근 통제 | 호스트에서 서버 VLAN 대상 DNS 외 포트 접속 시도 | 차단 |

