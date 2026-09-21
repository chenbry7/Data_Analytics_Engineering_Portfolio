param([string]$Server = '.\SQLEXPRESS')
$ErrorActionPreference = 'Stop'
$demo = Split-Path $PSScriptRoot -Parent
$runner = Join-Path $demo 'run_ssis_demo.ps1'
$sqlcmd = (Get-Command sqlcmd -ErrorAction Stop).Source
$connectionOptions = [System.Data.SqlClient.SqlConnectionStringBuilder]::new()
$connectionOptions['Data Source'] = $Server
$connectionOptions['Initial Catalog'] = 'SOR_Portfolio_Test'
$connectionOptions['Integrated Security'] = $true
$connectionOptions['TrustServerCertificate'] = $true
function Read-DemoScalar([string]$Sql) {
    $connection = [System.Data.SqlClient.SqlConnection]::new($connectionOptions.ConnectionString)
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = $Sql
        $command.CommandTimeout = 30
        return $command.ExecuteScalar()
    }
    finally { $connection.Dispose() }
}
$snapshotSql = @"
SET NOCOUNT ON;
SELECT CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max),
 (SELECT * FROM silver.SO_status ORDER BY sor_id FOR JSON PATH, INCLUDE_NULL_VALUES))), 2)
 + ':' + CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max),
 (SELECT * FROM silver.SO_category ORDER BY sor_id, category, client_id, program FOR JSON PATH, INCLUDE_NULL_VALUES))), 2);
"@
# Start with the SQL-loaded fixture, so the successful CSV path can be compared independently.
& $sqlcmd -S $Server -E -C -d SOR_Portfolio_Test -b -i (Join-Path $PSScriptRoot '01_synthetic_fixture.sql')
if ($LASTEXITCODE -ne 0) { throw 'Synthetic fixture initialization failed.' }
& $sqlcmd -S $Server -E -C -d SOR_Portfolio_Test -b -Q 'EXEC silver.load_all;'
if ($LASTEXITCODE -ne 0) { throw 'Baseline load failed.' }
$expected = Read-DemoScalar $snapshotSql
& $runner -Server $Server
if ((Read-DemoScalar $snapshotSql) -ne $expected) { throw 'SSIS output differs from the SQL fixture baseline.' }
Write-Output 'PASS: CSV/SSIS output exactly matches SQL fixture baseline.'

$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ('sor-ssis-tests-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null
$encoding = [Text.Encoding]::GetEncoding(1252)
$badCategory = Join-Path $temporaryDirectory 'bad_category.csv'
$duplicateStatus = Join-Path $temporaryDirectory 'duplicate_status.csv'
$categoryText = [IO.File]::ReadAllText((Join-Path $demo 'data\synthetic\SO_category.csv'),$encoding)
$statusText = [IO.File]::ReadAllText((Join-Path $demo 'data\synthetic\SO_status.csv'),$encoding)
if (-not $categoryText.Contains('2026-06-02T10:00:00') -or -not $statusText.Contains('DEMO-E003')) { throw 'Expected fixture tokens missing.' }
[IO.File]::WriteAllText($badCategory,$categoryText.Replace('2026-06-02T10:00:00','not-a-date'),$encoding)
[IO.File]::WriteAllText($duplicateStatus,$statusText.Replace('DEMO-E003','DEMO-E001'),$encoding)
$cases = @(
    @{ Name='Invalid category date'; Options=@{CategoryCsv=$badCategory}; Pattern='Invalid SO_category.date_time_report_submit' },
    @{ Name='Duplicate event ID'; Options=@{StatusCsv=$duplicateStatus}; Pattern='Status event identifiers must be unique' },
    @{ Name='Missing CSV'; Options=@{StatusCsv=(Join-Path $temporaryDirectory 'missing.csv')}; Pattern='cannot find|cannot open|failed to open|not found|cannot be opened|Failed to open' }
)
try {
    foreach ($case in $cases) {
        $messages = [Collections.Generic.List[string]]::new()
        $failed = $false
        $options = $case.Options
        try { & $runner -Server $Server @options 2>&1 | ForEach-Object { $messages.Add($_.ToString()) } }
        catch { $failed = $true; $messages.Add($_.Exception.Message) }
        if (-not $failed) { throw "Expected SSIS failure: $($case.Name)" }
        if (($messages -join "`n") -notmatch $case.Pattern) {
            throw "Unexpected failure for $($case.Name): $($messages -join ' | ')"
        }
        if ((Read-DemoScalar $snapshotSql) -ne $expected) { throw "Silver changed after $($case.Name)" }
        Write-Output "PASS: $($case.Name) rejected and complete Silver snapshot preserved."
    }
}
finally {
    # Delete only the specifically created temporary fixture files, then the empty directory.
    foreach ($path in @($badCategory,$duplicateStatus)) {
        if (Test-Path -LiteralPath $path -PathType Leaf) { Remove-Item -LiteralPath $path -Force }
    }
    if ((Test-Path -LiteralPath $temporaryDirectory) -and @(Get-ChildItem -LiteralPath $temporaryDirectory -Force).Count -eq 0) {
        Remove-Item -LiteralPath $temporaryDirectory
    }
    & $runner -Server $Server
}
if ((Read-DemoScalar $snapshotSql) -ne $expected) { throw 'Final valid reload changed fixture output.' }
Write-Output 'PASS: final valid CSV reload restores the expected demonstration.'
Write-Output 'SSIS acceptance complete: 5 checks passed.'
