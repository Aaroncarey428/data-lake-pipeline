# run_pipeline.ps1
# Orchestrates the data-lake-pipeline end to end:
#   1. Generate synthetic source data
#   2. Load it into PostgreSQL
#   3. Run SQL cleaning and reshaping
#   4. Export the curated reporting table
#
# Designed to run unattended on a schedule (for example via Windows
# Task Scheduler). All data is synthetic. No real or proprietary data is used.

# --- Configuration -----------------------------------------------------------
$ErrorActionPreference = "Stop"   # Stop the run on the first error.

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$DataFile    = Join-Path $ProjectRoot "sample_source_data.csv"
$SqlFile     = Join-Path $ProjectRoot "sql\01_clean_and_reshape.sql"
$OutputDir   = Join-Path $ProjectRoot "sample_output"
$LogFile     = Join-Path $ProjectRoot "rebuild_log.txt"

# PostgreSQL connection settings (override with your own environment).
$PgDatabase  = "datalake"
$PgUser      = "postgres"

# --- Logging helper ----------------------------------------------------------
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$timestamp  $Message"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line
}

# --- Pipeline ----------------------------------------------------------------
try {
    Write-Log "Pipeline started."

    # Step 1: Generate synthetic source data.
    Write-Log "Generating synthetic source data."
    python (Join-Path $ProjectRoot "generate_synthetic_data.py")

    # Step 2: Load the CSV into a raw staging table in PostgreSQL.
    # client_encoding is set to UTF8 to avoid Windows codepage issues.
    Write-Log "Loading raw data into PostgreSQL."
    $copyCmd = "\copy raw_jobs_tasks FROM '$DataFile' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')"
    psql -U $PgUser -d $PgDatabase -c "SET client_encoding = 'UTF8';"
    psql -U $PgUser -d $PgDatabase -c "$copyCmd"

    # Step 3: Run the cleaning and reshaping transformations.
    Write-Log "Running SQL transformations."
    psql -U $PgUser -d $PgDatabase -f $SqlFile

    # Step 4: Export the curated reporting table to a refreshed CSV.
    Write-Log "Exporting curated results."
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir | Out-Null
    }
    $exportFile = Join-Path $OutputDir "example_clean_data.csv"
    $exportCmd  = "\copy (SELECT * FROM report_monthly_spend) TO '$exportFile' WITH (FORMAT csv, HEADER true)"
    psql -U $PgUser -d $PgDatabase -c "$exportCmd"

    Write-Log "Pipeline completed successfully."
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    throw
}
