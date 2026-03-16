variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-west-3"  # Paris
}

variable "ami_id" {
  description = "Ubuntu 22.04 AMI (changer selon la région)"
  type        = string
  default     = "ami-0a1ee2fb28fe05df3"  # Ubuntu 22.04 eu-west-3
}

variable "public_key_path" {
  description = "Chemin vers la clé SSH publique"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
