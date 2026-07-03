# Infra Repo - DevOps & Kubernetes Learning Guide

This repository demonstrates production-ready infrastructure automation using Terraform, with a focus on EKS (Kubernetes) deployment and best practices. Perfect for interview preparation!

## Architecture-full

```
VPC (10.40.0.0/16)
├── Public Subnets (10.40.1.0/24, 10.40.2.0/24)
│   └── NAT Gateway
└── Private Subnets (10.40.11.0/24, 10.40.12.0/24)
    └── EKS Cluster + Worker Nodes
        ├── Load Balancer Controller (Add-on)
        ├── EBS CSI Driver (Add-on)
        ├── EFS CSI Driver (Add-on)
        └── CloudWatch Observability (Add-on)
```

## Table of Contents

- [Quick Start](#quick-start)
- [Infrastructure Components](#infrastructure-components)
- [Kubernetes Basics](#kubernetes-basics)
- [Kubernetes Objects](#kubernetes-objects)
- [Storage: EBS vs EFS](#storage-ebs-vs-efs)
- [IRSA - IAM Roles for Service Accounts](#irsa---iam-roles-for-service-accounts)
- [Step-by-Step Kubernetes Deployment](#step-by-step-kubernetes-deployment)
- [Interview Q&A](#interview-qa)
- [Troubleshooting](#troubleshooting)

## Quick Start

### 1. Deploy Infrastructure

```bash
# Initialize Terraform with S3 backend
terraform init

# Plan infrastructure
terraform plan

# Apply (creates VPC + EKS cluster)
terraform apply
```

### 2. Connect to Kubernetes Cluster

```bash
# Get the configure command from Terraform outputs
terraform output configure_kubectl

# Run it (example):
aws eks update-kubeconfig --region us-east-1 --name dev-eks-cluster

# Verify connection
kubectl cluster-info
kubectl get nodes
```

## Infrastructure Components

### VPC Module

- **Public Subnets**: NAT Gateway, Application Load Balancer
- **Private Subnets**: Worker nodes, RDS, EFS
- **High Availability**: Multi-AZ deployment (us-east-1a, us-east-1b)

### EKS Module

Features:
- ✅ Managed Kubernetes control plane
- ✅ Auto-scaling worker nodes
- ✅ OIDC Provider for IRSA
- ✅ CloudWatch logging
- ✅ 4 Production add-ons

## Kubernetes Basics

### What is Kubernetes?

Kubernetes is an **orchestration platform** for containerized applications. It handles:

- **Container Scheduling**: Run containers on available nodes
- **Load Balancing**: Distribute traffic across pods
- **Auto-scaling**: Scale pods and nodes based on demand
- **Self-healing**: Restart failed containers
- **Rolling Updates**: Deploy new versions without downtime

### Kubernetes Architecture

```
┌─────────────────────────────────┐
│   Kubernetes Control Plane      │
│   (AWS-managed in EKS)          │
│   ├── API Server                │
│   ├── etcd (State Store)        │
│   ├── Scheduler                 │
│   └── Controller Manager        │
└─────────────────────────────────┘
           ↓
┌─────────────────────────────────┐
│      Worker Nodes (EC2)         │
│   ├── Pod (Container 1)         │
│   ├── Pod (Container 2)         │
│   └── kubelet (Node Agent)      │
└─────────────────────────────────┘
```

### Key Terms

| Term | Definition |
|------|-----------|
| **Pod** | Smallest deployable unit, contains 1+ containers |
| **Node** | Worker machine (EC2 instance) running pods |
| **Cluster** | Collection of nodes + control plane |
| **Container** | Docker image running in a pod |
| **Deployment** | Declarative way to manage pods (replicas) |
| **Service** | Network abstraction to expose pods |
| **Namespace** | Virtual cluster within a cluster |

## Kubernetes Objects

### 1. Pod - Smallest Unit

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
```

**Use case**: Quick testing
**Reality**: Never run single pods in production

### 2. Deployment - Manage Replicas

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
```

**Use case**: Production applications
**Benefits**: Auto-restart, rolling updates, scaling

### 3. Service - Network Access

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  type: LoadBalancer  # Creates AWS ALB
  ports:
  - port: 80
    targetPort: 80
```

**Types**:
- `ClusterIP`: Internal only
- `NodePort`: External on fixed port
- `LoadBalancer`: AWS ALB/NLB (requires AWS Load Balancer Controller add-on)

### 4. ConfigMap - Configuration

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_ENV: "production"
  LOG_LEVEL: "info"
```

### 5. Secret - Sensitive Data

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
type: Opaque
data:
  password: aGVsbG8xMjM=  # base64 encoded
```

### 6. StatefulSet - Ordered Pods

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:latest
```

**Use case**: Databases, stateful applications
**Difference from Deployment**: Pods have persistent identity (mysql-0, mysql-1, mysql-2)

## Storage: EBS vs EFS

### EBS (Elastic Block Store)

```yaml
# PersistentVolumeClaim using EBS
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ebs-claim
spec:
  accessModes:
    - ReadWriteOnce  # Single pod
  storageClassName: ebs-sc
  resources:
    requests:
      storage: 10Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: app-with-ebs
spec:
  containers:
  - name: app
    image: myapp:latest
    volumeMounts:
    - name: data
      mountPath: /var/lib/data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: ebs-claim
```

**Characteristics**:
- Block storage (like external hard drive)
- Single attachment (one pod at a time)
- Better for databases
- Automatically provisions AWS EBS volume

### EFS (Elastic File System)

```yaml
# PersistentVolumeClaim using EFS
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-claim
spec:
  accessModes:
    - ReadWriteMany  # Multiple pods
  storageClassName: efs-sc
  resources:
    requests:
      storage: 10Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: app-with-efs
spec:
  containers:
  - name: app
    image: myapp:latest
    volumeMounts:
    - name: data
      mountPath: /var/lib/data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: efs-claim
```

**Characteristics**:
- File storage (NFS)
- Multiple attachments (many pods)
- Better for shared data
- Automatically provisions AWS EFS mount

### Quick Comparison

| Feature | EBS | EFS |
|---------|-----|-----|
| Type | Block Storage | File Storage |
| Attachment | Single | Multiple |
| Use Case | Databases | Shared data, logs |
| Performance | High IOPS | Moderate |
| Cost | Lower | Higher |

## IRSA - IAM Roles for Service Accounts

### Problem Without IRSA

```yaml
# BAD: Credentials hardcoded in pod
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  containers:
  - name: app
    image: myapp
    env:
    - name: AWS_ACCESS_KEY_ID
      value: AKIAIOSFODNN7EXAMPLE  # EXPOSED!
    - name: AWS_SECRET_ACCESS_KEY
      value: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY  # EXPOSED!
```

**Risks**: Credentials in plaintext, hard to rotate, exposed if pod is compromised

### Solution With IRSA

```yaml
# GOOD: Pod assumes IAM role via OIDC
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app-sa
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/my-app-role

---
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  serviceAccountName: my-app-sa
  containers:
  - name: app
    image: myapp
    # No hardcoded credentials!
```

### IRSA Flow

```
1. Pod starts
   ↓
2. Kubelet injects OIDC token into pod
   ↓
3. Pod calls AWS STS AssumeRoleWithWebIdentity
   ↓
4. OIDC Provider validates token
   ↓
5. STS returns temporary credentials
   ↓
6. Pod uses credentials to access AWS services (S3, DynamoDB, etc.)
```

### Why IRSA Matters for Interview

**IRSA demonstrates**:
- Understanding of cloud security
- Principle of least privilege
- Integration of Kubernetes and AWS IAM
- Modern DevOps practices

## Step-by-Step Kubernetes Deployment

### Step 1: Create Namespace

```bash
kubectl create namespace myapp
```

### Step 2: Create ConfigMap

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: myapp
data:
  APP_ENV: "production"
  LOG_LEVEL: "info"
EOF
```

### Step 3: Create ServiceAccount with IRSA

```bash
# First, create IAM role (manually or via Terraform)
# Then create service account with annotation:

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: myapp-sa
  namespace: myapp
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/myapp-role
EOF
```

### Step 4: Create Deployment

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      serviceAccountName: myapp-sa
      containers:
      - name: app
        image: nginx:latest
        ports:
        - containerPort: 80
        env:
        - name: APP_ENV
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: APP_ENV
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
EOF
```

### Step 5: Expose with Service

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: myapp-svc
  namespace: myapp
spec:
  type: LoadBalancer
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 80
EOF

# Wait for external IP
kubectl get svc -n myapp --watch
```

### Step 6: Create Ingress

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  namespace: myapp
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-svc
            port:
              number: 80
EOF

# Get ALB URL
kubectl get ingress -n myapp myapp-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### Step 7: Monitor

```bash
# View pod logs
kubectl logs -n myapp deployment/myapp

# View pod resources
kubectl top pods -n myapp

# Describe deployment
kubectl describe deployment -n myapp myapp

# Scale deployment
kubectl scale deployment myapp --replicas=5 -n myapp
```

## Interview Q&A

### Q1: What is Kubernetes and why is it important?

**Answer**: Kubernetes is a container orchestration platform that automates deployment, scaling, and management of containerized applications. It's important because it:
- Handles container scheduling and resource management
- Provides self-healing (restarts failed containers)
- Enables rolling updates with zero downtime
- Allows auto-scaling based on demand
- Is cloud-agnostic (works on any cloud)

**Interview Tip**: Mention real-world benefits like reduced operational overhead, faster deployments, and easier scaling.

### Q2: Explain the difference between Deployment and StatefulSet

**Answer**:
- **Deployment**: For stateless apps (web servers, APIs). Pods are interchangeable.
- **StatefulSet**: For stateful apps (databases, caches). Pods have persistent identity (db-0, db-1, db-2).

**Example**: Use Deployment for nginx, use StatefulSet for MySQL.

### Q3: What is IRSA and why is it important?

**Answer**: IRSA (IAM Roles for Service Accounts) allows Kubernetes pods to assume AWS IAM roles without hardcoding credentials. Important because:
- Credentials are temporary and auto-rotating
- Follows principle of least privilege
- No exposed secrets in pod configuration
- Integrates Kubernetes with AWS IAM

**Interview Tip**: Show understanding of cloud security best practices.

### Q4: Explain EBS vs EFS in Kubernetes

**Answer**:
- **EBS**: Block storage, single-attachment, good for databases
- **EFS**: File storage, multi-attachment, good for shared data

```
EBS = External hard drive (one computer at a time)
EFS = Network file share (many computers)
```

### Q5: What are Kubernetes add-ons and name 4 in this repo

**Answer**: Add-ons are Kubernetes extensions managed by AWS. In this repo:
1. **AWS Load Balancer Controller**: Creates ALB/NLB for Ingress
2. **EBS CSI Driver**: Provisions EBS volumes for pods
3. **EFS CSI Driver**: Provisions EFS volumes for pods
4. **CloudWatch Observability**: Sends logs/metrics to CloudWatch

### Q6: Explain pod lifecycle

**Answer**: Pod states:
1. **Pending**: Awaiting resources
2. **Running**: Container is running
3. **Succeeded**: Container completed successfully
4. **Failed**: Container exited with error
5. **Unknown**: Can't determine state

**Interview Tip**: Mention kubectl commands like `kubectl get pods`, `kubectl logs`, `kubectl describe`.

### Q7: What is a Service and name 3 types

**Answer**: Service is network abstraction that exposes pods.

Types:
1. **ClusterIP**: Internal-only (default)
2. **NodePort**: External on fixed port (31000-32767)
3. **LoadBalancer**: AWS ALB/NLB

```
ClusterIP: Only accessible from within cluster
NodePort: Accessible via NODE_IP:31000
LoadBalancer: Accessible via AWS ALB URL
```

### Q8: How would you deploy an application to EKS?

**Answer** (Step-by-step):
1. Create Dockerfile and push to ECR
2. Create Kubernetes manifests (Deployment, Service, etc.)
3. Create ServiceAccount with IRSA if app needs AWS permissions
4. Apply manifests with `kubectl apply`
5. Monitor with `kubectl logs`, `kubectl top`, CloudWatch

**Interview Tip**: Mention CI/CD integration (GitOps, ArgoCD).

## Troubleshooting

### Pod stuck in Pending

```bash
# Check events
kubectl describe pod POD_NAME

# Usually: node resources insufficient
# Solution: scale node group or reduce pod resource requests
```

### Pod can't access AWS services

```bash
# Check service account IRSA annotation
kubectl describe sa SERVICE_ACCOUNT

# Check assumed role inside pod
kubectl exec POD -- aws sts get-caller-identity

# Check IAM role trust relationship
aws iam get-role --role-name ROLE_NAME
```

### LoadBalancer service stuck in "pending"

```bash
# Check AWS Load Balancer Controller addon
kubectl get addon -n kube-system

# Check controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

### PersistentVolume not provisioning

```bash
# Check CSI driver status
kubectl get addon -n kube-system | grep csi

# Check PVC status
kubectl describe pvc PVC_NAME

# Check CSI controller logs
kubectl logs -n kube-system -l app=ebs-csi-controller
```

## Remote state backend

This repo uses an S3 backend for Terraform state.

In GitHub Actions, the workflow initializes Terraform with the S3 backend using the following values:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `TF_STATE_BUCKET`

The state file key is set per branch as:

`infra-repo/${{ github.event_name == 'pull_request' && github.base_ref || github.ref_name }}.tfstate`

## Next Steps for Interview Prep

1. **Deploy this repo**: Practice the infrastructure setup
2. **Deploy apps**: Try deploying a sample app to EKS
3. **Use storage**: Create PVCs with EBS and EFS
4. **Setup IRSA**: Create custom IAM roles for service accounts
5. **Monitor**: Use CloudWatch to view logs and metrics
6. **Scale**: Test auto-scaling with load testing

## Resources

- [Kubernetes Official Docs](https://kubernetes.io/docs/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [IRSA Guide](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
