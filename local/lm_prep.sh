#!/bin/bash -u

# Borrowing mainly from gp script of same name

set -o errexit
set -o pipefail

. ./path.sh    # Sets the PATH to contain necessary executables

# Begin configuration section.
filter_vocab_sri=false    # if true, use SRILM to change the LM vocab
srilm_opts="-subset -prune-lowprobs -unk -tolower"
version="small"
# end configuration sections

help_message="Usage: "`basename $0`" [options] language <lang-dir> <dict-dir>
working with one language for now
options:
  --help                           # print this message and exit
  --filter-vocab-sri (true|false)  # use SRILM to change the LM vocab (default: $filter_vocab_sri)
  --srilm-opts STRING              # options to pass to SRILM tools (default: '$srilm_opts')
  --version STRING                 # optional, for selecting alternative lm
";

. utils/parse_options.sh

if [ $# -lt 1 ]; then
  printf "$help_message\n"; exit 1;
fi

# Fix the source dir for now
LMDIR=$DATA_PATH/data_sources
# Work with only one language for now
LANGUAGES=$1
# Add the language directory
LANG_DIR=$2
# Add the directory for the lexicon
DICT_DIR=$3
# while [ $# -gt 0 ]; do
#   case "$1" in
#   ??) LANGUAGES=$LANGUAGES" $1"; shift ;;
#   *)  echo "Unknown argument: $1, exiting"; error_exit $usage ;;
#   esac
# done


if [ -z $IRSTLM ] ; then
  export IRSTLM=$KALDI_ROOT/tools/irstlm/
fi
export PATH=${PATH}:$IRSTLM/bin
if ! command -v prune-lm >/dev/null 2>&1 ; then
  echo "$0: Error: the IRSTLM is not available or compiled" >&2
  echo "$0: Error: We used to install it by default, but." >&2
  echo "$0: Error: this is no longer the case." >&2
  echo "$0: Error: To install it, go to $KALDI_ROOT/tools" >&2
  echo "$0: Error: and run extras/install_irstlm.sh" >&2
  exit 1
fi

# The part to change starts here
# We need to change the paths and stuff

for L in $LANGUAGES; do
  # This file name is unique and may need to be changed
  lm=$LMDIR/${L}_lm_${version}.arpa.gz
  # Convert to lowercase
  gunzip -c $lm | perl -pe '$_=lc' | gzip > $LMDIR/${L}_lm_${version}_lc.arpa.gz
  lm=$LMDIR/${L}_lm_${version}_lc.arpa.gz
  [ -f $lm ] || { echo "LM '$lm' not found"; exit 1; }
  if [ "$version" = "small" ]; then
    test=data/$L/${LANG_DIR}_test_tg
  else
    test=data/$L/${LANG_DIR}_${version}_test_tg
  fi

  # Format the LM
  if $filter_vocab_sri; then  # use SRILM to change LM vocab
    utils/format_lm_sri.sh --srilm-opts "$srilm_opts" \
      data/$L/$LANG_DIR $lm data/$L/local/$DICT_DIR/lexicon.txt "${test}_sri"
  else  # just remove out-of-lexicon words without renormalizing the LM
    utils/format_lm.sh data/$L/$LANG_DIR $lm data/$L/local/$DICT_DIR/lexicon.txt "$test"
  fi

  # Create a pruned version of the LM for building the decoding graphs, using
  # 'prune-lm' from IRSTLM:
  mkdir -p data/$L/local/lm
  prune-lm --threshold=1e-7 $lm /dev/stdout | gzip -c \
    > data/$L/local/lm/${L}.tgpr.arpa.gz
  lm=data/$L/local/lm/${L}.tgpr.arpa.gz
  if [ "$version" = "small" ]; then
    test=data/$L/${LANG_DIR}_test_tgpr
  else
    test=data/$L/${LANG_DIR}_${version}_test_tgpr
  fi
  # Again, not worrying about this for now
  if $filter_vocab_sri; then  # use SRILM to change LM vocab
    utils/format_lm_sri.sh data/$L/$LANG_DIR $lm data/$L/local/$DICT_DIR/lexicon.txt \
      "${test}_sri"
  else  # just remove out-of-lexicon words without renormalizing the LM
    utils/format_lm.sh data/$L/$LANG_DIR $lm data/$L/local/$DICT_DIR/lexicon.txt "$test"
  fi
done
