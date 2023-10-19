#!/bin/bash
#
#SBATCH -J protein-CHEMBL3402745-200-CHEMBL3402745-200
#SBATCH --partition=gpu-shared
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=2
#SBATCH --account=<account>
#SBATCH --no-requeue
#SBATCH -t 10:00:00

jobname=protein-CHEMBL3402745-200-CHEMBL3402745-200

. ~/miniconda3/bin/activate atm2
echo "Running on $(hostname)"

if [ ! -f ${jobname}_0.xml ]; then
   python /home/users/sheenam/src/AToM-OpenMM/rbfe_structprep.py ${jobname}_asyncre.cntl || exit 1
fi

echo "localhost,0:0,1,CUDA,,/tmp" > nodefile
python /home/users/sheenam/src/AToM-OpenMM/rbfe_explicit.py ${jobname}_asyncre.cntl
