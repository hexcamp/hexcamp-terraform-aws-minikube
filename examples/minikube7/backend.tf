terraform {
  backend "s3" {
    bucket = "localnet-farm-opentofu"
    key = "minikube7"
    region = "us-west-2"
    dynamodb_table = "localnet-farm-opentofu"
  }
}
