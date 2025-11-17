variable "tags" {
    description = "Tags aplicação"
    type        = map(string)
    default = {
        Name = "SiteArquProjeto"
        EmailOwner = "higorro.oliveira@gmail.com"
        Environment = "Production Lab"
    }
}

variable "project_name" {
  description = "Nome base do projeto/stack"
  type        = string
  default     = "SiteArquProjeto"
}

variable "region" {
  description = "Região da AWS"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_a_cidr" {
  description = "CIDR da subnet pública na AZ A"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  description = "CIDR da subnet pública na AZ B"
  type        = string
  default     = "10.0.2.0/24"
}

variable "ami_id" {
  description = "AMI utilizada na instância"
  default     = "ami-0866a3c8686eaeeba"
}


variable "instance_type" {
  description = "Tipo de instância EC2"
  type        = string
  default     = "t3.micro"
}

variable "asg_min" {
  description = "Capacidade mínima do Auto Scaling Group"
  type        = number
  default     = 2
}

variable "asg_max" {
  description = "Capacidade máxima do Auto Scaling Group"
  type        = number
  default     = 6
}

variable "asg_desired" {
  description = "Capacidade desejada do Auto Scaling Group"
  type        = number
  default     = 2
}

variable "cpu_target" {
  description = "Alvo de utilização média de CPU (%) para o Target Tracking"
  type        = number
  default     = 60
}