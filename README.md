# CTSE Lab 7 – Azure Microservices Deployment

**SE4010 – Current Trends in Software Engineering | SLIIT**

---

## Project Structure

```
Lab 7/
├── gateway/                  # Node.js API Gateway microservice
│   ├── server.js             # Express server with /health, /api/status, /api/services
│   ├── package.json
│   ├── Dockerfile            # Production Docker image (node:18-alpine)
│   └── .dockerignore
├── frontend/
│   └── index.html            # Static Web App dashboard UI
├── deploy.ps1                # PowerShell deployment script (all 6 tasks)
└── README.md
```

---

## Quick Start – Step by Step

### Prerequisites
- Azure CLI (`az --version` ≥ 2.50)
- Docker Desktop (running)
- Active Azure subscription
- Git

---

### Task 1 – Login to Azure

```powershell
az login
az account show
```

---

### Task 2 – Resource Group & Container Registry

```powershell
az group create --name microservices-rg --location eastus

az acr create --resource-group microservices-rg --name sliitmicroregistry22248244 --sku Basic

az acr login --name sliitmicroregistry22248244
```

> Registry name: `sliitmicroregistry22248244` (student ID: IT22248244)

---

### Task 3 – Build & Push Docker Image

```powershell
docker build -t sliitmicroregistry22248244.azurecr.io/gateway:v1 ./gateway
docker images | Select-String "gateway"
docker push sliitmicroregistry22248244.azurecr.io/gateway:v1
az acr repository list --name sliitmicroregistry22248244 --output table
```

---

### Task 4 – Deploy Container App

```powershell
az provider register --namespace Microsoft.App --wait
az provider register --namespace Microsoft.OperationalInsights --wait

az containerapp env create --name micro-env --resource-group microservices-rg --location eastus

az acr update -n sliitmicroregistry22248244 --admin-enabled true
az acr credential show --name sliitmicroregistry22248244   # note username + password

az containerapp create `
  --name gateway `
  --resource-group microservices-rg `
  --environment micro-env `
  --image sliitmicroregistry22248244.azurecr.io/gateway:v1 `
  --target-port 3000 `
  --ingress external `
  --registry-server sliitmicroregistry22248244.azurecr.io `
  --registry-username sliitmicroregistry22248244 `
  --registry-password <your-acr-password>

az containerapp show --name gateway --resource-group microservices-rg `
  --query properties.configuration.ingress.fqdn --output tsv
```

---

### Task 5 – Deploy Static Web App Frontend

1. Push this repo to GitHub (or create a new GitHub repo and push the `frontend/` folder).
2. Run:

```powershell
az staticwebapp create `
  --name sliit-frontend-app `
  --resource-group microservices-rg `
  --location eastus2 `
  --source https://github.com/it22248244/ctse-lab7 `
  --branch main `
  --app-location "/" `
  --output-location "frontend"

az staticwebapp show --name sliit-frontend-app --resource-group microservices-rg `
  --query defaultHostname --output tsv
```

3. Open the returned URL in your browser. Enter the gateway FQDN into the dashboard to test endpoints.

---

### Task 6 – Verify & Cleanup

```powershell
az resource list --resource-group microservices-rg --output table
Invoke-WebRequest -Uri "https://<gateway-fqdn>/health"
az containerapp logs show --name gateway --resource-group microservices-rg --follow false

# After screenshots – cleanup:
az group delete --name microservices-rg --yes
```

---

## Gateway API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Service info |
| GET | `/health` | Health check (`{ "status": "ok" }`) |
| GET | `/api/status` | Uptime and timestamp |
| GET | `/api/services` | Registered services list |

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `az login` fails | Use `az login --use-device-code` |
| `docker push` denied | Run `az acr login --name sliitmicroregistry22248244` |
| Container App returns 503 | Wait 2–3 min; check `az containerapp logs show` |
| Provider registration error | Contact subscription admin |
| Provider registration error | Contact subscription admin |
