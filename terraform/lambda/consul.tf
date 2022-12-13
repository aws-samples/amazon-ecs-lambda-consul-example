resource "consul_config_entry" "service_intentions_greeter" {
  name = "greeter-lambda"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "ingress"
        Precedence = 9
        Type       = "consul"
      }
    ]
  })
}