#!/usr/bin/env bash

start=$(date +%s)
BASE_DIR=$(pwd)

export AWS_REGION=$(aws configure get region)

# check to see if user_id file exists and if so read in the user_id
if [ -f "${BASE_DIR}/scripts/appd_workshop_user.txt" ]; then

  appd_workshop_user=$(cat ./scripts/appd_workshop_user.txt)
  UNIQUE_LAB_ID=$appd_workshop_user
  
else
  
  export UNIQUE_LAB_ID="svrless-"$(uuidgen | tail -c 7)
  appd_workshop_user=$(echo $UNIQUE_LAB_ID | tr '[:upper:]' '[:lower:]')
  export UNIQUE_LAB_ID=$appd_workshop_user

  # write the user_id to a file
  echo "$appd_workshop_user" > ${BASE_DIR}/scripts/appd_workshop_user.txt
  sed -i "s/##UNIQUE_ID##/${UNIQUE_LAB_ID}/g" ./scripts/hidden.env.template
fi	



if [ -f "${BASE_DIR}/scripts/appd_workshop_created.txt" ]; then

  echo "Workshop user and application already created."

else

  # Run Java file to scaffold application / user / role.
  echo "Creating workshop user and application..."
  cd $BASE_DIR/scripts
  java -DworkshopUtilsConf=./lambda-workshop-setup.yaml -DworkshopLabUserPrefix=$UNIQUE_LAB_ID -DworkshopAction=setup -jar ./AD-Workshop-Utils.jar
  echo "true" > ${BASE_DIR}/scripts/appd_workshop_created.txt
  echo "Workshop user and application created."

  echo "Sleeping for 5s"
  sleep 5
  
  cd ..
fi



if [ -f "${BASE_DIR}/scripts/appd_python_created.txt" ]; then
	
  echo "Python Lambda Function already deployed."

else

  # Auto-deploy uninstrumented Python Lambda
  echo "Deploying Python Lambda Function..."
  cd $BASE_DIR/python
  sed -i "s/##UNIQUE_ID##/$UNIQUE_LAB_ID/g" ./serverless.yml
  #npm install --quiet --save serverless-python-requirements serverless-s3-remover serverless-stack-output
  sls plugin install -n serverless-python-requirements
  sls plugin install -n serverless-s3-remover
  sls plugin install -n serverless-stack-output
  echo ""
  echo "####################################################################################################"
  echo " Fixing NPM vunerabilities"
  echo "####################################################################################################"  
  npm audit fix
  echo "####################################################################################################"
  echo " Finished fixing NPM vunerabilities"
  echo "####################################################################################################"    
  mkdir -p .build
  sls deploy -r $AWS_REGION
  cat .build/output.json | jq -r '.ServiceEndpoint' | xargs -I {} sh -c "sed -i 's|##PYTHON_LAMBDA_URL##|{}|g' ../docker-compose/graph.json"
  echo "true" > ${BASE_DIR}/scripts/appd_python_created.txt
  echo "Python Lambda Function deployed."
  echo
  echo "----------"
  echo
  echo "Sleeping for 5s"
  sleep 5
  
  cd ..
fi


if [ -f "${BASE_DIR}/scripts/appd_nodejs_created.txt" ]; then
	
  echo "Node Lambda Function already deployed."

else

  # Auto-deploy uninstrumented NodeJS Lambda
  cd $BASE_DIR/node
  echo "Deploying Node Lambda function..."
  sed -i "s/##UNIQUE_ID##/$UNIQUE_LAB_ID/g" ./serverless.yml
  sls plugin install -n serverless-stack-output
  echo "####################################################################################################"
  echo " Fixing NPM vunerabilities"
  echo "####################################################################################################"  
  npm audit fix
  echo "####################################################################################################"
  echo " Finished fixing NPM vunerabilities"
  echo "####################################################################################################"    
  mkdir -p .build
  sls deploy -r $AWS_REGION
  cat .build/output.json | jq -r '.ServiceEndpoint' | xargs -I {} sh -c "sed -i 's|##NODEJS_LAMBDA_URL##|{}|g' ../docker-compose/graph.json"
  echo "true" > ${BASE_DIR}/scripts/appd_nodejs_created.txt
  echo "Node Lambda Function deployed."
  echo
  echo "----------"
  echo
  echo "Sleeping for 5s"
  sleep 5
  
  cd ..
fi

if [ -f "${BASE_DIR}/scripts/appd_java_created.txt" ]; then
	
  echo "Java Lambda Function already deployed."

else

  # Auto-deploy uninstrumented Java Lambda
  cd $BASE_DIR/java
  echo "Deploying Java Lambda Function..."
  sed -i "s/##UNIQUE_ID##/$UNIQUE_LAB_ID/g" ./serverless.yml
  sls plugin install -n serverless-stack-output
  echo "####################################################################################################"
  echo " Fixing NPM vunerabilities"
  echo "####################################################################################################"  
  npm audit fix
  echo "####################################################################################################"
  echo " Finished fixing NPM vunerabilities"
  echo "####################################################################################################"    
  mvn clean package || { echo "Java build failed."; exit 1; }
  mkdir -p .build 
  sls deploy -r $AWS_REGION
  cat .build/output.json | jq -r '.ServiceEndpoint' | xargs -I {} sh -c "sed -i 's|##JAVA_LAMBDA_URL##|{}|g' ../docker-compose/graph.json"
  echo "true" > ${BASE_DIR}/scripts/appd_java_created.txt
  echo "Java Lambda Function deployed."
  echo
  echo "----------"
  echo
  echo "Sleeping for 5s"
  sleep 5
  
  cd ..
fi


end=$(date +%s)
echo "Execution time took $(expr $end - $start) seconds."
