variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  
}

variable "environment" {
  description = "Deployment environment (e.g., dev, qa, prod)"
  type        = string
}

variable "location" {
  description = "Azure region for resource deployment"
  type        = string
}