module "nlp" {
    source = "../infra"
    
    environment = var.environment
    location    = var.location
    subscription_id = var.subscription_id
  
}