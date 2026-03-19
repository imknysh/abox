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

variable "git_repository" {
  description = "Git repository"
  type        = string
  default     = "https://github.com/imknysh/abox"
}

variable "releases_version" {
  description = "Default tag for releases OCI artifact bootstrap"
  type        = string
  default     = "0.1.0"
}

variable "GOOGLE_API_KEY" {
  default = ""
  description = "Gemini API Key"
}

variable "OPENAI_API_KEY" {
  default = ""
  description = "OpenAI API Key"
}

variable "BEDROCK_API_KEY" {
  default = ""
  description = "Bedrock API Key"
}