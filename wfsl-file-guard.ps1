param(
    [Parameter(Mandatory)]
    [string]$Path,

    [ValidateSet("create","verify")]
    [string]$Mode = "create",

    [ValidateSet("notepad","code","none")]
    [string]$Editor = "notepad"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# rest of script below
