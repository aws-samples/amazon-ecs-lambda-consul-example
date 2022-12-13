resource "consul_config_entry" "service_defaults" {
  for_each = toset(["greeter", "name", "greeting", "ingress"])
  name     = each.value
  kind     = "service-defaults"

  config_json = jsonencode({
    Protocol         = "http"
    Expose           = {}
    MeshGateway      = {}
    TransparentProxy = {}
  })
}

resource "consul_config_entry" "service_intentions_greeter" {
  name = "greeter"
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

resource "consul_config_entry" "service_intentions_greeting" {
  name = "greeting"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "greeter"
        Precedence = 9
        Type       = "consul"
      },
      {
        Action     = "allow"
        Name       = "greeter-lambda"
        Precedence = 9
        Type       = "consul"
      }
    ]
  })
}

resource "consul_config_entry" "service_intentions_name" {
  name = "name"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "greeter"
        Precedence = 9
        Type       = "consul"
      },
      {
        Action     = "allow"
        Name       = "greeter-lambda"
        Precedence = 9
        Type       = "consul"
      }
    ]
  })
}