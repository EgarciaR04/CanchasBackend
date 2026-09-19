. "$PSScriptRoot\_config.ps1"
$ErrorActionPreference = 'Continue'

Write-Host "Region en uso: $location"

# --- Prerrequisitos: extension y proveedores de recursos ---
az extension add --name containerapp --upgrade --yes --only-show-errors
Assert-Ok 'extension containerapp'

foreach ($p in @('Microsoft.App', 'Microsoft.OperationalInsights', 'Microsoft.ManagedIdentity', 'Microsoft.ContainerRegistry')) {
    $estado = az provider show -n $p --query registrationState -o tsv
    if ($estado -ne 'Registered') {
        Write-Host "Registrando $p (estado: $estado)..."
        az provider register -n $p --wait
        Assert-Ok "provider $p"
    } else {
        Write-Host "Provider $p ya registrado"
    }
}

# --- 20. Entorno de Container Apps ---
az containerapp env create --name $envName --resource-group $rg --location $location --enable-workload-profiles false -o table
Assert-Ok 'containerapp env create'

# --- 20. Identidad administrada ---
az identity create --name $identityName --resource-group $rg --location $location -o table
Assert-Ok 'identity create'

$identityId  = az identity show --name $identityName --resource-group $rg --query id -o tsv
$principalId = az identity show --name $identityName --resource-group $rg --query principalId -o tsv

# --- 20. Rol AcrPull sobre el ACR ---
$acrId = az acr show --name $acr --resource-group $rg --query id -o tsv
az role assignment create --assignee-object-id $principalId --assignee-principal-type ServicePrincipal `
    --role AcrPull --scope $acrId -o table
Assert-Ok 'role assignment AcrPull'

$acrLoginServer = az acr show --name $acr --resource-group $rg --query loginServer -o tsv
$image = "${acrLoginServer}/${imageName}:${imageTag}"
Write-Host "Imagen: $image"

# Esperar propagacion del rol antes de que la app intente descargar la imagen
Write-Host 'Esperando 60s para la propagacion del rol AcrPull...'
Start-Sleep -Seconds 60

# --- 20. Secretos de produccion (desde docker.azure.env) ---
$jwtKey            = $cfg['JwtSettings__Key']
$seedAdminPassword = $cfg['SeedAdmin__Password']

az containerapp create `
    --name $appName `
    --resource-group $rg `
    --environment $envName `
    --image $image `
    --user-assigned $identityId `
    --registry-identity $identityId `
    --registry-server $acrLoginServer `
    --ingress external `
    --target-port 8080 `
    --cpu 0.5 `
    --memory 1Gi `
    --min-replicas 0 `
    --max-replicas 1 `
    --secrets `
    "db-connection=$azureConn" `
    "jwt-key=$jwtKey" `
    "seed-admin-password=$seedAdminPassword" `
    --env-vars `
    "ConnectionStrings__CanchasDb=secretref:db-connection" `
    "JwtSettings__Key=secretref:jwt-key" `
    "JwtSettings__Issuer=Canchas.Api" `
    "JwtSettings__Audience=Canchas.Web" `
    "JwtSettings__ExpirationMinutes=60" `
    "SeedAdmin__NombreCompleto=$($cfg['SeedAdmin__NombreCompleto'])" `
    "SeedAdmin__Correo=$($cfg['SeedAdmin__Correo'])" `
    "SeedAdmin__Password=secretref:seed-admin-password" `
    "Swagger__Enabled=true" `
    "Cors__AllowedOrigins__0=http://localhost:5173" `
    -o none
Assert-Ok 'containerapp create'

$fqdn = az containerapp show --name $appName --resource-group $rg --query properties.configuration.ingress.fqdn -o tsv
Write-Host ''
Write-Host "FQDN: $fqdn"
Write-Host "Swagger: https://$fqdn/swagger/index.html"
Set-Content -Path "$PSScriptRoot\fqdn.txt" -Value $fqdn -Encoding ASCII
