# Todoist Overdue Task Scheduler

This script uses the Todoist REST API to find all overdue tasks and reschedule them to the next appropriate workday. It supports dry-run mode, structured logging, project grouping, and cron automation.

## 🛠 Requirements

- macOS or Linux system
- [Homebrew](https://brew.sh/) installed
- Python 3.9+ installed via Homebrew
- A Python virtual environment will be automatically created and managed by the script on first run

> All other dependencies will be installed automatically inside a virtual environment during setup.

## 🚀 Getting Started

1. Clone this repository:
   ```bash
   git clone https://github.com/terrythomas/todoist-automation.git
   cd todoist-automation
   ```

2. Create a `.env` file in the root of this project with your Todoist API token:
   ```env
   TODOIST_API_TOKEN=your_actual_token_here
   ```
3. Make the wrapper script executable:
   ```bash
   chmod +x ./run_schedule.sh
   ```

### 🔑 Getting Your API Token

The Todoist CLI requires your Todoist API token for authentication. Here's how to get it:

1. Log into [Todoist](https://todoist.com/).
2. Go to [Settings > Integrations](https://todoist.com/prefs/integrations).
3. Under the "API token" section, click "Copy to clipboard".

## ▶️ Running the Script Manually

To run the scheduler manually (outside of cron), use:

```bash
./run_schedule.sh
```

The script will automatically:
- Create a virtual environment if it doesn't exist
- Install any missing dependencies
- Load your `.env` file
- Log output and errors to `run_schedule_setup.log`

## 🕒 Cron Setup

1. Open your crontab:
   ```bash
   crontab -e
   ```

2. Add the following line:
   ```cron
   0 * * * * /path/to/todoist-automation/run_schedule.sh >> /path/to/todoist-automation/logs/todoist-overdue-cron.log 2>&1
   ```
   To run the script with the `--dry-run` option, use:
   ```cron
   0 * * * * /path/to/todoist-automation/run_schedule.sh --dry-run >> /path/to/todoist-automation/logs/todoist-overdue-cron.log 2>&1
   ```

   This runs the wrapper script at the top of every hour and logs output to `logs/todoist-overdue-cron.log`. The script also writes detailed logs, including dependency checks and API validation, to `run_schedule_setup.log`.

4. Verify the job was added:
   ```bash
   crontab -l
   ```

### ♻️ Log Rotation for Cron Output (Optional)

The cron log file (`~/todoist-overdue-cron.log`) will grow over time if not rotated. You can use `logrotate` to manage this:

1. Create a logrotate configuration file:
   ```bash
   sudo nano /etc/logrotate.d/todoist-cron
   ```

2. Add the following contents (update the path to match your system):
   ```
   /path/to/todoist-automation/logs/todoist-overdue-cron.log {
       daily
       rotate 7
       compress
       missingok
       notifempty
       copytruncate
   }
   ```

3. (Optional) Test the rotation manually:
   ```bash
   logrotate --debug /etc/logrotate.d/todoist-cron
   ```

All other logs written by the script (such as `run_schedule_setup.log`) are already configured to rotate automatically.

## 🧪 Dry Run Mode

To simulate changes without modifying any tasks, use the `--dry-run` flag:

```bash
./run_schedule.sh --dry-run
```

This will output a preview of tasks that would be rescheduled, grouped by project and due date, without applying any changes.