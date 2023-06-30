variable "TENANCY_OCID" {
  description = "OCI tenancy OCID"
  type        = string
}

variable "USER_OCID" {
  description = "OCI user OCID"
  type        = string
}

variable "FINGERPRINT" {
  description = "OCI API key fingerprint"
  type        = string
}

variable "PRIVATE_KEY" {
  description = "OCI API key private key"
  type        = string
}

variable "COMPARTMENT_OCID" {
  description = "Test Compartment for GitHub Action"
  type        = string
}

variable "vcn_cidr" {
  description = "CIDR range for VCN"
  type        = string
  default     = "10.1.0.0/16"
}

# The value is is stored in TF Cloud as a sensitive variable
variable "CLOUDFLARE_API_TOKEN" {
  description = "A valid Cloudflare token with permission to create DNS records"
  type        = string
}
