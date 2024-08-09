start=$(date +%s)
BASE_DIR=$(pwd)

rm -rf $BASE_DIR/.git

user_name="${user_name:-ec2-user}"

export AWS_REGION=$(aws configure get region)

export AWS_RETRY_MODE=standard
export AWS_MAX_ATTEMPTS=100

echo "####################################################################################################"
echo " Be prepared to wait up to 20 minutes or more for the volume resizing to complete."
echo " The 'aws ec2 modify-volume' service used is frequently unavailable so this script" 
echo " is set to retry 100 times to try and connect to the service."
echo ""
echo " Please be patient and take a bio-io and or grab your favorite snack or drink while waiting :)"
echo " You can safely stop this script during this phase if desired and rerun it at a later time as well."
echo "####################################################################################################"

STARTDATE=$(date)

echo ""
echo "####################################################################################################"
echo " Start Time for 'aws ec2 modify-volume' service"
echo " "$STARTDATE
echo "####################################################################################################"

SECONDS=0


echo ""


# Increase disk size
SIZE=${1:-80}

# Get the ID of the environment host Amazon EC2 instance.
# INSTANCEID=$(curl --silent http://169.254.169.254/latest/meta-data//instance-id)
INSTANCEID=$(ec2-metadata -i | cut -d ' ' -f 2)

# Get the ID of the Amazon EBS volume associated with the instance.
VOLUMEID=$(aws ec2 describe-instances --instance-id $INSTANCEID --query "Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId" --output text)

# Resize the EBS volume.
aws ec2 modify-volume --volume-id $VOLUMEID --size $SIZE

# Wait for the resize to finish.
while [ "$(aws ec2 describe-volumes-modifications --volume-id $VOLUMEID --filters Name=modification-state,Values="optimizing","completed" --query "length(VolumesModifications)" --output text)" != "1" ]; do
  sleep 1
done

# Rewrite the partition table so that the partition takes up all the space that it can.
sudo growpart /dev/nvme0n1 1

# Expand the size of the file system.
sudo xfs_growfs -d /

duration=$SECONDS

ENDDATE=$(date)

echo ""
echo "####################################################################################################"
echo " End Time for 'aws ec2 modify-volume' service"
echo " "$ENDDATE
echo ""
echo " $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed for 'aws ec2 modify-volume' service."
echo "####################################################################################################"


echo ""
df -H
echo ""
echo "####################################################################################################"
echo " Finished Resizing Local EBS Volume"
echo "####################################################################################################"
echo ""

chmod +x ${BASE_DIR}/scripts/*.sh

# Setup tooling -- Java + Maven
sudo yum install -y java-1.8.0-devel
echo -e "2\n" | sudo /usr/sbin/alternatives --config java
echo -e "2\n" | sudo /usr/sbin/alternatives --config javac
sudo wget https://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo
sudo sed -i s/\$releasever/6/g /etc/yum.repos.d/epel-apache-maven.repo
sudo yum install -y apache-maven

echo "Sleeping for 5s"
sleep 5

# Setup tooling -- NodeJS / NPM 
sudo ${BASE_DIR}/scripts/install_node.sh

echo "Sleeping for 5s"
sleep 5

nvm use 18

echo "Sleeping for 5s"
sleep 5

# Setup tooling -- Serverless framework + jq
sudo ${BASE_DIR}/scripts/install_serverless.sh 

echo "Sleeping for 5s"
sleep 5

sudo yum install -y jq

echo "Sleeping for 5s"
sleep 5

# Setup tooling -- Docker / Docker Compose
sudo curl --silent -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose version

echo "===================="
echo "Java version info"
java -version
echo "===================="
echo "Node version"
node --version
echo "===================="
echo "npm version"
npm --version 
echo "===================="
echo "Serverless version"
sudo runuser -c "serverless --version" - ${user_name}
echo "===================="
echo "Maven version"
mvn -version
echo "===================="
echo 
end=$(date +%s)
echo "Execution time took $(expr $end - $start) seconds."