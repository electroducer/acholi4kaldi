#!/bin/bash

# This script does a grid search to find the best mono hyperparameters based on
# the dev set.



# Setup variables
[ -f cmd.sh ] && source ./cmd.sh \
  || echo "cmd.sh not found. Jobs may not execute properly."
. path.sh || { echo "Cannot source path.sh"; exit 1; }

max_num_jobs=48
num_test_spk=$(cat data/$L/dev/spk2utt | wc -l)
[ $num_test_spk -lt $max_num_jobs ] \
  && dec_nj=$num_test_spk || dec_nj=$max_num_jobs

LANGUAGES="acholi"
sil_boost=(0 0.2 0.4 0.6 0.8 1.2 1.4 1.6 1.8 2)
# Train a simple mono models
for n in ${sil_boost[@]}; do
  echo "Starting training for silence boost of ${n}..."
  for L in $LANGUAGES; do
    mkdir -p exp/$L/mono_${n};
      steps/train_mono.sh --nj 10 --boost-silence $n --cmd "$train_cmd" \
        data/$L/train data/$L/lang exp/$L/mono_${n} \
          | tee exp/$L/mono_${n}/train.log
  done
done
wait;

# Decode the mono model
for n in ${sil_boost[@]}; do
  echo "Starting decoding for silence boost of ${n}..."
  for L in $LANGUAGES; do
    for lm_suffix in tgpr_sri; do
      graph_dir=exp/$L/mono_${n}/graph_${lm_suffix}
      mkdir -p $graph_dir
      $decode_cmd JOB=1 $graph_dir/mkgraph.log \
        utils/mkgraph.sh data/$L/lang_test_${lm_suffix} exp/$L/mono_${n} \
          $graph_dir
    done
    for lm_suffix in tgpr_sri; do
      steps/decode.sh --nj 10 --cmd "$decode_cmd" $graph_dir data/$L/dev \
        exp/$L/mono_${n}/decode_dev_${lm_suffix}
    done
  done
done
wait;
