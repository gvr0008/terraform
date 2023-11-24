provider "aws" {
	//region ="ca-central-1"
	region = "us-west-2"
}

variable "numberofservers"{
	description = "How many servers do you want?"
	type = number
	default = 5
}

variable "azsinfo"{
	description = "What Availablity Zone should this environment deploy to: ca-central-1a"
	default = "us-west-2a"
}


variable "instance_type"{
	default = "d3.4xlarge"
}

variable "volume_size"{
	description = "How many GB of volume do you want?"
	default = 200
}

//I've defined a variable to filter against so that I can find the VPC/SG/etc information from previous module
//The key variable here is awshybrid = true
//THIS SHOULD BE MOVED TO A MAP, but who has the time for that!
variable "filter_tag"{
	type = string
	default = "AWSVPC"
}

variable "filter_value"{
	type = string
	default = "true"

}

data "aws_subnet_ids" "awshybrid" {
  vpc_id = data.aws_vpc.awshybrid.id
  //this tag just takes the public subnet value
  tags = {
	Name = "*subnet-public1*"
  }
}

data "aws_vpc" "awshybrid"{
		//just filtering on the AWS API value here (in the docs!)
		filter {
			name = "tag:${var.filter_tag}"
			values = [var.filter_value]
		}
}

data "aws_security_group" "awshybridsg"{
	//filtering on VPC ID
	//vpc_id = data.aws_vpc.awshybrid.id
	
	filter {
	name = "tag:${var.filter_tag}"
	values = [var.filter_value]
	}

}




variable "numberofebs"{
	description = "How many block devices per server do you want?: "
	type = list(string)
	//default = ["b", "c", "d", "e"]
	//default = ["b", "c", "d", "e", "f", "g", "h", "i"]
	default = ["b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m"]
}


variable "default_tags" {
	//type = map(string)
	description = "These are the default tags for the whole TF kits"
	default = {
	awshybrid: "true"
	Terraform: "true"
	Environment: "Prod"
	Name: "hyperstore-cluster"
	IsControlMaster: "No"
	}	
}

variable "default_tags2" {
	description = "These are the default tags for the whole TF kits"
	default = [{
		key = "awshybrid"
		value = "true"
		propagate_at_launch = true
	},
	{
		key = "IsControlMaster"
		value = "No"
		propagate_at_launch = true
	},
	{
		key ="Name"
		value = "hyperstore-node"
		propagate_at_launch = true
	},
	]
}


### THIS VARIABLE IS IMPORTANT!
variable "projectname"{
	description = "What are we calling this project?"
	default = "awshybrid"
}

resource "aws_launch_configuration" "awshybridlaunchconfig_cluster"{
	//image_id = "ami-0e7bad923e8155ef5" //This is a CentOS 7 image in us-west1 (north cali)
	//image_id = "ami-0873ae2a19f5eb52b" //THIS IS MY CENTOS snapshot based on 6xi hardware
	image_id = "ami-0ab8084342cdd196e"
	
	
	//using default tenancy (NOT dedicated)
	
	//placement_tenancy = "dedicated"
	placement_tenancy = "default"
	
	instance_type = var.instance_type
	
	security_groups = [data.aws_security_group.awshybridsg.id]
	name = var.default_tags.Name
	//name = "tf-launch-config-min"
	key_name ="hyperstore-awshybrid_oregon"
	
	user_data = <<-EOF
		#!/bin/bash
		#making root login OK!!!
		sed -i 's/.*sleep 10\" //' /root/.ssh/authorized_keys
	EOF	



	
	root_block_device {
		volume_type = "gp2"
		volume_size = "400"
		delete_on_termination = true
	}


/*
//this piece of code is a fancy look that will work through my drive letters to make the launch_configuration aware of how many drives are needed for the ASG
	dynamic "ebs_block_device" {
		for_each = var.numberofebs
		content {
		device_name = "/dev/xvd${ebs_block_device.value}"
		volume_type = "standard"
		volume_size = var.volume_size
		delete_on_termination = true
		}
	}
*/
	
	lifecycle {
		create_before_destroy = true
	}
}

resource "aws_autoscaling_group" "awshybridgroup_cluster"{
	launch_configuration = aws_launch_configuration.awshybridlaunchconfig_cluster.name
	name = var.default_tags.Name
	desired_capacity = var.numberofservers
	max_size           = var.numberofservers
	min_size           = 0
	vpc_zone_identifier = data.aws_subnet_ids.awshybrid.ids
	
	lifecycle {
		create_before_destroy = true
	}
	
	tags = var.default_tags2
	/*
	tag {
	key = "Name"
	value = var.projectname
	//value = "deployawshybridcluster_prod"
	propagate_at_launch = true	
	}
	*/

}
