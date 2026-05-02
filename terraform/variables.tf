variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-2"
}

variable "app_name" {
  description = "Application name used for naming all resources"
  type        = string
  default     = "restockiq"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be production, staging or development."
  }
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "restockiq.net"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "restockiq_admin"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "restockiq"
}

variable "app_port" {
  description = "Port the application runs on"
  type        = number
  default     = 5001
}

variable "app_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 1
}

# Map variable — different instance sizes per environment
variable "db_instance_class" {
  description = "RDS instance class per environment"
  type        = map(string)
  default     = {
    production  = "db.t3.micro"
    staging     = "db.t3.micro"
    development = "db.t3.micro"
  }
}

# Map variable — ECS task CPU and memory per environment
variable "ecs_task_config" {
  description = "ECS task CPU and memory per environment"
  type        = map(object({
    cpu    = number
    memory = number
  }))
  default = {
    production = {
      cpu    = 256
      memory = 512
    }
    staging = {
      cpu    = 256
      memory = 512
    }
    development = {
      cpu    = 256
      memory = 512
    }
  }
}

# List variable — availability zones to deploy into
variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b"]
}

# Boolean variable — whether to enable deletion protection on RDS
variable "enable_deletion_protection" {
  description = "Enable deletion protection on RDS"
  type        = bool
  default     = false
}