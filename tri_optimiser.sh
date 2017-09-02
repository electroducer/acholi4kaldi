#!/bin/bash

# This script does a simple grid search to find the optimal triphone
# hyperparameters based on the dev set.



# Setup variables
[ -f cmd.sh ] && source ./cmd.sh \
  || echo "cmd.sh not found. Jobs may not execute properly."
. path.sh || { echo "Cannot source path.sh"; exit 1; }

LANGUAGES="acholi"


# Define the monophone model and parameters that will be used
# Where is the monophone model?
mono_model="mono_10000"
# What are the ranges of the parameters?
num_states=(1000 2000 3000 4000 5000)
num_gauss=(10000 20000 30000 40000 50000)

# Create the alignments from the mono model used
for L in $LANGUAGES; do
  (
    mkdir -p exp/$L/mono_ali_opt
    steps/align_si.sh --nj 10 --cmd "$train_cmd" \
	    data/$L/train data/$L/lang exp/$L/${mono_model} exp/$L/mono_ali_opt \
	    >& exp/$L/mono_ali_opt/align.log
  ) &
done
wait;

# Now search through the numbers of states and gaussians

for ns in ${num_states[@]}; do
  for ng in ${num_gauss[@]}; do
    for L in $LANGUAGES; do
      (
        mkdir -p exp/$L/tri1_${ns}_${ng}
        steps/train_deltas.sh --cmd "$train_cmd" \
    	    --cluster-thresh 100 $ns $ng data/$L/train data/$L/lang \
    	    exp/$L/mono_ali_opt exp/$L/tri1_${ns}_${ng} \
          >& exp/$L/tri1_${ns}_${ng}/train.log
      ) &
    done
  done
done
wait;

# Decode tri1
for ns in ${num_states[@]}; do
  for ng in ${num_gauss[@]}; do
    for L in $LANGUAGES; do
      for lm_suffix in tgpr_sri; do
        (
          graph_dir=exp/$L/tri1_${ns}_${ng}/graph_${lm_suffix}
          mkdir -p $graph_dir
          utils/mkgraph.sh data/$L/lang_test_${lm_suffix} \
            exp/$L/tri1_${ns}_${ng} $graph_dir

          steps/decode.sh --nj 5 --cmd "$decode_cmd" $graph_dir data/$L/dev \
    	      exp/$L/tri1_${ns}_${ng}/decode_dev_${lm_suffix}
        ) &
      done
    done
  done
done
wait;
