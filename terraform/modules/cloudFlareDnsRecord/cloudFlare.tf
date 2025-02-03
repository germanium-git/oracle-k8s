# Create A record in Cloudflare DNS for the compute node
resource "cloudflare_record" "a_record" {
  for_each = var.vm_public_ip

  zone_id = var.cloudflare_zone_id
  name    = each.key
  content = each.value
  type    = "A"
}
