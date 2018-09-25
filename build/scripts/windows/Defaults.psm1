function DefaultAgentWorkFolder {
    $env:ProgramFiles
}

function DefaultBuildRepositoryPath {
    [IO.Path]::Combine($PSScriptRoot, "..", "..", "..")
}

function DefaultBuildScriptsRepositoryPath {
    [IO.Path]::Combine($PSScriptRoot, "..")
}

function DefaultNugetConfigLocalPath {
    [IO.Path]::Combine($PSScriptRoot, "..", "..", "..")
}

function DefaultConfiguration {
    "Debug"
}

function DefaultBuildId {
    ""
}

function DefaultBuildSourceVersion {
    ""
}

function DefaultBuildOutputPath {
    [IO.Path]::Combine($PSScriptRoot, "..", "..", "..", "out")
}

function DefaultBuildOutputCCToolsDirectory($BuildRepositoryLocalPath = (DefaultBuildOutputPath)) {
    Join-Path $BuildRepositoryLocalPath "cctools"
}

function DefaultBuildOutputBinariesDirectory($BuildRepositoryLocalPath = (DefaultBuildOutputPath)) {
    Join-Path $BuildRepositoryLocalPath "target"
}