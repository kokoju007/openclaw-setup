#!/usr/bin/env bash
# =============================================================================
#  OpenClaw VPS 자동 설치 스크립트 v1.1
#  작성: @kokoju007
#  대상: Ubuntu 20.04 / 22.04 / 24.04 VPS
#
#  [보안 원칙]
#  - 외부 URL 코드 직접실행 없음 (파일 저장 후 검증 후 실행)
#  - 공식 npm 레지스트리(npmjs.com)만 사용
#  - 개인정보(텔레그램 토큰)는 로컬 파일에만 저장, 외부 전송 없음
#  - 네트워크 요청: npm install + apt (공식 패키지만)
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

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
echo -e "${BOLD}  VPS 자동 설치 스크립트 v1.1${NC}"
echo -e "  24시간 대기하는 AI 에이전트를 지금 설치합니다"
echo ""
echo -e "${YELLOW}  [보안 안내] 이 스크립트는:${NC}"
echo    "  • 공식 npm 패키지(npmjs.com)만 설치합니다"
echo    "  • 입력하신 정보를 외부로 전송하지 않습니다"
echo    "  • 오픈소스이며 누구나 코드를 확인할 수 있습니다"
echo    "  • GitHub: https://github.com/kokoju007/openclaw-setup"
echo ""
read -p "  계속하려면 Enter를 누르세요..." _

# ── Step 1: OS 확인 ────────────────────────────────────────────────────────
step "Step 1/5 · 서버 환경 확인"

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

info "아키텍처: $(uname -m)"
info "호스트명: $(hostname)"

# ── Step 2: Node.js 22 설치 ────────────────────────────────────────────────
step "Step 2/5 · Node.js 설치 확인"

# OpenClaw는 Node.js 22.12.0 이상 필요
REQUIRED_NODE=22

install_node() {
  info "Node.js ${REQUIRED_NODE} LTS를 설치합니다 (공식 NodeSource 저장소)"
  TMP_SCRIPT=$(mktemp /tmp/nodesource_XXXXXX.sh)
  curl -fsSL "https://deb.nodesource.com/setup_${REQUIRED_NODE}.x" -o "$TMP_SCRIPT"
  if grep -q "nodesource" "$TMP_SCRIPT" && grep -q "nodejs" "$TMP_SCRIPT"; then
    DEBIAN_FRONTEND=noninteractive bash "$TMP_SCRIPT"
    DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs
    rm -f "$TMP_SCRIPT"
  else
    rm -f "$TMP_SCRIPT"
    error "Node.js 설치 스크립트 검증 실패. 수동으로 설치해주세요: https://nodejs.org"
  fi
}

if command -v node &>/dev/null; then
  NODE_VER=$(node --version | sed 's/v//' | cut -d. -f1)
  if (( NODE_VER >= REQUIRED_NODE )); then
    success "Node.js $(node --version) 이미 설치되어 있습니다"
  else
    warn "Node.js 버전이 낮습니다 (현재: v${NODE_VER}, 필요: v${REQUIRED_NODE}+)"
    info "Node.js ${REQUIRED_NODE}로 업그레이드합니다..."
    install_node
    success "Node.js $(node --version) 설치 완료"
  fi
else
  info "Node.js가 없습니다. 설치를 시작합니다..."
  install_node
  success "Node.js $(node --version) 설치 완료"
fi

# ── Step 3: OpenClaw 설치 ──────────────────────────────────────────────────
step "Step 3/5 · OpenClaw 설치"

# 최신 버전 확인
LATEST_VER=$(npm view openclaw version 2>/dev/null || echo "")
if [[ -z "$LATEST_VER" ]]; then
  error "npm에서 openclaw 패키지를 찾을 수 없습니다. 네트워크 연결을 확인해주세요."
fi
info "설치할 버전: openclaw@${LATEST_VER}"

if command -v openclaw &>/dev/null; then
  CURRENT_VER=$(openclaw -V 2>/dev/null || echo "알 수 없음")
  info "OpenClaw가 이미 설치되어 있습니다 (버전: $CURRENT_VER)"
  read -p "  최신 버전으로 업데이트할까요? (y/N): " update_oc
  if [[ "$update_oc" =~ ^[Yy]$ ]]; then
    npm install -g "openclaw@${LATEST_VER}"
    success "OpenClaw 업데이트 완료"
  fi
else
  info "OpenClaw를 설치합니다..."
  npm install -g "openclaw@${LATEST_VER}"

  # 설치 확인
  if ! command -v openclaw &>/dev/null; then
    error "OpenClaw 설치 실패. 'npm install -g openclaw'를 수동으로 실행해보세요."
  fi
  success "OpenClaw $(openclaw -V 2>/dev/null) 설치 완료"
fi

# ── Step 4: 텔레그램 봇 설정 ───────────────────────────────────────────────
step "Step 4/5 · 텔레그램 봇 연결"

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

echo ""
echo -e "  ${BOLD}Anthropic API 키가 필요합니다.${NC}"
echo ""
echo    "  발급 방법:"
echo -e "  1. ${CYAN}https://console.anthropic.com${NC} 접속 후 회원가입"
echo    "  2. API Keys → Create Key"
echo    "  3. sk-ant-... 형태의 키 복사"
echo ""

while true; do
  read -p "  Anthropic API 키를 입력하세요 (sk-ant-...): " ANTHROPIC_KEY
  if [[ "$ANTHROPIC_KEY" =~ ^sk-ant-[A-Za-z0-9_-]{20,}$ ]]; then
    success "API 키 형식 확인됨"
    break
  else
    warn "API 키 형식이 올바르지 않습니다 (sk-ant-로 시작해야 함)"
  fi
done

# ── Step 5: OpenClaw 설정 + 서비스 등록 ───────────────────────────────────
step "Step 5/5 · OpenClaw 설정 및 24시간 서비스 등록"

OPENCLAW_PATH=$(which openclaw)
info "openclaw 경로: $OPENCLAW_PATH"

# openclaw onboard로 설정 자동화
info "OpenClaw 설정을 진행합니다..."
openclaw onboard \
  --non-interactive \
  --accept-risk \
  --auth-choice token \
  --token "$ANTHROPIC_KEY" \
  --token-provider anthropic \
  --install-daemon \
  --skip-skills \
  --skip-ui 2>&1 | grep -v "^$" || true

# 텔레그램 채널 설정
info "텔레그램 채널 설정 중..."
openclaw config set channels.telegram.enabled true
openclaw config set channels.telegram.botToken "$BOT_TOKEN"
openclaw config set channels.telegram.dmPolicy allowlist
openclaw config set "channels.telegram.allowFrom[0]" "$USER_ID"

success "설정 완료"

# 서비스 재시작
info "서비스를 재시작합니다..."
if systemctl is-active --quiet openclaw 2>/dev/null; then
  systemctl restart openclaw
else
  systemctl enable openclaw 2>/dev/null || true
  systemctl start openclaw 2>/dev/null || true
fi

sleep 5

# ── 완료 확인 ────────────────────────────────────────────────────────────
if systemctl is-active --quiet openclaw 2>/dev/null; then
  SVC_STATUS="${GREEN}실행 중 ✅${NC}"
else
  SVC_STATUS="${YELLOW}확인 필요 ⚠️${NC}"
fi

echo ""
echo -e "${GREEN}${BOLD}"
echo    "  ╔════════════════════════════════════════╗"
echo    "  ║       🎉 설치가 완료되었습니다!        ║"
echo    "  ╚════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  서비스 상태: ${SVC_STATUS}"
echo    ""
echo    "  ✅ 텔레그램 봇에게 메시지를 보내보세요"
echo    "  ✅ '안녕' 이라고 입력하면 응답합니다"
echo ""
echo -e "  ${BOLD}유용한 명령어:${NC}"
echo    "  • 상태 확인:  sudo systemctl status openclaw"
echo    "  • 로그 보기:  sudo journalctl -u openclaw -f"
echo    "  • 재시작:     sudo systemctl restart openclaw"
echo    "  • 중지:       sudo systemctl stop openclaw"
echo ""
echo -e "  ${CYAN}GitHub: https://github.com/kokoju007/openclaw-setup${NC}"
echo ""
