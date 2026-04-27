<#
.SYNOPSIS
    Creates (or updates) Entra app registrations for every workload declared in the config.

.DESCRIPTION
    Idempotent. Re-running is safe — existing apps are reused, missing pieces (identifier URI,
    scope, federated credentials) are added in place.

    The output of this script feeds directly into the Terraform 'workloads' map:
    copy the printed appId into the 'app_client_ids' list of the corresponding workload
    in terraform/live/<env>/workloads.json (the field is a list — wrap a single value as
    ["<appId>"]; add more entries to share one pool across multiple Entra apps).

.PARAMETER ConfigPath
    Path to the workloads JSON config (see powershell/config/workloads.example.json).

.EXAMPLE
    Connect-MgGraph -TenantId 7bab0bc1-bb61-48d7-b2d4-79825c2ac6b8 -Scopes "Application.ReadWrite.All"
    ./powershell/scripts/New-WorkloadApps.ps1 -ConfigPath ./powershell/config/workloads.dev.json
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$ConfigPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. "$PSScriptRoot/../lib/DkEntraApps.ps1"

Assert-MgGraphConnected -RequiredScopes @("Application.ReadWrite.All")

$cfg = Read-WorkloadConfig -Path $ConfigPath

$ctx = Get-MgContext
if ($ctx.TenantId -ne $cfg.tenantId) {
    throw "Connected tenant ($($ctx.TenantId)) does not match config tenantId ($($cfg.tenantId))."
}

$results = @()

foreach ($entry in $cfg.workloads.PSObject.Properties) {
    $workloadKey = $entry.Name
    $workload    = $entry.Value

    $displayName = Get-WorkloadAppDisplayName `
        -NamePrefix  $cfg.namePrefix `
        -Environment $cfg.environment `
        -WorkloadKey $workloadKey

    $description = $null
    if ($workload.PSObject.Properties.Name.Contains("description")) {
        $description = $workload.description
    }

    $scopeName = "access_as_application"
    if ($workload.PSObject.Properties.Name.Contains("apiScopeName")) {
        $scopeName = $workload.apiScopeName
    }

    $app = New-WorkloadApp -DisplayName $displayName -Description $description -ApiScopeName $scopeName

    if ($workload.PSObject.Properties.Name.Contains("federatedCredentials")) {
        foreach ($fc in $workload.federatedCredentials) {
            $fcArgs = @{
                ApplicationObjectId = $app.Id
                Name                = $fc.name
                Issuer              = $fc.issuer
                Subject             = $fc.subject
            }
            if ($fc.PSObject.Properties.Name.Contains("audiences")) {
                $fcArgs.Audiences = $fc.audiences
            }
            if ($fc.PSObject.Properties.Name.Contains("description")) {
                $fcArgs.Description = $fc.description
            }
            Add-WorkloadFederatedCredential @fcArgs | Out-Null
        }
    }

    $results += [pscustomobject]@{
        workload       = $workloadKey
        display_name   = $displayName
        app_client_id  = $app.AppId
        object_id      = $app.Id
        identifier_uri = "api://$($app.AppId)"
    }
    # Display column kept singular for table readability; the Terraform field is a list.
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize

Write-Host ""
Write-Host "Paste these appIds into terraform/live/$($cfg.environment)/workloads.json:" -ForegroundColor Cyan
foreach ($r in $results) {
    Write-Host "  workloads[`"$($r.workload)`"].app_client_ids = [`"$($r.app_client_id)`"]"
}
