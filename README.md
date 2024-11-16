# Blue/Green Deployment Project for t2s-services.com

This project sets up a Blue/Green deployment for `t2s-services.com` using Minikube, Docker, and NGINX. The Blue environment has a blue background, while the Green environment has a green background. You can switch between these environments, ensuring high availability and minimal downtime.

---

## Prerequisites

1. **Install Minikube**:
Follow the official instructions: [Minikube Installation Guide](https://minikube.sigs.k8s.io/docs/start/)

2. **Install kubectl**:
[Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

4. **Install Docker** (if not already installed):
Follow the instructions for your operating system: [Docker Installation Guide](https://docs.docker.com/get-docker/)

---

## Steps

### Step 1: Start Minikube

Start Minikube to create a local Kubernetes cluster:

```bash
minikube start
```

### Step 2: Configure Docker to Use Minikube’s Docker Daemon

```bash
eval $(minikube docker-env)
```

### Step 3: Create the following Structure

### Step 4: Create the Blue and Green Applications

Blue Application
- blue/index.html:
```bash
<!DOCTYPE html>
<html>
<head>
    <title>Blue Environment</title>
    <style>
        body {
            background-color: blue;
            color: white;
            font-family: Arial, sans-serif;
            text-align: center;
            padding-top: 50px;
        }
    </style>
</head>
<body>
    <h1>Welcome to the Blue Environment!</h1>
</body>
</html>
```
- blue/Dockerfile
```bash
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
```

Green Application 
- green/index.html
```bash
<!DOCTYPE html>
<html>
<head>
    <title>Green Environment</title>
    <style>
        body {
            background-color: green;
            color: white;
            font-family: Arial, sans-serif;
            text-align: center;
            padding-top: 50px;
        }
    </style>
</head>
<body>
    <h1>Welcome to the Green Environment!</h1>
</body>
</html>
```
- green/Dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html

### Step 5: Build the Docker Images
Build the Blue image
```bash
docker build -t blue-app ./blue
```

Build the Green image
```bash
docker build -t green-app ./green
```

Verify images
```bash
docker images
```

### Step 6: Create The Kubernetes Deployment Configurations

Blue Deployment ((k8s/blue-deployment.yaml):
```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: blue-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: blue
  template:
    metadata:
      labels:
        app: blue
    spec:
      containers:
      - name: blue-container
        image: blue-app
        ports:
        - containerPort: 80
```

Green Deployment (k8s/green-deployment.yaml):
```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: green-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: green
  template:
    metadata:
      labels:
        app: green
    spec:
      containers:
      - name: green-container
        image: green-app
        ports:
        - containerPort: 80
```

### Step 7: Create The Service Configuration
Service Configuration (K8s/service.yaml):
```bash
apiVersion: v1
kind: Service
metadata:
  name: blue-green-service
spec:
  selector:
    app: blue # Default to route traffic to the Blue deployment
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: NodePort
```

### Step 8: Apply the Kubernetes Configurations
```bash
kubectl apply -f K8s/blue-deployment.yaml
kubectl apply -f K8s/green-deployment.yaml
kubectl apply -f K8s/services.yaml
```

### Step 9: Access the Services
```bash
minikube service blue-service --url
minikube service green-service --url
```

### Step 10: Switch Between Blue and Green 
Route Traffic to Blue:
```bash
kubectl patch service blue-green-service -p '{"spec": {"selector": {"app": "blue"}}}'
kubectl describe service blue-green-service  # To verify the service is routing to Blue.
minikube service blue-green-service # To test the service. 
```

Route Traffic to Blue:
```bash
kubectl patch service blue-green-service -p '{"spec": {"selector": {"app": "green"}}}'
kubectl describe service blue-green-service # To verify the service is routing to Green
minikube service blue-green-service # To test the service.
```

### Step 11: Automate Switching (Optional)
To streamline switching, you can create a shell script and name it switch-traffic.sh:
```bash
#!/bin/bash

if [ "$1" == "blue" ]; then
  kubectl patch service blue-green-service -p '{"spec": {"selector": {"app": "blue"}}}'
  echo "Switched traffic to Blue."
elif [ "$1" == "green" ]; then
  kubectl patch service blue-green-service -p '{"spec": {"selector": {"app": "green"}}}'
  echo "Switched traffic to Green."
else
  echo "Usage: ./switch-traffic.sh [blue|green]"
fi
```

Make the script executable: 
```bash
chmod +x switch-traffic.sh
```

Switch traffic by running: 
```bash
./switch-traffic.sh blue
./switch-traffic.sh green
```

----
### Step 12: Clean Up
* To stop Minikube and remove resources:
```bash
kubectl delete -f blue-deployment.yaml
kubectl delete -f green-deployment.yaml
kubectl delete -f service.yaml
minikube stop
```
