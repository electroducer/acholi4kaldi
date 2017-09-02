#!/bin/bash

# This script does a grid search to find the best mono hyperparameters based on
# the dev set.



# Setup variables
[ -f cmd.sh ] && source ./cmd.sh \
  || echo "cmd.sh not found. Jobs may not execute properly."
. path.sh || { echo "Cannot source path.sh"; exit 1; }

LANGUAGES="acholi"
gauss=(1000 2000 3000 4000 5000 6000 7000 8000 9000 10000)
# Train a simple mono models
for n in ${gauss[@]}; do
  echo "Starting training for ${n} gaussians..."
  for L in $LANGUAGES; do
    mkdir -p exp/$L/mono_${n};
      steps/train_mono.sh --nj 10 --totgauss $n --cmd "$train_cmd" \
        data/$L/train data/$L/lang exp/$L/mono_${n} \
          >& exp/$L/mono_${n}/train.log &
  done
done
wait;

# Decode the mono model
for n in ${gauss[@]}; do
  echo "Starting decoding for ${n} gaussians..."
  for L in $LANGUAGES; do
    for lm_suffix in tgpr_sri; do
      (
        graph_dir=exp/$L/mono_${n}/graph_${lm_suffix}
        mkdir -p $graph_dir
        utils/mkgraph.sh data/$L/lang_test_${lm_suffix} exp/$L/mono_${n} \
          $graph_dir

        steps/decode.sh --nj 10 --cmd "$decode_cmd" $graph_dir data/$L/dev \
          exp/$L/mono_${n}/decode_dev_${lm_suffix}
      ) &
    done
  done
done
wait;
