start=$(date +%s)
BASE_DIR=$(pwd)

user_name="${user_name:-ec2-user}"

export AWS_REGION=$(aws configure get region)

# Increase disk size
SIZE=${1:-80}

# Get the ID of the environment host Amazon EC2 instance.
INSTANCEID=$(curl --silent http://169.254.169.254/latest/meta-data//instance-id)

# Get the ID of the Amazon EBS volume associated with the instance.
VOLUMEID=$(aws ec2 describe-instances \
  --instance-id $INSTANCEID \
  --query "Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId" \
  --output text)

# Resize the EBS volume.
aws ec2 modify-volume --volume-id $VOLUMEID --size $SIZE

# Wait for the resize to finish.
while [ \
  "$(aws ec2 describe-volumes-modifications \
    --volume-id $VOLUMEID \
    --filters Name=modification-state,Values="optimizing","completed" \
    --query "length(VolumesModifications)"\
    --output text)" != "1" ]; do
sleep 1
done

# Rewrite the partition table so that the partition takes up all the space that it can.
sudo growpart /dev/nvme0n1 1

# Expand the size of the file system.
sudo xfs_growfs -d /

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

nvm use 16

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
sudo curl --silent -L https://github.com/docker/compose/releases/download/1.27.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
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