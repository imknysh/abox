variable "cluster_name" {
  description = "Cluster Name"
  type        = string
  default     = "abox"
}

variable "oci_registry" {
  description = "OCI registry base URL"
  type        = string
  default     = "oci://ghcr.io/imknysh/abox"
}

variable "releases_version" {
  description = "Default tag for releases OCI artifact bootstrap"
  type        = string
  default     = "0.1.0"
}

variable "google_api_key" {
  default = ""
  description = "Gemini API Key"
}

variable "openai_api_key" {
  default = ""
  description = "OpenAI API Key"
}

variable "bedrock_api_key" {
  default = ""
  description = "Bedrock API Key"
}