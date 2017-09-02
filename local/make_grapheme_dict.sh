#!/bin/bash

L=$1

# We need to change this so that it modifies a clean dictionary

LEX_PATH=$DATA_PATH/data_sources

pron_lex=$LEX_PATH/${L}_lexicon.txt

# If creating a dictionary from scratch (based on transcriptions)
data_text=
create_new=false

. utils/parse_options.sh || exit 1;

# For creating a dict from scratch
if $create_new; then
  [ ! -e $data_text ] && { echo "Incorrect data path."; exit 1; }
  cut -d' ' -f2- data/luganda/local/data/text \
    | tr ' ' '\n' | sort | uniq \
    > $LEX_PATH/${L}_lex_vocab.txt
else
  # Cut out the entries (leaving out single space delimeter for now)
  cut -f1 $pron_lex > $LEX_PATH/${L}_lex_vocab.txt
fi

# Add spaces between letters and paste with vocab
# Don't need that last part for a clean dict
# sed -r 's/(.)/\1 /g' $LEX_PATH/${L}_lex_vocab.txt \
#   | paste $LEX_PATH/${L}_lex_vocab.txt - \
#   | sed -r '/[^A-Z\t ]/d' > $LEX_PATH/${L}_lex_grapheme.txt

sed -e 's/[^A-Za-z]//g' $LEX_PATH/${L}_lex_vocab.txt | sed -r 's/(.)/\1 /g' \
  | paste $LEX_PATH/${L}_lex_vocab.txt - | sed '/\t$/d' \
  > $LEX_PATH/${L}_lex_grapheme.txt
