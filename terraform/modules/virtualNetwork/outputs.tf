output "vcn" {
  value = oci_core_vcn.vcn
}

output "subnet" {
  value = oci_core_subnet.subnet
}

output "nsg" {
  value = oci_core_network_security_group.nsg
}