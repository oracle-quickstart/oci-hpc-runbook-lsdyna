
# <img src="https://github.com/oci-hpc/oci-hpc-runbook-lsdyna/blob/master/lsdyna_logo.png" height="60"> LS-DYNA Runbook

 
## Table of Contents
- [Launch Cluster Network Steps](#launch-cluster-network-steps)
  - [Creation of Cluster Network through Marketplace](#creation-of-cluster-network-through-marketplace)
  - [Creation of Cluster Network through Manual Configuration](#creation-of-cluster-network-through-manual-configuration)
- [Access Your Cluster](#access-your-cluster)
- [Configure Visualization](#configure-visualization)
  - [Setting Up a VNC on your bastion](#setting-up-a-vnc-on-your-bastion)
  - [Add a GPU instance](#add-a-gpu-instance)
- [Accessing a VNC](#accessing-a-vnc)
- [Installing LS-DYNA](#installing-ls-dyna)
  - [Download the binaries](#download-the-binaries)
  - [Install LS-DYNA](#install-ls-dyna)
  - [Install MPI librairies](install-mpi-librairies)
- [Running LS-DYNA](#running-ls-dyna)
  - [Special case](#special-case)

# Launch Cluster Network Steps 
There are many ways to launch an HPC Cluster Network, this solutions guide will cover two different methods:
*	Via Marketplace
*	Manually
Depending on your OS, you will want to go with a specific method. If the HPC Cluster Network marketplace image or our OCI HPC CN Terraform scripts are used, this is for Oracle Linux 7 only. If you want to use CentOS, Ubuntu or another OS, manual configuration is required.

## Creation of Cluster Network through Marketplace
Marketplace holds applications and images that can be deployed with our infrastructure.  For customers that want to use Oracle Linux, an HPC Cluster Network image is available and can be launched from directly within marketplace.
We suggest launching the [CFD Ready Cluster](https://cloudmarketplace.oracle.com/marketplace/en_US/listing/75645211) that will contain librairies needed for CFD.

1.	Within marketplace, select <img src="https://github.com/oci-hpc/oci-hpc-runbook-lsdyna/blob/main/images/get_app.png" height="30"> at the top right.
2.	Select the OCI Region then click <img src="https://github.com/oci-hpc/oci-hpc-runbook-lsdyna/blob/main/images/sign_in.png" height="30">.
3.	Verify the version of the HPC Cluster image and then select the *Compartment* where the cluster will be launched. Accept the terms and conditions, then **Launch Stack**.
4.	Fill out the remaing details of the stack:
    1.	Select the desired <img src="https://github.com/oci-hpc/oci-hpc-runbook-lsdyna/blob/main/images/ad.png" height="30"> for the compute shapes and the bastion.
    2.	Copy-paste your public <img src="https://github.com/oci-hpc/oci-hpc-runbook-lsdyna/blob/main/images/ssh_key.png" height="30">
    3.	Type in the number of <img src="https://github.com/oci-hpc/oci-hpc-runbook-lsdyna/blob/main/images/compute_instances.png" height="30"> for the cluster
    4. Uncheck Install OpenFOAM
    5. If you need more than 6TB of Shared disk space, check GlusterFS and select how many servers you would need. (6TB per server)
5.	Click <img src="https://github.com/oci-hpc/oci-hpc-runbook-lsdyna/blob/main/images/create.png" height="30">.
6.	Navigate to *Terraform Actions* then click **Apply**. This will launch the CN provisioning.
7.	Wait until the job shows ‘Succeeded’ then navigate to **Outputs** to obtain the bastion and compute node private IP’s. 


## Creation of Cluster Network through Manual Configuration
Marketplace holds applications and images that can be deployed with our infrastructure.  For customers that want to use Oracle Linux, you can manually create a cluster network as follows:
1.	Select the OCI Region on the top right.
2.	In the main menu, select **Networking** and **Virtual Cloud Network**
3.	Click on Start VCN Wizard, and select **VCN with Internet Connectivity**
4.	Choose and name, the right compartment, and use 172.16.0.0/16 as **VCN CIDR**, 172.16.0.0/24 for Public Subnet and 172.16.1.0/24 for Private Subnet
5.	In the main menu, select **Compute**, **Instances**, then **Create Instance**
6.	Change the Image and select the **Oracle Image** tab, select **Oracle Linux 7 - HPC Cluster Networking Image**
7.	Select the **Availability Domain** in which you can spin up a BM.HPC2.36 instance
8.	Change the **shape** to BM.HPC2.36 under Bare Metal and Specialty
9.	Select the VCN and the public subnet you created. 
10.	Add a public key to connect to the instance. This key will be used on all compute instances. 
11.	Once the machine is up, click on the created instance. Under **More Actions**, select **Create Instance Configuration**. You can now **terminate** the instance under **More Actions**. 
12.	In the main menu, select **Compute**, then **Cluster Networks**
13.	Click **Create Cluster Network** and fill in all the options. Use the VCN, private subnet and instance configuration that you just created. Select the AD in which you can launch BM.HPC2.36 instances. 
14.	Launch the cluster network. 
15.	While it is loading, create another instance under **Main Menu**, **Compute** and **Instances**.
16.	Put it in the public subnet that was just created, using your public key and shape should be VM.Standard2.1 or similar. This will be the bastion that we will use to connect to the cluster. 
17.	SCP the key to the cluster on the bastion at /home/opc/.ssh/cluster_key and copy it also to /home/opc/.ssh/id_rsa
19.	Install the Provisioning Tool on the bastion via the following command:
```
sudo rpm -Uvh https://objectstorage.us-ashburn-1.oraclecloud.com/n/hpc/b/rpms/o/oci-hpc-provision-20190905-63.7.2.x86_64.rpm
```
18.	Navigate to **Compute** then **Instance Pools** in the Console and collect all the IP addresses for the cluster network pool. Or use this command on the bastion if you have nothing else running on your private subnet. 
```
for i in `nmap -sL Private_Subnet_CIDR | grep "Nmap scan report for" | grep ")" | awk '{print $6}'`;do echo ${i:1:-1} >> /tmp/ips; done
```
21.	Install the Provisioning Tool via the following command:
```
ips=`cat /tmp/ips`
/opt/oci-hpc/setup-tools/cluster-provision/hpc_provision_cluster_nodes.sh -p -i /home/opc/.ssh/id_rsa $ips
```

# Access your Cluster 
The public IP address of the bastion can be found on the lower left menu under Outputs. If you navigate to your instances in the main menu, you will also find your bastion instance as well as the public IP. 

The Private Key to access the machines can also be found there. Copy the text in a file on your machine, let's say/home/user/key:
```
chmod 600 /home/user/key 
ssh -i /home/user/key opc@ipaddress 
```

# Configure Visualization
HPC workloads often require visualization tools for scheduling, monitoring or analyzing the output of the simulations.  In these scenarios, it is often desired to create a GPU visualization node for optimal resolution and post processing. A GUI is not installed by default on OCI instances; however, one can be configured easily using VNC or X11 remote display protocol. The subsections below will walk through how to create a GPU visualization node in the public subnet using TurboVNC and OpenGL.

## Setting Up a VNC on your bastion
By default, the only access to the Oracle Linux machine is through SSH in a console mode. If you want to see the graphical interface, you will need to set up a VNC connection. The following script will work for the default user opc. The password for the vnc session is set as "HPC_oci1" but it can be edited in the next set of commands.
If you are not currently connected to the headnode via SSH, please do so as these commands need to be run on the headnode.
```
sudo yum -y groupinstall "Server with GUI"
sudo yum -y install tigervnc-server mesa-libGL
sudo systemctl set-default graphical.target
sudo cp /usr/lib/systemd/system/vncserver@.service /etc/systemd/system/vncserver@:1.service
sudo sed -i 's/<USER>/opc/g' /etc/systemd/system/vncserver@:1.service
sudo sed -ie '/^ExecStart=/a PIDFile=/home/opc/.vnc/%H%i.pid' /etc/systemd/system/vncserver@:1.service
sudo mkdir /home/opc/.vnc/
sudo chown opc:opc /home/opc/.vnc
echo "password" | vncpasswd -f > /home/opc/.vnc/passwd
chown opc:opc /home/opc/.vnc/passwd
chmod 600 /home/opc/.vnc/passwd
sudo systemctl start vncserver@:1.service
sudo systemctl enable vncserver@:1.service
```

## Add a GPU instance.
The below steps are taken Using OpenGL to Enhance GPU Use cases on OCI - refer to the blog for more details. 
1.	Within the Console, navigate to Compute then Instances.
2.	Create a Compute Instance for the Visualization Node:
a.	Select the desired AD
b.	Select the desired GPU shape (either VM or BM)
c.	Specify a GPU-compatible Oracle Linux image
The latest Oracle Linux Image will automatically be GPU enabled. 
d.	Select the Cluster Network VCN and Public Subnet
e.	Copy-paste your public ssh key
f.	Click Create.
3.	Wait for the instance to provision then log into the instance via:   
```
ssh opc@<public ip> -i <private key> 
```
4.	Install X Window System, a display manager (GNOME/GDM), and a desktop environment (MATE):
```
sudo yum groupinstall "X Window System"
sudo yum install gdm
sudo yum groupinstall "MATE Desktop"
```
5.	Install VNC server and VirtualGL. Note that VirtualGL is an open source toolkit that lets any Linux or Unix console run OpenGL applications with full hardware acceleration.
```
sudo yum install https://downloads.sourceforge.net/project/virtualgl/2.6.3/VirtualGL-2.6.3.x86_64.rpm
sudo yum install https://downloads.sourceforge.net/project/turbovnc/2.2.4/turbovnc-2.2.4.x86_64.rpm
```
6.	Configure the X server to enable GPU sharing for virtual sessions. Run the following commands:
```
sudo nvidia-xconfig --use-display-device=none --busid="PCI:4:0:0"
```
7.	Configure the X server to enable GPU sharing for virtual sessions. Run the following commands:
```
sudo vglserver_config -config -s -f -t
```
8.	To avoid being locked out when the screen saver launches, set the local user password to something you can use later:
```
sudo passwd opc
```
9.	Change your VNC password to something you can use for logging on:
```
vncpasswd
```
10.	Restart the X Server:
```systemctl restart gdm
kill $(pgrep Xvnc)
vncserver
```
11.	Enable and Start GDM:
```
systemctl enable gdm --now
```
12.	Launch the VNC server:
```
/opt/TurboVNC/bin/vncserver -wm mate-session
```
13.	If you want to access the VNC server directly without SSH forwarding, ensure that your security list allows connections on port 5901/tcp.
    1.	In the Console, navigate to Networking then Virtual Cloud Networks.
    2.	Select Subnets and then the public subnet.
    3.	In the default security list, add an Ingress Rule with the following details:
        1.	Stateless: No
        2.	Source Type: CIDR
        3.	Source CIDR: 0.0.0.0/0
        4.	IP Protocol: TCP
        5.	Source Port Range: All
        6.	Destination Port Range: 5901

Note: The standard VNC port is 5900 plus a display number (for example, 5901 for :1, 5902 for :2)

14.	Allow access in local firewall settings, as follows:
```
sudo firewall-cmd --zone=public --permanent --add-port=5901/tcp
sudo firewall-cmd --reload
```
15.	Open TurboVNC or TigerVNC client. Enter the IP address connection as <public ip>:1




# Accessing a VNC
We will connect through an SSH tunnel to the instance. On your machine, connect using ssh
PORT below will be the number that results from 5900 + N. N is the display number, if the output for N was 1, PORT is 5901, if the output was 9, PORT is 5909
public_ip is the public IP address of the headnode, which is running the VNC server.
If you used the previous instructions, port will be 5901
```
ssh -L 5901:127.0.0.1:5901 opc@public_ip
```
You can now connect using any VNC viewer using localhost:N as VNC server and the password you set during the vnc installation.
You can chose a VNC client that you prefer or use this guide to install on your local machine:
*	[Windows - TigerVNC](https://github.com/TigerVNC/tigervnc/wiki/Setup-TigerVNC-server-%28Windows%29) 
*	[MacOS/Windows - RealVNC](https://www.realvnc.com/en/connect/download/)

# Installing LS-Dyna

## Download the binaries
You can download the LS-DYNA binaries from the [LSTC website](http://www.lstc.com/download/ls-dyna) and push it to your machine using scp. 
Take the version that was created for mpi and compiled for RedHat Ent Srv 5.4. 
According to our findings, IntelMPI performs faster than Platform MPI on OCI. 
(ls-dyna_mpp_s_r10_1_123355_x64_centos65_ifort160_avx2_intelmpi-413 (1).tar.gz)
```
scp /path/own/machine/ls-dyna_mpp_s_r10_1_123355_x64_centos65_ifort160_avx2_intelmpi-413.tar.gz opc@1.1.1.1:/home/opc/
```
Another possibility is to upload the installer into object storage. 
1.	In the main menu of the console, select Object Storage. 
2.	Choose the correct region on the top right
3.	Select the correct compartment on the left-hand side
4.	Create a bucket if you do not have one already created
5.	In the bucket, select upload object and specify the path of the installer. 
6.	Select the 3 dots on the right-hand side of the installer object and select Create Pre-Authenticated Request
7.	If you lose the URL, you cannot get it back, but you can regenerate a new Pre-Authenticated Request

Download the installer form object storage with
```
wget PAR_URL
```
Untar or unzip the installer depending on your version
```
tar -xf installer.tgz
unzip installer.tgz
```

## Install LS-DYNA
Untar the binaries on a shared location. By default, an HPC cluster has a NFS-share or a Gluster-share mounted on all the compute nodes. 
```
mkdir /mnt/nfs-share/install/lsdyna
mv ls-dyna_mpp_s_r10_1_123355_x64_centos65_ifort160_avx2_intelmpi-413.tar.gz /mnt/nfs-share/install/lsdyna/
cd /mnt/nfs-share/install/lsdyna/
tar -xf ls-dyna_mpp_s_r10_1_123355_x64_centos65_ifort160_avx2_intelmpi-413.tar.gz
```

## Install MPI librairies
### Intel MPI 2018

Run those commands on every node. 
```
wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB
sudo rpm --import GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB
sudo yum-config-manager --add-repo=https://yum.repos.intel.com/mpi
sudo yum install -y intel-mpi-2018.4-057 intel-mpi-samples-2018.4-274
```
### Platform MPI

Install those librairies: 
```
sudo yum install -y glibc.i686 libgcc.x86_64 libgcc.i686
```

Download the tar file from the IBM website and run:
```
chmod 777 platform_mpi-09.01.04.03r-ce.bin
./platform_mpi-09.01.04.03r-ce.bin
```
Then follow the instructions on the screen. If you install platform on a share drive, it will be accessible to all compute nodes. 

# Running LS-DYNA
Running LS-DYNA is pretty straightforward.
To specify the host you need to run on, you need to create a machinefile. You can generate it as follow, or manually. Format is hostname:corenumber for both Platform and IntelMPI.
```
sed 's/$/:36/' /etc/opt/oci-hpc/hostfile > machinefile
```
Some run parameters can be specified by a parameter file: `pfile`

```
gen { nodump nobeamout dboutonly }
dir { global /mnt/nfs-share/benchmark/one_global_dir local /dev/shm }
```

This particular pfile tells LSDyna not to dump to much information to the disk. Uses memory to store local files and store global files into `/mnt/nfs-share/benchmark/one_global_dir`.

ANother place to store local files if it does not fit in the memory is `/mnt/localdisk/tmp` to use the local NVMe on the machine to store those files.

To run on multiple nodes, place the model on the share drive (Ex:/mnt/nfs-share/work/).
Example provided here is to run the 3 cars model. . You can add it to object storage like the installer and download it or scp it to the machine.
```
wget https://objectstorage.us-phoenix-1.oraclecloud.com/p/qwbdhqwdhqh/n/tenancy/b/bucket/o/3cars_shell2_150ms.k
```
Make sure you have set all the right variables for mpi to run correctly. 
Run it with the following command for Intel MPI (change the modelname and core number):
```
mpirun -np 256 -hostfile ./hostfile_rank \
-ppn 32 -iface enp94s0f0 -genv I_MPI_FABRICS=shm:dapl -genv DAT_OVERRIDE=/etc/dat.conf -genv I_MPI_DAT_LIBRARY=/usr/lib64/libdat2.so \
-genv I_MPI_DAPL_PROVIDER=ofa-v2-cma-roe-enp94s0f0 -genv I_MPI_FALLBACK=0 -genv I_MPI_DAPL_UD=0 -genv I_MPI_ADJUST_ALLREDUCE 5 -genv I_MPI_ADJUST_BCAST 1 -genv I_MPI_DEBUG=4 \
-genv I_MPI_PIN_PROCESSOR_LIST=0-35 -genv I_MPI_PROCESSOR_EXCLUDE_LIST=36-71 \
/mnt/nfs-share/LSDYNA/ ls-dyna_mpp_s_r9_2_119543_x64_redhat54_ifort131_sse2_intelmpi-413 
i=3cars_shell2_150ms.k \
memory=1000m memory2=160m p=pfile
```
 
For platform MPI: 
```
mpirun -np 256 -hostfile ./hostfile_rank -ppn 32 \ 
-d -v -prot -intra=shm -e MPI_FLAGS=y -e MPI_HASIC_UDAPL=ofa-v2-cma-roe-enp94s0f0 -UDAPL \
/mnt/nfs-share/LSDYNA/ls-dyna_mpp_s_r9_2_119543_x64_redhat54_ifort131_sse2_platformmpi \
i=3cars_shell2_150ms.k \
memory=1000m memory2=160m p=pfile
```

## Special case

For some model, Douple Precision executables will not be enough to do the decomposition of the model. You can either use the double precision version of the executable or you can do the decomposition in double precision and still do the run in single precision to gain speed. 
			
For the decomposition, add `ncycles=2` to the command line and add this part to the pfile: 	
```
decomposition {								
 file decomposition								
 rcblog rcblog								
}
```
The model will be decomposed in a file called decomposition and stored in the directory of the model. During the second run, LS-Dyna will see this file and not redo the decomposition. 
								
For the run in Single precision, you can use the same commands in the pfile.
