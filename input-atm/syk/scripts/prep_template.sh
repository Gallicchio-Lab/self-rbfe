#!/bin/bash
#
#SBATCH -J <JOBNAME>
#SBATCH --partition=gpu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gpus=1
#SBATCH --account=TG-MCB150001
#SBATCH --no-requeue
#SBATCH -t 90:00:00


. ~/miniconda3/bin/activate atm
for pair in <LIGPAIRS> ; do
    jobname=<RECEPTOR>-$pair
    echo "Prepping $jobname"
    ( cd ${jobname} &&  python <ASYNCRE_DIR>/rbfe_structprep.py ${jobname}_asyncre.cntl )  || exit 1
done
