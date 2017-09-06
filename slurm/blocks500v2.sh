#!/bin/bash -l
#SBATCH --job-name=b500v2
#SBATCH --time=0-24:0:0
#SBATCH --nodes=1
#SBATCH -p unlimited
#SBATCH -g 1
#SBATCH --cpus-per-task=6
#SBATCH --mail-type=end
#SBATCH --mail-user=cpaxton3@jhu.edu

set -e
set -x
set -u

echo
echo "Running $@ on $SLURMD_NODENAME ..."
echo

$HOME/costar_plan/costar_models/scripts/ctp_model_tool --features multi -e 100 --model predictor --data_file $HOME/work/ctp_blocks_500b.npz --lr 0.001  --model_directory $HOME/.costar/models4/ --optimizer nadam
