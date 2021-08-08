####################################################OUTPUT####################################################

output "aws_elb_public_dns" {
  value = aws_elb.encora-alb.dns_name
}