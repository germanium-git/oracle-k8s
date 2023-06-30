terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
      version = "5.2.1"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "4.9.0"
    }
  }
  backend "remote" {
    # The name of your Terraform Cloud organization.
    organization = "mygermanium"
    workspaces {
      name = "oracle-k8s"
    }
  }
  required_version = "1.4.6"
}

provider "oci" {
  region       = "eu-frankfurt-1"
  tenancy_ocid = var.TENANCY_OCID
  user_ocid    = var.USER_OCID
  fingerprint  = var.FINGERPRINT
  private_key  = var.PRIVATE_KEY
}

provider "cloudflare" {
  api_token = var.CLOUDFLARE_API_TOKEN
}
