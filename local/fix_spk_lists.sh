#!/bin/bash -u

# Fixes inconsistencies in the speaker lists

# Get the path to speaker lists as an argument
SPK_PATH=$1



for sfile in $(ls $SPK_PATH/*.txt); do
  base=$(basename $sfile '.txt')
  # Description of patterns:
  # Get rid of blank lines
  # Remove the extra formatting, leaving only the utt id
  # Add leading zeros to the utt id and complete it using the recording id
  # Use awk to seek and destroy duplicate lines
  awk '!seen[$0]++' $sfile \
    | sed -e '/^[[:space:]]*$/d' -e 's/\interval//' -e 's/\[\]//' \
    -e 's/\ *\[//' -e's/\]//' \
    -e 's/^\ *//' -e 's/\b[0-9]\b/00&/' -e 's/\b[0-9][0-9]\b/0&/' \
    -e "s/^/${base}_/" \
    -e 's/[^0-9]$//' -e 's/^[^0-9MF]//' \
    >> $SPK_PATH/all_spk.txt
done
