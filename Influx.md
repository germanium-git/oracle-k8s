# InfluxDB


## Install Docker
```
# Install docker
# https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
# Update the apt package index and install packages to allow apt to use a repository over HTTPS:
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg

# Add Docker’s official GPG key:
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Use the following command to set up the repository:
echo   "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
```

## Install Portainer

```
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9443:9443 \
    --name portainer \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data portainer/portainer-ce:latest


# Or with password
docker run -d -p 9000:9000 -p 8000:8000 -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer --admin-password $2y$05$b0DgtG94LtpeuqEKHRYYreEf2rqBI5.4Rin.38.ENaAlL/7TeKX2q
```

## Install ACME

```
sudo apt-get install socat
curl https://get.acme.sh | sh

# Export single variable for the CloudFlare DNS challenge to work #
export CF_Token="Your_Cloudflare_DNS_API_Key_Goes_here"

.acme.sh/acme.sh --register-account -m petr.nemec@gmx.com
.acme.sh/acme.sh --set-default-ca --server letsencrypt
.acme.sh/acme.sh --issue --dns dns_cf -d germanium.cz -d neptun.germanium.cz
```


Example:
```
ubuntu@neptun:~$ .acme.sh/acme.sh --issue --dns dns_cf -d germanium.cz -d neptun.germanium.cz
[Tue Feb 27 15:54:30 UTC 2024] Using CA: https://acme-v02.api.letsencrypt.org/directory
[Tue Feb 27 15:54:30 UTC 2024] Multi domain='DNS:germanium.cz,DNS:neptun.germanium.cz'
[Tue Feb 27 15:54:33 UTC 2024] Getting webroot for domain='germanium.cz'
[Tue Feb 27 15:54:33 UTC 2024] Getting webroot for domain='neptun.germanium.cz'
[Tue Feb 27 15:54:34 UTC 2024] Adding txt value: SGmaBaw1nf2uvMBJP16TXDLFgN0K3oVfDWxwa9sVyDM for domain:  _acme-challenge.neptun.germanium.cz
[Tue Feb 27 15:54:38 UTC 2024] Adding record
[Tue Feb 27 15:54:38 UTC 2024] Added, OK
[Tue Feb 27 15:54:38 UTC 2024] The txt record is added: Success.
[Tue Feb 27 15:54:38 UTC 2024] Let's check each DNS record now. Sleep 20 seconds first.
[Tue Feb 27 15:54:59 UTC 2024] You can use '--dnssleep' to disable public dns checks.
[Tue Feb 27 15:54:59 UTC 2024] See: https://github.com/acmesh-official/acme.sh/wiki/dnscheck
[Tue Feb 27 15:54:59 UTC 2024] Checking neptun.germanium.cz for _acme-challenge.neptun.germanium.cz
[Tue Feb 27 15:55:00 UTC 2024] Domain neptun.germanium.cz '_acme-challenge.neptun.germanium.cz' success.
[Tue Feb 27 15:55:00 UTC 2024] All success, let's return
[Tue Feb 27 15:55:00 UTC 2024] germanium.cz is already verified, skip dns-01.
[Tue Feb 27 15:55:00 UTC 2024] Verifying: neptun.germanium.cz
[Tue Feb 27 15:55:01 UTC 2024] Pending, The CA is processing your order, please just wait. (1/30)
[Tue Feb 27 15:55:05 UTC 2024] Success
[Tue Feb 27 15:55:05 UTC 2024] Removing DNS records.
[Tue Feb 27 15:55:05 UTC 2024] Removing txt: SGmaBaw1nf2uvMBJP16TXDLFgN0K3oVfDWxwa9sVyDM for domain: _acme-challenge.neptun.germanium.cz
[Tue Feb 27 15:55:09 UTC 2024] Removed: Success
[Tue Feb 27 15:55:09 UTC 2024] Verify finished, start to sign.
[Tue Feb 27 15:55:09 UTC 2024] Lets finalize the order.
[Tue Feb 27 15:55:09 UTC 2024] Le_OrderFinalize='https://acme-v02.api.letsencrypt.org/acme/finalize/1591302827/247941023417'
[Tue Feb 27 15:55:11 UTC 2024] Downloading cert.
[Tue Feb 27 15:55:11 UTC 2024] Le_LinkCert='https://acme-v02.api.letsencrypt.org/acme/cert/0470138b6ac4f7505fd0acca8c00526b1663'
[Tue Feb 27 15:55:12 UTC 2024] Cert success.
-----BEGIN CERTIFICATE-----
MIIELzCCAxegAwIBAgISBHATi2rE91Bf0KzKjABSaxZjMA0GCSqGSIb3DQEBCwUA
MDIxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MQswCQYDVQQD
EwJSMzAeFw0yNDAyMjcxNDU1MTBaFw0yNDA1MjcxNDU1MDlaMBcxFTATBgNVBAMT
DGdlcm1hbml1bS5jejBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABN6WtOk+UAHX
uG0i4eOgk5H2H6iaHPffY68TUK2U6T9NV/lQeiBWtzyZCYsHb5+XCV+JFmIoQimu
fd8AYsbojzWjggIjMIICHzAOBgNVHQ8BAf8EBAMCB4AwHQYDVR0lBBYwFAYIKwYB
BQUHAwEGCCsGAQUFBwMCMAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYEFJhirdpKhyQP
o1J8SzvCbk5BrfMjMB8GA1UdIwQYMBaAFBQusxe3WFbLrlAJQOYfr52LFMLGMFUG
CCsGAQUFBwEBBEkwRzAhBggrBgEFBQcwAYYVaHR0cDovL3IzLm8ubGVuY3Iub3Jn
MCIGCCsGAQUFBzAChhZodHRwOi8vcjMuaS5sZW5jci5vcmcvMCwGA1UdEQQlMCOC
DGdlcm1hbml1bS5jeoITbmVwdHVuLmdlcm1hbml1bS5jejATBgNVHSAEDDAKMAgG
BmeBDAECATCCAQQGCisGAQQB1nkCBAIEgfUEgfIA8AB2ADtTd3U+LbmAToswWwb+
QDtn2E/D9Me9AA0tcm/h+tQXAAABjetG7q0AAAQDAEcwRQIhAMAhvgPLYEfoLcqe
0JfMeRd6dj8/P/zaspxURdG269W4AiAeOj0VxblUij+PG+LHX+jYLzSPKlVYSB8h
7UWhApjN5gB2AO7N0GTV2xrOxVy3nbTNE6Iyh0Z8vOzew1FIWUZxH7WbAAABjetG
7rgAAAQDAEcwRQIhAMcCWRie29hiPPzGph7BZCwwRyVgcRyJNKC+z+2HDIYGAiAM
DJ33i8T+qsuPl9vbbJFbsxOlpN8AuiyPQyepHYy7ojANBgkqhkiG9w0BAQsFAAOC
AQEAgALztvlN6MblkwcNQYxo1qtG3+fD/aBBsz+0GS5xOa8IgnNCMbk2UhvnKKa5
wTj2DJ0bseP+9d7i+E9QeU6b+Nu0iG2vz3B4xHZo0CPOs4WWvhj3P8fHI2eh/S5V
QANnzhZBHkvs/0g7j7eN5REDLc9wSeS+SgY0wo32otxiYELIiqmJHStrEy2rLL96
fGuRHzkVERnMneYvBxjeNjNahyk67ykXSjQsgqoMcpeIaLm/KS9LnZJBCZ5b4J6t
sJvR0EAZlcjQWqqwN6/d2bUAloRsIha3DLvgBlduy0EU0TddfMenFdA8fzf0eirm
86k7Mt+OUscakzdW+u3nNNZTeQ==
-----END CERTIFICATE-----
[Tue Feb 27 15:55:12 UTC 2024] Your cert is in: /home/ubuntu/.acme.sh/germanium.cz_ecc/germanium.cz.cer
[Tue Feb 27 15:55:12 UTC 2024] Your cert key is in: /home/ubuntu/.acme.sh/germanium.cz_ecc/germanium.cz.key
[Tue Feb 27 15:55:12 UTC 2024] The intermediate CA cert is in: /home/ubuntu/.acme.sh/germanium.cz_ecc/ca.cer
[Tue Feb 27 15:55:12 UTC 2024] And the full chain certs is there: /home/ubuntu/.acme.sh/germanium.cz_ecc/fullchain.cer
```

## Configure storage

```
sudo apt install smartmontools
sudo smartctl -a /dev/sdb
sudo parted /dev/sdb

(parted) mklabel gpt
(parted) mkpart primary 0% 100%
(parted) print
(parted) quit

sudo mkfs.ext4 /dev/sdb1
sudo mkdir -p /mnt/sdb1
sudo mount -t auto /dev/sdb1 /mnt/sdb1
df -h
ls -al /mnt/sdb1/
df -h
```

## Install InfluxDB

```
# InfluxDB2 with SSL
mkdir influxdb
cd influxdb

docker run -d -p 8086:8086 \
  --name influxdb2 \
  -v /mnt/sdb1/data:/var/lib/influxdb2 \
  -v $PWD/config:/etc/influxdb2 \
  -v /home/ubuntu/.acme.sh/germanium.cz_ecc:/srv/ssl \
  -e DOCKER_INFLUXDB_INIT_MODE=setup \
  -e DOCKER_INFLUXDB_INIT_USERNAME=root \
  -e DOCKER_INFLUXDB_INIT_PASSWORD=ET2NuwGn4EqAL^NJGVL2koVU \
  -e DOCKER_INFLUXDB_INIT_ORG=germanium \
  -e DOCKER_INFLUXDB_INIT_BUCKET=bucket1 \
  -e DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=50l4azGWGTNMi5d2Suui2Sfls1O18a4dp_wMcnkNbzoJX8doOewoXNZetlbZ5CQipIZWbgUcixokrxAc4enHlQ== \
  -e INFLUXD_TLS_CERT=/srv/ssl/germanium.cz.cer \
  -e INFLUXD_TLS_KEY=/srv/ssl//germanium.cz.key \
  influxdb:2.6
```

Create additional organizations, users, buckets
```
docker exec influxdb2 influx org create -n org-A --skip-verify
docker exec influxdb2 influx organization list --skip-verify
docker exec influxdb2 influx bucket create -n bucket-A-1 -o org-A --skip-verify
docker exec influxdb2 influx user create -n user-A-1 -p secret-password -o org-A --skip-verify
docker exec influxdb2 influx user list --skip-verify
sudo cat config/influx-configs
```

# Troubleshooting - inspect logs
docker logs -t 117e458ef54d
Or if the containre has existed follow the instructions from the arrticle [docker-look-at-the-log-of-an-exited-container](https://stackoverflow.com/questions/36666246/docker-look-at-the-log-of-an-exited-container).

```