variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "kms_key_arn" {
  description = "ARN of the KMS CMK (from the kms module) used to encrypt these secrets"
  type        = string
}

variable "recovery_window_in_days" {
  description = "Number of days AWS waits before permanently deleting a secret (0 disables recovery and deletes immediately)"
  type        = number
  default     = 7
}

variable "secrets" {
  description = <<-EOT
    Map of secrets to create. Key is a short logical name used to derive the secret name
    (tradecore-<environment>-<key>). Set secret_string for a plain-text value, or
    secret_string_map for a value that should be marshalled to JSON. Leave both null to
    create the secret's metadata only and populate the value out-of-band later.
  EOT
  type = map(object({
    description       = optional(string, "")
    secret_string     = optional(string)
    secret_string_map = optional(map(string))
    additional_tags   = optional(map(string), {})
  }))
  default = {}
}

variable "allowed_principal_arns" {
  description = "IAM role/user ARNs (e.g. the ECS task role) permitted to read the secrets via resource policy. Leave empty to rely solely on IAM policy grants elsewhere."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags applied to all resources in this module"
  type        = map(string)
  default     = {}
}

