# OpenClaw VPS 설치 가이드

> 코딩 몰라도 됩니다. 24시간 AI 에이전트를 내 서버에 올리는 완전 가이드.

비개발자도 따라할 수 있도록 **Contabo VPS 가입부터 텔레그램 연결까지** 전 과정을 담았습니다.

---

## ⚡ 원클릭 설치

VPS에 SSH 접속 후 아래 두 줄을 붙여넣으세요:

```bash
curl -fsSL https://raw.githubusercontent.com/kokaju007/openclaw-setup/main/install.sh -o install.sh
bash install.sh
```

자동으로 처리되는 것들:
- ✅ Node.js 설치 확인
- ✅ OpenClaw 설치
- ✅ 텔레그램 봇 연결
- ✅ 설정 파일 보안 설정
- ✅ 24시간 자동 실행 등록

---

## 📋 준비물

| 항목 | 어디서 | 비용 |
|------|--------|------|
| VPS 서버 (Ubuntu 22.04) | [Contabo](https://contabo.com) | 월 $6.99~ |
| Claude API 키 | [console.anthropic.com](https://console.anthropic.com) | 사용량 과금 |
| 텔레그램 봇 토큰 | 텔레그램 @BotFather | 무료 |
| 텔레그램 사용자 ID | 텔레그램 @userinfobot | 무료 |

---

## 📖 상세 가이드 (PDF)

**Releases** 탭에서 PDF 가이드를 다운로드하세요.

👉 [PDF 다운로드](https://github.com/kokaju007/openclaw-setup/releases/download/v1.1.0/openclaw-vps-guide.pdf)

Contabo 가입 → SSH 접속 → 설치 → 텔레그램 연결 → API 키 설정까지  
스크린샷 없이도 따라할 수 있게 단계별로 설명합니다.

---

## 🔒 보안

- 외부 코드 자동 실행 없음 (eval/exec 미사용)
- 개인정보 외부 전송 없음 (토큰은 서버 내부에만 저장)
- 공식 패키지만 사용 (npm + apt 공식 저장소)
- **Ubuntu 20.04 / 22.04 / 24.04 실서버 3회 직접 테스트 완료**
- 파일 삭제 명령어 없음 (rm -rf 미사용)

코드는 전체 공개되어 있으니 직접 확인하세요.

---

## 🛠 유용한 명령어

```bash
# 상태 확인
sudo systemctl status openclaw

# 재시작
sudo systemctl restart openclaw

# 실시간 로그
sudo journalctl -u openclaw -f
```

---

## ❓ 자주 묻는 질문

**Q. 봇이 응답을 안 해요**  
봇 토큰과 사용자 ID 확인 후 `sudo systemctl restart openclaw`

**Q. SSH 비밀번호 입력 시 화면에 아무것도 안 보여요**  
정상입니다. 보안상 숨겨지는 거예요. 그냥 치고 엔터 누르면 됩니다.

**Q. 서버 재부팅 후 작동 안 해요**  
`sudo systemctl enable openclaw` 실행 후 재시도

---

## ⭐ Star

도움이 됐다면 Star 눌러주세요. 계속 업데이트합니다.

---

*Made by [@kokaju007](https://github.com/kokaju007)*
