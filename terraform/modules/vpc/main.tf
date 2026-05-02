# Fetch available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Use provided AZs or fall back to first 2 available
  azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 2)

  # CIDR blocks for public subnets — one per AZ
  public_subnet_cidrs = [for i, az in local.azs : cidrsubnet("10.0.0.0/16", 8, i)]

  # CIDR blocks for private subnets — one per AZ
  private_subnet_cidrs = [for i, az in local.azs : cidrsubnet("10.0.0.0/16", 8, i + 10)]
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

# Public subnets — one per AZ using for_each
resource "aws_subnet" "public" {
  for_each = tomap({ for i, az in local.azs : az => local.public_subnet_cidrs[i] })

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-public-${each.key}"
    Tier = "public"
  })
}

# Private subnets — one per AZ using for_each
resource "aws_subnet" "private" {
  for_each = tomap({ for i, az in local.azs : az => local.private_subnet_cidrs[i] })

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-private-${each.key}"
    Tier = "private"
  })
}

# Internet Gateway — allows public subnets to reach internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-igw"
  })
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-public-rt"
  })
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Private route table — no internet access
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-private-rt"
  })
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}