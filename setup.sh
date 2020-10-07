#!/usr/bin/env bash

start=$(date +%s)
BASE_DIR=$(pwd)

UNIQUE_LAB_ID=$(uuidgen | tail -c 7)
AUTH=eyJwYXNzd29yZCI6IkMxc2MwMTIzIyJ9
export AWS_REGION=$(aws configure get region)

# TODO: Run Java file to scaffold application / user / role.

APPLICATION_NAME=lambda-lab-$UNIQUE_LAB_ID

# Get controller information
echo "Retrieving AppDynamics controller information..."

VAULT_URL=https://35.227.66.33
VAULT_LOGIN_URL=$VAULT_URL/v1/auth/userpass/login/cloud-team
VAULT_INFO_URL=$VAULT_URL/v1/kv/cloud-labs/controller-info

VAULT_AUTH_TOKEN="$(echo "$AUTH" | base64 --decode | xargs -0 -I AUTHSTR curl -k --request POST --data 'AUTHSTR' --silent $VAULT_LOGIN_URL | jq -r '.auth.client_token')"
CONTROLLER_INFO="$(curl -k --header "Authorization: Bearer $VAULT_AUTH_TOKEN" --header "Content-Type: application/json" --silent $VAULT_INFO_URL | jq -r '.data')"
ACCOUNT_NAME="$(jq -r -n --argjson data "$CONTROLLER_INFO" '$data["controller-account"]')"
CONTROLLER_HOST="$(jq -r -n --argjson data "$CONTROLLER_INFO" '$data["controller-host-name"]')"
CONTROLLER_PORT="$(jq -r -n --argjson data "$CONTROLLER_INFO" '$data["controller-port"]')"
CONTROLLER_SSL_ENABLED="$(jq -r -n --argjson data "$CONTROLLER_INFO" '$data["controller-ssl-enabled"]')"
ACCESS_KEY="$(jq -r -n --argjson data "$CONTROLLER_INFO" '$data["controller-access-key"]')"
echo "AppDynamics controller information retrieved."
echo
echo "----------"
echo

# Auto-deploy uninstrumented Python Lambda
echo "Deploying Python Lambda function..."
cd $BASE_DIR/python
sed -i "s/##UNIQUE_ID##/$UNIQUE_LAB_ID/g" ./serverless.yml
npm install --quiet --save serverless-python-requirements serverless-s3-remover serverless-stack-output  || { echo "Python dependency installation failed."; exit 1; }
mkdir .build
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
mkdir .build
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
mkdir .build 
sls deploy -r $AWS_REGION || { echo "Java Lambda deployment failed."; exit 1; }
cat .build/output.json | jq -r '.ServiceEndpoint' | xargs -I {} sh -c "sed -i 's|##JAVA_LAMBDA_URL##|{}|g' ../docker-compose/graph.json"
echo "Java Lambda function deployed."
echo
echo "----------"
echo

# Configure docker-compose application
cd $BASE_DIR/docker-compose
sed -i "s/##APPLICATION_NAME##/$APPLICATION_NAME/g" ./controller.env
sed -i "s/##CONTROLLER_HOST##/$CONTROLLER_HOST/g" ./controller.env
sed -i "s/##CONTROLLER_SSL_ENABLED##/$CONTROLLER_SSL_ENABLED/g" ./controller.env
sed -i "s/##CONTROLLER_PORT##/$CONTROLLER_PORT/g" ./controller.env

cat <<EOF >.env
APPDYNAMICS_AGENT_ACCOUNT_NAME=$ACCOUNT_NAME
APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY=$ACCESS_KEY
EOF

end=$(date +%s)
echo "Execution time took $(expr $end - $start) seconds."
