#############################################
#               Virtual Network             #
#############################################

module "virtual_network" {
  source = "./modules/virtualNetwork"

  vcn_config = {
    vcn1 = {
      name     = "vcn_01"
      vcn_cidr = "10.1.0.0/16"
    }
  }

  subnet_config = {
    subnet1 = {
      name    = "subnet1"
      cidr_id = 1
      vcn_key = "vcn1"
    }
  }

  compartment_id = oci_identity_compartment.k8s.compartment_id

  nsg_rules = {
    rule1 = {
      vcn_key            = "vcn1"
      description        = "ssh"
      source             = "185.230.172.74/32"
      protocol           = "6"
      dst_port_range_min = 22
      dst_port_range_max = 22
    }
    rule2 = {
      vcn_key            = "vcn1"
      description        = "influxdb"
      source             = "185.230.172.74/32"
      protocol           = "6"
      dst_port_range_min = 8086
      dst_port_range_max = 8086
    }
    rule3 = {
      vcn_key            = "vcn1"
      description        = "portainer"
      source             = "185.230.172.74/32"
      protocol           = "6"
      dst_port_range_min = 9000
      dst_port_range_max = 9000
    }
  }
}

#############################################
#               Virtual Machines            #
#############################################

# Images in Frankfurt
# Canonical-Ubuntu-22.04-2023.04.19-0 ocid1.image.oc1.eu-frankfurt-1.aaaaaaaazjh7dx5267q4cpzeg7fgxhyluqq42usze6ahijkrs6bnwg2d2mdq

# Oracle-Linux-8.6-aarch64-2022.05.30-0 ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaxp2zqotv37r4zycmwfqywcujsh4scenphjjs5w2ozakmidg3vs6q

module "virtual_machine" {
  source = "./modules/virtualMachine"

  compartment_id = oci_identity_compartment.k8s.compartment_id
  vm_config = {
    /*
        control1 = {
            shape       = "VM.Standard.A1.Flex"
            cpu_count   = 2
            memory_gb   = 12
            image_id    = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaxp2zqotv37r4zycmwfqywcujsh4scenphjjs5w2ozakmidg3vs6q"
            subnet_id   = module.virtual_network.subnet["subnet1"].id
            nsg_ids     = toset([module.virtual_network.nsg["vcn1"].id])
            ssh_key     = file("sshkey/petr.nemec@gmx.com_2023-05-21T20_18_59.854Z_putty.pub")
            zone        = 2
        }
        control2 = {
            shape       = "VM.Standard.A1.Flex"
            cpu_count   = 2
            memory_gb   = 12
            image_id    = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaxp2zqotv37r4zycmwfqywcujsh4scenphjjs5w2ozakmidg3vs6q"
            subnet_id   = module.virtual_network.subnet["subnet1"].id
            nsg_ids     = toset([module.virtual_network.nsg["vcn1"].id])
            ssh_key     = file("sshkey/petr.nemec@gmx.com_2023-05-21T20_18_59.854Z_putty.pub")
            zone        = 2
        }
        */
    worker1 = {
      shape      = "VM.Standard.E2.1.Micro"
      cpu_count  = 1
      memory_gb  = 1
      image_id   = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaazjh7dx5267q4cpzeg7fgxhyluqq42usze6ahijkrs6bnwg2d2mdq"
      subnet_id  = module.virtual_network.subnet["subnet1"].id
      nsg_ids    = toset([module.virtual_network.nsg["vcn1"].id])
      ssh_key    = file("sshkey/petr.nemec@gmx.com_2023-05-21T20_18_59.854Z_putty.pub")
      zone       = 2
      storage_gb = 50
    }
    artemis = {
      shape      = "VM.Standard.E2.1.Micro"
      cpu_count  = 1
      memory_gb  = 1
      image_id   = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaazjh7dx5267q4cpzeg7fgxhyluqq42usze6ahijkrs6bnwg2d2mdq"
      subnet_id  = module.virtual_network.subnet["subnet1"].id
      nsg_ids    = toset([module.virtual_network.nsg["vcn1"].id])
      ssh_key    = file("sshkey/petr.nemec@gmx.com_2023-05-21T20_18_59.854Z_putty.pub")
      zone       = 2
      storage_gb = 50
    }
  }
}


module "cloudflare_dns" {
  source = "./modules/cloudFlareDnsRecord"

  vm_public_ip         = module.virtual_machine.vm_public_ip
  cloudflare_zone_name = "germanium.cz"
}