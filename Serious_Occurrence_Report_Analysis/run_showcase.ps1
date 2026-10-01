param(
    [string]$Server = '.\SQLEXPRESS',
    [string]$Python = 'python'
)
$ErrorActionPreference = 'Stop'
$checker = Join-Path $PSScriptRoot 'scripts\showcase_data.py'
# Check the delivered source files before replacing the demo snapshot.
& $Python $checker
if ($LASTEXITCODE -ne 0) { throw 'Showcase source validation failed.' }
& (Join-Path $PSScriptRoot 'run_ssis_demo.ps1') -Server $Server `
    -StatusCsv (Join-Path $PSScriptRoot 'data\showcase\SO_status.csv') `
    -CategoryCsv (Join-Path $PSScriptRoot 'data\showcase\SO_category.csv')

$options = [System.Data.SqlClient.SqlConnectionStringBuilder]::new()
$options['Data Source'] = $Server
$options['Initial Catalog'] = 'SOR_Portfolio_Test'
$options['Integrated Security'] = $true
$options['TrustServerCertificate'] = $true
$connection = [System.Data.SqlClient.SqlConnection]::new($options.ConnectionString)
$temporary = Join-Path ([IO.Path]::GetTempPath()) ('sor-showcase-' + [guid]::NewGuid().ToString('N') + '.json')
try {
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandTimeout = 60
    $command.CommandText = @'
SELECT (SELECT
 JSON_QUERY((SELECT * FROM gold.fact_events FOR JSON PATH, INCLUDE_NULL_VALUES)) AS events,
 JSON_QUERY((SELECT * FROM gold.fact_categories FOR JSON PATH, INCLUDE_NULL_VALUES)) AS categories,
 JSON_QUERY((SELECT
  (SELECT COUNT(*) FROM bronze.SO_status) AS bronze_events,
  (SELECT COUNT(*) FROM bronze.SO_category) AS bronze_categories,
  (SELECT COUNT(*) FROM silver.SO_status) AS silver_events,
  (SELECT COUNT(*) FROM silver.SO_category) AS silver_categories
  FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS counts
FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS payload;
'@
    [IO.File]::WriteAllText($temporary, [string]$command.ExecuteScalar())
    & $Python $checker --gold-json $temporary
    if ($LASTEXITCODE -ne 0) { throw 'Showcase Gold reconciliation failed.' }
}
finally {
    $connection.Dispose()
    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
}
Write-Output 'Showcase verified. The database is ready for Power BI Import/Refresh.'
