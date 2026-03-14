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

# Apply — requires GITHUB_TOKEN codespace secret
if [[ -z "${TF_VAR_github_token:-}" ]]; then
  log "ERROR: GITHUB_TOKEN secret not set — cannot provision cluster"
  log "Set it at: github.com/settings/codespaces -> Secrets"
  exit 1
fi

log "Running tofu apply..."
tofu apply -auto-approve
log "tofu apply done"

cd ..

# Install Gateway API CRDs (required by agentgateway)
log "Installing Gateway API CRDs..."
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml

# Install GatewayClass + Gateway
log "Applying gatewayapi/..."
kubectl apply -f gatewayapi/

# Install cloud-provider-kind (LoadBalancer support)
log "Installing cloud-provider-kind..."
ARCH=$(dpkg --print-architecture)
wget -q "https://github.com/kubernetes-sigs/cloud-provider-kind/releases/download/v0.6.0/cloud-provider-kind_0.6.0_linux_${ARCH}.tar.gz" \
  -O /tmp/cloud-provider-kind.tar.gz
tar -xzf /tmp/cloud-provider-kind.tar.gz -C /usr/local/bin cloud-provider-kind
rm /tmp/cloud-provider-kind.tar.gz
nohup cloud-provider-kind > /tmp/cloud-provider-kind.log 2>&1 &
log "cloud-provider-kind started (pid $!)"

# Install production HelmRelease
log "Applying release/..."
kubectl apply -f release/

# Wait for LoadBalancer IP
log "Waiting for LoadBalancer IP..."
for i in $(seq 1 30); do
  LB_IP=$(kubectl get svc -n agentgateway-system \
    -o jsonpath='{.items[?(@.spec.type=="LoadBalancer")].status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
  if [[ -n "$LB_IP" ]]; then
    log "LoadBalancer IP: $LB_IP"
    break
  fi
  log "Attempt $i/30 — not ready yet, retrying in 5s..."
  sleep 5
done

# Install preview ResourceSet manifests
log "Applying preview/..."
kubectl apply -f preview/

# Create GitHub auth secret for ResourceSetInputProvider
log "Creating github-auth secret in app-preview..."
kubectl create secret generic github-auth \
  --from-literal=username=git \
  --from-literal=password="${TF_VAR_github_token}" \
  -n app-preview \
  --dry-run=client -o yaml | kubectl apply -f -

log "=== setup complete ==="
