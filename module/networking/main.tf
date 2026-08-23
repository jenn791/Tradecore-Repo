#Tradecore VPC
resource "aws_vpc" "tradecore" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "tradecore-${var.environment}"
  }
}

resource "aws_internet_gateway" "tradecore" {
  vpc_id = aws_vpc.tradecore.id

  tags = {
    Name = "tradecore-igw"
  }
}

# Public subnets (for NAT Gateway)
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.tradecore.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "tradecore-public-${var.availability_zones[count.index]}"
    Type = "Public"
  }
}

# Private subnets (for ECS and Database)
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.tradecore.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + (length(var.availability_zones)))
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "tradecore-private-${var.availability_zones[count.index]}"
    Type = "Private"
  }
}

#Route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.tradecore.id

  tags = {
    Name = "tradecore-public-rt"
    Type = "Public"
  }
}

# internet route
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.tradecore.id
}

# Private route table, both public and private subnets are inside the same VPC, and the VPC automatically has a local route that allows private communication between its CIDR ranges.
resource "aws_route_table" "private" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.tradecore.id

  tags = {
    Name = "tradecore-private-rt-${var.availability_zones[count.index]}"
    Type = "Private"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  count = length(var.availability_zones)

  domain = "vpc"

  tags = {
    Name = "tradecore-nat-eip-${var.availability_zones[count.index]}"
  }
}

# NAT Gateway one per AZ
resource "aws_nat_gateway" "tradecore" {
  count = length(var.availability_zones)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "tradecore-nat-${var.availability_zones[count.index]}"
  }

  depends_on = [aws_internet_gateway.tradecore]
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Associate private subnets with their corresponding private route tables
resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Route private subnet internet traffic through NAT Gateway
resource "aws_route" "private_nat" {
  count = length(var.availability_zones)

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.tradecore[count.index].id
}
