[CmdletBinding()]
param(
    [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
    $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$source = Join-Path $root 'shared\codegraph-integration.md'
$targets = @(
    'slizm-requirements-doc-from-code\references\codegraph-integration.md',
    'slizm-requirements-to-technical-design\references\codegraph-integration.md',
    'tech-doc-implementation\references\codegraph-integration.md'
)

if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    throw "CodeGraph protocol source not found: $source"
}

$bytes = [System.IO.File]::ReadAllBytes($source)
foreach ($relativeTarget in $targets) {
    $target = Join-Path $root $relativeTarget
    $directory = Split-Path -Parent $target
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory | Out-Null
    }
    [System.IO.File]::WriteAllBytes($target, $bytes)
    Write-Output "updated $relativeTarget"
}
