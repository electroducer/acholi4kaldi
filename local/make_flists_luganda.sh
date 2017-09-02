#!/bin/bash -u

# Borrowed heavily from gp script of same name

set -o errexit
set -o pipefail

function read_dirname () {
  local dir_name=`expr "X$1" : '[^=]*=\(.*\)'`;
  [ -d "$dir_name" ] || { echo "Argument '$dir_name' not a directory" >&2; \
    exit 1; }
  local retval=`cd $dir_name 2>/dev/null && pwd || exit 1`
  echo $retval
}

PROG=`basename $0`;
usage="Usage: $PROG <arguments> <acholi|luganda|uenglish>\n
Prepare train, dev, eval file lists for a language.\n\n
Required arguments:\n
  --list-dir=DIR\t\tPlace where speaker lists are stored\n
  --work-dir=DIR\t\tPlace to write the files (in a subdirectory within lang)\n
";

if [ $# -lt 3 ]; then
  echo -e $usage; exit 1;
fi

while [ $# -gt 0 ];
do
  case "$1" in
  --help) echo -e $usage; exit 0 ;;
  --work-dir=*)
  WDIR=`read_dirname $1`; shift ;;
  --list-dir=*)
  LIST_PATH=`read_dirname $1`; shift ;;
  *) L=$1; shift ;;
  esac
done

[ -f path.sh ] && . path.sh  # Sets the PATH to contain necessary executables

tmpdir=$(mktemp -d /tmp/kaldi.XXXX);
trap 'rm -rf "$tmpdir"' EXIT

# Directory to write file lists & transcripts
ODIR=$WDIR/$L/local/data
ODIR_TR=${ODIR}_trimmed
mkdir -p $ODIR
mkdir -p $ODIR_TR
echo "Saving files to $ODIR"
echo "Saving trimmed files to $ODIR_TR"
echo "Getting lists from $LIST_PATH"


echo "Creating files for all speakers..."
# # Get all unique speakers from the speaker list
# # in order to divide them up into sets
# cut -d" " -f2 $DATA_PATH/$L/speakers/all_spk.txt | sed -e 's/[^0-9]$//' \
#   | sort | uniq > $tmpdir/uniq_spk

# Get the recording numbers from the original mp3 files
ls $DATA_PATH/$L/mp3 | sed -e "s/.mp3$//" \
  > $tmpdir/all_recs

# Get the list of transcript files
trans=$tmpdir/trans.list
ls -1 $DATA_PATH/$L/trans/*.trans > $trans
# Sanity check: select only transcript files that have recordings
# and transcripts that are not blank
# then combine them into a single file
sed 's/$/./' $tmpdir/all_recs > $tmpdir/all_recs_dot
sed '/^[0-9_]\+\s\+$/d' $(grep -f $tmpdir/all_recs_dot $trans) \
  > $tmpdir/${L}.trans
# Any blank lines (ID only) would be deleted here

# Clean the transcriptions (see cleaning script for details)
clean_trans_acholi.pl $tmpdir/${L}.trans \
  > $tmpdir/${L}_clean.trans


# Some changes for acholi
# After cleaning, there still might blanks and junk
awk '$0=NF' $tmpdir/${L}_clean.trans > $tmpdir/nwords
paste $tmpdir/nwords $tmpdir/${L}_clean.trans \
  | egrep "^2[^0-9]" | egrep "(junk|<fil>)" \
  | cut -f2 | cut -d" " -f1 > $tmpdir/junk_ids

# Make a list of all wav files (for each utt)
ls $DATA_PATH/$L/wav/*.wav > $ODIR/${L}_wav.flist

# Make the master scp file for all wavs
sed -e "s?.*/??" -e 's?.wav$??' $ODIR/${L}_wav.flist \
  > $tmpdir/basenames_wav
paste $tmpdir/basenames_wav $ODIR/${L}_wav.flist | sort -k1,1 \
  > $tmpdir/${L}_wav.scp
# We're going to make a copy of the IDs for now
cut -f1 $tmpdir/${L}_wav.scp > $tmpdir/basenames_wav2

# Now for the hard part. Find the intersection of speaker data,
# transcription data, and wav data
# This gets the intersection of wavs and transcripts
cut -d" " -f1 $tmpdir/${L}_clean.trans \
  | join $tmpdir/basenames_wav2 - > $tmpdir/final_ids
# And this adds the speaker ids to the intersection
# cut -d" " -f1 $DATA_PATH/$L/speakers/all_spk.txt \
#   | join $tmpdir/basenames - | sed -e 's/^[^0-9MF]//' -e 's/[^0-9]$//' \
#   > $tmpdir/final_ids

# Get final speaker list for ids and use as prefix
# (Kaldi apparently requires this)
# The extra call to sed cleans up leftover rogue characters
# join $tmpdir/final_ids $DATA_PATH/$L/speakers/all_spk.txt | cut -d" " -f2 \
#   | sed -e 's/^[^0-9MF]//' -e 's/[^0-9]$//' > $tmpdir/final_spks
# paste -d _ $tmpdir/final_spks $tmpdir/final_ids > $tmpdir/final_spk_ids

# This trims off the junk ids found previously
grep -v -f $tmpdir/junk_ids $tmpdir/final_ids > $tmpdir/final_ids_trimmed
# join $tmpdir/final_ids_trimmed \
#   $DATA_PATH/$L/speakers/all_spk.txt | cut -d" " -f2 \
#   | sed -e 's/^[^0-9MF]//' -e 's/[^0-9]$//' > $tmpdir/final_spks_trimmed
# paste -d _ $tmpdir/final_spks_trimmed $tmpdir/final_ids_trimmed \
#   > $tmpdir/final_spk_ids_trimmed


# Keep only the wavs in the final list
join $tmpdir/final_ids $tmpdir/${L}_wav.scp \
  | sed 's/^/LU/' | sort \
  > $ODIR/wav.scp
# Keep only the transcripts in the final list
join $tmpdir/final_ids $tmpdir/${L}_clean.trans \
  | sed 's/^/LU/' | sort \
  > $ODIR/text
# Keep only the speaker ids in the final list
sed -e 's/_.*$//' -e 's/^/LU/' $tmpdir/final_ids | paste $tmpdir/final_ids - \
  | sed 's/^/LU/' | sort \
  > $ODIR/utt2spk
# And the speakers to utterances
utt2spk_to_spk2utt.pl $ODIR/utt2spk \
  > $ODIR/spk2utt || exit 1;

# And for the trimmed version:
# Keep only the wavs in the final list
join $tmpdir/final_ids_trimmed $tmpdir/${L}_wav.scp \
  | sed 's/^/LU/' | sort \
  > $ODIR_TR/wav.scp
# Keep only the transcripts in the final list
join $tmpdir/final_ids_trimmed $tmpdir/${L}_clean.trans \
  | sed 's/^/LU/' | sort \
  > $ODIR_TR/text
# Keep only the speaker ids in the final list
sed -e 's/_.*$//' -e 's/^/LU/' $tmpdir/final_ids_trimmed \
  | paste $tmpdir/final_ids_trimmed - \
  | sed 's/^/LU/' | sort \
  > $ODIR_TR/utt2spk
# And the speakers to utterances
utt2spk_to_spk2utt.pl $ODIR_TR/utt2spk \
  > $ODIR_TR/spk2utt || exit 1;


echo "Done."
