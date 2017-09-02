#!/bin/bash

# Copyright 2012-2015  Brno University of Technology (Author: Karel Vesely)
# Apache 2.0

# This example script trains DNN with <BlockSoftmax> output on top of FBANK features.
# The network is trained on RM and WSJ84 simultaneously.

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. ./path.sh ## Source the tools/utils (import the queue.pl)


max_num_jobs=48

# We'll need to make a copy of the eval data dir, so source and target go here
original_test_set=data/acholi/eval_trimmed
test_set=data-fbank-multilingual2-acholi-swahili/eval_trimmed

# Also the location of the original gmm
gmm=exp/acholi/tri3b_trimmed_lang

# As well as the location of mdnn
dir=exp/dnn4g-multilingual2-acholi-swahili-bn

stage=0
. utils/parse_options.sh || exit 1;

set -euxo pipefail

# Make the FBANK features,
[ ! -e $test_set ] && if [ $stage -le 0 ]; then
  # Make datadir copies,
  utils/copy_data_dir.sh $original_test_set $test_set
  rm $test_set/{cmvn,feats}.scp

  # Feature extraction,
  # Dev set,
  steps/make_fbank_pitch.sh --nj 10 --cmd "$train_cmd" \
    $test_set $test_set/log $test_set/data
  steps/compute_cmvn_stats.sh $test_set $test_set/log $test_set/data
  utils/fix_data_dir.sh $test_set
fi


# Prepare the merged targets,
# This just gets the number of pdfs used in the gmm
ali1_dim=$(hmm-info ${gmm}_ali/final.mdl | grep pdfs | awk '{ print $NF }')
# This gets us the output
output_dim=$(nnet-info $dir/final.nnet | grep BlockSoftmax \
  | awk '{print $NF}' | sed 's/,*$//')
#This provides how to get the pdfs from the gmm
ali1_pdf="ark:ali-to-pdf ${gmm}_ali/final.mdl 'ark:gunzip -c ${gmm}_ali/ali.*.gz |' ark:- |"
ali1_dir=${gmm}_ali

if [ $stage -le 2 ]; then


# START HERE-----------------------

  # Create files used in decdoing, missing due to --labels use,
  analyze-counts --binary=false "$ali1_pdf" $dir/ali_train_pdf.counts
  copy-transition-model --binary=false $ali1_dir/final.mdl $dir/final.mdl
  cp $ali1_dir/tree $dir/tree


  # KEY: Rebuild the NN
  # Rebuild network, <BlockSoftmax> is removed, and neurons from 1st block are selected,
  nnet-concat "nnet-copy --remove-last-components=1 $dir/final.nnet - |" \
    "echo '<Copy> <InputDim> $output_dim <OutputDim> $ali1_dim <BuildVector> 1:$ali1_dim </BuildVector>' | nnet-initialize - - |" \
    $dir/final.nnet.lang1



  # Decode (reuse HCLG graph),
  num_test_spk=$(cat $test_set/spk2utt | wc -l)
  [ $num_test_spk -lt $max_num_jobs ] \
    && dec_nj=$num_test_spk || dec_nj=$max_num_jobs
  steps/nnet/decode.sh --nj $dec_nj --cmd "$decode_cmd" --config conf/decode_dnn.conf --acwt 0.1 \
    --nnet $dir/final.nnet.lang1 \
    $gmm/graph_tgpr_sri $test_set $dir/decode
fi

exit 0

# TODO,
# make nnet-copy support block selection,
# - either by replacing <BlockSoftmax> by <Softmax> and shrinking <AffineTransform>,
# - or by appending <Copy> transform,
#
# Will it be compatible with other scripts/tools which assume <Softmax> at the end?
# Or is it better to do everything visually in master script as now?...
# Hmmm, need to think about it...

# Train baseline system with <Softmax>,
if [ $stage -le 3 ]; then
  dir=exp/dnn4e-fbank_baseline
  $cuda_cmd $dir/log/train_nnet.log \
    steps/nnet/train.sh \
      --cmvn-opts "--norm-means=true --norm-vars=true" \
      --delta-opts "--delta-order=2" --splice 5 \
      --learn-rate 0.008 \
      ${train}_tr90 ${train}_cv10 data/lang ${gmm}_ali ${gmm}_ali $dir
  # Decode (reuse HCLG graph)
  steps/nnet/decode.sh --nj 20 --cmd "$decode_cmd" --config conf/decode_dnn.config --acwt 0.1 \
    $gmm/graph $dev $dir/decode
  steps/nnet/decode.sh --nj 20 --cmd "$decode_cmd" --config conf/decode_dnn.config --acwt 0.1 \
    $gmm/graph_ug $dev $dir/decode_ug
fi

echo Success
exit 0

# Getting results [see RESULTS file]
# for x in exp/*/decode*; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done
