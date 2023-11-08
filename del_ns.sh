#!/bin/bash

# Check if the correct number of arguments were provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <namespace>"
    exit 1
fi

# Assign the first argument to a variable called 'namespace'
namespace=$1

# Fetch the details of the namespace and write them to a temporary file
# If the command fails, print an error message and exit
if ! kubectl get namespace "$namespace" -o json > /tmp/temp.json; then
    echo "Failed to fetch namespace details."
    exit 1
fi

# Use 'jq' to set the 'finalizers' array to an empty array, indicating that we want to remove all finalizers
# Write the modified JSON to another temporary file
# If the command fails, print an error message and exit
if ! jq '.spec.finalizers=[]' /tmp/temp.json > /tmp/temp_final.json; then
    echo "Failed to modify finalizers."
    exit 1
fi

# Use 'kubectl replace' to update the namespace with the modified JSON that has the finalizers removed
# This is done by sending a request to the namespace's finalize endpoint
# If the command fails, print an error message and exit
if ! kubectl replace --raw "/api/v1/namespaces/$namespace/finalize" -f /tmp/temp_final.json; then
    echo "Failed to replace namespace finalize endpoint."
    exit 1
fi

# Remove the temporary files created during the process
rm -f /tmp/temp.json /tmp/temp_final.json

# Print a success message
echo "Finalizers removed successfully."
