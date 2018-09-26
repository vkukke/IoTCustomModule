function DefaultAgentWorkFolder {
    $env:ProgramFiles
}

function DefaultBuildRepositoryLocalPath {
    [IO.Path]::Combine($PSScriptRoot, "..", "..", "..")
}

function DefaultBuildBinariesDirectory($BuildRepositoryLocalPath = (DefaultBuildRepositoryLocalPath)) {
    Join-Path $BuildRepositoryLocalPath "bin"
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