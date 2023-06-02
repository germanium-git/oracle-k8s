output "vm_public_ip" {
  value = {
    for k, vm in module.virtual_machine.vm : k => vm.public_ip
  }
}
