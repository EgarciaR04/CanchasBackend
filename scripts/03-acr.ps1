. "$PSScriptRoot\_config.ps1"
$ErrorActionPreference = 'Continue'

Write-Host "Region en uso: $location"

# 19. Verificar disponibilidad del nombre
az acr check-name --name $acr -o table
Assert-Ok 'acr check-name'

# 19. Crear ACR
az acr create --resource-group $rg --name $acr --sku Basic --location $location -o table
Assert-Ok 'acr create'

az acr show --name $acr --resource-group $rg -o table
Assert-Ok 'acr show'

$acrLoginServer = az acr show --name $acr --resource-group $rg --query loginServer --output tsv
Write-Host "loginServer: $acrLoginServer"
