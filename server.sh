#!/bin/bash

# Path to JSON file
json_file="servers.json"

# Read the list of servers from JSON and correctly handle names with spaces
servers=$(grep -oP '"name": *"\K[^"]+' "$json_file")

# Present server options
echo "Available servers:"
index=1
declare -A server_map
while IFS= read -r server; do
    echo "$index) $server"
    server_map[$index]="$server"
    ((index++))
done <<< "$servers"

# Get user's choice
read -p "Select a server to connect: " choice

# Validate input
if [[ -z "${server_map[$choice]}" ]]; then
    echo "Invalid selection. Exiting."
    exit 1
fi

# Extract server details for the selected server
selected_name="${server_map[$choice]}"
host=$(grep -A 4 "\"name\": \"$selected_name\"" "$json_file" | grep '"host":' | awk -F'"' '{print $4}')
user=$(grep -A 4 "\"name\": \"$selected_name\"" "$json_file" | grep '"user":' | awk -F'"' '{print $4}')

# Check if a port is specified, otherwise use default port 22
port=$(grep -A 4 "\"name\": \"$selected_name\"" "$json_file" | grep '"port":' | awk -F': ' '{print $2}' | tr -d ',')

if [[ -z "$port" ]]; then
    port=22
fi

# Check if a proxy is specified
proxy=$(grep -A 4 "\"name\": \"$selected_name\"" "$json_file" | grep '"proxy":' | awk -F'"' '{print $4}')

# If proxy exists, use ProxyCommand for SSH
if [[ -n "$proxy" ]]; then
    echo "Connecting to $user@$host via $proxy on port $port ..."
    ssh -o ProxyCommand="ssh -W %h:%p root@$proxy" -p "$port" "$user@$host"
else
    echo "Connecting to $user@$host on port $port ..."
    ssh -p "$port" "$user@$host"
fi
