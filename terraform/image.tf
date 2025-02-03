data "oci_core_images" "ubuntu_e2_1_micro_images" {
  #compartment_id   = oci_identity_compartment.k8s.compartment_id
  compartment_id   = var.TENANCY_OCID
  operating_system = "Canonical Ubuntu" # Filter only Ubuntu images
  shape            = "VM.Standard.E2.1.Micro"
}

# Get the latest Ubuntu image by sorting images by version
locals {
  images       = [for img in data.oci_core_images.ubuntu_e2_1_micro_images.images : img if img.operating_system_version == "24.04"]
  latest_image = length(local.images) > 0 ? local.images[0].id : null
}
