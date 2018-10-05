output "asg_name" {
  value = "${aws_autoscaling_group.webapp-asg.id}"
}

output "elb_name" {
  value = "${aws_elb.webapp-elb.dns_name}"
}

output "url" {
  value = "http://${aws_elb.webapp-elb.dns_name}"
}
