variable "tf_state_bucket" {
  description = "Name of s3 bucket in AWS for storing TF state"
  default     = "devops-2026-receta-praguensis"
}
variable "tf_state_lock_table" {
  description = "Name of DynamoDB table in AWS for TF state locking"
  default     = "devops-receta-app-api-tf-lock"
}

variable "project" {
  description = "Project name for tagging resources"
  default     = "receta-praguensis"
}

variable "contact" {
  description = "Contact name for tagging resources"
  default     = "devops-team"
}
