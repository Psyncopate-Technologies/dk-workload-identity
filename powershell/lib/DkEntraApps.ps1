# Shared helper functions for the DK workload-identity Entra scripts.
# Dot-source from a script:  . "$PSScriptRoot/../lib/DkEntraApps.ps1"
#
# Requires Microsoft.Graph PowerShell module v2+:
#   Install-Module Microsoft.Graph -Scope CurrentUser

Set-StrictMode -Version Latest

function Assert-MgGraphConnected {
    [CmdletBinding()]
    param(
        [string[]]$RequiredScopes = @("Application.ReadWrite.All")
    )

    $ctx = Get-MgContext
    if ($null -eq $ctx) {
        throw "Not connected to Microsoft Graph. Run: Connect-MgGraph -TenantId <tenant-id> -Scopes '$($RequiredScopes -join ''', ''')'"
    }

    $missing = $RequiredScopes | Where-Object { $_ -notin $ctx.Scopes }
    if ($missing.Count -gt 0) {
        throw "Connected Graph session is missing scopes: $($missing -join ', '). Reconnect with -Scopes including these."
    }
}

function Get-WorkloadAppDisplayName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$NamePrefix,
        [Parameter(Mandatory)][string]$Environment,
        [Parameter(Mandatory)][string]$WorkloadKey
    )

    "$NamePrefix-$Environment-$WorkloadKey"
}

function Find-WorkloadApp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$DisplayName
    )

    # Filter-by-displayName returns a list; take the first match and warn if > 1.
    $apps = Get-MgApplication -Filter "displayName eq '$DisplayName'" -All
    if ($apps.Count -gt 1) {
        Write-Warning "Multiple applications found with displayName '$DisplayName' — using the first ($($apps[0].Id))."
    }
    $apps | Select-Object -First 1
}

function New-WorkloadApp {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$DisplayName,
        [string]$Description,
        [string]$ApiScopeName = "access_as_application"
    )

    $existing = Find-WorkloadApp -DisplayName $DisplayName
    if ($null -ne $existing) {
        Write-Information "App '$DisplayName' already exists (appId=$($existing.AppId)) — reusing." -InformationAction Continue
        return $existing
    }

    if (-not $PSCmdlet.ShouldProcess($DisplayName, "Create Entra app registration")) { return }

    $app = New-MgApplication -DisplayName $DisplayName -SignInAudience "AzureADMyOrg"

    # IdentifierUris can only be set AFTER the app exists and the AppId is known.
    $identifierUri = "api://$($app.AppId)"
    Update-MgApplication -ApplicationId $app.Id -IdentifierUris @($identifierUri)

    # Expose-an-API: one scope so admins can see the app is intentionally a resource.
    $scope = @{
        Id                       = [guid]::NewGuid().ToString()
        AdminConsentDescription  = "Allow the application to access Kafka on behalf of the workload."
        AdminConsentDisplayName  = $ApiScopeName
        IsEnabled                = $true
        Type                     = "Admin"
        Value                    = $ApiScopeName
    }
    Update-MgApplication -ApplicationId $app.Id -Api @{ Oauth2PermissionScopes = @($scope) }

    if ($Description) {
        Update-MgApplication -ApplicationId $app.Id -Description $Description
    }

    Write-Information "Created app '$DisplayName' (appId=$($app.AppId), identifierUri=$identifierUri)." -InformationAction Continue
    Get-MgApplication -ApplicationId $app.Id
}

function Add-WorkloadFederatedCredential {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$ApplicationObjectId,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Issuer,
        [Parameter(Mandatory)][string]$Subject,
        [string[]]$Audiences = @("api://AzureADTokenExchange"),
        [string]$Description
    )

    $existing = Get-MgApplicationFederatedIdentityCredential -ApplicationId $ApplicationObjectId |
        Where-Object { $_.Name -eq $Name }

    if ($null -ne $existing) {
        Write-Information "Federated credential '$Name' already exists on app $ApplicationObjectId — skipping." -InformationAction Continue
        return $existing
    }

    if (-not $PSCmdlet.ShouldProcess("$ApplicationObjectId/$Name", "Create federated identity credential")) { return }

    $params = @{
        ApplicationId = $ApplicationObjectId
        Name          = $Name
        Issuer        = $Issuer
        Subject       = $Subject
        Audiences     = $Audiences
    }
    if ($Description) { $params.Description = $Description }

    New-MgApplicationFederatedIdentityCredential @params
}

function New-WorkloadClientSecret {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$ApplicationObjectId,
        [string]$DisplayName = "client-credentials",
        [int]$ValidMonths = 6
    )

    if (-not $PSCmdlet.ShouldProcess($ApplicationObjectId, "Create client secret '$DisplayName'")) { return }

    $end = (Get-Date).AddMonths($ValidMonths)
    $pwd = Add-MgApplicationPassword -ApplicationId $ApplicationObjectId -PasswordCredential @{
        DisplayName = $DisplayName
        EndDateTime = $end
    }

    Write-Warning "Secret value is only returned once. Copy it now — there is no way to retrieve it later."
    [pscustomobject]@{
        DisplayName = $pwd.DisplayName
        KeyId       = $pwd.KeyId
        StartDate   = $pwd.StartDateTime
        EndDate     = $pwd.EndDateTime
        SecretValue = $pwd.SecretText
    }
}

function Read-WorkloadConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path
    )

    if (-not (Test-Path $Path)) {
        throw "Config file not found: $Path"
    }

    $cfg = Get-Content -Raw -Path $Path | ConvertFrom-Json -Depth 20

    foreach ($field in @("environment", "namePrefix", "tenantId", "workloads")) {
        if (-not $cfg.PSObject.Properties.Name.Contains($field)) {
            throw "Config at $Path is missing required field: $field"
        }
    }

    $cfg
}
