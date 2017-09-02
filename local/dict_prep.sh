#!/bin/bash -u

# Based mainly on gp code of same name

set -o errexit

function error_exit () {
  printf "$@\n" >&2; exit 1;
}

function read_dirname () {
  [ -d "$1" ] || error_exit "Argument '$1' not a directory";
  local retval=`cd $1 2>/dev/null && pwd || exit 1`
  echo $retval
}

. ./path.sh    # Sets the PATH to contain necessary executables

# Begin configuration section.
config_dir=conf    # if true, use SRILM to change the LM vocab
map_dir=
spoken_noise=true
grapheme=false
# end configuration sections

help_message="Usage: "`basename $0`" [options] language <dict-dir>
just taking a single language for now
  --help                # print this message and exit
  --config-dir DIR      # directory to find config files (default: $config_dir)
  --map-dir DIR         # directory to find phone mappings (default: '$map_dir')
  --spoken-noise (true|false)   # default: $spoken_noise
  --grapheme (true|false)   # use a grapheme dict default: $grapheme
";

. utils/parse_options.sh

if [ $# -lt 1 ]; then
  printf "$help_message\n"; exit 1;
fi

# We'll just use the main variable to locate the lexicon source
LEX_PATH=$DATA_PATH/data_sources
LANGUAGES=$1
DICT_DIR=$2
# GPDIR=`read_dirname $1`; shift;
# LANGUAGES=
# while [ $# -gt 0 ]; do
#   case "$1" in
#   ??) LANGUAGES=$LANGUAGES" $1"; shift ;;
#   *)  echo "Unknown argument: $1, exiting"; error_exit "$help_message" ;;
#   esac
# done

# (1) check if the config files are in place:
pushd $config_dir > /dev/null
[ -f dev_spk.list ] || error_exit "$PROG: Dev-set speaker list not found.";
[ -f eval_spk.list ] || error_exit "$PROG: Eval-set speaker list not found.";

popd > /dev/null
[ -f path.sh ] && . path.sh  # Sets the PATH to contain necessary executables

# (1) Normalize the dictionary
for L in $LANGUAGES; do
  printf "Language - ${L}: preparing pronunciation lexicon ... "
  mkdir -p data/$L/local/$DICT_DIR
  if $grapheme; then
    pron_lex=$LEX_PATH/${L}_lex_grapheme.txt
  else
    pron_lex=$LEX_PATH/${L}_lexicon.txt
  fi
  [ -f "$pron_lex" ] || { echo "Error: no dictionary found for $L"; exit 1; }

  # May need to use the phone mapping features later
  if [ ! -z "$map_dir" ]; then  # map the phones to a different phoneset
    if [ -f "$map_dir/$full_name" ]; then  # found the mapping file
      # Since the cleaning script doesn't check for duplicates
      # they must be removed using sort and awk
      local/clean_dict_${L}.pl -i "$pron_lex" -m "$map_dir/$full_name" \
	      | sort -u | awk '!seen[$1]++' > data/$L/local/$DICT_DIR/lexicon_nosil.txt
    else
      echo "No phone mapping '$map_dir/$full_name': keeping original phoneset";
      local/clean_dict_${L}.pl -i "$pron_lex" | sort -u | awk '!seen[$1]++' \
	      > data/$L/local/$DICT_DIR/lexicon_nosil.txt
    fi
  else
    local/clean_dict_${L}.pl -i "$pron_lex" | sort -u | awk '!seen[$1]++' \
      > data/$L/local/$DICT_DIR/lexicon_nosil.txt
  fi

  # Add silence
  if $spoken_noise; then
    (printf '!SIL\tsil\n<SPOKEN_NOISE>\tspn\n<UNK>\tspn\n';) \
      | cat - data/$L/local/$DICT_DIR/lexicon_nosil.txt \
      > data/$L/local/$DICT_DIR/lexicon.txt;
  else
    (printf '!SIL\tsil\n<UNK>\tspn\n';) \
      | cat - data/$L/local/$DICT_DIR/lexicon_nosil.txt \
      > data/$L/local/$DICT_DIR/lexicon.txt;
  fi
  echo "Done"


  printf "Language - ${L}: extracting phone lists ... "
  # silence phones, one per line.
  { echo sil; echo spn; } > data/$L/local/$DICT_DIR/silence_phones.txt
  echo sil > data/$L/local/$DICT_DIR/optional_silence.txt
  cut -f2- data/$L/local/$DICT_DIR/lexicon_nosil.txt | tr ' ' '\n' | sort -u \
    > data/$L/local/$DICT_DIR/nonsilence_phones.txt
  # Ask questions about the entire set of 'silence' and 'non-silence' phones.
  # These augment the questions obtained automatically by clustering.
  ( tr '\n' ' ' < data/$L/local/$DICT_DIR/silence_phones.txt; echo;
    tr '\n' ' ' < data/$L/local/$DICT_DIR/nonsilence_phones.txt; echo;
    ) > data/$L/local/$DICT_DIR/extra_questions.txt
  echo "Done"
done

echo "Finished dictionary preparation."
