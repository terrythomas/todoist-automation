#!/bin/bash
# -----------------------------------------------------------------------------
# This script is a wrapper for running the Todoist automation scheduler.
# It ensures a Python virtual environment is set up, installs required
# libraries if missing, and then runs the main automation script.
# It is designed to be used interactively or as a cron job.
#
# The use of a virtual environment ensures:
# - Python dependencies are isolated from the system installation.
# - Conflicts between system and project packages are avoided.
# - Portability and reproducibility of the environment are improved.
# -----------------------------------------------------------------------------
# Wrapper script to run the Todoist automation script via cron

# Check if script already ran today
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TODAY=$(date +%Y-%m-%d)
DAILY_LOCK_FILE="$SCRIPT_DIR/.daily_run_$TODAY"

# Set up logging first
LOGDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/logs"
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/run_schedule_setup.log"

if [ -f "$DAILY_LOCK_FILE" ]; then
    echo "[$(date)] Script already ran today ($TODAY). Skipping execution." | tee -a "$LOGFILE"
    exit 0
fi

# Create the daily lock file
touch "$DAILY_LOCK_FILE"

# Clean up old lock files (older than 7 days)
find "$SCRIPT_DIR" -name ".daily_run_*" -mtime +7 -delete 2>/dev/null

# Log the start time and arguments
echo "[$(date)] Starting run_schedule.sh with args: $@" >>"$LOGFILE"

# Rotate log if it's older than 7 days or larger than 1MB
if [ -f "$LOGFILE" ]; then
  if [ $(find "$LOGFILE" -mtime +7 -o -size +1M | wc -l) -gt 0 ]; then
    mv "$LOGFILE" "$LOGFILE.$(date +%Y%m%d%H%M%S)"
  fi
fi

# Optional: clean up old rotated logs older than 7 days
find . -name "run_schedule_setup.log.*" -mtime +7 -delete

# Change to the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for .env file
if [ ! -f "$SCRIPT_DIR/.env" ]; then
  echo "Error: .env file not found. Please create it with your TODOIST_API_TOKEN." | tee -a "$LOGFILE"
  exit 1
fi

export $(grep TODOIST_API_TOKEN "$SCRIPT_DIR/.env" | xargs)

echo "Validating Todoist API token..." | tee -a "$LOGFILE"
curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $TODOIST_API_TOKEN" \
  https://api.todoist.com/rest/v2/projects | grep -q "^2"

if [ $? -ne 0 ]; then
  echo "Error: Invalid or expired TODOIST_API_TOKEN." | tee -a "$LOGFILE"
  exit 1
fi

# Ensure virtual environment exists
if [ ! -d "venv" ]; then
  echo "Creating virtual environment..." | tee -a "$LOGFILE"
  python3 -m venv venv 2>>"$LOGFILE"
fi

# Install required Python packages if not already installed
./venv/bin/python -c "import requests, dotenv, colorama" 2>/dev/null
if [ $? -ne 0 ]; then
  echo "Installing required Python packages..." | tee -a "$LOGFILE"
  ./venv/bin/pip install requests python-dotenv colorama >>"$LOGFILE" 2>&1
fi

# Activate virtual environment and run the script
"$SCRIPT_DIR/venv/bin/python" "$SCRIPT_DIR/todoist-automation-schedule-overdue" "$@"

# Log the finish time
echo "[$(date)] Finished run_schedule.sh" >>"$LOGFILE"