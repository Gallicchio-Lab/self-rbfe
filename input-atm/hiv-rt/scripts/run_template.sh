#!/bin/bash
#
#SBATCH -J <JOBNAME>
#SBATCH --partition=lab
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=2
#SBATCH --no-requeue
#SBATCH -t 200:00:00

jobname=<JOBNAME>

. ~/miniconda3/bin/activate atm
echo "Running on $(hostname)"

if [ ! -f ${jobname}_0.xml ]; then
   python <ASYNCRE_DIR>/rbfe_structprep.py ${jobname}_asyncre.cntl || exit 1
fi

echo "localhost,0:0,1,CUDA,,/tmp" > nodefile
python <ASYNCRE_DIR>/rbfe_explicit.py ${jobname}_asyncre.cntl
