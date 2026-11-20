# oracle-k8s

Terraform for small virtual machines in Oracle Cloud (OCI, Always Free tier),
with DNS records in Cloudflare.

## What it creates

| Resource | Details |
|:---------|:--------|
| VMs | `uran`, `neptun`: `VM.Standard.E2.1.Micro`, Ubuntu 24.04, 50 GB boot + 50 GB block volume each |
| Network | VCN `vcn_01` (10.1.0.0/16), `subnet1`, NSG allowing 22, 80, 1022, 8086 (InfluxDB), 9443 (Portainer) |
| DNS | Cloudflare A record per VM (`uran`, `neptun`) |

Everything is in the **root compartment**, region **eu-frankfurt-1**, AD-3.
In the OCI console: *Compute → Instances*, compartment = tenancy (root).

Despite the repo name there is no Kubernetes cluster yet. The ARM
`control1`/`control2` nodes are commented out in `terraform/main.tf`.

## Layout

```
terraform/            root module (state in Terraform Cloud: mygermanium/oracle-k8s)
  modules/virtualNetwork/      VCN, subnet, internet gateway, NSG
  modules/virtualMachine/      instances + block volumes
  modules/cloudFlareDnsRecord/ A records
.github/workflows/    CI (see below)
Influx.md             manual setup of Docker, Portainer and InfluxDB on a VM
```

## Workflow

1. Open a PR against `main`; **plan** runs and posts the plan to the PR.
2. Approve the PR review; **apply** runs.
3. **destroy** is manual only (`workflow_dispatch`).

The VM image is resolved to the newest Ubuntu 24.04 but changes are ignored
for existing instances. To rebuild one on a newer image:
`terraform apply -replace='module.virtual_machine.oci_core_instance.vm["uran"]'`.

## Secrets (GitHub Actions)

| Secret | Purpose |
|:-------|:--------|
| `TF_TENANCY_OCID`, `TF_USER_OCID`, `TF_COMPARTMENT_OCID` | OCI identity |
| `TF_PRIVATE_KEY`, `TF_FINGERPRINT` | OCI API key |
| `TF_API_TOKEN` | Terraform Cloud |
| `TF_CLOUDFLARE_API_TOKEN` | Cloudflare token (DNS Write + Zone Read); create/rotate with `scripts/cf-token.sh` |
| `TF_CLOUDFLARE_ZONE_ID` | Cloudflare zone for the A records |
| `GH_TOKEN` | PAT so the pipeline can comment on PRs (expires Dec 31 2025) |
