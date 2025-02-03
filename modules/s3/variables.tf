variable "name" {
  type        = string
  description = "globally-unique name of the bucket to be created"
}

variable "tags" {
  description = "tags to be applied to resources"
  type        = map(string)
  default     = {}
}

variable "full_access_principals" {
  description = "role/user ARNs with read/write/delete access"
  type        = list(string)
}

variable "rw_access_principals" {
  description = "role/user ARNs with read/write access (but not delete)"
  type        = list(string)
}

variable "ro_access_principals" {
  description = "role/user ARNs with read-only access"
  type        = list(string)
}

variable "expiration_days" {
  description = "Number of days before objects in bucket expire"
  type        = number
}

variable "kms_key_arn" {
  description = "arn of the KMS key to use to encrypt the bucket"
  type        = string
}

variable "use_bucket_keys" {
  description = "Enable bucket keys to reduce KMS costs in the S3 findings bucket"
  type        = bool
  default     = true
}
