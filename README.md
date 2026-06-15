# Data Lake Pipeline

Automated nightly data pipeline that ingests data from a hosted source system, rebuilds a PostgreSQL data lake, cleans and reshapes the data with SQL, exports refreshed reporting files, and updates Power BI dashboards so reports reflect the current day, all on an unattended schedule.

> **Note on data:** This repository uses only synthetic, generated data. It contains no real or proprietary information. A generator script is included so anyone can create sample data and run the pipeline end to end.

## Overview

Operational data often lives in a hosted application that is hard to analyze directly and is never quite current in reporting. This project solves that by rebuilding a local analytical copy of the data every night and pushing it all the way through to refreshed dashboards.

The result is a single trusted source of truth that updates on its own before the workday starts, with no manual steps and no need for anyone to be logged in.

## Architecture

```mermaid
flowchart LR
    A[Hosted source system] -->|nightly backup| B[Backup file]
    B -->|restore| C[(PostgreSQL data lake)]
    C -->|clean and reshape with SQL| D[Curated tables]
    D -->|export| E[Refreshed data files]
    E -->|refresh| F[Power BI dashboards]
    S([Windows Task Scheduler]) -.triggers nightly.-> A
```

## How it works

1. **Ingest.** A scheduled task pulls the latest nightly backup from the hosted source system.
2. **Restore.** The backup is restored into a PostgreSQL database that serves as the data lake.
3. **Transform.** SQL scripts clean and reshape the raw data into curated, analysis ready tables.
4. **Export.** The pipeline writes refreshed data files that overwrite the prior day's files used for reporting.
5. **Refresh.** Power BI datasets and dashboards refresh against the new data so reports reflect the current day.
6. **Schedule and log.** The whole sequence runs unattended on a schedule, writing logs so each run is auditable, with log rotation to keep the history manageable.

## Tech stack

- **PostgreSQL** as the analytical data lake
- **SQL** for cleaning, reshaping, and data quality logic
- **PowerShell** for orchestration of the backup, restore, transform, and export steps
- **Windows Task Scheduler** to run the pipeline unattended on a nightly schedule
- **Power BI** for the refreshed dashboards and reports
- **Python** for the synthetic data generator included in this repository

## Repository structure

```
data-lake-pipeline/
  README.md                    This file
  LICENSE
  .gitignore
  requirements.txt             Python packages for the data generator
  generate_synthetic_data.py   Creates fake source data so anyone can run the project
  sql/
    01_clean_and_reshape.sql   SQL transformations
  scripts/
    run_pipeline.ps1           PowerShell orchestration script
  sample_output/
    example_clean_data.csv     Example of a refreshed export
```

## Run it yourself

**Prerequisites:** Python 3, PostgreSQL, and PowerShell on Windows.

1. Clone this repository.
2. Install the Python packages: `pip install -r requirements.txt`
3. Generate sample source data: `python generate_synthetic_data.py`
4. Create an empty PostgreSQL database for the lake.
5. Run the pipeline script: `scripts/run_pipeline.ps1`
6. Review the refreshed files in `sample_output/`.

## What this project demonstrates

- End to end data pipeline design, from ingestion through refreshed reporting
- ETL and ELT with SQL based cleaning and reshaping
- Automation and orchestration of unattended scheduled jobs
- Logging and reliability practices that make the process auditable
- Delivery all the way to business facing dashboards, not just a database

## License

Released under the MIT License. See the LICENSE file for details.
