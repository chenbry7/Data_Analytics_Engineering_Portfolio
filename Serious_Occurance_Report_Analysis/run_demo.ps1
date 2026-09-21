param([string]$Server = '.\SQLEXPRESS')
$ErrorActionPreference = 'Stop'
$client = (Get-Command sqlcmd -ErrorAction Stop).Source
$files = @(
    'sql\00_create_demo_database.sql',
    'sql\01_create_layers.sql',
    'sql\02_load_silver.sql',
    'sql\03_gold_views.sql',
    'tests\01_synthetic_fixture.sql',
    'tests\02_acceptance.sql'
)
foreach ($file in $files) {
    $database = if ($file -eq 'sql\00_create_demo_database.sql') { 'master' } else { 'SOR_Portfolio_Test' }
    Write-Output "Running $file"
    & $client -S $Server -E -C -d $database -b -l 15 -t 60 -W -w 240 -r 1 -i (Join-Path $PSScriptRoot $file)
    if ($LASTEXITCODE -ne 0) { throw "SQL execution failed: $file" }
}
Write-Output 'Completed. SOR_Portfolio_Test contains only the restored synthetic fixture.'
