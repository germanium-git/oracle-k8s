variable "vcn_config" {
  type = map(object({
    name     = string
    vcn_cidr = string
  }))
}

variable "subnet_config" {
  type = map(object({
    name    = string
    cidr_id = number
    vcn_key = string
  }))
}


# Protocol - Specify either all or an IPv4 protocol number as defined in Protocol Numbers
# Options are supported only for ICMP ("1"), TCP ("6"), UDP ("17"), and ICMPv6 ("58").

variable "nsg_rules" {
  type = map(object({
    vcn_key            = string
    description        = string
    source             = string
    dst_port_range_min = number
    dst_port_range_max = number
  }))
}


variable "compartment_id" {
  description = "Compartment Id"
  type        = string
}
