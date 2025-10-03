#!/bin/bash

# DE10-Standard Yocto Build Monitor Script
# Automated build with failure recovery for core-image-minimal targeting cyclone5

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="build/build_monitor.log"

# Function to log messages
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

# Function to check if image is complete
check_image_complete() {
    if ls build/tmp/deploy/images/cyclone5/*.wic* >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to clean failed packages
clean_failed_packages() {
    local log_file="$1"

    # Extract failed package names from bitbake log
    failed_packages=$(grep -o "ERROR:.*recipe.*failed" "$log_file" | sed 's/ERROR://g' | sed 's/recipe//g' | sed 's/failed//g' | tr -d ' :' | sort -u)

    if [ -n "$failed_packages" ]; then
        log_message "WARNING" "Found failed packages: $failed_packages"
        for package in $failed_packages; do
            log_message "INFO" "Cleaning failed package: $package"
            pipenv run bash -c "source poky/oe-init-build-env build && bitbake -c clean $package" || true
        done
    fi
}

# Main build loop
main() {
    log_message "INFO" "Starting DE10-Standard (cyclone5) build monitor"
    log_message "INFO" "Target: core-image-minimal"

    # Check if already complete
    if check_image_complete; then
        log_message "SUCCESS" "Build already complete! WIC image found in build/tmp/deploy/images/cyclone5/"
        ls -la build/tmp/deploy/images/cyclone5/*.wic* | tee -a "$LOG_FILE"
        exit 0
    fi

    local attempt=1
    local max_attempts=5

    while [ $attempt -le $max_attempts ]; do
        log_message "INFO" "Build attempt $attempt of $max_attempts"

        # Run bitbake build
        if pipenv run bash -c "source poky/oe-init-build-env build && bitbake core-image-minimal" 2>&1 | tee -a "$LOG_FILE"; then
            log_message "SUCCESS" "Build completed successfully!"

            # Verify image files exist
            if check_image_complete; then
                log_message "SUCCESS" "WIC image files created successfully:"
                ls -la build/tmp/deploy/images/cyclone5/*.wic* | tee -a "$LOG_FILE"
                log_message "SUCCESS" "Build artifacts location: build/tmp/deploy/images/cyclone5/"
                exit 0
            else
                log_message "ERROR" "Build reported success but WIC files not found"
            fi
        else
            log_message "ERROR" "Build attempt $attempt failed"

            # Extract and clean failed packages
            clean_failed_packages "$LOG_FILE"

            # Wait before retry
            if [ $attempt -lt $max_attempts ]; then
                log_message "INFO" "Waiting 30 seconds before retry..."
                sleep 30
            fi
        fi

        ((attempt++))
    done

    log_message "ERROR" "Build failed after $max_attempts attempts"
    log_message "INFO" "Check log file: $LOG_FILE"
    exit 1
}

# Ensure we're in the right directory
if [ ! -f "poky/oe-init-build-env" ]; then
    echo "Error: Must be run from yocto-de10-standard directory"
    exit 1
fi

# Run main function
main "$@"