#!/usr/bin/env bash

# ====================================================================================
#
# MySQL Database Backup and Rotation Script
#
# Performs a daily backup of the project database through bin/clinotty and
# rotates the files with the following retention policy:
#   1. Keep all daily backups for the last RETENTION_DAYS days.
#   2. Keep the backup from every Monday for the last RETENTION_WEEKS_MONDAY weeks.
#
# Database details are read from the project .env (MYSQL_HOST, MYSQL_DATABASE,
# MYSQL_ROOT_PASSWORD). Optional overrides in .env:
#   DB_BACKUP_DIR, DB_BACKUP_RETENTION_DAYS, DB_BACKUP_RETENTION_WEEKS
#
# Example host crontab entry (daily at 03:00):
#   0 3 * * * /path/to/project/scripts/db-backup.sh >> /path/to/project/scripts/db-backup.log 2>&1
#
# ====================================================================================

# cron runs with a minimal PATH, make sure docker is reachable
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# --- Configuration Variables ---

# Project root (one level above this script), bin/clinotty must run from here.
EXECUTION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${EXECUTION_DIR}/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: .env file not found at '${ENV_FILE}'."
  exit 1
fi

# Read a single variable from .env without sourcing the whole file.
env_value() {
  grep -E "^$1=" "$ENV_FILE" | tail -n 1 | cut -d '=' -f2-
}

# Database connection details
DB_HOST="$(env_value MYSQL_HOST)"
DB_USER="root"
DB_PASS="$(env_value MYSQL_ROOT_PASSWORD)"
DB_NAME="$(env_value MYSQL_DATABASE)"

# Backup directory
# IMPORTANT: Ensure this directory has the correct write permissions.
BACKUP_DIR="$(env_value DB_BACKUP_DIR)"
BACKUP_DIR="${BACKUP_DIR:-${EXECUTION_DIR}/backups/db}"

# Retention policy settings
RETENTION_DAYS="$(env_value DB_BACKUP_RETENTION_DAYS)"
RETENTION_DAYS="${RETENTION_DAYS:-7}"                   # Number of recent daily backups to keep.
RETENTION_WEEKS_MONDAY="$(env_value DB_BACKUP_RETENTION_WEEKS)"
RETENTION_WEEKS_MONDAY="${RETENTION_WEEKS_MONDAY:-3}"   # Number of weekly Monday backups to keep.

# --- End of Configuration ---

for var in DB_HOST DB_PASS DB_NAME; do
  if [ -z "${!var}" ]; then
    echo "ERROR: ${var} is empty, check MYSQL_* variables in '${ENV_FILE}'."
    exit 1
  fi
done

# --- Script Execution ---

echo "[$(date '+%F %T')] Starting DB backup"

# Ensure the backup directory exists.
mkdir -p "$BACKUP_DIR"

# Get the current date
TIMESTAMP=$(date +%F) # Format: YYYY-MM-DD

# Define the full path and filename for the new backup file.
BACKUP_FILE="${BACKUP_DIR%/}/${TIMESTAMP}.sql"

# --- CHANGE TO THE REQUIRED DIRECTORY ---
echo "Changing directory to ${EXECUTION_DIR}..."
if ! cd "$EXECUTION_DIR"; then
  echo "ERROR: Could not change to directory '${EXECUTION_DIR}'. Please check the path."
  exit 1
fi
# --- END OF DIRECTORY CHANGE ---

# Dump into a temporary file so a failed run never leaves a partial backup behind.
echo "Starting backup of database '${DB_NAME}' to '${BACKUP_FILE}'..."
if bin/clinotty mysqldump \
    --single-transaction --quick --routines --triggers --no-tablespaces \
    -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "${BACKUP_FILE}.tmp"; then
  mv -f "${BACKUP_FILE}.tmp" "$BACKUP_FILE"
  echo "Backup completed successfully."
else
  rm -f "${BACKUP_FILE}.tmp"
  echo "ERROR: Backup failed. Please check the logs and database connection details."
  # Optional: You can add a notification command here (e.g., send an email).
  exit 1
fi

# --- Backup Rotation and Cleanup ---

echo "Starting backup rotation and cleanup process..."

# 1. Cleanup: Remove daily backups older than RETENTION_DAYS, EXCLUDING Mondays.
echo "Finding daily backups older than ${RETENTION_DAYS} days (excluding Mondays) to delete..."
find "$BACKUP_DIR" -type f -name "*.sql" -mtime +$((RETENTION_DAYS - 1)) | while read -r file; do
  # Check the day of the week for the file. 1 = Monday.
  day_of_week=$(date -r "$file" +%u)
  if [ "$day_of_week" -ne 1 ]; then
    echo "Deleting old daily backup: $file"
    rm "$file"
  fi
done

# 2. Cleanup: Keep only the last RETENTION_WEEKS_MONDAY Monday backups.
echo "Checking for old Monday backups to delete..."
# Create a list of all Monday backups, sorted from oldest to newest (file names are YYYY-MM-DD).
monday_backups=$(find "$BACKUP_DIR" -type f -name "*.sql" | while read -r file; do
  if [ "$(date -r "$file" +%u)" -eq 1 ]; then
    echo "$file"
  fi
done | sort)

# Count how many Monday backups we have (an empty list counts as 0).
count=$(printf '%s' "$monday_backups" | grep -c .)

# If we have more than the number we want to keep...
if [ "$count" -gt "$RETENTION_WEEKS_MONDAY" ]; then
  # Calculate how many to delete.
  to_delete_count=$((count - RETENTION_WEEKS_MONDAY))

  # Get the list of the oldest files to delete.
  files_to_delete=$(echo "$monday_backups" | head -n "$to_delete_count")

  echo "Found $count Monday backups. Deleting the oldest $to_delete_count to keep the newest $RETENTION_WEEKS_MONDAY."
  echo "$files_to_delete" | while read -r file_to_delete; do
    echo "Deleting old Monday backup: $file_to_delete"
    rm "$file_to_delete"
  done
else
  echo "Found $count Monday backups. No old Monday backups to delete."
fi

echo "[$(date '+%F %T')] Script finished."
