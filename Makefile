export PACKER_LOG=1
export TF_PATH=./terraform
export AMI=ami-0ce4d2feb5b9cb287

.PHONY: init requirements build ami plan deploy

init:
	cd ${TF_PATH} && \
	terraform init \
	-input=false \
	-backend-config="access_key=${AWS_ACCESS_KEY_ID}" \
	-backend-config="secret_key=${AWS_SECRET_ACCESS_KEY}"

requirements:
	ansible-galaxy install -p packer/ansible/roles -r packer/ansible/requirements.yml

build:
	rm -rf ./build
	mkdir -p build
	zip -r ./build/ck-infra-homework.zip . \
	--exclude=*.git* --exclude=*terraform* \
	--exclude=*packer* --exclude=*ssh_keys* \
	--exclude=*aws-credentials*

ami: requirements build
	packer build packer/packer-ami.json

plan:
	cd ${TF_PATH} && \
	terraform plan \
	-input=false \
	-var "aws_access_key=${AWS_ACCESS_KEY_ID}" \
        -var "aws_secret_key=${AWS_SECRET_ACCESS_KEY}" \
	-var "ami=${AMI}"

deploy:
	cd ${TF_PATH} && \
	terraform apply \
	-input=false \
	-var "aws_access_key=${AWS_ACCESS_KEY_ID}" \
        -var "aws_secret_key=${AWS_SECRET_ACCESS_KEY}" \
	-var "ami=${AMI}" \
	-auto-approve

cleanup:
	cd ${TF_PATH} && \
	terraform destroy \
	-input=false \
	-var "aws_access_key=${AWS_ACCESS_KEY_ID}" \
        -var "aws_secret_key=${AWS_SECRET_ACCESS_KEY}" \
	-var "ami=${AMI}"
	terraform state rm aws_s3_bucket.state
