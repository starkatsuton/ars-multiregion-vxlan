# Azure Route Server Multi-Region Lab

This Terraform project deploys a multi-region Azure hub-and-spoke network topology with Azure Route Servers (ARS) and Network Virtual Appliances (NVAs) connected via VXLAN tunnels. The infrastructure demonstrates advanced routing scenarios using BGP peering between Azure Route Servers and NVAs across different regions.

## Architecture Overview

The lab creates a dual-hub architecture with the following components:

### Network Topology

```
Region 1 (Hub01)                          Region 2 (Hub02)
┌─────────────────────┐                   ┌─────────────────────┐
│  10.1.0.0/24        │ ◄────Peering────► │  10.2.0.0/24        │
│  ┌───────────────┐  │                   │  ┌───────────────┐  │
│  │ ARS01         │  │                   │  │ ARS02         │  │
│  │ 10.1.0.132/26 │  │                   │  │ 10.2.0.132/26 │  │
│  └───────┬───────┘  │                   │  └───────┬───────┘  │
│          │BGP       │                   │          │BGP       │
│  ┌───────┴───────┐  │                   │  ┌───────┴───────┐  │
│  │ NVA01         │  │   VXLAN Tunnel    │  │ NVA02         │  │
│  │ 10.1.0.4      │──┼──────(4789)───────┼──│ 10.2.0.4      │  │
│  │ 10.1.0.200    │  │                   │  │ 10.2.0.200    │  │
│  │ 172.16.0.11   │  │                   │  │ 172.16.0.21   │  │
│  └───────────────┘  │                   │  └───────────────┘  │
└──────────┬──────────┘                   └──────────┬──────────┘
           │Peering                                  │Peering
┌──────────┴──────────┐                   ┌──────────┴──────────┐
│  Spoke01            │                   │  Spoke02            │
│  10.1.1.0/24        │                   │  10.2.1.0/24        │
│  ┌──────────────┐   │                   │  ┌──────────────┐   │
│  │ test01       │   │                   │  │ test02       │   │
│  │ 10.1.1.11    │   │                   │  │ 10.2.1.11    │   │
│  └──────────────┘   │                   │  └──────────────┘   │
└─────────────────────┘                   └─────────────────────┘
```

### Components

#### Virtual Networks
- **Hub01** (10.1.0.0/24) - Primary hub with 3 subnets:
  - default-subnet: 10.1.0.0/25
  - RouteServerSubnet: 10.1.0.128/26
  - vxlan-subnet: 10.1.0.192/26
  
- **Hub02** (10.2.0.0/24) - Secondary hub with 3 subnets:
  - default-subnet: 10.2.0.0/25
  - RouteServerSubnet: 10.2.0.128/26
  - vxlan-subnet: 10.2.0.192/26

- **Spoke01** (10.1.1.0/24) - Spoke network peered with Hub01
- **Spoke02** (10.2.1.0/24) - Spoke network peered with Hub02

#### Azure Route Servers
- **ARS01** - Deployed in Hub01's RouteServerSubnet
  - BGP AS: 65515
  - BGP peers with NVA01 (AS 65501)
  - Branch-to-branch traffic enabled
  
- **ARS02** - Deployed in Hub02's RouteServerSubnet
  - BGP AS: 65515
  - BGP peers with NVA02 (AS 65502)
  - Branch-to-branch traffic enabled

#### Network Virtual Appliances (NVAs)
- **NVA01** (Ubuntu 24.04 LTS)
  - NIC1: 10.1.0.4 (BGP interface)
  - NIC2: 10.1.0.200 (VXLAN interface)
  - VXLAN IP: 172.16.0.11/24
  - BGP AS: 65501
  - Runs BIRD routing daemon
  
- **NVA02** (Ubuntu 24.04 LTS)
  - NIC1: 10.2.0.4 (BGP interface)
  - NIC2: 10.2.0.200 (VXLAN interface)
  - VXLAN IP: 172.16.0.21/24
  - BGP AS: 65502
  - Runs BIRD routing daemon

#### Test VMs
- **test01** - Ubuntu VM in Spoke01 (10.1.1.11)
- **test02** - Ubuntu VM in Spoke02 (10.2.1.11)

## Key Features

### VXLAN Tunnel
- A VXLAN tunnel (VNI 100) connects NVA01 and NVA02 over UDP port 4789
- Creates an overlay network (172.16.0.0/24) for BGP peering between NVAs
- Enables routing communication across the two hub networks

### BGP Routing
- Each NVA establishes BGP sessions with:
  - Local Azure Route Server (both primary and secondary instances)
  - Remote NVA over the VXLAN tunnel
- Route filtering prevents route loops and unwanted advertisements
- AS-Path prepending is handled to optimize routing decisions

### Network Security
- Network Security Group (NSG) allows:
  - SSH (TCP/22) for management
  - VXLAN (UDP/4789) for tunnel traffic
- Applied to all subnets except RouteServerSubnet

### VNet Peering
- Hub-to-hub peering enables inter-region connectivity
- Hub-to-spoke peering with:
  - Gateway transit enabled on hub side
  - Use remote gateways enabled on spoke side
  - Allows spoke VMs to learn routes from Azure Route Server

## Prerequisites

Before deploying this infrastructure, ensure you have:

1. **Azure Subscription** - An active Azure subscription
2. **Terraform** - Version 1.0 or later installed
3. **Azure CLI** - Installed and authenticated (`az login`)
4. **SSH Key Pair** - Public key stored at `./keys/kadmin_key.pub`

## Configuration

### Variables

The [variables.tf](variables.tf) file contains the following configurable parameters:

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `ars_rg_name` | `<resource_group_name>` | Resource group name |
| `location` | `<region_name>` | Azure region for deployment |
| `subscription_id` | `<your-subscription-id>` | Azure subscription ID |

**⚠️ Important**: Update the `ars_rg_name`, `location` and `subscription_id` in [variables.tf](variables.tf) with your own Azure resource group, preferred region and subscription ID before deployment.

## Deployment

### Step 1: Clone the Repository

```bash
git clone <repository-url>
cd ars-multiregion-lab
```

### Step 2: Generate SSH Key Pair

If you don't have an SSH key pair, generate one:

```bash
mkdir -p keys
ssh-keygen -t rsa -b 4096 -f keys/kadmin_key -N ""
```

### Step 3: Update Variables

Edit [variables.tf](variables.tf) and update the `ars_rg_name`, `location` and `subscription_id` variables with your Azure resource group, preferred region and subscription ID:

```terraform
variable "ars_rg_name" {
  default = "your-resource-group-name-here"
}

variable "location" {
  default = "your-preferred-region-name-here"
}

variable "subscription_id" {
  default = "your-subscription-id-here"
}
```

### Step 4: Initialize Terraform

```bash
terraform init
```

### Step 5: Review Deployment Plan

```bash
terraform plan
```

### Step 6: Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to confirm the deployment.

Deployment takes approximately 15-20 minutes.

## Post-Deployment Configuration

After the infrastructure is deployed, you need to configure the NVAs manually:

### Configure NVA01

1. SSH into NVA01:
   ```bash
   ssh -i keys/kadmin_key kadmin@<nva01-public-ip>
   ```

2. Run the configuration script:
   ```bash
   sudo bash
   # Copy and paste the contents of scripts/nva01_configuration.sh
   ```

### Configure NVA02

1. SSH into NVA02:
   ```bash
   ssh -i keys/kadmin_key kadmin@<nva02-public-ip>
   ```

2. Run the configuration script:
   ```bash
   sudo bash
   # Copy and paste the contents of scripts/nva02_configuration.sh
   ```

## Verification

### Verify VXLAN Tunnel

On NVA01:
```bash
ip link show vxlan-red
ping 172.16.0.21  # NVA02 VXLAN IP
```

On NVA02:
```bash
ip link show vxlan-blue
ping 172.16.0.11  # NVA01 VXLAN IP
```

### Verify BGP Sessions

On NVA01:
```bash
sudo birdc show protocols
sudo birdc show route
```

You should see three BGP sessions in "Established" state:
- azurerouteserverinstanceprimary
- azurerouteserverinstancesecondary
- vxlanpeer

### Verify Routing

From test01, test connectivity to test02:
```bash
ssh -i keys/kadmin_key kadmin@<test01-public-ip>
ping 10.2.1.11  # test02 private IP
traceroute 10.2.1.11
```

The traceroute should show the path going through NVA01, VXLAN tunnel, and NVA02.

### Check Azure Route Server Learned Routes

```bash
az network routeserver peering list-learned-routes \
  --name ars01-nva01-connection \
  --routeserver ars01 \
  --resource-group ars-rg
```

## Architecture Benefits

This design demonstrates several advanced Azure networking concepts:

1. **Multi-Region Connectivity** - Enables communication between resources in different Azure regions without ExpressRoute or VPN Gateway
2. **Custom Routing** - Uses BGP to dynamically advertise and learn routes
3. **Overlay Networks** - VXLAN provides a layer 2 overlay over layer 3 infrastructure
4. **High Availability** - Azure Route Server is deployed in high availability by default (2 instances)
5. **Scalability** - Hub-and-spoke topology allows easy addition of new spokes
6. **Traffic Inspection** - NVAs can be extended to include firewall or IDS/IPS capabilities

## Cost Considerations

The deployed resources will incur Azure charges:

- Azure Route Servers (2x) - ~$0.30/hour each
- Virtual Machines (4x) - Standard_D2s_v5 pricing
- Public IP Addresses (6x)
- VNet peering data transfer
- Outbound data transfer

**Estimated monthly cost**: $800-1000 USD (depending on region and usage)

## Cleanup

To destroy all resources and avoid ongoing charges:

```bash
terraform destroy
```

Type `yes` when prompted to confirm the destruction.

**Note**: Ensure all resources are deleted to avoid unexpected charges.

## Troubleshooting

### NVA Configuration Issues

If BGP sessions don't establish:

1. Verify IP forwarding is enabled:
   ```bash
   cat /proc/sys/net/ipv4/ip_forward
   ```

2. Check BIRD daemon status:
   ```bash
   systemctl status bird
   ```

3. Review BIRD logs:
   ```bash
   journalctl -u bird -f
   ```

### VXLAN Tunnel Issues

If VXLAN tunnel doesn't work:

1. Verify NSG rules allow UDP/4789
2. Check VXLAN interface status:
   ```bash
   ip link show type vxlan
   ```

3. Verify VXLAN endpoints:
   ```bash
   bridge fdb show dev vxlan-red  # or vxlan-blue
   ```

### Route Propagation Issues

If routes aren't propagating:

1. Check Azure Route Server BGP connection status in Azure Portal
2. Verify spoke VNets have "Use remote gateways" enabled in peering settings
3. Check effective routes on spoke VM NICs:
   ```bash
   az network nic show-effective-route-table \
     --name test01-nic \
     --resource-group ars-rg
   ```

## References

- [Azure Route Server Documentation](https://learn.microsoft.com/en-us/azure/route-server/)
- [BIRD Internet Routing Daemon](https://bird.network.cz/)
- [VXLAN Overview](https://datatracker.ietf.org/doc/html/rfc7348)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## License

This project is provided as-is for educational and testing purposes.

## Contributing

Feel free to submit issues or pull requests to improve this lab environment.

## Author

Created for Azure networking lab and learning purposes.
