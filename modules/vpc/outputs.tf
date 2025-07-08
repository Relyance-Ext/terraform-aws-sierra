output "subnet_ids" {
  value = [for s in aws_subnet.main : s.id]
}

output "vpc_id" {
  value = aws_vpc.main.id
}
