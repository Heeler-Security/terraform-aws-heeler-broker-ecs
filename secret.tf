resource "aws_secretsmanager_secret" "heeler_broker_secret_key" {
    name = "heeler-broker-secret-key"
}

resource "aws_secretsmanager_secret" "heeler_broker_key_id" {
    name = "heeler-broker-key-id"
}
