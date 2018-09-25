<#
 # Installs .NET Core, Nuget, and Python.
 #>

param (
    [ValidateNotNullOrEmpty()]
    [ValidateScript( {Invoke-WebRequest $_ -DisableKeepAlive -UseBasicParsing -Method "Head"})]
    [String]$DotnetSdkUrl = "https://download.microsoft.com/download/8/A/7/8A765126-50CA-4C6F-890B-19AE47961E4B/dotnet-sdk-2.1.402-win-x64.zip",

    [ValidateNotNullOrEmpty()]
    [ValidateScript( {Invoke-WebRequest $_ -DisableKeepAlive -UseBasicParsing -Method "Head"})]
    [String]$NugetUrl = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe",

    [ValidateNotNullOrEmpty()]
    [ValidateScript( {Test-Path $_ -PathType Container})]
    [String]$AgentWorkFolder = $Env:AGENT_WORKFOLDER,

    [ValidateNotNullOrEmpty()]
    [ValidateScript( {Test-Path $_ -PathType Container})]
    [String]$BuildRepositoryLocalPath = $Env:BUILD_REPOSITORY_LOCALPATH,

    [Switch]$Dotnet,
    [Switch]$Nuget,
    [Switch]$Coverage
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
    $BuildRepositoryLocalPath = DefaultBuildRepositoryPath
}

$All = -not $Dotnet -and -not $Nuget -and -not $Coverage

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

<#
 # Install .NET Core
 #>

if ($Dotnet -or $All) {
    $DotnetInstallPath = Join-Path $AgentWorkFolder "dotnet"
    if (Test-Path $DotnetInstallPath) {
        Remove-Item $DotnetInstallPath -Force -Recurse
    }
    New-Item $DotnetInstallPath -ItemType "Directory" -Force

    Write-Host "Downloading .NET Core package."
    $DotnetZip = Join-Path $Env:TEMP "dotnet.zip"
    (New-Object System.Net.WebClient).DownloadFile($DotnetSdkUrl, $DotnetZip)

    Write-Host "Extracting .NET Core package to $DotnetInstallPath."
    Add-Type -A System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::ExtractToDirectory($DotnetZip, $DotnetInstallPath)

    Write-Host "Cleaning up .NET Core installation."
    Remove-Item $DotnetZip
}

<#
 # Install Nuget 
 #>

$NugetInstallPath = Join-Path $AgentWorkFolder "nuget"
$NugetExe = Join-Path $NugetInstallPath "nuget.exe"
if ($Nuget -or $All) {
    if (Test-Path $NugetInstallPath) {
        Remove-Item $NugetInstalLPath -Force -Recurse
    }
    New-Item $NugetInstallPath -ItemType "Directory" -Force

    Write-Host "Downloading Nuget."
    (New-Object System.Net.WebClient).DownloadFile($NugetUrl, $NugetExe)
}

<#
 # Install code coverage tools
 #>

if ($Coverage -or $All) {
    $NugetConfigLocalPath = DefaultNugetConfigLocalPath
    $NugetConfig = Join-Path $NugetConfigLocalPath "nuget.config"
	$CodeCoverageToolsPath =  DefaultBuildOutputCCToolsDirectory
	Write-Host "Installing coverage tools"
    &$NugetExe install OpenCover -version 4.6.519 -OutputDirectory $CodeCoverageToolsPath -ConfigFile $NugetConfig
    &$NugetExe install OpenCoverToCoberturaConverter -version 0.2.6 -OutputDirectory $CodeCoverageToolsPath -ConfigFile $NugetConfig
    &$NugetExe install ReportGenerator  -version 2.5.6 -OutputDirectory $CodeCoverageToolsPath -ConfigFile $NugetConfig
}

Write-Host "Done!"
