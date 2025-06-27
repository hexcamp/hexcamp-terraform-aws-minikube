module "minikube" {
  #source = "scholzj/minikube/aws"
  #source = "github.com/scholzj/terraform-aws-minikube"
  #source = "github.com/praveen18k/terraform-aws-minikube-1?ref=patch-1"
  #source = "github.com/praveen18k/terraform-aws-minikube?ref=184e32c8347b6fa437671436b63c37193bf7b46e"
  #source = "git::https://github.com/praveen18k/terraform-aws-minikube.git?ref=184e32c8347b6fa437671436b63c37193bf7b46e"
  source = "./../.."

  aws_region          = "eu-west-3" # Paris
  cluster_name        = "minikube11"

  # https://instances.vantage.sh/aws/ec2/m6g.medium?min_memory=4&region=eu-west-3&selected=m7a.medium%2Cm6g.medium&os=linux&cost_duration=hourly&reserved_term=Standard.noUpfront
  #aws_instance_type   = "m6g.medium" # arm64, $0.045 on demand, $0.0149 spot

  # https://instances.vantage.sh/aws/ec2/m7g.medium?region=eu-west-3
  aws_instance_type   = "m7g.medium" # arm64, $0.0476 on demand, $0.0148 spot

  ssh_public_key      = "~/.ssh/id_rsa.pub"
  #aws_subnet_id       = "subnet-093bddf225b280865" # eu-west-3a
  #aws_subnet_id       = "subnet-0d0f470e834e7383b" # eu-west-3b
  aws_subnet_id       = "subnet-09858840f206bc589" # eu-west-3c
  hosted_zone         = "localnet.farm"
  hosted_zone_private = false
  # ami_image_id        = "ami-01a9ae6aa888347fe" # amd64
  ami_image_id        = "ami-0abadcd01a6555403" # hexcamp-ubuntu-minikube-3-arm64 / eu-west-3

  #no_spot             = true

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

