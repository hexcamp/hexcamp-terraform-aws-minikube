module "minikube" {
  #source = "scholzj/minikube/aws"
  #source = "github.com/scholzj/terraform-aws-minikube"
  #source = "github.com/praveen18k/terraform-aws-minikube-1?ref=patch-1"
  #source = "github.com/praveen18k/terraform-aws-minikube?ref=184e32c8347b6fa437671436b63c37193bf7b46e"
  #source = "git::https://github.com/praveen18k/terraform-aws-minikube.git?ref=184e32c8347b6fa437671436b63c37193bf7b46e"
  source = "./../.."

  aws_region          = "eu-central-1"
  cluster_name        = "minikube9"
 
  # https://instances.vantage.sh/aws/ec2/m5a.large?region=eu-central-1
  # AMD, $0.086 on-demand, $0.0344 spot 
  #aws_instance_type   = "m5a.large"

  # https://instances.vantage.sh/aws/ec2/m6a.large?region=eu-central-1
  # AMD, $0.1035 on-demand, $0.0528 spot
  #aws_instance_type   = "m6a.large"

  # https://instances.vantage.sh/aws/ec2/m7a.medium?region=eu-central-1
  # AMD, $0.0694 on-demand, $0.0243 spot
  aws_instance_type   = "m7a.medium"

  ssh_public_key      = "~/.ssh/id_rsa.pub"
  #aws_subnet_id       = "subnet-0dff924c15b061ac5" # eu-central-1a
  aws_subnet_id       = "subnet-0adb1c07a5e69f587" # eu-central-1b
  #aws_subnet_id       = "subnet-0782c0c8e0e9dccba" # eu-central-1c
  hosted_zone         = "localnet.farm"
  hosted_zone_private = false
  ami_image_id        = "ami-0d2246efddc8414dc"

  tags = {
    Application = "Minikube"
  }
  
  addons = [
    # "https://raw.githubusercontent.com/scholzj/terraform-aws-minikube/master/addons/storage-class.yaml",
    # "https://raw.githubusercontent.com/scholzj/terraform-aws-minikube/master/addons/csi-driver.yaml",
    # "https://raw.githubusercontent.com/scholzj/terraform-aws-minikube/master/addons/metrics-server.yaml",
    "https://raw.githubusercontent.com/scholzj/terraform-aws-minikube/8013eb285965fc220057664cddb021f3933b7bfb/addons/metrics-server.yaml",
    # "https://raw.githubusercontent.com/scholzj/terraform-aws-minikube/master/addons/dashboard.yaml",
    # "https://raw.githubusercontent.com/scholzj/terraform-aws-minikube/master/addons/external-dns.yaml",
  ]
}

output "public_ip" {
  description = "Public IP address"
  value       = module.minikube.public_ip
}

