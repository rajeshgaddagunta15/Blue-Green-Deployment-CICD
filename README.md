# 🚀Zero Downtime Deployment: Blue-Green Deployment Strategy for Java MySQL Application on EKS🚀

![Workflow-DIagram](https://github.com/user-attachments/assets/e5569c23-755a-4c7e-a9bf-dedd1eb2dd10)


# Complete END to END Workflow Diagram:


🛠 In today's fast-paced development environment, ensuring application availability and minimizing downtime during deployment is crucial. One of the most effective deployment strategies to achieve this is blue-green deployment, which allows for seamless updates and faster rollbacks in case of issues.

🛠 We will be deploying a **Java-based MySQL application** using **blue-green deployment** to achieve **zero downtime** and rapid rollback. \
We'll leverage a **CI/CD** pipeline integrated with IAC as **Terraform** for provisioning an **Amazon EKS cluster** and tools like **Git, Maven, SonarQube, Trivy, Nexus, Docker, and Kubernetes** to automate the entire deployment process.

# What is Blue-Green Deployment?

🌐Blue-green deployment is a deployment strategy designed to reduce downtime and minimize the risks involved in releasing new software versions. In this approach, two identical environments are maintained: Blue (the currently live environment) and Green (the environment with the new application version).

# Here’s how it works:

🌐Blue Environment (Current Production): The "blue" environment runs the live version of the application.

🌐Green Environment (New Version): The new version of the application is deployed to the "green" environment, which is identical to the blue environment.

🌐Switching Traffic: Once the green environment is fully tested and validated, traffic is seamlessly switched from the blue to the green environment. This ensures that users experience no downtime.

🌐Rollback: In case of any issues with the green environment, traffic can easily be switched back to the blue environment, providing a fast and reliable rollback option.

############################################################################################################################

# Steps to have a fully automated pipeline that ensures smooth application updates with zero downtime, high availability, and robust security checks:

# 1 Provision and Configure EKS :
  Create EC2 ubuntu and ssh into the instance:

✅ Update the instance:
 sudo apt update

✅ Install AWS CLI::
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install

✅ Install terraform:


✅ Clone the git repository for the EKS cluster code:

✅ Provision Infrastructure using terraform go into the folder:
 # Terraform initialization command
 terraform init

 # Terrafrom plan for planning resources
 terraform plan

 # Terraform apply command to apply changes to AWS
 terraform apply --auto-approve

✅ Connecting to the cluster:
 aws eks --region ap-south-1 update-kubeconfig --name cluster-name

✅To access the EKS cluster using the Jenkins pipeline we need Jenkins to have access to EKS, for that we will be creating the Service Account in webapps namespace which jenkins will use to access the EKS resources.

 # Creating namespace webapps in EKS:
      kubectl create ns webapps

✅ Creating service account first create service_acc.yml with content as:  
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: jenkins
      namespace: webapps

✅ Now we will be creating role to attach with the service account we will create a file role.yml with content:  
    apiVersion: rbac.authorization.k8s.io/v1
    kind: Role
    metadata:
      name: app-role
      namespace: webapps
    rules:
      - apiGroups:
            - ""
            - apps
            - autoscaling
            - batch
            - extensions
            - policy
            - rbac.authorization.k8s.io
        resources:
          - pods
          - secrets
          - componentstatuses
          - configmaps
          - daemonsets
          - deployments
          - events
          - endpoints
          - horizontalpodautoscalers
          - ingress
          - jobs
          - limitranges
          - namespaces
          - nodes
          - pods
          - persistentvolumes
          - persistentvolumeclaims
          - resourcequotas
          - replicasets
          - replicationcontrollers
          - serviceaccounts
          - services
        verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]


✅ Next step is to assign the created role to the service account i.e. binding the role to service account for that create file bind_role.yml with content:
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: app-rolebinding
      namespace: webapps 
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: Role
      name: app-role 
    subjects:
    - namespace: webapps 
      kind: ServiceAccount
      name: jenkins
      
  ✅ Next create secret token for the jenkins service account, will create file jenkins_token.yml with content:
    apiVersion: v1
    kind: Secret
    type: kubernetes.io/service-account-token
    metadata:
      name: mysecretname
      annotations:
        kubernetes.io/service-account.name: jenkins

✅  We will be using this secret for jenkins to EKS communication, to get the token run command:
      kubectl describe secret mysecretname -n webapps

###########################################################################################################################

# 2. Jenkins, SonarQube and Nexus:

✅Create 3 t2.medium ubuntu EC2 instances with 25 GB Storage.Name them as Jenkins, SonarQube and Nexus.

✅Configure Jenkins Instance:

✅SSH into the jenkins instance.

✅Install Java for Jenkins:

✅ Install Jenkins:
   # Download Jenkins GPG key
 sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
   https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

 # Add Jenkins repository to package manager sources
 echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
   https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
   /etc/apt/sources.list.d/jenkins.list > /dev/null

 # Update package manager repositories
 sudo apt-get update

 # Install Jenkins
 sudo apt-get install jenkins -y

 #Enable jenkins
 sudo systemctl enable jenkins

✅Access the jenkins server on <ec2-public-ip>:8080 and provide username as admin and password we will get using the command:

✅Install plugins in jenkins by clicking Dashboard > Manage Jenkins > Plugins:

- SonarQube scanner

- Config File Provider

- Maven Integration

- Pipeline Maven Integration

- Kubernetes

- Kubernetes Credentials

- Kubernetes CLI

- Kubernetes Client API

- Docker

- Docker Pipeline

- Pipeline stage view

✅Installing Tools:

In Jenkins > Tools

Maven: name= maven3; Install from apache;

SonarQube Scanner: name=sonar-scanner; Install from maven central;

✅ Install docker on Jenkins server using:
 sudo apt-get update
 sudo apt-get install ca-certificates curl
 sudo install -m 0755 -d /etc/apt/keyrings
 sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
 sudo chmod a+r /etc/apt/keyrings/docker.asc

 # Add the repository to Apt sources:
 echo \
   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
   $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
 sudo apt-get update

 sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

 sudo chmod 666 /var/run/docker.sock

✅Install Trivy:
 sudo apt-get install wget apt-transport-https gnupg lsb-release
 wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
 echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
 sudo apt-get update
 sudo apt-get install trivy

✅Install kubectl on Jenkins instance:

✅Configure SonarQube Server:

-SSH into the sonarqube instance.

-Install docker on the instance:

✅Run the sonarqube container:
  docker run -d --name sonar -p 9000:9000 sonarqube:lts-community

✅You can access the sonarqube using the <sonar-ec2-public-ip>:9000.

✅Next to sign in into sonarqube enter username: admin and password: admin.

✅Create token by clicking Administration > Security > Users > Generate token > copy token. 

✅Configure Nexus Server:

-SSH into the nexus instance.

-Install docker on the instance:

✅Run Nexus container:
  docker run -d --name nexus -p 8081:8081 sonatype/nexus3:latest

✅You can access the nexus using the <nexus-ec2-public-ip>:8081.

✅Next to you need to sign in into nexus using the username: admin and password we need to check for the file /nexus-data/admin.password inside the nexus container for that follow below commands:
   sudo docker exec -it containerid /bin/bash
   cd sonatype-work   
   cd nexus3 
   cat admin.password

#############################################################################################################################

# 3. Adding Credentials in Jenkins:
✅ To store credentials inside Jenkins, go to Jenkins > Manage Jenkins > Manage Credentials > System > Global Credentials > Add credentials >

-Git Credentials: Username & Password (github username:token)

-DockerHub: Username with password ( dockerhub username:password ).

-SonarQube: Secret Text ( Copied SonarQube token).

-Kubernetes: Secret Text ( jenkins service account token).


###############################################################################################################################

# 4. Adding Sonar Scanner in Jenkins:
✅ To configure sonarqube server go to Jenkins server > Dashboard > Manage Jenkins > System

-Under SonarQube server click on add SonarQube

-Add name= sonar-server

-url= <sonarserver-ip>:9000

-Select created credential as token. Click Apply.

![image](https://github.com/user-attachments/assets/435f8dac-47a4-4670-8159-72e84366242c)


#################################################################################################################################

# 5. Configure Nexus:
-Add URL to pom.xml

-To configure nexus first go to nexus > browse > copy maven releases url and paste it in the <maven-release> url section inside pom.xml of source code.

-For maven-snapshot copy the url from nexus > browse > copy maven-snapshot url and paste in the <maven-snapshots> url section inside pom.xml of source code.

  <distributionManagement>
          <repository>
              <id>maven-releases</id>
              <url>http://3.110.172.144:8081/repository/maven-releases/</url>
          </repository>
          <snapshotRepository>
              <id>maven-snapshots</id>
              <url>http://3.110.172.144:8081/repository/maven-snapshots/</url>
          </snapshotRepository>
  </distributionManagement>


 ✅ Nexus Credentials:

Go to Jenkins > Dashboard > Manage Jenkins > Managed Files > Click Add new config > Id= maven-settings > Next

You will get the maven settings file, inside file find the <server> </server> section and uncomment it. And make 2 copies of it.

  <server>
      <id>maven-releases</id>
      <username>nexus_username</username>
      <password>nexus_password</password>
  </server>
  <server>
      <id>maven-snapshots</id>
      <username>nexus_username</username>
      <password>nexus_password</password>
  </server>


####################################################################################################################################

# 6. Creating Jenkins Pipeline:
Click Dashboard > New Item > Project name > select pipeline > OK

Click Discard old builds > Max build =2

Next create pipeline:

![jenkins_pipeline](https://github.com/user-attachments/assets/b3a405fb-545d-455e-8ce1-2cc5136bfa0f)




# Eks cluster provisioned using Terraform:
![eks-mobax](https://github.com/user-attachments/assets/80de3f8b-27ad-4c75-af65-8c5ec9a08c7d)

![eks-cluster](https://github.com/user-attachments/assets/d1d035e1-79fd-4a23-83de-09860e33fae0)




# After Running pipeline again and selecting parameter version as green we can see both blue and green version being deployed:

![pods-services-deploymentsets](https://github.com/user-attachments/assets/d1ec9f2e-de8f-4a14-ba70-b94205d07c42)




# Artifact got created and published to Nexus Repository:
![nexus-artifact](https://github.com/user-attachments/assets/08eb6bfe-258b-4b20-9b61-57041888857f)


# Docker image pushed to dockerhub reguistry:

![docker-hub](https://github.com/user-attachments/assets/3e012f1c-f55d-40ab-b971-323cf9105488)


# Servers used for provisioning the different tools and servers:
![ec2-instances](https://github.com/user-attachments/assets/f1f00746-9aa8-456c-94f9-f99c5377d334)

# App got deployed and can be accessed with the LoadBalancer Url:
![blue-deploy](https://github.com/user-attachments/assets/f4f33c2a-a33e-43d3-90df-6050aa7d87a0)












        




      








 



