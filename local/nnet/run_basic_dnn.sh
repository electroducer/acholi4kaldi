#!/bin/bash

# This script is designed to be run after run.sh

# Based mainly on the nnet runner from wsj

# This example script trains a DNN on top of fMLLR features.
# The training is done in 3 stages,
#
# 1) RBM pre-training:
#    in this unsupervised stage we train stack of RBMs,
#    a good starting point for frame cross-entropy trainig.
# 2) frame cross-entropy training:
#    the objective is to classify frames to correct pdfs.
# 3) sequence-training optimizing sMBR:
#    the objective is to emphasize state-sequences with better
#    frame accuracy w.r.t. reference alignment.

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. ./path.sh ## Source the tools/utils (import the queue.pl)

# Config:
L=acholi
exp="best"
data_fmllr=data/$L/fmllr-tri3b
stage=0 # resume training with --stage=N
train_set="train_dev"
test_set="eval"
train_lang="lang"
max_num_jobs=48
lang_test="lang_test,lang_small_new_test"
lm_suffix="tg,tgpr,tg_sri,tgpr_sri"
# End of config.
. utils/parse_options.sh || exit 1;

gmmdir=exp/$L/tri3b_$exp

lang_test_arr=($(echo $lang_test | tr ',:' ' '))
lm_suffix_arr=($(echo $lm_suffix | tr ',:' ' '))

# Calculate the number of jobs for the eval set
num_test_spk=$(cat data/$L/$test_set/spk2utt | wc -l)
[ $num_test_spk -lt $max_num_jobs ] \
  && dec_nj=$num_test_spk || dec_nj=$max_num_jobs

if [ $stage -le 0 ]; then
  # Store fMLLR features, so we can train on them easily,
  # For the eval set
  dir=$data_fmllr/$test_set
  steps/nnet/make_fmllr_feats.sh --nj $dec_nj --cmd "$train_cmd" \
     --transform-dir $gmmdir/decode_${test_set}_tgpr_sri \
     $dir data/$L/$test_set $gmmdir $dir/log $dir/data || exit 1
  # For the training set
  # First do another alignment
  steps/align_fmllr.sh --nj 10 --cmd "$train_cmd" \
  data/$L/$train_set data/$L/$train_lang \
   $gmmdir ${gmmdir}_ali || exit 1;
  dir=$data_fmllr/$train_set
  steps/nnet/make_fmllr_feats.sh --nj 10 --cmd "$train_cmd" \
     --transform-dir ${gmmdir}_ali \
     $dir data/$L/$train_set $gmmdir $dir/log $dir/data || exit 1
  # split the data : 90% train 10% cross-validation (held-out)
  utils/subset_data_dir_tr_cv.sh $dir ${dir}_tr90 ${dir}_cv10 || exit 1
fi

if [ $stage -le 1 ]; then
  # Pre-train DBN, i.e. a stack of RBMs
  dir=exp/$L/dnn5b_pretrain-dbn_$exp
  (tail --pid=$$ -F $dir/log/pretrain_dbn.log 2>/dev/null)& # forward log
  $cuda_cmd $dir/log/pretrain_dbn.log \
    steps/nnet/pretrain_dbn.sh --rbm-iter 3 $data_fmllr/$train_set $dir || exit 1;
fi

if [ $stage -le 2 ]; then
  # Train the DNN optimizing per-frame cross-entropy.
  dir=exp/$L/dnn5b_pretrain-dbn_dnn_$exp
  ali=${gmmdir}_ali
  feature_transform=exp/$L/dnn5b_pretrain-dbn_${exp}/final.feature_transform
  dbn=exp/$L/dnn5b_pretrain-dbn_${exp}/6.dbn
  (tail --pid=$$ -F $dir/log/train_nnet.log 2>/dev/null)& # forward log
  # Train
  $cuda_cmd $dir/log/train_nnet.log \
    steps/nnet/train.sh --feature-transform $feature_transform --dbn $dbn \
      --hid-layers 0 --learn-rate 0.008 \
      $data_fmllr/${train_set}_tr90 $data_fmllr/${train_set}_cv10 \
      data/$L/$train_lang $ali $ali $dir || exit 1;
  # Decode (reuse HCLG graph)
  for lt in ${lang_test_arr[@]}; do
    for ls in ${lm_suffix_arr[@]}; do
      steps/nnet/decode.sh --nj $dec_nj --cmd "$decode_cmd" \
        --config conf/decode_dnn.conf --acwt 0.1 \
        $gmmdir/graph_${lt}_${ls} $data_fmllr/${test_set} \
        $dir/decode_${test_set}_${lt}_${ls} &
    done
  done
  wait;
fi

echo $0 success.

# Getting results [see RESULTS file]
# for x in exp/*/decode*; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done
