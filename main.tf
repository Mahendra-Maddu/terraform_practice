resource "aws_vpc" "vpc_2302" {

  cidr_block = var.cidr

}
resource "aws_subnet"   "subnet_1" {
    vpc_id = aws_vpc.vpc_2302.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true
  
}
resource "aws_subnet"   "subnet_2" {
    vpc_id = aws_vpc.vpc_2302.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true
  
}
resource "aws_internet_gateway" "terraform_ig" {
    vpc_id = aws_vpc.vpc_2302.id
  
}

resource "aws_route_table" "rt" {

    vpc_id = aws_vpc.vpc_2302.id
    route {
       cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.terraform_ig.id
    }
}
 resource "aws_route_table_association" "rta1" {
    subnet_id = aws_subnet.subnet_1.id
    route_table_id = aws_route_table.rt.id
   
 }
 resource "aws_route_table_association" "rta2" {
    subnet_id = aws_subnet.subnet_2.id
    route_table_id = aws_route_table.rt.id
   
 }
resource "aws_security_group" "terra_sg" {
    name = "mysg"
    vpc_id = aws_vpc.vpc_2302.id

  
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
resource "aws_s3_bucket" "mys3_tf" {
    bucket = "mahi123098-f3-bucket"
    
 
}



resource "aws_instance" "EC2_one" {
  instance_type = "t2.micro"
  ami = "ami-0c7217cdde317cfec"  
  vpc_security_group_ids = [aws_security_group.terra_sg.id]
  subnet_id = aws_subnet.subnet_1.id
  user_data = base64encode(file("userdata.sh"))
}
resource "aws_instance" "EC2_two" {
   instance_type = "t2.micro"
  ami = "ami-0c7217cdde317cfec"  
  vpc_security_group_ids = [aws_security_group.terra_sg.id]
  subnet_id = aws_subnet.subnet_2.id
  user_data = base64encode(file("userdata1.sh"))
}

resource "aws_lb" "tflb" {
    name = "TFLB"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.terra_sg.id]
    subnets = [ aws_subnet.subnet_1.id,aws_subnet.subnet_2.id ]
    tags = {
        name = "web"
      }

  
}

resource "aws_lb_target_group" "targetgroup-1" {
    name = "my-TG"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.vpc_2302.id
    health_check {
      path = "/"
      port = "traffic-port"
    }
  
}
resource "aws_lb_target_group_attachment" "one-attach" {
    target_group_arn = aws_lb_target_group.targetgroup-1.arn
    target_id = aws_instance.EC2_one.id
    port = 80
  
}
resource "aws_lb_target_group_attachment" "two-attach" {
    target_group_arn = aws_lb_target_group.targetgroup-1.arn
    target_id = aws_instance.EC2_two.id
    port = 80
  
}
resource "aws_lb_listener" "listener_lb" {
    load_balancer_arn = aws_lb.tflb.arn
    port = 80
    protocol = "HTTP"
    default_action {
      target_group_arn = aws_lb_target_group.targetgroup-1.arn
      type = "forward"
    }
  
}
output "loadbalancerdns" {
    value = aws_lb.tflb.dns_name
  
}