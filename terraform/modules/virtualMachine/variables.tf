variable "vm_config" {
  type = map(object({
    shape     = string
    cpu_count = number
    memory_gb = number
    image_id  = string
    subnet_id = string
    nsg_ids   = set(string)
    ssh_key   = string
    zone      = number
  }))
}


variable "compartment_id" {
  description = "Compartment Id"
  type        = string
}
