# ==========================================
# Bootstrap Agentgateway
# ==========================================
resource "helm_release" "agentgateway_crds" {
  depends_on       = [kind_cluster.this]
  name             = "agentgateway-crds"
  namespace        = "agentgateway-system"
  repository       = "oci://ghcr.io/kgateway-dev/charts"
  chart            = "kgateway-crds"
  version          = "2.3.0-main"
  create_namespace = true
}

resource "helm_release" "agentgateway" {
  depends_on       = [helm_release.agentgateway_crds]
  name             = "agentgateway"
  namespace        = "agentgateway-system"
  repository       = "oci://ghcr.io/kgateway-dev/charts"
  chart            = "kgateway"
  version          = "2.3.0-main"
  create_namespace = true
}
