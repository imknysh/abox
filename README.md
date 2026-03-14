# a-box

Ephemeral PR preview environments on a local Kubernetes cluster using KinD, Flux CD, and Agentgateway.

## Stack

- **KinD** — local Kubernetes cluster (1 control-plane + 2 workers)
- **Flux CD 2.x** — GitOps operator (Flux Operator + FluxInstance)
- **Agentgateway v2.2.1** — Kubernetes Gateway API implementation
- **cloud-provider-kind** — LoadBalancer support for KinD

## Quickstart (GitHub Codespaces)

1. Fork or open this repo in a Codespace
2. Set the `GITHUB_TOKEN` secret in your [Codespace secrets](https://github.com/settings/codespaces)
3. Create codespace — `postCreateCommand` runs `.devcontainer/setup.sh` automatically

```bash
gh codespace create --repo den-vasyliev/a-box --machine basicLinux32gb
```

The setup script installs OpenTofu and K9s, runs `tofu apply` to provision the KinD cluster, bootstraps Flux, and applies the gateway manifests.

## Manual Setup

```bash
# Install OpenTofu
curl -fsSL https://get.opentofu.org/install-opentofu.sh | sh -s -- --install-method standalone

# Install K9s
curl -sS https://webi.sh/k9s | sh

# Provision cluster + bootstrap Flux
cd bootstrap
export TF_VAR_github_token="<your-token>"
tofu init
tofu apply
```

## Directory Layout

| Directory | Purpose |
|-----------|---------|
| `bootstrap/` | OpenTofu: KinD cluster + Flux Operator + Agentgateway manifests |
| `gatewayapi/` | Flux HelmReleases for Gateway API CRDs + Agentgateway + GatewayClass |
| `release/` | HelmRelease for production app |
| `preview/` | Flux ResourceSet manifests for dynamic PR environments |
| `.devcontainer/` | GitHub Codespaces configuration |

## How it works

```
tofu apply
  → KinD cluster created
  → Flux Operator + FluxInstance bootstrapped (syncs this repo)
    → gatewayapi/ applied:
        - Gateway API CRDs (kubernetes-sigs/gateway-api v1.4.0)
        - agentgateway-crds HelmRelease
        - agentgateway HelmRelease
        - GatewayClass + Gateway
    → preview/ applied:
        - ResourceSetInputProvider polls GitHub PRs
        - ResourceSet creates GitRepository + HelmRelease + HTTPRoute per PR
```

## Verify

```bash
# Check Flux resources
flux get all

# Check gateway
kubectl get gateway,httproute -A
kubectl get gatewayclass agentgateway

# Get LoadBalancer IP
kubectl get svc -n agentgateway-system

# Test
curl $LB_IP -HHost:kbot.example.com
curl $LB_IP/pr-40 -HHost:kbot.example.com
```
