terraform {
  backend "s3" {
    bucket = "my-demo-13425"
    key    = "alb-openproject/backendfile"
    region = "us-east-1"
  }
}
