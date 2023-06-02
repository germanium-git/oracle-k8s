#############################################
#               Virtual Network             #
#############################################

module "virtual_network" {
    source = "./modules/virtualNetwork"


    providers = {
      oci = oci.frankfurt1
    }

    vcn_config = {
        vcn1 = {
            name        = "vcn_01"
            vcn_cidr    = "10.1.0.0/16"
        }
    }

    subnet_config = {
        subnet1 = {
            name = "subnet1"
            cidr_id = 1
            vcn_key = "vcn1"
        }
    }

    compartment_id = oci_identity_compartment.k8s.compartment_id

    nsg_rules = {
        rule1 = {
            vcn_key       = "vcn1"
            description   = "test rule"
            source        = "10.20.30.40"
            protocol      = "6"
            tcp_options   = [{
                dst_port_range_min  = 100
                dst_port_range_max  = 200
            }]
        }
    }
}