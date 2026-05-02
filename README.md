# RestockIQ — Restaurant Inventory Management System

A cloud-based inventory management system built to solve a real problem I observed working in a restaurant.

---

## The Problem

During my time working in a restaurant, I noticed managers spent time every day tracking stock with just a pen and paper. It was clearly tedious work — and even then it wasn't reliable. The restaurant would still run out of items and only realise once they were completely gone, meaning we'd be out of that product for a couple of days while waiting for the next order.

The root issues were:
- Stock tracking was manual, slow, and done after the fact
- There was no way to see stock levels in real time
- Orders were only placed once something had already run out

## The Solution

RestockIQ is a web application that live tracks restaurant stock levels, predicts when items are going to run out based on usage patterns, and alerts managers before it becomes a problem.

**Planned features:**
- Live inventory dashboard showing current stock levels
- Staff can quickly log how much of an item has been used
- Predictions use a 3 day forward average to avoid unnecessary orders being triggered by a single day's usage pattern
- Automated low stock alerts so managers can order before running out
- Automated nightly stock check via AWS Lambda and EventBridge — runs at midnight, checks all stock levels against thresholds, and sends SNS email alerts for any items running low without requiring manual triggers

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | Python Flask |
| Database | AWS RDS (PostgreSQL) |
| Containerisation | Docker |
| Hosting | AWS ECS |
| Infrastructure | Terraform |
| CI/CD | GitHub Actions |
| DNS | AWS Route 53 |
| Alerts | AWS SNS |

## Future Improvements
Seasonal demand forecasting — account for monthly and yearly patterns once sufficient historical data exists. Would require minimum 12 months of usage data to be statistically meaningful.

## Challenges
- Cascading Delete Bug: When trying to delete an item from the dashboard the app threw an internal server error. After investigating the database I found that each item had stock logs attached to it in a separate table. Because item is a foreign key on the stock logs table with a NOT NULL constraint, the database refused to delete the parent record while child records still referenced it. The fix was to delete all related stock logs first before deleting the parent item — teaching me the importance of understanding database relationships and constraints before designing delete operations.
- Prediction Threshold Sensitivity: My initial prediction logic only used the current day's average usage to determine whether stock was running low. I realised this could trigger unnecessary orders — for example on a Saturday night stock might look critically low based on Saturday's high usage average, triggering an automatic order, when in reality Sunday's much lower usage meant stock was perfectly fine. I fixed this by switching to a 3 day forward average which looks at today plus the next two days combined, giving a much more stable and accurate picture of actual demand.
- ECS vs EKS: When deciding how to host the application I considered both ECS and EKS. Kubernetes through EKS would have added significant complexity — managing node groups, cluster upgrades, kubectl configuration and Helm charts — for no real benefit at this scale. RestockIQ is a single containerised application with straightforward scaling needs. ECS with Fargate was the right tool — serverless containers with no server management, simpler configuration, and lower operational overhead. Choosing the right tool for the scale of the problem rather than over-engineering it was an important lesson.
- Lambda VPC Networking: While writing the Lambda Terraform configuration I researched VPC networking requirements and discovered that Lambda functions running inside a VPC require specific EC2 permissions to create an elastic network interface — needed to communicate with other VPC resources like RDS. Without ec2:CreateNetworkInterface, ec2:DescribeNetworkInterfaces and ec2:DeleteNetworkInterface the function would fail to start entirely. Adding these permissions preemptively avoided what would have been a confusing deployment failure since the error message doesn't immediately point to network interface permissions.

---

*Project in progress — README will be updated as the build progresses.*
