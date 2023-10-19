#!/bin/bash
#
#SBATCH -J protein-CHEMBL3264999-CHEMBL3264999
#SBATCH --partition=farm
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:4
#SBATCH --cpus-per-task=8
#SBATCH --no-requeue
#SBATCH -t 30:00:00
jobname=protein-CHEMBL3264999-CHEMBL3264999

. ~/miniconda3/bin/activate atm
echo "Running on $(hostname)"

if [ ! -f ${jobname}_0.xml ]; then
   python /home/users/sheenam/AToM-OpenM/rbfe_structprep.py ${jobname}_asyncre.cntl || exit 1
fi

echo "localhost,0:0,1,CUDA,,/tmp" >> nodefile
echo "localhost,0:1,1,CUDA,,/tmp" >> nodefile
echo "localhost,0:2,1,CUDA,,/tmp" >> nodefile
echo "localhost,0:3,1,CUDA,,/tmp" >> nodefile


python /home/users/sheenam/AToM-OpenMM/rbfe_explicit.py ${jobname}_asyncre.cntl
