. "$PSScriptRoot\_config.ps1"
$ErrorActionPreference = 'Continue'

Set-Location (Join-Path $proyecto 'Canchas.Api')

# 11. secrets.json (User Secrets) para desarrollo local
dotnet user-secrets init
Assert-Ok 'user-secrets init'

# Clave JWT propia de desarrollo (distinta a la de produccion)
$devKey = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 64 | ForEach-Object { [char]$_ })

dotnet user-secrets set 'ConnectionStrings:CanchasDb' $azureConn | Out-Null
dotnet user-secrets set 'JwtSettings:Key' $devKey | Out-Null
dotnet user-secrets set 'SeedAdmin:NombreCompleto' $cfg['SeedAdmin__NombreCompleto'] | Out-Null
dotnet user-secrets set 'SeedAdmin:Correo' $cfg['SeedAdmin__Correo'] | Out-Null
dotnet user-secrets set 'SeedAdmin:Password' $cfg['SeedAdmin__Password'] | Out-Null
Assert-Ok 'user-secrets set'

Write-Host '--- claves configuradas en user-secrets (sin valores):'
dotnet user-secrets list | ForEach-Object { ($_ -split ' = ')[0] }

# 12. Migracion inicial
dotnet ef migrations add InicialReservacionCanchas
Assert-Ok 'Add-Migration InicialReservacionCanchas'

# 18. Aplicar la migracion directamente en Azure SQL
dotnet ef database update --connection $azureConn
Assert-Ok 'Update-Database (Azure)'

az sql db show --resource-group $rg --server $sqlServer --name $db `
    --query "{Base:name,Estado:status,Servidor:'$sqlServer',Region:location}" -o table
Assert-Ok 'Comprobar base en Azure'
