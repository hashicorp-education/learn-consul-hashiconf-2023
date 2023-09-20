resource "aws_secretsmanager_secret" "bootstrap_token" {
  name                    = "${local.name}-bootstrap-token"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "bootstrap_token" {
  secret_id     = aws_secretsmanager_secret.bootstrap_token.id
  secret_string = hcp_consul_cluster_root_token.token.secret_id
}

data "aws_secretsmanager_secret_version" "bootstrap_token" {
  secret_id = aws_secretsmanager_secret.bootstrap_token.id
  depends_on = [aws_secretsmanager_secret_version.bootstrap_token]
}

resource "aws_secretsmanager_secret" "ca_cert" {
  name                    = "${local.name}-client-ca-cert"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "ca_cert" {
  secret_id     = aws_secretsmanager_secret.ca_cert.id
  secret_string = base64decode(hcp_consul_cluster.main.consul_ca_file)
}

resource "aws_secretsmanager_secret" "gossip_key" {
  name                    = "${local.name}-gossip-encryption-key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "gossip_key" {
  secret_id     = aws_secretsmanager_secret.gossip_key.id
  secret_string = jsondecode(base64decode(hcp_consul_cluster.main.consul_config_file))["encrypt"]
}