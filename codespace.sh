#!/bin/bash
set -euo pipefail

LOG=/tmp/setup.log
exec > >(tee -a "$LOG") 2>&1

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "=== k8sdiy-env setup start ==="

# Install OpenTofu
log "Installing OpenTofu..."
curl -fsSL https://get.opentofu.org/install-opentofu.sh | sh -s -- --install-method standalone
log "OpenTofu installed"

# Install K9s
log "Installing K9s..."
curl -sS https://webi.sh/k9s | sh
log "K9s installed"

# Add aliases to bashrc
cat >> ~/.bashrc <<'EOF'

# k8sdiy-env aliases
alias kk="EDITOR='code --wait' k9s"
alias tf=tofu
alias k=kubectl
EOF

# Initialize Tofu
log "Running tofu init..."
cd bootstrap
tofu init
log "tofu init done"

log "Running tofu apply..."
tofu apply -auto-approve
log "tofu apply done"

export KUBECONFIG=~/.kube/config

cd ..

# Install cloud-provider-kind (LoadBalancer support)
log "Installing cloud-provider-kind..."
ARCH=$(dpkg --print-architecture)
wget -q "https://github.com/kubernetes-sigs/cloud-provider-kind/releases/download/v0.6.0/cloud-provider-kind_0.6.0_linux_${ARCH}.tar.gz" \
  -O /tmp/cloud-provider-kind.tar.gz
tar -xzf /tmp/cloud-provider-kind.tar.gz -C /usr/local/bin cloud-provider-kind
rm /tmp/cloud-provider-kind.tar.gz
nohup cloud-provider-kind > /tmp/cloud-provider-kind.log 2>&1 &
log "cloud-provider-kind started (pid $!)"

# Apply GatewayClass + Gateway
log "Applying gatewayapi/Gateway.yaml..."
kubectl apply --kubeconfig /home/codespace/.kube/config -f gatewayapi/Gateway.yaml


helm install kagent-crd oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds --create-namespace -n kagent
helm install kagent oci://ghcr.io/kagent-dev/kagent/helm/kagent --create-namespace  -n kagent --set querydoc.enabled=0,cilium-policy-agent.enabled=0,cilium-manager-agent.enabled=0,cilium-debug-agent.enabled=0,promql-agent.enabled=0,istio-agent.enabled=0,istio-policy-agent.enabled=0,istio-manager-agent.enabled=0

log "=== setup complete ==="
