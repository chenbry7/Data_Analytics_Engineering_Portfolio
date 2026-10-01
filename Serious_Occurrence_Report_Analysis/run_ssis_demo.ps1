param(
    [string]$Server = '.\SQLEXPRESS',
    [string]$StatusCsv = (Join-Path $PSScriptRoot 'data\synthetic\SO_status.csv'),
    [string]$CategoryCsv = (Join-Path $PSScriptRoot 'data\synthetic\SO_category.csv')
)
$ErrorActionPreference = 'Stop'
$runner = (Get-Command dtexec -ErrorAction Stop).Source
$template = Join-Path $PSScriptRoot 'ssis\SOR_Portfolio_Demo.dtsx'
# Never persist local absolute file paths in the checked-in package.
[xml]$package = Get-Content -LiteralPath $template -Raw
$ns = [Xml.XmlNamespaceManager]::new($package.NameTable)
$ns.AddNamespace('DTS','www.microsoft.com/SqlServer/Dts')
$connection = "Data Source=$Server;Initial Catalog=SOR_Portfolio_Test;Provider=MSOLEDBSQL19.1;Integrated Security=SSPI;Use Encryption for Data=Optional;Trust Server Certificate=True;"
foreach ($manager in $package.SelectNodes('/DTS:Executable/DTS:ConnectionManagers/DTS:ConnectionManager',$ns)) {
    $name = $manager.GetAttribute('ObjectName','www.microsoft.com/SqlServer/Dts')
    $config = $manager.SelectSingleNode('DTS:ObjectData/DTS:ConnectionManager',$ns)
    $value = switch ($name) {
        'DemoDatabase' { $connection }
        'statusCSVupload' { [IO.Path]::GetFullPath($StatusCsv) }
        'categoryCSVupload' { [IO.Path]::GetFullPath($CategoryCsv) }
        default { throw "Unexpected connection: $name" }
    }
    $config.SetAttribute('ConnectionString','www.microsoft.com/SqlServer/Dts',$value) | Out-Null
}
$temporary = Join-Path ([IO.Path]::GetTempPath()) ("sor-demo-"+[guid]::NewGuid().ToString('N')+'.dtsx')
try {
    $package.Save($temporary)
    & $runner /FILE $temporary /REPORTING E
    if ($LASTEXITCODE -ne 0) { throw "SSIS package failed with exit code $LASTEXITCODE" }
}
finally {
    if (Test-Path -LiteralPath $temporary -PathType Leaf) { Remove-Item -LiteralPath $temporary -Force }
}
Write-Output 'SSIS CSV ingestion, Silver refresh and count validation succeeded.'
