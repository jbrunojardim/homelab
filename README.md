# homelab

Automação de infraestrutura para laboratório homelab — Kubernetes, serviços e devops em hardware local.

---

## Hardware

| Máquina | Modelo | SO | Função |
|---|---|---|---|
| Servidor | Lenovo ThinkPad T14 | Fedora Server | Nó do cluster k3d |
| Principal | Samsung Galaxy Book 360 | Fedora 43 / Hyprland | Controle remoto via kubectl |

> O servidor foi configurado como headless via [dotstrap/bootstrap/headless.sh](https://github.com/jbrunojardim/dotfile-bootstrap/blob/joseph/bootstrap/headless.sh).

---

## k3d — Cluster Kubernetes local

### Pré-requisitos (servidor)

- Fedora Server instalado e configurado como headless
- Acesso SSH funcionando
- `dotstrap/bootstrap/headless.sh` executado (swap desabilitado, SELinux permissive, firewalld desabilitado)

### Etapa 1 — Instalar dependências no servidor

```bash
# Via SSH no servidor:
bash tools/install_k3d.sh
```

Instala:
- Docker Engine (via [`dotstrap/tools/docker.sh`](https://github.com/jbrunojardim/dotfile-bootstrap/blob/joseph/tools/docker.sh))
- k3d (via script oficial)
- kubectl (versão estável mais recente via `dl.k8s.io`)

### Etapa 2 — Criar o cluster

```bash
# Via SSH no servidor:
bash k3d/cluster.sh create
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

---

## Ciclo de vida do cluster

```bash
bash k3d/cluster.sh create      # cria o cluster
bash k3d/cluster.sh status      # nodes + pods do sistema
bash k3d/cluster.sh kubeconfig  # exibe kubeconfig com IP da interface cabeada
bash k3d/cluster.sh delete      # destrói o cluster
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
    └── kubeconfig.sh     # (em evolução) configuração do kubectl no laptop principal
```

---

## Crescimento planejado

```
homelab/
├── tools/         # ← implementado
├── k3d/           # ← implementado
├── manifests/     # yamls de aplicações
├── helm/          # charts e values
└── terraform/     # infra-as-code
```

---

## Requisitos

- Fedora/RHEL (usa `dnf`)
- Acesso `sudo` no servidor
- `curl`, `bash`, `ssh` disponíveis
