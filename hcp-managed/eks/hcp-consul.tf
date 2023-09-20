# HCP HVN definition
resource "hcp_hvn" "main" {
  hvn_id         = local.name
  cloud_provider = "aws"
  region         = var.hvn_region
  cidr_block     = var.hvn_cidr_block
}

# HCP Consul cluster definition
resource "hcp_consul_cluster" "main" {
  cluster_id      = local.name
  hvn_id          = hcp_hvn.main.hvn_id
  public_endpoint = true
  tier            = var.tier
}

# HCP HVN <-> AWS VPC network peering module
module "aws_hcp_consul" {
  source  = "hashicorp/hcp-consul/aws"
  version = "~> 0.12.1"

  hvn             = hcp_hvn.main
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets
  route_table_ids = module.vpc.private_route_table_ids
}

resource "hcp_consul_cluster_root_token" "token" {
  cluster_id = hcp_consul_cluster.main.id
}