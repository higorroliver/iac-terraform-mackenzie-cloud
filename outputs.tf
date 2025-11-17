output "alb_dns_name" {
  description = "DNS público do Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "route53_fqdn" {
  description = "Record DNS configurado no Route 53"
  value       = aws_route53_record.app.fqdn
}

output "project_name" {
  description = "Nome do projeto configurado nesta stack"
  value       = var.project_name
}