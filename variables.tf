variable "ssh_private_key" {
        default         = "id_rsa"
        description     = "Private key for Frankfurt region"
}

variable "ssh_public_key" {
        default         = "id_rsa.pub"
        description     = "Private key for Frankfurt region"
}

variable "server_instance_type" {
        default         = "t2.micro"
        description     = "Instance type"
}

variable "region" {
        default = "us-west-1"
        description     = "AWS Region"
}
