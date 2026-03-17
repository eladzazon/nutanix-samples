# Nutanix Samples

A collection of Terraform examples for provisioning and managing infrastructure on **Nutanix AHV** using the [Nutanix Terraform Provider](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs).

## Examples

| Example | Description |
|---|---|
| [windows-server-2025](./examples/windows-server-2025/) | Deploy a Windows Server 2025 VM from an existing image |
| [windows-server-2025-domain-joined](./examples/windows-server-2025-domain-joined/) | Deploy a Windows Server 2025 VM and auto-join it to an Active Directory domain |

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- Access to a Nutanix Prism Central instance
- A valid image uploaded to the Nutanix Image Service

## Usage

1. Navigate to the example you want to use:
   ```bash
   cd examples/windows-server-2025
   ```

2. Copy the example variables file and fill in your values:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Initialize and apply:
   ```bash
   terraform init
   terraform apply
   ```
