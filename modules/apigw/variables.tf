variable "s3_arn" { 
  type = string 
}
variable "identifier" {
  type = string 
  default = "identifier"
}
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = any
  default     = {}
}

variable "lambda_arn" { 
  type = string
  default = ""
}