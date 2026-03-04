# vpc
resource "aws_vpc" "msa_vpc" {
  cidr_block = "10.10.10.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

# public_subnets
resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.msa_vpc.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "msa-public-${count.index}"
    "kubernetes.io/role/elb" = "1"
  }
}

# private_subnets
resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.msa_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "msa-private-${count.index}"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.msa_vpc.id

  tags = {
    Name = "msa-igw"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.msa_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "msa-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public.id
}

# # EIP
# resource "aws_eip" "nat_eips" {
#   count = length(var.azs)
# }
#
# # Nat Gateway
# resource "aws_nat_gateway" "nat_gws" {
#   count         = length(var.azs)
#   allocation_id = aws_eip.nat_eips[count.index].id
#   subnet_id     = aws_subnet.public_subnets[count.index].id
#
#   tags = {
#     Name = "msa-natgw-${count.index}"
#   }
# }
#
#
# # Private Route Table
# resource "aws_route_table" "private" {
#   count  = length(var.azs)
#   vpc_id = aws_vpc.msa_vpc.id
#
#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.nat_gws[count.index].id
#   }
#
#   tags = {
#     Name = "msa-private-rt-${count.index}"
#   }
# }
#
# resource "aws_route_table_association" "private_assoc" {
#   count          = length(aws_subnet.private_subnets)
#   subnet_id      = aws_subnet.private_subnets[count.index].id
#   route_table_id = aws_route_table.private[count.index].id
# }


# EIP
resource "aws_eip" "nat_eip" {
}

# Nat Gateway
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = {
    Name = "msa-natgw"
  }
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.msa_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "msa-private-rt"
  }
}

resource "aws_route_table_association" "private_assoc" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private.id
}