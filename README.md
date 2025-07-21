# Azure Automation Runbook Setup for Fabric Capacity Control

> [!CAUTION]
> **07/21/2025: This PowerShell runbook script is currently not working as intended and is being revised**.


This guide provides instructions to set up an Azure Automation Runbook that accepts `Start` and `Stop` inputs via webhook. The Runbook will control the running state of a Microsoft Fabric capacity resource.

## Step 1: Create an Automation Account

1. Go to [https://portal.azure.com](https://portal.azure.com)
2. Search for **Automation Accounts** and click **+ Create**
3. Fill in the required fields (Name, Resource Group, Region)
4. Click **Review + Create**, then **Create**

## Step 2: Enable System-Assigned Managed Identity

1. In the Automation Account, go to **'Account Settings' ➡ 'Identity'**
2. Under **System assigned**, switch the status to **On**
3. Click **Save**

## Step 3: Assign Permissions to the Managed Identity

1. In the Azure Portal, navigate to the **Fabric capacity resource** in Azure
2. Open **'Access Control (IAM)' ➡ '➕ Add' ➡ '➕ Add role assignment'**
3. Select the **'Privileged administrator roles'** tab
4. Select the **Contributor** role and select **Next** to move to the Members tab
5. Under **'Assign access to'**, select **'Managed identity'** 
6. Under **Members**, click **'➕ Select members'*** to open the selection pane
7. Select **'Automation Account (N)'** under the **'System-assigned managed identity'** section
8. Select the Automation Account’s managed identity
6. At the bottom, select **Next**, and then **'Review + Assign'** to complete the assignment

## Step 4: Create the Runbook

1. Go to **'Process Automation' ➡ 'Runbooks' ➡ '➕ Create a runbook'**
2. Name it `StartStopFabricCapacity`
3. Choose **PowerShell** as the Runbook type
4. Choose the recommended version for Runtime version
5. Click **Create**

## Step 5: Add the Script to Runbook

1. Paste the PowerShell script provided into the Runbook editor
2. Replace:
- `<subscription-id>` with Azure subscription ID
- `<fabric-capacity-rg-name>` with targeted resource group name
- `<fabric-capacity-name>` with targeted fabric capacity resource name

## Step 6: Publish the Runbook

1. Click **Save** and then **Publish**.

## Step 7: Create a Webhook

1. In the Runbook, go to **Resources ➡ Webhook ➡ '➕ Add Webhook'**
2. Name it `StartStopFabricCapacity-wh` and set an expiration date (default is one year)
3. _**Copy the Webhook URL (shown only once)**_
4. Click **OK** to create and enable the webhook
