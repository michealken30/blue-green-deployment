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

### Configure Docker to Use Minikube’s Docker Daemon

```bash
eval $(minikube docker-env)
```

### Create the following Structure

----
### Clean Up
* To stop Minikube and remove resources:
```bash
kubectl delete -f blue-deployment.yaml
kubectl delete -f green-deployment.yaml
kubectl delete -f service.yaml
minikube stop
```
