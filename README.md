# Azure Fabric Capacity Start/Stop Automation

A complete solution for automating Azure Fabric capacity start/stop operations using Azure Runbooks and webhooks. This enables cost optimization by programmatically controlling Fabric capacities through HTTP requests, Power Automate flows, or any system that can make REST API calls.

## Overview

This repository provides:
- PowerShell runbook for Azure Automation that can suspend/resume Fabric capacities
- Webhook-based invocation for integration with external systems
- Support for Power Automate workflows
- Cost optimization through automated capacity management

## Prerequisites

- Azure subscription with appropriate permissions
- Azure Automation Account
- Microsoft Fabric capacity deployed
- PowerShell execution policy allowing script execution

## Architecture

```
External System/Power Automate → Webhook → Azure Runbook → Fabric Capacity API
```

The solution uses Azure Managed Identity for secure authentication, eliminating the need for stored credentials.

## Setup Instructions

### Step 1: Create Azure Automation Account

1. Navigate to the Azure portal
2. Create a new **Automation Account**
3. Choose your subscription, resource group, and region
4. Enable **System assigned managed identity** during creation (or enable it later)

### Step 2: Configure Automation Account Variables

Set up the required configuration variables:

1. Go to your **Automation Account** → **Shared Resources** → **Variables**
2. Create the following variables:

| Variable Name | Type | Value | Description |
|---------------|------|-------|-------------|
| `SubscriptionId` | String | Your Azure subscription ID | Subscription containing the Fabric capacity |
| `ResourceGroupName` | String | Your resource group name | Resource group containing the Fabric capacity |

### Step 3: Configure Managed Identity Permissions

Grant the Automation Account permission to manage Fabric capacities:

1. Navigate to the **Resource Group** containing your Fabric capacity
2. Go to **Access control (IAM)** → **Add role assignment**
3. Select the **Contributor** role
4. Under **Assign access to**, select **Managed identity**
5. Choose your **Automation Account**
6. Click **Review + assign**

### Step 4: Import Required PowerShell Modules

The runbook requires Azure PowerShell modules:

1. In your **Automation Account**, go to **Shared Resources** → **Modules**
2. Click **Browse Gallery**
3. Import these modules in order (wait for each to complete):
   - `Az.Accounts`
   - `Az.Resources`
> [!NOTE]  
> Module import can take 10-15 minutes each. Wait for completion before proceeding.

### Step 5: Create and Deploy the Runbook

1. Go to **Process Automation** → **Runbooks** → **Create a runbook**
2. Configure the runbook:
   - **Name**: `StartStopFabricCapacity`
   - **Runbook type**: PowerShell
   - **Runtime version**: 5.1
   - **Description**: Automate Fabric capacity start/stop operations
3. Copy the PowerShell script from this repository into the editor
4. Click **Save**
5. Click **Test pane** to test the runbook (optional)
6. Click **Publish**

### Step 6: Create Webhook

1. In your runbook, go to **Resources** → **Webhooks**
2. Click **Add Webhook** → **Create new webhook**
3. Configure:
   - **Name**: `FabricCapacityWebhook`
   - **Enabled**: Yes
   - **Expires**: Set appropriate expiration date
4. **Copy the webhook URL immediately**
> [!WARNING]  
> The webhook URL **cannot** be retrieved later!
5. For parameters, enter placeholder values (these will be overridden by JSON payload):
   - **CAPACITYNAME**: `placeholder`
   - **ACTION**: `resume`
6. Click **Create**
> [!CAUTION]
> Webhook URLs contain sensitive tokens. Never commit them to version control or share them publicly.

## Usage

### REST API Calls

**Resume (Start) Capacity:**
```bash
curl -X POST "YOUR_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"CapacityName": "your-fabric-capacity-name", "Action": "resume"}'
```

**Suspend (Stop) Capacity:**
```bash
curl -X POST "YOUR_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"CapacityName": "your-fabric-capacity-name", "Action": "suspend"}'
```

### PowerShell Example
```powershell
$webhookUrl = "YOUR_WEBHOOK_URL"
$body = @{
    CapacityName = "your-fabric-capacity-name"
    Action = "resume"  # or "suspend"
} | ConvertTo-Json

Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $body -ContentType "application/json"
```

### Response Format

The webhook returns a job ID for tracking:
```json
{
  "JobIds": ["12345678-1234-1234-1234-123456789012"]
}
```

## Power Automate Integration

To use this in Power Automate flows:

1. Add an **HTTP** action
2. Set **Method** to `POST`
3. Set **URI** to your webhook URL
4. Add **Headers**:
   ```json
   {
     "Content-Type": "application/json"
   }
   ```
5. Set **Body**:
   ```json
   {
     "CapacityName": "@{variables('capacityName')}",
     "Action": "@{variables('action')}"
   }
   ```

## Monitoring and Troubleshooting

### View Execution Logs

1. Go to **Automation Account** → **Jobs**
2. Find your job by Job ID or timestamp
3. Click the job to view detailed output and any errors

## API Reference

### Request Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `CapacityName` | String | Yes | Name of the Fabric capacity to control |
| `Action` | String | Yes | Either "suspend" or "resume" |


## License

This project is licensed under the MIT License - see the LICENSE file for details.
