#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <namespace>"
    exit 1
fi

namespace=$1

# Fetch namespace details
if ! kubectl get namespace "$namespace" -o json > /tmp/temp.json; then
    echo "Failed to fetch namespace details."
    exit 1
fi

# Modify finalizers
if ! jq '.spec.finalizers=[]' /tmp/temp.json > /tmp/temp_final.json; then
    echo "Failed to modify finalizers."
    exit 1
fi

# Replace namespace finalize endpoint
if ! kubectl replace --raw "/api/v1/namespaces/$namespace/finalize" -f /tmp/temp_final.json; then
    echo "Failed to replace namespace finalize endpoint."
    exit 1
fi

# Cleanup temporary files
rm -f /tmp/temp.json /tmp/temp_final.json

echo "Finalizers removed successfully."
