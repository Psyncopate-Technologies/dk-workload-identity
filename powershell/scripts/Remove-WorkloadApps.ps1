<#
.SYNOPSIS
    Deletes Entra app registrations for workloads declared in the config.

.DESCRIPTION
    Intended for PoC/cleanup — removes every app that matches the display-name pattern
    dk-confluent-{env}-{workload-key}. Will prompt unless -Force is passed.

.PARAMETER ConfigPath
    Path to the workloads JSON config.

.PARAMETER Force
    Skip the confirmation prompt. Required for non-interactive use.

.EXAMPLE
    ./powershell/scripts/Remove-WorkloadApps.ps1 -ConfigPath ./powershell/config/workloads.dev.json
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
param(
    [Parameter(Mandatory)][string]$ConfigPath,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. "$PSScriptRoot/../lib/DkEntraApps.ps1"

Assert-MgGraphConnected -RequiredScopes @("Application.ReadWrite.All")

$cfg = Read-WorkloadConfig -Path $ConfigPath

$targets = @()
foreach ($entry in $cfg.workloads.PSObject.Properties) {
    $displayName = Get-WorkloadAppDisplayName `
        -NamePrefix  $cfg.namePrefix `
        -Environment $cfg.environment `
        -WorkloadKey $entry.Name

    $app = Find-WorkloadApp -DisplayName $displayName
    if ($app) { $targets += $app }
}

if ($targets.Count -eq 0) {
    Write-Host "Nothing to delete." -ForegroundColor Yellow
    return
}

Write-Host "Targets:" -ForegroundColor Yellow
$targets | Select-Object DisplayName, AppId, Id | Format-Table -AutoSize

if (-not $Force -and -not $PSCmdlet.ShouldContinue("Delete $($targets.Count) app registration(s)?", "Confirm")) {
    Write-Host "Aborted." -ForegroundColor Yellow
    return
}

foreach ($app in $targets) {
    if ($PSCmdlet.ShouldProcess($app.DisplayName, "Remove-MgApplication")) {
        Remove-MgApplication -ApplicationId $app.Id
        Write-Information "Deleted $($app.DisplayName) ($($app.AppId))" -InformationAction Continue
    }
}
