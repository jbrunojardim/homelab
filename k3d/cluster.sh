#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="homelab"
CLUSTER_YAML_URL="https://raw.githubusercontent.com/jbrunojardim/homelab/refs/heads/joseph/k3d/cluster.yaml"
CONFIG="$(mktemp /tmp/k3d-cluster.XXXXXX.yaml)"

cleanup() { rm -f "$CONFIG"; }
trap cleanup EXIT

log() {
  local GREEN="\e[32m"
  local RESET="\e[0m"
  printf "\n${GREEN}==> %s${RESET}\n" "$*"
}

get_server_ip() {
  local iface ip
  # tenta cabeada primeiro (en*, eth*), depois WiFi (wl*)
  iface=$(ip -o link show up | awk '$0 ~ /state UP/ && $2 ~ /^(e[nt]|wl)/ {gsub(/:$/, "", $2); print $2; exit}')
  ip=$(ip -o -4 addr show dev "$iface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1)
  if [[ -z "$ip" ]]; then
    echo "[ERRO] Não foi possível detectar o IP de nenhuma interface de rede." >&2
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

  log "Baixando cluster.yaml"
  curl -fsSL -H 'Cache-Control: no-cache' "$CLUSTER_YAML_URL" -o "$CONFIG"

  SERVER_IP="$(get_server_ip)"
  log "IP detectado: $SERVER_IP"
  log "Criando cluster '${CLUSTER_NAME}'"
  k3d cluster create --config "$CONFIG" \
    --api-port "${SERVER_IP}:6443" \
    --k3s-arg "--tls-san=${SERVER_IP}@server:0"

  log "Configurando kubeconfig local"
  k3d kubeconfig merge "$CLUSTER_NAME" --kubeconfig-switch-context

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
