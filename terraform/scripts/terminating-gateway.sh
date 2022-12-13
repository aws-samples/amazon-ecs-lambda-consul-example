#!/bin/bash

# Install Consul.  This creates...
# 1 - a default /etc/consul.d/consul.hcl
# 2 - a default systemd consul.service file
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt update && apt install -y consul=${CONSUL_VERSION} unzip

# Install Envoy
curl https://func-e.io/install.sh | bash -s -- -b /usr/local/bin
func-e use ${ENVOY_VERSION}
cp /root/.func-e/versions/${ENVOY_VERSION}/bin/envoy /usr/local/bin

# Grab instance IP
metadata_token=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
local_ip=$(curl -H "X-aws-ec2-metadata-token: $metadata_token" http://169.254.169.254/latest/meta-data/local-ipv4)

mkdir -p /etc/consul.d/certs

cat > /etc/consul.d/certs/consul-agent-ca.pem <<- EOF
${CA_PUBLIC_KEY}
EOF

cat > /etc/consul.d/certs/client-cert.pem <<- EOF
${CLIENT_PUBLIC_KEY}
EOF

cat > /etc/consul.d/certs/client-key.pem <<- EOF
${CLIENT_PRIVATE_KEY}
EOF

# Modify the default consul.hcl file
cat > /etc/consul.d/consul.hcl <<- EOF
data_dir = "/opt/consul"

client_addr = "0.0.0.0"

server = false

bind_addr = "0.0.0.0"

advertise_addr = "$local_ip"

retry_join = ["${CONSUL_ADDR}"]

encrypt = "${GOSSIP_KEY}"

verify_incoming = true

verify_outgoing = true

verify_server_hostname = true

ca_file = "/etc/consul.d/certs/consul-agent-ca.pem"

cert_file = "/etc/consul.d/certs/client-cert.pem"

key_file = "/etc/consul.d/certs/client-key.pem"

acl = {
  enabled = true
  default_policy = "deny"
  enable_token_persistence = true

  tokens {
    default = "${BOOTSTRAP_TOKEN}"
  }
}

connect {
  enable_serverless_plugin = true
  enabled                  = true
}

ports {
  grpc = 8502
}

telemetry {
  prometheus_retention_time = "24h"
  disable_hostname = true
}
EOF

# Start Consul
systemctl daemon-reload
systemctl start consul
systemctl enable consul

sleep 30

cat > /etc/systemd/system/consul-envoy.service <<- EOF
[Unit]
Description=Consul Envoy
Wants=consul.target
After=syslog.target network.target consul.target

[Service]
ExecStart=/usr/bin/consul connect envoy -gateway=terminating -register -service ${SERVICE_NAME} -token=${BOOTSTRAP_TOKEN}
ExecStop=/bin/sleep 5
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start consul-envoy
systemctl enable consul-envoy