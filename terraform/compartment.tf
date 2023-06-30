resource "oci_identity_compartment" "k8s" {
  provider       = hashi-oci
  compartment_id = var.TENANCY_OCID
  description    = "k8s cluster"
  name           = "k8s"
}