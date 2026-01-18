Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Fail {
  param([string]$Message)
  Write-Error "[WFSL-FILE-GUARD] $Message"
  exit 1
}

function Get-Sha256Hex {
  param([Parameter(Mandatory=$true)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { return $null }
  (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Resolve-AbsolutePath {
  param([Parameter(Mandatory=$true)][string]$Path)
  if ([string]::IsNullOrWhiteSpace($Path)) { Fail "Missing path." }

  # If relative, anchor to current directory.
  if (-not [System.IO.Path]::IsPathRooted($Path)) {
    $Path = Join-Path (Get-Location).Path $Path
  }

  # Normalise.
  [System.IO.Path]::GetFullPath($Path)
}

function Ensure-ParentDirectory {
  param([Parameter(Mandatory=$true)][string]$AbsolutePath)
  $parent = Split-Path -Parent $AbsolutePath
  if (-not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent | Out-Null
  }
}

function Ensure-FileExists {
  param([Parameter(Mandatory=$true)][string]$AbsolutePath)
  if (-not (Test-Path -LiteralPath $AbsolutePath)) {
    New-Item -ItemType File -Path $AbsolutePath -Force | Out-Null
  }
}

function Invoke-Editor {
  param([Parameter(Mandatory=$true)][string]$AbsolutePath)

  $editor = $env:WFSL_EDITOR
  if ([string]::IsNullOrWhiteSpace($editor)) {
    $editor = "notepad.exe"
  }

  if ($editor -match '\s') {
    # If WFSL_EDITOR contains arguments, execute via cmd to preserve quoting.
    cmd.exe /c "$editor `"$AbsolutePath`""
    return
  }

  & $editor $AbsolutePath
}

function Write-VerificationRecord {
  param(
    [Parameter(Mandatory=$true)][string]$AbsolutePath,
    [Parameter(Mandatory=$true)][string]$BeforeHash,
    [Parameter(Mandatory=$true)][string]$AfterHash,
    [Parameter(Mandatory=$true)][string]$OutPath
  )

  $record = [ordered]@{
    tool = "wfsl-file-guard"
    version = "0.1.0"
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    file = @{
      path = $AbsolutePath
      sha256_before = $BeforeHash
      sha256_after = $AfterHash
      changed = ($BeforeHash -ne $AfterHash)
      exists_after = (Test-Path -LiteralPath $AbsolutePath)
    }
  } | ConvertTo-Json -Depth 6

  $outDir = Split-Path -Parent $OutPath
  if (-not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
  }

  $record | Set-Content -LiteralPath $OutPath -Encoding UTF8
}

param(
  [Parameter(Mandatory=$true, Position=0)]
  [string]$Path,

  [Parameter(Mandatory=$false)]
  [string]$Out = ".\evidence\wfsl-file-guard.json"
)

$abs = Resolve-AbsolutePath -Path $Path
Ensure-ParentDirectory -AbsolutePath $abs

$before = Get-Sha256Hex -Path $abs

Ensure-FileExists -AbsolutePath $abs

if (-not (Test-Path -LiteralPath $abs)) {
  Fail "File did not materialise after creation attempt: $abs"
}

Invoke-Editor -AbsolutePath $abs

if (-not (Test-Path -LiteralPath $abs)) {
  Fail "File missing after editor exit: $abs"
}

$after = Get-Sha256Hex -Path $abs

Write-VerificationRecord -AbsolutePath $abs -BeforeHash $before -AfterHash $after -OutPath $Out

Write-Host "[WFSL-FILE-GUARD] OK: $abs"
Write-Host "[WFSL-FILE-GUARD] Evidence: $Out"
exit 0
