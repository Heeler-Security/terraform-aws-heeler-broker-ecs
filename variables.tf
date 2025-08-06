variable "private_subnet_ids" {
   description = "Array of subnet ids. Subnets need internet access. ECS tasks will be run here"
   type = list(string)
}

variable "region" {
   description = "The region to deploy the broker"
   type = string
}

variable "vpc_id" {
   description = "The id of the vpc where the broker will run in"
   type = string  
   
}

variable "broker_image" {
   description = "Thge location of the broker image"
   type = string
   default = "654654247928.dkr.ecr.us-east-1.amazonaws.com/broker:latest"
}
