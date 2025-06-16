# CI/CD Pipeline Setup Using Jenkins, Ansible, and  Docker

![Screenshot](J.png)

## Step 1: Launch Four Instances

1. Jenkins
2. Ansible + Docker
3. Docker

---

## Ansible Setup

### Step 2: Install Ansible

```bash
sudo apt update
sudo apt install software-properties-common -y
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible -y
```

### Step 3: Install Docker

```bash
sudo apt install docker.io -y
```

### Step 4: Login to DockerHub

```bash
docker login
```

### Step 5: Set Root User Password

```bash
passwd root
```

### Step 6: Generate SSH Key Pair

```bash
ssh-keygen
```

### Step 7: Enable SSH Root Login

```bash
sudo nano /etc/ssh/sshd_config
# Comment Out or Edit
PermitRootLogin yes
PasswordAuthentication yes

sudo nano /etc/ssh/sshd_config.d/10-cloud-init.conf
# Add
PermitRootLogin yes
PasswordAuthentication yes
```

### Step 8: Restart SSH Service & Verify

```bash
sudo systemctl restart ssh
sudo sshd -T | grep -Ei 'passwordauthentication|permitrootlogin'
```

---

## Jenkins Setup

### Step 9: Install Jenkins

```bash
nano jenkins.sh
```

Paste the following:

```bash
#!/bin/bash

set -e

echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "Installing Java (OpenJDK 17)..."
sudo apt install openjdk-17-jdk -y

echo "Adding Jenkins GPG key..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \  
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "Adding Jenkins repository..."
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \  
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \  
  /etc/apt/sources.list.d/jenkins.list > /dev/null

echo "Updating package list with Jenkins repo..."
sudo apt update

echo "Installing Jenkins..."
sudo apt install jenkins -y

echo "Starting and enabling Jenkins service..."
sudo systemctl start jenkins
sudo systemctl enable jenkins

echo "Allowing firewall on port 8080 (if UFW is active)..."
sudo ufw allow 8080 || true
sudo ufw reload || true

echo "Jenkins installation completed!"
echo

echo "Access Jenkins via: http://<your-server-ip>:8080"
echo "Initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Step 10: Permission to SH File

```bash
chmod +x jenkins.sh
```

### Step 11: Run Jenkins Install Script

```bash
sudo ./jenkins.sh
```

### Step 12: Set Root User Password (Same as Ansible)

```bash
passwd root
```
### Step 13: Generate SSH Key Pair

```bash
ssh-keygen
```

### Step 14: Enable SSH Root Login

```bash
sudo nano /etc/ssh/sshd_config
PermitRootLogin yes
PasswordAuthentication yes

sudo nano /etc/ssh/sshd_config.d/10-cloud-init.conf
PermitRootLogin yes
PasswordAuthentication yes
```
### Step 15: Restart SSH Service & Verify

```bash
sudo systemctl restart ssh
sudo sshd -T | grep -Ei 'passwordauthentication|permitrootlogin'
```

---

## Docker Server Setup

### Step 16: Install Docker

```bash
sudo apt install docker.io -y
```

### Step 17: Set Root User Password

```bash
passwd root
```
### Step 18: Generate SSH Key Pair

```bash
ssh-keygen
```
### Step 19: Enable SSH Root Login

```bash
sudo nano /etc/ssh/sshd_config
PermitRootLogin yes
PasswordAuthentication yes

sudo nano /etc/ssh/sshd_config.d/10-cloud-init.conf
PermitRootLogin yes
PasswordAuthentication yes
```
### Step 20: Restart SSH Service & Verify

```bash
sudo systemctl restart ssh
sudo sshd -T | grep -Ei 'passwordauthentication|permitrootlogin'
```

---

## SSH Key-Based Authentication

### Step 21: From Jenkins to Ansible

```bash
ssh-copy-id root@<ansible_private_ip>
ssh root@<ansible_private_ip>
```

### Step 22: From Ansible to Docker

```bash
ssh-copy-id root@<web-server_private_ip>
ssh root@<web-server_private_ip>
```

---

## Ansible Project Setup

### Step 23: Create Ansible Project Directory (Ansible)

```bash
mkdir -p /root/sourcecode
cd /root/sourcecode
```

### Step 24: Define Inventory (Ansible)

```bash
nano inventory
```

Paste:

```ini
[dockerhost]
<Docker Private Ip> ansible_user=root ansible_become=true
```

### Step 25: Create Playbook to Deploy Container (Ansible)

```bash
nano run_container.yml
```

Paste:

```yaml
- hosts: all
  become: yes
  tasks:
    - name: Run Docker container using Ansible module
      community.docker.docker_container:
        name: cloud-container
        image: <DockerHub User Name>/meetv1.4
        state: started
        recreate: true
        published_ports:
          - "9000:80"
```

---

## Jenkins Configuration

### Step 26: Create Jenkins API Token

- Navigate: Dashboard > Your Username > Configure
- Generate and save a new API token

### Step 27: GitHub Webhook Configuration

- Navigate: GitHub Repo > Settings > Webhooks > Add webhook
  - Payload URL: `http://<jenkins_ip>:8080/github-webhook/`
  - Content type: `application/json`
  - Secret: Your secret key
  - Click Save

### Step 28: Jenkins Host Configuration

- Go to: Dashboard > Manage Jenkins > Configure System
- Add SSH remote hosts (Install Publish Over SSH plugin)
  - Jenkins Host:
    - Name: Jenkins
    - Hostname: `<jenkins_private_ip>`
    - Username: root
  - Ansible Host:
    - Name: ansible
    - Hostname: `<ansible_private_ip>`
    - Username: root

---

## Jenkins Freestyle Project

### Step 29: Create Jenkins Project

- Source Code Management:
  - Git: [https://github.com/your/repo.git](https://github.com/your/repo.git)
  - Branch: `<your repo branch>`
- Build Triggers:
  - GitHub hook trigger for GITScm polling
- Build Steps:
  - Send files or execute commands over SSH
    
## Jenkins In This Command Add

```bash
# Send File To Ansible Server
rsync -avh /var/lib/jenkins/workspace/<project_name>/Dockerfile root@<ansible_ip>:/opt/
```

## Ansible In This Command Add

```bash
# Trigger Ansible Playbook
cd /opt

# Build Docker image
docker image build -t ${JOB_NAME}v1.${BUILD_ID} .

# Tag image
docker image tag ${JOB_NAME}v1.${BUILD_ID} <DockerHub User Name>/${JOB_NAME}v1.${BUILD_ID}
docker image tag ${JOB_NAME}v1.${BUILD_ID} <DockerHub User Name>/${JOB_NAME}:latest

# Push to Docker Hub
docker image push <DockerHub User Name>/${JOB_NAME}v1.${BUILD_ID}
docker image push <DockerHub User Name>/${JOB_NAME}:latest

# Clean up
docker image rmi ${JOB_NAME}v1.${BUILD_ID} \                 
         <DockerHub User Name>/${JOB_NAME}v1.${BUILD_ID} \
         <DockerHub User Name>/${JOB_NAME}:latest
```

---

## Final Deployment

### Step 30: Trigger Jenkins Job

- Click **Apply and Save**
- Click **Build Now**
- Confirm image is pushed to DockerHub

### Step 31: Deploy Using Ansible

```bash
cd /root/sourcecode
ansible-playbook -i inventory run_container.yml
```

### Step 32: Access Deployed Web App

```url
http://<Docker_Public_Ip>:9000
```

---
![Output Screenshot](D.png)

