#!/bin/bash
# Copyright 2010-2011 Microsoft Corporation

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# THIS CODE IS PROVIDED *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED
# WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR PURPOSE,
# MERCHANTABLITY OR NON-INFRINGEMENT.
# See the Apache 2 License for the specific language governing permissions and
# limitations under the License.


# Does the sclite version of scoring in decode directories.

if [ $# != 4 ]; then
   echo "Usage: scripts/score_sclite.sh <decode-dir> <ref>"
   exit 1;
fi

# if [ ! -f $sclite  ]; then
#    echo "The sclite program is not there.  Follow the INSTALL instructions in ../../../tools";
#    exit 1;
# fi

dir=exp/acholi/tri3b_trimmed_lang/decode_eval_trimmed_tg

dir=$1    # Decoding directory
ref=$2    # Name of reference file (assumed to be in dir/scoring)
hyp=$3    # Name of best wer file (assumed to be in dir/scoring)
words=$4  # Location of words.txt

scoredir=$dir/scoring


# if [ ! -f "$ref" ]; then
#    echo "Reference file $ref is not there"
#    exit 1
# fi

# Put the sc stats here
scdir=$dir/sc_scores
mkdir -p $scdir

cat $scoredir/$hyp  | \
  utils/int2sym.pl -f 2- $words - | \
  sed 's:<s>::' | sed 's:</s>::' | sed 's:<UNK>::g' | \
  sed 's/^\([^ ]*\)\ \(.*\)$/\2 (\1)/' > $scdir/hyp

  # | \
  # scripts/transcript2hyp.pl > $scdir/hyp

cat $scoredir/$ref | sed 's/^\([^ ]*\)\ \(.*\)$/\2 (\1)/' > $scdir/ref

# cat $ref | scripts/transcript2hyp.pl | sed 's:<NOISE>::g' | \
#   sed 's:<SPOKEN_NOISE>::g' > $scoredir/ref

# $sclite -r $scoredir/ref trn -h $scoredir/hyp trn -i wsj -o all -o dtl

sclite -r $scdir/ref trn -h $scdir/hyp trn -i swb -o sgml
# sc_stats -p -r sum rsum es res lur -t std4 -u -g grange2 det
