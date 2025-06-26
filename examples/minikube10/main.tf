module "minikube" {
  #source = "scholzj/minikube/aws"
  #source = "github.com/scholzj/terraform-aws-minikube"
  #source = "github.com/praveen18k/terraform-aws-minikube-1?ref=patch-1"
  #source = "github.com/praveen18k/terraform-aws-minikube?ref=184e32c8347b6fa437671436b63c37193bf7b46e"
  #source = "git::https://github.com/praveen18k/terraform-aws-minikube.git?ref=184e32c8347b6fa437671436b63c37193bf7b46e"
  source = "./../.."

  aws_region          = "us-east-2"
  cluster_name        = "minikube10"

  # https://instances.vantage.sh/aws/ec2/m7a.medium?region=us-east-2&selected=m7a.medium&os=linux&cost_duration=hourly&reserved_term=Standard.noUpfront
  #aws_instance_type   = "m7a.medium" # amd64, $0.0580 on demand, $0.0184 spot
  
  # https://instances.vantage.sh/aws/ec2/m6g.medium?min_memory=4&region=us-east-2&selected=m7a.medium%2Cm6g.medium&os=linux&cost_duration=hourly&reserved_term=Standard.noUpfront
  aws_instance_type   = "m6g.medium" # arm64, $0.0385 on demand, $0.0126 spot


  ssh_public_key      = "~/.ssh/id_rsa.pub"
  aws_subnet_id       = "subnet-010a9eb58d5d844e3"
  hosted_zone         = "localnet.farm"
  hosted_zone_private = false
  # ami_image_id        = "ami-01a9ae6aa888347fe" # amd64
  ami_image_id        = "ami-0eed33059dcc6fdf8"

  no_spot             = true

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

