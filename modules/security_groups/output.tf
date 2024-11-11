output "external_lb_sg" {
    value = aws_security_group.externalLoadBalancerSG
}

output "internal_lb_sg" {
    value = aws_security_group.internalLoadBalancerSG
}

output "webserverSG"{
    value = aws_security_group.webserverSG
}

output "appserverSG"{
    value = aws_security_group.appserverSG
}

output "dbserverSG"{
    value = aws_security_group.dbserverSG
}