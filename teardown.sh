#!/usr/bin/env bash

BASE_DIR=$(pwd)

start=$(date +%s)

# Stopping main application
echo "Stopping main application..."
kill $(ps aux | grep '[b]ash ./load.sh' | awk '{print $2}')
cd $BASE_DIR/docker-compose
./stop.sh &> /dev/null || { echo "Could not stop main application."; exit 1; }
rm .env
echo "Main application stopped."

echo
echo "----------"
echo

# Removing Python Lambda
echo "Removing Python Lambda function..."
cd $BASE_DIR/python
sls remove -r $AWS_REGION &> /dev/null || { echo "Could not remove Python Lambdas."; exit 1; }
echo "Python Lambda function removed."

echo
echo "----------"
echo

# Removing Java Lambda
echo "Removing Java Lambda function..."
cd $BASE_DIR/java
sls remove -r $AWS_REGION &> /dev/null || { echo "Could not remove Java Lambdas."; exit 1; }
echo "Java Lambda function removed."

echo
echo "----------"
echo

# Removing Node Lambda
echo "Removing Node Lambda function..."
cd $BASE_DIR/node
sls remove -r $AWS_REGION &> /dev/null || { echo "Could not remove Node Lambdas."; exit 1; }
echo "Node Lambda function removed."

# Run Java file to scaffold application / user / role.
echo "Deleting workshop user and application..."
cd $BASE_DIR/scripts
java -DworkshopUtilsConf=./lambda-workshop-teardown.yaml -DworkshopAction=teardown -jar ./AD-Workshop-Utils.jar
echo "Workshop user and application deleted."

cd $BASE_DIR
end=$(date +%s)
echo "Execution time took $(expr $end - $start) seconds."