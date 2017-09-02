#!/bin/bash

# This script will execute the data preparation and train and decode baseline
# HMM-GMM systems for the specified language(s).



# Need to set the queue options and paths in these files before running.
[ -f cmd.sh ] && source ./cmd.sh || echo "cmd.sh not found. Jobs may not execute properly."
. path.sh || { echo "Cannot source path.sh"; exit 1; }


# Options that need to be set

L=swahili
LANGUAGES="swahili" # Separate these with single spaces

max_num_jobs=48 # Set this to the most cpus available at once

# Can take options from command line here
. utils/parse_options.sh || exit 1;


# PART 1: Data and language prep
echo "Preparing the data..."

for L in $LANGUAGES; do
  # STEP 1: Do the data preproc
  # Note that this called script has undergone a lot of changes
  # SET THE STAGE TO MAKE IT GO QUICKER
  # Note that this will clean the transcriptions
  # WARNING: THIS WILL WIPE THE DATA DIR
  local/data_prep.sh --stage 4 $L


  # Build a grapheme dict
  local/make_grapheme_dict.sh $L
  # From here, create a regular dict and a grapheme one
  for D in dict dict_grapheme; do
    # STEP 2: Do the dict preproc
    if [ "$D" == "dict_grapheme" ]; then
      local/dict_prep.sh --grapheme true $L $D
      lang_dir="lang_grapheme"
    else
      local/dict_prep.sh $L $D
      lang_dir="lang"
    fi

    # STEP 3: Prepare the language
    # Only testing for the presence of position-dependent-phones
    utils/prepare_lang.sh --position-dependent-phones true \
       data/$L/local/$D "<UNK>" \
       data/$L/local/${lang_dir}_tmp data/$L/$lang_dir \
       >& data/$L/prepare_${lang_dir}.log || exit 1;
    utils/prepare_lang.sh --position-dependent-phones false \
      data/$L/local/$D "<UNK>" \
      data/$L/local/${lang_dir}_pos_ind_tmp data/$L/${lang_dir}_pos_ind \
      >& data/$L/prepare_${lang_dir}_pos_ind.log || exit 1;

    # Prepare the language model using sri-renormalisation
    local/lm_prep.sh --filter-vocab-sri false $L $lang_dir $D
    local/lm_prep.sh --filter-vocab-sri true $L $lang_dir $D
    local/lm_prep.sh --filter-vocab-sri false $L ${lang_dir}_pos_ind $D
    local/lm_prep.sh --filter-vocab-sri true $L ${lang_dir}_pos_ind $D
  done
done
echo "Done."


mfccdir=mfcc/$L
x=all
steps/make_mfcc.sh --nj 6 --cmd "$train_cmd" data/$L/$x \
  exp/$L/make_mfcc/$x $mfccdir;
steps/compute_cmvn_stats.sh data/$L/$x exp/$L/make_mfcc/$x $mfccdir;


utils/subset_data_dir_tr_cv.sh --cv-spk-percent 5 data/$L/all \
  data/$L/train data/$L/eval

exp="grapheme_95"
mono_train_set="train"
tri1_train_set="train"
tri2a_train_set="train"
tri2b_train_set="train"
tri3b_train_set="train"
test_set="eval"

train_lang="lang_grapheme"
test_lang="lang_grapheme_test"

# Train a simple mono models
mkdir -p exp/$L/mono_${exp};
steps/train_mono.sh --nj $max_num_jobs --cmd "$train_cmd" \
  --cmvn-opts "--norm-vars=true" --totgauss 10000 \
  data/$L/$mono_train_set data/$L/$train_lang exp/$L/mono_${exp} \
  | tee exp/$L/mono_${exp}/train.log

# Decode the mono model
# Note: the lm_suffix could include _sri if re-created using SRILM
for L in $LANGUAGES; do
  for lm_suffix in tg tgpr tg_sri tgpr_sri; do
    graph_dir=exp/$L/mono_${exp}/graph_${lm_suffix}
    mkdir -p $graph_dir
    utils/mkgraph.sh data/$L/${test_lang}_${lm_suffix} exp/$L/mono_${exp} \
      $graph_dir
    num_test_spk=$(cat data/$L/$test_set/spk2utt | wc -l)
    [ $num_test_spk -lt $max_num_jobs ] \
      && dec_nj=$num_test_spk || dec_nj=$max_num_jobs
    steps/decode.sh --nj $dec_nj --cmd "$decode_cmd" \
      $graph_dir data/$L/${test_set} \
      exp/$L/mono_${exp}/decode_${test_set}_${lm_suffix} &
  done
done
wait;



# Train tri1, which is first triphone pass
for L in $LANGUAGES; do
  (
    mkdir -p exp/$L/mono_${exp}_ali
    steps/align_si.sh --nj 10 --cmd "$train_cmd" \
	    data/$L/$tri1_train_set data/$L/${train_lang} \
      exp/$L/mono_${exp} exp/$L/mono_${exp}_ali \
	    | tee exp/$L/mono_${exp}_ali/align.log

    num_states=$(grep "^$L" conf/tri.conf | cut -f2)
    num_gauss=$(grep "^$L" conf/tri.conf | cut -f3)
    mkdir -p exp/$L/tri1_${exp}
    steps/train_deltas.sh --cmd "$train_cmd" \
      --cmvn-opts "--norm-vars=true" \
	    --cluster-thresh 100 $num_states $num_gauss \
      data/$L/$tri1_train_set data/$L/${train_lang} \
	    exp/$L/mono_${exp}_ali exp/$L/tri1_${exp} \
      | tee exp/$L/tri1_${exp}/train.log
  ) &
done
wait;

# Decode tri1
for L in $LANGUAGES; do
  for lm_suffix in tg tgpr tg_sri tgpr_sri; do
    graph_dir=exp/$L/tri1_${exp}/graph_${lm_suffix}
    mkdir -p $graph_dir
    utils/mkgraph.sh data/$L/${test_lang}_${lm_suffix} exp/$L/tri1_${exp} \
      $graph_dir
    num_test_spk=$(cat data/$L/$test_set/spk2utt | wc -l)
    [ $num_test_spk -lt $max_num_jobs ] \
      && dec_nj=$num_test_spk || dec_nj=$max_num_jobs
    steps/decode.sh --nj $dec_nj --cmd "$decode_cmd" \
      $graph_dir data/$L/$test_set \
      exp/$L/tri1_${exp}/decode_${test_set}_${lm_suffix} &
  done
done

# Train tri2a, which is deltas + delta-deltas
for L in $LANGUAGES; do
  (
    mkdir -p exp/$L/tri1_${exp}_ali
    steps/align_si.sh --nj 10 --cmd "$train_cmd" \
	    data/$L/$tri2a_train_set data/$L/${train_lang} \
      exp/$L/tri1_${exp} exp/$L/tri1_${exp}_ali \
	    | tee exp/$L/tri1_${exp}_ali/align.log

    num_states=$(grep "^$L" conf/tri.conf | cut -f2)
    num_gauss=$(grep "^$L" conf/tri.conf | cut -f3)
    mkdir -p exp/$L/tri2a_${exp}
    steps/train_deltas.sh --cmd "$train_cmd" \
      --cmvn-opts "--norm-vars=true" \
	    --cluster-thresh 100 $num_states $num_gauss \
      data/$L/$tri2a_train_set data/$L/${train_lang} \
	    exp/$L/tri1_${exp}_ali exp/$L/tri2a_${exp} \
      | tee exp/$L/tri2a_${exp}/train.log
  ) &
done
wait;

# Decode tri2a
for L in $LANGUAGES; do
  for lm_suffix in tg tgpr_sri; do
    graph_dir=exp/$L/tri2a_${exp}/graph_${lm_suffix}
    mkdir -p $graph_dir
    utils/mkgraph.sh data/$L/${test_lang}_${lm_suffix} exp/$L/tri2a_${exp} \
      $graph_dir
    num_test_spk=$(cat data/$L/$test_set/spk2utt | wc -l)
    [ $num_test_spk -lt $max_num_jobs ] \
      && dec_nj=$num_test_spk || dec_nj=$max_num_jobs
    steps/decode.sh --nj $dec_nj --cmd "$decode_cmd" \
      $graph_dir data/$L/$test_set \
      exp/$L/tri2a_${exp}/decode_${test_set}_${lm_suffix} &
  done
done

# Train tri2b, which is LDA+MLLT
for L in $LANGUAGES; do
  (
    # Realign tri2a results
    mkdir -p exp/$L/tri2a_${exp}_ali
    steps/align_si.sh --nj 10 --cmd "$train_cmd" \
      data/$L/$tri2b_train_set data/$L/${train_lang} \
      exp/$L/tri2a_${exp} exp/$L/tri2a_${exp}_ali \
      | tee exp/$L/tri2a_${exp}_ali/align.log
    num_states=$(grep "^$L" conf/tri.conf | cut -f2)
    num_gauss=$(grep "^$L" conf/tri.conf | cut -f3)
    # Run tri2b on tri2a alignment
    mkdir -p exp/$L/tri2b_${exp}
    steps/train_lda_mllt.sh --cmd "$train_cmd" \
      --cmvn-opts "--norm-vars=true" \
	    --splice-opts "--left-context=3 --right-context=3" \
      $num_states $num_gauss data/$L/$tri2b_train_set \
	    data/$L/${train_lang} exp/$L/tri2a_${exp}_ali exp/$L/tri2b_${exp} \
      | tee exp/$L/tri2b_${exp}/train.log
  ) &
done
wait;

# Decode tri2b
for L in $LANGUAGES; do
  for lm_suffix in tg tgpr_sri; do
    graph_dir=exp/$L/tri2b_${exp}/graph_${lm_suffix}
    mkdir -p $graph_dir
    utils/mkgraph.sh data/$L/${test_lang}_${lm_suffix} exp/$L/tri2b_${exp} \
	    $graph_dir
    num_test_spk=$(cat data/$L/$test_set/spk2utt | wc -l)
    [ $num_test_spk -lt $max_num_jobs ] \
      && dec_nj=$num_test_spk || dec_nj=$max_num_jobs
    steps/decode.sh --nj $dec_nj --cmd "$decode_cmd" \
      $graph_dir data/$L/$test_set \
	    exp/$L/tri2b_${exp}/decode_${test_set}_${lm_suffix} &
  done
done

# Train tri3b, which is LDA+MLLT+SAT.
for L in $LANGUAGES; do
  (
    mkdir -p exp/$L/tri2b_${exp}_ali
    steps/align_fmllr.sh --nj 10 --cmd "$train_cmd" \
	    data/$L/$tri3b_train_set data/$L/${train_lang} \
      exp/$L/tri2b_${exp} exp/$L/tri2b_${exp}_ali \
	    | tee exp/$L/tri2b_${exp}_ali/align.log

    num_states=$(grep "^$L" conf/tri.conf | cut -f2)
    num_gauss=$(grep "^$L" conf/tri.conf | cut -f3)
    mkdir -p exp/$L/tri3b_${exp}
    steps/train_sat.sh --cmd "$train_cmd" \
	    --cluster-thresh 100 $num_states $num_gauss \
      data/$L/$tri3b_train_set data/$L/${train_lang} \
	    exp/$L/tri2b_${exp}_ali exp/$L/tri3b_${exp} \
      | tee exp/$L/tri3b_${exp}/train.log
  ) &
done
wait;

# Decode 3b
for L in $LANGUAGES; do
  for lm_suffix in tg tgpr tg_sri tgpr_sri; do
    graph_dir=exp/$L/tri3b_${exp}/graph_${lm_suffix}
    mkdir -p $graph_dir
    utils/mkgraph.sh data/$L/${test_lang}_${lm_suffix} exp/$L/tri3b_${exp} \
	    $graph_dir
    num_test_spk=$(cat data/$L/$test_set/spk2utt | wc -l)
    [ $num_test_spk -lt $max_num_jobs ] \
      && dec_nj=$num_test_spk || dec_nj=$max_num_jobs
    steps/decode_fmllr.sh --nj $dec_nj --cmd "$decode_cmd" \
	    $graph_dir data/$L/${test_set} \
      exp/$L/tri3b_${exp}/decode_${test_set}_${lm_suffix} &
  done
done

# Train tri3c, the second pass of LDA+MLLT+SAT.
for L in $LANGUAGES; do
  (
    mkdir -p exp/$L/tri3b_${exp}_ali
    steps/align_fmllr.sh --nj 10 --cmd "$train_cmd" \
	    data/$L/$tri3b_train_set data/$L/${train_lang} \
      exp/$L/tri3b_${exp} exp/$L/tri3b_${exp}_ali \
	    | tee exp/$L/tri3b_${exp}_ali/align.log

    num_states=$(grep "^$L" conf/tri.conf | cut -f2)
    num_gauss=$(grep "^$L" conf/tri.conf | cut -f3)
    mkdir -p exp/$L/tri3c_${exp}
    steps/train_sat.sh --cmd "$train_cmd" \
	    --cluster-thresh 100 $num_states $num_gauss \
      data/$L/$tri3b_train_set data/$L/${train_lang} \
	    exp/$L/tri3b_${exp}_ali exp/$L/tri3c_${exp} \
      | tee exp/$L/tri3c_${exp}/train.log
  ) &
done
wait;


# Decode 3c
for L in $LANGUAGES; do
  for lm_suffix in tg tgpr tg_sri tgpr_sri; do
    graph_dir=exp/$L/tri3c_${exp}/graph_${lm_suffix}
    mkdir -p $graph_dir
    utils/mkgraph.sh data/$L/${test_lang}_${lm_suffix} exp/$L/tri3c_${exp} \
	    $graph_dir
    num_test_spk=$(cat data/$L/$test_set/spk2utt | wc -l)
    [ $num_test_spk -lt $max_num_jobs ] \
      && dec_nj=$num_test_spk || dec_nj=$max_num_jobs
    steps/decode_fmllr.sh --nj $dec_nj --cmd "$decode_cmd" \
	    $graph_dir data/$L/${test_set} \
      exp/$L/tri3c_${exp}/decode_${test_set}_${lm_suffix} &
  done
done
wait;
