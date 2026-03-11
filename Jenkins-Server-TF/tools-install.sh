#!/bin/bash

set -e

echo "Updating packages..."
apt update -y

#####################################
# Install Java
#####################################
echo "Installing Java..."
apt install openjdk-17-jdk openjdk-17-jre -y
java -version

#####################################
# Install Jenkins
#####################################
echo "Installing Jenkins..."

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee \
/usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/" | tee \
/etc/apt/sources.list.d/jenkins.list > /dev/null

apt update -y
apt install jenkins -y

systemctl enable jenkins
systemctl start jenkins

#####################################
# Install Docker
#####################################
echo "Installing Docker..."

apt install docker.io -y
systemctl enable docker
systemctl start docker

usermod -aG docker ubuntu
usermod -aG docker jenkins
chmod 777 /var/run/docker.sock

#####################################
# Run SonarQube Container
#####################################
echo "Starting SonarQube container..."

docker run -d \
--name sonar \
-p 9000:9000 \
sonarqube:lts-community

#####################################
# Install AWS CLI
#####################################
echo "Installing AWS CLI..."

apt install unzip curl -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

#####################################
# Install kubectl
#####################################
echo "Installing kubectl..."

curl -LO "https://dl.k8s.io/release/v1.28.4/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/
kubectl version --client

#####################################
# Install eksctl
#####################################
echo "Installing eksctl..."

curl --silent --location \
"https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
| tar xz -C /tmp

mv /tmp/eksctl /usr/local/bin
eksctl version

#####################################
# Install Terraform
#####################################
echo "Installing Terraform..."

wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
| tee /etc/apt/sources.list.d/hashicorp.list

apt update -y
apt install terraform -y

#####################################
# Install Trivy
#####################################
echo "Installing Trivy..."

apt install wget apt-transport-https gnupg lsb-release -y

wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | \
gpg --dearmor -o /usr/share/keyrings/trivy.gpg

echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] \
https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" \
| tee /etc/apt/sources.list.d/trivy.list

apt update -y
apt install trivy -y

#####################################
# Install Helm
#####################################
echo "Installing Helm..."

snap install helm --classic

echo "Setup completed successfully!"
