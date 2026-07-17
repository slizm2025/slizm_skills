[CmdletBinding()]
param(
    [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) {
    $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}

function Decode-Utf8Base64([string]$Value) {
    return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Value))
}

$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$skills = @(
    'slizm-requirements-doc-from-code',
    'slizm-requirements-to-technical-design',
    'tech-doc-implementation'
)
$stageTerms = @{
    'slizm-requirements-doc-from-code' = @(
        (Decode-Utf8Base64 'Q29kZUdyYXBoIOS7o+eggei3r+eUsQ=='),
        (Decode-Utf8Base64 '5rK/5a6e6ZmF55Sf5pWI6Lev5b6E5YiG5p6Q546w54q2'),
        (Decode-Utf8Base64 'Q29kZUdyYXBoIOeKtuaAgQ=='),
        (Decode-Utf8Base64 '5Luj56CB546w54q25LiN5b6X6Ieq5Yqo5b2i5oiQ55uu5qCH')
    )
    'slizm-requirements-to-technical-design' = @(
        (Decode-Utf8Base64 'Q29kZUdyYXBoIOS7o+eggei3r+eUsQ=='),
        (Decode-Utf8Base64 '5bu656uLIENvZGVHcmFwaCDor63kuYnln7rnur8='),
        (Decode-Utf8Base64 '6LCD55So6ICF'),
        (Decode-Utf8Base64 '5b2x5ZON6Z2i')
    )
    'tech-doc-implementation' = @(
        (Decode-Utf8Base64 'Q29kZUdyYXBoIOS7o+eggei3r+eUsQ=='),
        (Decode-Utf8Base64 '57yW6L6R5YmN56Gu6K6k'),
        (Decode-Utf8Base64 '57yW6L6R5ZCO5b2x5ZON6Z2i5a6h6K6h'),
        (Decode-Utf8Base64 '5b2x5ZON6Z2i')
    )
}
$source = Join-Path $root 'shared\codegraph-integration.md'
$requiredProtocolTerms = @(
    'codegraph_explore',
    'codegraph explore',
    '.codegraph/',
    'CodeGraph-first',
    'codegraph init',
    'not-indexed',
    'query-failed',
    'stale-partial',
    'rg'
)
$requiredEvalTerms = @('.codegraph', 'codegraph_explore', 'codegraph explore', 'codegraph init', 'stale')
$forbiddenHostTerms = @('Qoder', 'Codex', 'Claude')
$errors = [System.Collections.Generic.List[string]]::new()
$sourceHash = $null

if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    $errors.Add("missing shared protocol: $source")
} else {
    $sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $source).Hash
    $sourceText = Get-Content -Raw -Encoding utf8 -LiteralPath $source
    foreach ($term in $requiredProtocolTerms) {
        if ($sourceText.IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
            $errors.Add("shared protocol missing required term: $term")
        }
    }
    foreach ($term in $forbiddenHostTerms) {
        if ($sourceText.IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            $errors.Add("shared protocol contains host-specific term: $term")
        }
    }
}

foreach ($skill in $skills) {
    $skillRoot = Join-Path $root $skill
    $skillFile = Join-Path $skillRoot 'SKILL.md'
    $protocol = Join-Path $skillRoot 'references\codegraph-integration.md'
    $evalFile = Join-Path $skillRoot 'evals\evals.json'

    if (-not (Test-Path -LiteralPath $skillFile -PathType Leaf)) {
        $errors.Add("$skill missing SKILL.md")
        continue
    }
    if (-not (Test-Path -LiteralPath $protocol -PathType Leaf)) {
        $errors.Add("$skill missing local CodeGraph protocol")
    } elseif ($sourceHash -and (Get-FileHash -Algorithm SHA256 -LiteralPath $protocol).Hash -ne $sourceHash) {
        $errors.Add("$skill local protocol differs from shared source")
    }

    $skillText = Get-Content -Raw -Encoding utf8 -LiteralPath $skillFile
    if ($skillText -notmatch '\]\(references/codegraph-integration\.md\)') {
        $errors.Add("$skill SKILL.md does not link its local protocol")
    }
    foreach ($term in $stageTerms[$skill]) {
        if ($skillText.IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
            $errors.Add("$skill SKILL.md missing route or stage term: $term")
        }
    }

    $frontmatter = [regex]::Match($skillText, '(?s)\A---\r?\n(.*?)\r?\n---\r?\n')
    if (-not $frontmatter.Success) {
        $errors.Add("$skill invalid frontmatter")
    } else {
        $frontmatterLines = @($frontmatter.Groups[1].Value -split '\r?\n' | Where-Object { $_.Trim() })
        if ($frontmatterLines.Count -ne 2 -or $frontmatterLines[0] -ne "name: $skill" -or $frontmatterLines[1] -notmatch '^description: .+') {
            $errors.Add("$skill frontmatter must contain matching name and description")
        }
    }

    if (Test-Path -LiteralPath $evalFile -PathType Leaf) {
        try {
            $evalText = Get-Content -Raw -Encoding utf8 -LiteralPath $evalFile
            $eval = $evalText | ConvertFrom-Json
            if ($eval.skill_name -ne $skill) {
                $errors.Add("$skill eval skill_name mismatch")
            }
            if (@($eval.evals.id | Sort-Object -Unique).Count -ne @($eval.evals).Count) {
                $errors.Add("$skill eval IDs are not unique")
            }
            if (@($eval.evals | Where-Object { $_.category -eq 'codegraph' }).Count -lt 4) {
                $errors.Add("$skill requires at least four CodeGraph evals")
            }
            foreach ($term in $requiredEvalTerms) {
                if ($evalText.IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
                    $errors.Add("$skill evals missing CodeGraph scenario term: $term")
                }
            }
        } catch {
            $errors.Add("$skill eval JSON is invalid: $($_.Exception.Message)")
        }
    } else {
        $errors.Add("$skill missing evals/evals.json")
    }

    foreach ($markdown in Get-ChildItem -LiteralPath $skillRoot -Recurse -File -Filter '*.md') {
        $markdownText = Get-Content -Raw -Encoding utf8 -LiteralPath $markdown.FullName
        foreach ($term in $forbiddenHostTerms) {
            if ($markdownText.IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                $errors.Add("$skill contains host-specific term '$term' in $($markdown.Name)")
            }
        }
        foreach ($match in [regex]::Matches($markdownText, '\]\(([^)]+)\)')) {
            $target = $match.Groups[1].Value.Split('#')[0]
            if (-not $target -or $target -match '^[a-z]+://' -or [System.IO.Path]::IsPathRooted($target)) {
                continue
            }
            $resolved = [System.IO.Path]::GetFullPath((Join-Path $markdown.DirectoryName $target))
            if (-not $resolved.StartsWith($skillRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
                $errors.Add("$skill link escapes skill directory: $target")
            } elseif (-not (Test-Path -LiteralPath $resolved)) {
                $errors.Add("$skill broken link in $($markdown.Name): $target")
            }
        }
    }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Output "validated $($skills.Count) skills, synchronized CodeGraph protocols, and CodeGraph eval coverage"
