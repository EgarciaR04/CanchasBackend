. "$PSScriptRoot\_config.ps1"

$actual = az group show -n $rg --query location -o tsv
Write-Host "Region actual de ${rg}: $actual (objetivo: $location)"

if ($actual -eq $location) { Write-Host 'Ya esta en la region correcta.'; return }

$recursos = az resource list -g $rg --query "[].name" -o tsv
if ($recursos) {
    Write-Host "El grupo NO esta vacio, no se elimina:"
    $recursos
    exit 1
}

az group delete -n $rg --yes
Assert-Ok 'RG vacio eliminado'
az group create --name $rg --location $location -o table
Assert-Ok "RG recreado en $location"
