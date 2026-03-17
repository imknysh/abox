resource "kubectl_manifest" "test" {
    depends_on = [kind_cluster.this]

    yaml_body = <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: ai-providers-api-keys
  annotations:
    replicator.v1.mittwald.de/replicate-to: "kagent, agentgateway-system"
data:
  GOOGLE_API_KEY: "${base64encode(var.google_api_key)}"
  OPENAI_API_KEY: "${base64encode(var.openai_api_key)}"
  BEDROCK_API_KEY: "${base64encode(var.bedrock_api_key)}"
YAML
}