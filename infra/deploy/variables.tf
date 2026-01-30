variable "prefix" {
  description = "Prefix for resources in AWS"
  default     = "rapguensis"
}

variable "project" {
  description = "Project name for tagging resources"
  default     = "receta-praguensis"
}

variable "contact" {
  description = "Contact email for tagging resources"
  default     = "devops-team@receta-praguensis.com"
}

variable "db_username" {
  description = "Username for the receta app api database"
  default     = "recipeapp"
}

variable "db_password" {
  description = "Password for the Terraform database"
}
