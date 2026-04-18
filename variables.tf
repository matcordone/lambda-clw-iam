# Bucket name variable
variable "bucket_name_old" {
    description = "The name of the S3 bucket where the placeholder is."
    type        = string
}
variable "bucket_name_new" {
    description = "The name of the S3 bucket where the placeholder is."
    type        = string
}

variable "new_key" {
    description = "The name of the S3 key to rename the file."
    type        = string
}


