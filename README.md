# Blue/Green Deployment Project for t2s-services.com

This project sets up a Blue/Green deployment for `t2s-services.com` using Minikube, Docker, and NGINX. The Blue environment has a blue background, while the Green environment has a green background. You can switch between these environments, ensuring high availability and minimal downtime.

---

## Prerequisites

1. **Install Minikube**:
Follow the official instructions: [Minikube Installation Guide](https://minikube.sigs.k8s.io/docs/start/)

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

You can also do it by using Docker Compose. First, install Docker Compose. 

```bash
sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '(?<="tag_name": ")[^"]*')/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```

Now, create a Docker Compose File. 
```bash
mkdir minikube-docker
cd minikube-docker
```

```bash
version: '3.9'

services:
  minikube:
    image: gcr.io/k8s-minikube/minikube:latest
    container_name: minikube
    ports:
      - "8443:8443" # Kubernetes API server
      - "30000-32767:30000-32767" # NodePort range
    privileged: true
    volumes:
      - /var/lib/docker:/var/lib/docker
      - /sys/fs/cgroup:/sys/fs/cgroup
      - /var/run/docker.sock:/var/run/docker.sock
      - ./data:/root/.minikube
    environment:
      - MINIKUBE_IN_STYLE=true
```

Start Mininube
```bash
docker-compose up -d
```

2. **Install kubectl**:
[Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

4. **Install Docker** (if not already installed):
Follow the instructions for your operating system: [Docker Installation Guide](https://docs.docker.com/get-docker/)

```bash
sudo apt update
sudo apt install docker.io -y
sudo systemctl enable --now docker
```

---

## Steps

### Step 1: Start

Start Minikube to create a local Kubernetes cluster:

```bash
minikube start
```

### Step 2: Configure Docker to Use Minikube’s Docker Daemon

```bash
eval $(minikube docker-env)
```

### Step 3: Create the following files
- Create the requirements.txt file and add the following content:
```bash
flask
```
- Create the Flask Application Code for the Blue Environment, app_blue.py:
```bash
from flask import Flask, render_template_string

app = Flask(__name__)

@app.route("/")
def home():
    return render_template_string('''
    <html>
        <head>
            <title>Blue Deployment</title>
        </head>
        <body style="background-color: blue; color: white; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; font-family: Arial, sans-serif;">
            <h1>Blue Deployment Environment</h1>
        </body>
    </html>
    ''')

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
```
- Create the Flask Application Code for the Green Environment, app_green.py:
```bash
from flask import Flask, render_template_string

app = Flask(__name__)

@app.route("/")
def home():
    return render_template_string('''
    <html>
        <head>
            <title>Green Deployment</title>
        </head>
        <body style="background-color: green; color: white; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; font-family: Arial, sans-serif;">
            <h1>Green Deployment Environment</h1>
        </body>
    </html>
    ''')

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
```

### Step 4: Create Dockerfiles for the Blue and Green Environments
- Create the Dockerfile for the Blue Environment, Dockerfile.blue:
```bash
# Use Python base image
FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Copy files and install dependencies
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

# Copy the application code
COPY app_blue.py .

# Run the Flask application
CMD ["python", "app_blue.py"]
```
- Create Dockerfile for the Blue Environment, Dockerfile.green:
```bash
# Use Python base image
FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Copy files and install dependencies
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

# Copy the application code
COPY app_green.py .

# Run the Flask application
CMD ["python", "app_green.py"]
```

### Step 5: Build and Run Docker Images in Minikube
- Enusre you're in Minikube's Docker environment:
```bash
eval $(minikube docker-env)
```
- Build the images:
```bash
docker build -f Dockerfile.blue -t t2s-blue .
docker build -f Dockerfile.green -t t2s-green .
```

### Step 6: Create the Kubernetes Deployment Files
- Use the same Kubernetes deployment setup as before, adjusting the container image to t2s-blue and t2s-green in the deployment YAML files.
- Create the blue-deployment.yaml file:
```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: t2s-blue
spec:
  replicas: 2
  selector:
    matchLabels:
      app: t2s
      environment: blue
  template:
    metadata:
      labels:
        app: t2s
        environment: blue
    spec:
      containers:
      - name: t2s-blue
        image: t2s-blue
        imagePullPolicy: Never
        ports:
        - containerPort: 5000
```
- Create the green-deployment.yaml
```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: t2s-green
spec:
  replicas: 2
  selector:
    matchLabels:
      app: t2s
      environment: green
  template:
    metadata:
      labels:
        app: t2s
        environment: green
    spec:
      containers:
      - name: t2s-green
        image: t2s-green
        imagePullPolicy: Never
        ports:
        - containerPort: 5000
```
- Create the service.yaml file:
```bash
apiVersion: v1
kind: Service
metadata:
  name: t2s-service
spec:
  selector:
    app: t2s
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5000
  type: LoadBalancer
```

### Step 7: Deploy and Validate
- Apply the Configurations:
```bash
kubectl apply -f blue-deployment.yaml
kubectl apply -f green-deployment.yaml
kubectl apply -f service.yaml
```

### Step 8: Switch Between Green and Blue Environments
- Use minikube service t2s-service to expose the service and test the deployment by switching between blue and green environments with:
```bash'
kubectl patch service t2s-service -p '{"spec":{"selector":{"environment":"blue"}}}'
kubectl patch service t2s-service -p '{"spec":{"selector":{"environment":"green"}}}'
```

### Step 9: Verify the Flask-based Blue/Green Deployment in the Browser
- Retrieve the Minikube IP Address:
```bash
minikube IP
```
- Run minikube tunnel (if using LoadBalancer). Keep this terminal window open while testing. 
```bash
minikube tunnel
```
- Check service details. Verify that the t2s-service is running on port 80. If it's on another port, note the port number. 
```bash
kubectl get svc t2s-service
```
- Access the Application in the Browser.
```bash
http://<Minikube-IP>
```

### Step 10: Clean Up
* To stop Minikube and remove resources:
```bash
kubectl delete -f blue-deployment.yaml
kubectl delete -f green-deployment.yaml
kubectl delete -f service.yaml
minikube stop
```
