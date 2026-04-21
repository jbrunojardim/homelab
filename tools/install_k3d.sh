#!/usr/bin/env bash
set -euo pipefail

log() {
  local GREEN="\e[32m"
  local RESET="\e[0m"
  printf "\n${GREEN}==> %s${RESET}\n" "$*"
}

warn() {
  local YELLOW="\e[33m"
  local RESET="\e[0m"
  printf "\n${YELLOW}[AVISO] %s${RESET}\n" "$*"
}

# Verificação do gerenciador de pacotes
if ! command -v dnf >/dev/null 2>&1; then
  printf "\n\e[31mERRO: 'dnf' não encontrado. Este script suporta apenas Fedora/RHEL.\e[0m\n" >&2
  exit 1
fi

sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# ─── Docker Engine ────────────────────────────────────────────────────────────
log "Instalando Docker Engine (via dotstrap/tools/docker.sh)"

curl -fsSL -H 'Cache-Control: no-cache' \
  https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/tools/docker.sh | bash

# ─── k3d ──────────────────────────────────────────────────────────────────────
log "Instalando k3d"

if command -v k3d >/dev/null 2>&1; then
  log "k3d já instalado: $(k3d version | head -1)"
else
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
  log "k3d instalado: $(k3d version | head -1)"
fi

# ─── kubectl ──────────────────────────────────────────────────────────────────
log "Instalando kubectl"

if command -v kubectl >/dev/null 2>&1; then
  log "kubectl já instalado: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
  KUBECTL_VERSION="$(curl -Ls https://dl.k8s.io/release/stable.txt)"
  curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/kubectl
  log "kubectl instalado: $(kubectl version --client)"
fi

# ─── Conclusão ────────────────────────────────────────────────────────────────
echo ""
log "Instalação concluída com sucesso!"
echo ""
echo "    Docker:  $(docker --version)"
echo "    k3d:     $(k3d version | head -1)"
echo "    kubectl: $(kubectl version --client 2>/dev/null | head -1)"
echo ""
echo "    Próximo passo:"
echo "      bash k3d/cluster.sh create"
echo ""
if ! groups "$USER" | grep -q docker; then
  warn "Execute 'newgrp docker' ou abra uma nova sessão SSH antes de criar o cluster."
fi
