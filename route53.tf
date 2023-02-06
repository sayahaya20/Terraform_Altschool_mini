variable "domain_name" {
  default    = "sayahaya.me"
  type        = string
  description = "Domain name"
}
resource "aws_route53_zone" "hosted_zone" {
  name = var.domain_name
  tags = {
    Environment = "dev"
  }
}

resource "aws_route53_record" "site_domain" {
  zone_id = aws_route53_zone.hosted_zone.zone_id
  name    = "terraform-test.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_lb.Altschool-load-balancer.dns_name
    zone_id                = aws_lb.Altschool-load-balancer.zone_id
    evaluate_target_health = true
  }
}