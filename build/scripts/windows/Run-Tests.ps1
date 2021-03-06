<#
 # Runs all .NET Core test projects in the repo
 #>

param (
    [ValidateNotNullOrEmpty()]
    [ValidateScript( {Test-Path $_ -PathType Container})]
    [String] $AgentWorkFolder = $Env:AGENT_WORKFOLDER,

    [ValidateNotNullOrEmpty()]
    [ValidateScript( {Test-Path $_ -PathType Container})]
    [String] $BuildRepositoryLocalPath = $Env:BUILD_REPOSITORY_LOCALPATH,
    
    [ValidateNotNullOrEmpty()]
    [ValidateScript( {Test-Path $_ -PathType Container})]
    [String] $BuildBinariesDirectory = $Env:BUILD_BINARIESDIRECTORY
)

Set-StrictMode -Version "Latest"
$ErrorActionPreference = "Stop"

<#
 # Prepare environment
 #>

Import-Module ([IO.Path]::Combine($PSScriptRoot, "Defaults.psm1")) -Force

if (-not $AgentWorkFolder) {
    $AgentWorkFolder = DefaultAgentWorkFolder
}

if (-not $BuildRepositoryLocalPath) {
    $BuildRepositoryLocalPath = DefaultBuildRepositoryLocalPath
}

if (-not $BuildBinariesDirectory) {
    $BuildBinariesDirectory = DefaultBuildBinariesDirectory
}

Write-Host "AgentWorkFolder $AgentWorkFolder."
Write-Host "BuildRepositoryLocalPath '$BuildRepositoryLocalPath'."
Write-Host "BuildBinariesDirectory '$BuildBinariesDirectory'."


$TEST_CSPROJ_PATTERN = "*Tests.csproj"
$LOGGER_ARG = "trx;LogFileName=result.trx"

$DOTNET_PATH = [IO.Path]::Combine($AgentWorkFolder, "dotnet", "dotnet.exe")
$CCTOOLS_PATH = Join-Path $AgentWorkFolder "cctools"
$BINARIES_FOLDER = Join-Path $BuildBinariesDirectory "bin"
$OPENCOVER = [IO.Path]::Combine($CCTOOLS_PATH, "OpenCover.4.6.519", "tools", "OpenCover.Console.exe")
$CODE_COVERAGE = Join-Path $BuildBinariesDirectory "code-coverage.xml"
$OPENCOVER_COBERTURA_CONVERTER = [IO.Path]::Combine(
    $CCTOOLS_PATH,
    "OpenCoverToCoberturaConverter.0.2.6.0",
    "tools",
    "OpenCoverToCoberturaConverter.exe")
$REPORT_GENERATOR = [IO.Path]::Combine(
    $CCTOOLS_PATH,
    "ReportGenerator.2.5.6",
    "tools",
    "ReportGenerator.exe"
)

if (-not (Test-Path $DOTNET_PATH -PathType Leaf)) {
    throw "$DOTNET_PATH not found."
}

<#
 # Run tests
 #>

$BaseTestCommand = "test --no-build --logger `"$LOGGER_ARG`"" 
$Success = $True
foreach ($Project in (Get-ChildItem $BuildRepositoryLocalPath -Include $TEST_CSPROJ_PATTERN -Recurse)) {
    Write-Host "Running tests for $Project."
    if (Test-Path $OPENCOVER -PathType "Leaf") {
	    Write-Host "Running tests from if."
        &$OPENCOVER `
            -register:user `
            -target:$DOTNET_PATH `
            -targetargs:"$BaseTestCommand $Project" `
			-targetdir:$BINARIES_FOLDER `
            -skipautoprops `
            -hideskipped:All `
            -oldstyle `
            -output:$CODE_COVERAGE `
            -mergeoutput:$CODE_COVERAGE `
            -returntargetcode `
    }
    else {
	    Write-Host "Running tests from else."
        Invoke-Expression "&`"$DOTNET_PATH`" $BaseTestCommand --collect `"Code coverage`" -o $BINARIES_FOLDER $Project"
    }

    $Success = $Success -and $LASTEXITCODE -eq 0
}

<#
 # Process results
 #>

if (Test-Path $OPENCOVER_COBERTURA_CONVERTER -PathType "Leaf") {
    &$OPENCOVER_COBERTURA_CONVERTER -sources:. -input:$CODE_COVERAGE -output:(Join-Path $BuildBinariesDirectory "CoberturaCoverage.xml")
}

if (Test-Path $REPORT_GENERATOR -PathType "Leaf") {
    &$REPORT_GENERATOR -reporttypes:MHtml -reports:$CODE_COVERAGE -targetdir:(Join-Path $BuildBinariesDirectory "report")
}

if (-not $Success) {
    throw "Failed tests."
}

Write-Host "Done!"