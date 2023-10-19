#!/bin/bash
#
#SBATCH -J protein-33-33
#SBATCH --partition=lab
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=2
#SBATCH --no-requeue
#SBATCH -t 100:00:00

jobname=protein-33-33

. ~/miniconda3/bin/activate atm
echo "Running on $(hostname)"

if [ ! -f ${jobname}_0.xml ]; then
   python /home/users/sheenam/AToM-OpenMM/rbfe_structprep.py ${jobname}_asyncre.cntl || exit 1
fi

echo "localhost,0:0,1,CUDA,,/tmp" > nodefile
python /home/users/sheenam/AToM-OpenMM/rbfe_explicit.py ${jobname}_asyncre.cntl
