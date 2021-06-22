#!/bin/bash
 
#GENERAL VARIABLES
MODEL_VERS="N/A"
CELLS=0
export LSTC_LICENSE_SERVER=127.0.0.1
export LSTC_MEMORY=AUTO
export LSTC_LICENSE=network

source /opt/intel/compilers_and_libraries_2018.5.274/linux/mpi/intel64/bin/mpivars.sh
export PATH=/opt/intel/compilers_and_libraries_2018.5.274/linux/mpi/intel64/bin:$PATH
export LD_LIBRARY_PATH=/opt/intel/compilers_and_libraries_2018.5.274/linux/mpi/intel64/lib:$LD_LIBRARY_PATH
export PATH=/opt/intel/compilers_and_libraries_2018.5.274/linux/mpi/intel64/bin/mpirun:$PATH

#GET BASIC SYSTEM INFO
OFED_VERS=`ofed_info -s`
OS_VERS=`cat /etc/*-release | grep "PRETTY_NAME" | cut -d= -f2`
OS_VERS="${OS_VERS%\"}"
OS_VERS="${OS_VERS#\"}"
KERNEL_VERS=`uname -r`
HPC_TOOLS_VERS=N/A
IMAGE_VERS=""  ###TODO - in the terraform scripts, have one of the outputs be gather the image version details to export
HOSTNAME=`hostname`
dt=$( date '+%FT%H:%M:%S'.123Z )


#COMMAND LINE VARIABLES:
MODELNAME=3cars
NODES_ITER=2
PPN=36
COMMENT="LS-DYNA_R12.0.0_CentOS-65_AVX2_MPP_S on BM.HPC2.36 with intel 2018, 3cars model"
MACHINEFILE="/nfs/cluster/lsdyna/work/machinefile"
MPINAME="intel"
INSTANCE="BM.HPC2.36"
LSDYNA_EXE="/nfs/cluster/lsdyna/install/LS-DYNA_R12.0.0_CentOS-65_AVX2_MPP_S/ls-dyna_mpp_s_R12_0_0_x64_centos65_ifort160_avx2_intelmpi-2018" ##replace with your LSDYNA path
VERS="R12_intel_avx2"
MPI_NAME=$MPINAME
NETWORK="RDMA"
REGION=""
ENVIRONMENT="OCI"
CUSTOMER_NAME="N/A"
POC="N/A"
IMAGE_OCID=""
 

#MPI FLAGS VARIABLES:
if [ $INSTANCE=='BM.HPC2.36' ]; then
        if [ "$MPINAME" == "intel" ]; then
                MPI_FLAGS="-iface enp94s0f0 -genv I_MPI_DAPL_PROVIDER ofa-v2-cma-roe-enp94s0f0 -genv I_MPI_DAPL_UD 0 -genv I_MPI_FALLBACK 0 -genv I_MPI_DYNAMIC_CONNECTION 0 -genv I_MPI_FABRICS shm:dapl -genv I_MPI_DAT_LIBRARY /usr/lib64/libdat2.so -genv I_MPI_DEBUG 6 -genv I_MPI_PIN_PROCESSOR_LIST=0-35 -genv I_MPI_PROCESSOR_EXCLUDE_LIST=36-71"
 
        elif [ "$MPINAME" == "openmpi" ]; then
                echo "running OpenMPI"
                MPI_FLAGS="-mca btl self -x UCX_TLS=rc,self,sm -x HCOLL_ENABLE_MCAST_ALL=0 -mca coll_hcoll_enable 0 -x UCX_IB_TRAFFIC_CLASS=105 -x UCX_IB_GID_INDEX=3 --cpu-set 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35"
 
        elif [ "$MPINAME" == "platform" ]; then
                echo "running platform"
                MPI_FLAGS="-intra=shm -e MPI_HASIC_UDAPL=ofa-v2-cma-roe-enp94s0f0 -UDAPL -aff=automatic:bandwidth:core -affopt=v -prot"
 
        else
                MPI_FLAGS=""
        fi
else
        MPI_FLAGS=""
fi
echo "part4"

 
#GET MPI VERSION:
MPI_VERSION=`mpirun -version | awk 'NR==1'`
echo "part5"

 
#SET MODEL PARAMETERS:
memory_param=""
ENDTIME=""
case "$MODELNAME" in
3cars)
        K_FILE="3cars_shell2_150ms.rev02.k"
        P_FILE="pfile.default"
        MODEL_VERS="rev02"
        memory_param="memory=48M memory2=3600K"
        CELLS=800000
        ;;
car2car-10ms)
        K_FILE="Caravan-V03c_ver10-2020.04.k"
        P_FILE="pfile.default"
        ENDTIME="endtime=0.010"
        MODEL_VERS="rescale-model"
        memory_param="memory=180M memory2=9829K"
        CELLS=2400000
        ;;
car2car-30ms)
        K_FILE="Caravan-V03c_ver10-2020.04.k"
        P_FILE="pfile.default"
        ENDTIME="endtime=0.030"
        MODEL_VERS="rescale-model"
        memory_param="memory=180M memory2=9829K"
        CELLS=2400000
        ;;
odb10m)
        K_FILE="odb10m-ver18.k"
        P_FILE="pfile.decomp20"
        MODEL_VERS="ver18"
        #memory_param="memory=1800M  memory2=340M"
        memory_param="memory=800M  memory2=200M"
        CELLS=10317536
        ;;
odb10m-10ms)
        K_FILE="odb10m-ver18.k"
        P_FILE="pfile.decomp20"
        ENDTIME="endtime=0.010"
        MODEL_VERS="ver18"
        #memory_param="memory=1800M  memory2=340M"
        memory_param="memory=800M  memory2=200M"
        CELLS=10317536
        ;;
odb10m-30ms)
        K_FILE="odb10m-ver18.k"
        P_FILE="pfile.decomp20"
        ENDTIME="endtime=0.030"
        MODEL_VERS="ver18"
        #memory_param="memory=1800M  memory2=340M"
        memory_param="memory=800M  memory2=200M"
        CELLS=10317536
        ;;
neon)
        K_FILE="neon.refined.rev01.k"
        P_FILE="pfile.default"
        MODEL_VERS="rev01"
        CELLS=535000
        ;;
*)
        echo $0: unknown LSDYNA test $LSDYNA, valid choices are 3cars, car2car, odb10m, odb10m-10ms, odb10m-30ms, neon.
        usage 3
esac
echo "part7"

 
#CREATE CSV FILE TO HOLD RESULTS
csv_file="LSDYNA_"$dt".csv"
echo "uniqueid,application,model,application name,instance,hostname,nodes,ppn,cores,cells,metric,speedup,cellscore,scaling,network,notes,rundate,mpi_vers,mpi_name,mpi_version_number,ofed_vers,os_vers,kernel_vers,hpc_tools_vers,image_vers,command line,model_vers,region,environment,customer_name,poc" > $csv_file
echo "part8"

 
#SET INITIAL RUN VARIABLES
uid=`uuidgen | cut -c-8`
base_elapsed=0
base_elapsed_per_core=0
base_cores=0
echo "part9"

UNIQUEID="04-26-21-BM.HPC2.36-MarcinX9-lsdyna-12-avx2-3cars-intelmpi-2018-Run1"
 
#START THE RUN
for NODES in $NODES_ITER; do
 
    #calculate the number of cores for the run
    CORES=$(($NODES * $PPN))
    dynalog="dynalog."$MODELNAME"_"$dt"_nodes_"$NODES"_ppn_"$PPN"_cores_"$CORES".log"
    if [ "$MPINAME" == "intel" ]
    then
        MPI_CMD="mpirun -hostfile $MACHINEFILE -n $CORES -ppn $PPN $MPI_FLAGS"
    else
        MPI_CMD="mpirun -hostfile $MACHINEFILE -np $CORES $MPI_FLAGS"
    fi
    echo "part10"

 
    MPI_ARGS="$LSDYNA_EXE $memory_param i=$K_FILE p=$P_FILE $ENDTIME"
    echo $0: `date`: MPI_CMD=\"$MPI_CMD\"
    echo $0: `date`: MPI_ARGS=\"$MPI_ARGS\"
    echo $0: `date`: $MPI_CMD $MPI_ARGS
    $MPI_CMD $MPI_ARGS > $dynalog 2>&1
    echo "part11"

 
    __status=$?
    if [ $__status -ne 0 ]
    then
       echo $0: `date`: run $dt bench $LSDYNA_EXE vers with $ppn ppn, $nodes nodes, $cores cores, log to $dynalog: status $__status
       continue
    fi
    echo "part12"
    #
        #get results
    #
    termination=`grep "N o r m a l    t e r m i n a t i o n" $dynalog`
 
    if [ "$termination" == "" ]
        then
        echo $0: `date`: run $dt bench $LSDYNA_EXE vers with $PPN ppn, $NODES nodes, $CORES cores, log to $dynalog: error termination
        continue
    fi
    echo "part13"

 
    echo $0: `date`: finished run $dt bench $LSDYNA_EXE vers $VERS with $PPN ppn, $NODES nodes, $CORES cores, log to $dynalog
    echo "part14"
 
    ELAPSED_TIME=`fgrep --binary-files=text "Elapsed" $dynalog  | awk '{print $3;}'`
    echo "part15"
 
    if [ $base_elapsed -eq 0 ]
    then
        base_elapsed=$ELAPSED_TIME
        base_elapsed_per_core=`echo "scale=2 ; $ELAPSED_TIME * $CORES" | bc`
        base_cores=$CORES
    fi
    echo "part16"
 
    CELLSCORE=`echo "scale=2; $CELLS / $CORES" | bc`
    SPEEDUP=`echo "scale=2; $base_elapsed_per_core / $ELAPSED_TIME" | bc`
    ELAPSED_PER_CORE=`echo "scale=2 ; $ELAPSED_TIME * $CORES" | bc`
    SCALING=`echo "scale=2; $SPEEDUP / $CORES" | bc`
    echo "part17"

        echo $COMMENT
        echo $dt
        echo $MPI_VERSION
        echo $MPI_NAME
        echo $OFED_VERS
        echo $POC

        echo "part19"
 
    sleep 10
    echo "$UNIQUEID,LSDYNA,$MODELNAME,$VERS,$INSTANCE,$HOSTNAME,$NODES,$PPN,$CORES,$CELLS,$ELAPSED_TIME,$SPEEDUP,$CELLSCORE,$SCALING,$NETWORK,\"$COMMENT\",$dt,$MPI_VERSION,$MPI_NAME,$OFED_VERS,$OS_VERS,$KERNEL_VERS,$HPC_TOOLS_VERS,$IMAGE_VERS,\"$MPI_CMD $MPI_ARGS\",$MODEL_VERS,$REGION,$ENVIRONMENT,$CUSTOMER_NAME,$POC" >> $csv_file
 
done
echo "part20"


