#!/usr/bin/env bash

BASE_DIR=$(pwd)

start=$(date +%s)

export AWS_REGION=$(aws configure get region)

# Stopping main application
echo "Stopping main application..."
kill $(ps aux | grep '[b]ash ./load.sh' | awk '{print $2}')
cd $BASE_DIR/docker-compose
./stop.sh
rm .env
echo "Main application stopped."

echo
echo "----------"
echo

echo "Sleeping for 5s"
sleep 5

# Removing Python Lambda
echo "Removing Python Lambda function..."
cd $BASE_DIR/python
sls remove -r $AWS_REGION
echo "Python Lambda function removed."

echo
echo "----------"
echo

echo "Sleeping for 5s"
sleep 5

# Removing Java Lambda
echo "Removing Java Lambda function..."
cd $BASE_DIR/java
sls remove -r $AWS_REGION
echo "Java Lambda function removed."

echo
echo "----------"
echo

# Removing Node Lambda
echo "Removing Node Lambda function..."
cd $BASE_DIR/node
sls remove -r $AWS_REGION
echo "Node Lambda function removed."

# Run Java file to scaffold application / user / role.
echo "Deleting workshop user and application..."
cd $BASE_DIR/scripts
java -DworkshopUtilsConf=./lambda-workshop-teardown.yaml -DworkshopAction=teardown -jar ./AD-Workshop-Utils.jar
echo "Workshop user and application deleted."

cd $BASE_DIR
end=$(date +%s)
echo "Execution time took $(expr $end - $start) seconds."