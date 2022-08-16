resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = var.dashboard_name

  dashboard_body = <<EOF
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [
            "AWS/EC2",
            "NetworkIn",
            "InstanceId",
            "${var.nat_instance_id}"
          ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "${var.region_id}",
        "title": "NetworkIn"
      }
    },
 {
      "type": "metric",
      "x": 12,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [
            "AWS/EC2",
            "NetworkOut",
            "InstanceId",
            "${var.nat_instance_id}"
          ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "${var.region_id}",
        "title": "NetworkOut"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 6,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [
            "AWS/EC2",
            "NetworkPacketsIn",
            "InstanceId",
            "${var.nat_instance_id}"
          ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "${var.region_id}",
        "title": "NetworkPacketsIn"
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 6,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [
            "AWS/EC2",
            "NetworkPacketsOut",
            "InstanceId",
            "${var.nat_instance_id}"
          ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "${var.region_id}",
        "title": "NetworkPacketsOut"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 12,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [
            "AWS/EC2",
            "CPUUtilization",
            "InstanceId",
            "${var.nat_instance_id}"
          ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "${var.region_id}",
        "title": "CPUUtilization"
      }
    }
  ]
}
EOF
}