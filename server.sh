#!/bin/bash

# Path to JSON file
json_file="servers.json"

# Read server names (portable: sed instead of grep -P)
servers=()
while IFS= read -r line; do
    servers+=("$line")
done < <(sed -n 's/.*"name": *"\([^"]*\)".*/\1/p' "$json_file")

if [[ ${#servers[@]} -eq 0 ]]; then
    echo "No servers found in $json_file"
    exit 1
fi

# Present server options
echo "Available servers:"
for i in "${!servers[@]}"; do
    echo "$((i+1))) ${servers[$i]}"
done

# Get user's choice
read -p "Select a server to connect: " choice

# Validate input
if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#servers[@]} )); then
    echo "Invalid selection. Exiting."
    exit 1
fi

selected_name="${servers[$((choice-1))]}"

# Extract server details for the selected server
block=$(grep -A 4 "\"name\": \"$selected_name\"" "$json_file")
host=$(echo "$block"  | grep '"host":'  | awk -F'"' '{print $4}')
user=$(echo "$block"  | grep '"user":'  | awk -F'"' '{print $4}')
port=$(echo "$block"  | grep '"port":'  | awk -F': ' '{print $2}' | tr -d ', ')
proxy=$(echo "$block" | grep '"proxy":' | awk -F'"' '{print $4}')

port=${port:-22}

# Connect
if [[ -n "$proxy" ]]; then
    echo "Connecting to $user@$host via $proxy on port $port ..."
    ssh -o ProxyCommand="ssh -W %h:%p root@$proxy" -p "$port" "$user@$host"
else
    echo "Connecting to $user@$host on port $port ..."
    ssh -p "$port" "$user@$host"
fi
