# Azure Runbook Script for Fabric Capacity Management
param(
    [Parameter(Mandatory=$false)]
    [string]$CapacityName,
    
    [Parameter(Mandatory=$false)]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [object]$WebhookData
)

# Handle webhook data if called via webhook
if ($WebhookData) {
    Write-RunbookOutput "Processing webhook data..."
    
    # Parse the webhook request body
    if ($WebhookData.RequestBody) {
        try {
            $webhookParams = $WebhookData.RequestBody | ConvertFrom-Json
            $CapacityName = $webhookParams.CapacityName
            $Action = $webhookParams.Action
            Write-RunbookOutput "Extracted from webhook - CapacityName: $CapacityName, Action: $Action"
        } catch {
            Write-RunbookOutput "Failed to parse webhook request body: $($_.Exception.Message)" "Error"
            throw "Invalid webhook request body format"
        }
    }
}

# Validate required parameters
if (-not $CapacityName -or -not $Action) {
    $errorMsg = "Missing required parameters. CapacityName: '$CapacityName', Action: '$Action'"
    Write-RunbookOutput $errorMsg "Error"
    throw $errorMsg
}

# Validate Action parameter
if ($Action -notin @("suspend", "resume")) {
    $errorMsg = "Invalid action '$Action'. Must be 'suspend' or 'resume'"
    Write-RunbookOutput $errorMsg "Error"
    throw $errorMsg
}

# Get runbook variables (set these in your Automation Account)
try {
    $SubscriptionId = Get-AutomationVariable -Name "SubscriptionId"
    $ResourceGroupName = Get-AutomationVariable -Name "ResourceGroupName"
} catch {
    Write-Error "Failed to retrieve automation variables. Ensure 'SubscriptionId' and 'ResourceGroupName' are set as variables in your Automation Account."
    throw
}

# Function for consistent output
function Write-RunbookOutput {
    param(
        [string]$Message,
        [string]$Level = "Information"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "[$timestamp] [$Level] $Message"
}

try {
    Write-RunbookOutput "Starting Fabric capacity operation: $Action on $CapacityName"
    Write-RunbookOutput "Resource Group: $ResourceGroupName"
    Write-RunbookOutput "Subscription: $SubscriptionId"
    
    # Connect using Managed Identity (recommended for runbooks)
    Write-RunbookOutput "Connecting to Azure using Managed Identity..."
    try {
        $context = Connect-AzAccount -Identity
        Write-RunbookOutput "Successfully connected as: $($context.Context.Account.Id)"
    } catch {
        Write-RunbookOutput "Failed to connect with Managed Identity. Error: $($_.Exception.Message)" "Error"
        throw
    }

    # Set subscription context
    Write-RunbookOutput "Setting subscription context..."
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null

    # Check if capacity exists and get current state
    Write-RunbookOutput "Checking Fabric capacity status..."
    $capacity = Get-AzResource -ResourceGroupName $ResourceGroupName -Name $CapacityName -ResourceType "Microsoft.Fabric/capacities" -ErrorAction SilentlyContinue
    
    if (-not $capacity) {
        $errorMsg = "Fabric capacity '$CapacityName' not found in resource group '$ResourceGroupName'"
        Write-RunbookOutput $errorMsg "Error"
        throw $errorMsg
    }

    $currentState = $capacity.Properties.state
    Write-RunbookOutput "Current capacity state: $currentState"

    # Check if action is needed
    if (($Action -eq "resume" -and $currentState -eq "Active") -or 
        ($Action -eq "suspend" -and $currentState -eq "Paused")) {
        Write-RunbookOutput "Capacity is already in the desired state. No action needed."
        return @{
            Status = "Success"
            Message = "Capacity already in desired state: $currentState"
            CapacityName = $CapacityName
            Action = $Action
            FinalState = $currentState
        }
    }

    # Prepare REST API call
    Write-RunbookOutput "Preparing to $Action capacity..."
    
    # Get access token
    $context = Get-AzContext
    $token = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, "Never", $null, "https://management.azure.com/").AccessToken
    
    # Set API endpoint based on action
    $apiAction = if ($Action -eq "resume") { "resume" } else { "suspend" }
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Fabric/capacities/$CapacityName/$apiAction" + "?api-version=2022-07-01-preview"
    
    $headers = @{
        'Authorization' = "Bearer $token"
        'Content-Type' = 'application/json'
    }

    # Execute the operation
    Write-RunbookOutput "Executing $Action operation..."
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -ErrorAction Stop
        Write-RunbookOutput "$Action operation initiated successfully"
        # Log additional response details if available
        if ($response.operationId) {
        Write-RunbookOutput "Operation ID: $($response.operationId)"
        }
    } catch {
        $errorMsg = "Failed to $Action capacity. Error: $($_.Exception.Message)"
        if ($_.Exception.Response) {
            $errorMsg += " HTTP Status: $($_.Exception.Response.StatusCode)"
        }
        Write-RunbookOutput $errorMsg "Error"
        throw $errorMsg
    }

    # Monitor operation progress
    Write-RunbookOutput "Monitoring operation progress..."
    $maxAttempts = 30  # Maximum 5 minutes (30 * 10 seconds)
    $attempts = 0
    $expectedStates = @{
        "resume" = @("Resuming", "Active")
        "suspend" = @("Suspending", "Paused")
    }
    $finalState = if ($Action -eq "resume") { "Active" } else { "Paused" }
    
    do {
        Start-Sleep -Seconds 10
        $attempts++
        
        $capacity = Get-AzResource -ResourceGroupName $ResourceGroupName -Name $CapacityName -ResourceType "Microsoft.Fabric/capacities"
        $currentState = $capacity.Properties.state
        Write-RunbookOutput "Attempt $attempts - Current state: $currentState"
        
        if ($currentState -eq $finalState) {
            Write-RunbookOutput "✓ Operation completed successfully! Capacity is now: $currentState"
            break
        }
        
        if ($attempts -ge $maxAttempts) {
            $warningMsg = "Operation monitoring timed out after $maxAttempts attempts. Current state: $currentState"
            Write-RunbookOutput $warningMsg "Warning"
            break
        }
        
    } while ($currentState -in $expectedStates[$Action])

    # Return result object for webhook response
    $result = @{
        Status = if ($currentState -eq $finalState) { "Success" } else { "Warning" }
        Message = if ($currentState -eq $finalState) { 
            "Capacity $Action operation completed successfully" 
        } else { 
            "Operation initiated but final state verification timed out. Current state: $currentState" 
        }
        CapacityName = $CapacityName
        Action = $Action
        InitialState = $capacity.Properties.state
        FinalState = $currentState
        Duration = "$($attempts * 10) seconds"
    }
    
    Write-RunbookOutput "Operation summary: $($result | ConvertTo-Json -Compress)"
    return $result

} catch {
    $errorResult = @{
        Status = "Error"
        Message = $_.Exception.Message
        CapacityName = $CapacityName
        Action = $Action
        Error = $_.Exception.ToString()
    }
    
    Write-RunbookOutput "Operation failed: $($errorResult | ConvertTo-Json -Compress)" "Error"
    throw $_.Exception
}

Write-RunbookOutput "Runbook execution completed"