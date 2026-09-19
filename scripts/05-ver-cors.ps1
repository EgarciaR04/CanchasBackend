. "$PSScriptRoot\_config.ps1"

Write-Host '--- Variables Cors__* de la Container App'
$json = az containerapp show --name $appName --resource-group $rg --query "properties.template.containers[0].env" -o json | ConvertFrom-Json
$json | Where-Object { $_.name -like 'Cors*' } | ForEach-Object { "{0} = {1}" -f $_.name, $_.value }

Write-Host '--- Ingress corsPolicy (nivel Azure, no debe interferir)'
az containerapp show --name $appName --resource-group $rg --query "properties.configuration.ingress.corsPolicy" -o json

Write-Host '--- Revision activa'
az containerapp revision list --name $appName --resource-group $rg --query "[].{Rev:name,Activa:properties.active,Creada:properties.createdTime}" -o table
