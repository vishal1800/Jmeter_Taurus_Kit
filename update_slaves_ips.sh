#!/bin/bash

# Check if at least two arguments are provided
if [ "$#" -lt 2 ]; then
    echo "Error: Insufficient arguments provided."
    echo "Usage: $0 <nodes> <jmx_script_name>"
    exit 1
fi

# Get the arguments passed to the script
nodes="$1"
JMX_SCRIPT_NAME="$2"

# Output the beginning of the distributed section
echo "distributed:"
#echo "  - $nodes"
for nodes in "$1"; do
    # Output each IP address as a separate list item
echo "  - $nodes"
done


echo "script: $JMX_SCRIPT_NAME"

# Define the path to the YAML file
yaml_file="./taurus_execution.yaml"

sleep 10
# Check if the file exists
if [ ! -f "$yaml_file" ]; then
    echo "Error: File '$yaml_file' not found."
    exit 1
fi

sleep 5

# Update the YAML content using sed

nodes_formatted=$(printf '%s\n' "$nodes" | sed 's/^/      - /')  # Add 2 spaces before '-'
sed -i "/^\s*distributed:/s/.*/&\n$nodes_formatted/" "$yaml_file"

# Update the JMX script name in the YAML file

 sed -i "/^\s*scenarios:/,/^settings:/ {
 /^\s*testing_taurus:/,/^\s*modifications:/ {
 /^\s*script:/s|:.*|: $JMX_SCRIPT_NAME|
 }
 }" "$yaml_file"



# echo "YAML file updated successfully."

echo "YAML file updated successfully."
