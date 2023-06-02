resource "oci_core_vcn" "vcn" {
    for_each = var.vcn_config

    display_name   = each.value.name
    cidr_block     = each.value.vcn_cidr
    compartment_id = var.compartment_id
}


resource "oci_core_subnet" "subnet" {
    for_each = var.subnet_config

    cidr_block        = cidrsubnet(var.vcn_config[each.value.vcn_key].vcn_cidr, 8, each.value.cidr_id)
    display_name      = each.value.name
    compartment_id    = var.compartment_id
    vcn_id            = oci_core_vcn.vcn[each.value.vcn_key].id

    security_list_ids = [oci_core_vcn.vcn[each.value.vcn_key].default_security_list_id]
    route_table_id    = oci_core_route_table.rt[each.value.vcn_key].id
}


resource oci_core_internet_gateway "igw" {
    for_each = var.vcn_config
    
    compartment_id = var.compartment_id
    vcn_id = oci_core_vcn.vcn[each.key].id
    display_name = "${each.value.name}-igw"

    defined_tags = {}
    enabled      = "true"
    freeform_tags = {}
}


resource oci_core_route_table "rt" {
    for_each = var.vcn_config

    compartment_id = var.compartment_id
    display_name = "Default RT for ${each.value.name}"
    vcn_id = oci_core_vcn.vcn[each.key].id

    route_rules {
        cidr_block          = "0.0.0.0/0"
        network_entity_id   = oci_core_internet_gateway.igw[each.key].id
    }

    defined_tags = {}
    freeform_tags = {}
}


resource "oci_core_network_security_group" "nsg" {
    for_each        = var.vcn_config
    
    display_name    =  "${each.value.name}-nsg"
    vcn_id          = oci_core_vcn.vcn[each.key].id
    compartment_id  = var.compartment_id
}

# Allows only TCP protocol
resource "oci_core_network_security_group_security_rule" "nsg_rule" {
    for_each = var.nsg_rules

    network_security_group_id = oci_core_network_security_group.nsg[each.value.vcn_key].id
    description               = each.value.description
    source_type               = "CIDR_BLOCK"
    source                    = each.value.source
    protocol                  = "6"
    direction                 = "INGRESS"
    stateless                 = false
    tcp_options {
        destination_port_range {
            max = each.value.dst_port_range_max
            min = each.value.dst_port_range_min
        }
    }
}
