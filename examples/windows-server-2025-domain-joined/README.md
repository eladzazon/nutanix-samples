# Example: Windows Server 2025 — Domain Joined

This example provisions a **Windows Server 2025** virtual machine on Nutanix AHV and automatically joins it to an **Active Directory domain** on first boot using a sysprep `unattend.xml` guest customization.

## How It Works

The `unattend.xml` is rendered **inline** from Terraform variables and base64-encoded — no external file needed. It runs during Windows Specialize pass and uses the `Microsoft-Windows-UnattendedJoin` component to join the domain. Subsequent `terraform apply` runs will not re-trigger sysprep thanks to `lifecycle { ignore_changes = [guest_customization] }`.

## Prerequisites

- A Windows Server 2025 image uploaded to the Nutanix Image Service (already sysprepped / generalized)
- Network connectivity between the VM subnet and your Active Directory domain controllers
- A domain account with permission to join computers to the domain

## Usage

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Fill in your values in `terraform.tfvars`

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Review the plan:
   ```bash
   terraform plan
   ```

5. Apply:
   ```bash
   terraform apply
   ```

6. After the VM boots and joins the domain, refresh to get its IP:
   ```bash
   terraform refresh
   terraform output vm_ip_address
   ```

## Variables

| Variable | Description | Required |
|---|---|---|
| `nutanix_username` | Prism Central username | Yes |
| `nutanix_password` | Prism Central password | Yes |
| `nutanix_endpoint` | Prism Central hostname or IP | Yes |
| `nutanix_port` | Prism Central port (default: 443) | Yes |
| `image_name` | Name of the source image | Yes |
| `subnet_name` | Name of the subnet to attach | Yes |
| `vm_name` | VM hostname and AD computer name | Yes |
| `domain_name` | FQDN of the AD domain (e.g. `corp.example.com`) | Yes |
| `domain_user` | Account with permission to join the domain | Yes |
| `domain_password` | Password for the domain join account | Yes |
| `domain_ou` | OU path for the computer account | No (defaults to `""`) |

## Outputs

| Output | Description |
|---|---|
| `vm_ip_address` | IP address assigned to the VM (available after boot) |
