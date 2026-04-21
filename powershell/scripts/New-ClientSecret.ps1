<#
.SYNOPSIS
    Creates a client secret on a workload app registration.

.DESCRIPTION
    For local PoC testing (Path 2 — client-credentials grant) and for on-prem servers
    that cannot run Azure Arc. For Azure-native workloads, prefer a User-Assigned
    Managed Identity (keyless); no secret needed.

    The secret value is only returned once — save it to a gitignored .env or vault
    entry immediately.

.PARAMETER ConfigPath
    Path to the workloads JSON config.

.PARAMETER WorkloadKey
    Which workload (key in the config) to issue a secret for.

.PARAMETER DisplayName
    Secret label. Defaults to 'client-credentials'.

.PARAMETER ValidMonths
    Secret lifetime in months. Default 6.

.EXAMPLE
    ./powershell/scripts/New-ClientSecret.ps1 -ConfigPath ./powershell/config/workloads.dev.json `
        -WorkloadKey mergerarb-madam -ValidMonths 3
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$ConfigPath,
    [Parameter(Mandatory)][string]$WorkloadKey,
    [string]$DisplayName = "client-credentials",
    [int]$ValidMonths = 6
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. "$PSScriptRoot/../lib/DkEntraApps.ps1"

Assert-MgGraphConnected -RequiredScopes @("Application.ReadWrite.All")

$cfg = Read-WorkloadConfig -Path $ConfigPath

if (-not $cfg.workloads.PSObject.Properties.Name.Contains($WorkloadKey)) {
    throw "Config does not declare workload '$WorkloadKey'."
}

$displayNameOfApp = Get-WorkloadAppDisplayName `
    -NamePrefix  $cfg.namePrefix `
    -Environment $cfg.environment `
    -WorkloadKey $WorkloadKey

$app = Find-WorkloadApp -DisplayName $displayNameOfApp
if ($null -eq $app) {
    throw "App '$displayNameOfApp' does not exist yet — run New-WorkloadApps.ps1 first."
}

$secret = New-WorkloadClientSecret `
    -ApplicationObjectId $app.Id `
    -DisplayName         $DisplayName `
    -ValidMonths         $ValidMonths

if ($null -ne $secret) {
    Write-Host ""
    Write-Host "=== Secret — copy now ===" -ForegroundColor Cyan
    Write-Host "App             : $($app.DisplayName)"
    Write-Host "App client ID   : $($app.AppId)"
    Write-Host "Secret label    : $($secret.DisplayName)"
    Write-Host "Valid until     : $($secret.EndDate)"
    Write-Host "Secret value    : $($secret.SecretValue)"
    Write-Host ""
    Write-Host "Suggested .env entry:" -ForegroundColor Cyan
    Write-Host "  AZURE_CLIENT_ID=$($app.AppId)"
    Write-Host "  AZURE_CLIENT_SECRET=$($secret.SecretValue)"
    Write-Host "  AZURE_TENANT_ID=$($cfg.tenantId)"
}
