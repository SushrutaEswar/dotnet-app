resource "aws_autoscaling_group" "blue" {
  name = "blue-asg"

  desired_capacity = 1
  max_size         = 2
  min_size         = 1

  vpc_zone_identifier = [
    aws_subnet.public1.id,
    aws_subnet.public2.id
  ]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  target_group_arns = [
    aws_lb_target_group.blue.arn
  ]
}

resource "aws_autoscaling_group" "green" {
  name = "green-asg"

  desired_capacity = 1
  max_size         = 2
  min_size         = 1

  vpc_zone_identifier = [
    aws_subnet.public1.id,
    aws_subnet.public2.id
  ]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  target_group_arns = [
    aws_lb_target_group.green.arn
  ]
}