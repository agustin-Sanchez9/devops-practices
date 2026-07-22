#!/usr/bin/env bash

# Server Performance Stats Script
# Displays basic server performance statistics

set -eo pipefail

export LC_ALL=C

echo "=========================================="
echo "       SERVER PERFORMANCE STATS"
echo "=========================================="
echo ""

# OS Version
echo "--- OS Version ---"
if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    echo "${PRETTY_NAME:-${NAME:-$(uname -o)}}"
else
    uname -a
fi
echo ""

# Uptime
echo "--- Uptime ---"
uptime
echo ""

# Total CPU Usage
echo "--- Total CPU Usage ---"
if [ -f /proc/stat ]; then
    # Read two samples from /proc/stat with a small delay for accurate usage
    read -r idle1 total1 < <(awk '/^cpu /{print ($5+$6), ($2+$3+$4+$5+$6+$7+$8+$9+$10+$11)}' /proc/stat)

    sleep 0.5

    read -r idle2 total2 < <(awk '/^cpu /{print ($5+$6), ($2+$3+$4+$5+$6+$7+$8+$9+$10+$11)}' /proc/stat)

    total_diff=$((total2 - total1))
    idle_diff=$((idle2 - idle1))

    if [ "$total_diff" -gt 0 ]; then
        cpu_percent=$(awk "BEGIN {printf \"%.1f\", 100 * ($total_diff - $idle_diff) / $total_diff}")
        echo "Total CPU Usage: ${cpu_percent}%"
    else
        echo "Total CPU Usage: 0.0%"
    fi
else
    echo "Cannot determine CPU usage: /proc/stat not available"
fi
echo ""

# Total Memory Usage
echo "--- Total Memory Usage ---"
if command -v free &>/dev/null; then
    free -h | awk 'NR==2{total=$2; used=$3; free=$4; print "  Total: " total ", Used: " used ", Free: " free} NR==3{print "  Shared: "$2", Buff/Cache: "$3", Available: "$4}'
    mem_total=$(free | awk '/^Mem:/{print $2}')
    mem_used=$(free | awk '/^Mem:/{print $3}')
    if [ -n "$mem_total" ] && [ "$mem_total" -gt 0 ]; then
        mem_percent=$(awk "BEGIN {printf \"%.2f\", ($mem_used/$mem_total)*100}")
        echo "  Memory Usage Percentage: ${mem_percent}%"
    fi
else
    echo "  'free' command not available"
fi
echo ""

# Total Disk Usage
echo "--- Total Disk Usage ---"
df -h / | awk 'NR==2{total=$2; used=$3; avail=$4; use=$5; print "  Total: " total ", Used: " used ", Available: " avail ", Usage: " use}'
echo ""

# Top 5 CPU-consuming processes
echo "--- Top 5 CPU Usage Processes ---"
ps -eo pid,ppid,%cpu,comm --sort=-%cpu | head -n 6 | sed 's/^/  /'
echo ""

# Top 5 Memory-consuming processes
echo "--- Top 5 Memory Usage Processes ---"
ps -eo pid,ppid,%mem,comm --sort=-%mem | head -n 6 | sed 's/^/  /'
echo ""

echo "=========================================="
