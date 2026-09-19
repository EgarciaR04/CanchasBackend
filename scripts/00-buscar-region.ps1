. "$PSScriptRoot\_config.ps1"

# Regiones permitidas por la politica de Azure for Students de esta suscripcion
$candidatas = @('centralus', 'canadacentral', 'northcentralus', 'chilecentral', 'eastus')

foreach ($r in $candidatas) {
    Write-Host "=== Probando region: $r ===" -ForegroundColor Cyan

    # El RG debe estar vacio para poder recrearlo en otra region
    $existe = az group exists -n $rg
    if ($existe -eq 'true') {
        $recursos = az resource list -g $rg --query "[].name" -o tsv
        if ($recursos) { Write-Host "RG no vacio, abortando: $recursos"; exit 1 }
        az group delete -n $rg --yes | Out-Null
    }
    az group create --name $rg --location $r -o none

    az sql server create --name $sqlServer --resource-group $rg --location $r `
        --admin-user $sqlAdmin --admin-password $sqlPassword -o none 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK: SQL Server creado en $r" -ForegroundColor Green
        Set-Content -Path "$PSScriptRoot\region.txt" -Value $r -Encoding ASCII
        exit 0
    }
    Write-Host "Region $r rechazada." -ForegroundColor Yellow
}

Write-Host 'Ninguna region acepto el servidor SQL.' -ForegroundColor Red
exit 1
