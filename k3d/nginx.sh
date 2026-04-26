#!/usr/bin/env bash
set -euo pipefail

MANIFESTS_DIR="$(cd "$(dirname "$0")/manifests/nginx" && pwd)"

log() {
  local GREEN="\e[32m"
  local RESET="\e[0m"
  printf "\n${GREEN}==> %s${RESET}\n" "$*"
}

usage() {
  echo ""
  echo "  Uso: $0 <comando>"
  echo ""
  echo "  Comandos:"
  echo "    deploy   Aplica namespace, deployment e service do nginx"
  echo "    delete   Remove todos os recursos do nginx"
  echo "    status   Exibe pods e service no namespace ingress-nginx"
  echo ""
}

cmd_deploy() {
  log "Aplicando manifests do nginx"
  kubectl apply -f "$MANIFESTS_DIR"

  log "Aguardando rollout do deployment"
  kubectl rollout status deployment/nginx -n ingress-nginx

  log "Deploy concluído"
  cmd_status
}

cmd_delete() {
  log "Removendo recursos do nginx"
  kubectl delete -f "$MANIFESTS_DIR" --ignore-not-found
  log "Recursos removidos."
}

cmd_status() {
  log "Pods"
  kubectl get pods -n ingress-nginx -o wide

  echo ""
  log "Service"
  kubectl get svc -n ingress-nginx
}

case "${1:-}" in
  deploy) cmd_deploy ;;
  delete) cmd_delete ;;
  status) cmd_status ;;
  *)      usage; exit 1 ;;
esac
