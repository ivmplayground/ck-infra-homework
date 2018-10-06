# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

# Homework notes

## Objectives and constraints

The objective for this homework is to deploy this ruby on rails application on AWS in 10 hours deploying the infrastructure as code. The tools used are described below:

* Terraform
* Packer
* Ansible
* Makefile

## Infrastructure

All the infrastructure has been deployed in North Virginia region (us-east-1). 

### Networking

A VPC with the network range 10.0.0.0/16 has been launched with the following subnets:

* 10.0.1.0/24 us-east-1a
* 10.0.2.0/24 us-east-1b

Each subnet is in a different zone to ensure the HA of the resources launched. Also both subnets have been configured to auto-assign public IP addresses and have a route table with a default gateway routing to an IGW in order to have an easier way to access to the resources launched there from the Internet. The access restrictions are configured over the security groups for each specific resource.

### EC2

Web servers has been deployed with an ASG of t2.micro instances to take profit of the free tier. Also I keept the size of the ASG very low for cost reasons (min size 1 and max size 2), that means the infrastructure doesn't have high availability, but it's prepared to have it. Also I didn't configure scaling policies due to a lack of time, this is something I think it's not relevant for the homework right now and I decided to leave it.

The AMI of the webapp ASG it's build using packer and ansible. The stack for the AMI it's deployed using some public ansible roles I've found from ansible galaxy in order to save time, 

The AMI contains the following in order to have the app working:

* Ubuntu 18.04.1 LTS
* ruby 2.5.1: Installed using the ansible role [1].
* nginx & phusion passenger: Installed using the ansible role [2].

Also an ELB is configured to send the requests to the ASG instances.

### Database

A MySQL 5.7 RDS instance has been launched to store the database. This is the only resource has been deployed without using terraform. The main reason has been to save time, it wouldn't worth the time spent coding this part for the final results. Also the  RDS has launched without MultiAZ or any read replica, again to save costs.

Also the database has been seed manually, no provision script has been provided or any kind of system to execute database migrations due to a lack of time.

### Application deployment

Application is directly saved inside the AMI, I find this is the fastest way to deploy it. Using Makefile directive "ami", generates a zip file with all the application code which ansible takes it and uploads to the EC2 instance used to generate the new AMI. One time the code is unzipped in the filesystem, packer launches a bash script to deploy the app (compiles the assests and runs bundle install).

The secrets for the application are managed with AWS KMS, using the Ruby gem [3]. I find it's the fastest and the safest way to manage the secrets. This ruby gem it's pretty simple, basically you need to define the env variables with the suffix "_KMS" and then uses KMS to decrypt the string defined and set a new variable with the string decrypted without the suffix. This env variables has been defined using passenger_env_var directive and at application boot time kms-env manage them. This secrets has been already encrypted manually using aws cli [4].

### Tradeoffs

I've found there's a lot of stuff I would like to include in the homework were missing due to time constraint. Others are just for cost reasons, which I don't consider are necessary for the homework but on the other hand are important for a real production applications and have to be considered.

* VPC subnetting would be improved separating the public subnets (DMZ) and private subnets (Backend services) with a NAT Gateway, in order to improve the network security. I couldn't do this due to the time constraint.
* Ansible playbook needs some refactor, I've defined all the code inside the playbook.yaml and I think it should be split and maintained in different ansible roles.
* I would like to use terraform workspaces and ansible variables to parametrize infrastructure's code in order to have multiple environments using the same templates.
* Database provisioning has been done manually to save time. I would like to remove all manual steps and make a mechanism to run database migrations in case of new deployments.
* scaling policies for the ASG were not defined due to a lack of time, but should be defined to take profit of the autoscaling features.
* Application tests are not executed in any step of the deployment process because I didn't have enough time to implement it.
* I've created a Makefile to facilitate the execution steps to generate new AMIs, deploy changes with terraform, etc... I found it worth to keep this steps orchestrated in a Makefile, especially when you're changing and testing continuously which saves you a lot of time.
* The AMI id is defined as a variable in terraform. My first idea was to implement a simple deploy system inspired like Kubernetes does which is the rolling update. Every time a new AMI id is defined, a new launch config is created using the new AMI and a new ASG with the new launch config it's created (ASG name includes launch config name which is auto generated). The instances launched by the ASG are attached to the ELB and once they're in service, the old ASG is destroyed. With this I would like to implement a small CI/CD workflow using TravisCI, where every time is commited in master branch, a new AMI is generated with the new code and deployed to production. To implement this CI/CD workflow needs more time so I haven't been able to address it.
* Execute tests during the application deployment. I didn't implement this again for the time.
* Having more time I would change the deployment process. Right now the code is saved inside the AMI, this is not ideal since the AMI creation may take several minutes and it will increase the deployment time. Creating the app artifact, uploading to S3 and leave the EC2 instances to download and deploy by itself, will allow to decrease the deploy time. But this would require more time to implement a mechanism to trigger new code releases and deploy it in the ASG.
* Use ALB instead of a classic ELB. I used ELB basically because I found it's fastest to deploy it and save more time, but for sure I would prefer to use an ALB and take profit of the feature it has.

[1] https://galaxy.ansible.com/geerlingguy/ruby/

[2] https://galaxy.ansible.com/zaiste/passenger/

[3] https://rubygems.org/gems/kms-env

[4] https://docs.aws.amazon.com/cli/latest/reference/kms/encrypt.html
