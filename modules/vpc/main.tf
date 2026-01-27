locals {
  subnet_ids = [
    for zone in data.aws_availability_zones.all.zone_ids : aws_subnet.main[zone].id
  ]

  networking_tags = merge(var.default_tags, { Name = var.base_name })

  # Split NAT subnet CIDR into 2 subnets (one for each of the first 2 AZs)
  nat_subnet_cidrs = [
    cidrsubnet(var.nat_subnet_cidr, 1, 0), # First half for AZ1
    cidrsubnet(var.nat_subnet_cidr, 1, 1), # Second half for AZ2
  ]

  # Map each AZ to its NAT Gateway index (AZ1->NAT0, AZ2->NAT1, AZ3->NAT0, AZ4->NAT1)
  az_to_nat_map = {
    for idx, zone_id in data.aws_availability_zones.all.zone_ids :
    zone_id => idx % 2
  }
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = merge(var.default_tags, { Name = var.base_name })

  enable_dns_support   = true
  enable_dns_hostnames = true
}

data "aws_availability_zones" "all" {}

resource "aws_subnet" "main" {
  for_each             = toset(data.aws_availability_zones.all.zone_ids)
  availability_zone_id = each.value
  vpc_id               = aws_vpc.main.id
  cidr_block           = var.subnet_cidrs[each.value]

  map_public_ip_on_launch = false
}

# Create 2 NAT subnets (one in each of first 2 AZs for high availability)
resource "aws_subnet" "nat" {
  count = 2

  availability_zone_id    = data.aws_availability_zones.all.zone_ids[count.index]
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.nat_subnet_cidrs[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.default_tags, {
    Name = "${var.base_name}_nat_${count.index + 1}"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = local.networking_tags
}

# Create 2 Elastic IPs (one for each NAT Gateway)
resource "aws_eip" "nat" {
  count = 2

  domain = "vpc"

  tags = merge(var.default_tags, {
    Name = "${var.base_name}_nat_${count.index + 1}"
  })
}

# Create 2 NAT Gateways (one in each of first 2 AZs)
resource "aws_nat_gateway" "main" {
  count = 2

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.nat[count.index].id

  tags = merge(var.default_tags, {
    Name = "${var.base_name}_nat_${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

# Create route tables for private subnets (one for each NAT Gateway)
# AZ1 and AZ3 use NAT1, AZ2 and AZ4 use NAT2
resource "aws_route_table" "private" {
  count = 2

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(var.default_tags, {
    Name = "${var.base_name}_private_nat_${count.index + 1}"
  })
}

# Associate private subnets with their respective route tables
# Uses explicit mapping to ensure correct AZ-to-NAT routing
resource "aws_route_table_association" "private" {
  for_each = {
    for s in aws_subnet.main : s.id => s
  }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[local.az_to_nat_map[each.value.availability_zone_id]].id
}

# Public subnet (for NAT) needs separate route so outbound traffic goes to internet
resource "aws_route_table" "nat-igw" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.default_tags, { Name = "${var.base_name}_public" })
}

resource "aws_route_table_association" "nat-igw" {
  count = 2

  subnet_id      = aws_subnet.nat[count.index].id
  route_table_id = aws_route_table.nat-igw.id
}
