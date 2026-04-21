#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/cluster.yaml"
CLUSTER_NAME="homelab"

log() {
  local GREEN="\e[32m"
  local RESET="\e[0m"
  printf "\n${GREEN}==> %s${RESET}\n" "$*"
}

get_server_ip() {
  local iface
  iface=$(ip -o link show | awk -F': ' '$2 ~ /^e[nt]/ {print $2; exit}')
  local ip
  ip=$(ip -o -4 addr show dev "$iface" | awk '{print $4}' | cut -d/ -f1)
  if [[ -z "$ip" ]]; then
    echo "[ERRO] Não foi possível detectar o IP da interface cabeada." >&2
    exit 1
  fi
  echo "$ip"
}

usage() {
  echo ""
  echo "  Uso: $0 <comando>"
  echo ""
  echo "  Comandos:"
  echo "    create      Cria o cluster k3d com a configuração em cluster.yaml"
  echo "    delete      Destrói o cluster"
  echo "    status      Exibe nodes e pods do sistema"
  echo "    kubeconfig  Exibe o kubeconfig com o IP da interface cabeada"
  echo ""
}

cmd_create() {
  if k3d cluster list | grep -q "^${CLUSTER_NAME}"; then
    echo "Cluster '${CLUSTER_NAME}' já existe."
    k3d cluster list
    return
  fi

  SERVER_IP="$(get_server_ip)"
  log "IP detectado: $SERVER_IP"
  log "Criando cluster '${CLUSTER_NAME}' com config: $CONFIG"
  k3d cluster create --config "$CONFIG" --k3s-arg "--tls-san=${SERVER_IP}@server:0"

  log "Cluster criado com sucesso!"
  kubectl get nodes
}

cmd_delete() {
  log "Destruindo cluster '${CLUSTER_NAME}'"
  k3d cluster delete "$CLUSTER_NAME"
  log "Cluster removido."
}

cmd_status() {
  log "Nodes do cluster"
  kubectl get nodes -o wide

  echo ""
  log "Pods do sistema"
  kubectl get pods -A
}

cmd_kubeconfig() {
  SERVER_IP="$(get_server_ip)"
  log "IP detectado: $SERVER_IP"
  echo ""
  k3d kubeconfig get "$CLUSTER_NAME" | sed "s/0\.0\.0\.0/${SERVER_IP}/g"
}

case "${1:-}" in
  create)     cmd_create ;;
  delete)     cmd_delete ;;
  status)     cmd_status ;;
  kubeconfig) cmd_kubeconfig ;;
  *)          usage; exit 1 ;;
esac
