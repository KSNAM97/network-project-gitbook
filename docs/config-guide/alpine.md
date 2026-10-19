# 알파인 노드 설정

> 설정 가이드 목차: [README.md](./README.md) | [Cisco 라우터](./cisco-router.md) | [Cisco 스위치](./cisco-switch.md) | [Arista 스위치](./arista-switch.md) | [Aruba 스위치](./aruba-switch.md) | [알파인](./alpine.md)

- `DC-DNS-1`, `DC-DNS-2`는 알파인이 아니라 GNS3 `DNS` 템플릿(Debian 계열, `dnsmasq` 설치됨)을 사용. `docs/dhcp-dns-design.md` 2절의 `interfaces`, `dnsmasq.conf`, `hosts.lab` 사용. 설정은 `configs/dc/host/<장비명>.sh`(고정 주소, `dnsmasq.conf`, 레코드 31개, `service dnsmasq restart`, 확인 명령을 순서대로 붙여 넣는 명령 모음).
- 호스트(`HQ-PC*`, `BR*-PC*`): DHCP 클라이언트(`docs/dhcp-dns-design.md` 4절). 설정은 `configs/<사이트>/host/<장비명>.alp`에 기록. 파일은 콘솔에 순서대로 붙여 넣는 명령 모음(hostname 지정, `interfaces` 작성, DHCP 요청, `cat`/`ip`로 확인)이며 주석은 `#`.

- 호스트 `/etc/network/interfaces`(DHCP 클라이언트):

```
auto eth0
iface eth0 inet dhcp
```

- 서버(`DC-DNS-1`, `DC-DNS-2`)의 고정 주소 설정과 `dnsmasq.conf`는 `docs/dhcp-dns-design.md` 2.1절 형식 사용.
