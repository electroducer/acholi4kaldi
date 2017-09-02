#!/bin/bash


# Produces stats for two systems



# Paths to systems
sys1=$1
sys2=$2

best_sys1=$(grep WER $sys1/decode*/wer* | utils/best_wer.sh | cut -d" " -f14)
best_sys2=$(grep WER $sys2/decode*/wer* | utils/best_wer.sh | cut -d" " -f14)

hyp1=$(basename $best_sys1 | sed -e 's/wer_//' -e 's/_/./' -e 's/$/.tra/')
hyp2=$(basename $best_sys2 | sed -e 's/wer_//' -e 's/_/./' -e 's/$/.tra/')

dir1=$(dirname $best_sys1)
dir2=$(dirname $best_sys2)

ref=test_filt.txt

if [[ $dir1 == *"grapheme"* ]] && [[ $dir1 != *"phoneme"* ]]; then
  words1=data/acholi/lang_grapheme_test_tg/words.txt
else
  words1=data/acholi/lang_test_tg/words.txt
fi

if [[ $dir2 == *"grapheme"* ]] && [[ $dir2 != *"phoneme"* ]]; then
  words2=data/acholi/lang_grapheme_test_tg/words.txt
else
  words2=data/acholi/lang_test_tg/words.txt
fi


local/score_sclite.sh $dir1 $ref $hyp1 $words1
local/score_sclite.sh $dir2 $ref $hyp2 $words2

cat $dir1/sc_scores/hyp.sgml $dir2/sc_scores/hyp.sgml | \
  sc_stats -p -r sum rsum es res lur -t std4 -u -g grange2 det
