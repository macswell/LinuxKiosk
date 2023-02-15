#!/bin/bash

# Display message
echo "This script will create a new local user with sudo permissions. These credentials can be used in case the machine becomes inaccessible for any reason and needs to be repaired via console or SSH."

# Check if script is being run as root
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root."
  exit 1
fi

# Prompt for username
read -p "Enter the username for the new user: " username

# Check if user already exists
if id "$username" >/dev/null 2>&1; then
  echo "Error: User $username already exists."
  exit 1
fi

# Prompt for password
read -s -p "Enter the password for the new user: " password
echo

# Create new user
useradd -m -s /bin/bash "$username"

# Set user password
echo "$username:$password" | chpasswd

# Add user to sudo group
usermod -aG sudo "$username"
