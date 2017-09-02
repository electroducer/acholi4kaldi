#!/bin/bash

# Writes the best WER and other useful info to a file for each experiment

# Should normally be exp unless otherwise specified
lang=$1
# Can be any prefix (general or specific), none will give all results for lang
test_type=$2

for exp in exp/${lang}/${test_type}*; do
  if [[ ! "$exp" == *"ali" ]]; then
    expname=`basename $exp`
    for decode_type in $exp/decode*; do
      decodename=`basename $decode_type`
      # Get the average log likelihood
      avg_ll=`egrep -o 'frame is -[0-9.]+ over [0-9]+' $decode_type/log/* | awk '{f+=$5; p+=$3*$5} END {print p/f}'`
      # Send out the following:
      # - language `echo $expname | awk -F"_" '{print $1, $2, $3, $4}'`
      # - experiment `echo $decodename | awk -F"_" '{print $2, $3, $4, $5}'`
      echo $lang\
        $expname\
        $decodename\
        `grep WER $decode_type/wer* | utils/best_wer.sh |\
          awk '{print $2, $4, $7, $9, $11}'`\
        `gmm-info --print-args=false $exp/final.mdl | grep gauss | awk '{print $4}'`\
        `steps/info/gmm_dir_info.pl $exp | awk '{print $4}' | awk -F '=' '{print $2}'`\
         $avg_ll
    done
  fi
done
