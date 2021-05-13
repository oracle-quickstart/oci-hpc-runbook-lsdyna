#!/bin/bash

#PPN="32 34 36"
#PPN="32 36"
#PPN="32"
PPN="36"
NODES="8"
#NODES="8"
#VERS="R9.2_intel_sse2"
#VERS="R9.2_intel_avx2"
VERS="R9.2_platform_avx2"
#VERS="R9.2_platform_avx512"
#VERS="R9.2_platform_sse2"

rundate=`date +%Y%m%d_%H%M%S`

source /etc/opt/oci-hpc/bashrc/.bashrc
source /mnt/beegfs/LSDYNA/license_server.sh
case $VERS in
R9.2_intel_avx2)
	source /etc/opt/oci-hpc/bashrc/.bashrc_intelmpi
	MPI_IMPL="intel_mpi"
        LSDYNA_EXE_SP=/mnt/beegfs/LSDYNA/lsdyna/ls-dyna_mpp_s_r9_2_119543_x64_redhat54_ifort131_avx2_intelmpi-413
        LSDYNA_EXE_DP=/mnt/beegfs/LSDYNA/lsdyna/ls-dyna_mpp_d_r9_2_119543_x64_redhat54_ifort131_avx2_intelmpi-413
        ;;
R9.2_intel_sse2)
	source /etc/opt/oci-hpc/bashrc/.bashrc_intelmpi
	MPI_IMPL="intel_mpi"
        LSDYNA_EXE_SP=/mnt/beegfs/LSDYNA/lsdyna/ls-dyna_mpp_s_r9_2_119543_x64_redhat54_ifort131_sse2_intelmpi-413
        LSDYNA_EXE_DP=/mnt/beegfs/LSDYNA/lsdyna/ls-dyna_mpp_d_r9_2_119543_x64_redhat54_ifort131_sse2_intelmpi-413
        ;;
R9.2_platform_avx2)
	source /etc/opt/oci-hpc/bashrc/.bashrc_platformmpi
	MPI_IMPL="platform_mpi"
        LSDYNA_EXE_SP=/mnt/beegfs/LSDYNA/lsdyna/ls-dyna_mpp_s_r9_2_119543_x64_redhat54_ifort131_avx2_platformmpi
        LSDYNA_EXE_DP=/mnt/beegfs/LSDYNA/lsdyna/ls-dyna_mpp_d_r9_2_119543_x64_redhat54_ifort131_avx2_platformmpi
        ;;
R9.2_platform_avx512)
	source /etc/opt/oci-hpc/bashrc/.bashrc_platformmpi
	MPI_IMPL="platform_mpi"
        LSDYNA_EXE_SP=/mnt/beegfs/LSDYNA/lsdyna/ls-dyna_mpp_s_r9_2_119543_x64_redhat54_ifort160_avx512_platformmpi
        LSDYNA_EXE_DP=/mnt/beegfs/LSDYNA/lsdyna/ls-dyna_mpp_d_r9_2_119543_x64_redhat54_ifort160_avx512_platformmpi
        ;;
R9.2_platform_sse2)
	source /etc/opt/oci-hpc/bashrc/.bashrc_platformmpi
	MPI_IMPL="platform_mpi"
        LSDYNA_EXE_SP=/mnt/beegfs/LSDYNA/lsdyna/ls-dyna_mpp_s_r9_2_119543_x64_redhat54_ifort131_sse2_platformmpi
        LSDYNA_EXE_DP=/mnt/beegfs/LSDYNA/lsdyna/ls-dyna_mpp_d_r9_2_119543_x64_redhat54_ifort131_sse2_platformmpi
        ;;
*)
	echo $0: unknown vers $VERS
	exit 1
	;;
esac

instance=BM.HPC2.36
hostname=`hostname`
num_nodes=`wc -l /etc/opt/oci-hpc/hostfile | awk ' { print $1; }'`
base_elapsed=0
base_elapsed_per_core=0
base_cores=0
comment=$*

csv_file="LSDYNA_"$rundate".log"
echo "test,model,vers,rundate,nodes,ppn,cores,elapsed,speedup,scaling,comment" > $csv_file

for ppn in $PPN
do
	for nodes in $NODES
	do
		if [ $nodes -gt $num_nodes ]
		then
			break
		fi
		cores=$(($nodes * $ppn))
		#
		#
		rm -f ./hostfile_rank ./hostfile ./hostfile1
		dynalog="dynalog."$rundate"_nodes_"$nodes"_ppn_"$ppn"_cores_"$cores"_"$VERS".log"
		generate_hostfile_rank /etc/opt/oci-hpc/hostfile $ppn $nodes
		echo $0: `date`: run $rundate with $ppn ppn, $nodes nodes, $cores cores, log to $dynalog
		case $MPI_IMPL in
		"intel_mpi")
			export I_MPI_ADJUST_ALLREDUCE=5
			export I_MPI_ADJUST_BCAST=1
			MPI_CMD="mpirun -hostfile ./hostfile_rank \
				-n $cores -ppn $ppn \
				$MPI_INTERFACE_OPTIONS \
				-genv I_MPI_DAPL_UD=0 \
				-genv I_MPI_ADJUST_ALLREDUCE $I_MPI_ADJUST_ALLREDUCE \
				-genv I_MPI_ADJUST_BCAST $I_MPI_ADJUST_BCAST \
				$MPI_DEBUG_OPTIONS \
				$MPI_CPU_BINDING_OPTIONS \
				"
			;;
		"platform_mpi")
			MPI_CMD="mpirun -d -v -prot -intra=shm \
				-e MPI_FLAGS=$MPI_FLAGS \
				-np $cores \
				-cpu_bind=$MPI_MAP_CPU_BIND \
				-hostfile ./hostfile_rank \
				-e MPI_HASIC_UDAPL=ofa-v2-cma-roe-enp94s0f0 -UDAPL \
				"
			;;
		*)
			echo $0: unsupported MPI_IMPL=$MPI_IMPL
			exit 3
			;;
		esac
                MPI_ARGS_SP="$LSDYNA_EXE_SP i=example.key \
                        memory=1000m memory2=160m p=pfile_run ncycle=100000"
                MPI_ARGS_DP="$LSDYNA_EXE_DP \
			i=example.key \
          		memory=4000m memory2=120m \
                	p=pfile_decomp ncycle=2"
			
		# For decomposition of the model
                # MPI_ARGS="$MPI_ARGS_DP"
		
		# For running the model
                MPI_ARGS="$MPI_ARGS_SP"
		
		echo $0: `date`: MPI_CMD=\"$MPI_CMD\"
		echo $0: `date`: MPI_ARGS=\"$MPI_ARGS\"
		echo $0: `date`: $MPI_CMD $MPI_ARGS
		echo $0: `date`: $dynalog
		$MPI_CMD $MPI_ARGS > $dynalog 2>&1
		__status=$?
		if [ $__status -ne 0 ]
		then
			echo $0: `date`: run $rundate with $ppn ppn, $nodes nodes, $cores cores, log to $dynalog: status $__status
			continue
		fi
		rm -f ./hostfile_rank ./hostfile ./hostfile1 d3hsp
		#
		# remove all output and temporary files
		#
		run_on_cluster_nodes.sh "find /mnt/localdisk/tmp -type f -print -exec rm {} \;"
		rm one_global_dir/*
		#
		# get results
		#
		termination=`grep "N o r m a l    t e r m i n a t i o n" $dynalog`
		if [ "$termination" == "" ]
		then
			echo $0: `date`: run $rundate with $ppn ppn, $nodes nodes, $cores cores, log to $dynalog: error termination
			continue
		fi

		echo $0: `date`: finished run $rundate with $ppn ppn, $nodes nodes, $cores cores, log to $dynalog

		elapsed_time=`fgrep --binary-files=text "Elapsed" $dynalog  | awk '{print $3;}'`
		if [ $base_elapsed -eq 0 ]
		then
			base_elapsed=$elapsed_time
			base_elapsed_per_core=`echo "scale=2 ; $elapsed_time * $cores" | bc`
			base_cores=$cores
		fi

		speedup=`echo "scale=2; $base_elapsed_per_core / $elapsed_time" | bc`
		elapsed_per_core=`echo "scale=2 ; $elapsed_time * $cores" | bc`
		scaling=`echo "scale=2; $speedup / $cores" | bc`

		echo elapsed_time=$elapsed_time
		echo base_elapsed=$base_elapsed
		echo base_elapsed_per_core=$base_elapsed_per_core
		echo base_cores=$base_cores
		echo speedup=$speedup
		echo elapsed_per_core=$elapsed_per_core
		echo scaling=$scaling

		echo "LSDYNA,sol-cpf-dm,$VERS,$rundate,$nodes,$ppn,$cores,$elapsed_time,$speedup,$scaling,\"$comment\"" >> $csv_file

	done
done
