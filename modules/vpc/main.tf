locals {
  subnet_ids = [
    for zone in data.aws_availability_zones.all.zone_ids : aws_subnet.main[zone].id
  ]

  networking_tags = merge(var.default_tags, { Name = var.base_name })
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

resource "aws_subnet" "nat" {
  # TODO: make optional if nodes are public?
  availability_zone_id = data.aws_availability_zones.all.zone_ids[0]
  vpc_id               = aws_vpc.main.id
  cidr_block           = var.nat_subnet_cidr

  # We should only create the NAT here with its own explicit public IP
  map_public_ip_on_launch = false
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = local.networking_tags
}

resource "aws_eip" "main-nat" {
  domain = "vpc"

  tags = local.networking_tags
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main-nat.id
  subnet_id     = aws_subnet.nat.id

  tags = local.networking_tags

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route" "main-nat" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = aws_nat_gateway.main.id
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
  subnet_id      = aws_subnet.nat.id
  route_table_id = aws_route_table.nat-igw.id
}
