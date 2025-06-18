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

### Step 32: Jenkins Free Style Shell Script (Option 1)

#### 🖥️ Step 1: Prepare `jenkins.pem` on Jenkins Server (Jenkins)

1. Navigate to Jenkins home directory:
 
```bash
   cd /var/lib/jenkins
```
2. Create and paste your .pem key file:

```bash
nano jenkins.pem
```
3. Save and make it executable:

```bash
chmod +x jenkins.pem
```
#### 🖥️ Step 2: Jenkins Freestyle Project Configuration

- 📌 Git Configuration:
- Go to Jenkins Dashboard → New Item → Freestyle Project.
- Enter a project name and click OK.
- In Source Code Management, choose Git
- Repository URL:<Your GitHub Repo>
- Branch:<Your Repo Branch>

#### Build Step:
- Click Add build step → Execute shell
- Add your script:

```sh
#!/bin/bash
 
# Define variables
ANSIBLE_USER=ubuntu
ANSIBLE_HOST=3.7.253.121              # Ansible EC2 Public IP
PEM_KEY=/var/lib/jenkins/jenkins.pem
JOB_NAME=meet                        # Jenkins Job name
DOCKERHUB_USER=<Your DockerHub User Name>
DOCKERHUB_PASS='<Your DockerHub Password>'
PRIVATE_DOCKER_HOST=172.31.14.70      # Private IP of Docker host from Ansible
 
# Step 1: Generate inventory and playbook on Ansible server
ssh -o StrictHostKeyChecking=no -i "$PEM_KEY" $ANSIBLE_USER@$ANSIBLE_HOST << EOF
 
sudo mkdir -p /root/sourcecode
 
sudo tee /root/sourcecode/inventory > /dev/null <<EOL
[dockerhost]
$PRIVATE_DOCKER_HOST ansible_user=root ansible_become=true
EOL
 
sudo tee /root/sourcecode/run_container.yml > /dev/null <<EOL
- hosts: all
  become: yes
  tasks:
    - name: Run Docker container using Ansible module
      community.docker.docker_container:
        name: cloudknowledge-container
        image: ${DOCKERHUB_USER}/${JOB_NAME}:latest
        state: started
        recreate: true
        published_ports:
          - "9000:80"
EOL
 
EOF
 
# Step 2: Transfer Dockerfile to Ansible server
rsync -avh -e "ssh -o StrictHostKeyChecking=no -i $PEM_KEY" /var/lib/jenkins/workspace/$JOB_NAME/Dockerfile root@$ANSIBLE_HOST:/opt/
 
# Step 3: Build, tag, login, push, clean on Ansible server
ssh -o StrictHostKeyChecking=no -i "$PEM_KEY" $ANSIBLE_USER@$ANSIBLE_HOST << EOF
 
cd /opt
 
# Login to Docker Hub
echo "$DOCKERHUB_PASS" | sudo docker login -u $DOCKERHUB_USER --password-stdin
 
# Build Docker image
sudo docker image build -t ${JOB_NAME}v1.${BUILD_ID} .
 
# Tag image
sudo docker image tag ${JOB_NAME}v1.${BUILD_ID} ${DOCKERHUB_USER}/${JOB_NAME}v1.${BUILD_ID}
sudo docker image tag ${JOB_NAME}v1.${BUILD_ID} ${DOCKERHUB_USER}/${JOB_NAME}:latest
 
# Push to Docker Hub
sudo docker image push ${DOCKERHUB_USER}/${JOB_NAME}v1.${BUILD_ID}
sudo docker image push ${DOCKERHUB_USER}/${JOB_NAME}:latest
 
# Clean up local images
sudo docker image rmi ${JOB_NAME}v1.${BUILD_ID} \
                      ${DOCKERHUB_USER}/${JOB_NAME}v1.${BUILD_ID} \
                      ${DOCKERHUB_USER}/${JOB_NAME}:latest
 
EOF
 
# Step 4: Run playbook from Ansible to Docker Host
ssh -o StrictHostKeyChecking=no -i "$PEM_KEY" $ANSIBLE_USER@$ANSIBLE_HOST << EOF
  sudo ansible-playbook -i /root/sourcecode/inventory /root/sourcecode/run_container.yml
EOF
```

### Step 33: Jenkins Pipeline (Option 2)

#### 🖥️ Step 1: Prepare `jenkins.pem` on Jenkins Server

1. Navigate to Jenkins home directory:
 
```bash
   cd /var/lib/jenkins
```
2. Create and paste your .pem key file:

```bash
nano jenkins.pem
```
3. Save and make it executable:

```bash
chmod +x jenkins.pem
```

4. Permission In File (Ansible)

```bash
sudo chmod 777 /opt
```

#### Add Pipeline:
```groovy
automate project update pipline
 
pipeline {
    agent any
 
    environment {
        ANSIBLE_USER = "ubuntu"
        ANSIBLE_HOST = "3.7.253.121"                    // Ansible EC2 public IP
        PEM_KEY = "/var/lib/jenkins/jenkins.pem"
        JOB_NAME = "meet"                               // Jenkins Job Name
        DOCKERHUB_USER = "<Your DockerHub User Name>"
        DOCKERHUB_PASS = "<Your DockerHub Password>"
        PRIVATE_DOCKER_HOST = "172.31.14.70"            // Docker Host private IP
    }
 
    stages {
        stage('Clone GitHub Repository') {
            steps {
                git branch: 'main', url: '<Your GitHub Repo>'
            }
        }
 
        stage('Transfer Dockerfile to Ansible') {
            steps {
                sh """
                rsync -avh -e "ssh -o StrictHostKeyChecking=no -i $PEM_KEY" $WORKSPACE/Dockerfile $ANSIBLE_USER@$ANSIBLE_HOST:/opt/
                """
            }
        }
 
        stage('Build and Push Docker Image on Ansible') {
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no -i "$PEM_KEY" $ANSIBLE_USER@$ANSIBLE_HOST << 'EOF'
                cd /opt
 
                echo "$DOCKERHUB_PASS" | sudo docker login -u $DOCKERHUB_USER --password-stdin
 
                sudo docker image build -t ${JOB_NAME}v1.${BUILD_ID} .
 
                sudo docker image tag ${JOB_NAME}v1.${BUILD_ID} ${DOCKERHUB_USER}/${JOB_NAME}v1.${BUILD_ID}
                sudo docker image tag ${JOB_NAME}v1.${BUILD_ID} ${DOCKERHUB_USER}/${JOB_NAME}:latest
 
                sudo docker image push ${DOCKERHUB_USER}/${JOB_NAME}v1.${BUILD_ID}
                sudo docker image push ${DOCKERHUB_USER}/${JOB_NAME}:latest
 
                sudo docker image rmi ${JOB_NAME}v1.${BUILD_ID} \\
                                     ${DOCKERHUB_USER}/${JOB_NAME}v1.${BUILD_ID} \\
                                     ${DOCKERHUB_USER}/${JOB_NAME}:latest
EOF
                """
            }
        }
 
        stage('Create Inventory & Playbook on Ansible') {
  steps {
    sh """
    ssh -o StrictHostKeyChecking=no -i $PEM_KEY $ANSIBLE_USER@$ANSIBLE_HOST << 'EOF'
    sudo mkdir -p /root/sourcecode
 
    sudo tee /root/sourcecode/inventory > /dev/null <<EOL
[dockerhost]
$PRIVATE_DOCKER_HOST ansible_user=root ansible_become=true
EOL
 
    sudo tee /root/sourcecode/run_container.yml > /dev/null <<EOL
- hosts: all
  become: yes
  tasks:
    - name: Pull latest image manually
      ansible.builtin.shell: docker pull ${DOCKERHUB_USER}/${JOB_NAME}:latest
 
    - name: Stop and remove old container
      community.docker.docker_container:
        name: cloudknowledge-container
        state: absent
 
    - name: Run updated container
      community.docker.docker_container:
        name: cloudknowledge-container
        image: ${DOCKERHUB_USER}/${JOB_NAME}:latest
        state: started
        recreate: true
        published_ports:
          - "9000:80"
EOL
 
EOF
    """
  }
}
 
 
        stage('Run Ansible Playbook to Deploy') {
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no -i "$PEM_KEY" $ANSIBLE_USER@$ANSIBLE_HOST << 'EOF'
                sudo ansible-playbook -i /root/sourcecode/inventory /root/sourcecode/run_container.yml
EOF
                """
            }
        }
    }
 
    post {
        success {
            echo "✅ Deployment successful. Visit your project at http://<Docker-Public-IP>:9000"
        }
        failure {
            echo "❌ Deployment failed. Check the logs above."
        }
    }
}
```
 
### Step 34: Access Deployed Web App

```url
http://<Docker_Public_Ip>:9000
```

---
![Output Screenshot](D.png)

