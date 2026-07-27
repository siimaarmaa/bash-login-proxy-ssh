#!/bin/bash

# Resolve paths relative to this script (not the current working directory).
script_dir="$(cd "$(dirname "$0")" && pwd)"
json_file="$script_dir/servers.json"

if [[ ! -f "$json_file" ]]; then
    echo "servers.json not found at $json_file"
    exit 1
fi

# Portable server list (works with macOS BSD tools and bash 3.2+).
server_names=()
while IFS= read -r name; do
    [[ -n "$name" ]] && server_names+=("$name")
done < <(sed -n 's/.*"name":[[:space:]]*"\([^"]*\)".*/\1/p' "$json_file")

if [[ ${#server_names[@]} -eq 0 ]]; then
    echo "No servers found in $json_file"
    exit 1
fi

echo "Available servers:"
i=0
while [[ $i -lt ${#server_names[@]} ]]; do
    echo "$((i + 1))) ${server_names[$i]}"
    i=$((i + 1))
done

read -p "Select a server to connect: " choice

if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
    echo "Invalid selection. Exiting."
    exit 1
fi

idx=$((choice - 1))
if (( idx < 0 || idx >= ${#server_names[@]} )); then
    echo "Invalid selection. Exiting."
    exit 1
fi

selected_name="${server_names[$idx]}"

# Extract the JSON object for the selected server.
block=$(awk -v name="$selected_name" '
    $0 ~ "\"name\"" && $0 ~ "\"" name "\"" { capture=1 }
    capture { print }
    capture && /^[[:space:]]*}[[:space:]]*,?[[:space:]]*$/ { exit }
' "$json_file")

host=$(echo "$block" | sed -n 's/.*"host":[[:space:]]*"\([^"]*\)".*/\1/p')
user=$(echo "$block" | sed -n 's/.*"user":[[:space:]]*"\([^"]*\)".*/\1/p')
port=$(echo "$block" | sed -n 's/.*"port":[[:space:]]*\([0-9][0-9]*\).*/\1/p')
proxy=$(echo "$block" | sed -n 's/.*"proxy":[[:space:]]*"\([^"]*\)".*/\1/p')

if [[ -z "$host" || -z "$user" ]]; then
    echo "Could not read host/user for \"$selected_name\"."
    exit 1
fi

if [[ -z "$port" ]]; then
    port=22
fi

if [[ -n "$proxy" ]]; then
    echo "Connecting to $user@$host via $proxy on port $port ..."
    ssh -o ProxyCommand="ssh -W %h:%p root@$proxy" -p "$port" "$user@$host"
else
    echo "Connecting to $user@$host on port $port ..."
    ssh -p "$port" "$user@$host"
fi
