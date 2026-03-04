
output "vpc_id" {
  value = aws_vpc.msa_vpc.id
}
output "public_subnet_ids" {
  value = [for s in aws_subnet.public_subnets : s.id]
}
output "private_subnet_ids" {
  value = [for s in aws_subnet.private_subnets : s.id]
}
output "public_lb_sg_id" {
  value = aws_security_group.public_lb_sg.id
}
output "private_lb_sg_id" {
  value = aws_security_group.private_lb_sg.id
}
output "web_sg_id" {
  value = aws_security_group.web_sg.id
}
# output "db_sg_id" {
#   value = aws_security_group.db_sg.id
# }
output "bastion_sg_id" {
  value = aws_security_group.bastion_sg.id
}
