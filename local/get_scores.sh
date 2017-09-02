#!/bin/bash

for L in acholi; do
  for dir in exp/$L/*; do
    if ls $dir/decode*/wer* 1> /dev/null 2>&1; then
      echo `basename $dir`
      grep WER $dir/decode*/wer* | utils/best_wer.sh
    fi
  done
done
