#####
# Setup AWS provider
# (Retrieve AWS credentials from env variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY)
#####

provider "aws" {
  region = var.aws_region
}

#####
# Generate kubeadm token
#####

module "kubeadm-token" {
  source = "scholzj/kubeadm-token/random"
}

#####
# Security Group
#####

data "aws_subnet" "minikube_subnet" {
  id = var.aws_subnet_id
}

resource "aws_security_group" "minikube" {
  vpc_id = data.aws_subnet.minikube_subnet.vpc_id
  name   = var.cluster_name

  tags = merge(
    {
      "Name"                                               = var.cluster_name
      format("kubernetes.io/cluster/%v", var.cluster_name) = "owned"
    },
    var.tags,
  )

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_access_cidr]
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9153
    to_port     = 9153
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30443
    to_port     = 30443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#####
# IAM role
#####

resource "aws_iam_policy" "minikube_policy" {
  name        = var.cluster_name
  path        = "/"
  description = "Policy for role ${var.cluster_name}"
  policy      = file("${path.module}/template/policy.json.tpl")
}

resource "aws_iam_role" "minikube_role" {
  name = var.cluster_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_policy_attachment" "minikube-attach" {
  name = "minikube-attachment"
  roles = [aws_iam_role.minikube_role.name]
  policy_arn = aws_iam_policy.minikube_policy.arn
}

resource "aws_iam_instance_profile" "minikube_profile" {
  name = var.cluster_name
  role = aws_iam_role.minikube_role.name
}

##########
# Bootstraping scripts
##########

data "cloudinit_config" "minikube_cloud_init" {
  gzip = true
  base64_encode = true

  part {
    filename = "init-aws-minikube.sh"
    content_type = "text/x-shellscript"
    #content = templatefile("${path.module}/scripts/init-aws-minikube.sh", { kubeadm_token = module.kubeadm-token.token, dns_name = "${var.cluster_name}.${var.hosted_zone}", ip_address = aws_eip.minikube.public_ip, cluster_name = var.cluster_name, kubernetes_version = var.kubernetes_version, addons = join(" ", var.addons) } )
    content = templatefile("${path.module}/scripts/init-aws-minikube.sh", { kubeadm_token = module.kubeadm-token.token, dns_name = "${var.cluster_name}.${var.hosted_zone}", cluster_name = var.cluster_name, kubernetes_version = var.kubernetes_version, addons = join(" ", var.addons) } )
  }
}

##########
# Keypair
##########

resource "aws_key_pair" "minikube_keypair" {
  key_name = var.cluster_name
  public_key = file(var.ssh_public_key)
}

#####
# EC2 instance
#####

#resource "aws_eip" "minikube" {
#  #vpc = true
#  domain = "vpc"
#}

resource "aws_instance" "minikube" {
  # Instance type - any of the c4 should do for now
  instance_type = var.aws_instance_type

  ami = var.ami_image_id

  key_name = aws_key_pair.minikube_keypair.key_name

  subnet_id = var.aws_subnet_id

  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.minikube.id,
  ]

  iam_instance_profile = aws_iam_instance_profile.minikube_profile.name

  user_data = data.cloudinit_config.minikube_cloud_init.rendered

  tags = merge(
    {
      "Name" = var.cluster_name
      format("kubernetes.io/cluster/%v", var.cluster_name) = "owned"
    },
    var.tags,
  )

  root_block_device {
    volume_type = "gp2"
    volume_size = "20"
    delete_on_termination = true
  }

  lifecycle {
    ignore_changes = [
      ami,
      user_data,
      associate_public_ip_address,
    ]
  }

  dynamic "instance_market_options" {
    for_each = var.no_spot ? [] : [true]
    content {
      market_type = "spot"
      spot_options {
        max_price = 0.045
        instance_interruption_behavior = "stop"
        spot_instance_type = "persistent"
      }
    }
  }

  #instance_market_options {
  #  market_type = "spot"
  #  spot_options {
  #    max_price = 0.045
  #    instance_interruption_behavior = "stop"
  #    spot_instance_type = "persistent"
  #  }
  #}

  credit_specification {
    cpu_credits = "standard"
  }
}

#resource "aws_eip_association" "minikube_assoc" {
#  instance_id = aws_instance.minikube.id
#  allocation_id = aws_eip.minikube.id
#}

#####
# DNS record
#####

data "aws_route53_zone" "dns_zone" {
  name = "${var.hosted_zone}."
  private_zone = var.hosted_zone_private
}

resource "aws_route53_record" "minikube" {
  zone_id = data.aws_route53_zone.dns_zone.zone_id
  name = "${var.cluster_name}.${var.hosted_zone}"
  type = "A"
  #records = [aws_eip.minikube.public_ip]
  records = [aws_instance.minikube.public_ip]
  ttl = 300
  allow_overwrite = true
}

resource "aws_route53_record" "minikube_wildcard" {
  zone_id = data.aws_route53_zone.dns_zone.zone_id
  name = "*.${var.cluster_name}.${var.hosted_zone}"
  type = "A"
  #records = [aws_eip.minikube.public_ip]
  records = [aws_instance.minikube.public_ip]
  ttl = 300
  allow_overwrite = true
}


