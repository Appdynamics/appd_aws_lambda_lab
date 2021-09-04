#!/usr/bin/env bash

start=$(date +%s)
BASE_DIR=$(pwd)

UNIQUE_LAB_ID=$(uuidgen | tail -c 7)
export AWS_REGION=$(aws configure get region)
sed -i "s/##UNIQUE_ID##/${UNIQUE_LAB_ID}/g" ./scripts/hidden.env.template

# Run Java file to scaffold application / user / role.
echo "Creating workshop user and application..."
cd $BASE_DIR/scripts
java -DworkshopUtilsConf=./lambda-workshop-setup.yaml -DworkshopLabUserPrefix=$UNIQUE_LAB_ID -DworkshopAction=setup -jar ./AD-Workshop-Utils.jar
echo "Workshop user and application created."

# Auto-deploy uninstrumented Python Lambda
echo "Deploying Python Lambda function..."
cd $BASE_DIR/python
sed -i "s/##UNIQUE_ID##/$UNIQUE_LAB_ID/g" ./serverless.yml
npm install --quiet --save serverless-python-requirements serverless-s3-remover serverless-stack-output  || { echo "Python dependency installation failed."; exit 1; }
mkdir -p .build
sls deploy -r $AWS_REGION  || { echo "Python Lambda deployment failed."; exit 1; }
cat .build/output.json | jq -r '.ServiceEndpoint' | xargs -I {} sh -c "sed -i 's|##PYTHON_LAMBDA_URL##|{}|g' ../docker-compose/graph.json"
echo "Python Lambda Function deployed."
echo
echo "----------"
echo

# Auto-deploy uninstrumented NodeJS Lambda
cd $BASE_DIR/node
echo "Deploying Node Lambda function..."
sed -i "s/##UNIQUE_ID##/$UNIQUE_LAB_ID/g" ./serverless.yml
npm install --quiet && npm install --quiet --save serverless-stack-output || { echo "Node dependency installation failed."; exit 1; }
mkdir -p .build
sls deploy -r $AWS_REGION  || { echo "Node Lambda deployment failed."; exit 1; }
cat .build/output.json | jq -r '.ServiceEndpoint' | xargs -I {} sh -c "sed -i 's|##NODEJS_LAMBDA_URL##|{}|g' ../docker-compose/graph.json"
echo "Node Lambda function deployed."
echo
echo "----------"
echo

# Auto-deploy uninstrumented Java Lambda
cd $BASE_DIR/java
echo "Deploying Java Lambda function..."
sed -i "s/##UNIQUE_ID##/$UNIQUE_LAB_ID/g" ./serverless.yml
npm install --quiet --save serverless-stack-output  || { echo "Java dependency installation failed."; exit 1; }
mvn clean package || { echo "Java build failed."; exit 1; }
mkdir -p .build 
sls deploy -r $AWS_REGION || { echo "Java Lambda deployment failed."; exit 1; }
cat .build/output.json | jq -r '.ServiceEndpoint' | xargs -I {} sh -c "sed -i 's|##JAVA_LAMBDA_URL##|{}|g' ../docker-compose/graph.json"
echo "Java Lambda function deployed."
echo
echo "----------"
echo

end=$(date +%s)
echo "Execution time took $(expr $end - $start) seconds."
