module "minikube" {
  #source = "scholzj/minikube/aws"
  #source = "github.com/scholzj/terraform-aws-minikube"
  #source = "github.com/praveen18k/terraform-aws-minikube-1?ref=patch-1"
  #source = "github.com/praveen18k/terraform-aws-minikube?ref=184e32c8347b6fa437671436b63c37193bf7b46e"
  #source = "git::https://github.com/praveen18k/terraform-aws-minikube.git?ref=184e32c8347b6fa437671436b63c37193bf7b46e"
  source = "./../.."

  aws_region          = "ap-northeast-1"
  cluster_name        = "minikube7"
  aws_instance_type   = "m7a.medium"
  ssh_public_key      = "~/.ssh/id_rsa.pub"
  aws_subnet_id       = "subnet-0fb6c8617ffc85228"
  hosted_zone         = "localnet.farm"
  hosted_zone_private = false
  ami_image_id        = "ami-0266324950582ff7c"

  tags = {
    Application = "Minikube"
  }
  
  addons = [
    # "https://raw.githubusercontent.com/scholzj/terraform-aws-minikube/master/addons/storage-class.yaml",
    # "https://raw.githubusercontent.com/scholzj/terraform-aws-minikube/master/addons/csi-driver.yaml",
    "https://raw.githubusercontent.com/scholzj/terraform-aws-minikube/master/addons/metrics-server.yaml",
    # "https://raw.githubusercontent.com/scholzj/terraform-aws-minikube/master/addons/dashboard.yaml",
    # "https://raw.githubusercontent.com/scholzj/terraform-aws-minikube/master/addons/external-dns.yaml",
  ]
}

output "public_ip" {
  description = "Public IP address"
  value       = module.minikube.public_ip
}

