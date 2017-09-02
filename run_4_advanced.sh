#!/bin/bash

# Runs advanced experiments involving bottleneck features.
# Since each experiment takes time, they are executed individually and
# can be copied directly into the command line if desired.

# Assumes that the GMM runners have already been run.

max_num_jobs=48



# This will run a basic dnn, but with only the pretrained dbn layers
local/nnet/run_basic_dnn.sh --L acholi --exp trimmed_lang \
  --train_set train_dev_trimmed --test_set eval_trimmed

# Another for graphemes
local/nnet/run_basic_dnn.sh --L acholi --exp trimmed_lang_grapheme \
  --data-fmllr data/acholi/fmllr-tri3b-grapheme \
  --train_set train_dev_trimmed --test_set eval_trimmed \
  --train-lang lang_grapheme

# BNF EXPERIMENTS --------------------------------------------

# BNF Baseline (Acholi-only BN-DNN)

# PHONEME-BASED BNFs

lang_code_csl="acholi"
lang_weight_csl="1.0" # Per-language weights, they scale loss-function and gradient, 1.0 for each language is good,
ali_dir_csl="exp/acholi/tri3b_trimmed_lang_ali" # One ali-dir per language,
data_dir_csl="data/acholi/train_dev_trimmed" # One train-data-dir per language (features will be re-computed),

nnet_type=bn # dnn_small | dnn | bn

local/nnet/run_multilingual.sh --lang-code-csl $lang_code_csl \
  --lang-weight-csl $lang_weight_csl --ali-dir-csl $ali_dir_csl \
  --data-dir-csl $data_dir_csl --nnet-type $nnet_type \
  --train_lang lang

# GRAPHEME-BASED BNFs

ali_dir_csl="exp/acholi/tri3b_trimmed_lang_grapheme_ali" # One ali-dir per language,

local/nnet/run_multilingual.sh --lang-code-csl $lang_code_csl \
  --lang-weight-csl $lang_weight_csl --ali-dir-csl $ali_dir_csl \
  --data-dir-csl $data_dir_csl --nnet-type $nnet_type --exp grapheme \
  --train_lang lang_grapheme --stage 1


# Now get train using the Acholi-only phoneme BNFs (Using phonemes)

train_lang=data/acholi/lang
lang_test="data/acholi/lang_test,data/acholi/lang_small_new_test"
ali=exp/acholi/tri3b_trimmed_lang_ali

# Bottleneck NN
nnet_dir=exp/dnn4g-multilingual1-acholi-bn
dnn_dir=exp/acholi/dnn_multilingual1_bnf_pretrain-dbn
# New training and test data directories
train_bn=data-bn/acholi/train_dev_trimmed_mono
test_bn=data-bn/acholi/eval_trimmed_mono
train_bn_fmllr=data-bn-fmllr/acholi/train_dev_trimmed_mono
test_bn_fmllr=data-bn-fmllr/acholi/eval_trimmed_mono

local/nnet/run_bnf_models.sh --lang $train_lang --lang-test $lang_test \
  --ali $ali --nnet-dir $nnet_dir --dnn-dir $dnn_dir \
  --train-bn $train_bn --test-bn $test_bn \
  --train-bn-fmllr $train_bn_fmllr --test-bn-fmllr $test_bn_fmllr

# Now get train using the Acholi-only phoneme BNFs (Using graphemes)

train_lang=data/acholi/lang_grapheme
lang_test="data/acholi/lang_grapheme_test,data/acholi/lang_grapheme_small_new_test"
ali=exp/acholi/tri3b_trimmed_lang_grapheme_ali

# Bottleneck NN
nnet_dir=exp/dnn4g-multilingual1-acholi-bn
dnn_dir=exp/acholi/dnn_multilingual1_bnf_pretrain-dbnap-grapheme
# New training and test data directories
train_bn=data-bn/acholi/train_dev_trimmed_grapheme_mono_ap
test_bn=data-bn/acholi/eval_trimmed_grapheme_mono_ap
train_bn_fmllr=data-bn-fmllr/acholi/train_dev_trimmed_grapheme_mono_ap
test_bn_fmllr=data-bn-fmllr/acholi/eval_trimmed_grapheme_mono_ap

local/nnet/run_bnf_models.sh --lang $train_lang --lang-test $lang_test \
  --ali $ali --nnet-dir $nnet_dir --dnn-dir $dnn_dir \
  --train-bn $train_bn --test-bn $test_bn \
  --train-bn-fmllr $train_bn_fmllr --test-bn-fmllr $test_bn_fmllr



# Now get train using the Acholi-only grapheme BNFs (Using graphemes)

train_lang=data/acholi/lang_grapheme
lang_test="data/acholi/lang_grapheme_test,data/acholi/lang_grapheme_small_new_test"
ali=exp/acholi/tri3b_trimmed_lang_grapheme_ali

# Bottleneck NN
nnet_dir=exp/dnn4g-multilingual1-acholi-bngrapheme
dnn_dir=exp/acholi/dnn_multilingual1_bnf_pretrain-dbngrapheme
# New training and test data directories
train_bn=data-bn/acholi/train_dev_trimmed_grapheme_mono
test_bn=data-bn/acholi/eval_trimmed_grapheme_mono
train_bn_fmllr=data-bn-fmllr/acholi/train_dev_trimmed_grapheme_mono
test_bn_fmllr=data-bn-fmllr/acholi/eval_trimmed_grapheme_mono

local/nnet/run_bnf_models.sh --lang $train_lang --lang-test $lang_test \
  --ali $ali --nnet-dir $nnet_dir --dnn-dir $dnn_dir \
  --train-bn $train_bn --test-bn $test_bn \
  --train-bn-fmllr $train_bn_fmllr --test-bn-fmllr $test_bn_fmllr

# Now get train using the Acholi-only grapheme BNFs (Using phonemes)

train_lang=data/acholi/lang
lang_test="data/acholi/lang_test,data/acholi/lang_small_new_test"
ali=exp/acholi/tri3b_trimmed_lang_ali

# Bottleneck NN
nnet_dir=exp/dnn4g-multilingual1-acholi-bngrapheme
dnn_dir=exp/acholi/dnn_multilingual1_bnf_pretrain-dbnag-phoneme
# New training and test data directories
train_bn=data-bn/acholi/train_dev_trimmed_mono_ag
test_bn=data-bn/acholi/eval_trimmed_mono_ag
train_bn_fmllr=data-bn-fmllr/acholi/train_dev_trimmed_mono_ag
test_bn_fmllr=data-bn-fmllr/acholi/eval_trimmed_mono_ag

local/nnet/run_bnf_models.sh --lang $train_lang --lang-test $lang_test \
  --ali $ali --nnet-dir $nnet_dir --dnn-dir $dnn_dir \
  --train-bn $train_bn --test-bn $test_bn \
  --train-bn-fmllr $train_bn_fmllr --test-bn-fmllr $test_bn_fmllr




# ACHOLI (PH) + SWAHILI (PH) MULTILINGUAL BN DNN (Used to extract BNFs)
# THIS USES PHONEMES

lang_code_csl="acholi,swahili" # One label for each language,
lang_weight_csl="1.0,1.0" # Per-language weights, they scale loss-function and gradient, 1.0 for each language is good,
ali_dir_csl="exp/acholi/tri3b_trimmed_lang_ali,exp/swahili/tri3b_basic_95_ali" # One ali-dir per language,
data_dir_csl="data/acholi/train_dev_trimmed,data/swahili/train" # One train-data-dir per language (features will be re-computed),

nnet_type=bn # dnn_small | dnn | bn

local/nnet/run_multilingual.sh --lang-code-csl $lang_code_csl \
  --lang-weight-csl $lang_weight_csl --ali-dir-csl $ali_dir_csl \
  --data-dir-csl $data_dir_csl --nnet-type $nnet_type \
  --train_lang lang

# ACHOLI (PH) + SWAHILI (PH) BNF TRAINING AND DECODING (USING PHONEMES)

train_lang=data/acholi/lang
lang_test="data/acholi/lang_test,data/acholi/lang_small_new_test"
ali=exp/acholi/tri3b_trimmed_lang_ali

# Bottleneck NN
nnet_dir=exp/dnn4g-multilingual2-acholi-swahili-bn
dnn_dir=exp/acholi/dnn_multilingual2_bnf_pretrain-dbn
# New training and test data directories
train_bn=data-bn/acholi/train_dev_trimmed
test_bn=data-bn/acholi/eval_trimmed
train_bn_fmllr=data-bn-fmllr/acholi/train_dev_trimmed
test_bn_fmllr=data-bn-fmllr/acholi/eval_trimmed

local/nnet/run_bnf_models.sh --lang $train_lang --lang-test $lang_test \
  --ali $ali --nnet-dir $nnet_dir --dnn-dir $dnn_dir \
  --train-bn $train_bn --test-bn $test_bn \
  --train-bn-fmllr $train_bn_fmllr --test-bn-fmllr $test_bn_fmllr


# ACHOLI (PH) + SWAHILI (PH) BNF TRAINING AND DECODING (USING GRAPHEMES)

train_lang=data/acholi/lang_grapheme
lang_test="data/acholi/lang_grapheme_test,data/acholi/lang_grapheme_small_new_test"
ali=exp/acholi/tri3b_trimmed_lang_grapheme_ali

# Bottleneck NN
nnet_dir=exp/dnn4g-multilingual2-acholi-swahili-bn
dnn_dir=exp/acholi/dnn_multilingual2_bnf_pretrain-dbnapsp-grapheme
# New training and test data directories
train_bn=data-bn/acholi/train_dev_trimmed_grapheme_apsp
test_bn=data-bn/acholi/eval_trimmed_grapheme_apsp
train_bn_fmllr=data-bn-fmllr/acholi/train_dev_trimmed_grapheme_apsp
test_bn_fmllr=data-bn-fmllr/acholi/eval_trimmed_grapheme_apsp

local/nnet/run_bnf_models.sh --lang $train_lang --lang-test $lang_test \
  --ali $ali --nnet-dir $nnet_dir --dnn-dir $dnn_dir \
  --train-bn $train_bn --test-bn $test_bn \
  --train-bn-fmllr $train_bn_fmllr --test-bn-fmllr $test_bn_fmllr




# ACHOLI + SWAHILI MULTILINGUAL BN DNN (Used to extract BNFs)
# THIS USES GRAPHEMES

lang_code_csl="acholi,swahili" # One label for each language,
lang_weight_csl="1.0,1.0" # Per-language weights, they scale loss-function and gradient, 1.0 for each language is good,
ali_dir_csl="exp/acholi/tri3b_trimmed_lang_grapheme_ali,exp/swahili/tri3b_grapheme_95_ali" # One ali-dir per language,
data_dir_csl="data/acholi/train_dev_trimmed,data/swahili/train" # One train-data-dir per language (features will be re-computed),

nnet_type=bn # dnn_small | dnn | bn

local/nnet/run_multilingual.sh --lang-code-csl $lang_code_csl \
  --lang-weight-csl $lang_weight_csl --ali-dir-csl $ali_dir_csl \
  --data-dir-csl $data_dir_csl --nnet-type $nnet_type --exp grapheme \
  --train_lang lang_grapheme --stage 1

# ACHOLI + SWAHILI (GRAPHEME) BNF TRAINING AND DECODING (PHONEME)

train_lang=data/acholi/lang
lang_test="data/acholi/lang_test,data/acholi/lang_small_new_test"
ali=exp/acholi/tri3b_trimmed_lang_ali

# Bottleneck NN
nnet_dir=exp/dnn4g-multilingual2-acholi-swahili-bngrapheme
dnn_dir=exp/acholi/dnn_multilingual2_bnf_pretrain-dbngrapheme-phoneme
# New training and test data directories
train_bn=data-bn/acholi/train_dev_trimmed_m2agsg
test_bn=data-bn/acholi/eval_trimmed_m2agsg
train_bn_fmllr=data-bn-fmllr/acholi/train_dev_trimmed_m2agsg
test_bn_fmllr=data-bn-fmllr/acholi/eval_trimmed_m2agsg

local/nnet/run_bnf_models.sh --lang $train_lang --lang-test $lang_test \
  --ali $ali --nnet-dir $nnet_dir --dnn-dir $dnn_dir \
  --train-bn $train_bn --test-bn $test_bn \
  --train-bn-fmllr $train_bn_fmllr --test-bn-fmllr $test_bn_fmllr


# ACHOLI + SWAHILI (GRAPHEME) BNF TRAINING AND DECODING (GRAPHEME)

train_lang=data/acholi/lang_grapheme
lang_test="data/acholi/lang_grapheme_test,data/acholi/lang_grapheme_small_new_test"
ali=exp/acholi/tri3b_trimmed_lang_grapheme_ali

# Bottleneck NN
nnet_dir=exp/dnn4g-multilingual2-acholi-swahili-bngrapheme
dnn_dir=exp/acholi/dnn_multilingual2_bnf_pretrain-dbngrapheme
# New training and test data directories
train_bn=data-bn/acholi/train_dev_trimmed_grapheme_m2
test_bn=data-bn/acholi/eval_trimmed_grapheme_m2
train_bn_fmllr=data-bn-fmllr/acholi/train_dev_trimmed_grapheme_m2
test_bn_fmllr=data-bn-fmllr/acholi/eval_trimmed_grapheme_m2

local/nnet/run_bnf_models.sh --lang $train_lang --lang-test $lang_test \
  --ali $ali --nnet-dir $nnet_dir --dnn-dir $dnn_dir \
  --train-bn $train_bn --test-bn $test_bn \
  --train-bn-fmllr $train_bn_fmllr --test-bn-fmllr $test_bn_fmllr


# ACHOLI + LUGANDA BN MDNN
# THIS USES GRAPHEMES

lang_code_csl="acholi,luganda" # One label for each language,
lang_weight_csl="1.0,1.0" # Per-language weights, they scale loss-function and gradient, 1.0 for each language is good,
ali_dir_csl="exp/acholi/tri3b_trimmed_lang_grapheme_ali,exp/luganda/tri3b_trimmed_lang_grapheme" # One ali-dir per language,
data_dir_csl="data/acholi/train_dev_trimmed,data/luganda/train_trimmed" # One train-data-dir per language (features will be re-computed),

nnet_type=bn # dnn_small | dnn | bn

local/nnet/run_multilingual.sh --lang-code-csl $lang_code_csl \
  --lang-weight-csl $lang_weight_csl --ali-dir-csl $ali_dir_csl \
  --data-dir-csl $data_dir_csl --nnet-type $nnet_type --exp grapheme \
  --train_lang lang_grapheme

# ACHOLI + LUGANDA (GRAPHEME) (USING PHONEMES)

train_lang=data/acholi/lang
lang_test="data/acholi/lang_test,data/acholi/lang_small_new_test"
ali=exp/acholi/tri3b_trimmed_lang_ali

# Bottleneck NN
nnet_dir=exp/dnn4g-multilingual2-acholi-luganda-bngrapheme
dnn_dir=exp/acholi/dnn_multilingual2_al_bnf_pretrain-dbngrapheme-phoneme
# New training and test data directories
train_bn=data-bn/acholi/train_dev_trimmed_al
test_bn=data-bn/acholi/eval_trimmed_al
train_bn_fmllr=data-bn-fmllr/acholi/train_dev_trimmed_al
test_bn_fmllr=data-bn-fmllr/acholi/eval_trimmed_al

local/nnet/run_bnf_models.sh --lang $train_lang --lang-test $lang_test \
  --ali $ali --nnet-dir $nnet_dir --dnn-dir $dnn_dir \
  --train-bn $train_bn --test-bn $test_bn \
  --train-bn-fmllr $train_bn_fmllr --test-bn-fmllr $test_bn_fmllr --stage 3


# ACHOLI + LUGANDA (GRAPHEME) (USING GRAPHEMES)

train_lang=data/acholi/lang_grapheme
lang_test="data/acholi/lang_grapheme_test,data/acholi/lang_grapheme_small_new_test"
ali=exp/acholi/tri3b_trimmed_lang_grapheme_ali

# Bottleneck NN
nnet_dir=exp/dnn4g-multilingual2-acholi-luganda-bngrapheme
dnn_dir=exp/acholi/dnn_multilingual2_al_bnf_pretrain-dbngrapheme
# New training and test data directories
train_bn=data-bn/acholi/train_dev_trimmed_grapheme_al
test_bn=data-bn/acholi/eval_trimmed_grapheme_al
train_bn_fmllr=data-bn-fmllr/acholi/train_dev_trimmed_grapheme_al
test_bn_fmllr=data-bn-fmllr/acholi/eval_trimmed_grapheme_al

local/nnet/run_bnf_models.sh --lang $train_lang --lang-test $lang_test \
  --ali $ali --nnet-dir $nnet_dir --dnn-dir $dnn_dir \
  --train-bn $train_bn --test-bn $test_bn \
  --train-bn-fmllr $train_bn_fmllr --test-bn-fmllr $test_bn_fmllr --stage 3


# TRILINGUAL BN DNN TRAINING (ACHOLI+SWAHILI+LUGANDA) (ALL GRAPHEME)

lang_code_csl="acholi,swahili,luganda" # One label for each language,
lang_weight_csl="1.0,1.0,1.0" # Per-language weights, they scale loss-function and gradient, 1.0 for each language is good,
ali_dir_csl="exp/acholi/tri3b_trimmed_lang_grapheme_ali,exp/swahili/tri3b_grapheme_95_ali,exp/luganda/tri3b_trimmed_lang_grapheme_ali" # One ali-dir per language,
data_dir_csl="data/acholi/train_dev_trimmed,data/swahili/train,data/luganda/train_trimmed" # One train-data-dir per language (features will be re-computed),

nnet_type=bn # dnn_small | dnn | bn

local/nnet/run_multilingual.sh --lang-code-csl $lang_code_csl \
  --lang-weight-csl $lang_weight_csl --ali-dir-csl $ali_dir_csl \
  --data-dir-csl $data_dir_csl --nnet-type $nnet_type --exp grapheme \
  --train_lang lang_grapheme --stage 1

# TRILINGUAL BN DNN TRAINING (ACHOLI(PH)+SWAHILI(PH)+LUGANDA(GR))

lang_code_csl="acholi,swahili,luganda" # One label for each language,
lang_weight_csl="1.0,1.0,1.0" # Per-language weights, they scale loss-function and gradient, 1.0 for each language is good,
ali_dir_csl="exp/acholi/tri3b_trimmed_lang_ali,exp/swahili/tri3b_basic_95_ali,exp/luganda/tri3b_trimmed_lang_grapheme_ali" # One ali-dir per language,
data_dir_csl="data/acholi/train_dev_trimmed,data/swahili/train,data/luganda/train_trimmed" # One train-data-dir per language (features will be re-computed),

nnet_type=bn # dnn_small | dnn | bn

local/nnet/run_multilingual.sh --lang-code-csl $lang_code_csl \
  --lang-weight-csl $lang_weight_csl --ali-dir-csl $ali_dir_csl \
  --data-dir-csl $data_dir_csl --nnet-type $nnet_type --exp apsplg \
  --train_lang lang


# TRAIN USING TRILINGUAL-GRAPHAME BNFs (TO GRAPHEMES)

train_lang=data/acholi/lang_grapheme
lang_test="data/acholi/lang_grapheme_test,data/acholi/lang_grapheme_small_new_test"
ali=exp/acholi/tri3b_trimmed_lang_grapheme_ali

# Bottleneck NN
nnet_dir=exp/dnn4g-multilingual3-acholi-swahili-luganda-bngrapheme
dnn_dir=exp/acholi/dnn_multilingual3_bnf_pretrain-dbngrapheme
# New training and test data directories
train_bn=data-bn/acholi/train_dev_trimmed_grapheme_m3
test_bn=data-bn/acholi/eval_trimmed_grapheme_m3
train_bn_fmllr=data-bn-fmllr/acholi/train_dev_trimmed_grapheme_m3
test_bn_fmllr=data-bn-fmllr/acholi/eval_trimmed_grapheme_m3

local/nnet/run_bnf_models.sh --lang $train_lang --lang-test $lang_test \
  --ali $ali --nnet-dir $nnet_dir --dnn-dir $dnn_dir \
  --train-bn $train_bn --test-bn $test_bn \
  --train-bn-fmllr $train_bn_fmllr --test-bn-fmllr $test_bn_fmllr


# TRAIN USING TRILINGUAL-GRAPHEME BNFs (USING PHONEMES)

train_lang=data/acholi/lang
lang_test="data/acholi/lang_test,data/acholi/lang_small_new_test"
ali=exp/acholi/tri3b_trimmed_lang_ali

# Bottleneck NN
nnet_dir=exp/dnn4g-multilingual3-acholi-swahili-luganda-bngrapheme
dnn_dir=exp/acholi/dnn_multilingual3_bnf_pretrain-dbngrapheme-phoneme
# New training and test data directories
train_bn=data-bn/acholi/train_dev_trimmed_m3
test_bn=data-bn/acholi/eval_trimmed_m3
train_bn_fmllr=data-bn-fmllr/acholi/train_dev_trimmed_m3
test_bn_fmllr=data-bn-fmllr/acholi/eval_trimmed_m3

local/nnet/run_bnf_models.sh --lang $train_lang --lang-test $lang_test \
  --ali $ali --nnet-dir $nnet_dir --dnn-dir $dnn_dir \
  --train-bn $train_bn --test-bn $test_bn \
  --train-bn-fmllr $train_bn_fmllr --test-bn-fmllr $test_bn_fmllr

# TRAIN USING TRILINGUAL-apsplg BNFs (USING PHONEMES)

train_lang=data/acholi/lang
lang_test="data/acholi/lang_test,data/acholi/lang_small_new_test"
ali=exp/acholi/tri3b_trimmed_lang_ali

# Bottleneck NN
nnet_dir=exp/dnn4g-multilingual3-acholi-swahili-luganda-bnapsplg
dnn_dir=exp/acholi/dnn_multilingual3_bnf_pretrain-dbnapsplg-phoneme
# New training and test data directories
train_bn=data-bn/acholi/train_dev_trimmed_m3apsplg
test_bn=data-bn/acholi/eval_trimmed_m3apsplg
train_bn_fmllr=data-bn-fmllr/acholi/train_dev_trimmed_m3apsplg
test_bn_fmllr=data-bn-fmllr/acholi/eval_trimmed_m3apsplg

local/nnet/run_bnf_models.sh --lang $train_lang --lang-test $lang_test \
  --ali $ali --nnet-dir $nnet_dir --dnn-dir $dnn_dir \
  --train-bn $train_bn --test-bn $test_bn \
  --train-bn-fmllr $train_bn_fmllr --test-bn-fmllr $test_bn_fmllr

# TRAIN USING TRILINGUAL-apsplg BNFs (USING GRAPHEMES)

train_lang=data/acholi/lang_grapheme
lang_test="data/acholi/lang_grapheme_test,data/acholi/lang_grapheme_small_new_test"
ali=exp/acholi/tri3b_trimmed_lang_grapheme_ali

# Bottleneck NN
nnet_dir=exp/dnn4g-multilingual3-acholi-swahili-luganda-bnapsplg
dnn_dir=exp/acholi/dnn_multilingual3_bnf_pretrain-dbnapsplg-grapheme
# New training and test data directories
train_bn=data-bn/acholi/train_dev_trimmed_grapheme_m3apsplg
test_bn=data-bn/acholi/eval_trimmed_grapheme_m3apsplg
train_bn_fmllr=data-bn-fmllr/acholi/train_dev_trimmed_grapheme_m3apsplg
test_bn_fmllr=data-bn-fmllr/acholi/eval_trimmed_grapheme_m3apsplg

local/nnet/run_bnf_models.sh --lang $train_lang --lang-test $lang_test \
  --ali $ali --nnet-dir $nnet_dir --dnn-dir $dnn_dir \
  --train-bn $train_bn --test-bn $test_bn \
  --train-bn-fmllr $train_bn_fmllr --test-bn-fmllr $test_bn_fmllr \
  --run-local true
