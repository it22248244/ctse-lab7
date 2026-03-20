# ============================================================
# CTSE Lab 7 – Azure Microservices Deployment Script
# SE4010 – Current Trends in Software Engineering
# ============================================================
# USAGE: Run each section (Task) one at a time.
# Right-click a section and "Run Selection" in VS Code,
# or paste commands into your terminal manually.
# ============================================================

# ─── CONFIGURATION (edit these before running) ──────────────
$RESOURCE_GROUP   = "microservices-rg"
$LOCATION         = "eastus"
$REGISTRY_NAME    = "sliitmicroregistry22248244"   # Student ID: IT22248244
$ENVIRONMENT_NAME = "micro-env"
$APP_NAME         = "gateway"
$IMAGE_TAG        = "v1"
$GITHUB_REPO      = "https://github.com/it22248244/ctse-lab7"
$FRONTEND_APP     = "sliit-frontend-app"
# ────────────────────────────────────────────────────────────

# ============================================================
# TASK 1 – Login to Azure
# ============================================================

Write-Host "`n[Task 1] Checking Azure CLI version..." -ForegroundColor Cyan
az --version | Select-String "azure-cli"

Write-Host "`n[Task 1] Logging in to Azure..." -ForegroundColor Cyan
az login
# Headless/SSH alternative: az login --use-device-code

Write-Host "`n[Task 1] Verifying active account..." -ForegroundColor Cyan
az account show

# Optional – list and set a specific subscription:
# az account list --output table
# az account set --subscription "<Subscription Name or ID>"


# ============================================================
# TASK 2 – Create Resource Group & Container Registry
# ============================================================

Write-Host "`n[Task 2] Creating resource group '$RESOURCE_GROUP'..." -ForegroundColor Cyan
az group create --name $RESOURCE_GROUP --location $LOCATION

Write-Host "`n[Task 2] Creating Container Registry '$REGISTRY_NAME'..." -ForegroundColor Cyan
az acr create `
  --resource-group $RESOURCE_GROUP `
  --name $REGISTRY_NAME `
  --sku Basic

Write-Host "`n[Task 2] Authenticating Docker with ACR..." -ForegroundColor Cyan
az acr login --name $REGISTRY_NAME


# ============================================================
# TASK 3 – Build & Push Docker Image
# ============================================================

$IMAGE_FULL = "$REGISTRY_NAME.azurecr.io/$APP_NAME`:$IMAGE_TAG"

Write-Host "`n[Task 3] Building Docker image: $IMAGE_FULL ..." -ForegroundColor Cyan
docker build -t $IMAGE_FULL ./gateway

Write-Host "`n[Task 3] Verifying local image..." -ForegroundColor Cyan
docker images | Select-String "gateway"

Write-Host "`n[Task 3] Pushing image to ACR..." -ForegroundColor Cyan
docker push $IMAGE_FULL

Write-Host "`n[Task 3] Verifying image in ACR..." -ForegroundColor Cyan
az acr repository list --name $REGISTRY_NAME --output table
az acr repository show-tags --name $REGISTRY_NAME --repository $APP_NAME --output table


# ============================================================
# TASK 4 – Deploy Container App
# ============================================================

Write-Host "`n[Task 4] Registering Microsoft.App provider..." -ForegroundColor Cyan
az provider register --namespace Microsoft.App --wait
az provider register --namespace Microsoft.OperationalInsights --wait

Write-Host "`n[Task 4] Creating Container Apps Environment '$ENVIRONMENT_NAME'..." -ForegroundColor Cyan
az containerapp env create `
  --name $ENVIRONMENT_NAME `
  --resource-group $RESOURCE_GROUP `
  --location $LOCATION

Write-Host "`n[Task 4] Enabling ACR admin credentials..." -ForegroundColor Cyan
az acr update -n $REGISTRY_NAME --admin-enabled true

Write-Host "`n[Task 4] Fetching ACR credentials..." -ForegroundColor Cyan
$ACR_CREDS = az acr credential show --name $REGISTRY_NAME | ConvertFrom-Json
$ACR_USERNAME = $ACR_CREDS.username
$ACR_PASSWORD = $ACR_CREDS.passwords[0].value
Write-Host "ACR Username: $ACR_USERNAME" -ForegroundColor Yellow

Write-Host "`n[Task 4] Deploying Container App '$APP_NAME'..." -ForegroundColor Cyan
az containerapp create `
  --name $APP_NAME `
  --resource-group $RESOURCE_GROUP `
  --environment $ENVIRONMENT_NAME `
  --image "$REGISTRY_NAME.azurecr.io/$APP_NAME`:$IMAGE_TAG" `
  --target-port 3000 `
  --ingress external `
  --registry-server "$REGISTRY_NAME.azurecr.io" `
  --registry-username $ACR_USERNAME `
  --registry-password $ACR_PASSWORD

Write-Host "`n[Task 4] Retrieving gateway public URL..." -ForegroundColor Cyan
$GATEWAY_FQDN = az containerapp show `
  --name $APP_NAME `
  --resource-group $RESOURCE_GROUP `
  --query properties.configuration.ingress.fqdn `
  --output tsv

Write-Host "Gateway URL: https://$GATEWAY_FQDN" -ForegroundColor Green
Write-Host "Health check: https://$GATEWAY_FQDN/health" -ForegroundColor Green


# ============================================================
# TASK 5 – Deploy Static Web App Frontend
# ============================================================

Write-Host "`n[Task 5] Creating Static Web App '$FRONTEND_APP'..." -ForegroundColor Cyan
az staticwebapp create `
  --name $FRONTEND_APP `
  --resource-group $RESOURCE_GROUP `
  --location eastus2 `
  --source $GITHUB_REPO `
  --branch main `
  --app-location "/" `
  --output-location "frontend"

Write-Host "`n[Task 5] Getting frontend URL..." -ForegroundColor Cyan
$FRONTEND_URL = az staticwebapp show `
  --name $FRONTEND_APP `
  --resource-group $RESOURCE_GROUP `
  --query defaultHostname `
  --output tsv

Write-Host "Frontend URL: https://$FRONTEND_URL" -ForegroundColor Green

# Optional – connect frontend to gateway:
# az staticwebapp appsettings set `
#   --name $FRONTEND_APP `
#   --resource-group $RESOURCE_GROUP `
#   --setting-names REACT_APP_API_URL=https://$GATEWAY_FQDN


# ============================================================
# TASK 6 – Verify Deployment
# ============================================================

Write-Host "`n[Task 6] Listing all resources in '$RESOURCE_GROUP'..." -ForegroundColor Cyan
az resource list --resource-group $RESOURCE_GROUP --output table

Write-Host "`n[Task 6] Testing gateway health endpoint..." -ForegroundColor Cyan
if ($GATEWAY_FQDN) {
    Invoke-WebRequest -Uri "https://$GATEWAY_FQDN/health" -UseBasicParsing | Select-Object StatusCode, Content
}

Write-Host "`n[Task 6] Viewing container app logs..." -ForegroundColor Cyan
az containerapp logs show `
  --name $APP_NAME `
  --resource-group $RESOURCE_GROUP `
  --follow false


# ============================================================
# CLEANUP – Delete All Resources (run LAST, after screenshots)
# ============================================================

Write-Host "`n[CLEANUP] WARNING: This will delete ALL resources in '$RESOURCE_GROUP'!" -ForegroundColor Red
Write-Host "Only run this after you have taken all required screenshots." -ForegroundColor Yellow
# Uncomment the line below when ready to clean up:
# az group delete --name $RESOURCE_GROUP --yes
