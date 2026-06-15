"""
generate_synthetic_data.py

Creates a synthetic "jobs and tasks" dataset for the data-lake-pipeline project.
All data is randomly generated. It contains no real or proprietary information.

Usage:
    python generate_synthetic_data.py
This writes sample_source_data.csv to the current folder.
"""

import csv
import random
from datetime import datetime, timedelta

# Reproducible results: the same fake data every run.
random.seed(42)

NUM_ROWS = 500
OUTPUT_FILE = "sample_source_data.csv"

CUSTOMERS = ["North Region Retail", "Coastal Logistics", "Summit Healthcare",
             "Lakeside Education", "Metro Warehousing"]
JOB_TYPES = ["Preventive", "Reactive", "Inspection", "Installation", "Repair"]
STATUSES = ["Open", "Closed", "On Hold", "Pending Approval"]
CITIES = ["Springfield", "Riverton", "Fairview", "Greenville", "Madison"]


def random_date(start_days_ago=365):
    """Return a random datetime within the past year."""
    start = datetime.now() - timedelta(days=start_days_ago)
    offset = random.randint(0, start_days_ago)
    return start + timedelta(days=offset)


def build_rows(num_rows):
    rows = []
    for i in range(1, num_rows + 1):
        job_type = random.choice(JOB_TYPES)
        is_recurring = job_type in ("Preventive", "Inspection")
        created = random_date()
        cost = round(random.uniform(75, 5000), 2)
        markup = 1.15  # standard overhead markup
        rows.append({
            "job_id": 10000 + i,
            "task_id": 50000 + i,
            "customer": random.choice(CUSTOMERS),
            "city": random.choice(CITIES),
            "job_type": job_type,
            "is_recurring": is_recurring,
            "status": random.choice(STATUSES),
            "created_at": created.strftime("%Y-%m-%d"),
            "task_cost": cost,
            "sales_price": round(cost * markup, 2),
        })
    return rows


def main():
    rows = build_rows(NUM_ROWS)
    fieldnames = list(rows[0].keys())
    with open(OUTPUT_FILE, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    print(f"Wrote {len(rows)} rows to {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
