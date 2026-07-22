#!/bin/bash

set -uo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

error_exit() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

info() {
    echo -e "${GREEN}INFO: $1${NC}"
}

warn() {
    echo -e "${YELLOW}WARN: $1${NC}"
}

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

DURATION=60

# Check if stress-ng is available
if ! command -v stress-ng >/dev/null 2>&1; then
    warn "stress-ng is not installed. It is the recommended tool for system load testing."
    echo ""
    echo "Why stress-ng is better than 'yes':"
    echo "  - Supports CPU, memory, disk I/O, and network stress testing"
    echo "  - More controlled and predictable load generation"
    echo "  - Standard tool used in real-world production testing"
    echo ""
    read -p "Install stress-ng now? [Y/n]: " response
    response=${response:-Y}
    if [[ "$response" =~ ^[Yy]$ ]]; then
        info "Installing stress-ng..."
        if command -v apt-get >/dev/null 2>&1; then
            apt-get update -qq && apt-get install -y -qq stress-ng
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y -q stress-ng
        elif command -v yum >/dev/null 2>&1; then
            yum install -y -q stress-ng
        elif command -v pacman >/dev/null 2>&1; then
            pacman -Sy --noconfirm stress-ng
        else
            warn "Could not install stress-ng automatically. Falling back to basic 'yes' method."
        fi
    fi
fi

# Function to test with stress-ng
run_stress_tests() {
    print_header "Running comprehensive stress tests with stress-ng"
    
    # CPU test: stress all CPU cores
    info "Starting CPU stress test (${DURATION}s)..."
    stress-ng --cpu $(nproc) --cpu-method matrixprod --timeout ${DURATION}s --metrics-brief &
    CPU_PID=$!
    
    # Memory test: allocate and exercise memory
    info "Starting memory stress test (${DURATION}s)..."
    stress-ng --vm 2 --vm-bytes 30% --vm-method all --timeout ${DURATION}s --metrics-brief &
    MEM_PID=$!
    
    # Disk I/O test: perform disk writes
    info "Starting disk I/O stress test (${DURATION}s)..."
    stress-ng --io 4 --timeout ${DURATION}s --metrics-brief &
    IO_PID=$!
    
    info "All stress tests running for ${DURATION} seconds. Check your Netdata dashboard!"
    
    # Wait for all background jobs
    wait $CPU_PID
    wait $MEM_PID
    wait $IO_PID
    
    print_header "Stress tests completed"
}

# Fallback function using basic tools
run_fallback_tests() {
    print_header "Running basic stress tests (fallback mode)"
    
    info "Starting CPU stress test using 'yes' processes..."
    PIDS=()
    for i in $(seq 1 $(nproc)); do
        yes > /dev/null &
        PIDS+=($!)
    done
    
    info "Starting memory stress test..."
    # Use a Python one-liner to allocate memory if available, otherwise use /dev/shm
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "
import time
x = bytearray(300 * 1024 * 1024)  # 300MB
for i in range(len(x)):
    x[i] = i % 256
time.sleep(${DURATION})
" &
        MEM_PID=$!
    else
        # Fallback to dd writing to /dev/shm (tmpfs)
        dd if=/dev/zero of=/dev/shm/stress_mem bs=1M count=300 2>/dev/null && \
        while sleep 1; do :; done &
        MEM_PID=$!
    fi
    
    info "Starting disk I/O stress test..."
    dd if=/dev/zero of=/tmp/stress_disk bs=1M count=10000 2>/dev/null || true &
    IO_PID=$!
    
    info "All stress tests running for ${DURATION} seconds. Check your Netdata dashboard!"
    sleep ${DURATION}
    
    # Cleanup
    info "Cleaning up stress processes..."
    for pid in "${PIDS[@]}"; do
        kill $pid 2>/dev/null || true
    done
    kill $MEM_PID 2>/dev/null || true
    kill $IO_PID 2>/dev/null || true
    wait 2>/dev/null || true
    
    # Clean up temp files
    rm -f /dev/shm/stress_mem /tmp/stress_disk 2>/dev/null || true
    
    print_header "Stress tests completed"
}

# Main execution
if command -v stress-ng >/dev/null 2>&1; then
    run_stress_tests
else
    run_fallback_tests
fi

info "Test complete. Review your Netdata dashboard for metrics and alerts."
