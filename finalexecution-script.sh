#!/bin/bash

#set -x
set -x

# Function to display usage instructions
display_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -c, --count     Number of JMeter slaves to create (default: 1)"
    echo "  -j, --jmx       JMX script name"
    echo "  -h, --help      Display this help message"
    exit 1
}

# Default values
TAURUS_SLAVE_COUNT=1
SLAVE_NODE_NAME="slave"
MASTER_NODE_NAME="master"


# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--count)
            shift
            TAURUS_SLAVE_COUNT=$1
            ;;
		-j|--jmx)
            shift
            JMX_SCRIPT_NAME=$1
            ;;
        -h|--help)
            display_usage
            ;;
        *)
            echo "Unknown option: $1"
            display_usage
            ;;
    esac
    shift
done

# Set environment variables
TEST_DIR='.'
FILES_DIR="${TEST_DIR}"
export JMX_SCRIPT_NAME="$JMX_SCRIPT_NAME"

# Delete existing pods
kubectl delete --all deployment

# Create Taurus Master Deployment
kubectl apply -f taurus-master-deployment.yaml

# Prepare JMeter Slaves
for ((i=1; i<=${TAURUS_SLAVE_COUNT}; i++)); do
    env SLAVE_NUMBER=${i} POD_SLAVE_NODE_NAME=${SLAVE_NODE_NAME} envsubst < "${TEST_DIR}/taurus-slave-template.yaml" | kubectl apply -f -
done

# Wait for pods to start
sleep 5

# Update Taurus execution config
kubectl get pods -l ParentNodeName=${SLAVE_NODE_NAME} -o=jsonpath='{.items[*].status.podIP}' | tr ' ' '\n' | xargs -I {} "${TEST_DIR}/update_slaves_ips.sh" {} "$JMX_SCRIPT_NAME"


sleep 5

# Copy files to Taurus Master pods
LABEL_SELECTOR="ParentNodeName=${MASTER_NODE_NAME}"
MASTER_POD=$(kubectl get pods -l $LABEL_SELECTOR -o=jsonpath='{.items[*].metadata.name}')
for pod in $MASTER_POD; do
    echo "Copying files to pod: $pod"
    kubectl cp $FILES_DIR $pod:/opt/jmeter/bin
done

# Copy files to JMeter slave pods
LABEL_SELECTOR="ParentNodeName=${SLAVE_NODE_NAME}"
PODS=$(kubectl get pods -l $LABEL_SELECTOR -o=jsonpath='{.items[*].metadata.name}')
for pod in $PODS; do
    echo "Copying files to pod: $pod"
    kubectl cp $FILES_DIR $pod:/opt/jmeter/bin
done

sleep 20


# Execute Taurus in Master pods
pod_status=$(kubectl get pod $MASTER_POD -o=jsonpath='{.status.phase}')

# Check if the pod is running
if [[ "$pod_status" == "Running" ]]; then
    echo "Running Taurus execution in pod: $MASTER_POD"
    # Execute the command using the correct path to Bash
    kubectl exec -i  $MASTER_POD -- //bin/sh -c "cd //opt/jmeter/bin/ && bzt taurus_execution.yaml"

else
    echo "Pod $MASTER_POD is not in a running state."
fi	