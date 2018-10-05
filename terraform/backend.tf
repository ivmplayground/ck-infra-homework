terraform {
    backend "s3" {
        bucket = "terraform-state-ck-homework"
        key    = "terraform-production.tfstate"
        region = "us-east-1"
    }
}
