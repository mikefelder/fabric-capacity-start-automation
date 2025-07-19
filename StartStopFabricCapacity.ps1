param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("Start", "Stop")]
    [string]$Action
)

# Variables
$subscriptionId = "<subscription-id>"
$resourceGroup = "<fabric-capacity-rg-name>"
$capacityName = "<fabric-capacity-name>"
$apiVersion = "2023-11-01"

# Authenticate using Managed Identity
Connect-AzAccount -Identity
Set-AzContext -SubscriptionId $subscriptionId

# Perform the requested action
if ($Action -eq "Start") {
    Start-AzResource -ResourceType "Microsoft.Fabric/capacities" `
                     -ResourceName $capacityName `
                     -ResourceGroupName $resourceGroup `
                     -ApiVersion $apiVersion
    Write-Output "Fabric capacity started."
}
elseif ($Action -eq "Stop") {
    Stop-AzResource -ResourceType "Microsoft.Fabric/capacities" `
                    -ResourceName $capacityName `
                    -ResourceGroupName $resourceGroup `
                    -ApiVersion $apiVersion
    Write-Output "Fabric capacity stopped."
}

