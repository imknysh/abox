# ==========================================
# Bootstrap Flux Operator
# ==========================================
resource "helm_release" "flux_operator" {
  depends_on = [kind_cluster.this]

  name             = "flux-operator"
  namespace        = "flux-system"
  repository       = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart            = "flux-operator"
  create_namespace = true
}

# ==========================================
# Bootstrap Flux Instance
# ==========================================
resource "helm_release" "flux_instance" {
  depends_on = [helm_release.flux_operator]

  name       = "flux-instance"
  namespace  = "flux-system"
  repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart      = "flux-instance"
  wait       = true

  set {
    name  = "distribution.version"
    value = "=2.x"
  }
}

# ==========================================
# Bootstrap Flux ResourceSetInputProvider
# ==========================================
resource "kubectl_manifest" "rsip" {
  depends_on = [helm_release.flux_instance]

  yaml_body = <<-YAML
    apiVersion: fluxcd.controlplane.io/v1
    kind: ResourceSetInputProvider
    metadata:
      name: releases-image
      namespace: flux-system
      annotations:
        fluxcd.controlplane.io/reconcileEvery: 5m
    spec:
      type: OCIArtifactTag
      url: ${var.oci_registry}/releases
      filter:
        includeTag: "^\\d+\\.\\d+\\.\\d+$"
        limit: 1
      defaultValues:
        tag: "${var.releases_version}"
  YAML
}

# ==========================================
# Bootstrap Flux ResourceSet
# ==========================================
resource "kubectl_manifest" "rset" {
  depends_on = [kubectl_manifest.rsip]

  yaml_body = <<-YAML
    apiVersion: fluxcd.controlplane.io/v1
    kind: ResourceSet
    metadata:
      name: releases
      namespace: flux-system
    spec:
      inputsFrom:
      - kind: ResourceSetInputProvider
        name: releases-image
      resources:
      - apiVersion: source.toolkit.fluxcd.io/v1
        kind: OCIRepository
        metadata:
          name: releases
          namespace: flux-system
        spec:
          interval: 2m
          url: ${var.oci_registry}/releases
          ref:
            tag: "<< inputs.tag >>"
      - apiVersion: kustomize.toolkit.fluxcd.io/v1
        kind: Kustomization
        metadata:
          name: releases-crds
          namespace: flux-system
        spec:
          interval: 2m
          sourceRef:
            kind: OCIRepository
            name: releases
          path: ./crds
          prune: true
          wait: true
      - apiVersion: kustomize.toolkit.fluxcd.io/v1
        kind: Kustomization
        metadata:
          name: releases
          namespace: flux-system
        spec:
          interval: 2m
          dependsOn:
            - name: releases-crds
          sourceRef:
            kind: OCIRepository
            name: releases
          path: ./
          prune: true
          wait: true
          retryInterval: 30s
  YAML
}
