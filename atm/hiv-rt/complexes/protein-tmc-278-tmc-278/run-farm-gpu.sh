#!/bin/bash
#
# Example of a 4-GPU job on the farm that rsync's the job directory to scratch.
# Runs the job from scratch and rsync's back the results when done.
#
#
#SBATCH -J protein-tmc-278-tmc-278
#SBATCH --partition=farm
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:4
#SBATCH --cpus-per-task=8
#SBATCH --no-requeue
#SBATCH -t 60:00:00

echo "Running on $(hostname)"
jobname=protein-tmc-278-tmc-278
. ~/miniconda3/bin/activate atm

srcdir=/nfs/sheenam-d/self-rbfe/cdk8/complexes
scratchdir=/scratch/${SLURM_JOB_ID}
mkdir -p ${scratchdir}

rsync --exclude='slurm*.out' -avz ${srcdir}/${jobname} ${scratchdir}/ || exit 1

cd ${scratchdir}/${jobname} || exit 1

if [ ! -f ${jobname}_0.xml ]; then
   python /home/users/sheenam/AToM-OpenMM/rbfe_structprep.py ${jobname}_asyncre.cntl || exit 1
fi

echo "localhost,0:0,1,CUDA,,/tmp" >>  nodefile
echo "localhost,0:1,1,CUDA,,/tmp" >> nodefile
echo "localhost,0:2,1,CUDA,,/tmp" >> nodefile
echo "localhost,0:3,1,CUDA,,/tmp" >> nodefile
python /home/users/sheenam/AToM-OpenMM/rbfe_explicit.py ${jobname}_asyncre.cntl || exit 1

cd ..
rsync --exclude='slurm*.out' -avz ${jobname}  ${srcdir}/ || exit 1
#rm -r ${scratchdir}
