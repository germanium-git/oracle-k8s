terraform {
   required_providers {
      hashi-oci = {
         source = "hashicorp/oci"
      }
      oracle-oci = {
         source = "oracle/oci"
      }
   }
   backend "remote" {
   # The name of your Terraform Cloud organization.
      organization = "mygermanium"

    # The name of the Terraform Cloud workspace to store Terraform state files in.
      workspaces {
         name = "oracle-k8s"
      }
   }
}

provider "oracle-oci" {
   region       = "eu-frankfurt-1"
   tenancy_ocid = var.TENANCY_OCID
   user_ocid    = var.USER_OCID
   fingerprint  = var.FINGERPRINT
   private_key  = var.PRIVATE_KEY
}

provider "hashi-oci" {
   region       = "eu-frankfurt-1"
   tenancy_ocid = var.TENANCY_OCID
   user_ocid    = var.USER_OCID
   fingerprint  = var.FINGERPRINT
   private_key  = var.PRIVATE_KEY
}