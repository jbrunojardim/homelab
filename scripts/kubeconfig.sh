#!/usr/bin/env bash
set -euo pipefail

log() {
  local GREEN="\e[32m"
  local RESET="\e[0m"
  printf "\n${GREEN}==> %s${RESET}\n" "$*"
}

if [[ -z "${1:-}" ]]; then
  echo ""
  echo "  Uso: $0 <user@server-ip>"
  echo ""
  echo "  Exemplo:"
  echo "    $0 joseph@192.168.68.60"
  echo ""
  exit 1
fi

SERVER="$1"
SERVER_IP="${SERVER#*@}"
CLUSTER_NAME="homelab"
KUBECONFIG_DIR="$HOME/.kube"
KUBECONFIG_FILE="$KUBECONFIG_DIR/config"
TEMP="$(mktemp /tmp/kubeconfig-homelab.XXXXXX)"

cleanup() { rm -f "$TEMP"; }
trap cleanup EXIT

log "Verificando kubectl"
curl -fsSL -H 'Cache-Control: no-cache' \
  https://raw.githubusercontent.com/jbrunojardim/dotstrap/refs/heads/joseph/tools/kubectl.sh | bash

mkdir -p "$KUBECONFIG_DIR"
chmod 700 "$KUBECONFIG_DIR"

log "Buscando kubeconfig do servidor $SERVER"
ssh "$SERVER" "k3d kubeconfig get $CLUSTER_NAME | sed 's|https://0\\.0\\.0\\.0:[0-9]*|https://${SERVER_IP}:6443|g'" > "$TEMP"

log "Mesclando em $KUBECONFIG_FILE"
if [[ -f "$KUBECONFIG_FILE" ]]; then
  KUBECONFIG="${KUBECONFIG_FILE}:${TEMP}" kubectl config view --flatten > "${KUBECONFIG_FILE}.merged"
  mv "${KUBECONFIG_FILE}.merged" "$KUBECONFIG_FILE"
else
  cp "$TEMP" "$KUBECONFIG_FILE"
fi

chmod 600 "$KUBECONFIG_FILE"

log "Definindo contexto ativo: k3d-${CLUSTER_NAME}"
kubectl config use-context "k3d-${CLUSTER_NAME}"

log "Validando acesso ao cluster"
kubectl get nodes

echo ""
log "Configuração concluída!"
echo "    Contexto ativo: $(kubectl config current-context)"
echo ""
