# Create A record in Cloudflare DNS for the compute node
resource "cloudflare_record" "a_record" {
  for_each = var.vm_public_ip

  zone_id = data.cloudflare_zone.zone.id
  name    = each.key
  value   = each.value
  type    = "A"
}

data "cloudflare_zone" "zone" {
  name = var.cloudflare_zone_name
}
