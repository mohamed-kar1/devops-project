# Projet Final DevOps - Master DSBD & IA 2026

## Architecture

```
Internet → NodePort 30080 → K8s Service → Pods (port 8080) → Flask API
                                            ↑
                              GitHub Actions CI/CD
                              (test → build → deploy)
```

> **Note ports** : Les ports 5000 et 3000 étant déjà utilisés, l'application tourne sur le **port 8080** et est exposée via NodePort **30080**.

---

## Structure du projet

```
devops-project/
├── app/
│   ├── app.py              # Application Flask (port 8080)
│   ├── requirements.txt
│   └── test_app.py         # Tests pytest
├── docker/
│   ├── Dockerfile          # Image Docker (EXPOSE 8080)
│   └── .dockerignore
├── terraform/
│   ├── main.tf             # 2 VMs AWS t2.micro (free tier)
│   └── variables.tf
├── ansible/
│   ├── inventory/hosts.ini
│   └── playbooks/
│       ├── setup-cluster.yml   # Install Docker + K8s
│       └── deploy-app.yml      # Deploy sur K8s
├── k8s/
│   ├── deployment.yaml     # 2 replicas, port 8080
│   └── service.yaml        # NodePort 30080
└── .github/workflows/
    └── ci-cd.yml           # GitHub Actions pipeline
```

---

## ÉTAPE PAR ÉTAPE

### Pré-requis locaux

```bash
# Installer Terraform
wget https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip
unzip terraform_1.7.0_linux_amd64.zip && sudo mv terraform /usr/local/bin/

# Installer Ansible (attention version Python)
pip3 install ansible --break-system-packages
# ou
python3 -m pip install ansible

# Vérifier
terraform --version
ansible --version
```

---

### ÉTAPE 1 — Générer une clé SSH

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

---

### ÉTAPE 2 — Créer les VMs avec Terraform

```bash
cd terraform/

# Configurer vos credentials AWS
export AWS_ACCESS_KEY_ID="votre_access_key"
export AWS_SECRET_ACCESS_KEY="votre_secret_key"
export AWS_DEFAULT_REGION="eu-west-3"

# Initialiser Terraform
terraform init

# Valider la configuration
terraform plan

# Créer les ressources
terraform apply -auto-approve

# Récupérer les IPs
terraform output
# master_ip = "X.X.X.X"
# worker_ip  = "Y.Y.Y.Y"
```

> ⚠️ **Libérez les ressources** quand vous ne travaillez pas : `terraform destroy`

---

### ÉTAPE 3 — Configurer l'inventaire Ansible

```bash
# Remplacer les IPs dans l'inventaire
sed -i 's/MASTER_IP/X.X.X.X/' ansible/inventory/hosts.ini
sed -i 's/WORKER_IP/Y.Y.Y.Y/' ansible/inventory/hosts.ini

# Tester la connexion
ansible all -i ansible/inventory/hosts.ini -m ping
```

---

### ÉTAPE 4 — Installer Docker et Kubernetes avec Ansible

```bash
cd ansible/

# Lancer le playbook d'installation
ansible-playbook -i inventory/hosts.ini playbooks/setup-cluster.yml

# Durée estimée : 10-15 minutes
```

---

### ÉTAPE 5 — Tester l'application localement

```bash
cd app/

# Installer les dépendances
pip3 install -r requirements.txt

# Lancer les tests
pytest test_app.py -v

# Tester en local sur port 8080
PORT=8080 python app.py
curl http://localhost:8080/health
```

---

### ÉTAPE 6 — Build et Push Docker

```bash
# Se connecter à DockerHub
docker login

# Build de l'image (depuis le dossier racine)
docker build -f docker/Dockerfile -t votre-username/devops-api:latest ./app

# Push sur DockerHub
docker push votre-username/devops-api:latest

# Mettre à jour k8s/deployment.yaml avec votre username DockerHub
sed -i 's/votre-dockerhub-username/votre-username/' k8s/deployment.yaml
```

---

### ÉTAPE 7 — Déployer sur Kubernetes

```bash
# Se connecter au master
ssh ubuntu@MASTER_IP

# Copier les manifests
scp -r k8s/ ubuntu@MASTER_IP:/home/ubuntu/

# Sur le master, appliquer les manifests
kubectl apply -f /home/ubuntu/k8s/

# Vérifier le déploiement
kubectl get pods
kubectl get services

# L'API est accessible sur : http://MASTER_IP:30080
curl http://MASTER_IP:30080/health
curl http://MASTER_IP:30080/api/info
```

---

### ÉTAPE 8 — CI/CD avec GitHub Actions

1. Pousser le projet sur GitHub
2. Aller dans **Settings > Secrets and variables > Actions**
3. Ajouter les secrets :
   - `DOCKERHUB_USERNAME` : votre username DockerHub
   - `DOCKERHUB_TOKEN` : votre token DockerHub
   - `KUBECONFIG` : contenu de `~/.kube/config` encodé en base64

```bash
# Encoder le kubeconfig (récupéré depuis le master)
scp ubuntu@MASTER_IP:~/.kube/config ./kubeconfig
cat kubeconfig | base64 -w 0
# Coller le résultat dans le secret KUBECONFIG
```

4. Chaque push sur `main` déclenche automatiquement : **test → build → deploy**

---

### ÉTAPE 9 — Monitoring (Optionnel)

```bash
# Sur le master, déployer le stack Prometheus + Grafana
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/kube-prometheus/main/manifests/setup/

# Accès Grafana (par défaut admin/admin)
kubectl port-forward svc/grafana 9090:3000 -n monitoring
# → http://localhost:9090 (port-forward local, pas de conflit)
```

---

## Endpoints de l'API

| Route | Description |
|-------|-------------|
| `GET /` | Page d'accueil + statut |
| `GET /health` | Health check (utilisé par K8s) |
| `GET /api/info` | Informations sur l'app |

---

## Vérifications utiles

```bash
# État du cluster
kubectl get nodes
kubectl get pods --all-namespaces

# Logs d'un pod
kubectl logs -l app=devops-api

# Vérifier le service
kubectl describe service devops-api-service

# Lens (UI pour Kubernetes)
# Télécharger sur https://k8slens.dev/
```

---

## ⚠️ Points importants

- Les ports **5000** et **3000** sont déjà utilisés → l'app utilise **8080**
- NodePort exposé : **30080**
- Utiliser les instances **t2.micro** (750h/mois free tier AWS)
- **Toujours** faire `terraform destroy` quand vous ne travaillez pas
- Vérifier les IPs dans `ansible/inventory/hosts.ini` après `terraform apply`
