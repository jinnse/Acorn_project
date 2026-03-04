
# VPC Link: API Gateway → ALB
resource "aws_apigatewayv2_vpc_link" "internal_link" {
  name               = "msa-vpc-link"
  subnet_ids         = [for subnet in aws_subnet.private_subnets : subnet.id]
  security_group_ids = [aws_security_group.public_lb_sg.id]
}

# API Gateway 생성 (HTTP API)
resource "aws_apigatewayv2_api" "msa_http_api" {
  name          = "msa-api"
  protocol_type = "HTTP"
}

# 서비스 개수만큼 API Gateway Integration 생성
resource "aws_apigatewayv2_integration" "service_integration" {
  count                  = length(var.service_names)
  api_id                 = aws_apigatewayv2_api.msa_http_api.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = aws_lb_listener.front_end[count.index].arn   # EC2의 ALB Listener ARN
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.internal_link.id
  integration_method     = "ANY"
  payload_format_version = "1.0"
}

# 서비스 개수만큼 라우팅 생성 (/center, /notice, /reg)
resource "aws_apigatewayv2_route" "service_routes" {
  count     = length(var.service_names)
  api_id    = aws_apigatewayv2_api.msa_http_api.id
  route_key = "ANY /${var.service_names[count.index]}/{any+}"
  target    = "integrations/${aws_apigatewayv2_integration.service_integration[count.index].id}"
}

# 배포 스테이지
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.msa_http_api.id
  name        = "$default"
  auto_deploy = true
}

