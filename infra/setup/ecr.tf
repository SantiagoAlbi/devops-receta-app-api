############################################
# Create ECR repos for storing Docker images
#############################################

resource "aws_ecr_repository" "app" {
  name                 = "receta-praguensis-api-app"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    # NOTE: Consider enabling this for production repos 
    scan_on_push = false
  }

  tags = {
    Project    = var.project
    Contact    = var.contact
    Enviroment = terraform.workspace
    ManageBy   = "Terraform/setup"
  }

}

resource "aws_ecr_repository" "proxy" {
  name                 = "receta-praguensis-api-proxy"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    # NOTE: Consider enabling this for production repos 
    scan_on_push = false
  }
}
