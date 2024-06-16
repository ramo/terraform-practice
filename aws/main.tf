
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    "Name" = "main"
  }
}

data "aws_availability_zones" "available" {}

# Define subnet configurations
locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  subnets = merge({
    for idx, az in local.azs : "public-${idx + 1}" => {
      cidr = cidrsubnet(aws_vpc.main.cidr_block, 8, idx),
      az   = az,
      type = "public"
    }
    }, {
    for idx, az in local.azs : "private-${idx + 1}" => {
      cidr = cidrsubnet(aws_vpc.main.cidr_block, 8, idx + var.az_count),
      az   = az,
      type = "private"
    }
  })

  private_subnets = { for k, v in aws_subnet.subnets : v.tags.Name => v if v.tags.Type == "private" }


}

# Create subnets using for_each
resource "aws_subnet" "subnets" {
  for_each = local.subnets
  vpc_id   = aws_vpc.main.id

  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = each.key
    Type = each.value.type
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  route {
    cidr_block = aws_vpc.main.cidr_block
    gateway_id = "local"
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public" {
  for_each       = { for k, v in aws_subnet.subnets : k => v if v.tags.Type == "public" }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  count  = var.az_count
  domain = "vpc"

  tags = {
    Name = "nat-eip-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = var.az_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = lookup(local.private_subnets, "private-${count.index + 1}").id

  tags = {
    Name = "nat-gw-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
  count  = var.az_count
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "private-route-table-${count.index + 1}"
  }
}

resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = lookup(local.private_subnets, "private-${count.index + 1}").id
  route_table_id = aws_route_table.private[count.index].id
}
