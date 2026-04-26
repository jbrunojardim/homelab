#!/usr/bin/env bash
set -euo pipefail

CLUSTER="homelab"

mkdir -p /home/gitlab-runner/.kube
k3d kubeconfig get "${CLUSTER}" | sudo tee /home/gitlab-runner/.kube/config > /dev/null
sudo chown gitlab-runner:gitlab-runner /home/gitlab-runner/.kube/config

echo "kubeconfig applied for cluster '${CLUSTER}'"

