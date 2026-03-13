#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

echo "Updating system and installing Java..."
sudo apt update -y
sudo apt install openjdk-17-jdk -y

echo "Installing Jenkins..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update -y
sudo apt install jenkins -y

echo "Installing Docker..."
sudo apt install docker.io -y
sudo usermod -aG docker jenkins
sudo usermod -aG docker $USER
# Instead of 777, we use 666 to allow read/write without giving execute permissions to everyone
sudo chmod 666 /var/run/docker.sock

echo "Setting up SonarQube (Ensuring system limits are met)..."
# SonarQube requires higher memory map limits
sudo sysctl -w vm.max_map_count=262144
docker run -d --name sonar -p 9000:9000 sonarqube:lts-community

echo "Installing Infrastructure Tools (AWS, K8s, Terraform)..."
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip -y && unzip awscliv2.zip
sudo ./aws/install && rm -rf awscliv2.zip aws/

# Kubectl
sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Trivy
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt update && sudo apt install trivy -y

# Helm
sudo snap install helm --classic

echo "Installation Complete! Please log out and back in for Docker group changes to take effect."
