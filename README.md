# homelab

Automação de infraestrutura para laboratório homelab — Kubernetes, serviços e devops em hardware local.

---

## Hardware

| Máquina | Modelo | SO | Função |
|---|---|---|---|
| Servidor | Samsung Galaxy Book 360 | Fedora Server | Nó do cluster k3d |
| Desktop | Lenovo ThinkPad T14 | Fedora 43 / Hyprland | Controle remoto via kubectl |

> O servidor foi configurado como headless via [dotstrap/bootstrap/headless.sh](https://github.com/jbrunojardim/dotstrap/blob/joseph/bootstrap/headless.sh).

---

## Servidor (srvfed01)

### Etapa 1 — Instalar dependências

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/homelab/refs/heads/joseph/tools/install_k3d.sh | bash
```

Instala:
- Docker Engine (via [`dotstrap/tools/docker.sh`](https://github.com/jbrunojardim/dotstrap/blob/joseph/tools/docker.sh))
- k3d (via script oficial)
- kubectl (versão estável mais recente via `dl.k8s.io`)

### Etapa 2 — Criar o cluster

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/homelab/refs/heads/joseph/k3d/cluster.sh | bash -s create
```

Cria um cluster `homelab` com **1 server + 2 agents**, conforme `k3d/cluster.yaml`.

| Detalhe | Valor |
|---|---|
| Nome | `homelab` |
| Servers | 1 |
| Agents | 2 |
| Porta HTTP | 80 → loadbalancer |
| Porta HTTPS | 443 → loadbalancer |
| Porta API (kubectl) | 6443 → loadbalancer |
| TLS-SAN | IP da interface cabeada (detectado automaticamente) |
| Traefik | habilitado (ingress controller padrão) |

### (Opcional) — Permissões para gitlab-runner

Se o servidor tiver um gitlab-runner configurado com executor `shell`, execute no servidor para dar acesso ao kubeconfig:

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/homelab/refs/heads/joseph/scripts/gitlab-runner-shell-permissions.sh | bash
```

O script cria `~gitlab-runner/.kube/config` com o kubeconfig do cluster e ajusta as permissões de ownership.

---

## Desktop (ThinkPad T14)

### Etapa 3 — Configurar kubectl

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/homelab/refs/heads/joseph/scripts/kubeconfig.sh | bash -s joseph@192.168.68.60
```

O script:
- Busca o kubeconfig do servidor via SSH
- Corrige o endereço para `IP:6443`
- Mescla em `~/.kube/config`
- Define `k3d-homelab` como contexto ativo
- Valida com `kubectl get nodes`

---

## Ciclo de vida do cluster

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/homelab/refs/heads/joseph/k3d/cluster.sh | bash -s create
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/homelab/refs/heads/joseph/k3d/cluster.sh | bash -s status
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jbrunojardim/homelab/refs/heads/joseph/k3d/cluster.sh | bash -s delete
```

---

## Estrutura do repositório

```
homelab/
├── tools/
│   └── install_k3d.sh    # Docker + k3d + kubectl no Fedora Server
├── k3d/
│   ├── cluster.sh        # create / delete / status / kubeconfig
│   └── cluster.yaml      # configuração declarativa do cluster k3d
└── scripts/
    ├── kubeconfig.sh                      # configura kubectl no desktop via SSH
    └── gitlab-runner-shell-permissions.sh # kubeconfig para gitlab-runner shell executor (opcional)
```

---

## Crescimento planejado

```
homelab/
├── tools/         # ← implementado
├── k3d/           # ← implementado
├── scripts/       # ← implementado
├── manifests/     # yamls de aplicações
├── helm/          # charts e values
└── terraform/     # infra-as-code
```

---

## Requisitos

- Fedora/RHEL (usa `dnf`)
- Acesso `sudo` no servidor
- `curl`, `bash`, `ssh` disponíveis
