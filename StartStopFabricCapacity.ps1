param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("Start", "Stop")]
    [string]$Action
)

# Variables
$subscriptionId = "<your-subscription-id>"
$resourceGroup = "<your-resource-group>"
$capacityName = "<fabric-capacity-name>"
$apiVersion = "2023-11-01"

# Authenticate using Managed Identity
Connect-AzAccount -Identity
Set-AzContext -SubscriptionId $subscriptionId

# Perform the requested action
Invoke-AzResourceAction `
    -ResourceGroupName $resourceGroup `
    -ResourceType "Microsoft.Fabric/capacities" `
    -ResourceName $capacityName `
    -Action $Action.ToLower() `
    -ApiVersion $apiVersion `
    -Force

Write-Output "Fabric capacity $Action command sent."

