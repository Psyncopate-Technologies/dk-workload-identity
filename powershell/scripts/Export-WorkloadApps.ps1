<#
.SYNOPSIS
    Exports app client IDs for declared workloads in a Terraform-friendly shape.

.DESCRIPTION
    Reads a workloads config, looks up the live app registrations in Entra,
    and emits a JSON object mapping workload_key -> app_client_id. The output
    can be piped straight into a terragrunt tfvars file or rendered into the
    'workloads' map by hand.

.PARAMETER ConfigPath
    Path to the workloads JSON config.

.PARAMETER OutputPath
    Optional. If set, writes JSON to this file; otherwise prints to stdout.

.EXAMPLE
    ./powershell/scripts/Export-WorkloadApps.ps1 -ConfigPath ./powershell/config/workloads.dev.json `
        -OutputPath ./powershell/config/workloads.dev.appids.json
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ConfigPath,
    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. "$PSScriptRoot/../lib/DkEntraApps.ps1"

Assert-MgGraphConnected -RequiredScopes @("Application.Read.All")

$cfg = Read-WorkloadConfig -Path $ConfigPath

$out = [ordered]@{
    environment = $cfg.environment
    tenantId    = $cfg.tenantId
    workloads   = [ordered]@{}
}

foreach ($entry in $cfg.workloads.PSObject.Properties) {
    $workloadKey = $entry.Name
    $displayName = Get-WorkloadAppDisplayName `
        -NamePrefix  $cfg.namePrefix `
        -Environment $cfg.environment `
        -WorkloadKey $workloadKey

    $app = Find-WorkloadApp -DisplayName $displayName
    if ($null -eq $app) {
        Write-Warning "No app found for '$displayName' — skipping."
        continue
    }

    $out.workloads[$workloadKey] = [ordered]@{
        app_client_id  = $app.AppId
        object_id      = $app.Id
        display_name   = $app.DisplayName
        identifier_uri = ($app.IdentifierUris | Select-Object -First 1)
    }
}

$json = $out | ConvertTo-Json -Depth 10

if ($OutputPath) {
    $json | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Host "Wrote $OutputPath"
} else {
    $json
}
