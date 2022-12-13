resource "consul_config_entry" "lambda_redirect" {
  count = var.migrate_to_lambda ? 1 : 0
  name  = "greeter"
  kind  = "service-splitter"

  config_json = jsonencode({
    Splits = [
      {
        Weight  = 50
        Service = "greeter"
      },
      {
        Weight  = 50
        Service = "greeter-lambda"
      },
    ]
  })
}