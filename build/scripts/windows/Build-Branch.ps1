<#
 # Builds and publishes to target/publish/ all .NET Core solutions in the repo
 #>

param (
    [ValidateNotNullOrEmpty()]
    [ValidateScript( {Test-Path $_ -PathType Container})]
    [String] $AgentWorkFolder = $Env:AGENT_WORKFOLDER,

    [ValidateNotNullOrEmpty()]
    [ValidateScript( {Test-Path $_ -PathType Container})]
    [String] $BuildRepositoryLocalPath = $Env:BUILD_REPOSITORY_LOCALPATH,
    
    [ValidateNotNullOrEmpty()]
    [String] $BuildBinariesDirectory = $Env:BUILD_BINARIESDIRECTORY,

    [ValidateSet("Debug", "Release")]
    [String] $Configuration = $Env:CONFIGURATION,

    [ValidateNotNull()]
    [String] $BuildId = $Env:BUILD_BUILDID,

    [ValidateNotNull()]
    [String] $BuildSourceVersion = $Env:BUILD_SOURCEVERSION,
    
    [Switch] $UpdateVersion
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

if (-not $Configuration) {
    $Configuration = DefaultConfiguration
}

if (-not $BuildId) {
    $BuildId = DefaultBuildId
}

if (-not $BuildSourceVersion) {
    $BuildSourceVersion = DefaultBuildSourceVersion
}

$SLN_PATTERN = "CustomModule*.sln"
$CSPROJ_PATTERN = "*.csproj"
$TEST_CSPROJ_PATTERN = "*Tests.csproj"

$DOTNET_PATH = [IO.Path]::Combine($AgentWorkFolder, "dotnet", "dotnet.exe")
$VERSIONINFO_FILE_PATH = Join-Path $BuildRepositoryLocalPath "versionInfo.json"
$SRC_SCRIPTS_DIR = [IO.Path]::Combine($BuildRepositoryLocalPath, "build", "scripts")

$BINARIES_FOLDER = Join-Path $BuildBinariesDirectory "bin"
$PUBLISH_ROOT_FOLDER = Join-Path $BuildBinariesDirectory "publish"
$PUBLISH_SCRIPTS_DIR = Join-Path $PUBLISH_ROOT_FOLDER "scripts"

if (-not (Test-Path $DOTNET_PATH -PathType Leaf)) {
    throw "$DOTNET_PATH not found"
}

if (Test-Path $BuildBinariesDirectory -PathType Container) {
    Remove-Item $BuildBinariesDirectory -Force -Recurse
}

<#
 # Update version
 #>

if ($UpdateVersion) {
    if (Test-Path $VERSIONINFO_FILE_PATH -PathType Leaf) {
        Write-Host "`nUpdating versionInfo.json with the build ID and commit ID.`n"
        ((Get-Content $VERSIONINFO_FILE_PATH) `
                -replace "BUILDNUMBER", $BuildId) `
            -replace "COMMITID", $BuildSourceVersion |
            Out-File $VERSIONINFO_FILE_PATH
    }
    else {
        Write-Host "`nversionInfo.json not found.`n"
    }
}
else {
    Write-Host "`nSkipping versionInfo.json update.`n"
}

<#
 # Build solutions
 #>

Write-Host "`nBuilding all solutions in repo`n"

foreach ($Solution in (Get-ChildItem $BuildRepositoryLocalPath -Include $SLN_PATTERN -Recurse)) {
    Write-Host "Building Solution - $Solution"
    &$DOTNET_PATH build -c $Configuration -o $BINARIES_FOLDER $Solution |
        Write-Host
    if ($LASTEXITCODE -ne 0) {
        throw "Failed building $Solution."
    }
}

<#
 # Publish applications
 #>

Write-Host "`nPublishing .NET Core apps`n"

$AppProjects = Get-ChildItem $BuildRepositoryLocalPath -Include $CSPROJ_PATTERN -Recurse |
    Where-Object FullName -NotMatch "\\c-shared\\?" |
    Where-Object FullName -NotMatch "\\c-utility\\?" |
    Select-String "<OutputType>Exe</OutputType>"

foreach ($Project in $AppProjects) {
    Write-Host "Publishing Solution - $($Project.Filename)"
	$ProjectFileNameTrimmed = ($Project.Filename -replace @(".csproj", ""))
	$ProjectPathTrimmed = ($Project.Path -replace @(".csproj", ""))
    $ProjectPublishPath = Join-Path $PUBLISH_ROOT_FOLDER $ProjectFileNameTrimmed
    &$DOTNET_PATH publish -f netcoreapp2.1 -c $Configuration -o $ProjectPublishPath $Project.Path |
        Write-Host
    if ($LASTEXITCODE -ne 0) {
        throw "Failed publishing $($Project.Filename)."
    }
	
	$SrcDockerFolder = [IO.Path]::Combine($ProjectPathTrimmed, "..", "..", "docker")
	$DestDockerFolder = Join-Path $ProjectPublishPath "docker"
	
	Write-Host "Copying docker files"
	Copy-Item $SrcDockerFolder $DestDockerFolder -Recurse -Force 
}

<#
 # Publish tests
 #>
Write-Host "`nPublishing .NET Core Tests`n"
foreach ($Project in (Get-ChildItem $BuildRepositoryLocalPath -Include $TEST_CSPROJ_PATTERN -Recurse)) {
        Write-Host "Publishing - $Project"
        $ProjectPublishPath = Join-Path $PUBLISH_ROOT_FOLDER ($Project.BaseName -replace @(".csproj", ""))
		&$DOTNET_PATH publish -f netcoreapp2.1 -c $Configuration -o $ProjectPublishPath $Project |
            Write-Host
        if ($LASTEXITCODE -ne 0) {
            throw "Failed publishing $Project."
        }
}


<#
 # Copy remaining files
 #>

Write-Host "Copying $SRC_SCRIPTS_DIR to $PUBLISH_SCRIPTS_DIR"
Copy-Item $SRC_SCRIPTS_DIR $PUBLISH_SCRIPTS_DIR -Recurse -Force 
