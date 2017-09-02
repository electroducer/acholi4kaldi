# This script prepares the data for the language specified

stage=0

# Get the paths
[ -f path.sh ] && . path.sh || exit 1

. parse_options.sh || exit 1;

# Check for necessary files
[ -f conf/dev_spk.list ] || error_exit "$PROG: Dev-set speaker list not found.";
[ -f conf/eval_spk.list ] || error_exit "$PROG: Eval-set speaker list not found.";

# Argument 1: language
L=$1

# Step 1. Analyse and organise files
# This will unpack the zip file with the data reorganise the files
if [ $stage -le 0 ]; then
  echo "Getting and setting up language data..."
  case "$L" in
    acholi)
      local/setup_acholi.sh
      ;;
    luganda)
      local/setup_luganda.sh
      ;;
    swahili)
      echo "Setting up data for swahili..."
      local/data_prep_swahili.sh
      exit 0
      ;;
    *)
      echo "Language out of database."
      exit 1
      ;;
  esac
  echo "Done."
fi

# Step 2. Parse the TextGrid files into durations and transcriptions
# creates a new dir called 'trans'
if [ $stage -le 1 ]; then
  echo "Parsing TextGrid files..."
  [ -d $DATA_PATH/$L/trans ] && rm -rf $DATA_PATH/$L/trans
  local/parse_textgrid.sh $DATA_PATH/$L/TextGrid
  echo "Done."
fi

# Step 2a. Fix the speaker files for acholi
# creates the file 'speakers/all_spk.txt'
if [ $stage -le 2 ]; then
  if [ "$L" == "acholi" ]; then
    echo "Compiling speaker list..."
    [ -d $DATA_PATH/$L/speakers/all_spk.txt ] && rm $DATA_PATH/$L/speakers/all_spk.txt
    local/fix_spk_lists.sh $DATA_PATH/$L/speakers
    echo "Done."
  fi
fi

# Step 3. Convert and split the audio
# Will create the 'tmpwav' and 'wav' directories
if [ $stage -le 3 ]; then
  echo "Converting and splitting audio..."
  [ -d $DATA_PATH/$L/tmpwav ] && rm -rf $DATA_PATH/$L/tmpwav
  [ -d $DATA_PATH/$L/wav ] && rm -rf $DATA_PATH/$L/wav
  local/convert_audio.sh $L
  echo "Done."
fi

# END OF CHANGES TO THE MAIN DATA STORAGE DIR

# From now, the 'data' dir in the working dir will be created and modified

# Step 4. Make the file lists
if [ $stage -le 4 ]; then
  echo "Compiling file lists and splitting data..."
  # Turning this off for now
  # [ -d data ] && rm -rf data
  mkdir -p data/$L/local/data
  local/make_flists.sh --work-dir=data --list-dir=conf $L \
    >& data/$L/make_flists.log
  echo "Done."
fi

# Step 5. Normalise the transcriptions
# This involves running a script over the transcriptions to get rid of the
# ending tags and other stuff
# See the perl script for details.
# Note that this differs from the gp script, as the transcript formats differ
# for x in dev eval train; do
#   echo "Cleaning the transcriptions..."
#   clean_trans_acholi.pl data/$L/local/data/${x}_${L}.trans1 \
#     > data/$L/local/data/${x}_${L}.txt
#   echo "Done."
# done
#
# # Step 6. Organise the final data directories
# for x in train dev eval; do
#   echo "Moving files to partition directories..."
#   mkdir -p data/$L/$x
#   cp data/$L/local/data/${x}_${L}_wav.scp data/$L/$x/wav.scp
#   cp data/$L/local/data/${x}_${L}.txt data/$L/$x/text
#   cp data/$L/local/data/${x}_${L}.spk2utt data/$L/$x/spk2utt
#   cp data/$L/local/data/${x}_${L}.utt2spk data/$L/$x/utt2spk
#   echo "Done."
# done

echo "Data preparation complete."
