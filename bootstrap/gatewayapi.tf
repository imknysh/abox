# ==========================================
# Bootstrap Agentgateway
# ==========================================
resource "helm_release" "agentgateway_crds" {
  depends_on       = [kind_cluster.this]
  name             = "agentgateway-crds"
  namespace        = "agentgateway-system"
  repository       = "oci://ghcr.io/kgateway-dev/charts"
  chart            = "agentgateway-crds"
  version          = "v2.2.1"
  create_namespace = true
}

resource "helm_release" "agentgateway" {
  depends_on       = [helm_release.agentgateway_crds]
  name             = "agentgateway"
  namespace        = "agentgateway-system"
  repository       = "oci://ghcr.io/kgateway-dev/charts"
  chart            = "agentgateway"
  version          = "v2.2.1"
  create_namespace = true
}
