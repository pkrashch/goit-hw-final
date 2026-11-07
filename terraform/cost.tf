resource "aws_budgets_budget" "monthly" {
  name         = "${var.project}-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 50
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}

# Cost Explorer: anomaly detection per AWS service (Cost Explorer itself is
# enabled once in the console: Billing -> Cost Explorer -> Launch).
# AWS allows only ONE dimensional SERVICE monitor per account. If the account
# already has one, pass its ARN via existing_anomaly_monitor_arn.
resource "aws_ce_anomaly_monitor" "services" {
  count             = var.existing_anomaly_monitor_arn == "" ? 1 : 0
  name              = "${var.project}-services"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

resource "aws_ce_anomaly_subscription" "daily" {
  name      = "${var.project}-anomalies"
  frequency = "DAILY"
  monitor_arn_list = [
    var.existing_anomaly_monitor_arn != "" ? var.existing_anomaly_monitor_arn : aws_ce_anomaly_monitor.services[0].arn
  ]

  subscriber {
    type    = "EMAIL"
    address = var.alert_email
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = ["5"]
    }
  }
}
