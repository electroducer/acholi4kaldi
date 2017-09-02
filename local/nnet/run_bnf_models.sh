#!/bin/bash

# This script extracts the bottleneck features and then runs
# a gmm model and a dnn model using the features


. ./cmd.sh

. ./path.sh

max_num_jobs=48

# Original training and test sets
train_set=data-fbank-multilingual2-acholi-swahili/acholi_train_dev_trimmed
test_set=data-fbank-multilingual2-acholi-swahili/eval_trimmed

# Get the original language model
lang=data/acholi/lang
# Set the test extensions as a space-separated list
lang_test="data/acholi/lang_test,data/acholi/lang_small_new_test"
lm_suffix="tg,tgpr,tg_sri,tgpr_sri"
ali=exp/acholi/tri3b_trimmed_lang_ali

# Bottleneck NN
nnet_dir=exp/dnn4g-multilingual2-acholi-swahili-bn
# Path to new dnn
dnn_dir=exp/acholi/dnn_multilingual2_bnf_pretrain-dbngrapheme
# New training and test data directories
train_bn=data-bn/acholi/train_dev_trimmed
test_bn=data-bn/acholi/eval_trimmed
train_bn_fmllr=data-bn-fmllr/acholi/train_dev_trimmed
test_bn_fmllr=data-bn-fmllr/acholi/eval_trimmed

run_local=false


stage=0
. utils/parse_options.sh || exit 1;

lang_test_arr=($(echo $lang_test | tr ',:' ' '))
lm_suffix_arr=($(echo $lm_suffix | tr ',:' ' '))

if [ "$run_local" = true ]; then
  echo "Running locally"
  . ./cmd_local.sh
fi

# Step 0: make bottleneck features
if [ $stage -le 0 ]; then
  mkdir -p $train_bn/{data,log}
  mkdir -p $test_bn/{data,log}
  mkdir -p $train_bn_fmllr/{data,log}
  mkdir -p $test_bn_fmllr/{data,log}

  # First, extract the features for the training data
  # This will remove the last for components by default, exposing the
  # bottleneck layer as output
  steps/nnet/make_bn_feats.sh --nj $max_num_jobs --cmd "$train_cmd" \
    $train_bn $train_set $nnet_dir $train_bn/log $train_bn/data
  steps/compute_cmvn_stats.sh $train_bn $train_bn/log $train_bn/data

  # Then for the test data
  num_test_spk=$(cat $test_set/spk2utt | wc -l)
  [ $num_test_spk -lt $max_num_jobs ] \
    && dec_nj=$num_test_spk || dec_nj=$max_num_jobs
  steps/nnet/make_bn_feats.sh --nj $dec_nj --cmd "$train_cmd" \
    $test_bn $test_set $nnet_dir $test_bn/log $test_bn/data
  steps/compute_cmvn_stats.sh $test_bn $test_bn/log $test_bn/data
fi

# Step 1: train a bottleneck gmm
graph_dir=$nnet_dir/bn-gmm/graph_tgpr_sri
num_test_spk=$(cat $test_bn/spk2utt | wc -l)
[ $num_test_spk -lt $max_num_jobs ] \
  && dec_nj=$num_test_spk || dec_nj=$max_num_jobs
if [ $stage -le 1 ]; then
  mkdir -p $nnet_dir/bn-gmm
  steps/train_deltas.sh --power 0.5 --boost-silence 1.5 --cmd "$train_cmd" \
    --delta-opts "--delta-order=0" \
    --cmvn-opts "--norm-means=false --norm-vars=false" \
    --beam 20 --retry-beam 80 \
    5000 80000 $train_bn $lang $ali $nnet_dir/bn-gmm \
    | tee $nnet_dir/bn-gmm/train.log

  # Decode it
  for lt in ${lang_test_arr[@]}; do
    for ls in ${lm_suffix_arr[@]}; do
      graph_dir=$nnet_dir/bn-gmm/graph_$(basename $lt)_$ls
      mkdir -p $graph_dir
      utils/mkgraph.sh ${lt}_${ls} $nnet_dir/bn-gmm $graph_dir
      steps/decode.sh --nj $dec_nj --cmd "$decode_cmd" \
        --acwt 0.05 --beam 15.0 --lattice-beam 8.0 \
        $graph_dir $test_bn \
        $nnet_dir/bn-gmm/decode_$(basename $test_bn)_$(basename $lt)_${ls} &
    done
  done
fi

# Step 2: train a bottleneck SAT gmm and make fmllr features
dir=$nnet_dir/fmllr-gmm
ali=$nnet_dir/bn-gmm_ali
graph_dir=$dir/graph_tgpr_sri
if [ $stage -le 2 ]; then
  steps/align_fmllr.sh --boost-silence 1.5 --nj $max_num_jobs --cmd "$train_cmd" \
    --beam 20 --retry-beam 80 \
    $train_bn $lang $nnet_dir/bn-gmm $nnet_dir/bn-gmm_ali

  steps/train_sat.sh --power 0.5 --boost-silence 1.5 --cmd "$train_cmd" \
    --beam 20 --retry-beam 80 \
    5000 80000 $train_bn $lang $ali $dir

  # Now run decoding
  for lt in ${lang_test_arr[@]}; do
    for ls in ${lm_suffix_arr[@]}; do
      graph_dir=$dir/graph_$(basename $lt)_$ls
      mkdir -p $graph_dir
      utils/mkgraph.sh ${lt}_${ls} $dir $graph_dir
      steps/decode_fmllr.sh --nj $dec_nj --cmd "$decode_cmd" \
        --acwt 0.05 --beam 15.0 --lattice-beam 8.0 \
        $graph_dir $test_bn \
        $dir/decode_$(basename $test_bn)_$(basename $lt)_${ls} &
    done
  done
  wait;

  steps/align_fmllr.sh --boost-silence 1.5 --nj $max_num_jobs --cmd "$train_cmd" \
    --beam 20 --retry-beam 80 \
    $train_bn $lang $dir ${dir}_ali


  # Next, save the fMLLR feats
  steps/nnet/make_fmllr_feats.sh --nj $dec_nj --cmd "$train_cmd" \
    --transform-dir $dir/decode_$(basename $test_bn)_$(basename $lt)_${ls} \
    $test_bn_fmllr $test_bn $dir $test_bn_fmllr/log $test_bn_fmllr/data

  steps/nnet/make_fmllr_feats.sh --nj $max_num_jobs --cmd "$train_cmd" \
    --transform-dir ${dir}_ali \
    $train_bn_fmllr $train_bn $dir $train_bn_fmllr/log $train_bn_fmllr/data

  utils/subset_data_dir_tr_cv.sh --cv-spk-percent 10 $train_bn_fmllr \
    ${train_bn_fmllr}_tr90 ${train_bn_fmllr}_cv10
fi

# Step 3: pretrain a dnn
fmllrdir=$dir
dir=$dnn_dir; mkdir -p $dir
if [ $stage -le 3 ]; then
  # Be sure to splice in 13 frames
  echo "<Splice> <InputDim> 40 <OutputDim> 520 \
  <BuildVector> -10 -5:1:5 10 </BuildVector>" >$dir/proto.main
  # Pretrain
  (tail --pid=$$ -F $dir/log/pretrain_dbn.log 2>/dev/null)&
  $cuda_cmd $dir/log/pretrain_dbn.log \
    steps/nnet/pretrain_dbn.sh --feature-transform-proto $dir/proto.main \
    $train_bn_fmllr $dir
fi
# Step 4: fully train the dnn
dbn_dir=$dir
dir=${dir}_dnn; mkdir -p $dir
ali=$nnet_dir/fmllr-gmm_ali
if [ $stage -le 4 ]; then
  feature_transform=$dbn_dir/final.feature_transform
  dbn=$dbn_dir/6.dbn

  (tail --pid=$$ -F $dir/log/train_nnet.log 2>/dev/null)& # forward log
  $cuda_cmd $dir/log/train_nnet.log \
    steps/nnet/train.sh --feature-transform $feature_transform \
    --dbn $dbn --hid-layers 0 --learn-rate 0.008 \
    ${train_bn_fmllr}_tr90 ${train_bn_fmllr}_cv10 $lang $ali $ali $dir

  for lt in ${lang_test_arr[@]}; do
    for ls in ${lm_suffix_arr[@]}; do
      graph_dir=$fmllrdir/graph_$(basename $lt)_$ls
      steps/nnet/decode.sh --nj $dec_nj --cmd "$decode_cmd" \
        --config conf/decode_dnn.conf --acwt 0.10 \
        $graph_dir $test_bn_fmllr \
        $dir/decode_$(basename $test_bn_fmllr)_$(basename $lt)_${ls} &
    done
  done
fi

# Finally optimize sMBR criterion, we do Stochastic-GD with per-utterance updates,
srcdir=$dir
dir=${dir}_smbr
acwt=0.1
# Step 5: prepare for sMBR training
if [ $stage -le 5 ]; then
  # Generate lattices and alignments
  steps/nnet/align.sh --nj $max_num_jobs --cmd "$train_cmd" \
    $train_bn_fmllr $lang $srcdir ${srcdir}_ali || exit 1;
  steps/nnet/make_denlats.sh --nj $max_num_jobs --cmd "$decode_cmd" \
    --acwt $acwt \
    $train_bn_fmllr $lang $srcdir ${srcdir}_denlats  || exit 1;
fi
# Step 6: train the sMBR
if [ $stage -le 6 ]; then
  # Do 4 epochs of sMBR (leaving out all silence frames and compensating insertions),
  (tail --pid=$$ -F $dir/log/train_mpe.log 2>/dev/null)& # forward log
  steps/nnet/train_mpe.sh --cmd "$cuda_cmd" --num-iters 4 --acwt $acwt \
    --do-smbr true --exclude-silphones true --one-silence-class true \
    $train_bn_fmllr $lang $srcdir ${srcdir}_ali ${srcdir}_denlats $dir || exit 1
  # Decode test,
  for ITER in 1 2 3 4; do
    for lt in ${lang_test_arr[@]}; do
      for ls in ${lm_suffix_arr[@]}; do
        graph_dir=$fmllrdir/graph_$(basename $lt)_$ls
        steps/nnet/decode.sh --nj $dec_nj --cmd "$decode_cmd" \
          --config conf/decode_dnn.conf --acwt $acwt \
          --nnet $dir/${ITER}.nnet \
          $graph_dir $test_bn_fmllr \
          $dir/decode_$(basename $test_bn_fmllr)_$(basename $lt)_${ls}_it${ITER} &
      done
    done
    wait;
  done
fi

echo $0 success.
exit 0
