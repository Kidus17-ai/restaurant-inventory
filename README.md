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

##Future Improvements
Seasonal demand forecasting — account for monthly and yearly patterns once sufficient historical data exists. Would require minimum 12 months of usage data to be statistically meaningful.

---

*Project in progress — README will be updated as the build progresses.*
