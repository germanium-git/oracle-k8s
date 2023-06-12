data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

resource "oci_core_instance" "vm" {
  for_each = var.vm_config

  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[each.value.zone].name
  compartment_id      = var.compartment_id
  shape               = each.value.shape

  source_details {
    source_id   = each.value.image_id
    source_type = "image"
  }

  display_name = each.key

  shape_config {
    ocpus         = each.value.cpu_count
    memory_in_gbs = each.value.memory_gb
  }

  create_vnic_details {
    assign_public_ip = true
    subnet_id        = each.value.subnet_id
    nsg_ids          = each.value.nsg_ids
  }

  metadata = {
    ssh_authorized_keys = each.value.ssh_key
  }

  preserve_boot_volume = false
}
