#!/bin/bash -l
#SBATCH --job-name=gan
#SBATCH --time=0-48:0:0
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --nodes=1
#SBATCH --mem=8G
#SBATCH --mail-type=end

# Check if running on marcc
if [[ -z ${SLURM_JOB_ID+x} ]]; then marcc=false; else marcc=true; fi

if $marcc; then
  echo "Running $@ on $SLURMD_NODENAME ..."
  module load tensorflow/cuda-8.0/r1.3
else
  echo "Not running on Marcc"
fi

OPTS=$(getopt -o '' --long lr:,dr:,opt:,noisedim:,loss:,wass,no_wass,noise,retrain,encoder,gan_encoder,load_model,suffix:,multi,husky,jigsaws -n ctp_gan -- "$@")

[[ $? != 0 ]] && echo "Failed parsing options." && exit 1

train_image_encoder=false
train_gan_image_encoder=false
lr=0.001
dropout=0.1
optimizer=adam
noise_dim=1
loss=mae
wass=false
use_noise=false
retrain=false
load_model=false
dataset=''
features=''
suffix=''

echo "$OPTS"
eval set -- "$OPTS"

while true; do
  case "$1" in
    --lr) lr="$2"; shift 2 ;;
    --dr) dropout="$2"; shift 2 ;;
    --opt) optimizer="$2"; shift 2 ;;
    --noisedim) noise_dim="$2"; shift 2 ;;
    --noise) use_noise=true; shift ;;
    --loss) loss="$2"; shift 2 ;;
    --wass) wass=true; shift ;;
    --no_wass) wass=false; shift ;;
    --retrain) retrain=true; shift ;;
    --encoder) train_image_encoder=true; shift ;;
    --gan_encoder) train_gan_image_encoder=true; shift ;;
    --load_model) load_model=true; shift ;;
    --multi) dataset=ctp_dec; features=multi; shift ;;
    --husky) dataset=husky_data; features=husky; shift ;;
    --jigsaws) dataset=suturing_data2; features=jigsaws; shift ;;
    --suffix) suffix="$2"; shift 2 ;;
    --) shift; break ;;
    *) echo "Internal error!" ; exit 1 ;;
  esac
done

# positional arguments
[[ ! -z "$1" ]] && dataset="$1"
[[ ! -z "$2" ]] && features="$2"

[[ $dataset == '' ]] && echo 'Dataset is mandatory!' && exit 1
[[ $features == '' ]] && echo 'Features are mandatory!' && exit 1

if $wass; then wass_dir=wass; else wass_dir=nowass; fi
if $use_noise; then noise_dir=noise; else noise_dir=nonoise; fi
if $retrain; then retrain_dir=retrain; else retrain_dir=noretrain; fi

MODELDIR="$HOME/.costar/${dataset}_${lr}_${optimizer}_${dropout}_${noise_dim}_${loss}_${wass_dir}_${noise_dir}_${retrain_dir}${suffix}"

[[ ! -d $MODELDIR ]] && mkdir -p $MODELDIR

if $marcc; then
  touch $MODELDIR/$SLURM_JOB_ID
  # Handle different Marcc layouts
  data_dir=$HOME/work/$dataset
  [[ ! -d $data_dir ]] && data_dir=$HOME/work/dev_yb/$dataset
else
  data_dir=$dataset
fi

if [[ $features == husky ]]; then data_suffix=npz; else data_suffix=h5f; fi
data_dir=${data_dir}.${data_suffix}

if $wass; then wass_cmd='--wasserstein'; else wass_cmd=''; fi
if $use_noise; then use_noise_cmd='--use_noise'; else use_noise_cmd=''; fi
if $retrain; then retrain_cmd='--retrain'; else retrain_cmd=''; fi
if $load_model; then load_cmd='--load_model'; else load_cmd=''; fi

if $marcc; then
  cmd_prefix="$HOME/costar_plan/costar_models/scripts/"
else
  cmd_prefix='rosrun costar_models '
fi

if $train_image_encoder; then
  echo "Training discriminator"
  ${cmd_prefix}ctp_model_tool \
    --features $features \
    -e 100 \
    --model discriminator \
    --data_file $data_dir \
    --lr $lr \
    --dropout_rate $dropout \
    --model_directory $MODELDIR/ \
    --optimizer $optimizer \
    --steps_per_epoch 300 \
    --noise_dim $noise_dim \
    --loss $loss \
    --batch_size 64 \
    $load_cmd

  echo "Training non-gan image encoder"
  ${cmd_prefix}ctp_model_tool \
    --features $features \
    -e 100 \
    --model pretrain_image_encoder \
    --data_file $data_dir \
    --lr $lr \
    --dropout_rate $dropout \
    --model_directory $MODELDIR/ \
    --optimizer $optimizer \
    --steps_per_epoch 300 \
    --noise_dim $noise_dim \
    --loss $loss \
    --batch_size 64 \
    $load_cmd
fi
if $train_gan_image_encoder; then
  echo "Training encoder gan"
  ${cmd_prefix}ctp_model_tool \
    --features $features \
    -e 300 \
    --model pretrain_image_gan \
    --data_file $data_dir \
    --lr $lr \
    --dropout_rate $dropout \
    --model_directory $MODELDIR/ \
    --optimizer $optimizer \
    --steps_per_epoch 100 \
    --noise_dim $noise_dim \
    --loss $loss \
    --gan_method gan \
    --batch_size 64 \
    $wass_cmd \
    $load_cmd
fi

echo "Training conditional gan"
  ${cmd_prefix}ctp_model_tool \
  --features $features \
  -e 100 \
  --model conditional_image_gan \
  --data_file $data_dir \
  --lr $lr \
  --dropout_rate $dropout \
  --model_directory $MODELDIR/ \
  --optimizer $optimizer \
  --steps_per_epoch 100 \
  --noise_dim $noise_dim \
  --loss $loss \
  --gan_method gan \
  --batch_size 64 \
  $wass_cmd \
  $use_noise_cmd \
  $load_cmd

