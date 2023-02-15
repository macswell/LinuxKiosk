#!/bin/bash

# Read the input file containing the list of applications and resources to download
input_file="app_list.xml"

# Set the log file name and location
log_file="install.log"

# Install required packages using apt
install_packages() {
    for package in "$@"
    do
        if ! sudo apt-get install -y "$package" >> "$log_file" 2>&1; then
            echo "Error installing package $package. Aborting script." >&2
            remove_downloaded_files
            exit 1
        fi
    done
}

# Download a file using wget
download_file() {
    local filename="$1"
    local url="$2"
    if ! wget -O "$filename" "$url" >> "$log_file" 2>&1; then
        echo "Error downloading file $filename from $url. Aborting script." >&2
        remove_downloaded_files
        exit 1
    fi
}

# Run a script
run_script() {
    local script="$1"
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
    while IFS= read -r line; do
        if [[ "$line" == *"<file name=\""* ]]; then
            filename=$(echo "$line" | sed -e 's/<file name=\"\(.*\)\" url=\".*\"\/>/\1/')
            if [ -e "$filename" ]; then
                rm "$filename"
            fi
        fi
    done < "$input_file"
}

# Remove installed packages
remove_packages() {
    local packages=()
    while IFS= read -r line; do
        if [[ "$line" == *"<package>"* ]]; then
            package=$(echo "$line" | sed -e 's/<package>\(.*\)<\/package>/\1/')
            packages+=("$package")
        fi
    done < "$input_file"
    if [ ${#packages[@]} -gt 0 ]; then
        sudo apt-get remove -y "${packages[@]}" >> "$log_file" 2>&1
    fi
}

# Parse the input file and install packages, download files and run scripts as defined
parse_input_file() {
    local packages=()
    while IFS= read -r line; do
        case "$line" in
            *"<package>"*)
                package=$(echo "$line" | sed -e 's/<package>\(.*\)<\/package>/\1/')
                packages+=("$package")
                ;;
            *"<file name=\""*)
                filename=$(echo "$line" | sed -e 's/<file name=\"\(.*\)\" url=\"\(.*\)\"\/>/\1/')
                url=$(echo "$line" | sed -e 's/<file name=\"\(.*\)\" url=\"\(.*\)\"\/>/\2/')
                download_file "$filename" "$url"
                ;;
            *"<script>"*)
                script=$(echo "$line" | sed -e 's/<script>\(.*\)<\/script>/\1/')
                run_script "$script"
                ;;
            *)
                continue
                ;;
        esac
    done < "$input_file"
    install_packages "${packages[@]}"
}

parse_input_file