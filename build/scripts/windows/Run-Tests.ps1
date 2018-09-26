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
    [String] $BuildBinariesDirectory = $Env:BUILD_BINARIESDIRECTORY,

    [ValidateNotNullOrEmpty()]
    [String] $Filter
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
Write-Host "Filter '$Filter'."


$TEST_CSPROJ_PATTERN = "*Tests.csproj"
$LOGGER_ARG = "trx;LogFileName=result.trx"

$DOTNET_PATH = [IO.Path]::Combine($AgentWorkFolder, "dotnet", "dotnet.exe")
$BINARIES_FOLDER = Join-Path $BuildBinariesDirectory "bin"

if (-not (Test-Path $DOTNET_PATH -PathType Leaf)) {
    throw "$DOTNET_PATH not found."
}

<#
 # Run tests
 #>

$BaseTestCommand = if ($Filter) {
    "test --no-build --logger `"$LOGGER_ARG`" --filter `"$Filter`" --collect `"Code coverage`"" 
}
else {
    "test --no-build --logger `"$LOGGER_ARG`" --collect `"Code Coverage`""
}

Write-Host "Running tests in all test projects with filter '$Filter'."
$Success = $True
foreach ($Project in (Get-ChildItem $BuildRepositoryLocalPath -Include $TEST_CSPROJ_PATTERN -Recurse)) {
    Write-Host "Running tests for $Project."
    Invoke-Expression "&`"$DOTNET_PATH`" $BaseTestCommand -o $BINARIES_FOLDER $Project"
    
	$Success = $Success -and $LASTEXITCODE -eq 0
	if (-not $Success) {
      throw "Failed tests in $Project."
}


}

Write-Host "Done!"