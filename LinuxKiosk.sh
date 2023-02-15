#!/bin/bash

# Set the working directory to the directory from which the script is run
cd "$(dirname "$0")"

# Read the input file containing the list of applications and resources to download
input_file="LinuxKioskConfig.xml"

# Set the log file name and location
log_file="install.log"

# Set the temporary download directory
temp_dir="Linux Kiosk Temp"

# Install required packages using apt
install_packages() {
    for package in "$@"
    do
        package=$(echo "$package" | sed -e 's/^[[:space:]]*//')
        if ! sudo apt-get install -y "$package" >> "$log_file" 2>&1; then
            echo "Error installing package $package. Aborting script." >&2
            remove_downloaded_files
            exit 1
        fi
    done
}

# Download a file using wget
download_file() {
    local tag="$1"
    local filename=$(echo "$tag" | sed -e 's/.*name="\([^"]*\)".*/\1/' | sed -e 's/^[[:space:]]*//')
    local url=$(echo "$tag" | sed -e 's/.*url="\([^"]*\)".*/\1/' | sed -e 's/^[[:space:]]*//')
    if ! wget -P "$temp_dir" -q --show-progress "$url" -O "$filename" >> "$log_file" 2>&1; then
        echo "Error downloading file $filename from $url. Aborting script." >&2
        remove_downloaded_files
        exit 1
    fi
}

# Run a script
run_script() {
    local script="$1"
    script=$(echo "$script" | sed -e 's/^[[:space:]]*//')
    chmod +x "$script"
    if ! ./"$script" >> "$log_file" 2>&1; then
        echo "Error running script $script. Aborting script." >&2
        remove_downloaded_files
        remove_packages
        exit 1
    fi
}

# Remove downloaded files
remove_downloaded_files() {
    if [ -d "$temp_dir" ]; then
        rm -r "$temp_dir"
    fi
}

# Remove installed packages
remove_packages() {
    local packages=()
    while IFS= read -r line; do
        if [[ "$line" == *"<package>"* ]]; then
            package=$(echo "$line" | sed -e 's/<package>\(.*\)<\/package>/\1/' | sed -e 's/^[[:space:]]*//')
            packages+=("$package")
        fi
    done < "$input_file"
    if [ ${#packages[@]} -gt 0 ]; then
        sudo apt-get remove -y "${packages[@]}" >> "$log_file" 2>&1
    fi
}

# Parse the input file, install packages, download files and run scripts as defined
parse_input_file() {
    local packages=()
    local files=()
    local scripts=()
    while IFS= read -r line; do
        case "$line" in
            *"<package>"*)
                package=$(echo "$line" | sed -e 's/<package>\(.*\)<\/package>/\1/' | sed -e 's/^[[:space:]]*//')
                packages+=("$package")
                ;;
            *"<file name=\""*)
                files+=("$line")
                download_file "$line"
                ;;
            *"<script>"*)
                script=$(echo "$line" | sed -e 's/<script>\(.*\)<\/script>/\1/' | sed -e 's/^[[:space:]]*//')
                scripts+=("$script")
                ;;
            *)
                continue
                ;;
        esac
    done < "$input_file"

    # Install packages
    if [ ${#packages[@]} -gt 0 ]; then
        install_packages "${packages[@]}"
    fi

    # Run scripts
    if [ ${#scripts[@]} -gt 0 ]; then
        for script in "${scripts[@]}"; do
            run_script "$script"
        done
    fi

    # Remove downloaded files
    remove_downloaded_files
}
parse_input_file