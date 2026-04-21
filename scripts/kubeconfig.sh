#!/usr/bin/env bash
set -euo pipefail

# Busca o kubeconfig do servidor homelab e mescla em ~/.kube/config
#
# Uso:
#   bash scripts/kubeconfig.sh <user@server-ip>
#
# Exemplo:
#   bash scripts/kubeconfig.sh bruno@192.168.1.100

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
  echo "    $0 bruno@192.168.1.100"
  echo ""
  exit 1
fi

SERVER="$1"
CLUSTER_NAME="homelab"
KUBECONFIG_DIR="$HOME/.kube"
KUBECONFIG_FILE="$KUBECONFIG_DIR/config"
TEMP_KUBECONFIG="$(mktemp /tmp/kubeconfig-homelab.XXXXXX)"

cleanup() { rm -f "$TEMP_KUBECONFIG"; }
trap cleanup EXIT

mkdir -p "$KUBECONFIG_DIR"
chmod 700 "$KUBECONFIG_DIR"

log "Buscando kubeconfig do servidor $SERVER"

# Obtém o IP da conexão SSH (resolve o que foi passado como argumento)
SERVER_HOST="${SERVER#*@}"

# Puxa o kubeconfig via SSH e substitui 0.0.0.0 pelo IP real do servidor
ssh "$SERVER" "bash k3d/cluster.sh kubeconfig" \
  | sed "s/0\.0\.0\.0/${SERVER_HOST}/g" \
  | sed "s/127\.0\.0\.1/${SERVER_HOST}/g" \
  > "$TEMP_KUBECONFIG"

log "Kubeconfig obtido. Mesclando em $KUBECONFIG_FILE"

# Mescla usando a variável KUBECONFIG do kubectl
if [[ -f "$KUBECONFIG_FILE" ]]; then
  KUBECONFIG="${KUBECONFIG_FILE}:${TEMP_KUBECONFIG}" \
    kubectl config view --flatten > "${KUBECONFIG_FILE}.merged"
  mv "${KUBECONFIG_FILE}.merged" "$KUBECONFIG_FILE"
else
  cp "$TEMP_KUBECONFIG" "$KUBECONFIG_FILE"
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
