# Blue/Green Deployment Project for t2s-services.com

This project sets up a Blue/Green deployment for `t2s-services.com` using Minikube, Docker, and NGINX. The Blue environment has a blue background, while the Green environment has a green background. You can switch between these environments, ensuring high availability and minimal downtime.

---

## Prerequisites

1. **Install Minikube**:
    - Follow the official instructions: [Minikube Installation Guide](https://minikube.sigs.k8s.io/docs/start/)

2. **Install kubectl**:
    - [Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

3. **Install Docker** (if not already installed):
    - Follow the instructions for your operating system: [Docker Installation Guide](https://docs.docker.com/get-docker/)

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

### Step 3: Create Docker Images for Blue and Green Environments

#### 1.	Create a primary NGINX server:
- Create two HTML files (index-blue.html and index-green.html) with a simple background color for each environment.
- Create a file, name it index-blue.html, and add the following content:
```bash
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Blue Deployment</title>
    <style>
        body {
            background-color: blue;
            color: white;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            font-family: Arial, sans-serif;
        }
        h1 {
            font-size: 3em;
        }
    </style>
</head>
<body>
    <h1>Blue Deployment Environment</h1>
</body>
</html>
```
- Create a file, name it index-green.html, and add the following content:
```bash
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Green Deployment</title>
    <style>
        body {
            background-color: green;
            color: white;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            font-family: Arial, sans-serif;
        }
        h1 {
            font-size: 3em;
        }
    </style>
</head>
<body>
    <h1>Green Deployment Environment</h1>
</body>
</html>
```

#### 2.	Dockerfile:
- Place the following Dockerfile in the project root:
```bash
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
```

#### 3.	Build the Docker images:
```bash
cp index-blue.html index.html
docker build -t t2s-blue .
cp index-green.html index.html
docker build -t t2s-green .
```

### Step 4: Deploy Blue/Green Environments on Minikube

#### 1.	Create Kubernetes Deployment and Service Files:
- Deployment for Blue Environment (blue-deployment.yaml):
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
        ports:
        - containerPort: 80
```

- Deployment for Green Environment (green-deployment.yaml):
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
        ports:
        - containerPort: 80
```

- Service (service.yaml)
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
      targetPort: 80
  type: LoadBalancer
```

#### 2. Apply the Configurations
```bash
kubectl apply -f blue-deployment.yaml
kubectl apply -f green-deployment.yaml
kubectl apply -f service.yaml
```

### Step 5: Switch Between Blue and Green Environments

#### 1. Update the Service to Point to Blue:
```bash
kubectl patch service t2s-service -p '{"spec":{"selector":{"environment":"blue"}}}'
```

#### 2. Update the Service to Point to Green:
```bash
kubectl patch service t2s-service -p '{"spec":{"selector":{"environment":"green"}}}'
```

### Step 6: Verify on Localhost
- Run the following to get the Minikube IP and open in a browser:
```bash
minikube service t2s-service
```

### Step 7: Clean Up
* To stop Minikube and remove resources:
```bash
kubectl delete -f blue-deployment.yaml
kubectl delete -f green-deployment.yaml
kubectl delete -f service.yaml
minikube stop
```
