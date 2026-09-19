# Configuracion compartida del Laboratorio 2 (Eric Garcia)
# Los secretos se leen de docker.azure.env (ignorado por Git).

$proyecto = 'C:\UMG\Desarrollo Web\Laboratorio2\reservacion-canchas-api'
$envFile  = Join-Path $proyecto 'docker.azure.env'

$cfg = @{}
Get-Content $envFile -Encoding UTF8 |
    Where-Object { $_ -match '^[A-Za-z_][^=]*=' } |
    ForEach-Object {
        $i = $_.IndexOf('=')
        $cfg[$_.Substring(0, $i)] = $_.Substring($i + 1)
    }

# Nombres de recursos (personalizados: egarcia en lugar de fzepeda)
$rg          = 'rg-canchas-umg'
$location    = 'eastus'
# Si 00-buscar-region.ps1 encontro una region valida para SQL, se usa esa
$regionFile  = Join-Path $PSScriptRoot 'region.txt'
if (Test-Path $regionFile) { $location = (Get-Content $regionFile -Raw).Trim() }
$sqlServer   = 'sql-canchas-egarcia-2026'
$db          = 'DB_RESERVACION_CANCHAS'
$sqlAdmin    = $cfg['AZURE_SQL_ADMIN_USER']
$sqlPassword = $cfg['AZURE_SQL_ADMIN_PASSWORD']
$azureConn   = $cfg['ConnectionStrings__CanchasDb']

$acr          = 'acrcanchasegarcia26'
$imageName    = 'reservacion-canchas-api'
$imageTag     = 'semana11'
$envName      = 'env-canchas-umg'
$appName      = 'canchas-api'
$identityName = 'id-canchas-acr'

function Assert-Ok($paso) {
    if ($LASTEXITCODE -ne 0) { throw "FALLO: $paso (exit $LASTEXITCODE)" }
    Write-Host "OK: $paso" -ForegroundColor Green
}
