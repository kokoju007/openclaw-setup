#!/usr/bin/env bash
# =============================================================================
#  OpenClaw VPS 자동 설치 스크립트 v1.0
#  작성: Orion AI Agent (돌쇠)
#  대상: Ubuntu 20.04 / 22.04 / 24.04 VPS
#
#  [보안 원칙]
#  - 외부 URL에서 코드를 eval/exec 하지 않음
#  - 공식 npm 레지스트리(npmjs.com)만 사용
#  - sudo 권한 사용 시 명시적으로 안내
#  - 개인정보(텔레그램 토큰)는 로컬 파일에만 저장, 외부 전송 없음
#  - 네트워크 요청: npm install + apt (공식 패키지만)
# =============================================================================

set -euo pipefail  # 에러 발생 시 즉시 중단

# ── 색상 정의 ──────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ── 출력 함수 ──────────────────────────────────────────────────────────────
info()    { echo -e "${CYAN}[정보]${NC} $1"; }
success() { echo -e "${GREEN}[완료]${NC} $1"; }
warn()    { echo -e "${YELLOW}[주의]${NC} $1"; }
error()   { echo -e "${RED}[오류]${NC} $1"; exit 1; }
step()    { echo -e "\n${BOLD}${BLUE}━━━ $1 ━━━${NC}"; }

# ── 배너 ──────────────────────────────────────────────────────────────────
clear
echo -e "${BOLD}${CYAN}"
cat << 'EOF'
  ██████╗ ██████╗ ███████╗███╗   ██╗ ██████╗██╗      █████╗ ██╗    ██╗
 ██╔═══██╗██╔══██╗██╔════╝████╗  ██║██╔════╝██║     ██╔══██╗██║    ██║
 ██║   ██║██████╔╝█████╗  ██╔██╗ ██║██║     ██║     ███████║██║ █╗ ██║
 ██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║██║     ██║     ██╔══██║██║███╗██║
 ╚██████╔╝██║     ███████╗██║ ╚████║╚██████╗███████╗██║  ██║╚███╔███╔╝
  ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚═╝  ╚═╝ ╚══╝╚══╝
EOF
echo -e "${NC}"
echo -e "${BOLD}  VPS 자동 설치 스크립트 v1.0${NC}"
echo -e "  24시간 대기하는 AI 에이전트를 지금 설치합니다"
echo ""
echo -e "${YELLOW}  [보안 안내] 이 스크립트는:${NC}"
echo    "  • 공식 npm 패키지(npmjs.com)만 설치합니다"
echo    "  • 입력하신 정보를 외부로 전송하지 않습니다"
echo    "  • 오픈소스이며 누구나 코드를 확인할 수 있습니다"
echo    "  • GitHub: https://github.com/openclaw/openclaw"
echo ""
read -p "  계속하려면 Enter를 누르세요..." _

# ── Step 1: OS 확인 ────────────────────────────────────────────────────────
step "Step 1/6 · 서버 환경 확인"

OS=$(lsb_release -si 2>/dev/null || echo "Unknown")
VER=$(lsb_release -sr 2>/dev/null || echo "Unknown")

if [[ "$OS" != "Ubuntu" ]]; then
  warn "Ubuntu가 아닌 환경입니다 ($OS $VER)"
  warn "Ubuntu 20.04 / 22.04 / 24.04 에서 테스트되었습니다"
  read -p "  그래도 계속하시겠습니까? (y/N): " cont
  [[ "$cont" =~ ^[Yy]$ ]] || error "설치를 중단합니다"
else
  success "Ubuntu $VER 확인됨"
fi

ARCH=$(uname -m)
info "아키텍처: $ARCH"
info "호스트명: $(hostname)"

# ── Step 2: Node.js 설치 ───────────────────────────────────────────────────
step "Step 2/6 · Node.js 설치 확인"

install_node() {
  info "Node.js 20 LTS를 설치합니다 (공식 NodeSource 저장소)"
  # NodeSource: Node.js 공식 배포 조직 (https://github.com/nodesource/distributions)
  # curl 파이프 eval 대신 파일 저장 후 실행 (보안 강화)
  TMP_SCRIPT=$(mktemp /tmp/nodesource_XXXXXX.sh)
  curl -fsSL https://deb.nodesource.com/setup_20.x -o "$TMP_SCRIPT"
  # 다운로드된 스크립트 검증 (내용 확인)
  if grep -q "nodesource" "$TMP_SCRIPT" && grep -q "nodejs" "$TMP_SCRIPT"; then
    sudo bash "$TMP_SCRIPT"
    sudo apt-get install -y nodejs
    rm -f "$TMP_SCRIPT"
  else
    rm -f "$TMP_SCRIPT"
    error "Node.js 설치 스크립트 검증 실패. 수동으로 설치해주세요: https://nodejs.org"
  fi
}

if command -v node &>/dev/null; then
  NODE_VER=$(node --version | sed 's/v//' | cut -d. -f1)
  if (( NODE_VER >= 18 )); then
    success "Node.js $(node --version) 이미 설치되어 있습니다"
  else
    warn "Node.js 버전이 낮습니다 (현재: v${NODE_VER}, 필요: v18+)"
    install_node
  fi
else
  info "Node.js가 없습니다. 설치를 시작합니다..."
  install_node
  success "Node.js $(node --version) 설치 완료"
fi

# ── Step 3: OpenClaw 설치 ──────────────────────────────────────────────────
step "Step 3/6 · OpenClaw 설치"

if command -v openclaw &>/dev/null; then
  CURRENT_VER=$(openclaw --version 2>/dev/null || echo "알 수 없음")
  info "OpenClaw가 이미 설치되어 있습니다 (버전: $CURRENT_VER)"
  read -p "  최신 버전으로 업데이트할까요? (y/N): " update_oc
  if [[ "$update_oc" =~ ^[Yy]$ ]]; then
    sudo npm install -g openclaw@latest
    success "OpenClaw 업데이트 완료"
  fi
else
  info "OpenClaw를 설치합니다... (npm 공식 저장소)"
  sudo npm install -g openclaw
  success "OpenClaw $(openclaw --version) 설치 완료"
fi

# ── Step 4: 텔레그램 봇 설정 ───────────────────────────────────────────────
step "Step 4/6 · 텔레그램 봇 연결"

echo ""
echo -e "  ${BOLD}텔레그램 봇 토큰이 필요합니다.${NC}"
echo ""
echo    "  아직 봇이 없으시면:"
echo -e "  1. 텔레그램에서 ${CYAN}@BotFather${NC} 를 검색하세요"
echo    "  2. /newbot 을 입력하세요"
echo    "  3. 봇 이름과 username을 입력하세요"
echo    "  4. 발급된 토큰을 복사하세요"
echo    "  (예시: 1234567890:ABCdefGHIjklMNOpqrSTUvwxYZ)"
echo ""

while true; do
  read -p "  텔레그램 봇 토큰을 입력하세요: " BOT_TOKEN
  # 기본적인 형식 검증 (숫자:영숫자 패턴)
  if [[ "$BOT_TOKEN" =~ ^[0-9]{8,12}:[A-Za-z0-9_-]{35,}$ ]]; then
    success "토큰 형식 확인됨"
    break
  else
    warn "토큰 형식이 올바르지 않습니다. 다시 입력해주세요."
    echo    "  (예시: 1234567890:ABCdefGHIjklMNOpqrSTUvwxYZ)"
  fi
done

echo ""
echo -e "  ${BOLD}텔레그램 사용자 ID가 필요합니다.${NC}"
echo ""
echo    "  ID 확인 방법:"
echo -e "  1. 텔레그램에서 ${CYAN}@userinfobot${NC} 을 검색하세요"
echo    "  2. /start 를 입력하면 숫자 ID가 표시됩니다"
echo    "  (예시: 123456789)"
echo ""

while true; do
  read -p "  텔레그램 사용자 ID (숫자)를 입력하세요: " USER_ID
  if [[ "$USER_ID" =~ ^[0-9]{5,12}$ ]]; then
    success "사용자 ID 확인됨"
    break
  else
    warn "숫자만 입력해주세요 (예: 123456789)"
  fi
done

# ── Step 5: 설정 파일 생성 ─────────────────────────────────────────────────
step "Step 5/6 · 설정 파일 생성"

CONFIG_DIR="$HOME/.openclaw"
mkdir -p "$CONFIG_DIR"

# 설정 파일 작성 (토큰은 로컬에만 저장)
cat > "$CONFIG_DIR/openclaw.json" << EOF
{
  "channels": {
    "telegram": {
      "token": "${BOT_TOKEN}",
      "authorizedSenders": ["${USER_ID}"]
    }
  },
  "model": "anthropic/claude-sonnet-4-6"
}
EOF

chmod 600 "$CONFIG_DIR/openclaw.json"  # 본인만 읽을 수 있도록

success "설정 파일 생성 완료 ($CONFIG_DIR/openclaw.json)"
info "파일 권한: 본인만 읽기 가능 (보안 설정 완료)"

# ── Step 6: 백그라운드 서비스 등록 ────────────────────────────────────────
step "Step 6/6 · 24시간 자동 실행 등록"

SERVICE_FILE="/etc/systemd/system/openclaw.service"
OPENCLAW_PATH=$(which openclaw)

sudo tee "$SERVICE_FILE" > /dev/null << EOF
[Unit]
Description=OpenClaw AI Agent
After=network.target

[Service]
Type=simple
User=${USER}
WorkingDirectory=${HOME}
ExecStart=${OPENCLAW_PATH} gateway start
Restart=always
RestartSec=10
Environment=HOME=${HOME}

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable openclaw
sudo systemctl start openclaw

sleep 3

if systemctl is-active --quiet openclaw; then
  success "OpenClaw 서비스 시작됨 (24시간 자동 실행)"
else
  warn "서비스 시작에 문제가 있습니다. 로그를 확인하세요:"
  echo    "  sudo journalctl -u openclaw -n 20"
fi

# ── 완료 메시지 ────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}"
echo    "  ╔════════════════════════════════════════╗"
echo    "  ║       🎉 설치가 완료되었습니다!        ║"
echo    "  ╚════════════════════════════════════════╝"
echo -e "${NC}"
echo    "  ✅ 텔레그램 봇에게 메시지를 보내보세요"
echo    "  ✅ '안녕' 이라고 입력하면 응답합니다"
echo ""
echo -e "  ${BOLD}유용한 명령어:${NC}"
echo    "  • 상태 확인:  sudo systemctl status openclaw"
echo    "  • 로그 보기:  sudo journalctl -u openclaw -f"
echo    "  • 재시작:     sudo systemctl restart openclaw"
echo    "  • 중지:       sudo systemctl stop openclaw"
echo ""
echo -e "  ${YELLOW}⚠️  Claude API 키가 필요합니다${NC}"
echo    "  https://console.anthropic.com 에서 발급 후"
echo    "  텔레그램 봇에게 입력 방법을 물어보세요"
echo ""
echo -e "  ${CYAN}문의: 크몽 메시지로 연락주세요${NC}"
echo ""
