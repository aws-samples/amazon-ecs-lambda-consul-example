variable "name" {
  type        = string
  description = "Name to prefix lambda resources"
}

variable "mesh_gateway_uri" {
  type        = string
  description = "Mesh Gateway WAN address and port"
}

variable "consul_lambda_extension_file_path" {
  type        = string
  description = "File path to Consul Lambda extention zip file"
}

variable "greeter_lambda_file_path" {
  type        = string
  description = "File path to greeter lambda zip file"
}

variable "name_port" {
  type        = string
  description = "Local port for name service"
  default     = "3001"
}

variable "greeting_port" {
  type        = string
  description = "Local port for greeting service"
  default     = "3002"
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security groups for lambda"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for lambda"
}