# Example: Windows Server 2025 VM

This example provisions a **Windows Server 2025** virtual machine on Nutanix AHV from an existing image using the Nutanix Terraform provider.

## Resources Created

- `nutanix_virtual_machine_v2` — A VM with 4 vCPUs, 8 GB RAM, and an OS disk cloned from the specified image.
- **Guest Customization** — Automatically applies a sysprep `unattend.xml` on first boot to configure the local Administrator account and regional settings.

## How It Works

The `unattend.xml` is rendered **inline** from Terraform variables and base64-encoded. It handles critical Sysprep passes (`offlineServicing`, `generalize`, `specialize`, and `oobeSystem`) to ensure a smooth first-boot experience on Windows Server 2025. The configuration is protected by `lifecycle { ignore_changes = [guest_customization] }` to prevent re-running Sysprep on subsequent applies.

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

6. After the VM boots, refresh to get its IP:
   ```bash
   terraform refresh
   terraform output vm_ip_address
   ```

## Variables

| Variable | Description |
|---|---|
| `nutanix_username` | Prism Central username |
| `nutanix_password` | Prism Central password |
| `nutanix_endpoint` | Prism Central hostname or IP |
| `nutanix_port` | Prism Central port (default: 443) |
| `image_name` | Name of the source image to clone the OS disk from |
| `subnet_name` | Name of the subnet to attach to the VM |
| `vm_name` | VM hostname and computer name |
| `admin_password` | Password for the local Administrator account |

## Outputs

| Output | Description |
|---|---|
| `vm_ip_address` | IP address assigned to the VM (available after boot) |
