terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket         = "zupikas-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-west-1"
    dynamodb_table = "zupikas-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

module "vpc" {
  source      = "../../modules/vpc"
  environment = var.environment
  aws_region  = var.aws_region
  vpc_cidr    = "10.0.0.0/16"
  azs         = ["${var.aws_region}a", "${var.aws_region}c"]
}

module "ecr" {
  source      = "../../modules/ecr"
  environment = var.environment
  image_names = ["tc-backend-dev", "tc-queue-job-dev", "tc-trigger-job-dev", "tc-migration-dev"]
}

module "eks" {
  source              = "../../modules/eks"
  environment         = var.environment
  cluster_name        = "zupikas-cluster"
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  node_instance_type  = "t3.medium"
  node_min_size       = 2
  node_max_size       = 6
  node_desired_size   = 2
}

module "monitoring" {
  source            = "../../modules/monitoring"
  environment       = var.environment
  slack_webhook_url = var.slack_webhook_url
  depends_on        = [module.eks]
}

module "aurora" {
  source                = "../../modules/aurora"
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  eks_security_group_id = module.eks.cluster_security_group_id
  serverless_min_acu    = 0.5
  serverless_max_acu    = 8
  instance_count        = 1
  deletion_protection   = false
}
