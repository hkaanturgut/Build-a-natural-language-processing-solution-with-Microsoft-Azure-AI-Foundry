module "nlp" {
  source = "../terraform"
  # Core variables
  environment     = var.environment
  location        = var.location
  subscription_id = var.subscription_id

}