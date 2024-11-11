output public_subnet {
  value       = aws_subnet.public
  sensitive   = false
  description = "description"
  depends_on  = []
}

output private_subnet{
    value = aws_subnet.private
}

output database_subnet{
    value = aws_subnet.db_private
}

output vpc{
    value = aws_vpc.main
}