resource "oci_core_volume" "volume" {
  for_each = { for k, v in var.vm_config : k => v if(v.storage_gb > 0) }
  #for_each = range(length(var.delete_retention_policy_days) > 0 ? 1 : 0)
  #for_each = try(var.value, [])
  #Required
  compartment_id = var.compartment_id

  #Optional
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[each.value.zone].name
  display_name        = "${each.key}_${each.value.storage_gb}GB"
  size_in_gbs         = each.value.storage_gb
}


resource "oci_core_volume_attachment" "volume_attachment" {
  for_each = { for k, v in var.vm_config : k => v if(v.storage_gb > 0) }
  #Required
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.vm[each.key].id
  volume_id       = oci_core_volume.volume[each.key].id
}
