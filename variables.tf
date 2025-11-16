variable "region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_a_cidr" {
  description = "CIDR Sub-rede pública A"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  description = "CIDR Sub-rede pública B"
  type        = string
  default     = "10.0.2.0/24"
}

variable "ami_id" {
  description = "AMI da instância (Amazon Linux 2/2023)"
  type        = string
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Nome do Key Pair para SSH (opcional)"
  type        = string
  default     = null
}

variable "ssh_ingress_cidr" {
  description = "CIDR para permitir SSH direto nas instâncias (ex: seu IP). Deixe null para desabilitar."
  type        = string
  default     = null
}

variable "asg_min" {
  description = "Mínimo de instâncias no ASG"
  type        = number
  default     = 2
}

variable "asg_max" {
  description = "Máximo de instâncias no ASG"
  type        = number
  default     = 6
}

variable "asg_desired" {
  description = "Capacidade desejada do ASG"
  type        = number
  default     = 2
}

variable "cpu_target" {
  description = "Target de CPU médio do ASG (%)"
  type        = number
  default     = 50
}

variable "route53_zone_id" {
  description = "Hosted Zone ID do Route 53"
  type        = string
}

variable "route53_record_name" {
  description = "Hostname (ex: app.seudominio.com)"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN do certificado ACM para HTTPS (opcional)"
  type        = string
  default     = null
}