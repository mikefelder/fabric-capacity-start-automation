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

> ⚠️ **Important**: Module import can take 10-15 minutes each. Wait for completion before proceeding.

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
4. **Copy the webhook URL immediately** - you cannot retrieve it later!
5. For parameters, enter placeholder values (these will be overridden by JSON payload):
   - **CAPACITYNAME**: `placeholder`
   - **ACTION**: `resume`
6. Click **Create**

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

### Common Issues and Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| "Capacity not found" | Incorrect capacity name or resource group | Verify `ResourceGroupName` variable and capacity name |
| "Access denied" | Missing permissions | Ensure Managed Identity has Contributor role on resource group |
| "Module not found" | Missing PowerShell modules | Import `Az.Accounts` and `Az.Resources` modules |
| "Invalid webhook request" | Malformed JSON | Verify JSON syntax and Content-Type header |
| Using placeholder values | Webhook data not processed | Ensure runbook code handles `$WebhookData` parameter |

### Log Analysis

The runbook provides detailed timestamped logging:
```
[2025-07-22 16:38:54] [Information] Starting Fabric capacity operation: resume on felderfabcap001
[2025-07-22 16:38:55] [Information] Current capacity state: Paused
[2025-07-22 16:38:56] [Information] Executing resume operation...
[2025-07-22 16:39:10] [Information] ✓ Operation completed successfully! Capacity is now: Active
```

## Security Best Practices

- **Webhook URL Security**: Store webhook URLs securely (Azure Key Vault, environment variables)
- **Access Control**: Limit access to webhook URLs
- **Expiration Management**: Set reasonable expiration dates and rotate regularly
- **Monitoring**: Monitor webhook usage through Automation Account logs
- **Principle of Least Privilege**: Grant minimal required permissions to Managed Identity

## Cost Optimization

This solution enables significant cost savings by:
- **Automated Scheduling**: Stop capacities during non-business hours
- **Event-Driven Control**: Start/stop based on usage patterns
- **Integration**: Connect with monitoring systems to respond to utilization metrics
- **Workflow Integration**: Embed capacity control in broader automation workflows

## API Reference

### Request Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `CapacityName` | String | Yes | Name of the Fabric capacity to control |
| `Action` | String | Yes | Either "suspend" or "resume" |

### Response Codes

- **200 OK**: Request accepted, job initiated
- **400 Bad Request**: Invalid JSON or missing parameters
- **401 Unauthorized**: Invalid webhook token
- **500 Internal Server Error**: Runbook execution error

## Runbook Script

The complete PowerShell runbook script handles:
- Webhook data processing
- Parameter validation
- Azure authentication via Managed Identity
- Fabric capacity state management
- Detailed logging and error handling
- Operation monitoring and status reporting

## Contributing

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly with your Automation Account
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Azure Automation Account job logs
3. Verify all prerequisites are met
4. Open an issue in this repository with detailed logs

## Version History

- **v2.0**: Added webhook support and Power Automate integration
- **v1.0**: Initial PowerShell script for direct execution

---

**Note**: Webhook URLs contain sensitive tokens. Never commit them to version control or share them publicly.