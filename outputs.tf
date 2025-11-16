output "alb_dns_name" {
  value       = aws_lb.alb.dns_name
  description = "DNS público do ALB"
}

output "route53_fqdn" {
  value       = aws_route53_record.app_alias.fqdn
  description = "FQDN apontando para o ALB"
}
