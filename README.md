# <img src="https://github.com/oracle-quickstart/oci-hpc-runbook-lsdyna/raw/main/images/lsdyna_logo.png" height="60"> LS-DYNA Runbook

# Introduction
This Runbook will take you through the process of deploying an LS Dyna cluster on Oracle Cloud with low latency networking between the compute nodes. Running LS Dyna on Oracle Cloud is quite straightforward, follow along this guide for all the tips and tricks.

[LS-DYNA](https://www.lstc.com/products/ls-dyna) is a general-purpose simulation program capable of simulating the response of materials, severe loading, by allowing users to control all details of their problem. This application is used in several industries including automotive, aerospace, construction, military, manufacturing, and bioengineering industries.

For details of the architecture, see [_High Performance Computing: LS-DYNA on Oracle Cloud Infrastructure_](https://docs.oracle.com/en/solutions/hpc-lsdyna/index.html)

## Prerequisites

- Permission to `manage` the following types of resources in your Oracle Cloud Infrastructure tenancy: `vcns`, `internet-gateways`, `route-tables`, `network-security-groups`, `subnets`, and `instances`.

- Quota to create the following resources: 1 VCN, 2 subnets, 1 Internet Gateway, 1 NAT Gateway, 1 Service Gateway, 3 route rules, and minimum 2 compute instances in instance pool or cluster network (plus bastion host).

If you don't have the required permissions and quota, contact your tenancy administrator. See [Policy Reference](https://docs.cloud.oracle.com/en-us/iaas/Content/Identity/Reference/policyreference.htm), [Service Limits](https://docs.cloud.oracle.com/en-us/iaas/Content/General/Concepts/servicelimits.htm), [Compartment Quotas](https://docs.cloud.oracle.com/iaas/Content/General/Concepts/resourcequotas.htm).

## Deploy Using Oracle Resource Manager

1. Click [![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?region=home&zipUrl=https://github.com/oracle-quickstart/oci-hpc-runbook-lsdyna/releases/latest/download/oci-hpc-runbook-lsdyna-stack-latest.zip)

    If you aren't already signed in, when prompted, enter the tenancy and user credentials.

2. Review and accept the terms and conditions.

3. Select the region where you want to deploy the stack.

4. Follow the on-screen prompts and instructions to create the stack.

5. After creating the stack, click **Terraform Actions**, and select **Plan**.

6. Wait for the job to be completed, and review the plan.

    To make any changes, return to the Stack Details page, click **Edit Stack**, and make the required changes. Then, run the **Plan** action again.

7. If no further changes are necessary, return to the Stack Details page, click **Terraform Actions**, and select **Apply**. 

## Deploy Using the Terraform CLI

### Clone the Module
Now, you'll want a local copy of this repo. You can make that with the commands:

    git clone https://github.com/oracle-quickstart/oci-hpc-runbook-lsdyna.git
    cd oci-hpc-runbook-lsdyna
    ls

### Set Up and Configure Terraform

1. Complete the prerequisites described [here](https://github.com/cloud-partners/oci-prerequisites).

2. Create a `terraform.tfvars` file, and specify the following variables:

```
# Authentication
tenancy_ocid         = "<tenancy_ocid>"
user_ocid            = "<user_ocid>"
fingerprint          = "<finger_print>"
private_key_path     = "<pem_private_key_path>"

# Region
region = "<oci_region>"

# Availablity Domain 
ad = "<availablity doman>" # for example "GrCH:US-ASHBURN-AD-1"

# Bastion 
bastion_ad               = "<availablity doman>" # for example "GrCH:US-ASHBURN-AD-1"
bastion_boot_volume_size = "<bastion_boot_volume_size>" # for example 50
bastion_shape            = "<bastion_shape>" # for example "VM.Standard.E3.Flex"
boot_volume_size         = "<boot_volume_size>" # for example 100
node_count               = "<node_count>" # for example 2
ssh_key                  = "<ssh_key>"
targetCompartment        = "<targetCompartment>" 
use_custom_name          = false
use_existing_vcn         = false
use_marketplace_image    = true
use_standard_image       = true
cluster_network          = false
instance_pool_shape      = "<instance_pool_shape>" # for example VM.Standard.E3.Flex
lsdyna_binaries          = "<lsdyna_binaries>" # for example https://objectstorage.us-phoenix-1.oraclecloud.com/p/CTYj(...)F7V/n/hpc/b/HPC_APPS/o/LS-DYNA_R12.0.0_CentOS-65_AVX2_MPP_S.zip"

````

### Create the Resources
Run the following commands:

    terraform init
    terraform plan
    terraform apply

### Destroy the Deployment
When you no longer need the deployment, you can run this command to destroy the resources:

    terraform destroy
    
# Architecture
![](https://github.com/oracle-quickstart/oci-hpc-runbook-fluent/blob/main/images/architecture-hpc.png "Architecture for Running LSDYNA in OCI")
The architecture for this runbook is as follow, we have one small machine (bastion) that you will connect into. The compute nodes will be on a separate private network linked with RDMA RoCE v2 networking. The bastion will be accesible through SSH from anyone with the key (or VNC if you decide to enable it). Compute nodes will only be accessible through the bastion inside the network. This is made possible with 1 Virtual Cloud Network with 2 subnets, one public and one private.

The above baseline infrastructure provides the following specifications:
-	Networking
    -	1 x 100 Gbps RDMA over converged ethernet (ROCE) v2
    -	Latency as low as 1.5 µs
-	HPC Compute Nodes (BM.HPC2.36)
    -	6.4 TB Local NVME SSD storage per node
    -	36 cores per node
    -	384 GB memory per node

# Upload LSDYNA binaries to Object Storage
1. Log In

You can start by logging in the Oracle Cloud console. If this is the first time, instructions to do so are available [here](https://docs.cloud.oracle.com/iaas/Content/GSG/Tasks/signingin.htm).
Select the region in which you wish to create your Object Storage Bucket. Click on the current region in the top right dropdown list to select another one. 

2. Go to Buckets by clicking on  <img src="https://github.com/oracle-quickstart/oci-hpc-runbook-lsdyna/blob/main/images/menu.png?raw=true" height="30">  and selecting **Storage**  <img src="https://github.com/oracle-quickstart/oci-hpc-runbook-lsdyna/blob/main/images/Storage%20option.png?raw=true" height="130">  > **Buckets**  <img src="https://github.com/oracle-quickstart/oci-hpc-runbook-lsdyna/blob/main/images/Buckets.png?raw=true" height="70">

3. Create a bucket by clicking  <img src="https://github.com/oracle-quickstart/oci-hpc-runbook-lsdyna/blob/main/images/Create%20bucket.png?raw=true" height="30">. Give your bucket a name and select the storage tier and encryption.

4. Once the bucket has been created, upload an object (binary) to the bucket by clicking **Upload**  <img src="https://github.com/oracle-quickstart/oci-hpc-runbook-lsdyna/blob/main/images/Upload%20Object.png?raw=true" height="90">  under **Objects**.

5. Create a Pre-Authenitcated Request (PAR) using the following steps:

	- Click on  <img src="https://github.com/oracle-quickstart/oci-hpc-runbook-lsdyna/blob/main/images/par%20menu.png?raw=true" height="40">  for the object, then select  <img src="https://github.com/oracle-quickstart/oci-hpc-runbook-lsdyna/blob/main/images/Create%20PAR%20button%20from%20menu.png?raw=true" height="30"> 

	- Select  <img src="https://github.com/oracle-quickstart/oci-hpc-runbook-lsdyna/blob/main/images/Object%20option%20PAR%20menu.png?raw=true" height="100">  for the **Pre-Authenticated Request Target** and then select an access type.

	- Click  <img src="https://github.com/oracle-quickstart/oci-hpc-runbook-lsdyna/blob/main/images/Create%20PAR.png?raw=true" height="30">

	- Be sure to copy the PAR URL by clicking <img src="https://github.com/oracle-quickstart/oci-hpc-runbook-lsdyna/blob/main/images/Copy.png?raw=true" height="30"> before closing because you will **NOT** have access to the URL again.  

6. Add this PAR to the lsdyna_binaries variable.

# Install Intel MPI 2018 librairies

Run those commands on every node. 
```
cd /nfs/cluster
wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB
sudo rpm --import GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB
sudo yum-config-manager --add-repo=https://yum.repos.intel.com/mpi
sudo yum install -y intel-mpi-2018.4-057 intel-mpi-samples-2018.4-274
```
	
# Running LS-DYNA

1. Navigate to Bastion - Find the public IP address of your remote host after the deployment job has finished:
<details>
	<summary>Resource Manager</summary>
	<p></p>
	If you deployed your stack via Resource Manager, find the public IP address of the compute node at the bottom of the CLI console logs.
	<p></p>
</details>
<details>
	<summary>Command Line</summary>
	<p></p>
	If you deployed your stack via Command Line, find the public IP address of the compute node at the bottom of the console logs on the <b>Logs</b> page, or on the <b>Outputs</b> page.
	<p></p>
</details>

2. SSH into your bastion host 
```
ssh -i PRIVATE KEY PATH opc@IP_ADDRESS
```

3. SSH into cluster
```
ssh hpc-node-1
```

3. Create a private key file - paste your license key into `lsdyna_private_key`
```
cd /nfs/cluster/lsdyna
vi lsdyna_private_key
```

4. Set read permissions on the private key file by running this command
```
chmod 600 lsdyna_private_key
```

5. Create a tunnel to your LS Dyna server on Node 1 

Example:
```
ssh -M -S control.socket -fnNT -i /nfs/cluster/lsdyna/lsdyna_private_key -L 31010:127.0.0.1:31010 opc@BASTION_IP_ADDRESS
```

6. Check to make sure the tunnel is successful by running this command
```
ps ax | grep lsdyna
```
The output should look like this: <img src="https://github.com/oracle-quickstart/oci-hpc-runbook-lsdyna/blob/main/images/Screen%20Shot%202021-06-22%20at%204.06.00%20PM.png?raw=true" height="35" >

7. To run, navigate to and run this [script](https://github.com/oracle-quickstart/oci-hpc-runbook-lsdyna/blob/main/Resources/LSDYNA_3car.sh)
```
/nfs/cluster/lsdyna/work
```
Be sure to set execution permission before running the [script](https://github.com/oracle-quickstart/oci-hpc-runbook-lsdyna/blob/main/Resources/LSDYNA_3car.sh).

Example:
```
chmod +x script.sh
```

Please change the variable on `line 35` with your LSDYNA path:
```
LSDYNA_EXE="/nfs/cluster/lsdyna/install/LS-DYNA_R12.0.0_CentOS-65_AVX2_MPP_S/ls-dyna_mpp_s_R12_0_0_x64_centos65_ifort160_avx2_intelmpi-2018"
```

