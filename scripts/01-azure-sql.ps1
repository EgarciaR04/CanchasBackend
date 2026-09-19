. "$PSScriptRoot\_config.ps1"
$ErrorActionPreference = 'Continue'

Write-Host "Region en uso: $location"
az account show --query "{Cuenta:user.name,Suscripcion:name}" -o table
Assert-Ok 'az account show'

# 16. Resource Group + servidor logico se crean en 00-buscar-region.ps1
az sql server show --name $sqlServer --resource-group $rg -o table
Assert-Ok 'SQL Server show'

# 16. Firewall: mi PC + servicios de Azure
$myIp = (Invoke-RestMethod 'https://api4.ipify.org').Trim()
Write-Host "IP publica: $myIp"
az sql server firewall-rule create --resource-group $rg --server $sqlServer `
    --name 'MiPCDesarrollo' --start-ip-address $myIp --end-ip-address $myIp -o table
Assert-Ok 'Firewall MiPCDesarrollo'

az sql server firewall-rule create --resource-group $rg --server $sqlServer `
    --name 'AllowAzureServices' --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0 -o table
Assert-Ok 'Firewall AllowAzureServices'

# 17. Base de datos serverless
az sql db create --resource-group $rg --server $sqlServer --name $db `
    --edition GeneralPurpose --compute-model Serverless --family Gen5 `
    --capacity 2 --min-capacity 0.5 --auto-pause-delay 60 `
    --backup-storage-redundancy Local --zone-redundant false -o table
Assert-Ok 'SQL Database'

az sql db show --resource-group $rg --server $sqlServer --name $db -o table
Assert-Ok 'SQL Database show'
