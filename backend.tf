# S3 Backend configuration for Terraform state file storage
module "s3_backend" {
    source  = "terraform-aws-modules/s3-bucket/aws"
    version = "5.12.0"
    bucket  = "terraform-statefiles-yt" 
}