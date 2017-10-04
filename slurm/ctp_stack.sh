#!/bin/bash -l
#SBATCH --job-name=stack1
#SBATCH --time=0-48:0:0
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --nodes=1
#SBATCH --mem=8G
#SBATCH --mail-type=end
#SBATCH --mail-user=cpaxton3@jhu.edu

set -e
set -x
set -u

echo
echo "Running $@ on $SLURMD_NODENAME ..."
echo

module load tensorflow/cuda-8.0/r1.3 

# models_stack: no dropouts, 2 tforms
# models_stack2: all dropouts, including on tforms
# models_stack3: no dropouts on tforms?
# models_stack4: smaller hidden arm+gripper layer and smaller hidden layers
# models_stack5: (8,8,64) and ph output
# models_stack6: (8,8,64) and noise

$HOME/costar_plan/costar_models/scripts/ctp_model_tool \
	--features multi \
	-e 250 \
	--model predictor \
	--data_file $HOME/work/ctp_value.npz \
	--lr 0.001 \
	--model_directory $HOME/.costar/models_stack6/ \
	--optimizer adam \
  --upsampling conv_transpose \
  --hypothesis_dropout false \
  --dropout_rate 0.5 \
  --use_noise true \
  --noise_dim 32 \
	--batch_size 64

