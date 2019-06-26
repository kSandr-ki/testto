#Terraform main config file
        #Defining access keys and region
provider "aws" {
        region = "${var.region}"
}

        #Selecting default VPC. In the next block we will attach this VPC to the security groups.
data "aws_vpc" "selected" {
  default = true
}

resource "aws_key_pair" "ssh-keys" {
  key_name = "ssh-keys"
  public_key = "${file(var.ssh_public_key)}"
}

        #Create new aws security group for database instance. Only MySQL and SSH ports is open for outside.
resource "aws_security_group" "db_sg" {
        name            = "pg_ssh"
        description     = "For db server"
        vpc_id          = "${data.aws_vpc.selected.id}" #Default VPC id here

        ingress { #PG Port
                from_port       = 5432
                to_port         = 5432
                protocol        = "tcp"
                cidr_blocks     = ["0.0.0.0/0"]
        }

        ingress { #SSH Port
                from_port       = 22
                to_port         = 22
                protocol        = "tcp"
                cidr_blocks     = ["0.0.0.0/0"]
        }

        egress  { #Outbound all allow
                from_port       = 0
                to_port         = 0
                protocol        = -1
                cidr_blocks     = ["0.0.0.0/0"]
        }

        tags = {
                Name            = "PG-SSH"
        }
}

        #Create new aws security group for appliaction instance. Only HTTPS,HTTP and SSH ports is open for outside.
resource "aws_security_group" "app_sg" {
        name            = "ssh_http_https"
        description     = "For web and ssh access"
        vpc_id          = "${data.aws_vpc.selected.id}" #Default VPC id here

        ingress {  #HTTP Port
                from_port       = 80
                to_port         = 80
                protocol        = "tcp"
                cidr_blocks     = ["0.0.0.0/0"]

        }
        ingress {  #SSH Port
                from_port       = 22
                to_port         = 22
                protocol        = "tcp"
                cidr_blocks     = ["0.0.0.0/0"]

        }

        ingress {  #HTTPS Port
                from_port       = 443
                to_port         = 443
                protocol        = "tcp"
                cidr_blocks     = ["0.0.0.0/0"]

        }

        egress  {  #Outbound all allow
                from_port       = 0
                to_port         = 0
                protocol        = -1
                cidr_blocks     = ["0.0.0.0/0"]
        }

        tags = {
                Name    = "SSH-HTTP-HTTPS"
        }

}

        #Database instance
resource "aws_instance" "db_master" {
        ami = "${data.aws_ami.debian.id}"                               #AMI defined in variables.tf file
        instance_type = "${var.server_instance_type}"                   #Instance type defined in variables.tf file
        key_name = "ssh-keys"                                    
        vpc_security_group_ids = ["${aws_security_group.db_sg.id}"]     #Security group id which we already created

        tags = {
            Name = "Db_master"
        }
                #Same goes here
          provisioner "remote-exec" {
                inline = ["sudo hostname"]

                connection {
                        host = self.public_ip
                        type        = "ssh"
                        user        = "admin"
                        private_key = "${file(var.ssh_private_key)}"
                }
        }
}

resource "aws_instance" "db_slave" {
        ami = "${data.aws_ami.debian.id}"                               #AMI defined in aws_ami.tf file
        instance_type = "${var.server_instance_type}"                   #Instance type defined in variables.tf file
        key_name = "ssh-keys"                                           #KeyPair name to be attached to the instance.
        vpc_security_group_ids = ["${aws_security_group.db_sg.id}"]     #Security group id which we already created

        tags = {
            Name = "Db_slave"
        }
                #Same goes here
          provisioner "remote-exec" {
                inline = ["sudo hostname"]

                connection {
                        host = self.public_ip
                        type        = "ssh"
                        user        = "admin"
                        private_key = "${file(var.ssh_private_key)}"
                }
        }
                #DB instance related playbook

}
        #Application instance. 
resource "aws_instance" "app_wm" {
        ami = "${data.aws_ami.debian.id}"                                #AMI defined in aws_ami.tf file
        instance_type = "${var.server_instance_type}"                    #Instance type defined in variables.tf file
        key_name = "ssh-keys"                                            #KeyPair name to be attached to the instance.
        vpc_security_group_ids = ["${aws_security_group.app_sg.id}"]     #Security group id which we already created

        tags = {
            Name = "App"
        }
          provisioner "remote-exec" {
                inline = ["sudo hostname"]

                connection {
                        host = self.public_ip
                        type        = "ssh"
                        user        = "admin"
                        private_key = "${file(var.ssh_private_key)}"
                }
        }

         provisioner "local-exec" {
                command ="ansible-playbook -t pg_replication -i aws_ec2.yml -l ${aws_instance.db_master.public_dns},${aws_instance.db_slave.public_dns} -e pgrs_master=${aws_instance.db_master.public_ip} -e pgrs_slave=${aws_instance.db_slave.public_ip} site.yml --private-key=${var.ssh_private_key} --user admin"
         }
         provisioner "local-exec" {
                command ="ansible-playbook  -l ${aws_instance.db_master.public_dns} -i aws_ec2.yml -t app_init_db site.yml -e pg_host=${aws_instance.db_master.public_ip} --private-key=${var.ssh_private_key} --user admin"
        }
         provisioner "local-exec" {
                command ="ansible-playbook   -l ${self.public_dns} -i aws_ec2.yml -t app site.yml  -e pg_host=${aws_instance.db_master.public_ip} --private-key=${var.ssh_private_key} --user admin"
        }
         provisioner "local-exec" {
                command ="echo -e http://${self.public_dns}"
        }
}

