resource "aws_kms_key" "kms-production-app-key" {
  description             = "KMS key for production Ruby app"
  deletion_window_in_days = 10
  key_usage               = "ENCRYPT_DECRYPT"
  is_enabled              = true
  enable_key_rotation     = false
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "key-manage-permissions",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::419509192784:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow use of the key",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::419509192784:role/ec2-webapp-iam-role"
        ]
      },
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_kms_alias" "kms-production-app-key-alias" {
  name          = "alias/production-app-key"
  target_key_id = "${aws_kms_key.kms-production-app-key.key_id}"
}

resource "aws_kms_grant" "kms-grant-webapp-role" {
  name              = "kms-grant-webapp-role"
  key_id            = "${aws_kms_key.kms-production-app-key.key_id}"
  grantee_principal = "${aws_iam_role.ec2-webapp-iam-role.arn}"
  operations        = [ "Encrypt", "Decrypt" ]
  depends_on = ["aws_kms_key.kms-production-app-key", "aws_iam_role.ec2-webapp-iam-role"]
}
