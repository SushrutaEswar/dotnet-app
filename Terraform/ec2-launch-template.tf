resource "aws_launch_template" "app" {
  name_prefix   = "dotnet-template"
  image_id      = "ami-0f58b397bc5c1f2e8"
  instance_type = "t2.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.profile.name
  }

  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]

  user_data = base64encode(file("userdata.sh"))
}