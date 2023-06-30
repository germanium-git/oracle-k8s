output "vm" {
  value = oci_core_instance.vm
}

output "vm_public_ip" {
  value = {
    for k, vm in oci_core_instance.vm : k => vm.public_ip
  }
}
