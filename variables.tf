variable "region" {
  description     = "AWS Region"
  type            = string
  default         = "us-east-1"
}

variable "identifier" {
  description     = "Infrastructure identifier, will be used to name the resources"
  type            = string
  default         = "test"
}

variable "environment" {
  type = string
  default = "dev"
}

variable "bucket" {
  type = string
  default = "retargely"
}

variable vpc_offset {
        description     = "Denotes the number of address locations added to a base address in order to get to a specific absolute address, Usually the 8-bit byte"
        type            = number
        default         = "4"
}
variable azs_count {
        description     = "Number of availability zones per network"
        type            = number
        default         = "3"
}
variable vpc_cidr {
        description     = "Classless Inter-Domain Routing (CIDR), IP addressing scheme"
        type            = string
        default         = "10.10.0.0/16"
}

# Lambda Functions 
variable "lambda" {
        description = "Map of lambda funtions configuration"
        type = any
        default = { 
                text_loader = {
                        handler = "text_loader.handler"
                        runtime = "python3.7"
                        source_path = "./functions/s3_text_returner.py"
                }                                        
        }
}
